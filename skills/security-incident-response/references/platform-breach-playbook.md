# Provider and platform breach playbook (class A)

A vendor tells you — by email, status page or the news — that someone got into
systems that hold your secrets or data. You did nothing wrong, and you are still
the one who must act, because the attacker's next stop is *your* upstream
services.

**Core stance:** the provider's statement "a subset of users" tells you their
confidence, not your safety. Rotation costs an afternoon. A missed exposure costs
an incident. **Rotate unless you can prove the exposure did not apply.**

---

## The first hour

```
 1  Read the primary source — the provider's own disclosure, not a summary.
    Note: what was accessed, the time window, what they ask you to do, and what
    they have NOT said (scope, vector, whether protected/sealed items were in scope).
 2  List everything the provider stores for you:
      environment variables · private registry credentials · deploy and CLI
      tokens · Git integration grants · database connection strings ·
      volumes/backups · webhooks · team members' access tokens
 3  Pause what you can afford to pause: scheduled jobs and workers that call
    spend-bearing APIs (AI inference, SMS, email) while you rotate.
 4  Rotate upstream-first, highest blast radius first
    (secret-rotation-playbook.md).
 5  Start the hunt at the ISSUERS' audit logs (detection-and-hunting.md).
 6  Record every step in templates/incident-timeline.md.
```

## Rotate in the right direction

The provider holds a *copy* of the secret; the issuer controls whether it works.
Rotating inside the provider's dashboard alone changes nothing the attacker has.

```
WRONG  edit the value in the provider  →  the old value still works at the issuer
RIGHT  1. create the new credential at the issuer (cloud IAM, database, Stripe…)
       2. store the new value in the provider
       3. redeploy so the app uses it
       4. revoke the OLD credential at the issuer
       5. prove step 4: call with the old value, expect 401/403
```

## Provider recovery quirks

Incidents often come with a deploy freeze. Plan for these:

- **Deploys paused or queued.** You may be unable to ship the rotated secrets or a
  patch. Decide in advance what is acceptable meanwhile: take non-critical
  services offline, put edge protection (WAF rule, IP allowlist) in front of the
  rest, and stop workers that call spend-bearing APIs.
- **Commits made during the freeze may not have been built.** After the freeze
  lifts, **redeploy the latest commit explicitly** and confirm the running
  version matches (a version endpoint or build-id header you control).
- **Git integration.** If the provider held a Git-host grant, revoke and
  reconnect it, and review the Git host's security log for token use.
- **CLI and CI credentials.** Recreate every token the provider issued — the
  ones in CI variable stores and on developers' laptops. A stale token left in a
  CI job is a standing key into the provider.
- **Preview and staging environments** usually carry copies of production
  variables. They are in scope.

## Do not forget the people

Every team member's personal access tokens, SSH keys and OAuth grants to the
provider are in the same blast radius. Ask each person to review and revoke
sessions, enable or re-enroll MFA, and check for unfamiliar sign-ins.

## Closing the incident

Closed when **all** of these are true:

- [ ] Every inventoried secret is rotated, and the old value verified dead
- [ ] Provider-side audit logs show no unexplained use since the exposure window
      began — or each anomaly is explained or being followed
- [ ] Deploys are healthy and the running version is the one you intended
- [ ] Customer-data impact decided with counsel, and any notification sent
- [ ] A control added so the next provider breach is cheaper (see below)

## Make the next one cheaper

Do these after the incident, while the pain is fresh. They are the point of
`cloud-security`:

1. **Fewer long-lived secrets.** Replace static cloud keys with short-lived
   federated credentials (OIDC) wherever the platform supports it.
2. **Narrow every key.** One key per service, least privilege, scoped to the
   resource, with an expiry or rotation date. A single all-powerful key is how
   one breach becomes total.
3. **Spend caps and alerts** on every provider that bills by use.
4. **A rotation runbook you have rehearsed.** If rotating everything takes you
   three days, find out now.
5. **Use a dedicated secrets manager** for the highest-value secrets rather than
   plain platform variables; fetch at runtime with an identity, not a pasted key.
6. **Network and egress allowlists** so a stolen database credential is useless
   from the attacker's IP.

---

# Case file — Railway disclosure, October 2026

> **Last verified: 2026-10-23.** This is a dated record, not a standing claim.
> Provider incidents evolve; **re-read the provider's current page** before
> acting on any detail here.

**Primary sources**
- Railway security disclosure, 21 October 2026:
  <https://blog.railway.com/p/security-disclosure-wednesday-october-21st>
  (the page also lists later posts: a preliminary report on 22 October, and on
  23 October a recommendation titled "Recover Failing Deploys")
- Railway status page: <https://status.railway.com>

**What Railway has said** (per the disclosure page)
- It detected anomalous activity involving the systems that store customer
  environment variables.
- An unauthorised third party **may have accessed encrypted environment
  variables and, for some, obtained the decrypted contents.**
- Initial analysis suggests impact **may be limited to a subset of users**;
  affected, confirmed accounts are to be contacted by email.
- It associates the activity with a series of recent attacks on platform
  companies aimed at compromising **AI inference providers**, and says it has
  notified upstream providers so they can revoke keys proactively.
- All deployments were paused during the investigation.

**What Railway asks customers to do**
- Roll all environment variables stored in Railway, including API keys.
- Roll private registry credentials.
- Review logs for those services for unusual activity.
- (23 Oct recommendation, per the page's summary) Redeploy the latest commit —
  commits pushed while deployments were paused were not deployed — reconnect
  GitHub, and recreate CLI and CI credentials.

**What is not public (as of the date above)** — do not fill these gaps with
guesses: the attack vector, the number of affected accounts, whether
protected ("sealed") variables were in scope, and whether anything beyond
environment variables was accessed.

**Your checklist if you ran anything on Railway**

```
[ ] Export the list of variable NAMES per service and environment (never paste
    values into tickets or chat). Include preview/PR environments.
[ ] Rotate each at its ISSUER first (see rule above), starting with:
      cloud keys → database → payment → signing/app keys → AI-provider and other
      spend-bearing keys → OAuth/webhook secrets
[ ] Rotate private registry credentials
[ ] Treat "sealed"/protected variables as in scope until Railway confirms otherwise
[ ] Recreate Railway CLI tokens, project tokens and CI secrets; revoke old ones
[ ] Revoke and reconnect the GitHub integration; review the GitHub security log
[ ] Redeploy the LATEST commit of every service; confirm the running build id
[ ] Hunt at the issuers: AWS CloudTrail, GCP audit logs, GitHub security log,
    database connection logs, AI-provider usage dashboards, Stripe dashboard
[ ] Set spend caps and usage alerts on AI and messaging providers
[ ] Record all of it in templates/incident-timeline.md and rotation-tracker.md
```

**If the app on Railway is PHP:** two incidents landed within a day of each
other. A PHP worker an attacker can execute code in can read the same
environment variables the platform just told you may be exposed. Apply
`php-hardening/references/php2shell-response.md` as well, and treat the
combination as one higher-severity incident.

**If your variables hold AI-provider keys:** these are the explicit target of
the campaign Railway describes. Check provider usage for the period since the
exposure window opened (unfamiliar models, regions, request volume, new keys),
rotate, and set hard spend limits.
