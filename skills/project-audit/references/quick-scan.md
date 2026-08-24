# Quick Scan — the 30-minute audit

For a first look, a small project, or a triage before committing to a full
audit. It answers one question: **is there anything here that must be fixed
before this touches a real user?**

It is not a substitute for the full audit. Say so explicitly in the output.

---

## The seven checks, in order of expected yield

### 1. Secrets (5 min) — highest yield of any check

```bash
git log --all --full-history --name-only -- '*.env' '*.pem' '*.key' '*.p12' '*credential*' '*secret*' | head -30

grep -rEn '(sk_live_|pk_live_|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_|xox[baprs]-|AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----)' . \
  --exclude-dir={node_modules,.git,dist,build,vendor,.next,target} | head -30

git ls-files | grep -E '(^|/)\.env($|\.)' | grep -v example
```

Any hit is a **P0**. The remediation order is always: rotate the credential,
*then* clean the history.

### 2. Authorization on the hottest routes (7 min) — highest severity of any check

Pick the three routes that return or modify user-owned data. For each, trace to
the data access and answer: **is the query scoped to the authenticated user?**

```bash
# Find the pattern that signals unscoped lookup
grep -rEn 'findById|findByPk|\.get\(pk=|Model\.find\(|findOne\(\{ *_?id|SELECT \* FROM [a-z_]+ WHERE id' \
  --exclude-dir={node_modules,.git,dist,vendor} . | head -30
```

A lookup by id with no ownership predicate, on an authenticated route, is an
IDOR — **P0**. Confirm by reading the surrounding handler before calling it;
the scope may be applied in a repository layer.

### 3. Injection (4 min)

```bash
# String-built SQL
grep -rEn "(query|execute|raw|exec)\s*\(\s*[\"\`'].*(\\\$\{|\+ *[a-zA-Z_]|%s|f[\"'])" \
  --exclude-dir={node_modules,.git,vendor} . | head -20

# Command execution with interpolation
grep -rEn "(exec|execSync|spawn|system|popen|os\.system|subprocess\.(call|run|Popen))\s*\(" \
  --exclude-dir={node_modules,.git,vendor} . | head -20

# Raw HTML sinks
grep -rEn 'dangerouslySetInnerHTML|v-html|innerHTML\s*=|\|\s*safe|html_safe|\braw\(' \
  --exclude-dir={node_modules,.git,dist} . | head -20
```

### 4. Data survivability (4 min)

Three questions, answered or marked `UNKNOWN`:
- Are there automated backups? Where, how often, retained how long?
- Has a restore ever been performed successfully?
- Are migrations versioned and reversible?

No backups on a system holding real user data is a **P0**. Backups never
restored is a **P1** — the capability is unverified, which is not the same as
present.

### 5. Public surface sanity (4 min)

If there is a live URL:

```bash
URL=https://example.com
curl -sSI "$URL" | grep -Ei 'strict-transport|content-security|x-frame|x-content-type|referrer-policy|server|x-powered-by'
curl -sS -o /dev/null -w '%{http_code}\n' "$URL/definitely-not-a-real-page-xyz"   # want 404, not 200
curl -sS "$URL/robots.txt" | head -20
curl -sS "$URL" | grep -Eio '<title>[^<]*</title>|<meta name="description"[^>]*>' | head
```

A soft-404 (200 for a missing page) is a **P2** SEO finding. A missing CSP with
user-generated content is a **P1**. `X-Powered-By` disclosing versions is a P3
on its own but a signal that no hardening pass was done.

### 6. Correctness signal (3 min)

```bash
find . -type d \( -name test -o -name tests -o -name __tests__ -o -name spec \) -not -path '*/node_modules/*' | head
ls .github/workflows .gitlab-ci.yml 2>/dev/null && grep -l 'test' .github/workflows/* 2>/dev/null
grep -rn 'TODO\|FIXME\|HACK' --include='*auth*' --include='*payment*' --include='*billing*' --include='*admin*' . | head
```

Zero tests on a system handling money or personal data is a **P1**. Tests that
exist but are not gated in CI is a **P2**.

### 7. Honest promises (3 min)

```bash
find . -iname '*privacy*' -o -iname '*cookie*' -o -iname '*terms*' | grep -v node_modules | head
grep -rEo 'googletagmanager|google-analytics|gtag|facebook\.net|hotjar|segment|mixpanel|posthog|intercom|clarity\.ms|fonts\.googleapis' \
  --exclude-dir={node_modules,.git} . | sort -u | head -20
```

Compare the second list to what the privacy policy names. A processor receiving
personal data that the policy omits is a **P1** — it is a misrepresentation to
users and a regulatory exposure, not merely a documentation gap.

---

## Quick-scan output

Keep it to one screen. Anything longer means running the full audit instead.

```markdown
## Quick Scan — <project> (<commit>)

**Scope:** static read-only review, ~30 min. NOT a full audit.

**Verdict:** <one sentence: safe to continue / stop and fix first>

**Blockers (P0)**
1. <finding> — `file:line` — <consequence> — <fix>

**Critical (P1)**
1. ...

**Checked and clean:** <the checks that passed, named>
**Not checked:** <what a full audit would cover that this did not>

**Recommendation:** <fix the blockers / proceed to a full audit / this is fine>
```

The **"Checked and clean"** line matters as much as the findings — without it
the reader cannot distinguish "we looked and it was fine" from "we did not
look".
