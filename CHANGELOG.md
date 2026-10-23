# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For a skill suite, versioning means:

- **Major** — a skill is removed or renamed, or the plugin structure changes in a
  way that breaks an existing install.
- **Minor** — a new skill, command, agent or script; a substantial expansion of
  existing guidance.
- **Patch** — corrections, clarifications, script fixes, documentation.

---

## [1.1.0] — 2026-10-23

Security response and authorised testing. Prompted by two incidents disclosed on
21 October 2026: Railway's possible exposure of stored customer environment
variables, and PHP's emergency fix for two critical unauthenticated
remote-code-execution flaws (CVE-2026-109618, CVE-2026-109619). Incident facts are
dated 2026-10-23 and link their primary sources.

### Skills (+5 → 20)

| Skill | Covers |
|---|---|
| `security-incident-response` | Triage into four classes, ordered upstream-first secret rotation with proof the old value is dead, provider-side log hunting, persistence checklist, recovery, notification flag; Railway case file; incident timeline and rotation tracker templates |
| `php-hardening` | php2shell response (inventory, patch, restart, verify the running build, interim mitigations, compromise assessment), php.ini / FPM / nginx / Apache / container baseline, PHP-specific code flaws, Composer, WordPress, Laravel, Symfony |
| `pentest-methodology` | Authorisation gate and rules of engagement, scope guard, white/grey/black-box method, web / API (OWASP API Top 10) / infrastructure test plans, tooling and a local practice lab, reporting and retest; RoE and report templates |
| `cloud-security` | "Assume the platform is breached": the secrets ladder, blast-radius questions, OIDC federation, egress control, PaaS / AWS / GCP / Azure / container / Kubernetes / IaC checklists, rotation drills |
| `ai-security` | Prompt injection, the private-data / untrusted-content / outbound-channel overlap, excessive agency, output handling, RAG and tenant isolation, MCP / skill / instruction-file supply chain, AI-provider key and spend protection, an attack-suite eval design |

### Commands (+7 → 14)

`/snr-incident` · `/snr-rotate` · `/snr-php` · `/snr-pentest` · `/snr-cloud` ·
`/snr-ai-security` · `/snr-threatmodel`

### Agents (+4 → 8)

`snr-incident-responder` · `snr-pentester` · `snr-cloud-auditor` · `snr-php-auditor`

### Scripts (+3, each in `.sh` and `.ps1`)

- `security-incident-response/scripts/rotation-inventory` — secret **names** the
  repository reads or defines, never values
- `php-hardening/scripts/php-check` — declared PHP versions, CLI build against the
  fixed releases, ini values, PHP risk patterns
- `pentest-methodology/scripts/scope-guard` — refuses hosts and IPs outside a signed
  scope file or after its expiry

### Changed

- `senior-engineer`: routes the new skills; non-negotiable bar now includes runtime
  currency and blast-radius-limited credentials; description covers security events
- `security-hardening`: new section on platform and runtime failure; routing to the
  new skills; secret-value guidance
- `project-audit`: security extensions table (PHP, platform, AI, compromise, testing)
- `devops-platform`, `release-readiness`: platform-breach, rebuild-on-advisory and
  rotation-readiness checks added; launch checklist gains runtime and rotation gates
- `role-playbooks`: Penetration Tester and Incident Responder playbooks; platform
  trust and runtime currency in the AppSec playbook
- `secret-scan`: PHP include/`phpinfo` sinks, remote-script-to-shell, unpinned CI
  actions
- `/snr-harden` and `snr-security-auditor`: look beneath the code and hand off
- README (English and Spanish), installers, manifests and `AGENTS.md` updated;
  the install section now covers Windows, macOS and Linux side by side
- CI: GitHub Actions pinned to commit SHAs, with Dependabot keeping them current

---

## [1.0.0] — 2026-08-24

First public release.

### Skills (15)

| Skill | Covers |
|---|---|
| `senior-engineer` | The router and the standard: discovery protocol, severity rubric, role playbooks, recurring anti-patterns |
| `project-audit` | 15-domain audit, architecture review, per-stack playbooks, 30-minute quick scan, report template |
| `project-blueprint` | Stack selection, architecture patterns, day-one scaffold checklist, product-type blueprints, ADR/README/config templates |
| `security-hardening` | OWASP Top 10 checklist, authorization patterns, authentication patterns, security headers and CSP, supply chain, 30-minute threat model |
| `database-engineering` | Schema design, indexing and query plans, zero-downtime migrations, backups and restore drills, data lifecycle and erasure |
| `api-contracts` | REST house style, error envelopes, idempotency, versioning, rate limits, webhooks, integration patterns |
| `devops-platform` | Pipeline design, infrastructure as code, environments, deploy and rollback, containers, secrets, DR, cost |
| `observability-slo` | Telemetry setup, correlation ids, SLOs and error budgets, alerting on symptoms, incident response and postmortems |
| `testing-strategy` | Test pyramid, coverage policy, test patterns, flake control, specialised testing (load, security, a11y, contract, mutation, property) |
| `performance-engineering` | Core Web Vitals diagnostic order, frontend techniques, backend profiling, caching, capacity planning |
| `accessibility-audit` | WCAG 2.2 AA checklist, accessible component patterns, manual and automated testing protocol |
| `web-presence-audit` | Technical SEO, on-page metadata, structured data (including `LocalBusiness` and `FAQPage`), trust and conversion surface |
| `privacy-compliance` | Data inventory from code, cookie consent, rights pipeline (export and deletion), governance |
| `release-readiness` | Go/no-go gate, launch checklist with verification commands, runbook template |
| `engineering-standards` | Conventions, git and review practice, documentation |

### Commands (7)

`/snr-audit` · `/snr-build` · `/snr-harden` · `/snr-web` · `/snr-privacy` ·
`/snr-ship` · `/snr-scorecard`

### Agents (4)

`snr-security-auditor` · `snr-data-auditor` · `snr-web-auditor` · `snr-architect`

### Scripts

Read-only, POSIX shell and PowerShell, no dependencies beyond `curl`, `grep` and
`git`:

- `project-audit/scripts/recon.{sh,ps1}` — stack, state layer, tests, CI, risk
  signals, third parties
- `security-hardening/scripts/secret-scan.{sh,ps1}` — credential patterns in the
  working tree and git history, injection sinks, configuration weaknesses
- `web-presence-audit/scripts/web-check.{sh,ps1}` — live URL surface check across
  transport, crawlability, metadata, social, structured data, images and trust
  pages

### Templates

Audit report · ADR · README skeleton · config contract · `robots.txt` · 404 page
· FAQ page · case study · thank-you page · **privacy policy (English and
Spanish)** · cookie policy · subprocessor list · deletion request flow · go/no-go
verdict · runbook

### Documentation

- `README.md` and `README.es.md` — full documentation in English and Spanish
- `CONTRIBUTING.md` — the editorial standard, bilingual
- `SECURITY.md` — disclosure policy, bilingual
- `AGENTS.md` — conventions for AI assistants working on this repository

### Installation

- Claude Code plugin marketplace (`.claude-plugin/marketplace.json`)
- `npx skills add` for 40+ agents
- `install.sh` / `install.ps1` with agent auto-detection, `--project`,
  `--dry-run` and `--uninstall`

---

[1.0.0]: https://github.com/Kin9Zeus/senior-engineer-skills/releases/tag/v1.0.0
