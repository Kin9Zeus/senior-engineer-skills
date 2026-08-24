# REST House Style

A complete, opinionated standard. Adopt it verbatim or fork it — the value is in
having *one* answer per question, written down, so that reviews stop relitigating
naming and shape.

---

## URLs

```
https://api.example.com/v1/organizations/{org_id}/invoices/{invoice_id}/line-items
```

- Plural nouns for collections. Lowercase. Hyphens between words, never
  underscores or camelCase in paths.
- Nest at most **one** level deep. Beyond that, use a top-level resource with a
  filter: `/v1/line-items?invoice_id=...`. Deep nesting produces URLs nobody can
  construct.
- No verbs in paths, except for non-CRUD state transitions as a sub-resource
  (`POST /invoices/{id}/void`).
- No trailing slash. Redirect if one arrives.
- No file extensions. Use `Accept`.
- The version is the first path segment.

## Methods

| Method | Safe | Idempotent | Body | Notes |
|---|---|---|---|---|
| `GET` | yes | yes | no | Never mutates. A `GET` with a side effect will be prefetched by a browser or crawler and will surprise you |
| `POST` | no | no* | yes | *Make it idempotent with `Idempotency-Key` |
| `PUT` | no | yes | yes | Full replacement |
| `PATCH` | no | should be | yes | Partial update; use JSON Merge Patch semantics |
| `DELETE` | no | yes | no | Return `204` on both the first and subsequent calls |
| `HEAD` / `OPTIONS` | yes | yes | no | Support them; clients and proxies use them |

## Naming and types

- `snake_case` for JSON fields. Pick one convention and never mix; `snake_case`
  survives contact with more languages than `camelCase` does.
- Timestamps: RFC 3339 / ISO 8601 in **UTC with an explicit offset** —
  `2026-08-24T16:18:12Z`. Never epoch integers (ambiguous units), never local
  time.
- Dates without a time: `2026-08-24`.
- Durations: integer with the unit in the field name — `timeout_seconds`,
  `retention_days`.
- Money: **integer minor units plus a currency code** —
  `{"amount": 1999, "currency": "USD"}`. Never a float, never a formatted string.
- Booleans: positively named — `is_active`, not `is_not_disabled`.
- Enums: lowercase snake_case strings, never integers. Document every value.
- Identifiers: opaque strings with a type prefix — `inv_01HQ8XYZ...`. The prefix
  makes logs readable and catches "passed the wrong id" bugs immediately.
- Nulls: prefer omitting an absent field over `null`; be consistent either way.
  Never use empty string to mean absent.

## Response shapes

**Single resource** — the object at the top level, unwrapped:
```json
{ "id": "inv_01HQ8", "object": "invoice", "amount": 1999, "currency": "USD",
  "created_at": "2026-08-24T16:18:12Z" }
```

**Collection** — always wrapped, so pagination has somewhere to live:
```json
{ "object": "list",
  "data": [ ... ],
  "has_more": true,
  "next_cursor": "inv_01HQ9" }
```

A bare top-level array is a mistake: there is no room to add pagination or
metadata later without a breaking change.

**Include an `object` type field.** It makes polymorphic handling possible and
logs self-describing.

**Expansion over nesting.** Return ids by default; let the client ask for
embedded objects:
```
GET /v1/invoices/inv_01HQ8?expand=customer,line_items
```
Cap expansion depth, or you have reinvented GraphQL's cost problem without its
tooling.

## Errors

```json
{ "error": {
    "type": "validation_error",
    "code": "invoice.amount_negative",
    "message": "Amount must be greater than zero.",
    "details": [ { "field": "amount", "code": "min", "message": "Must be > 0." } ],
    "request_id": "req_01HQ8",
    "doc_url": "https://docs.example.com/errors/invoice.amount_negative"
} }
```

**Error `type` vocabulary** — keep it small and closed:

| `type` | HTTP | Meaning |
|---|---|---|
| `invalid_request` | 400 | Malformed |
| `authentication_error` | 401 | Missing or bad credentials |
| `permission_error` | 403 | Authenticated, not allowed |
| `not_found` | 404 | Absent, or not visible to you |
| `conflict` | 409 | State conflict, duplicate, or idempotency mismatch |
| `validation_error` | 422 | Well-formed, semantically invalid |
| `rate_limit_error` | 429 | Throttled |
| `api_error` | 5xx | Our fault |

`code` is the stable, granular, machine-readable identifier. Consumers branch on
it, so changing one is a breaking change. Maintain a public error catalogue.

## Headers

**Request**
```
Authorization: Bearer <token>
Content-Type: application/json
Idempotency-Key: <uuid>            # on every POST
X-Request-Id: <uuid>               # client-supplied; echo it back
```

**Response**
```
Content-Type: application/json; charset=utf-8
X-Request-Id: req_01HQ8
X-RateLimit-Limit / -Remaining / -Reset
Cache-Control: private, no-store   # default for authenticated responses
ETag: "..."                        # on cacheable resources
```

Never put a token, an API key or personal data in a URL. URLs land in access
logs, proxy logs, browser history and `Referer` headers.

## Filtering, sorting, searching

```
GET /v1/invoices
      ?status=open,past_due          # comma = OR within a field
      &created_at[gte]=2026-01-01    # bracketed operators for ranges
      &created_at[lt]=2026-07-01
      &sort=-created_at,id           # leading minus = descending
      &limit=50
      &starting_after=inv_01HQ8
```

- Allowlist filterable and sortable fields. **Never** construct SQL from
  arbitrary parameters.
- Support `gte`, `gt`, `lte`, `lt` for dates and numbers.
- Full-text search is its own parameter (`q=`) with documented, bounded
  behaviour.
- Always include a stable tiebreaker in the sort.

## Bulk and async

**Bulk:** `POST /v1/invoices/batch` with an array, returning per-item results
including per-item errors, and an overall `207`-style summary. Cap the batch size.

**Long-running:** return `202` with a job resource.
```
POST /v1/exports        → 202  { "id": "job_01HQ8", "status": "pending",
                                 "url": "/v1/jobs/job_01HQ8" }
GET  /v1/jobs/job_01HQ8 → 200  { "status": "succeeded", "result_url": "..." }
```
The result URL is authenticated and expiring. Never a public link.

## Authentication

- `Authorization: Bearer <key>` — never a query parameter, never a custom header
  scheme without reason.
- Keys prefixed by environment (`sk_live_`, `sk_test_`) so a mistake is visible
  and secret scanners can detect leaks.
- Store only a hash. Show the key once.
- Scopes per key; `last_used_at` tracked; multiple active keys so rotation needs
  no downtime.

## Caching

- Authenticated responses: `Cache-Control: private, no-store` by default. Opt
  specific endpoints in deliberately.
- `ETag` + `If-None-Match` on read-heavy resources; return `304`.
- `Cache-Control: public, max-age=...` only for genuinely public data.
- Never cache a user-scoped response in a shared cache without the user in the
  key. Cross-user cache leakage is a `P0`.

## Compatibility contract — state it in your docs

> Clients MUST ignore unknown fields in responses.
> Clients MUST NOT depend on field order.
> Clients MUST NOT parse opaque identifiers or cursors.
> Clients MUST handle new enum values in response fields gracefully.
> We MAY add optional request fields, response fields and endpoints at any time.
> We WILL NOT remove or retype a field within a major version.

Stating this converts a whole class of would-be breaking changes into additive
ones, because you have told consumers what they may rely on.

---

## Checklist for a new endpoint

- [ ] Resource name and URL fit the existing scheme
- [ ] Correct method and status codes
- [ ] Request schema validates, rejects unknown fields
- [ ] Object-level authorization
- [ ] Idempotency key accepted if it mutates
- [ ] Pagination if it returns a collection, with a capped limit
- [ ] Uses the standard error envelope
- [ ] Rate-limited
- [ ] OpenAPI generated, with a request and a response example
- [ ] Logged with a correlation id; latency and error rate measured
- [ ] Tested: happy path, validation failure, unauthenticated, wrong-user, 404
- [ ] Changelog entry
