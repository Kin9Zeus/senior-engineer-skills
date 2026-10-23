---
description: PHP security — inventory every PHP runtime, check against the October 2026 php2shell fixes, apply interim mitigations, harden config and code, assess compromise.
argument-hint: "[path or host scope, e.g. '.' | 'the WordPress site' | 'Dockerfile']"
---

# PHP Security Pass

Scope: **$ARGUMENTS** (default: the whole repository and its deployment config).

Load the `php-hardening` skill. Defensive only. **Do not trust remembered versions
or CVEs** — the incident facts in the skill are dated 2026-10-23; re-read the
official PHP advisory and your distribution's tracker before asserting anything.

## 1 · Run the inventory

```
bash skills/php-hardening/scripts/php-check.sh .      # PowerShell: php-check.ps1
```

Every hit is a **lead**. Then answer from the real environment, not the repo:

- Which PHP **actually serves requests**? (FPM / Apache `mod_php` / container / platform build)
- Is it at or above the fixed release for its branch, or a vendor-fixed build?
- Were **all workers restarted** after patching? Is the *running* build verified?

## 2 · If anything is unpatched

Follow `references/php2shell-response.md`: patch → restart → verify; interim
mitigations only if patching must wait (each with owner and removal date);
edge restrictions; then the **compromise assessment** — assume exposure for the
window since 17 October 2026, rotate secrets the PHP process could read, and hunt
(`security-incident-response`). If the platform also reported a secrets incident,
treat both as one.

## 3 · Then harden

In yield order: supported branch with a patch SLA → PHP-FPM over `mod_php` and a
pool per app → baseline config (`references/php-ini-baseline.md`) → least-privilege
process and container → application code (`references/php-code-security.md`) →
Composer / WordPress / Laravel / Symfony hygiene (`references/php-ecosystem.md`).

## 4 · Output

Findings in the suite format (what is wrong → why it matters → fix → verify), P0 first:

```markdown
### <Title> — P0
**Class** · **Location** · **Confidence** CONFIRMED | PLAUSIBLE · **Impact** ·
**Reproduce/Evidence** · **Fix** · **Verify**
```

For code findings, include a failing regression test. End with **What I could not
verify** — typically the serving SAPI, the real running build, and distro backports.
