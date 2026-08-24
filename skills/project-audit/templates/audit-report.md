# `<Project Name>` — Senior Engineering Audit

| | |
|---|---|
| **Date** | `YYYY-MM-DD` |
| **Commit** | `<sha>` on `<branch>` |
| **Scope** | `<repository / repository + live site / + infrastructure>` |
| **Depth** | `Quick scan / Standard / Deep` |
| **Auditor** | Devleck Senior Engineer Skills |

---

## Verdict

> Two to four sentences, written for someone who will read nothing else.
> Can this ship? What is the single biggest risk? What does fixing it cost?
> If the answer is no, the first word is no.

**Score: `NN`/100 — `<Critical / At risk / Functional / Professional / Exemplary>`**

**Weakest domains:** `<domain>` (`n`/10) · `<domain>` (`n`/10) · `<domain>` (`n`/10)

| Severity | Count |
|---|---|
| P0 Blocker | `n` |
| P1 Critical | `n` |
| P2 Important | `n` |
| P3 Polish | `n` |

---

## Ground Truth

| | |
|---|---|
| **Product** | `<what it does, one line>` |
| **Stack** | `<language / framework / versions>` |
| **Runtime** | `<host, deploy method>` |
| **State** | `<databases, caches, queues, blob storage>` |
| **Public surface** | `<n routes, n webhooks, uploads y/n>` |
| **Third parties** | `<every SDK, tag, pixel, CDN found in code>` |
| **Auth model** | `<provider, session type, roles, tenancy enforcement point>` |
| **Tests** | `<count, layers, CI gate y/n>` |
| **Personal data** | `<tables and fields>` |
| **Scale** | `<users / rows / RPS, or UNKNOWN>` |

**Could not determine:** `<explicit list>`

---

## Findings

### P0 — Blockers

> Exploitable, data-losing, or legally exposing. Nothing ships until these close.

#### P0-1 · `<Short imperative title>`

| | |
|---|---|
| **Domain** | `<Security / Data / ...>` |
| **Location** | `path/to/file.ext:120-138` |
| **Confidence** | `CONFIRMED` / `PLAUSIBLE` |
| **Effort** | `S (< 1d) / M (1-3d) / L (> 3d)` |

**What is wrong**
`<The defect, stated factually. No adjectives.>`

**Why it matters**
`<The concrete consequence. Who is harmed, how, and at what scale. Not "this is
insecure" but "any authenticated user can read any other user's invoices by
changing the id in the URL — all 4,200 customers' billing data is reachable.">`

**Reproduce**
```
<exact request, steps, or query that demonstrates it>
```

**Fix**
```diff
<the change, as a diff or a precise instruction>
```

**Verify**
```
<the command, test, or request that proves it is fixed>
```

---

### P1 — Critical

> Will cause an incident or fail a real audit. Fix this sprint.

#### P1-1 · `<title>`
`<same structure>`

---

### P2 — Important

> Compounding debt. Schedule it.

| # | Domain | Finding | Location | Effort |
|---|---|---|---|---|
| P2-1 | | | | |

`<Expand any P2 that needs more than a table row.>`

---

### P3 — Polish

> Worth doing when you are already in that file. Capped at the ten most valuable.

| # | Finding | Location |
|---|---|---|
| P3-1 | | |

---

## Scorecard

| # | Domain | Weight | Score | Justification |
|---|---|---:|---:|---|
| 1 | Security | 15 | `n`/10 | `<one line of evidence>` |
| 2 | Data & persistence | 12 | `n`/10 | |
| 3 | Correctness & testing | 11 | `n`/10 | |
| 4 | Architecture | 10 | `n`/10 | |
| 5 | API design | 7 | `n`/10 | |
| 6 | DevOps & delivery | 8 | `n`/10 | |
| 7 | Observability | 7 | `n`/10 | |
| 8 | Performance | 6 | `n`/10 | |
| 9 | Accessibility | 6 | `n`/10 | |
| 10 | Web presence & SEO | 5 | `n`/10 | |
| 11 | Privacy & compliance | 6 | `n`/10 | |
| 12 | Documentation | 4 | `n`/10 | |
| 13 | Dependencies & supply chain | 5 | `n`/10 | |
| 14 | Developer experience | 4 | `n`/10 | |
| 15 | Cost & scalability | 4 | `n`/10 | |
| | **Weighted total** | **100** | **`NN`/100** | |

---

## Remediation plan

Ordered by what unblocks the most, soonest.

### Now — before any release

| # | Finding | Effort | Depends on | Verification |
|---|---|---|---|---|
| 1 | P0-1 | S | — | |

### This sprint

| # | Finding | Effort | Depends on | Verification |
|---|---|---|---|---|

### Next quarter

| # | Finding | Effort | Rationale |
|---|---|---|---|

**Estimated total to reach a `Professional` band (75+):** `<effort>`

---

## What is already good

> Name it specifically. An audit that only lists problems misrepresents the
> codebase and burns the reader's trust. Three to six items, with locations.

- `<specific good decision>` — `<where>`

---

## What I could not verify

> Mandatory. Never empty by omission. This section is what separates an audit
> from a guess.

- `<what>` — `<why: no access / not run / out of scope / needs production data>`

---

## Appendix

**Commands run**
```
<the read-only commands executed, so the audit is reproducible>
```

**Tools not available in this environment**
`<name them — a check that did not run is not a check that passed>`

---

<sub>Generated with **Devleck Senior Engineer Skills** — https://github.com/Kin9Zeus/senior-engineer-skills</sub>
