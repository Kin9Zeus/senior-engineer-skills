## What

<!-- One or two sentences. -->

## Why

<!-- The problem this solves. Link the issue if there is one. -->

## How you tested it

<!--
  Not "it looks right". Install it and use it:

    ./install.sh --project
    <give the assistant a task that should trigger the skill>

  Then tell us: did it activate? Was the output better than without it?
  A PR body like "ran /snr-audit against a Next.js repo with a known IDOR;
  it was found and correctly rated P0" is exactly right.
-->

---

## Editorial standard

<!-- See CONTRIBUTING.md. These are the rules that keep the suite trustworthy. -->

- [ ] Every claim is **checkable** — a reader can tell whether they complied
- [ ] Every finding has a **verification step**
- [ ] **Nothing fabricated** — no invented version numbers, CVE ids, API
      signatures, benchmarks or statistics. Facts that change over time are
      written as "check the current documentation"
- [ ] Security content is **defensive only** — no weaponised exploits, no
      unauthorised scanning
- [ ] Privacy content states that it is **not legal advice**
- [ ] No premature complexity recommended (microservices, Kubernetes, event
      sourcing, CQRS) without naming the specific problem it solves

## Mechanics

- [ ] `node .github/scripts/validate.mjs` passes
- [ ] Shell scripts pass `bash -n` and are executable
- [ ] PowerShell scripts parse
- [ ] A new `.sh` script has a `.ps1` counterpart
- [ ] `SKILL.md` stayed focused; depth went into `references/`
- [ ] The `description` includes the **literal phrases a user would type**, not
      only formal domain terms
- [ ] `README.md` **and** `README.es.md` updated together, if user-facing docs changed
- [ ] `CHANGELOG.md` updated
- [ ] `install.sh` and `install.ps1` skill lists updated, if a skill was added or renamed
