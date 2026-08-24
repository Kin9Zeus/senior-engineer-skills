# The Rights Pipeline — Export and Deletion

The user asked for deletion to be **as automated as possible**. That is also the
right engineering answer: manual handling is slow, error-prone, unauditable, and
collapses under volume. Build it once, and every subsequent request costs
nothing.

---

## Surface: make it findable

A right nobody can find is a right nobody has. Regulators check this.

```
Settings → Privacy & data
├── Download my data          → export flow
├── Delete my account         → deletion flow
├── Cookie preferences        → consent settings
└── Privacy policy            → the document
```

Requirements: reachable in **three clicks or fewer** from anywhere in the
product; linked from the privacy policy and the footer; available to users who
signed up with SSO; and available (via a verified route) to people who no longer
have an account.

For mobile apps, both major stores now require an in-app account-deletion path
for apps that allow account creation, plus a web-accessible route. Verify the
current requirement against the store's live policy — it is enforced at review,
and a missing path gets the app rejected.

---

## Endpoints

```
POST   /api/privacy/export              request an export      → 202 + job id
GET    /api/privacy/export/:id          status / download link
POST   /api/privacy/delete              request deletion       → 202
POST   /api/privacy/delete/confirm      confirm with token     → 202
POST   /api/privacy/delete/cancel       cancel within grace    → 200
GET    /api/privacy/status              pending requests + deadlines
```

All authenticated. All rate-limited. All logged to an audit trail.

---

## Deletion

### The flow

```
1. REQUEST    Authenticated user initiates in-product
2. VERIFY     Re-authenticate (password or MFA), or confirm by emailed token.
              NEVER delete on an unverified request — it is a denial-of-service
              vector against your own users
3. GRACE      7-30 days. Account suspended and inaccessible, not yet erased.
              Email the user: what will be deleted, what is retained and why,
              when it happens, how to cancel
4. EXECUTE    Run the erasure plan across every store (below)
5. VERIFY     Re-query every store for the identifier; assert absent
6. RECORD     Audit entry — no personal data beyond a hash of the identifier
7. NOTIFY     Confirm completion within the statutory deadline (GDPR: one month,
              extendable by two with an explanation)
```

### The erasure plan as code

```ts
// privacy/erasure-plan.ts — reviewed like a schema, tested like code
export const plan: ErasurePlan = {
  users:        { strategy: "anonymise",
                  fields: { email: sha256, name: "[deleted]", phone: null,
                            avatarUrl: null, lastLoginIp: null } },
  sessions:     { strategy: "delete" },
  api_keys:     { strategy: "delete" },
  oauth_grants: { strategy: "delete" },
  comments:     { strategy: "anonymise", fields: { authorIp: null }, keep: ["body"] },
  orders:       { strategy: "anonymise", fields: { userId: TOMBSTONE },
                  reason: "revenue reporting requires the transaction, not the identity" },
  invoices:     { strategy: "retain",
                  reason: "statutory tax retention",
                  until: "created_at + 7 years",
                  thenApply: "anonymise" },
  audit_log:    { strategy: "pseudonymise", fields: { actorId: tokenise } },
  uploads:      { strategy: "delete", store: "s3://uploads/{userId}/*" },
};

export const processors: ProcessorErasure[] = [
  { name: "Stripe",   fn: deleteStripeCustomer,
    note: "retains payment records under its own legal obligation" },
  { name: "Postmark", fn: suppressRecipient },
  { name: "Sentry",   fn: scrubSentryUser },
  { name: "PostHog",  fn: deletePostHogPerson },
  { name: "Intercom", fn: deleteIntercomContact },
];
```

### The fan-out — every store, not just the database

| Store | Action | Commonly missed |
|---|---|---|
| Application database | Per-field strategy | — |
| Object storage | Delete the prefix | Thumbnails, generated derivatives, old exports |
| Cache | Evict by key pattern | Cached rendered fragments |
| Search index | Delete the document | The index is a separate copy |
| Queues | Cancel or drain in-flight jobs | A queued email sends after deletion |
| Logs | Redact or let retention expire | Frequently holds IPs and emails |
| Error tracker | Scrub user context | Sentry/Bugsnag hold user records |
| Analytics | Delete via API | Most providers offer a person-delete endpoint |
| Email/marketing | Delete or suppress | A deleted user receiving a campaign is the visible failure |
| **Every other processor** | Their deletion API | **This is the step that gets skipped** |
| Backups | Age out on the normal cycle | Document honestly |

**The processors step is the one that gets skipped.** Deletion that stops at your
own database is a partial deletion you told the user was complete.

### Backups — the honest position

You cannot surgically remove one person from an encrypted backup archive without
restoring and rewriting it, which is neither practical nor safe.

The defensible position, and the one to write down:

> Backups are retained for 30 days and are then permanently destroyed. Access to
> backups is restricted and logged. If a backup is ever restored, pending
> deletion requests are replayed against the restored data before it returns to
> service.

Implement the replay — a queue of completed erasures, kept for longer than the
backup retention, that runs automatically after any restore. Then the statement
is true.

### Implementation sketch

```ts
export async function executeErasure(userId: string, requestId: string) {
  const audit = { requestId, userId: sha256(userId), startedAt: new Date(),
                  steps: [] as StepResult[] };

  await db.transaction(async (tx) => {
    for (const [table, rule] of Object.entries(plan)) {
      audit.steps.push(await applyRule(tx, table, rule, userId));
    }
  });

  audit.steps.push(await deletePrefix(`s3://uploads/${userId}/`));
  audit.steps.push(await evictCache(`user:${userId}:*`));
  audit.steps.push(await searchIndex.delete({ userId }));
  audit.steps.push(await cancelQueuedJobs({ userId }));

  // Processors: never let one failure abort the rest
  for (const p of processors) {
    try   { await p.fn(userId); audit.steps.push({ name: p.name, ok: true }); }
    catch (e) { audit.steps.push({ name: p.name, ok: false, error: String(e) });
                await alertPrivacyTeam(p.name, requestId, e); }
  }

  // Verify, do not assume
  const remaining = await findAnywhere(userId);
  audit.verified = remaining.length === 0;
  audit.remaining = remaining;

  await writeAuditRecord(audit);
  if (!audit.verified) throw new IncompleteErasureError(audit);
}
```

Three properties that matter: **idempotent** (safe to re-run), **verified**
(re-query rather than assume), and **audited** (the record is your evidence of
compliance, and it contains no personal data beyond a hash).

---

## Export (portability)

Same inventory, same pipeline. Build them together — the second one is nearly
free once the first exists.

```json
{
  "exported_at": "2026-08-24T16:18:12Z",
  "subject": { "id": "usr_01HQ8", "email": "user@example.com" },
  "format_version": "1.0",
  "data": {
    "profile":  { "name": "...", "created_at": "..." },
    "orders":   [ { "id": "...", "total": 4900, "currency": "USD", "items": [] } ],
    "comments": [ { "id": "...", "body": "...", "created_at": "..." } ],
    "files":    [ { "name": "photo.jpg", "size": 204800, "path": "files/photo.jpg" } ]
  },
  "notes": {
    "retained_elsewhere": "Payment records held by Stripe under their own retention policy",
    "not_included": "Content authored by other users in shared threads"
  }
}
```

**Rules:**
- Machine-readable, structured, documented.
- **Everything about the subject, not everything they can see.** A shared
  conversation export containing other users' messages is a data breach dressed
  as a rights request. This is the classic mistake.
- Include uploaded files in a ZIP alongside the JSON.
- Generated **asynchronously** — a large export will time out inline.
- Delivered by an **authenticated, expiring link**. Never a public URL, never an
  email attachment.
- **The export file is personal data**: encrypted at rest, retention of days not
  months, access logged, and deleted after download or expiry.
- **Rate-limited.** Export generation is expensive and is an abuse vector.

---

## Requests from people without an account

Not everyone with data in your systems is a current user: former users,
newsletter subscribers, people who filled in a form, people mentioned in someone
else's content.

Provide a route — a public form, or `privacy@yourdomain` — and **verify identity
proportionately**. Enough to be confident, not so much that you collect *more*
personal data to process a privacy request, which is its own problem.

Log these with their statutory deadline and alert before it expires. A missed
deadline is the most common enforcement trigger and it is entirely avoidable
with a due-date reminder.

---

## Testing

```ts
describe("erasure", () => {
  it("has a rule for every table", async () => {
    // The test that keeps the plan honest as the schema grows.
    // Without it the plan is correct on the day it is written and wrong in a month.
    const tables = await listTables();
    expect(tables.filter((t) => !plan[t] && !EXEMPT.includes(t))).toEqual([]);
  });

  it("removes the subject from every store", async () => {
    const user = await seedUserWithDataEverywhere();
    await executeErasure(user.id, "req_test");

    expect(await findAnywhere(user.id)).toEqual([]);
    expect(await searchIndex.find(user.email)).toEqual([]);
    expect(await s3.list(`uploads/${user.id}/`)).toEqual([]);
    expect(await cache.keys(`user:${user.id}:*`)).toEqual([]);
  });

  it("retains legally-required records with an expiry", async () => {
    const user = await seedUserWithInvoice();
    await executeErasure(user.id, "req_test");
    const invoice = await db.invoice.findFirst({ where: { id: user.invoiceId } });
    expect(invoice).not.toBeNull();
    expect(invoice.customerName).toBe("[deleted]");
    expect(invoice.retentionExpiresAt).toBeDefined();
  });

  it("is idempotent", async () => {
    const user = await seedUser();
    await executeErasure(user.id, "req_1");
    await expect(executeErasure(user.id, "req_2")).resolves.not.toThrow();
  });

  it("does not include other users' data in an export", async () => {
    const { alice, bob } = await seedSharedThread();
    const exported = await buildExport(alice.id);
    expect(JSON.stringify(exported)).not.toContain(bob.email);
  });
});
```

The **first test is the load-bearing one.** It fails when someone adds a table
without deciding what happens to it on erasure, which is exactly the moment the
decision is cheap to make.

---

## Monitoring

| Metric | Alert |
|---|---|
| Open requests approaching the statutory deadline | 7 days before |
| Erasure jobs failing | Any |
| Processor deletion API failures | Any |
| Verification finding remaining data | Any — this is a `P0` |
| Retention jobs not run | Any missed window |
| Time from request to completion | Trending toward the deadline |

A retention or erasure job that silently stopped is both a compliance finding
and, eventually, a breach-notification problem. Monitor it like a payment
pipeline.
