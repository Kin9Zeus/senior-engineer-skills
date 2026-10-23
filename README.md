<div align="center">

<img src="assets/banner.svg" alt="Devleck Senior Engineer Skills" width="100%">

# Senior Engineer Skills

**Turn Claude Code into a senior engineering organization.**

Twenty skills that audit an existing codebase across fifteen domains, respond to security
incidents, test systems with authorisation, or build a new one to the standard a
due-diligence review, a penetration test and a data-protection regulator would all pass.

[![Claude Skill](https://img.shields.io/badge/Claude-Skill-8B5CF6?style=flat-square)](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview)
[![Skills](https://img.shields.io/badge/skills-20-ECFF0C?style=flat-square&labelColor=0A0B0D)](#the-skills)
[![Commands](https://img.shields.io/badge/commands-14-ECFF0C?style=flat-square&labelColor=0A0B0D)](#slash-commands)
[![Agents](https://img.shields.io/badge/agents-8-ECFF0C?style=flat-square&labelColor=0A0B0D)](#subagents)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

**[English](README.md)** · **[Español](README.es.md)**

<sub>Built by **[Devleck](https://github.com/Kin9Zeus)** — Aleck Martinez, Founder &amp; CEO</sub>

</div>

---

## What this is

Most AI coding assistance produces code that works. This makes it produce code that
**survives** — a security review, a real incident, a scaling event, a regulator's
question, and the engineer who inherits it two years from now.

It installs twenty specialist skills that Claude loads automatically when the work
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

> [!TIP]
> **Fastest path — any OS, 30 seconds.** Inside Claude Code, run these two lines:
>
> ```
> /plugin marketplace add Kin9Zeus/senior-engineer-skills
> /plugin install senior-engineer-skills@senior-engineer-skills
> ```
>
> Restart Claude Code, type `/snr-` — **fourteen commands appear**. Done.

Not using Claude Code, want it in a single project, or want to read what gets copied
first? Pick your system:

<table>
<tr>
<th width="33%">🪟 Windows</th>
<th width="33%">🍎 macOS</th>
<th width="33%">🐧 Linux · WSL · Git Bash</th>
</tr>
<tr>
<td>

PowerShell 5.1+:

```powershell
git clone https://github.com/Kin9Zeus/senior-engineer-skills.git
cd senior-engineer-skills
./install.ps1
```

</td>
<td>

Terminal:

```bash
git clone https://github.com/Kin9Zeus/senior-engineer-skills.git
cd senior-engineer-skills
./install.sh
```

</td>
<td>

Any shell with bash:

```bash
git clone https://github.com/Kin9Zeus/senior-engineer-skills.git
cd senior-engineer-skills
./install.sh
```

</td>
</tr>
</table>

The installer **shows exactly what it will do and asks before overwriting anything**.
It auto-detects Claude Code, Cursor, Codex, OpenCode and Antigravity, and copies
`skills/`, `commands/` and `agents/` into that agent's directory.

> [!IMPORTANT]
> We deliberately do **not** offer a `curl … | sh` one-liner. A security suite should
> not ask you to execute a script you have not read. Clone, skim `install.sh` /
> `install.ps1` (they are short), then run.

### Installer options

| You want to… | macOS · Linux · WSL | Windows (PowerShell) |
|---|---|---|
| **Preview** without changing anything | `./install.sh --dry-run` | `./install.ps1 -DryRun` |
| Install for **one project only** (`./.claude/`) | `./install.sh --project` | `./install.ps1 -Project` |
| Target a **specific agent** | `./install.sh --agent cursor` | `./install.ps1 -Agent cursor` |
| Skills only — **no commands or agents** | `./install.sh --skills-only` | `./install.ps1 -SkillsOnly` |
| **No prompts** (CI, scripts) | `./install.sh --yes` | `./install.ps1 -Yes` |
| **Uninstall** | `./install.sh --uninstall` | `./install.ps1 -Uninstall` |

Agents: `claude` · `cursor` · `codex` · `opencode` · `antigravity`. Options combine, e.g.
`./install.sh --project --dry-run`.

### Other ways in

<details>
<summary><b>Any agent — one command with Node (Windows, macOS, Linux)</b></summary>

Works with Claude Code, Cursor, Codex, Windsurf, Copilot, Antigravity and
[40+ other agents](https://github.com/vercel-labs/skills#supported-agents):

```bash
npx skills add https://github.com/Kin9Zeus/senior-engineer-skills
```

This installs the skills. Slash commands and subagents are Claude Code features; use
the plugin or `install.sh` / `install.ps1` to get those too.
</details>

<details>
<summary><b>Let Claude do it</b></summary>

Paste the repository URL into Claude Code and ask:

> Install this plugin globally: https://github.com/Kin9Zeus/senior-engineer-skills
</details>

<details>
<summary><b>No Git installed (Windows)</b></summary>

Download the ZIP from the repository's **Code → Download ZIP**, extract it, then in
PowerShell from the extracted folder:

```powershell
Get-ChildItem -Recurse | Unblock-File     # clears the "downloaded from the internet" flag
./install.ps1
```
</details>

<details>
<summary><b>Where the files go</b></summary>

| Agent | Skills directory (macOS · Linux) | Windows |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `%USERPROFILE%\.claude\skills\` |
| Cursor | `~/.cursor/skills/` | `%USERPROFILE%\.cursor\skills\` |
| OpenAI Codex | `~/.codex/skills/` | `%USERPROFILE%\.codex\skills\` |
| OpenCode | `~/.config/opencode/skills/` | `%USERPROFILE%\.config\opencode\skills\` |
| Google Antigravity | `~/.gemini/antigravity/skills/` | `%USERPROFILE%\.gemini\antigravity\skills\` |

Commands and agents go to the sibling `commands/` and `agents/` directories. With
`--project` / `-Project`, everything goes to `.claude/` in the current directory
instead — commit it so your whole team gets the suite.
</details>

### Verify it worked

1. **Restart** your agent.
2. Type `/snr-` — you should see **14 commands** (`/snr-audit`, `/snr-incident`,
   `/snr-pentest`, …).
3. Ask for something that should trigger a skill: *"review my project before we
   launch"* → `senior-engineer` and `project-audit` load.

<details>
<summary><b>Something is off?</b></summary>

| Symptom | Fix |
|---|---|
| `/snr-` shows nothing | Restart the agent fully; for the plugin route confirm with `/plugin` |
| `Permission denied` running `install.sh` | `chmod +x install.sh`, or run `bash install.sh` |
| PowerShell: *"running scripts is disabled"* | For this window only: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, then `./install.ps1` |
| PowerShell: *"not digitally signed"* after a ZIP download | `Get-ChildItem -Recurse \| Unblock-File` |
| Wrong agent detected | Pass it explicitly: `--agent cursor` / `-Agent cursor` |
| Unsure what it will touch | `--dry-run` / `-DryRun` first — it changes nothing |
</details>

### Update and uninstall

```bash
git pull && ./install.sh          # Windows: git pull; ./install.ps1
```

Plugin route: refresh the marketplace from the `/plugin` menu and reinstall. Remove everything with
`/plugin uninstall senior-engineer-skills`, or `./install.sh --uninstall` /
`./install.ps1 -Uninstall`.

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

## Security response & ethical hacking

Added in 1.1.0, after two incidents in the same week of October 2026:

- **Railway** disclosed (21 Oct) that an unauthorised party may have accessed the
  systems storing customer environment variables — some possibly in decrypted form —
  and asked every customer to roll all variables and registry credentials.
  [Railway's disclosure](https://blog.railway.com/p/security-disclosure-wednesday-october-21st).
- **PHP** shipped emergency fixes (21 Oct) for two critical, unauthenticated
  remote-code-execution flaws in the interpreter itself, CVE-2026-109618 and
  CVE-2026-109619 ("php2shell"), fixed in 8.5.12, 8.4.27, 8.3.36 and 8.2.35.
  [CISA alert](https://www.cisa.gov/news-events/alerts/2026/10/21/critical-vulnerabilities-php-require-immediate-patching).

> Incident facts in the skills are **dated 2026-10-23** and link their primary
> sources. Re-read the provider's and the PHP project's current pages before acting.

What the suite now does about it:

| You need to… | Use | Core idea |
|---|---|---|
| Respond to a breach, a leaked key, an exploited CVE, a suspect server | `/snr-incident` · `security-incident-response` | Revoke before investigating, investigate before cleaning; rotate **upstream first** and prove the old value dead |
| Rotate every secret fast | `/snr-rotate` | Names-only inventory → blast-radius order → verify with a `401` |
| Check and fix PHP | `/snr-php` · `php-hardening` | Inventory every PHP, verify the **running** build, interim mitigations, compromise assessment, FPM/ini baseline |
| Make a stolen env var worthless | `/snr-cloud` · `cloud-security` | The secrets ladder: narrow, network-restricted, spend-capped, short-lived, detected on first use |
| Attack your own system, safely | `/snr-pentest` · `pentest-methodology` | **Written authorisation + a scope file + `scope-guard`** before any packet; non-destructive proof; fix, regression test, retest |
| Secure AI features and agents | `/snr-ai-security` · `ai-security` | Break the private-data / untrusted-content / outbound-channel overlap; least agency; scoped, capped provider keys |
| Model threats | `/snr-threatmodel` | STRIDE, a control and a test for each threat |

**Guardrails.** Defensive and authorised only: no weaponised exploits, no malware,
no denial of service, no post-exploitation, no testing of third parties. Active
testing is refused without a scope file whose authorisation has not expired.

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

<tr><td><b>security-incident-response</b></td>
<td>Classify, contain, rotate secrets upstream-first, hunt provider-side logs, eradicate, recover, notify. Includes the dated Railway case file and rotation tracker.</td>
<td>"we got breached", "leaked key", "rotate all my secrets"</td></tr>

<tr><td><b>php-hardening</b></td>
<td>The October 2026 php2shell response, PHP/SAPI inventory, php.ini and FPM baseline, mod_php → FPM, PHP code flaws, Composer, WordPress, Laravel, Symfony.</td>
<td>Any PHP project; "PHP vulnerability"</td></tr>

<tr><td><b>pentest-methodology</b></td>
<td>Authorised penetration testing: the authorisation gate, scope guard, web/API/cloud test plans, non-destructive proof, reporting and retest.</td>
<td>"pentest", "ethical hacking", "bug bounty"</td></tr>

<tr><td><b>cloud-security</b></td>
<td>Assume the platform is breached: secrets ladder, least privilege, OIDC, egress control, containers, Kubernetes, IaC scanning, rotation drills.</td>
<td>"is Railway safe?", "where do I keep secrets?"</td></tr>

<tr><td><b>ai-security</b></td>
<td>Prompt injection, excessive agency, output handling, RAG isolation, MCP and skill supply chain, AI-provider key and spend protection.</td>
<td>LLM features, agents, MCP servers</td></tr>
</table>

Each skill is a focused `SKILL.md` plus reference files loaded on demand — **eighty-plus
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
| `/snr-incident [what happened]` | Classify → contain → rotate in order → hunt → recover (breach, leaked key, exploited CVE) |
| `/snr-rotate [scope]` | Secret inventory (names only) → blast-radius order → rotate upstream-first → prove old values dead |
| `/snr-php [scope]` | PHP runtime inventory vs fixed releases, interim mitigations, config and code hardening |
| `/snr-cloud [scope]` | Cloud / PaaS / container review built on "the platform can be breached" |
| `/snr-pentest <target> [--plan\|--retest]` | Authorised, scoped, non-destructive test — gated on a scope file |
| `/snr-ai-security [scope]` | AI feature and agent review, prompt-injection attack suite |
| `/snr-threatmodel [system]` | Thirty-minute STRIDE model with a control and a test per threat |

## Subagents

Eight specialists for focused, parallel review. Read-only; they report and propose
rather than apply.

`snr-security-auditor` · `snr-data-auditor` · `snr-web-auditor` · `snr-architect` ·
`snr-incident-responder` · `snr-pentester` · `snr-cloud-auditor` · `snr-php-auditor`

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
| `security-incident-response/scripts/rotation-inventory.{sh,ps1}` | Secret **names** the repo reads or defines (never values), grouped by sensitivity — the rotation worksheet |
| `php-hardening/scripts/php-check.{sh,ps1}` | Every declared PHP version, the CLI build vs fixed releases, ini values, PHP-specific risky code |
| `pentest-methodology/scripts/scope-guard.{sh,ps1}` | Refuses any host or IP outside a signed scope file, or after authorisation expires |

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
<summary><b>Incident response, runtime &amp; platform security</b></summary>

**Rotation upstream first, then the platform, then revoke the old one — and prove it
with a `401`** · names-only secret inventory · provider-side audit logs hunted before
host logs · persistence checklist · rebuild from a clean image when cleanliness cannot
be proven · the **running** PHP build, not the Dockerfile · every SAPI and bundled
copy · interim mitigations with an owner and a removal date · web workers that spawn
shells · `mod_php` → PHP-FPM · per-app pools with `clear_env` · the secrets ladder
(hard-coded → platform variable → secrets manager → no static secret) · OIDC instead
of long-lived CI keys · network allowlists and spend caps on every key · canary
credentials · a **timed, rehearsed rotation drill**
</details>

<details>
<summary><b>Authorised testing &amp; AI security</b></summary>

**A written scope and rules of engagement before the first packet**, enforced by
`scope-guard` · the cross-account authorisation matrix · OWASP WSTG and API Top 10 as
test plans · inert markers, never data harvesting · every finding reproduced twice,
with a fix, a regression test and a detection signal, then retested · prompt injection
direct and indirect · the private-data / untrusted-content / outbound-channel overlap ·
least agency and human approval for the irreversible · model output treated as
untrusted input · per-tenant vector stores · MCP servers, skills and `AGENTS.md`
reviewed like code · scoped, capped AI-provider keys
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
> **Resilience** — Assume the host or CI can leak what it stores: every credential
> narrow, network-restricted, spend-capped, per-environment, with a **rehearsed
> rotation runbook**. The runtime is patched — on the *running* build.
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

> **[→ The cookbook](docs/en/cookbook.md)** — fourteen complete workflows, in the order
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

"Railway says our environment variables may be exposed"
  → /snr-incident. Class A. Names-only inventory, rotation in blast-radius order
    (cloud → database → signing keys → payments → AI keys → registries), issuer
    first, each old value proven dead with a 401, then provider-side log hunting.

"is our PHP site affected by the new PHP vulnerability?"
  → /snr-php. Finds every PHP, resolves the build that actually serves traffic,
    compares with the fixed releases, lists interim mitigations if you cannot patch
    today, and runs the compromise assessment for the exposure window.

"pentest our staging site"
  → /snr-pentest. Asks for written authorisation and scope, writes scope.txt, runs
    scope-guard before every host, tests access control with two accounts, proves
    findings with inert markers, reports fix + regression test, then retests.

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
<summary><b>Twenty skills — does that fill up the context window?</b></summary>

No. Only skill *descriptions* are loaded up front (a few hundred tokens total). A
skill's body loads when it is triggered, and its reference files load only when that
skill decides it needs them. This is why the suite is twenty focused skills rather
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
<summary><b>Can it "hack" my system?</b></summary>

It can run an **authorised, scoped, non-destructive security test** — the way a
professional penetration tester does. It requires your written confirmation of
ownership or authorisation, a scope file with an expiry date, and it checks every
host against that file before touching it. It proves findings with harmless markers,
never harvests real data, and never runs denial-of-service, malware, persistence or
post-exploitation. Without a scope it will only review code you own or work in a local
lab. See `pentest-methodology`.
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
