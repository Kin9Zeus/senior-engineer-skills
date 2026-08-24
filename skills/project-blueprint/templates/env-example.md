# The Config Contract

`.env.example` is not a convenience file — it is the contract between the
application and every environment it runs in. Treated properly it eliminates an
entire class of 3am incidents.

## Three rules

1. **Every variable the app reads appears here.** A variable read in code but
   absent here is a landmine for the next deploy.
2. **No real values, ever.** Placeholders only. This file is committed.
3. **Validated at boot.** The application parses this contract with a schema at
   startup and refuses to run if it is not satisfied — naming the offending key.
   A misconfigured app must fail at start, not at the first request that needs
   the missing value.

## Template

```bash
# =============================================================================
#  <Project> — environment contract
#
#  Copy to .env and fill every value marked REQUIRED.
#  Config is validated at boot: a missing or malformed REQUIRED value will
#  stop the process with an error naming the key.
#
#  Never commit .env. Never put a real value in this file.
# =============================================================================

# --- Runtime -----------------------------------------------------------------
NODE_ENV=development                  # REQUIRED  development | test | production
PORT=3000                             # optional  default 3000
LOG_LEVEL=debug                       # optional  trace|debug|info|warn|error

# --- Database ----------------------------------------------------------------
# REQUIRED. Postgres 16+. Include ?sslmode=require in every deployed environment.
DATABASE_URL=postgresql://user:password@localhost:5432/appname_dev
DATABASE_POOL_MAX=10                  # optional  default 10

# --- Cache / queue -----------------------------------------------------------
REDIS_URL=redis://localhost:6379      # REQUIRED in production; optional locally

# --- Authentication ----------------------------------------------------------
# REQUIRED. Min 32 bytes of entropy. Rotating this invalidates all sessions.
#   generate: openssl rand -base64 32
SESSION_SECRET=<generate-me>
SESSION_TTL_HOURS=720                 # optional  default 720 (30 days)

OAUTH_GOOGLE_CLIENT_ID=               # optional  enables Google sign-in
OAUTH_GOOGLE_CLIENT_SECRET=           # required if the ID above is set

# --- Third-party services ----------------------------------------------------
# REQUIRED in production. Use test keys locally — never a live key in .env.
STRIPE_SECRET_KEY=sk_test_<...>
STRIPE_WEBHOOK_SECRET=whsec_<...>     # REQUIRED — the handler verifies signatures

RESEND_API_KEY=                       # REQUIRED in production; logs to console otherwise
EMAIL_FROM=noreply@example.com        # REQUIRED in production

SENTRY_DSN=                           # optional locally; REQUIRED in production

# --- Public (compiled into the client bundle — NEVER put a secret here) -------
PUBLIC_APP_URL=http://localhost:3000   # REQUIRED
PUBLIC_ANALYTICS_ID=                   # optional; gated behind cookie consent

# --- Feature flags -----------------------------------------------------------
FEATURE_NEW_CHECKOUT=false            # owner: @name  remove by: 2026-Q4
```

## Conventions worth enforcing

**Annotate every key** with `REQUIRED` or `optional`, its default, its allowed
values and how to generate it. The comment is the documentation; nobody reads a
separate page.

**Mark the public prefix loudly.** Anything with a `PUBLIC_` / `NEXT_PUBLIC_` /
`VITE_` prefix is compiled into the browser bundle and is readable by anyone. A
secret with that prefix is a disclosed secret. Add a CI check that greps the
built output for key patterns — it catches more leaks than code review does.

**Give feature flags an owner and a removal date** at creation. Flags without
expiry become permanent untested branching.

**Differ deliberately per environment.** Production must not share credentials
with staging. If staging can read the production database, staging *is*
production for breach purposes.

**Keep a drift check in CI:** fail the build if a key is read in code but missing
from `.env.example`. Ten lines of script, and it permanently ends "it works on
my machine".

## Validation sketch

```ts
// src/platform/config.ts — the only file in the codebase that reads process.env
import { z } from "zod";

const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().url(),
  SESSION_SECRET: z.string().min(32, "SESSION_SECRET needs >= 32 characters"),
  STRIPE_SECRET_KEY: z.string().startsWith("sk_"),
  SENTRY_DSN: z.string().url().optional(),
  PUBLIC_APP_URL: z.string().url(),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error("Invalid configuration:\n" + JSON.stringify(parsed.error.flatten().fieldErrors, null, 2));
  process.exit(1);
}

export const config = Object.freeze(parsed.data);
```

Add a lint rule forbidding `process.env` outside this file. It is the difference
between configuration you can reason about and configuration you discover.
