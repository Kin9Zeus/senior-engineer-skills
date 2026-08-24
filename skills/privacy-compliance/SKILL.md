---
name: privacy-compliance
description: Privacy engineering and compliance — building a data inventory from the actual code, generating a privacy policy that matches real data flows and names every third-party processor, cookie consent that genuinely gates scripts, and an automated self-service data export and deletion pipeline (DSAR / right to erasure) covering every store and processor. Use when the user says "privacy policy", "GDPR", "CCPA", "CPRA", "LGPD", "cookies", "cookie banner", "consent", "delete my data", "right to be forgotten", "DSAR", "data subject request", "data retention", "PII", "personal data", "terms of service", "compliance" or "what data do we collect"; whenever a project handles user accounts, analytics, email addresses or payments; and as a mandatory pass in any project audit. By Devleck.
license: MIT
---

# Privacy and Compliance Engineering

Almost every product processes personal data — an email address is personal
data. The engineering obligations that follow are concrete, buildable, and far
cheaper to build in than to retrofit.

**Scope note.** This skill produces the *technical* controls and a policy drafted
from real data flows. It is not legal advice. For a regulated sector, a
high-risk processing activity, or a live regulatory enquiry, the recommendation
is to have a qualified privacy lawyer review the output. Say this plainly to the
user; do not let it stop you from building the controls, which are the same
either way.

---

## The order of work

Every artefact depends on the one above it. Drafting a privacy policy before the
inventory means describing a system you have not read.

```
1. DATA INVENTORY   →  what is actually collected, from the code
2. POLICY           →  a document generated from that inventory
3. CONSENT          →  a mechanism that genuinely gates the scripts
4. RIGHTS PIPELINE  →  export and deletion, automated end to end
5. GOVERNANCE       →  DPAs, retention, breach plan, ongoing review
```

---

## 1. Build the data inventory from the code

Never from a form, an interview, or a template. From the schema, the routes and
the third-party integrations. What a team believes it collects and what it
collects are routinely different.

```bash
# Personal data in the schema
grep -rEni '(email|phone|address|birth|dob|ssn|passport|ip_?addr|location|lat|lng|gender|name)' \
  --include='*.prisma' --include='*.sql' --include='models*.py' --include='schema.rb' . | head -40

# Every third party that receives data — SDKs, tags, pixels, fonts, embeds
grep -rhoE 'googletagmanager|google-analytics|gtag\(|connect\.facebook\.net|hotjar|segment|mixpanel|posthog|intercom|clarity\.ms|sentry\.io|stripe|paypal|fonts\.googleapis|recaptcha|youtube\.com/embed|player\.vimeo|cdn\.jsdelivr' \
  . --exclude-dir={node_modules,.git,dist} | sort -u

# Where data enters
grep -rEn 'req\.body|request\.form|@RequestBody|params\.permit' --exclude-dir=node_modules . | head -30
```

Then, per field: **what, why, on what basis, for how long, who else gets it, and
what happens on an erasure request.**

Tag it in the schema so the inventory stays current rather than going stale in
month two — see `database-engineering/references/data-lifecycle.md`:

```sql
COMMENT ON COLUMN users.email
  IS 'PII: identifier | purpose: account+notifications | basis: contract | retention: account+30d | erase: hash';
```

**The most common finding in a real privacy audit** is a third party receiving
personal data that the policy does not name — an analytics tag, a session
recorder, a font CDN (which receives every visitor's IP), a chat widget. Compare
the grep output above against the policy. Every discrepancy is a `P1`: it is a
misrepresentation to users, not merely a documentation gap.

`references/data-inventory.md` has the full template.

---

## 2. The privacy policy, generated from the inventory

A policy copied from a generator describes a different product. It names
processors you do not use and omits the three you do.

**What it must contain**

| Section | Requirement |
|---|---|
| Identity | Who the controller is, with a real address and contact |
| **What is collected** | Every category, **specifically** — not "certain information" |
| Why | The purpose per category |
| Legal basis | Per purpose (GDPR): consent, contract, legal obligation, legitimate interest |
| **Third parties** | **Every processor by name**, what they receive, why, and where they are |
| International transfers | Where data goes and under what mechanism |
| Retention | Per category, as a period or a rule — never "as long as necessary" alone |
| **Rights** | Access, rectify, erase, port, restrict, object, withdraw consent — and **how to exercise each** |
| **How to delete** | A direct link to the self-service path |
| Cookies | Or a link to a separate cookie policy |
| Children | Whether the service is for children, and how age is handled |
| Automated decisions | If any decision with legal or significant effect is automated |
| Security | Honest and general — never a specific claim you cannot back |
| Changes | How users are notified |
| Complaints | The supervisory authority, for EU/UK users |
| **Last updated** | A real date |

**Write it in plain language.** Several regimes require it, and it is what makes
the document useful rather than defensive. A policy nobody can read is a policy
nobody consented to meaningfully.

**Never**: claim a certification you do not hold; describe processing you do not
do; promise deletion you cannot perform; or state a retention period nothing
enforces. Each is a misrepresentation, and each is what a regulator checks first.

Templates: `templates/privacy-policy.md` (EN) and `templates/privacy-policy.es.md` (ES).

---

## 3. Cookie consent that actually works

**The single most common failure:** the banner appears, and the analytics and
advertising scripts have already loaded and set cookies. That is not consent —
it is a notification after the fact, and it is the easiest violation to detect.

```
Requirements
├── Non-essential scripts DO NOT EXECUTE before consent
├── "Reject all" is as prominent and as easy as "Accept all"
├── Granular by category: necessary · functional · analytics · marketing
├── Pre-ticked boxes are not consent — everything non-essential defaults to off
├── Withdrawing is as easy as giving (a persistent link, not a buried setting)
├── The choice is recorded with a timestamp and the policy version
└── No cookie wall for essential functionality
```

**Test it — this is the check that finds the violation:**

```
1. Open a private window, DevTools → Application → Cookies, Network tab
2. Load the page. DO NOT interact with the banner.
3. Any non-essential cookie set? Any analytics/ads request fired?  → violation
4. Click "Reject all". Reload. Same check.                          → violation if any fire
```

**Implementation**: gate the injection, not the execution.

```html
<!-- Not loaded. A type the browser will not execute. -->
<script type="text/plain" data-consent="analytics" src="https://.../analytics.js"></script>
```
```js
function grant(category) {
  document.querySelectorAll(`script[data-consent="${category}"]`).forEach((old) => {
    const s = document.createElement("script");
    for (const { name, value } of old.attributes) {
      if (name !== "type" && name !== "data-consent") s.setAttribute(name, value);
    }
    s.type = "text/javascript";
    old.replaceWith(s);
  });
}
```

`references/cookie-consent.md` covers categorisation, tag managers, server-side
enforcement and the audit procedure.

---

## 4. The rights pipeline — export and deletion

The user asked for this to be **as automated as possible**, and that is also the
correct engineering answer: a manual process is slow, error-prone, unauditable
and does not scale past a handful of requests.

### Deletion, end to end

```
1. REQUEST    In-product, self-service, reachable in ≤ 3 clicks from settings
2. VERIFY     Re-authenticate, or confirm by email link.
              Never delete on an unverified request — that is a denial-of-service vector
3. GRACE      7-30 day reversible window. Account suspended and inaccessible
4. EXECUTE    Run the erasure plan across EVERY store:
                a. application database   (per-field strategy)
                b. object storage         (uploads, avatars, exports)
                c. caches and search indexes
                d. queues and in-flight jobs
                e. logs and analytics
                f. EVERY third-party processor, via their deletion API
                g. email and marketing platforms
5. VERIFY     Re-query every store for the identifier; assert absent
6. RECORD     Audit entry: who, when, which stores, which processors confirmed
7. NOTIFY     Confirm to the user within the statutory deadline (GDPR: one month)
8. BACKUPS    Age out on their normal cycle. Document this honestly, and replay
              the deletion if a backup is ever restored
```

**Step 4f is the one that gets skipped.** Every processor that received the data
must delete it too, and most have an API for it. Deletion that stops at your own
database is a partial deletion you told the user was complete.

**Step 8 is the honest one.** You cannot surgically remove one person from an
encrypted backup archive. The defensible position — and the one regulators
accept — is: backups age out on a defined, bounded cycle; access is restricted;
and the deletion queue is replayed against any restored backup. Document exactly
that, rather than claiming total erasure.

**Per-field strategy, not one operation.** Some rows are deleted, some are
anonymised (keep the order for revenue reporting, sever the identity), some are
retained under a legal obligation with the reason and the expiry recorded. See
`database-engineering/references/data-lifecycle.md` for the erasure plan as code,
and the test that fails when a new unclassified table appears.

### Export (portability)

Same inventory, same pipeline, so build them together.

- Machine-readable (JSON or CSV), structured and documented.
- Everything **about** the subject — not everything they can see. One user's
  export must not contain another user's personal data. A shared conversation
  export is the classic mistake.
- Generated asynchronously; delivered by an authenticated, expiring link. Never
  a public URL, never an email attachment.
- **The export file is itself personal data**: encrypted at rest, short
  retention, access logged.
- Rate-limited — export generation is expensive and is an abuse vector.

`references/rights-pipeline.md` has the implementation, endpoints and tests.

---

## 5. Governance

- **A Data Processing Agreement with every processor.** Most publish one; you
  accept it. No DPA means no lawful basis for that transfer.
- **A public subprocessor list**, kept current, with a notification mechanism for
  changes. Enterprise buyers require it.
- **Retention enforced by a job**, not by intention. Monitored — a retention job
  that silently stopped three months ago is a finding and a storage bill.
- **A breach response plan** with a 72-hour clock (GDPR: notify the supervisory
  authority within 72 hours of becoming aware). Written before you need it,
  naming who decides and who notifies.
- **Data minimisation as the primary control.** The cheapest compliance is data
  you never collected. For every field: what do we do with this? "Nothing yet"
  means it should not exist.
- **Privacy by design** on new features: a two-minute review question in the PR
  template — does this collect new personal data, send it anywhere new, or
  change retention?
- **Non-production environments hold no production personal data.** See
  `devops-platform`.

---

## Regional quick map

Do not opine on legal specifics. Do flag applicability and build the controls.

| Regime | Applies when | Distinctive engineering requirement |
|---|---|---|
| **GDPR** (EU/EEA) | Any EU/EEA data subject | Lawful basis per purpose; DSAR within one month; 72-hour breach notification; consent before non-essential cookies; DPO if large-scale sensitive processing |
| **UK GDPR** | UK data subjects | Substantially aligned with GDPR |
| **CCPA / CPRA** (California) | Thresholds on revenue or data volume | "Do Not Sell or Share My Personal Information" link; opt-out signal (GPC) honoured; deletion and access rights |
| **LGPD** (Brazil) | Brazilian data subjects | Similar structure to GDPR |
| **PIPEDA** (Canada), **APP** (Australia), **POPIA** (South Africa), **PDPA** (Singapore) | Regional | Consent, access, correction, breach notification |
| **HIPAA** (US health) | Protected health information | BAAs, audit logging, encryption, minimum-necessary access |
| **COPPA** (US, under 13) | Children | Verifiable parental consent; no behavioural advertising |
| **PCI DSS** | Card data touches your systems | **Avoid scope entirely** with a hosted payment element |

**The universal engineering answer is the same across all of them:** know what
you hold, minimise it, secure it, be honest about it, and be able to delete it.
Build that, and regional variation becomes configuration rather than
architecture.

---

## Audit checklist

- [ ] A data inventory exists and matches the code
- [ ] Every third party in the code appears in the policy
- [ ] The policy is specific, plain-language, dated, and describes *this* product
- [ ] Legal basis stated per purpose
- [ ] Retention stated per category and **enforced by a monitored job**
- [ ] Cookie banner **gates scripts before consent** (tested in a private window)
- [ ] Reject is as easy as accept; nothing non-essential is pre-ticked
- [ ] Consent recorded with timestamp and policy version; withdrawal is easy
- [ ] **Self-service deletion exists**, reachable in ≤ 3 clicks
- [ ] Deletion reaches storage, caches, search, logs and **every processor**
- [ ] Deletion is verified and recorded in an audit trail
- [ ] Export is scoped to the subject and delivered securely
- [ ] The backup position is documented and defensible
- [ ] DPAs in place; subprocessor list published
- [ ] Breach plan written, with a named decision-maker
- [ ] No production personal data in non-production environments
- [ ] Personal data is not in logs or error-tracker payloads

## References and templates

- `references/data-inventory.md` — building and maintaining the inventory
- `references/cookie-consent.md` — implementation, categories, tag managers, testing
- `references/rights-pipeline.md` — export and deletion, endpoints, jobs, tests
- `references/governance.md` — DPAs, subprocessors, breach response, DPIAs
- `templates/privacy-policy.md` — English, annotated
- `templates/privacy-policy.es.md` — Spanish, annotated
- `templates/cookie-policy.md` · `templates/subprocessors.md` · `templates/deletion-request-flow.md`
