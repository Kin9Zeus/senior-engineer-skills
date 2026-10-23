# Secrets architecture

How to move up the ladder from "environment variable" to "nothing static worth
stealing". Product names are examples, not endorsements; check each product's
current documentation.

---

## 1 · Inventory first

You cannot protect what you cannot list. Build the table:

| Secret | Issuer | Used by | Scope/permissions | Lives in | Rotation | Network limit | Spend cap |
|---|---|---|---|---|---|---|---|

Seed it with `security-incident-response/scripts/rotation-inventory.sh` plus the
provider dashboards, CI variable stores and developer machines. Every empty cell
is a task.

## 2 · Rung 5 — no static secret (federated, short-lived)

### CI → cloud with OIDC (example: GitHub Actions → AWS)

The workflow requests a short-lived token from GitHub; the cloud trusts it only
for a specific repository and branch. No stored key exists to leak.

```yaml
permissions:
  id-token: write      # request an OIDC token
  contents: read
steps:
  - uses: aws-actions/configure-aws-credentials@<commit-sha>
    with:
      role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/gha-deploy-prod
      aws-region: <region>
```

Role trust policy (condition keys narrow *which* repo/branch may assume it):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike":   { "token.actions.githubusercontent.com:sub": "repo:<org>/<repo>:ref:refs/heads/main" }
    }
  }]
}
```

A `sub` condition that is too loose (`repo:<org>/*`) lets any repository in the
organisation assume the role — the most common mistake. **Verify** by attempting
the assume-role from a different branch in a test and expecting denial.

Equivalents: Google Cloud Workload Identity Federation, Azure federated
credentials. For compute: instance profiles / IAM roles for service accounts /
managed identities instead of access keys.

## 3 · Rung 4 — secrets manager with identity-based fetch

```
app (has an IDENTITY, not a secret)
   └── authenticates to the secrets manager as that identity
         └── policy: this workload may read ONLY secrets/<app>/<env>/*
               └── returns the secret; access logged; version history; rotation
```

Properties to demand:

- Access by **workload identity**, not by a shared token pasted into an env var
  (otherwise you moved the problem one hop)
- Per-secret, per-environment policies; production unreadable from staging
- Audit log of every read, alerting on unusual readers
- Versioning and automatic or scripted rotation
- Local development uses its own, separate, low-privilege values

Examples of the category: cloud-native secret managers (AWS Secrets Manager /
SSM Parameter Store, Google Secret Manager, Azure Key Vault), HashiCorp Vault /
OpenBao, and hosted tools (Doppler, Infisical and similar). Choose by where your
workloads run and who operates it.

**Cache carefully:** fetch at startup or with a short TTL; never write the value to
disk or logs; handle fetch failure (fail closed).

## 4 · Rung 2–3 — when you must use platform variables

Sometimes the platform's variables are all you have. Make them as cheap to lose
as possible:

1. Store only secrets that are **narrow, network-restricted and spend-capped**.
2. Never store cloud root, owner or admin keys, or broad database superusers.
3. Use **different values per environment**, and different from local development.
4. Use the platform's **write-only / sealed** option where offered — knowing it is
   a UI/API protection, not necessarily protection against a storage-layer breach.
5. Keep an up-to-date inventory so rotation takes an hour, not a week.
6. Disable or lock down variable access for team members who don't need it.

## 5 · Limiting what a stolen credential can do

### Databases
- Application role with only the privileges it needs (no `SUPERUSER`, no DDL at
  runtime — migrations run under a separate role during deploy).
- **Network allowlist** or private networking; require TLS.
- One role per service so one leak does not cross services.
- Row-level security for multi-tenant data (`database-engineering`).

### Third-party APIs
- Use **scoped/restricted keys** (read-only, specific resources) where offered.
- **IP allowlisting** of your egress addresses where offered.
- **Hard spend caps and usage alerts** — AI inference, SMS, email, maps and cloud
  compute are monetised by attackers within hours of a leak.
- One key per environment and per service; label keys with owner and purpose.

### Cloud
- Roles scoped to resources and actions, with conditions (source VPC, tags, time).
- Permission boundaries / SCPs / organisation policies as a ceiling so a
  compromised admin cannot do everything.
- Deny actions that disable logging or delete audit trails.

## 6 · Egress and exfiltration control

An attacker with code execution must send data out. Make that hard and loud:

- **Default-deny egress** for production workloads where feasible; allowlist only
  the APIs the app needs (database, payment provider, email, AI provider).
- DNS-level or proxy-level logging of outbound destinations.
- Alert on first-time destinations from production workloads.

## 7 · Canaries — know on first use

Plant decoys that no legitimate code path touches:

- A **canary cloud key** (a real credential with zero permissions, or a
  purpose-built canary token) placed where an attacker would look, with an alert
  on any use.
- A fake `.env.bak` or `backup.sql` in a monitored location.
- A honey table/record in the database, alerting on read.

False-positive rate is near zero, which is what makes them valuable.

## 8 · Secret scanning and prevention

- Pre-commit and CI secret scanning on every push, including history on adoption
  (`secret-scan.sh`, gitleaks, trufflehog, or the Git host's native scanning with
  push protection).
- Block secrets at the Git host with push protection where available.
- Scan built artifacts: client bundles, source maps, container layers.
- `.gitignore` covers `.env*`, key files, state files; `.env.example` has no real values.
- Share secrets between people through the secrets manager or password manager, never
  chat or tickets.

## 9 · Detection

Alert on the handful of events that matter most:

- Secret read by an unfamiliar identity or from a new network
- New access key / token / deploy key / OAuth grant created
- A credential used from a country or ASN you have never seen
- Disabled logging, deleted trail, changed retention
- Spend anomaly on any metered provider
- Production workload connecting to an unfamiliar destination

## 10 · Verification checklist

- [ ] The inventory table exists and has no empty "Scope" or "Network limit" cells
      for production secrets
- [ ] No long-lived cloud keys in CI; assume-role from a wrong branch is denied
- [ ] Database unreachable from a non-allowlisted network (test it)
- [ ] Every metered provider has a hard cap and an alert
- [ ] A canary exists and its alert was tested
- [ ] A timed rotation drill was done this half-year; result recorded
