# WCAG 2.2 AA — Auditable Checklist

Every Level A and AA success criterion, phrased as something you can check.
Criteria added or changed in WCAG 2.2 are marked **[2.2]**.

Cite the criterion number and level in every finding — it turns a preference
into a standard.

---

## 1 · Perceivable

### 1.1 Text alternatives
- [ ] **1.1.1 Non-text Content (A)** — every image, icon, chart, and media
      element has an appropriate text alternative. Decorative images have
      `alt=""`. Icon-only controls have an accessible name. CAPTCHAs offer an
      alternative form.

### 1.2 Time-based media
- [ ] **1.2.1 Audio-only / Video-only (A)** — a transcript for audio; a
      description or transcript for silent video.
- [ ] **1.2.2 Captions (A)** — synchronised captions for all prerecorded video
      with audio.
- [ ] **1.2.3 Audio Description or Alternative (A)**
- [ ] **1.2.4 Captions (Live) (AA)**
- [ ] **1.2.5 Audio Description (AA)** — for prerecorded video.

### 1.3 Adaptable
- [ ] **1.3.1 Info and Relationships (A)** — structure conveyed visually is
      conveyed in markup: real headings in order, real lists, tables with `<th>`
      and `scope`, fieldsets with legends, labels associated with inputs.
- [ ] **1.3.2 Meaningful Sequence (A)** — DOM order matches reading order.
      Check where CSS reorders content (`order`, `grid-area`, absolute
      positioning) — the visual order and the keyboard order must agree.
- [ ] **1.3.3 Sensory Characteristics (A)** — instructions do not rely on shape,
      size or position alone ("click the round button on the right").
- [ ] **1.3.4 Orientation (AA)** — content is not locked to portrait or
      landscape.
- [ ] **1.3.5 Identify Input Purpose (AA)** — `autocomplete` attributes on
      fields collecting the user's own information.

### 1.4 Distinguishable
- [ ] **1.4.1 Use of Colour (A)** — colour is never the only means of conveying
      information. Check: error states, required fields, chart series, status
      badges, and links within body text.
- [ ] **1.4.2 Audio Control (A)** — audio that plays for more than 3 seconds can
      be paused or stopped.
- [ ] **1.4.3 Contrast (Minimum) (AA)** — **4.5:1** for normal text, **3:1** for
      large text (≥24px, or ≥19px bold). Check hover, focus, disabled and
      placeholder states — that is where it is usually lost.
- [ ] **1.4.4 Resize Text (AA)** — text scales to 200% without loss of content
      or function.
- [ ] **1.4.5 Images of Text (AA)** — use real text, not text baked into an
      image.
- [ ] **1.4.10 Reflow (AA)** — no horizontal scrolling at 320 CSS pixels wide
      (equivalently, 400% zoom at 1280px).
- [ ] **1.4.11 Non-text Contrast (AA)** — **3:1** for UI component boundaries
      (input borders, button edges, toggle states) and for graphics that convey
      meaning (icons, chart elements).
- [ ] **1.4.12 Text Spacing (AA)** — no loss of content when line height is set
      to 1.5×, paragraph spacing to 2×, letter spacing to 0.12em and word
      spacing to 0.16em.
- [ ] **1.4.13 Content on Hover or Focus (AA)** — tooltips and popovers are
      dismissible (Escape), hoverable (the pointer can move onto them), and
      persistent (they do not vanish on a timer).

---

## 2 · Operable

### 2.1 Keyboard accessible
- [ ] **2.1.1 Keyboard (A)** — all functionality is available from a keyboard.
- [ ] **2.1.2 No Keyboard Trap (A)** — focus can always move away using the
      keyboard alone.
- [ ] **2.1.4 Character Key Shortcuts (A)** — single-character shortcuts can be
      turned off, remapped, or are active only on focus. They break dictation
      software otherwise.

### 2.2 Enough time
- [ ] **2.2.1 Timing Adjustable (A)** — time limits can be turned off, adjusted,
      or extended. Session timeouts must warn and allow extension.
- [ ] **2.2.2 Pause, Stop, Hide (A)** — moving, blinking, scrolling or
      auto-updating content lasting more than 5 seconds can be paused. Carousels
      need a pause control.

### 2.3 Seizures
- [ ] **2.3.1 Three Flashes or Below (A)** — nothing flashes more than three
      times per second.

### 2.4 Navigable
- [ ] **2.4.1 Bypass Blocks (A)** — a skip link, or proper landmark regions.
- [ ] **2.4.2 Page Titled (A)** — unique and descriptive `<title>` per page.
- [ ] **2.4.3 Focus Order (A)** — focus order preserves meaning and operability.
- [ ] **2.4.4 Link Purpose (In Context) (A)** — link text describes the
      destination. Multiple "Read more" links on one page fail this.
- [ ] **2.4.5 Multiple Ways (AA)** — more than one way to find a page
      (navigation, search, sitemap).
- [ ] **2.4.6 Headings and Labels (AA)** — descriptive, not generic.
- [ ] **2.4.7 Focus Visible (AA)** — a visible focus indicator on every focusable
      element. `outline: none` with no replacement is a failure.
- [ ] **2.4.11 Focus Not Obscured (Minimum) (AA) [2.2]** — the focused element
      is not entirely hidden by author-created content. **Check sticky headers,
      cookie banners and fixed mobile CTA bars** — this is the most common new
      2.2 failure.

### 2.5 Input modalities
- [ ] **2.5.1 Pointer Gestures (A)** — multipoint or path-based gestures have a
      single-pointer alternative.
- [ ] **2.5.2 Pointer Cancellation (A)** — actions fire on the up-event, so a
      mis-press can be aborted by moving away.
- [ ] **2.5.3 Label in Name (A)** — the accessible name contains the visible
      label text. Otherwise voice-control users cannot activate the control by
      saying what they see.
- [ ] **2.5.4 Motion Actuation (A)** — device-motion triggers have a
      conventional alternative and can be disabled.
- [ ] **2.5.7 Dragging Movements (AA) [2.2]** — any drag operation has a
      single-pointer alternative (a menu, buttons, a form field).
- [ ] **2.5.8 Target Size (Minimum) (AA) [2.2]** — targets are at least **24×24
      CSS pixels**, or have sufficient spacing. Inline links in text are exempt.
      Aim for 44×44 on touch surfaces.

---

## 3 · Understandable

### 3.1 Readable
- [ ] **3.1.1 Language of Page (A)** — `<html lang="...">`.
- [ ] **3.1.2 Language of Parts (AA)** — `lang` on content in another language.

### 3.2 Predictable
- [ ] **3.2.1 On Focus (A)** — receiving focus does not trigger a context change.
- [ ] **3.2.2 On Input (A)** — changing a value does not automatically submit or
      navigate without warning.
- [ ] **3.2.3 Consistent Navigation (AA)** — navigation appears in the same
      relative order across pages.
- [ ] **3.2.4 Consistent Identification (AA)** — the same function is labelled
      the same way throughout.
- [ ] **3.2.6 Consistent Help (A) [2.2]** — help mechanisms (contact details,
      chat, help link) appear in the same relative place on every page that has
      them.

### 3.3 Input assistance
- [ ] **3.3.1 Error Identification (A)** — errors are described **in text** and
      the field is identified.
- [ ] **3.3.2 Labels or Instructions (A)** — every input has a visible,
      associated label. **A placeholder is not a label.**
- [ ] **3.3.3 Error Suggestion (AA)** — the error says how to fix it. "Invalid
      date" fails; "Enter a date in the future, in DD/MM/YYYY format" passes.
- [ ] **3.3.4 Error Prevention (Legal, Financial, Data) (AA)** — submissions
      that are legal, financial or that delete data are reversible, checked, or
      confirmed.
- [ ] **3.3.7 Redundant Entry (A) [2.2]** — information already provided in the
      same process is auto-populated or selectable, not re-typed.
- [ ] **3.3.8 Accessible Authentication (Minimum) (AA) [2.2]** — no cognitive
      function test (remembering, transcribing, solving a puzzle) is required
      without an alternative. **Allow paste in password and OTP fields** —
      blocking paste breaks password managers and fails this criterion.

---

## 4 · Robust

- [ ] **4.1.2 Name, Role, Value (A)** — every UI component exposes a name, a
      role and its current state, and updates them as the state changes.
- [ ] **4.1.3 Status Messages (AA)** — status, error and success messages are
      announced to assistive technology **without moving focus** — via
      `role="status"`, `role="alert"`, or `aria-live`.

(4.1.1 Parsing was removed in WCAG 2.2. Valid HTML still matters — duplicate ids
break `aria-labelledby` and `for`/`id` associations in practice.)

---

## Priority order for remediation

When you cannot fix everything at once:

1. **Keyboard traps and unreachable functionality** — the user cannot proceed at
   all.
2. **Missing accessible names on controls** — the user cannot know what
   anything does.
3. **Invisible focus** — the keyboard user is lost on every page.
4. **Form labels and error identification** — the user cannot complete the task.
5. **Contrast failures** — the user cannot read it.
6. **Structure (headings, landmarks)** — the user cannot navigate efficiently.
7. **Everything else.**

---

## What automation can and cannot find

**Automated tools reliably find:** missing alt attributes, contrast failures on
static text, missing form labels, duplicate ids, missing `lang`, empty buttons
and links, and some ARIA misuse.

**Only a human finds:** whether alt text is *meaningful*, whether focus order
makes *sense*, whether an error message is *helpful*, whether a custom widget
behaves as a screen reader user expects, whether the reading order matches the
visual order, and whether the journey is actually completable.

Run both. Report which findings came from which — it tells the reader how much
coverage they have.
