# FAQ Page

An FAQ page does three jobs: it removes objections before they end the visit, it
captures long-tail search traffic, and it is among the most-cited structures by
AI assistants.

It only works if the questions are **real** and the answers are **specific**.

---

## Where the questions come from

Not from imagination. From:
- Your support inbox and chat logs — sort by frequency.
- Sales call recordings — the objection raised at minute 20 is your best FAQ.
- Search Console queries that land on your site as questions.
- "People also ask" for your core terms.
- Competitor FAQs — what are they answering that you are not?

**Include the uncomfortable questions.** Price, how you compare to the obvious
alternative, what you do *not* do, what happens when something goes wrong.
Answering these builds more trust than any testimonial, because most competitors
avoid them.

---

## How to write the answers

| Do | Don't |
|---|---|
| Answer in the first sentence, then elaborate | Build up to the answer |
| Give ranges, timeframes and numbers | "It depends" with no dependency named |
| Say what it costs, or what drives the cost | "Contact us for pricing" |
| Name the limits honestly | Imply you do everything |
| Link to the deeper page | Duplicate a whole page inside an answer |
| 40–120 words | One line, or five paragraphs |

```
✗  Q: How long does implementation take?
   A: Timelines vary depending on the scope and complexity of each project.

✓  Q: How long does implementation take?
   A: Most projects go live in 4 to 6 weeks — one week of discovery, two to
      four weeks of build, and one week of testing and handover. Larger data
      migrations can run to 12 weeks. We give a firm date after discovery, and
      we have hit it on 38 of our last 40 projects.
```

The second answer is what gets surfaced in a rich result and quoted by an
assistant. The first is invisible.

---

## Page structure

```html
<main id="content">
  <h1>Frequently asked questions</h1>
  <p>Answers to what we get asked most. Not here?
     <a href="/contact">Ask us</a> — we reply within one business day.</p>

  <nav aria-label="Sections">          <!-- only once you exceed ~10 questions -->
    <ul>
      <li><a href="#getting-started">Getting started</a></li>
      <li><a href="#pricing">Pricing and billing</a></li>
      <li><a href="#security">Security and data</a></li>
      <li><a href="#support">Support</a></li>
    </ul>
  </nav>

  <section aria-labelledby="pricing">
    <h2 id="pricing">Pricing and billing</h2>

    <div class="faq-item">
      <h3>How much does a project cost?</h3>
      <p>Most engagements fall between $15,000 and $60,000. The main drivers are
         the number of integrations and whether existing data must be migrated.
         A typical two-integration build with no migration is around $22,000.
         See <a href="/pricing">pricing</a> for a full breakdown.</p>
    </div>

    <div class="faq-item">
      <h3>Do you offer payment plans?</h3>
      <p>Yes. Projects over $20,000 can be split into three payments: 40% to
         start, 40% at the midpoint review, and 20% on acceptance. There is no
         interest or fee.</p>
    </div>
  </section>
</main>
```

**Accessibility notes**

- **Plain headings and paragraphs are the safest structure.** They are readable,
  linkable, printable, findable with Ctrl+F, and crawlable with no JavaScript.
- If you use an accordion, use `<details>`/`<summary>`, which is accessible by
  default — or implement the full disclosure pattern with `aria-expanded` and
  proper focus management. Do not build one from `div`s and click handlers.
- **Content inside a collapsed `<details>` is still crawled and still counts as
  visible** for schema purposes, so an accordion is compatible with `FAQPage`
  markup.
- Give each question a stable `id` so answers can be linked directly. Support
  agents will use those links constantly.

---

## Schema

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "How much does a project cost?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Most engagements fall between $15,000 and $60,000. The main drivers are the number of integrations and whether existing data must be migrated. A typical two-integration build with no migration is around $22,000."
      }
    },
    {
      "@type": "Question",
      "name": "Do you offer payment plans?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes. Projects over $20,000 can be split into three payments: 40% to start, 40% at the midpoint review, and 20% on acceptance. There is no interest or fee."
      }
    }
  ]
}
</script>
```

**The question and answer text must match what is visible on the page.**
Schema-only content is a guidelines violation, and enforcement is sitewide.

Generate the JSON-LD from the same source as the rendered content — a data file
or CMS collection — so they cannot drift. Hand-maintaining both guarantees they
diverge.

---

## Distribute FAQs, do not only centralise them

A dedicated FAQ page is useful. Placing the three most relevant questions
**inline on the page where the objection arises** is more useful.

| Page | The questions that belong there |
|---|---|
| Pricing | What is included? Are there hidden costs? Can I change plans? |
| Product | Does it work with X? What are the limits? Is there a trial? |
| Checkout | What is your refund policy? Is my payment secure? When am I charged? |
| Contact | How fast do you reply? What information should I include? |
| Signup | Do I need a credit card? Can I delete my account and data later? |

Only one page on the site should carry `FAQPage` schema for a given set of
questions — duplicating the same markup across many pages is not helpful.

---

## Maintenance

- **Review quarterly** against the current support inbox. An FAQ answering last
  year's questions is worse than none — it signals neglect.
- Track which questions still arrive in support despite being answered. That
  means the answer is unclear, or unfindable, or the visitor did not trust it.
- Remove questions nobody asks any more; they dilute the page.
- Add a "Was this helpful?" control and act on the results.
