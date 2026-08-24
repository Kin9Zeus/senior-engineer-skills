# `<Project Name>`

> `<One sentence: what this does and for whom. Not "a web application built with
> X" — what problem it solves.>`

`<badges: build status, coverage, licence, version>`

---

## Quick start

The test of this section: someone who has never seen the project is running it
in under 15 minutes. If your instructions have a step that says "you may need
to...", that step is a bug.

**Prerequisites**

| | Version | Check |
|---|---|---|
| `<runtime>` | `<pinned version>` | `<command>` |
| `<database>` | `<version>` | `<command>` |
| `<container runtime>` | `<version>` | `<command>` |

**Run it**

```bash
git clone <url> && cd <project>
cp .env.example .env        # then fill in the values marked REQUIRED
<one command that starts everything>
```

Open `<url>`. Sign in with the seeded account `<credentials>`.

**Verify it works**

```bash
<the command that proves the setup is correct>
```

---

## Commands

| Command | What it does |
|---|---|
| `<dev>` | Start everything in development with hot reload |
| `<test>` | Run the full test suite |
| `<test:watch>` | Tests in watch mode |
| `<lint>` | Lint and format check |
| `<typecheck>` | Static type check |
| `<migrate>` | Apply pending database migrations |
| `<migrate:down>` | Roll back the last migration |
| `<seed>` | Load development data |
| `<build>` | Production build |

---

## Architecture

`<A diagram or five lines of prose. What are the pieces, and how does a request
flow through them?>`

```
<ASCII or mermaid diagram — browser -> edge -> app -> database, plus the
external services>
```

**Key directories**

| Path | Contains |
|---|---|
| `src/modules/` | Domain modules — each owns its routes, logic and data access |
| `src/platform/` | Cross-cutting: config, logging, auth, database, errors |
| `migrations/` | Versioned schema changes. Never edited after merge |
| `docs/adr/` | Why things are the way they are |

**Decisions worth knowing before you change anything**

- `<link to the two or three ADRs that constrain most work>`

---

## Configuration

Every variable is documented in `.env.example`. Config is validated at boot —
the application refuses to start with a missing or malformed value and names it.

| Variable | Required | Purpose |
|---|---|---|
| `DATABASE_URL` | yes | Primary datastore connection |
| `<...>` | | |

Secrets are never committed. In deployed environments they come from
`<secret manager>`. Rotation procedure: `<link>`.

---

## Testing

`<What is tested at each layer, and what the CI gate requires.>`

| Layer | Tool | Runs on |
|---|---|---|
| Unit | `<tool>` | Every commit |
| Integration | `<tool>` | Every PR |
| E2E | `<tool>` | Every PR, and before deploy |

Every bug fix ships with a test that fails without the fix.

---

## Deployment

| Environment | URL | Deploys when |
|---|---|---|
| Staging | `<url>` | Merge to `main` |
| Production | `<url>` | `<tag / manual approval>` |

**Rolling back:** `<the exact command or steps. If nobody has ever run this,
say so — an untested rollback is not a rollback.>`

**Migrations** run as a separate pipeline step before the application deploy.
If a migration fails, `<the documented procedure>`.

---

## Operations

- **Dashboards:** `<link>`
- **Error tracking:** `<link>`
- **Logs:** `<link>` — filter by `correlation_id`
- **On-call / escalation:** `<link>`
- **Runbooks:** `docs/runbooks/`

---

## Contributing

See `CONTRIBUTING.md`. In short: branch from `main`, keep the PR small, include
a test, and make sure CI is green.

**Conventions** are documented in `CLAUDE.md` / `AGENTS.md` so that both humans
and AI assistants write code that matches the codebase.

---

## Security

Report vulnerabilities to `<address>` — see `SECURITY.md`. Please do not open a
public issue for a security problem.

---

## Licence

`<licence>` — see `LICENSE`.
