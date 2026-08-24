# Runbook — `<Failure scenario>`

> A runbook is written for the person on call at 3am who did not build this
> system and has never seen this failure. Every command is copy-pasteable. Every
> credential's location is named. Nothing says "you may need to".
>
> **A runbook that has never been executed is a draft.** Run it during a drill
> and correct what was wrong.

| | |
|---|---|
| **Scenario** | `<what is broken>` |
| **Severity** | `SEV1 / SEV2 / SEV3` |
| **Owner** | `<team or person>` |
| **Last executed** | `<date — drill or real incident>` |
| **Last reviewed** | `<date>` |

---

## Symptoms

How you know this is what is happening — and how you know it is *not* something
else that looks similar.

- `<alert name>` fires
- `<dashboard>` shows `<specific pattern>`
- Users report `<specific behaviour>`

**Not this runbook if:** `<the similar-looking failure and its runbook>`

---

## Impact

| | |
|---|---|
| **Who is affected** | `<all users / one tenant / one region / background jobs only>` |
| **What they experience** | `<specific>` |
| **Data at risk** | `<none / in-flight writes / N minutes of events>` |
| **Revenue impact** | `<if applicable>` |

---

## Immediate mitigation — do this first

> Restore service before diagnosing. The cause will still be there in an hour;
> the users will not.

```bash
# 1. <What this does, in one line>
<exact command>

# 2. <What this does>
<exact command>

# Expected result: <what you should see>
# If that does not happen: <the next step, or escalate to whom>
```

**Time to mitigate:** `<measured, from the last drill>`

---

## Diagnosis

Only after service is restored, or if mitigation did not work.

```bash
# Is it us or a dependency?
curl -sS -o /dev/null -w '%{http_code} %{time_total}s\n' https://api.example.com/health
<provider status page URL>

# What changed? (This is almost always the answer.)
<how to see recent deploys, flag changes and config changes>

# Resource state
<the specific queries or commands for connections, memory, queue depth, disk>

# Recent errors
<the exact log query, with the correlation-id filter>
```

**Decision tree**

```
Is the dependency healthy?
├── No  → <link to the dependency-outage runbook>
└── Yes → Did we deploy in the last hour?
          ├── Yes → roll back first, investigate after
          └── No  → Is one instance affected or all?
                    ├── One → <cycle the instance>
                    └── All → <continue below>
```

---

## Resolution

```bash
# <Step, with what it does and what to expect>
<command>
```

**Verify recovery — with metrics, not hope**

```bash
<the specific check that proves the system is healthy>
```

- `<dashboard link>` — error rate back to baseline
- `<dashboard link>` — p95 latency back under `<threshold>`
- `<business metric>` — flowing again

Watch for `<duration>` before declaring it resolved. Recoveries that revert
within ten minutes are common.

---

## Rollback

If the above does not work:

```bash
<the exact rollback command, with the version argument explained>
```

**Last executed:** `<date>` · **Measured duration:** `<minutes>`

---

## Access you will need

| Thing | Where | Who has it |
|---|---|---|
| Production console | `<link>` | `<team>` |
| Database credentials | `<secret manager path>` | `<team>` |
| Deploy pipeline | `<link>` | `<team>` |
| Provider dashboard | `<link>` | `<team>` |
| Status page | `<link>` | `<team>` |

**If you do not have access:** `<who to wake, and how>`

---

## Escalation

| When | Who | How |
|---|---|---|
| Not mitigated in `<15>` minutes | `<name>` | `<phone/pager>` |
| Data loss suspected | `<name>` + `<name>` | `<phone>` |
| Security incident suspected | `<security contact>` | `<phone>` — **do not wipe the affected host; preserve evidence** |
| Customer-visible for > `<30>` minutes | `<comms owner>` | Status page + customer email |

---

## Communication

**Status page template**
```
[INVESTIGATING] <time> UTC — We are investigating <user-visible symptom>
affecting <scope>. Next update by <time>.
```

Update on a fixed cadence **even when there is nothing new**. "Still
investigating, next update in 20 minutes" prevents the flood of "any news?" that
distracts the people fixing it.

---

## Prevention

What would stop this recurring? Link to the tracked work.

- [ ] `<action>` — `<issue link>` — `<owner>`

---

## Related

- `<other runbooks that look similar>`
- `<the postmortem from the last time this happened>`
- `<the dashboard that shows this system's health>`

---

<!--
  MAINTENANCE

  [ ] Executed in a drill within the last 6 months
  [ ] Every command tested — copy-paste, no editing required
  [ ] Every link resolves
  [ ] Every named person still works here and still has that access
  [ ] Measured durations updated after the last drill

  Review after every incident that used it. The runbook you did not need to
  edit after an incident is a runbook nobody actually opened.
-->
