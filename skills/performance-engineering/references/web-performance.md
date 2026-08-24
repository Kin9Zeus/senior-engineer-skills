# Web Performance — Diagnostic Order

Work in this order. Each step's finding changes what the next step means.

---

## Step 1 — Get field data, not lab data

Lab tools (Lighthouse, WebPageTest) are reproducible and useful for iteration.
They are not what your users experience. A score of 98 from a fast laptop on a
fast connection tells you nothing about a mid-range Android on a congested
network — which is a large share of real traffic.

**Sources of truth:**
- Chrome UX Report (real Chrome users, 28-day rolling, p75) — via PageSpeed
  Insights or the CrUX API.
- Your own real-user monitoring, using the `web-vitals` library.

```js
import { onLCP, onINP, onCLS, onTTFB } from "web-vitals";
const send = (metric) => navigator.sendBeacon("/rum", JSON.stringify({
  name: metric.name, value: metric.value, id: metric.id,
  rating: metric.rating, path: location.pathname,
}));
onLCP(send); onINP(send); onCLS(send); onTTFB(send);
```

Segment by device class, connection type, country and route. The aggregate hides
the segment that is actually suffering — and it is usually mobile on a slow
network, which is also usually the segment that converts worst.

---

## Step 2 — Locate the bottleneck

**Waterfall reading, in order:**

1. **TTFB high?** The problem is server-side or network-side. Jump to the backend
   section — no amount of frontend work fixes a 2-second TTFB.
2. **Long gap before anything loads?** Render-blocking resources in `<head>`, or
   a redirect chain.
3. **The LCP resource starts late?** It was discovered late — it is inside
   JavaScript, or behind a CSS import, or not preloaded.
4. **The LCP resource takes long?** It is too big, unoptimised, or on a slow
   origin.
5. **Everything loads but the page is not interactive?** Main-thread blocking —
   too much JavaScript executing.

---

## Step 3 — TTFB

| Cause | Fix |
|---|---|
| No CDN | Put one in front. Largest single win for global audiences |
| Slow origin | Profile the backend; usually a database query in the render path |
| No caching of a cacheable page | `Cache-Control` + `stale-while-revalidate` at the edge |
| Redirect chains | Resolve to the final URL. Each hop is a full round trip |
| No compression | Brotli, falling back to gzip |
| Cold serverless start | Provisioned concurrency, or a lighter runtime |
| TLS negotiation | HTTP/2 or HTTP/3, session resumption, `preconnect` for third-party origins |

---

## Step 4 — Render-blocking resources

```html
<!-- Blocking: nothing renders until this downloads and parses -->
<link rel="stylesheet" href="/styles.css">
<script src="/app.js"></script>

<!-- Non-blocking -->
<style>/* critical, above-the-fold CSS, inlined */</style>
<link rel="preload" href="/styles.css" as="style" onload="this.rel='stylesheet'">
<script src="/app.js" defer></script>
```

- Inline critical CSS; load the rest asynchronously.
- `defer` for scripts that need the DOM; `async` for genuinely independent ones
  (analytics). Never a plain synchronous `<script>` in `<head>`.
- `preconnect` to origins you will definitely use (a font host, an image CDN);
  limit to three or four — each costs a connection.
- `preload` only the resources needed for the initial render. Over-preloading
  competes for bandwidth with the thing you actually needed.

---

## Step 5 — Images

Usually the largest byte contributor, and the easiest win.

| Technique | Effect |
|---|---|
| AVIF / WebP instead of JPEG/PNG | 30–70% smaller |
| Responsive `srcset` + `sizes` | Stop sending 2000px images to 400px viewports |
| Explicit `width`/`height` | Eliminates CLS |
| `loading="lazy"` below the fold | Defers what is not needed |
| `fetchpriority="high"` on the LCP image | Earlier discovery and download |
| An image CDN with on-the-fly transforms | All of the above, automatically |

**The two mistakes that cost the most:**
- `loading="lazy"` on the hero image. It delays the LCP element by design.
- No `width`/`height`, producing layout shift on every image.

Use your framework's image component (`next/image`, `nuxt-img`) if you have one —
it handles most of this correctly by default.

---

## Step 6 — Fonts

```css
@font-face {
  font-family: "Inter";
  src: url("/fonts/inter-var.woff2") format("woff2-variations");
  font-weight: 100 900;
  font-display: swap;
  unicode-range: U+0000-00FF;   /* subset to what you actually render */
}
```

- **Self-host.** Removes a third-party connection, a privacy data flow, and a
  point of failure.
- **Subset** to the characters you use — a full font with every script is many
  times larger than a Latin subset.
- **Preload** the one face used above the fold: `<link rel="preload" as="font"
  type="font/woff2" crossorigin>`. Note `crossorigin` is required even
  same-origin, or the preload is wasted and the font fetches twice.
- **Variable fonts** replace multiple weight files with one.
- **`font-display: swap`** shows fallback text immediately; `optional` avoids the
  swap shift entirely at the cost of sometimes not using your font.
- **Match fallback metrics** (`size-adjust`, `ascent-override`) so the swap does
  not shift layout.

---

## Step 7 — JavaScript

```bash
npx source-map-explorer 'dist/**/*.js'
npx vite-bundle-visualizer
```

**The audit questions:**
- What is the largest dependency, and is it worth its size?
- Is a heavy library in the initial bundle when it is only used on one route?
- Are we shipping polyfills for browsers we do not support?
- Are we shipping locale/timezone data for every locale?
- Is the icon library tree-shaking, or shipping all 3,000 icons?
- How much of this is third-party scripts?

**Techniques**
- Route-level splitting, plus `import()` for heavy components.
- Import only what you use; avoid namespace imports.
- Replace heavy libraries with lighter or native equivalents where the API
  surface you use is small.
- Modern build target — do not transpile to ES5 for browsers nobody uses.
- Set a budget and **fail CI on regression**.

**Third-party scripts** deserve their own audit. On a typical marketing page they
are more than half the JavaScript, they execute on the main thread, and each is
also a security and privacy surface. For each: is it earning its cost? Can it
load after interaction, after consent, or in a worker?

---

## Step 8 — Main-thread work

Profile with CPU throttling (4x or 6x) in the Performance panel. Without
throttling you are profiling a machine none of your users have.

- **Long tasks** (> 50ms) block input. Break them up and yield.
- **Layout thrashing:** reading `offsetHeight` after writing a style forces a
  synchronous reflow. Batch all reads, then all writes.
- **Hydration** is frequently the largest cost on a server-rendered app. Reduce
  it structurally: server components, islands, or progressive hydration.
- **Expensive re-renders:** in React, find them with the Profiler. Memoise
  deliberately, not everywhere — memoisation has its own cost.
- **Virtualise** lists beyond a few hundred rows.
- Move genuinely heavy computation to a Web Worker.

---

## Step 9 — Enforce it

```json
// .lighthouserc.json
{
  "ci": {
    "collect": { "url": ["http://localhost:3000/", "http://localhost:3000/pricing"],
                 "numberOfRuns": 3 },
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "total-blocking-time": ["error", { "maxNumericValue": 300 }],
        "resource-summary:script:size": ["error", { "maxNumericValue": 300000 }]
      }
    }
  }
}
```

Run on every PR against the key routes. Performance regresses one small addition
at a time; a gate is the only thing that stops it.

---

## Quick reference — symptom to cause

| Symptom | Most likely cause |
|---|---|
| High LCP, low TTFB | Image unoptimised, lazy-loaded, or discovered late |
| High LCP, high TTFB | Backend — usually a database query in the render path |
| High CLS | Missing image dimensions, or a banner inserted above content |
| High INP | Too much JavaScript executing; hydration; long tasks |
| Good lab score, bad field data | Testing on fast hardware; real users are on mobile |
| Slow only for some users | Segment by geography (no CDN) or device class |
| Progressively slower over months | Accretion — no budget in CI |
| Fast on repeat visit, slow first | Caching works; the cold path is the problem |
