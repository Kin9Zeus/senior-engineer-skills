---
name: php-hardening
description: PHP security — emergency response to critical PHP runtime vulnerabilities (the October 2026 "php2shell" remote-code-execution pair), PHP version and SAPI inventory, php.ini and PHP-FPM hardening, Apache mod_php to FPM migration, and PHP application-code security for Laravel, Symfony, WordPress and plain PHP. Use when the user says "PHP vulnerability", "PHP CVE", "php2shell", "CVE-2026-109618", "CVE-2026-109619", "update PHP", "is my PHP safe", "PHP RCE", "patch PHP", "harden PHP", "php.ini", "PHP-FPM", "mod_php", "WordPress hacked", "Laravel security", "composer audit", "unserialize", "webshell in PHP" or "PHP version end of life"; when a project has composer.json, .php files, a php Docker image, WordPress, Laravel or Symfony; and as a pass in any audit of a PHP project. Defensive security only. By Devleck.
license: MIT
---

# PHP Hardening

PHP runs a very large share of the public web, which is why a flaw in the
interpreter itself is an event, not a nuisance. This skill does three things in
order: **get patched**, **shrink what a flaw in PHP could reach**, and **fix the
PHP-shaped bugs in the application**.

**Scope:** PHP systems the user owns or is authorised to assess. Defensive only:
inventory, patch, configure, detect, fix. No exploit code, no probing of
third-party hosts.

> **Fact-check rule.** Versions and advisories change. The incident facts below
> are dated; before relying on them, **re-read the official PHP advisory and your
> distribution's advisory**. Never assert a CVE or a fixed version from memory.

---

## 1. The order of work

```
1  INVENTORY   every PHP you run — including copies you did not install
2  PATCH       upgrade, restart every worker, verify the RUNNING build
3  REDUCE      config that blocks known attack paths + shrinks blast radius
4  ASSUME      if exposed and unpatched in the window, treat as possibly compromised
5  HUNT        shells from web workers, new files, outbound traffic, crashes
6  HARDEN      baseline config, then application code, then dependencies
7  PREVENT     patch SLA, image rebuilds on advisory, detection that fires
```

Steps 1–5 are the incident (`security-incident-response` is the parent
playbook); 6–7 are the lasting work.

---

## 2. Incident: "php2shell" (October 2026)

> **Last verified: 2026-10-23.** Details evolve — confirm against the sources.

**What was disclosed.** On 21 October 2026 the PHP project released emergency
fixes for **CVE-2026-109618** and **CVE-2026-109619**, two critical flaws in the
core interpreter allowing **unauthenticated remote code execution** against
installations that serve web requests. CISA published an alert the same day.

| | |
|---|---|
| **Fixed releases** | PHP **8.5.12**, **8.4.27**, **8.3.36**, **8.2.35** |
| **PHP 7.4 – 8.1** | No official release; the PHP security team published **minimal source backports**. Get a fixed build from your distributor, apply the backport, or upgrade |
| **Older / EOL** | No fix from the project. Treat as unfixable in place — migrate or isolate |
| **Root causes** (per Tenable's summary) | 109618: out-of-memory handling leaves request data half-initialised and cleanup treats it as valid. 109619: use-after-free from stale global state reused by a later request on the same worker |
| **Reach** | Every SAPI that serves web requests: PHP-FPM, Apache `mod_php`, `php-cgi`, FrankenPHP, LiteSpeed. Highest risk reported for **`mod_php`** |
| **Application-independent** | The bug is in PHP, not in WordPress/Laravel/your plugins. Updating the app does not fix it |
| **Exploitation** | Reports conflict: Amazon Threat Intelligence reported an attempt on **17 October**, four days *before* disclosure, and broader attempts after; CISA's alert said it had not observed exploitation at publication; neither CVE was in CISA's KEV catalogue as of 22 October. **Treat as actively exploited** |

**Primary and key sources** — read these, not a summary of them
- CISA alert: <https://www.cisa.gov/news-events/alerts/2026/10/21/critical-vulnerabilities-php-require-immediate-patching>
- Tenable FAQ (versions, root causes, workarounds): <https://www.tenable.com/blog/php2shell-cve-2026-109618-cve-2026-109619-frequently-asked-questions-about-critical-php-remote>
- Qualys (finding PHP, mitigation, advisory ids): <https://blog.qualys.com/vulnerabilities-threat-research/2026/10/20/php-announces-critical-security-release-for-two-vulnerabilities>
- The official advisory on php.net and your distro's security tracker

Step-by-step response, interim mitigations and the post-patch compromise
assessment: `references/php2shell-response.md`.

### The 10-minute version

```bash
bash skills/php-hardening/scripts/php-check.sh .      # inventory + config + sinks
```

1. **Find every PHP.** Declared versions in the repo, base images, CI, hosting
   config — and the binary that actually serves web traffic. `php -v` on a shell
   often reports a *different* installation than FPM or Apache is running.
2. **Patch the serving runtime.** Distro package, new image tag, or a new
   platform build. Distribution packages may carry the fix under an *older*
   upstream version number — check the vendor advisory, not the string.
3. **Restart every process that loads PHP** (FPM pools, Apache, queue workers,
   Octane/RoadRunner/Swoole). A patched package under a running old process is
   not patched.
4. **Verify the running build** — a version endpoint you control, a container
   image digest, or the platform's deploy record. Not "the package says so".
5. **If you cannot patch today**, apply the interim mitigations in the reference
   (they reduce exposure; they are not a fix) and put edge protection and
   request limits in front.
6. **Assume exposure** for the window the runtime was reachable and unpatched
   (the earliest reported attempt was 17 October). Rotate secrets that the PHP
   process could read and hunt (`security-incident-response`).

---

## 3. What people get wrong

- **"I updated WordPress/Laravel, so I'm fine."** The flaw is in the
  interpreter. App updates do not touch it.
- **Checking `php -v` over SSH.** The CLI binary, the FPM binary and the Apache
  module can be three different installs. Check the one that serves requests.
- **Patching the image but not redeploying**, or redeploying a cached layer that
  still has the old PHP. Rebuild with a no-cache/pull flag and compare digests.
- **Forgetting bundled PHP**: hosting-panel packages, appliances, vendor
  products, a forgotten staging VM, a CI image. Inventory broadly.
- **Leaving workaround settings forever.** Interim settings (for example an
  unlimited `memory_limit`) trade one risk for another. Record them, set an
  owner and a deadline to restore, and restore after patching.
- **Believing a WAF is the fix.** It is partial protection for known vectors on
  traffic that goes through it; the origin stays vulnerable to anything that
  bypasses it.
- **Ignoring EOL branches.** PHP 8.1 and earlier get no official fix. "It still
  works" is the finding.
- **Skipping the compromise assessment** because the patch is applied. Patching
  closes the door; it does not tell you whether someone is already inside.

---

## 4. Lasting hardening — in yield order

1. **Run supported PHP, patched on a stated SLA.** Pick a branch inside security
   support; subscribe to the project's and your distro's security announcements;
   rebuild images on every advisory, not on every feature release.
2. **Prefer PHP-FPM behind nginx/Apache event over `mod_php`.** Separate pools
   per application with separate Unix users; a flaw in one site's workers then
   cannot trivially read another's files. (`references/php-ini-baseline.md`)
3. **Baseline configuration**: errors off in production, dangerous remote
   features off, session settings strict, upload and request limits tight,
   settings the app must not override pinned with `php_admin_*`.
4. **Least privilege for the PHP process**: it can read the code, write only to
   the directories that need it, never write to code, and sees only the secrets
   it needs. In containers: non-root, read-only root filesystem, dropped
   capabilities, a memory limit enforced by the runtime.
5. **Application code**: `references/php-code-security.md` — SQL, XSS,
   `unserialize`, file includes, uploads, type juggling, session and CSRF, SSRF.
6. **Dependencies and framework**: `references/php-ecosystem.md` — Composer
   hygiene, WordPress plugins (the dominant real-world vector), Laravel and
   Symfony production settings.
7. **Detection**: web workers must not spawn shells; alert on it.
   (`security-incident-response/references/detection-and-hunting.md`)

---

## 5. Reporting

```markdown
### PHP runtime below fixed release on internet-facing service — P0
**Class**       Vulnerable runtime (known-exploited RCE class)
**Location**    Dockerfile:1  FROM php:8.3-apache  (resolved build: 8.3.<n>)
**Confidence**  CONFIRMED (resolved from the running image) | PLAUSIBLE (declared only)
**Impact**      Unauthenticated request reaches code execution inside the web
                worker; the worker can read every environment variable and file
                its user can open.
**Fix**         Rebuild on a patched tag; restart all workers; move off mod_php.
**Verify**      The running container reports the fixed build; an interim-setting
                check shows the mitigations if patching is delayed; hunt completed.
```

End with **"What I could not verify"** — typically: the SAPI actually in use, the
real running build, and whether a distro backport applies.

---

## References and scripts

- `references/php2shell-response.md` — inventory, patch, interim mitigations, compromise assessment
- `references/php-ini-baseline.md` — php.ini, FPM pool, nginx, Apache, container baseline
- `references/php-code-security.md` — the PHP-specific bugs, with fixes and verification
- `references/php-ecosystem.md` — Composer, WordPress, Laravel, Symfony
- `scripts/php-check.sh` / `scripts/php-check.ps1` — read-only PHP inventory, config and sink scan
- Related skills: `security-incident-response`, `security-hardening`, `cloud-security`, `devops-platform`
