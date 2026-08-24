# Architecture Patterns

Patterns are answers to specific problems. Applying one without the problem it
solves is how systems become expensive. Each entry below states the problem
first.

---

## The modular monolith — the correct default

**Problem it solves:** you need clear boundaries and independent reasoning, but
you do not have the team size, load asymmetry or deployment-independence problem
that justifies a distributed system.

One deployable unit, internally divided by **domain**, not by technical layer.

```
src/
  modules/
    billing/          domain/  application/  infrastructure/  http/
    accounts/         domain/  application/  infrastructure/  http/
    catalogue/        ...
  platform/           config  logging  db  auth  errors  events
  app.ts
```

Rules that make it work:

1. **Modules communicate through explicit interfaces**, never by reaching into
   each other's internals. Enforce it with lint rules or module boundaries —
   convention alone decays within a quarter.
2. **Dependencies point inward.** `domain/` imports nothing from the framework,
   the ORM or the HTTP layer. This is what makes business rules testable in
   milliseconds without a database.
3. **Each module owns its tables.** Another module reads them through the owning
   module's interface, not with a direct join.
4. **Cross-module workflows go through events**, published in-process. When you
   eventually split a module out, the event boundary is already there.

The payoff: splitting a module into a service later becomes a deployment change
rather than a rewrite, and you pay no distributed-system cost until you need to.

---

## Layering inside a module

| Layer | Contains | May import |
|---|---|---|
| `domain` | Entities, value objects, business rules, invariants | Nothing external |
| `application` | Use cases, orchestration, transaction boundaries | `domain`, port interfaces |
| `infrastructure` | Repository implementations, external clients | `domain`, `application` interfaces |
| `http` / `cli` / `jobs` | Transport adapters, serialisation | `application` |

**The test that proves it:** can you unit-test the business rules without a
database, an HTTP server, or a mock framework? If not, the domain layer is not
isolated, whatever the folder names say.

**Do not over-apply.** A CRUD module with no interesting rules does not need four
layers. Layer where there is logic worth protecting; keep the rest thin.

---

## When to split into services

Split only when you can name which of these you have. Otherwise you are buying
distributed transactions, network partitions, deployment coordination and
observability complexity in exchange for nothing.

| Reason | Real form | Not a reason |
|---|---|---|
| Independent scaling | One component's load profile differs by an order of magnitude (video transcoding vs CRUD) | "It might get big" |
| Team autonomy | Teams genuinely blocked on each other's release cadence, at real team size | Three engineers |
| Isolation boundary | Regulatory or security requirement for physical separation | "It feels cleaner" |
| Technology fit | One component genuinely needs a different runtime | Curiosity |
| Failure isolation | One component's failure must not take the rest down | Any component can fail |

**If you split:** each service owns its data, is deployable independently, has
its own pipeline, and communicates asynchronously wherever it can. Two services
sharing a database is a distributed monolith — the worst of both worlds.

---

## Event-driven communication

**Problem it solves:** decoupling producers from an unknown or growing set of
consumers, and absorbing load spikes.

- **Events describe facts that happened** (`OrderPlaced`), in the past tense.
  Commands describe intent (`PlaceOrder`). Do not blur them.
- **Consumers must be idempotent.** Delivery is at-least-once in every real
  system; a non-idempotent consumer will double-charge someone. Deduplicate on
  an event id.
- **The event schema is a public contract.** Version it. Additive changes only,
  or you break consumers you cannot see.
- **The transactional outbox** solves the dual-write problem: write the event to
  a table in the same transaction as the state change, then publish from that
  table. Without it, you will eventually publish an event for a transaction that
  rolled back — or fail to publish one that committed.
- **Dead-letter queues** with alerting. An event that fails forever, silently, is
  data loss that nobody notices for months.

Do not adopt **event sourcing** (state as an append-only event log) unless you
genuinely need a full audit history or temporal queries. It is a large, permanent
increase in complexity, and "we might want history" is satisfied far more cheaply
by an audit table.

---

## CQRS — read/write separation

**Problem it solves:** read and write workloads that genuinely conflict — complex
reporting queries fighting transactional writes.

The cheap version is usually sufficient: a read replica, and query objects
separate from your write models. The full version (separate stores, projections,
eventual consistency between them) introduces a consistency window that every
feature must then handle. Only pay that when the read load actually demands it.

---

## Multi-tenancy

| Model | Isolation | Cost | Migration pain | Use when |
|---|---|---|---|---|
| Shared schema, `tenant_id` column | Logical | Lowest | Lowest | Default for SaaS |
| Schema per tenant | Medium | Medium | Medium | Per-tenant restore or residency needed |
| Database per tenant | Strong | Highest | Highest | Enterprise or regulatory isolation |

For shared schema, **enforce tenancy in the database** with row-level security,
not only in application code. Application-only enforcement means one forgotten
`WHERE tenant_id = ?` is a cross-tenant data breach — and that is exactly the
line a tired engineer forgets.

Decide this before the first migration. Changing it later is a project, not a
refactor.

---

## Background work

Anything slower than ~200ms that the user does not need to wait for belongs off
the request path: email, image processing, report generation, webhook delivery,
third-party synchronisation, exports.

Requirements for any job system:
- **Idempotent handlers** — retries are guaranteed.
- **Bounded retries with exponential backoff and jitter**, then a dead-letter
  queue.
- **Visibility**: queue depth, oldest-message age, failure rate — with an alert
  on oldest-message age, which is the metric that catches a stalled worker.
- **Poison-message handling** so one bad job cannot block a queue forever.

Start with your framework's queue on Postgres or Redis. Dedicated infrastructure
is a scaling answer, not a starting point.

---

## API layer

- **REST** for public and general-purpose APIs. Predictable, cacheable,
  universally understood.
- **GraphQL** when clients genuinely need to compose varied views and you can
  afford the complexity budget — depth limiting, cost analysis, persistent
  queries, and an N+1 strategy (dataloaders) are all mandatory, not optional.
- **RPC (gRPC/tRPC)** for internal service-to-service, or for a typed
  monorepo client.
- **Webhooks** for outbound notifications: signed, retried with backoff,
  idempotent from the consumer's perspective, with a replay endpoint.

See `api-contracts` for the design rules.

---

## Frontend architecture

- **Rendering per route**, chosen deliberately: static for content, server for
  dynamic-crawlable, client for authenticated app surfaces.
- **Server state and client state are different things.** Server state belongs in
  a query cache with explicit invalidation; client state (UI, forms, selection)
  belongs in local state. Putting server data in a global client store without
  invalidation guarantees stale reads.
- **Feature folders, not type folders.** `features/checkout/` beats
  `components/`, `hooks/`, `utils/` for anything past a few screens.
- **A design system layer** — tokens for colour, spacing, typography and states —
  so accessibility and consistency are enforced once rather than per component.
- **Route-level code splitting**; heavy libraries (editors, charts, PDF, locale
  data) loaded on demand.

---

## Choosing between patterns

Ask, in order:

1. What specific problem do I have *today*?
2. What is the simplest thing that solves it?
3. What does this make expensive later, and is that acceptable?
4. If I am wrong, what does reversing cost?

Prefer the reversible choice at equal quality. Record the irreversible ones as
ADRs. And remember that the most expensive architecture advice is the kind that
sounds most senior: distribution, abstraction and indirection bought before the
problem arrives.
