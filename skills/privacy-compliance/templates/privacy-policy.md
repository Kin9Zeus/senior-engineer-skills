<!--
════════════════════════════════════════════════════════════════════════════════
  PRIVACY POLICY TEMPLATE  ·  Devleck Senior Engineer Skills
════════════════════════════════════════════════════════════════════════════════

  HOW TO USE THIS

  1. Build the data inventory FIRST (references/data-inventory.md). Every table
     below is generated from it. Filling this in without the inventory produces
     a document that describes a different product.

  2. Replace every <PLACEHOLDER>. Delete every section that does not apply —
     an inapplicable section is worse than a missing one, because it describes
     processing you do not do.

  3. Cross-check the "Who we share it with" table against the code:

       grep -rhoE 'googletagmanager|google-analytics|gtag\(|connect\.facebook\.net|
         hotjar|segment|mixpanel|posthog|intercom|clarity\.ms|sentry\.io|stripe|
         paypal|fonts\.googleapis|recaptcha' . --exclude-dir={node_modules,.git}

     Anything in that output and not in the table is a P1 finding.

  4. Have a qualified privacy lawyer review it before publishing, especially for
     a regulated sector, children's data, or special-category data.

  NEVER: claim a certification you do not hold · describe processing you do not
  do · promise deletion you cannot perform · state a retention period nothing
  enforces. Each is a misrepresentation and each is what gets checked first.
════════════════════════════════════════════════════════════════════════════════
-->

# Privacy Policy

**Last updated: <YYYY-MM-DD>** · **Version <N>** · [Previous versions](<LINK>)

<COMPANY NAME> ("we", "us") operates <PRODUCT/SITE> at <URL>. This policy
explains what personal data we collect, why, who we share it with, how long we
keep it, and the choices you have.

We have written this in plain language deliberately. If anything is unclear,
email <privacy@DOMAIN> and we will explain it.

**In short**
- We collect the minimum we need to run <PRODUCT>.
- We do not sell your personal data.
- Non-essential cookies load only after you agree.
- You can [download everything we hold about you](<EXPORT LINK>) or
  [delete your account and data](<DELETE LINK>) at any time, yourself.

---

## 1. Who we are

| | |
|---|---|
| **Controller** | <LEGAL ENTITY NAME> |
| **Registered address** | <FULL ADDRESS> |
| **Company number** | <NUMBER, if applicable> |
| **Privacy contact** | <privacy@DOMAIN> |
| **Data Protection Officer** | <NAME / "We are not required to appoint a DPO. Privacy enquiries go to the address above."> |
| **EU/UK representative** | <NAME AND ADDRESS, if you are outside the EU/UK and offer services to people in it> |

---

## 2. What we collect, and why

<!-- Generated from the data inventory. Be SPECIFIC. "Certain information" is
     not a disclosure. Delete rows that do not apply. Add the ones that do. -->

### 2.1 Data you give us

| What | When | Why | Legal basis |
|---|---|---|---|
| Name, email address | When you create an account | To create and secure your account, and to contact you about the service | Performance of a contract |
| Password (stored only as a cryptographic hash — we never see it) | Registration | Authentication | Performance of a contract |
| Billing name, address, country, tax id | When you subscribe | To process payment and issue a legally compliant invoice | Contract; legal obligation |
| Content you upload (<DESCRIBE: files, messages, documents>) | While using <PRODUCT> | To provide the service | Performance of a contract |
| Support messages and attachments | When you contact us | To answer you and improve our support | Contract; legitimate interests |
| Marketing preferences | When you subscribe | To send you what you asked for | Consent |

### 2.2 Data collected automatically

| What | Why | Legal basis |
|---|---|---|
| IP address, browser and device type, operating system | Security, fraud prevention, and diagnosing faults | Legitimate interests |
| Pages visited, features used, timestamps, referring URL | To understand how <PRODUCT> is used and improve it | Consent (analytics cookies) |
| Error reports, including a technical stack trace and your user id | To find and fix faults | Legitimate interests |
| Cookies and similar technologies | See section 6 | See section 6 |

**Note.** An IP address and a cookie identifier are personal data. We treat them
as such.

### 2.3 Data from other sources

| Source | What | Why |
|---|---|---|
| <SSO provider, e.g. Google> | Name, email, profile picture | To let you sign in without a separate password |
| <Payment provider> | Payment status, last four digits of the card, card brand | To manage your subscription |
| <DELETE IF NONE> | | |

### 2.4 What we deliberately do **not** collect

<!-- Optional, and disproportionately effective at building trust. Only include
     what is true. -->

- We do not store card numbers. Payments are handled entirely by <PROVIDER>;
  card details are entered on their systems and never reach ours.
- We do not collect special-category data (health, biometrics, race, religion,
  political opinions, sexual orientation, trade-union membership).
- We do not use session-recording or heatmap tools.
- <PRODUCT> is not intended for children under <AGE> and we do not knowingly
  collect their data.

---

## 3. Who we share it with

<!-- ══════════════════════════════════════════════════════════════════════════
     THE MOST IMPORTANT TABLE IN THIS DOCUMENT.

     Every third party in your code that receives personal data must appear
     here — including analytics, error tracking, fonts, embeds, chat widgets
     and CDNs. A processor present in the code and absent here is a
     misrepresentation to users, not a documentation gap.
     ══════════════════════════════════════════════════════════════════════════ -->

We do **not sell** your personal data, and we do not share it for cross-context
behavioural advertising.

We share it only with the service providers below, only for the purpose stated,
and only under a written data-processing agreement.

| Provider | What they receive | Why | Where | Transfer safeguard | Their policy |
|---|---|---|---|---|---|
| <AWS / hosting> | All data you store with us | To host <PRODUCT> | <REGION> | <— / SCCs> | <LINK> |
| <Stripe> | Name, email, billing address, purchase history | To take payment and issue invoices | <US> | <SCCs> | <LINK> |
| <Postmark> | Name, email | To send account and transactional emails | <US> | <SCCs> | <LINK> |
| <Sentry> | User id, IP address, technical error data | To detect and fix faults | <EU> | <—> | <LINK> |
| <PostHog> | Usage events, IP address, device data | Product analytics — **only if you accept analytics cookies** | <EU> | <—> | <LINK> |
| <Intercom> | Name, email, support conversation | To provide customer support | <US> | <SCCs> | <LINK> |

<!-- Also list, if present in your code: Google Fonts (receives every visitor's
     IP), reCAPTCHA, YouTube/Vimeo embeds, Google Tag Manager, CDNs serving
     scripts, and any AI/LLM API you send user content to. -->

Our current list of sub-processors is maintained at <SUBPROCESSOR PAGE LINK>.
We will notify you at least <30> days before adding a new one.

**We may also disclose personal data:**
- to comply with a legal obligation, court order or lawful request from an
  authority — and we will tell you unless legally prohibited from doing so;
- to establish, exercise or defend legal claims;
- to protect the rights, safety or property of our users or the public;
- to an acquirer, in the event of a merger, acquisition or sale of assets — you
  will be notified, and this policy will continue to apply to data transferred.

---

## 4. International transfers

<DELETE IF ALL PROCESSING IS IN ONE JURISDICTION>

Some of our providers are located outside <YOUR REGION>. Where personal data is
transferred out of the <EEA/UK>, we rely on:

- an **adequacy decision** by the European Commission, where one exists for that
  country; or
- the European Commission's **Standard Contractual Clauses**, together with
  additional technical measures (encryption in transit and at rest, and access
  controls) where the transfer risk assessment requires them.

You can request a copy of the safeguards in place by emailing <privacy@DOMAIN>.

---

## 5. How long we keep it

<!-- Every row must be enforced by an actual job. "As long as necessary" alone
     is not a retention policy. -->

| Data | Retention | Then |
|---|---|---|
| Account data | While your account is active, then **30 days** | Permanently deleted or anonymised |
| Content you upload | While your account is active, then **30 days** | Permanently deleted |
| Session records | **7 days** after expiry | Deleted |
| Server logs containing IP addresses | **90 days** (IP removed after 30) | Deleted |
| Analytics data | **14 months** | Deleted |
| Support conversations | **3 years** after closure | Deleted |
| Invoices and tax records | **<7> years** | Required by <TAX LAW>. Retained even after account deletion, with personal details minimised |
| Marketing consent records | Until you withdraw, then **3 years** | Kept as proof that consent was withdrawn |
| Backups | **30 days** | Automatically destroyed |

---

## 6. Cookies and similar technologies

We use cookies and similar technologies (local storage, pixels). **Nothing other
than strictly necessary cookies is loaded until you agree.**

| Category | What it does | Consent needed |
|---|---|---|
| **Strictly necessary** | Keeps you signed in, secures forms, remembers your cookie choice | No — the service cannot work without these |
| **Functional** | Remembers your language and display preferences | Yes |
| **Analytics** | Helps us understand which features are used | Yes |
| **Marketing** | <Measures advertising / DELETE IF NONE> | Yes |

You can change your choice at any time at <COOKIE SETTINGS LINK>. Rejecting is
as easy as accepting, and rejecting will not restrict access to <PRODUCT>.

The full list of cookies, with names and durations, is at <COOKIE POLICY LINK>.

---

## 7. Your rights

<!-- These are GDPR rights. Adjust for your jurisdictions; CCPA/CPRA equivalents
     are noted in section 12. -->

You have the right to:

| Right | What it means | How to use it |
|---|---|---|
| **Access** | Get a copy of the personal data we hold about you | [Download your data](<EXPORT LINK>) — instant, self-service |
| **Rectification** | Correct anything inaccurate | [Account settings](<SETTINGS LINK>), or email us |
| **Erasure** | Have your data deleted | [Delete your account](<DELETE LINK>) — self-service. See section 8 |
| **Portability** | Receive your data in a machine-readable format | [Download your data](<EXPORT LINK>) — provided as JSON |
| **Restriction** | Ask us to pause processing while a dispute is resolved | <privacy@DOMAIN> |
| **Objection** | Object to processing based on legitimate interests | <privacy@DOMAIN> |
| **Withdraw consent** | Withdraw consent at any time, without affecting what happened before | [Cookie settings](<COOKIE LINK>); marketing: the unsubscribe link in any email |
| **Complain** | Complain to a supervisory authority | See section 11 |

We respond to requests **within one month**. If a request is complex we may
extend this by two further months, and we will tell you why within the first
month. Exercising your rights is free.

We may ask you to verify your identity before acting on a request. This protects
you: without verification, someone else could request your data or delete your
account.

---

## 8. Deleting your data

<!-- Describe what your pipeline ACTUALLY does. Do not promise more. -->

You can delete your account and your data yourself, at any time:

**<SETTINGS LINK> → Privacy & data → Delete my account**

**What happens:**

1. We ask you to confirm — by re-entering your password, or by clicking a link
   we email you.
2. Your account is **suspended immediately** and becomes inaccessible.
3. After a **<30>-day grace period** — during which you can cancel and restore
   the account by contacting us — deletion runs automatically.
4. Deletion removes your data from our database, our file storage, our caches,
   our search index, and it is propagated to the providers listed in section 3
   through their own deletion interfaces.
5. We verify that the deletion completed and send you a confirmation.

**What we keep, and why:**

| Kept | Why | For how long |
|---|---|---|
| Invoices and payment records | Required by <TAX LAW> | <7> years, with personal details minimised |
| A record that a deletion request was made and completed | To demonstrate we honoured it | <3> years — contains no personal data beyond a one-way hash |
| Anonymised usage statistics | Aggregate data that can no longer identify you | Indefinitely |

**Backups.** Our backups are retained for **30 days** and are then permanently
destroyed. It is not technically possible to remove an individual record from an
encrypted backup archive without restoring it. Access to backups is restricted
and logged, and if a backup is ever restored, completed deletion requests are
automatically re-applied to it before it returns to service.

If you do not have an account but believe we hold data about you, email
<privacy@DOMAIN> and we will handle your request the same way.

---

## 9. How we protect your data

We take the following measures. This is a summary, not an exhaustive list, and
no system can be guaranteed completely secure.

- Encryption in transit (TLS) and at rest.
- Passwords stored only as salted cryptographic hashes; we cannot read them.
- Access to production systems restricted to staff who need it, protected by
  multi-factor authentication, and logged.
- Automated dependency and vulnerability monitoring.
- <Regular penetration testing / security review — DELETE IF NOT TRUE>.
- An incident response process with defined notification timelines.

<!-- Do not claim SOC 2, ISO 27001 or any certification unless you actually hold
     a current one. A false claim is a misrepresentation and is easily checked. -->

**If a breach occurs** that is likely to result in a risk to your rights, we
will notify the relevant supervisory authority within **72 hours** of becoming
aware, and we will notify you directly and without undue delay where the risk to
you is high.

---

## 10. Children

<PRODUCT> is not intended for people under <AGE>, and we do not knowingly
collect their personal data. If you believe a child has provided us with
personal data, contact <privacy@DOMAIN> and we will delete it promptly.

---

## 11. Complaints

If you are unhappy with how we handle your data, please contact us first at
<privacy@DOMAIN> — we would like the chance to put it right.

You also have the right to complain to a data protection authority:

- **EU** — the supervisory authority in your country of residence, place of
  work, or where the issue occurred.
- **UK** — the Information Commissioner's Office, <ico.org.uk>.
- **<OTHER JURISDICTION>** — <AUTHORITY AND LINK>.

---

## 12. Regional information

<!-- Include only what applies to you. Delete the rest. -->

### California residents (CCPA/CPRA)

In the past 12 months we collected the categories of personal information
described in section 2: identifiers, commercial information, internet activity,
and geolocation inferred from IP address. The sources, purposes and recipients
are set out in sections 2 and 3.

**We do not sell your personal information, and we do not share it for
cross-context behavioural advertising.** Because we do not, we do not offer a
"Do Not Sell or Share My Personal Information" link — but if that changes, this
policy will be updated and the link provided.

You have the right to know, delete, correct, and to opt out of sale or sharing,
and not to be discriminated against for exercising those rights. Use the
self-service links in section 7, or email <privacy@DOMAIN>. You may use an
authorised agent. We honour the **Global Privacy Control** signal.

### Brazil (LGPD) · <OTHER>

<Add equivalent sections where applicable, or delete.>

---

## 13. Changes to this policy

We will update this policy when our practices change. The version and date are
at the top, and previous versions are archived at <LINK>.

For **material** changes — a new purpose, a new category of data, or a new
recipient — we will notify you by email and, where the change relies on consent,
we will ask for your consent again before it takes effect.

---

## 14. Contact

| | |
|---|---|
| **Privacy** | <privacy@DOMAIN> |
| **Post** | <LEGAL ENTITY, FULL ADDRESS> |
| **Security disclosures** | <security@DOMAIN> · <URL>/.well-known/security.txt |
| **Response commitment** | We reply to privacy enquiries within <2 business days> and complete requests within one month |

---

<!--
  AUDIT CHECKLIST before publishing
  ─────────────────────────────────
  [ ] Every placeholder replaced; every inapplicable section deleted
  [ ] Section 3 cross-checked against the code (grep at the top of this file)
  [ ] Every retention period in section 5 is enforced by a real, monitored job
  [ ] The deletion flow in section 8 matches what the pipeline actually does
  [ ] The self-service links work, and are reachable in ≤3 clicks in-product
  [ ] Section 9 claims nothing untrue — no unearned certifications
  [ ] Cookie banner tested in a private window: nothing loads before consent
  [ ] Linked from the footer of every page, and from signup and checkout
  [ ] Reviewed by a qualified privacy lawyer
  [ ] A calendar reminder exists for the annual review
-->
