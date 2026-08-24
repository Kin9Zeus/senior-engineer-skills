# Git Workflow and Code Review

## Branching

**Trunk-based with short-lived branches** for anything continuously deployed —
which is most products.

```
main ──●──●──●──●──●──●──►    always deployable, protected
        \        /
         ●──●──●              1-3 days, then merged and deleted
```

The reason is arithmetic: merge risk grows with branch age and with the number
of commits landing on `main` meanwhile. A three-day branch merges cleanly; a
three-week branch is a project.

**Use Git Flow only** if you genuinely ship versioned releases that customers
choose when to upgrade. For a continuously deployed product it is friction
without benefit.

**Feature flags decouple deploy from release.** Merge incomplete work behind a
flag rather than holding a branch open for three weeks. Give every flag an owner
and a removal date at creation — flags without expiry become permanent untested
branching.

### Branch protection on `main`

- [ ] No direct pushes
- [ ] At least one approving review
- [ ] Status checks must pass
- [ ] Branches must be up to date before merging
- [ ] Force-push and deletion disabled
- [ ] `CODEOWNERS` for sensitive paths (auth, payments, migrations, CI config)

---

## Commits

```
feat(billing): add proration for mid-cycle plan changes

Customers upgrading mid-cycle were charged the full new price for the
remainder of the period. We now credit the unused portion of the current
plan and charge only the difference, which matches what the pricing page
has always promised.

The credit is computed from whole days remaining, not seconds, to match
the invoice display and avoid off-by-one disputes.

Fixes #482
```

**Format**
```
<type>(<scope>): <subject in the imperative, under ~72 chars>

<body: WHY, wrapped at 72. What changed is in the diff.>

<footer: Fixes #123 · BREAKING CHANGE: …>
```

**Types** (Conventional Commits): `feat`, `fix`, `docs`, `refactor`, `perf`,
`test`, `build`, `ci`, `chore`. Adopt the convention wholly or not at all —
half-applied it just adds noise without enabling the tooling (changelogs,
semantic versioning) that justifies it.

**Rules**
- Imperative mood: "add", not "added" or "adds". A commit is an instruction to
  the codebase.
- **One logical change per commit.** A commit mixing formatting and behaviour is
  unreviewable and unrevertable.
- Never `wip`, `fix`, `stuff`, `.` on `main`. Clean the history before merging.
- `git rebase -i` to tidy your own branch before review. Never rebase a branch
  someone else has based work on.
- If a commit message needs "and", it is probably two commits.

**Why it matters:** `git log` is the only documentation guaranteed to still
exist in five years. `git blame` on a confusing line should answer "why is this
here?" — that is the payoff for the discipline.

---

## Pull requests

### Size is the dominant factor in review quality

| PR size | What actually happens |
|---|---|
| < 100 lines | Read line by line. Real defects found |
| 100–400 lines | Read carefully. Most defects found |
| 400–1000 lines | Skimmed. Structural feedback only |
| > 1000 lines | "LGTM" |

If a change is genuinely large, **split it**: the refactor first, then the
behaviour change; the schema migration first, then the code that uses it; the
new module first, then the wiring.

### Template

```markdown
## What
One or two sentences.

## Why
The problem this solves. Link the issue.

## How
Only if the approach is non-obvious. Say what you considered and rejected.

## Testing
What you tested and how the reviewer can verify it.

## Screenshots
Any UI change. Before and after.

## Checklist
- [ ] Tests added or updated
- [ ] Docs updated if behaviour changed
- [ ] No new personal data collected, or the inventory and policy are updated
- [ ] Migration is reversible and tested at production scale
- [ ] No new secret, and no personal data added to logs
```

### The author's job is to make review easy

- **Self-review first.** Read your own diff before requesting review; you will
  find the debug statement and the leftover comment.
- **Annotate your own diff** where something is surprising, or where you want
  attention.
- **Say what you are unsure about.** "I'm not confident about the transaction
  boundary here" directs review where it is most valuable.
- **Separate mechanical from meaningful.** A rename touching 40 files goes in its
  own commit, ideally its own PR.
- **Do not force-push mid-review** — it destroys the reviewer's ability to see
  what changed since their last look.

---

## Code review

### What it is for

Correctness. Missed edge cases. Security. Whether the change fits the system.
Knowledge transfer.

**Not** style — that is the formatter's job, automated, with no human
discussion. If a review comment could have been a lint rule, configure the lint
rule and stop discussing it.

### Reviewer conduct

**Review within one working day.** A blocked PR blocks a person and ages a
branch. If you cannot, say so immediately so someone else takes it.

**Label every comment by weight:**

```
blocking:    This must change before merge. (State why.)
suggestion:  I would do this differently. Your call.
nit:         Trivial. Take it or leave it.
question:    I do not understand this yet.
praise:      This is good, and I want you to know.
```

Without labels, every comment reads as a demand, and reviews become adversarial.

**Ask rather than assert.** "What happens if `items` is empty here?" beats "this
will crash" — it is more often correct, and it invites the author to think
rather than defend.

**Say what is good.** A review that is only criticism trains people to dread
review. `praise:` costs nothing and changes the culture.

**Approve with comments** when the remaining points are minor. Blocking over a
preference is a tax on the whole team's velocity.

**Review the diff in context.** Open the file. A change that looks fine in
isolation may duplicate something twenty lines above.

### What to actually look for

```
Correctness   Does it do what the description says? Edge cases: empty, null,
              huge, concurrent, malformed, unicode?
Failure       What happens when the external call fails? Is the error handled,
              logged, and surfaced usefully?
Security      Is this authorised for THIS object? Is input validated? Any new
              secret? Is anything personal being logged?
Data          Is the migration reversible? Will it lock a hot table? Are the
              new columns indexed and constrained?
Fit           Does this match how the codebase does things, or introduce a
              second way?
Tests         Is there a test that fails without this change?
Reversibility Can this be rolled back? Is it behind a flag?
```

### Author conduct

- Respond to every comment, even if only "good catch, fixed".
- **Disagree with reasons, not by ignoring.** Silence reads as dismissal.
- **Two rounds, then talk.** A thread with fifteen replies is a conversation that
  should have been a five-minute call.
- Do not take it personally, and do not make it personal. Review the code.

### When you disagree

1. State your reasoning once, clearly.
2. If the reviewer still disagrees, ask what evidence would change their mind —
   and offer yours.
3. If it is genuinely a judgement call with no clear winner, **the author
   decides** and the reviewer approves. Consistency of process matters more than
   winning a preference.
4. If it is a real architectural disagreement, escalate to a third person or
   write an ADR. Do not let it stall the PR.

---

## Merging

**Squash merge** is the sensible default: one commit per PR on `main`, clean
history, easy revert. It requires a good PR title, since that becomes the commit
message.

**Merge commit** preserves the branch's individual commits — useful when they
were curated deliberately.

**Rebase merge** produces a linear history without a merge commit. Fine, but it
rewrites the SHAs, which confuses anyone who had the branch checked out.

Pick one per repository and configure the platform to allow only that. Mixed
merge strategies produce a history nobody can read.

**Delete the branch on merge.** Automatically.

---

## Reverting

**Revert first, diagnose second.** If a change is causing a production problem,
revert it and investigate afterwards. The cause will still be there in an hour;
the incident will not.

```bash
git revert <sha>            # a new commit undoing the change — safe, auditable
git revert -m 1 <merge-sha> # reverting a merge commit
```

Never `git push --force` to a shared branch to "undo" something. Revert leaves a
record; force-push destroys one and breaks everyone else's clone.

---

## Repository hygiene

- **`.gitignore`** covering environment files, build output, dependency
  directories, editor state, OS files, coverage, logs, local databases.
- **Never commit**: secrets, `node_modules`/`vendor`, build artefacts, large
  binaries (use LFS), or personal editor configuration.
- **`.gitattributes`** for line endings (`* text=auto`) — this prevents the
  entire-file-changed diffs on mixed Windows/Unix teams.
- **Tag releases** with annotated tags, and generate the changelog from commits
  if you use Conventional Commits.
- **Keep the repository small.** A large binary committed once is in the history
  forever, in every clone, permanently.
