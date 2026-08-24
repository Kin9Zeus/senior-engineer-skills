# Pipeline Design

A pipeline is a product with users — the engineers waiting on it. Its
requirements are: fast, trustworthy, and impossible to bypass.

---

## The stages

```
┌─ On every pull request ─────────────────────────────────────────┐
│  checkout → restore cache → install (frozen)                     │
│  ├── lint                     ┐                                  │
│  ├── typecheck                ├─ parallel                        │
│  ├── unit tests               │                                  │
│  ├── dependency audit         │                                  │
│  └── secret scan              ┘                                  │
│  → integration tests (with real services)                        │
│  → build artefact                                                │
│  → [optional] preview environment + E2E smoke                    │
└──────────────────────────────────────────────────────────────────┘
                                ↓ merge
┌─ On the default branch ──────────────────────────────────────────┐
│  build ONCE, tag by commit SHA → push to registry                │
│  → migrate staging → deploy staging → smoke tests                │
│  → [gate: automatic or manual approval]                          │
│  → migrate production → deploy production → smoke tests          │
│  → tag release, annotate dashboards, notify                      │
└──────────────────────────────────────────────────────────────────┘
```

**Build once, promote the same artefact.** Rebuilding per environment means the
thing you tested is not the thing you shipped.

---

## Speed — because a slow pipeline gets bypassed

Target under 10 minutes for the PR pipeline. Past that, people context-switch,
stop watching, and start merging around it.

| Technique | Typical gain |
|---|---|
| Cache dependencies keyed on the lockfile hash | Large |
| Run independent jobs in parallel | Large |
| Shard slow test suites across runners | Large |
| Only run affected packages in a monorepo | Large |
| Docker layer caching / BuildKit cache mounts | Medium |
| Fail fast — cheap checks before expensive ones | Medium |
| Skip on docs-only changes (carefully — never skip security checks) | Small |

Measure the pipeline itself: total duration, per-stage duration, queue time,
failure rate, and flake rate. A pipeline nobody measures gets slower every month.

---

## Trustworthiness

**A flaky pipeline is worse than no pipeline** — it teaches people that red means
"try again", and then a real failure gets re-run past.

- Track flake rate per test. Quarantine flaky tests explicitly (still run, do not
  block) and fix them on a deadline, with an owner.
- Never add a blanket automatic re-run. Retrying until green destroys the signal
  the suite exists to provide.
- No test may depend on execution order, on wall-clock time, on a live third
  party, or on shared mutable state.
- Pin every version in the pipeline itself — action SHAs, tool versions, base
  images. A pipeline that changes underneath you produces failures nobody can
  attribute.

---

## Security in the pipeline

The pipeline has production credentials. It is production.

- [ ] Actions/steps pinned to a **commit SHA**, not a tag.
- [ ] Fork PRs cannot access secrets — check the trigger type; the "run on PR
      with secrets" pattern is a known escalation path.
- [ ] Least-privilege tokens; read-only by default.
- [ ] Secrets scoped per environment; production credentials unreachable from
      staging workflows.
- [ ] Deployment via short-lived federated identity (OIDC), not static keys.
- [ ] Self-hosted runners isolated per job.
- [ ] Secret scanning and dependency audit as blocking steps.
- [ ] Branch protection: no direct pushes, review required, checks required,
      force-push disabled.
- [ ] The pipeline definition itself requires review to change.

---

## A worked example

```yaml
name: CI
on:
  pull_request:
  push: { branches: [main] }

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true          # do not burn runners on superseded commits

permissions:
  contents: read                    # least privilege by default

jobs:
  verify:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16@sha256:<digest>
        env: { POSTGRES_PASSWORD: test }
        options: >-
          --health-cmd pg_isready --health-interval 5s --health-retries 10
        ports: ['5432:5432']
    steps:
      - uses: actions/checkout@<sha>            # pinned, not @v4
      - uses: actions/setup-node@<sha>
        with: { node-version-file: '.nvmrc', cache: 'npm' }

      - run: npm ci --ignore-scripts             # frozen; no install-time code

      - run: npm run lint
      - run: npm run typecheck
      - run: npm run test:unit -- --coverage
      - run: npm audit --audit-level=high
      - run: npm run test:integration
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/postgres

      - run: npm run build
      - uses: actions/upload-artifact@<sha>
        with: { name: dist, path: dist/, retention-days: 7 }

  deploy-staging:
    needs: verify
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging                        # protection rules + scoped secrets
    permissions: { contents: read, id-token: write }   # OIDC, no static keys
    steps:
      - uses: actions/checkout@<sha>
      - uses: actions/download-artifact@<sha>
        with: { name: dist, path: dist/ }
      - name: Migrate
        run: npm run migrate:deploy
      - name: Deploy
        run: ./scripts/deploy.sh staging ${{ github.sha }}
      - name: Smoke test
        run: ./scripts/smoke.sh https://staging.example.com
```

The details that matter here: `concurrency` cancellation, `permissions` set to
least privilege, `--ignore-scripts`, pinned SHAs, the artefact built once and
downloaded rather than rebuilt, migration as an explicit step before deploy, and
a smoke test that actually verifies the deploy landed.

---

## Monorepo pipelines

- Detect affected packages and build only those (Nx, Turborepo, Bazel, or a
  path-filter). A monorepo that rebuilds everything on every change gets slow
  enough that people split the repo for the wrong reason.
- Remote caching, so CI reuses what a developer already built.
- Per-package deploy triggers.
- Enforce dependency boundaries in CI — a lint rule that fails when an app
  imports another app's internals.

---

## Preview environments

The highest-value platform investment most teams skip. Every pull request gets a
running deployment at a unique URL.

- Seeded with synthetic data; **never** production personal data.
- Torn down automatically on merge or close, and after a TTL — orphaned preview
  environments are a common cost leak.
- Basic-auth or IP-restricted; they must not be publicly crawlable.
- The URL posted to the PR.

They convert "looks right in the diff" into "I clicked it", which changes review
quality more than any lint rule.

---

## The deployment script

Whatever the platform, the deploy script should:

1. Take a **commit SHA**, not a branch. Deploying "main" is deploying "whatever
   main is right now", which is not a reproducible action.
2. Verify the artefact exists for that SHA rather than rebuilding.
3. Run migrations as a separate, ordered step with its own failure handling.
4. Deploy with a health check gate — abort and roll back if the new version does
   not become healthy.
5. Run smoke tests against the deployed environment.
6. Annotate dashboards and notify the team.
7. Exit non-zero on any failure, and leave the previous version serving.

And there must be `deploy.sh rollback <previous-sha>`, which has been run at
least once deliberately.

---

## Metrics worth tracking

| Metric | Why |
|---|---|
| Lead time (commit → production) | The headline number |
| Deploy frequency | Small frequent deploys are safer than large rare ones |
| Change failure rate | What fraction of deploys cause an incident |
| Time to restore | How fast you recover — the number that matters most in an incident |
| Pipeline duration and flake rate | The developer-experience tax |

These are the DORA metrics. Their value is not benchmarking against an industry
average; it is noticing when your own numbers get worse.
