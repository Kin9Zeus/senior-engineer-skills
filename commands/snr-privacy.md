---
description: Build the privacy pack — data inventory from the code, an accurate privacy policy, working cookie consent, and an automated self-service deletion pipeline.
argument-hint: "[path] [--policy | --deletion | --cookies | --audit]"
---

# Privacy and Compliance Pack

Scope: **$ARGUMENTS** (default: the whole project, all four artefacts).

Load `privacy-compliance`. Load `database-engineering` for the erasure plan and
retention jobs.

**Say once, plainly:** this produces technical controls and a policy drafted
from real data flows. It is not legal advice. For a regulated sector, children's
data, or special-category data, recommend a qualified privacy lawyer review the
output — then build the controls anyway, because they are the same either way.

## The order is fixed

Each artefact depends on the one above it. Drafting a policy before the
inventory means describing a system you have not read.

```
1 DATA INVENTORY   from the CODE — schema, routes, third parties
2 POLICY           generated from the inventory
3 CONSENT          a mechanism that genuinely gates the scripts
4 RIGHTS PIPELINE  export and deletion, automated end to end
5 GOVERNANCE       DPAs, subprocessor list, retention jobs, breach plan
```

## 1 · The inventory — from the code, never from an interview

```bash
# Personal data in the schema
grep -rEni '(email|phone|address|birth|dob|ssn|passport|ip_?addr|location|gender|name)' \
  --include='*.prisma' --include='*.sql' --include='models*.py' --include='schema.rb' . | head -40

# EVERY third party that receives data — the highest-yield check in a privacy audit
grep -rhoE 'googletagmanager|google-analytics|gtag\(|connect\.facebook\.net|hotjar|segment|mixpanel|posthog|intercom|clarity\.ms|sentry\.io|stripe|paypal|fonts\.googleapis|recaptcha|youtube\.com/embed' \
  . --exclude-dir={node_modules,.git,dist} | sort -u
```

**Every third party present in the code and absent from the policy is a `P1`.**
It is a misrepresentation to users, not a documentation gap. Note that a font CDN
receives every visitor's IP address.

Then tag the schema so the inventory stays current rather than going stale in
month two.

## 2 · The policy

Use `templates/privacy-policy.md` (EN) or `templates/privacy-policy.es.md` (ES).
Fill it **from the inventory**, delete every inapplicable section, and never:
claim a certification you do not hold, describe processing you do not do,
promise deletion you cannot perform, or state a retention period nothing
enforces.

## 3 · Consent — test it, do not assume it

The most common failure: the banner appears after the analytics scripts have
already loaded and set cookies.

```
1. Private window, DevTools → Application → Cookies, and Network
2. Load the page. DO NOT interact with the banner.
3. Any non-essential cookie set, or any analytics/ads request?  → VIOLATION
4. Click "Reject all", reload, check again.                     → VIOLATION if any fire
5. Click "Accept", confirm scripts NOW load.                    → else it is decorative
```

Also: is "Reject all" as prominent as "Accept all"? Anything non-essential
pre-ticked? Is withdrawal as easy as granting?

## 4 · The deletion pipeline — the user's explicit requirement

Build it as automation, not a mailbox. Use
`templates/deletion-request-flow.md`.

```
REQUEST (self-service, ≤3 clicks) → VERIFY (re-auth) → GRACE (7-30 days)
  → EXECUTE across EVERY store:
      database · object storage · caches · search index · queues · logs
      · analytics · email platform · EVERY THIRD-PARTY PROCESSOR
  → VERIFY by re-querying → RECORD in an audit trail → NOTIFY the user
```

**The processor fan-out is the step that gets skipped.** Deletion that stops at
your own database is a partial deletion you told the user was complete.

**Be honest about backups.** You cannot surgically remove one person from an
encrypted archive. State the retention period, restrict access, and replay
completed deletions against any restored backup. A documented, bounded position
is defensible; a vague claim of total erasure is not.

Ship the **erasure plan as code**, plus the test that fails when a new
unclassified table is added. That test is what keeps the plan honest as the
schema grows.

## 5 · Governance

Subprocessor page (`templates/subprocessors.md`), DPAs, retention jobs that are
monitored, and a breach plan with a named decision-maker and a 72-hour clock.

## Deliverables

- `docs/data-inventory.md`
- `PRIVACY.md` / the policy page (and the Spanish version if the product is
  Spanish-facing)
- `COOKIES.md` / the cookie policy with a table generated from a real scan
- The consent implementation, with the gating verified
- The deletion and export endpoints, jobs and tests
- `docs/subprocessors.md`
- A findings list for anything that could not be built without a decision from
  the user
