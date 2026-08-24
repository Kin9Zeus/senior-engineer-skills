---
description: Application security pass — secrets, access control, injection, auth, headers, supply chain — with fixes and regression tests.
argument-hint: "[path or scope, e.g. 'the API' or 'auth flow']"
---

# Security Hardening Pass

Harden: **$ARGUMENTS** (default: the whole repository).

Load the `security-hardening` skill. Defensive security only — never scan,
probe or send traffic to infrastructure the user has not confirmed they own or
are authorised to test.

## Order of work — top-down by real-world yield

```
1  Secrets           — anything committed is compromised. Start here
2  Access control    — the highest-severity findings live here
3  Injection         — SQL, command, template, path, deserialization
4  Authentication    — sessions, tokens, resets, MFA, rate limits
5  XSS and CSP
6  SSRF, CSRF, CORS, redirects, uploads
7  Configuration     — debug mode, headers, exposed endpoints
8  Supply chain      — dependencies, install scripts, CI
9  Crypto            — hashing, randomness, JWT verification
10 Logging           — auth events logged; no secrets or PII in logs
```

## Run the scan first

`skills/security-hardening/scripts/secret-scan.sh` (or `.ps1`). It is read-only.
Everything it reports is a **lead, not a finding** — confirm each by reading the
file.

## The two checks that find the most severe issues

**1 · Secrets in git history.** Anything ever committed is disclosed, in every
clone and fork. Remediation order is fixed and non-negotiable:

```
1. ROTATE the credential — immediately, before anything else
2. Check the provider's audit log for abuse
3. Purge the history (git filter-repo / BFG), everyone re-clones
4. Enable secret scanning and a pre-commit hook
```

Purging without rotating leaves the key live and makes the repository look
clean. That is the most common mistake in this whole area.

**2 · Object-level authorization.** Authenticate as user A; request user B's
resource by changing an identifier. A `200` is a `P0`. Grep for the shape:

```bash
grep -rEn 'findById|findByPk|findOne\(\{ *_?id|\.get\(pk=|WHERE id *=' \
  --exclude-dir={node_modules,.git,vendor,dist} . | head -30
```

Then read each hit and ask: **where is the caller's relationship to this object
asserted?** Grep for the mitigating control before declaring a finding — a false
`P0` costs the reader's trust for the whole report.

## Fixing

If the user asks for fixes, not just findings:

- **Severity order.** `P0` first, one finding per commit.
- **Write the failing test before the fix.** A security fix without a regression
  test gets reintroduced.
- **Do not bundle refactors with security fixes** — a reviewer must be able to
  see the fix.
- Re-verify each fix with its stated verification step and report the actual
  result.

## Report format

```markdown
### <Title> — P0
**Class**       Broken object-level authorization (OWASP A01)
**Location**    src/api/invoices/[id]/route.ts:24
**Confidence**  CONFIRMED
**Impact**      <concrete: who is harmed, how many, what data>
**Reproduce**   <exact request>
**Fix**         <diff>
**Verify**      <the test that must fail against current code>
```

Never assert a CVE, a severity or an affected version range from memory. Run the
ecosystem's audit tool and quote its real output. If the tool is unavailable, say
the check did not run — not that the project is clean.
