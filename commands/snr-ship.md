---
description: Run the go/no-go release gate and produce an explicit ship or do-not-ship verdict with named blockers, accepted risks and a rollback plan.
argument-hint: "[version or scope]"
---

# Release Readiness Gate

Assess readiness to ship: **$ARGUMENTS**

Load `release-readiness`. Load the domain skills for anything that needs a
deeper look.

## Produce one of three verdicts, in writing

```
GO              No blockers. Ship.
GO WITH RISK    Named, owned, accepted risks. Ship, with mitigations listed.
NO GO           Named blockers. Do not ship until these close.
```

**Never soften a `NO GO` into "mostly ready".** If a blocker is real, say no in
the first sentence and name it. A gate that has never produced a `NO GO` is not
a gate.

## Check the blockers first — any one is `NO GO`

These are not judgement calls. Each causes a breach, data loss or legal exposure
the launch cannot be undone from.

- [ ] A secret in the repository or its git history
- [ ] Any user can access another user's data (test it: auth as A, request B's)
- [ ] No backups, or backups never restored
- [ ] Personal data processed with no policy, or a policy omitting a real processor
- [ ] No working data-deletion path where one is promised or required
- [ ] Payment amounts computed or trusted from the client
- [ ] A webhook that mutates state without verifying its signature
- [ ] String-interpolated SQL on a user-reachable route
- [ ] Debug mode on, or stack traces returned to clients
- [ ] No rollback path that anyone has ever executed
- [ ] A migration with no tested reverse running against production data
- [ ] A known critical vulnerability in a reachable dependency

If any are unticked, the verdict is `NO GO` and the report is short.

## Then the full gate

Nine areas — security, data, legal/trust, public surface, accessibility,
correctness, operations, performance, documentation. The complete checklist with
verification commands is in `references/launch-checklist.md`.

Run the automated helpers where they apply:
```bash
skills/security-hardening/scripts/secret-scan.sh
skills/web-presence-audit/scripts/web-check.sh <url>
```

## Capture the pre-launch baseline

Without it you cannot tell whether the post-launch numbers are bad.

```
Error rate · p50/p95/p99 latency · Core Web Vitals (p75) ·
conversion on the core journey · DB connections at peak · monthly cost
```

## Output

Use `templates/go-no-go.md`. Mandatory sections:

- **Verdict** in the first line, with the estimated time to `GO`.
- **Blockers** — each with an owner, an estimate and a verification step.
- **Accepted risks** — each with a mitigation and a **named person who accepted
  it**. An unowned risk is a blocker.
- **Verified working** — named specifically. A report listing only problems
  misrepresents the work done.
- **Not assessed** — mandatory. Scope limits belong in the verdict, not
  discovered afterwards.
- **Launch plan** — window, sequence, who watches, the rollback trigger
  condition, the rollback procedure and its **measured** duration.

## Calibration

Scale the gate to the stakes: an internal tool and a fintech are not held to the
same standard on load testing or observability. They are held to **identical**
standards on secrets in git, cross-user data access, backups, and honest privacy
claims.

Do not gate on perfection. `GO WITH RISK` is the common and correct verdict for
a healthy team — the value is that the risks are named, owned and accepted
deliberately rather than discovered later.
