# Privacy Governance

The operational layer. Not legal advice — these are the artefacts and processes
an engineering team owns, and the ones an auditor or an enterprise buyer will
ask for.

---

## Processors and DPAs

Every third party that processes personal data on your behalf is a **processor**,
and the relationship needs a Data Processing Agreement. Most publish a standard
one you accept online; a few require signature.

**Who counts as a processor:** cloud hosting, database hosting, email delivery,
analytics, error tracking, session recording, customer support tools, CRM,
payment processing, CDN, search, SMS, and any AI/LLM API you send user content
to.

**Who is usually a separate controller, not a processor:** payment networks and
some advertising platforms, which determine their own purposes. The distinction
changes the paperwork; identify it rather than assuming.

**The register to maintain:**

| Processor | Purpose | Data | Location | Transfer basis | DPA | Reviewed |
|---|---|---|---|---|---|---|
| AWS | Hosting | All | eu-west-1 | — (EU) | ✓ link | 2026-01 |
| Stripe | Payments | Email, name, address | US | SCCs | ✓ link | 2026-01 |
| Postmark | Transactional email | Email, name | US | SCCs | ✓ link | 2026-01 |
| Sentry | Error tracking | User id, IP | EU | — | ✓ link | 2026-01 |
| PostHog | Analytics | Behavioural, IP | EU | — | ✓ link | 2026-01 |

**Publish it** as a subprocessor page. Enterprise buyers require it, and it is
what your privacy policy's "third parties" section should be generated from.
Notify customers of changes — enterprise contracts typically require 30 days'
notice and a right to object.

**Sub-processors of processors** count too. Your hosting provider's own
sub-processors are in your chain, which is why their published list matters.

**Review annually**, and whenever a processor is added. The most common finding
is a processor added by an engineer during a sprint that never reached the
register or the policy.

---

## Retention, enforced

A retention period nothing enforces is a statement, not a policy.

```
Category                 Period                      Enforced by
─────────────────────────────────────────────────────────────────────
Account data             Account life + 30 days      Erasure pipeline
Session records          7 days after expiry         Daily job
Request logs (with IP)   90 days, IP nulled at 30    Daily job
Analytics                14 months                   Provider config + job
Support tickets          3 years after closure       Monthly job
Invoices / tax records   7 years                     Retained; then anonymised
Marketing consent        Until withdrawn + 3 years   On withdrawal + job
Backups                  30 days                     Backup policy
Audit logs               2 years                     Monthly job
Job application data     6-12 months                 Monthly job
```

Requirements: **batched and throttled** (see `database-engineering`),
**monitored** (a job that silently stopped is a finding and a bill), and
**covering every store** — deleting a row is not enough if the file, the cache
entry and the search document survive.

---

## Breach response

Written before you need it. Under GDPR the clock is **72 hours from becoming
aware**, which is not 72 hours from being certain.

```
0h    DETECT & CONTAIN
      Stop the exposure. Preserve evidence — do not wipe the compromised host.
      Declare an incident; assign a lead. Start the clock and record the time
      you became aware.

0-24h ASSESS
      What data, whose, how many, how, since when, still ongoing?
      Is it likely to result in a risk to the individuals?
      Document the reasoning either way — "we assessed and concluded low risk"
      is a defensible position; silence is not.

<72h  NOTIFY THE AUTHORITY (if risk is likely)
      Nature of the breach, categories and approximate numbers, likely
      consequences, measures taken and proposed, DPO/contact.
      A partial notification on time beats a complete one late — you may
      supplement in phases.

ASAP  NOTIFY INDIVIDUALS (if HIGH risk is likely)
      Plain language: what happened, what data, what it means for them, what you
      are doing, what they should do, who to contact.
      No jargon, no minimising, no burying it in a status update.

AFTER REMEDIATE & LEARN
      Root cause, blameless postmortem, owned and dated action items,
      register entry.
```

**Maintain a breach register** — every incident, including those you assessed as
not notifiable, with the reasoning. Regulators ask for it, and "we considered it
and here is why" is a far stronger position than an undocumented judgement call.

**Decide in advance who decides.** The most damaging delay in a real breach is
the hours spent working out who has the authority to notify.

---

## Privacy by design in the workflow

Two questions in the pull request template, answered in one line each:

```markdown
### Privacy
- [ ] Does this collect new personal data, send data somewhere new, or change
      retention? If yes → inventory, policy and processor register updated in
      this PR.
- [ ] Is any new personal data logged, sent to the error tracker, or included in
      an analytics event?
```

Then a lightweight review — a **DPIA** (Data Protection Impact Assessment) — for
anything higher risk: large-scale processing, special-category data, systematic
monitoring, automated decisions with significant effect, children's data, new
technology, or combining datasets.

A DPIA is not a bureaucratic form. It is: what are we doing, why is it
necessary, what is the risk to people, and what are we doing to reduce it —
written down, with a decision. Two pages is often enough. It also happens to be
excellent design review.

---

## Roles

- **Who owns privacy?** A named person, even in a small team. Unowned means
  unmaintained.
- **A DPO is required** in specific cases (public authority; large-scale
  systematic monitoring; large-scale special-category processing). Most small
  products do not need one — but they still need a named owner and a published
  contact address.
- **`privacy@yourdomain`**, monitored, published in the policy. An unmonitored
  privacy contact turns a routine request into a missed statutory deadline.
- **Training**, proportionate: engineers should know not to log personal data,
  not to copy production data to a laptop, and to escalate anything that looks
  like a breach immediately rather than investigating quietly first.

---

## Vendor and AI-feature review

Before sending personal data to any new service, including an LLM API:

- [ ] Is there a DPA?
- [ ] Where does the data physically go, and under what transfer mechanism?
- [ ] What is their retention? Can you configure it to zero?
- [ ] **Is your data used to train their models?** If yes, that is a disclosure
      obligation and usually a decision you should not make by default.
- [ ] Do they have a deletion API you can call from your erasure pipeline?
- [ ] What is their security posture and breach-notification commitment?
- [ ] What happens to the data if they are acquired or shut down?

**For AI features specifically:** sending user content to a third-party model is
a data transfer to a processor. It needs a lawful basis, a DPA, disclosure in the
privacy policy, and a retention answer. Many providers offer a zero-retention or
no-training configuration — use it, and record that you did.

---

## The annual review

Once a year, deliberately, with the greps from `data-inventory.md`:

- [ ] Inventory matches the code
- [ ] Policy matches the inventory; every processor in the code is named
- [ ] Processor register current; DPAs still in force
- [ ] Retention jobs ran, every window, all year
- [ ] Deletion pipeline tested end to end
- [ ] Consent mechanism re-tested in a private window
- [ ] Breach plan current; contacts still work; roles still exist
- [ ] Access to personal data reviewed — who has it, do they still need it?
- [ ] Non-production environments still free of production personal data
- [ ] Policy version and "last updated" date accurate

Put it in the calendar with an owner. Privacy compliance decays silently — the
failure mode is never a dramatic breach, it is a policy that stopped describing
the product eighteen months ago.
