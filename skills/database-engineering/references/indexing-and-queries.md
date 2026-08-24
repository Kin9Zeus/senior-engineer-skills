# Indexing and Query Optimisation

Optimisation without measurement is guessing. Every recommendation here starts
with a query plan or a statistic, never with intuition about what "should" be
slow.

---

## Find the queries worth optimising

Optimise by **total** time — calls × mean — not by the slowest single query. A
4ms query executed two million times a day costs far more than a 6-second report
run twice.

**Postgres** (requires `pg_stat_statements`):
```sql
SELECT calls,
       round(mean_exec_time::numeric, 2)  AS mean_ms,
       round(total_exec_time::numeric, 2) AS total_ms,
       rows,
       left(query, 120)                   AS query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;
```

**MySQL**: enable the slow query log with `long_query_time = 0.1`, then
`pt-query-digest`, or read `performance_schema.events_statements_summary_by_digest`.

**MongoDB**: the profiler at level 1, then `db.system.profile`.

**Application-side**: your APM's endpoint breakdown, or the ORM query log for a
single page load — which is where N+1 shows up and nowhere else.

---

## Read the plan

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
```

`ANALYZE` executes the query and gives real timings. `BUFFERS` shows whether
data came from cache or disk. Wrap in a transaction and roll back if you are
analysing a write.

**What to look for, in order:**

1. **Estimated vs actual rows.** A large divergence means the planner is working
   from bad information and every downstream choice is suspect. Fix with
   `ANALYZE`, more statistics targets, or extended statistics for correlated
   columns.
2. **`Seq Scan` on a large table.** Add an index — or confirm the table is small
   enough that a scan is genuinely cheaper (the planner is often right).
3. **`Rows Removed by Filter`.** A large number means the index found rows the
   filter then discarded. A composite or partial index that includes the filter
   condition fixes it.
4. **`Sort` with `Sort Method: external merge  Disk`.** The sort spilled. Index
   the sort order, or raise `work_mem` for that workload.
5. **`Nested Loop` with a high outer row count.** Usually a consequence of bad
   estimates. Fix the statistics before rewriting the query.
6. **Time concentrated in one node.** Optimise that node; the rest is noise.

---

## Index types and when each applies

| Type | Serves | Notes |
|---|---|---|
| **B-tree** | Equality, ranges, sorting, prefix `LIKE 'abc%'` | The default; correct for almost everything |
| **Hash** | Equality only | Rarely worth choosing over B-tree |
| **GIN** | `jsonb` containment, arrays, full-text | Slower to write, much faster to search |
| **GiST** | Geometric, ranges, nearest-neighbour | PostGIS, exclusion constraints |
| **BRIN** | Very large, naturally ordered tables (append-only time series) | Tiny index, only useful with physical correlation |
| **Partial** | A queried subset | `WHERE deleted_at IS NULL` — far smaller, far faster |
| **Expression** | Queries on a computed value | `LOWER(email)`, `(payload->>'type')` |
| **Covering** | Reads served entirely from the index | `INCLUDE (cols)` avoids the heap lookup |

**Composite index column order** is the thing most often got wrong:

```sql
-- Query: WHERE organization_id = ? AND status = ? ORDER BY created_at DESC
CREATE INDEX idx_inv_org_status_created
  ON invoices (organization_id, status, created_at DESC);
--             └─ equality ──┘  └equality┘  └── sort ──┘
```

Equality predicates first, then the range or sort column. An index on `(a, b)`
serves `WHERE a = ?` and `WHERE a = ? AND b = ?`. It does **not** serve
`WHERE b = ?` — that needs its own index.

---

## Diagnostics worth keeping

```sql
-- Unindexed foreign keys (Postgres)
SELECT c.conrelid::regclass AS tbl, a.attname AS col
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (SELECT 1 FROM pg_index i
                  WHERE i.indrelid = c.conrelid AND a.attnum = i.indkey[0]);

-- Indexes that cost writes and serve nothing
SELECT relname, indexrelname, idx_scan,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelid NOT IN (SELECT conindid FROM pg_constraint)
ORDER BY pg_relation_size(indexrelid) DESC;

-- Tables taking the most sequential scans
SELECT relname, seq_scan, seq_tup_read, idx_scan,
       seq_tup_read / GREATEST(seq_scan, 1) AS rows_per_scan
FROM pg_stat_user_tables
WHERE seq_scan > 0 ORDER BY seq_tup_read DESC LIMIT 15;

-- Cache hit ratio (below ~0.99 on a busy OLTP database means memory pressure)
SELECT sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0)
FROM pg_statio_user_tables;

-- Bloat and vacuum health
SELECT relname, n_dead_tup, n_live_tup, last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables WHERE n_dead_tup > 10000 ORDER BY n_dead_tup DESC;

-- Blocking right now
SELECT pid, state, wait_event_type, wait_event, left(query, 80), age(now(), query_start)
FROM pg_stat_activity WHERE state <> 'idle' ORDER BY query_start;
```

**Add indexes concurrently on live systems:** `CREATE INDEX CONCURRENTLY` in
Postgres, `ALGORITHM=INPLACE, LOCK=NONE` in MySQL. A plain `CREATE INDEX` takes a
lock that will stall your application. `CONCURRENTLY` cannot run inside a
transaction, and can leave an invalid index if it fails — check and drop.

---

## The N+1 problem

Invisible in source code, obvious in the query log.

```
GET /invoices  →  1 query for invoices
                  40 queries for each invoice's customer
                  40 queries for each invoice's line items
                  = 81 round trips, ~400ms of pure latency
```

**Detection:** look at the ORM log for a single request. Repeated identical query
*shapes* with different parameters is the signature.

**Prevention — turn it into an error in development:**

| Stack | Mechanism |
|---|---|
| Laravel | `Model::preventLazyLoading()` in a non-production service provider |
| Rails | the `bullet` gem |
| Django | `django-debug-toolbar`; assert query counts in tests |
| Prisma | log queries in development; assert counts |
| Hibernate | disable open-session-in-view; lazy init then throws |
| SQLAlchemy | `lazy="raise"` on relationships |

**Fixes:** eager loading (`select_related`/`prefetch_related`, `with()`,
`include`, `Preload`, `JOIN FETCH`); a single query with joins; a dataloader for
GraphQL (batch and cache within a request).

**Assert it in tests.** A test that fails when a page issues more than N queries
is the only thing that stops N+1 from returning.

---

## Pagination

**Offset pagination degrades linearly.** `OFFSET 100000` makes the database read
and discard 100,000 rows. It is also incorrect under concurrent writes — rows
shift between pages.

**Use keyset (cursor) pagination** for anything large or changing:

```sql
-- page 1
SELECT * FROM events WHERE org_id = $1 ORDER BY created_at DESC, id DESC LIMIT 50;
-- next page: pass the last row's (created_at, id) as the cursor
SELECT * FROM events
WHERE org_id = $1 AND (created_at, id) < ($2, $3)
ORDER BY created_at DESC, id DESC LIMIT 50;
```

Include a tiebreaker column (`id`) so the ordering is total — otherwise rows with
equal timestamps can be skipped or repeated.

**Always cap the page size** server-side. An unbounded `limit` parameter is a
denial-of-service vector.

---

## Query anti-patterns

| Pattern | Problem | Instead |
|---|---|---|
| `SELECT *` | Fetches unused columns; breaks on schema change; prevents covering indexes | Name the columns |
| `WHERE LOWER(email) = ?` | Index unusable | Expression index, or store normalised |
| `WHERE date_col::date = ?` | Function on the column kills the index | Range: `>= d AND < d+1` |
| `WHERE col LIKE '%x%'` | Leading wildcard cannot use a B-tree | Full-text or trigram index |
| `NOT IN (subquery)` | NULL semantics surprise; often slow | `NOT EXISTS` |
| `OR` across different columns | Often prevents index use | `UNION ALL` of two indexed queries |
| `COUNT(*)` on a huge table for a UI | Full scan every page load | Approximate count, or a maintained counter |
| `DISTINCT` to fix duplicates | Hides a wrong join | Fix the join |
| Query inside a loop | N+1 | Batch it |

---

## Connection pooling

The most common production database incident that is not a slow query.

- Pool size is a function of **database capacity**, not application concurrency.
  A common starting point is `(cores × 2) + effective spindle count`; more
  connections usually means *less* throughput, not more.
- Serverless and autoscaling platforms multiply connections without bound — put a
  proxy pooler in front (PgBouncer, RDS Proxy, Supavisor).
- Set a connection timeout, a statement timeout and an idle-in-transaction
  timeout. Without `idle_in_transaction_session_timeout`, one stuck transaction
  holds locks indefinitely.
- Alert on pool saturation and connection wait time. "The site is slow" is
  frequently "the pool is exhausted because a transaction is waiting on an HTTP
  call".

---

## Caching, in order of preference

1. **Make the query fast.** Cache is not a fix for a missing index; it is a layer
   over one, and it will mask the problem until it fails.
2. **Database-level:** materialised views for expensive aggregates, refreshed on
   a schedule.
3. **Application-level:** cache with an explicit TTL and an explicit invalidation
   rule. If you cannot state the invalidation rule, you do not have a cache — you
   have stale data with extra steps.
4. **HTTP-level:** `Cache-Control` and `ETag` for read-heavy endpoints; a CDN in
   front.

Never cache anything user-scoped in a shared cache without the user or tenant in
the key. Cross-user cache leakage is a `P0`.
