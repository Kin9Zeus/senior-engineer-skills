# Data Lifecycle — Retention, Deletion, Anonymisation

Every row should have an answer to "when does this die, and what happens when the
person it describes asks us to forget them?" A schema without those answers is a
schema that cannot honour a deletion request without a manual archaeology project.

This is the engineering half of `privacy-compliance`. That skill owns the legal
obligations; this one owns making them executable.

---

## 1. The data inventory is a schema artefact

Tag personal data at design time, in the schema itself, so the inventory is
generated rather than remembered.

```sql
COMMENT ON COLUMN users.email
  IS 'PII: identifier | purpose: account+notifications | basis: contract | retention: account_life+30d | erase: delete';
COMMENT ON COLUMN users.ip_address
  IS 'PII: online-identifier | purpose: fraud | basis: legitimate-interest | retention: 90d | erase: null';
COMMENT ON COLUMN invoices.billing_address
  IS 'PII: contact | purpose: tax-record | basis: legal-obligation | retention: 7y | erase: RETAIN-legal';
```

Then the inventory is a query, not a spreadsheet that went stale in month two:

```sql
SELECT c.table_name, c.column_name, pgd.description
FROM pg_catalog.pg_description pgd
JOIN information_schema.columns c
  ON c.ordinal_position = pgd.objsubid
 AND c.table_name = pgd.objoid::regclass::text
WHERE pgd.description LIKE 'PII:%'
ORDER BY 1, 2;
```

Add a CI check: a new column on a table that already holds personal data must
carry a classification comment, or the build fails. This is how the inventory
stays current.

---

## 2. Erasure strategy, per field

"Delete the user" is never one operation. Decide the strategy per field:

| Strategy | When | Example |
|---|---|---|
| **Hard delete** | The row exists only to describe this person | Session, notification preference, draft |
| **Null out** | The row must survive for others, the field need not | `comments.author_ip` |
| **Anonymise** | Aggregate value matters, identity does not | Replace `user_id` with a tombstone; keep the order for revenue reporting |
| **Pseudonymise** | Re-identification must remain possible under control | Replace with a token; keep the mapping in a separately-secured store |
| **Retain (justified)** | A legal obligation overrides the erasure request | Invoices for tax law; anti-fraud records |
| **Cascade** | Dependent rows die with the parent | Uploaded files, API keys, integrations |

**Retention that overrides erasure must be documented, bounded and specific.**
"We might need it" is not a basis. "Tax law requires invoice retention for seven
years" is — and it means the invoice is retained while the *account* is deleted.

---

## 3. The deletion pipeline

Deletion is a workflow with an audit trail, not a `DELETE` statement.

```
1. REQUEST      User initiates in-product (or support logs a verified request)
                → record: subject, timestamp, channel, verification method
2. VERIFY       Confirm identity (re-auth, or an emailed confirmation link)
                → never delete on an unverified request; that is a DoS vector
3. GRACE        Short reversible window (7-30 days), account suspended and
                inaccessible. Cancels on user login if you offer that.
4. EXECUTE      Run the deletion plan, transactionally per store:
                  a. application database (per-field strategy above)
                  b. object storage (uploads, avatars, exports, generated files)
                  c. caches and search indexes
                  d. queues and in-flight jobs
                  e. logs and analytics (or confirm they hold no identifiers)
                  f. every third-party processor, via their deletion API
                  g. email/marketing platforms
5. VERIFY       Re-query every store for the identifier; assert absent
6. RECORD       Write an audit entry: who, when, what strategy, which stores,
                which processors confirmed. Keep this — it is your evidence
                of compliance, and it holds no personal data beyond a hash
7. NOTIFY       Confirm completion to the subject within the legal deadline
8. BACKUPS      Backups expire on their normal cycle. Document this, and
                have a documented procedure for re-deleting if a backup is
                ever restored
```

**Step 4f is the one that gets skipped.** Every processor that received the data
must delete it too, and most have an API for it. A deletion that stops at your
own database is not a deletion — it is a partial one you have told the user was
complete.

**Step 8 is the honest one.** You cannot surgically remove one person from an
encrypted backup archive without restoring and rewriting it. The accepted
approach is: backups age out on a defined, short-enough cycle; access to backups
is restricted; and if a backup is restored, the deletion queue is replayed
against it. Document exactly this — regulators accept a documented, bounded
approach far better than a vague claim of total erasure.

---

## 4. Make it a specification, not tribal knowledge

```ts
// data-lifecycle/erasure-plan.ts — reviewed like a schema, tested like code
export const erasurePlan: ErasurePlan = {
  users:            { strategy: "anonymise",
                      fields: { email: hash, name: "[deleted]", phone: null, avatarUrl: null } },
  sessions:         { strategy: "delete" },
  api_keys:         { strategy: "delete" },
  comments:         { strategy: "anonymise", fields: { authorIp: null }, keep: ["body"] },
  invoices:         { strategy: "retain",
                      reason: "statutory tax retention",
                      until: "created_at + 7 years",
                      thenApply: "anonymise" },
  audit_log:        { strategy: "pseudonymise", fields: { actorId: tokenise } },
  uploads:          { strategy: "delete", store: "s3://user-uploads/{userId}/*" },
};

export const processors = [
  { name: "Stripe",   action: deleteStripeCustomer,   retains: "payment records, per their legal obligation" },
  { name: "Sentry",   action: scrubSentryUser },
  { name: "Postmark", action: suppressRecipient },
];
```

Two properties make this work:

**A test that fails when a new table appears.** Enumerate the tables from the
information schema, diff against the plan, fail if any table holding personal
data is unclassified. This is what keeps the plan honest as the schema grows —
without it, the plan is accurate on the day it is written and wrong within a
month.

**An end-to-end test.** Create a user, populate every table, run the erasure,
then search every store for the identifier and assert absence. This is the only
proof that the pipeline works.

---

## 5. Retention jobs

Erasure on request is one half. Retention is the other, and it is the half that
runs unattended.

```
Daily job:
  DELETE FROM sessions       WHERE expires_at   < now() - interval '7 days';
  DELETE FROM password_resets WHERE created_at  < now() - interval '1 day';
  DELETE FROM email_events   WHERE created_at   < now() - interval '90 days';
  UPDATE  request_logs SET ip_address = NULL WHERE created_at < now() - interval '90 days';
  DELETE FROM exports        WHERE created_at   < now() - interval '30 days';   -- and the files
```

- Batched, throttled, resumable — see `migrations.md`.
- **Monitored.** A retention job that silently stopped three months ago is a
  compliance finding and a storage bill.
- Deleting a row is not enough if a file, a cache entry or a search document
  survives it. Retention must cover every store.

**Data minimisation is cheaper than retention management.** The strongest control
is not collecting the field. Ask of every column: what do we do with this? If the
answer is "nothing yet", it should not exist. Every field you do not hold is one
you never have to inventory, secure, delete or disclose in a breach.

---

## 6. Export (portability)

The same inventory drives the export path, and building both together is far
cheaper than building them apart.

- Machine-readable format (JSON or CSV), structured and documented.
- Everything **about** the subject, not everything they can see. One user's
  export must not contain another user's personal data — a shared conversation
  export is the classic mistake.
- Generated asynchronously; delivered by an authenticated, expiring link — never
  a public URL, and never as an email attachment.
- The export file itself is personal data: encrypted at rest, short retention,
  and access logged.
- Rate-limited. Export generation is expensive and is an abuse vector.

---

## 7. Non-production environments

**Production data in staging is production data.** It carries every obligation,
usually with weaker controls and broader access. It is one of the most common
findings in a real privacy audit.

The correct approaches, in order of preference:
1. **Synthetic data.** Generated, realistic in shape, containing no real person.
2. **Anonymised extract.** Irreversibly transformed — not "obfuscated" by
   replacing names while keeping email, phone and postcode, which is trivially
   re-identifiable.
3. **A subset with real data**, only if the environment carries production-grade
   controls, access is restricted and audited, and the retention is short.

Whichever you choose, deletion requests must reach it too. A "forgotten" user
whose record survives in staging has not been forgotten.

---

## Review checklist

- [ ] Every personal-data column classified in the schema
- [ ] A retention period defined per table, and a job that enforces it
- [ ] The retention job is monitored, and its last successful run is visible
- [ ] An erasure plan exists as code, covering every table
- [ ] A test fails when an unclassified table is added
- [ ] The deletion pipeline reaches object storage, caches, search, logs and
      **every third-party processor**
- [ ] Deletion is verified by re-querying, and recorded in an audit trail
- [ ] The backup position is documented and defensible
- [ ] Export is scoped to the subject and delivered securely
- [ ] Non-production environments hold no unnecessary real personal data
