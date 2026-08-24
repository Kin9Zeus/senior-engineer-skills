# Authorization Patterns

Authentication asks *who are you*. Authorization asks *may you do this, to this
specific object, right now*. Almost every serious access-control bug is a system
that got the first right and the second wrong.

The goal is not "add checks". The goal is **an architecture where forgetting the
check is impossible or immediately visible**.

---

## The failure that keeps happening

```ts
// Authenticated. Not authorised.
app.get("/api/invoices/:id", requireAuth, async (req, res) => {
  const invoice = await db.invoice.findUnique({ where: { id: req.params.id } });
  res.json(invoice);                       // any user can read any invoice
});
```

It passes every manual test, because a developer only ever tests with their own
data. It is found by an attacker in minutes, and by an auditor in one request.

```ts
// Authorised — the ownership predicate is in the query.
app.get("/api/invoices/:id", requireAuth, async (req, res) => {
  const invoice = await db.invoice.findFirst({
    where: { id: req.params.id, organizationId: req.session.organizationId },
  });
  if (!invoice) return res.status(404).end();   // 404, not 403 — see below
  res.json(invoice);
});
```

**Return 404, not 403,** for objects the caller may not see. A 403 confirms the
resource exists, which leaks the existence of other users' data and enables
enumeration. Reserve 403 for "you know this exists and may not act on it".

---

## Choose a model deliberately

| Model | Shape | Fits |
|---|---|---|
| **RBAC** | User has roles; roles grant permissions | Most applications. Start here |
| **ReBAC** | Permission derives from a relationship (owner of, member of, shared with) | Documents, projects, collaboration |
| **ABAC** | Rules over attributes of subject, object, action and context | Complex conditional policy |
| **Ownership-only** | Every row has a user or tenant id, and that is the whole model | Simple single-user-scoped products |

Most real products are **RBAC scoped by tenancy, plus ReBAC for sharing**. Do not
build a policy engine before you have a policy problem — but do put every check
behind one function from day one, so the model can change in one place.

---

## Pattern 1 — Deny by default at the router

The single highest-leverage decision. A route that forgets to declare a policy
must **fail closed**, loudly, ideally at startup.

```ts
type Policy = "public" | "authenticated" | ((ctx: Ctx) => Promise<boolean>);

const routes = [
  { method: "GET",  path: "/health",            policy: "public" },
  { method: "GET",  path: "/api/invoices/:id",  policy: canReadInvoice },
  { method: "POST", path: "/api/invoices",      policy: canCreateInvoice },
];

// At boot: every registered handler must appear in this table.
// A route without a policy throws before the server accepts traffic.
assertEveryRouteHasAPolicy(app, routes);
```

Compare with the common alternative — middleware applied by path prefix — which
fails open the moment someone adds a route under a prefix nobody remembered to
protect.

**Framework equivalents:** NestJS global guard with an explicit `@Public()`
opt-out; Django's `LoginRequiredMiddleware` plus per-view object checks; Rails
`before_action :authorize!` in `ApplicationController` with an explicit skip;
ASP.NET `[Authorize]` as the fallback policy.

---

## Pattern 2 — One authorization function

Every check goes through one call. Never inline `if (user.role === "admin")`
scattered through handlers — that is a policy you cannot audit, test or change.

```ts
// platform/authz.ts — the only place policy lives
export async function authorize(
  actor: Actor,
  action: Action,          // "invoice:read" | "invoice:void" | "member:invite"
  resource: Resource,
): Promise<void> {
  const allowed = await can(actor, action, resource);
  if (!allowed) {
    log.warn({ actor: actor.id, action, resource: resource.id }, "authz.denied");
    throw new NotFoundError();        // 404 by default; 403 when existence is known
  }
}
```

Benefits that compound: one place to add logging, one place to add caching, one
place to test exhaustively, and a grep that finds every authorization decision in
the codebase.

---

## Pattern 3 — Push the predicate into the query

The most reliable authorization is the kind the database enforces, because it
cannot be skipped by a code path you forgot.

```ts
// Fragile: fetch, then check. Correct today, wrong the first time
// someone adds an early return above the check.
const doc = await db.document.findUnique({ where: { id } });
await authorize(user, "document:read", doc);

// Robust: the scope is the query. There is no unauthorised result to leak.
const doc = await db.document.findFirst({
  where: { id, OR: [{ ownerId: user.id }, { shares: { some: { userId: user.id } } }] },
});
```

**Strongest form — row-level security.** Enforce tenancy in the database so that
a forgotten `WHERE tenant_id = ?` cannot leak data:

```sql
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON invoices
  USING (organization_id = current_setting('app.current_org')::uuid);
```

The application sets `app.current_org` once per request from the session. Every
query is then scoped by the database, including the ones written months later by
someone who did not know the rule. For multi-tenant SaaS this is the difference
between "we try to filter correctly" and "we cannot fail to".

---

## Pattern 4 — Explicit field allowlists

Mass assignment is access control at the field level.

```ts
// Vulnerable — the client decides what it can set
await db.user.update({ where: { id }, data: req.body });   // { role: "admin" }

// Correct — the server decides
const input = UpdateUserSchema.pick({ name: true, avatarUrl: true }).parse(req.body);
await db.user.update({ where: { id }, data: input });
```

Fields that must **never** be settable from a request body: `role`, `isAdmin`,
`permissions`, `organizationId`/`tenantId`, `userId`/`ownerId`, `emailVerified`,
`balance`, `credits`, `price`, `status` on anything financial, `createdAt`.

Framework equivalents: Rails strong parameters (`params.permit!` is a P0),
Laravel `$fillable` (`$guarded = []` is a P0), Django `ModelForm.fields` (never
`__all__` on a model with privileged fields), DRF serializer `read_only_fields`.

---

## Pattern 5 — Authorize at every layer that can be reached

A check on the HTTP handler does not protect the GraphQL resolver, the background
job, the CLI command, the webhook processor or the admin panel that all call the
same service.

Put the check in the **service layer** — the narrowest point every path crosses —
and let transports enforce authentication.

```
HTTP route ─┐
GraphQL     ├─→ service.voidInvoice(actor, id) ─→ authorize() ─→ domain
Job runner  │
Admin CLI  ─┘
```

---

## Multi-tenancy specifics

1. **Tenant comes from the session, never from the request.** A `tenantId` in a
   body, query string or header is attacker-controlled. `P0`.
2. **Every table carries the tenant column** from the first migration, including
   join tables.
3. **Enforce in the database** with row-level security.
4. **Test cross-tenant access explicitly** — a test that authenticates as tenant
   A and requests tenant B's resource, for every resource type.
5. **Watch the aggregate leaks:** counts, search indexes, autocomplete,
   exports, generated reports, cached fragments, and error messages that echo
   another tenant's data.

---

## Testing authorization

This is the test suite that finds real bugs. Make it a matrix, not a handful of
cases.

```ts
describe("authorization matrix", () => {
  const actors = ["anonymous", "otherTenantUser", "memberOfSameTenant",
                  "resourceOwner", "tenantAdmin", "platformAdmin"];

  for (const actor of actors) {
    for (const [method, path] of ROUTES) {
      it(`${actor} -> ${method} ${path}`, async () => {
        const res = await request(app)[method](path).auth(actor);
        expect(res.status).toBe(EXPECTED[actor][`${method} ${path}`]);
      });
    }
  }
});
```

The rules:
- **Every new route adds a row.** Make the matrix fail on an unlisted route, so
  adding an endpoint forces an authorization decision.
- **Test the negative cases**, not just the positive — the bug is always in what
  should be denied.
- **Include anonymous** for every route. It catches the middleware that was
  applied to the wrong prefix.

---

## Review checklist

- [ ] Is there a route with no declared policy? What happens to it?
- [ ] Does every read of a user-owned object carry an ownership predicate?
- [ ] Is authorization a single function, or scattered conditionals?
- [ ] Can tenancy be influenced by the request?
- [ ] Can any request body set a privileged field?
- [ ] Do background jobs, GraphQL, webhooks and admin paths authorize too?
- [ ] Does a 403 leak the existence of a resource that should be invisible?
- [ ] Are denials logged with actor, action and target?
- [ ] Is there a test that authenticates as A and is refused B's data?
