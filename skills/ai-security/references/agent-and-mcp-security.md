# Agent, MCP and coding-assistant security

Agents act. That makes every injected sentence a potential action. This document
covers how to run agents, tool servers (MCP) and AI coding assistants so that a
tricked model has little to work with.

---

## 1 · Principles

1. **Least privilege, per task.** Tools, files, network and credentials sized to the
   current job — not the developer's whole machine.
2. **Isolation.** Run the agent where a mistake is cheap: a container, VM, or
   disposable workspace, not the host with your cloud credentials loaded.
3. **Approval for the irreversible.** Show the actual command/URL/payload, not a
   summary the model wrote.
4. **No ambient secrets.** Don't export cloud keys, `.env` files or tokens into
   the agent's environment. Give it scoped, short-lived ones if it needs any.
5. **Assume the content it reads is hostile** — issues, READMEs, web pages, logs,
   dependency docs, code comments, tool outputs.
6. **Everything is logged and reviewable** — commands run, files changed, network calls.

## 2 · Running a coding agent safely

```
[ ] Work in a branch or worktree; never directly on main/production
[ ] Sandbox or container with: no cloud credentials, no SSH agent forwarding, no
    access to ~/.aws ~/.ssh ~/.config unrelated to the task
[ ] Network egress limited to what the task needs (package registry, git remote)
[ ] Permission mode: ask before shell commands that write, delete, install or
    access the network; allowlist only read-only commands
[ ] Never auto-approve commands containing `curl | sh`, `rm -rf`, `sudo`, `chmod -R`,
    `git push --force`, credential files, or unknown package installs
[ ] Review diffs before commit; pay attention to CI workflows, package scripts,
    lockfiles, .env handling, auth code, and new dependencies — the places an
    injected instruction would plant something
[ ] Dependencies the agent adds are checked: exists, maintained, expected name
    (typosquats and hallucinated package names are a real attack route)
[ ] Pre-commit secret scanning stays on
[ ] Production access is not available from the agent's environment — ever
```

**Slopsquatting / hallucinated packages:** models sometimes invent package names;
attackers register them. Before installing a package an agent suggests, confirm it
is the real, established one (publisher, download history, repository) and check
the lockfile diff.

## 3 · Repository instruction files are code

`AGENTS.md`, `CLAUDE.md`, `.cursorrules`, skill files, prompt templates and
workflow definitions are loaded into the agent's context and obeyed with high
trust. Therefore:

- Review them in pull requests with the same care as scripts.
- Treat a change to them in an **untrusted PR** as hostile by default. Look for
  hidden text: invisible/zero-width Unicode, HTML comments, very long lines,
  base64 blobs, instructions that fetch or run remote content.
- Don't let an agent with powerful tools process instruction files from forks.
- Skills and plugins you install (including this suite): read the files, pin the
  version, and prefer sources where you can diff updates. Check that scripts only
  do what they claim — this suite's scripts are read-only by policy
  (`AGENTS.md`), and you should hold any other package to the same standard.

Search for invisible characters in instruction files:

```bash
grep -rnP '[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{2064}\x{FEFF}]' --include='*.md' --include='*.json' --include='*.yml' .
```

## 4 · MCP servers

An MCP server exposes tools (and resources, prompts) to the model. Security
properties come from how you choose and run it.

**Choosing**
- Prefer official or well-reviewed servers; read the source for the tools you enable.
- Check what credentials it requests and what it does with them.
- Enable only the tools you need; disable write/delete/execute tools by default.

**Running**
- Run locally-executed servers in a sandbox/container with only the directories and
  network they need. A "filesystem" server rooted at `$HOME` is a data-theft tool.
- Pass **scoped, per-server credentials** (a read-only token for a read-only task),
  never your personal admin token.
- Remote servers: use OAuth with scoped consent; know where data goes; review the
  vendor's security posture and incident history.
- Pin versions; update deliberately; diff tool descriptions on update (a
  "rug pull" changes behaviour after you approved the first version).

**Hostile-server model**
- Tool **descriptions and results are untrusted text** and can contain
  instructions aimed at the model ("tool poisoning").
- A malicious server can try to **shadow** a trusted server's tool or read other
  servers' context. Keep high-trust and low-trust servers in separate sessions.
- Do not enable servers that read external content (web, email, tickets) in the
  same session as servers with powerful write access to private systems — that is
  the three-way overlap from `SKILL.md` §2.

**Authoring your own MCP server**
```
[ ] Authenticate callers; authorise each tool call against the end user's rights
[ ] Validate all arguments with a schema; reject unknown fields
[ ] No generic "execute SQL/shell/URL" tools; narrow, purpose-built operations
[ ] Confine file access (resolve paths; deny traversal and symlink escape)
[ ] Rate-limit, time-limit and size-limit every tool
[ ] Never echo secrets in results or errors; redact logs
[ ] Return data, not instructions — don't put imperative text in tool results
[ ] Provide an allowlist for outbound requests (SSRF-safe)
[ ] Version and sign releases; publish a security contact
```

## 5 · Agent platforms you build

- Sandboxed code execution: no host mounts, no credentials, no metadata service
  access, CPU/memory/time limits, ephemeral filesystem, egress allowlist.
- Separate the **planner** (sees untrusted content, no powerful tools) from the
  **executor** (has tools, sees only validated structured plans).
- Per-user credentials flowing through (on-behalf-of tokens), never a shared
  service account with broad access.
- Per-session budgets (tokens, tool calls, wall-clock, spend) with hard stops.
- A visible audit trail users can inspect; a kill switch operators can pull.

## 6 · Detection

- Alert on agent processes spawning unexpected binaries, reading credential
  paths, or contacting new hosts.
- Canary credentials in the agent's reachable files — any use means the agent (or
  something steering it) went looking.
- Review agent transcripts after any incident; keep them for the retention you
  can justify, with secrets and personal data redacted.

## 7 · If you suspect an agent was manipulated

1. Stop the session and isolate the workspace.
2. Review commands run, files changed, network calls and any commits or pushes.
3. Assume any credential visible to that environment is exposed — rotate it
   (`security-incident-response`).
4. Identify the injected source (file, page, issue, tool result) and remove it.
5. Add the case to your tests and tighten permissions so it cannot act next time.
