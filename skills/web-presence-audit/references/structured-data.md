# Structured Data (JSON-LD)

Structured data turns strings into entities. It drives rich results, feeds
knowledge panels, and is increasingly how AI assistants determine what they can
say about you.

**Three rules that keep it working:**

1. **Only mark up what is visible on the page.** Describing content a user
   cannot see violates every search engine's guidelines and gets rich results
   revoked — sitewide, not just on the offending page.
2. **Never fabricate.** Invented ratings, reviews or prices are detectable and
   are fraud.
3. **Validate after every template change.** Structured data breaks silently;
   nothing in your application will tell you.

Use JSON-LD in a `<script>` tag. Microdata and RDFa still work but are harder to
maintain because they are entangled with markup.

---

## The sitewide graph

Put this on every page. `@id` values let other blocks reference these entities
instead of repeating them.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://example.com/#organization",
      "name": "Devleck",
      "legalName": "Devleck LLC",
      "url": "https://example.com",
      "logo": {
        "@type": "ImageObject",
        "url": "https://example.com/logo.png",
        "width": 512, "height": 512
      },
      "foundingDate": "2021-03-01",
      "founder": { "@type": "Person", "name": "Aleck Martinez" },
      "sameAs": [
        "https://www.linkedin.com/company/devleck",
        "https://github.com/Kin9Zeus",
        "https://x.com/devleck"
      ],
      "contactPoint": [{
        "@type": "ContactPoint",
        "contactType": "customer support",
        "email": "support@example.com",
        "telephone": "+1-555-0100",
        "availableLanguage": ["English", "Spanish"],
        "hoursAvailable": {
          "@type": "OpeningHoursSpecification",
          "dayOfWeek": ["Monday","Tuesday","Wednesday","Thursday","Friday"],
          "opens": "09:00", "closes": "18:00"
        }
      }]
    },
    {
      "@type": "WebSite",
      "@id": "https://example.com/#website",
      "url": "https://example.com",
      "name": "Devleck",
      "publisher": { "@id": "https://example.com/#organization" },
      "inLanguage": "en-US"
    }
  ]
}
</script>
```

`sameAs` links are how a search engine connects your site to your social and
directory profiles into one entity. Include every profile you actually control.

---

## LocalBusiness — for any physical or service-area business

This is what drives map results and the local pack. Without it, a local business
is largely invisible in the searches that matter most to it.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "ProfessionalService",
  "@id": "https://example.com/#localbusiness",
  "name": "Devleck",
  "description": "Senior software engineering consultancy.",
  "url": "https://example.com",
  "telephone": "+1-555-0100",
  "email": "hello@example.com",
  "priceRange": "$$$",
  "image": ["https://example.com/office.jpg"],
  "logo": "https://example.com/logo.png",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main Street, Suite 400",
    "addressLocality": "Austin",
    "addressRegion": "TX",
    "postalCode": "78701",
    "addressCountry": "US"
  },
  "geo": { "@type": "GeoCoordinates", "latitude": 30.2672, "longitude": -97.7431 },
  "openingHoursSpecification": [
    { "@type": "OpeningHoursSpecification",
      "dayOfWeek": ["Monday","Tuesday","Wednesday","Thursday","Friday"],
      "opens": "09:00", "closes": "18:00" }
  ],
  "areaServed": [
    { "@type": "City", "name": "Austin" },
    { "@type": "State", "name": "Texas" }
  ],
  "hasMap": "https://maps.google.com/?cid=...",
  "sameAs": ["https://www.linkedin.com/company/devleck"],
  "parentOrganization": { "@id": "https://example.com/#organization" }
}
</script>
```

**Choose the most specific type** — `Restaurant`, `Dentist`, `LawFirm`,
`ProfessionalService`, `Store`, `HomeAndConstructionBusiness`. Specificity
enables type-specific features.

**NAP consistency is the whole game in local.** Name, Address and Phone must be
byte-identical across the site, the schema, the business profile and every
directory listing. "Suite 400" vs "Ste. 400" splits the entity and suppresses
ranking.

**Multiple locations:** one page per location, each with its own
`LocalBusiness` block and a unique `@id`, all with `parentOrganization` pointing
at the sitewide `Organization`.

---

## FAQPage

Directly answers questions, is eligible for rich results, and is among the most
frequently cited structures by AI assistants.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "How long does implementation take?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Most projects go live in 4 to 6 weeks. Discovery takes one week, build takes two to four, and testing and handover take one. Larger migrations can run to 12 weeks; we give a firm estimate after discovery."
      }
    },
    {
      "@type": "Question",
      "name": "Do you offer a guarantee?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes. If the delivered work does not meet the agreed acceptance criteria, we fix it at no additional cost. We also provide 30 days of post-launch support with every project."
      }
    }
  ]
}
</script>
```

**The question and answer text must appear visibly on the page**, in the same
words. Schema-only FAQ content is a guidelines violation.

Write real answers, not one-liners. A complete, specific answer is what gets
surfaced; a vague one is skipped.

---

## Article / BlogPosting

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "Migrating Postgres 14 to 16 Without Downtime",
  "description": "A step-by-step account of a zero-downtime major-version upgrade on a 2TB production database.",
  "image": ["https://example.com/posts/pg-migration-1200x630.png"],
  "datePublished": "2026-08-24T09:00:00-05:00",
  "dateModified": "2026-08-24T09:00:00-05:00",
  "author": {
    "@type": "Person",
    "name": "Aleck Martinez",
    "url": "https://example.com/about/aleck",
    "jobTitle": "Founder & Principal Engineer"
  },
  "publisher": { "@id": "https://example.com/#organization" },
  "mainEntityOfPage": { "@type": "WebPage", "@id": "https://example.com/blog/pg-migration" },
  "wordCount": 2400,
  "articleSection": "Engineering",
  "inLanguage": "en-US"
}
</script>
```

`dateModified` must reflect a **genuine** content change. Bumping it without
editing is detectable and erodes trust in every other signal you send.

---

## Product and Offer

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Standing Desk Pro",
  "description": "Height-adjustable desk, 120x70cm, 10-year frame warranty.",
  "image": ["https://example.com/desk-1x1.jpg", "https://example.com/desk-16x9.jpg"],
  "sku": "SDP-120-WHT",
  "gtin13": "0123456789012",
  "brand": { "@type": "Brand", "name": "Devleck" },
  "offers": {
    "@type": "Offer",
    "url": "https://example.com/products/standing-desk-pro",
    "priceCurrency": "USD",
    "price": "649.00",
    "priceValidUntil": "2027-12-31",
    "availability": "https://schema.org/InStock",
    "itemCondition": "https://schema.org/NewCondition",
    "shippingDetails": {
      "@type": "OfferShippingDetails",
      "shippingRate": { "@type": "MonetaryAmount", "value": "0", "currency": "USD" },
      "deliveryTime": {
        "@type": "ShippingDeliveryTime",
        "handlingTime": { "@type": "QuantitativeValue", "minValue": 1, "maxValue": 2, "unitCode": "DAY" },
        "transitTime": { "@type": "QuantitativeValue", "minValue": 2, "maxValue": 5, "unitCode": "DAY" }
      }
    },
    "hasMerchantReturnPolicy": {
      "@type": "MerchantReturnPolicy",
      "returnPolicyCategory": "https://schema.org/MerchantReturnFiniteReturnWindow",
      "merchantReturnDays": 30,
      "returnMethod": "https://schema.org/ReturnByMail",
      "returnFees": "https://schema.org/FreeReturn"
    }
  }
}
</script>
```

**Price, availability and shipping must match the page exactly.** A mismatch
between structured data and displayed price is a policy violation and, in some
jurisdictions, a consumer-protection issue.

**`AggregateRating` only from real, verifiable reviews** that are displayed on
the page. Fabricated ratings are fraud.

---

## BreadcrumbList

Cheap, universally supported, and it improves how your URL is displayed in
results. Put it on every page below the top level.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com" },
    { "@type": "ListItem", "position": 2, "name": "Desks", "item": "https://example.com/desks" },
    { "@type": "ListItem", "position": 3, "name": "Standing Desk Pro" }
  ]
}
</script>
```

The last item has no `item` — it is the current page.

---

## SoftwareApplication / SaaS

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Devleck Analytics",
  "applicationCategory": "BusinessApplication",
  "operatingSystem": "Web",
  "offers": {
    "@type": "Offer", "price": "29.00", "priceCurrency": "USD",
    "priceSpecification": {
      "@type": "UnitPriceSpecification",
      "price": "29.00", "priceCurrency": "USD",
      "unitText": "user/month",
      "billingDuration": 1,
      "billingIncrement": 1
    }
  },
  "featureList": ["Real-time dashboards", "SQL access", "SSO"],
  "screenshot": "https://example.com/screenshot.png"
}
</script>
```

Other common types worth knowing: `Event`, `JobPosting`, `Recipe`, `Course`,
`VideoObject`, `HowTo`, `Person`, `Service`, `Review`.

---

## Validation and monitoring

| Tool | Checks |
|---|---|
| Google Rich Results Test | Eligibility for rich results, per URL |
| Schema.org Validator | Syntax and vocabulary correctness |
| Search Console → Enhancements | Errors across the whole site, over time |
| Social debuggers (per platform) | Open Graph rendering; forces a cache re-scrape |

**Automate it.** A single test in CI that fetches key pages, extracts every
`application/ld+json` block, parses it, and asserts required fields exist. Ten
lines of code that catch the template change which silently removed your product
schema three weeks ago.

```bash
curl -sS https://example.com/products/x \
  | grep -o '<script type="application/ld+json">.*</script>' \
  | sed 's/<[^>]*>//g' | jq .
```

---

## Common mistakes

| Mistake | Consequence |
|---|---|
| Marking up invisible content | Guidelines violation; rich results revoked sitewide |
| Fabricated reviews or ratings | Fraud; manual penalty |
| `dateModified` bumped without a change | Trust erosion; detectable |
| Price in schema ≠ price on page | Policy violation; possible consumer-protection issue |
| Relative image URLs | Silently ignored |
| Multiple conflicting `Organization` blocks | Entity confusion; nothing resolves |
| FAQ schema with no visible FAQ | Violation |
| Schema added once and never validated again | Silent breakage after a template change |
| `LocalBusiness` with inconsistent NAP | Split entity; suppressed local ranking |
