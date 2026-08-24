# Product-Type Blueprints

The obligations and early decisions specific to each product shape. Use
alongside the generic scaffold checklist, not instead of it.

---

## B2B SaaS

**Dominating decisions:** tenancy model, billing model, roles.

- **Tenancy from migration 001.** `organization_id` on every table, row-level
  security enforcing it. Users belong to organisations, not the other way round —
  a user in two organisations is a requirement you will get.
- **Roles before features.** Owner / admin / member / billing-only / read-only.
  Retrofitting roles means auditing every endpoint.
- **Billing:** subscription state lives in your database as the source of truth
  for entitlement, synchronised from the payment provider by webhook. Never gate
  features by calling the payment API in the request path. Handle: trial,
  active, past due, cancelled, paused, and the grace period between past-due and
  suspension.
- **Invitations, seat counting, and what happens when the owner leaves.**
- **Audit log** of security-relevant actions from day one. Enterprise buyers ask
  for it, and it cannot be backfilled.
- **SSO/SAML** will be requested by the first enterprise customer. You do not
  need it now; you do need an auth abstraction that can accommodate it.
- **Data export** — enterprise contracts require it, and it doubles as your GDPR
  portability mechanism.
- **Public status page** and a stated support response commitment.

**Early P0s:** cross-tenant data leakage; entitlement checked client-side;
webhook handler not verifying the provider's signature.

---

## Marketplace / two-sided platform

**Dominating decisions:** money flow, trust, and the cold-start side.

- **Payments:** use a platform product (Stripe Connect or equivalent). Holding
  and disbursing other people's money yourself is a regulated activity.
- **Money model:** every movement is a ledger entry — double-entry, append-only,
  never a mutable balance column. Balances are computed. This is the single most
  important decision in a marketplace and the most expensive to retrofit.
- **Escrow and payout timing**, refunds, chargebacks, disputes, partial refunds.
- **Identity and trust:** verification level per side, reviews with anti-gaming
  measures, reporting and moderation queue.
- **Both sides' lifecycle:** onboarding, listing quality, matching, and what a
  cold marketplace shows when one side is empty.
- **Tax:** marketplace facilitator obligations vary by jurisdiction — flag it
  early, it constrains the money model.

**Early P0s:** mutable balance columns; a payout path that can double-pay on
retry; unauthenticated access to another party's transaction history.

---

## Consumer app with a public site

**Dominating decisions:** performance, SEO, and privacy.

- **Split the surfaces:** the marketing site is static or server-rendered and
  fast; the app is authenticated and can be client-heavy. Rendering one strategy
  across both compromises whichever one loses.
- **Core Web Vitals are a business metric.** Budget for LCP, INP and CLS before
  building, and enforce in CI.
- **Full `web-presence-audit` surface**: per-page metadata, structured data,
  sitemap, custom 404, internal linking, sticky mobile CTA.
- **Privacy is at its most exposed here.** Consumer products attract regulatory
  attention. Cookie consent that actually gates, a real deletion path, an
  accurate processor list.
- **Onboarding and empty states** are the product for the first ten minutes.
- **Email deliverability**: SPF, DKIM and DMARC configured before the first
  campaign, or your transactional mail lands in spam and you will not know.

**Early P0s:** analytics loading before consent; `NEXT_PUBLIC_`-style exposure of
a privileged key; user-generated content rendered without sanitisation.

---

## Internal tool / admin panel

Held to *lower* standards on polish and *higher* standards on authorization and
audit. Internal tools are where breaches escalate from one account to everything.

- **SSO against the company directory**, never a separate password.
- **Least privilege, per action.** "Internal" is not a permission level. An
  internal tool with a single admin role is a single compromised laptop away
  from total data exposure.
- **Audit log of every read of personal data**, not only writes. This is what a
  regulator asks for after an internal-misuse incident.
- **Rate-limit and confirm destructive actions**; require a typed confirmation
  for anything irreversible, and prefer soft-delete with a restore window.
- **Never expose it to the public internet** without an additional network
  control (VPN, IP allowlist, identity-aware proxy).
- Dangerous operations behind a second approval.

**Early P0s:** the admin panel reachable publicly with only application-level
auth; a single role with unlimited access; bulk export with no logging.

---

## Public API as the product

- **Versioning strategy chosen before the first external consumer**, and a
  deprecation policy with a stated notice period.
- **Authentication:** API keys for server-to-server, OAuth for delegated access.
  Keys are hashed at rest, scoped, rotatable and revocable, with last-used
  tracking.
- **Rate limits per key**, with `X-RateLimit-*` headers and `429` plus
  `Retry-After`. Documented, and enforced before launch — adding limits later
  breaks working integrations.
- **Idempotency keys on every mutating endpoint.** Non-negotiable for anything
  touching money.
- **Consistent pagination** (cursor-based for anything that changes), consistent
  error envelope, consistent field naming.
- **OpenAPI spec generated from the code**, not maintained beside it, or it will
  drift within a month.
- **A sandbox environment** and a changelog.
- **Webhooks** signed, retried with backoff, replayable.

**Early P0s:** no idempotency on a payment endpoint; API keys stored in plaintext;
no rate limiting.

---

## Mobile app

- **Nothing in the bundle is secret.** Any key shipped in the app is public.
  Privileged operations go through your backend.
- **Tokens in the platform keychain/keystore**, never plain preferences.
  Certificate pinning where the threat model warrants it, never disabled TLS
  validation.
- **Forced-upgrade mechanism from v1.** Without it you support every version ever
  shipped, forever, because you cannot make users update.
- **Offline behaviour is a design decision**, not an accident: what is cached,
  what queues, how conflicts resolve.
- **Release cadence is slow.** Feature flags and remote config are how you fix
  things without a store review.
- **Store obligations:** privacy nutrition labels / data safety form must match
  the actual SDK behaviour — including analytics SDKs you did not write.
  Mismatches get apps removed.
- **Deep links validated** as untrusted input.
- **In-app deletion path** — both major stores now require account deletion to be
  available in-app for apps that support account creation. Verify the current
  requirement against the store's live policy; it is enforced at review.

---

## Content site / blog / documentation

- Static generation; no client JavaScript required to read the content.
- Per-page metadata, `Article`/`BreadcrumbList` structured data, an RSS feed.
- Internal linking as a deliberate structure — orphan pages do not rank.
- Image optimisation and explicit dimensions to avoid layout shift.
- A search that works without JavaScript, or degrades gracefully.
- Comment systems are a third party receiving personal data — they belong in the
  privacy policy and behind consent.

---

## Data / AI product

- **Provenance:** where every input came from, what licence covers it, and
  whether users consented to its use. This is the question that ends AI products.
- **PII in training data and prompts.** Do not send personal data to a third-party
  model without a lawful basis, a DPA, and disclosure in the privacy policy.
- **Prompt injection is an authorization problem.** Anything the model can do,
  an attacker who controls its input can attempt. Never give a model direct
  privileged access; put a permission check between the model's intent and the
  action. Treat model output reaching a browser as untrusted content.
- **Cost per request is a product constraint.** Instrument tokens and spend per
  user from day one, with a per-account cap.
- **Non-determinism breaks conventional testing.** Test with evaluation sets and
  measurable criteria, not exact-match assertions.
- **Model version pinning**, and a rollback plan when a provider changes
  behaviour.
- **Disclosure:** users should know when they are interacting with a model and
  what happens to their input. Several jurisdictions now require it.

---

## Regulated domains — flag early, do not improvise

If the product touches any of these, say so plainly and recommend the user get
specialist advice. Build the technical controls; do not opine on legal
compliance.

| Domain | Trigger | Technical consequences |
|---|---|---|
| Payments | Card data touches your systems | PCI DSS scope — avoid entirely by using a hosted payment element |
| Health | Health records, US | HIPAA — BAAs with every processor, encryption, audit logging, minimum necessary access |
| Children | Users under 13 (US) / under 16 (EU varies) | COPPA / GDPR-K — verifiable parental consent, no behavioural advertising |
| Finance | Holding funds, lending, investing | Licensing, KYC/AML, transaction monitoring |
| EU personal data | Any EU user | GDPR — lawful basis, DSAR within one month, 72-hour breach notification |
| Accessibility (public sector, and increasingly private) | Public-facing service | WCAG conformance as a legal requirement, not a nice-to-have |

The engineering answer is almost always the same: **reduce scope**. Do not store
card numbers, do not store health data you do not need, do not collect a birth
date you will not use. The cheapest compliance is data you never held.
