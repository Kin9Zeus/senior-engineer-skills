---
name: observability-slo
description: Observability and reliability engineering — structured logging, metrics, distributed tracing, correlation ids, error tracking, dashboards, SLIs/SLOs and error budgets, alerting that pages on symptoms rather than causes, on-call practice, incident response and blameless postmortems. Use when the user says "logging", "monitoring", "observability", "metrics", "tracing", "Prometheus", "Grafana", "Datadog", "Sentry", "OpenTelemetry", "SLO", "SLA", "uptime", "alerting", "on-call", "incident", "postmortem", "how do we know if it breaks", "it broke and we didn't notice" or "debugging production"; and as a pass in any project audit. By Devleck.
license: MIT
---

# Observability and Reliability

The question this discipline answers is not "is the server up". It is:

> **When a user has a bad experience right now, can we tell — and can we find out
> why without deploying new code?**

A system you cannot debug from its own output is a system you debug by guessing.

---

## The three signals, and what each is for

| Signal | Answers | Cost |
|---|---|---|
| **Metrics** | *Is something wrong?* Aggregate, cheap, alertable | Low, until cardinality explodes |
| **Traces** | *Where is it wrong?* One request across every service | Medium, sample it |
| **Logs** | *Why is it wrong?* Full detail for one event | High at volume |

You need all three, and they must be **linked**: a metric spike leads to an
exemplar trace, which leads to the log lines for that request. Three
disconnected tools mean three separate investigations and a much longer
time-to-diagnosis.

Use OpenTelemetry as the instrumentation layer — it keeps the vendor decision
reversible, which matters because observability vendors are expensive and
switching is otherwise a rewrite.

---

## Structured logging

```json
{"ts":"2026-08-24T16:18:12.451Z","level":"error","msg":"payment.capture_failed",
 "trace_id":"4bf92f...","span_id":"00f067...","request_id":"req_01HQ8",
 "user_id":"usr_01HQ8","org_id":"org_01HQ8","payment_id":"pay_01HQ8",
 "provider":"stripe","error_code":"card_declined","duration_ms":842}
```

**Rules**

1. **JSON, not prose.** Grep does not scale; structured queries do.
2. **A correlation id on every line**, generated at the edge (or accepted from
   the client), propagated through every service, job and outbound call. This
   single field is the difference between a two-minute investigation and a
   two-hour one.
3. **Log events, not sentences.** `payment.capture_failed` with fields beats
   `"Failed to capture payment for user 123"` — the first is queryable and
   aggregatable, the second is a string.
4. **Levels with meaning.** `error` = a human should look. `warn` = degraded but
   handled. `info` = business events worth keeping. `debug` = off in production.
   If everything is `error`, nothing is.
5. **Never log secrets or personal data.** Tokens, passwords, card numbers, full
   request bodies, authorization headers. Implement redaction as a **layer in the
   logger**, not as a habit at each call site. Logs are frequently the least
   protected copy of your data, and they are shipped to third parties.
6. **Log at boundaries**: request in/out, external call in/out, job start/end,
   state transitions. Not every line of business logic.
7. Retention bounded deliberately — a cost control *and* a privacy obligation.

---

## Metrics

**The four that matter for a request-serving system** (RED / golden signals):

```
Rate        requests per second, by route and status class
Errors      error rate, by route and error class
Duration    p50, p95, p99 latency, by route
Saturation  how full the constrained resource is — pool, queue, memory, CPU
```

Plus, for anything with a queue: **queue depth** and **oldest-message age**.
Oldest-message age is the metric that catches a stalled worker, and it is the one
teams forget.

Plus **business metrics**: signups, payments, core actions completed. A technical
dashboard showing green while zero orders are being placed is a monitoring
failure. Business metrics catch the outages that infrastructure metrics cannot
see.

**Cardinality is the cost driver.** Never put a user id, request id, full URL
path with parameters, or an unbounded value in a metric label. Those belong in
traces and logs. One careless label can multiply your bill by a thousand.

**Percentiles, not averages.** An average latency of 200ms is consistent with
90% of users at 50ms and 10% at 1.5 seconds. Average hides exactly what you need
to see. And never average percentiles across instances — that is not a
percentile.

---

## SLIs, SLOs and error budgets

**SLI** — a measurement of user experience. **SLO** — the target. **Error
budget** — how much you are permitted to miss.

Start with two per critical journey:

```
Availability SLI  = successful requests / total requests           (excluding 4xx client errors)
Latency SLI       = requests faster than threshold / total requests

SLO: 99.9% availability over 30 days   → error budget: 43 minutes
     99% of requests under 300ms
```

**Choosing the number.** 99.9% is a reasonable default for a paid product. Each
additional nine multiplies cost roughly tenfold. **99.99% is not achievable if
you depend on services that do not offer it** — your ceiling is the product of
your dependencies' availability. Do not publish an SLA you cannot structurally
meet.

**The error budget is the point.** It converts reliability from an argument into
arithmetic:

- **Budget remaining** → ship features, take risks, deploy on Friday.
- **Budget exhausted** → reliability work takes priority until it recovers.

Agree this policy before you need it, with whoever owns the roadmap. Its value is
that it ends the recurring argument between shipping and stability by making the
trade-off explicit and measurable.

Measure the SLI **from the user's side** where you can — real user monitoring,
or a synthetic probe from outside your network. A server-side metric cannot see
the outage where your load balancer was unreachable.

---

## Alerting

**Alert on symptoms, not causes.** Page when users are having a bad time. CPU at
90% with healthy latency and no errors is not an incident; it is a well-utilised
machine.

| Page a human | Ticket, do not page | Never alert |
|---|---|---|
| Error rate above SLO burn rate | Disk at 70% | CPU high |
| Latency above SLO | Certificate expiring in 30 days | Memory high |
| Core business metric at zero | Elevated retry rate | A single failed request |
| Queue oldest-message age growing | Non-critical job failing | Deploy happened |
| Health check failing across instances | Cost anomaly | |

**Every paging alert must satisfy all four:**
1. **Urgent** — it needs action now, not tomorrow.
2. **Actionable** — there is something a human can do.
3. **Linked to a runbook** — the alert names the document.
4. **Real** — it is not a known-noisy alert people have learned to dismiss.

An alert failing any of these should be downgraded or deleted. **Alert fatigue
is the primary cause of missed incidents** — every noisy page trains the on-call
engineer to dismiss the next one.

**Burn-rate alerting** beats simple thresholds: alert when you are consuming the
error budget fast enough to exhaust it early. Use a fast burn (page) and a slow
burn (ticket) so a slow degradation is caught without a 3am page for it.

---

## Tracing

- Instrument every service boundary, database call and external HTTP call.
- Propagate W3C `traceparent` across every hop, including queues (put it in the
  message).
- Sample intelligently: keep **all** errors and slow requests, sample the fast
  successful ones (1–10%). Tail-based sampling if your backend supports it.
- Add span attributes for the identifiers you will search by: user, org,
  resource id. Never for secrets.
- Link traces to logs by trace id, and to metrics by exemplar.

Traces earn their cost the first time a latency problem is in a dependency you
did not suspect.

---

## The minimum viable setup

For a small project with no observability, in priority order:

1. **Error tracking** (Sentry or equivalent) with source maps and release
   tagging. Highest value per hour of setup, by a wide margin.
2. **Structured logs with a correlation id**, shipped somewhere queryable.
3. **An uptime check** from outside your network, on the critical path — not on
   `/health`, which is famously green while the app is broken.
4. **One dashboard**: request rate, error rate, p95 latency, plus your single
   most important business metric.
5. **One alert that pages a human** on user-visible errors.
6. Then traces, SLOs and the rest.

Steps 1–5 are a day of work and cover most of the value.

---

## Incidents

```
DETECT    → alert, or a customer report (count how often it is the second —
            that ratio is a monitoring KPI)
DECLARE   → name it. A named incident has an owner
ROLES     → Incident Lead (coordinates, does not debug), Comms, Operators
MITIGATE  → stop the bleeding. Roll back, disable the flag, scale up.
            RESTORING SERVICE COMES BEFORE FINDING THE CAUSE
COMMUNICATE → status page and internal updates on a fixed cadence, even when
            the update is "still investigating"
RESOLVE   → confirm recovery with metrics, not with hope
LEARN     → blameless postmortem within a week
```

**The postmortem must be blameless.** Not out of politeness — because a culture
that blames individuals produces engineers who hide information, and hidden
information is how the same incident happens twice. Ask what about the *system*
allowed a reasonable person to make that decision.

Every postmortem produces **owned, dated action items**, tracked like any other
work. A postmortem whose actions are never done is a document, not a learning
process.

---

## Review checklist

- [ ] Structured JSON logs with a correlation id propagated end to end
- [ ] Secrets and personal data redacted by a logging layer
- [ ] Error tracking wired, with releases and source maps
- [ ] RED metrics per route; queue depth and oldest-message age where relevant
- [ ] At least one business metric monitored
- [ ] Distributed tracing across services, with errors always sampled
- [ ] SLIs measured from the user's perspective; SLOs defined and published
- [ ] An error budget policy agreed with the roadmap owner
- [ ] Alerts page on symptoms; every page is urgent, actionable and runbooked
- [ ] External uptime check on the real user path
- [ ] Runbooks for the top failure modes, linked from alerts
- [ ] A named on-call rotation and escalation path
- [ ] Postmortems are blameless and produce owned action items
- [ ] Metric cardinality bounded; log retention deliberate

## References

- `references/telemetry-setup.md` — instrumentation, per stack
- `references/slo-and-incidents.md` — SLO maths, error budgets, incident process, postmortem template
