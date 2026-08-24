# Severity, Scoring and Reporting

## Severity model

Severity is not a feeling. Compute it from three factors and let the result
speak.

```
Severity = Blast radius  x  Likelihood  x  Cost-to-fix-later
```

| | **Blast radius** | **Likelihood** | **Cost later** |
|---|---|---|---|
| High | Data loss, credential exposure, full account takeover, regulatory breach, total outage | Reachable by an unauthenticated user, or already happening | Requires a migration, a rewrite, or customer notification |
| Medium | Single-tenant data leak, degraded service, failed audit | Requires authentication or a specific state | Requires coordinated deploy |
| Low | Cosmetic, internal-only, self-healing | Requires privileged access or an unlikely race | Local change |

### The four labels

**`P0 BLOCKER`** — Stop the launch. Fix before anything else ships.
> Unauthenticated access to another user's data. A secret in the repository.
> No backups. Payment amounts computed client-side. Raw SQL string interpolation
> on a public route. A privacy policy that omits a processor that is actually
> receiving personal data.

**`P1 CRITICAL`** — Will cause an incident or fail a real audit. This sprint.
> No rate limiting on auth endpoints. Missing authorization on an admin route
> that is merely unlinked. Migrations with no down path. No error monitoring.
> No test covering the billing calculation. Backups that have never been restored.

**`P2 IMPORTANT`** — Compounding debt with a real interest rate. Schedule it.
> N+1 queries on the main list view. No CI gate on tests. Missing indexes on
> foreign keys. No structured logging. Missing meta descriptions across the site.
> Inaccessible custom form controls.

**`P3 POLISH`** — Do it when you are already in that file.
> Inconsistent naming. Missing JSDoc on internal helpers. A slightly oversized
> hero image. Duplicated constants.

**Escalation rules that override the formula**
- Anything touching **money, authentication, or personal data** moves up one level.
- Anything reachable **without authentication** moves up one level.
- Anything the project **publicly claims to do but does not** (a privacy policy
  promising deletion with no deletion path) is at minimum `P1`, because it is a
  misrepresentation, not just a gap.

---

## The scorecard

Fifteen domains, each scored 0–10, weighted. Report the weighted total out of
100 and — more usefully — the three lowest domains.

| # | Domain | Weight | 0–3 | 4–6 | 7–8 | 9–10 |
|---|---|---|---|---|---|---|
| 1 | Security | 15 | Exploitable now | Basics only | Hardened, reviewed | Threat-modelled, tested, monitored |
| 2 | Data & persistence | 12 | No backups/migrations | Migrations, untested backups | Tested restore, indexed | PITR, tested DR, tenancy enforced in DB |
| 3 | Correctness & testing | 11 | No tests | Some unit tests | Pyramid + CI gate | Contract, E2E, mutation, flake budget |
| 4 | Architecture | 10 | Big ball of mud | Layered, leaky | Clear boundaries | Documented, ADRs, evolvable |
| 5 | API design | 7 | Ad hoc | Consistent-ish | Versioned, documented | Contract-tested, idempotent, paginated |
| 6 | DevOps & delivery | 8 | Manual deploys | CI exists | CD, IaC, envs | Progressive delivery, tested rollback |
| 7 | Observability | 7 | Console logs | Logs centralised | Metrics + alerts | Traces, SLOs, error budgets |
| 8 | Performance | 6 | Unmeasured | Measured once | Budgets enforced | Load-tested, cached, profiled |
| 9 | Accessibility | 6 | Unusable by keyboard | Some ARIA | WCAG 2.2 AA on key flows | AA sitewide, tested with AT |
| 10 | Web presence & SEO | 5 | No metadata | Titles present | Full metadata + schema | Indexed, structured, monitored |
| 11 | Privacy & compliance | 6 | No policy | Generic policy | Accurate policy + consent | Data map, automated DSAR, retention |
| 12 | Documentation | 4 | None | Stale README | Current README + runbooks | ADRs, onboarding under 15 min |
| 13 | Dependencies & supply chain | 5 | Unpinned, stale | Pinned | Automated updates | SBOM, provenance, license policy |
| 14 | Developer experience | 4 | Undocumented setup | Works with effort | One command | Reproducible, fast feedback |
| 15 | Cost & scalability | 4 | Unknown | Estimated | Monitored | Modelled, alerted, optimised |

**Bands**
- **0–39 Critical** — not fit to hold real user data.
- **40–59 At risk** — will have an incident; treat launch as conditional.
- **60–74 Functional** — normal startup standard; known debt, manageable.
- **75–89 Professional** — would pass most due diligence.
- **90–100 Exemplary** — would pass a regulated-industry audit.

Never inflate. A generous score is a disservice — the point of the number is to
be uncomfortable enough to fund the fix.

---

## Report shape

```markdown
# <Project> — Senior Engineering Audit
Date · Commit · Auditor · Scope

## Verdict
<Two to four sentences. Can this ship? What is the single biggest risk?>

**Score: NN/100 (<band>)** — weakest: <d1>, <d2>, <d3>

## Ground Truth
<the discovery block>

## Findings

### P0 — Blockers (n)
#### P0-1 <Short imperative title>
- **Where** `path/to/file.ts:120-138`
- **What** <the defect, stated factually>
- **Why it matters** <the concrete consequence — who gets hurt, how>
- **Reproduce** <exact steps or request>
- **Fix** <the change, with a code sketch where it helps>
- **Verify** <the command, test or check that proves it is fixed>
- **Effort** <S / M / L>

### P1 — Critical (n)
### P2 — Important (n)
### P3 — Polish (n)

## Scorecard
<the 15-domain table with per-domain justification lines>

## Remediation plan
| Order | Finding | Effort | Owner | Gate |
|---|---|---|---|---|

## What I could not verify
<explicit — this section is mandatory and must never be empty by omission>
```

### Rules for findings

1. **One defect per finding.** If a fix has two independent parts, that is two
   findings.
2. **Location is mandatory.** `file:line`, a route, a table name, or a config
   key. "Somewhere in the auth flow" is not a finding.
3. **Consequence must be concrete.** Not "this is insecure" but "any logged-in
   user can read any other user's invoices by changing the id in the URL".
4. **Verification must be executable.** A command, a test, a request, a query.
5. **No stacked hedging.** Either you verified it (`CONFIRMED`) or you are
   reasoning from strong evidence (`PLAUSIBLE`). Label which.
6. **Ordering is by severity, not by file.** The reader stops after P0; put the
   thing that matters at the top.

### Rules for the verdict

The verdict is written for someone who will read only the verdict. It answers:
can this ship, what breaks first, and what does fixing it cost? If the honest
answer is "no", write "no" in the first sentence.

---

## Reporting anti-patterns

- **The wall of nits.** 200 style findings burying two real vulnerabilities.
  Cap `P3` at the ten most valuable and say the rest are available on request.
- **The unverifiable claim.** "This will not scale." Compared to what load, at
  what latency target, hitting which bottleneck?
- **The vague fix.** "Add proper validation." Which library, at which boundary,
  rejecting which inputs?
- **Score inflation to be kind.** The user asked for a senior review, not
  reassurance. Deliver the number the evidence supports.
- **Silent omission.** If you did not review the mobile app, the report says so
  in the scope line and in "What I could not verify".
