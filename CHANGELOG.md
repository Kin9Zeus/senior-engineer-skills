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
