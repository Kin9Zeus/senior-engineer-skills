# Custom 404 Page

## The requirements

1. **Returns HTTP `404`.** A 200 is a soft 404 — the page gets indexed, and every
   mistyped URL becomes a thin duplicate. This is the single most important
   requirement and the one most often missed.
2. **Keeps the full site chrome** — header, navigation, footer, search.
3. **Recovers the visitor** with search and the top destinations.
4. **Explains plainly**, without blaming them and without an error code dump.
5. **Logs the hit with the referrer**, so you find your own broken links.

---

## Markup

```html
<!-- Server MUST respond with status 404 -->
<main id="content">
  <section class="notfound">
    <p class="notfound__code" aria-hidden="true">404</p>

    <h1>We couldn't find that page</h1>
    <p class="notfound__lead">
      The link may be out of date, or the page may have moved.
      Here are a few ways to get back on track.
    </p>

    <form action="/search" method="get" role="search" class="notfound__search">
      <label for="q">Search the site</label>
      <input type="search" id="q" name="q" autocomplete="off"
             placeholder="What are you looking for?" required>
      <button type="submit">Search</button>
    </form>

    <nav aria-labelledby="popular">
      <h2 id="popular">Popular pages</h2>
      <ul>
        <li><a href="/">Home</a></li>
        <li><a href="/services">What we do</a></li>
        <li><a href="/case-studies">Case studies</a></li>
        <li><a href="/pricing">Pricing</a></li>
        <li><a href="/contact">Contact us</a></li>
      </ul>
    </nav>

    <p class="notfound__help">
      Still stuck? <a href="/contact">Get in touch</a> — we reply within one
      business day.
    </p>
  </section>
</main>
```

**Metadata**
```html
<title>Page not found (404) | Devleck</title>
<meta name="robots" content="noindex, follow">
```
`follow` matters: the crawler should still traverse the recovery links.

Do **not** set a canonical on the 404 page. Pointing it at the homepage tells the
crawler this *is* the homepage.

---

## Implementation

| Stack | How |
|---|---|
| Next.js (app) | `app/not-found.tsx` — served with a 404 automatically |
| Next.js (pages) | `pages/404.js` |
| Nuxt | `error.vue`, branching on `error.statusCode === 404` |
| SvelteKit | `src/routes/+error.svelte` |
| Django | `templates/404.html` (requires `DEBUG = False`) |
| Rails | `public/404.html`, or a dynamic route |
| Laravel | `resources/views/errors/404.blade.php` |
| Express | A final middleware: `res.status(404).render("404")` |
| Netlify | `404.html` at the publish root |
| Vercel | Framework default, or `vercel.json` routing |
| Nginx | `error_page 404 /404.html;` |
| S3 + CloudFront | Error document configured, **with response code 404** — the default is 200, which produces a soft 404 across the whole site |

**SPA caution:** a single-page app served with a catch-all rewrite returns 200
for every path by definition. You must have the server return a real 404 for
unmatched routes, or every typo becomes an indexable page.

---

## Verify

```bash
# The only test that matters
curl -o /dev/null -sS -w '%{http_code}\n' https://example.com/definitely-not-real-xyz
# Expect: 404

# And that it is a real page, not a stack trace
curl -sS https://example.com/definitely-not-real-xyz | head -40
```

Add both to your deployment smoke tests.

---

## Also do the 500 page

```html
<title>Something went wrong | Devleck</title>
```
- Branded, calm, and **leaking nothing** — no stack trace, no framework version,
  no file path, no SQL.
- Include a **support reference id** that matches your logs:
  "Something went wrong. Reference: `req_01HQ8XYZ`". This turns an
  unreproducible bug report into a single log query.
- Offer a retry and a contact link.
- Return a real `500`, and make sure your error tracker receives it.

---

## Log and act on 404s

```
404 · /old-pricing-page · referrer: https://example.com/services · 42 hits/week
      → an internal broken link. Fix the link.

404 · /blog/2024-guide · referrer: https://partner.com/resources · 310 hits/week
      → an external link to a page you moved. Add a 301.

404 · /wp-admin/setup-config.php · referrer: none · 1,200 hits/week
      → automated scanning. Ignore, or rate-limit.
```

The first two are recoverable traffic and are found nowhere else. Review the 404
log monthly; it is one of the highest-yield, lowest-effort audits available.
