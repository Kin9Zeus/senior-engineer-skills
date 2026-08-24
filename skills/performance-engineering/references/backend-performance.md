# Backend Performance

## Set the budget first

Without a target, "fast enough" is an argument. With one, it is a measurement.

```
Endpoint class          p50      p95      p99
─────────────────────────────────────────────
Read (cached)         < 20ms   < 50ms   < 150ms
Read (database)       < 50ms  < 200ms   < 500ms
Write                < 100ms  < 300ms  < 1000ms
Search                < 100ms  < 400ms  < 1000ms
Report / export        async — return 202 and a job id
```

Anything that cannot meet its budget synchronously belongs in a queue. Returning
`202` with a job resource is not a compromise; it is the correct design for
work that takes seconds.

---

## Find where the time goes

**Distributed tracing** is the fastest route to an answer: it shows the
breakdown per request without adding instrumentation for each hypothesis.

**Profilers** for CPU-bound work:

| Runtime | Tool |
|---|---|
| Node | `--cpu-prof`, `clinic flame`, `0x` |
| Python | `py-spy` (no code change, works on a live process), `cProfile` |
| Go | `net/http/pprof` — CPU, heap, goroutines, blocking |
| Java | async-profiler, JFR |
| .NET | dotnet-trace, dotnet-counters |
| Ruby | stackprof, rbspy |

`py-spy` and `pprof` are especially valuable because they attach to a running
production process without a deploy.

**Where the time actually is, in order of frequency:**

1. **Database.** Missing index, N+1, fetching more than needed, a slow join.
   This is the answer most of the time. See `database-engineering`.
2. **Sequential external calls** that could run concurrently.
3. **Work that belongs in a queue** happening inline.
4. **Serialisation** of large payloads (surprisingly often the top CPU consumer).
5. **Application logic** — genuinely last. Optimising code before checking the
   four above is the classic wasted afternoon.

---

## Concurrency — the cheapest win

```ts
// Sequential: 300ms. Three independent calls waiting in line.
const user = await getUser(id);
const orders = await getOrders(id);
const prefs = await getPrefs(id);

// Concurrent: ~100ms. Same work, one round trip's worth of latency.
const [user, orders, prefs] = await Promise.all([
  getUser(id), getOrders(id), getPrefs(id),
]);
```

Check every handler for sequential `await`s on independent operations. It is the
most common and most easily fixed backend latency problem.

Two caveats: use `Promise.allSettled` when a partial failure should not fail the
whole request, and bound the concurrency (`p-limit` or equivalent) when fanning
out over a list — unbounded parallelism exhausts connection pools and turns a
latency problem into an outage.

---

## Move work out of the request path

Anything the user does not need to wait for:

| Move to a queue | Why |
|---|---|
| Sending email | An email provider's latency is not your user's problem |
| Image and video processing | Seconds to minutes |
| Report and export generation | Unbounded |
| Webhook delivery | The consumer may be slow or down |
| Third-party synchronisation | Their outage should not be yours |
| Search indexing | Eventually consistent is fine |
| Analytics events | Fire and forget |

The user gets an immediate response and a status they can poll or be notified
about. See `project-blueprint/references/architecture-patterns.md` for the job
system requirements — chiefly, handlers must be idempotent.

---

## Caching layers

```
Browser  →  CDN / edge  →  App cache (Redis)  →  Database  →  Materialised view
 fastest ─────────────────────────────────────────────────────────→ slowest
```

Cache as close to the user as the data's freshness allows.

**Before caching, ask:** can I make the underlying operation fast instead? A
cache over a missing index masks the problem, adds an invalidation bug surface,
and fails exactly when you need it most — during a cache-cold restart under load.

**Patterns**

| Pattern | Shape | Use |
|---|---|---|
| Cache-aside | Read cache, miss → load → store | Default |
| Write-through | Write both together | Read-heavy, freshness critical |
| Write-behind | Write cache, flush async | High write volume, some loss tolerable |
| Refresh-ahead | Refresh before expiry | Predictable hot keys |

**Invalidation** — if you cannot state the rule, you do not have a cache:
- **TTL** — simplest, always correct eventually, tolerates staleness.
- **Event-based** — invalidate on write. Correct, and easy to miss a path.
- **Versioned keys** — `user:123:v7`. Changing the version invalidates
  atomically without a delete, which avoids the race entirely.

**The rules that prevent incidents:**
- **Never cache user-scoped data in a shared cache without the user or tenant in
  the key.** Cross-user leakage is a `P0` and it recurs in real audits.
- Set a **maximum** on every cache. An unbounded in-memory cache is a memory
  leak with a friendly name.
- **Cache stampede:** when a hot key expires, every request misses at once and
  hammers the origin. Fix with a lock/single-flight, or jittered TTLs, or
  `stale-while-revalidate` semantics.
- Instrument hit rate. A cache below ~80% hit rate is usually mis-keyed or
  under-TTL'd, and may be costing more than it saves.

---

## Connection and resource pools

The most common "the database is down" that is not the database.

- Pool size is a function of **database capacity**, not application concurrency.
  More connections frequently means less throughput.
- Serverless multiplies connections without bound — put a proxy pooler in front.
- Set all three timeouts: connection acquisition, statement, and
  idle-in-transaction.
- **Alert on pool saturation and acquisition wait time.**
- Never hold a pooled connection across an external HTTP call. This single rule
  prevents a large fraction of production latency incidents.

---

## Payload size

Frequently overlooked, and often the top CPU cost.

- Return only the fields the client needs. `SELECT *` and a full-object
  serialiser is bytes, CPU and bandwidth for nothing.
- Paginate everything. Cap the page size server-side.
- Compress responses (gzip/brotli) — usually a config flag.
- For very large responses, stream rather than buffering the whole thing in
  memory.
- Consider a binary format for high-volume internal service-to-service traffic.

---

## Capacity planning

```
1. Measure current: RPS, p95 latency, resource utilisation at peak
2. Find the knee: load-test until latency degrades. What saturates FIRST?
3. Compute headroom: (capacity at knee) / (current peak)
4. Project growth: at the current rate, when does headroom reach 1?
5. Decide: scale up, scale out, or optimise — and schedule it before the date
```

**Name the first bottleneck**, not all of them. In practice it is almost always
one of: database connections, database CPU, a single-threaded component, an
external rate limit, or memory.

Test with **production-sized data**. A load test against a small dataset measures
your framework, not your system.

---

## Anti-patterns

| Anti-pattern | Consequence |
|---|---|
| Optimising before profiling | Time spent on the wrong thing; added complexity |
| Caching to hide a missing index | Masks the problem; fails under cache-cold load |
| Unbounded parallel fan-out | Exhausts pools; converts latency into an outage |
| External HTTP inside a transaction | Holds a connection through someone else's outage |
| No timeouts on outbound calls | Unbounded hang; cascading failure |
| Sync work that should be a queue | Latency the user pays for, for no benefit |
| Premature horizontal scaling | More instances hammering the same saturated database |
| Micro-optimising application code | Almost never where the time is |
| Load-testing against seed data | Measures nothing about production |
| "It's fast on my machine" | Your machine is not a mid-range phone on 4G |
