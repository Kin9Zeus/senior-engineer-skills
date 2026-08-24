# Trust and Conversion Surface

A technically perfect site that reads as anonymous does not convert. This is the
layer engineers skip and businesses lose money to.

The visitor is asking three questions, in this order:

```
1. Is this real?          → identity, address, names, faces, history
2. Does it work?          → case studies, testimonials, specifics, numbers
3. What happens if I act? → response time, guarantee, next step, what it costs
```

Every element below answers one of them. An element that answers none is
decoration.

---

## The pages a credible business has

### Custom 404

A dead end loses the visitor entirely. A useful 404 recovers most of them.

- **Returns a real `404` status code.** A 200 is a soft 404 — a technical SEO
  defect and a signal that nobody tested it.
- Explains plainly, without blaming the visitor.
- Offers **search** and the **top five destinations**.
- Keeps the full navigation, header and footer.
- No stack trace, no framework branding, no "Error: ENOENT".
- Log 404s with the referrer — they reveal your broken internal links and the
  external links pointing at pages you moved.

See `templates/404-page.md`.

### FAQ page

Answers objections before they become "I'll think about it". It is also among the
most-cited structures by AI assistants, and it is eligible for rich results.

- **Real questions from real prospects.** Mine your support inbox, sales calls
  and chat logs. Invented questions are obvious and useless.
- **Answer completely and specifically.** "It depends" wastes the visit. Give
  the range, the conditions and the number.
- **Answer the uncomfortable ones**: price, how you compare to the obvious
  alternative, what you do not do, what happens if it goes wrong. Answering these
  builds more trust than any testimonial.
- Group by theme once you exceed ten.
- Mark up with `FAQPage` schema — the visible text and the schema text must
  match.
- Each answer links to the deeper page on that topic.

See `templates/faq-page.md`.

### Case studies

The single most persuasive asset a B2B or service business has — and the one
most often done badly.

**The structure that works:**
```
1. The client            who they are, and enough context to be relatable
2. The situation         the specific problem, with numbers
3. What was done         the approach — concrete, not "we leveraged our expertise"
4. The measured outcome  numbers, before and after, with a timeframe
5. A direct quote        from a named person with a real title
6. The next step         a CTA to start the same conversation
```

**What separates a persuasive case study from a useless one:**
- **Numbers.** "Reduced page load from 4.2s to 0.9s, and checkout completion rose
  from 61% to 78% over eight weeks." Not "significantly improved performance."
- **Specificity about the problem.** A reader recognises themselves in the
  problem, not in the solution.
- **A named person**, with a photo and a title. An anonymous quote is worth
  approximately nothing.
- **Honesty about constraints.** "We could not migrate the legacy billing system
  in phase one, so we..." Acknowledging limits makes the rest credible.
- Three excellent case studies beat twelve thin ones.

See `templates/case-study.md`.

### Thank-you page

A **real URL**, not a modal. Three jobs:

1. **Confirm** the action succeeded and say exactly what happens next.
2. **Set the expectation** with the response-time commitment: "We reply within
   one business day. If it is urgent, call +1-555-0100."
3. **Offer the next step** — related content, a calendar link, a resource
   download. The visitor is at maximum engagement here; a dead end wastes it.

It is also your **conversion tracking anchor**. A modal cannot be a conversion
goal URL, cannot be linked in an email, and cannot be measured cleanly.

See `templates/thank-you-page.md`.

### About / team

The strongest negative trust signal on the internet is anonymity.

Real names, real photographs, real roles. Where the company is. When it started.
Who the founder is and why they started it. Team size, honestly — "a team of
four" is more credible than a page implying forty.

### Contact

- **Multiple channels** — email, phone, form, chat. Different people use
  different ones, and offering only a form reads as avoidance.
- **A physical address** if you have one, with a map.
- **A stated response time** (below).
- Named people for specific concerns: sales, support, press, security, privacy.

### Pricing

"Contact us for pricing" loses every visitor unwilling to start a conversation
blind, and that is most of them. If you cannot publish exact prices, publish:
a starting price, a typical range, what drives it up or down, and what is
included. A range with context beats silence by a wide margin.

### The rest

**Status page** for any SaaS — silence during an outage costs more than the
outage. **Security page** and `/.well-known/security.txt` with a disclosure
contact. **Changelog** — visible progress is a trust signal. **Privacy policy**,
**terms**, **cookie notice** and a **data deletion path** — see
`privacy-compliance`.

---

## The response-time commitment

State it explicitly wherever a visitor is deciding whether to make contact: the
contact page, next to every form, on the thank-you page, and in the footer.

> **We reply to every enquiry within one business day.**
> Support: within 4 business hours (Mon–Fri, 09:00–18:00 CET).
> Urgent production issues: within 1 hour for customers on a support plan.

Why it matters more than it looks:

- It removes the "will anyone even answer?" hesitation at the precise moment of
  decision. That hesitation is a measurable share of abandoned contact forms.
- It is a differentiator, because most competitors do not state one.
- **It is a promise.** So it must be true and **monitored** — an unmet stated
  commitment does more damage than no commitment at all. Instrument it: measure
  first-response time and alert when it exceeds what you published.

For a SaaS, extend this into a support policy with tiers by severity, and a
public status page.

---

## Sticky mobile CTA

Over half of traffic is mobile. Mobile users scroll a long way and rarely scroll
back. A persistent bar keeps the action one tap away at all times.

```html
<div class="cta-bar" role="region" aria-label="Primary action">
  <a href="/get-started" class="cta-bar__btn">Get a free quote</a>
</div>
```
```css
.cta-bar {
  position: fixed; inset-inline: 0; bottom: 0; z-index: 40;
  display: flex; gap: .5rem; align-items: center;
  padding: .75rem 1rem calc(.75rem + env(safe-area-inset-bottom));
  background: var(--surface); border-top: 1px solid var(--border);
  box-shadow: 0 -2px 12px rgb(0 0 0 / .08);
}
.cta-bar__btn {
  flex: 1; min-height: 48px;                /* comfortable touch target */
  display: grid; place-items: center;
  border-radius: .5rem; font-weight: 600;
  background: var(--accent); color: var(--accent-ink);
}
/* The page must reserve space, or the bar covers the last element */
body { padding-bottom: 5rem; }

@media (min-width: 768px) { .cta-bar { display: none; } body { padding-bottom: 0; } }
@media (prefers-reduced-motion: no-preference) { .cta-bar { transition: transform .2s; } }
```

**Do it correctly or it costs more than it gains:**

- **Reserve space on the page.** The most common implementation bug is a bar
  permanently covering the last form field, the footer links, or the submit
  button.
- **One action.** Two competing buttons in a 60px bar is a decision, not a call
  to action.
- **48px minimum touch target**; respect `env(safe-area-inset-bottom)` on notched
  devices.
- **Keyboard reachable, not a focus trap**; the `role="region"` with a label
  makes it navigable by screen reader.
- **Do not stack it** with a cookie banner and a chat bubble. Three fixed
  elements consume 40% of a phone screen and read as hostile.
- Consider hiding it on the page the CTA points to — a "Get a quote" bar on the
  quote page is noise.
- Optionally reveal it after the hero scrolls out, so it does not compete with
  the primary CTA above the fold.

---

## Trust signals throughout the site

| Signal | Done well | Done badly |
|---|---|---|
| Customer logos | Real, with permission, recognisable | Stock logos, or clients you had once in 2019 |
| Testimonials | Name, role, company, photo, **specific claim** | "Great service!" — J.D. |
| Review scores | Linked to the real profile on the real platform | An unlinked star graphic |
| Certifications | Current, verifiable, linked | Expired badges |
| Guarantee | Specific and honoured | "Satisfaction guaranteed" with no terms |
| Team | Real photos and names | Stock photography of a diverse boardroom |
| Address | Real, mapped | A virtual office nobody occupies |
| Numbers | "412 projects since 2021" | "Thousands of happy customers" |
| Security | SOC 2, a security page, `security.txt` | A padlock icon in the footer |

**Specific beats superlative, always.** Every vague superlative on a page
slightly reduces belief in everything else on it.

---

## Conversion mechanics

- **One primary action per page.** A page offering four equally-weighted options
  gets none of them chosen.
- **The CTA states the outcome**, not the mechanism: "Get my free audit" beats
  "Submit".
- **Reduce the perceived cost** next to the CTA: "No credit card", "2 minutes",
  "No obligation", "Cancel anytime".
- **The above-the-fold answer:** what is this, who is it for, why should I care,
  what do I do next — visible without scrolling, on mobile.
- **Design every state**: empty, loading, error, partial, offline, and
  one-item. Only designing the populated state is the most common frontend
  omission.
- **Forms:** minimum fields, real labels, inline validation, no data loss on
  error, idempotent submission, redirect to a real thank-you page.

---

## The audit questions

Ask them as a stranger who has never heard of this company:

1. Within five seconds, do I know what this is and who it is for?
2. Do I believe a real organisation is behind it?
3. Can I find out what it costs?
4. Is there evidence it works — with numbers, and from named people?
5. Do I know what happens if I make contact, and how fast?
6. Are my objections answered without having to ask?
7. On my phone, is the action always reachable?
8. If I land on a broken URL, am I recovered or lost?
9. Do I know what happens to my data, and can I get it deleted?
10. Is there any way to tell this site is maintained?

Every "no" is a finding, with a page attached.
