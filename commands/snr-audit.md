---
description: Run a full senior engineering audit across 15 domains and produce a prioritised findings report with a 0-100 scorecard.
argument-hint: "[path or URL] [--quick | --deep] [--parallel]"
---

# Senior Engineering Audit

Run a full-spectrum audit of **$ARGUMENTS** (default: the current repository).

Load the `project-audit` skill and follow it exactly. Load `senior-engineer` for
the discovery protocol and the severity rubric.

## Depth

- `--quick` — the 30-minute triage in `project-audit/references/quick-scan.md`.
  Domains 1, 2, 3 and 11 at depth; the rest as a one-line status. Say explicitly
  that this is not a full audit.
- *(default)* — Standard. All fifteen domains, depth proportional to weight.
- `--deep` — All fifteen at depth, plus a threat model, a restore-drill request
  and a load-test recommendation.

## Parallelising

`--parallel` is an explicit authorisation to dispatch concurrent domain
reviewers. When passed, run these as independent subagents and merge the
findings, giving each one the Ground Truth block so nobody re-derives it:

1. Security and supply chain — load `security-hardening`
2. Data and persistence — load `database-engineering`
3. Testing and correctness — load `testing-strategy`
4. Web presence, accessibility and privacy — load `web-presence-audit`,
   `accessibility-audit`, `privacy-compliance`
5. Platform, observability and performance — load `devops-platform`,
   `observability-slo`, `performance-engineering`

Without `--parallel`, run the passes yourself, in weight order.

## Before anything else

1. **Confirm scope.** Repository only, or also the live site and infrastructure?
   Never send traffic to infrastructure the user has not confirmed they own or
   are authorised to test.
2. **Confirm what may be run.** Read-only analysis is always safe. Ask before
   installing dependencies, running tests, or starting services.
3. Run `skills/project-audit/scripts/recon.sh` (or `recon.ps1`) if the
   environment allows. It is read-only.

## Output

Use `project-audit/templates/audit-report.md`. Write it to
`AUDIT-<YYYY-MM-DD>.md` if it is longer than a screen, and offer to publish it
as a shareable artifact.

Every finding: **what is wrong → why it matters concretely → the fix → how to
verify the fix**, with a `file:line` location and a `CONFIRMED`/`PLAUSIBLE`
label.

The **"What I could not verify"** section is mandatory and must never be empty
by omission.

## Calibration

Grade against what this project claims to be, not against a hypothetical ideal —
but hold every project to identical standards on secrets in git, cross-user data
access, backups, and honest privacy claims.

Do not inflate the score to be kind, and do not inflate findings to look
thorough. A `P0` that is not exploitable teaches the reader to ignore your
`P0`s.
