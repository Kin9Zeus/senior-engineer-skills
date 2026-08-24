# Test Patterns

## Table-driven tests

For a function with many input/output cases, one table beats twenty near-identical
tests. Failures name the case, and adding a case is one line.

```ts
describe("calculateVat", () => {
  const cases = [
    { name: "standard rate DE",        net: 10_000, country: "DE", expected: 1_900 },
    { name: "reduced rate DE books",   net: 10_000, country: "DE", category: "book", expected: 700 },
    { name: "reverse charge B2B EU",   net: 10_000, country: "FR", vatId: "FR123", expected: 0 },
    { name: "outside EU",              net: 10_000, country: "US", expected: 0 },
    { name: "zero net",                net: 0,      country: "DE", expected: 0 },
    { name: "rounds half up",          net: 999,    country: "DE", expected: 190 },
  ];

  it.each(cases)("$name", ({ expected, ...input }) => {
    expect(calculateVat(input)).toBe(expected);
  });
});
```

Note what the table encodes: the boundaries, the special cases, and the rounding
rule. That is the specification, readable by someone who does not know the code.

---

## Builders over fixtures

Shared fixture files become a shared dependency nobody dares change, and they
hide what a test actually depends on.

```ts
// test/builders.ts
export const aUser = (overrides: Partial<User> = {}): User => ({
  id: `usr_${ulid()}`,
  email: `user-${counter++}@test.local`,
  role: "member",
  organizationId: `org_${ulid()}`,
  emailVerifiedAt: new Date("2026-01-01T00:00:00Z"),
  ...overrides,
});

// In the test — only the relevant field is stated, so intent is obvious
const admin = aUser({ role: "admin" });
const unverified = aUser({ emailVerifiedAt: null });
```

The rule: **a reader should see, in the test body, every input that affects the
outcome.** Anything hidden in a default is, by construction, something the test
does not care about.

---

## Integration tests against a real database

```ts
// Per-test isolation via transaction rollback — fast and total
let tx: Transaction;
beforeEach(async () => { tx = await db.transaction(); });
afterEach(async () => { await tx.rollback(); });

it("scopes invoices to the requesting organization", async () => {
  const orgA = await createOrg(tx);
  const orgB = await createOrg(tx);
  await createInvoice(tx, { orgId: orgB.id, amount: 5_000 });

  const result = await listInvoices(tx, { orgId: orgA.id });

  expect(result).toHaveLength(0);   // the cross-tenant assertion
});
```

Alternatives when transactions do not work (because the code under test manages
its own transactions): truncate between tests, or a schema per worker for
parallelism. Both are acceptable; a shared, un-reset database is not.

**Run migrations before the suite**, against the test database. This makes the
suite a continuous test of your migrations, which is free coverage of a
high-risk area.

---

## The authorization matrix

The single highest-value test suite in a multi-user product. See
`security-hardening/references/authz-patterns.md`.

```ts
const EXPECTED = {
  "GET /api/invoices/:id": {
    anonymous:        401,
    otherOrgUser:     404,   // not 403 — existence must not leak
    sameOrgMember:    200,
    owner:            200,
    platformAdmin:    200,
  },
  // every route gets a row
};

describe("authorization", () => {
  it("has an expectation for every registered route", () => {
    // This is the test that keeps the matrix honest as routes are added
    expect(Object.keys(EXPECTED).sort()).toEqual(listRegisteredRoutes().sort());
  });

  for (const [route, actors] of Object.entries(EXPECTED)) {
    for (const [actor, status] of Object.entries(actors)) {
      it(`${actor} → ${route} → ${status}`, async () => {
        expect((await callAs(actor, route)).status).toBe(status);
      });
    }
  }
});
```

The first test — "has an expectation for every registered route" — is what makes
this durable. Adding an endpoint without an authorization decision fails the
build.

---

## E2E: stable selectors and real waits

```ts
test("a user can complete a purchase", async ({ page }) => {
  await page.goto("/products/widget");
  await page.getByRole("button", { name: "Add to cart" }).click();
  await page.getByRole("link", { name: "Checkout" }).click();

  await page.getByLabel("Card number").fill("4242424242424242");
  await page.getByLabel("Expiry").fill("12/30");
  await page.getByRole("button", { name: "Pay" }).click();

  // Wait for the CONDITION, never for a duration
  await expect(page.getByRole("heading", { name: "Order confirmed" })).toBeVisible();
  await expect(page.getByText(/Order #\d+/)).toBeVisible();
});
```

- **Select by role and accessible name.** It is stable across refactors, and it
  fails when accessibility breaks — you get an a11y regression test for free.
  CSS class selectors break on every restyle.
- **Never `waitForTimeout`.** Sleeping is the single largest source of flakiness:
  too short and it fails on a slow CI runner, too long and the suite crawls.
  Wait for the assertion.
- **Independent tests.** Each creates its own data and does not depend on
  another's leftovers. Log in via an API call or a stored session state, not by
  driving the login form in every test.
- Use a **test payment mode**, never a live provider.
- Capture a trace, screenshot and video on failure. A failed E2E test with no
  artefact is unreproducible.

---

## Testing time

```ts
// Inject the clock rather than calling the global one
export const createSubscription = (deps: { now: () => Date }) => (input) => ({
  ...input,
  trialEndsAt: addDays(deps.now(), 14),
});

it("ends the trial 14 days after creation", () => {
  const now = () => new Date("2026-01-01T00:00:00Z");
  expect(createSubscription({ now })(input).trialEndsAt)
    .toEqual(new Date("2026-01-15T00:00:00Z"));
});
```

Set `TZ=UTC` for the whole suite. Test the boundaries deliberately: month ends,
leap days, DST transitions, and the timezone where your users are but your CI
runner is not.

---

## Testing async and concurrency

```ts
it("does not oversell the last item", async () => {
  await createProduct({ id: "p1", stock: 1 });

  // The bug only appears under genuine concurrency
  const results = await Promise.allSettled(
    Array.from({ length: 10 }, () => purchase({ productId: "p1", qty: 1 }))
  );

  expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
  expect(await stockOf("p1")).toBe(0);
});
```

Race conditions never appear in serial tests. If a resource can be contended,
fire concurrent requests at it. This test finds the missing constraint, the
missing lock and the read-modify-write bug — all of which are invisible to every
other test you will write.

---

## Snapshot tests — use sparingly

Snapshots are useful for large stable structures (a rendered email, a generated
config, an OpenAPI document). They are harmful as a general assertion mechanism
because the standard response to a failure is to press `u` and update, which
approves the bug.

If you use them: keep them small, review the diffs seriously, and never snapshot
something containing a timestamp, an id or an ordering that varies.

---

## Anti-patterns

| Anti-pattern | Why it hurts | Instead |
|---|---|---|
| Testing implementation details | Breaks on every refactor; blocks improvement | Assert observable behaviour |
| Mocking your own modules | Passes while the system is broken | Test them together |
| One test asserting five behaviours | The first failure hides the rest | One behaviour per test |
| Logic (`if`/`for`) in tests | Branches that may never run; tests need testing | Parameterised tables |
| `sleep` / `waitForTimeout` | The main cause of flakes and slow suites | Wait for the condition |
| Shared mutable fixtures | Order-dependent failures | Builders, per-test data |
| Asserting on log output | Brittle; logs are not an interface | Assert on return values or state |
| Tests that depend on order | Fails when parallelised or shuffled | Full isolation |
| `expect(true).toBe(true)` after a call | Coverage theatre | Assert the actual outcome |
| Enormous setup for a small assertion | Nobody can tell what is being tested | Extract, or reconsider the design |

---

## When a test is hard to write

That is diagnostic information about the code, not about testing.

| Symptom | What it usually means |
|---|---|
| Needs a huge amount of setup | Too many dependencies; the unit is doing too much |
| Needs six mocks | Business logic is entangled with I/O |
| Cannot test without a browser | Logic is trapped in a component |
| Cannot test without the network | A missing boundary/interface |
| Assertion is unclear | The behaviour itself is unclear — clarify the requirement first |

The usual fix is to extract the decision from the machinery: a pure function
that takes data and returns a decision, called by a thin layer that does the I/O.
That function is trivially testable, and the thin layer needs one integration
test.
