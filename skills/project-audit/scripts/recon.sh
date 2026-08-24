#!/usr/bin/env bash
# Devleck Senior Engineer Skills — read-only project reconnaissance.
#
# Prints a structured Ground Truth summary. Makes no network calls, installs
# nothing, writes nothing outside stdout, and modifies no file.
#
# Usage:  ./recon.sh [path]           (defaults to the current directory)

set -uo pipefail
ROOT="${1:-.}"
cd "$ROOT" 2>/dev/null || { echo "recon: cannot enter '$ROOT'" >&2; exit 1; }

EXCLUDES='node_modules|\.git/|dist/|build/|vendor/|\.next/|target/|__pycache__|\.venv|venv/|coverage/'
have() { command -v "$1" >/dev/null 2>&1; }
hr()   { printf '\n\033[2m%s\033[0m\n' "────────────────────────────────────────────────────────"; }
sec()  { hr; printf '\033[1m%s\033[0m\n' "$1"; }

printf '\033[1m Devleck · Project Reconnaissance \033[0m\n'
printf ' %s\n' "$(pwd)"
printf ' %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# ── Repository ────────────────────────────────────────────────────────────────
sec "REPOSITORY"
if [ -d .git ] && have git; then
  echo "branch          : $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  echo "commit          : $(git rev-parse --short HEAD 2>/dev/null)"
  echo "last commit     : $(git log -1 --format=%cd --date=short 2>/dev/null)"
  echo "commits         : $(git rev-list --count HEAD 2>/dev/null)"
  echo "tracked files   : $(git ls-files | wc -l | tr -d ' ')"
  echo "contributors    :"
  git log --format='%an' 2>/dev/null | sort | uniq -c | sort -rn | head -5 | sed 's/^/                  /'
  echo "uncommitted     : $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') file(s)"
else
  echo "not a git repository (or git unavailable)"
fi

# ── Languages ─────────────────────────────────────────────────────────────────
sec "LANGUAGE MIX (top 12 tracked extensions)"
if [ -d .git ] && have git; then
  git ls-files | grep -E '\.[a-zA-Z0-9]+$' | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -12
else
  find . -type f -name '*.*' 2>/dev/null | grep -Ev "$EXCLUDES" | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -12
fi

# ── Stack ─────────────────────────────────────────────────────────────────────
sec "STACK DETECTED"
detect() { [ -e "$1" ] && printf '  %-22s %s\n' "$1" "$2"; }
detect package.json          "Node / JavaScript / TypeScript"
detect next.config.js        "Next.js";  detect next.config.mjs "Next.js";  detect next.config.ts "Next.js"
detect nuxt.config.ts        "Nuxt";     detect vite.config.ts  "Vite";     detect vite.config.js "Vite"
detect angular.json          "Angular";  detect svelte.config.js "Svelte"
detect requirements.txt      "Python";   detect pyproject.toml  "Python"
detect manage.py             "Django"
detect go.mod                "Go"
detect Cargo.toml            "Rust"
detect composer.json         "PHP";      detect artisan          "Laravel"
detect Gemfile               "Ruby";     detect config/application.rb "Rails"
detect pom.xml               "Java / Maven"; detect build.gradle "Java / Gradle"; detect build.gradle.kts "Kotlin / Gradle"
detect pubspec.yaml          "Dart / Flutter"
detect Package.swift         "Swift"
detect mix.exs               "Elixir"
ls *.csproj *.sln >/dev/null 2>&1 && printf '  %-22s %s\n' "*.csproj/*.sln" ".NET"

echo
echo "  lockfiles:"
for f in package-lock.json yarn.lock pnpm-lock.yaml bun.lockb poetry.lock Pipfile.lock uv.lock go.sum Cargo.lock Gemfile.lock composer.lock; do
  [ -e "$f" ] && printf '    ✓ %s\n' "$f"
done
[ -e package.json ] && [ ! -e package-lock.json ] && [ ! -e yarn.lock ] && [ ! -e pnpm-lock.yaml ] && [ ! -e bun.lockb ] \
  && printf '    \033[33m! package.json with NO lockfile — builds are not reproducible\033[0m\n'

if [ -e package.json ] && have node; then
  echo
  node -e 'try{const p=require("./package.json");console.log("  name        :",p.name||"-");console.log("  version     :",p.version||"-");console.log("  node engine :",(p.engines&&p.engines.node)||"UNPINNED");console.log("  deps        :",Object.keys(p.dependencies||{}).length,"prod /",Object.keys(p.devDependencies||{}).length,"dev");console.log("  scripts     :",Object.keys(p.scripts||{}).join(", ")||"-");}catch(e){}' 2>/dev/null
fi

# ── Delivery ──────────────────────────────────────────────────────────────────
sec "BUILD / DEPLOY / INFRA"
found=0
for f in .github/workflows .gitlab-ci.yml .circleci Jenkinsfile azure-pipelines.yml bitbucket-pipelines.yml \
         Dockerfile docker-compose.yml docker-compose.yaml Procfile \
         vercel.json netlify.toml fly.toml render.yaml app.yaml serverless.yml \
         Makefile Taskfile.yml justfile; do
  [ -e "$f" ] && { printf '  ✓ %s\n' "$f"; found=1; }
done
for d in terraform infra infrastructure k8s kubernetes helm charts ansible pulumi .devcontainer; do
  [ -d "$d" ] && { printf '  ✓ %s/\n' "$d"; found=1; }
done
[ -d .github/workflows ] && { echo "  workflows:"; ls .github/workflows 2>/dev/null | sed 's/^/    /'; }
[ "$found" -eq 0 ] && printf '  \033[33m! no CI, container or IaC configuration found — deploys are likely manual\033[0m\n'

# ── State ─────────────────────────────────────────────────────────────────────
sec "STATE LAYER"
for f in prisma/schema.prisma schema.sql db/schema.rb drizzle.config.ts knexfile.js alembic.ini; do
  [ -e "$f" ] && printf '  ✓ %s\n' "$f"
done
MIGDIRS=$(find . -maxdepth 4 -type d \( -name migrations -o -name migrate -o -name migration \) 2>/dev/null | grep -Ev "$EXCLUDES" | head -5)
if [ -n "$MIGDIRS" ]; then
  echo "$MIGDIRS" | while read -r d; do
    n=$(ls -1 "$d" 2>/dev/null | wc -l | tr -d ' ')
    printf '  ✓ %-40s %s file(s)\n' "$d" "$n"
  done
else
  printf '  \033[33m! no migrations directory found\033[0m\n'
fi
echo "  engines referenced in config/examples:"
grep -rhoiE 'postgres(ql)?|mysql|mariadb|sqlite|mongodb|redis|dynamodb|clickhouse|cassandra|elasticsearch|rabbitmq|kafka' \
  --include='*.env.example' --include='*.yml' --include='*.yaml' --include='*.toml' --include='*.json' \
  . 2>/dev/null | grep -Ev "$EXCLUDES" | tr 'A-Z' 'a-z' | sort -u | sed 's/^/    /' | head -12

# ── Tests ─────────────────────────────────────────────────────────────────────
sec "TESTS"
TD=$(find . -maxdepth 4 -type d \( -name test -o -name tests -o -name __tests__ -o -name spec -o -name e2e \) 2>/dev/null | grep -Ev "$EXCLUDES" | head -8)
[ -n "$TD" ] && echo "$TD" | sed 's/^/  ✓ /' || printf '  \033[33m! no test directory found\033[0m\n'
TF=$(grep -rlE '\b(it|test|describe)\(|def test_|func Test[A-Z]|\[Test\]|@Test' . 2>/dev/null | grep -Ev "$EXCLUDES" | wc -l | tr -d ' ')
echo "  files containing tests : $TF"
for f in jest.config.js vitest.config.ts playwright.config.ts cypress.config.js pytest.ini tox.ini phpunit.xml .rspec; do
  [ -e "$f" ] && printf '  ✓ %s\n' "$f"
done
if [ -d .github/workflows ]; then
  grep -rlE '(npm|yarn|pnpm) (run )?test|pytest|go test|cargo test|mvn test|phpunit|rspec' .github/workflows >/dev/null 2>&1 \
    && echo "  CI runs tests          : yes" \
    || printf '  \033[33m  CI runs tests          : NOT DETECTED\033[0m\n'
fi

# ── Quality gates ─────────────────────────────────────────────────────────────
sec "QUALITY GATES"
for f in tsconfig.json .eslintrc .eslintrc.js .eslintrc.json eslint.config.js eslint.config.mjs \
         .prettierrc biome.json ruff.toml .ruff.toml mypy.ini .golangci.yml .golangci.yaml \
         .editorconfig .pre-commit-config.yaml lefthook.yml .husky sonar-project.properties; do
  [ -e "$f" ] && printf '  ✓ %s\n' "$f"
done
if [ -e tsconfig.json ]; then
  grep -qE '"strict"[[:space:]]*:[[:space:]]*true' tsconfig.json \
    && echo "  TypeScript strict      : true" \
    || printf '  \033[33m  TypeScript strict      : FALSE or unset\033[0m\n'
fi

# ── Risk signals ──────────────────────────────────────────────────────────────
sec "RISK SIGNALS  (indicative only — every hit needs manual confirmation)"

TRACKED_ENV=$( { [ -d .git ] && git ls-files 2>/dev/null | grep -E '(^|/)\.env($|\.)' | grep -v example; } | head -5)
if [ -n "$TRACKED_ENV" ]; then
  printf '  \033[31m✗ P0  .env file(s) tracked in git:\033[0m\n'; echo "$TRACKED_ENV" | sed 's/^/        /'
else
  echo "  ✓ no .env tracked in the working tree"
fi

if [ -d .git ] && have git; then
  HIST=$(git log --all --full-history --name-only --pretty=format: -- '*.env' '*.pem' '*.key' '*.p12' '*.pfx' 2>/dev/null | grep -v '^$' | grep -v example | sort -u | head -5)
  [ -n "$HIST" ] && { printf '  \033[31m✗ P0  secret-shaped files in git HISTORY (rotate, then purge):\033[0m\n'; echo "$HIST" | sed 's/^/        /'; }
fi

KEYS=$(grep -rEl '(sk_live_[0-9a-zA-Z]{10,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[0-9A-Za-z-]{10,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----)' \
  . 2>/dev/null | grep -Ev "$EXCLUDES" | head -8)
[ -n "$KEYS" ] && { printf '  \033[31m✗ P0  live-key patterns found in:\033[0m\n'; echo "$KEYS" | sed 's/^/        /'; } \
                || echo "  ✓ no live-key patterns matched"

SQLI=$(grep -rEln "(query|execute|exec|raw|prepare)[[:space:]]*\([[:space:]]*[\"\`'][^\"\`']*(\\\$\{|\" *\+|%s|f[\"'])" \
  . 2>/dev/null | grep -Ev "$EXCLUDES" | head -8)
[ -n "$SQLI" ] && { printf '  \033[33m! string-built query candidates:\033[0m\n'; echo "$SQLI" | sed 's/^/        /'; }

XSS=$(grep -rEln 'dangerouslySetInnerHTML|v-html|\.innerHTML[[:space:]]*=|html_safe|\|[[:space:]]*safe' \
  . 2>/dev/null | grep -Ev "$EXCLUDES" | head -8)
[ -n "$XSS" ] && { printf '  \033[33m! raw-HTML sinks:\033[0m\n'; echo "$XSS" | sed 's/^/        /'; }

CMD=$(grep -rEln '(child_process|execSync|os\.system|subprocess\.(call|run|Popen)|shell_exec|`.*\$\{)' \
  . 2>/dev/null | grep -Ev "$EXCLUDES" | head -5)
[ -n "$CMD" ] && { printf '  \033[33m! command-execution sites:\033[0m\n'; echo "$CMD" | sed 's/^/        /'; }

echo
CRIT=$(grep -rn 'TODO\|FIXME\|HACK\|XXX' --include='*auth*' --include='*login*' --include='*payment*' \
  --include='*billing*' --include='*admin*' --include='*permission*' . 2>/dev/null | grep -Ev "$EXCLUDES" | wc -l | tr -d ' ')
ALL=$(grep -rn 'TODO\|FIXME\|HACK\|XXX' . 2>/dev/null | grep -Ev "$EXCLUDES" | wc -l | tr -d ' ')
echo "  debt markers           : $ALL total, $CRIT in auth/payment/admin paths"

# ── Third parties ─────────────────────────────────────────────────────────────
sec "THIRD PARTIES  (cross-check every one against the privacy policy)"
grep -rhoE 'googletagmanager\.com|google-analytics\.com|gtag\(|connect\.facebook\.net|static\.hotjar\.com|cdn\.segment\.com|api\.mixpanel\.com|posthog|widget\.intercom|clarity\.ms|sentry\.io|fonts\.googleapis\.com|js\.stripe\.com|paypal\.com/sdk|player\.vimeo|youtube\.com/embed|recaptcha' \
  . 2>/dev/null | grep -Ev "$EXCLUDES" | sort -u | sed 's/^/  · /' | head -20 \
  || echo "  none detected in source"

# ── Public promises ───────────────────────────────────────────────────────────
sec "PUBLIC PROMISES"
for pat in '*privacy*' '*terms*' '*cookie*' 'robots.txt' 'sitemap*' '*404*' '*llms.txt*' '*security.txt*'; do
  find . -maxdepth 5 -iname "$pat" 2>/dev/null | grep -Ev "$EXCLUDES" | head -3 | sed 's/^/  ✓ /'
done
find . -maxdepth 2 -iname 'README*' -o -maxdepth 2 -iname 'LICENSE*' -o -maxdepth 2 -iname 'CONTRIBUTING*' \
  -o -maxdepth 2 -iname 'SECURITY*' -o -maxdepth 2 -iname 'CHANGELOG*' 2>/dev/null | sed 's/^/  ✓ /' | head -8

hr
printf '\033[2mRead-only reconnaissance complete. Every flag above is a lead, not a finding —\nconfirm each by reading the code before it enters a report.\033[0m\n'
