# OWASP Top 10 — Working Checklist

Organised by the OWASP Top 10 (2021) categories. Each item is a check you can
actually run, with the finding severity it usually carries.

---

## A01 — Broken Access Control

The most common serious finding in real applications. Budget the most time here.

- [ ] **Object-level authorization on every read and write.** Test: authenticate
      as A, request B's resource by id. `P0` if it returns data.
- [ ] **Deny by default.** A route with no declared policy fails closed. Find the
      router's default and confirm.
- [ ] **Function-level access control.** Every admin/privileged endpoint checks
      role server-side. Enumerate them from the route table, not the navigation.
- [ ] **Mass assignment.** No handler spreads a request body into a model.
      Explicit field allowlists. `P0` if `role`, `is_admin`, `tenant_id`,
      `price`, `balance` or `verified` are settable.
- [ ] **Privilege escalation.** Can a user change their own role? Invite
      themselves as owner? Move a resource to another tenant?
- [ ] **Tenant isolation.** Every query in a multi-tenant system filters by
      tenant. Enforced in the database (row-level security), not only in code.
      `P0` for any cross-tenant read.
- [ ] **CORS is an allowlist**, not origin reflection with credentials.
- [ ] **Direct object references are unguessable or authorised.** Sequential ids
      on public resources enable enumeration.
- [ ] **Force-browsing.** Unlinked pages, old routes, `.git/`, `/admin`,
      backup files, `/api/v1` after v2 shipped.
- [ ] **JWT claims are verified server-side**, not trusted from the payload.
      A `role` claim the client can influence is not authorization.

---

## A02 — Cryptographic Failures

- [ ] TLS everywhere, HSTS set, HTTP redirected. No mixed content.
- [ ] Passwords: argon2id / scrypt / bcrypt at current cost. `P0` for MD5, SHA-1,
      SHA-256, or unsalted.
- [ ] Sensitive data encrypted at rest where the threat model requires it;
      key management is via a KMS, not a constant in the codebase.
- [ ] No custom cryptography. Ever. Use the platform's vetted library.
- [ ] Randomness from a CSPRNG for tokens, ids and secrets. `Math.random()`,
      `rand()` and `uuid4` from a non-crypto source are `P1` for anything
      security-relevant.
- [ ] JWTs: algorithm pinned server-side; `alg: none` rejected; asymmetric keys
      where the verifier should not be able to sign; expiry enforced; `aud` and
      `iss` validated.
- [ ] Secrets not in code, not in logs, not in error messages, not in client
      bundles, not in container layers.
- [ ] Payment card data never touches your servers — use a hosted element.
- [ ] Sensitive data not in URLs (they land in logs, referrers and browser
      history).

---

## A03 — Injection

- [ ] **SQL:** parameterised everywhere. Audit every `raw`, `extra`, `whereRaw`,
      `FromSqlRaw`, `text()`, `$queryRawUnsafe`. `P0` for any interpolated input.
- [ ] Dynamic identifiers (table/column/direction) come from an allowlist —
      they cannot be parameterised.
- [ ] **Command:** no shell interpolation. Argument arrays, no `shell: true`,
      allowlisted binaries. `P0`.
- [ ] **Template:** user input never rendered as a template.
- [ ] **NoSQL:** request values coerced to expected types; object operators
      (`$ne`, `$gt`, `$where`) cannot arrive from input.
- [ ] **Path:** resolve then verify containment within the intended root.
      `P0` for path traversal on a file-serving endpoint.
- [ ] **LDAP / XPath / GraphQL:** escaped or parameterised per their rules.
- [ ] **XML:** external entity resolution disabled (XXE). `P0` if enabled on an
      endpoint accepting user XML.
- [ ] **Deserialization:** never deserialise untrusted data into arbitrary types.
      `P0` — this class is remote code execution.
- [ ] **Header / log injection:** control characters stripped from user input
      reaching headers or log lines.

---

## A04 — Insecure Design

- [ ] A threat model exists for the sensitive flows (auth, payment, deletion,
      admin).
- [ ] Business logic limits enforced server-side: quantities, amounts, quotas,
      rate of operations, negative values, integer overflow.
- [ ] **Prices, discounts and totals computed server-side.** `P0` if the client
      sends an amount that is trusted.
- [ ] Workflow steps cannot be skipped or reordered (checkout, verification,
      onboarding).
- [ ] Anti-automation on registration, login, reset, coupon redemption, search,
      and anything expensive.
- [ ] Segregation of duties for high-value actions (a second approval).
- [ ] Failure modes fail closed, not open.

---

## A05 — Security Misconfiguration

- [ ] Debug mode off in every deployed environment. `P0` — Django, Flask,
      Laravel and Rails debug pages all leak configuration or allow execution.
- [ ] Stack traces and internal errors never returned to clients.
- [ ] Default credentials changed; sample and installer routes removed.
- [ ] Directory listing off. `.git/`, `.env`, `.DS_Store`, backups not served.
- [ ] Security headers present (see `security-headers.md`).
- [ ] Version disclosure removed (`X-Powered-By`, `Server`, framework banners).
- [ ] Cloud storage buckets not public; object ACLs reviewed.
- [ ] Management interfaces network-restricted: databases, admin panels,
      dashboards, actuator/health endpoints exposing configuration. `P0` for an
      internet-reachable admin surface with only application auth.
- [ ] Container: non-root user, minimal base image, no build tooling in the
      runtime layer, no secrets in layers.
- [ ] CI/CD: secrets scoped, workflows from forks cannot access them, actions
      pinned to SHAs.

---

## A06 — Vulnerable and Outdated Components

- [ ] Lockfile committed; CI installs from it frozen.
- [ ] Automated dependency alerts enabled and triaged.
- [ ] Ecosystem audit tool run, and **its real output read**. Never assert a CVE
      from memory — check the actual advisory.
- [ ] Unmaintained dependencies identified (no release in 18+ months, single
      maintainer, archived).
- [ ] Runtime and framework versions still receiving security support. `P1` for
      an end-of-life runtime in production.
- [ ] Client-side dependencies loaded from a CDN carry subresource integrity, or
      better, are self-hosted.
- [ ] Install scripts in the dependency tree reviewed.

---

## A07 — Identification and Authentication Failures

- [ ] Rate limiting and progressive delay on login, registration, reset, MFA.
- [ ] Account lockout or equivalent, designed so it cannot be used to lock out
      other users deliberately.
- [ ] No user enumeration — identical responses and timing across login, reset
      and registration.
- [ ] Credential-stuffing defence: breached-password checking, MFA.
- [ ] Session id rotated on login and on privilege change.
- [ ] Sessions invalidated on logout and password change, everywhere including
      other devices.
- [ ] Session timeout: idle and absolute.
- [ ] Reset tokens single-use, short-lived, high-entropy, invalidated on use and
      on password change.
- [ ] MFA available; enforced for admins.
- [ ] "Remember me" tokens are per-device, revocable and rotated.
- [ ] OAuth: `state` validated (CSRF), PKCE for public clients, redirect URIs
      exactly matched, tokens never in URL fragments that leak.

---

## A08 — Software and Data Integrity Failures

- [ ] Dependencies from trusted registries; integrity hashes verified.
- [ ] CI/CD pipeline cannot be modified by an unreviewed PR.
- [ ] Build artefacts immutable, versioned, traceable to a commit.
- [ ] Auto-update mechanisms verify signatures.
- [ ] **Insecure deserialization** of untrusted data. `P0`.
- [ ] Webhook payloads verify the sender's signature before any processing.
      `P0` if a payment webhook is unverified — anyone can post a "payment
      succeeded" event.
- [ ] Third-party scripts pinned with SRI, or self-hosted.

---

## A09 — Security Logging and Monitoring Failures

- [ ] Auth events logged: success, failure, logout, reset, MFA, privilege change.
- [ ] Access-control failures logged with actor, target and outcome.
- [ ] Admin and high-value actions logged with an immutable audit trail.
- [ ] Logs carry enough context to reconstruct an incident: correlation id,
      actor, source, timestamp with timezone.
- [ ] **No secrets, tokens, passwords or personal data in logs.** Redaction is a
      layer, not a habit. `P1` for passwords or tokens in logs.
- [ ] Logs shipped off the host, tamper-resistant, retained to policy.
- [ ] Alerting on: authentication failure spikes, authorization failure spikes,
      unusual data export volume, new admin creation.
- [ ] There is a written incident response plan and someone is on call.

---

## A10 — Server-Side Request Forgery

- [ ] Every server-side fetch of a user-supplied URL has a scheme and host
      allowlist. `P0` without one.
- [ ] Private, loopback, link-local and cloud-metadata ranges blocked —
      including after redirects.
- [ ] DNS resolved and the resolved address checked before connecting (defeats
      rebinding).
- [ ] Redirects not followed, or re-validated at every hop.
- [ ] Response not returned verbatim to the user (blind SSRF is preferable to
      full response disclosure).
- [ ] Outbound network policy at the infrastructure layer as defence in depth.

Common SSRF entry points, in order of frequency: webhook URL configuration,
image or avatar "import from URL", PDF/screenshot renderers, link preview
generators, file import, and integrations where the user supplies a base URL.

---

## Beyond the Top 10 — checks worth running

- **Business logic abuse:** negative quantities, decimal amounts where integers
  are assumed, race conditions on balance or inventory (test with concurrent
  requests), coupon stacking, refund loops.
- **Race conditions / TOCTOU:** check-then-act without a lock or a database
  constraint. Test by firing concurrent requests at the same resource.
- **Denial of service:** unbounded uploads, unbounded pagination, regex
  catastrophic backtracking on user input, zip bombs, GraphQL query depth.
- **Client-side:** `postMessage` origin validation, `localStorage` holding
  tokens, prototype pollution, DOM XSS sinks.
- **Mobile:** secrets in the bundle, disabled certificate validation, tokens in
  plain preferences, exported components, unvalidated deep links.
- **AI features:** prompt injection treated as an authorization problem — never
  give the model direct privileged access; put a permission check between model
  intent and action; treat model output reaching a browser as untrusted.
