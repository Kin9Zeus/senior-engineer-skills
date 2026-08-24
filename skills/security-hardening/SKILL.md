---
name: security-hardening
description: Application security engineering — OWASP Top 10, authentication and object-level authorization, injection, XSS/CSP, CSRF, SSRF, secrets management, file uploads, security headers, dependency and supply-chain risk, and threat modelling. Use when reviewing or building anything touching login, sessions, tokens, passwords, permissions, roles, payments, file uploads, webhooks, user-generated content or personal data; when the user says "is this secure", "security review", "pentest", "harden", "vulnerability", "OWASP", "XSS", "SQL injection", "CSRF", "IDOR", "leaked key", "exposed secret", "auth bypass", "rate limit" or "security headers"; and as a mandatory pass in any project audit. Defensive security only. By Devleck.
license: MIT
---

# Security Hardening

Assume every input is hostile, every user is an attacker, and every secret in
the repository is already public. Then check whether the code agrees.

**Scope:** defensive security — finding and fixing weaknesses in code the user
owns or is authorised to assess. Never scan, probe or send traffic to
infrastructure without explicit confirmation of ownership or authorisation.
Produce fixes and detections, not weaponised exploits.

---

## The order of operations

Findings are not equal. Work top-down; the first three account for most real
breaches.

1. **Secrets** — anything committed is compromised.
2. **Broken access control** — the most common critical finding in real systems.
3. **Injection** — SQL, command, template, LDAP, NoSQL.
4. **Authentication weaknesses** — sessions, tokens, resets, MFA.
5. **XSS and content injection.**
6. **SSRF and unvalidated redirects.**
7. **Insecure configuration** — headers, debug modes, exposed endpoints.
8. **Supply chain** — dependencies, install scripts, build pipeline.
9. **Cryptographic failures** — at rest, in transit, in tokens.
10. **Logging and monitoring gaps** — an undetected breach is an unbounded one.

`references/owasp-checklist.md` carries the full per-category checks.

---

## 1. Secrets — start here, always

```bash
git log --all --full-history --name-only -- '*.env' '*.pem' '*.key' '*.p12' '*credential*' | head -30
git ls-files | grep -E '(^|/)\.env($|\.)' | grep -v example
```

Plus the pattern scan in `scripts/secret-scan.sh` / `.ps1`.

**Anything found in history is disclosed**, even if a later commit removed it. It
lives in every clone, every fork, every CI cache. The remediation order is fixed:

1. **Rotate the credential.** Immediately, before anything else.
2. **Check for abuse** — provider audit logs, unexpected usage, unfamiliar IPs.
3. **Purge the history** (`git filter-repo`, or BFG) and force-push, with every
   collaborator re-cloning.
4. **Prevent recurrence** — secret scanning in CI, pre-commit hooks, `.gitignore`.

Doing step 3 without step 1 is the most common mistake: it makes the repository
look clean while the key stays live.

**Also check for secrets in:** built client bundles, source maps, container image
layers, CI logs, error messages, and `PUBLIC_`-prefixed environment variables.

---

## 2. Broken access control — the highest-yield review

This is where the severe findings are. Authentication answers *who are you*;
authorization answers *may you do this to this object*. Systems get the first
right and the second wrong.

**The test that finds it:** authenticate as user A, then request user B's
resource by changing an identifier.

```
GET  /api/invoices/{B's id}      -> must be 403 or 404, never 200
POST /api/teams/{B's team}/members
GET  /api/users/{B's id}/export
```

Grep for the shape of the bug — a lookup by id with no ownership predicate:

```bash
grep -rEn 'findById|findByPk|findOne\(\{ *_?id|\.get\(pk=|Model\.find\(|WHERE id *=' \
  --exclude-dir={node_modules,.git,vendor,dist} . | head -30
```

Then read each hit and ask: **where is the caller's relationship to this object
asserted?** If the answer is "the frontend only shows the user their own", it is
an IDOR and it is a P0.

Also check:
- **Function-level access control.** Admin endpoints reachable by non-admins.
  "Unlinked" is not access control.
- **Mass assignment.** A request body that can set `role`, `is_admin`,
  `organization_id`, `price` or `verified` because the handler spreads it into
  the model.
- **Privilege escalation paths.** Can a member invite themselves as owner? Can a
  user change their own role? Can an org admin reach another org?
- **Deny by default.** Is there a route with no policy declared? What does the
  system do — allow or deny?

See `references/authz-patterns.md`.

---

## 3. Injection

| Type | The bug | The fix |
|---|---|---|
| SQL | String concatenation or interpolation into a query | Parameterised queries. Always. Identifiers that must be dynamic come from an allowlist, never from input |
| Command | User input reaching a shell | Avoid shells; use argument-array APIs; allowlist |
| Template | User input rendered as a template | Never render user strings as templates |
| NoSQL | Objects passed where scalars are expected (`{$ne: null}`) | Coerce and validate types at the boundary |
| Path | User-controlled path segments | Resolve, then verify the result stays inside the intended root |
| Header / log | Newlines in user input reaching headers or logs | Strip control characters |

```bash
grep -rEn "(query|execute|exec|raw|prepare)\s*\(\s*[\"\`'][^\"\`']*(\\\$\{|\" *\+|%s|f[\"'])" \
  --exclude-dir={node_modules,.git,vendor} . | head -20
```

An ORM does not make you safe. `.raw()`, `.extra()`, `whereRaw`, `FromSqlRaw`
and `text()` all bypass parameterisation.

---

## 4. Authentication

- Password hashing: argon2id, scrypt, or bcrypt at a current cost. Never MD5,
  SHA-1, SHA-256, or an unsalted hash.
- Session invalidation on logout, on password change, and on privilege change.
- Tokens: short-lived access tokens, rotating refresh tokens with reuse
  detection. JWTs verified with a pinned algorithm — reject `alg: none` and
  never let the token choose its own verification algorithm.
- Password reset: single-use, time-bounded, invalidated on use, and delivered
  without leaking whether the account exists.
- No user enumeration: identical response and timing for existing and
  non-existing accounts on login, reset and registration.
- Rate limiting and progressive delay on login, reset and registration.
- MFA available, and enforced for privileged accounts.
- Cookies: `HttpOnly`, `Secure`, `SameSite=Lax` or `Strict`, scoped path.

See `references/auth-patterns.md`.

---

## 5. XSS, CSP and content

- Output encoded by default; every escape hatch (`dangerouslySetInnerHTML`,
  `v-html`, `innerHTML`, `|safe`, `html_safe`, `raw`) individually justified and
  fed only sanitised content.
- Sanitise with a maintained library on an allowlist basis, server-side, at
  render.
- **A CSP without `unsafe-inline` and without `unsafe-eval`**, using nonces or
  hashes. This is the control that turns most XSS from critical into noise.
- User-supplied URLs validated against a scheme allowlist — `javascript:` and
  `data:` in an `href` are XSS.
- File uploads served from a separate origin, with
  `Content-Disposition: attachment` and `X-Content-Type-Options: nosniff`.

---

## 6. The rest of the surface

**SSRF** — any server-side fetch of a user-supplied URL is a finding until it has
a scheme and host allowlist, blocks private and link-local ranges, blocks
redirects to them, and resolves DNS before connecting (to defeat rebinding).
Cloud metadata endpoints are the usual target.

**CSRF** — `SameSite` cookies plus tokens for cookie-authenticated state changes.
Token-in-header auth is not automatically immune if a cookie fallback exists.

**CORS** — an explicit origin allowlist. Reflecting the request origin with
`Allow-Credentials: true` is equivalent to no policy at all.

**Uploads** — verify content, not extension; cap size; never store with a
user-controlled filename; never serve from a path that can execute; scan where
the threat model warrants it.

**Redirects** — never redirect to a user-supplied URL without an allowlist.

**Headers** — HSTS, `X-Content-Type-Options: nosniff`, `Referrer-Policy`,
`frame-ancestors`, `Permissions-Policy`. Remove `X-Powered-By` and version
banners.

**Configuration** — debug off, stack traces not returned to clients, directory
listing off, default credentials changed, admin interfaces network-restricted,
cloud storage buckets not public.

See `references/security-headers.md`.

---

## 7. Supply chain

- Lockfile committed; builds install from it with a frozen/`ci` flag.
- Automated vulnerability alerts enabled and actually triaged.
- Run the ecosystem's audit tool and **read the real output** — never assert a
  CVE from memory.
- Review `postinstall` and `preinstall` scripts in the dependency tree; they run
  arbitrary code on every developer machine and CI runner.
- Pin CI actions to a commit SHA, not a moving tag.
- CI secrets scoped to the minimum, never exposed to workflows triggered by
  forks.
- Generate an SBOM for anything distributed.
- Licence policy enforced in CI.

See `references/supply-chain.md`.

---

## 8. Threat modelling — for new systems and major features

Four questions, thirty minutes, in `references/threat-modelling.md`:

1. What are we building? (a data-flow sketch with trust boundaries)
2. What can go wrong? (STRIDE per boundary)
3. What are we doing about it? (a control per threat)
4. Did we do a good job? (a test per control)

---

## Reporting a security finding

```markdown
### `<Title>` — P0

**Class**       Broken object-level authorization (OWASP A01)
**Location**    src/api/invoices/[id]/route.ts:24
**Confidence**  CONFIRMED

**Impact**      Any authenticated user can read any other user's invoice —
                names, addresses, line items and amounts for all 4,200 customers.

**Reproduce**   Authenticate as user A, then:
                GET /api/invoices/<any id belonging to B>   -> 200 with B's data

**Fix**         Scope the query to the caller:
                - const invoice = await db.invoice.findUnique({ where: { id } })
                + const invoice = await db.invoice.findFirst({
                +   where: { id, organizationId: session.organizationId } })

**Verify**      Add a test: authenticate as A, request B's invoice, expect 404.
                It must fail against the current code.
```

Always include the failing test. A security fix without a regression test will
be reintroduced.

---

## References and scripts

- `references/owasp-checklist.md` — the full Top 10 checks, per category
- `references/authz-patterns.md` — access control that is hard to get wrong
- `references/auth-patterns.md` — sessions, tokens, resets, MFA
- `references/security-headers.md` — headers and CSP, with working configurations
- `references/supply-chain.md` — dependencies, CI, build integrity
- `references/threat-modelling.md` — the 30-minute STRIDE pass
- `scripts/secret-scan.sh` / `scripts/secret-scan.ps1` — read-only secret and pattern scan
