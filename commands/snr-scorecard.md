---
description: Fast 15-domain health scorecard with a 0-100 rating and the three weakest areas named. One screen, no full report.
argument-hint: "[path or URL]"
---

# Engineering Scorecard

Score: **$ARGUMENTS** (default: the current repository).

This is the **fast** assessment — one screen, a number, and the three things to
fix first. For the full findings report with reproductions and fixes, use
`/snr-audit`.

Load `senior-engineer` for the rubric in
`references/severity-and-reporting.md`.

## Gather evidence quickly

```bash
skills/project-audit/scripts/recon.sh          # read-only, ~30 seconds
skills/security-hardening/scripts/secret-scan.sh
skills/web-presence-audit/scripts/web-check.sh <url>   # if there is a live site
```

Then the seven high-yield checks from
`project-audit/references/quick-scan.md`: secrets, authorization on the hottest
routes, injection, data survivability, public surface, correctness signal, and
honest promises.

## Score

Fifteen domains, 0–10 each, weighted to 100.

| # | Domain | Wt | # | Domain | Wt |
|---|---|---:|---|---|---:|
| 1 | Security | 15 | 9 | Accessibility | 6 |
| 2 | Data & persistence | 12 | 10 | Web presence & SEO | 5 |
| 3 | Correctness & testing | 11 | 11 | Privacy & compliance | 6 |
| 4 | Architecture | 10 | 12 | Documentation | 4 |
| 5 | API design | 7 | 13 | Dependencies & supply chain | 5 |
| 6 | DevOps & delivery | 8 | 14 | Developer experience | 4 |
| 7 | Observability | 7 | 15 | Cost & scalability | 4 |
| 8 | Performance | 6 | | | |

**Bands** — 0–39 Critical · 40–59 At risk · 60–74 Functional ·
75–89 Professional · 90–100 Exemplary

## Output — one screen

```markdown
## <Project> — Engineering Scorecard          <commit> · <date>

# 58/100 — At risk

**Weakest:** Privacy 2/10 · Observability 3/10 · Testing 4/10

| Domain | Score | Evidence |
|---|---:|---|
| Security | 6/10 | Headers set, deps current. No rate limit on /login (`auth.ts:41`) |
| Data | 7/10 | Migrations reversible. Backups configured but never restored |
| Testing | 4/10 | 31 unit tests, no integration or E2E. CI does not block |
| ... | | |

## Fix these three first
1. **No privacy policy, and PostHog + Intercom receive personal data** —
   `P0`, legal exposure from day one. ~4h.
2. **Backups never restored** — `P1`, recovery capability is unverified. ~1d.
3. **No error tracking** — `P1`, faults are invisible. ~2h.

## Blockers for launch
<the P0 list, or "none">

## Not assessed
<explicit — this section is mandatory>
```

## Rules

- **Evidence in every row.** A score without a reason is a guess. One line,
  with a location.
- **Do not inflate.** The point of the number is to be uncomfortable enough to
  fund the fix. A generous score is a disservice to someone who asked for a
  senior review.
- **Grade against what the project claims to be** — but hold every project to
  identical standards on secrets in git, cross-user data access, backups, and
  honest privacy claims.
- **Say what you did not check.** A domain you could not assess scores nothing;
  it goes in "Not assessed".
