#!/usr/bin/env bash
# Devleck Senior Engineer Skills — secret rotation inventory (names only).
#
# Lists the environment-variable NAMES a repository reads or defines, grouped by
# how sensitive the name sounds, so you can build a rotation worksheet fast after
# a provider breach or a leak. It NEVER prints a value, makes no network calls and
# modifies nothing.
#
# It cannot see secrets that live only in a provider dashboard, a CI variable
# store or a developer's shell — ask the user for those. Everything it lists is a
# lead for a worksheet, not a finding.
#
# Usage:  ./rotation-inventory.sh [path]
# Exit:   0 no secret-named variables found · 1 some found · 2 usage error

set -uo pipefail
ROOT="${1:-.}"
cd "$ROOT" 2>/dev/null || { echo "rotation-inventory: cannot enter '$ROOT'" >&2; exit 2; }

EXD='node_modules|\.git/|dist/|build/|vendor/|\.next/|target/|__pycache__|\.venv|venv/|coverage/'
SENS='(SECRET|PASSWORD|PASSWD|TOKEN|PRIVATE|CREDENTIAL|API_?KEY|ACCESS_?KEY|SIGNING|ENCRYPTION|SALT|DSN|WEBHOOK|CLIENT_SECRET|APP_KEY|MASTER_KEY|DATABASE_URL|REDIS_URL|MONGO(DB)?_URI|AMQP_URL|CONN(ECTION)?_?STRING)'

TMP="$(mktemp 2>/dev/null || echo /tmp/rotinv.$$)"
trap 'rm -f "$TMP"' EXIT

red() { printf '\033[31m%s\033[0m\n' "$*"; }
ylw() { printf '\033[33m%s\033[0m\n' "$*"; }
grn() { printf '\033[32m%s\033[0m\n' "$*"; }
sec() { printf '\n\033[1m%s\033[0m\n\033[2m%s\033[0m\n' "$1" "────────────────────────────────────────────"; }

printf '\033[1m Devleck · Rotation Inventory (names only) \033[0m\n %s\n' "$(pwd)"

# ── 1. Names DEFINED in env-style files (left side of KEY=value; value dropped) ─
find . -type f \( -name '.env' -o -name '.env.*' -o -name '*.env' -o -name 'docker-compose*.yml' -o -name 'docker-compose*.yaml' -o -name 'railway.json' -o -name 'railway.toml' -o -name 'app.json' -o -name 'fly.toml' -o -name 'render.yaml' -o -name 'vercel.json' \) \
  2>/dev/null | grep -Ev "$EXD" | while read -r f; do
    grep -oE '^[[:space:]]*(export[[:space:]]+)?[A-Z][A-Z0-9_]{2,}[[:space:]]*[=:]' "$f" 2>/dev/null \
      | sed -E 's/^[[:space:]]*(export[[:space:]]+)?//; s/[[:space:]]*[=:]$//' \
      | sed "s|\$|\t$f|"
  done >> "$TMP"

# ── 2. Names READ by code ─────────────────────────────────────────────────────
grep -rhoE 'process\.env\.[A-Z][A-Z0-9_]+|process\.env\[["'"'"'][A-Z][A-Z0-9_]+["'"'"']\]|os\.environ(\.get)?[\(\[]["'"'"'][A-Z][A-Z0-9_]+|os\.getenv\(["'"'"'][A-Z][A-Z0-9_]+|getenv\(["'"'"'][A-Z][A-Z0-9_]+|\$_ENV\[["'"'"'][A-Z][A-Z0-9_]+|\$_SERVER\[["'"'"'][A-Z][A-Z0-9_]+|env\(["'"'"'][A-Z][A-Z0-9_]+|ENV\[["'"'"'][A-Z][A-Z0-9_]+|System\.getenv\(["'"'"'][A-Z][A-Z0-9_]+|Environment\.GetEnvironmentVariable\(["'"'"'][A-Z][A-Z0-9_]+' \
  . --include='*.js' --include='*.ts' --include='*.tsx' --include='*.jsx' --include='*.mjs' --include='*.py' \
  --include='*.php' --include='*.rb' --include='*.go' --include='*.java' --include='*.cs' --include='*.rs' \
  --exclude-dir={node_modules,.git,dist,build,vendor,.next,target,coverage,__pycache__} 2>/dev/null \
  | grep -oE '[A-Z][A-Z0-9_]{2,}' | grep -vE '^(PROCESS|ENV|GETENV|SYSTEM|ENVIRONMENT|OS|SERVER|NODE_ENV)$' \
  | sed "s|\$|\t(read in code)|" >> "$TMP"

# ── 3. Secret-bearing names in CI workflows ───────────────────────────────────
if [ -d .github/workflows ]; then
  grep -rhoE 'secrets\.[A-Za-z0-9_]+' .github/workflows 2>/dev/null | sed 's/^secrets\.//' \
    | sed "s|\$|\t(GitHub Actions secret)|" >> "$TMP"
fi

if [ ! -s "$TMP" ]; then
  grn "No environment variable names found in this tree."
  ylw "That does not mean there are no secrets — check the provider dashboard and CI."
  exit 0
fi

sort -u "$TMP" > "$TMP.s" && mv "$TMP.s" "$TMP"

# ── Report ────────────────────────────────────────────────────────────────────
sec "HIGH SENSITIVITY — rotate (and prove the old value dead)"
HI=$(awk -F'\t' '{print $1}' "$TMP" | sort -u | grep -E "$SENS" || true)
if [ -n "$HI" ]; then
  echo "$HI" | while read -r n; do
    where=$(grep -E "^$n	" "$TMP" | cut -f2 | sort -u | head -3 | tr '\n' ' ')
    printf '  %-34s %s\n' "$n" "$where"
  done
else
  grn "none matched the sensitive-name pattern"
fi

sec "OTHER VARIABLES — review; a harmless-sounding name can hold a secret"
OTHER=$(awk -F'\t' '{print $1}' "$TMP" | sort -u | grep -Ev "$SENS" || true)
if [ -n "$OTHER" ]; then echo "$OTHER" | tr '\n' ' ' | fold -s -w 78 | sed 's/^/  /'; echo; else echo "  none"; fi

printf '\n\033[2m%s\033[0m\n' "────────────────────────────────────────────"
ylw "Names only. Not covered: provider dashboards, CI variable stores, laptops,"
ylw "preview/staging copies, secrets baked into images. Ask the user for those."
ylw "Next: templates/rotation-tracker.md — one row per name, ordered by blast radius."

[ -n "$HI" ] && exit 1 || exit 0
