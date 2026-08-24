# Accessible Component Patterns

**Use the native element.** Every pattern below exists because a native element
does not cover the case. Where one does, the native element wins on every axis:
focusable by default, keyboard-operable by default, correctly announced,
functional without JavaScript, and free.

```html
<!-- If you find yourself writing this, stop -->
<div role="button" tabindex="0" onclick="…" onkeydown="…">Save</div>
<button type="button" onclick="…">Save</button>          <!-- this is complete -->
```

---

## Buttons and links — the distinction matters

```html
<!-- Navigates somewhere → a link. Works with Enter, middle-click, right-click. -->
<a href="/settings">Settings</a>

<!-- Performs an action → a button. Works with Enter AND Space. -->
<button type="button" onclick="save()">Save</button>

<!-- Icon-only: must have an accessible name -->
<button type="button" aria-label="Delete item">
  <svg aria-hidden="true" focusable="false"><!-- … --></svg>
</button>

<!-- Icon plus text: label the SVG out, do not double-announce -->
<button type="button">
  <svg aria-hidden="true" focusable="false"><!-- … --></svg>
  Delete
</button>
```

A link styled as a button is fine. A `div` behaving as either is not. And an
`<a>` with no `href` is not focusable — it is a `div` with underlines.

---

## Forms

```html
<div class="field">
  <label for="email">Email address</label>
  <input
    id="email"
    name="email"
    type="email"
    autocomplete="email"
    required
    aria-describedby="email-hint email-error"
    aria-invalid="true">                         <!-- only when actually invalid -->

  <p id="email-hint" class="hint">We'll only use this to sign you in.</p>
  <p id="email-error" class="error" role="alert">
    Enter an email address in the format name@example.com
  </p>
</div>
```

**The rules**

- **Visible label, always**, associated by `for`/`id`. A placeholder is not a
  label: it disappears on focus, usually fails contrast, and is inconsistently
  exposed to assistive technology.
- `autocomplete` on anything about the user (WCAG 1.3.5) — and it makes mobile
  forms dramatically faster.
- `aria-describedby` links hint and error text to the field, so a screen reader
  reads them with the label.
- `aria-invalid="true"` only while invalid.
- **Errors say how to fix it.** "Invalid" fails 3.3.3; "Enter a date in the
  future" passes.
- **On submit failure: move focus to the first invalid field**, or to an error
  summary at the top that links to each field.
- **Never remove entered data** on a validation error.
- **Allow paste** in password and OTP fields — blocking it breaks password
  managers and fails WCAG 2.2's accessible authentication criterion.
- Group related inputs (radios, checkboxes, address parts) in
  `<fieldset>`/`<legend>`.

```html
<fieldset>
  <legend>Delivery speed</legend>
  <label><input type="radio" name="speed" value="standard"> Standard (3–5 days)</label>
  <label><input type="radio" name="speed" value="express"> Express (next day)</label>
</fieldset>
```

---

## Modal dialog

The pattern most often broken, and the most disorienting when it is.

```html
<dialog id="confirm" aria-labelledby="confirm-title">
  <h2 id="confirm-title">Delete this project?</h2>
  <p>This cannot be undone. All 42 files will be permanently removed.</p>
  <button type="button" data-close>Cancel</button>
  <button type="button" data-confirm>Delete project</button>
</dialog>
```

```js
const dialog = document.getElementById("confirm");
let opener = null;

function open() {
  opener = document.activeElement;      // remember where we came from
  dialog.showModal();                   // native: focus trap + Escape + inert background
  dialog.querySelector("button").focus();
}

dialog.addEventListener("close", () => {
  opener?.focus();                      // RETURN focus. This is the step people miss.
});
```

**Use `<dialog>` with `showModal()`.** It gives you the focus trap, Escape
handling, and the inert background for free — all three of which are commonly
wrong in hand-rolled implementations.

If you must build your own: trap focus inside, close on Escape, mark the rest of
the page `inert` or `aria-hidden="true"`, move focus in on open, and **return
focus to the opener on close**.

---

## Disclosure (show/hide)

```html
<button type="button" aria-expanded="false" aria-controls="details-1">
  Shipping information
</button>
<div id="details-1" hidden>…</div>
```
```js
btn.addEventListener("click", () => {
  const open = btn.getAttribute("aria-expanded") === "true";
  btn.setAttribute("aria-expanded", String(!open));   // MUST update
  panel.hidden = open;
});
```

Or simply `<details><summary>Shipping information</summary>…</details>`, which
is accessible with no JavaScript, and whose content is still crawled and still
counts as visible for structured-data purposes.

**The failure to look for:** `aria-expanded` set in the markup and never updated
by the handler.

---

## Tabs

```html
<div role="tablist" aria-label="Account settings">
  <button role="tab" id="tab-1" aria-selected="true"  aria-controls="panel-1" tabindex="0">Profile</button>
  <button role="tab" id="tab-2" aria-selected="false" aria-controls="panel-2" tabindex="-1">Billing</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1" tabindex="0">…</div>
<div role="tabpanel" id="panel-2" aria-labelledby="tab-2" tabindex="0" hidden>…</div>
```

**Keyboard contract** (this is the part usually missing):
- `Tab` moves into the tablist, then out to the panel — **not** between tabs.
- **Arrow keys** move between tabs. `Home`/`End` jump to first/last.
- Only the active tab is in the tab order (`tabindex="0"`); the others are `-1`.
  This is the "roving tabindex" pattern.

If the keyboard contract is not implemented, do not add the ARIA — a set of
links or buttons with no `role="tab"` is more usable than a broken tablist.

---

## Menu / dropdown

Two different things, frequently confused:

**A navigation dropdown** is a disclosure containing a list of links. Use the
disclosure pattern above with a `<ul>` of `<a>` elements. Do **not** use
`role="menu"` — that role is for application menus and brings keyboard
expectations (arrow-key-only navigation) that a navigation menu should not have.

**An application menu** (like a right-click menu or a toolbar action list) uses
`role="menu"` / `role="menuitem"`, with arrow-key navigation, Escape to close,
type-ahead, and focus returning to the trigger.

Getting this backwards is one of the most common ARIA misuses on the web.

---

## Combobox / autocomplete

Genuinely hard to build correctly. **Strongly prefer a maintained accessible
library** over a bespoke implementation.

The requirements: `role="combobox"` with `aria-expanded` and `aria-controls`; a
listbox of options; `aria-activedescendant` to indicate the highlighted option
without moving focus; arrow keys to navigate; Enter to select; Escape to close;
and a live region announcing the number of results as the user types.

If you cannot commit to all of that, a native `<select>`, or a text input with a
`<datalist>`, is a better product decision than a broken combobox.

---

## Data tables

```html
<table>
  <caption>Invoices, January 2026</caption>
  <thead>
    <tr>
      <th scope="col">Invoice</th>
      <th scope="col">Date</th>
      <th scope="col">Amount</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">INV-1042</th>
      <td>12 Jan 2026</td>
      <td>$1,240.00</td>
    </tr>
  </tbody>
</table>
```

- `<caption>` names the table.
- `scope="col"` and `scope="row"` — without them, a screen reader cannot
  associate a cell with its headers, and the table is a wall of unlabelled
  values.
- Sortable columns: a `<button>` inside the `<th>`, with `aria-sort` on the
  `<th>` updated to `ascending`, `descending` or `none`.
- **Never use a table for layout.** Never use `div`s for tabular data.
- Wrap wide tables in a focusable scroll container so keyboard users can scroll
  it:
  ```html
  <div class="table-wrap" tabindex="0" role="region" aria-label="Invoices">
  ```

---

## Toasts and status messages

```html
<!-- Polite: announced when the user is idle. For success and progress. -->
<div role="status" aria-live="polite" aria-atomic="true"></div>

<!-- Assertive: interrupts. For errors only. Use sparingly. -->
<div role="alert" aria-live="assertive" aria-atomic="true"></div>
```

- **The container must exist in the DOM before the message is inserted.**
  Creating the live region and its content at the same time frequently announces
  nothing.
- **Do not move focus** to a toast — it interrupts the user's task.
- Do not auto-dismiss critical information. Screen reader users and slow readers
  need time; WCAG 2.2.1 applies.
- One live region per politeness level, reused. Multiple competing live regions
  produce announcement chaos.

---

## Skip link

```html
<a href="#main" class="skip-link">Skip to main content</a>
…
<main id="main" tabindex="-1">…</main>
```
```css
.skip-link {
  position: absolute; left: -9999px;
  /* Visible when focused — the entire point */
}
.skip-link:focus { left: 1rem; top: 1rem; z-index: 100; }
```

`tabindex="-1"` on the target so focus actually moves there. Without it, some
browsers scroll but leave focus behind.

---

## Reduced motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

Respect it in JavaScript too:
```js
const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
if (!reduce) startParallax();
```

Vestibular disorders make large parallax and zoom animations genuinely
nauseating. This is not a preference to override.

---

## Focus indicator

```css
/* Never remove without replacing */
:focus-visible {
  outline: 3px solid var(--focus);
  outline-offset: 2px;
  border-radius: 2px;
}
/* Only suppress the default when you have provided your own */
:focus:not(:focus-visible) { outline: none; }
```

WCAG 2.2 tightened the appearance requirement: a 1px faint outline no longer
passes. Aim for at least 2px, with 3:1 contrast against both the component and
the adjacent background — which usually means two colours, or an outline plus an
offset ring, to survive both light and dark surroundings.

---

## The review checklist for any component

- [ ] Could a native element do this instead?
- [ ] Reachable and operable by keyboard alone
- [ ] Visible focus indicator meeting the contrast requirement
- [ ] Accessible name, role and state exposed — and **updated** on change
- [ ] Escape closes anything that opens
- [ ] Focus moves in on open and **returns to the opener** on close
- [ ] Announced correctly in a real screen reader (test it)
- [ ] Contrast passes in every state, including hover, focus and disabled
- [ ] Target at least 24×24 CSS pixels
- [ ] Works at 400% zoom without horizontal scrolling
- [ ] Respects `prefers-reduced-motion`
- [ ] Not obscured by a sticky header or fixed CTA bar when focused
