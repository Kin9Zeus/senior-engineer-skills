---
name: project-blueprint
description: Architect, scaffold and guide the construction of a new project to senior professional standards — requirements, stack selection, architecture, data model, security baseline, CI/CD, testing, observability, legal and SEO surface — built in the right order so nothing expensive has to be retrofitted. Use when the user says "build me a", "start a new project", "create an app", "scaffold", "set up a new repo", "I want to build", "help me plan a system", "design the architecture", "what stack should I use", "greenfield", "MVP", "from scratch", "rewrite this properly" or describes a product they want to exist. By Devleck.
license: MIT
---

# Project Blueprint

Anything retrofitted costs five to fifty times what it costs to build in. The
order below is not stylistic — it is ordered by the cost of getting it wrong
later.

**Never start typing code from a one-line brief.** Ten minutes of Phase 1 saves
weeks. But do not interrogate either: ask the questions whose answers change the
architecture, assume sensible defaults for the rest, and state the assumptions.

---

## Phase 1 — Understand what is actually being built

Five questions. Ask only the ones you cannot infer from the brief.

1. **Who uses it, and how many?** Ten internal users and ten million consumers
   are different systems. If unknown, design for 10k and note the first
   bottleneck.
2. **What is the core transaction?** The one thing that must never be wrong.
   Everything else is supporting cast.
3. **What data does it hold?** Specifically: does it hold **personal data**,
   **payment data**, or **health/financial records**? Each adds non-optional
   obligations.
4. **What must it integrate with?** Existing systems, auth providers, payment
   rails, data sources.
5. **What are the constraints?** Team size and skills, budget, deadline,
   regulatory jurisdiction, self-host vs cloud.

Then write, in five lines: what it is, who it serves, the core transaction,
the data classification, and the constraint that dominates. Confirm this before
building. Getting the brief wrong is the only unrecoverable error here.

## Phase 2 — Choose the stack, and justify it

See `references/stack-selection.md` for the decision framework.

The default answer is **boring, well-supported technology the team already
knows**. Novelty is a cost paid in hiring, debugging and documentation for the
life of the system. Choose novelty only where it is the differentiator.

Decide and record: language and runtime, framework, database, hosting, auth
strategy, CI, monitoring. Each with a one-line reason. These become the first
ADRs — see `templates/adr.md`.

**Refuse to over-engineer.** No Kubernetes, no microservices, no event sourcing,
no CQRS, no service mesh for a product with no users. A modular monolith on a
managed platform with a managed Postgres is the correct answer for the
overwhelming majority of new products, and it is the answer that stays cheap to
change.

## Phase 3 — Model the data first

The schema outlives the code, the framework, and usually the company. Load
`database-engineering` and design it properly before writing a handler.

- Entities, relationships, cardinality.
- Keys: prefer UUIDv7 or ULID for public identifiers — sequential integers leak
  volume and invite enumeration.
- Constraints in the database: `NOT NULL`, `UNIQUE`, `FOREIGN KEY` with an
  explicit `ON DELETE`, `CHECK` for invariants.
- Money as integer minor units or decimal, never float. Timestamps in UTC with
  timezone-aware types.
- **Tenancy decided now.** Shared-schema with a tenant column, schema-per-tenant,
  or database-per-tenant. Moving between them later is a migration project.
- **Personal data marked now.** Every column holding personal data gets flagged
  in the model. This becomes the data inventory that `privacy-compliance` and the
  deletion pipeline both consume. Deciding this at the end means auditing every
  table by hand.
- Retention: for each table, when does a row die?

## Phase 4 — The security baseline, before the first feature

Load `security-hardening`. These go into the skeleton, not the backlog:

- Config from environment, validated at boot, failing loudly. Never a committed
  secret; `.env` in `.gitignore` from commit one; `.env.example` documenting
  every key.
- Auth chosen and wired: provider, session or token model, refresh strategy,
  logout invalidation, password reset.
- **An authorization layer that is impossible to forget.** Deny by default at the
  router; every route explicitly declares its policy. This single decision
  prevents the most common critical vulnerability in shipped products.
- Input validation with one schema library at the boundary.
- Security headers and a CSP from day one — retrofitting a CSP onto a built app
  is genuinely painful; starting with one costs nothing.
- Rate limiting on auth and mutation.
- Dependency scanning enabled in the repository from the first commit.

## Phase 5 — Scaffold in this order

```
1. Repo + .gitignore + README + LICENSE + .editorconfig
2. Language toolchain, formatter, linter, strict type checking
3. Config module (validated env) + secrets handling
4. Database + first migration + seed script
5. Auth + authorization middleware
6. One vertical slice, end to end: route -> validation -> authz -> domain
   -> persistence -> response -> test
7. CI: install, lint, type check, test, build, dependency audit — blocking
8. Error tracking + structured logging + health endpoint
9. Deploy pipeline to a real environment (staging), with rollback
10. Then, and only then, feature work
```

**Step 6 is the load-bearing step.** One complete vertical slice — with its test,
its authorization check, its error path, its log line — establishes the pattern
every subsequent feature copies. Get it right and quality scales for free; get it
wrong and every feature inherits the flaw.

**Step 9 before feature work.** A product that has never deployed does not know
what it costs to deploy. Ship the skeleton to staging on day one.

## Phase 6 — The public surface, if there is one

For anything with a public website, load `web-presence-audit` and
`accessibility-audit`. Build these in, do not bolt them on:

- Per-route metadata: unique title, unique meta description, canonical URL,
  Open Graph and Twitter card image.
- `robots.txt`, a generated `sitemap.xml`, and a custom 404 that helps rather
  than dead-ends.
- Semantic HTML, keyboard operability, visible focus, contrast, alt text — a
  component library built accessibly is free; an inaccessible one is a rewrite.
- Structured data (`Organization`, `WebSite`, `LocalBusiness` if there is a
  physical location, `FAQPage`, `BreadcrumbList`).
- Sticky mobile CTA, internal linking structure, trust pages.

## Phase 7 — The legal and trust surface

Load `privacy-compliance`. If the product touches personal data — and almost
every product does, an email address is personal data — these ship with v1:

- A privacy policy generated from the actual data inventory, naming every real
  processor.
- A cookie consent mechanism that **gates scripts before consent**, with
  rejecting as easy as accepting.
- A **self-service data export and deletion path**, built as an endpoint and a
  UI, wired to a job that propagates to every store and processor.
- Terms of service, a security contact, and a defined support response commitment.

Building deletion into the data model in week one is a day of work. Retrofitting
it across forty tables and six processors is a quarter.

## Phase 8 — Prove it works

Load `testing-strategy` and `observability-slo`.

- The vertical slice's test is the template: unit tests for rules, integration
  tests across the real database, E2E for the critical journeys.
- CI blocks merge on red. No exceptions culture from day one, because it never
  gets established later.
- Structured logs with a correlation id, error tracking wired to a real
  destination, one dashboard, and one alert that pages a human.
- A defined SLO for the core transaction, even if it is a guess to start.

## Phase 9 — Document the decisions

Load `engineering-standards`.

- README: what it is, how to run it in one command, how to test, how to deploy,
  where the docs are.
- ADRs for every one-way door from Phase 2 and 3.
- A runbook for the three most likely failures.
- `CONTRIBUTING.md` if anyone else will ever touch it.

---

## Working with the user

- **Show the plan before building it.** A short architecture summary, then
  build. Do not disappear for twenty tool calls and return with a finished repo
  nobody agreed to.
- **Build incrementally and verifiably.** Each phase ends in something runnable.
- **Explain the expensive choices.** The user should understand why UUIDs, why
  this database, why deletion is being built now — those are the choices they
  will be asked to defend later.
- **Push back on scope, not on quality.** If the deadline is tight, cut features.
  Never cut the security baseline, the deletion path, or the tests for the core
  transaction. Say this plainly if asked to.

## References and templates

- `references/stack-selection.md` — how to choose, with defaults per product type
- `references/architecture-patterns.md` — modular monolith, when to split, and when not to
- `references/scaffold-checklist.md` — the full day-one checklist, per stack
- `references/product-type-blueprints.md` — SaaS, marketplace, internal tool, API, mobile, content site
- `templates/adr.md` — architecture decision record
- `templates/readme-skeleton.md` — the README that gets someone running in 15 minutes
- `templates/env-example.md` — config contract conventions
