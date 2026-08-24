#!/usr/bin/env bash
# Devleck Senior Engineer Skills — read-only secret and risk-pattern scan.
#
# Scans the working tree and git history for credential-shaped strings and
# high-risk code patterns. Makes no network calls and modifies nothing.
#
# This is a triage aid, not a scanner. It finds obvious leaks fast; it does not
# find everything, and it produces false positives. Confirm every hit by reading
# the file. For continuous coverage use a dedicated tool (gitleaks, trufflehog,
# or your host's native secret scanning).
#
# Usage:  ./secret-scan.sh [path]
# Exit:   0 clean · 1 findings · 2 usage error

set -uo pipefail
ROOT="${1:-.}"
cd "$ROOT" 2>/dev/null || { echo "secret-scan: cannot enter '$ROOT'" >&2; exit 2; }

EX='node_modules|\.git/|dist/|build/|vendor/|\.next/|target/|__pycache__|\.venv|venv/|coverage/|\.min\.js|package-lock\.json|yarn\.lock|pnpm-lock\.yaml'
FINDINGS=0

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[33m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
sec()  { printf '\n\033[1m%s\033[0m\n\033[2m%s\033[0m\n' "$1" "────────────────────────────────────────────"; }
hit()  { FINDINGS=$((FINDINGS+1)); }

printf '\033[1m Devleck · Secret & Risk Pattern Scan \033[0m\n %s\n' "$(pwd)"

# ── 1. Tracked environment and key files ──────────────────────────────────────
sec "1 · TRACKED SECRET FILES"
if [ -d .git ] && command -v git >/dev/null 2>&1; then
  T=$(git ls-files 2>/dev/null | grep -E '(^|/)(\.env($|\.)|.*\.pem$|.*\.key$|.*\.p12$|.*\.pfx$|.*\.jks$|id_rsa|id_ed25519|.*service-account.*\.json)' | grep -viE 'example|sample|template|\.d\.ts' )
  if [ -n "$T" ]; then red "P0 · secret-shaped files tracked in git:"; echo "$T" | sed 's/^/     /'; hit
  else grn "ok · no secret-shaped files tracked"; fi
else
  ylw "-- not a git repository; skipping tracked-file check"
fi

# ── 2. Git history ────────────────────────────────────────────────────────────
sec "2 · GIT HISTORY"
if [ -d .git ] && command -v git >/dev/null 2>&1; then
  H=$(git log --all --full-history --name-only --pretty=format: \
        -- '*.env' '*.env.*' '*.pem' '*.key' '*.p12' '*.pfx' '*id_rsa*' '*credentials*' 2>/dev/null \
      | grep -v '^$' | grep -viE 'example|sample|template' | sort -u)
  if [ -n "$H" ]; then
    red "P0 · secret-shaped files exist in history (present in every clone):"
    echo "$H" | sed 's/^/     /'
    ylw "     Remediation order: 1) ROTATE the credential  2) check provider audit"
    ylw "     logs for abuse  3) purge history (git filter-repo / BFG)  4) enable"
    ylw "     secret scanning. Purging without rotating leaves the key live."
    hit
  else grn "ok · no secret-shaped files in history"; fi
fi

# ── 3. Credential patterns in the working tree ────────────────────────────────
sec "3 · CREDENTIAL PATTERNS IN SOURCE"
scan() { # <label> <regex>
  local out
  out=$(grep -rEn "$2" . --exclude-dir={node_modules,.git,dist,build,vendor,.next,target,coverage} 2>/dev/null \
        | grep -Ev "$EX" | grep -viE 'example|sample|placeholder|your[-_]|xxx|<.*>|dummy|fake|test_key' | head -5)
  if [ -n "$out" ]; then red "P0 · $1"; echo "$out" | cut -c1-160 | sed 's/^/     /'; hit; fi
}
scan "AWS access key id"           'AKIA[0-9A-Z]{16}'
scan "Stripe live secret key"      'sk_live_[0-9a-zA-Z]{16,}'
scan "Stripe restricted key"       'rk_live_[0-9a-zA-Z]{16,}'
scan "GitHub token"                '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}'
scan "Google API key"              'AIza[0-9A-Za-z_-]{35}'
scan "Slack token"                 'xox[baprs]-[0-9A-Za-z-]{10,}'
scan "Slack webhook"               'hooks\.slack\.com/services/T[A-Za-z0-9]+/B[A-Za-z0-9]+/'
scan "Private key block"           '-----BEGIN [A-Z ]*PRIVATE KEY-----'
scan "SendGrid key"                'SG\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'
scan "Twilio account SID"          'AC[a-f0-9]{32}'
scan "OpenAI / Anthropic key"      '(sk-proj-[A-Za-z0-9_-]{20,}|sk-ant-[A-Za-z0-9_-]{20,})'
scan "npm token"                   'npm_[A-Za-z0-9]{36}'
scan "JWT with payload"            'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.'
scan "Connection string w/ password" '(postgres(ql)?|mysql|mongodb(\+srv)?|redis|amqp)://[^:/@\s]+:[^@/\s]{6,}@'
scan "Hardcoded password assignment" '(password|passwd|pwd|secret|api_?key|token)\s*[:=]\s*["'"'"'][^"'"'"'$\{]{10,}["'"'"']'

[ "$FINDINGS" -eq 0 ] && grn "ok · no credential patterns matched"

# ── 4. Client-bundle exposure ─────────────────────────────────────────────────
sec "4 · CLIENT-BUNDLE EXPOSURE"
PUB=$(grep -rEn '(NEXT_PUBLIC|VITE|REACT_APP|PUBLIC|NUXT_PUBLIC|EXPO_PUBLIC)_[A-Z0-9_]*(SECRET|PRIVATE|KEY|TOKEN|PASSWORD|CREDENTIAL)' \
      . --exclude-dir={node_modules,.git,dist,build,.next} 2>/dev/null | head -8)
if [ -n "$PUB" ]; then
  red "P0 · secret-sounding variable with a PUBLIC prefix — this is compiled into"
  red "     the browser bundle and is readable by anyone:"
  echo "$PUB" | cut -c1-160 | sed 's/^/     /'; hit
else grn "ok · no secret-named public-prefixed variables"; fi

for d in dist build .next/static out public; do
  [ -d "$d" ] || continue
  B=$(grep -rEl 'sk_live_[0-9a-zA-Z]{16,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----' "$d" 2>/dev/null | head -3)
  [ -n "$B" ] && { red "P0 · live-key pattern inside built output ($d):"; echo "$B" | sed 's/^/     /'; hit; }
done

# ── 5. Injection sinks ────────────────────────────────────────────────────────
sec "5 · INJECTION SINKS  (review each — many are legitimate)"
warn_scan() { # <label> <regex>
  local out
  out=$(grep -rEn "$2" . --exclude-dir={node_modules,.git,dist,build,vendor,.next,target} 2>/dev/null | grep -Ev "$EX" | head -5)
  [ -n "$out" ] && { ylw "!  $1"; echo "$out" | cut -c1-160 | sed 's/^/     /'; }
}
warn_scan "String-built SQL"        "(query|execute|exec|raw|prepare)[[:space:]]*\([[:space:]]*[\"\`'][^\"\`']*(\\\$\{|\" *\+|%s|f[\"'])"
warn_scan "ORM raw escape hatches"  '\.(raw|extra)\(|whereRaw|FromSqlRaw|\$queryRawUnsafe|sequelize\.query\('
warn_scan "Shell execution"         '(child_process|execSync|exec\(|spawn\(|os\.system|subprocess\.(call|run|Popen)|shell_exec|passthru|`.*\$\{)'
warn_scan "Dynamic code evaluation" '\beval\(|new Function\(|setTimeout\([^,]*["'"'"']|pickle\.loads|yaml\.load\((?!.*Loader)'
warn_scan "Raw HTML sinks"          'dangerouslySetInnerHTML|v-html|\.innerHTML[[:space:]]*=|document\.write|html_safe|\braw\(|\|[[:space:]]*safe'
warn_scan "Deserialization"         'pickle\.load|yaml\.unsafe_load|ObjectInputStream|unserialize\(|Marshal\.load'
warn_scan "Server-side fetch of input URL (SSRF)" '(fetch|axios|requests\.(get|post)|http\.(get|request)|urlopen|curl_exec)\([^)]*(req\.|request\.|params|query|body)'

# ── 6. Configuration weaknesses ───────────────────────────────────────────────
sec "6 · CONFIGURATION"
warn_scan "Debug enabled"           '(DEBUG|debug)[[:space:]]*[:=][[:space:]]*(True|true|1)\b'
warn_scan "TLS verification disabled" 'rejectUnauthorized[[:space:]]*:[[:space:]]*false|verify[[:space:]]*=[[:space:]]*False|InsecureSkipVerify[[:space:]]*:[[:space:]]*true|CURLOPT_SSL_VERIFYPEER[[:space:]]*,[[:space:]]*(0|false)'
warn_scan "Permissive CORS"         'Access-Control-Allow-Origin[^,)]*\*|origin[[:space:]]*:[[:space:]]*(true|"\*")'
warn_scan "Weak hashing on secrets" '(md5|sha1)\((.*(pass|pwd|secret|token))'
warn_scan "Non-crypto randomness for tokens" '(Math\.random|random\.random)\(\)[^;]*(token|secret|key|otp|nonce|password)'

# ── 7. Ignore-file hygiene ────────────────────────────────────────────────────
sec "7 · IGNORE FILES"
if [ -f .gitignore ]; then
  for p in '.env' '*.pem' '*.key'; do
    grep -qF -- "$p" .gitignore || ylw "!  .gitignore does not cover  $p"
  done
  grep -qF -- '.env' .gitignore && grn "ok · .gitignore covers .env"
else
  red "P0 · no .gitignore at the repository root"; hit
fi

# ── Summary ───────────────────────────────────────────────────────────────────
printf '\n\033[2m%s\033[0m\n' "────────────────────────────────────────────"
if [ "$FINDINGS" -gt 0 ]; then
  red "$FINDINGS high-severity pattern group(s) matched."
  ylw "Confirm each by reading the file. If a real credential is exposed:"
  ylw "ROTATE IT FIRST, then check for abuse, then purge the history."
  exit 1
else
  grn "No high-severity patterns matched."
  printf '\033[2mThis is triage, not assurance. Run a dedicated scanner (gitleaks,\ntrufflehog, or your host'"'"'s native secret scanning) for real coverage.\033[0m\n'
  exit 0
fi
