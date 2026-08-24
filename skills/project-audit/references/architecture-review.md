# Architecture Review

Architecture is assessed by consequence, not by aesthetics. The question is never
"is this the pattern I would have used" but "what does this structure make cheap,
and what does it make expensive?"

---

## 1. Map before judging

Produce, in this order:

**Module map.** The top-level units and what each owns. If the directory names
are `components/`, `utils/`, `helpers/`, `services/`, the codebase is organised
by *technical kind* rather than by *domain*, which predicts that every feature
change touches every folder. Note it; it is a P2 unless the codebase is large,
where it is a P1.

**Dependency direction.** Which modules import which. Draw it.

```bash
# Node/TS — who imports whom at the top level
grep -rhoE "from ['\"](\.\./)*[a-zA-Z@/._-]+['\"]" src --include='*.ts' --include='*.tsx' \
  | sort | uniq -c | sort -rn | head -40

# Python
grep -rhoE '^(from|import) [a-zA-Z_.]+' --include='*.py' . | sort | uniq -c | sort -rn | head -40

# Go
go list -deps ./... 2>/dev/null | head -40
```

The two findings to look for:
- **Cycles.** A imports B imports A. Every cycle is a unit that cannot be tested,
  built or reasoned about independently.
- **Inward-pointing framework dependencies.** The domain/business layer importing
  the HTTP framework, the ORM, or the cloud SDK. This is what makes a codebase
  impossible to test without booting the whole world.

**Coupling hubs.** The file imported by everything. It is the rebuild
bottleneck, the merge-conflict magnet, and usually a `utils` file that has
accumulated unrelated concerns.

---

## 2. The seven structural questions

### Q1 — Where do the business rules live?

Trace one non-trivial rule (a discount calculation, an eligibility check, a state
transition) from request to persistence.

- In the HTTP handler -> untestable without a request, unreusable from a job or CLI. **P2.**
- In the ORM model -> couples rules to persistence; a schema change forces a rules change. **P2.**
- Duplicated in frontend and backend with no shared source -> they will diverge, and the divergence will be a bug in money or permissions. **P1.**
- In a testable domain module called by both -> correct.

### Q2 — How many ways are there to do the same thing?

Count the HTTP clients, the date libraries, the validation approaches, the state
managers, the error types. Three ways to make an HTTP request means three sets of
retry semantics, three timeout defaults and three places to add a header.

Consistency is worth more than the quality of any individual choice. Recommend
converging on the best existing one, not introducing a fourth.

### Q3 — What is the transaction boundary?

Find where a unit of work begins and ends. The failures:
- No explicit boundary — multiple writes that can half-succeed. **P1** if it
  touches money or permissions.
- An external HTTP call inside a transaction — holds a database connection for
  the duration of somebody else's outage. **P1.**
- A transaction per ORM call, with a multi-step business operation spread across
  several. **P1** where partial state is invalid.

### Q4 — Where is untrusted input validated?

There should be one boundary, crossed once, with a schema. Enumerate the entry
points: HTTP routes, webhooks, queue consumers, file uploads, scheduled jobs
reading external data, CLI arguments. Any entry point without schema validation
is a finding; webhooks and queue consumers are the ones teams forget.

### Q5 — What is the failure model?

- Are errors typed, or is everything a generic exception caught at the top?
- Is there a distinction between *expected* failures (validation, not found,
  conflict) and *unexpected* ones (bugs, outages)? Only the second should page.
- Does every external call have a timeout? (Missing timeouts are the most common
  cause of cascading failure. Grep for the HTTP client's construction and check.)
- Is there a retry policy, and is it bounded, jittered, and applied only to
  idempotent operations?
- Are there circuit breakers or bulkheads around the dependencies that can be
  slow?

### Q6 — What is the one-way door?

List the decisions that would be expensive to reverse:
- Primary key strategy (sequential integers leak volume and enable enumeration;
  changing later means rewriting every foreign key).
- The public API shape, once third parties consume it.
- The tenancy model — moving from shared-schema to per-tenant later is a
  migration project, not a refactor.
- Auth provider and session model.
- The event/message schema, once consumers exist.

Each one-way door should have an ADR. Where there is none, that is a
documentation finding *and* an architecture risk, because nobody can tell
whether it was decided or defaulted.

### Q7 — What happens at 10x?

Pick the current bottleneck honestly. It is almost always one of:
- A query that scans a table that only grows.
- An in-process operation that should be a queue (email, image processing,
  report generation, webhook delivery).
- A synchronous fan-out to third parties in the request path.
- Session or cache state in process memory, blocking horizontal scaling.
- A single writer with no read replicas.

Name the *first* one to break, not all of them. A ranked bottleneck is
actionable; a list of five is ignored.

---

## 3. Distributed systems, if applicable

Only apply this section if there is genuinely more than one deployable unit.

- **Can each service be deployed independently?** If not, it is a monolith with
  network latency and distributed failure modes — the worst of both. **P1.**
- **Does each service own its data?** Two services writing one database is
  shared mutable state across a network boundary.
- **Is communication sync or async, and deliberately so?** Synchronous chains
  multiply latency and couple availability: three services at 99.9% in a chain
  give you 99.7%.
- **Are messages idempotent?** At-least-once delivery is the norm; a consumer
  that is not idempotent will double-charge someone.
- **Is there a saga/compensation strategy** for operations spanning services, or
  is partial failure simply unhandled?
- **Is there a correlation id** threaded through every hop?

---

## 4. Frontend architecture

- **Server vs client state.** Server data cached in a client store without
  invalidation goes stale. Prefer a query library with explicit cache semantics.
- **Rendering strategy per route.** Static, server-rendered, streamed, or
  client-rendered — chosen deliberately. A marketing page that ships a 400KB
  client bundle to render static text is a P2 performance and SEO finding.
- **Bundle boundaries.** Route-level code splitting present? Is a heavy library
  (charting, editor, date/locale data, PDF) in the initial bundle?
- **Component contract.** Are components pure and prop-driven, or do leaf
  components fetch and mutate global state? The latter makes rendering order a
  correctness concern.
- **Design system.** One source for spacing, colour, typography and interactive
  states, or ad hoc values per component. Ad hoc values guarantee accessibility
  and consistency drift.

---

## 5. Scoring architecture

| Score | What it looks like |
|---|---|
| 0–3 | No discernible boundaries; business logic in handlers and templates; cycles; every change touches everything. |
| 4–6 | Layered but leaky. Framework types reach the domain. Some duplication of rules. Boundaries exist by convention, not enforcement. |
| 7–8 | Clear modules by domain, dependencies point inward, business rules testable in isolation, one way to do each thing. |
| 9–10 | The above, plus ADRs for one-way doors, enforced boundaries (lint rules, module systems, build-level checks), and a named, monitored scaling bottleneck. |

---

## 6. What not to report

- **Style preferences dressed as architecture.** Folder naming, barrel files,
  default vs named exports — these are `engineering-standards` territory at most.
- **Pattern purity.** "This is not hexagonal architecture" is not a finding.
  "The domain layer imports the ORM, so business rules cannot be tested without a
  database" is.
- **Speculative scale.** Do not recommend microservices, event sourcing, CQRS or
  Kubernetes to a project without the load, the team size or the deployment
  independence problem that justifies them. Premature distribution is the most
  expensive advice in this document, and the easiest to give.
- **Rewrites.** Recommending a rewrite is almost always wrong and always
  expensive. If you genuinely believe it, state the specific unfixable property
  that forces it, and price it honestly.
