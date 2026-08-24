---
name: accessibility-audit
description: Audit and build interfaces to WCAG 2.2 AA — keyboard operability, focus management, semantic structure and landmarks, accessible names, colour contrast, forms and error handling, ARIA patterns, reduced motion, zoom and reflow, and testing with real assistive technology. Use when the user says "accessibility", "a11y", "WCAG", "screen reader", "keyboard navigation", "contrast", "ARIA", "focus", "alt text", "accessible", "ADA", "Section 508", "EAA" or "European Accessibility Act"; when building or reviewing any UI component, form, modal, menu or data table; and as a mandatory pass in any audit of a project with a user interface. By Devleck.
license: MIT
---

# Accessibility Audit

Accessibility is not a feature for a minority. Temporary and situational
impairments — a broken arm, bright sunlight, a noisy room, a trackpad that
stopped working — mean everyone uses accessible design eventually. It is also
increasingly a legal requirement rather than a nice-to-have.

**Automated tools catch roughly a third of WCAG issues.** They are necessary and
nowhere near sufficient. The findings that matter come from the manual pass.

---

## The four-test triage — run this first

Ten minutes, and it finds most serious problems.

### 1. Unplug the mouse

Complete the critical journey with `Tab`, `Shift+Tab`, `Enter`, `Space` and the
arrow keys.

- Can you reach every interactive element?
- Can you *see* where you are at all times? (A visible focus indicator is not
  optional — `outline: none` with no replacement is a `P1` on its own.)
- Does the focus order follow the visual order?
- Can you escape every component — modal, menu, date picker — without a mouse?
- Does anything trap focus permanently?
- Is there a skip link to bypass the navigation?

### 2. Zoom to 400%

At 400% zoom on a 1280px viewport (equivalent to a 320px-wide window):

- Does all content remain available?
- Is there horizontal scrolling? (Reflow failure.)
- Do fixed elements cover the content?
- Does text truncate or overlap?

### 3. Turn on a screen reader

NVDA (Windows, free), VoiceOver (macOS/iOS, built in), TalkBack (Android).

Twenty minutes learning the basic commands pays for itself permanently, because
it converts "I think this is accessible" into evidence.

- Is the page structure announced (headings, landmarks, lists)?
- Does every control announce a meaningful name and its role?
- Are state changes announced (loading, error, success, expanded)?
- Do images announce useful alt text — or a filename?

### 4. Run the automated scanner

axe DevTools, Lighthouse, or WAVE. Fix what it finds, then **remember it found a
third of the problems**. A clean automated scan is a starting line, not a
finish.

---

## WCAG 2.2 AA — the checks that matter most

Organised by principle. `references/wcag-checklist.md` has the full list.

### Perceivable

- **Text alternatives.** Every meaningful image has alt text describing its
  function in context. Decorative images have `alt=""` — empty, not missing.
  Icon-only buttons have an accessible name.
- **Contrast.** 4.5:1 for body text, 3:1 for large text (24px, or 19px bold),
  3:1 for UI component boundaries and graphical objects that convey meaning.
  Check the states too — a disabled button and a placeholder still need to be
  readable, and hover/focus states are where contrast is usually lost.
- **Not colour alone.** Error states, required fields, chart series, status
  indicators and links in body text must be distinguishable without colour.
- **Structure.** Real headings in order, real lists, real tables with `<th>` and
  `scope`. Semantics are what screen reader users navigate by.
- **Reflow.** No horizontal scrolling at 320px equivalent.
- **Text spacing.** The layout survives increased line height, letter spacing
  and word spacing without clipping.

### Operable

- **Keyboard.** Everything reachable and operable. No traps.
- **Focus visible.** A clear indicator with sufficient contrast against both the
  component and the background. **WCAG 2.2 adds a minimum appearance
  requirement** — a 1px faint outline no longer passes.
- **Focus not obscured.** New in 2.2: the focused element must not be hidden
  behind a sticky header, a cookie banner or a fixed CTA bar. This is a common
  new failure on sites with a sticky mobile CTA.
- **Target size.** New in 2.2: interactive targets at least 24×24 CSS pixels
  (with exceptions for inline text links). Aim for 44×44 on touch.
- **Skip link** to the main content.
- **Page titles** unique and descriptive.
- **Timing.** Extendable or disableable time limits. No content that moves,
  blinks or auto-updates without a pause control.
- **Motion.** Respect `prefers-reduced-motion`. Nothing flashes more than three
  times per second.
- **Dragging.** New in 2.2: any drag operation has a single-pointer alternative.

### Understandable

- **`lang`** on `<html>`, and on any section in a different language.
- **Consistent** navigation and naming across pages.
- **Labels.** Every input has a visible, associated `<label>`. **A placeholder
  is not a label** — it disappears on focus, usually fails contrast, and is
  inconsistently exposed to assistive technology.
- **Errors** identified in text, associated with the field, and describing how to
  fix them. Announced to assistive technology.
- **No surprises.** Focus or input does not trigger an unexpected context change.
- **Redundant entry** (2.2): do not ask for the same information twice in one
  process.
- **Accessible authentication** (2.2): no cognitive-function test (like
  transcribing a code from memory) without an alternative. Allow paste in
  password and OTP fields — blocking paste breaks password managers.

### Robust

- **Valid HTML.** Unique ids, correct nesting, no duplicate attributes.
- **Name, role, value** exposed for every custom control.
- **Status messages** announced without moving focus (`role="status"`,
  `aria-live="polite"`).

---

## ARIA — the rules

> **The first rule of ARIA: do not use ARIA.**
> A native `<button>` is better than a `<div role="button">` in every respect —
> it is focusable, it responds to Enter and Space, it announces correctly, it
> works when CSS fails, and it needs no JavaScript.

**No ARIA is better than bad ARIA.** Incorrect ARIA actively breaks what would
otherwise work.

```html
<!-- Wrong: an ARIA reimplementation of a solved problem -->
<div role="button" tabindex="0" onclick="save()">Save</div>

<!-- Right -->
<button type="button" onclick="save()">Save</button>
```

The failures to look for:
- `role` applied to an element that already has that role.
- `aria-label` on an element that displays visible text (they conflict, and the
  label wins — so the visible text is not what gets announced).
- `aria-hidden="true"` on something focusable — it is announced as an unlabelled
  element with no context.
- Missing keyboard handlers on a custom control that has ARIA roles.
- `aria-expanded` and `aria-selected` that are set once and never updated.
- A `div` soup with roles instead of `<nav>`, `<main>`, `<ul>` and `<button>`.

When you genuinely need a custom widget, follow an established pattern
completely — every keyboard interaction, every state — or use a maintained
accessible component library.

---

## Focus management

The area most often broken, and the most disorienting when it is.

```
Opening a dialog     → move focus into it (the first interactive element, or the
                       dialog itself with tabindex="-1")
While it is open     → trap focus inside; Escape closes it
Closing it           → RETURN focus to the element that opened it
Route change (SPA)   → move focus to the new page's h1 and announce the change
Content inserted     → announce with a live region; do not steal focus
Deleting an item     → move focus to a sensible neighbour, never to the body
```

Focus landing on `<body>` after an action means keyboard users start again from
the top of the document. It is one of the most common and most frustrating
defects.

---

## Testing

```ts
// In your E2E suite — cheap, and catches regressions permanently
import AxeBuilder from "@axe-core/playwright";

test("checkout has no detectable a11y violations", async ({ page }) => {
  await page.goto("/checkout");
  const { violations } = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"])
    .analyze();
  expect(violations).toEqual([]);
});

test("the whole checkout is keyboard operable", async ({ page }) => {
  await page.goto("/checkout");
  await page.keyboard.press("Tab");
  await expect(page.locator(":focus")).toBeVisible();   // focus is never invisible
  // ... walk the journey with keyboard only
});
```

**Write E2E selectors by role and accessible name.** `getByRole("button", { name:
"Add to cart" })` is stable across refactors *and* fails when accessibility
breaks — you get a regression test for free.

Then the manual pass, which is where the real findings are. See
`references/testing-accessibility.md`.

---

## Reporting

```markdown
### Icon-only buttons have no accessible name — P1

**WCAG**       4.1.2 Name, Role, Value (Level A)
**Location**   src/components/Toolbar.tsx:34-58 (6 buttons)
**Affects**    Screen reader users cannot determine what any toolbar button does.
               They are announced as "button", six times.

**Reproduce**  Enable VoiceOver, Tab into the toolbar, listen.

**Fix**
```diff
- <button onClick={onDelete}><TrashIcon /></button>
+ <button onClick={onDelete} aria-label="Delete selected items">
+   <TrashIcon aria-hidden="true" />
+ </button>
```

**Verify**     axe reports zero "buttons must have discernible text";
               VoiceOver announces "Delete selected items, button".
```

Cite the specific success criterion and level. It makes the finding
non-negotiable and shows the reader it is a standard, not a preference.

---

## Legal context — flag, do not opine

Accessibility is a legal requirement in a growing number of jurisdictions,
including for private-sector services in some. The **European Accessibility Act**
extends obligations to many consumer-facing digital products and services; US
courts have repeatedly applied the ADA to websites; public-sector bodies in
many countries have long-standing obligations.

The engineering answer is the same regardless: **WCAG 2.2 AA, tested with real
assistive technology.** Flag the applicability and build to the standard; leave
the legal interpretation to a lawyer.

## References

- `references/wcag-checklist.md` — the complete auditable checklist by criterion
- `references/component-patterns.md` — accessible implementations of the common widgets
- `references/testing-accessibility.md` — the manual protocol, tools, and screen reader basics
