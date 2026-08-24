# Authentication Patterns

Authentication is a solved problem that teams keep re-solving badly. The
strongest recommendation in this document: **use a maintained provider or your
framework's battle-tested built-in.** Hand-rolled auth is where the breaches are.

---

## Passwords

**Hashing**

| Algorithm | Verdict |
|---|---|
| argon2id | Preferred. Memory-hard, tunable |
| scrypt | Good |
| bcrypt | Acceptable, at a current cost factor. Note its input length limit — pre-hash long inputs |
| PBKDF2 | Acceptable only where a compliance regime requires it |
| SHA-256 / SHA-1 / MD5, salted or not | **`P0`.** These are fast by design, which is exactly wrong here |

Tune parameters to your hardware, targeting roughly 250–500ms per hash on your
production instance, then re-tune annually. Store the parameters with the hash so
you can upgrade cost over time and rehash on next successful login.

**Policy**
- Minimum length 8, and *encourage* long passphrases. Do not impose composition
  rules (upper/lower/symbol) — current guidance is that they reduce entropy by
  pushing users to predictable patterns.
- Allow the full Unicode range and paste; never truncate silently.
- Check against a breached-password corpus (k-anonymity APIs let you do this
  without sending the password).
- No mandatory periodic rotation. Rotate on evidence of compromise.
- Cap at a sane maximum (e.g. 128 chars) to prevent hashing-based DoS.

---

## Sessions vs tokens

| | Server sessions | JWT / stateless |
|---|---|---|
| Revocation | Immediate | Hard — needs a denylist, which reintroduces state |
| Scaling | Needs shared storage | Stateless |
| Size | Small cookie | Larger, sent every request |
| Best for | Web apps | Service-to-service, short-lived access tokens |

**For a web application, server-side sessions in a cookie are the correct default.**
Instant revocation matters more than statelessness at almost every scale, and the
common JWT failure mode — a compromised token valid for its full lifetime with no
way to kill it — is worse than the problem it solves.

**Session cookies**

```
Set-Cookie: sid=<opaque-high-entropy-value>;
  HttpOnly;                 # unreachable from JavaScript — blunts XSS token theft
  Secure;                   # HTTPS only
  SameSite=Lax;             # CSRF defence; Strict where UX allows
  Path=/;
  Max-Age=2592000
```

- Session id is opaque and from a CSPRNG (128+ bits). Never derived from the
  user id.
- **Rotate the session id on login** and on any privilege change (session
  fixation).
- Store server-side with an absolute expiry *and* an idle timeout.
- Invalidate on logout, on password change, and on demand across all devices.
- Bind loosely to context (user agent family, coarse IP) — tightly enough to
  notice theft, loosely enough not to log out mobile users who change networks.

**If you use JWTs**
- Access tokens short-lived (5–15 minutes). Refresh tokens long-lived, rotating,
  stored server-side, with **reuse detection** — a replayed refresh token means
  theft, so revoke the whole family.
- Pin the algorithm server-side. Reject `alg: none`. Never let the token select
  its verification algorithm — this is a decade-old bypass that still ships.
- Validate `exp`, `nbf`, `iss` and `aud` on every request.
- Prefer asymmetric signing so verifiers cannot mint tokens.
- Never put anything secret in the payload — it is base64, not encryption.
- **Never store tokens in `localStorage`** if XSS is a realistic threat; any
  script on the page can read them. `HttpOnly` cookies plus CSRF protection is
  the stronger posture.

---

## Login flow

```
1. Rate-limit the attempt          (per IP and per account; progressive delay)
2. Look up the account             (constant-time behaviour whether or not it exists)
3. Verify the password             (always run the hash comparison, even for a
                                    missing account, against a dummy hash — this
                                    is what defeats timing enumeration)
4. Check account state             (locked, unverified, disabled)
5. Check MFA if enrolled
6. Create the session              (new id; record device, IP, timestamp)
7. Log the event                   (success or failure, with actor and source)
8. Redirect to a validated internal path only
```

**No user enumeration.** Login, registration and password reset must return the
same response and take the same time whether or not the account exists.
"No account with that email" is a gift to credential stuffing.

**Rate limiting** on both axes — per IP defeats a single attacker, per account
defeats a distributed one. Progressive delay is friendlier than lockout;
lockout must be designed so it cannot be weaponised to lock legitimate users out.

---

## Password reset

The reset flow is frequently the weakest link, because it is a full account
takeover path that gets less attention than login.

```
1. Accept the identifier; always respond with the same neutral message
2. If the account exists, generate a CSPRNG token (32+ bytes)
3. Store only a HASH of the token, with an expiry (15-60 minutes) and single-use flag
4. Email the link; never expose the token elsewhere
5. On use: verify hash, verify not expired, verify not used
6. Set the new password, mark the token used, invalidate every other reset token
7. INVALIDATE ALL SESSIONS for that user
8. Notify the account by email that the password changed
```

The failures to check for: tokens that are not single-use; tokens that survive a
password change; sessions that survive a reset (an attacker who is already in
stays in); reset links leaking through the `Referer` header; host-header
injection controlling the link domain; and tokens stored in plaintext, so a
database read yields account takeover.

---

## Multi-factor authentication

- **TOTP** is the sensible default: standard, offline, no delivery cost.
- **WebAuthn/passkeys** are stronger — phishing-resistant by design — and now
  well supported. Offer them where you can.
- **SMS** is weak (SIM swap, SS7) but better than nothing; do not make it the
  only option for privileged accounts.
- Recovery codes: generated once, hashed at rest, single-use, and regenerable.
- **Require MFA for administrative accounts.** Non-negotiable.
- Re-authenticate for sensitive actions (changing email, disabling MFA, deleting
  the account, viewing secrets) even within a valid session.
- Rate-limit MFA verification — a 6-digit code is brute-forceable without it.

---

## OAuth / OIDC

- Validate `state` on the callback — this is the CSRF defence, and omitting it
  is a common finding.
- Use PKCE for every public client (mobile, SPA), and increasingly for all
  clients.
- Redirect URIs matched **exactly** against a registered allowlist. No wildcards,
  no prefix matching — open redirect here is account takeover.
- Validate the ID token signature, `iss`, `aud` and `exp`. Do not trust an
  unverified `email` claim to link accounts.
- **Account linking is a takeover risk.** Linking by unverified email lets an
  attacker who registers with a victim's address take over the account. Require
  a verified email, or explicit confirmation while signed in.
- Store provider tokens encrypted; scope them minimally; support revocation.

---

## API keys (service-to-service)

- Generate from a CSPRNG with a recognisable prefix (`sk_live_`, `sk_test_`) so
  secret scanners can detect leaks.
- **Store only a hash.** Show the full key exactly once at creation.
- Scope each key to permissions and, where possible, to source IPs.
- Track `last_used_at` so dormant keys can be found and revoked.
- Support multiple active keys per account so rotation needs no downtime.
- Rate-limit per key; expire or force rotation on a schedule.

---

## Account lifecycle

- **Email verification** before the account can do anything meaningful.
- **Email change** requires the current password and confirmation at *both*
  addresses; notify the old address.
- **Deletion** is a real path — see `privacy-compliance`. Deletion must revoke
  sessions, API keys and OAuth grants.
- **Impersonation** (support logging in as a user) must be explicitly logged,
  time-bounded, consented to where required, and visibly indicated in the UI.
  An unlogged impersonation feature is an audit failure and an insider risk.

---

## Review checklist

- [ ] Modern password hashing at current cost
- [ ] Session id rotated on login and privilege change
- [ ] Sessions invalidated on logout and password change, on all devices
- [ ] Cookies `HttpOnly`, `Secure`, `SameSite`
- [ ] Rate limits on login, registration, reset and MFA
- [ ] No user enumeration in any of those three flows
- [ ] Reset tokens hashed, single-use, short-lived, invalidated on use
- [ ] MFA available; enforced for admins
- [ ] JWT algorithm pinned; `alg: none` rejected; claims validated
- [ ] OAuth `state` and exact redirect URI matching
- [ ] API keys hashed at rest, scoped, revocable, usage-tracked
- [ ] Auth events logged; anomalies alerted
- [ ] Re-authentication required for sensitive actions
