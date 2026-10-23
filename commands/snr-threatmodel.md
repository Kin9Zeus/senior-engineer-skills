---
description: Thirty-minute threat model for a system or feature — data-flow sketch with trust boundaries, STRIDE per boundary, a control and a test for every threat.
argument-hint: "[system or feature, e.g. 'checkout flow' | 'file uploads' | 'the new AI agent']"
---

# Threat Model

Subject: **$ARGUMENTS**

Load `security-hardening` and follow `references/threat-modelling.md`. For AI
features also load `ai-security`; for infrastructure, `cloud-security`.

## The four questions

1. **What are we building?** Sketch the data flow: actors, processes, data stores,
   external services, and the **trust boundaries** between them. Mark where
   untrusted input enters, where secrets live, and where data leaves.
2. **What can go wrong?** STRIDE at each boundary — Spoofing, Tampering,
   Repudiation, Information disclosure, Denial of service, Elevation of privilege.
   Add the platform case: *what if our host, CI or secrets store is breached?*
3. **What are we doing about it?** One control per threat, with an owner. Prefer
   preventive controls; add detective ones (alerts) where prevention is partial.
4. **Did we do a good job?** One **test per control** — an automated test, a
   configuration check or a drill. A control with no test is a hope.

## Output

A table: `# · Boundary · Threat (STRIDE) · Impact · Likelihood · Control · Test · Owner`,
ordered by risk, followed by the residual risks the user must explicitly accept
and **What I could not verify**. Save it beside the code (e.g. `docs/threat-model.md`)
so it is reviewed when the design changes.
