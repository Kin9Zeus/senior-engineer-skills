<div align="center">

<img src="assets/banner.svg" alt="Devleck Senior Engineer Skills" width="100%">

# Senior Engineer Skills

**Convierte Claude Code en un equipo de ingeniería senior.**

Quince skills que auditan un proyecto existente en quince dominios, o construyen uno
nuevo con el estándar que superaría una *due diligence*, un test de penetración y la
revisión de una autoridad de protección de datos.

[![Claude Skill](https://img.shields.io/badge/Claude-Skill-8B5CF6?style=flat-square)](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview)
[![Skills](https://img.shields.io/badge/skills-15-ECFF0C?style=flat-square&labelColor=0A0B0D)](#las-skills)
[![Comandos](https://img.shields.io/badge/comandos-7-ECFF0C?style=flat-square&labelColor=0A0B0D)](#comandos)
[![Agentes](https://img.shields.io/badge/agentes-4-ECFF0C?style=flat-square&labelColor=0A0B0D)](#subagentes)
[![Licencia: MIT](https://img.shields.io/badge/licencia-MIT-blue?style=flat-square)](LICENSE)

**[English](README.md)** · **[Español](README.es.md)**

<sub>Creado por **[Devleck](https://github.com/Kin9Zeus)** — Aleck Martinez, Founder &amp; CEO</sub>

</div>

---

## Qué es esto

La mayoría de la asistencia de IA produce código que funciona. Esto hace que produzca
código que **sobrevive**: a una revisión de seguridad, a un incidente real, a un pico
de escala, a la pregunta de un regulador y al ingeniero que lo herede dentro de dos
años.

Instala quince skills especializadas que Claude carga automáticamente cuando el
trabajo lo requiere, o que puedes invocar por nombre.

```
Tú: "revisa mi proyecto antes de lanzar"

Claude carga senior-engineer → project-audit → y despacha las pasadas por dominio.

→ Estado real: Next.js 15, Postgres 16, Stripe, 4 encargados, 31 tests, CI sin bloqueo
→ P0: cualquier usuario autenticado puede leer las facturas de otro (api/invoices/[id]:24)
→ P0: STRIPE_SECRET_KEY presente en el historial de git desde el commit 8f14e45
→ P1: copias de seguridad configuradas, nunca restauradas — capacidad sin verificar
→ P1: la política de privacidad omite PostHog e Intercom, que sí reciben datos personales
→ 58/100 — En riesgo. Más débiles: Privacidad 2/10, Observabilidad 3/10, Testing 4/10
→ Plan de remediación: 3 bloqueantes, ~2 días hasta un estado lanzable
```

Cada hallazgo incluye una ubicación, una consecuencia concreta, la corrección y una
forma de **verificar** la corrección. Un hallazgo sin paso de verificación es una
opinión.

---

## Instalación

### Claude Code — marketplace de plugins (recomendado)

```
/plugin marketplace add Kin9Zeus/senior-engineer-skills
/plugin install senior-engineer-skills@senior-engineer-skills
```

O simplemente pega la URL de este repositorio en Claude Code y pídele que instale el
plugin globalmente:

> Instala este plugin globalmente: https://github.com/Kin9Zeus/senior-engineer-skills

Reinicia Claude Code y verifica con `/plugin`, o escribiendo `/snr-` — deberían
aparecer los siete comandos.

### Cualquier agente — un solo comando

Funciona con Claude Code, Cursor, Codex, Windsurf, Copilot, Antigravity y
[más de 40 agentes](https://github.com/vercel-labs/skills#supported-agents):

```bash
npx skills add https://github.com/Kin9Zeus/senior-engineer-skills
```

### Manual — clonar y copiar

```bash
git clone https://github.com/Kin9Zeus/senior-engineer-skills.git
cd senior-engineer-skills

# macOS / Linux
./install.sh

# Windows (PowerShell)
./install.ps1
```

El instalador copia `skills/`, `commands/` y `agents/` al directorio de tu agente.
Muestra exactamente lo que va a hacer y pregunta antes de sobrescribir nada.

<details>
<summary><b>Directorios de skills por agente</b></summary>

| Agente | Directorio de skills |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Cursor | `~/.cursor/skills/` |
| OpenAI Codex | `~/.codex/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Google Antigravity | `~/.gemini/antigravity/skills/` |

Para un solo proyecto en lugar de globalmente, copia en `.claude/skills/` dentro de
la raíz del proyecto.
</details>

### Desinstalar

```
/plugin uninstall senior-engineer-skills
```
O `./install.sh --uninstall` / `./install.ps1 -Uninstall`.

---

## Cómo se activa

De las dos formas, siempre.

**Automáticamente.** Cada skill declara las situaciones a las que pertenece. Claude
carga `security-hardening` cuando tocas una ruta de autenticación,
`database-engineering` cuando escribes una migración y `privacy-compliance` cuando un
formulario empieza a recoger un correo electrónico — sin que se lo pidas.

**Bajo demanda.** Nombra una skill o usa un comando:

```
"usa la skill project-audit en este repo"
"haz una pasada de security-hardening sobre la API"
/snr-audit --deep
```

---

## Las skills

<table>
<tr><th>Skill</th><th>Qué hace</th><th>Se carga cuando</th></tr>

<tr><td><b>senior-engineer</b></td>
<td>El enrutador y el estándar. Establece el estado real antes de opinar, elige el modo, delega en el especialista correcto y hace cumplir el mínimo innegociable.</td>
<td>Cualquier trabajo de ingeniería no trivial</td></tr>

<tr><td><b>project-audit</b></td>
<td>Auditoría completa en 15 dominios → hallazgos priorizados + puntuación 0–100.</td>
<td>"revisa mi proyecto", "¿está listo para producción?"</td></tr>

<tr><td><b>project-blueprint</b></td>
<td>Arquitectura y andamiaje desde cero, en el orden que evita retrofits caros.</td>
<td>"constrúyeme un…", "empezar un proyecto nuevo"</td></tr>

<tr><td><b>security-hardening</b></td>
<td>OWASP Top 10, autorización a nivel de objeto, inyección, autenticación, CSP, secretos, cadena de suministro, modelado de amenazas.</td>
<td>Auth, pagos, subidas, dependencias, auditorías</td></tr>

<tr><td><b>database-engineering</b></td>
<td>Esquema, restricciones, índices, planes de consulta, N+1, migraciones, multi-tenancy, backups, simulacros de restauración, retención.</td>
<td>Cualquier trabajo de persistencia</td></tr>

<tr><td><b>api-contracts</b></td>
<td>Diseño REST/GraphQL, sobres de error, paginación, idempotencia, versionado, límites de tasa, webhooks, OpenAPI.</td>
<td>Cualquier endpoint o integración</td></tr>

<tr><td><b>devops-platform</b></td>
<td>CI/CD, IaC, contenedores, paridad de entornos, estrategias de despliegue, rollback, secretos, recuperación ante desastres, coste.</td>
<td>Pipelines, Docker, Terraform, despliegues</td></tr>

<tr><td><b>observability-slo</b></td>
<td>Logs estructurados, métricas, trazas, identificadores de correlación, SLO y presupuestos de error, alertas sobre síntomas, respuesta a incidentes.</td>
<td>"¿cómo sabemos si se rompe?"</td></tr>

<tr><td><b>testing-strategy</b></td>
<td>La pirámide, política de cobertura con sentido, tests de integración y de contrato, E2E, control de flakes, mutation testing.</td>
<td>Cualquier conversación sobre tests</td></tr>

<tr><td><b>performance-engineering</b></td>
<td>Core Web Vitals, tamaño del bundle, estrategia de renderizado, presupuestos de latencia, caché, profiling, pruebas de carga.</td>
<td>"va lento", planificación de escala</td></tr>

<tr><td><b>accessibility-audit</b></td>
<td>WCAG 2.2 AA — teclado, foco, semántica, contraste, formularios, patrones ARIA, movimiento reducido, pruebas con tecnología de asistencia real.</td>
<td>Cualquier trabajo de interfaz</td></tr>

<tr><td><b>web-presence-audit</b></td>
<td>SEO técnico, metadatos por página, datos estructurados, 404 personalizada, enlazado interno y la capa de confianza y conversión.</td>
<td>Cualquier sitio público</td></tr>

<tr><td><b>privacy-compliance</b></td>
<td>Inventario de datos desde el código, política de privacidad veraz, consentimiento que realmente bloquea, borrado y exportación automatizados.</td>
<td>Cualquier dato personal</td></tr>

<tr><td><b>release-readiness</b></td>
<td>La puerta de go/no-go → veredicto explícito de lanzar o no lanzar, con bloqueantes nombrados y un rollback ya ensayado.</td>
<td>Antes de cualquier lanzamiento</td></tr>

<tr><td><b>engineering-standards</b></td>
<td>Convenciones, flujo de git, práctica de PR y revisión, ADR, documentación, onboarding, DX, deuda técnica.</td>
<td>Prácticas de equipo, onboarding</td></tr>
</table>

Cada skill es un `SKILL.md` conciso más archivos de referencia que se cargan bajo
demanda — **más de cincuenta documentos** de checklists, rúbricas, patrones y
plantillas, para que Claude trabaje desde un estándar y no desde la memoria.

---

## Comandos

| Comando | Qué hace |
|---|---|
| `/snr-audit [ruta\|url] [--quick\|--deep] [--parallel]` | Auditoría completa → informe de hallazgos + puntuación. `--parallel` autoriza revisores concurrentes por dominio |
| `/snr-build <descripción>` | Arquitectura y andamiaje de un proyecto nuevo, en el orden correcto |
| `/snr-harden [alcance]` | Pasada de seguridad con correcciones y tests de regresión |
| `/snr-web <url>` | SEO, metadatos, datos estructurados, 404, enlaces internos, capa de confianza |
| `/snr-privacy [--policy\|--deletion\|--cookies]` | Inventario → política → consentimiento → pipeline de borrado |
| `/snr-ship [versión]` | Puerta de go/no-go con veredicto explícito |
| `/snr-scorecard [ruta]` | Puntuación rápida de 15 dominios en una pantalla |

## Subagentes

Cuatro especialistas para revisión enfocada y paralela. Son de solo lectura:
informan y proponen, no aplican.

`snr-security-auditor` · `snr-data-auditor` · `snr-web-auditor` · `snr-architect`

```
"usa los agentes snr-security-auditor y snr-data-auditor en paralelo sobre este repo"
```

## Scripts incluidos

Scripts de solo lectura, en shell POSIX y PowerShell, sin más dependencias que `curl`
y `grep`. Todo lo que señalan es una **pista, no un hallazgo** — las skills instruyen
a Claude para confirmar cada una leyendo el código.

| Script | Qué hace |
|---|---|
| `project-audit/scripts/recon.{sh,ps1}` | Stack, capa de estado, tests, CI, señales de riesgo, terceros |
| `security-hardening/scripts/secret-scan.{sh,ps1}` | Patrones de credenciales en el árbol **y en el historial de git**, sumideros de inyección, configuración débil |
| `web-presence-audit/scripts/web-check.{sh,ps1}` | URL en vivo: cabeceras, robots, soft-404, metadatos, OG, schema, textos ALT, páginas de confianza |

---

## Qué comprueba realmente

<details open>
<summary><b>Seguridad y datos</b></summary>

Secretos en el árbol de trabajo **y en el historial de git** · autorización a nivel de
objeto (la prueba entre usuarios) · asignación masiva · inyección SQL, de comandos, de
plantillas y de rutas · hashing de contraseñas e invalidación de sesión · límites de
tasa y enumeración de usuarios · CSP sin `unsafe-inline` · CSRF, CORS, SSRF, subidas,
redirecciones · cabeceras de seguridad · riesgo de dependencias y cadena de suministro
· scripts de instalación · permisos de CI · restricciones del esquema en la base de
datos · índices en cada clave foránea · planes de consulta y N+1 · migraciones
reversibles probadas a escala de producción · límites de transacción · multi-tenancy
aplicada en la base de datos · **copias de seguridad realmente restauradas** ·
retención y borrado por tabla
</details>

<details>
<summary><b>Corrección, entrega y operación</b></summary>

Forma de la pirámide de tests · cobertura de ramas en la lógica de negocio · la matriz
de autorización · tests de contrato, E2E y de mutación · control de flakes · CI que
bloquea el merge · builds reproducibles desde un lockfile · un solo artefacto promovido
entre entornos · paridad de entornos · **un rollback que alguien ha ejecutado de
verdad** · contenedores sin root y sin secretos en las capas · secretos en un gestor y
rotables · logs estructurados con identificador de correlación y **sin datos
personales** · seguimiento de errores con releases y source maps · métricas RED más una
métrica de negocio · SLO y presupuestos de error · alertas que avisan por síntomas ·
runbooks que se han ejecutado · coste etiquetado y con alertas de anomalía
</details>

<details>
<summary><b>Superficie pública y confianza</b></summary>

`robots.txt` que no bloquea el sitio por accidente · `sitemap.xml` generado ·
**una 404 personalizada que devuelve un estado 404 real** · URLs canónicas que no
apuntan todas a la home · **título y metadescripción únicos en cada página** · Open
Graph y Twitter Cards con imagen 1200×630 en URL absoluta · **textos ALT en todas
partes**, vacíos en las decorativas · un solo `h1`, encabezados ordenados, landmarks ·
**datos estructurados incluyendo `LocalBusiness`, `FAQPage` y `BreadcrumbList`** ·
**enlazado interno sin páginas huérfanas** · **página de FAQ** · **casos de estudio con
resultados medidos** · **páginas de agradecimiento como URLs reales** · **un compromiso
de tiempo de respuesta declarado y monitorizado** · **un CTA fijo en móvil que no tapa
el contenido ni el foco** · páginas de nosotros, precios, estado y seguridad · WCAG 2.2
AA en todo
</details>

<details>
<summary><b>Privacidad y cumplimiento</b></summary>

**Un inventario de datos construido desde el código, no desde una entrevista** · **una
política de privacidad que nombra a todos los terceros que reciben datos** —
contrastada con `grep`, porque la etiqueta de analítica omitida es el hallazgo más
común en una auditoría de privacidad real · base jurídica por finalidad · retención por
categoría, aplicada por un proceso vigilado · **consentimiento de cookies que bloquea
los scripts antes de aceptar**, verificado en ventana privada, con rechazar tan fácil
como aceptar · **una ruta de exportación y borrado en autoservicio, automatizada de
extremo a extremo** — que alcanza el almacenamiento de objetos, cachés, buscador, logs
y **todos los encargados externos** · borrado verificado reconsultando y registrado en
una traza de auditoría · una posición honesta y documentada sobre las copias de
seguridad · contratos de encargo y lista pública de subencargados · plan de brechas con
responsable nombrado y reloj de 72 horas

Plantillas incluidas en **inglés y español**.
</details>

---

## El estándar que impone

Se aplica a todo proyecto que toca, grande o pequeño. Un proyecto pequeño no es una
excusa para uno inseguro; es una razón para que la versión segura sea barata.

> **Seguridad** — Ningún secreto en el control de versiones, nunca. Todo endpoint que
> muta: autenticado, autorizado *para ese objeto concreto*, validado por esquema y con
> límite de tasa. Solo consultas parametrizadas. Una CSP que no sea `unsafe-inline`.
>
> **Datos** — Migraciones versionadas y reversibles. Copias de seguridad **restauradas
> al menos una vez en una prueba** — una copia sin probar no es una copia. Datos
> personales inventariados, minimizados, con retención acotada y borrables.
>
> **Corrección** — Un test por cada bug corregido y cada regla de negocio. CI que
> bloquea el merge en rojo. Ningún `TODO` en una ruta que maneje dinero,
> autenticación o datos personales.
>
> **Operabilidad** — Arranque local con un comando. Despliegues reversibles. Logs
> estructurados con identificadores de correlación. Al menos una alerta que despierte
> a una persona. Un runbook para los tres fallos más probables.
>
> **Usuarios** — Título y descripción únicos por página. WCAG 2.2 AA. Una política de
> privacidad que coincide con los flujos reales, consentimiento que bloquea de verdad,
> y una ruta de borrado en autoservicio que funciona.

Y un contrato de conducta: leer antes de escribir · respetar las convenciones del
código existente · el cambio correcto más pequeño · sin reducir el alcance en silencio
· discrepar de forma explícita · **nunca inventar** una versión, un CVE, una firma de
API ni un benchmark · confirmar antes de cualquier acción destructiva.

---

## Ejemplos

> **[→ El recetario](docs/es/recetario.md)** — diez flujos completos, en el orden
> en que los ejecutarías de verdad: heredar un código, empezar uno bien,
> diagnosticar lentitud, construir el pipeline de borrado, arreglar la visibilidad
> en buscadores, cerrar la puerta de un lanzamiento, y el uso diario sin comandos.

```
"audita este repo antes de nuestra Serie A"
  → /snr-audit --deep. Quince dominios, modelo de amenazas, solicitud de simulacro
    de restauración, puntuación y plan de remediación con estimaciones de esfuerzo.

"constrúyeme un SaaS multi-tenant para reservas de gimnasio"
  → /snr-build. Cinco preguntas, luego ADR de stack, un esquema con tenancy y PII
    etiquetados desde la migración 001, una capa de autorización que deniega por
    defecto, un corte vertical completo, CI y un despliegue a staging — antes de
    cualquier funcionalidad.

"¿por qué va lenta mi página de checkout?"
  → performance-engineering. Primero datos de campo, luego la cascada, luego la
    medición: "LCP 4,8s (p75, móvil, 28d, n=12.400). La imagen hero es un PNG de
    2,4 MB sin optimizar y con lazy-load. Convertir a AVIF + srcset, quitar
    loading=lazy, añadir fetchpriority=high. Esperado ~1,9s."

"necesitamos que los usuarios puedan borrar sus datos"
  → /snr-privacy --deletion. Inventario desde el esquema, plan de borrado como
    código, los endpoints, el periodo de gracia, la propagación a encargados, el paso
    de verificación, la traza de auditoría y el test que falla cuando se añade una
    tabla nueva sin regla.

"¿estamos listos para lanzar el jueves?"
  → /snr-ship. "NO GO. Tres bloqueantes. El mayor es que cualquier usuario
    autenticado puede leer las facturas de otro, lo que sería una brecha notificable
    el primer día. Estimado: 2 días para resolverlos."
```

---

## Preguntas frecuentes

<details>
<summary><b>¿Funciona fuera de Claude Code?</b></summary>

Sí. Las skills son Markdown plano siguiendo el formato Agent Skills. `npx skills add`
las instala en Cursor, Codex, Windsurf, Copilot, Antigravity y otros. Los comandos y
los subagentes son funciones de Claude Code; las skills en sí son portables.
</details>

<details>
<summary><b>Quince skills, ¿no llenan la ventana de contexto?</b></summary>

No. Solo se cargan de entrada las *descripciones* de las skills (unos pocos cientos de
tokens en total). El cuerpo de una skill se carga cuando se activa, y sus archivos de
referencia solo cuando esa skill decide que los necesita. Por eso el conjunto son
quince skills enfocadas y no un único documento enorme.
</details>

<details>
<summary><b>¿Es seguro publicar el contenido de seguridad?</b></summary>

Es defensivo de principio a fin: encontrar y corregir debilidades en código que posees
o estás autorizado a evaluar. Las skills instruyen a Claude para no escanear ni enviar
tráfico a infraestructura sin confirmación de propiedad, y para producir correcciones
y detecciones en lugar de exploits armados.
</details>

<details>
<summary><b>¿El contenido de privacidad es asesoramiento legal?</b></summary>

No, y la skill lo dice cada vez que se ejecuta. Produce controles técnicos y una
política redactada a partir de tus flujos de datos reales. Para un sector regulado,
datos de menores o categorías especiales, haz que lo revise un abogado especializado.
Construye los controles igualmente — son los mismos.
</details>

<details>
<summary><b>¿Va a reescribir mi código?</b></summary>

No. La postura por defecto es leer e informar. Las correcciones se aplican solo si lo
pides, en orden de severidad, un hallazgo por commit y con el test que falla escrito
primero. Las skills prohíben explícitamente recomendar una reescritura sin nombrar la
propiedad concreta e irreparable que la obliga.
</details>

<details>
<summary><b>¿Cómo lo hago menos estricto para un proyecto personal?</b></summary>

Díselo — se calibra. Evalúa según lo que el proyecto dice ser, y te indicará qué
hallazgos está bajando de prioridad. Cuatro cosas nunca se bajan: secretos en git,
acceso a datos de otros usuarios, ausencia de copias de seguridad, y afirmaciones de
privacidad que no son ciertas.
</details>

---

## Contribuir

Issues y pull requests son bienvenidos. Consulta **[CONTRIBUTING.md](CONTRIBUTING.md)**
para las convenciones de escritura de skills — principalmente: toda afirmación debe ser
comprobable, todo hallazgo necesita un paso de verificación, y nada de números de
versión, CVE ni benchmarks inventados.

Divulgación de vulnerabilidades: **[SECURITY.md](SECURITY.md)**.

## Licencia

[MIT](LICENSE) © Aleck Martinez / Devleck. Úsalo comercialmente, bifúrcalo, publícalo.

---

<div align="center">

<img src="assets/mark.svg" alt="" width="72">

**Creado por [Devleck](https://github.com/Kin9Zeus)**
Aleck Martinez — Founder &amp; CEO

<sub>Si esto hizo tu código más difícil de romper, una ⭐ ayuda a que otros ingenieros lo encuentren.</sub>

</div>
