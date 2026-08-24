# Resilience — Backups, Recovery, Availability

The only question that matters: **when did you last restore a backup, and how
long did it take?** Everything else in this document supports answering it.

An untested backup is not a backup. It is a configuration that reports success.

---

## Define the targets before the mechanism

| | Question | Typical answers |
|---|---|---|
| **RPO** — Recovery Point Objective | How much data may we lose? | Nightly snapshot = up to 24h. Continuous archiving = seconds |
| **RTO** — Recovery Time Objective | How long may we be down? | Restore a 500GB database = hours. Replica failover = minutes |

State both as numbers, agreed with whoever owns the business risk. Then **verify
them against a real drill** — an RPO on a slide is a hope; an RPO measured in a
restore is a fact.

Most teams discover in the drill that their real RTO is four to ten times their
assumed one, because nobody counted DNS propagation, application reconfiguration,
cache warming and verification.

---

## The backup stack

**Three layers, all of them:**

1. **Continuous archiving / point-in-time recovery.** WAL archiving (Postgres),
   binlog (MySQL), oplog (MongoDB). Lets you recover to any moment, including the
   second before a bad `DELETE`. Without PITR, your RPO is your snapshot
   interval.
2. **Periodic full snapshots.** Daily is typical. Retained per policy.
3. **Off-site, separately-credentialed copies.** A backup in the same account as
   the database does not survive a compromised account or an accidental
   account-level deletion. This is what protects you from ransomware and from
   your own automation.

**Properties every backup needs:**

- [ ] Automated. A manual backup is a backup that stops happening.
- [ ] Encrypted at rest, with keys managed separately from the data.
- [ ] Retention defined: daily for 30 days, weekly for 3 months, monthly for a
      year — adjusted to your obligations. Unbounded retention is a cost problem
      *and* a privacy problem.
- [ ] **Monitored.** Alert on backup *failure* and on backup *staleness*. A
      silent failure discovered during an incident is the worst case.
- [ ] Access-controlled and audited. A backup is a full copy of all your data;
      who can download it is a security question of the first order.
- [ ] Immutable / write-once where the threat model includes ransomware.

---

## The restore drill

**Schedule it. Quarterly minimum.** Put it in the calendar as an owned task, or
it does not happen.

```
1. Pick a restore point (yesterday, and a point mid-day for PITR)
2. Restore into a fresh, isolated environment — never over anything real
3. TIME IT. Record wall-clock from decision to usable database
4. Verify integrity: row counts on key tables, referential integrity,
   the most recent transactions present
5. Point a copy of the application at it and exercise the critical journeys
6. Record: date, restore point, measured RTO, measured RPO, what broke
7. Fix what broke. Repeat next quarter
```

**What drills reliably discover:** the backup does not include a critical table;
extensions or roles are missing; the restore needs a credential nobody has;
required parameters differ; the process takes far longer than assumed; the
person who set it up has left; the runbook references a tool that was
decommissioned.

Every one of those is cheap to find in a drill and catastrophic to find in an
incident.

---

## Replication and failover

Replicas give you read scaling and fast failover. They are **not** backups —
replication faithfully replicates a `DROP TABLE` in milliseconds.

- Synchronous replication: zero data loss, higher write latency. Asynchronous:
  lower latency, a window of loss on failover. Choose deliberately.
- **Alert on replication lag.** A replica hours behind is not a failover target,
  and stale reads from it are a correctness bug.
- **Practise failover.** An untested failover has an unknown recovery time and
  frequently a broken step.
- Beware read-after-write on replicas: a user updates their profile, is served
  from a lagging replica, and sees the old value. Route reads after a write to
  the primary for a bounded window.
- Automatic failover needs fencing, or you get split-brain — two primaries
  accepting writes, and a manual data reconciliation afterwards.

---

## Protecting against the human

Most data loss is not hardware. It is a `DELETE` without a `WHERE`, a migration
run against the wrong environment, or a script with a wrong argument.

- **Separate credentials per environment**, visually distinct connection
  prompts, and a production role that cannot `DROP`.
- **Grant the application the minimum:** it rarely needs `DROP`, `CREATE ROLE`,
  or superuser. A compromised application credential should not be able to
  destroy the schema.
- **Guard rails on destructive operations:** `--i-am-sure` flags, typed
  confirmations, transaction wrapping so `ROLLBACK` is available.
- **PITR is the antidote** to accidental deletion — but only if you notice within
  the retention window. Alert on anomalous row-count drops.
- Restrict production database access to a small, audited group, ideally through
  a bastion or an audited proxy that logs statements.

---

## Availability under load

**Connection pooling** — see `indexing-and-queries.md`. Pool exhaustion is the
most common "the database is down" that is not the database.

**Timeouts, all three:**
```sql
statement_timeout = '30s'                      -- no query runs forever
idle_in_transaction_session_timeout = '60s'    -- no transaction holds locks forever
lock_timeout = '3s'                            -- for migrations
```
The middle one prevents the classic incident: a transaction opened, an external
HTTP call inside it, the third party hangs, locks are held, everything queues.

**Read replicas** for reporting and analytics, so a heavy query cannot degrade
the transactional path.

**Rate limits and query cost limits** at the application layer — an unbounded
`limit` parameter or an unpaginated export is a self-inflicted denial of service.

**Graceful degradation:** what does the application do when the database is
unreachable? Return a clear 503, not a stack trace or a hang. Circuit-break so
a database outage does not exhaust every application thread.

---

## Monitoring — the minimum set

| Metric | Alert when |
|---|---|
| Backup success and age | Failed, or older than the schedule + margin |
| Replication lag | Above your read-consistency tolerance |
| Connection pool utilisation | Above ~80% sustained |
| Disk space / IOPS | Below 20% free, or credits exhausting |
| Slow query count | Above baseline |
| Deadlocks / lock waits | Any sustained increase |
| Cache hit ratio | Below ~0.99 on OLTP |
| Dead tuples / vacuum age | Bloat growing, or transaction wraparound approaching |
| Error rate by class | Any connection-refused or timeout increase |

Transaction ID wraparound in Postgres deserves a specific mention: it is rare,
preventable and catastrophic — the database refuses writes until it is resolved.
Monitor `age(datfrozenxid)` and let autovacuum do its job.

---

## The runbook

Write it before you need it. In the repository, not in someone's memory.

```markdown
# Runbook — database recovery

## Total loss / corruption
1. Declare the incident; post to <channel>; assign a lead
2. Stop writes: <exact command to put the app in maintenance mode>
3. Identify the restore point: <how to determine the last-good moment>
4. Restore: <exact commands, with the credential location>
5. Verify: <the specific queries that confirm integrity>
6. Reconfigure the application: <where the connection string lives>
7. Resume traffic; monitor <these metrics> for <this long>
8. Post-incident: what was lost, who must be notified, within what deadline

## Accidental deletion (data still recoverable via PITR)
...

## Primary failure (failover)
...

Measured RTO at last drill: <n> minutes, <date>
Escalation: <name>, then <name>
```

A runbook that has never been executed is a draft. Run it during the drill and
correct it.

---

## Review checklist

- [ ] Automated backups, encrypted, off-site, with defined retention
- [ ] Point-in-time recovery available
- [ ] Backup failure and staleness alerted
- [ ] **A restore drill completed in the last 90 days, with a measured RTO**
- [ ] RPO and RTO stated as numbers and verified
- [ ] Backup access controlled and audited
- [ ] Replication lag monitored and alerted
- [ ] Failover practised
- [ ] `statement_timeout` and `idle_in_transaction_session_timeout` set
- [ ] Application role has least privilege
- [ ] Production access restricted and audited
- [ ] A written recovery runbook that has actually been executed
