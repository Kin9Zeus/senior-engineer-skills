# Security Policy

**[English](#reporting-a-vulnerability)** · **[Español](#reportar-una-vulnerabilidad)**

---

## Scope

This repository contains **Markdown skill definitions and read-only shell
scripts**. It has no runtime, no server, no dependencies and no data. The
realistic security surface is:

1. **The scripts.** `recon.sh`, `secret-scan.sh`, `web-check.sh`,
   `rotation-inventory.sh`, `php-check.sh` and `scope-guard.sh` (and their
   PowerShell equivalents) run on a contributor's machine and read their files.
   `rotation-inventory` must never print a secret value, and `scope-guard` must
   never approve a target outside its scope file or after its expiry date — a flaw
   in either is a genuine vulnerability.
   A command-injection or path-traversal flaw in one of them would be a genuine
   vulnerability.
2. **The guidance.** A skill that instructs an assistant to do something unsafe —
   disable TLS verification, log a secret, weaken a control, or scan
   infrastructure without authorisation — is a security defect in this
   repository, and we treat it as one.
3. **The supply chain.** A malicious pull request that adds a script phoning
   home, or guidance that quietly exfiltrates code or credentials.

## Reporting a vulnerability

**Do not open a public issue.**

Use GitHub's private reporting: **Security → Report a vulnerability** on
[this repository](https://github.com/Kin9Zeus/senior-engineer-skills/security).

Please include:

- What the problem is, and which file
- How to reproduce or demonstrate it
- What an attacker could achieve
- A suggested fix, if you have one

**What to expect**

| | |
|---|---|
| Acknowledgement | Within 3 business days |
| Initial assessment | Within 7 days |
| Fix for a confirmed high-severity issue | As fast as we can, and we will keep you updated |
| Credit | In the release notes, unless you prefer otherwise |

We will not take legal action against anyone reporting in good faith under this
policy.

## What is not a vulnerability here

- **A skill giving advice you disagree with.** That is an issue or a pull
  request, and both are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
- **The scripts flagging false positives.** They are documented as triage aids
  that produce leads, not findings.
- **The security content describing attack classes.** The skills teach defensive
  identification and remediation. That is the point.
- **A vulnerability in *your* project that our skills did not find.** These
  skills reduce the chance of shipping a defect; they are not a guarantee, and
  they do not replace a professional security assessment.

## Using these skills responsibly

The security guidance here is **defensive**: finding and fixing weaknesses in
code you own or are explicitly authorised to assess.

The skills instruct the assistant never to scan, probe or send traffic to
infrastructure without confirmed ownership or authorisation, and to produce
fixes and detections rather than weaponised exploits. **If you find guidance in
this repository that could be read otherwise, report it as a vulnerability** —
that is exactly the kind of defect this policy exists for.

---
---

<a id="reportar-una-vulnerabilidad"></a>

# Política de Seguridad (Español)

## Alcance

Este repositorio contiene **definiciones de skills en Markdown y scripts de solo
lectura**. No tiene runtime, servidor, dependencias ni datos. La superficie real
es:

1. **Los scripts.** `recon.sh`, `secret-scan.sh`, `web-check.sh`,
   `rotation-inventory.sh`, `php-check.sh` y `scope-guard.sh` (y sus
   equivalentes en PowerShell) se ejecutan en la máquina de quien los usa y leen
   sus archivos. Una inyección de comandos o un *path traversal* en ellos sería
   una vulnerabilidad real. `rotation-inventory` nunca debe imprimir el valor de
   un secreto, y `scope-guard` nunca debe aprobar un objetivo fuera de su archivo
   de alcance ni después de su fecha de caducidad: un fallo en cualquiera de los
   dos es una vulnerabilidad genuina.
2. **La guía.** Una skill que indique al asistente hacer algo inseguro
   —desactivar la verificación TLS, registrar un secreto, debilitar un control o
   escanear infraestructura sin autorización— es un defecto de seguridad de este
   repositorio y lo tratamos como tal.
3. **La cadena de suministro.** Un pull request malicioso que añada un script que
   llame a casa, o guía que exfiltre código o credenciales de forma encubierta.

## Reportar una vulnerabilidad

**No abras un issue público.**

Usa el reporte privado de GitHub: **Security → Report a vulnerability** en
[este repositorio](https://github.com/Kin9Zeus/senior-engineer-skills/security).

Incluye qué es el problema y en qué archivo, cómo reproducirlo, qué podría lograr
un atacante y, si la tienes, una corrección propuesta.

**Qué esperar:** acuse de recibo en 3 días hábiles, evaluación inicial en 7 días,
corrección de un problema grave confirmado lo antes posible con actualizaciones
por el camino, y crédito en las notas de versión salvo que prefieras lo
contrario.

No emprenderemos acciones legales contra quien reporte de buena fe bajo esta
política.

## Qué no es una vulnerabilidad aquí

- **Una skill que da un consejo con el que no estás de acuerdo.** Eso es un issue
  o un pull request, y ambos son bienvenidos.
- **Los scripts marcando falsos positivos.** Están documentados como ayudas de
  triaje que producen pistas, no hallazgos.
- **Que el contenido de seguridad describa clases de ataque.** Las skills enseñan
  identificación y remediación defensiva. Ese es el objetivo.
- **Una vulnerabilidad en *tu* proyecto que nuestras skills no encontraron.**
  Reducen la probabilidad de publicar un defecto; no son una garantía y no
  sustituyen una evaluación de seguridad profesional.

## Uso responsable

La guía de seguridad de este repositorio es **defensiva**: encontrar y corregir
debilidades en código que posees o estás explícitamente autorizado a evaluar.

Las skills instruyen al asistente para no escanear, sondear ni enviar tráfico a
infraestructura sin propiedad o autorización confirmada, y para producir
correcciones y detecciones en lugar de exploits armados. **Si encuentras en este
repositorio guía que pueda leerse de otro modo, repórtala como vulnerabilidad** —
es exactamente el tipo de defecto para el que existe esta política.
