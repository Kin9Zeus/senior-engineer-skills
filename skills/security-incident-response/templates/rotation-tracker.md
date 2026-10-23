# Rotation tracker

One row per secret. A row is **done only when the last column is filled** — the
old credential proven dead. Names and ids only; never values.

Order rows by blast radius (cloud/IAM → database → signing keys → payments →
spend-bearing APIs → OAuth/webhooks → registries/CI → the rest).

| # | Secret (name) | Issuer | Environments / copies | New id created | Deployed (UTC) | Old revoked (UTC) | Old proven dead (how, UTC) | Owner |
|---|---|---|---|---|---|---|---|---|
| 1 | `AWS_ACCESS_KEY_ID` | AWS IAM | prod, staging, CI | | | | e.g. `GetCallerIdentity` with old key → AccessDenied | |
| 2 | `DATABASE_URL` | Postgres host | prod, staging, replica, BI | | | | e.g. login with old role fails | |
| 3 | `SESSION_SECRET` | self | prod, staging | | | | old cookie rejected | |
| 4 | `STRIPE_SECRET_KEY` | Stripe | prod | | | | old key → 401 | |
| 5 | `OPENAI_API_KEY` | AI provider | prod, workers | | | | old key → 401; spend cap set | |

## Also rotate (people and pipeline)

| Item | Done (UTC) | By |
|---|---|---|
| Platform CLI / project tokens | | |
| CI/CD variables and deploy tokens | | |
| Private registry credentials | | |
| Git host integration (revoke + reconnect) | | |
| Personal access tokens of every team member | | |
| MFA re-enrolled / sessions revoked for platform accounts | | |

## Found copies that were not on the list

(Forgotten cron jobs, preview environments, laptop `.env` files, old Docker
layers. Each one is a finding.)

| Where | Secret | Action |
|---|---|---|
| | | |
