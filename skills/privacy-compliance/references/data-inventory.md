# The Data Inventory

Everything else — the policy, the consent banner, the deletion pipeline, the
breach assessment — is generated from this. Build it from the code, not from an
interview.

---

## Discover it from the code

```bash
# 1. Personal data in the schema
grep -rEni '(email|phone|mobile|address|postcode|zip|birth|dob|ssn|nino|passport|tax_?id|ip_?addr|user_?agent|latitude|longitude|geo|gender|photo|avatar|signature|card|iban)' \
  --include='*.prisma' --include='*.sql' --include='models*.py' --include='schema.rb' \
  --include='*.entity.ts' --include='*Entity.java' . | head -60

# 2. Every third party that receives data
grep -rhoE 'googletagmanager|google-analytics|gtag\(|connect\.facebook\.net|static\.hotjar|cdn\.segment|api\.mixpanel|posthog|widget\.intercom|clarity\.ms|sentry\.io|fonts\.googleapis|js\.stripe|paypal\.com/sdk|recaptcha|youtube\.com/embed|player\.vimeo|cdn\.jsdelivr|unpkg\.com' \
  . --exclude-dir={node_modules,.git,dist,build} | sort -u

# 3. Where personal data enters
grep -rEn 'req\.body|request\.form|@RequestBody|params\.permit|request\.json' \
  --exclude-dir=node_modules . | head -30

# 4. Where it leaves
grep -rEn 'fetch\(|axios\.|requests\.(post|put)|http\.Post|HttpClient' \
  --exclude-dir=node_modules . | grep -iE 'analytics|track|crm|mail|webhook|sync' | head -20

# 5. Where it might be logged
grep -rEn 'console\.log|logger\.(info|debug)|print\(' --exclude-dir=node_modules . \
  | grep -iE 'user|email|body|payload|request' | head -20
```

Item 2 is the highest-yield check in a privacy audit. Compare that list against
the privacy policy: **every third party present in the code and absent from the
policy is a `P1` finding** — it is a misrepresentation to users, not a
documentation gap.

Item 5 finds the other common one: personal data in logs, which are frequently
the least protected copy of your data and are shipped to a third party.

---

## The inventory table

One row per **field**, not per system. Field granularity is what makes the
deletion plan and the breach assessment possible.

| Field | Category | Purpose | Legal basis | Source | Stored where | Processors | Retention | On erasure |
|---|---|---|---|---|---|---|---|---|
| `users.email` | Identifier | Account, notifications | Contract | User | Postgres `users`, Postmark, Stripe | Postmark, Stripe | Account + 30d | Hash |
| `users.name` | Identifier | Personalisation | Contract | User | Postgres `users` | — | Account + 30d | `[deleted]` |
| `users.password_hash` | Credential | Authentication | Contract | User | Postgres `users` | — | Account | Delete |
| `sessions.ip_address` | Online id | Security, fraud | Legitimate interest | Automatic | Postgres `sessions` | — | 90 days | Delete |
| `request_logs.ip` | Online id | Security, debugging | Legitimate interest | Automatic | Log store | Log vendor | 30 days | Null |
| `invoices.billing_address` | Contact | Tax record | **Legal obligation** | User | Postgres, Stripe | Stripe | **7 years** | **Retain** |
| `uploads.*` | User content | Product function | Contract | User | S3 | — | Account + 30d | Delete |
| `analytics.*` | Behavioural | Product analytics | **Consent** | Automatic | PostHog | PostHog | 14 months | Delete via API |

**The columns that do real work:**

- **Legal basis** determines whether you need consent, and whether the user can
  object. Consent-based processing must not happen before consent.
- **Processors** becomes the subprocessor list and the deletion fan-out.
- **Retention** becomes the retention job.
- **On erasure** becomes the erasure plan as code.

---

## Categories, and why the distinction matters

| Category | Examples | Note |
|---|---|---|
| Identifiers | Name, email, phone, account id | The baseline |
| Contact | Address, billing address | |
| Online identifiers | IP, cookie id, device id, advertising id | **These are personal data.** Teams routinely assume they are not |
| Behavioural | Page views, clicks, session recordings | Usually consent-based |
| Content | Uploads, messages, documents | May contain third parties' personal data |
| Financial | Payment method, transactions | Never store card numbers — use a hosted element |
| **Special category** | Health, biometrics, race, religion, politics, sexual orientation, union membership | **Much stricter rules.** Flag loudly. Prefer not to collect at all |
| Children's data | Anything about a minor | Verifiable parental consent regimes apply |

**Two categories that are systematically under-recognised:**

**Online identifiers.** An IP address is personal data under GDPR. So is a
cookie id and a device id. A team that says "we do not collect personal data, only
analytics" is almost always wrong.

**Inferred data.** A segment, a score, a prediction, a "likely to churn" flag
derived from behaviour is personal data too, and it is subject to access and
erasure rights.

---

## Legal basis (GDPR) — choose deliberately

| Basis | Use for | Cannot be used for |
|---|---|---|
| **Consent** | Analytics, marketing, non-essential cookies | Anything the service cannot work without — consent must be freely given |
| **Contract** | Delivering the service the user signed up for | Anything beyond what is necessary to deliver it |
| **Legal obligation** | Tax records, AML, statutory retention | Anything not actually required by law |
| **Legitimate interest** | Fraud prevention, security, basic service analytics | Anything with significant privacy impact without a balancing test |
| Vital interests / Public task | Rare | |

Two rules that matter:

**You cannot switch basis when the first one fails.** Processing under consent
that the user withdraws cannot be continued under "legitimate interest".

**Legitimate interest requires a documented balancing test** — your interest,
the necessity, and why it does not override the individual's rights. One
paragraph, written down.

---

## Data flow map

Alongside the table, draw where data actually goes. It makes the transfer and
processor obligations visible.

```
                        ┌──────────────┐
   Browser ─────────────► Your servers │
   (email, name, IP)    └──────┬───────┘
                               │
        ┌──────────────────────┼────────────────────────┐
        ▼                      ▼                        ▼
   ┌─────────┐           ┌──────────┐             ┌──────────┐
   │ Postgres│           │  Stripe  │             │ Postmark │
   │  (EU)   │           │ (US·SCC) │             │ (US·SCC) │
   │ all PII │           │ email,   │             │ email,   │
   └────┬────┘           │ address  │             │ name     │
        │                └──────────┘             └──────────┘
        ▼
   ┌─────────┐   ┌──────────┐   ┌──────────┐
   │ Backups │   │  Sentry  │   │ PostHog  │
   │  (EU)   │   │ (id only)│   │ (consent)│
   └─────────┘   └──────────┘   └──────────┘
```

**International transfers.** Any flow out of the EEA needs a transfer mechanism
(adequacy decision, Standard Contractual Clauses, or an approved framework).
Mark it on the map. Most major processors publish theirs; you record which one
applies and where the data lands.

---

## Keeping it current

An inventory that is accurate on the day it is written and wrong a month later
is worse than none, because it creates false confidence.

**Tag in the schema**, so the inventory is a query:

```sql
COMMENT ON COLUMN users.email
  IS 'PII: identifier | purpose: account+notifications | basis: contract | retention: account+30d | erase: hash';
```

**Enforce in CI:** a new column on a personal-data table without a classification
comment fails the build. Ten lines of script, and it is the difference between a
living inventory and a stale document.

**A PR template question**, answered in one line:
> Does this change collect new personal data, send existing data somewhere new,
> or change how long anything is kept? If yes, update the inventory and the
> policy in this PR.

**A quarterly review** against the live code, with the greps at the top of this
document.

---

## Minimisation — the control that beats all the others

For every field in the inventory, ask: **what do we do with this?**

If the answer is "nothing yet", "it might be useful", or "the form has always had
it", the field should not exist.

Data you never collected:
- cannot leak in a breach,
- cannot appear in a subject access request,
- does not need a retention rule, a deletion path, a processor agreement, or a
  line in the policy,
- costs nothing to store, secure or audit.

**This is the cheapest compliance available, and it is almost always
under-applied.** Before optimising the deletion pipeline, delete the columns
nobody uses.
