# Supply Chain Security

Your application is mostly other people's code, executed with your privileges,
on your developers' machines and your CI runners. The dependency tree is a
larger attack surface than the code you wrote.

---

## Reproducibility first

Without a lockfile, "the build that passed" and "the build that shipped" are
different artefacts.

- [ ] Lockfile committed for every manifest.
- [ ] CI installs **from the lockfile, frozen**: `npm ci`, `pnpm install
      --frozen-lockfile`, `yarn --immutable`, `poetry install --sync`,
      `bundle install --deployment`, `composer install --no-dev`. A CI job
      running plain `install` can silently resolve different versions than the
      developer tested.
- [ ] Lockfile changes are reviewed. A PR that touches only the lockfile
      deserves attention, not a rubber stamp.
- [ ] Runtime version pinned in a file the toolchain reads *and* in the manifest.
- [ ] Container base images pinned by digest, not by a moving tag. `node:20` is
      a different image today than last week.

---

## Knowing what you depend on

```bash
# Real counts, including transitive
npm ls --all --parseable 2>/dev/null | wc -l
pip list --format=freeze | wc -l
go list -m all | wc -l

# Vulnerability scan — READ THE OUTPUT, never assert a CVE from memory
npm audit --production
pip-audit
govulncheck ./...
bundle audit check --update
composer audit
cargo audit
```

**Never report a specific CVE, severity or affected version range from memory.**
Advisory data changes constantly. Run the tool, read what it says, and quote it.
If the tool is not available in the environment, report that the check did not
run — not that the project is clean.

**Triage by reachability.** A critical advisory in a dev-only tool that never
runs in production is not a production emergency. A moderate one in your request
path might be. Ask: is the vulnerable code path actually reachable with
attacker-influenced input?

---

## Install scripts — the underestimated risk

`postinstall` hooks execute arbitrary code on every developer machine and every
CI runner, with that environment's credentials. This is the mechanism most
package-registry compromises use.

```bash
# What runs on install in this tree?
find node_modules -name package.json -maxdepth 3 \
  -exec grep -l '"\(pre\|post\)install"' {} \; 2>/dev/null | head -20
```

Mitigations, in increasing order of strictness:
- Review scripts on new dependency additions.
- `npm ci --ignore-scripts` in CI where the build does not need them.
- Set `ignore-scripts=true` in `.npmrc` and allowlist the few that genuinely
  require it.
- Isolate CI credentials so an install-time compromise cannot reach production
  secrets.

---

## Evaluating a new dependency

Six checks, two minutes:

1. **Alive?** Last release, commit frequency, open issue trend. No release in 18
   months on a security-relevant package is a future migration.
2. **Maintained by how many?** A single maintainer is a single account takeover.
3. **How heavy?** Transitive count and bundle impact. Forty packages for one
   function is not a bargain.
4. **Licence?** Compatible with how you distribute. AGPL in a commercial SaaS is
   a decision, not an accident. Enforce a licence policy in CI.
5. **Typosquat?** Verify the exact name and the repository link. Confusable
   names and dependency-confusion attacks (a public package shadowing your
   internal one) both rely on nobody looking.
6. **Could you write it?** Under ~100 lines and stable — writing it removes a
   supply-chain surface permanently.

**Prefer:** fewer, larger, well-maintained dependencies over many small ones;
platform standard library over a package; a package with no dependencies of its
own over one with fifty.

---

## Registry and account hygiene

- MFA enforced on every account that can publish or merge.
- Publishing tokens scoped, short-lived, and stored in CI secrets — never in a
  developer's shell profile.
- Internal packages published to a private registry, with the public registry
  configured so a public package cannot shadow an internal name (scoped
  packages, or explicit registry pinning per scope).
- Deprecated and abandoned dependencies tracked as debt with an owner.

---

## CI/CD pipeline integrity

The pipeline has production credentials. Treat it as production.

- [ ] **Actions/steps pinned to a commit SHA**, not a tag. Tags are mutable; a
      compromised action that moves `v3` runs in your pipeline on the next build.
- [ ] Workflows triggered by pull requests from forks **must not** have access
      to secrets. Check the trigger type carefully — the "run on PR with
      secrets" pattern is a known escalation path.
- [ ] Secrets scoped per environment; production credentials unavailable to
      staging workflows.
- [ ] Least-privilege tokens (read-only by default, write only where needed).
- [ ] Branch protection: no direct pushes to the default branch, review
      required, status checks required, force-push disabled.
- [ ] Signed commits or tags for releases, where the threat model warrants it.
- [ ] Build artefacts immutable and traceable to a commit SHA.
- [ ] Self-hosted runners isolated per job — a shared runner leaks state between
      builds.
- [ ] Deployment credentials use short-lived federated identity (OIDC) rather
      than long-lived static keys.

---

## Client-side third parties

Every script you include on a page runs with full access to that page: the DOM,
the cookies your JavaScript can read, and every form field. An analytics tag is
a same-origin actor.

- [ ] Inventory every third-party script, tag, pixel, font and widget. Cross-check
      against the privacy policy — this list *is* the subprocessor list.
- [ ] Self-host where you can. A self-hosted font removes a third party from
      every page load, and removes a data flow from your privacy obligations.
- [ ] Subresource Integrity (`integrity` + `crossorigin`) on any CDN-loaded
      script that supports it.
- [ ] Tag managers are a code-execution channel granted to whoever has access to
      the tag manager account. Restrict and audit it.
- [ ] `Permissions-Policy` to deny device APIs to embedded content.
- [ ] Non-essential scripts gated behind consent — a compliance requirement and
      a security reduction at the same time.

---

## SBOM and provenance

For anything distributed to others, or where a customer will ask:

- Generate an SBOM (CycloneDX or SPDX) as a build artefact.
- Attach build provenance attestation where the platform supports it.
- Keep SBOMs per release so you can answer "were we affected by X?" in minutes
  rather than days. That question arrives eventually, and the answer's speed is
  the whole value.

---

## When a compromise is suspected

1. **Assume the credentials on the affected machine are gone.** Rotate them —
   registry tokens, cloud keys, deploy keys, database passwords.
2. **Pin to the last known-good version** immediately; do not wait for a patched
   release.
3. **Check what the malicious version did.** Registry advisories and the
   package's issue tracker usually document behaviour within hours.
4. **Search your logs** for the indicators once they are published — outbound
   connections, unusual process execution on runners.
5. **Rebuild from a clean state.** Clear caches: CI dependency caches, Docker
   layer caches, developer `node_modules`.
6. **Notify** if customer data or customer builds were in scope.

---

## Review checklist

- [ ] Lockfile committed; CI installs frozen
- [ ] Automated vulnerability alerts enabled and triaged
- [ ] Audit tool run and its real output read
- [ ] Install scripts reviewed or disabled
- [ ] No end-of-life runtime or framework in production
- [ ] CI actions pinned to SHAs; fork PRs cannot reach secrets
- [ ] Publish and deploy credentials scoped, short-lived, MFA-protected
- [ ] Third-party client scripts inventoried, SRI where applicable, consent-gated
- [ ] Licence policy enforced
- [ ] SBOM produced for distributed artefacts
