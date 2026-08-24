# Cookie Consent

## The failure that is everywhere

The banner appears. Behind it, the analytics script has already loaded, executed
and set cookies. The user clicks "Accept" — or does not — and nothing changes,
because the processing already happened.

This is not a technicality. **Consent that is obtained after the processing is
not consent**, and it is trivially detectable: open a private window, open
DevTools, load the page, touch nothing.

---

## The test

Run this before writing anything else. It takes ninety seconds and it determines
whether you have a real finding.

```
1. Private/incognito window
2. DevTools open → Application → Cookies, and the Network tab (filtered)
3. Load the page. DO NOT INTERACT WITH THE BANNER.
4. Check:
   · Any cookie beyond strictly necessary?            → VIOLATION
   · Any request to an analytics or ad domain?        → VIOLATION
   · Any third-party font, embed or pixel loaded?     → VIOLATION
5. Click "Reject all". Reload. Repeat step 4.         → VIOLATION if anything fires
6. Click "Accept all". Confirm scripts NOW load.      → otherwise the banner is decorative
```

Step 5 catches the second-most-common failure: a banner that records the
rejection and loads the scripts anyway.

---

## Requirements

| Requirement | Why |
|---|---|
| Non-essential scripts do not execute before consent | The core obligation |
| "Reject all" as prominent and as easy as "Accept all" | Consent must be freely given; a hidden reject is not free |
| Granular categories | Consent must be specific |
| Nothing non-essential pre-ticked | Pre-ticked boxes are settled as not constituting consent |
| Withdrawal as easy as granting | A persistent link, not a buried setting |
| Recorded with timestamp and policy version | You must be able to demonstrate consent |
| No cookie wall on essential functionality | Access cannot be conditioned on unnecessary consent |
| Re-ask when purposes change | Consent covers what was described at the time |

**Consent is not required for strictly necessary cookies** — session,
authentication, load balancing, security, and the consent record itself. It *is*
required for analytics, advertising, personalisation, session recording, chat
widgets, embedded media, and third-party fonts.

---

## Categories

```
NECESSARY    Session, auth, CSRF token, load balancer, the consent record itself
             → Always on, no consent needed. Disclose them, do not gate them.

FUNCTIONAL   Language, theme, saved preferences, non-essential chat
             → Consent. The feature degrades gracefully without it.

ANALYTICS    Product analytics, heatmaps, session recording, A/B testing
             → Consent. Nothing loads before it.

MARKETING    Ad pixels, conversion tracking, retargeting, affiliate
             → Consent. The strictest category; also the most commonly violated.
```

Session recording deserves a specific mention: it captures form fields, and
without careful masking it captures passwords, card numbers and personal data
typed but never submitted. Treat it as high-risk, mask aggressively, and consider
whether you need it at all.

---

## Implementation — gate the injection

The only reliable approach is to prevent the script from being *added*, not to
try to stop it once it is running.

```html
<!-- The browser will not execute an unknown script type -->
<script type="text/plain" data-consent="analytics"
        src="https://cdn.example.com/analytics.js"></script>

<script type="text/plain" data-consent="marketing">
  // inline code is equally gated
  fbq('init', '000000000000');
</script>
```

```js
// consent.js — loaded unconditionally; it is itself strictly necessary
const CATEGORIES = ["functional", "analytics", "marketing"];
const KEY = "consent.v2";                 // version it: bump to re-ask

const read = () => { try { return JSON.parse(localStorage.getItem(KEY)) ?? null; }
                     catch { return null; } };

function activate(category) {
  document.querySelectorAll(`script[data-consent="${category}"]`).forEach((old) => {
    const s = document.createElement("script");
    for (const { name, value } of old.attributes) {
      if (name !== "type" && name !== "data-consent") s.setAttribute(name, value);
    }
    s.type = "text/javascript";
    if (!old.src) s.textContent = old.textContent;
    old.replaceWith(s);
  });
  // Gated iframes (maps, video, social embeds) use the same pattern
  document.querySelectorAll(`iframe[data-consent="${category}"][data-src]`)
    .forEach((f) => { f.src = f.dataset.src; });
}

export function apply(consent) {
  for (const c of CATEGORIES) if (consent[c]) activate(c);
}

export function save(consent) {
  const record = {
    ...consent,
    timestamp: new Date().toISOString(),
    policyVersion: "2026-08-24",
    method: consent.__method ?? "banner",     // banner | settings | api
  };
  try { localStorage.setItem(KEY, JSON.stringify(record)); } catch {}
  // Also persist server-side for authenticated users — you must be able to
  // demonstrate consent later, and localStorage is not evidence.
  if (window.__userId) {
    navigator.sendBeacon("/api/consent", JSON.stringify(record));
  }
  apply(record);
}

const existing = read();
if (existing) apply(existing); else showBanner();
```

**Withdrawal** must reload the page. Scripts already running cannot be recalled,
and their cookies must be actively deleted:

```js
export function withdraw(category) {
  const c = { ...read(), [category]: false, __method: "settings" };
  save(c);
  deleteCookiesFor(category);   // maintain a category → cookie-name map
  location.reload();            // the only way to unload what is running
}
```

---

## Banner design

```html
<div role="dialog" aria-modal="false" aria-labelledby="cc-title" class="cc">
  <h2 id="cc-title">We use cookies</h2>
  <p>
    Necessary cookies keep the site working. We would also like to use analytics
    cookies to understand how the site is used. You can change your mind at any
    time on our <a href="/cookies">cookie page</a>.
  </p>
  <div class="cc__actions">
    <!-- Equal weight. This is a requirement, not a style choice. -->
    <button data-action="reject">Reject all</button>
    <button data-action="accept">Accept all</button>
    <button data-action="settings" class="cc__link">Manage preferences</button>
  </div>
</div>
```

- **Reject and Accept get the same visual weight** — same size, same contrast,
  same prominence. A grey "Reject" next to a bright "Accept" is the pattern
  regulators specifically cite.
- Do not block the page with a modal overlay unless you have a reason; it fails
  accessibility and it is not required.
- Keyboard reachable, focus visible, dismissible. Announce with `role="dialog"`
  and a label.
- **Do not stack it** with a sticky CTA and a chat bubble — three fixed elements
  on a phone is 40% of the screen.
- Keep the copy plain. "We value your privacy" followed by 400 words is not
  informed consent.

---

## Tag managers

A tag manager is a code-execution channel granted to whoever has access to the
account. Two obligations follow:

1. **Gate the container itself**, or configure consent mode so tags fire only in
   their granted category. A tag manager loaded before consent that then loads
   analytics is the same violation with an extra layer.
2. **Restrict and audit access.** Anyone with publish rights can execute
   arbitrary JavaScript on every page of your site.

Where a platform offers a consent-mode integration, use it — but **verify with
the network tab**, because "consent mode" in several implementations still sends
cookieless pings before consent. Whether that is acceptable is a decision to make
knowingly, not by default.

---

## Server-side enforcement

Client-side gating is bypassable. For anything that matters, enforce on the
server too:

```ts
// Do not render the tag at all without consent
const consent = parseConsent(req.cookies["consent.v2"]);
res.render("page", { analyticsEnabled: consent?.analytics === true });
```

And never send personal data to an analytics or advertising API server-side
without the corresponding consent — server-side tracking does not escape the
obligation, it just makes the violation harder for the user to see.

---

## The cookie table

Required by several regimes, and useful regardless. Generate it from a live scan,
not from memory — you will find cookies nobody knew about.

| Name | Provider | Category | Purpose | Duration | Type |
|---|---|---|---|---|---|
| `sid` | First party | Necessary | Session | Session | HTTP |
| `consent.v2` | First party | Necessary | Stores your choice | 12 months | Local storage |
| `_ga` | Google | Analytics | Distinguishes users | 2 years | HTTP |
| `_fbp` | Meta | Marketing | Advertising attribution | 3 months | HTTP |

Audit with DevTools → Application → Storage, **after accepting everything**, to
see the full set.

---

## Beyond cookies

The obligation is about **storing or accessing information on a device**, not
about the word "cookie". These count and are routinely missed:

- `localStorage` and `sessionStorage`
- IndexedDB
- Fingerprinting (canvas, fonts, screen metrics)
- Pixels and tracking beacons
- **Third-party fonts** — a font CDN receives every visitor's IP address and
  user agent. Self-hosting removes the data flow entirely and is faster.
- **Embedded video and maps** — most set cookies on load. Use a click-to-load
  placeholder.
- Server-side tracking that correlates to an individual.

---

## Audit checklist

- [ ] No non-essential cookie or request before interaction (tested, private window)
- [ ] Nothing fires after "Reject all" (tested)
- [ ] Scripts do load after "Accept" (tested — the banner is not decorative)
- [ ] Reject and Accept have equal prominence
- [ ] Granular categories; nothing non-essential pre-ticked
- [ ] Withdrawal is easy, persistent, and reloads the page
- [ ] Cookies are actively deleted on withdrawal
- [ ] Consent recorded with timestamp and policy version, server-side for logged-in users
- [ ] Cookie table published and generated from a real scan
- [ ] Third-party fonts self-hosted, or gated
- [ ] Embeds use click-to-load
- [ ] Tag manager gated and access-restricted
- [ ] Server-side tracking respects the same consent
