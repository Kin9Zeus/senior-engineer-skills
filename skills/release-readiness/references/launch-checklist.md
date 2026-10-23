# Launch Checklist — with verification commands

Every item has a way to prove it. An unverified tick is a guess.

---

## Blockers — verify these first

```bash
# 1 · Secrets in the repository or its history
git log --all --full-history --name-only -- '*.env' '*.pem' '*.key' | head
git ls-files | grep -E '(^|/)\.env($|\.)' | grep -v example
# Expect: nothing. Any hit → rotate the credential, then purge history.

# 2 · Cross-user data access — the highest-severity check there is
curl -s -H "Cookie: <session of user A>" https://app.example.com/api/invoices/<B's id> -o /dev/null -w '%{http_code}\n'
# Expect: 404 (or 403). A 200 is a NO GO.

# 3 · Backups restored
# There is no command. Ask: "What date was the last restore drill, and what was
# the measured recovery time?" No date → NO GO.

# 4 · Debug mode / information disclosure
curl -sI https://app.example.com | grep -iE 'x-powered-by|server'
curl -s https://app.example.com/api/nonexistent | head -20
# Expect: no version disclosure, no stack trace.

# 5 · Soft 404
curl -o /dev/null -s -w '%{http_code}\n' https://example.com/definitely-not-real-xyz
# Expect: 404. A 200 is a soft 404.

# 6 · robots.txt not blocking the site
curl -s https://example.com/robots.txt | grep -E '^\s*Disallow:\s*/\s*$'
# Expect: nothing.

# 7 · Dependency vulnerabilities — read the real output
npm audit --production --audit-level=high
# (or pip-audit / govulncheck / bundle audit / composer audit)

# 8 · The runtime itself is patched (language, web server, base image)
# No single command. Ask: "Which exact runtime build is SERVING traffic, and is it
# at or above the vendor's latest security release?" Verify the RUNNING build
# (a version route you control, the image digest, the deploy record) — not the
# Dockerfile. An unpatched, actively exploited remote-code-execution flaw → NO GO.
# PHP: bash skills/php-hardening/scripts/php-check.sh .

# 9 · Rotation readiness
# Ask: "If every environment variable on our host leaked tonight, how long to
# rotate them all, and who does it?" No inventory, no runbook, or "days" → fix
# before launch for any system holding customer data or spend-bearing keys.
# bash skills/security-incident-response/scripts/rotation-inventory.sh .
```

---

## Security

| Check | Verify |
|---|---|
| Secret scan clean | `secret-scan.sh` (from `security-hardening/scripts/`) |
| Cross-user access blocked | The authorization matrix test passes |
| Deny-by-default routing | Add a route with no policy; the app refuses to start |
| Password hashing | Read the hashing call; confirm argon2id/scrypt/bcrypt |
| Session invalidated on password change | Change password in one browser; the other session is dead |
| Rate limiting on login | 20 rapid attempts → `429` |
| Security headers | `curl -sSI <url> \| grep -Ei 'strict-transport\|content-security\|x-content-type\|referrer'` |
| CSP without `unsafe-inline` | Read the header value |
| Webhook signature verified | Post an unsigned event → `400`, no state change |
| Upload restrictions | Post a 1GB file and a disguised executable → both rejected |
| CORS is an allowlist | `curl -H 'Origin: https://evil.test' -I <api>` → not reflected |
| Runtime on a patched, supported release | Resolve the running build; compare with the vendor's current security release; no end-of-life branches on the internet |
| Secrets are narrow, restricted and capped | Each production credential: least privilege, network allowlist, spend cap, separate per environment (`cloud-security`) |
| No static cloud keys in CI | Pipeline assumes a role via OIDC; assuming it from the wrong branch fails |
| Rotation rehearsed | A timed drill in the last 6 months; old values proven dead (`security-incident-response`) |
| AI features cannot exfiltrate | No session combines private data + untrusted content + an outbound channel without approval (`ai-security`) |
| Authorised security test done (high-risk systems) | A scoped test or review with findings fixed and retested (`pentest-methodology`) |

## Data

| Check | Verify |
|---|---|
| Backups automated and encrypted | Console/config, plus the last success timestamp |
| **Restore drill performed** | Recorded date within 90 days, with measured RTO |
| PITR available | Provider config |
| Migration reverses tested | `migrate up && migrate down && migrate up` on a clean DB |
| Migration tested at scale | Run against a restored production-sized copy; record duration |
| FKs indexed | The unindexed-FK query in `database-engineering` |
| Timeouts set | `SHOW statement_timeout; SHOW idle_in_transaction_session_timeout;` |
| Tenancy enforced in the DB | Query as another tenant's role → no rows |
| Retention job running | Last successful run timestamp within its window |

## Legal and trust

| Check | Verify |
|---|---|
| Privacy policy accurate | Grep the code for third parties; diff against the policy |
| Consent gates scripts | Private window, DevTools, load, do not interact → no analytics requests |
| Reject actually rejects | Click "Reject all", reload → still no analytics requests |
| Deletion works end to end | Create a user, populate everything, delete, search every store |
| Export excludes other users | Export a user in a shared thread; grep for the other user's email |
| Terms published | Fetch the URL |
| Subprocessor list current | Diff against the code grep |
| Response commitment true | Measure actual first-response time over the last 30 days |

## Public surface

Run `web-presence-audit/scripts/web-check.sh <url>` — it covers most of this
section automatically. Then confirm by hand:

| Check | Verify |
|---|---|
| Unique titles and descriptions | Crawl the sitemap; check for duplicates |
| No page canonicals to the homepage | Fetch several pages; read the canonical |
| Custom 404 with a real status | `curl -w '%{http_code}'` on a bad path |
| OG image reachable and absolute | Fetch the `og:image` URL directly |
| Structured data valid | Rich Results Test on each template |
| Alt text present | Automated scan, then read a sample for meaning |
| Internal links resolve | `npx linkinator <url> --recurse` |
| Sticky CTA does not obscure content | Tab to the last form field on mobile |

## Accessibility

| Check | Verify |
|---|---|
| Automated scan clean | axe on each critical page and each state |
| Keyboard completion | Unplug the mouse; complete signup and checkout |
| Focus always visible | Tab through; watch |
| Focus not obscured | Tab with the sticky header and CTA bar present |
| Screen reader pass | NVDA or VoiceOver on the core journey |
| Contrast in all states | Sample rendered pixels, including hover and disabled |
| 400% zoom | Resize; check for horizontal scroll |

## Correctness

| Check | Verify |
|---|---|
| CI green and blocking | Try to merge a red PR — it should be refused |
| E2E on critical journeys | The run passes in the pre-deploy stage |
| Authorization matrix | The test exists, covers every route, and passes |
| No flakes in the blocking set | Pass rate per test over the last 50 runs |
| Post-deploy smoke test | Run the journeys manually on production after deploy |

## Operations

| Check | Verify |
|---|---|
| Error tracking receiving events | Trigger a deliberate error; confirm it appears with the release tag |
| No personal data in logs | Grep recent logs for `@`, and for token patterns |
| Correlation id end to end | One request; find every log line for it |
| Health vs readiness distinct | Stop the database; `/health` stays 200, `/ready` returns 503 |
| Graceful shutdown | Send `SIGTERM` under load; no dropped requests |
| **Rollback executed** | Do it. On staging at minimum. Record the duration |
| Alert pages a human | Fire a test alert; confirm someone's phone rings |
| External uptime check | Configured against a real user path, not `/health` |
| On-call named | A person, a rotation, a phone number |
| Cost alerts | Budget and anomaly alerts configured |

## Performance

| Check | Verify |
|---|---|
| Core Web Vitals | PageSpeed Insights on key pages; field data if available |
| p95 latency | Dashboard, against a stated budget |
| Load tested | k6/Artillery run at expected peak; name the first bottleneck |
| LCP image not lazy-loaded | Read the markup |
| Caching invalidation stated | Ask "what invalidates this?" — if there is no answer, there is no cache |

---

## The pre-launch baseline

Capture these **before** launch. Without them you cannot tell whether the
post-launch numbers are bad.

```
Error rate (by class)      ____
p50 / p95 / p99 latency    ____
Core Web Vitals (p75)      ____
Conversion on the core journey ____
Database connections at peak ____
Monthly cost               ____
```

---

## Post-launch watch

```
T+0 to T+1h    Someone WATCHES the dashboards. Not "keeps an eye on".
               Error rate, latency, the business metric, database connections.
T+1h           Compare against the baseline. Anything moved? Why?
T+24h          Review. Any alert that should have fired and did not?
T+7d           Retrospective: what did the gate miss? Add it to the gate.
```

**The gate improves by being wrong.** Every incident that the checklist did not
prevent becomes a new line in it. That is the entire mechanism by which a
release process gets better.
