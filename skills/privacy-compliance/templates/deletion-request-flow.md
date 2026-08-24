# Self-Service Deletion — Implementation Spec

A working specification for the automated deletion path. Adapt the stack, keep
the guarantees.

---

## User-facing flow

```
Settings → Privacy & data → Delete my account
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│  Delete your account                                         │
│                                                              │
│  This will permanently delete:                               │
│   · your profile, settings and preferences                   │
│   · your <42> uploaded files (<1.2 GB>)                      │
│   · your <18> projects and all their contents                │
│   · your data held by our providers: Stripe, Postmark,       │
│     Sentry, PostHog  (see our privacy policy)                │
│                                                              │
│  We are required to keep:                                    │
│   · invoices, for 7 years (tax law), with your personal      │
│     details minimised                                        │
│                                                              │
│  You have 30 days to change your mind. After that this       │
│  cannot be undone.                                           │
│                                                              │
│  [ Download my data first ]   ← always offer this            │
│                                                              │
│  Type DELETE to confirm:  [__________]                       │
│  Enter your password:     [__________]                       │
│                                                              │
│  [ Cancel ]                      [ Delete my account ]       │
└─────────────────────────────────────────────────────────────┘
        │
        ▼
   Email confirmation → 30-day grace → automated erasure → verification
        → confirmation email
```

**Design requirements**
- Reachable in **≤ 3 clicks** from anywhere in the product.
- **Show what will actually be deleted, with counts.** Generated from the data,
  not hardcoded — it is honest, and it forces the counts to be correct.
- **Show what is retained, and why.** Surprising a user later is worse than
  telling them now.
- **Offer the export first.** Most people who delete want their data.
- Typed confirmation plus re-authentication. Not a single button.
- No dark patterns: no guilt copy, no hidden cancel, no multi-step maze. If the
  flow to delete is harder than the flow to sign up, that is a finding.

---

## Endpoints

```
POST   /api/privacy/delete            initiate    → 202, sends confirmation email
POST   /api/privacy/delete/confirm    token       → 202, starts the grace period
POST   /api/privacy/delete/cancel     within grace → 200, restores the account
GET    /api/privacy/delete/status     → { state, scheduled_for, cancellable }
```

All authenticated, all rate-limited, all written to an audit trail.

---

## State machine

```
active ──request──► pending_confirmation ──confirm──► scheduled ──T+30d──► erasing
                            │                             │                   │
                          expires                       cancel              verify
                            ▼                             ▼                   ▼
                          active                       active              erased
                                                                              │
                                                                        (failure)
                                                                              ▼
                                                                    failed → alert
```

`failed` must page a human. A deletion that silently did not complete is a
compliance failure with a statutory deadline attached.

---

## Server

```ts
// POST /api/privacy/delete
export async function requestDeletion(req: Request, res: Response) {
  const user = req.session.user;

  // 1. Re-authenticate. Never delete on an unverified request.
  if (!(await verifyPassword(user.id, req.body.password))) {
    await audit("deletion.request_failed", { userId: user.id, reason: "bad_password" });
    return res.status(401).json({ error: { code: "auth.invalid_password" } });
  }
  if (req.body.confirmation !== "DELETE") {
    return res.status(422).json({ error: { code: "confirmation.mismatch" } });
  }

  // 2. Refuse where an obligation genuinely blocks it, and say why.
  const blockers = await deletionBlockers(user.id);   // e.g. an open dispute
  if (blockers.length) {
    return res.status(409).json({ error: { code: "deletion.blocked", details: blockers } });
  }

  // 3. Single-use, hashed, short-lived confirmation token.
  const token = randomToken(32);
  await db.deletionRequest.create({
    data: {
      userId: user.id,
      tokenHash: sha256(token),
      state: "pending_confirmation",
      expiresAt: addHours(new Date(), 24),
      requestedIp: hashIp(req.ip),
      requestedAt: new Date(),
    },
  });

  await sendEmail(user.email, "confirm-deletion", {
    url: `${config.APP_URL}/privacy/delete/confirm?token=${token}`,
    graceDays: 30,
  });

  await audit("deletion.requested", { userId: user.id });
  return res.status(202).json({ status: "confirmation_sent" });
}
```

```ts
// POST /api/privacy/delete/confirm
export async function confirmDeletion(req: Request, res: Response) {
  const request = await db.deletionRequest.findFirst({
    where: { tokenHash: sha256(req.body.token), state: "pending_confirmation",
             expiresAt: { gt: new Date() } },
  });
  if (!request) return res.status(400).json({ error: { code: "token.invalid_or_expired" } });

  const scheduledFor = addDays(new Date(), 30);

  await db.$transaction([
    db.deletionRequest.update({ where: { id: request.id },
      data: { state: "scheduled", confirmedAt: new Date(), scheduledFor } }),
    db.user.update({ where: { id: request.userId },
      data: { status: "suspended", suspendedReason: "pending_deletion" } }),
    db.session.deleteMany({ where: { userId: request.userId } }),   // sign out everywhere
    db.apiKey.updateMany({ where: { userId: request.userId },
      data: { revokedAt: new Date() } }),
  ]);

  await enqueue("erasure.execute", { requestId: request.id }, { runAt: scheduledFor });
  await sendEmail(request.userEmail, "deletion-scheduled", { scheduledFor });
  await audit("deletion.confirmed", { userId: request.userId, scheduledFor });

  return res.status(202).json({ status: "scheduled", scheduledFor });
}
```

---

## The erasure job

The full implementation is in `references/rights-pipeline.md`. The properties
that matter:

| Property | Why |
|---|---|
| **Idempotent** | Retries are guaranteed; a partial run must be safely resumable |
| **Ordered** | Database first (inside a transaction), then external stores, then processors |
| **Fault-isolated** | One processor's API failing must not abort the rest — record it and alert |
| **Verified** | Re-query every store for the identifier and assert absence. Never assume |
| **Audited** | A record of who, when, which stores, which processors confirmed — containing no personal data beyond a hash |
| **Alerting** | Any failure, and any verification finding remaining data, pages a human |

---

## Tests

```ts
it("requires re-authentication", async () => {
  const res = await api.post("/api/privacy/delete")
    .auth(user).send({ password: "wrong", confirmation: "DELETE" });
  expect(res.status).toBe(401);
  expect(await db.deletionRequest.count()).toBe(0);
});

it("cannot be triggered by another user", async () => {
  const res = await api.post("/api/privacy/delete").auth(otherUser)
    .send({ userId: victim.id, password: otherUser.password, confirmation: "DELETE" });
  // The user id must come from the session, never from the body
  expect(await db.deletionRequest.findFirst({ where: { userId: victim.id } })).toBeNull();
});

it("removes the subject from every store", async () => {
  const u = await seedUserWithDataEverywhere();
  await runErasure(u.id);
  expect(await findAnywhere(u.id)).toEqual([]);
  expect(await s3.list(`uploads/${u.id}/`)).toEqual([]);
  expect(await searchIndex.find(u.email)).toEqual([]);
  expect(await cache.keys(`user:${u.id}:*`)).toEqual([]);
});

it("calls every processor's deletion API", async () => {
  const spies = processors.map((p) => jest.spyOn(p, "fn"));
  await runErasure(user.id);
  spies.forEach((s) => expect(s).toHaveBeenCalledWith(user.id));
});

it("retains legally-required records with an expiry", async () => {
  await runErasure(user.id);
  const invoice = await db.invoice.findFirst({ where: { id: user.invoiceId } });
  expect(invoice).not.toBeNull();
  expect(invoice.customerName).toBe("[deleted]");
  expect(invoice.retentionExpiresAt).toBeDefined();
});

it("is idempotent", async () => {
  await runErasure(user.id);
  await expect(runErasure(user.id)).resolves.not.toThrow();
});

it("has an erasure rule for every table", async () => {
  // The load-bearing test: it fails when someone adds a table without deciding
  // what happens to it on erasure — exactly when that decision is cheap.
  const tables = await listTables();
  expect(tables.filter((t) => !erasurePlan[t] && !EXEMPT.includes(t))).toEqual([]);
});
```

---

## Monitoring

| Signal | Alert |
|---|---|
| Erasure job failed | Immediately — page |
| Verification found remaining data | Immediately — page. This is a `P0` |
| A processor's deletion API failed | Immediately |
| A request approaching the statutory deadline | 7 days before |
| Requests stuck in `pending_confirmation` | Daily digest — may indicate email delivery problems |
| Time from request to completion | Trending toward the deadline |

---

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| "Email us to delete your account" | Not self-service; misses the automation requirement and does not scale |
| Deleting without verification | A denial-of-service vector against your own users |
| Setting `deleted_at` and calling it done | The data is still there, still queryable, still in the export, still in the breach |
| Stopping at your own database | Processors still hold the data; the deletion you confirmed did not happen |
| Assuming success without verifying | You cannot demonstrate compliance from an assumption |
| Making deletion harder than signup | A dark pattern, and specifically cited by regulators |
| No grace period | Accidental and coerced deletions become unrecoverable |
| An unbounded grace period | "Suspended" indefinitely is not deletion |
| No audit record | You cannot prove you honoured the request |
| Silent failure | The worst case: the user was told it was done, and it was not |
