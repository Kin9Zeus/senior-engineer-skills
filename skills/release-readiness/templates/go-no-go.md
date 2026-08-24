# Release Readiness — `<Project>` `v<version>`

| | |
|---|---|
| **Date** | `YYYY-MM-DD` |
| **Commit** | `<sha>` |
| **Assessor** | `<name>` |
| **Scope** | `<what was assessed>` |
| **Decision owner** | `<who accepts the risk>` |

---

## Verdict: `GO` / `GO WITH RISK` / `NO GO`

> Two to four sentences, written for someone who will read nothing else. Can
> this ship? If not, what is the single largest problem and how long does it take
> to clear? If the answer is no, the first word is no.

| Severity | Count |
|---|---|
| Blockers | `n` |
| Accepted risks | `n` |
| Follow-ups (post-launch) | `n` |

**Estimated time to `GO`:** `<duration>`

---

## Blockers

> Any one of these makes the verdict `NO GO`. Each must be closed and verified
> before launch.

| # | Blocker | Why it blocks | Owner | Estimate | Verification |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |

**Expanded**

### B1 · `<title>`
- **Where** `path/file.ts:120`
- **Impact** `<the concrete consequence — who is harmed, how many, how>`
- **Fix** `<the change>`
- **Verify** `<the command or test that proves it closed>`

---

## Accepted risks

> Known gaps we are shipping with, deliberately. Each has an owner, a
> mitigation, and a named person who accepted it. An unowned risk is a blocker.

| Risk | Likelihood | Impact if it occurs | Mitigation | Accepted by | Revisit |
|---|---|---|---|---|---|
| | | | | | |

---

## Gate results

| Area | Status | Notes |
|---|---|---|
| Security | ✅ / ⚠️ / ❌ | |
| Data & recovery | | |
| Legal & privacy | | |
| Public surface | | |
| Accessibility | | |
| Correctness | | |
| Operations | | |
| Performance | | |
| Documentation | | |

---

## Verified working

> Name it specifically. A gate report listing only problems misrepresents the
> work that was done, and it burns the reader's trust for the next report.

- `<specific thing verified, and how>`

---

## Not assessed

> Mandatory. Scope limits belong in the verdict, not discovered afterwards.

| Area | Why not | Risk of not knowing |
|---|---|---|
| | | |

---

## Pre-launch baseline

Captured `<date/time>` so post-launch numbers are comparable.

| Metric | Value |
|---|---|
| Error rate | |
| p50 / p95 / p99 latency | |
| Core Web Vitals (LCP / INP / CLS, p75) | |
| Conversion on the core journey | |
| Database connections at peak | |
| Monthly cost | |

---

## Launch plan

| | |
|---|---|
| **Window** | `<date, time, timezone — prefer low traffic>` |
| **Sequence** | migrate → deploy → smoke test → watch |
| **Who is watching** | `<name>`, for `<duration>` |
| **Rollback trigger** | `<the specific condition: error rate > X%, latency p95 > Yms, any P0 report>` |
| **Rollback procedure** | `<link — and the date it was last executed>` |
| **Rollback duration** | `<measured, not estimated>` |
| **Communication** | `<status page, customers, internal channel>` |
| **Escalation** | `<name>`, then `<name>` |

---

## Post-launch

| When | Check | Owner |
|---|---|---|
| T+1h | Error rate, latency, business metric vs baseline | |
| T+24h | Review; any alert that should have fired and did not? | |
| T+7d | Retrospective; what did this gate miss? | |

---

## Sign-off

| Role | Name | Date | Decision |
|---|---|---|---|
| Engineering | | | |
| Product | | | |
| Risk owner (for accepted risks) | | | |

---

<sub>Generated with **Devleck Senior Engineer Skills** — https://github.com/Kin9Zeus/senior-engineer-skills</sub>
