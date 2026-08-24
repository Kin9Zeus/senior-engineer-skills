# Security Headers and CSP

Headers are the cheapest security control available: a config change that
neutralises whole classes of attack. Verify against the live response, not the
source — a header set in code and stripped by a proxy is not a header.

```bash
curl -sSI https://example.com | grep -Ei 'strict-transport|content-security|x-frame|x-content-type|referrer|permissions|cross-origin'
```

---

## The baseline

```
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
Content-Security-Policy:   <see below>
X-Content-Type-Options:    nosniff
Referrer-Policy:           strict-origin-when-cross-origin
Permissions-Policy:        camera=(), microphone=(), geolocation=(), interest-cohort=()
X-Frame-Options:           DENY                 # legacy; CSP frame-ancestors supersedes it
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
```

And remove: `X-Powered-By`, `Server` version strings, framework banners.

| Header | What it prevents |
|---|---|
| `Strict-Transport-Security` | Protocol downgrade and cookie interception. `preload` requires submission to the browser preload list and is effectively permanent for the domain — understand that before enabling it |
| `Content-Security-Policy` | XSS execution, data exfiltration, unwanted framing |
| `X-Content-Type-Options: nosniff` | The browser guessing an executable type for a file you serve as data |
| `Referrer-Policy` | Leaking URLs (which can contain tokens or ids) to third parties |
| `Permissions-Policy` | Silent access to device APIs, including by embedded third parties |
| `frame-ancestors` / `X-Frame-Options` | Clickjacking |
| `COOP` / `CORP` | Cross-origin isolation attacks and side-channel leaks |

`X-XSS-Protection` is obsolete — modern browsers ignore it, and its legacy
filter caused vulnerabilities of its own. Set `0` or omit it entirely.

---

## Content Security Policy

The single most valuable header, and the one most often defeated by its own
configuration.

**A policy containing `unsafe-inline` in `script-src` provides essentially no XSS
protection.** If a policy has it, the finding is "no CSP", not "weak CSP".

### Nonce-based policy — the recommended shape

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{RANDOM}' 'strict-dynamic';
  style-src 'self' 'nonce-{RANDOM}';
  img-src 'self' data: https://cdn.example.com;
  font-src 'self';
  connect-src 'self' https://api.example.com;
  frame-ancestors 'none';
  form-action 'self';
  base-uri 'none';
  object-src 'none';
  upgrade-insecure-requests;
  report-uri /csp-report
```

The nonce is generated **per response** from a CSPRNG and stamped on every
legitimate inline script. An injected script has no nonce and does not execute.

`'strict-dynamic'` lets a nonced script load further scripts it trusts, which is
what makes bundlers and third-party loaders workable without host allowlists.
Host allowlists in `script-src` are widely bypassable — prefer nonces.

Four directives that are easy to forget and matter a great deal:
- `object-src 'none'` — blocks legacy plugin-based XSS vectors.
- `base-uri 'none'` — stops an injected `<base>` from redirecting every relative
  script URL to an attacker's host.
- `form-action 'self'` — stops an injected form from posting credentials
  elsewhere.
- `frame-ancestors 'none'` — the modern clickjacking control.

### Rolling one out on an existing app

1. Deploy as `Content-Security-Policy-Report-Only` with a report endpoint.
2. Collect for one to two weeks across real traffic. Expect noise from browser
   extensions — filter it.
3. Fix genuine violations by moving inline handlers into files and adding nonces.
4. Tighten the policy until reports are clean.
5. Switch to enforcing. Keep the report endpoint permanently — it is an early
   warning for injected content.

**Frameworks:** Next.js supports nonces via middleware and
`next.config` headers; Django has `django-csp`; Rails has a built-in
`content_security_policy` DSL with nonce helpers; Laravel and Express both have
maintained middleware. Use the framework's mechanism rather than hand-writing
the header, so the nonce reaches the templates.

---

## Cookies

```
Set-Cookie: sid=...; HttpOnly; Secure; SameSite=Lax; Path=/
```

- `HttpOnly` — unreachable from JavaScript. Blunts token theft via XSS.
- `Secure` — HTTPS only.
- `SameSite=Lax` is the right default (`Strict` breaks inbound links;
  `None` requires `Secure` and removes CSRF protection).
- `__Host-` prefix for session cookies where possible — the browser enforces
  `Secure`, `Path=/` and no `Domain`, which prevents a compromised subdomain from
  setting a cookie for the parent.
- Scope `Domain` as narrowly as possible. A cookie on `.example.com` is readable
  by every subdomain, including that forgotten marketing site on a shared host.

---

## CORS

```
Access-Control-Allow-Origin: https://app.example.com   # exact, from an allowlist
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET, POST, PATCH, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Max-Age: 86400
```

**The finding to look for:** reflecting `Origin` back with
`Allow-Credentials: true`. That is equivalent to allowing every origin to make
authenticated requests, and it is a `P0`. `Allow-Origin: *` with credentials is
rejected by browsers, which is why implementations reflect instead — and
reflection is the vulnerability.

Also check the allowlist matching logic: `origin.endsWith("example.com")` matches
`evilexample.com`. Compare against a set of exact strings.

---

## Framework configuration

**Express**
```js
import helmet from "helmet";
app.use(helmet({
  contentSecurityPolicy: { directives: { /* as above */ } },
  hsts: { maxAge: 63072000, includeSubDomains: true, preload: true },
  referrerPolicy: { policy: "strict-origin-when-cross-origin" },
}));
app.disable("x-powered-by");
```

**Next.js** — `headers()` in `next.config.js` for the static set, plus
`middleware.ts` for the per-request nonce.

**Django** — `SECURE_HSTS_SECONDS`, `SECURE_SSL_REDIRECT`,
`SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `SECURE_CONTENT_TYPE_NOSNIFF`,
`X_FRAME_OPTIONS`. Run `manage.py check --deploy` and fix everything it prints.

**Nginx / Caddy / CDN** — setting headers at the edge is fine and often
simplest, but be aware that a proxy can also *strip* headers the application
sets. Verify the final response.

---

## Verification

```bash
# The live response is the only source of truth
curl -sSI https://example.com | grep -Ei 'strict-transport|content-security|x-frame|x-content-type|referrer|permissions|server|x-powered'

# Does the CSP actually block inline script?
curl -sS https://example.com | grep -o "<script>" | head
```

Automated graders (Mozilla Observatory, securityheaders.com) are useful as a
smoke test. Do not let a grade substitute for reading the policy — a policy can
score well and still contain `unsafe-inline`.

**Do not forget:** the API subdomain, the marketing site, the docs site, the
status page and the staging environment. Headers set on the app and absent
everywhere else are a partial control, and the forgotten subdomain is usually
where the cookie scope problem lives.
