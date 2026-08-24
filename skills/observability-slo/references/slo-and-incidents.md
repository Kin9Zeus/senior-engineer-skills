# SLOs, Error Budgets and Incident Response

## Defining an SLI

An SLI measures **user experience**, expressed as a ratio of good events to
valid events.

```
availability = successful requests / valid requests
latency      = requests faster than T / valid requests
freshness    = pipeline runs completed within T / total runs
correctness  = records processed without error / total records
```

Getting the denominator right is most of the work:

- **Exclude client errors** (`4xx`) from availability — a user sending a
  malformed request is not your outage. But **include `429`**: rate-limiting a
  legitimate user *is* a degraded experience you caused.
- Exclude health-check and bot traffic.
- **Measure per critical journey**, not per service. "Checkout works" is what a
  user cares about; "the inventory service is up" is not.
- Measure **as close to the user as possible**. Server-side metrics cannot see
  the outage where your load balancer was unreachable — that is what synthetic
  probes and real user monitoring are for.

---

## Choosing the SLO

| Target | Downtime / 30 days | Realistic when |
|---|---|---|
| 99% | 7h 12m | Internal tools, early-stage products |
| 99.5% | 3h 36m | Most small SaaS |
| **99.9%** | **43m** | **A sensible default for a paid product** |
| 99.95% | 21m | Requires redundancy and mature on-call |
| 99.99% | 4m 19m | Multi-region, automated failover, a dedicated team |

Two rules that get ignored:

**Your ceiling is the product of your dependencies.** If your identity provider
offers 99.9% and your database offers 99.95%, you cannot offer 99.99% — the
arithmetic does not permit it. Check what you actually depend on before
publishing a number.

**The SLA must be looser than the SLO.** The SLO is your internal target; the
SLA is the contractual promise with financial consequences. Set the SLA at least
one step below the SLO so you have headroom before you owe credits.

**100% is not a target.** It means no maintenance, no deploys and no risk-taking,
and it will be missed anyway. An SLO that is never missed is set too low to
inform any decision.

---

## Error budgets

```
SLO 99.9% over 30 days  →  0.1% × 30d  =  43 minutes of permitted badness
```

The budget converts reliability from an opinion into arithmetic:

| Budget state | Policy |
|---|---|
| > 50% remaining | Ship. Take risks. Deploy on Friday |
| 10–50% remaining | Ship, with more care on risky changes |
| < 10% remaining | Freeze risky changes; reliability work is prioritised |
| Exhausted | Feature freeze until the budget recovers. Incident review |

**Agree this policy before you need it**, with whoever owns the roadmap. Its
whole value is that it ends the recurring argument between shipping and stability
by making the trade-off explicit, measured and pre-negotiated.

**Burn-rate alerting** is the correct way to alert on an SLO:

| Burn rate | Budget consumed in | Action |
|---|---|---|
| 14.4x | 2% in 1 hour | **Page** — this exhausts the month in ~2 days |
| 6x | 5% in 6 hours | **Page** |
| 1x | Exactly on budget | Ticket |

Two windows (a short and a long one) prevent both false pages from brief blips
and missed slow degradations.

---

## Incident response

### Severity

| | Definition | Response |
|---|---|---|
| **SEV1** | Complete outage, data loss, or a security breach | Page immediately. All hands. Status page. Customer comms |
| **SEV2** | Major feature broken, or severe degradation for many users | Page. Fix now |
| **SEV3** | Minor feature broken, or a workaround exists | Business hours |
| **SEV4** | Cosmetic or single-user | Backlog |

Err upward. Downgrading a SEV1 costs nothing; discovering three hours late that
a SEV3 was a SEV1 costs a great deal.

### Roles — assign them out loud

- **Incident Lead** — coordinates, decides, tracks the timeline. **Does not
  debug.** The most common failure in a small-team incident is that the only
  coordinator is also the only person fixing it, so nobody communicates.
- **Communications** — status page, internal updates, customer replies.
- **Operators** — the people actually investigating and fixing.
- **Scribe** — timestamps everything. Invaluable in the postmortem, impossible
  to reconstruct afterwards.

### The sequence

```
1. DECLARE       Name it. Open a channel. Assign the lead.
2. ASSESS        Scope: who is affected, how badly, since when?
3. COMMUNICATE   Status page within 15 minutes for a SEV1. Say what you know,
                 what you don't, and when you will update again.
4. MITIGATE      STOP THE BLEEDING FIRST. Roll back, disable the flag, scale up,
                 fail over. Do not diagnose before restoring service — the cause
                 will still be there in an hour; the users will not.
5. VERIFY        Confirm recovery with metrics, not with a hopeful refresh.
6. RESOLVE       Close the incident. Final customer communication.
7. LEARN         Blameless postmortem within a week.
```

**"What changed?" is the first diagnostic question**, and the answer is usually a
deploy, a flag, a config change, or a third party. Annotate deploys on your
dashboards so this takes seconds.

### Communication template

```
[INVESTIGATING] 16:42 UTC — We are investigating elevated error rates
affecting checkout. Some users may be unable to complete a purchase.
Next update by 17:00 UTC.

[IDENTIFIED] 17:01 UTC — Cause identified: a database connection pool
exhaustion following a deploy at 16:30. Rolling back now.

[MONITORING] 17:14 UTC — Rollback complete, error rates returning to
normal. Monitoring for 30 minutes.

[RESOLVED] 17:48 UTC — Resolved. Checkout was degraded between 16:31 and
17:16 UTC; approximately 4% of purchase attempts failed and can be
retried. A full postmortem will be published within five business days.
```

Update on a fixed cadence **even when there is nothing new** — "still
investigating, next update in 20 minutes" prevents the flood of "any news?" that
distracts the people fixing it.

---

## The postmortem

**Blameless is not politeness. It is epistemics.** A culture that blames
individuals produces engineers who withhold information, and withheld information
is how the same incident happens twice. Ask what about the *system* allowed a
competent person, acting reasonably with the information they had, to make that
choice.

```markdown
# Postmortem — <short title>

**Date** 2026-08-24 · **Duration** 45m · **Severity** SEV2
**Authors** · **Status** Draft / Reviewed

## Impact
Who was affected, how many, how badly, for how long. In user terms and in
numbers. "4% of checkout attempts failed for 45 minutes; 312 users affected;
~$8,400 in delayed revenue, all recoverable."

## Timeline (UTC)
| Time | Event |
|---|---|
| 16:30 | Deploy of #4821 to production |
| 16:31 | Error rate begins rising |
| 16:38 | Alert fires (7 minutes after onset — see action item 3) |
| 16:42 | Incident declared, lead assigned |
| 17:01 | Cause identified |
| 17:16 | Rollback complete, recovery confirmed |

## What happened
The technical narrative. Precise, factual, no blame, no adjectives.

## Why it happened
Contributing factors — plural. Real incidents have several. Ask "why" until you
reach something structural rather than someone's individual error.
- The change increased per-request connection usage without a load test.
- Pool saturation was not alerted on.
- Staging has 1/50th the traffic, so it could not surface the problem.

## What went well
Name it. Fast rollback, good communication, the alert that did fire. Incident
response improves by reinforcing what worked, not only by cataloguing failures.

## What did not go well
- Detection took 7 minutes; the alert threshold was too loose.
- The runbook did not cover pool exhaustion.

## Where we got lucky
The most under-used section. What would have made this much worse?
"It happened at 16:30 on a Tuesday. At 02:00 detection would have taken far
longer."

## Action items
| # | Action | Type | Owner | Due |
|---|---|---|---|---|
| 1 | Alert on connection pool utilisation > 80% | Detect | @a | 2026-08-31 |
| 2 | Load test connection usage in CI for DB-touching changes | Prevent | @b | 2026-09-15 |
| 3 | Tighten error-rate alert to 2-minute window | Detect | @a | 2026-08-27 |
| 4 | Add pool exhaustion to the runbook | Mitigate | @c | 2026-08-31 |
```

Classify every action as **prevent**, **detect** or **mitigate**. A postmortem
with only prevention items has not improved your response to the next, different
incident.

**Track action items like any other work.** A postmortem whose actions are never
completed is a document, not a learning process — and the same incident will
recur, with the postmortem sitting there as evidence you knew.

---

## On-call

- A **named rotation** with a **named escalation path**. "Whoever notices" is not
  on-call.
- Compensated, or at minimum time-in-lieu. Unpaid on-call is unsustainable and
  produces slow, resentful responses.
- Everyone on the rotation has: production access, the runbooks, the escalation
  numbers, and has practised at least one drill.
- A **handover** at rotation change: open issues, ongoing risks, recent changes.
- **Page volume is a KPI.** More than one or two pages per week per person is
  unsustainable and produces alert fatigue. If the volume is high, the fix is to
  reduce the alerts and fix the causes, not to endure it.
- Track: how often did a customer tell you before your monitoring did? That
  ratio is the single best measure of monitoring quality.
