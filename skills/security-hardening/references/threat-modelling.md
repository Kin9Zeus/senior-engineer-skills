# Threat Modelling — the 30-minute pass

A threat model that fits on one page and gets done beats a thorough one that
never happens. Run this for a new system, and for any feature touching auth,
money, personal data, file handling, or a new external integration.

Four questions.

---

## 1. What are we building?

Draw the data flow. Boxes for components, arrows for data, and **dotted lines
where trust changes**. Trust boundaries are where attacks happen; everything
inside one boundary is equally trusted, so that is where you stop worrying and
start assuming.

```
        ┌──────────── untrusted ────────────┐
        │   Browser / mobile / third party  │
        └──────────────┬────────────────────┘
     ═══════════════════╪═══════ TRUST BOUNDARY ═══════
                        ▼
                  ┌──────────┐        ┌──────────────┐
                  │   CDN    │        │ Payment API  │
                  │  / WAF   │◄──────►│ (3rd party)  │
                  └────┬─────┘        └──────────────┘
                       ▼
                  ┌──────────┐
                  │   App    │──────► Object storage
                  └────┬─────┘
     ═══════════════════╪═══════ TRUST BOUNDARY ═══════
                        ▼
                  ┌──────────┐        ┌──────────────┐
                  │ Database │        │    Queue     │
                  └──────────┘        └──────────────┘
```

Then list, explicitly:

- **Entry points** — every route, webhook, queue consumer, upload, scheduled job
  reading external data, CLI, admin panel.
- **Assets** — what an attacker wants: credentials, personal data, money,
  compute, reputation, availability.
- **Actors** — anonymous, authenticated user, other tenant, employee, admin,
  compromised third party, insider.

---

## 2. What can go wrong?

Walk **STRIDE** across each trust boundary. One or two concrete threats per
letter is enough; the value is in the prompt, not in exhaustiveness.

| | Threat | Ask |
|---|---|---|
| **S** | Spoofing | Can someone claim to be another user, service or webhook sender? |
| **T** | Tampering | Can data be modified in transit, at rest, or in a client-controlled field? |
| **R** | Repudiation | Could someone deny an action because nothing logged it? |
| **I** | Information disclosure | What leaks — through responses, errors, logs, timing, URLs, or another tenant's view? |
| **D** | Denial of service | What is unbounded — uploads, pagination, regex, queries, spend? |
| **E** | Elevation of privilege | Can a user become an admin, reach another tenant, or run code? |

**Prompts that reliably surface real threats:**

- What happens if this request is replayed? Sent twice concurrently?
- What if the id in this URL belongs to someone else?
- What if this field is negative, enormous, empty, or the wrong type?
- What if the third party is compromised, slow, or returns a hostile payload?
- What if the user is an employee acting maliciously?
- What does an error message tell an attacker that a success does not?
- What is logged, and who can read the logs?
- What happens between the check and the use?

---

## 3. What are we doing about it?

For each threat, one of four responses. Naming which is the point — an accepted
risk that was decided is different from one that was overlooked.

| Response | Meaning |
|---|---|
| **Mitigate** | Add a control |
| **Eliminate** | Remove the feature or the data. The cheapest and most underused option |
| **Transfer** | Push it to a provider (hosted payment element, managed auth) |
| **Accept** | Document the decision, the reasoning, and who accepted it |

**Elimination deserves more consideration than it gets.** Do not store the card
number. Do not collect the birth date you never use. Do not accept the file
upload if a URL would do. Data you never held cannot leak, cannot be
subpoenaed, and does not appear in a breach notification.

---

## 4. Did we do a good job?

Every mitigation gets a **test**, or it is a hope.

| Threat | Control | Test |
|---|---|---|
| User reads another's invoice | Query scoped by tenant; RLS | Authenticate as A, request B's invoice, expect 404 |
| Forged payment webhook | Signature verification | Post an unsigned event, expect 400 and no state change |
| Password brute force | Rate limit + progressive delay | 20 attempts, expect 429 |
| Unbounded upload | Size cap + type verification | Post 1GB and a disguised executable, expect rejection |
| Double-charge on retry | Idempotency key | Post the same key twice, expect one charge |

Then: are the controls **monitored**? A rate limit with no metric is a control
you cannot tell is working. Alert on authorization-failure spikes, unusual
export volume, and new admin creation.

---

## Output — one page

```markdown
## Threat model — <feature/system>            <date>

**Diagram** <link or inline sketch>

**Assets**        <what an attacker wants>
**Entry points**  <every one>
**Actors**        <who, including insiders>

| # | Threat (STRIDE) | Boundary | Likelihood | Impact | Response | Control | Test | Owner |
|---|---|---|---|---|---|---|---|---|
| 1 | I — cross-tenant read | app→db | High | Critical | Mitigate | RLS + scoped queries | authz matrix test | @x |
| 2 | S — forged webhook | 3p→app | Med | Critical | Mitigate | Signature verify | test | @y |
| 3 | D — unbounded export | user→app | Med | Med | Accept | Documented; revisit at 1k users | — | @z |

**Assumptions** <what we are trusting — e.g. "the payment provider's signature
scheme is sound", "the platform's network isolation holds">

**Explicitly out of scope** <and why>

**Revisit when** <the change that invalidates this model>
```

---

## When to run it

- Before building anything that touches auth, money, personal data, uploads, or
  a new external integration.
- When adding a new trust boundary — a new third party, a new client type, a new
  deployment target.
- When an incident reveals a threat class you had not considered. Update the
  model; do not just patch the bug.
- Annually for the core system, as a deliberate review.

**Keep it in the repository**, next to the code, in version control. A threat
model in a slide deck is a document nobody will read again. One in `docs/` gets
updated in the same PR as the change that invalidates it.

---

## Common blind spots

- **Insiders.** Most models assume an external attacker. Employees, contractors
  and compromised laptops are a larger share of real incidents than people plan
  for.
- **The third party as the attacker.** Not "can they be compromised" but "what
  can they do with the access we granted, right now, if they chose to".
- **Non-production environments.** Staging with a copy of production data, and
  weaker controls, is production for breach purposes.
- **The support and admin path.** Impersonation, password reset by a support
  agent, bulk export tooling. Frequently the strongest privilege in the system
  and the least modelled.
- **Deletion and data lifecycle.** Where does data go when it is supposed to be
  gone? Backups, logs, analytics, caches, processors.
- **Availability of a dependency.** What does your system do when the identity
  provider, payment API or database is unreachable? Fail closed or fail open —
  and is that the choice you would have made deliberately?
