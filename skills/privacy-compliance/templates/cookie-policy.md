# Cookie Policy

**Last updated: <YYYY-MM-DD>**

This page lists every cookie and similar technology used on <SITE>, what each
one does, and how to change your choices.

**[Manage my cookie preferences](<COOKIE SETTINGS LINK>)**

---

## What these are

A cookie is a small file stored on your device. We also use similar technologies
— local storage, session storage and tracking pixels — which are covered by this
policy and by the same consent choices.

**Nothing other than strictly necessary technologies loads until you agree.** You
can change or withdraw your choice at any time using the link above, and
rejecting will not restrict your access to <SITE>.

---

## Strictly necessary

Always active. <SITE> cannot function without these, so they do not require
consent. They do not track you across other websites.

| Name | Provider | Purpose | Duration | Type |
|---|---|---|---|---|
| `sid` | <SITE> | Keeps you signed in | Session | HTTP cookie |
| `csrf_token` | <SITE> | Protects forms against cross-site request forgery | Session | HTTP cookie |
| `consent.v2` | <SITE> | Remembers your cookie choices | 12 months | Local storage |
| `lb_route` | <HOST> | Routes your requests consistently to one server | Session | HTTP cookie |

---

## Functional — requires your consent

Remember your preferences. Without them, <SITE> still works but forgets your
settings between visits.

| Name | Provider | Purpose | Duration | Type |
|---|---|---|---|---|
| `locale` | <SITE> | Remembers your language | 12 months | HTTP cookie |
| `theme` | <SITE> | Remembers light or dark mode | 12 months | Local storage |

---

## Analytics — requires your consent

Help us understand how <SITE> is used so we can improve it.

| Name | Provider | Purpose | Duration | Type |
|---|---|---|---|---|
| `<ph_...>` | <PostHog> | Distinguishes visitors and records feature usage | <12 months> | HTTP cookie |
| `<_ga>` | <Google> | Distinguishes visitors | <2 years> | HTTP cookie |

**Where the data goes:** <PROVIDER>, hosted in <REGION>. See our
[privacy policy](<LINK>) section 3 for the full processor details.

---

## Marketing — requires your consent

<DELETE THIS ENTIRE SECTION IF YOU DO NOT USE ADVERTISING TECHNOLOGY. An empty
"Marketing" heading suggests you do and are hiding it.>

| Name | Provider | Purpose | Duration | Type |
|---|---|---|---|---|
| `_fbp` | <Meta> | Measures the effectiveness of advertising | <3 months> | HTTP cookie |

---

## Third-party content

Some pages embed content from other services. That content may set its own
cookies when it loads. **We load these only after you consent**, using a
click-to-load placeholder.

| Service | Where it appears | Their policy |
|---|---|---|
| <YouTube> | <Product demo pages> | <LINK> |
| <Google Maps> | <Contact page> | <LINK> |
| <reCAPTCHA> | <Signup and contact forms> | <LINK> |

<!-- Also list, if applicable: Google Fonts (receives every visitor's IP address
     — self-hosting removes this data flow entirely and is faster), chat
     widgets, comment systems, social share buttons, and any CDN that serves
     scripts to the browser. -->

---

## Your choices

**On this site** — [manage your preferences](<LINK>) at any time. Withdrawing
consent takes effect immediately and we delete the relevant cookies.

**In your browser** — you can block or delete cookies in your browser settings.
Blocking strictly necessary cookies will prevent you from signing in.

- <Chrome> · <Firefox> · <Safari> · <Edge> — see each browser's help pages.

**Global Privacy Control** — <SITE> honours the GPC browser signal. If your
browser sends it, we treat it as a rejection of analytics and marketing
technologies without you needing to interact with our banner.

---

## Changes

We update this page whenever we add or remove a technology. The date at the top
reflects the last change. If we add a new non-essential category, we will ask
for your consent again.

Questions: <privacy@DOMAIN>.

---

<!--
  MAINTAINING THIS PAGE

  Generate the tables from a real scan, not from memory:
    1. Private window → accept everything
    2. DevTools → Application → Cookies AND Local Storage AND Session Storage
    3. Every entry goes in a table above

  You will find cookies nobody on the team knew about. That is the point.

  Then verify the gating (this is what an auditor checks):
    1. Private window, DevTools open, Network tab
    2. Load the page. DO NOT touch the banner.
    3. Anything beyond "strictly necessary" firing? → violation
    4. Click "Reject all", reload, check again → violation if anything fires

  Re-run both after every change to the tag manager or any third-party script.
-->
