---
description: Build and run a secret-rotation plan — inventory every secret the project uses, order by blast radius, rotate upstream-first, and prove each old value is dead.
argument-hint: "[scope, e.g. 'all' | 'Railway services' | 'database' | 'after the leak in commit abc123']"
---

# Secret Rotation

Rotate: **$ARGUMENTS** (default: every secret the project and its platform hold).

Load `security-incident-response` (and `cloud-security` for the long-term fix).
Rotation changes live credentials — **propose the plan, get the user's confirmation,
then execute step by step.** Never print or paste secret values.

## Steps

1. **Inventory (names only).**
   `bash skills/security-incident-response/scripts/rotation-inventory.sh .`
   (PowerShell: `.ps1`). Then ask the user for what the script cannot see: provider
   dashboards, CI variable stores, preview/staging environments, laptops.

2. **Fill `templates/rotation-tracker.md`**, ordered by blast radius:
   cloud/IAM → database → signing & encryption keys → payments → spend-bearing APIs
   (AI, SMS, email) → OAuth/webhooks → registries/CI → the rest.

3. **For each secret, apply the universal procedure:**
   `create new at the ISSUER → distribute → deploy → revoke old → prove old is dead → record`.
   Per-provider notes and consequences (session secrets, framework app keys, JWT
   signing) are in `references/secret-rotation-playbook.md` — read the consequences
   row *before* rotating signing or encryption keys.

4. **Verify** every row: call with the old value and expect `401/403`. A dashboard
   edit alone is not a rotation.

5. **Narrow while you are here** — new credentials get least privilege, a network
   restriction, a spend cap and a label (`cloud-security`).

6. **Hunt** at each issuer for use during the exposure window
   (`references/detection-and-hunting.md`).

## Output

- The completed tracker (names and ids only — never values)
- Rotations that could not be completed, with owner and deadline
- Copies found that were not on the list
- **What I could not verify** — mandatory
