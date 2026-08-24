<div align="center">

<img src="assets/banner.svg" alt="Devleck Senior Engineer Skills" width="100%">

# Senior Engineer Skills

**Turn Claude Code into a senior engineering organization.**

Fifteen skills that audit an existing codebase across fifteen domains, or build a new one
to the standard a due-diligence review, a penetration test and a data-protection
regulator would all pass.

[![Claude Skill](https://img.shields.io/badge/Claude-Skill-8B5CF6?style=flat-square)](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview)
[![Skills](https://img.shields.io/badge/skills-15-ECFF0C?style=flat-square&labelColor=0A0B0D)](#the-skills)
[![Commands](https://img.shields.io/badge/commands-7-ECFF0C?style=flat-square&labelColor=0A0B0D)](#slash-commands)
[![Agents](https://img.shields.io/badge/agents-4-ECFF0C?style=flat-square&labelColor=0A0B0D)](#subagents)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

**[English](README.md)** · **[Español](README.es.md)**

<sub>Built by **[Devleck](https://github.com/Kin9Zeus)** — Aleck Martinez, Founder &amp; CEO</sub>

</div>

---

## What this is

Most AI coding assistance produces code that works. This makes it produce code that
**survives** — a security review, a real incident, a scaling event, a regulator's
question, and the engineer who inherits it two years from now.

It installs fifteen specialist skills that Claude loads automatically when the work
calls for them, or that you invoke by name.

```
You: "review my project before we launch"

Claude loads senior-engineer → project-audit → and dispatches the domain passes.

→ Ground truth: Next.js 15, Postgres 16, Stripe, 4 processors, 31 tests, no CI gate
→ P0: any authenticated user can read any other user's invoices (api/invoices/[id]:24)
→ P0: STRIPE_SECRET_KEY present in git history since commit 8f14e45
→ P1: backups configured, never restored — recovery capability is unverified
→ P1: privacy policy omits PostHog and Intercom, both receiving personal data
→ 58/100 — At risk. Weakest: Privacy 2/10, Observability 3/10, Testing 4/10
→ Remediation plan: 3 blockers, ~2 days to a launchable state
```

Every finding carries a location, a concrete consequence, a fix, and a way to
**verify** the fix. A finding without a verification step is an opinion.

---

## Install

### Claude Code — plugin marketplace (recommended)

```
/plugin marketplace add Kin9Zeus/senior-engineer-skills
/plugin install senior-engineer-skills@senior-engineer-skills
```

Or just paste this repository's URL into Claude Code and ask it to install the plugin
globally:

> Install this plugin globally: https://github.com/Kin9Zeus/senior-engineer-skills

Restart Claude Code, then verify with `/plugin` or by typing `/snr-` — the seven
commands should appear.

### Any agent — one command

Works with Claude Code, Cursor, Codex, Windsurf, Copilot, Antigravity and
[40+ other agents](https://github.com/vercel-labs/skills#supported-agents):

```bash
npx skills add https://github.com/Kin9Zeus/senior-engineer-skills
```

### Manual — clone and copy

```bash
git clone https://github.com/Kin9Zeus/senior-engineer-skills.git
cd senior-engineer-skills

# macOS / Linux
./install.sh

# Windows (PowerShell)
./install.ps1
```

The installer copies `skills/`, `commands/` and `agents/` into your agent's
directory. It prints exactly what it will do and asks before overwriting anything.

<details>
<summary><b>Skill directories by agent</b></summary>

| Agent | Skills directory |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Cursor | `~/.cursor/skills/` |
| OpenAI Codex | `~/.codex/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Google Antigravity | `~/.gemini/antigravity/skills/` |

For a single project instead of globally, copy into `.claude/skills/` in the
project root.
</details>

### Uninstall

```
/plugin uninstall senior-engineer-skills
```
Or `./install.sh --uninstall` / `./install.ps1 -Uninstall`.

---

## How it activates

Both ways, always.

**Automatically.** Each skill declares the situations it belongs in. Claude loads
`security-hardening` when you touch an auth route, `database-engineering` when you
write a migration, `privacy-compliance` when a form starts collecting an email
address — without being asked.

**On demand.** Name a skill, or use a slash command:

```
"use the project-audit skill on this repo"
"run a security-hardening pass over the API"
/snr-audit --deep
```

---

## The skills

<table>
<tr><th>Skill</th><th>What it does</th><th>Loads when</th></tr>

<tr><td><b>senior-engineer</b></td>
<td>The router and the standard. Establishes ground truth before opinions, picks the mode, delegates to the right specialist, enforces the non-negotiable bar.</td>
<td>Any non-trivial engineering work</td></tr>

<tr><td><b>project-audit</b></td>
<td>Full-spectrum audit across 15 domains → prioritised findings + a 0–100 scorecard.</td>
<td>"review my project", "is this production ready"</td></tr>

<tr><td><b>project-blueprint</b></td>
<td>Greenfield architecture and scaffold, in the order that avoids expensive retrofits.</td>
<td>"build me a…", "start a new project"</td></tr>

<tr><td><b>security-hardening</b></td>
<td>OWASP Top 10, object-level authorization, injection, auth, CSP, secrets, supply chain, threat modelling.</td>
<td>Auth, payments, uploads, deps, any audit</td></tr>

<tr><td><b>database-engineering</b></td>
<td>Schema, constraints, indexes, query plans, N+1, migrations, tenancy, backups, restore drills, retention.</td>
<td>Any persistence work</td></tr>

<tr><td><b>api-contracts</b></td>
<td>REST/GraphQL design, error envelopes, pagination, idempotency, versioning, rate limits, webhooks, OpenAPI.</td>
<td>Any endpoint or integration</td></tr>

<tr><td><b>devops-platform</b></td>
<td>CI/CD, IaC, containers, environment parity, deploy strategies, rollback, secrets, DR, cost.</td>
<td>Pipelines, Docker, Terraform, deploys</td></tr>

<tr><td><b>observability-slo</b></td>
<td>Structured logs, metrics, traces, correlation ids, SLOs and error budgets, alerting on symptoms, incident response.</td>
<td>"how do we know if it breaks?"</td></tr>

<tr><td><b>testing-strategy</b></td>
<td>The pyramid, meaningful coverage policy, integration and contract tests, E2E, flake control, mutation testing.</td>
<td>Any test conversation</td></tr>

<tr><td><b>performance-engineering</b></td>
<td>Core Web Vitals, bundle size, rendering strategy, latency budgets, caching, profiling, load testing.</td>
<td>"it's slow", scale planning</td></tr>

<tr><td><b>accessibility-audit</b></td>
<td>WCAG 2.2 AA — keyboard, focus, semantics, contrast, forms, ARIA patterns, reduced motion, real AT testing.</td>
<td>Any UI work</td></tr>

<tr><td><b>web-presence-audit</b></td>
<td>Technical SEO, per-page metadata, structured data, custom 404, internal linking, and the trust/conversion layer.</td>
<td>Any public-facing site</td></tr>

<tr><td><b>privacy-compliance</b></td>
<td>Data inventory from the code, an accurate privacy policy, consent that actually gates, automated deletion and export.</td>
<td>Any personal data at all</td></tr>

<tr><td><b>release-readiness</b></td>
<td>The go/no-go gate → an explicit ship or do-not-ship verdict with named blockers and a rehearsed rollback.</td>
<td>Before any launch</td></tr>

<tr><td><b>engineering-standards</b></td>
<td>Conventions, git workflow, PR and review practice, ADRs, documentation, onboarding, DX, tech debt.</td>
<td>Team practices, onboarding</td></tr>
</table>

Each skill is a focused `SKILL.md` plus reference files loaded on demand — **fifty-plus
documents** of checklists, rubrics, patterns and templates, so Claude works from a
standard rather than from recall.

---

## Slash commands

| Command | What it does |
|---|---|
| `/snr-audit [path\|url] [--quick\|--deep] [--parallel]` | Full audit → findings report + scorecard. `--parallel` authorises concurrent domain reviewers |
| `/snr-build <description>` | Architect and scaffold a new project, in the right order |
| `/snr-harden [scope]` | Security pass with fixes and regression tests |
| `/snr-web <url>` | SEO, metadata, structured data, 404, internal links, trust layer |
| `/snr-privacy [--policy\|--deletion\|--cookies]` | Data inventory → policy → consent → deletion pipeline |
| `/snr-ship [version]` | Go/no-go gate with an explicit verdict |
| `/snr-scorecard [path]` | Fast 15-domain rating on one screen |

## Subagents

Four specialists for focused, parallel review. Read-only; they report and propose
rather than apply.

`snr-security-auditor` · `snr-data-auditor` · `snr-web-auditor` · `snr-architect`

```
"use the snr-security-auditor and snr-data-auditor agents on this repo in parallel"
```

## Executable helpers

Read-only scripts, POSIX shell and PowerShell, no dependencies beyond `curl` and
`grep`. Every hit they report is a **lead, not a finding** — the skills instruct
Claude to confirm each one by reading the code.

| Script | Does |
|---|---|
| `project-audit/scripts/recon.{sh,ps1}` | Stack, state layer, tests, CI, risk signals, third parties |
| `security-hardening/scripts/secret-scan.{sh,ps1}` | Credential patterns in the tree **and git history**, injection sinks, config weaknesses |
| `web-presence-audit/scripts/web-check.{sh,ps1}` | Live URL: headers, robots, soft-404, metadata, OG, schema, alt text, trust pages |

---

## What it actually checks

<details open>
<summary><b>Security &amp; data</b></summary>

Secrets in the working tree **and git history** · object-level authorization (the
cross-user test) · mass assignment · SQL, command, template and path injection ·
password hashing and session invalidation · rate limits and user enumeration · CSP
without `unsafe-inline` · CSRF, CORS, SSRF, uploads, redirects · security headers ·
dependency and supply-chain risk · install scripts · CI permissions · schema
constraints in the database · indexes on every foreign key · query plans and N+1 ·
reversible migrations tested at production scale · transaction boundaries · tenancy
enforced in the database · **backups that have actually been restored** · retention
and erasure per table
</details>

<details>
<summary><b>Correctness, delivery &amp; operations</b></summary>

Test pyramid shape · branch coverage on business logic · the authorization matrix ·
contract, E2E and mutation testing · flake control · CI that blocks merge ·
reproducible builds from a lockfile · one artefact promoted through environments ·
environment parity · **a rollback someone has actually executed** · non-root
containers with no secrets in layers · secrets in a manager, rotatable · structured
logs with a correlation id and **no personal data** · error tracking with releases
and source maps · RED metrics plus one business metric · SLOs and error budgets ·
alerts that page on symptoms · runbooks that have been run · cost tagged and
anomaly-alerted
</details>

<details>
<summary><b>Public surface &amp; trust</b></summary>

`robots.txt` that does not accidentally block the site · generated `sitemap.xml` ·
**a custom 404 returning a real 404 status** · canonical URLs that do not all point
at the homepage · **unique title and meta description on every page** · Open Graph
and Twitter cards with an absolute-URL 1200×630 image · **alt text everywhere**,
empty for decorative · one `h1`, ordered headings, landmarks · **structured data
including `LocalBusiness`, `FAQPage` and `BreadcrumbList`** · **internal linking with
no orphan pages** · **FAQ page** · **case studies with measured outcomes** ·
**thank-you pages as real URLs** · **a stated, monitored response-time commitment** ·
**a sticky mobile CTA that does not obscure content or focus** · about, pricing,
status and security pages · WCAG 2.2 AA throughout
</details>

<details>
<summary><b>Privacy &amp; compliance</b></summary>

**A data inventory built from the code, not an interview** · **a privacy policy that
names every third party actually receiving data** — cross-checked by grep, because
the omitted analytics tag is the most common finding in a real privacy audit ·
legal basis per purpose · retention per category, enforced by a monitored job ·
**cookie consent that gates scripts before consent**, verified in a private window,
with reject as easy as accept · **a self-service export and deletion path, automated
end to end** — reaching object storage, caches, search, logs and **every third-party
processor** · deletion verified by re-querying and recorded in an audit trail · an
honest, documented position on backups · DPAs and a published subprocessor list · a
breach plan with a named decision-maker and a 72-hour clock

Templates included in **English and Spanish**.
</details>

---

## The bar it enforces

These apply to every project it touches, small or large. A small project is not an
excuse for an unsafe one; it is a reason for the safe version to be cheap.

> **Security** — No secret in source control, ever. Every mutating endpoint
> authenticated, authorised *for that specific object*, schema-validated,
> rate-limited. Parameterised queries only. A CSP that is not `unsafe-inline`.
>
> **Data** — Versioned reversible migrations. Backups **restored at least once in a
> test** — an untested backup is not a backup. Personal data inventoried, minimised,
> retention-bounded and deletable.
>
> **Correctness** — A test for every bug fixed and every business rule. CI blocks
> merge on red. No `TODO` in a path handling money, auth or personal data.
>
> **Operability** — One-command setup. Reversible deploys. Structured logs with
> correlation ids. At least one alert that pages a human. A runbook for the three
> most likely failures.
>
> **Users** — Unique title and description per page. WCAG 2.2 AA. A privacy policy
> that matches actual data flows, consent that actually gates, and a working
> self-service deletion path.

And a behavioural contract: read before writing · match the codebase's conventions ·
smallest correct change · no silent scope reduction · disagree explicitly · **never
fabricate** a version, a CVE, an API signature or a benchmark · confirm before
anything destructive.

---

## Examples

> **[→ The cookbook](docs/en/cookbook.md)** — ten complete workflows, in the order
> you would actually run them: inheriting a codebase, starting one properly,
> diagnosing slowness, building the deletion pipeline, fixing search visibility,
> gating a launch, and using it day to day without commands.

```
"audit this repo before our Series A"
  → /snr-audit --deep. Fifteen domains, threat model, restore-drill request,
    scorecard, remediation plan with effort estimates.

"build me a multi-tenant SaaS for gym scheduling"
  → /snr-build. Five questions, then stack ADRs, a schema with tenancy and PII
    tagged from migration 001, a deny-by-default authorization layer, one complete
    vertical slice, CI, and a staging deploy — before any feature work.

"why is my checkout page slow?"
  → performance-engineering. Field data first, then the waterfall, then the
    measurement: "LCP 4.8s (p75, mobile, 28d, n=12,400). Hero image is a 2.4MB
    unoptimised PNG, lazy-loaded. Convert to AVIF + srcset, remove loading=lazy,
    add fetchpriority=high. Expected ~1.9s."

"we need to let users delete their data"
  → /snr-privacy --deletion. Data inventory from the schema, an erasure plan as
    code, the endpoints, the grace period, the processor fan-out, the verification
    step, the audit trail, and the test that fails when a new table is added
    without a rule.

"are we ready to launch on Thursday?"
  → /snr-ship. "NO GO. Three blockers. The largest is that any authenticated user
    can read any other user's invoices, which would be a reportable data breach on
    day one. Estimated 2 days to clear."
```

---

## FAQ

<details>
<summary><b>Does this work outside Claude Code?</b></summary>

Yes. The skills are plain Markdown following the Agent Skills format. `npx skills add`
installs them into Cursor, Codex, Windsurf, Copilot, Antigravity and others. Slash
commands and subagents are Claude Code features; the skills themselves are portable.
</details>

<details>
<summary><b>Fifteen skills — does that fill up the context window?</b></summary>

No. Only skill *descriptions* are loaded up front (a few hundred tokens total). A
skill's body loads when it is triggered, and its reference files load only when that
skill decides it needs them. This is why the suite is fifteen focused skills rather
than one enormous document.
</details>

<details>
<summary><b>Is the security guidance safe to publish?</b></summary>

It is defensive throughout: finding and fixing weaknesses in code you own or are
authorised to assess. The skills instruct Claude never to scan or send traffic to
infrastructure without confirmation of ownership, and to produce fixes and detections
rather than weaponised exploits.
</details>

<details>
<summary><b>Is the privacy content legal advice?</b></summary>

No, and the skill says so every time it runs. It produces technical controls and a
policy drafted from your real data flows. For a regulated sector, children's data or
special-category data, have a qualified privacy lawyer review the output. Build the
controls either way — they are the same.
</details>

<details>
<summary><b>Will it rewrite my codebase?</b></summary>

No. The default posture is read-and-report. Fixes are applied only when you ask, in
severity order, one finding per commit, with the failing test written first. The
skills explicitly forbid recommending a rewrite without naming the specific unfixable
property that forces it.
</details>

<details>
<summary><b>How do I make it less strict for a side project?</b></summary>

Say so — it calibrates. It grades against what a project claims to be, and it will
tell you which findings it is down-weighting. Four things are never down-weighted:
secrets in git, cross-user data access, absent backups, and privacy claims that are
not true.
</details>

---

## Contributing

Issues and pull requests welcome. See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the
skill-writing conventions — chiefly: every claim must be checkable, every finding
needs a verification step, and no fabricated version numbers, CVEs or benchmarks.

Security disclosures: **[SECURITY.md](SECURITY.md)**.

## Licence

[MIT](LICENSE) © Aleck Martinez / Devleck. Use it commercially, fork it, ship it.

---

<div align="center">

<img src="assets/mark.svg" alt="" width="72">

**Built by [Devleck](https://github.com/Kin9Zeus)**
Aleck Martinez — Founder &amp; CEO

<sub>If this made your codebase harder to break, a ⭐ helps other engineers find it.</sub>

</div>
