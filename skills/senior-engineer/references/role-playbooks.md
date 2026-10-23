# Role Playbooks

What each senior role actually looks for. Run the relevant playbooks; you are
all of these people at once.

---

## Principal Engineer

Cares about the decisions that are expensive to reverse.

- **Boundaries.** Can I name the modules and the direction dependencies flow?
  Is there a cycle? Does the domain layer import the framework?
- **Coupling.** If I change the payment provider, how many files move? If the
  answer is "dozens", the abstraction is missing or wrong.
- **The seam that will hurt.** Every system has one place where the next three
  features will be painful. Find it and name it before it costs a quarter.
- **Reversibility.** Which choices here are one-way doors (data model, public
  API shape, auth provider, primary key strategy)? Are they written down as ADRs?
- **Consistency over cleverness.** Three ways to do the same thing in one
  codebase is a defect, even when all three work.
- **The build-vs-buy line.** Is the team maintaining infrastructure that a
  managed service would do better? Is it depending on a vendor for something
  that is core differentiation?

Signature questions: *"What happens when this doubles?" "What did we decide, and
where is it written?" "What is the blast radius of this abstraction being wrong?"*

---

## Senior Fullstack Developer

Cares about the path from a user's click to a row in a table, and back.

- **The boundary contract.** Where exactly is untrusted input validated? Once,
  at the edge, with a schema — or ad hoc in six handlers?
- **Error paths.** For every happy path, is there a defined failure path with a
  user-facing message, a log line and a metric? What does the user see on a 500?
- **State management.** Is server state cached in a client store where it will
  go stale? Are loading, empty, error and partial states designed, or only the
  populated one?
- **Forms.** Validated on both sides, keyboard-usable, labelled, disabled on
  submit, idempotent against double-click, with inline errors that name the
  field and the fix.
- **Rendering strategy.** Static, server-rendered, streamed or client-rendered —
  chosen deliberately per route, not inherited by accident.
- **The N+1 in the component tree.** A list rendering a component that fetches
  per item is the frontend version of the same bug.
- **Dead code and dead flags.** Feature flags with no expiry become permanent
  branching complexity.

Signature questions: *"What does the user see when this fails?" "Where is this
validated?" "What is the empty state?"*

---

## Senior Database Engineer

Cares about the data outliving every version of the application.

- **Keys and constraints.** Primary keys, foreign keys with an explicit `ON
  DELETE`, unique constraints on the things that are actually unique, `NOT NULL`
  wherever the business says required. Constraints in the database, not only in
  the ORM — the ORM is not the only writer.
- **Indexes.** Every foreign key indexed. Every column in a `WHERE`, `JOIN`,
  or `ORDER BY` on a hot path indexed. Composite index column order matches
  query predicate order. No unused indexes paying write cost forever.
- **Query shapes.** `EXPLAIN ANALYZE` on the five hottest queries. Sequential
  scans on large tables, nested loops over big row counts, and sorts spilling to
  disk are the three things to find.
- **N+1.** Look at the ORM's query log for one page load, not at the code.
- **Migrations.** Versioned, reversible, tested against a production-sized copy.
  No `ALTER TABLE` that takes an exclusive lock on a hot table without a
  concurrent strategy.
- **Transactions.** Correct boundaries, understood isolation level, no external
  HTTP call inside a transaction, retry logic for serialization failures.
- **Money and time.** Decimal or integer minor units for money, never float.
  Timestamps stored in UTC with timezone awareness, never naive local time.
- **Retention and deletion.** Every table has an answer to "when does this row
  die?" Soft-delete flags that no query filters on are a data-leak vector.
- **Backups.** Automated, off-site, encrypted, retention-defined, and **restored
  in a drill within the last 90 days**.

Signature questions: *"Show me the EXPLAIN." "What happens to this row when the
user asks to be deleted?" "When did you last restore a backup?"*

---

## Senior DevOps / SRE

Cares about the system at 3am when nobody is watching.

- **Reproducibility.** Can the environment be rebuilt from the repository alone?
  Is there a snowflake server holding state that is not in code?
- **Pipeline.** Does CI run tests, lint, type check, dependency audit and build
  on every PR, and block merge on failure? How long does it take? (Over 15
  minutes and people stop running it.)
- **Deploys.** Automated, one command or one click, with a rollback that has
  been executed at least once for practice. Blue/green, canary or rolling —
  chosen deliberately.
- **Environments.** Local, staging and production are structurally the same
  thing with different scale. Staging with a different database engine is not
  staging.
- **Secrets.** In a manager (cloud KMS/secret manager, Vault, or the platform's
  own), injected at runtime, rotatable, with access logged.
- **Health and readiness.** Distinguish liveness (restart me) from readiness
  (do not send traffic yet). Graceful shutdown that drains connections.
- **Failure domains.** What is the single point of failure? What happens when
  the database fails over, the queue backs up, the third-party API times out?
- **Cost.** Is spend attributed per service and alerted on? Unbounded log
  retention and idle over-provisioned instances are the usual two leaks.

Signature questions: *"How do we roll this back?" "What pages a human?" "Have we
ever practised this failure?"*

---

## Application Security Engineer

Assumes every input is hostile and every user is an attacker.

- **Authentication.** Password hashing with a memory-hard algorithm, session
  invalidation on logout and password change, MFA available on privileged
  accounts, no user enumeration in error messages, rate limits and lockout.
- **Authorization.** Enforced server-side, per object, on every mutating and
  every reading route. The test: can user A, authenticated, read or modify user
  B's resource by changing an identifier?
- **Injection.** Parameterised queries everywhere. No shell interpolation of
  user input. No dynamic template rendering of user strings.
- **XSS and CSP.** Output encoded by default; every escape hatch
  (`dangerouslySetInnerHTML`, `v-html`, `|safe`) individually justified. A CSP
  without `unsafe-inline` or `unsafe-eval`.
- **CSRF and CORS.** SameSite cookies plus tokens for cookie-authenticated state
  changes; a CORS allowlist that is not a reflected origin.
- **SSRF.** Any server-side fetch of a user-supplied URL is a finding until
  proven to have an allowlist and blocked internal ranges.
- **Uploads.** Type verified by content not extension, size limited, stored off
  the application domain, never executed, filenames not user-controlled on disk.
- **Secrets and supply chain.** Nothing in git history, dependencies pinned,
  vulnerability scanning automated, install scripts reviewed.
- **Exposure.** Debug mode off, stack traces not returned to clients, admin
  panels not merely unlinked, directory listing off, security headers set.
- **Platform trust.** Assumes the host, CI or secrets store can be breached:
  every credential narrow, network-restricted, spend-capped and separate per
  environment; no long-lived cloud keys in CI; a rehearsed rotation runbook
  (`cloud-security`, `security-incident-response`).
- **Runtime currency.** The language runtime, web server and base image are on a
  supported, patched release — verified on the *running* build, rebuilt on
  advisories (`php-hardening` for the PHP case).
- **AI surface.** Every model call, tool and MCP server is inventoried; no
  session combines private data, untrusted content and an outbound channel
  (`ai-security`).

Signature question: *"Show me the line where this is authorised — not
authenticated, authorised, for this object."* Second question: *"If our host
leaked every secret it holds tonight, what could the attacker do with them?"*

## Penetration Tester / Ethical Hacker

Finds what an attacker would find first — with permission, inside a scope, and
without harming the system or its users.

- **Gate.** Written authorisation, a scope file and rules of engagement before any
  active step; `scope-guard` before every host.
- **Method.** Model, map, then test by yield: exposure → access control (two
  accounts per role) → authentication → injection → XSS/CSRF → SSRF/uploads →
  business logic → configuration → infrastructure.
- **Proof.** The least harmful evidence — inert markers, own test accounts, no
  persistence, no data harvesting. Reproduced twice.
- **Output.** Severity justified by impact × likelihood; each finding with a fix, a
  regression test and a detection signal; every fix retested
  (`pentest-methodology`).

Signature question: *"What is the cheapest path from an anonymous visitor to our
most valuable data, and which single control would break it?"*

## Incident Responder

Limits damage and preserves evidence when something may already be compromised.

- **Classify** (provider breach, leaked credential, runtime CVE, active intrusion).
- **Revoke before investigating; investigate before cleaning.** Rotate upstream
  first, prove the old value dead.
- **Hunt at the issuer first** — provider audit logs the attacker did not control.
- **Rebuild from a clean patched image** when cleanliness cannot be proven.
- **Flag notification** early; the legal decision is counsel's, the clock may
  already be running (`security-incident-response`).

Signature question: *"How do you know the old credential no longer works?"*

---

## QA Lead

Cares about the difference between "it works" and "we know it works".

- **The pyramid.** Many fast unit tests, a meaningful integration layer, a few
  high-value E2E journeys. An inverted pyramid is slow and flaky; a pyramid with
  no top has never tested the real thing.
- **Coverage that means something.** Branch coverage on business logic beats
  line coverage across the codebase. A covered line with no assertion is theatre.
- **Regression discipline.** Every bug fixed gets a test that fails without the
  fix. No exceptions — this is how a codebase stops repeating itself.
- **The critical journeys.** Signup, login, the core action, payment, deletion.
  These are E2E-tested and run before every deploy.
- **Flakes.** Tracked, quarantined and fixed. A tolerated flaky suite is a suite
  nobody believes, which is the same as no suite.
- **Data.** Deterministic fixtures, no shared mutable state between tests, no
  dependence on test execution order, no calls to real third parties.

Signature questions: *"What test fails if I break this?" "When did the suite last
catch a real bug?"*

---

## Accessibility Specialist

Cares about the users the team did not picture.

- Keyboard-only traversal of every flow, with a visible focus indicator.
- Every control has an accessible name; every image has appropriate alt text
  (empty for decorative).
- Contrast at 4.5:1 for body text, 3:1 for large text and UI boundaries.
- Semantic structure: one `h1`, ordered headings, landmarks, lists as lists.
- Errors announced, associated with their field, and not conveyed by colour
  alone.
- Motion respects `prefers-reduced-motion`; nothing auto-plays with sound.
- Custom widgets follow an established ARIA pattern, or are replaced by native
  elements — which is almost always the better answer.

Signature question: *"Can I complete this with a keyboard and no mouse, and does
a screen reader announce what just happened?"*

---

## Privacy Officer

Cares about what the company promises versus what the code does.

- Is there a data inventory naming every field of personal data, its purpose,
  its legal basis and its retention period?
- Does the privacy policy list every third party that actually receives data —
  cross-checked against the SDKs, tags, pixels and font CDNs in the code?
- Is there a working, discoverable, self-service path to export and delete?
  Does deletion reach backups, logs, analytics and every processor?
- Does the cookie banner gate scripts before consent, and is rejecting as easy
  as accepting?
- Is data minimised — is the app collecting fields it never uses?
- Are there Data Processing Agreements with the processors, and a breach
  notification plan with a 72-hour clock?

Signature question: *"If a user asks to be forgotten today, what exactly happens,
in which systems, within how many days — and who does it manually?"*
