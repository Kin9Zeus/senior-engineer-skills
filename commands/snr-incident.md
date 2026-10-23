---
description: Security incident response — classify, contain, rotate secrets in the right order, hunt, recover. For provider breaches, leaked keys, critical CVEs and suspected compromise.
argument-hint: "[what happened, e.g. 'Railway breach' | 'leaked AWS key' | 'php2shell' | 'unknown process on server']"
---

# Security Incident Response

Incident: **$ARGUMENTS** (if empty, ask what happened and when it was noticed).

Load the `security-incident-response` skill. Defensive only — investigate systems
the user owns or is authorised to defend; never hack back; **every destructive step
(revoke, delete, rebuild, wipe) needs the user's confirmation.**

## 1 · Classify in the first minutes

```
A  Provider / platform breach     → rotate everything the provider stored
B  Leaked credential              → revoke first, then check abuse, then clean up
C  Critical CVE in the runtime    → inventory, patch, restart, assume exposure
D  Active intrusion               → isolate, preserve evidence, then investigate
```

Two classes can apply at once. A provider breach plus an open runtime CVE is one
incident at the higher severity — secrets from A are what an attacker exploiting C
would read.

## 2 · Read the primary source

For a named incident, fetch the provider's own disclosure (not a summary) and the
official advisory, and note: what was accessed, the time window, what the provider
asks you to do, **and what it has not said**. The dated case files are in
`references/platform-breach-playbook.md` (Railway, October 2026) and
`php-hardening/references/php2shell-response.md`. Facts there are dated — re-read
the source before acting.

## 3 · Run the response in order

```
0 Declare      one owner · start templates/incident-timeline.md
1 Contain      stop the bleeding without destroying evidence
2 Inventory    bash skills/security-incident-response/scripts/rotation-inventory.sh .
3 Rotate       blast radius first · issuer first · prove the old value dead
4 Hunt         provider-side audit logs first, then edge, then host
5 Eradicate    remove persistence · patch the entry point (or rebuild clean)
6 Recover      redeploy from a known-good patched build · verify the running version
7 Notify       personal data? ask counsel/DPO about regulator and customer duties
8 Learn        blameless postmortem · add the control that would have caught it
```

Use `templates/rotation-tracker.md` — one row per secret, done only when the old
value is proven dead.

## 4 · Output

1. **Classification** and what is known vs unknown
2. **Ordered action list** with owner and a verification for each step
3. **Rotation tracker** pre-filled from the inventory
4. **Hunt plan** per issuer and per host
5. **Notification decision** flagged for counsel
6. **What I could not verify** — mandatory

Never assert a CVE, version or exposure scope from memory. Where facts are
unconfirmed, say `UNKNOWN`.
