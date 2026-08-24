---
description: Audit the public web surface — SEO, metadata, structured data, 404, robots, internal links, accessibility and the trust/conversion layer.
argument-hint: "[URL or path]"
---

# Web Presence Audit

Audit the public surface of: **$ARGUMENTS**

Load `web-presence-audit`. Load `accessibility-audit` for the a11y pass and
`privacy-compliance` for the cookie and legal-page pass.

Only assess a site the user owns or is authorised to assess.

## Run the live check first

```bash
skills/web-presence-audit/scripts/web-check.sh <url>
```

(or `web-check.ps1` on Windows). It is read-only — a handful of GET and HEAD
requests, no crawling. It covers the crawlable, legible, structured and trust
layers automatically. Then confirm by hand and go deeper.

## The four layers

```
1 CRAWLABLE   robots.txt · sitemap · REAL 404 status · canonicals · HTTPS
              · one hostname · render-without-JS · no index bloat
2 LEGIBLE     unique title AND description PER PAGE · canonical · Open Graph
              with an absolute-URL 1200x630 image · alt text · one h1 · lang
3 STRUCTURED  Organization · WebSite · LocalBusiness (if physical/service area)
              · FAQPage · BreadcrumbList · Article/Product — all validated
4 TRUSTED     custom 404 · FAQ page · case studies · thank-you page ·
              response-time commitment · sticky mobile CTA · internal links ·
              about/team · pricing · privacy · terms · cookies · deletion path
```

## The two failures that silently destroy traffic

**A soft 404** — a missing page returning `200`. Every mistyped URL becomes an
indexable thin page.
```bash
curl -o /dev/null -sS -w '%{http_code}\n' https://site.com/definitely-not-real-xyz
```

**A staging `robots.txt` in production** — `Disallow: /` removes the site from
search, and nobody notices for weeks.
```bash
curl -sS https://site.com/robots.txt | grep -E '^\s*Disallow:\s*/\s*$'
```

Also check: does any page canonical to the homepage? That de-indexes everything
but one page, and it is invisible unless you check per page.

## Report per page, with the replacement text

A finding that says "write a meta description" is half a finding. One that
supplies the description is a completed task.

```markdown
| Page | Title | Desc | Canon | OG img | H1 | Alt | Links in | Schema |
|---|---|---|---|---|---|---|---|---|
| / | ✓ 54ch | ✗ | ✓ | ✓ | ✓ | 12/12 | — | Org, WebSite |
| /pricing | ⚠ dup of / | ✗ | ✓ | ✗ | ✓ | 3/5 | 4 | none |
```

Then the prioritised findings, then the suggested copy.

## Trust layer — ask as a stranger

1. Within five seconds, do I know what this is and who it is for?
2. Do I believe a real organisation is behind it? (Names, faces, an address.)
3. Can I find out what it costs?
4. Is there evidence it works, with numbers, from named people?
5. Do I know what happens if I make contact, and how fast?
6. Are my objections answered without having to ask?
7. On my phone, is the action always reachable — without covering the content?
8. If I land on a broken URL, am I recovered or lost?
9. Do I know what happens to my data, and can I get it deleted?

Every "no" is a finding with a page attached.
