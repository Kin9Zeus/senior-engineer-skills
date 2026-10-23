# Secret rotation playbook

Rotation done well is boring: no downtime, no leftover live credentials, and a
record. Rotation done badly is an outage plus a still-open door.

> Commands below are standard but flags change. Run `--help` or check the
> provider's current documentation before executing; never paste real secret
> values into tickets, chat or logs.

---

## The universal procedure (per secret)

```
1  IDENTIFY   what it unlocks, who uses it, where every copy lives
2  CREATE     a new credential at the issuer — least privilege, scoped, labelled
3  DISTRIBUTE put it where the app reads it (secrets manager / platform / CI)
4  DEPLOY     restart or redeploy; confirm the app now uses the NEW one
5  REVOKE     disable, then delete, the OLD credential at the issuer
6  VERIFY     call with the OLD value → must fail (401/403/auth error)
7  RECORD     rotation-tracker row: who, when, old id, new id, verified
```

**Find every copy** before step 5, or you revoke something a forgotten cron job
still uses. Copies hide in: platform variables for *each* environment, preview
environments, CI variable stores, `.env` files on laptops, Docker image layers,
Terraform state, shared password-manager notes, chat history, runbooks.

## Zero-downtime: the dual-key technique

When the service accepts one credential at a time, you cannot swap atomically.
Prefer issuers that allow two valid credentials at once:

1. Create key B while key A is still valid.
2. Deploy the app using B.
3. Watch for any remaining use of A (issuer last-used data).
4. Revoke A once unused.

Where the issuer allows only one (some webhook secrets, some OAuth secrets),
schedule a short window, or put the app in a state that retries on failure.

---

## Ordering and consequences

| Secret | Rotate how | Watch out for |
|---|---|---|
| **Cloud access keys** (IAM) | Create second key, deploy, deactivate then delete old. Prefer replacing static keys with short-lived federated credentials | Instance profiles/roles need no key — remove static keys altogether if possible |
| **Database password** | Create a *new role* with the same grants; switch the app; drop the old role | Read replicas, BI tools, backup jobs, migration runners often hold their own copy. Restrict network access to the DB at the same time |
| **Session secret / cookie key** | Add the new key first (many frameworks accept a list), keep the old as verify-only, remove after sessions expire | Rotating hard logs every user out. That is acceptable in an incident — say so in your comms |
| **JWT signing key** | Publish the new key with a new `kid`; sign with new; accept both until old tokens expire; then remove old | Tokens signed with the compromised key remain valid until it is removed from verification — shorten the overlap in an incident |
| **Framework app/encryption key** (e.g. Laravel `APP_KEY`, Rails master key, Django `SECRET_KEY`) | Check the framework's documented rotation path — several support previous-key lists | Rotating can make previously encrypted data **undecryptable**. Plan re-encryption before removing the old key |
| **Data-at-rest encryption keys** | Use the KMS's key-versioning; re-wrap data keys | Never delete the old key until everything it protected is re-encrypted |
| **Payment keys / webhook secrets** | Roll in the provider dashboard; roll webhook signing secrets separately | Verify webhooks still validate; replay protection |
| **AI / SMS / email / maps API keys** | Create new, deploy, delete old; set a hard spend cap | These are directly monetisable — check usage history for the exposure window first |
| **OAuth client secrets** | Regenerate; update; revoke old | Existing refresh tokens may need re-consent; check for unfamiliar grants |
| **Git host tokens / deploy keys** | Revoke, recreate with minimum scope and an expiry | Review the security log for token use and for new deploy keys/webhooks |
| **Registry credentials** | Regenerate; update CI and the platform | Review recent image pushes for tampering before trusting any image |
| **CI/CD secrets** | Rotate, then audit workflow files for changes | Anything the pipeline could read, an attacker with pipeline access could too |
| **SSH keys** | Generate new, replace in `authorized_keys`, remove old | Check `authorized_keys` for entries you did not add |

## Provider notes

**AWS** — list and age keys: `aws iam list-access-keys --user-name <u>`. Rotate:
`aws iam create-access-key`, deploy, `aws iam update-access-key --status Inactive`,
observe, then `delete-access-key`. Audit with CloudTrail (`LookupEvents` by access
key id). Prefer roles and short-lived credentials.

**Google Cloud** — service-account keys: `gcloud iam service-accounts keys list`,
`keys create`, `keys delete`. Audit via Cloud Audit Logs. Prefer workload
identity federation over exported keys.

**GitHub** — revoke classic and fine-grained tokens and OAuth/App grants in
settings; review the account and organisation **security log**; list deploy keys
and webhooks per repository. Prefer short-lived `GITHUB_TOKEN` and OIDC for CI.

**Databases** — `ALTER ROLE <name> PASSWORD ...` is acceptable for a break-glass
rotation but a new role plus a drop is cleaner because it also invalidates
anything still holding the old role's session. Terminate stale connections.

**Railway** — variables live per service and per environment; also project/CLI
tokens and the Git integration. Check the CLI's own help
(`railway variables --help`) for current syntax. See the case file in
`platform-breach-playbook.md`.

**Stripe and other payment providers** — roll secret keys with the overlap window
the dashboard offers; roll webhook signing secrets; review restricted-key scopes.

## Verification — the part people skip

For each rotated secret, record the check that proves the old one is dead:

```bash
# Pattern — expect an authentication failure, not success.
# Run with the OLD value, from a shell where it will not land in history:
curl -sS -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $OLD" https://api.example.com/me
# 401 or 403 = good.  200 = the old credential is STILL LIVE.
```

For databases: attempt a login with the old credentials and expect failure. For
cloud keys: the issuer shows the key as inactive/deleted and a call fails.

## Anti-patterns

- Rotating by editing the provider dashboard value only (the issuer still honours
  the old one).
- One rotation script that does all steps at once with no verify step.
- New secrets generated by hand with low entropy. Use the issuer's generator or
  a CSPRNG (`openssl rand -base64 32`).
- Storing the new secret in the same place the old one leaked from, with the same
  exposure path.
- Rotating without narrowing: if the new key has the same sweeping permissions,
  the next breach is as bad as this one. Apply least privilege while you are here.
