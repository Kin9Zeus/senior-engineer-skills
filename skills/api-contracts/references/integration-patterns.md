# Integration Patterns

Every third-party integration is a dependency on someone else's availability,
correctness and goodwill. Design for the day it is slow, wrong, or down.

---

## The outbound call contract

Every call you make to another system must have all five. A missing one is a
finding.

1. **A timeout.** Connect *and* read. A missing timeout is an unbounded hang, and
   it is the most common cause of cascading failure — your threads fill up
   waiting on someone else's outage.
2. **A retry policy** — bounded attempts, exponential backoff, **jitter**, and
   only on retriable conditions (timeouts, `429`, `5xx`; never `4xx`). Without
   jitter, every client retries in lockstep and hammers a recovering service.
3. **Idempotency**, so retries are safe. If the provider offers idempotency keys,
   use them.
4. **A circuit breaker** for anything in the request path. After N consecutive
   failures, fail fast for a cooldown rather than queueing.
5. **A fallback**, decided deliberately: degrade, queue for later, or fail the
   request with a clear message. "Hang until timeout" is a decision made by
   default.

```ts
const client = new HttpClient({
  timeout: { connect: 2_000, read: 10_000 },
  retry: { attempts: 3, backoff: "exponential", jitter: true,
           retryOn: [408, 429, 500, 502, 503, 504] },
  circuitBreaker: { threshold: 5, cooldownMs: 30_000 },
});
```

**Never make an external call inside a database transaction.** It holds a
connection for the duration of the third party's outage and exhausts the pool.

---

## Receiving webhooks

The order of these steps is the security control, not a style preference.

```ts
app.post("/webhooks/stripe", raw({ type: "application/json" }), async (req, res) => {
  // 1. Verify the signature over the RAW body, before parsing.
  //    Parsing first, verifying second, is how forged payloads get through.
  let event;
  try {
    event = verifySignature(req.body, req.headers["stripe-signature"], SECRET);
  } catch {
    return res.status(400).end();
  }

  // 2. Deduplicate. Delivery is at-least-once, always.
  if (await seen(event.id)) return res.status(200).end();

  // 3. Acknowledge FAST. Do the work asynchronously.
  //    A slow handler causes the sender to time out and retry, multiplying load.
  await enqueue("webhook", event);
  await markSeen(event.id);
  res.status(200).end();
});
```

**The failure modes to check for in review:**
- Signature not verified, or verified after `JSON.parse` mutated the body. `P0`
  on anything financial.
- No timestamp check, so a captured payload can be replayed indefinitely.
- No deduplication, so a retry double-processes.
- Heavy work inline, causing sender timeouts and retry storms.
- Returning `5xx` for a business-logic failure the sender cannot fix — it will
  retry forever. Return `200` and handle it internally.
- Trusting payload contents. Treat the webhook as a **notification that something
  happened**, then fetch the authoritative state from the provider's API.

---

## Sending webhooks

- Sign with HMAC over the raw body, including a timestamp:
  `t=1735689600,v1=<hex>`. Publish verification code samples — most consumers
  will get it wrong otherwise.
- Retry with exponential backoff over hours, then dead-letter and notify the
  customer in your dashboard.
- Send a **minimal payload with an id and a type**; let consumers fetch current
  state. Full-object payloads deliver stale data on retry.
- Give every event a stable id, and document at-least-once delivery so consumers
  build deduplication.
- Timeout fast (5–10s). Document that consumers must acknowledge quickly.
- Provide a delivery log, a manual replay button, and a test-event sender.
- Let customers rotate the signing secret with an overlap window.

---

## The transactional outbox

The dual-write problem: you commit a database transaction *and* publish an event.
Either can fail after the other succeeds, and you get an event for a rolled-back
transaction, or a committed change nobody was told about.

```sql
BEGIN;
  UPDATE orders SET status = 'paid' WHERE id = $1;
  INSERT INTO outbox (id, topic, payload, created_at)
       VALUES (gen_random_uuid(), 'order.paid', $2, now());
COMMIT;
-- A separate poller publishes from `outbox` and marks rows sent.
-- Publish may happen twice; consumers deduplicate. It cannot happen zero times.
```

This converts an impossible guarantee (distributed atomicity) into an achievable
one (at-least-once with idempotent consumers). Use it wherever a state change and
a notification must not diverge.

---

## Polling, when webhooks are not available

- Use cursors or `updated_since`, never full scans.
- Store the last successful cursor durably; resume from it.
- Handle the boundary carefully — records updated during the poll window are the
  classic source of missed or duplicated items. Overlap slightly and deduplicate.
- Back off when there is nothing new; do not poll a quiet endpoint every second.
- Respect the provider's rate limits, and handle `429` properly.

---

## Third-party client hygiene

- **Wrap every SDK in your own thin interface.** Not for the abstraction's sake,
  but so that the vendor's types do not leak into your domain, so you can add
  logging, timeouts and metrics in one place, and so replacing the vendor is a
  bounded change.
- Pin the SDK version; read the changelog before upgrading a payment or auth SDK.
- Keep credentials in the secret manager; scope them minimally; know how to
  rotate them.
- **Test against a sandbox**, and record fixtures for CI. Never let a test suite
  call a live third party — it is slow, flaky, and occasionally expensive.
- Log every outbound call with duration and status. When a vendor is degraded,
  you should know before their status page says so.
- Understand the failure semantics: what does a timeout mean for that operation?
  For a payment, a timeout means "unknown" — never "failed". Treating unknown as
  failed is how customers get charged twice.

---

## Handling degradation

Decide, per integration, what happens when it is unavailable:

| Integration | If down |
|---|---|
| Payments | Fail the request with a clear message. Never silently succeed |
| Email | Queue and retry. Never block the user's request |
| Analytics | Drop silently. Never let analytics break the product |
| Auth provider | Fail closed. An auth outage must not become an auth bypass |
| Search | Degrade to a database query, even a worse one |
| Feature flags | Serve cached last-known values; have a compiled-in default |
| Storage upload | Retry, then fail with a clear message and no partial state |

Write this table for your own system. The exercise finds the integrations nobody
thought about — and the ones where the current behaviour is "hang for 60 seconds
then 500".

---

## Review checklist

- [ ] Every outbound call has connect and read timeouts
- [ ] Retries are bounded, backed off, jittered, and only on retriable conditions
- [ ] Retried mutations are idempotent
- [ ] Circuit breakers on request-path dependencies
- [ ] No external call inside a database transaction
- [ ] Inbound webhooks: signature verified on the raw body, before parsing
- [ ] Inbound webhooks: deduplicated, acknowledged fast, processed async
- [ ] Outbound webhooks: signed, retried, replayable, minimal payload
- [ ] Outbox pattern where a state change and an event must not diverge
- [ ] Vendor SDKs wrapped behind an internal interface
- [ ] Sandbox or recorded fixtures in tests; no live third parties in CI
- [ ] A documented degradation behaviour per integration
