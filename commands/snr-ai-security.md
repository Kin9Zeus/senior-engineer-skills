---
description: AI feature security review — prompt injection paths, agent permissions, output handling, data isolation, MCP/skill supply chain, provider-key and spend protection.
argument-hint: "[scope, e.g. 'the support chatbot' | 'agent tools' | 'MCP servers' | 'whole repo']"
---

# AI Security Review

Scope: **$ARGUMENTS** (default: every place the project calls a model, defines a
tool, or loads third-party skills / MCP servers).

Load the `ai-security` skill. Test only the user's own application.

## Order of work

```
1 Inventory     model calls · tools · data sources · MCP servers · plugins · where keys live
2 Keys & spend  scoped, per-env, hard caps, alerts, never client-side
3 Agency        each tool: reads / changes / reversible / who approves
4 Overlap       does any session combine private data + untrusted content +
                an outbound channel?  → break a leg in the design
5 Inputs        every path untrusted text reaches the model
6 Outputs       HTML/Markdown, SQL, shell, code, tool args — validated as untrusted
7 Isolation     tenants, memory, vector store, conversation history
8 Supply chain  models, MCP servers, skills, AGENTS.md / rules files — read before trusting
9 Test & watch  attack-suite evals in CI · canary strings · egress allowlist · alerts
```

## Evidence

Build the attack suite from `references/llm-threat-model.md` §3 and run each case
**several times** against staging, checking outcomes programmatically (tool called?
canary leaked? request left the network?). Report run counts and failure rates —
absence of a failure is not proof.

## Output

Findings in suite format; name the broken leg of the three-way overlap in each fix.
Include a tool-inventory table (tool · reads · writes · reversible · approval).
End with **What I could not verify**.
