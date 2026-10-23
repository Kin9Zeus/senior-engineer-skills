# php2shell response — CVE-2026-109618 and CVE-2026-109619

> **Last verified: 2026-10-23.** Interim settings and affected ranges are taken
> from the advisories as reported by CISA, Tenable and Qualys. Re-read the
> official PHP advisory and your distribution's tracker before acting; they are
> authoritative and may have changed.

Goal: **fixed runtime, verified, with a compromise assessment** — in that order,
fast, with a record of what you did.

---

## 1 · Inventory — every PHP you run

```
[ ] Repo: composer.json "require.php", .php-version, .tool-versions, Dockerfile
    FROM php:*, docker-compose images, CI php-version, platform build config
[ ] Registry: tags currently deployed (not just what the Dockerfile says today)
[ ] Hosts: package manager version, AND the binary FPM/Apache actually loads
[ ] SAPIs: PHP-FPM · Apache mod_php · php-cgi · FrankenPHP · LiteSpeed · CLI-only
[ ] Bundled copies: hosting panels, appliances, vendor products, CI images,
    forgotten staging VMs, serverless/layer runtimes
[ ] Queue workers and long-lived servers (Octane / RoadRunner / Swoole): they
    keep an old binary in memory until restarted
[ ] Internet-facing first. Then internal. CLI-only batch jobs last
```

Helper: `bash skills/php-hardening/scripts/php-check.sh .`

**Do not trust the version string alone.** A distribution may ship the fix under
an older upstream number. Check the vendor advisory for the exact package
version. Conversely, a container tag like `php:8.3-apache` floats — resolve the
*digest* you actually run.

## 2 · Patch

| Your branch | Action |
|---|---|
| 8.5 / 8.4 / 8.3 / 8.2 | Upgrade to 8.5.12 / 8.4.27 / 8.3.36 / 8.2.35 or later in the same branch (or the vendor's fixed package) |
| 7.4 – 8.1 | No official release. Use the distro/LTS vendor's fixed build, apply the project's published backport, or upgrade to a supported branch. Prefer upgrading |
| < 7.4 | No fix. Migrate; until then, isolate (below) |

After the upgrade:

```bash
# Debian/Ubuntu example — restart whatever loads PHP, then confirm the loaded build
sudo systemctl restart php8.3-fpm apache2 nginx      # adapt to your units
# Containers: rebuild without cache, pull the base, then redeploy
docker build --pull --no-cache -t app:patched .
```

**Verify the running build** — one of: a version-reporting health route you
control (never expose `phpinfo()`), the running image digest against the one you
built, or the platform's deploy record. Record it. **Verify** = the workers that
answer requests report the fixed build.

## 3 · If you cannot patch today — interim mitigations

These reduce exposure to *known* attack paths. They are **not** fixes. Record
each with an owner and a removal date. Restart every PHP worker after any change.

Per the advisory as summarised by Tenable and Qualys:

| For | Setting | Notes |
|---|---|---|
| CVE-2026-109619 | `session.upload_progress.enabled = 0` | Set in `php.ini` / the FPM pool / server config — **not** with `ini_set()` in application code. On PHP 8.5 also `fatal_error_backtraces = 0` |
| CVE-2026-109618 | `memory_limit = -1`, set so applications cannot override it (`php_admin_value` in the FPM pool or Apache config) | Counter-intuitive: the reported flaw is in out-of-memory handling. Unlimited memory is a **denial-of-service risk** — bound it with a container/cgroup memory limit, and **restore a finite `memory_limit` after patching**. An underlying allocation failure can still reach the vulnerable path |
| Both (hardening) | Tighten `post_max_size`, `upload_max_filesize`, `max_file_uploads`, `max_input_nesting_level` | If uploads are unused, much smaller; the advisory discussion cited `post_max_size` in the 8M–32M range |
| Both (hardening) | `pm.max_requests = 1` on PHP-FPM, if performance allows | Limits state carried between requests on one worker |
| Both | Remove invalid or deprecated per-request INI overrides (`.user.ini`, `php_value` in `.htaccess`) | Reduces attacker-influenced config |

Network and edge, in front of the origin:

- **Block or restrict `multipart/form-data`** on routes that never accept uploads
  (at nginx/Apache/the proxy). Cap request body size at the edge.
- A **WAF** with the vendor's rule set for these CVEs (Cloudflare reported rules
  for known vectors). Partial only; the origin stays vulnerable to bypasses.
- **Isolate** internet-facing PHP: IP allowlist, VPN, or take it offline if it
  is unsupported and not essential (CISA's recommendation for PHP 8.1 and
  earlier that cannot be updated).
- Move `mod_php` sites to PHP-FPM when you can: highest reported risk is
  `mod_php`, where a demonstrated exploit runs before application code.

**Verify** the interim settings are *in effect* for the serving SAPI — read the
active value from a request-time context you control (a locked-down internal
diagnostics route), not from `php -i` on the CLI.

## 4 · Compromise assessment — assume until shown otherwise

If the runtime was internet-reachable and unpatched at any point since the
**earliest reported attempt (17 October 2026)**, treat it as possibly
compromised. Patching does not remove an attacker who already ran code.

```
1  PRESERVE   snapshot the disk/image and note running processes before changes
2  SECRETS    list everything the PHP process could read: environment variables,
             .env, config files, mounted secrets, framework app keys, DB
             credentials, API keys, cloud credentials from the metadata service
3  ROTATE     everything in step 2, highest blast radius first, old values proven
             dead (security-incident-response/references/secret-rotation-playbook.md)
4  HUNT       detection-and-hunting.md §2–§4:
               · web worker processes that spawn sh/bash/curl/wget/nc/python
               · new or modified .php/.phtml/.phar files in webroot, uploads, tmp
               · outbound connections from the web user to unfamiliar hosts
               · worker crashes (signal 11 / OOM) clustered in time or by client
               · new cron jobs, SSH keys, users, deploy keys, webhooks
5  REBUILD    if you cannot prove it is clean, redeploy from a patched, freshly
             built image rather than cleaning by hand
6  REVIEW     data the process could reach: customer data, uploads, databases —
             then the notification track with counsel
```

On a managed platform where you cannot inspect the host, use the deploy history,
the running image digest, variable last-changed times and egress graphs; then
rotate and redeploy.

## 5 · If the app also lives on a platform with a secrets incident

The PHP process reads its environment. If the platform also reported possible
exposure of stored environment variables (see
`security-incident-response/references/platform-breach-playbook.md`, the Railway
case), the two incidents compound: assume the secrets are known **and** that code
could run. One incident record, the higher severity, rotation first.

If the platform has paused deployments, you may be unable to ship the patch —
decide immediately: edge restrictions, take non-critical services down, and stop
workers that call spend-bearing APIs. After the freeze lifts, redeploy the
**latest** commit explicitly and verify the running build.

## 6 · Closure checklist

- [ ] Every inventoried PHP is on a fixed build, **verified at runtime**
- [ ] All workers restarted after patching
- [ ] Interim mitigations removed or ticketed with owner and date
      (and any `memory_limit=-1` restored to a finite value)
- [ ] Secrets reachable by the PHP process rotated; old values proven dead
- [ ] Hunt completed for the window from 17 October; findings explained
- [ ] `mod_php` → PHP-FPM migration planned for remaining sites
- [ ] EOL branches have a dated migration or isolation plan
- [ ] Patch SLA and advisory subscriptions in place (see `SKILL.md` §4)
- [ ] Timeline recorded (`security-incident-response/templates/incident-timeline.md`)
