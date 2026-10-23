---
name: project-audit
description: Run a full-spectrum senior engineering audit of an existing codebase or product across 15 domains — security, data, testing, architecture, API, DevOps, observability, performance, accessibility, SEO/web presence, privacy, docs, dependencies, DX and cost — producing a prioritised, verifiable findings report with a 0–100 scorecard. Use when the user says "audit my project", "review my codebase", "is this production ready", "what's wrong with my app", "health check", "due diligence", "technical assessment", "security review", "code review of the whole repo", "inherited this codebase", "what would a senior engineer say", "is this safe to launch", "find the problems" or shares a repository or URL and asks for an assessment. By Devleck.
license: MIT
---

# Project Audit

A real audit is evidence-driven. Every finding points at a line, a route, a
table or a config key, and every finding carries a way to prove the fix. Opinions
without locations are not findings.

## Phase 0 — Scope and consent (2 minutes, never skipped)

Establish before reading code:

1. **What is in scope?** Repository only, or also the live site, infrastructure
   and third-party accounts?
2. **What is the audit for?** Pre-launch gate, investor due diligence, an
   inherited codebase, a security concern, or a general health check. This
   changes what gets weighted.
3. **What may be run?** Read-only analysis is always safe. Ask before installing
   dependencies, running tests, starting services, or touching anything that
   reaches production.
4. **Is there a live URL?** If yes, the `web-presence-audit`, `accessibility-audit`
   and `privacy-compliance` passes become live checks rather than code inference.

Never scan, probe or send traffic to infrastructure the user has not confirmed
they own or are authorised to test.

State the scope in one line and begin.

## Phase 1 — Ground truth

Run the discovery protocol from `senior-engineer/references/discovery-protocol.md`.
`scripts/recon.sh` (or `recon.ps1` on Windows) automates the first pass and
prints a structured summary — run it if the environment allows, and fall back to
the manual commands if not. It is read-only.

Do not proceed to findings until the Ground Truth block is filled in. An audit
built on a misread stack is worse than no audit.

## Phase 2 — The fifteen domain passes

Load the specialised skill for each domain rather than working from memory.

| # | Domain | Skill to load | Weight |
|---|---|---|---|
| 1 | Security | `security-hardening` | 15 |
| 2 | Data and persistence | `database-engineering` | 12 |
| 3 | Correctness and testing | `testing-strategy` | 11 |
| 4 | Architecture | this skill, `references/architecture-review.md` | 10 |
| 5 | API design | `api-contracts` | 7 |
| 6 | DevOps and delivery | `devops-platform` | 8 |
| 7 | Observability | `observability-slo` | 7 |
| 8 | Performance | `performance-engineering` | 6 |
| 9 | Accessibility | `accessibility-audit` | 6 |
| 10 | Web presence and SEO | `web-presence-audit` | 5 |
| 11 | Privacy and compliance | `privacy-compliance` | 6 |
| 12 | Documentation | `engineering-standards` | 4 |
| 13 | Dependencies and supply chain | `security-hardening` | 5 |
| 14 | Developer experience | `engineering-standards` | 4 |
| 15 | Cost and scalability | `devops-platform` | 4 |

**Scale the depth to the project.** Not every audit needs all fifteen at full
depth:

- **Quick scan** (a small app, a first look): domains 1, 2, 3, 11 at depth; the
  rest as a one-line status each.
- **Standard audit** (the default): all fifteen, depth proportional to weight.
- **Deep audit** (due diligence, pre-funding, regulated): all fifteen at depth,
  plus a threat model, a restore drill and a load test.

Say which depth you are running, and why.

**Security extensions — load alongside `security-hardening` for domains 1 and 13
whenever the evidence calls for them:**

| If the recon shows… | Also load | Why |
|---|---|---|
| PHP (`composer.json`, `.php`, a `php` image, WordPress, Laravel, Symfony) | `php-hardening` | The runtime itself has had critical, actively targeted flaws; check the running build, SAPI and config before the code |
| A hosting platform, CI, containers, Terraform, or any stored secrets | `cloud-security` | Score how much a stolen environment variable would buy an attacker (blast radius, rotation readiness) |
| Model/LLM calls, agents, tools, MCP servers, third-party skills | `ai-security` | Prompt-injection paths, agent permissions, provider-key spend exposure |
| Any sign the system may *already* be compromised (unknown processes or files, foreign admin users, a vendor breach notice, a key in public) | `security-incident-response` | **Stop the audit and switch.** Auditing a live compromise destroys evidence and delays rotation |
| A request to *test* (not review) a running system | `pentest-methodology` | Active testing needs written authorisation and a scope file; this audit does not authorise it |

A high-risk system (payments, health, regulated data, public API) should end with
a recommendation for an authorised penetration test even when the code review is
clean — reading code does not replace attacking the running thing.

**Parallelising.** For a large codebase, running domain passes concurrently as
subagents is the right call — dispatch security, data, testing and web-presence
as independent reviewers, then merge. This skill authorises that; give each
agent the Ground Truth block so nobody re-derives it.

## Phase 3 — Evidence discipline

For every candidate finding, before it enters the report:

```
Can I point at the exact location?          -> if no, keep investigating or drop it
Can I state the concrete consequence?       -> if no, it is a preference, not a finding
Did I verify it, or am I inferring?         -> label CONFIRMED or PLAUSIBLE
Can I name a way to prove the fix works?    -> if no, the fix is underspecified
```

**Confirm before escalating.** A missing authorization check might be enforced
in middleware you have not read. A missing index might exist under a different
name. Grep for the mitigating control before calling something a P0 — a false P0
costs you the reader's trust for the whole report.

**Sample when exhaustive is impossible.** On a large codebase, review every
auth-adjacent, money-adjacent and personal-data-adjacent path exhaustively, and
sample the rest. Say what you sampled and at what rate.

## Phase 4 — Score and report

Apply the rubric in `senior-engineer/references/severity-and-reporting.md`.
Use `templates/audit-report.md` as the output shape.

Write to a file (`AUDIT.md` or `docs/audit-YYYY-MM-DD.md`) when the report is
longer than a screen — a report that scrolls out of a terminal does not get
acted on. Offer to publish it as a shareable artifact if the user wants to
circulate it.

Mandatory sections, in this order:
1. **Verdict** — can this ship, what breaks first, what does the fix cost.
2. **Score** — NN/100 with the three weakest domains named.
3. **Ground Truth**.
4. **Findings** — P0, P1, P2, P3, each fully formed.
5. **Scorecard** — fifteen rows, each with a one-line justification.
6. **Remediation plan** — ordered, with effort estimates.
7. **What I could not verify** — never empty by omission.

## Phase 5 — Remediation, on request

If the user asks you to fix rather than only report:

- Fix in severity order, P0 first. One finding per commit.
- Write the failing test **before** the fix wherever a test is possible.
- Do not bundle refactors with security fixes; a reviewer must be able to see
  the fix.
- Re-verify each fix with the verification step written in the finding, and
  report the actual result.
- If a fix turns out to be wrong or infeasible, say so and leave the finding
  open rather than quietly closing it.

## Calibration

Grade against **what this project claims to be**, not against a hypothetical
ideal. A weekend side project with no users and a fintech handling card data are
held to different standards on scalability and process — and to *identical*
standards on secrets in git, SQL injection, and honest privacy claims.

Two failure modes to avoid in equal measure:

- **Flattery.** Grading generously so the user feels good. They asked for a
  senior review; give them the number the evidence supports.
- **Performative severity.** Inflating findings to look thorough. A P0 that is
  not exploitable teaches the reader to ignore your P0s.

## References and assets

- `references/architecture-review.md` — how to assess structure, boundaries, coupling
- `references/stack-playbooks.md` — per-stack specifics (Next.js, Django, Rails, Laravel, Spring, Go, .NET, Flutter, mobile)
- `references/quick-scan.md` — the 30-minute version and its command sequence
- `templates/audit-report.md` — the full report template
- `scripts/recon.sh` / `scripts/recon.ps1` — read-only reconnaissance
