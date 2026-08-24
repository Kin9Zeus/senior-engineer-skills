# Telemetry Setup

Instrument once, through OpenTelemetry, so the backend stays a reversible
decision. Observability vendors are expensive and switching is otherwise a
rewrite of every instrumentation call.

---

## The correlation id — do this first

One field, propagated everywhere, is worth more than any dashboard.

```ts
// platform/context.ts — request-scoped context, available anywhere in the call
import { AsyncLocalStorage } from "node:async_hooks";

type Ctx = { requestId: string; traceId?: string; userId?: string; orgId?: string };
export const ctx = new AsyncLocalStorage<Ctx>();
export const current = () => ctx.getStore();
```

```ts
// The edge middleware — accept an inbound id or mint one, and always echo it
app.use((req, res, next) => {
  const requestId = req.header("x-request-id") ?? `req_${ulid()}`;
  res.setHeader("x-request-id", requestId);
  ctx.run({ requestId, traceId: trace.getActiveSpan()?.spanContext().traceId }, next);
});
```

Then: the logger reads it automatically, the HTTP client forwards it as a header,
the queue producer puts it in the message, and the consumer restores it. Every
log line in the system, across every service and job, can be filtered to one
user's one request.

**Echo it back to the client** so a support ticket can carry the id. "Something
went wrong (ref: req_01HQ8)" turns an unreproducible bug report into a single
query.

---

## Logging

```ts
// platform/logger.ts
import pino from "pino";

const REDACT = [
  "password", "token", "secret", "authorization", "cookie", "apiKey",
  "card", "cvv", "ssn", "req.headers.authorization", "req.headers.cookie",
  "*.password", "*.token",
];

export const logger = pino({
  level: config.LOG_LEVEL,
  redact: { paths: REDACT, censor: "[redacted]" },
  formatters: { level: (label) => ({ level: label }) },
  timestamp: pino.stdTimeFunctions.isoTime,
  mixin: () => {
    const c = current();
    return c ? { request_id: c.requestId, trace_id: c.traceId, user_id: c.userId } : {};
  },
});
```

**Redaction must be a layer, not a habit.** Relying on every engineer to remember
not to log a request body guarantees that one day someone logs a request body.

**Event naming**: `domain.action_outcome` — `payment.capture_failed`,
`user.signup_completed`, `job.export_started`. Namespaced, aggregatable,
greppable, and stable enough to alert on.

**What to log at each boundary**

| Boundary | Fields |
|---|---|
| Request in | method, route (the *pattern*, not the filled path), status, duration, user, org |
| Request out | host, operation, status, duration, retry count |
| Database | operation, table, duration, row count — **never the parameter values** |
| Job | name, id, attempt, duration, outcome |
| State change | entity, id, from, to, actor |
| Auth | event, user, source ip, outcome |

Log the route *pattern* (`/users/:id`), not the concrete path — otherwise every
request is a unique value and aggregation is impossible.

---

## OpenTelemetry

```ts
// platform/telemetry.ts — imported FIRST, before any instrumented library
import { NodeSDK } from "@opentelemetry/sdk-node";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { resourceFromAttributes } from "@opentelemetry/resources";

const sdk = new NodeSDK({
  resource: resourceFromAttributes({
    "service.name": config.SERVICE_NAME,
    "service.version": config.GIT_SHA,
    "deployment.environment": config.NODE_ENV,
  }),
  traceExporter: new OTLPTraceExporter({ url: config.OTEL_ENDPOINT }),
  instrumentations: [getNodeAutoInstrumentations({
    "@opentelemetry/instrumentation-fs": { enabled: false },   // very noisy
  })],
});
sdk.start();
```

Auto-instrumentation covers HTTP, database drivers and popular clients. Add
manual spans for business operations that matter:

```ts
await tracer.startActiveSpan("checkout.complete", async (span) => {
  span.setAttributes({ "order.id": order.id, "order.total": order.total,
                       "org.id": order.orgId });
  try {
    return await completeCheckout(order);
  } catch (err) {
    span.recordException(err);
    span.setStatus({ code: SpanStatusCode.ERROR });
    throw err;
  } finally {
    span.end();
  }
});
```

**Never put a secret or raw personal data in a span attribute.** Traces are
frequently retained longer and shared more widely than logs.

**Sampling**: keep all errors and all slow requests; sample fast successes at
1–10%. Tail-based sampling (decide after the trace completes) is strictly better
if your backend supports it, because head-based sampling throws away the errors
you needed before it knows they were errors.

---

## Metrics

```ts
const httpDuration = meter.createHistogram("http.server.duration", {
  unit: "ms", description: "Request duration",
});

httpDuration.record(ms, {
  "http.route": req.route?.path ?? "unmatched",   // the PATTERN
  "http.method": req.method,
  "http.status_code": String(res.statusCode),
});
```

**The cardinality rule.** Every unique combination of label values is a separate
time series with a separate cost. Safe labels: route pattern, method, status
class, service, environment, region. **Never**: user id, request id, full URL,
email, session id, or anything unbounded. One careless label can multiply your
bill by a thousand and make queries time out.

If you need per-user detail, that is what traces and logs are for.

**Instrument the queue**, if you have one:
```
queue.depth              gauge
queue.oldest_message_age gauge     ← the one that catches a stalled worker
queue.processed          counter   by outcome
queue.duration           histogram
```

---

## Error tracking

The highest value-per-hour setup step. Configure properly:

```ts
Sentry.init({
  dsn: config.SENTRY_DSN,
  environment: config.NODE_ENV,
  release: config.GIT_SHA,                 // makes "which deploy broke this" answerable
  tracesSampleRate: 0.1,
  beforeSend(event) {
    delete event.request?.cookies;
    delete event.request?.headers?.authorization;
    if (event.user) event.user = { id: event.user.id };   // id only, no email/ip
    return event;
  },
});
```

- **Upload source maps or symbols** on every release, or the stack traces are
  minified noise.
- **Tag with the release SHA** so regressions are attributable to a deploy.
- Set the user context to an **id only**. Sending email addresses to an error
  tracker is a data flow that belongs in your privacy policy — avoid creating it.
- Group and triage. An error tracker nobody triages becomes a wall of noise, and
  then the real regression arrives and is not noticed.

---

## Health endpoints

```ts
// Liveness: is the process itself functional? MUST NOT check dependencies —
// a database blip should not cause the orchestrator to kill every instance.
app.get("/health", (_, res) => res.json({ status: "ok" }));

// Readiness: should this instance receive traffic right now?
app.get("/ready", async (_, res) => {
  const checks = await Promise.allSettled([pingDb(), pingCache()]);
  const ok = checks.every((c) => c.status === "fulfilled");
  res.status(ok ? 200 : 503).json({ status: ok ? "ready" : "not_ready" });
});
```

Confusing the two is a common and damaging mistake: a liveness probe that checks
the database restarts every instance during a database blip, turning a partial
degradation into a total outage.

**Neither endpoint proves the application works.** Uptime monitoring must hit a
real user path — an endpoint that queries the database and renders something —
from outside your network.

---

## Frontend telemetry

- **Real User Monitoring** for Core Web Vitals (LCP, INP, CLS) from actual users
  on actual devices. Lab numbers from a fast machine on a fast connection are not
  what your users experience.
- Client error tracking with source maps, filtering browser-extension noise
  (which is otherwise most of the volume).
- **Send the correlation id with every API call** so a client error and a server
  error can be joined.
- Instrument the funnel steps that matter, not every click.
- Remember: **client telemetry is a third-party data flow** and belongs in the
  privacy policy and behind consent where required.

---

## Cost control

Observability bills can rival infrastructure bills. The three controls:

1. **Log volume** — do not log every successful request body. Sample high-volume
   info logs. Set retention deliberately (30 days hot is usually plenty; archive
   to cheap storage if you need longer).
2. **Metric cardinality** — audit label sets. This is where surprise bills come
   from.
3. **Trace sampling** — 1–10% of successes is ample when errors are always kept.

Set a budget alert on the observability vendor too.
