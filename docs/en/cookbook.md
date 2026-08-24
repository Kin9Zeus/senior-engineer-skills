# Cookbook

Real workflows, in the order you would actually run them.

[English](../en/cookbook.md) · [Español](../es/recetario.md)

---

## 1 · You inherited a codebase and have no idea what is in it

```
/snr-audit --quick
```

Thirty minutes. Answers one question: is there anything here that must be fixed
before this touches a real user? You get blockers, criticals, what was checked
and found clean, and what a full audit would cover that this did not.

Then, once you know the shape of it:

```
/snr-audit --parallel
```

The full fifteen-domain pass, with concurrent domain reviewers. Expect a report
of a few thousand words: verdict, score, ground truth, findings by severity,
scorecard, remediation plan, and an explicit "what I could not verify".

**Then fix in order.** Ask it to work the P0 list, one finding per commit, with
the failing test written first:

> Fix the P0 findings from the audit. One commit each. Write the failing test
> before the fix, and re-verify with the verification step from each finding.

---

## 2 · You are starting something new and want to do it properly

```
/snr-build a multi-tenant SaaS for gym class scheduling
```

It will ask up to five questions — who uses it and how many, the core
transaction, the data classification, integrations, and the dominant constraint
— then show you an architecture summary before writing anything.

Say yes, and it builds in this order:

```
repo → toolchain + strict types → validated config → database + migration 001
→ auth + deny-by-default authorization → ONE COMPLETE VERTICAL SLICE
→ CI that blocks merge → logging + error tracking + one alert
→ deploy to staging → then features
```

**The vertical slice is the point.** One route with validation, object-level
authorization, domain logic, persistence, a log line and two tests. Every future
feature copies its shape, so quality scales for free.

**If you are on a deadline**, say so. It will cut features. It will not cut the
security baseline, the deletion path, or the tests on the core transaction — and
it will tell you plainly that it is not cutting those.

---

## 3 · Something is slow and you do not know why

```
"the checkout page takes forever to load"
```

`performance-engineering` activates. It will refuse to guess and will ask for
field data first, because a Lighthouse score from your laptop is not what your
users experience.

Expect a measurement, not an opinion:

```
Measured: LCP 4.8s (p75, field data, mobile, last 28 days, n=12,400)
Cause:    Hero image is a 2.4MB unoptimised PNG, lazy-loaded, not preloaded
Fix:      AVIF + srcset (est. 180KB), remove loading="lazy", fetchpriority="high"
Expected: LCP ~1.9s
Verify:   PageSpeed Insights field data after 28 days; Lighthouse CI meanwhile
```

If the bottleneck turns out to be the backend, it hands over to
`database-engineering` — because the answer is a missing index or an N+1 far
more often than it is application code.

---

## 4 · You need to let users delete their data

This is the workflow most teams put off until a regulator or an enterprise buyer
forces it, at which point it is a quarter of work instead of a week.

```
/snr-privacy --deletion
```

What you get:

1. **A data inventory built from your schema and routes**, not from a
   questionnaire. Including the list of every third party in your code that
   receives personal data.
2. **An erasure plan as code** — per table, per field: delete, null, anonymise,
   pseudonymise, or retain with a documented legal reason and an expiry.
3. **The endpoints and the job** — request, verify, grace period, execute across
   every store, verify by re-querying, record in an audit trail, notify.
4. **The processor fan-out** — the step that gets skipped, and the one that makes
   the difference between deletion and partial deletion.
5. **The test that fails when a new table is added without a rule.** This is what
   keeps the plan honest six months from now.

Then run the whole pack:

```
/snr-privacy
```

Inventory → policy (English and Spanish templates) → consent that actually gates
scripts → the rights pipeline → subprocessor page and breach plan.

---

## 5 · Your site is not showing up in search

```
/snr-web https://yoursite.com
```

It runs the live check first, then goes deeper. The two things it finds most
often, both invisible in a browser:

- **A soft 404** — missing pages returning `200`, so every mistyped URL becomes
  an indexable thin page.
- **A staging `robots.txt` in production** — `Disallow: /` removes the site from
  search entirely, and traffic decays for weeks before anyone notices.

Third most common: every page canonicalling to the homepage, which de-indexes
the whole site except one page.

You get a per-page table, prioritised findings, and — importantly — **the
suggested replacement copy**. Titles and meta descriptions written for you, not
a note saying you should write some.

---

## 6 · You are launching on Thursday

```
/snr-ship v1.0
```

Twelve blocker checks first. Any one of them makes the verdict `NO GO`, and the
report is short:

> **NO GO.** Three blockers. The largest is that any authenticated user can read
> any other user's invoices, which would be a reportable data breach on day one.
> Estimated 2 days to clear all three.

If the blockers are clear, it runs the full nine-area gate and gives you
`GO` or `GO WITH RISK` — with every accepted risk named, mitigated, and assigned
to a person who accepted it.

It also captures the **pre-launch baseline**. Without it you cannot tell, on
Friday morning, whether the numbers are bad.

---

## 7 · You want a second opinion on a design before building it

```
"use the snr-architect agent to review this plan: <your plan>"
```

You get the seven structural questions answered, the one-way doors named as
ADRs, the first scaling bottleneck identified, and — most usefully — **the seam
that will hurt in the next three features**, named before it costs a quarter.

It will also push back on premature complexity. If you propose microservices for
a product with no users, it says so in two sentences and then designs what you
asked for with the assumption stated.

---

## 8 · Running a security pass before a pentest

```
/snr-harden
```

Works top-down by real-world yield: secrets first (including git history), then
object-level authorization, then injection. The two checks that find the most
severe issues:

**Secrets in git history.** If anything is found, the remediation order is fixed:
rotate the credential, check the provider's audit log, *then* purge the history.
Purging without rotating leaves the key live and makes the repository look clean
— the most common mistake in this area.

**The cross-user test.** Authenticate as user A, request user B's resource by
changing an identifier. A `200` is a P0. This one check finds more severe
vulnerabilities in real applications than any other.

Ask for fixes and it works in severity order, one finding per commit, with the
regression test written first.

---

## 9 · Using it day to day, without commands

The skills activate on their own. You do not need to think about which one.

| You say | What loads |
|---|---|
| "add a login endpoint" | `security-hardening` + `api-contracts` |
| "write a migration to add a teams table" | `database-engineering` |
| "this modal isn't working with the keyboard" | `accessibility-audit` |
| "set up CI for this repo" | `devops-platform` + `testing-strategy` |
| "we're getting a lot of 500s and don't know why" | `observability-slo` |
| "add an email field to the signup form" | `privacy-compliance` |
| "what stack should I use for this?" | `project-blueprint` |

The last one is worth noticing: adding an email field to a form is a privacy
event, and the suite treats it as one — without being asked.

---

## 10 · Making it less strict

It calibrates to what a project claims to be. Tell it:

> This is a weekend side project with no users and no plans to have any. Grade
> it accordingly.

It will down-weight scalability, process, observability and documentation, and
tell you which findings it is down-weighting.

**Four things are never down-weighted**, and it will say so: secrets in git,
cross-user data access, absent backups, and privacy claims that are not true.
Those cause the same harm regardless of how small the project is.
