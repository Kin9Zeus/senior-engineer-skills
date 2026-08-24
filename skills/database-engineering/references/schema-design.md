# Schema Design

## Normalise first, denormalise with evidence

Start at third normal form. Denormalise only when a measured query problem
justifies it, and when you have decided how the copies stay consistent.

Denormalisation that is usually correct: a counter cache maintained by trigger or
transaction, a materialised view for reporting, a snapshot of values that must
be **historically immutable** — an invoice line stores the price at the time of
sale, because the product's current price is a different fact.

Denormalisation that is usually a bug: copying a mutable attribute (a user's
name, an address) into another table for convenience. Now there are two truths
and no rule about which wins.

---

## Keys

**Natural vs surrogate.** Use a surrogate key. Natural keys (email, username,
ISBN, tax id) change, get corrected, and turn out not to be unique across
jurisdictions. Keep the natural key as a `UNIQUE` constraint.

**Which surrogate:**

| Type | Pros | Cons |
|---|---|---|
| `bigserial` / auto-increment | Compact, index-friendly, ordered | Leaks volume and ordering; enumerable; painful to merge across databases |
| UUIDv4 | Unguessable, generable client-side, mergeable | Random ordering hurts index locality on a clustered PK |
| **UUIDv7 / ULID** | Unguessable *and* time-ordered — index-friendly | Slightly larger than an integer |

**Recommended:** UUIDv7 (or ULID) as the primary key for anything exposed
publicly. If you have an existing integer-keyed schema, add an opaque public
identifier column rather than migrating primary keys.

Never expose sequential ids in URLs on a multi-user system. `/orders/1043` tells
a competitor your order volume and tells an attacker exactly what to iterate.

**Composite keys** are correct for pure join tables (`(user_id, role_id)`), and
awkward everywhere else because every referencing table must carry every column.

---

## Relationships

- **One-to-many:** foreign key on the many side. Always indexed.
- **Many-to-many:** a join table with its own primary key, plus a unique
  constraint on the pair. Give it `created_at` — you will want to know when the
  relationship formed.
- **One-to-one:** usually a sign the tables should be one table. Legitimate when
  splitting rarely-accessed or differently-secured columns (a `user_secrets`
  table with different grants).
- **Polymorphic associations** (`commentable_type` + `commentable_id`) cannot
  have a foreign key, which means the database cannot protect referential
  integrity. Prefer separate join tables per type, or accept the trade-off
  knowingly.

**`ON DELETE`, chosen per relationship:**

| | Use for |
|---|---|
| `CASCADE` | Children with no independent existence — an order's line items |
| `RESTRICT` / `NO ACTION` | Anything where deletion should be prevented — a customer with invoices |
| `SET NULL` | Optional references — a task's assignee |

`CASCADE` copied everywhere is how a user deletion silently removes audit
records, financial history and other users' data.

---

## Soft delete — use it deliberately or not at all

A `deleted_at` column that half the queries forget is a data-leak vector: the
"deleted" row is still returned by the report, the export, the search index and
the raw query someone wrote last Tuesday.

If you soft-delete:
- Enforce the filter at the data-access layer, not per query.
- Or create a view (`active_users`) and grant the application access to the view,
  not the table.
- **Unique constraints break.** A deleted user with `email = x` blocks a new
  signup with the same address. Use a partial unique index:
  `CREATE UNIQUE INDEX ON users (email) WHERE deleted_at IS NULL`.
- Define when soft-deleted rows are **hard**-deleted. Soft delete is a recycle
  bin, not a retention policy — and for a GDPR deletion request it is not
  deletion at all.

Often better: move the row to an archive table, or hard-delete with an audit
record of what was deleted and by whom.

---

## Audit and history

Three levels, increasing cost:

1. **`created_at` / `updated_at` / `created_by` / `updated_by`** on every table.
   Baseline. Always do this.
2. **An audit table** capturing who changed what, when, old value and new value —
   written by a trigger, so it cannot be bypassed by a direct write. This is what
   an enterprise buyer or a regulator asks for.
3. **Full temporal tables** (system-versioned, or a history table per table)
   where you must reconstruct state at any past time.

Audit logs are append-only. Revoke `UPDATE` and `DELETE` on them from the
application role — an audit log the application can rewrite is not evidence.

**Retain personal data in audit logs deliberately.** An audit table is a common
place where deletion requests are quietly not honoured.

---

## Money, quantities and time

**Money:** `NUMERIC(19,4)` or integer minor units, plus a currency column. Never
float, at any layer — including the JSON your API returns and the JavaScript that
parses it. Store the currency with every amount; a system that assumes one
currency will be internationalised eventually.

**Rounding** is a business rule, decided once, applied consistently, and tested.
Where rounding happens in a multi-line total changes the total.

**Time:** `timestamptz` storing UTC. Convert at presentation. Store the user's
timezone if you need to render or schedule in local time — an offset is not a
timezone, because offsets change with DST. For dates without a time (birthdays,
invoice dates) use `date`, not a timestamp that shifts across zones.

**Quantities:** integers where the thing is countable. Decimals with an explicit
scale where it is measurable. Never a float for anything a user will compare for
equality.

---

## JSON columns

`jsonb` is right for genuinely schemaless data: third-party webhook payloads,
user-defined form responses, feature-flag configuration, event metadata.

It is wrong as an escape from schema design. Data in JSON has no constraints, no
foreign keys, weaker indexing and no type safety — every consumer must handle
every shape the column has ever held.

The test: **do you query it by value, join on it, or enforce rules about it?**
If yes, it is a column.

If you use JSON, add a `CHECK` validating structure where the engine supports
it, and index the paths you actually query (GIN, or an expression index).

---

## Multi-tenancy in the schema

- Tenant column on **every** table, from migration 001, including join tables.
- Row-level security enforcing it (see the main skill).
- Composite indexes lead with the tenant column: `(organization_id, created_at)`
  serves both the tenant filter and the sort.
- Unique constraints are scoped to the tenant:
  `UNIQUE (organization_id, slug)`, not `UNIQUE (slug)`.

---

## Personal data, marked at design time

Tag every column that holds personal data in the schema documentation, in a
comment, or in a dedicated metadata table:

```sql
COMMENT ON COLUMN users.email IS 'PII: identifier; basis=contract; retention=account+30d';
COMMENT ON COLUMN users.ip_address IS 'PII: online identifier; basis=legit-interest; retention=90d';
```

This becomes the data inventory `privacy-compliance` needs, and the deletion
pipeline's specification. Doing it now costs minutes per table. Doing it later
means auditing every table by hand under time pressure.

---

## Naming

Pick one convention and enforce it. The specific choice matters far less than
the consistency.

A workable default: `snake_case`; plural table names (`users`); singular column
names; `<table_singular>_id` for foreign keys (`user_id`); `is_`/`has_` for
booleans; `_at` for timestamps; `idx_<table>_<cols>` for indexes; `fk_`, `uq_`,
`ck_` prefixes for named constraints.

Name your constraints explicitly. A generated name like
`invoices_organization_id_fkey1` is what appears in the production error message
at 3am.

---

## Review checklist

- [ ] Primary key on every table
- [ ] Every foreign key has a constraint, an index, and a deliberate `ON DELETE`
- [ ] `NOT NULL` on everything the business requires
- [ ] `UNIQUE` and `CHECK` expressing real invariants
- [ ] Money is not float; timestamps are `timestamptz` in UTC
- [ ] Public identifiers are not sequential
- [ ] Tenant column present and enforced in the database
- [ ] Soft deletes filtered at the data layer; partial unique indexes where needed
- [ ] Personal-data columns tagged; retention defined per table
- [ ] Audit tables append-only from the application's role
- [ ] Naming convention consistent; constraints explicitly named
