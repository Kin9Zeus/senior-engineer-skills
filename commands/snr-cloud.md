---
description: Cloud / PaaS / container security review — secrets architecture, blast radius, identity, network, runtime, IaC and rotation readiness. Assumes the platform can be breached.
argument-hint: "[scope, e.g. 'Railway project' | 'AWS account' | 'Dockerfile and compose' | 'Terraform']"
---

# Cloud Security Review

Scope: **$ARGUMENTS** (default: everything that defines or deploys the project).

Load the `cloud-security` skill. Read-only review; ask for a viewer role, never
write access. Changes to live infrastructure need the user's confirmation.

## The premise

Assume the platform, CI or secrets store **will** be breached. The question for
every credential is: *what does an attacker get, from where, for how long, at what
cost to us, and would we notice?*

## Order of work

```
1 Inventory   secrets · identities · internet-facing assets
              (skills/security-incident-response/scripts/rotation-inventory.sh)
2 Secrets     place each on the ladder (static in source → … → no static secret)
3 Identity    least privilege · MFA · OIDC for CI · no shared or root keys
4 Network     data stores private · management ports closed · egress control
5 Runtime     non-root · read-only · minimal · limits · patched (PHP etc.)
6 Data        encrypted · backed up · restore tested
7 Detection   audit logs on and watched · canaries · spend alerts
8 Repeatable  IaC scanned · rotation drill timed
```

For each credential answer the six questions in the skill (what can it do, from
where, how long, how much can it spend, shared across environments, would we
notice). Walk `references/platform-hardening-checklist.md` sections A–H for what
exists; mark ▲ items first.

## Output

Findings in suite format with **blast radius** stated and the **compensating
control** that would limit it, ordered P0 → P3, grouped into *this week / this
month / this quarter*. Include the secrets-ladder table (secret → rung → target
rung). End with **What I could not verify** (provider settings and IAM you could
not read).
