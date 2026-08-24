# Recurring Anti-Patterns

The failure modes that show up in project after project. Recognising them by
shape is faster than deriving them each time. Each entry: the smell, why it
persists, and the correction.

---

## Security

**Authentication mistaken for authorization**
The route checks that *someone* is logged in and then trusts the identifier in
the request. Persists because it works perfectly in testing, where you only ever
use your own account. *Correction:* every read and write resolves the object and
asserts the caller's relationship to it. Write the test that logs in as A and
requests B's resource.

**The unlinked admin panel**
`/admin` is not in the navigation, so it is treated as private. Persists because
"nobody knows it's there". *Correction:* obscurity is not access control. It is
discoverable via JS bundles, sitemaps, wordlists and referrer leaks within days.

**Client-side price**
The browser posts the amount. Persists because the server "already knows" the
cart. *Correction:* the server computes every monetary value from server-held
state. The client sends intent, never value.

**The rotated-nothing leak**
A key was committed, then removed in a follow-up commit, and the incident is
considered closed. Persists because the diff looks clean. *Correction:* it is
still in history and in every clone. Rotate first, purge second, and treat it as
disclosed.

**Validation in the wrong place**
Input is validated in the UI and trusted by the API. Persists because the UI is
the only client — until the mobile app, the integration, or curl arrives.
*Correction:* validate at the trust boundary with a schema; the UI's validation
is a courtesy, not a control.

**CORS as a wildcard**
`Access-Control-Allow-Origin` reflects the request origin with credentials
enabled. Persists because it makes an integration error go away. *Correction:*
an explicit allowlist. Reflection with credentials is equivalent to no policy.

---

## Data

**The ORM as the only source of truth**
Constraints, defaults and cascades live in model classes; the database has none.
Persists because a single application is the only writer. *Correction:* a
migration script, an admin tool, an analytics job or a future service will write
directly. Constraints belong in the schema.

**Float money**
`price: number` in a language where numbers are IEEE 754. Persists because it is
correct for months and then off by a cent. *Correction:* integer minor units or
a decimal type, at every layer including JSON.

**Naive timestamps**
Local time stored without a zone. Persists until the first DST transition, the
first user abroad or the first server migration. *Correction:* UTC with
timezone-aware types; convert at the presentation edge only.

**Soft delete nobody filters**
A `deleted_at` column and a dozen queries that forget it. Persists because the
happy path uses the ORM's default scope and the reports do not. *Correction:*
enforce at the data-access layer or use a view. Audit every raw query.

**The unindexed foreign key**
Fast at 1,000 rows, catastrophic at 1,000,000. Persists because it never appears
in development. *Correction:* index every FK by default; measure against
production-sized data, not seed data.

**The untested backup**
It is configured, it reports success, it has never been restored. Persists
because restoring is inconvenient and nothing has gone wrong yet. *Correction:*
schedule a restore drill; record the date and the measured recovery time. Until
then, the recovery capability is unknown, not present.

**Migration without a down path**
Forward-only migrations against production. Persists because rollbacks are rare.
*Correction:* every migration has a tested reverse, or an explicitly documented
reason it cannot and a forward-fix plan instead.

---

## Architecture

**The distributed monolith**
Services split by team, sharing one database. Persists because the split was
organisational, not architectural. *Correction:* a service that cannot be
deployed independently is a module with network latency. Either give it its own
data or merge it back.

**The abstraction with one implementation**
An interface, a factory and a registry wrapping a single concrete class.
Persists because it feels forward-looking. *Correction:* wait for the second
implementation. The right abstraction is discovered from two cases, not
predicted from zero.

**The god module**
`utils.js` at 3,000 lines, imported by everything. Persists because adding to it
is always the smallest immediate step. *Correction:* split by domain concept.
Anything imported by everything is a coupling hub and a rebuild bottleneck.

**Business logic in the controller**
The HTTP handler contains the rules. Persists because it is the shortest path.
*Correction:* the rules must be testable without an HTTP request and reusable
from a job, a CLI or a second transport.

**Configuration by scatter**
`process.env.X` read in forty files with inline defaults. Persists because each
addition is one line. *Correction:* one validated config module, parsed and
type-checked at boot, failing loudly on missing values.

---

## Delivery and operations

**The green build nobody trusts**
Tests are skipped, flaky ones are retried, and failures are merged past.
Persists because deadlines. *Correction:* a suite that is allowed to be wrong
provides zero information. Quarantine flakes explicitly, block on the rest.

**Manual production steps**
A runbook with "then SSH in and run this". Persists because automating it is a
day of work. *Correction:* it will be executed wrong at 3am by whoever is
awake. Automate or make it a single audited script.

**Logging without correlation**
Every service logs, nothing shares a request id. Persists because each service
was instrumented separately. *Correction:* propagate a trace/correlation id from
the edge through every hop and log line.

**Alerting on causes instead of symptoms**
Pages for CPU at 80%. Persists because infrastructure metrics are the default
dashboard. *Correction:* page on user-visible symptoms — error rate, latency,
queue age. CPU is a diagnostic, not an alert.

**The staging that is not**
Different database engine, no data, no traffic, half the services stubbed.
Persists because a real staging costs money. *Correction:* either make it
structurally identical at smaller scale, or admit that production is the first
real environment and invest in progressive delivery instead.

---

## Frontend and public surface

**States that were never designed**
Only the populated state exists. Empty, loading, error, partial, offline and
"one item" all break the layout. Persists because the design was made with
seeded data. *Correction:* design and test all six.

**The accessibility retrofit**
ARIA attributes sprinkled onto `div`s to satisfy a scanner. Persists because
scanners reward attributes. *Correction:* native elements first; ARIA only where
no native element exists, following a documented pattern.

**The cookie banner that does nothing**
Scripts load on page load; the banner records a preference afterwards. Persists
because the vendor snippet is easy and the gate is not. *Correction:* no
non-essential script executes before consent. Test with the network tab.

**Metadata by template**
Every page shares one title and one description because they are set in the
layout. Persists because it is one line to make it work. *Correction:* per-route
metadata; a duplicated title is a page that competes with itself in search.

**The privacy policy that describes a different product**
Copied from a generator, listing processors the company does not use and
omitting the three it does. Persists because nobody re-reads it after launch.
*Correction:* generate it from the actual data inventory and re-verify on every
new SDK.

**Deletion by email**
"Contact us to delete your data." Persists because building deletion is real
work touching every table. *Correction:* a self-service flow with a defined
completion window, propagation to processors, and an audit record.

---

## Process

**No decision record**
Nobody remembers why the queue was chosen, so the choice is relitigated every
six months. *Correction:* an ADR per expensive decision — context, options,
choice, consequences.

**Bus factor of one**
One person understands deploys, the database, or the payment integration.
*Correction:* write the runbook, pair on the next incident, and rotate.

**Tests written after the fact, once**
A coverage push produced tests that assert current behaviour, including its
bugs. *Correction:* tests assert intended behaviour derived from requirements;
a bug fix starts with a failing test.

**The permanent feature flag**
Flags with no owner and no expiry, multiplying code paths that are never all
tested together. *Correction:* every flag gets an owner and a removal date at
creation.
