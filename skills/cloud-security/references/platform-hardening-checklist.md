# Platform hardening checklist

Each line is checkable: a command, a console setting or a test. Items marked ▲ are
the highest-yield — do them first. Verify against the provider's current
documentation; setting names move.

---

## A · PaaS / managed platforms (Railway, Vercel, Render, Fly.io, Heroku …)

```
[ ]▲ Production secrets are not present in preview / PR / staging environments
[ ]▲ Databases use private networking; any public proxy has an IP allowlist
[ ]▲ MFA enforced for every member of the team/account; SSO if offered
[ ]▲ Project/team tokens inventoried, least-scope, expiring, owned by a person
[ ]  Roles: members have the minimum role; billing/admin limited to 2 people
[ ]  Git integration limited to the repositories that deploy
[ ]  Build-time secrets are not baked into images or client bundles
[ ]  No `PUBLIC_`/`NEXT_PUBLIC_`/`VITE_` variable holds a secret
[ ]  Logs and error pages never print environment, tokens or full bodies
[ ]  Alternative deploy path exists if the provider freezes deploys
[ ]  Backups copied outside the provider account; restore rehearsed
[ ]  Custom domain: HSTS on; no dangling DNS records to deleted services
[ ]  Provider security notices subscribed (status page, security mailing list)
```

## B · AWS baseline

```
[ ]▲ Root account: MFA, no access keys, used only for break-glass
[ ]▲ IAM: no wildcard (*:*) policies; roles over users; access-key age < 90 days or none
[ ]▲ Account-wide S3 Block Public Access on; no public snapshots/AMIs
[ ]▲ CloudTrail enabled in all regions, log-file validation, delivered to a separate locked account
[ ]▲ Instance metadata: IMDSv2 required
[ ]  Security groups: no 0.0.0.0/0 on SSH/RDP/database/cache/queue ports
[ ]  Databases: private subnets, encryption at rest, TLS required, backups + PITR
[ ]  GuardDuty (or equivalent) on; findings routed to a human
[ ]  SCPs / permission boundaries forbid disabling logging
[ ]  Budgets and anomaly alerts configured
[ ]  Secrets in Secrets Manager/SSM, not in user-data, task definitions or env
[ ]  Lambda/ECS roles are per-function/per-task, least privilege
```
Read-only audit helpers (examples): `aws iam get-account-summary`, `aws iam
list-access-keys`, `aws s3api get-public-access-block`, a CSPM tool such as
Prowler run with a read-only role.

## C · Google Cloud baseline

```
[ ]▲ Organisation policy: disable service-account key creation; use Workload Identity Federation
[ ]▲ No `roles/owner` / `roles/editor` on service accounts or humans for routine work
[ ]▲ Cloud Audit Logs (Admin Activity + Data Access for sensitive services) on and exported
[ ]▲ Cloud Storage: uniform bucket-level access, public access prevention
[ ]  VPC firewall rules: no 0.0.0.0/0 on management/data ports; Private Google Access
[ ]  Cloud SQL private IP, TLS required, backups
[ ]  Secret Manager with per-secret IAM; no secrets in metadata/env
[ ]  Budgets and alerts
```

## D · Azure baseline

```
[ ]▲ Entra ID: MFA/Conditional Access for all admins; no standing Global Admin
[ ]▲ Managed identities instead of client secrets; Key Vault with RBAC and logging
[ ]▲ Storage accounts: public blob access disabled; secure transfer required
[ ]▲ Activity logs and diagnostic settings to a Log Analytics workspace
[ ]  NSGs: no Any→22/3389/DB ports from the internet; Defender for Cloud recommendations triaged
[ ]  Azure SQL private endpoint, TLS, auditing
```

## E · Containers (Docker / OCI)

```
[ ]▲ Non-root USER; no `--privileged`; no Docker socket mounted into containers
[ ]▲ Base image minimal and pinned by digest; rebuilt on advisories and on schedule
[ ]▲ No secrets in layers, build args or ENV in the image (check: docker history, image scan)
[ ]  Read-only root filesystem + tmpfs for scratch; capabilities dropped; no-new-privileges
[ ]  CPU/memory limits set (bounds runaway and some exploit impact)
[ ]  HEALTHCHECK defined; one process per container
[ ]  Image scanned in CI (trivy/grype); critical fixable vulns block release
[ ]  Registry: private, access-scoped tokens, content trust/signing where available
[ ]  .dockerignore excludes .git, .env, keys, node_modules
```
Quick checks: `docker history --no-trunc <image> | grep -iE 'secret|token|password|key'`;
`trivy image --scanners vuln,secret <image>`.

## F · Kubernetes

```
[ ]▲ API server and kubelet not reachable from the internet; dashboard disabled or authenticated
[ ]▲ RBAC least privilege; no workloads bound to cluster-admin; audit RoleBindings
[ ]▲ NetworkPolicies default-deny per namespace, explicit allows
[ ]▲ Pod Security Standards "restricted" (or equivalent admission policy) enforced
[ ]  Secrets encrypted at rest; external secrets operator / CSI driver preferred
[ ]  automountServiceAccountToken: false unless needed
[ ]  Images from allowed registries only, by digest; admission control verifies
[ ]  Resource requests/limits; PodDisruptionBudgets; no hostPath/hostNetwork/hostPID
[ ]  Audit logging on; node OS patched; control-plane managed or hardened
```
Read-only checks: `kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa>`,
`kubectl get clusterrolebindings -o wide`, a policy scanner such as kube-linter or
Kubescape against manifests.

## G · Infrastructure as code

```
[ ]▲ Scanned in CI on every PR (trivy config / checkov / tfsec / cfn-nag); high findings block
[ ]▲ No credentials in .tf/.yaml/.tfvars; variables marked sensitive; state in a private
      encrypted backend with access control and locking — state files contain secrets
[ ]  Modules and providers version-pinned; lock file committed
[ ]  `terraform plan` reviewed in PR; apply from CI with an OIDC role, not a laptop
[ ]  Drift detection scheduled; manual console changes are alerts
[ ]  Policy-as-code (OPA/Conftest/Sentinel) for the rules you never want broken
       (no public storage, no 0.0.0.0/0 on admin ports, encryption required)
```

## H · Detection and response readiness

```
[ ]▲ Audit logs on, tamper-resistant, retained long enough to cover a quiet breach (≥ 90 days; longer where required)
[ ]▲ Alerts on: new keys/tokens, disabled logging, console login without MFA, root use, unusual egress, spend spikes
[ ]  An on-call path exists for security alerts (not just for uptime)
[ ]  Canary credential deployed and tested
[ ]  Incident runbook and rotation drill current (security-incident-response)
[ ]  Contact list for each provider's security team
```

## I · How to run this as a review

1. Collect read-only access (a viewer role) — never ask for write access to audit.
2. Walk A–H for what exists. Mark ▲ items first.
3. Each failure becomes a finding: what is wrong → blast radius → fix → verify.
4. Group fixes into: this week (▲ items and exposed data stores), this month,
   this quarter.
5. Re-run after changes and record the delta.
