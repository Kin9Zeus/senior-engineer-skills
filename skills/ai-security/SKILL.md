---
name: ai-security
description: Security for AI-powered software — LLM applications, agents, tool calling, RAG, MCP servers and AI-assisted coding. Covers prompt injection (direct and indirect), excessive agency, output handling, data leakage, vector-store tenant isolation, AI-provider key theft and spend abuse, supply chain for models, plugins and skills, and testing and monitoring of AI features. Use when the user says "prompt injection", "jailbreak", "secure my chatbot", "LLM security", "AI agent security", "MCP security", "tool calling safe", "RAG security", "OWASP LLM", "system prompt leak", "AI API key leaked", "unexpected OpenAI bill", "unexpected Anthropic bill", "agent permissions", "can the agent be tricked", "AI inference provider attack" or "is it safe to give the agent shell access"; when a project calls an LLM API, defines tools or agents, runs an MCP server, or loads third-party skills or plugins; and as a pass in any audit of an AI feature. Defensive security only. By Devleck.
license: MIT
---

# AI Security

A language model cannot reliably tell instructions from data. Everything below
follows from that one fact: **any text the model reads can steer it, and anything
the model can do, an attacker who controls that text can try to do.**

Two threats are current and concrete: **attacks on the AI feature itself**
(prompt injection, over-powered agents) and **attacks on the keys and accounts
behind it** — AI-provider keys are monetisable on sight, and platform breaches have
been reported to target AI inference providers specifically (see
`security-incident-response`).

**Scope:** AI features in software the user owns or is authorised to assess.
Testing prompts against the user's own application is in scope; attacking
third-party AI services or other people's deployments is not.

> Taxonomies change. The OWASP Top 10 for LLM Applications is the maintained
> reference — check its current edition rather than quoting category numbers
> from memory.

---

## 1 · The order of work

```
 1  INVENTORY    every model call, tool, data source, MCP server, plugin; where each key lives
 2  KEYS & SPEND provider keys scoped, per-environment, capped, monitored
 3  AGENCY       what can the AI do? reduce it to what it needs; gate the irreversible
 4  DATA FLOWS   find the three-way overlap (below); break at least one leg
 5  INPUT PATHS  every place untrusted text reaches the model (users, web, files, email, tool results, RAG)
 6  OUTPUT       treat model output as untrusted input to the rest of the system
 7  ISOLATION    tenants, memory, vector stores, conversation history
 8  SUPPLY CHAIN models, plugins, MCP servers, skills, prompt files — all of it is code
 9  TEST & WATCH red-team your own app; regression evals; alert on abuse
```

## 2 · The three-way overlap that makes exfiltration possible

An AI feature is in serious danger when **one session** combines all three:

1. **Access to private data** (user data, secrets, internal documents)
2. **Exposure to untrusted content** (web pages, emails, uploaded files, issue
   text, retrieved documents, other users' input)
3. **A way to communicate externally** (HTTP requests, email, rendering images or
   links, writing to a shared place)

With all three, injected text in (2) can instruct the model to read (1) and send
it out via (3). **You cannot rely on the prompt to prevent this.** Break a leg in
the design: remove external communication, strip private data from sessions that
read untrusted content, or require human approval at the exfiltration step.

## 3 · Prompt injection — direct and indirect

- **Direct:** the user types instructions that override yours.
- **Indirect:** instructions hidden in content the model *retrieves* — a web page,
  a PDF, an email, a code comment, a tool result, an image's text, a repository
  file. The user never typed them.

There is no complete filter. Effective controls are architectural:

| Control | How |
|---|---|
| **Least agency** | The model gets the smallest tool set that does the job; read-only wherever possible |
| **Separate privilege** | The component that reads untrusted content has no powerful tools; the component with tools never reads raw untrusted content |
| **Human approval for irreversible actions** | Sending, paying, deleting, publishing, deploying, running commands — confirmation shows the *actual* action and parameters, not the model's description of it |
| **Constrained outputs** | Structured output with a schema validated by code; the model proposes, code disposes |
| **No secrets in context** | Keys and credentials never enter prompts, tool descriptions, or logs the model can read |
| **Marked, minimised context** | Delimit untrusted content, say it is data; this reduces but does not eliminate risk |
| **Egress control** | The runtime can only call an allowlist of hosts; links and images from model output are not auto-fetched |

## 4 · Excessive agency — agents and tools

For every tool the model can call, record: what it can read, what it can change,
whether the effect is reversible, and who approves it.

```
[ ] Tools are narrow (one purpose, validated arguments), not "run any SQL / any shell / any URL"
[ ] Credentials the tool uses belong to the END USER's authority, not a super-account
[ ] Authorization is checked by the tool/server per call, never delegated to the model
[ ] Dangerous tools (shell, filesystem write, network, payments, email send) need approval
[ ] File access confined to a working directory (resolve paths, deny `..` and symlinks out)
[ ] Network access from agent sandboxes limited to an allowlist
[ ] Rate and budget limits per session, per user, per day
[ ] Every tool call is logged with the user, arguments and result (minus secrets)
[ ] A kill switch exists and is tested
```

Coding agents and shells deserve special care: an agent that can run commands
and read untrusted repository text can be instructed by that text. Run them in
sandboxes, without production credentials, with network and filesystem scope
limited, and review diffs before they are applied.

## 5 · Output handling

The model's output is attacker-influenced input to everything downstream.

- HTML/Markdown rendering → XSS and data exfiltration via image/link URLs. Encode;
  sanitise Markdown; do not auto-load remote images from model output.
- SQL or shell built from model output → injection. Parameterise; never execute
  generated commands without approval and sandboxing.
- Generated code → treat as untrusted until reviewed and tested.
- Structured output → validate against a schema and range-check before use.
- Tool arguments → validate server-side exactly like user-supplied parameters.

## 6 · Data leakage and isolation

- Don't put data in the context the current user may not see. Retrieval must apply
  the **requesting user's access controls**, not the application's.
- **Vector stores / RAG:** per-tenant namespaces or filters enforced server-side;
  ingestion is an attack path (poisoned documents) — scan, attribute and gate who
  can add documents.
- **Conversation memory** is user data: scope it per user, give it retention and
  deletion (`privacy-compliance`), and never let one user's memory enter
  another's context.
- **System prompts are not secrets.** Assume they can be extracted; keep keys and
  confidential logic out of them.
- **Logging:** log enough to investigate; redact secrets and personal data;
  restrict who reads transcripts.

## 7 · Keys, spend and abuse

- One provider key **per environment and per service**; project- or workspace-scoped
  keys where the provider supports them.
- **Hard monthly budget and per-key rate limits** set at the provider, plus an
  application-level quota per user.
- Keys never in client code, mobile apps, repositories, prompts or logs; call the
  provider from your backend only.
- Alerts on usage anomalies: unfamiliar models, regions, request volume, off-hours
  traffic, new keys on the account.
- After any provider or platform incident: rotate, then review usage for the
  exposure window (`security-incident-response`).
- Bound cost per request: max input/output tokens, max tool-loop iterations,
  timeouts — an unbounded loop is both an outage and a bill.

## 8 · Supply chain — models, plugins, MCP servers, skills

Instructions are code. A skill, a prompt file, an `AGENTS.md`/`CLAUDE.md`, an MCP
server's tool descriptions and a plugin all steer the agent that loads them.

```
[ ] Install skills/plugins/MCP servers only from sources you can inspect; read them first
[ ] Pin versions or commit SHAs; review diffs on update
[ ] MCP servers: least-privilege credentials, scoped tools, no ambient access to
    unrelated secrets or the whole filesystem, running in a sandbox where possible
[ ] Tool descriptions from third-party servers are untrusted text (they can contain instructions)
[ ] Do not auto-approve tool calls for servers that read external content
[ ] Third-party models/weights from trusted registries, hashes verified; avoid pickle-based formats from unknown sources
[ ] Repository instruction files (AGENTS.md, CLAUDE.md, rules files) reviewed in PRs like code
```

Details: `references/agent-and-mcp-security.md`.

## 9 · Testing and monitoring

Test **your own** AI features: build a small attack suite (`references/llm-threat-model.md`
§tests), run it in CI as a regression eval, and re-run when prompts, tools,
models or data sources change. Monitor in production for: tool-call anomalies,
refusal/override patterns, unusual token use, outbound requests to new hosts,
and canary strings (a fake secret planted in private context that should never
appear in output or egress).

## 10 · What people get wrong

- **Trusting the system prompt to enforce security.** Prompts are suggestions.
  Enforcement lives in code, permissions and the network.
- **Giving the agent the developer's credentials** "to make it work".
- **Treating retrieved content as safe** because "it's our data" — it includes
  user-submitted and scraped text.
- **Authorisation by the model** ("only show this user their invoices") instead of
  by the data layer.
- **Rendering model output as HTML/Markdown with remote images** — the quiet
  exfiltration channel.
- **No spend cap.** A leaked key or a runaway loop is a five-figure surprise.
- **Auto-approving everything** after the first week because the prompts are
  annoying.
- **Treating a skill or MCP server as documentation** when it is executable
  influence.

## 11 · Report format

```markdown
### Support agent can send customer data to any URL after reading ticket text — P0
**Class**       Indirect prompt injection → data exfiltration (private data + untrusted content + external send)
**Location**    agent/tools/http_post.ts; tickets are inserted into context unfiltered
**Confidence**  CONFIRMED (staging: a ticket containing instructions caused a POST of the customer record to a test endpoint we control)
**Impact**      Any customer who files a ticket can make the agent leak other customers' data.
**Fix**         Remove the generic HTTP tool; allowlist destinations; require approval for external sends; strip customer PII from sessions that read raw ticket text.
**Verify**      The eval "ticket-injection-01" must fail on current code and pass after; egress to non-allowlisted hosts is blocked at the network layer.
```

End with **"What I could not verify"** (model behaviour is probabilistic: say how
many runs you did and that absence of a failure is not proof).

---

## References

- `references/llm-threat-model.md` — OWASP-style risk map, attack suite and eval design
- `references/agent-and-mcp-security.md` — sandboxing, permissions, MCP server and skill vetting, coding-agent safety
- Related skills: `security-hardening`, `cloud-security`, `security-incident-response`, `pentest-methodology`, `privacy-compliance`
