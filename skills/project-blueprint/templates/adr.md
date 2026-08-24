# ADR-`NNNN`: `<Short decision title, stated as the decision>`

| | |
|---|---|
| **Status** | Proposed / Accepted / Superseded by ADR-NNNN / Deprecated |
| **Date** | `YYYY-MM-DD` |
| **Deciders** | `<names>` |
| **Reversibility** | One-way door / Reversible with effort / Easily reversible |

---

## Context

What forces are at play? Be factual and neutral — describe the problem, the
constraints and the requirements, not the solution.

Include:
- The concrete problem this decision addresses (with numbers where they exist).
- Constraints: team size and skills, budget, deadline, regulatory, existing
  systems.
- What is genuinely uncertain, and what is settled.

> A reader six months from now should be able to tell whether the context still
> holds. If it no longer does, this ADR should be superseded rather than quietly
> ignored.

---

## Options considered

### Option A — `<name>`
- **How it works:** `<one paragraph>`
- **Pros:** `<specific to this context, not generic>`
- **Cons:** `<specific>`
- **Cost to reverse:** `<hours / days / project>`

### Option B — `<name>`
`<same shape>`

### Option C — Do nothing / defer
Always consider this one explicitly. Deferring is sometimes correct, and naming
it as an option forces you to state what deferring costs.

---

## Decision

> We will `<decision, in one sentence, in the present tense>`.

Because `<the one or two factors that actually decided it — not a summary of all
the pros>`.

---

## Consequences

**What becomes easier**
- `<specific>`

**What becomes harder**
- `<specific — this section being empty means the analysis was not honest>`

**What this commits us to**
- `<the obligations this creates: operational burden, vendor dependency, a
  migration we now owe, a skill the team must acquire>`

**Exit cost**
- `<what it would take to reverse this, concretely>`

**How we would know this was wrong**
- `<the observable signal that should trigger revisiting this ADR>`

---

## Follow-ups

- [ ] `<work this decision creates>`
- [ ] `<monitoring or review this decision requires>`

---

<sub>ADRs live in `docs/adr/` and are numbered sequentially. Never edit an
accepted ADR to change its decision — write a new one that supersedes it, and
update the old one's status. The history of what was decided and later reversed
is more valuable than a tidy directory.</sub>
