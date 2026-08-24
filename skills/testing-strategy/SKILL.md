---
name: testing-strategy
description: Test strategy and quality engineering — the test pyramid, what to test at each layer, meaningful coverage policy, integration and contract testing, E2E for critical journeys, test data and fixtures, flaky-test control, mutation testing, load and security testing, and CI gating. Use when the user says "tests", "testing", "unit test", "integration test", "E2E", "Playwright", "Cypress", "Jest", "pytest", "coverage", "TDD", "flaky", "mocking", "test data", "how do I test this", "we have no tests" or "the tests keep breaking"; when writing tests for new code; and as a pass in any project audit. By Devleck.
license: MIT
---

# Testing Strategy

A test suite has one job: **tell you, quickly and truthfully, whether the system
still does what it is supposed to do.** Judge every testing decision against
that. Coverage percentage, test count and framework choice are proxies, and
proxies get gamed.

---

## The pyramid, and why it is that shape

```
        ╱──────────╲        E2E              few, slow, high confidence
       ╱   5-10%    ╲                        the critical journeys only
      ╱──────────────╲
     ╱   Integration  ╲     20-30%           real database, real HTTP layer
    ╱──────────────────╲                     where most real bugs live
   ╱────────────────────╲
  ╱         Unit         ╲  60-70%           milliseconds, no I/O
 ╱────────────────────────╲                  business rules and edge cases
```

The shape follows from cost. A unit test runs in a millisecond and fails
precisely; an E2E test takes 30 seconds, is flakier, and tells you only that
*something* broke. You want as much signal as possible from the cheap layer, and
just enough from the expensive one to know the pieces are actually connected.

**Both inversions are failures.** An ice-cream cone (mostly E2E) is slow and
flaky, and people stop running it. A suite with no top has never tested that the
parts work together — which is where integration bugs live by definition.

---

## What belongs at each layer

**Unit** — business rules, calculations, state machines, validation, edge cases,
error paths, pure transformations. No database, no network, no filesystem, no
clock. If it needs a mock of something you own, that is usually a design signal:
the logic wants to be extracted from its dependencies.

**Integration** — the things unit tests structurally cannot catch: does the query
return what you think, does the migration apply, does the authorization
middleware actually reject, does the transaction roll back, does the serialiser
produce the right shape. **Use a real database** (a container, or a per-worker
schema). A mocked database tests your mock.

**E2E** — the handful of journeys where failure is unacceptable: signup, login,
the core action, payment, account deletion. Through a real browser, against a
real stack. Five to fifteen of these, not two hundred.

**Contract** — between services or against third parties. Consumer-driven
contract tests catch the "we changed the API and did not tell you" class of
break.

---

## Coverage — the honest version

Coverage tells you what is **not** tested. It tells you nothing about whether
what *is* covered is tested well. A line executed with no assertion is covered
and worthless.

```ts
// 100% coverage. Zero value.
it("works", () => { calculateTax(100, "DE"); });
```

**A policy that works:**
- No global percentage target — it produces tests written to hit lines.
- **Branch coverage** on business logic modules: high, and enforced.
- **100% on the money path**, the authorization path, and anything computing a
  permission or a price.
- **Coverage must not decrease** on a pull request. This is the useful gate —
  it prevents erosion without incentivising theatre.
- Track coverage of **changed lines**, not the whole repository. It is the number
  a reviewer can act on.

**Mutation testing** is the real measure. It changes your code (flips a
comparison, removes a line) and checks whether a test fails. A surviving mutant
is a line your tests execute but do not verify. Run it on the critical modules —
it is slow, so it is not a whole-suite tool, but on a pricing engine or a
permission checker it is worth more than any coverage number.

---

## Writing a good test

```ts
it("refuses a refund larger than the amount captured", async () => {
  // Arrange — explicit, local, obviously correct
  const payment = await createPayment({ captured: 5_000, currency: "USD" });

  // Act
  const result = refund(payment, { amount: 7_500 });

  // Assert — one behaviour, named precisely
  expect(result).toEqual({
    ok: false,
    code: "refund.exceeds_captured",
    maxRefundable: 5_000,
  });
});
```

**Rules**

1. **Name the behaviour, not the function.** `refuses a refund larger than the
   amount captured` beats `test refund 2`. The name is what you read when it
   fails at 3am.
2. **One behaviour per test.** Multiple assertions about *the same* behaviour are
   fine; testing three behaviours in one test means one failure hides two.
3. **Arrange visibly.** A reader should not have to open three fixture files to
   know what the input was. Prefer explicit builders over shared global fixtures.
4. **Assert on outcomes, not implementation.** Asserting that a private method
   was called locks the test to the current design and breaks on every refactor.
5. **No conditionals or loops in tests.** A test with an `if` has a branch that
   might never run. Table-driven parameterised tests, not `for` loops with logic.
6. **Deterministic.** Inject the clock, seed the randomness, fix the timezone,
   never depend on execution order or on another test's leftovers.
7. **Failure message must locate the bug.** `expected 5000, got 7500` is useful;
   `expected true, got false` is not.

**Test the error paths.** Most production incidents are in code paths that were
never exercised: the timeout, the malformed input, the concurrent update, the
third party returning a 500. Those need tests more than the happy path does.

---

## Mocking — the discipline

**Mock at the system boundary, not inside your own design.**

| Mock this | Never mock this |
|---|---|
| Third-party HTTP APIs | Your own database (use a real one) |
| Email, SMS, payment providers | Your own modules (test them together) |
| Time, randomness, UUID generation | The thing under test |
| Slow, expensive or rate-limited services | |

Heavy mocking of your own code produces tests that pass while the system is
broken, because the mocks encode assumptions the real collaborator does not
honour. When you find yourself mocking four of your own classes to test a fifth,
the design is telling you something.

For third-party HTTP, prefer **recorded fixtures** or a local mock server over
hand-written stubs — hand-written stubs drift from the real API silently, and
you find out in production.

**Never let CI call a live third party.** Slow, flaky, and occasionally
expensive.

---

## Test data

- **Builders with sensible defaults**, overriding only what the test cares about:
  `aUser({ role: "admin" })`. This keeps the test's intent visible.
- **Isolation per test.** A transaction rolled back, a truncate between tests, or
  a schema per worker. Shared mutable state produces order-dependent failures,
  which are the worst kind to debug.
- **No production data in tests, ever.** It is a privacy violation and it makes
  tests non-reproducible.
- Seed randomness and log the seed, so a random failure is reproducible.
- **Freeze time.** Tests that depend on the real clock fail at midnight, on the
  last day of the month, and during DST transitions.

---

## Flaky tests — treat as outages

**A suite people re-run until green provides no information.** One tolerated
flake teaches the team that red means "try again", and then a real regression is
merged past.

```
1. Detect     — track pass rate per test in CI
2. Quarantine — move it out of the blocking set immediately, with an owner and a date
3. Diagnose   — the usual causes, in order of frequency:
                 · a race between the assertion and an async operation
                   (fix: wait for the condition, never sleep for a duration)
                 · shared state leaking between tests
                 · real time, real network, real randomness
                 · test-order dependence (verify by shuffling)
4. Fix or delete — a quarantined test with no owner after two weeks is deleted.
                   An unowned flake is worse than no test
```

**Never** add blanket automatic retries. Retrying until green destroys the exact
signal the suite exists to produce.

---

## The CI gate

```
Every PR, blocking:   lint · typecheck · unit · integration · build · dep audit
Before deploy:        E2E on the critical journeys, against staging
Nightly:              full E2E matrix, load test, mutation on critical modules
```

Requirements: under ~10 minutes for the PR gate, not flaky, and **not
bypassable**. A gate with a culture of "just merge it, CI is being weird" is not
a gate.

---

## Starting from zero

A codebase with no tests, in priority order:

1. **A test for the bug you are fixing right now.** Every bug fix starts with a
   failing test. This alone stops the codebase repeating itself.
2. **E2E on the single most critical journey.** One test that proves the product
   fundamentally works.
3. **Integration tests on the money and authorization paths.** Where a bug is
   most expensive.
4. **Unit tests on the business rules** as you touch them.
5. Then breadth.

Do not attempt a coverage sprint on a legacy codebase. Characterisation tests
written against existing behaviour lock in the bugs along with the features. Test
what you change, and let coverage grow where the work is.

---

## Review checklist

- [ ] The pyramid is roughly the right shape
- [ ] Integration tests run against a real database
- [ ] E2E covers signup, login, the core action, payment, deletion
- [ ] Every bug fix has a regression test that fails without the fix
- [ ] Authorization is tested as a matrix (see `security-hardening`)
- [ ] Error paths and edge cases tested, not just happy paths
- [ ] No live third-party calls in CI
- [ ] Tests are deterministic: time frozen, randomness seeded, order-independent
- [ ] Flake rate tracked; flakes quarantined with owners
- [ ] CI blocks merge and runs in under ~10 minutes
- [ ] Coverage does not decrease; critical modules at 100% branch coverage
- [ ] Test names describe behaviour

## References

- `references/test-patterns.md` — patterns and anti-patterns per layer, with examples
- `references/specialised-testing.md` — load, security, accessibility, contract, visual, chaos
