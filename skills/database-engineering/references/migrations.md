# Migrations

A migration is code that runs once, in production, against irreplaceable data,
usually while the application is serving traffic. Treat it with more care than
the feature it enables — not less.

---

## Non-negotiables

- Versioned, committed, applied by the pipeline. **Never by hand in production.**
- Reviewed like any other code, and reviewed by someone who reads the lock
  implications.
- **Reversible**, with the down path actually tested. Where reversal is genuinely
  impossible (a dropped column), say so in a comment and define the forward-fix
  instead.
- **Tested against a production-sized copy.** Row count changes migration
  behaviour by orders of magnitude.
- Never edited after merge. A migration that has run somewhere is immutable;
  correct it with a new migration.
- One logical change per migration.
- Schema migrations separate from data migrations.

---

## Locks — the thing that causes the outage

Most migration incidents are not slow migrations. They are a migration taking a
lock, a queue of blocked queries building behind it, and the connection pool
exhausting within seconds.

**Rules that prevent it:**

1. **Set a lock timeout** so the migration fails fast instead of blocking the
   application:
   ```sql
   SET lock_timeout = '3s';
   SET statement_timeout = '30s';
   ```
   A migration that cannot get its lock in three seconds should abort and be
   retried, not queue behind a long-running query while everything else queues
   behind it.

2. **Know what your engine version does** for each operation. Behaviour differs
   substantially between versions — check the documentation for the version you
   actually run rather than assuming. Historically dangerous operations include
   adding a column with a volatile default, changing a column type, and adding a
   constraint that requires validating existing rows.

3. **Two-step the validating operations.** Where the engine supports it, add the
   constraint as `NOT VALID` (which takes a brief lock), then `VALIDATE
   CONSTRAINT` separately (which takes a weaker lock and can run long):
   ```sql
   ALTER TABLE orders ADD CONSTRAINT orders_total_positive
     CHECK (total >= 0) NOT VALID;
   ALTER TABLE orders VALIDATE CONSTRAINT orders_total_positive;
   ```

4. **Indexes go on concurrently.** `CREATE INDEX CONCURRENTLY` (Postgres),
   `ALGORITHM=INPLACE, LOCK=NONE` (MySQL). It cannot run inside a transaction,
   so it needs its own migration, and a failure leaves an invalid index that must
   be dropped.

5. **Never `ALTER` a hot table inside a long transaction.** The lock is held for
   the whole transaction, not just the statement.

---

## Expand / contract — the zero-downtime pattern

Any breaking change becomes three safe deploys.

```
EXPAND    Add the new thing. Old and new code both work.
MIGRATE   Backfill in batches. Dual-write. Move reads to the new thing.
CONTRACT  Remove the old thing, once nothing references it.
```

### Renaming a column

```
1. Add `new_name`, nullable                              (deploy)
2. Write to both columns in application code             (deploy)
3. Backfill `new_name` from `old_name` in batches        (migration)
4. Read from `new_name`                                  (deploy)
5. Stop writing `old_name`                               (deploy)
6. Drop `old_name`                                       (migration)
```

Six steps for a rename. That is the price of not taking the site down, and it is
worth paying on any table that matters.

### Adding a required column

```
1. Add nullable, with a default for new rows
2. Backfill existing rows in batches
3. Add NOT NULL as NOT VALID, then VALIDATE
```

### Changing a column type

Treat as a rename: add a new column of the new type, dual-write, backfill,
switch reads, drop.

### Splitting or merging tables

Same shape, at table granularity. Dual-write through a repository method so the
application has one place that knows about the transition.

---

## Backfills

Never `UPDATE` an entire large table in one statement. It takes a long lock,
generates enormous WAL, and blocks vacuum.

```sql
-- Batched, resumable, interruptible
DO $$
DECLARE
  rows_updated integer;
BEGIN
  LOOP
    UPDATE users SET display_name = first_name || ' ' || last_name
    WHERE id IN (
      SELECT id FROM users WHERE display_name IS NULL LIMIT 1000 FOR UPDATE SKIP LOCKED
    );
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    EXIT WHEN rows_updated = 0;
    COMMIT;
    PERFORM pg_sleep(0.1);          -- let replication and vacuum keep up
  END LOOP;
END $$;
```

Properties that matter: **batched** (bounded lock duration), **resumable** (the
`WHERE` clause finds the remaining work, so a restart is safe), **throttled**
(replicas keep up), and **observable** (log progress so a four-hour backfill is
not a black box).

For very large backfills, run them as a background job rather than a migration.
A migration that takes hours blocks your deploy pipeline and cannot be monitored
properly.

---

## Migrations in the deploy pipeline

Order matters, and it is decided by which direction is compatible.

```
Additive change (new column, new table, new index):
  migrate  →  then deploy code                 (old code ignores the new thing)

Destructive change (drop column, drop table):
  deploy code  →  then migrate                 (new code stops using it first)
```

Requirements:
- Migrations run as an **explicit, separate pipeline step**, not on application
  boot. Boot-time migration means N instances racing to migrate simultaneously.
- A documented procedure for a mid-migration failure — what state is the
  database in, and what does the on-call engineer do?
- **Migrations must be backward-compatible with the currently running code**,
  because during a rolling deploy both versions run at once.
- A pre-deploy check that verifies no pending migration is incompatible with the
  running version.

---

## Testing a migration

- [ ] Runs clean on an empty database (a fresh developer setup)
- [ ] Runs clean on a **restored production-sized copy**
- [ ] The down migration runs and returns the schema to the previous state
- [ ] Up → down → up leaves a correct schema
- [ ] Measured duration on production-sized data, with the lock profile observed
- [ ] The application's previous version still works against the new schema
- [ ] Data integrity verified after the fact (row counts, spot checks,
      constraint validation)

The single most valuable habit here: **restore a recent production backup into a
scratch environment and run the migration against it.** It takes twenty minutes
and it catches the migration that would have locked a table for forty.

---

## Framework specifics

**Prisma** — `migrate dev` for development, `migrate deploy` for production
(never `db push` against production). Review the generated SQL before committing;
the generator does not know about lock implications.

**Django** — `makemigrations --check --dry-run` in CI catches models drifting
from migrations. Watch for merge conflicts producing multiple leaf nodes.
`RunPython` needs a `reverse_code` to be reversible.

**Rails** — `strong_migrations` gem flags dangerous operations and suggests the
safe alternative. Worth adding on day one. `disable_ddl_transaction!` for
concurrent index creation.

**Laravel** — migrations run in a transaction by default on engines that support
transactional DDL. Keep them small.

**Flyway / Liquibase / Alembic** — checksums prevent editing an applied
migration. Do not override the check; write a new migration.

**Golang-migrate / sql-migrate** — plain SQL, which is honest. You are
responsible for the lock discipline yourself.

---

## Red flags in review

- No down migration, and no comment explaining why
- `ALTER TABLE` on a large table with no lock timeout
- `CREATE INDEX` without `CONCURRENTLY` on a live table
- An unbatched `UPDATE` or `DELETE` across a whole table
- A data migration mixed into a schema migration
- Anything that runs on application boot
- A migration that has been edited after merge
- A drop of a column or table that current code still references
- No stated expectation of how long it takes on production data
