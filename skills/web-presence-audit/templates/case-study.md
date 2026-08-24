# Case Study Template

The most persuasive asset a B2B or service business has, and the one most often
wasted on vagueness.

**The test of a case study:** could a prospect read it and recognise their own
situation in the *problem*? If the problem section is generic, nothing after it
lands.

---

## Structure

```markdown
# How <Client> <achieved a specific measurable outcome>

<One-sentence summary containing the headline number.>

| | |
|---|---|
| **Client** | <Name — or "a Series-B fintech" if under NDA> |
| **Industry** | <Industry> |
| **Size** | <Employees / users / revenue band> |
| **Engagement** | <What we did, in four words> |
| **Duration** | <n weeks> |

> ### The result
> - **<Metric>: <before> → <after>** (<timeframe>)
> - **<Metric>: <before> → <after>**
> - **<Business outcome>: <the thing the CFO cares about>**

---

## The situation

<Two to three paragraphs. The specific problem, with numbers, in the client's
terms. This is the section a prospect reads to decide whether the rest applies
to them — so it must be concrete.>

<What had they already tried? Why had it not worked? What was it costing them?
The cost is what justified the project, so state it.>

**What was at stake**
- <Concrete consequence, quantified>
- <Concrete consequence, quantified>

---

## What we did

<The approach, concretely. Not "we leveraged our expertise in modern
architecture" — what did you actually do, in what order, and why?>

### Phase 1 — <name> (<weeks>)
<What happened. What you found. What you decided and why.>

### Phase 2 — <name> (<weeks>)
<Same.>

### Phase 3 — <name> (<weeks>)
<Same.>

**The decision that mattered most**
<Every project has one. Name it, explain the alternatives you rejected and why.
This is the section that demonstrates judgement rather than activity — and
judgement is what the reader is actually buying.>

---

## The constraints we worked within

<Include this section. It is what makes the rest believable.>

<What you could not change, what was out of scope, what trade-off you made and
what it cost. "We could not migrate the legacy billing system in phase one, so
we built a synchronisation layer as a bridge — which added two weeks but avoided
a risky big-bang cutover."">

---

## Results

| Metric | Before | After | Change |
|---|---|---|---|
| <Page load, p75> | 4.2s | 0.9s | −79% |
| <Checkout completion> | 61% | 78% | +17pp |
| <Support tickets / week> | 140 | 38 | −73% |
| <Deploy frequency> | monthly | daily | 20× |

**Measured over <timeframe>, <how it was measured>.**

<State the measurement method. "Google Analytics, 30 days before vs 30 days
after launch, same traffic sources" is credible. An unattributed number is not.>

<Then the business outcome the numbers add up to — revenue, cost, risk, time.>

---

## In the client's words

> "<A specific quote about a specific thing. Not 'they were great to work with' —
> something like 'They found the query that had been costing us four seconds on
> every page load for two years. Nobody else had looked.'>"
>
> **<Full name>**, <Job title>, <Company>
> <photo>

---

## What we would do differently

<Optional, and disproportionately powerful. Naming one thing you would change
signals a team that reflects rather than sells. Keep it honest and small.>

---

## Ready for the same?

<A specific CTA that matches this reader's situation — not a generic "contact
us". "If you're seeing similar load times, we run a free two-hour performance
review." Link to the relevant next step.>
```

---

## Rules that separate persuasive from useless

**Numbers, with method.** "Reduced page load from 4.2s to 0.9s at p75, measured
in field data over 30 days" persuades. "Significantly improved performance" does
not, and it slightly reduces belief in everything else on the page.

**A named human.** Full name, real job title, real company, and a photograph.
An anonymous quote is worth approximately nothing — readers assume it was
written in-house, and they are frequently right.

**The problem section carries the weight.** Prospects recognise themselves in
problems, not in solutions. Spend your best writing there.

**Honesty about constraints.** A case study where everything went perfectly reads
as marketing. One that names a real trade-off reads as a record.

**Three excellent beats twelve thin.** Depth is the whole point of the format.

**Permission and accuracy.** Get written approval for the client's name, logo,
quote and numbers before publishing. Under NDA, anonymise the client but keep
the numbers — "a Series-B fintech with 40,000 monthly active users" is specific
enough to be useful and vague enough to be permitted.

---

## Structured data

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "How Acme cut checkout abandonment by 17 points",
  "description": "A six-week performance engagement that took p75 page load from 4.2s to 0.9s.",
  "image": ["https://example.com/case-studies/acme-1200x630.png"],
  "datePublished": "2026-08-24",
  "dateModified": "2026-08-24",
  "author": { "@type": "Person", "name": "Aleck Martinez" },
  "publisher": { "@id": "https://example.com/#organization" },
  "about": { "@type": "Thing", "name": "Web performance optimisation" }
}
</script>
```

---

## Distribution

A case study nobody reads has no value. Link it from:
- The service page for the work it demonstrates.
- The pricing page (proof next to the number).
- The relevant blog posts.
- Sales email templates and proposals.
- A dedicated case-studies index, sortable by industry and problem.

And create the **one-page PDF version** for sales conversations — the same
content, laid out to be read in two minutes.
