# Day-One Scaffold Checklist

Everything here is cheap now and expensive later. Work top to bottom; each block
ends in something runnable.

---

## Block 1 — Repository hygiene

- [ ] `git init`, first commit before any dependency is installed
- [ ] `.gitignore` covering: environment files, build output, dependency
      directories, editor state, OS files, coverage, logs, local databases
- [ ] `.editorconfig` (indentation, charset, final newline, trailing whitespace)
- [ ] `README.md` — see `templates/readme-skeleton.md`
- [ ] `LICENSE`
- [ ] `.env.example` listing **every** key with a comment; no real values
- [ ] `CHANGELOG.md` if this will be released or consumed by others
- [ ] `SECURITY.md` with a disclosure address, if public
- [ ] Branch protection on the default branch: no direct pushes, review required,
      status checks required
- [ ] `CODEOWNERS` if more than one person will contribute

> **Verify:** `git status` is clean, and `git ls-files | grep -i env` returns
> only `.env.example`.

---

## Block 2 — Toolchain and quality gates

- [ ] Runtime version pinned in a file the tooling reads (`.nvmrc`,
      `.python-version`, `go.mod`, `.tool-versions`) **and** in the manifest's
      engines field
- [ ] Lockfile committed
- [ ] Formatter configured, with a single command to run it
- [ ] Linter configured, failing on real problems rather than style opinions
- [ ] **Strict type checking enabled from the first commit.** TypeScript
      `strict: true`, `mypy`/`pyright` strict, Go vet, nullable reference types
      in .NET. Turning strictness on later means fixing thousands of errors at
      once, which nobody ever does.
- [ ] Pre-commit hook running format and lint on staged files only (fast, or it
      gets bypassed)
- [ ] One script per verb: `dev`, `build`, `test`, `lint`, `typecheck`,
      `migrate`, `seed`

> **Verify:** a deliberate type error fails `typecheck`; a deliberate lint
> violation fails `lint`.

---

## Block 3 — Configuration and secrets

- [ ] **One config module.** All environment access happens there and nowhere
      else.
- [ ] Config parsed and **validated at boot** with a schema. Missing or malformed
      values crash the process at startup with a clear message naming the key.
- [ ] Typed config object exported; no `process.env` / `os.environ` anywhere else
      in the codebase (add a lint rule to enforce it)
- [ ] Secrets in the platform's secret manager for every deployed environment
- [ ] Distinct credentials per environment — staging must never hold production
      credentials
- [ ] A documented rotation procedure

> **Verify:** unset a required variable; the app refuses to start and names it.

---

## Block 4 — Data layer

- [ ] Database chosen, running locally via one command (Docker Compose or the
      platform's dev command)
- [ ] Migration tool wired; **migration 001 committed**
- [ ] Naming convention decided and written down (snake_case tables, plural or
      singular — pick one)
- [ ] Every table: primary key, `created_at`, `updated_at`
- [ ] Every foreign key: constraint **and** index, with an explicit `ON DELETE`
- [ ] `NOT NULL` and `CHECK` constraints expressing real invariants
- [ ] Money as integer minor units or decimal; timestamps `timestamptz` in UTC
- [ ] Tenancy column present from the first migration if the product is
      multi-tenant, with row-level security enabled
- [ ] **Personal-data columns tagged** in the schema documentation — this is the
      seed of the data inventory
- [ ] Seed script producing a realistic development dataset
- [ ] Connection pooling configured with sane limits
- [ ] Automated backups enabled the day the first real row is written

> **Verify:** migrate up, migrate down, migrate up again, on a clean database.

---

## Block 5 — Security baseline

- [ ] Auth wired end to end: register, login, logout, password reset, session
      invalidation on password change
- [ ] Password hashing with a memory-hard algorithm (argon2id / bcrypt with a
      current cost factor)
- [ ] **Authorization deny-by-default at the router.** Every route explicitly
      declares its policy; a route with no declaration fails closed. This single
      pattern prevents the most common critical vulnerability in shipped
      products.
- [ ] Object-level authorization helper (`can(user, action, resource)`) used by
      every handler that touches user-owned data
- [ ] Input validation at the boundary with one schema library, on body, query
      and params
- [ ] Security headers: HSTS, `X-Content-Type-Options`, `Referrer-Policy`,
      `X-Frame-Options` or `frame-ancestors`, `Permissions-Policy`
- [ ] **CSP without `unsafe-inline`**, using nonces or hashes. Start here; do not
      retrofit
- [ ] CSRF protection for cookie-authenticated state changes; `SameSite` set
- [ ] CORS allowlist, never origin reflection with credentials
- [ ] Rate limiting on login, registration, password reset, and all mutations
- [ ] Body size limits, upload type and size validation
- [ ] Dependency vulnerability scanning enabled in the repository
- [ ] Secret scanning enabled

> **Verify:** log in as user A, request user B's resource by id, confirm 403/404.
> Write this as a test now.

---

## Block 6 — The vertical slice

Build one complete feature, end to end. It is the template every future feature
copies.

- [ ] Route with declared authorization policy
- [ ] Request schema validation
- [ ] Object-level authorization check
- [ ] Business logic in a testable domain module, not in the handler
- [ ] Persistence through the data layer
- [ ] Typed response with a consistent error envelope
- [ ] Structured log line with correlation id
- [ ] Unit test for the business rule
- [ ] Integration test through the real database
- [ ] The authorization test from Block 5

> **Verify:** this slice passes in CI, and a second engineer could build feature
> two by copying its shape.

---

## Block 7 — CI/CD

- [ ] CI on every pull request: install (from lockfile), lint, typecheck, test,
      build, dependency audit
- [ ] **CI blocks merge on failure.** Set this up before there is any pressure
      to bypass it
- [ ] Total CI time under ~10 minutes; cache dependencies
- [ ] Deploy to staging automatically on merge to the default branch
- [ ] Production deploy: automated, one action, with an **executed** rollback
      rehearsal
- [ ] Migrations run as an explicit, ordered pipeline step with a documented
      failure procedure
- [ ] Build artefacts are immutable and traceable to a commit

> **Verify:** deploy to staging, roll it back, deploy again. Time each.

---

## Block 8 — Observability

- [ ] Structured (JSON) logging with level, timestamp, correlation id, user id
      where present
- [ ] **No personal data or secrets in logs.** Add a redaction layer now
- [ ] Correlation id generated at the edge and propagated through every call
- [ ] Error tracking wired to a real destination, with source maps or symbols
      uploaded
- [ ] `/health` (liveness) and `/ready` (readiness) endpoints, distinct
- [ ] Request duration and error rate metrics
- [ ] One dashboard with: request rate, error rate, p95 latency, database
      connections
- [ ] **One alert that pages a human**, on a user-visible symptom
- [ ] Graceful shutdown draining in-flight requests on `SIGTERM`

> **Verify:** trigger an error deliberately; confirm it appears in the tracker
> with the correlation id and no personal data.

---

## Block 9 — Public surface (if there is a website)

- [ ] Per-route unique `<title>` and meta description
- [ ] Canonical URL per page
- [ ] Open Graph and Twitter card tags with a real 1200x630 image
- [ ] `robots.txt` with a sitemap reference
- [ ] `sitemap.xml`, generated not hand-maintained
- [ ] **Custom 404** with navigation and search, returning a real 404 status
- [ ] Custom 500 page that does not leak stack traces
- [ ] Favicon set and web app manifest
- [ ] Semantic HTML: one `h1`, ordered headings, landmarks
- [ ] Visible focus indicator; full keyboard operability
- [ ] Alt text on every image; empty `alt` for decorative
- [ ] Structured data: `Organization`, `WebSite`, plus `LocalBusiness` if there
      is a physical location
- [ ] `security.txt` at `/.well-known/security.txt`
- [ ] Sticky mobile CTA on conversion pages

---

## Block 10 — Legal and trust

- [ ] Data inventory started — every personal-data field, purpose, legal basis,
      retention
- [ ] Privacy policy generated **from that inventory**, naming every real
      processor
- [ ] Cookie consent that **gates non-essential scripts before consent**, with
      reject as easy as accept
- [ ] **Self-service data export and deletion endpoint**, wired to a job that
      reaches every store and processor
- [ ] Terms of service
- [ ] Support and security contact, with a stated response commitment
- [ ] Subprocessor list, kept current

---

## Block 11 — Documentation

- [ ] README: what, why, run in one command, test, deploy, architecture sketch
- [ ] ADRs for every one-way door decided so far
- [ ] Runbook for the three most likely failures
- [ ] `CONTRIBUTING.md` if others will contribute
- [ ] `CLAUDE.md` / `AGENTS.md` describing conventions, so AI assistance matches
      the codebase instead of fighting it

> **Verify the whole scaffold:** hand the README to someone who has never seen
> the project. If they are not running it in 15 minutes, the README is wrong.

---

## The order matters

If time forces cuts, cut from the bottom of each block, never from Blocks 3, 5
or the authorization test in Block 6. Those three are the ones that turn into
incidents, breach notifications and rewrites. Everything else is recoverable.
