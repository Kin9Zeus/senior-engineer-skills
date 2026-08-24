---
name: performance-engineering
description: Performance engineering across the stack — Core Web Vitals (LCP, INP, CLS), bundle size and rendering strategy, image and font optimisation, backend latency budgets, caching layers, database query cost, profiling, and load testing. Use when the user says "slow", "performance", "optimize", "Core Web Vitals", "LCP", "INP", "CLS", "Lighthouse", "PageSpeed", "bundle size", "page speed", "latency", "TTFB", "caching", "CDN", "it takes forever to load", "high response times" or "will this scale"; and as a pass in any project audit. By Devleck.
license: MIT
---

# Performance Engineering

Three rules, in order:

1. **Measure first.** Optimising the wrong thing is worse than doing nothing —
   it costs time and adds complexity for no gain.
2. **Fix the biggest thing.** Performance work follows a power law; one
   bottleneck usually dominates.
3. **Set a budget and enforce it in CI.** Performance regresses by accretion, one
   small addition at a time, and is only ever recovered by deliberate effort.

Never report "this will be slow" without a measurement. Never report a
measurement without saying what it was measured on.

---

## Frontend: the numbers that matter

Core Web Vitals, measured at the **75th percentile of real users** — not from
your laptop on office wifi.

| Metric | Good | Needs work | Poor | What it measures |
|---|---|---|---|---|
| **LCP** | ≤ 2.5s | ≤ 4.0s | > 4.0s | When the main content appears |
| **INP** | ≤ 200ms | ≤ 500ms | > 500ms | Responsiveness to interaction |
| **CLS** | ≤ 0.1 | ≤ 0.25 | > 0.25 | Visual stability |

Supporting: TTFB (≤ 800ms), total JavaScript, and total page weight.

**Lab vs field.** Lighthouse is a lab tool: reproducible, useful for catching
regressions, and not what your users experience. Field data (Chrome UX Report,
or your own real-user monitoring) is the truth. Use lab to iterate, field to
decide.

---

## LCP — usually the highest-leverage fix

LCP is almost always an image or a heading blocked by something.

1. **Find the element.** Chrome DevTools Performance panel marks it; PageSpeed
   Insights names it.
2. **Attack the chain** in this order:
   - **TTFB** — slow server, no CDN, no caching, a slow database query in the
     render path.
   - **Render-blocking resources** — synchronous CSS and JS in `<head>`. Inline
     critical CSS, defer the rest.
   - **Resource load time** — the image itself: format, size, compression.
   - **Element render delay** — waiting on JavaScript, or on a font.
3. **Preload the LCP image** (`<link rel="preload" fetchpriority="high">`), and
   never lazy-load it. Lazy-loading the hero image is one of the most common
   self-inflicted LCP problems.

**Images**, the single biggest lever on most sites:
```html
<img src="hero-800.avif" alt="..."
     srcset="hero-400.avif 400w, hero-800.avif 800w, hero-1600.avif 1600w"
     sizes="(max-width: 768px) 100vw, 800px"
     width="1600" height="900"          <!-- always: prevents CLS -->
     fetchpriority="high"                <!-- for the LCP image only -->
     decoding="async">
```
AVIF or WebP with a fallback; responsive `srcset`; explicit dimensions; lazy-load
everything **below** the fold and nothing above it.

**Fonts:** `font-display: swap` (or `optional`), preload the one face used above
the fold, self-host, subset to the characters you use, and set a metric-matched
fallback so the swap does not shift layout.

---

## INP — responsiveness

INP measures the worst interaction latency. It is dominated by long tasks
blocking the main thread.

- **Break up long tasks.** Anything over 50ms blocks input. Yield to the main
  thread between chunks.
- **Reduce hydration cost.** Server components, islands, partial or progressive
  hydration — ship less JavaScript that must execute before the page is
  interactive.
- **Debounce expensive handlers**; move heavy computation to a Web Worker.
- **Avoid layout thrashing** — reading a layout property after writing one forces
  a synchronous reflow. Batch reads, then writes.
- Virtualise long lists.
- Profile in the Performance panel with CPU throttling on. A fast laptop hides
  everything your users experience on a mid-range phone.

## CLS — stability

Almost entirely preventable:
- `width` and `height` (or `aspect-ratio`) on every image, video and iframe.
- Reserve space for ads, embeds and banners before they load.
- Never insert content above existing content after load — the classic offender
  is a cookie banner or promotional bar that pushes the page down.
- `font-display: optional`, or a metric-matched fallback.
- Animate `transform` and `opacity` only; animating `width`, `height`, `top` or
  `margin` triggers layout on every frame.

---

## JavaScript weight

The most reliable structural improvement available to most sites.

```bash
npx vite-bundle-visualizer         # or: next build (prints per-route sizes)
npx source-map-explorer 'dist/**/*.js'
```

- **Route-level code splitting**, and dynamic imports for heavy components
  (editors, charts, PDF viewers, date-locale data, maps).
- **Audit the largest dependencies.** The usual offenders are a full date library
  where a formatter would do, a full icon set where five icons are used, a
  charting library on a page with one sparkline, and locale data for every
  language.
- Tree-shakeable imports (`import { x } from "lib"`, never `import * as lib`).
- **Question every third-party script.** They are frequently more than half the
  JavaScript on a marketing page, they run on the main thread, and each one is
  also a privacy and security surface. Load them after consent, deferred, or via
  a partytown-style worker.
- Set a **bundle-size budget and fail CI on regression.** Without a gate, bundle
  size only goes one way.

---

## Rendering strategy

Choose per route. Getting this wrong is a structural performance defect that no
amount of micro-optimisation fixes.

| Content | Strategy |
|---|---|
| Marketing, blog, docs | Static generation. Nothing beats a file on a CDN |
| Personalised but crawlable | Server-render, stream where supported |
| Authenticated app | Client render is fine; SEO is irrelevant behind a login |
| Frequently-changing public data | Incremental regeneration or short-TTL edge cache |

A marketing page that ships 400KB of JavaScript to render static text is a
performance *and* an SEO defect.

---

## Backend latency

Set a budget per endpoint before optimising:

```
p50 < 100ms · p95 < 300ms · p99 < 1000ms
```

Then find where the time goes, with a profiler or a trace — never by reading
code and guessing.

**Where backend time actually goes, in order of frequency:**
1. **Database queries** — missing index, N+1, unnecessary data. See
   `database-engineering`. This is the answer most of the time.
2. **Sequential external calls** that could be parallel.
3. **Work in the request path** that belongs in a queue — email, image
   processing, report generation, webhook delivery.
4. **Serialisation** of large payloads.
5. **Application code** — genuinely last, and usually not worth touching until
   the four above are handled.

**Quick wins that are almost always available:** parallelise independent I/O
(`Promise.all` rather than sequential `await`), move non-blocking work to a
queue, add the missing index, enable compression, return less data.

---

## Caching — in order of preference

1. **Make it fast.** Cache is not a substitute for an index; it is a layer over
   one, and it will mask the problem until the cache fails.
2. **CDN / edge** for static assets and public pages. Immutable hashed filenames
   with a long `max-age`, `stale-while-revalidate` for HTML.
3. **HTTP caching** — `ETag`, `Cache-Control` — so browsers stop asking.
4. **Application cache** (Redis) for expensive computed results, with an explicit
   TTL **and an explicit invalidation rule**. If you cannot state the
   invalidation rule, you have stale data, not a cache.
5. **Database-level** — materialised views for expensive aggregates.

**The rule that prevents a `P0`:** never cache user-scoped data in a shared cache
without the user or tenant in the key. Cross-user cache leakage is a data breach,
and it is a recurring one in real audits.

---

## Enforcing it

```yaml
# In CI — performance regresses by accretion unless something stops it
- name: Lighthouse CI
  run: lhci autorun
  # budgets: LCP < 2500ms, CLS < 0.1, total JS < 300KB, TBT < 300ms

- name: Bundle size
  run: npx size-limit    # fails the build on regression
```

Plus, in production: real-user monitoring for Core Web Vitals, and alerts on p95
latency per endpoint against the budget.

---

## The measurement discipline

Every performance claim in a report carries:

```markdown
**Measured:** LCP 4.8s (p75, field data, mobile, last 28 days, n=12,400)
**Cause:**    Hero image is a 2.4MB unoptimised PNG, lazy-loaded, not preloaded
**Fix:**      Convert to AVIF with srcset (est. 180KB), remove loading="lazy",
              add fetchpriority="high"
**Expected:** LCP ~1.9s
**Verify:**   PageSpeed Insights field data after 28 days; Lighthouse CI in the
              meantime
```

Never write "this is slow" or "this will not scale" without the measurement, the
conditions, and the target it is being compared against.

## References

- `references/web-performance.md` — frontend techniques in depth, with a diagnostic order
- `references/backend-performance.md` — profiling, concurrency, caching, capacity planning
