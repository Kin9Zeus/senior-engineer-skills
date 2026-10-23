#!/usr/bin/env bash
# Devleck Senior Engineer Skills — read-only PHP inventory and risk-pattern scan.
#
# 1. Finds every place a PHP version is declared (composer, Docker, CI, version
#    files, platform config).
# 2. If a `php` binary is on PATH, reports its version and the ini values that
#    matter, and compares the version with the fixed releases listed below.
# 3. Greps application code for PHP-specific dangerous patterns.
#
# Makes no network calls and modifies nothing. It is a triage aid, not a scanner:
#   * The CLI binary is NOT necessarily the PHP that serves your web traffic
#     (FPM / Apache / the container can be different). Verify the serving runtime.
#   * Distribution packages may carry the fix under an older version number.
#   * Everything it reports is a lead, not a finding — confirm by reading the code.
#
# Fixed releases below are from the October 2026 PHP security release (CVE-2026-109618
# and CVE-2026-109619) as reported by CISA / Tenable — VERIFY against the official
# PHP advisory; update the variables when newer releases ship.
#
# Usage:  ./php-check.sh [path]
# Exit:   0 clean · 1 findings · 2 usage error

set -uo pipefail
ROOT="${1:-.}"
cd "$ROOT" 2>/dev/null || { echo "php-check: cannot enter '$ROOT'" >&2; exit 2; }

FIXED_85=12; FIXED_84=27; FIXED_83=36; FIXED_82=35   # minimum patch level per branch

FINDINGS=0
red() { printf '\033[31m%s\033[0m\n' "$*"; }
ylw() { printf '\033[33m%s\033[0m\n' "$*"; }
grn() { printf '\033[32m%s\033[0m\n' "$*"; }
sec() { printf '\n\033[1m%s\033[0m\n\033[2m%s\033[0m\n' "$1" "────────────────────────────────────────────"; }
hit() { FINDINGS=$((FINDINGS+1)); }
EXCL=(--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor --exclude-dir=storage --exclude-dir=cache --exclude-dir=dist --exclude-dir=build)

# assess <major.minor.patch> -> prints verdict, returns 1 when action needed
assess() {
  local v="$1" mm patch
  mm="$(echo "$v" | cut -d. -f1,2)"; patch="$(echo "$v" | cut -d. -f3 | sed 's/[^0-9].*//')"
  [ -z "$patch" ] && patch=0
  case "$mm" in
    8.5) [ "$patch" -lt "$FIXED_85" ] && { red "P0 · PHP $v is below fixed 8.5.$FIXED_85"; return 1; } ;;
    8.4) [ "$patch" -lt "$FIXED_84" ] && { red "P0 · PHP $v is below fixed 8.4.$FIXED_84"; return 1; } ;;
    8.3) [ "$patch" -lt "$FIXED_83" ] && { red "P0 · PHP $v is below fixed 8.3.$FIXED_83"; return 1; } ;;
    8.2) [ "$patch" -lt "$FIXED_82" ] && { red "P0 · PHP $v is below fixed 8.2.$FIXED_82"; return 1; } ;;
    8.1|8.0|7.4) ylw "P0? · PHP $mm has no official fixed release; needs a vendor-fixed build or the published backport, or an upgrade"; return 1 ;;
    7.*|5.*|4.*) red "P0 · PHP $mm is end-of-life with no fix from the project — migrate or isolate"; return 1 ;;
    *) ylw "?  · unrecognised branch '$mm' — check the current advisory" ;;
  esac
  grn "ok · PHP $v is at or above the listed fixed level for its branch (still verify distro/runtime)"
  return 0
}

printf '\033[1m Devleck · PHP Inventory & Risk Scan \033[0m\n %s\n' "$(pwd)"

# ── 1. Declared versions ──────────────────────────────────────────────────────
sec "1 · DECLARED PHP VERSIONS (what the repo says — not necessarily what runs)"
FOUND=0
[ -f composer.json ] && { grep -E '"php"\s*:' composer.json | sed 's/^/  composer.json: /'; FOUND=1; }
for f in .php-version .tool-versions runtime.txt; do [ -f "$f" ] && { grep -iE 'php' "$f" | sed "s|^|  $f: |"; FOUND=1; }; done
DK=$(find . -maxdepth 4 \( -name 'Dockerfile*' -o -name 'docker-compose*.y*ml' -o -name '*.dockerfile' \) -not -path './node_modules/*' -not -path './vendor/*' 2>/dev/null)
for f in $DK; do
  grep -iE '^\s*(FROM|image:).*php|serversideup|wordpress|laravel' "$f" 2>/dev/null | sed "s|^|  $f: |" | head -4 && FOUND=1
done
grep -rEn 'php-version|setup-php|php_version|phpVersion|NIXPACKS_PHP|PHP_VERSION' .github railway.json railway.toml nixpacks.toml .gitlab-ci.yml 2>/dev/null | cut -c1-140 | sed 's/^/  /' | head -8
[ "$FOUND" -eq 0 ] && ylw "no PHP version declarations found (not a PHP project, or declared elsewhere)"
ylw "Floating tags (php:8.3-apache) hide the real build — resolve the digest you deploy."
# Floating tag / mod_php
if [ -n "$DK" ] && grep -qiE 'FROM[[:space:]]+php:[0-9.]+-apache' $DK 2>/dev/null; then
  ylw "!  *-apache images run mod_php — the SAPI reported at highest risk. Prefer php-fpm + nginx."; hit
fi
grep -rqiE 'LoadModule[[:space:]]+php|php_admin_value|php_value' . "${EXCL[@]}" --include='*.conf' --include='.htaccess' 2>/dev/null \
  && ylw "!  Apache PHP-module directives found — mod_php may be in use."

# ── 2. The php binary on PATH ─────────────────────────────────────────────────
sec "2 · php BINARY ON PATH (CLI — may differ from the web-serving runtime)"
if command -v php >/dev/null 2>&1; then
  V="$(php -r 'echo PHP_VERSION;' 2>/dev/null)"
  echo "  version: $V   sapi: $(php -r 'echo PHP_SAPI;' 2>/dev/null)"
  assess "$V" || hit
  echo
  for k in session.upload_progress.enabled memory_limit display_errors expose_php allow_url_include allow_url_fopen file_uploads post_max_size upload_max_filesize max_file_uploads disable_functions open_basedir session.use_strict_mode session.cookie_httponly session.cookie_secure; do
    printf '  %-34s %s\n' "$k" "$(php -r "echo ini_get('$k') === false ? '(unset)' : (ini_get('$k') === '' ? '(empty)' : ini_get('$k'));" 2>/dev/null)"
  done
  ylw "These are CLI values. Read the web SAPI's values from a request-time context you control."
  [ "$(php -r "echo ini_get('display_errors');" 2>/dev/null)" = "1" ] && { ylw "!  display_errors is on (fine for dev, a finding in production)"; }
  [ "$(php -r "echo ini_get('session.upload_progress.enabled');" 2>/dev/null)" = "1" ] && ylw "!  session.upload_progress.enabled=1 — documented interim mitigation target (patch is the real fix)"
else
  ylw "no php binary on PATH — version not assessed (check the running container/host instead)"
fi

# ── 3. Code patterns ──────────────────────────────────────────────────────────
sec "3 · PHP RISK PATTERNS  (review each — many are legitimate)"
pscan() { # <label> <regex> [severity]
  local out
  out=$(grep -rEn "$2" . "${EXCL[@]}" --include='*.php' --include='*.phtml' --include='*.inc' 2>/dev/null | head -5)
  [ -n "$out" ] && { ylw "!  $1"; echo "$out" | cut -c1-160 | sed 's/^/     /'; }
}
pscan "unserialize() — deserialization of possibly untrusted data" 'unserialize[[:space:]]*\('
pscan "include/require with a variable path"                       '(include|require)(_once)?[[:space:]]*\(?[[:space:]]*\$'
pscan "eval / assert-with-string / create_function"                '\b(eval|create_function)[[:space:]]*\(|assert[[:space:]]*\([[:space:]]*\$'
pscan "command execution functions"                                '\b(exec|shell_exec|system|passthru|popen|proc_open|pcntl_exec)[[:space:]]*\('
pscan "phpinfo() present"                                          '\bphpinfo[[:space:]]*\('
pscan "request data in file functions"                             '(file_get_contents|readfile|fopen|file|unlink|copy)[[:space:]]*\([[:space:]]*\$_(GET|POST|REQUEST|COOKIE)'
pscan "extract() on request data / variable-variables"             'extract[[:space:]]*\([[:space:]]*\$_(GET|POST|REQUEST)|\$\$[A-Za-z_]'
pscan "string-built SQL"                                           '(mysqli_query|->query|->exec|DB::select|whereRaw|DB::raw)[[:space:]]*\([^)]*(\$_(GET|POST|REQUEST)|"[^"]*\$[A-Za-z_]|\.[[:space:]]*\$)'
pscan "weak hashing of secrets"                                    '\b(md5|sha1)[[:space:]]*\([^)]*(pass|pwd|secret|token)'
pscan "non-crypto randomness for tokens"                           '\b(rand|mt_rand|uniqid|lcg_value)[[:space:]]*\([^)]*\)[^;]*(token|secret|key|nonce|otp|password)'
pscan "loose comparison on secrets/tokens"                         '(token|secret|hash|password)[A-Za-z_]*[[:space:]]*==[^=]'
pscan "TLS verification disabled"                                  'CURLOPT_SSL_VERIFY(PEER|HOST)[[:space:]]*,[[:space:]]*(0|false)|verify_peer[[:space:]]*.*false'
pscan "unvalidated redirect"                                       'header[[:space:]]*\([[:space:]]*["'"'"']Location:[^)]*\$_(GET|POST|REQUEST)'
pscan "uploaded file moved with client-controlled name"            'move_uploaded_file[[:space:]]*\([^,]+,[^)]*(\$_FILES\[[^]]+\]\[.name.\]|basename[[:space:]]*\(\$_FILES)'

# ── 4. Configuration files and exposure ───────────────────────────────────────
sec "4 · CONFIGURATION"
[ -f .env ] && git ls-files --error-unmatch .env >/dev/null 2>&1 && { red "P0 · .env is tracked in git"; hit; }
grep -rqE 'APP_DEBUG[[:space:]]*=[[:space:]]*true' .env.production .env.prod 2>/dev/null && { red "P0 · APP_DEBUG=true in a production env file"; hit; }
[ -f composer.json ] && [ ! -f composer.lock ] && { ylw "!  composer.json without composer.lock — builds are not reproducible"; }
[ -d vendor ] && git ls-files vendor 2>/dev/null | head -1 | grep -q . && ylw "!  vendor/ is tracked in git"
for p in phpinfo.php info.php test.php adminer.php; do [ -f "$p" ] || [ -f "public/$p" ] && { red "P1 · $p present in the tree (dev/diagnostic script)"; hit; }; done
if [ -f wp-config.php ] || [ -f public/wp-config.php ] || [ -d wp-content ]; then
  ylw "!  WordPress detected — confirm DISALLOW_FILE_EDIT, plugin hygiene and no inactive plugins (references/php-ecosystem.md)"
fi
ylw "Run 'composer audit' yourself — it contacts the package index, so this script does not."

# ── Summary ───────────────────────────────────────────────────────────────────
printf '\n\033[2m%s\033[0m\n' "────────────────────────────────────────────"
if [ "$FINDINGS" -gt 0 ]; then
  red "$FINDINGS high-severity item(s). Confirm each; patching is the only complete fix"
  red "for the runtime flaws. If exposed and unpatched, assume compromise: rotate and hunt."
  exit 1
fi
grn "No high-severity PHP items matched."
printf '\033[2mThis is triage, not assurance. Verify the SERVING runtime, and run composer audit.\033[0m\n'
exit 0
