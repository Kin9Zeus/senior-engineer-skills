# PHP production baseline

Configuration cannot fix a vulnerable interpreter — patch first. It can **remove
attack paths, shrink what a worker can reach, and make a compromise loud**.

Every directive below: set it in `php.ini`, the FPM pool, or server config.
Settings the application must not override go in `php_admin_value` /
`php_admin_flag`, which `ini_set()` and `.user.ini` cannot change. Check the
current PHP manual for defaults in your branch — they have changed over time.

---

## php.ini (production)

```ini
; --- Information leakage ---
expose_php              = Off
display_errors          = Off
display_startup_errors  = Off
html_errors             = Off
log_errors              = On
error_log               = /var/log/php/error.log   ; not web-readable
zend.assertions         = -1                        ; never assert() in production

; --- Remote code / file inclusion ---
allow_url_include       = Off
allow_url_fopen         = Off      ; On only if the app truly fetches URLs — then SSRF-guard it

; --- Requests and uploads: smallest that works ---
file_uploads            = Off      ; On only for apps that need it
upload_max_filesize     = 2M
post_max_size           = 8M       ; raise only where uploads require it
max_file_uploads        = 5
max_input_vars          = 1000
max_input_nesting_level = 32
max_execution_time      = 30
memory_limit            = 128M     ; finite. (-1 only as a documented interim mitigation)

; --- Sessions ---
session.use_strict_mode    = 1
session.use_only_cookies   = 1
session.use_trans_sid      = 0
session.cookie_httponly    = 1
session.cookie_secure      = 1
session.cookie_samesite    = Lax
session.upload_progress.enabled = 0   ; also a documented interim mitigation (see php2shell-response)

; --- Defence in depth (weak alone, useful together) ---
; Only disable functions the app does not use. Test before enabling.
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,pcntl_exec,dl,show_source
open_basedir      = /var/www/app:/tmp/php-app

; --- nginx + FPM ---
cgi.fix_pathinfo  = 0

; --- OPcache: immutable deploys ---
opcache.validate_timestamps = 0      ; if code only changes via redeploy
```

`disable_functions` and `open_basedir` are **speed bumps, not boundaries** — they
are known to be bypassable and must not be the only control. They make casual
post-exploitation harder and noisier. Do not enable what breaks the app; verify
with the test suite.

**Verify** (from a request context, not CLI): a locked-down internal route that
prints `ini_get()` for each key above, compared with this file. Fail the deploy
if `display_errors`, `allow_url_include`, `expose_php` differ.

---

## PHP-FPM pool (one pool per application)

```ini
; /etc/php/<ver>/fpm/pool.d/app.conf
[app]
user  = app-web
group = app-web
listen = /run/php/app.sock
listen.owner = www-data          ; the web server's user
listen.group = www-data
listen.mode  = 0660

pm = dynamic
pm.max_children = 20
pm.max_requests = 500            ; recycle workers; 1 only as a temporary mitigation

security.limit_extensions = .php  ; only execute .php, not .jpg.php tricks via config
clear_env = yes                   ; do NOT pass the whole environment to workers
env[APP_ENV] = production         ; pass ONLY what the app reads, explicitly

; Cannot be overridden by the application:
php_admin_value[error_log]            = /var/log/php/app-error.log
php_admin_flag[log_errors]            = on
php_admin_flag[display_errors]        = off
php_admin_value[open_basedir]         = /var/www/app:/tmp/php-app
php_admin_value[session.save_path]    = /var/lib/php/sessions/app
php_admin_value[upload_tmp_dir]       = /tmp/php-app
php_admin_flag[session.upload_progress.enabled] = off
```

- **One Unix user per application**, not a shared `www-data` for everything.
- `clear_env = yes` plus explicit `env[...]` is the high-value line: a worker only
  sees the secrets you named. (If you use a secrets manager, fetch at runtime.)
- Files owned by a deploy user, **not writable by the PHP user** except upload,
  cache and log directories.

---

## nginx

```nginx
server_tokens off;
client_max_body_size 8m;

# Only the front controller runs PHP — everything else is static or 404.
location / { try_files $uri /index.php?$query_string; }

location ~ ^/index\.php(/|$) {
    include fastcgi_params;
    fastcgi_pass unix:/run/php/app.sock;
    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    internal;                                  # not directly requestable
}
location ~ \.php$ { return 404; }              # no other .php is executable
location ~ /\.(?!well-known) { deny all; }     # .git, .env, .htaccess …

# Uploads: never execute.
location ^~ /uploads/ {
    location ~ \.(php|phtml|phar)$ { return 403; }
    add_header X-Content-Type-Options nosniff always;
}
```

To refuse multipart bodies on routes that do not accept uploads, route the
upload endpoints to their own `location` and return `415` for multipart
elsewhere — test it against your real traffic first; a blanket block breaks
legitimate forms.

## Apache

- Prefer **event MPM + PHP-FPM** over `mod_php`. `mod_php` runs PHP inside every
  Apache worker, with the worker's privileges — the configuration reported at
  highest risk for the October 2026 flaws.
- `ServerTokens Prod`, `ServerSignature Off`, `LimitRequestBody 8388608`.
- Deny dotfiles: `<FilesMatch "^\.">  Require all denied  </FilesMatch>`.
- Disable PHP in upload directories: `<Directory "/var/www/app/uploads"> php_admin_flag engine off  </Directory>` (mod_php) or `SetHandler none` / deny `.php` (FPM).

## Containers

```dockerfile
FROM php:8.3-fpm@sha256:<digest>      # pin by digest; rebuild on every PHP advisory
RUN useradd --system --no-create-home app
COPY --chown=root:root --chmod=0555 . /var/www/app   # code not writable by the app
USER app
# runtime: --read-only --tmpfs /tmp --cap-drop=ALL --security-opt no-new-privileges
#          --memory=512m   (cgroup limit; bounds a runaway worker)
```

- No secrets in image layers or build args. Inject at runtime.
- Rebuild with `--pull --no-cache` on advisories; **a patched base tag you never
  rebuilt against is not patched**.
- Scan the image on every build (e.g. a vulnerability scanner in CI) and treat a
  fixable critical in the runtime layer as a release blocker.

---

## Verification checklist

- [ ] `display_errors` Off, `expose_php` Off in the serving SAPI
- [ ] No `phpinfo()` reachable (search the code; request `/phpinfo.php` → 404)
- [ ] Per-application FPM pool and Unix user; `clear_env = yes`
- [ ] App code not writable by the PHP user
- [ ] Uploads directory cannot execute PHP (upload a harmless `.txt` renamed
      `.php` in a test environment, request it, expect download or 403 — never
      execution)
- [ ] Memory limited by cgroup/container
- [ ] `mod_php` absent, or on a dated migration plan
