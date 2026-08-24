---
name: api-contracts
description: API design and contract engineering — REST resource modelling, error envelopes, pagination, filtering, idempotency, versioning and deprecation, rate limiting, webhooks, OpenAPI, GraphQL schema and N+1 defence, and contract testing. Use when designing, reviewing or documenting an endpoint or integration; when the user says "API design", "REST", "GraphQL", "endpoint", "OpenAPI", "Swagger", "versioning", "pagination", "rate limit", "webhook", "idempotency", "status code", "API contract", "breaking change" or "integrate with"; and as a pass in any project audit that finds a public or internal API. By Devleck.
license: MIT
---

# API Contracts

An API is a promise you cannot take back. Internal APIs can be refactored;
anything a second party consumes becomes a compatibility obligation the moment
the first integration ships.

Design for the consumer who is not in the room, does not read your changelog, and
will retry on failure.

---

## The seven properties of a good endpoint

Every endpoint should be:

1. **Predictable** — its shape is inferable from the others.
2. **Authorised** — per object, not merely authenticated.
3. **Validated** — with a schema, at the boundary, rejecting unknown fields.
4. **Idempotent where it can be** — safe to retry.
5. **Bounded** — pagination capped, payload size capped, response time bounded.
6. **Observable** — logged with a correlation id, latency and error rate
   measured.
7. **Documented** — from the code, so it cannot drift.

An endpoint missing any of these is a finding, whatever it returns.

---

## REST essentials

**Resources are nouns; HTTP verbs are the operations.**

```
GET    /v1/invoices                list
POST   /v1/invoices                create
GET    /v1/invoices/{id}           read
PATCH  /v1/invoices/{id}           partial update
DELETE /v1/invoices/{id}           delete
POST   /v1/invoices/{id}/void      a state transition that is not CRUD
```

Actions that are genuinely not CRUD get a sub-resource with `POST`. Do not
contort them into `PATCH` with a magic `status` field, and do not invent
`/getInvoices`.

**Status codes people actually need to distinguish**

| | Use for |
|---|---|
| `200` / `201` / `204` | Success; `201` with a `Location` on create; `204` for an empty response |
| `202` | Accepted for async processing — return a status URL |
| `400` | Malformed request |
| `401` | Not authenticated |
| `403` | Authenticated, not permitted — **only when the resource's existence is not secret** |
| `404` | Not found, **or found but not visible to you** (prefer this over 403 for other users' data) |
| `409` | Conflict — duplicate, or a state transition that is not valid now |
| `410` | Gone — removed permanently; useful in deprecation |
| `422` | Well-formed but semantically invalid (validation failures) |
| `429` | Rate limited — **always with `Retry-After`** |
| `5xx` | Your fault. Never use a 4xx to hide a server error, and never a 200 with `{"error": ...}` |

Returning `200` with an error body is the single most consumer-hostile pattern in
API design: it defeats every HTTP client's error handling, every retry policy,
and every monitoring tool.

---

## One error envelope, everywhere

```json
{
  "error": {
    "type": "validation_error",
    "message": "The request could not be processed.",
    "code": "invoice.amount_negative",
    "details": [
      { "field": "amount", "code": "min", "message": "Must be greater than 0." }
    ],
    "request_id": "req_01HQ8..."
  }
}
```

- **`code` is stable and machine-readable.** Consumers branch on it. Changing a
  code is a breaking change.
- **`message` is for humans** and may change freely.
- **`details` is field-level** so a client can render inline form errors.
- **`request_id` matches your logs** — this single field turns "the API is
  broken" into a two-minute investigation.
- **Never leak internals**: no stack traces, no SQL, no file paths, no upstream
  vendor errors passed through verbatim.

Define the envelope once, in one module, and make it impossible to return a
different shape.

---

## Idempotency — the property that makes retries safe

Networks time out after the server committed. The client cannot distinguish that
from a failure. Without idempotency, every retry risks a duplicate charge, a
duplicate order, a duplicate email.

```
POST /v1/payments
Idempotency-Key: 8f14e45f-ea9b-4f8a-9d2c-1f2e3a4b5c6d
```

Server behaviour:
1. Look up the key, scoped to the account and endpoint.
2. **Miss** → process, store `(key, request fingerprint, response, status)`,
   return.
3. **Hit, same request fingerprint** → return the stored response. Do not
   reprocess.
4. **Hit, different fingerprint** → `409`. The client reused a key for a
   different request, which is a bug worth surfacing.
5. **Hit, still in flight** → `409` with a retry hint.
6. Expire keys after 24 hours or so.

**Mandatory** on anything touching money, and cheap enough to apply to every
`POST`. `PUT` and `DELETE` should be naturally idempotent; check that yours
actually are — a `DELETE` that returns `404` on the second call breaks retry
logic, so return `204` both times.

---

## Pagination, filtering, sorting

**Cursor pagination for anything large or changing.** Offset pagination degrades
linearly and is incorrect under concurrent writes — rows shift between pages.

```
GET /v1/events?limit=50&starting_after=evt_01HQ8...

{
  "data": [ ... ],
  "has_more": true,
  "next_cursor": "evt_01HQ9..."
}
```

- The cursor is **opaque**. Do not document its structure; you will want to
  change it.
- **Cap `limit` server-side.** An uncapped limit is a denial-of-service vector.
- Total counts are expensive on large tables. Omit them, or make them an explicit
  opt-in.
- Filtering: an explicit allowlist of filterable fields. Never build SQL from
  arbitrary query parameters.
- Sorting: an allowlist of sortable fields, with a stable tiebreaker so the
  ordering is total.

---

## Versioning and deprecation

Choose one and be consistent: **URL path** (`/v1/`) is the most obvious and most
common; a header or a date-pinned version is more elegant and less discoverable.
For most teams, the path wins on operability.

**What is breaking:** removing or renaming a field; changing a type; adding a
required request field; narrowing an enum you return; changing an error `code`;
changing pagination semantics; tightening validation on previously-accepted
input.

**What is not:** adding an optional request field; adding a response field
(*provided* consumers do not reject unknown fields — say so in your docs);
adding a new endpoint; adding a new enum value to a field you *accept*.

**Deprecation, done properly:**
```
Deprecation: Sun, 01 Nov 2026 00:00:00 GMT
Sunset: Sun, 01 May 2027 00:00:00 GMT
Link: <https://docs.example.com/migrate/v2>; rel="deprecation"
```
Announce, instrument (measure who is still calling it), contact them directly,
then remove. A deprecation with no usage measurement is a guess about who you are
about to break.

---

## Rate limiting

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 847
X-RateLimit-Reset: 1735689600
Retry-After: 42                    # on 429
```

- Limit per API key or per account, not per IP, for authenticated APIs.
- Different limits per endpoint class — reads, writes, and expensive operations
  (search, export, report generation) are not the same.
- Return `429` with `Retry-After`, not `403` and not a silent drop.
- Document the limits. Undocumented limits produce support tickets and broken
  integrations.
- **Add them before launch.** Adding limits later breaks working integrations,
  which is why teams put it off and then cannot do it.

---

## Webhooks — the API you call

- **Sign every payload** (HMAC over the raw body, with a timestamp to prevent
  replay). Consumers must verify before parsing. An unverified payment webhook
  means anyone can post "payment succeeded".
- **Retry with exponential backoff and jitter**, for a bounded period, then
  dead-letter.
- **At-least-once delivery** — say so in your docs, and give each event a stable
  id so consumers can deduplicate.
- Send a **minimal payload with an id**, letting the consumer fetch the current
  state. Sending full objects means you deliver stale data on retry.
- Provide a **replay/redelivery** endpoint and a delivery log in the dashboard.
- Time out fast (a few seconds); a slow consumer must not block your queue.
- Consumers should return `2xx` immediately and process asynchronously — document
  this expectation.

---

## Documentation that cannot drift

**Generate the OpenAPI spec from the code** — decorators, types, or schema
definitions. A hand-maintained spec is wrong within a month, and a wrong spec is
worse than none because people trust it.

Then: examples for every endpoint (request and response), the error catalogue
with every `code`, auth setup, rate limits, pagination, idempotency, webhook
signature verification, a changelog, and a sandbox environment.

**Contract-test against the spec.** Validate real responses against the schema in
CI so the documentation is enforced rather than aspirational.

---

## GraphQL specifics

If you chose GraphQL, these are not optional:

- **Depth and complexity limiting.** Without them, one query can scan your entire
  database. This is a denial-of-service vulnerability, not a performance concern.
- **Persisted queries** in production — an allowlist of known operations removes
  the arbitrary-query attack surface entirely.
- **Dataloaders everywhere.** GraphQL's resolver model produces N+1 by default;
  batching is the fix, and it must be per-request.
- **Authorization at the field and object level**, not at the query entry point —
  a nested resolver is a separate access decision.
- **Errors:** GraphQL returns `200` with an `errors` array by design. Give errors
  stable `extensions.code` values so clients can branch.
- Disable introspection in production if the schema is not public.
- Cost analysis and timeouts per query.

---

## Review checklist

- [ ] Consistent resource naming, verbs and status codes across all endpoints
- [ ] One error envelope with stable machine-readable codes and a request id
- [ ] Request validation by schema, rejecting unknown fields
- [ ] Object-level authorization on every endpoint
- [ ] Idempotency on all money-touching mutations
- [ ] Cursor pagination with a server-side cap
- [ ] Filter and sort fields allowlisted
- [ ] Versioning strategy and a written deprecation policy
- [ ] Rate limits enforced, headed and documented
- [ ] Webhooks signed, retried, replayable, deduplicable
- [ ] OpenAPI generated from code and contract-tested in CI
- [ ] Timeouts on every outbound call your API makes
- [ ] No internal detail in any error response

## References

- `references/rest-standard.md` — the full house style, worth adopting verbatim
- `references/integration-patterns.md` — webhooks, retries, outbox, third-party clients
