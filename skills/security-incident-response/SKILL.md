---
name: security-incident-response
description: Security incident response for developers and small teams — a provider or platform breach, a leaked or exposed credential, a critical CVE in your runtime, or signs that a server is already compromised. Covers triage, containment, ordered secret rotation, log hunting, eradication, recovery and notification. Use when the user says "we got breached", "we were hacked", "my server is compromised", "leaked key", "exposed secret", "rotate all my secrets", "rotate my API keys", "Railway incident", "Vercel incident", "platform breach", "provider breach", "environment variables exposed", "suspicious activity", "webshell", "unknown process", "unexpected charges on my API key", "emergency patch", "patch now", "zero-day", "is my site hacked", "what do I do after a breach" or "credential leak"; when a vendor or the news announces a security incident that touches the user's stack; and as the first skill to load whenever something may already be compromised. Defensive security only. By Devleck.
license: MIT
---

# Security Incident Response

When something may already be compromised, the work is different. You are no
longer preventing — you are **limiting damage, finding the extent, and not
destroying evidence while you do it**.

**Scope:** systems the user owns or is authorised to defend. Never "hack back",
never probe a third party's infrastructure, never touch systems you were not
asked about. Read-only investigation first; every destructive step (revoking,
deleting, rebuilding, wiping) needs the user's confirmation.

**Not legal advice.** Breach-notification duties vary by jurisdiction and
contract. Where this skill mentions a legal clock, it is a prompt to ask a
lawyer or the data-protection officer, not an answer.

---

## 1. Triage — classify in the first fifteen minutes

Four situations need different first moves. Decide which one you are in; it can
be more than one.

| Class | Signal | First move |
|---|---|---|
| **A · Provider / platform breach** | A vendor (host, PaaS, CI, registry, SaaS) announces unauthorised access to systems that hold *your* data or secrets | **Rotate every secret that provider stored**, then hunt for use of them. See `references/platform-breach-playbook.md` |
| **B · Leaked credential** | A key in a public repo, a log, a bundle, a paste, a screenshot; or unexplained usage on an API key | **Revoke or rotate first**, then check for abuse, then clean the leak. Never the reverse |
| **C · Critical CVE in your runtime** | A language, web server, framework or image has an actively-targeted remote-code-execution flaw | **Inventory, patch, restart, then assume exposure** for the window before the patch. See `php-hardening` for the PHP case |
| **D · Active intrusion** | Unknown processes, unexpected files, new admin users, outbound traffic you cannot explain | **Isolate, preserve evidence, then investigate.** Do not "clean up" first |

If two classes apply at once — a platform breach while a runtime CVE is open, for
example — secrets exposed by A are exactly what an attacker exploiting C would
read. Treat the combination as one incident with the higher severity.

---

## 2. The rules that decide whether the response works

1. **Revoke before you investigate; investigate before you clean.** A live
   credential is an open door while you read logs. A cleaned server is a
   destroyed crime scene.
2. **Rotate upstream first, then update the platform.** Create the new
   credential at the issuing service (cloud IAM, database, payment provider),
   put it where the app reads it, redeploy, **then revoke the old one**. Doing it
   in the other order causes an outage; skipping the last step leaves the old
   key live.
3. **Rotation is complete only when the old credential is proven dead.** Call the
   provider with the old value and expect `401`/`403`. "I changed it in the
   dashboard" is not verification.
4. **Assume every secret the compromised system could read is compromised.**
   Not just the one you know was used. If an attacker ran code on a web worker,
   it read the whole environment and every file that user can open.
5. **Do not trust the compromised system to report on itself.** Logs on a
   host an attacker controlled can be edited. Prefer provider-side audit logs
   (cloud audit trails, Git host security log, payment dashboard) — the
   attacker did not control those.
6. **Write the timeline as you go.** `templates/incident-timeline.md`. At 3 a.m.
   you will not remember which key you rotated at which minute.
7. **No silent scope reduction.** If you could not rotate something, say so and
   record the owner and deadline — an un-rotated secret is an open finding, not a
   footnote.

---

## 3. The response, in order

```
 0  Declare       one owner, one channel, start the timeline
 1  Contain       stop the bleeding without destroying evidence
 2  Inventory     what secrets and data could the affected system reach?
 3  Rotate        highest blast radius first (see ordering below)
 4  Hunt          provider-side logs first; look for use of the exposed secrets
 5  Eradicate     remove persistence; patch the entry point
 6  Recover       redeploy from a known-good, patched build; verify
 7  Notify        users, regulators, partners — per legal advice
 8  Learn         blameless postmortem; add the control that would have caught it
```

### Step 2 — inventory with the helper

```bash
bash skills/security-incident-response/scripts/rotation-inventory.sh .
```

It lists environment-variable **names** (never values) that the repository
reads or defines, grouped by likely sensitivity. It is a starting worksheet, not
a complete inventory: secrets that live only in a provider dashboard, a CI
variable store, or a developer's shell will not appear. Ask the user to list
those.

### Step 3 — rotation order (highest blast radius first)

1. Cloud root and IAM credentials, CI/CD deploy tokens, Git host tokens
2. Database credentials and connection strings
3. Signing and encryption keys (session secret, JWT signing key, framework app
   key) — **read the consequences first**, they invalidate sessions or make old
   ciphertext unreadable
4. Payment provider keys and webhook signing secrets
5. Third-party API keys, **especially anything that spends money** (AI inference,
   SMS, email, maps)
6. OAuth client secrets, SSO and SCIM tokens
7. Container-registry and package-registry credentials
8. Everything else that the inventory turned up

Per-provider detail and the dual-key technique for zero-downtime rotation are in
`references/secret-rotation-playbook.md`.

### Step 4 — hunt

Start at the issuer, not the host. For each rotated credential: when was it last
used, from which IP, doing what? Anything after the exposure window that you
cannot explain is a lead. `references/detection-and-hunting.md` has the queries
and the host-level checks for class C and D.

### Step 5 — eradicate

Patching the entry point without removing persistence is the classic half-fix.
Check for: new users and keys, scheduled jobs, modified startup files, new
files in web-served and upload directories, new webhooks and OAuth grants, new
deploy keys. If you cannot prove the host is clean, **rebuild it from a clean
image** rather than cleaning it by hand.

---

## 4. What people get wrong

- **Rotating only the secret they know leaked.** The attacker had the whole
  store. Rotate the lot, in order of blast radius.
- **Updating the platform before the issuer**, taking production down, or the
  reverse — never revoking the old key.
- **Purging git history instead of rotating.** The repository looks clean; the
  key still works. (Class B.)
- **Re-deploying from a poisoned pipeline.** If CI tokens or registry
  credentials were exposed, rotate them *before* the recovery deploy, or the
  fresh build runs with the exposed credentials.
- **Treating "the provider says limited subset" as "not us".** Rotation is cheap;
  a missed exposure is not. Rotate unless you can prove otherwise.
- **Sealed or write-only variables assumed safe.** Whether a protected variable
  was in scope is the provider's to confirm. Until they do, rotate it too.
- **Forgetting derived secrets.** Webhook URLs with embedded tokens, database
  read replicas with their own passwords, preview-environment copies of the
  production variables, local `.env` files on laptops.
- **No customer-impact check.** If the exposed secrets could read user data, the
  privacy and notification track starts now, in parallel — not after the
  technical work ends.
- **Declaring victory at "deploys work again".** Done means every rotated
  secret's old value is proven dead and the hunt found nothing — or found
  something and you followed it.

---

## 5. Notification and communication

Start the decision early; it often has a deadline.

- If personal data may have been accessed, a regulator clock may already be
  running (under the GDPR the controller's window is 72 hours from becoming aware,
  Art. 33). **Ask counsel or the DPO** — do not decide this alone.
- Send customers facts, not reassurance: what happened, what data, what you have
  done, what they should do (rotate passwords, watch for phishing).
- Do not publish indicators or details that help a second attacker before the
  entry point is closed.
- Link to `privacy-compliance` for the data inventory — it tells you *whose* data
  the exposed systems held.

---

## 6. Report format

Every finding or action in the incident record uses the suite's standard shape:

```markdown
### <Action or finding> — P0
**Class**       A · Provider breach (secrets exposure)
**Evidence**    <provider disclosure URL + timestamp / log line / file>
**Confidence**  CONFIRMED | PLAUSIBLE
**Impact**      <what an attacker holding this could do, concretely>
**Action**      <the exact rotation / patch / isolation step>
**Verify**      <the check that proves it worked — e.g. old key returns 401>
**Owner / by**  <name, deadline>
```

End every incident summary with **"What I could not verify"** — mandatory.

---

## References, templates and scripts

- `references/platform-breach-playbook.md` — class A end to end, plus the dated case file for the Railway disclosure (October 2026)
- `references/secret-rotation-playbook.md` — ordering, dual-key rotation, per-provider steps, verification
- `references/detection-and-hunting.md` — provider audit logs, web-server and host hunting, persistence checklist
- `templates/incident-timeline.md` — the running record
- `templates/rotation-tracker.md` — one row per secret: rotated, revoked, verified
- `scripts/rotation-inventory.sh` / `scripts/rotation-inventory.ps1` — read-only list of secret names the repo reads
- Related skills: `security-hardening` (prevention), `php-hardening` (the PHP runtime case), `cloud-security` (limiting blast radius before the next incident), `observability-slo` (post-incident learning), `privacy-compliance` (data inventory and notification)
