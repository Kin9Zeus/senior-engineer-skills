# PHP ecosystem hardening — Composer, WordPress, Laravel, Symfony

The interpreter is one risk. Most real compromises of PHP sites come through the
ecosystem on top of it: plugins, packages, and production settings left in
development mode.

> Plugin and package advisories change daily. Never assert a vulnerable version
> from memory — run the audit tool and quote its real output.

---

## Composer and dependencies

```bash
composer validate --strict
composer audit                      # reads advisories — contacts the package index
composer outdated --direct
```

- Commit `composer.lock`; install in CI and production with
  `composer install --no-dev --prefer-dist --optimize-autoloader` (add
  `--no-scripts` where scripts are not required for the build).
- Configure `allow-plugins` explicitly in `composer.json`; an unreviewed Composer
  plugin runs code during install.
- Review `scripts` entries (`post-install-cmd`, `post-update-cmd`) in your own and
  in new dependencies before adding them.
- Prefer maintained packages; remove abandoned ones (`composer audit` reports
  abandoned packages).
- Keep `vendor/` and `composer.json/lock` **out of the web root**.
- Pin CI actions by SHA; cache keyed on the lockfile hash
  (`security-hardening/references/supply-chain.md`).

**Verify:** CI fails on `composer audit` findings of high severity or on a
lockfile that does not match `composer.json`.

---

## WordPress

WordPress core is comparatively well-defended; **plugins and themes are where
sites are taken**. Install only what you need.

```
[ ] Core, themes, plugins updated; automatic updates on for security releases
[ ] Inactive plugins/themes DELETED (inactive ≠ safe; the files are still reachable)
[ ] Plugin set reviewed: maintained, recent update, reasonable install base;
    nulled/pirated plugins forbidden (they ship with backdoors)
[ ] define('DISALLOW_FILE_EDIT', true);   — no editing code from wp-admin
[ ] define('DISALLOW_FILE_MODS', true);   — on production where updates ship via deploy
[ ] wp-config.php outside the web root (WordPress supports one directory up) or denied
[ ] Fresh salts/keys (wp-config) — regenerate after any compromise; this logs everyone out
[ ] Admin accounts: unique names (no "admin"), MFA, least-privilege roles
[ ] XML-RPC disabled unless required; REST user enumeration restricted
[ ] Login rate-limited; admin path behind IP allowlist or SSO where feasible
[ ] Uploads directory cannot execute PHP (php-ini-baseline.md)
[ ] Database user has only the privileges WordPress needs; unique table prefix is cosmetic
[ ] Backups off-host, restore tested
[ ] A vulnerability feed for plugins subscribed (check current providers)
```

**Compromise check:** compare core files against the official checksums
(`wp core verify-checksums` where WP-CLI is available), reinstall core and
plugins from clean sources, list admin users, look for `.php` in uploads and for
`eval(base64_decode(` / `gzinflate(` patterns in themes and plugins, and review
scheduled events (`wp cron event list`).

---

## Laravel

```
[ ] APP_ENV=production, APP_DEBUG=false  — debug pages leak environment and source
[ ] APP_KEY set, unique per environment, never committed. Rotating it affects
    encrypted data and sessions — plan using the framework's documented
    previous-key support before rotating (see secret-rotation-playbook.md)
[ ] php artisan config:cache / route:cache / view:cache in production builds
[ ] Debug tooling (Telescope, Debugbar, Ignition share/execute features) NOT
    reachable in production; gated by auth if present
[ ] Mass assignment: every model defines $fillable (preferred) — avoid $guarded = []
[ ] Authorization via Policies/Gates on every controller action (object-level)
[ ] Eloquent/Query Builder with bindings; no whereRaw/DB::raw with concatenation
[ ] Rate limiting on login, reset, API (RateLimiter / throttle middleware)
[ ] Sanctum/Passport tokens scoped and expiring; sessions in Redis/DB, not files shared across apps
[ ] storage/ and bootstrap/cache writable only by the app user; public/ is the only web root
[ ] .env not in the web root; deny dotfiles at the server
[ ] Queue workers restarted after deploys (php artisan queue:restart) — and after PHP patches
[ ] Trusted proxies configured explicitly, not '*'
```

## Symfony

```
[ ] APP_ENV=prod, APP_DEBUG=0; the web profiler and debug toolbar not reachable
[ ] Secrets via the Secrets vault or environment, `APP_SECRET` unique per environment
[ ] security.yaml: access_control denies by default; voters for object-level rules
[ ] CSRF protection on forms; sessions with secure cookie options
[ ] Doctrine parameters bound; no string-built DQL/SQL
[ ] _fragment / debug routes disabled in prod; `bin/console` not web-accessible
[ ] Messenger workers restarted on deploy and on PHP patches
```

## Drupal, Joomla and others

Apply the same shape: a supported major version, security releases applied
within days (their teams publish advisories — subscribe), modules/extensions
minimised, admin behind MFA, writable directories non-executable, and a tested
restore. Check the project's current security-team guidance rather than relying
on this document for version specifics.

---

## Deployment hygiene (all PHP)

- Deploy by **immutable artifact** (image or release directory + atomic symlink),
  not by editing files on the server.
- Files in the web root owned by a deploy user, read-only to the PHP user.
- Nothing like `.git`, `.env`, `composer.json`, `vendor/`, backups (`*.sql`,
  `*.zip`, `*.bak`) or editor leftovers in the web root:

```bash
for p in .env .git/config composer.json composer.lock vendor/autoload.php phpinfo.php backup.sql; do
  # run only against a host you own
  printf '%s -> ' "$p"; curl -s -o /dev/null -w '%{http_code}\n' "https://YOUR-OWN-HOST/$p"
done
# every line must be 403 or 404
```

- Staging and preview environments get **their own** secrets, behind auth, not
  copies of production's.
- Logs and error pages never print environment variables or stack traces to users.
