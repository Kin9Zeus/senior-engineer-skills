# Specialised Testing

Beyond unit, integration and E2E. Each answers a question the standard pyramid
cannot.

---

## Contract testing

**The question:** did we break a consumer we cannot see?

Between your services, or between you and a third party. The consumer declares
what it needs; the provider verifies it still supplies it. Consumer-driven
contracts (Pact and similar) catch the "we renamed a field and did not tell the
mobile team" break at build time rather than at runtime.

For a public API, the lighter version is often enough: **validate real responses
against your OpenAPI schema in CI**. It makes the documentation enforced rather
than aspirational, and it catches drift in both directions.

For third parties you consume: record real responses as fixtures, and run a
scheduled job that replays a live call and diffs against the fixture. When the
provider changes something, you learn on a Tuesday morning rather than during an
incident.

---

## Load and performance testing

**The question:** what breaks first, and at what load?

```js
// k6 — a shape that answers a real question
import http from "k6/http";
import { check } from "k6";

export const options = {
  stages: [
    { duration: "2m", target: 50 },    // ramp
    { duration: "5m", target: 50 },    // steady — this is where you measure
    { duration: "2m", target: 200 },   // stress — find the knee
    { duration: "5m", target: 200 },
    { duration: "2m", target: 0 },     // ramp down — watch recovery
  ],
  thresholds: {
    http_req_duration: ["p(95)<300", "p(99)<800"],
    http_req_failed: ["rate<0.01"],
  },
};

export default function () {
  const res = http.get(`${__ENV.BASE_URL}/api/invoices?limit=50`, {
    headers: { Authorization: `Bearer ${__ENV.TOKEN}` },
  });
  check(res, { "status 200": (r) => r.status === 200 });
}
```

**Types, and what each is for**

| Type | Shape | Answers |
|---|---|---|
| Load | Expected peak, sustained | Do we meet our latency SLO at normal peak? |
| Stress | Ramp until failure | Where is the knee, and what breaks first? |
| Soak | Moderate load for hours | Do we leak memory, connections or file handles? |
| Spike | Instant 10x | Do we degrade gracefully, and do we recover? |

**Rules that make the results mean something**
- Run against an environment that resembles production **including data volume**.
  A load test against 100 rows tells you nothing about a table with 10 million.
- **Realistic user journeys**, not one endpoint hammered. Real traffic has a mix.
- Warm caches first, or measure cold and warm separately and say which.
- Watch the *system* during the test, not just the client-side numbers: database
  connections, queue depth, CPU, memory, error classes. The interesting finding
  is almost always "the connection pool saturated at 180 concurrent users", not
  "latency went up".
- Establish a baseline, then run after significant changes. The trend matters
  more than the absolute number.
- Never load-test production without explicit authorisation and a plan.

**Soak tests find what nothing else does:** memory leaks, connection leaks,
unbounded caches, log-driven disk exhaustion, and slow degradation from table
growth.

---

## Security testing

Automated, in CI:
- **SAST** — static analysis for injection and unsafe patterns (Semgrep,
  CodeQL, your language's linter security rules).
- **Dependency scanning** — the ecosystem's audit tool, blocking on high
  severity.
- **Secret scanning** — pre-commit and in CI.
- **Container scanning** for image vulnerabilities.
- **DAST** against staging for the standard classes.

Manual, and irreplaceable:
- **The authorization matrix** (see `test-patterns.md`). Automation does not find
  IDOR; a test that logs in as A and requests B's resource does.
- **Business logic abuse**: negative quantities, decimal manipulation, coupon
  stacking, refund loops, race conditions on balance or inventory.
- **Threat-model-derived tests** — one test per identified threat's mitigation.

**Penetration testing** before a significant launch, and annually for anything
holding sensitive data. Only against systems you own or have written
authorisation to test.

---

## Accessibility testing

Automated tooling catches roughly a third of WCAG issues. It is necessary and
nowhere near sufficient.

```ts
// In your E2E suite — cheap, and catches regressions
import AxeBuilder from "@axe-core/playwright";

test("checkout has no automatically detectable a11y violations", async ({ page }) => {
  await page.goto("/checkout");
  const { violations } = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag22aa"])
    .analyze();
  expect(violations).toEqual([]);
});
```

Then the manual pass, which is where the real findings are:
- Complete each critical journey **with the keyboard only**, watching the focus
  indicator.
- Navigate with a screen reader (NVDA on Windows, VoiceOver on macOS/iOS,
  TalkBack on Android).
- Zoom to 400% and check nothing is lost or requires horizontal scrolling.
- Force colours / high contrast mode.
- Test with reduced motion enabled.

See the `accessibility-audit` skill.

---

## Visual regression testing

**The question:** did a CSS change break a layout somewhere nobody looked?

Screenshot comparison per component or page, across viewports. Genuinely useful
for design systems and marketing sites; noisy for dynamic, data-driven screens.

To keep it usable: freeze time and data, disable animations, use consistent
fonts (a font that loads late produces a diff on every run), and set a small
pixel tolerance. Review diffs as part of the PR, not in a separate tool nobody
opens.

---

## Mutation testing

**The question:** do your tests actually verify what they cover?

It mutates your code — flips `>` to `>=`, removes a line, changes a constant —
and checks whether a test fails. A **surviving mutant** is a line your tests
execute without verifying.

It is slow, so target it: the pricing engine, the permission checker, the state
machine, the tax calculation. On those modules it is worth more than any coverage
number, because it measures assertion quality rather than execution.

Tools: Stryker (JS/TS, C#, Scala), mutmut / cosmic-ray (Python), PIT (Java),
go-mutesting (Go).

---

## Property-based testing

**The question:** does this hold for inputs you did not think of?

Instead of examples, state a property and let the framework search for a
counterexample.

```ts
import fc from "fast-check";

it("round-trips through serialisation for any valid invoice", () => {
  fc.assert(fc.property(arbitraryInvoice(), (invoice) => {
    expect(deserialise(serialise(invoice))).toEqual(invoice);
  }));
});

it("never produces a negative total", () => {
  fc.assert(fc.property(fc.array(arbitraryLineItem()), (items) => {
    expect(calculateTotal(items)).toBeGreaterThanOrEqual(0);
  }));
});
```

Excellent for parsers, serialisers, encoders, financial calculations and anything
with algebraic properties (round-trip, idempotence, commutativity, invariants).
When it finds a counterexample it shrinks it to the minimal failing case, which
is frequently the most useful bug report you will get.

Tools: fast-check (JS/TS), Hypothesis (Python), QuickCheck (Haskell), gopter
(Go), jqwik (Java).

---

## Chaos testing

**The question:** does the system behave as designed when a dependency fails?

Only worth doing once you have a hypothesis about how the system *should*
degrade. Injecting failure into a system with no defined degradation behaviour
just produces an outage you caused.

Start small and locally: in a test environment, make the cache unavailable, add
500ms of latency to the database, kill one instance, fill a disk. Verify the
behaviour matches what you designed in `api-contracts/references/integration-patterns.md`.

Progress to production experiments only with a defined blast radius, an abort
switch, and stakeholder agreement.

---

## Testing background jobs

Frequently the least-tested part of a system, and the one most likely to fail
silently.

- **Handlers are pure functions** where possible: test the logic without the
  queue.
- **Idempotency:** run the handler twice with the same input, assert the effect
  happened once. This is the single most important job test, because retries are
  guaranteed.
- **Failure and retry:** assert bounded retries and that exhaustion lands in the
  dead-letter queue.
- **Poison messages:** a malformed payload must not block the queue.
- **Ordering:** if your handler assumes ordering, test what happens when it does
  not hold — because at-least-once delivery usually means it does not.

---

## Testing migrations

Run migrations against a **restored production-sized copy** as part of the
release process. It is twenty minutes of work that catches the migration that
would have locked a table for forty.

- Up → down → up leaves a correct schema.
- Measure duration and observe the lock profile at production scale.
- The **previous** application version still works against the new schema
  (required for a rolling deploy).
- Data integrity after the fact: row counts, spot checks, constraint validation.
