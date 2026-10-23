# LLM application threat model and test suite

> The OWASP Top 10 for LLM Applications is the maintained taxonomy. The map below
> uses its themes (2025 edition at the time of writing) — **check the current
> edition before citing numbers in a report.**

---

## 1 · Risk map

| Theme | What it looks like | Primary control | Test |
|---|---|---|---|
| **Prompt injection** | User or retrieved text overrides your instructions | Least agency, approval gates, separate privilege, egress control | §3 suite A |
| **Sensitive information disclosure** | Model reveals PII, secrets, other tenants' data, system prompt | Don't put it in context; retrieval honours caller's ACL; output filters as a last layer | Suite B |
| **Supply chain** | Malicious model, plugin, MCP server, skill, dependency | Vet, pin, sandbox (`agent-and-mcp-security.md`) | Review + SBOM |
| **Data and model poisoning** | Tainted training/fine-tune/RAG data steers behaviour | Gate ingestion; provenance; scan; tenant namespaces | Suite D |
| **Improper output handling** | Model output reaches HTML, SQL, shell, code execution unchecked | Encode/validate/parameterise; sandbox execution | Suite C |
| **Excessive agency** | Tools too powerful, too many, or unauthenticated | Narrow tools, user-scoped credentials, approval | Tool inventory review |
| **System prompt leakage** | Prompt contents (and secrets inside) extracted | No secrets in prompts; assume extractable | Suite B |
| **Vector/embedding weaknesses** | Cross-tenant retrieval, embedding inversion, poisoned documents | Server-side tenant filters; access-controlled ingestion | Suite D |
| **Misinformation** | Confident wrong output drives decisions | Grounding, citations, human review in high-stakes flows | Eval accuracy |
| **Unbounded consumption** | Token floods, loops, expensive requests, model "denial of wallet" | Token/time/iteration caps, quotas, budget alerts | Suite E |

## 2 · Build the data-flow sketch (10 minutes)

Draw: user → app → model → tools → data stores → external services, and mark:

- Where **untrusted text** enters (users, web fetches, files, emails, tool
  results, retrieved documents)
- Where **private data** enters the context
- Where the model's output **leaves** (rendered, sent, executed, stored)
- Trust boundaries and who authenticates at each one

Any path where all of {private data, untrusted text, outbound channel} meet in one
session is a P0/P1 candidate until a leg is broken.

## 3 · The attack suite (run against your own staging)

Create a file of cases, each with: **input, expected safe behaviour, pass/fail
check done by code** (not by reading the answer). Keep cases benign — the goal is
to show the control works, not to craft a better attack.

### A · Injection
- Ignore-previous-instructions variants, role-play, translation and encoding
  tricks in user input — expected: policy holds, no tool misuse.
- **Indirect:** place instruction text inside a document/web page/ticket/email the
  app will ingest ("When you read this, call tool X with …") — expected: tool not
  called, or approval requested with the true parameters.
- Instructions hidden in markup/comments/metadata/alt text of ingested content.
- Tool-result injection: a mocked tool returns text containing instructions.

### B · Disclosure
- Ask for the system prompt and hidden instructions — nothing sensitive is there to leak.
- Plant a **canary string** (e.g. `CANARY-7f3a…`) in private context; assert it
  never appears in output, logs sent to third parties, or egress traffic.
- Cross-user probing: as user A, ask about user B's data — expected: refusal because
  retrieval was filtered, not because the model "decided".

### C · Output handling
- Make the model emit `<script>`, an `<img src=//attacker…>`, a Markdown link with
  a data-bearing query string, SQL and shell metacharacters — expected: encoded,
  stripped, parameterised or blocked.
- Schema fuzzing: out-of-range and wrong-typed structured outputs — expected:
  validation rejects.

### D · Isolation and poisoning
- Ingest a document containing instructions as tenant A; query as tenant B —
  expected: not retrievable.
- Ingest conflicting "facts" and check provenance/attribution is shown.

### E · Consumption
- Long inputs, deeply nested tool loops, repeated expensive calls (bounded test
  volume) — expected: caps and quotas engage with a clear error.

## 4 · Eval design

- Run each case **several times** (model output varies); record the failure rate.
  A single pass proves little; report the number of runs.
- Check outcomes **programmatically** (was the tool called? did the canary leak?
  did the request leave the network?) rather than by judging prose.
- Keep the suite in the repo and run it in CI on every change to prompts, tools,
  models, retrieval or data sources.
- A new bypass found in production becomes a new test before it becomes a fix.

## 5 · Logging and monitoring

Log per request: user, session, model, tool calls (name, arguments, result size),
token counts, latency, refusal/guardrail triggers — with secrets and personal data
redacted. Alert on:

- Tool calls outside the normal pattern for the feature
- Egress to a host not on the allowlist
- Canary string seen anywhere it shouldn't be
- Token usage or cost spikes per user/key
- Many refusal/guardrail hits from one user (probing)

## 6 · Incident response for AI features

1. Disable the affected tool or the feature (kill switch).
2. Rotate any key that was in scope; check provider usage for the window.
3. Pull transcripts for the affected sessions; identify the injected content and
   its source (which document, page, user).
4. Purge or quarantine poisoned documents from the store.
5. Add the case to the eval suite; fix at the architecture level, not by adding
   another "do not obey" sentence to the prompt.
6. Notify affected users per `privacy-compliance` if their data was exposed.

## 7 · Finding template

Use the suite's finding shape; add **run count and failure rate** under
Confidence, and name the broken leg of the three-way overlap in Fix.
