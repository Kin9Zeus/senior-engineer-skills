# Working on this repository

Conventions for anyone — human or AI — editing this repository. If you are an AI
assistant, read this before changing anything here.

## What this is

A skill suite for AI coding agents. Twenty skills, fourteen slash commands, eight
subagents, and read-only helper scripts. **There is no application here** — no
build, no runtime, no dependencies. The deliverable is prose that changes how an
assistant behaves.

That makes the editorial standard the entire quality bar.

## Structure

```
.claude-plugin/          marketplace.json + plugin.json — the install manifests
skills/<name>/
  SKILL.md               frontmatter + focused body (loaded when triggered)
  references/*.md        depth, loaded only when that skill asks for it
  templates/*.md         things a user copies and fills in
  scripts/*.{sh,ps1}     read-only helpers, both platforms
commands/snr-*.md        slash commands
agents/snr-*.md          subagent definitions
assets/                  banner.svg, mark.svg, devleck-logo.png
install.sh / install.ps1 installers with auto-detection and --dry-run
```

## The rules

**1 · Every claim must be checkable.** If a reader cannot tell whether they have
complied, the instruction is not finished. "Add proper validation" fails;
"validate the body with a schema at the route boundary, rejecting unknown fields
— verify by posting an extra field and expecting 422" passes.

**2 · Every finding needs a verification step.** The format throughout is *what
is wrong → why it matters concretely → the fix → how to verify the fix*. Keep it.

**3 · Never fabricate.** No invented version numbers, CVE ids, API signatures,
benchmarks or statistics. Where a fact changes over time — framework behaviour,
an advisory, a store policy — write "check the current documentation", never an
assertion. This is the rule most often broken and the one that does the most
damage.

**4 · Prefer boring and reversible.** The suite deliberately refuses to
recommend microservices, Kubernetes, event sourcing or CQRS without the specific
problem each solves. Do not add premature complexity back in because it sounds
senior.

**5 · Defensive security only.** No weaponised exploits. No instructions to scan
or send traffic to infrastructure without confirmed authorisation. "Ethical
hacking" content (`pentest-methodology`) stays inside this rule: it is gated on
written authorisation and a scope file, proves findings with the least harmful
evidence, and contains no malware, denial-of-service, persistence or
post-exploitation guidance.

**Dated incident facts.** Case files (the Railway disclosure, the PHP
"php2shell" CVEs) carry a "last verified" date and link primary sources. When you
update one, re-read the source, change the date, and never add a fact you could
not find there.

**6 · Privacy content is not legal advice**, and says so where it appears.

**7 · Bilingual parity.** `README.md` and `README.es.md` stay in sync. The
Spanish is a proper translation at the same quality, not a summary.

## Skill authoring

**The `description` in the frontmatter is the entire activation mechanism.** It
is the only part loaded up front. Write it for matching: include the literal
phrases a user types ("my site is slow", "not showing up in Google", "delete my
data"), not only the formal domain terms.

**Keep `SKILL.md` to roughly 150–300 lines.** It loads in full when triggered.
Depth belongs in `references/`, which loads only when that skill decides it needs
it. This is why twenty skills cost almost no context.

**Lead with the order of work**, not a taxonomy. What first, and why that first?

**State the failure modes.** "This is what people get wrong here" is frequently
the most valuable paragraph in a skill.

## Scripts

- Read-only. No network beyond explicitly-scoped HTTP checks against a URL the
  user supplied.
- Both `.sh` (POSIX, clean under `bash -n`) and `.ps1` (PowerShell 5.1+, clean
  under the language parser).
- No dependencies beyond `curl`, `grep`, `git` and the shell.
- **Everything they report is a lead, not a finding**, and the output says so.
- Exit `0` clean, `1` findings, `2` usage error.

## Validation before committing

```bash
bash -n skills/*/scripts/*.sh install.sh
python -c "import json;[json.load(open(p)) for p in ['.claude-plugin/marketplace.json','.claude-plugin/plugin.json']]"
python -c "import xml.dom.minidom as m; m.parse('assets/banner.svg'); m.parse('assets/mark.svg')"
```

PowerShell files:
```powershell
[System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$null)
```

Then **test the skill in a real session**: `./install.sh --project`, give the
assistant a task that should trigger it, and confirm both that it activates and
that the output is better than without it.

## Do not

- Add a skill without checking whether an existing one should be extended instead
- Let `SKILL.md` grow into an encyclopedia — that is what `references/` is for
- Write a description that only lists formal terms; it will not activate
- Add a dependency to a script
- Assert a CVE, version or benchmark from memory
- Change `README.md` without changing `README.es.md`
