---
name: devops-platform
description: Platform and delivery engineering — CI/CD pipelines, infrastructure as code, containers, environment parity, deployment strategies (blue/green, canary, rolling), rollback, secrets management, disaster recovery, autoscaling and cloud cost control. Use when working on pipelines, Dockerfiles, Terraform, Kubernetes, GitHub Actions, deployment or hosting; when the user says "CI", "CD", "pipeline", "deploy", "Docker", "Kubernetes", "Terraform", "infrastructure", "staging", "rollback", "downtime", "environment variables", "secrets", "autoscaling", "cloud costs" or "how do I ship this"; and as a pass in any project audit. By Devleck.
license: MIT
---

# DevOps and Platform Engineering

Two questions decide whether a platform is professional:

> **How long from commit to production?**
> **How long from "this is broken" to it not being broken?**

Everything below serves those two numbers. A pipeline that produces neither
speed nor reversibility is ceremony.

---

## Reproducibility — the precondition

If the environment cannot be rebuilt from the repository, everything else is
built on sand.

- [ ] Runtime version pinned in a file the toolchain reads, and in the manifest.
- [ ] Lockfile committed; CI installs **frozen** (`npm ci`, `--frozen-lockfile`,
      `poetry install --sync`, `bundle --deployment`).
- [ ] Container base images pinned **by digest**, not by a moving tag.
- [ ] Infrastructure in code, in the repository, applied by the pipeline.
- [ ] **No snowflake servers.** Anything configured by hand once is a single
      point of failure with no recovery procedure. The test: could you delete
      the production environment and rebuild it from the repo?
- [ ] Local development one command away — Docker Compose, devcontainer, or a
      documented single script.

---

## The pipeline

**On every pull request**, blocking merge:
```
install (frozen)  →  lint  →  typecheck  →  unit  →  integration  →  build  →  dependency audit  →  secret scan
```

**On merge to the default branch:**
```
build once, tag by commit SHA  →  deploy to staging  →  smoke tests  →  ready for production
```

Rules that matter more than the tool:

- **Build the artefact once.** Promote the *same* artefact through environments.
  Rebuilding per environment means you deployed something you never tested.
- **CI must block merge.** Establish this before there is pressure to bypass it;
  it is never established afterwards.
- **Keep it under ~10 minutes.** Beyond that, people stop waiting and start
  merging around it. Cache dependencies, parallelise, split slow suites.
- **A flaky pipeline is a broken pipeline.** A suite people re-run until green
  provides no information.
- **Pin actions to a commit SHA**, not a tag. Tags are mutable.
- **Fork PRs must not access secrets.**
- Branch protection: no direct pushes, review required, checks required.

---

## Environments

Local, staging and production should be **structurally identical, differing in
scale**. Staging with a different database engine, no data and half the services
stubbed does not tell you anything about production.

| | Local | Staging | Production |
|---|---|---|---|
| Same engines and versions | yes | yes | yes |
| Same deploy mechanism | — | yes | yes |
| Realistic data volume | no | approximate | — |
| Real personal data | **never** | **never** | yes |
| Same secret management | file | manager | manager |

**Staging must never hold production personal data or production credentials.**
If staging can read the production database, staging *is* production for breach
purposes, with weaker controls and broader access. See
`database-engineering/references/data-lifecycle.md`.

Ephemeral preview environments per pull request are the highest-value platform
investment most teams have not made: they turn "looks right in the diff" into
"I clicked it".

---

## Deployment and rollback

**Rollback is the feature.** A deploy you cannot reverse in minutes is a deploy
you are afraid to make, which is how teams end up shipping monthly.

| Strategy | Reversal | Cost | Use |
|---|---|---|---|
| Rolling | Redeploy previous | Low | Default for stateless services |
| Blue/green | Switch traffic back — seconds | Double infra briefly | When instant reversal matters |
| Canary | Shift the small percentage back | Needs traffic splitting + metrics | High-risk changes at real volume |
| Feature flag | Toggle — no deploy at all | Flag debt | Risky behaviour changes |

**Non-negotiables**
- The rollback procedure is documented **and has been executed at least once for
  practice**. An untested rollback has unknown duration.
- Migrations are ordered relative to the deploy by direction: additive changes
  migrate first, destructive changes deploy first. During a rolling deploy both
  code versions run simultaneously, so the schema must satisfy both.
- Health and readiness endpoints are distinct: liveness means "restart me",
  readiness means "do not send traffic yet".
- Graceful shutdown on `SIGTERM`, draining in-flight requests. Without it, every
  deploy drops requests.
- Deploys are logged and annotated on dashboards — the first question in any
  incident is "what changed?"

---

## Containers

```dockerfile
# Multi-stage: build tooling never reaches the runtime image
FROM node:22.11.0-slim@sha256:<digest> AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build && npm prune --omit=dev

FROM node:22.11.0-slim@sha256:<digest>
ENV NODE_ENV=production
WORKDIR /app
RUN groupadd -r app && useradd -r -g app app
COPY --from=build --chown=app:app /app/node_modules ./node_modules
COPY --from=build --chown=app:app /app/dist ./dist
USER app                                    # never root
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD node dist/healthcheck.js
CMD ["node", "dist/server.js"]
```

- Pin the base image by digest. Multi-stage so compilers and dev dependencies do
  not ship.
- **Run as non-root.** Read-only root filesystem where possible.
- **No secrets in layers, ever** — including in intermediate layers a later
  `RM` "removed". Layers are permanently inspectable. Use build secrets or
  runtime injection.
- `.dockerignore` covering `.git`, `.env`, `node_modules`, tests.
- Scan images for vulnerabilities in CI.
- Set memory and CPU limits, and make sure the runtime respects them (older
  runtimes ignore cgroup limits and get OOM-killed).

---

## Secrets

- In the platform's secret manager (cloud KMS/Secrets Manager, Vault, or the
  hosting platform's own). Never in the repository, never in the image, never in
  CI logs.
- Injected at runtime, distinct per environment.
- **Rotatable, with a documented and practised procedure.** A secret nobody knows
  how to rotate is a secret you cannot revoke after a leak.
- Access audited. Least privilege per service.
- Prefer short-lived federated credentials (OIDC from CI to cloud) over
  long-lived static keys.
- Secret scanning in CI and as a pre-commit hook.
- **Assume the platform can be breached.** Hosting and CI providers have had
  incidents that exposed stored environment variables. Keep each credential
  narrow, network-restricted and spend-capped, and keep a rehearsed rotation
  runbook — a stolen variable should buy an attacker little. See `cloud-security`
  (secrets ladder, blast radius) and `security-incident-response` (the rotation
  playbook and the dated Railway case file).
- **Have a second route to ship a patch.** If the provider freezes deploys during
  an incident, a security fix must still be deployable (or the exposed service
  restrictable at the edge). Know the answer before you need it.
- **Rebuild on advisories, not on features.** A pinned base image that is never
  rebuilt keeps its old runtime. Runtime CVEs (language, web server, OS packages)
  trigger a rebuild with `--pull --no-cache` and a check of the *running* build.

---

## Disaster recovery

Backups and restore drills live in
`database-engineering/references/resilience.md` — that is the core of DR and it
is the part most often unverified.

Beyond the database:
- [ ] Object storage versioned and backed up; deletion protection on.
- [ ] Infrastructure rebuildable from code — tested by actually creating a fresh
      environment from scratch.
- [ ] Secrets recoverable (who else can access the manager if one person is
      unavailable?).
- [ ] DNS and domain ownership documented, with registrar access not held by one
      person.
- [ ] TLS certificates auto-renewing, with expiry alerting as a backstop.
- [ ] A written incident runbook, and a named escalation path.
- [ ] Dependencies on third parties assessed: what breaks if the identity
      provider, payment processor or CDN is down?

---

## Cost

Cost is an engineering property, not a finance problem discovered at month end.

- Tag every resource by service and environment; report spend per tag.
- **Alert on anomalies**, not just on budget — a 3x jump on Tuesday matters more
  than a monthly total.
- The usual leaks, in order: unbounded log retention; over-provisioned instances
  running at 5%; forgotten non-production environments; cross-AZ and egress
  traffic; unattached volumes and old snapshots; oversized managed databases.
- Autoscaling with a **maximum** — unbounded scaling turns a traffic spike or a
  retry storm into a five-figure bill.
- Set a budget alert on day one, before anything is deployed.

---

## Review checklist

- [ ] Environment rebuildable from the repository alone
- [ ] Lockfile committed; CI installs frozen; images pinned by digest
- [ ] CI runs lint, types, tests, build, dependency audit, secret scan — blocking
- [ ] CI under ~10 minutes and not flaky
- [ ] One artefact built once and promoted
- [ ] Staging structurally matches production and holds no production data
- [ ] Deploys automated; **rollback documented and rehearsed**
- [ ] Migration ordering relative to deploys is correct for both directions
- [ ] Health and readiness distinct; graceful shutdown implemented
- [ ] Containers non-root, multi-stage, no secrets in layers, scanned
- [ ] Secrets in a manager, per-environment, rotatable, audited
- [ ] Backups tested by restore; infrastructure rebuild tested
- [ ] Cost tagged, monitored, anomaly-alerted; autoscaling capped

## References

- `references/pipeline-design.md` — CI/CD in depth, per platform
- `references/infrastructure.md` — IaC, environments, networking, scaling, cost
