---
name: engineering-standards
description: Team engineering practice — code conventions and readability, git and branching workflow, commit and pull request hygiene, code review standards, architecture decision records, documentation and runbooks, onboarding, developer experience, and managing technical debt deliberately. Use when the user says "code review", "conventions", "code style", "git workflow", "branching", "commit messages", "pull request", "ADR", "documentation", "README", "onboarding", "developer experience", "technical debt", "refactor", "CLAUDE.md", "AGENTS.md" or "how should the team work"; and as a pass in any project audit covering documentation and DX. By Devleck.
license: MIT
---

# Engineering Standards

Conventions exist to remove decisions that do not matter, so attention goes to
the ones that do. **The specific choice matters far less than the consistency**
— three ways to do the same thing in one codebase is a defect even when all
three work.

---

## Code that reads well

Optimise for the reader. Code is read many more times than it is written, and
usually by someone who has forgotten writing it.

- **Names carry the meaning.** `daysUntilExpiry` beats `d`. A good name removes
  the need for a comment.
- **Comments explain *why*, never *what*.** The code says what. A comment that
  restates the line is noise that will go stale; one that records the reason
  ("the provider returns 200 on failure, so we check the body") is permanent
  value.
- **Functions do one thing** at one level of abstraction. Mixing "orchestrate the
  checkout" with "format a date string" in one function forces the reader to
  change altitude mid-sentence.
- **Early returns over nesting.** Handle the failure and leave; keep the happy
  path unindented.
- **Make illegal states unrepresentable.** A discriminated union beats a struct
  with six optional fields and a comment explaining which combinations are valid.
- **Explicit over clever.** The clever line saves you a minute now and costs
  someone twenty later.
- **Consistent error handling.** One approach per codebase, applied everywhere.

**Match the codebase you are in.** Even where you would have chosen differently.
Argue for the change in a PR of its own; do not smuggle it in alongside a
feature.

---

## Git workflow

**Trunk-based, with short-lived branches**, is right for the large majority of
teams. Long-lived branches accumulate merge risk in direct proportion to their
age.

```
main ──●──●──●──●──●──●──►   always deployable, protected
        \        /
         ●──●──●             feature branch: 1-3 days, then merged
```

Use Git Flow only if you genuinely ship versioned releases to customers who
choose when to upgrade. For anything continuously deployed it is friction with
no benefit.

**Branch protection on `main`:** no direct pushes, review required, status
checks required, force-push disabled.

### Commits

```
feat(billing): add proration for mid-cycle plan changes

Customers upgrading mid-cycle were charged the full new price.
Now we credit the unused portion of the current period and charge
the difference, matching what the pricing page promises.

Fixes #482
```

- **Imperative mood**, present tense: "add", not "added" or "adds". It reads as
  an instruction to the codebase, which is what a commit is.
- Subject under ~72 characters. Body explains *why*, wrapping at 72.
- **One logical change per commit.** A commit that changes formatting *and*
  behaviour is a commit nobody can review or revert cleanly.
- Conventional Commits (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`,
  `perf`) if you want automated changelogs and semantic versioning. Adopt it as
  a whole or not at all — half-applied it just adds noise.
- **Never** `wip`, `fix`, `stuff`, `asdf`, or `.` as a commit message on `main`.

### Pull requests

**Small.** Review quality falls off a cliff past a few hundred lines. A 1,000-line
PR gets "LGTM"; a 100-line PR gets read.

```markdown
## What
One or two sentences.

## Why
The problem this solves. Link the issue.

## How
Only if the approach is non-obvious. Note anything you rejected and why.

## Testing
What you tested, and how a reviewer can verify it.

## Screenshots
For any UI change. Before and after.

## Checklist
- [ ] Tests added or updated
- [ ] Docs updated if behaviour changed
- [ ] No new personal data collected, or the privacy inventory is updated
- [ ] Migration is reversible and tested
```

**The author's job is to make review easy.** Separate refactors from behaviour
changes. Leave comments on your own diff explaining anything surprising. Say
what you are unsure about — that is where you want attention.

---

## Code review

**What review is for:** correctness, missed edge cases, security, whether the
change fits the system, and knowledge transfer. It is **not** for style — that
is the formatter's job, automated, with no human discussion.

**Reviewer conduct**
- **Review within one working day.** A blocked PR is a blocked person, and the
  branch is getting staler.
- **Distinguish blocking from optional.** Prefix non-blocking comments —
  `nit:`, `suggestion:`, `question:`, `praise:`. Without this, every comment
  reads as a demand.
- **Ask, do not assert.** "What happens if this is null?" beats "this will
  crash" — and is right more often.
- **Say what is good.** Review that is only criticism trains people to dread it.
- **Approve with comments** when the remaining points are minor. Blocking a PR
  over a preference is a tax on the whole team.

**Author conduct**
- Respond to every comment, even if only to say "good catch, fixed".
- Disagree with reasons, not by ignoring. If you and the reviewer cannot
  converge in two rounds, talk — a thread with fifteen replies is a conversation
  that should have been a call.
- Do not force-push mid-review; it destroys the reviewer's ability to see what
  changed.

**Escalate rather than block indefinitely.** A PR stuck for a week is a process
failure, not a code failure.

---

## Documentation

Write the documents that are read. Skip the ones that are not.

| Document | Purpose | Failure mode |
|---|---|---|
| **README** | Get someone running in 15 minutes | Stale; describes a setup that no longer works |
| **ADR** | Why an expensive decision was made | Never written; the decision is relitigated every six months |
| **Runbook** | What to do at 3am | Written once, never executed, half the commands wrong |
| **API docs** | How to integrate | Hand-maintained, and wrong within a month |
| **CLAUDE.md / AGENTS.md** | Conventions, for humans and AI assistants | Absent, so every AI-generated change fights the codebase |
| Architecture overview | Orientation | A diagram of an architecture that was replaced |

**The rule:** documentation that is not generated, or not exercised, decays.
Generate API docs from the code. Exercise runbooks in drills. Keep the README in
CI by having the setup script be the thing the README describes.

**ADRs** are the highest-value-per-word document in this list. One page —
context, options, decision, consequences — for every one-way door. Six months
later it is what stops the team relitigating a settled question, and what tells
a new engineer whether a constraint is a decision or an accident. See
`project-blueprint/templates/adr.md`.

**`CLAUDE.md` / `AGENTS.md`** deserve a specific mention now that AI assistance
is routine. A short file describing your conventions, your directory layout,
your test commands and your non-negotiables makes AI-generated code match the
codebase instead of fighting it. It costs twenty minutes and pays back on every
subsequent change.

---

## Onboarding

**The test:** hand a new engineer the README and time them. If they are not
running the project in 15 minutes, the README is wrong — not the engineer.

The first week should produce a merged pull request. Not a large one — a real
one. It exercises the whole path (setup, convention, review, CI, deploy) and it
finds every broken step in the process.

**Have the newest person fix the onboarding docs.** They are the only one who can
see what is missing; everyone else has forgotten.

---

## Developer experience

DX is not comfort. It is the rate at which the team can safely change the system.

| Signal | Healthy | Fix if not |
|---|---|---|
| Setup | One command | The single highest-value DX investment |
| Feedback loop | Under 10s for unit tests | Slow tests do not get run |
| CI duration | Under 10 minutes | People stop waiting and merge around it |
| Flaky tests | Zero in the blocking set | A tolerated flake destroys the suite's signal |
| Local vs production parity | Same engines and versions | "Works on my machine" is a parity bug |
| Time to first PR | Under one week | The onboarding path is broken |
| Deploy | One action, reversible | Fear of deploying produces large, risky releases |

Every hour spent on the feedback loop is repaid many times over, by every
engineer, on every change.

---

## Technical debt

Debt is not a moral failure — taking it on deliberately to ship is often
correct. The failure is taking it on **invisibly**.

**Make it visible.**

```markdown
## Debt register

| # | What | Where | Cost now | Cost if unfixed | Effort | Trigger |
|---|---|---|---|---|---|---|
| 1 | Payment retry logic duplicated in 3 places | billing/ | Bugs fixed 3× | Divergence → double charges | M | Next billing change |
| 2 | No index on `events.user_id` | schema | 400ms on the timeline | Linear degradation | S | At 1M events |
| 3 | Auth logic in the controller | api/auth | Untestable | Blocks the SSO feature | L | Before SSO |
```

**The "trigger" column is what makes this useful.** Debt with no trigger is
never repaid; debt with a trigger gets fixed at the moment it is cheapest,
because you are already in that code.

**The boy-scout rule, bounded:** leave code better than you found it — within
the scope of what you are doing. Do not bundle a refactor into a bug fix; the
reviewer cannot then see the fix.

**Do not rewrite.** Recommending a rewrite is almost always wrong and always
expensive. If you genuinely believe it, name the specific unfixable property
that forces it, and price it honestly. Then consider strangling it incrementally
instead.

---

## The audit questions

1. Could a new engineer set this up in 15 minutes from the README alone?
2. Is there one way to do each thing, or several?
3. Are the expensive decisions recorded anywhere?
4. Does CI block merge, and does anyone bypass it?
5. What is the median PR size and review turnaround?
6. Is there a runbook for the three most likely failures, and has anyone run it?
7. Is known debt written down with triggers, or carried in one person's head?
8. What is the bus factor on deploys, on the database, and on the payment
   integration?

## References

- `references/conventions.md` — code style, naming, structure, comments
- `references/git-and-review.md` — branching, commits, PR and review practice in depth
- `references/documentation.md` — what to write, what to generate, what to skip
