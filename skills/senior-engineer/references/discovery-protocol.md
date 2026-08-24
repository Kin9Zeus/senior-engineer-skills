# Discovery Protocol

Reconnaissance before recommendation. Run the generic pass, then the pass for
the stack you detected. Record everything in a Ground Truth block. Anything you
cannot determine is written `UNKNOWN`, never inferred.

Read-only commands only during discovery. Never install dependencies, run
migrations, or start services without asking.

---

## Pass 0 — Shape of the repository

```bash
# Size and language mix
git ls-files | wc -l
git ls-files | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20

# History health
git log --oneline -15
git log --format='%an' | sort | uniq -c | sort -rn | head        # bus factor
git log -1 --format=%cd                                          # is it alive?
git branch -a | head -30

# What is deliberately hidden
cat .gitignore 2>/dev/null
git count-objects -vH | grep size-pack                            # repo weight
```

**Read next, in this order, if present:** `README*`, `CONTRIBUTING*`, `CLAUDE.md`,
`AGENTS.md`, `docs/`, `.env.example`, `Makefile`/`Taskfile`, `docker-compose*.yml`.
These four minutes tell you more than an hour of file browsing.

**Immediate red flags at this stage**
- No lockfile next to a manifest -> non-reproducible builds.
- `.env` tracked in git -> assume every secret in it is compromised.
- Last commit older than 12 months on a "live" product -> unpatched dependencies.
- One author with 95%+ of commits -> bus factor 1, document accordingly.
- A `node_modules/`, `vendor/`, or `dist/` directory committed -> tooling is broken.

---

## Pass 1 — Stack detection

Detect by manifest file, not by asking:

| File present | Stack | Then read |
|---|---|---|
| `package.json` | Node / JS / TS | `engines`, `scripts`, dep count, lockfile type |
| `next.config.*` | Next.js | app vs pages router, `middleware.ts`, route handlers |
| `nuxt.config.*` / `vite.config.*` | Vue / Vite | SSR mode, adapter |
| `requirements.txt` / `pyproject.toml` | Python | pinning style, `django`/`fastapi`/`flask` |
| `go.mod` | Go | module path, Go version, `internal/` layout |
| `Cargo.toml` | Rust | edition, feature flags, unsafe blocks |
| `composer.json` | PHP | Laravel/Symfony, PHP constraint |
| `Gemfile` | Ruby | Rails version, `config/` |
| `pom.xml` / `build.gradle*` | Java / Kotlin | Spring Boot version, modules |
| `*.csproj` / `*.sln` | .NET | target framework, nullable enabled |
| `pubspec.yaml` | Dart / Flutter | SDK constraint, platforms |
| `Package.swift` / `*.xcodeproj` | Swift / iOS | deployment target |

Then the runtime layer:

```bash
ls -a | grep -Ei 'docker|compose|Procfile|vercel|netlify|fly|railway|render|serverless|k8s|helm|terraform|pulumi|ansible'
ls .github/workflows .gitlab-ci.yml .circleci Jenkinsfile 2>/dev/null
```

---

## Pass 2 — The state layer

State is where irreversible damage lives. Map it explicitly.

```bash
# Migrations: how many, how recent, are they reversible?
find . -type d \( -name migrations -o -name migrate -o -name db \) -not -path '*/node_modules/*' | head
ls -1 <migrations-dir> | wc -l
ls -1 <migrations-dir> | tail -5

# Schema definition
find . -name 'schema.prisma' -o -name 'schema.rb' -o -name '*.sql' -not -path '*/node_modules/*' | head -20

# Connection surface
grep -rEn 'DATABASE_URL|DB_HOST|MONGO_URI|REDIS_URL|connectionString' --include='*.env.example' --include='*.yml' --include='*.yaml' . | head
```

Answer these five, or mark `UNKNOWN`:
1. Which engine and version? (Postgres 14 and Postgres 16 are different products
   for your purposes.)
2. Where do backups go, on what schedule, and has a restore ever been tested?
3. Is there a rollback path for the last three migrations?
4. Is there any multi-tenancy, and is it enforced in the database or only in
   application code?
5. Which tables hold personal data? (Feed this straight into `privacy-compliance`.)

---

## Pass 3 — The exposed surface

Everything reachable from the internet is attack surface.

```bash
# Route inventory (adjust per framework)
find . -path '*/routes/*' -o -path '*/api/*' -o -name 'urls.py' -o -name '*.controller.*' | grep -v node_modules | head -40

# Uploads, webhooks, redirects, raw HTML — the four usual wounds
grep -rEn 'multer|formidable|upload|createWriteStream' --include='*.{js,ts,py,go,rb,php}' . | grep -v node_modules | head
grep -rEn 'webhook|/hooks/' --include='*.{js,ts,py,go,rb,php}' . | grep -v node_modules | head
grep -rEn 'redirect\(|res\.redirect|RedirectResponse' --include='*.{js,ts,py,go,rb,php}' . | grep -v node_modules | head
grep -rEn 'dangerouslySetInnerHTML|v-html|innerHTML\s*=|\|safe|render_template_string' . | grep -v node_modules | head
```

For each public route ask: **who may call this, and who may call it *for this
specific object*?** Route-level auth that lets user A pass `?id=B` is the single
most common critical finding in real audits (IDOR / broken object-level
authorization).

---

## Pass 4 — Secrets and configuration

```bash
# Tracked secrets — check history, not just the working tree
git log --all --full-history --name-only -- '*.env' '*.pem' '*.key' '*.p12' '*credentials*' | head -30

# High-signal literal patterns
grep -rEn '(sk_live|pk_live|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|xox[baprs]-|-----BEGIN [A-Z ]*PRIVATE KEY-----|AIza[0-9A-Za-z_-]{35})' . --exclude-dir={node_modules,.git,dist,build,vendor} | head -30

# Config that is validated at boot vs read ad hoc everywhere
grep -rn 'process\.env\.\|os\.environ\|getenv(' --exclude-dir={node_modules,.git} . | wc -l
```

A high `process.env` count scattered across the codebase (rather than one
validated config module) is a reliability finding, not just a style one: it
means the app can boot in a half-configured state and fail at 3am instead of at
startup.

Anything found in git history is compromised even if deleted later. The fix is
always **rotate the credential first**, then purge the history. Never the other
way round.

---

## Pass 5 — Quality signals

```bash
# Tests: do they exist, do they run, do they mean anything?
find . -type d \( -name test -o -name tests -o -name __tests__ -o -name spec \) -not -path '*/node_modules/*' | head
grep -rEc 'it\(|test\(|def test_|func Test' --include='*.{js,ts,tsx,py,go,rb}' . 2>/dev/null | grep -v ':0' | wc -l

# Static analysis and types
ls .eslintrc* eslint.config.* tsconfig.json .ruff.toml mypy.ini .golangci.yml 2>/dev/null
grep -n '"strict"' tsconfig.json 2>/dev/null

# Debt markers, weighted by where they are
grep -rn 'TODO\|FIXME\|HACK\|XXX' --exclude-dir={node_modules,.git} . | wc -l
grep -rn 'TODO\|FIXME\|HACK' --include='*auth*' --include='*payment*' --include='*billing*' . | head
```

A `TODO` in a stylesheet is noise. A `FIXME` in the authorization middleware is a
P0 finding. Weight by location, never by count.

---

## Pass 6 — The public promise

If the project has a public site, what it *claims* is part of the audit surface.

```bash
find . -iname '*privacy*' -o -iname '*terms*' -o -iname '*cookie*' -o -iname 'robots.txt' -o -iname 'sitemap*' | grep -v node_modules
```

- Does the privacy policy list the third parties actually present in the code?
  (Cross-check against every SDK, analytics tag, font CDN and pixel you found.)
- Does the cookie banner gate scripts, or does it merely apologise after they
  have already loaded and set cookies?
- Is there a real, reachable deletion path, or only a promise to email someone?

Hand all three to `privacy-compliance`.

---

## Ground Truth output shape

```markdown
## Ground Truth

**Project**   <name> — <one line on what it does>
**Stack**     <language/framework/versions>
**Runtime**   <where it deploys, how>
**State**     <databases, caches, queues, blob storage>
**Surface**   <n public routes, n webhooks, uploads: y/n, third parties: ...>
**Auth**      <model, roles, tenancy enforcement point>
**Tests**     <count, layers present, CI gate: y/n>
**Personal data** <tables/fields holding PII>
**Scale**     <requests, rows, users — or UNKNOWN>

**Could not determine:** <explicit list>
```

Ask for what is missing only when it changes your recommendation. Otherwise
state the assumption and continue — a blocked question is not an excuse for an
undelivered audit.
