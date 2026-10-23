---
name: cloud-security
description: Cloud, PaaS, container and infrastructure security built on one assumption — your hosting platform, CI or secrets store can be breached, so a stolen environment variable must buy an attacker as little as possible. Covers secrets architecture, least-privilege identity, short-lived and federated credentials (OIDC), blast-radius limits, network and egress control, container and Kubernetes hardening, infrastructure-as-code scanning, cloud logging and detection, and rotation drills. Use when the user says "cloud security", "is Railway safe", "is Vercel safe", "where should I store secrets", "environment variables safe", "secrets manager", "IAM", "least privilege", "OIDC", "AWS security", "GCP security", "Azure security", "Kubernetes security", "Docker security", "Terraform security", "public bucket", "blast radius", "zero trust", "harden my deployment", "platform breach lessons" or "limit damage if my host is hacked"; when reviewing any infrastructure, Dockerfile, pipeline or IaC; and as a pass in any project audit. Defensive security only. By Devleck.
license: MIT
---

# Cloud Security

Every platform you depend on is somebody else's code and somebody else's
employees. Hosts get breached, CI tokens leak, and a vendor's "limited subset"
turns out to include you. You cannot prevent that. You **can** decide, in
advance, how much a stolen secret is worth.

> **The design goal:** an attacker who obtains everything your platform stores —
> every environment variable, every token — should find credentials that are
> narrow, short-lived, network-restricted, spend-capped, and detected on first use.

**Scope:** infrastructure the user owns or is authorised to assess. Review is
read-only by default; changes to live infrastructure need the user's confirmation.
No probing of provider infrastructure or other tenants.

---

## 1 · The order of work

```
 1  INVENTORY    every secret, every identity, every internet-facing thing
 2  SECRETS      climb the ladder (below): fewer, narrower, shorter-lived
 3  IDENTITY     least privilege; no shared keys; MFA; federated CI
 4  NETWORK      private by default; data stores unreachable from the internet; egress control
 5  RUNTIME      patched, minimal, non-root, read-only, resource-limited
 6  DATA         encrypted, backed up, restore-tested, retention-bounded
 7  DETECTION    audit logs on and watched; canaries; alert on the dangerous few
 8  REPEATABLE   infrastructure as code, scanned; rotation drill rehearsed
```

Do steps 1–3 first. They are where a platform breach turns from an incident into a
catastrophe or into an afternoon.

---

## 2 · The secrets ladder

Where a secret lives decides what a breach of that place costs. Climb as high as
the platform allows.

| Rung | Where | What a breach gives the attacker |
|---|---|---|
| 0 | Hard-coded in source | Everything, forever, in every clone |
| 1 | `.env` committed or shared in chat | Same, plus your history |
| 2 | Plain platform environment variables | Everything the platform stored — **this is what a platform-store breach exposes** |
| 3 | Write-only / "sealed" platform variables | Better against UI/API read-back; **a breach of the storage layer itself may still expose them** — ask the provider, do not assume |
| 4 | Dedicated secrets manager, fetched at runtime with the workload's identity | Attacker needs the identity *and* a network path; access is logged and revocable centrally |
| 5 | **No static secret**: federated, short-lived credentials (OIDC / workload identity) | A stolen token expires in minutes; nothing to rotate |

Practical target: rung 5 for cloud access from CI and compute; rung 4 for
databases and third-party API keys; rung 2–3 only for low-value config, never for
the keys that move money or reach customer data. `references/secrets-architecture.md`.

---

## 3 · Make a stolen secret worth little

For every credential, ask the same six questions:

| Question | Control that limits the damage |
|---|---|
| **What can it do?** | Least privilege; read-only variants; per-service keys; no root/owner keys in apps |
| **Where can it be used from?** | IP/VPC allowlists, private networking, mTLS — a database password is useless from the attacker's laptop |
| **How long does it live?** | Short-lived tokens; automatic rotation; expiry dates |
| **How much can it spend?** | Hard budget caps and quotas on AI, SMS, email, maps, cloud |
| **Does the environment share it?** | Separate credentials for dev, staging, preview, production |
| **Would we notice?** | Alert on first use from a new place; canary credentials |

If the honest answer to "what happens if this leaks?" is "everything", that
credential is a finding even if nothing has leaked yet.

---

## 4 · Platform and PaaS specifics

Applies to Railway, Vercel, Render, Fly.io, Heroku and similar. Check each
provider's current documentation for the features named.

- **Variables per environment.** Production secrets must not appear in preview or
  PR environments. Preview environments are the usual forgotten copy.
- **Build-time vs runtime secrets.** Anything present at build time can end up in
  image layers, logs, or client bundles (`NEXT_PUBLIC_`, `VITE_`, `PUBLIC_`
  prefixes are compiled into the browser).
- **Private networking.** Databases and internal services get private
  addresses; a public database proxy is a deliberate, documented exception with an
  IP allowlist.
- **Team and project tokens.** Per-purpose, least-scope, expiring where possible;
  inventory them; offboarding revokes them.
- **Git integration.** Grant the minimum repository access; review it after any
  provider incident.
- **Deploy freeze plan.** If the provider pauses deploys (as happens in
  incidents) can you still ship a security patch another way? Know before you
  need to.
- **Logs.** Never print environment variables, tokens or full request bodies; the
  platform's log store is another place secrets leak.
- **Region, backups, restore.** Backups exist outside the provider account or
  region where the threat model demands; restore is rehearsed.

## 5 · CI/CD is part of your attack surface

- **No long-lived cloud keys in CI.** Use OIDC federation (GitHub Actions, GitLab,
  etc.) to assume a role for the duration of the job.
- Scope the role to the repo and branch/environment that needs it.
- Separate *build* identity from *deploy* identity from *developer* identity.
- Protect the production environment with required reviewers.
- Pin actions and images by digest; treat any workflow that runs on forked PRs as
  hostile; never expose secrets to it.
- After any CI-provider or registry incident, rotate CI secrets and review recent
  workflow and image changes.

## 6 · Identity hygiene

- MFA on every human account, phishing-resistant for admins.
- No shared accounts. No access keys on the root/owner account.
- Review unused users, roles and keys on a schedule; delete rather than disable
  after a grace period.
- Break-glass admin access exists, is sealed, alerts when used.
- Wildcard (`*`) actions or resources are a finding until justified.

## 7 · Containers, Kubernetes and IaC — the short list

Full checklists in `references/platform-hardening-checklist.md`.

- Minimal pinned base images, non-root user, read-only root filesystem, dropped
  capabilities, resource limits, no secrets in layers.
- Kubernetes: RBAC least privilege, default-deny network policies, Pod Security
  Standards enforced, secrets from an external manager, API server not public.
- Terraform/CloudFormation/Bicep scanned in CI (`trivy config`, `checkov`, `tfsec`
  or equivalent); state files treated as secrets; no inline credentials.

## 8 · What people get wrong

- **"It's in the platform's encrypted store, so it's safe."** Encrypted at rest
  does not help when the party that can decrypt is the party that was breached.
- **One god-key** used by every service and every environment.
- **Rotating the platform value only**, leaving the old credential live at the
  issuer (see `security-incident-response`).
- **Public database for convenience.** A database reachable from the internet will
  be found.
- **Trusting preview and staging.** They hold production-grade secrets with
  weaker access control.
- **No spend cap.** Leaked AI and cloud keys are monetised within hours.
- **Logging disabled or in the attacker's reach.** No audit trail means no scope
  of breach, which means you rotate and notify everything.
- **IaC that nobody scans**, so the public bucket ships through code review.
- **Never rehearsing rotation.** The first drill should not be the incident.

## 9 · The rotation drill

Twice a year, or after any provider incident: in a staging copy, rotate every
credential end to end using `security-incident-response/references/secret-rotation-playbook.md`,
timing it. Targets: critical credentials rotated in **under one hour**, with no
downtime, and every old value proven dead. The inventory script and tracker are in
that skill. A rotation that takes days is a finding.

## 10 · Report format

```markdown
### Production database password stored as plain platform variable, reachable from any IP — P1
**Class**       Excessive blast radius (secrets rung 2, no network restriction)
**Location**    Platform service "api", variable DATABASE_URL; DB firewall rule 0.0.0.0/0
**Confidence**  CONFIRMED (read from provider settings and DB network config)
**Impact**      A platform-store breach or leaked variable gives anyone the full database from the internet.
**Fix**         Private network address; allowlist app egress IP; new least-privilege role; rotate.
**Verify**      Connection from a non-allowlisted IP is refused; old role dropped and its login fails.
```

End with **"What I could not verify"** (provider settings you cannot see, IAM you
could not read).

---

## References

- `references/secrets-architecture.md` — the ladder in practice, OIDC federation, secrets managers, egress and canaries
- `references/platform-hardening-checklist.md` — PaaS, AWS/GCP/Azure baseline, containers, Kubernetes, IaC
- Related skills: `security-incident-response`, `devops-platform`, `security-hardening`, `pentest-methodology`, `observability-slo`
