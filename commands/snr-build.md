---
description: Architect and scaffold a new project to senior professional standards, in the order that avoids expensive retrofits.
argument-hint: "[what you want to build]"
---

# Build a New Project

Design and build: **$ARGUMENTS**

Load the `project-blueprint` skill and follow its phases. Load `senior-engineer`
for the non-negotiable bar.

## Do not start typing code yet

Phase 1 first. Ask only the questions whose answers change the architecture;
assume sensible defaults for everything else and state the assumptions:

1. **Who uses it, and how many?**
2. **What is the core transaction** — the one thing that must never be wrong?
3. **What data does it hold?** Specifically: personal data, payment data, or
   health/financial records? Each adds non-optional obligations.
4. **What must it integrate with?**
5. **What constrains it** — team skills, budget, deadline, jurisdiction?

Then write five lines: what it is, who it serves, the core transaction, the data
classification, and the dominant constraint. Confirm before building.

## Then, in this order

The order is by cost-of-getting-it-wrong-later, not by convenience.

```
2  Stack selection      — boring, known technology; one ADR per choice
3  Data model           — schema, constraints, tenancy, PII tagged, retention
4  Security baseline    — config validation, authz deny-by-default, CSP
5  Scaffold             — repo → toolchain → config → db → auth → VERTICAL SLICE
                          → CI → observability → deploy to staging
6  Public surface       — metadata, 404, robots, sitemap, schema, a11y
7  Legal surface        — privacy policy, consent, DELETION PATH, terms
8  Prove it             — tests, CI gate, logging, one alert
9  Document             — README, ADRs, runbook
```

**Step 6 of the scaffold is load-bearing.** One complete vertical slice — route,
validation, authorization, domain logic, persistence, response, log line, test —
establishes the pattern every future feature copies. Get it right and quality
scales for free.

**Deploy to staging before feature work.** A product that has never deployed does
not know what deploying costs.

## Refuse to over-engineer

No Kubernetes, no microservices, no event sourcing, no CQRS for a product with
no users. A modular monolith on a managed platform with a managed Postgres is
the correct answer for the overwhelming majority of new products, and it stays
cheap to change.

If the user asks for premature distribution, say so in two sentences, then build
what they asked with the assumption stated.

## Working style

- **Show the plan before building it.** A short architecture summary, then build.
- **Each phase ends in something runnable.**
- **Explain the expensive choices** — UUIDs, tenancy model, why deletion is
  being built now. Those are what the user will be asked to defend later.
- **If the deadline is tight, cut features** — never the security baseline, the
  deletion path, or the tests on the core transaction. Say this plainly.
