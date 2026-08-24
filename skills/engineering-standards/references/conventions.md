# Code Conventions

The specific choices below matter far less than picking one set and applying it
everywhere. **Consistency is the feature.**

---

## Automate everything automatable

Anything a tool can enforce should never be discussed in a review. Review
attention is scarce; spend it on correctness and design.

```
Formatter    Prettier / Biome / gofmt / Black / rustfmt   — zero configuration debate
Linter       ESLint / Ruff / golangci-lint / Clippy       — real problems, not style
Types        strict from commit one                        — never retrofittable
Pre-commit   format + lint on staged files only            — fast, or it gets bypassed
CI           the same checks, blocking                     — the pre-commit hook is skippable
```

**Enable strict type checking on day one.** TypeScript `strict: true`,
`mypy`/`pyright` strict, nullable reference types in .NET, `golangci-lint` with
a real ruleset. Turning strictness on later means fixing thousands of errors at
once, which nobody ever does — so it never gets turned on.

---

## Naming

| | Convention |
|---|---|
| Booleans | `is`, `has`, `should`, `can` — `isActive`, `hasPermission` |
| Functions | Verb phrases — `calculateTax`, `sendInvite`, `parseConfig` |
| Predicates | `isValid`, `canEdit`, `shouldRetry` |
| Collections | Plural — `users`, not `userList` or `userArray` |
| Constants | `SCREAMING_SNAKE` for true module-level constants only |
| Types | `PascalCase`. No Hungarian prefixes (`IUser`, `TUser`) |
| Files | Match the language's convention, and be consistent |
| Private | The language's mechanism (`#field`, `_name`, unexported) |

**Say what it is, not what it is made of.** `retryAttempts` beats `retryNumber`.
`daysUntilExpiry` beats `expiryDays` (ambiguous). `userIdsByOrganization` tells
you the shape.

**Avoid**: single letters outside a tight loop or a well-known idiom;
abbreviations that are not universal (`usr`, `cfg`, `mgr`); `data`, `info`,
`temp`, `obj`, `handleStuff`; and numbered variants (`user2`, `dataNew`).

**Units and currency in the name.** `timeoutMs`, `sizeBytes`, `priceCents`,
`distanceKm`. This single habit prevents a whole class of unit-confusion bugs,
and it makes an incorrect call site visible on sight.

---

## Function design

```ts
// Hard to read: nested, mixed altitude, unclear failure
function processOrder(order) {
  if (order) {
    if (order.items.length > 0) {
      if (order.customer.isActive) {
        // ... 40 lines of mixed validation, calculation and I/O
      }
    }
  }
}

// Better: guard clauses, one altitude, explicit failures
function processOrder(order: Order): Result<Receipt, OrderError> {
  if (order.items.length === 0)     return err({ code: "order.empty" });
  if (!order.customer.isActive)     return err({ code: "customer.inactive" });

  const totals = calculateTotals(order.items, order.customer.taxRegion);
  const payment = capturePayment(order.customer, totals.grandTotal);
  return payment.ok ? ok(buildReceipt(order, totals, payment.value)) : payment;
}
```

- **Guard clauses first.** Handle the impossible cases and leave; keep the happy
  path unindented.
- **One level of abstraction per function.** If a function orchestrates *and*
  formats a date, extract the formatting.
- **Length is a symptom, not a rule.** A 60-line function doing one thing
  linearly is fine. A 20-line function doing three things is not.
- **Parameter count.** Past three or four, pass an options object — and name the
  fields, so call sites are readable.
- **No boolean flag parameters.** `render(true)` is unreadable at the call site.
  Two functions, or a named option.
- **Return, do not mutate**, unless mutation is the point and is documented.

---

## Comments

```ts
// ✗ Restates the code. Will go stale. Adds nothing.
// increment the counter
counter++;

// ✓ Records a reason that is not visible in the code.
// The provider returns HTTP 200 with an error in the body on declines,
// so status alone is not sufficient. See PROV-1042.
if (response.body.status !== "succeeded") { … }

// ✓ Documents a deliberate trade-off.
// O(n²), but n is bounded at 50 by the plan limit. A map would be
// faster and less readable; revisit if the limit is raised.

// ✓ Marks known debt with an owner and a trigger.
// TODO(@aleck, before SSO): extract auth from the controller — it cannot
// currently be tested without an HTTP request. Debt register #3.
```

**Rules**
- Explain **why**, not what. The code says what.
- A comment explaining *what* usually means the code needs a better name.
- **Delete commented-out code.** Git remembers it. Commented code is
  unreviewable, unrunnable, and misleading.
- `TODO` gets an owner and a trigger, or it is a lie about future work.
- **Never leave a `TODO` in a path handling money, auth, or personal data.**
- Doc comments on public APIs: what it does, what it returns, what it throws,
  and any non-obvious constraint.

---

## Error handling

**One approach per codebase.** Mixing exceptions, error returns and null returns
means every call site needs a different defensive pattern.

```ts
// Distinguish EXPECTED failures from BUGS. Only the second should page.
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };

// Expected: a validation failure, a not-found, a conflict. Part of the contract.
function findUser(id: string): Result<User, "not_found"> { … }

// Unexpected: a bug or an outage. Throw; let it reach the error boundary.
function connectDatabase(): Connection {
  if (!config.DATABASE_URL) throw new ConfigurationError("DATABASE_URL is not set");
  …
}
```

- **Never swallow an error silently.** `catch {}` is a defect. If you genuinely
  mean to ignore it, log it at debug level with a comment saying why.
- **Preserve the cause** when wrapping: `new Error("msg", { cause: err })`.
- **Add context, not noise.** "Failed to charge customer cus_123 for order
  ord_456" beats "Payment failed".
- **Never expose internals to the client.** Log the detail; return a code and a
  generic message with a request id.
- **Fail fast at boot.** Missing configuration should stop the process at
  startup, not produce an error at 3am on the first request that needed it.

---

## File and module structure

Organise by **domain**, not by technical kind, past a handful of screens.

```
✗  components/  hooks/  utils/  services/  types/
   → every feature change touches every folder

✓  features/checkout/    components/  hooks/  api.ts  types.ts  index.ts
   features/billing/     …
   platform/             config  logging  db  auth  errors
   → a feature lives in one place; deleting it is deleting one folder
```

- **One public entry point per module** (`index.ts`), so the internals can change
  without breaking consumers.
- **No circular imports.** Enforce with a lint rule; a cycle is a unit that
  cannot be tested or reasoned about independently.
- **Avoid the `utils` sinkhole.** Anything imported by everything is a coupling
  hub and a rebuild bottleneck. Name modules by what they do —
  `formatting/currency.ts`, not `utils/helpers.ts`.
- **Colocate tests** with the code, or mirror the structure exactly. Either is
  fine; drifting between them is not.

---

## Types

- **Model the domain, not the database.** `EmailAddress` and `Money` carry
  meaning that `string` and `number` do not.
- **Make illegal states unrepresentable.** A discriminated union beats a struct
  with six optional fields and a comment about which combinations are valid.
  ```ts
  // ✗ Four impossible states are representable
  type Request = { loading: boolean; data?: User; error?: Error };

  // ✓ Only the real states exist
  type Request =
    | { status: "idle" }
    | { status: "loading" }
    | { status: "success"; data: User }
    | { status: "error"; error: Error };
  ```
- **`any` is a decision, not a default.** Where you need it, comment why.
- **Parse, do not validate.** Turn unknown input into a typed value once, at the
  boundary, and let the type carry the guarantee inward.
- **Do not export types you do not intend consumers to depend on.**

---

## Async

- **Every external call has a timeout.** A missing timeout is an unbounded hang
  and the most common cause of cascading failure.
- **Parallelise independent work.** Sequential `await`s on unrelated operations
  is the most common and most easily fixed latency defect.
- **Bound your parallelism** when fanning out over a list — unbounded
  `Promise.all` over 10,000 items exhausts connection pools.
- **Handle rejection.** An unhandled rejection crashes or hangs the process
  depending on runtime and version. Register a handler and exit rather than
  continuing in an unknown state.
- **`Promise.allSettled`** when a partial failure should not fail everything.
- **Never `async` in a `forEach`** — it does not await, and the errors vanish.

---

## Magic values

```ts
// ✗
if (user.status === 3) { … }
setTimeout(retry, 30000);

// ✓
const UserStatus = { Active: 1, Suspended: 2, Deleted: 3 } as const;
const RETRY_DELAY_MS = 30_000;

if (user.status === UserStatus.Deleted) { … }
setTimeout(retry, RETRY_DELAY_MS);
```

Every literal that is not `0`, `1`, or an obvious empty value should have a
name. The name is what makes the call site reviewable.

---

## The review questions

1. Could I understand this in six months without asking anyone?
2. Does the naming make a comment unnecessary?
3. Is there exactly one way this codebase does this kind of thing?
4. What happens on the failure path — and is it tested?
5. Is anything here a decision that should be an ADR?
6. Would a formatter or linter have caught this? (If so, configure it and stop
   discussing it.)
