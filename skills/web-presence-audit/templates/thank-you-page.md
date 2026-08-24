# Thank-You Page

A **real URL**, not a modal. This is non-negotiable for three reasons: a modal
cannot be a conversion goal, cannot be linked from an email, and cannot be
measured cleanly.

## The three jobs

1. **Confirm** — the action succeeded, and here is exactly what happens next.
2. **Set the expectation** — the response-time commitment, stated plainly.
3. **Offer the next step** — the visitor is at maximum engagement. A dead end
   wastes it.

---

## Markup

```html
<main id="content">
  <section class="thanks">
    <svg class="thanks__icon" aria-hidden="true" focusable="false"><!-- check --></svg>

    <h1>Thanks — we've got your message</h1>

    <p class="thanks__lead">
      We've sent a confirmation to <strong>you@example.com</strong>.
      If it doesn't arrive within a few minutes, check your spam folder.
    </p>

    <!-- JOB 2: the expectation. This is the most valuable block on the page. -->
    <div class="thanks__promise">
      <h2>What happens next</h2>
      <ol>
        <li><strong>Within 1 business day</strong> — a real person reads your
            message and replies with either an answer or a question.</li>
        <li><strong>Within 3 business days</strong> — if it's a project enquiry,
            we send a short scoping call invitation.</li>
        <li><strong>No obligation</strong> — the first call is free and there's
            no pitch.</li>
      </ol>
      <p>Need it sooner? Call <a href="tel:+15550100">+1 555 0100</a>
         (Mon–Fri, 09:00–18:00 CET).</p>
    </div>

    <!-- JOB 3: the next step, chosen for where they came from -->
    <div class="thanks__next">
      <h2>While you wait</h2>
      <ul>
        <li><a href="/case-studies/acme">How Acme cut checkout abandonment by 17 points</a>
            — a 6-minute read on the work most like yours</li>
        <li><a href="/guides/performance-checklist">The pre-launch performance checklist</a>
            — 24 checks you can run today</li>
        <li><a href="/book">Book a slot directly</a> — skip the back-and-forth</li>
      </ul>
    </div>

    <p class="thanks__ref">
      Reference: <code>ENQ-2026-08-1042</code> — quote this if you follow up.
    </p>
  </section>
</main>
```

**Metadata**
```html
<title>Thanks — we'll be in touch | Devleck</title>
<meta name="robots" content="noindex, follow">
```

`noindex` because it has no search value and would confuse anyone landing on it
cold. Keep it a **real, linkable URL** regardless — that is what makes it usable
as a conversion goal and in email.

---

## One page per action

Do not send every form to `/thank-you`. Different actions have different next
steps, and a shared page makes conversion attribution impossible.

| Action | URL | The specific next step |
|---|---|---|
| Contact form | `/thank-you/contact` | Response time, a case study, a direct booking link |
| Demo request | `/thank-you/demo` | Calendar embed, what to prepare, who they'll meet |
| Newsletter | `/thank-you/subscribe` | Confirm the email, link the archive, set frequency |
| Resource download | `/thank-you/guide` | **The download link itself**, plus related resources |
| Purchase | `/order/confirmed` | Order details, delivery estimate, support contact |
| Trial signup | `/welcome` | The first three things to do in the product |

---

## Deliver files here, not by email

For a resource download, put the file on the thank-you page **and** email it.
Email-only delivery loses everyone whose mail is slow, filtered, or mistyped —
and you never find out.

---

## Conversion tracking

The thank-you URL is the anchor. Fire the conversion event here, server-side
where possible, and **respect consent**:

```js
// Only after consent for analytics/advertising categories
if (hasConsent("analytics")) {
  gtag("event", "generate_lead", {
    value: 0, currency: "USD",
    lead_source: new URLSearchParams(location.search).get("src"),
  });
}
```

**Guard against double counting.** A refresh re-fires the event. Use a
server-side conversion with the submission id, or set a flag once per
submission.

**A thank-you page loaded directly, without a submission, is not a conversion.**
Check for a submission token or a referrer from the form page before firing.

**Privacy:** advertising and analytics pixels here are third-party data flows.
They belong in your privacy policy and behind consent. Never put personal data
(email, name, phone) into a tracking event payload or a URL parameter — see
`privacy-compliance`.

---

## The confirmation email

The thank-you page and the confirmation email should say the same thing. The
email is what they still have tomorrow.

```
Subject: We got your message — here's what happens next

Hi <name>,

Thanks for getting in touch. Your enquiry reference is ENQ-2026-08-1042.

WHAT HAPPENS NEXT
A real person will read your message and reply within one business day —
usually much sooner. If it's a project enquiry, we'll suggest a short
scoping call. There's no obligation and no pitch.

Need it sooner? Reply to this email or call +1 555 0100
(Mon–Fri, 09:00–18:00 CET).

WHILE YOU WAIT
• How Acme cut checkout abandonment by 17 points — <link>
• The pre-launch performance checklist — <link>

— Aleck Martinez, Devleck
<address> · <unsubscribe, if this is anything other than transactional>
```

Send it from a **monitored** address. `noreply@` is a small, constant signal that
you do not want to hear from the person you just asked to contact you.

---

## The audit checks

- [ ] It is a real URL, not a modal
- [ ] A distinct URL per action type
- [ ] `noindex, follow`
- [ ] The response-time commitment is stated, and it is **true and monitored**
- [ ] An alternative contact route for urgent cases
- [ ] A specific next step, not a generic "back to home"
- [ ] Any promised file is available on the page, not only by email
- [ ] A reference number the visitor can quote
- [ ] Conversion tracking fires once, and only after consent
- [ ] A direct load without a submission does not count as a conversion
- [ ] The confirmation email matches the page
- [ ] The email comes from a monitored address
