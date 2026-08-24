#!/usr/bin/env node
/**
 * Devleck Senior Engineer Skills — repository validator.
 *
 * Checks structure and frontmatter for every skill, command and agent, verifies
 * the plugin manifests, and confirms that files referenced from a SKILL.md
 * actually exist. No dependencies.
 *
 *   node .github/scripts/validate.mjs
 *
 * Exit 0 = clean, 1 = errors.
 */

import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const errors = [];
const warnings = [];
const err = (m) => errors.push(m);
const warn = (m) => warnings.push(m);

const C = { red: "\x1b[31m", yel: "\x1b[33m", grn: "\x1b[32m", dim: "\x1b[2m", bld: "\x1b[1m", off: "\x1b[0m" };

/** Minimal YAML frontmatter reader — sufficient for the flat keys we use. */
function frontmatter(text, file) {
  if (!text.startsWith("---\n")) {
    err(`${file}: missing YAML frontmatter (must start with '---')`);
    return null;
  }
  const end = text.indexOf("\n---", 3);
  if (end === -1) {
    err(`${file}: frontmatter is not closed with '---'`);
    return null;
  }
  const block = text.slice(4, end);
  const out = {};
  let key = null;
  for (const raw of block.split("\n")) {
    const m = raw.match(/^([A-Za-z][\w-]*):\s?(.*)$/);
    if (m) {
      key = m[1];
      out[key] = m[2].trim();
    } else if (key && /^\s+\S/.test(raw)) {
      out[key] = `${out[key]} ${raw.trim()}`.trim();   // folded continuation
    }
  }
  return out;
}

const dirs = (p) =>
  existsSync(p) ? readdirSync(p).filter((d) => statSync(join(p, d)).isDirectory()) : [];
const files = (p, ext) =>
  existsSync(p) ? readdirSync(p).filter((f) => f.endsWith(ext)) : [];

// ── Skills ───────────────────────────────────────────────────────────────────
const skillsDir = join(ROOT, "skills");
const skillNames = dirs(skillsDir).sort();

if (skillNames.length === 0) err("skills/: no skill directories found");

for (const name of skillNames) {
  const dir = join(skillsDir, name);
  const skillPath = join(dir, "SKILL.md");
  const rel = `skills/${name}/SKILL.md`;

  if (!existsSync(skillPath)) {
    err(`skills/${name}/: no SKILL.md`);
    continue;
  }

  const text = readFileSync(skillPath, "utf8");
  const fm = frontmatter(text, rel);
  if (!fm) continue;

  if (!fm.name) err(`${rel}: frontmatter has no 'name'`);
  else if (fm.name !== name) err(`${rel}: name '${fm.name}' does not match directory '${name}'`);

  if (!fm.description) {
    err(`${rel}: frontmatter has no 'description' — the skill will never activate`);
  } else {
    if (fm.description.length < 80)
      warn(`${rel}: description is only ${fm.description.length} chars — likely too narrow to activate reliably`);
    if (fm.description.length > 1400)
      warn(`${rel}: description is ${fm.description.length} chars — consider trimming`);
    if (!/use when|use this|load when/i.test(fm.description))
      warn(`${rel}: description does not state WHEN to use the skill`);
  }

  const body = text.slice(text.indexOf("\n---", 3) + 4);
  const lines = body.split("\n").length;
  if (lines > 420) warn(`${rel}: body is ${lines} lines — push depth into references/`);
  if (lines < 30) warn(`${rel}: body is only ${lines} lines — is it finished?`);

  // Referenced files must exist
  const refs = body.match(/`(references|templates|scripts)\/[A-Za-z0-9._{},-]+`/g) ?? [];
  for (const raw of refs) {
    const ref = raw.slice(1, -1);
    // Expand a brace group like scripts/recon.{sh,ps1}
    const brace = ref.match(/^(.*)\{([^}]+)\}(.*)$/);
    const candidates = brace
      ? brace[2].split(",").map((x) => `${brace[1]}${x}${brace[3]}`)
      : [ref];
    for (const c of candidates) {
      if (!existsSync(join(dir, c))) err(`${rel}: references '${c}', which does not exist`);
    }
  }

  // Scripts must ship in both flavours
  const scriptDir = join(dir, "scripts");
  if (existsSync(scriptDir)) {
    for (const sh of files(scriptDir, ".sh")) {
      const ps1 = sh.replace(/\.sh$/, ".ps1");
      if (!existsSync(join(scriptDir, ps1)))
        warn(`skills/${name}/scripts/: ${sh} has no PowerShell counterpart`);
    }
  }
}

// ── Commands ─────────────────────────────────────────────────────────────────
for (const f of files(join(ROOT, "commands"), ".md")) {
  const rel = `commands/${f}`;
  const fm = frontmatter(readFileSync(join(ROOT, "commands", f), "utf8"), rel);
  if (!fm) continue;
  if (!fm.description) err(`${rel}: frontmatter has no 'description'`);
}

// ── Agents ───────────────────────────────────────────────────────────────────
for (const f of files(join(ROOT, "agents"), ".md")) {
  const rel = `agents/${f}`;
  const fm = frontmatter(readFileSync(join(ROOT, "agents", f), "utf8"), rel);
  if (!fm) continue;
  if (!fm.name) err(`${rel}: frontmatter has no 'name'`);
  else if (fm.name !== f.replace(/\.md$/, ""))
    err(`${rel}: name '${fm.name}' does not match the filename`);
  if (!fm.description) err(`${rel}: frontmatter has no 'description'`);
}

// ── Manifests ────────────────────────────────────────────────────────────────
let marketplace = null;
for (const p of [".claude-plugin/marketplace.json", ".claude-plugin/plugin.json"]) {
  const full = join(ROOT, p);
  if (!existsSync(full)) { err(`${p}: missing`); continue; }
  try {
    const json = JSON.parse(readFileSync(full, "utf8"));
    if (p.endsWith("marketplace.json")) {
      marketplace = json;
      if (!json.name) err(`${p}: no 'name'`);
      if (!Array.isArray(json.plugins) || json.plugins.length === 0) err(`${p}: no 'plugins'`);
    } else {
      if (!json.name) err(`${p}: no 'name'`);
      if (!json.version) err(`${p}: no 'version'`);
      for (const [key, dir] of [["skills", "skills"], ["commands", "commands"], ["agents", "agents"]]) {
        if (json[key] && !existsSync(join(ROOT, dir))) err(`${p}: declares '${key}' but ${dir}/ does not exist`);
      }
    }
  } catch (e) {
    err(`${p}: invalid JSON — ${e.message}`);
  }
}

// ── Required repository files ────────────────────────────────────────────────
for (const f of ["README.md", "README.es.md", "LICENSE", "CONTRIBUTING.md",
                 "SECURITY.md", "CHANGELOG.md", "AGENTS.md", ".gitignore",
                 "install.sh", "install.ps1", "assets/banner.svg", "assets/mark.svg"]) {
  if (!existsSync(join(ROOT, f))) err(`${f}: missing`);
}

// The installer's skill list must match what actually ships
const installer = existsSync(join(ROOT, "install.sh")) ? readFileSync(join(ROOT, "install.sh"), "utf8") : "";
for (const name of skillNames) {
  if (installer && !installer.includes(name)) err(`install.sh: does not list the skill '${name}'`);
}

// ── Report ───────────────────────────────────────────────────────────────────
console.log("");
console.log(`${C.bld}  Devleck · repository validation${C.off}`);
console.log(`${C.dim}  ${skillNames.length} skills · ${files(join(ROOT, "commands"), ".md").length} commands · ${files(join(ROOT, "agents"), ".md").length} agents${C.off}`);
console.log("");

for (const w of warnings) console.log(`  ${C.yel}warn${C.off}  ${w}`);
for (const e of errors)   console.log(`  ${C.red}FAIL${C.off}  ${e}`);

console.log("");
if (errors.length) {
  console.log(`  ${C.red}${errors.length} error(s)${C.off}, ${warnings.length} warning(s)`);
  console.log("");
  process.exit(1);
}
console.log(`  ${C.grn}Valid.${C.off} ${warnings.length} warning(s).`);
console.log("");
