# Contributing

Thanks for considering it. This repository has one job: make an AI assistant
produce engineering work that survives review. Every contribution is judged
against that.

**[English](CONTRIBUTING.md)** · [Español](#contribuir-español)

---

## The editorial standard

These are not style preferences. A skill that violates them makes the assistant
worse, because the assistant will follow it confidently.

### 1 · Every claim must be checkable

```
✗  "Add proper validation."
✓  "Validate the request body with a schema at the route boundary, rejecting
    unknown fields. Verify: post a body with an extra field, expect 422."
```

If a reader cannot tell whether they have complied, the instruction is not
finished.

### 2 · Every finding needs a verification step

The report format throughout this suite is **what is wrong → why it matters
concretely → the fix → how to verify the fix**. A finding without verification
is an opinion, and the skills say so. Keep it that way.

### 3 · Never fabricate

No invented version numbers, CVE identifiers, API signatures, benchmark figures
or statistics. If a fact changes over time — a framework's behaviour, an
advisory, a store policy — write the instruction as *check the current
documentation*, not as an assertion.

This is the rule most often broken by well-meaning contributions, and it is the
one that does the most damage: a confidently wrong CVE reference in a security
skill is worse than no skill.

### 4 · Prefer the boring, reversible recommendation

The suite deliberately refuses to recommend microservices, Kubernetes, event
sourcing or CQRS without the specific problem each solves. Premature complexity
is the most expensive advice available and the easiest to give, because it sounds
senior. Do not add it back.

### 5 · Defensive security only

Finding and fixing weaknesses in code the user owns or is authorised to assess.
No weaponised exploits. No instructions to scan or send traffic to
infrastructure without confirmed authorisation. Detections and fixes, always.

### 6 · Privacy content is not legal advice

Say so where it appears. Produce technical controls and documents drafted from
real data flows; recommend a qualified lawyer for regulated contexts. Never state
a legal conclusion as fact.

---

## Writing a skill

```
skills/<name>/
├── SKILL.md              required — frontmatter + focused body
├── references/*.md       loaded on demand, where the depth lives
├── templates/*.md        things a user can copy and fill in
└── scripts/*.{sh,ps1}    read-only helpers, both platforms
```

### Frontmatter

```yaml
---
name: kebab-case-matching-the-directory
description: >
  What it does, then the trigger vocabulary — the literal phrases a user would
  type. This is the ONLY part loaded up front, and it is what decides whether
  the skill activates at the right moment.
license: MIT
---
```

**The description is the whole activation mechanism.** Write it for matching, not
for elegance: include the words users actually type ("my site is slow", "not
showing up in Google", "delete my data"), not just the formal domain terms.

### Body

- **Keep `SKILL.md` focused** — roughly 150–300 lines. It is loaded in full when
  the skill triggers.
- **Push depth into `references/`.** Those load only when the skill decides it
  needs them. This is why a fifteen-skill suite costs almost no context.
- **Lead with the order of work**, not with a taxonomy. What do I do first, and
  why that first?
- **Give commands that run**, tables that can be worked through, and templates
  that can be filled in.
- **State the failure modes.** "This is what people get wrong here" is often the
  most valuable paragraph in a skill.

### Scripts

- Read-only. No network calls beyond explicitly-scoped HTTP checks against a URL
  the user supplied.
- Both `.sh` (POSIX, `bash -n` clean) and `.ps1` (PowerShell 5.1+, parser clean).
- No dependencies beyond `curl`, `grep`, `git` and the shell.
- **Everything they report is a lead, not a finding.** Say so in the output.
- Exit `0` clean, `1` findings, `2` usage error.

---

## Before you open a pull request

```bash
# Frontmatter and structure
node .github/scripts/validate.mjs      # or: the workflow will run it

# Shell scripts parse
bash -n skills/**/scripts/*.sh

# PowerShell scripts parse
pwsh -c '[System.Management.Automation.Language.Parser]::ParseFile("path",[ref]$null,[ref]$null)'

# JSON manifests parse
python -c "import json;[json.load(open(p)) for p in ['.claude-plugin/marketplace.json','.claude-plugin/plugin.json']]"
```

Then **test the skill in a real session.** Install it locally
(`./install.sh --project`), give the assistant a task that should trigger it, and
check that it does — and that the output is better than without it. A skill that
never triggers is dead weight; a skill that triggers and gives worse advice is
harmful.

---

## Pull requests

- **Small and focused.** One skill, or one coherent improvement.
- **Say what you tested.** "Ran `/snr-audit` against a Next.js repo with a known
  IDOR; it was found and correctly rated P0" is a useful PR body.
- **Both languages** if you change user-facing documentation: `README.md` and
  `README.es.md` stay in sync.
- **No generated slop.** If a section reads as filler, it is filler. Every
  paragraph should earn its place.

## Reporting problems

- **A skill gives bad advice** → open an issue with the prompt, the output, and
  what the correct answer would have been. This is the most valuable issue type.
- **A skill does not activate when it should** → tell us the exact phrasing you
  used. That is a description bug and it is easy to fix.
- **A security issue in this repository** → see [SECURITY.md](SECURITY.md). Do
  not open a public issue.

---
---

<a id="contribuir-español"></a>

# Contribuir (Español)

Gracias por planteártelo. Este repositorio tiene un objetivo: que un asistente de
IA produzca trabajo de ingeniería que sobreviva a una revisión. Cada contribución
se juzga contra eso.

## El estándar editorial

No son preferencias de estilo. Una skill que los incumple empeora al asistente,
porque el asistente la seguirá con confianza.

**1 · Toda afirmación debe ser comprobable.** Si quien lee no puede saber si la
ha cumplido, la instrucción no está terminada.

**2 · Todo hallazgo necesita un paso de verificación.** El formato en toda la
suite es: qué está mal → por qué importa concretamente → la corrección → cómo
verificar la corrección. Un hallazgo sin verificación es una opinión.

**3 · Nunca inventar.** Ningún número de versión, identificador CVE, firma de
API, benchmark ni estadística inventados. Si un dato cambia con el tiempo,
escribe la instrucción como *consulta la documentación actual*, no como una
afirmación. Es la regla que más se incumple y la que más daño hace.

**4 · Preferir la recomendación aburrida y reversible.** La suite se niega
deliberadamente a recomendar microservicios, Kubernetes, event sourcing o CQRS
sin el problema concreto que cada uno resuelve. La complejidad prematura es el
consejo más caro que existe y el más fácil de dar, porque suena senior.

**5 · Solo seguridad defensiva.** Encontrar y corregir debilidades en código que
se posee o se está autorizado a evaluar. Nada de exploits armados ni de escanear
infraestructura sin autorización confirmada.

**6 · El contenido de privacidad no es asesoramiento legal.** Dilo donde
aparezca. Produce controles técnicos y documentos redactados desde flujos de
datos reales; recomienda un abogado cualificado para contextos regulados.

## Escribir una skill

Estructura: `SKILL.md` (obligatorio) + `references/` (profundidad, se carga bajo
demanda) + `templates/` + `scripts/` (solo lectura, `.sh` y `.ps1`).

**La `description` del frontmatter es todo el mecanismo de activación.**
Escríbela para que coincida, no para que quede elegante: incluye las palabras que
la gente escribe de verdad ("mi web va lenta", "no aparezco en Google", "borrar
mis datos"), no solo los términos formales del dominio.

Mantén `SKILL.md` enfocado (150–300 líneas) y empuja la profundidad a
`references/`. Empieza por el **orden de trabajo**, no por una taxonomía. Da
comandos que se ejecutan, tablas que se recorren y plantillas que se rellenan.
Y describe los modos de fallo: "esto es lo que la gente hace mal aquí" suele ser
el párrafo más valioso de una skill.

## Antes de abrir un pull request

Valida el frontmatter, comprueba que los scripts parsean (`bash -n` y el parser
de PowerShell), y que los manifiestos JSON son válidos. Después **prueba la skill
en una sesión real**: instálala en local (`./install.sh --project`), dale al
asistente una tarea que debería activarla, y comprueba que se activa y que el
resultado es mejor que sin ella.

Los PR deben ser pequeños y enfocados, decir qué se probó, y mantener
`README.md` y `README.es.md` sincronizados si tocan documentación de usuario.

## Reportar problemas

- **Una skill da mal consejo** → abre un issue con el prompt, la salida y cuál
  habría sido la respuesta correcta. Es el tipo de issue más valioso.
- **Una skill no se activa cuando debería** → dinos la frase exacta que usaste.
  Es un fallo de `description` y se arregla fácil.
- **Un problema de seguridad en este repositorio** → ver [SECURITY.md](SECURITY.md).
  No abras un issue público.
