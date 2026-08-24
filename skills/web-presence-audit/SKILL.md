---
name: web-presence-audit
description: Audit and build the public surface of a website to professional standards — technical SEO (robots.txt, sitemap, canonicals, indexing, custom 404), on-page metadata (unique titles, meta descriptions, Open Graph and social share images, alt text), structured data including LocalBusiness and FAQ schema, internal linking architecture, and the trust and conversion surface (case studies, FAQ page, response-time commitment, thank-you pages, sticky mobile CTA, cookie notice, legal pages). Use when the user shares a website URL, or says "SEO", "meta tags", "robots.txt", "sitemap", "404 page", "not showing up in Google", "structured data", "schema markup", "Open Graph", "social preview", "alt text", "internal links", "landing page", "trust", "conversion", "case studies", "FAQ page" or "make my site professional"; and as a mandatory pass in any audit of a public-facing project. By Devleck.
license: MIT
---

# Web Presence Audit

The public surface is where the product meets people who do not yet trust it.
Every gap here costs traffic, conversion or credibility — and unlike most
engineering debt, the cost is continuous and silent.

This skill covers four layers. Run them in order; each depends on the one above.

```
1. CRAWLABLE   Can a machine find, fetch and index this at all?
2. LEGIBLE     Does each page declare what it is, uniquely and correctly?
3. STRUCTURED  Can a machine understand the entities and answer questions with it?
4. TRUSTED     Would a stranger believe this is a real business and act?
```

Verify against the **live rendered page**, not the source. Server-side headers,
proxies, CDNs and client-side rendering all change what a crawler actually sees.
Run `scripts/web-check.sh <url>` for the automated first pass.

---

## Layer 1 — Crawlable

| Check | Requirement | Severity if missing |
|---|---|---|
| `robots.txt` | Exists at the root, does not accidentally block the site, references the sitemap | P1 |
| `sitemap.xml` | Generated (never hand-maintained), only canonical indexable URLs, submitted to Search Console | P2 |
| **Custom 404** | Returns a **real 404 status**, offers navigation and search, does not dead-end | P2 |
| Custom 500 | Branded, leaks no stack trace | P2 |
| Canonical URL | One per page, self-referencing by default | P2 |
| HTTPS | Enforced, HTTP redirected once, no mixed content | P1 |
| One hostname | `www` and apex resolve to one canonical host, 301 not 302 | P2 |
| Trailing slash | Consistent; the other form redirects | P3 |
| No index bloat | Filters, sorts, pagination and internal search not indexable | P2 |
| Render check | Content present without JavaScript, or server-rendered | P1 for a content site |
| No orphan pages | Every important page reachable by internal links | P2 |

**The two failures that silently destroy traffic:**

**A soft 404** — a missing page returning `200` with "not found" text. Crawlers
index it, and every mistyped URL becomes a thin duplicate page. Test with
`curl -o /dev/null -w '%{http_code}' https://site.com/nonexistent-xyz`.

**A blocking `robots.txt` shipped from staging.** `Disallow: /` deployed to
production removes the site from search entirely, and nobody notices for weeks.
Check it on every deploy.

```
# robots.txt — a sane default
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/
Disallow: /*?sort=
Disallow: /search

Sitemap: https://example.com/sitemap.xml
```

`robots.txt` controls **crawling**, not indexing. To keep a page out of the
index, use `<meta name="robots" content="noindex">` — and do not also block it in
`robots.txt`, or the crawler cannot see the `noindex`.

---

## Layer 2 — Legible

**Every page needs its own:**

```html
<title>Ergonomic Standing Desks for Home Offices | Devleck</title>
<meta name="description" content="Height-adjustable desks built for small
      spaces, shipped in 3 days with a 10-year frame warranty. Compare six
      models and find yours.">
<link rel="canonical" href="https://example.com/desks/standing">

<!-- Social share — the difference between a link that gets clicked and one
     that looks broken -->
<meta property="og:type" content="website">
<meta property="og:title" content="Ergonomic Standing Desks for Home Offices">
<meta property="og:description" content="...">
<meta property="og:image" content="https://example.com/og/desks.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:url" content="https://example.com/desks/standing">
<meta property="og:site_name" content="Devleck">
<meta property="og:locale" content="en_US">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:image:alt" content="A white standing desk in a small home office">
```

**Titles**
- **Unique on every page.** Duplicated titles are the most common on-page defect
  and they make your pages compete with each other. A site-wide title set in the
  layout is a `P2` finding on every page it touches.
- Roughly 50–60 characters before truncation. The distinctive words go first —
  a title that begins with the brand wastes the position that matters.
- Describe the page, do not stuff keywords.

**Meta descriptions**
- **Unique per page**, roughly 140–160 characters.
- They are not a ranking factor; they are ad copy for the search result. Write
  them to earn the click: state the value and include an implicit call to action.
- Missing means the engine writes one for you, usually badly.

**Social share image (`og:image`)**
- 1200×630, under ~1MB, an **absolute URL** (relative URLs silently fail).
- Legible at thumbnail size — large type, high contrast, no fine detail.
- **Page-specific where it matters.** One generic logo across a whole site is a
  missed opportunity on every share.
- Test with the platforms' own debuggers; each caches aggressively, so a fix is
  not visible until you force a re-scrape.

**Alt text**
- **Every meaningful image** gets alt text describing its *function in context*,
  not its appearance. A product photo's alt is the product; a chart's alt is the
  finding it shows.
- **Decorative images get `alt=""`** — empty, not missing. Missing alt makes a
  screen reader announce the filename.
- Never begin with "image of" or "photo of".
- Text inside an image must be repeated in the alt, or the information is lost
  to search engines and screen readers alike.

**Heading structure**
- Exactly one `<h1>` per page, matching the page's subject.
- Ordered without skipping levels. Headings are structure, not styling — a
  `<h4>` chosen because it looks right is a defect.

**Language and locale**
- `<html lang="en">` set correctly.
- `hreflang` for multi-language sites, reciprocal and self-referencing.

---

## Layer 3 — Structured

Structured data (JSON-LD) is how a machine understands entities rather than
strings. It drives rich results, knowledge panels, and increasingly what AI
assistants can cite about you.

**The baseline set for any business site:**

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://example.com/#org",
      "name": "Devleck",
      "url": "https://example.com",
      "logo": "https://example.com/logo.png",
      "sameAs": [
        "https://www.linkedin.com/company/devleck",
        "https://github.com/Kin9Zeus"
      ],
      "contactPoint": {
        "@type": "ContactPoint",
        "contactType": "customer support",
        "email": "support@example.com",
        "availableLanguage": ["English", "Spanish"]
      }
    },
    {
      "@type": "WebSite",
      "@id": "https://example.com/#website",
      "url": "https://example.com",
      "name": "Devleck",
      "publisher": { "@id": "https://example.com/#org" }
    }
  ]
}
</script>
```

**`LocalBusiness` — for any business with a physical location or a service area.**
This is what drives map results and the local pack; without it a local business
is largely invisible in the search that matters most to it.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "@id": "https://example.com/#localbusiness",
  "name": "Devleck",
  "image": "https://example.com/storefront.jpg",
  "url": "https://example.com",
  "telephone": "+1-555-0100",
  "priceRange": "$$",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main Street",
    "addressLocality": "Austin",
    "addressRegion": "TX",
    "postalCode": "78701",
    "addressCountry": "US"
  },
  "geo": { "@type": "GeoCoordinates", "latitude": 30.2672, "longitude": -97.7431 },
  "openingHoursSpecification": [{
    "@type": "OpeningHoursSpecification",
    "dayOfWeek": ["Monday","Tuesday","Wednesday","Thursday","Friday"],
    "opens": "09:00", "closes": "18:00"
  }],
  "areaServed": { "@type": "City", "name": "Austin" }
}
</script>
```

**NAP consistency** — Name, Address, Phone must be byte-identical across the
site, the schema, the business listing and every directory. Inconsistency
splits the entity and suppresses local ranking.

**Per page type:** `Article` / `BlogPosting` (with `author`, `datePublished`,
`dateModified`), `Product` + `Offer`, `FAQPage`, `BreadcrumbList`,
`SoftwareApplication`, `Event`, `Recipe`, `JobPosting`.

**Rules that keep it working:**
- **Mark up only what is visible on the page.** Schema describing content a user
  cannot see is a policy violation and gets rich results revoked.
- **Never fabricate reviews or ratings.** Invented `AggregateRating` is fraud,
  and it is detectable.
- Validate with the Rich Results Test and the Schema.org validator after every
  template change. Silent breakage is the norm.

`references/structured-data.md` has the full templates.

---

## Layer 4 — Trusted

This is the layer engineers skip and businesses lose money to. A technically
perfect site that reads as anonymous does not convert.

### Internal linking

- **Every important page reachable within three clicks of the homepage.** An
  orphan page is one nobody — human or crawler — will find.
- **Descriptive anchor text.** "Read our pricing" beats "click here" for
  accessibility, for search, and for the reader scanning the page.
- Contextual links inside body content, not only in the navigation. Contextual
  links carry topical meaning that a nav link does not.
- **Breadcrumbs** on any site deeper than two levels, with `BreadcrumbList`
  schema.
- A related-content block on articles and products.
- **Fix broken internal links.** They waste crawl budget and read as neglect.
- An HTML sitemap page for large sites.

### The pages a credible business has

| Page | Why it matters |
|---|---|
| **Custom 404** | A dead end loses the visitor. Offer navigation, search and the top destinations |
| **FAQ page** | Answers objections before they become "I'll think about it". Mark up with `FAQPage` schema for rich results and AI citation |
| **Case studies** | The single most persuasive asset a B2B or service business has. Structure: the client's situation → what was done → **measured outcome** → a quote. Vague case studies are worse than none |
| **Thank-you page** | A real URL, not a modal. It is the conversion tracking anchor, and it is where you set the next expectation ("we reply within 4 business hours") and offer the next step |
| **About / team** | Real names, real photos, real location. Anonymity is the strongest negative trust signal on the internet |
| **Contact** | Multiple channels, a **stated response time**, and a real address if there is one |
| **Pricing** | Even a range. "Contact us for pricing" loses visitors who will not start a conversation blind |
| **Privacy policy** | Legally required almost everywhere. See `privacy-compliance` |
| **Terms of service** | Required for anything transactional |
| **Cookie notice** | Must **gate scripts before consent**, not apologise after. See `privacy-compliance` |
| **Data deletion** | A self-service path, not "email us". See `privacy-compliance` |
| **Status page** | For any SaaS. Silence during an outage costs more than the outage |
| **Security / `security.txt`** | A disclosure contact at `/.well-known/security.txt` |

### The response-time commitment

State it explicitly, wherever a visitor is deciding whether to make contact —
the contact page, the form, the thank-you page and the footer:

> **We reply to every enquiry within one business day.**
> Support: within 4 business hours, Monday–Friday, 09:00–18:00 CET.

Two reasons this matters more than it looks. It removes the "will anyone even
answer?" hesitation at the exact moment of decision. And it is a promise, so it
must be **true and monitored** — an unmet stated commitment does more damage than
no commitment at all.

### Sticky mobile CTA

More than half of traffic is mobile, and mobile users scroll far and rarely
scroll back. A persistent bottom bar keeps the action always one tap away.

```html
<div class="cta-bar" role="region" aria-label="Primary action">
  <a href="/get-started" class="cta-bar__button">Get a free quote</a>
</div>
```
```css
.cta-bar {
  position: fixed; inset-inline: 0; bottom: 0; z-index: 40;
  padding: .75rem 1rem calc(.75rem + env(safe-area-inset-bottom));
  background: var(--surface); border-top: 1px solid var(--border);
}
@media (min-width: 768px) { .cta-bar { display: none; } }   /* mobile only */
```

**Do it correctly, or it costs more than it gains:**
- Add matching `padding-bottom` to the page so it never covers content —
  especially the last form field or the footer links.
- One action only. Two competing buttons in a 60px bar is a decision, not a CTA.
- Minimum 44×44px touch target; respect `env(safe-area-inset-bottom)` on
  notched devices.
- Keyboard reachable, and not a focus trap.
- Do not stack it with a cookie banner and a chat widget — three fixed elements
  is 40% of a phone screen and reads as hostile.

### Trust signals throughout

Real customer logos (with permission), specific testimonials with a name, role
and company, third-party review scores, certifications and compliance badges,
a physical address, years in business, and any guarantee you actually offer.

**Specific beats superlative.** "Reduced their onboarding from 6 weeks to 4 days"
is persuasive; "world-class solutions" is noise.

---

## Reporting

Report per page, not per site — "meta descriptions are missing" is not
actionable; a table of which pages, with the suggested text, is.

```markdown
| Page | Title | Description | Canonical | OG image | H1 | Alt gaps | Schema |
|---|---|---|---|---|---|---|---|
| / | ✓ | ✗ missing | ✓ | ✓ | ✓ | 0/12 | Organization, WebSite |
| /pricing | ⚠ duplicate of / | ✗ missing | ✓ | ✗ | ✓ | 2/5 | none |
| /blog/x | ✓ | ✓ | ✗ points to / | ✓ | ⚠ two h1 | 4/9 | Article |
```

Then the prioritised findings, with the exact replacement text where you can
supply it. A finding that says "write a meta description" is half a finding; one
that includes the description is a completed task.

## References, templates and scripts

- `references/technical-seo.md` — crawling, indexing, canonicals, redirects, migrations
- `references/onpage-and-content.md` — titles, descriptions, headings, images, internal linking
- `references/structured-data.md` — JSON-LD templates for every common page type
- `references/trust-and-conversion.md` — the trust surface, case studies, FAQ, CTA, forms
- `templates/robots.txt` · `templates/404-page.md` · `templates/faq-page.md` ·
  `templates/case-study.md` · `templates/thank-you-page.md`
- `scripts/web-check.sh` / `scripts/web-check.ps1` — live surface check for any URL
