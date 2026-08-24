# Technical SEO

Everything here is about one question: **can a machine find, fetch, render and
correctly attribute your content?** Verify against the live response, never
against source code.

---

## The crawl chain

```
robots.txt allows  →  URL is discoverable  →  server returns 200  →
content renders    →  meta robots allows indexing  →  canonical points here  →
indexed
```

A break anywhere removes the page. Diagnose in that order.

```bash
URL=https://example.com

curl -sSI "$URL"                                   # status, redirects, headers
curl -sS "$URL/robots.txt"
curl -sS -o /dev/null -w '%{http_code}\n' "$URL/definitely-not-real-xyz"   # want 404
curl -sS "$URL" | grep -Eio '<title>[^<]*|<meta name="description"[^>]*|<link rel="canonical"[^>]*'
curl -sS -A 'Googlebot' "$URL" | wc -c             # does content differ for a crawler?
```

---

## `robots.txt`

```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /account/
Disallow: /api/
Disallow: /search
Disallow: /*?sort=
Disallow: /*?filter=

Sitemap: https://example.com/sitemap.xml
```

**The critical distinction:** `robots.txt` controls **crawling**, not
**indexing**. A page blocked in `robots.txt` can still be indexed (from external
links) — the crawler simply cannot see its content or its `noindex`. To remove a
page from the index, allow crawling and use `<meta name="robots" content="noindex">`.

**Check on every deploy.** `Disallow: /` shipped from a staging configuration is
one of the highest-impact, lowest-visibility incidents a site can have: traffic
decays over weeks, and by the time anyone notices, recovery takes weeks more.

Never rely on `robots.txt` for privacy. It is a public file that lists exactly
what you consider sensitive.

---

## Sitemaps

- **Generated at build time**, never hand-maintained. A stale sitemap is worse
  than none.
- Only **canonical, indexable, 200-returning** URLs. A sitemap containing
  redirects, 404s or `noindex` pages wastes crawl budget and signals low quality.
- `<lastmod>` accurate — if every page claims today's date, the signal is
  discarded.
- Split at 50,000 URLs or 50MB with a sitemap index.
- Separate sitemaps per content type make diagnosis easier (which section is
  under-indexed?).
- Referenced from `robots.txt` and submitted to the search console.

---

## Canonicals

```html
<link rel="canonical" href="https://example.com/products/desk">
```

- **Self-referencing by default** on every page. It resolves the duplication
  caused by tracking parameters, session ids and case variations.
- Absolute URL, matching the preferred protocol and hostname exactly.
- A canonical is a **hint**, not a directive. If the canonical target does not
  match the page's content closely, it will be ignored.
- **The failure to look for:** a canonical set in a shared layout pointing every
  page at the homepage. It removes the entire site from the index except one
  page, and it is invisible unless you check per page.
- Paginated series: each page self-canonicals. Do not canonical page 2 to page 1
  — the content on page 2 then has no indexable home.
- Cross-domain canonicals for syndicated content.

---

## Redirects

- **301** for permanent, **302** only for genuinely temporary.
- **One hop.** Every chain link is a full round trip and dilutes signals. Audit
  with `curl -sSIL` and count.
- Never redirect everything to the homepage. A missing page should 404 (or 410);
  redirecting it to `/` is a soft 404 that frustrates users and confuses
  crawlers.
- Redirect the non-canonical hostname (`www` ↔ apex) and protocol at the edge, in
  one hop.
- Keep the redirect map after a migration — permanently.

---

## Status codes

| Code | Use | Common mistake |
|---|---|---|
| 200 | Content exists | Returned for a missing page ("soft 404") |
| 301 | Permanent move | Chains of three or four |
| 302 | Temporary | Used for permanent moves, losing signals |
| **404** | **Not found** | Returning 200 with "not found" text |
| 410 | Permanently gone | Rarely used; it removes from the index faster than 404 |
| 451 | Legally blocked | |
| 500 | Server error | Returned for user errors, or leaking a stack trace |
| 503 | Temporary unavailable | Use with `Retry-After` during planned maintenance |

**Test the soft 404 explicitly.** It is the most common technical SEO defect and
it is invisible in a browser:

```bash
curl -o /dev/null -sS -w '%{http_code}\n' https://example.com/this-does-not-exist-xyz
```

---

## Rendering

Search engines execute JavaScript, but rendering is queued, delayed and
resource-limited. Content that requires client-side JavaScript is indexed later
and less reliably — and AI crawlers and social preview bots frequently do not
execute JavaScript at all.

**Decide per route:**

| Content | Strategy |
|---|---|
| Marketing, blog, docs, product pages | Static or server-rendered. Non-negotiable |
| Personalised but public | Server-render the shell and the content |
| Behind a login | Client-render freely; it is not indexed anyway |

**Test what a crawler sees:**
```bash
curl -sS https://example.com/product/x | grep -c "the product description text"
# 0 means the content is client-rendered only
```

Also verify: does the page render without JavaScript? Are links real `<a href>`
elements (a `div` with an `onclick` is not a link and is not crawlable)? Are
`og:` tags in the server response (social bots do not run JavaScript)?

---

## Index hygiene

Uncontrolled URL generation creates thousands of thin, near-duplicate pages that
dilute the site's quality signals.

**Keep out of the index:** faceted filter and sort combinations, internal search
results, session or tracking parameter variants, print views, pagination beyond
useful depth, tag pages with one item, staging and preview subdomains.

**Mechanisms**, in order of directness: `noindex` (allow crawling so it is seen);
canonical to the clean version; `robots.txt` for parameters that generate
infinite space; and `rel="nofollow"` on links into filter space.

**Protect staging with HTTP authentication**, not just `noindex`. A publicly
reachable staging site will be crawled, will be indexed, and will compete with
production.

---

## Site migrations — the high-risk operation

Traffic loss from a botched migration is severe and slow to recover. The
checklist:

- [ ] Complete URL map, old → new, for **every** indexed URL. Export from
      Search Console, analytics and the sitemap; do not rely on the sitemap
      alone.
- [ ] 301 redirects, **one hop**, tested in bulk before launch.
- [ ] Canonicals updated to the new URLs.
- [ ] Internal links updated to point directly at the new URLs, not through
      redirects.
- [ ] `robots.txt` and sitemap regenerated for the new structure.
- [ ] Structured data preserved and re-validated.
- [ ] Analytics and tag configuration updated.
- [ ] Search Console: new property verified; change-of-address submitted for a
      domain change.
- [ ] Baseline captured before launch: rankings, traffic, indexed page count.
- [ ] Monitor daily for four weeks: index coverage, crawl errors, 404 spikes,
      ranking movement.

**Never** launch a redesign and a domain change and a URL restructure in the same
release. When traffic drops, you will not know which one caused it.

---

## Core Web Vitals

Page experience is a real ranking input and a definite conversion input. See the
`performance-engineering` skill.

Field data (real users, p75) is what counts. Lab scores are for iteration.

---

## International

- `hreflang` on every localised page, **reciprocal** (each variant lists all the
  others, including itself) and using valid language-region codes.
- `x-default` for the fallback.
- One URL pattern: subdirectory (`/es/`) is simplest and inherits domain
  authority; subdomain and ccTLD both split it.
- Do not auto-redirect by IP. Offer a choice and remember it — an automatic
  redirect prevents crawlers (which crawl from one location) from seeing your
  other locales at all.
- Translate metadata and structured data too, not just body copy.

---

## Monitoring

| Check | Frequency | Alert on |
|---|---|---|
| `robots.txt` content | Every deploy | Any change, especially `Disallow: /` |
| Indexed page count | Weekly | Sudden drop |
| Crawl errors | Weekly | New 5xx or a 404 spike |
| Core Web Vitals (field) | Monthly | Any metric leaving "good" |
| Broken internal links | Monthly | Any |
| Structured data validity | Every template change | Any error |
| Canonical correctness | Every deploy | Pages canonicalling elsewhere |
| Certificate expiry | Continuous | 30 days out |

Add a smoke test to CI that fetches the deployed site and asserts: `robots.txt`
does not contain `Disallow: /`, the homepage returns 200 with a non-empty title,
and a random nonexistent path returns 404. Three assertions that prevent the
three most expensive silent failures.
