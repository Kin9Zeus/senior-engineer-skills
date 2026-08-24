---
name: release-readiness
description: The go/no-go gate before shipping — a structured launch checklist across security, data, legal, operations, performance, accessibility and rollback, producing an explicit ship or do-not-ship decision with named blockers. Use when the user says "ready to launch", "go live", "ship it", "pre-launch", "launch checklist", "release checklist", "production ready", "deploy to production", "v1", "MVP launch", "are we ready" or "what's left before we ship"; and after any project audit, to convert findings into a gate. By Devleck.
license: MIT
---

# Release Readiness

The purpose of a gate is to make a decision **explicit** rather than implicit.
Shipping with known gaps is legitimate — shipping without knowing what they are
is not.

Produce one of three verdicts, in writing:

```
GO              No blockers. Ship.
GO WITH RISK    Named, accepted, owned risks. Ship, with mitigations listed.
NO GO           Named blockers. Do not ship until these close.
```

Never soften a `NO GO` into "mostly ready". If a blocker is real, say so in the
first line and name it.

---

## The blockers — any one of these is `NO GO`

These are not judgement calls. Each one causes a breach, data loss, or a legal
exposure that the launch cannot be undone from.

- [ ] **A secret is in the repository or its git history.** Rotate first, then
      purge.
- [ ] **Any user can access another user's data.** Test it: authenticate as A,
      request B's resource.
- [ ] **No backups**, or backups that have never been restored.
- [ ] **Personal data is processed with no privacy policy**, or a policy that
      omits a processor actually receiving data.
- [ ] **No way to delete user data** when the policy or the law says there is.
- [ ] **Payments where amounts are computed or trusted from the client.**
- [ ] **A webhook that mutates state without verifying its signature.**
- [ ] **String-interpolated SQL on a route reachable by a user.**
- [ ] **Debug mode enabled**, or stack traces returned to clients.
- [ ] **No rollback path** that anyone has ever executed.
- [ ] **A migration with no tested reverse** running against production data.
- [ ] **A known critical vulnerability** in a reachable dependency.

If any box is unticked, the verdict is `NO GO` and the report is short.

---

## The gate

### 1 · Security

- [ ] Secret scan clean, including git history
- [ ] Object-level authorization tested — the cross-user test exists and passes
- [ ] Authentication: hashing, session invalidation, rate limits, no user
      enumeration
- [ ] Input validated by schema at every entry point, including webhooks and
      queue consumers
- [ ] Security headers set; CSP without `unsafe-inline`
- [ ] Dependency audit run, output read, high-severity issues resolved or
      accepted in writing
- [ ] Debug off; stack traces not returned; admin surfaces network-restricted
- [ ] Rate limiting on auth and all mutations
- [ ] Uploads: type verified by content, size capped, served from a separate origin

### 2 · Data

- [ ] Backups automated, encrypted, off-site — **and restored in a drill**, with
      the measured recovery time recorded
- [ ] Point-in-time recovery available
- [ ] Migrations tested against production-sized data, with reverses tested
- [ ] Migration ordering relative to deploy is correct for both directions
- [ ] Foreign keys indexed; the hottest queries have plans that were actually read
- [ ] `statement_timeout` and `idle_in_transaction_session_timeout` set
- [ ] Tenancy enforced in the database, not only in application code
- [ ] Retention rules defined per table and enforced by a monitored job

### 3 · Legal and trust

- [ ] Privacy policy published, accurate, dated, and generated from the real
      data inventory
- [ ] **Every third party in the code appears in the policy**
- [ ] Cookie consent gates scripts before consent — **tested in a private window**
- [ ] Self-service data export and deletion working end to end, reaching every
      processor
- [ ] Terms of service published
- [ ] Subprocessor list published; DPAs in force
- [ ] Breach response plan written, with a named decision-maker
- [ ] Support and security contacts published, with a stated response commitment

### 4 · Public surface

- [ ] Unique title and meta description on every page
- [ ] Canonical URLs correct — **check that no page canonicals to the homepage**
- [ ] `robots.txt` present and **does not contain `Disallow: /`**
- [ ] `sitemap.xml` generated and submitted
- [ ] **Custom 404 returning a real 404 status** (not a soft 404)
- [ ] Custom 500 leaking nothing
- [ ] Open Graph tags with a reachable absolute-URL image
- [ ] Structured data present and validated
- [ ] Alt text on every meaningful image
- [ ] Internal links resolve; no orphan pages
- [ ] Sticky mobile CTA does not obscure content or focus

### 5 · Accessibility

- [ ] Automated scan clean on the critical journeys
- [ ] **Keyboard-only completion of every critical journey**, with visible focus
- [ ] Screen reader pass on signup, the core action, and checkout
- [ ] Contrast passes in every state
- [ ] 400% zoom without horizontal scrolling
- [ ] Focus never obscured by sticky elements

### 6 · Correctness

- [ ] CI green and blocking merge
- [ ] The critical journeys are E2E tested and run before deploy
- [ ] Authorization matrix test present and passing
- [ ] No flaky tests in the blocking set
- [ ] Error paths tested, not just happy paths
- [ ] Manual smoke test of the critical journeys on staging **and** production
      after deploy

### 7 · Operations

- [ ] Error tracking wired, with releases and source maps
- [ ] Structured logs with a correlation id; **no personal data in logs**
- [ ] Health and readiness endpoints distinct; graceful shutdown implemented
- [ ] One dashboard: rate, errors, latency, plus one business metric
- [ ] **At least one alert that pages a human**, on a user-visible symptom
- [ ] External uptime check on a real user path
- [ ] **Rollback documented and executed at least once**
- [ ] On-call named; escalation path documented
- [ ] Runbooks for the three most likely failures
- [ ] Cost budget and anomaly alerts configured; autoscaling capped

### 8 · Performance

- [ ] Core Web Vitals measured and within budget on the key pages
- [ ] p95 latency measured against a stated budget
- [ ] Load tested at expected peak, with the first bottleneck named
- [ ] Caching configured with a stated invalidation rule
- [ ] Images optimised; LCP image preloaded and not lazy-loaded

### 9 · Documentation

- [ ] README gets a new engineer running in under 15 minutes
- [ ] ADRs for the one-way doors
- [ ] Runbooks current
- [ ] Changelog for this release

---

## Launch-day sequence

```
T-7d   Freeze non-critical changes. Run the full gate. Publish the verdict.
T-2d   Restore drill. Rollback rehearsal. Final dependency audit.
T-1d   Staging matches production. Smoke tests green. On-call confirmed.
       Status page ready. Support briefed on the response commitment.

T-0    Deploy in a low-traffic window if you can.
       Migrate → deploy → smoke test → watch.
       Someone watches dashboards for the first hour. Not "keeps an eye on" —
       watches.

T+1h   Error rate, latency, business metric — compared against the pre-launch
       baseline you captured.
T+24h  Review. Any surprises? Any alert that should have fired and did not?
T+7d   Retrospective. What did the gate miss? Add it to the gate.
```

**Capture a baseline before launch.** Without pre-launch numbers for error rate,
latency and conversion, you cannot tell whether the post-launch numbers are bad.

---

## Verdict format

```markdown
# Release Readiness — <project> v<version>
Date · Commit · Assessor

## Verdict: NO GO

Three blockers must close before launch. The largest is that any authenticated
user can read any other user's invoices, which would be a reportable data breach
on day one. Estimated time to clear all three: 2 days.

### Blockers
| # | Blocker | Owner | Estimate | Verification |
|---|---|---|---|---|
| 1 | IDOR on `/api/invoices/:id` | @a | 4h | Cross-user test passes |
| 2 | Backups never restored | @b | 1d | Drill completed, RTO recorded |
| 3 | Privacy policy omits PostHog and Intercom | @c | 2h | Policy matches code grep |

### Accepted risks (would be GO WITH RISK once blockers clear)
| Risk | Impact if it occurs | Mitigation | Accepted by |
|---|---|---|---|
| No load test above 200 concurrent | Unknown behaviour at a traffic spike | Autoscaling capped at 10; alert on p95 | @founder |

### Passed
<Named. A gate report that lists only problems misrepresents the work done.>

### Not assessed
<Explicit. Scope limits belong in the verdict, not discovered later.>
```

---

## Calibration

**Scale the gate to the stakes.** An internal tool for five people and a fintech
holding customer funds are not held to the same standard on load testing,
observability or process. They are held to **identical** standards on: secrets in
git, cross-user data access, backups, and honest privacy claims.

**Do not gate on perfection.** The gate exists to surface what is unknown or
unacceptable, not to block until everything is ideal. `GO WITH RISK` is the
common and correct verdict for a healthy team — the value is that the risks are
named, owned and accepted deliberately.

**Say no when it is no.** A gate that has never produced a `NO GO` is not a
gate.

## References

- `references/launch-checklist.md` — the full checklist, printable, with verification commands
- `templates/go-no-go.md` — the verdict document
- `templates/runbook.md` — the operational runbook template
