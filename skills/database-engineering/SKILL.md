---
name: database-engineering
description: Senior database engineering — schema design, constraints, indexing, query optimisation, N+1 elimination, transactions and isolation, migrations, multi-tenancy and row-level security, backups, point-in-time recovery and restore drills, retention and deletion. Use when designing or changing a schema, writing or reviewing migrations, when the user says "slow query", "database design", "add an index", "N+1", "my database is slow", "migration", "data model", "schema", "backup", "restore", "postgres", "mysql", "mongodb", "ORM", "deadlock", "connection pool" or "row level security"; and as a mandatory pass in any project audit. By Devleck.
license: MIT
---

# Database Engineering

The schema outlives the code, the framework, and usually the company. Application
bugs are fixed with a deploy; data-model mistakes are fixed with a migration
project, and data loss is fixed with nothing at all.

---

## The five questions that open every review

1. **What are the constraints?** Not in the ORM — in the database. `SELECT`
   against the catalogue, not the model file.
2. **Which foreign keys are unindexed?** Almost always the top performance
   finding, and it never shows up in development.
3. **What does the hottest query actually do?** `EXPLAIN ANALYZE`, not intuition.
4. **When was a backup last restored?** Not "do backups exist" — restored.
5. **What happens to a row when the user asks to be deleted?** If nobody can
   answer, that is a compliance finding as well as a design one.

---

## Schema design

**Constraints belong in the database.** The ORM is not the only writer — a
migration script, an admin tool, an analytics job, a psql session or a future
service will write directly. A rule enforced only in application code is a rule
that will be broken.

- Primary key on every table.
- Foreign keys with an **explicit** `ON DELETE` — `CASCADE`, `RESTRICT` or
  `SET NULL` chosen per relationship. Copying `CASCADE` everywhere is how a user
  deletion silently removes audit records.
- `NOT NULL` wherever the business says required. Nullable-by-default columns
  push the check into every consumer, forever.
- `UNIQUE` on what is genuinely unique, including composite uniqueness.
- `CHECK` for invariants: non-negative amounts, valid ranges, valid enum values,
  `end_date > start_date`.
- Enums as a database type or a lookup table with a foreign key — not a free
  string column with a comment.

**Types matter more than they look**

| Data | Use | Never |
|---|---|---|
| Money | `NUMERIC(19,4)` or integer minor units | Float. Ever |
| Timestamps | `timestamptz`, stored UTC | Naive local time |
| Identifiers | UUIDv7 / ULID for public ids | Sequential integers exposed publicly — they leak volume and enable enumeration |
| Text | `text` with a `CHECK` on length | Arbitrary `varchar(255)` chosen by habit |
| JSON | `jsonb`, for genuinely schemaless data only | JSON as an escape from schema design |
| Booleans | `boolean NOT NULL DEFAULT false` | Nullable three-state booleans |

Every table gets `created_at` and `updated_at`. Tables holding personal data get
a documented retention rule and a deletion path — decide this at design time, not
at DSAR time.

`references/schema-design.md` covers normalisation, denormalisation, soft
deletes, audit tables and temporal data.

---

## Indexing

**The rules**
1. Index every foreign key. The database does not do it for you (except MySQL),
   and unindexed FKs turn joins and cascading deletes into table scans.
2. Index columns used in `WHERE`, `JOIN`, and `ORDER BY` on hot paths.
3. Composite index column order follows selectivity and usage: equality
   predicates first, then range, then sort. An index on `(a, b)` serves queries
   filtering on `a`, or on `a` and `b` — not on `b` alone.
4. Partial indexes for queries over a subset (`WHERE deleted_at IS NULL`) — much
   smaller, much faster.
5. Covering indexes (`INCLUDE`) to avoid heap lookups on hot reads.
6. **Every index costs write throughput and storage forever.** Find and drop the
   unused ones.

```sql
-- Postgres: unindexed foreign keys
SELECT c.conrelid::regclass AS table, a.attname AS column
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND a.attnum = i.indkey[0]
  );

-- Indexes that cost writes and return nothing
SELECT relname, indexrelname, idx_scan, pg_size_pretty(pg_relation_size(indexrelid))
FROM pg_stat_user_indexes WHERE idx_scan = 0 ORDER BY pg_relation_size(indexrelid) DESC;

-- The queries actually worth optimising (requires pg_stat_statements)
SELECT calls, round(mean_exec_time::numeric,2) AS mean_ms,
       round(total_exec_time::numeric,2) AS total_ms, left(query, 100)
FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 15;
```

Optimise by **total** time, not mean. A 5ms query run 2,000,000 times costs more
than a 4-second report run twice a day.

**Building indexes on live tables:** use `CREATE INDEX CONCURRENTLY` (Postgres)
or the equivalent online path. A plain `CREATE INDEX` takes a lock that will stop
your application.

---

## Query optimisation

Read the plan, do not guess.

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) <your query>;
```

| In the plan | Means | Do |
|---|---|---|
| `Seq Scan` on a large table | No usable index | Add one, or accept if the table is small |
| `Rows Removed by Filter` large | Index not selective enough | Composite or partial index |
| Estimated rows far from actual | Stale statistics | `ANALYZE`; check autovacuum |
| `Nested Loop` over many rows | Bad join strategy from bad estimates | Fix statistics; consider rewriting |
| `Sort` with `external merge Disk` | Sort spilling to disk | Index the sort order, or raise `work_mem` |
| `Hash Join` with high memory | Fine, usually | Watch memory under concurrency |

**N+1 is the most common performance defect in application code**, and it is
invisible in the source — you find it in the query log for one page load, not by
reading the handler.

```
Look at: the ORM's query log for a single request.
If you see the same query shape N times with different parameters, that is it.
Fix with: eager loading (select_related / prefetch_related / with / include /
Preload / JOIN FETCH), or a dataloader for GraphQL.
```

Enable your ORM's strict mode in development so N+1 raises rather than passes:
Laravel `Model::preventLazyLoading()`, Rails `bullet`, Django
`django-debug-toolbar`, Hibernate's lazy-init exceptions.

---

## Transactions

- **Boundaries wrap the business operation**, not each individual write. A
  multi-step operation where partial state is invalid must be one transaction.
- **Never make an external HTTP call inside a transaction.** It holds a
  connection for the duration of someone else's outage and is a classic cause of
  pool exhaustion.
- Know your isolation level and what it does not prevent. Read Committed (the
  usual default) allows non-repeatable reads and does not prevent lost updates on
  read-modify-write. Use `SELECT ... FOR UPDATE`, an atomic update
  (`SET n = n - 1 WHERE n >= 1`), or a unique constraint.
- **Race conditions:** the correct fix is almost always a database constraint or
  an atomic operation, not application-level locking. Test with concurrent
  requests — this class of bug never appears in serial testing.
- Retry serialization failures with backoff, at the transaction boundary.
- Keep transactions short. Long transactions block vacuum, hold locks, and bloat.

---

## Migrations

- Versioned, in the repository, applied by the pipeline, never by hand in
  production.
- **Reversible**, with the down path tested. Where a reverse is genuinely
  impossible, document why and define the forward-fix.
- **Test against production-sized data.** A migration that takes 50ms on 1,000
  rows can take 40 minutes and an exclusive lock on 50,000,000.
- **Expand/contract for anything breaking:** add the new structure, backfill in
  batches, dual-write, migrate reads, then remove the old. Three deploys, zero
  downtime.
- Backfills run in batches with a sleep, not one statement across a whole table.
- Adding a `NOT NULL` column with a default rewrites the table on older engines —
  check what your version does before running it on a hot table.
- Separate schema migrations from data migrations.
- Migrations run as an explicit pipeline step **before** the application deploy,
  with a documented procedure for a mid-migration failure.

`references/migrations.md` has the zero-downtime patterns per operation.

---

## Multi-tenancy

Shared schema with a tenant column is the default. **Enforce it in the database**:

```sql
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON invoices
  USING (organization_id = current_setting('app.current_org')::uuid);
```

Application-only filtering means one forgotten `WHERE organization_id = ?` is a
cross-tenant breach — and that is exactly the line a tired engineer omits.
Row-level security makes the failure impossible rather than unlikely.

Watch the aggregate leaks: counts, search indexes, autocomplete, exports,
generated reports and cached fragments frequently bypass the tenant filter.

---

## Survivability — the part nobody tests

**An untested backup is not a backup.** It is a configuration that reports
success.

- [ ] Automated, scheduled, off-site, encrypted, with defined retention.
- [ ] **Point-in-time recovery** available, not just nightly snapshots — a
      nightly snapshot means up to 24 hours of data loss.
- [ ] **A restore drill performed within the last 90 days**, with the measured
      recovery time recorded. Until that has happened, recovery capability is
      unknown.
- [ ] RPO and RTO stated as numbers, and verified against the drill.
- [ ] Backups tested for *usability*, not just restorability — does the app run
      against the restored copy?
- [ ] Restore access is itself controlled and audited (a backup is a full copy of
      your data; who can download it?).
- [ ] Deletion propagates to backups per a documented, defensible policy.

Also: connection pooling sized deliberately (an app with 100 workers and a
100-connection database will exhaust it); slow-query logging on; autovacuum
monitored; replication lag alerted; disk-space alerting well before full.

---

## Reporting a database finding

State the measurement, not the impression.

```markdown
### Missing index on `invoices.organization_id` — P1

**Evidence**  EXPLAIN ANALYZE on the invoice list query:
              Seq Scan on invoices (cost=0..48210 rows=1 width=412)
                (actual time=0.03..612.4 rows=41 loops=1)
              Rows Removed by Filter: 1,284,013
**Impact**    612ms on the most-visited authenticated page, growing linearly
              with total invoice count across all tenants.
**Fix**       CREATE INDEX CONCURRENTLY idx_invoices_org
                ON invoices (organization_id, created_at DESC);
**Verify**    Re-run EXPLAIN ANALYZE; expect an Index Scan and < 5ms.
```

## References

- `references/schema-design.md` — modelling, keys, types, soft delete, audit, temporal data
- `references/indexing-and-queries.md` — index types, plan reading, engine-specific diagnostics
- `references/migrations.md` — zero-downtime patterns per operation
- `references/resilience.md` — backups, PITR, restore drills, replication, pooling
- `references/data-lifecycle.md` — retention, deletion, anonymisation, and the DSAR pipeline
