# On-Page and Content

## Titles

The most valuable 60 characters on the page. It is the search result headline,
the browser tab, the bookmark name, and the shared-link text.

```
✓  Ergonomic Standing Desks for Home Offices | Devleck
✓  How to Migrate from Postgres 14 to 16 Without Downtime
✗  Home | Devleck                                        (says nothing)
✗  Devleck | Standing Desks | Office Furniture | Austin  (keyword stuffing)
✗  Untitled                                              (a real, common defect)
```

**Rules**
- **Unique on every page.** Duplicates make your own pages compete. A title set
  once in a shared layout is a `P2` finding on every page it covers.
- 50–60 characters before truncation. Longer is not penalised, it is just cut.
- **Distinctive words first.** Starting with the brand wastes the position the
  eye reads first. Brand goes last, after a separator, and only if it adds
  credibility.
- Describe the page's actual content. A title promising something the page does
  not deliver produces a bounce, which is worse than not ranking.
- One separator style site-wide (`|` or `–`).

**Templates**
```
Homepage    <Value proposition> | <Brand>
Product     <Product> — <key differentiator> | <Brand>
Category    <Category> for <audience> | <Brand>
Article     <Specific, complete promise>
Local       <Service> in <City> | <Brand>
Comparison  <A> vs <B>: <the decision it helps with>
```

---

## Meta descriptions

Not a ranking factor. **Ad copy for your search result**, and the click-through
rate it produces is a real signal.

```
✓  Height-adjustable desks built for small spaces, shipped in 3 days with a
   10-year frame warranty. Compare six models and find yours.

✗  We are a leading provider of quality office furniture solutions for
   discerning customers worldwide.
```

- **Unique per page**, 140–160 characters.
- State the specific value, then imply the action.
- Include the terms a searcher would use — they are bolded in the result, which
  draws the eye.
- Numbers, timeframes and guarantees outperform adjectives.
- Missing means the engine writes one by extracting page text, usually badly.

---

## Headings

Headings are **document structure**, not typography. A `<h4>` chosen because it
looked right is a defect for both accessibility and search.

```html
<h1>Standing Desks for Home Offices</h1>       <!-- exactly one, the page subject -->
  <h2>How to choose a height range</h2>
    <h3>Measuring your seated elbow height</h3>
    <h3>Measuring your standing elbow height</h3>
  <h2>Our six models compared</h2>
  <h2>Frequently asked questions</h2>
```

- Exactly one `h1`, matching the page's subject and usually similar to the title.
- Never skip a level. `h1 → h3` breaks screen-reader navigation.
- Headings describe the section beneath them. A reader should be able to
  understand the page from the headings alone — which is exactly how screen
  reader users and skimmers consume it.

---

## Images

**Alt text**

```html
<!-- Meaningful: describe the FUNCTION in context -->
<img src="desk.jpg" alt="White standing desk raised to standing height in a
                         small home office">

<!-- The image IS a link: describe the destination -->
<a href="/pricing"><img src="pricing.svg" alt="View pricing plans"></a>

<!-- Data visualisation: state the finding, not the shape -->
<img src="chart.png" alt="Revenue grew from $1.2M in 2024 to $4.8M in 2026">

<!-- Decorative: EMPTY alt, not missing -->
<img src="divider.svg" alt="">
```

- **Every meaningful image.** Missing `alt` makes a screen reader announce the
  filename — `DSC_04821.jpg`.
- **`alt=""` for decorative**, so assistive technology skips it entirely.
- Never start with "image of" / "photo of" — the technology already announces
  that it is an image.
- **Text inside an image must appear in the alt**, or that information does not
  exist for search engines or screen readers. Better: do not put text in images.
- Complex charts need a longer description nearby, with the alt pointing to it.
- Under ~125 characters where you can; beyond that, use a caption or adjacent
  text.

**Files and delivery** — see `performance-engineering`. In summary: AVIF/WebP,
responsive `srcset`, explicit `width`/`height` (prevents layout shift), lazy-load
below the fold only, `fetchpriority="high"` on the LCP image, and descriptive
filenames (`standing-desk-white-home-office.jpg`, not `IMG_4821.jpg`).

---

## Internal linking

Internal links do three jobs at once: they help people find things, they
distribute ranking signals through the site, and they tell search engines what
each page is about via anchor text.

**Architecture**
```
Homepage
├── Category            ← linked from the main navigation
│   ├── Product         ← linked from the category and from related products
│   └── Product
├── Blog
│   └── Article         ← linked from the index, from related articles,
│                          and contextually from relevant product pages
└── Trust pages         ← linked from the footer, sitewide
```

- **Three clicks maximum** from the homepage to any important page.
- **No orphans.** A page with no internal links is one nobody will find. Audit by
  comparing the sitemap against the set of internally-linked URLs.
- **Descriptive anchor text.** "See our pricing plans" beats "click here" for
  screen reader users (who navigate by link list), for search engines, and for
  anyone skimming.
- Contextual links **inside body content** carry topical meaning that a
  navigation link does not.
- **Breadcrumbs** on anything deeper than two levels, with `BreadcrumbList`
  schema.
- Related-content blocks on articles and products.
- **Fix broken internal links.** They waste crawl budget and read as neglect —
  a visitor who hits a broken link on your own site downgrades everything else.
- Link to your important pages more often. Internal link count is a signal of
  what you consider important.

```bash
# Find internal links pointing at 404s
npx linkinator https://example.com --recurse --silent | grep -i broken
```

---

## Content quality

Ranking follows usefulness more reliably than it follows optimisation. The
durable version:

- **Answer the question the visitor arrived with**, in the first screen. Do not
  make them scroll past a preamble.
- **Specific beats superlative.** "Reduced onboarding from 6 weeks to 4 days"
  persuades; "world-class solutions" does not.
- **Show your work.** Numbers, screenshots, methodology, sources. This is also
  what makes content citable by AI assistants, which increasingly matters.
- **Demonstrate real experience.** First-hand detail — what actually happened,
  what went wrong — cannot be synthesised and is what distinguishes useful
  content now.
- **Named authors** with credentials and a real bio. Anonymous content is
  discounted by readers and by ranking systems.
- **Dates that are honest.** Show `dateModified` when the content was genuinely
  updated. Bumping a date without changing the content is detectable and
  corrosive.
- **Update rather than accumulate.** One current, comprehensive page outranks
  five thin, stale ones on the same topic — and the five compete with each other.

**The audit question for any page:** *if a person read only this page, would
they have what they came for?* If not, no amount of metadata fixes it.

---

## Forms

Forms are where the conversion actually happens, and where it is usually lost.

- **Ask for the minimum.** Every additional field measurably reduces completion.
  Do you need the phone number now, or after they reply?
- **Labels, always** — visible, and associated with `for`/`id`. Placeholder text
  is not a label: it disappears on focus, fails contrast, and is invisible to
  some assistive technology.
- **Inline validation on blur**, not only on submit. Say what is wrong *and how
  to fix it*: "Enter a date in the future", not "Invalid".
- **Errors are announced** to assistive technology (`aria-live`), associated with
  the field (`aria-describedby`), and never conveyed by colour alone.
- **Correct `type` and `autocomplete`** attributes — the difference between a
  10-second and a 60-second mobile form.
- **Disable the submit button while submitting**, and make the endpoint
  idempotent. Double-submission is a real and common bug.
- **Never lose entered data** on a validation error.
- **Redirect to a real thank-you page** on success — a URL, not a modal. It is
  the conversion tracking anchor and the place to set the next expectation.
- Spam protection that does not punish humans: honeypot fields and timing checks
  first; a challenge only if that is insufficient. Note that a third-party
  challenge is a data flow that belongs in your privacy policy.

---

## Per-page audit table

```markdown
| Page | Title | Desc | Canon | OG img | H1 | Alt | Internal links in | Schema |
|---|---|---|---|---|---|---|---|---|
| / | ✓ 54ch | ✗ | ✓ | ✓ | ✓ | 12/12 | — | Org, WebSite |
| /pricing | ⚠ dup | ✗ | ✓ | ✗ | ✓ | 3/5 | 4 | none |
| /blog/post | ✓ | ✓ 148ch | ✗ → / | ✓ | ⚠ 2×h1 | 5/9 | 1 | Article |
```

Report per page with the **suggested replacement text included**. A finding that
says "write a meta description" is half a finding; one that supplies the
description is a completed task.
