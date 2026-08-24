# Stack Playbooks

Stack-specific checks that generic advice misses. Run the playbook for the stack
you detected. Framework and library versions change — verify current guidance
against the project's actual installed versions rather than assuming what a
given release does.

---

## Next.js / React

**Server/client boundary**
- `"use client"` at the top of a layout or a high component pushes the entire
  subtree to the client. Grep for it and check placement.
- **Secrets in client components.** Any env var read in a client component must
  be public. `NEXT_PUBLIC_` prefixed values are compiled into the browser bundle
  — check nothing sensitive carries that prefix. Reading a non-prefixed secret in
  client code is a build-time bug or a leak, depending on version. **P0 if a key
  is exposed.**
- Server Actions are public HTTP endpoints. Each one needs its own
  authentication and authorization check — being unexported from a page is not
  access control. **P0 if a Server Action mutates without an authorization check.**
- Route handlers under `app/api/` are equally public. Enumerate them all.

**Caching and revalidation**
- Data cached at the wrong scope leaks between users. Any per-user fetch inside
  a cached segment is a cross-user data leak. **P0.**
- `revalidate` values and `dynamic` exports set deliberately per route, or
  inherited by accident.
- `cookies()`/`headers()` usage forces dynamic rendering — check whether
  supposedly static pages are actually dynamic.

**Performance and SEO**
- `next/image` used, or raw `<img>` with unoptimised assets.
- `generateMetadata` per route, or one shared title in the root layout.
  Duplicated titles across routes is a P2 SEO finding.
- Client bundle size per route (`next build` prints it). Anything over ~200KB
  first-load JS on a content page warrants a look.
- `middleware.ts` runs on every matched request — check the matcher is not `/*`
  doing database work.

**Common P0s:** unauthenticated Server Action; `NEXT_PUBLIC_` secret; per-user
data in a cached static segment.

---

## Django

- `DEBUG = True` in anything reachable from the internet. **P0** — it exposes
  settings, SQL and stack traces.
- `SECRET_KEY` hardcoded in settings and committed. **P0.**
- `ALLOWED_HOSTS` set to `["*"]`.
- Security middleware present and configured: `SecurityMiddleware`,
  `CsrfViewMiddleware`, `XFrameOptionsMiddleware`; `SECURE_SSL_REDIRECT`,
  `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `SECURE_HSTS_SECONDS`.
  `python manage.py check --deploy` prints the whole list — run it.
- **Object-level permissions.** `LoginRequiredMixin` is authentication.
  `get_queryset` must filter by the requesting user, or every detail view is an
  IDOR. This is the single most common Django finding.
- Raw SQL: `.raw()` and `.extra()` with f-strings or `%` formatting. **P0.**
- N+1: missing `select_related` / `prefetch_related`. Install
  `django-debug-toolbar` in development and count queries on the main list view.
- Migrations: check for conflicting leaf nodes (`makemigrations --check`), and
  data migrations mixed into schema migrations.
- `on_delete` on every `ForeignKey` chosen deliberately — `CASCADE` copied
  everywhere is how a user deletion silently removes audit records.

---

## Rails

- `credentials.yml.enc` used, with `master.key` **not** committed. If
  `master.key` is in git, every credential is compromised. **P0.**
- Strong parameters on every controller; `params.permit!` anywhere is a **P0**
  mass-assignment hole.
- `html_safe` and `raw` on user-supplied content. **P0** for XSS.
- Scoping: `Model.find(params[:id])` without a user scope is an IDOR. The correct
  shape is `current_user.models.find(params[:id])`.
- N+1: run with `bullet` or check the log for repeated queries per request.
- `config.force_ssl`, `protect_from_forgery`, and secure cookie flags set in
  production.
- Background jobs: retry semantics and idempotency; a non-idempotent job with
  retries will double-execute.

---

## Laravel

- `APP_DEBUG=false` and `APP_ENV=production` in production. **P0** otherwise —
  Laravel's debug page exposes environment variables.
- `.env` never committed; `APP_KEY` set and not the framework default.
- Mass assignment: `$fillable` or `$guarded` defined on every model. `$guarded =
  []` is a **P0**.
- Authorization via policies/gates on every action, not just `auth` middleware.
- `DB::raw` and `whereRaw` with interpolated input. **P0.**
- Eager loading (`with()`) to avoid N+1; `Model::preventLazyLoading()` in
  development catches these.
- Queue driver in production is not `sync` (which silently makes every job
  synchronous and slow).
- Storage: files written to `storage/app/public` and served via symlink, not
  into a web-executable directory.

---

## Express / Node / NestJS

- `helmet` (or equivalent explicit headers) applied. Missing security headers is
  a P2 on its own but signals a broader gap.
- Body size limits set; unbounded JSON bodies are a trivial DoS.
- Rate limiting on auth and mutating routes.
- Async errors: an async handler that throws without a wrapper crashes or hangs
  depending on version. Check the error middleware exists and is registered last.
- `process.on('unhandledRejection')` handled, and the process exits rather than
  continuing in an unknown state.
- No `eval`, `new Function`, or `child_process.exec` with interpolated input.
  **P0.**
- Dependency count: a 1,200-package tree for a small API is a supply-chain
  finding. Check for install scripts (`npm ls --all --parseable` and review
  `preinstall`/`postinstall`).
- Graceful shutdown on `SIGTERM` — otherwise every deploy drops in-flight
  requests.

---

## Spring Boot / Java

- Actuator endpoints exposed without authentication (`/actuator/env`,
  `/heapdump`) — **P0**, they leak configuration and memory contents.
- Method-level security (`@PreAuthorize`) or explicit checks — URL-pattern
  security alone misses direct service calls.
- JPA: `FetchType.EAGER` on collections producing cartesian joins; missing
  `@Transactional` boundaries; open-session-in-view masking N+1.
- Jackson polymorphic deserialization enabled on untrusted input — a known RCE
  class.
- Dependency versions: run the project's dependency check task and read the
  actual report; do not assert CVEs from memory.

---

## Go

- Every `error` checked. `errcheck` / `golangci-lint` in CI.
- `context.Context` propagated with deadlines to every outbound call. A missing
  deadline is an unbounded hang.
- `database/sql`: `rows.Close()`, `rows.Err()` checked, statements parameterised
  with placeholders — never `fmt.Sprintf` into SQL. **P0.**
- Goroutine lifecycle: every goroutine has a termination path; leaks show as
  growing goroutine count under load.
- Mutex/shared state: run the race detector (`go test -race ./...`).
- `http.Server` with `ReadTimeout`, `WriteTimeout`, `IdleTimeout` set — the
  zero-value server has no timeouts at all. **P1.**

---

## .NET

- `UseDeveloperExceptionPage` gated to development only.
- EF Core: `AsNoTracking` on read paths, no client-side evaluation of `Where` on
  large sets, explicit `Include` rather than lazy loading.
- Parameterised queries; `FromSqlRaw` with interpolation is a **P0** (use
  `FromSqlInterpolated`, which parameterises).
- Data protection keys persisted and shared across instances, or every restart
  invalidates all sessions and antiforgery tokens.
- `[Authorize]` with policies, plus resource-based authorization for object-level
  checks.
- `ConfigureAwait` / synchronous blocking on async (`.Result`, `.Wait()`) causing
  thread-pool starvation.

---

## Python (FastAPI / Flask)

- Pydantic (or equivalent) models on every request body and query parameter —
  FastAPI gives this almost free, so an unvalidated endpoint is a deliberate gap.
- Dependency-injected auth applied per route; a global middleware that exempts
  paths by prefix is fragile.
- SQLAlchemy: `text()` with f-strings is a **P0**; `lazy="select"` relationships
  in loops are N+1.
- Async endpoints doing blocking I/O (a sync database driver inside `async def`)
  block the event loop. **P1** under load.
- `requirements.txt` unpinned (`flask` with no version) means non-reproducible
  builds — prefer a lock file.
- Flask `debug=True` in production is remote code execution via the debugger
  console. **P0.**

---

## Mobile (React Native / Flutter / native)

- **Secrets in the bundle.** Anything compiled into the app is readable. API
  keys with server-side privileges in a mobile binary are **P0**.
- Certificate handling: no disabled TLS validation, no accept-all trust managers
  left from development. **P0.**
- Local storage: tokens in the platform keychain/keystore, not in plain
  preferences or `AsyncStorage`.
- Deep links validated — an unvalidated deep link is an entry point.
- Permissions requested lazily with a purpose string, not all at launch.
- Forced upgrade path for the case where a client version must be retired.
- Offline and poor-network behaviour designed, not accidental.

---

## Static sites / Jamstack / WordPress

- Build-time secrets not inlined into the output. Grep the built assets for key
  patterns — this catches more leaks than reviewing source.
- Form endpoints (Netlify/Formspree/serverless) rate-limited and spam-protected.
- Redirects and headers configured (`_headers`, `_redirects`, `netlify.toml`,
  `vercel.json`) — including a real 404 and security headers.
- WordPress specifically: core, theme and plugin versions current; `wp-config.php`
  outside the web root or protected; `XML-RPC` disabled if unused; admin under a
  non-default path with rate limiting; no plugin abandoned by its author. An
  outdated plugin is the most common WordPress compromise vector. **P0/P1
  depending on the known vulnerability status — verify against the actual
  installed version, do not assert from memory.**

---

## Cross-cutting, whatever the stack

Run these regardless:

```bash
# Reproducibility
ls package-lock.json yarn.lock pnpm-lock.yaml poetry.lock Pipfile.lock go.sum Gemfile.lock composer.lock 2>/dev/null

# Vulnerability surface — read the real output, never assert from memory
npm audit --production 2>/dev/null | tail -20
pip-audit 2>/dev/null | tail -20
govulncheck ./... 2>/dev/null | tail -20
bundle audit 2>/dev/null | tail -20
composer audit 2>/dev/null | tail -20

# Secrets in history
git log --all --full-history --name-only -- '*.env' '*.pem' '*.key' | head -20
```

If a tool is not installed, say the check was not run rather than reporting a
clean result.
