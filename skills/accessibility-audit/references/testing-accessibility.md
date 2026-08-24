# Testing Accessibility

Automated tools find roughly a third of WCAG issues. The other two thirds — and
almost all the ones that make a product unusable — come from the manual pass.

---

## The layered approach

```
1. Lint          in the editor        catches obvious markup issues as you type
2. Unit          in the test run      per-component axe checks
3. E2E           in CI                per-page axe checks, blocking
4. Manual        before release       keyboard, zoom, screen reader
5. Real users    periodically         the only complete test
```

---

## 1 · Lint

`eslint-plugin-jsx-a11y` (React), `eslint-plugin-vue-a11y`, `svelte-check`, or
your framework's equivalent. Catches missing alt, invalid ARIA, click handlers
on non-interactive elements, and inaccessible autofocus — at zero cost, while
typing.

Enable the rules as **errors**, not warnings. Warnings accumulate and are
ignored.

---

## 2 · Component tests

```ts
import { render } from "@testing-library/react";
import { axe, toHaveNoViolations } from "jest-axe";
expect.extend(toHaveNoViolations);

it("Modal has no detectable accessibility violations", async () => {
  const { container } = render(<Modal open title="Confirm">Body</Modal>);
  expect(await axe(container)).toHaveNoViolations();
});
```

**Testing Library's queries are themselves an accessibility test.** Selecting by
role and accessible name means a test fails when the accessible name disappears:

```ts
// This test breaks if the button loses its accessible name — for free
await user.click(screen.getByRole("button", { name: "Delete project" }));
```

Prefer `getByRole` and `getByLabelText` over `getByTestId` throughout the suite,
for this reason alone.

---

## 3 · E2E checks in CI

```ts
import AxeBuilder from "@axe-core/playwright";

const PAGES = ["/", "/pricing", "/signup", "/checkout", "/account/settings"];

for (const path of PAGES) {
  test(`${path} has no detectable a11y violations`, async ({ page }) => {
    await page.goto(path);
    const { violations } = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"])
      .analyze();

    if (violations.length) {
      console.log(violations.map((v) =>
        `${v.id} (${v.impact}) — ${v.nodes.length} node(s)\n  ${v.help}\n  ${v.helpUrl}`
      ).join("\n\n"));
    }
    expect(violations).toEqual([]);
  });
}
```

Test the **states**, not only the initial render: modal open, dropdown expanded,
form in an error state, list empty, content loading. Most violations live in
states the default render never reaches.

**Keyboard operability, automated:**

```ts
test("checkout is fully keyboard operable", async ({ page }) => {
  await page.goto("/checkout");

  const reached: string[] = [];
  for (let i = 0; i < 40; i++) {
    await page.keyboard.press("Tab");
    const el = page.locator(":focus");
    await expect(el).toBeVisible();                  // focus is never invisible
    reached.push(await el.evaluate((n) => n.tagName + (n.getAttribute("aria-label") ?? n.textContent?.slice(0, 20))));
  }
  expect(reached).toContain(/* the submit button */);
});
```

---

## 4 · The manual pass — where the real findings are

### Keyboard (10 minutes)

Unplug the mouse. Genuinely — do not just "avoid using it".

| Check | Failure looks like |
|---|---|
| Reach every interactive element | A control that Tab skips |
| Always see where focus is | Focus vanishes; you are lost |
| Focus order matches visual order | Tab jumps from header to footer to sidebar |
| Escape closes every overlay | A modal that traps you |
| No permanent trap | Tab cycles forever inside a widget |
| Skip link works | No way past 30 nav links on every page |
| Focus returns after closing a dialog | Focus lands on `<body>`; you start again |
| Focus is never hidden behind a sticky bar | The focused field is under the header |

### Zoom and reflow (5 minutes)

- Browser zoom to **400%** at a 1280px window (≈320px equivalent).
- Is anything cut off? Is there horizontal scrolling? Do fixed elements cover
  the content?
- Then increase text size only (Firefox: text-only zoom) to 200%.
- Then apply the WCAG 1.4.12 text-spacing bookmarklet and check for clipping.

### Colour and contrast (5 minutes)

- Sample real rendered pixels with a contrast checker — not the design token
  values, which are frequently not what ships.
- **Check every state:** hover, focus, active, disabled, placeholder, and text
  over images or gradients.
- Set the OS to greyscale: is any information now lost? (Error states, chart
  series, status badges, required-field markers.)
- Turn on Windows High Contrast / forced-colors mode: does the interface
  survive? Custom-styled controls frequently disappear entirely.

### Screen reader (20 minutes)

The highest-value twenty minutes in this document. It converts "I believe this
is accessible" into evidence.

| Platform | Reader | Start/stop | Essentials |
|---|---|---|---|
| Windows | **NVDA** (free) | `Ctrl+Alt+N` | `H` next heading · `D` landmark · `F` form field · `K` link · `Insert+F7` element list |
| macOS | **VoiceOver** (built in) | `Cmd+F5` | `Ctrl+Opt+→` next · `Ctrl+Opt+U` rotor · `Ctrl` to silence |
| iOS | VoiceOver | Settings → Accessibility | Swipe right/left · double-tap to activate |
| Android | TalkBack | Settings → Accessibility | Swipe right/left · double-tap |

**What to listen for:**
- Does the page announce a sensible structure? Pull up the heading list — does it
  read like an outline of the page?
- Does every control announce a name **and** a role? "Button" alone is a
  failure.
- Are state changes announced — loading, error, success, expanded, selected?
- Do images announce something useful, or a filename?
- Is anything announced twice (usually an `aria-label` duplicating visible
  text)?
- Is anything announced that should be hidden (decorative icons without
  `aria-hidden`)?

Test on **both** NVDA/Firefox and VoiceOver/Safari where you can — they differ
in real ways, and a pattern that works in one sometimes fails in the other.

### Mobile (10 minutes)

- Real device, screen reader on.
- Target sizes comfortable for a thumb (24×24 minimum, 44×44 preferred).
- Does the layout survive a device-font-size increase to maximum?
- Both orientations.
- Zoom **not** disabled — `user-scalable=no` in the viewport meta is a failure.

---

## 5 · Real users

Nothing in this document substitutes for watching someone who uses assistive
technology daily attempt your critical journey. Expert users navigate
differently from anyone testing with a screen reader for the first time, and
they find things no checklist contains.

For a product with a legal obligation or significant reach, budget for a
professional audit and for user testing with disabled participants.

---

## Tools

| Tool | Use |
|---|---|
| **axe DevTools** | The best browser scanner; low false-positive rate |
| **Lighthouse** | Quick score; subset of axe |
| **WAVE** | Good visual overlay of structure and issues |
| **Accessibility Insights** | Guided manual assessment — excellent for the parts automation cannot check |
| **Browser accessibility tree** | DevTools → Accessibility. Shows exactly what is exposed to assistive technology |
| **Contrast checkers** | For sampled, real rendered colours |
| **Screen readers** | NVDA, VoiceOver, TalkBack. Free and built in |
| **Keyboard** | The single most effective tool here |

The **accessibility tree** in DevTools deserves particular mention: it shows the
computed name, role and state of any element. When you are unsure why something
announces oddly, it gives the answer directly rather than by inference.

---

## Interpreting automated results

**False positives exist**, but they are rarer than teams assume. Before
dismissing one, check the accessibility tree — most "false positives" turn out
to be real.

**Absence of violations is not conformance.** axe checks perhaps a third of the
criteria. A page with zero violations can still be unusable: focus order can be
nonsense, alt text can be wrong, a custom widget can announce correctly and
behave incorrectly.

**Report the split.** "Automated scan: clean. Manual keyboard and screen reader
pass: 6 findings." That tells the reader how much coverage they actually have —
which is the difference between an accessibility report and an accessibility
claim.
