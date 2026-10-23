# Detection and hunting

Hunting answers one question: **did anyone use what they could have taken?**
Everything below is read-only. Every hit is a lead until you read the evidence.

Work from the outside in: the issuer's logs first (the attacker did not control
them), then the edge, then the host.

---

## 1 · Provider-side audit logs (start here)

For every credential you rotate, ask the *issuer*: first/last use, source IP,
user agent, and actions — within and after the exposure window.

| Issuer | Where to look | What is suspicious |
|---|---|---|
| **AWS** | CloudTrail; IAM "access key last used"; `LookupEvents` filtered by access key id | Calls from unfamiliar IPs/regions; `ListBuckets`, `GetSecretValue`, `CreateAccessKey`, `CreateUser`, `AttachUserPolicy`, `RunInstances` you did not make; any change to logging itself (`StopLogging`, `DeleteTrail`) |
| **Google Cloud** | Cloud Audit Logs (Admin Activity, Data Access); service-account key usage | New service-account keys, new IAM bindings, compute instances you did not create |
| **GitHub** | Account and org **security log**; Settings → Applications; deploy keys; webhooks | Token use from new IPs, new deploy keys/webhooks/Actions secrets, workflow changes, force-pushes |
| **Database** | Connection log / `pg_stat_activity` history / cloud audit | Logins from outside your app's egress IPs; bulk `SELECT`; new roles; `COPY ... TO` |
| **Stripe / payments** | Dashboard → Developers → Logs; event log | API calls from unfamiliar IPs; new restricted keys; webhook endpoint changes; payouts/refund anomalies |
| **AI / SMS / email providers** | Usage dashboard, per-key usage, billing | Sudden volume, unfamiliar models or regions, usage outside your traffic hours, new keys on the account |
| **Container / package registry** | Push and pull history | Image pushes you did not make, tag moves, new tokens |
| **Identity provider / SSO** | Sign-in and admin audit logs | New admin, MFA reset, new OAuth app consent |

Record each answer in the incident timeline, including "checked, found nothing,
as of <time>".

## 2 · Web and edge logs

```bash
# Requests to dynamic endpoints with unusually large or multipart bodies
awk '$9 ~ /^(200|500|502|499)$/ && $6 ~ /POST/' access.log | sort | uniq -c | sort -rn | head -20
```

What to look for (adapt field positions to your log format):

- Bursts of `POST` with `multipart/form-data` to endpoints that never receive
  uploads
- Request bodies far larger or more deeply nested than normal traffic
- The same client repeating requests that end in `500`, `502` or a dropped
  connection (a worker that died mid-request)
- Requests to paths you do not serve (`/.env`, `/.git/`, `/phpinfo.php`,
  `/wp-admin/` on a non-WordPress site) — recon, not necessarily compromise
- New URLs returning `200` that never existed before (a dropped script)
- Responses to unknown clients with unusually large bodies (data being pulled out)

## 3 · Host checks (class C and D)

Only on a host you are authorised to inspect. **Preserve first**: snapshot the
disk or image, and save volatile state (process list, connections) before
changing anything.

```bash
# Processes: web workers must not spawn shells or download tools.
ps -eo pid,ppid,user,etime,cmd --forest | grep -E 'php|httpd|apache2|nginx|node|gunicorn' -A3

# Specific tell: a shell or fetcher whose parent is a web worker
ps -eo pid,ppid,comm | awk '$3 ~ /^(sh|bash|dash|curl|wget|nc|ncat|python|perl)$/ {print}' |
  while read pid ppid comm; do echo "$comm pid=$pid parent=$(ps -o comm= -p $ppid)"; done

# Unexpected outbound connections from the web user
ss -tnp 2>/dev/null | grep -E 'php|httpd|apache|nginx|node'

# Files recently changed in web-served, upload and temp directories
find /var/www /srv /tmp /var/tmp -type f -mtime -14 \( -name '*.php' -o -name '*.phtml' -o -name '*.phar' -o -name '*.sh' -o -name '.*' \) 2>/dev/null | head -50

# Persistence: scheduled jobs, startup, keys, users
crontab -l; ls -la /etc/cron.* /var/spool/cron 2>/dev/null
ls -la ~/.ssh/authorized_keys /root/.ssh/authorized_keys 2>/dev/null
awk -F: '$3==0{print}' /etc/passwd          # extra uid 0 accounts
last -n 20; lastb -n 20 2>/dev/null
```

**Crashes are a signal.** Memory-corruption exploits often fail before they
succeed. Search the web-server and PHP-FPM logs and the kernel log for workers
killed by a signal (segmentation fault / signal 11), out-of-memory kills, and
restarts that cluster in time or by client. This is an inference from how the
bug class behaves, not a guaranteed indicator — absence of crashes proves
nothing.

**Containers and PaaS.** You often cannot shell into a managed host. Use what
the platform gives you: deployment history (who deployed what, when), build and
runtime logs, the list of variables and their last-changed times, and
egress/metrics graphs. Compare the running image digest with the one your
pipeline built. If you cannot establish that it is clean, redeploy from a
patched, rebuilt image — containers are cheap to replace.

## 4 · Persistence checklist

An attacker who got code execution once usually leaves a way back:

- [ ] New or modified files in webroot, upload, cache and temp directories
- [ ] New users, API tokens, SSH keys, deploy keys, OAuth grants
- [ ] New scheduled jobs, systemd units, startup scripts, container entrypoints
- [ ] Modified application code or config (compare to the Git commit / image)
- [ ] New webhooks (Git host, payment provider, CMS)
- [ ] New admin accounts inside the application itself
- [ ] Changed DNS records, email forwarding or auto-forward rules
- [ ] Modified CI workflow files or new CI secrets
- [ ] Altered `composer.json` / `package.json` scripts, or new dependencies

## 5 · Canaries — make the next breach loud

Cheap, high-signal, add after the incident:

- **Canary credentials**: a fake cloud key or API token in a place an attacker
  would look (env, `.env.bak`), wired to alert if used. Free services exist; or
  a real least-privilege key with zero permissions and alerting on any call.
- **Honey records** in the database that no legitimate code path reads.
- **Alerts on high-signal events**: new IAM key created, new deploy key, login
  from a new country to an admin account, a web worker spawning a shell.

## 6 · Writing the finding

Hunt results go in the same shape as every other finding — including negative
results:

```markdown
### Hunt: AWS CloudTrail for rotated key AKIA… — P1
**Window**      2026-10-17 00:00 UTC → 2026-10-23 12:00 UTC
**Method**      LookupEvents by access key id, all regions
**Result**      <N> calls, all from the known NAT egress IPs | 3 calls from <ip> — unexplained
**Confidence**  CONFIRMED (read from provider log)
**Next**        <follow the unexplained calls | close>
```

If a log source was not available or retention was too short to cover the
window, say so under **"What I could not verify"** — a gap in logs is a gap in
your confidence.
