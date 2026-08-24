# Stack Selection

## The decision rule

> Choose the most boring technology that solves the problem, in a language the
> team already knows, with a managed service wherever the thing is not your
> differentiator.

Every novel choice spends a limited budget: the team's capacity to debug
unfamiliar failure modes at 3am. Spend it on the one or two places where the
novelty *is* the product. Everywhere else, boring wins — boring means answered
Stack Overflow questions, mature libraries, hireable engineers and predictable
failure modes.

## The four questions that actually decide

1. **What does the team already ship confidently?** A senior team's mediocre
   stack beats a perfect stack they are learning. This dominates almost every
   other consideration for a small team.
2. **What is the shape of the load?** Request/response, long-running jobs,
   real-time streams, heavy computation, or mostly-static content. Each has a
   natural fit.
3. **What is the operational budget?** Not money — hours per week someone will
   spend keeping it running. Managed services convert hours into dollars, which
   is almost always the right trade for a small team.
4. **What is genuinely uncertain?** Design for change where you are unsure, and
   commit hard where you are not. Do not build flexibility into the parts you are
   certain about; that is where over-engineering comes from.

---

## Defaults that are rarely wrong

These are starting points, not commandments. Deviate with a reason, and record
the reason as an ADR.

| Concern | Default | Deviate when |
|---|---|---|
| **Database** | PostgreSQL | You need a document model *and* have proven Postgres JSONB insufficient; or you need a genuine time-series/analytics engine at volume |
| **Web app** | The framework the team knows; Next.js / Nuxt / Rails / Django / Laravel / Phoenix are all correct answers | — |
| **Hosting** | A managed platform (Vercel, Fly, Render, Railway, App Runner, App Service) | You have a platform team, or compliance requires specific control |
| **Auth** | A managed provider (Auth0, Clerk, Cognito, Supabase Auth, WorkOS) or your framework's battle-tested built-in | You have specific enterprise SSO needs no provider covers |
| **Payments** | Stripe (or the regional equivalent) — never touch raw card data | — |
| **File storage** | Object storage (S3/R2/GCS) with signed URLs | Never the application server's local disk |
| **Background jobs** | Your framework's queue, backed by Postgres or Redis | Volume genuinely justifies dedicated infrastructure |
| **Search** | Postgres full-text first | Relevance tuning, facets or typo tolerance become the product |
| **Cache** | Redis, or none until measured | — |
| **Email** | A transactional provider (Postmark, SES, Resend) | Never SMTP from your own server |
| **Monitoring** | Error tracking (Sentry) + the platform's metrics, from day one | — |
| **CI** | GitHub Actions (or whatever hosts the code) | — |

---

## Choices that are expensive to reverse — decide deliberately

**Primary key strategy.** UUIDv7 or ULID for anything exposed publicly:
sequential integers leak business volume (`/orders/1043` tells a competitor your
order count) and enable enumeration attacks. Random UUIDv4 as a *clustered
primary key* has real index-locality costs at scale — UUIDv7 is time-ordered and
avoids that. A common compromise: an internal integer key plus an external
opaque identifier.

**Tenancy model.** Shared schema with `tenant_id` on every table is simplest and
correct for most SaaS; enforce it in the database with row-level security, not
only in application code. Schema-per-tenant helps with per-tenant restore and
data residency, and costs you migration complexity. Database-per-tenant is for
enterprise or regulatory isolation. Changing later is a migration project.

**Monolith vs services.** Start with a modular monolith — one deployable, clear
internal module boundaries. Split only when you have a *specific* problem that a
split solves: independent scaling of a genuinely different load profile,
independent deployment for team autonomy at real team size, or a hard isolation
boundary. "We might need to scale" is not that problem. A distributed system
bought early costs you distributed transactions, network failure modes,
deployment coordination and observability complexity, in exchange for nothing.

**Rendering strategy.** Static generation for content, server rendering for
dynamic-but-crawlable, client rendering for app-like authenticated surfaces.
Decide per route. A marketing site rendered entirely client-side is an SEO and
performance defect that is expensive to reverse.

**ORM vs query builder vs raw SQL.** An ORM for CRUD, a query builder or raw SQL
for anything with real query complexity. The failure mode is an ORM used for
reporting queries, producing joins nobody can read or optimise. Whichever you
pick, keep migrations explicit and versioned.

**Monorepo vs polyrepo.** Monorepo for a small team shipping one product —
atomic cross-cutting changes are worth a great deal. Polyrepo when teams need
genuinely independent release cadence.

---

## Runtime and language fit

| Load shape | Fits well | Poor fit |
|---|---|---|
| Request/response CRUD | Anything mainstream | — |
| High-concurrency I/O | Go, Node, Elixir, JVM async, .NET async | Sync Python/Ruby without care |
| CPU-heavy compute | Go, Rust, JVM, C#, native extensions | Pure Python/Node in the request path |
| Real-time / websockets | Elixir, Go, Node | Anything with per-connection threads |
| Data pipelines / ML | Python | Everything else, in practice |
| Mobile cross-platform | React Native, Flutter | — |
| Long-lived stateful connections | Elixir, Go | Serverless functions |

**Serverless** fits spiky, stateless, short workloads and removes operational
burden. It is a poor fit for long-running jobs, persistent connections,
predictable heavy load (cost), and anything sensitive to cold starts. It also
constrains your database connection strategy — pair with a connection pooler.

---

## Evaluating any dependency

Before adding a library, check all six:

1. **Maintenance.** Last release, open issue trend, number of maintainers. One
   maintainer with no releases in 18 months is a future migration.
2. **Weight.** Transitive dependency count and bundle impact. A date library
   pulling 40 packages for one function is not a bargain.
3. **Licence.** Compatible with your distribution model. AGPL in a commercial
   SaaS is a decision, not an accident.
4. **Exit cost.** How much code touches it directly? A library behind a small
   internal interface is replaceable; one whose types leak everywhere is not.
5. **Security posture.** Does it have a disclosure policy? Does it run install
   scripts?
6. **Could you write it?** If it is under ~100 lines and stable, writing it
   removes a supply-chain surface permanently.

---

## Anti-patterns in stack selection

- **Résumé-driven development.** Choosing technology for how it looks on a CV
  rather than for the problem. It is real, it is common, and it is expensive.
- **Scaling for imaginary load.** Building for a million users you do not have,
  at the cost of shipping to the hundred you could get.
- **The polyglot small team.** Four languages across six services with three
  engineers. Every context switch has a cost.
- **Vendor lock-in without acknowledgement.** Managed services are the right
  call; using one whose exit cost you have never estimated is not. Know what
  leaving costs before you depend on it.
- **Self-hosting the undifferentiated.** Running your own Postgres, Kafka,
  Kubernetes or email infrastructure to save money, and spending far more in
  engineering hours than the managed service costs.
- **The framework that solves next year's problem.** Adopting complexity now for
  a requirement that may never arrive.

## Record the decision

Every choice above gets one ADR (`templates/adr.md`): context, options
considered, decision, consequences. Six months from now, the ADR is what stops
the team relitigating a settled question — and what tells a new engineer whether
a constraint is a decision or an accident.
