# Recetario

Flujos reales, en el orden en que los ejecutarías de verdad.

[English](../en/cookbook.md) · [Español](../es/recetario.md)

---

## 1 · Has heredado un código y no tienes ni idea de qué hay dentro

```
/snr-audit --quick
```

Treinta minutos. Responde a una sola pregunta: ¿hay algo aquí que deba
corregirse antes de que lo toque un usuario real? Obtienes bloqueantes,
críticos, lo que se comprobó y salió limpio, y lo que una auditoría completa
cubriría y esta no.

Después, cuando ya conoces la forma del proyecto:

```
/snr-audit --parallel
```

La pasada completa de quince dominios, con revisores concurrentes por dominio.
Espera un informe de varios miles de palabras: veredicto, puntuación, estado
real, hallazgos por severidad, tabla de puntuación, plan de remediación y un
apartado explícito de "lo que no pude verificar".

**Después corrige en orden.** Pídele que trabaje la lista de P0, un hallazgo por
commit, con el test que falla escrito primero:

> Corrige los hallazgos P0 de la auditoría. Un commit por hallazgo. Escribe el
> test que falla antes de la corrección, y vuelve a verificar con el paso de
> verificación de cada hallazgo.

---

## 2 · Empiezas algo nuevo y quieres hacerlo bien

```
/snr-build un SaaS multi-tenant para reservas de clases de gimnasio
```

Te hará hasta cinco preguntas —quién lo usa y cuántos, la transacción central,
la clasificación de datos, las integraciones y la restricción dominante— y luego
te mostrará un resumen de arquitectura antes de escribir nada.

Si dices que sí, construye en este orden:

```
repo → toolchain + tipos estrictos → configuración validada → base de datos + migración 001
→ auth + autorización que deniega por defecto → UN CORTE VERTICAL COMPLETO
→ CI que bloquea el merge → logging + seguimiento de errores + una alerta
→ despliegue a staging → después, funcionalidades
```

**El corte vertical es lo importante.** Una ruta con validación, autorización a
nivel de objeto, lógica de dominio, persistencia, una línea de log y dos tests.
Cada funcionalidad futura copia su forma, así que la calidad escala sola.

**Si tienes una fecha límite**, dilo. Recortará funcionalidades. No recortará la
base de seguridad, la ruta de borrado ni los tests de la transacción central — y
te dirá claramente que no las está recortando.

---

## 3 · Algo va lento y no sabes por qué

```
"la página de checkout tarda una eternidad en cargar"
```

Se activa `performance-engineering`. Se negará a adivinar y pedirá primero datos
de campo, porque una puntuación de Lighthouse desde tu portátil no es lo que
experimentan tus usuarios.

Espera una medición, no una opinión:

```
Medido:    LCP 4,8s (p75, datos de campo, móvil, últimos 28 días, n=12.400)
Causa:     La imagen hero es un PNG de 2,4 MB sin optimizar, con lazy-load y sin preload
Corrección: AVIF + srcset (≈180 KB), quitar loading="lazy", fetchpriority="high"
Esperado:  LCP ~1,9s
Verificar: datos de campo en PageSpeed Insights a los 28 días; Lighthouse CI mientras tanto
```

Si el cuello de botella resulta estar en el backend, cede el paso a
`database-engineering` — porque la respuesta es un índice que falta o un N+1
mucho más a menudo que el código de la aplicación.

---

## 4 · Necesitas que los usuarios puedan borrar sus datos

Este es el flujo que la mayoría de los equipos posponen hasta que un regulador o
un cliente empresarial les obliga, momento en el que cuesta un trimestre en lugar
de una semana.

```
/snr-privacy --deletion
```

Lo que obtienes:

1. **Un inventario de datos construido desde tu esquema y tus rutas**, no desde
   un cuestionario. Incluida la lista de todos los terceros de tu código que
   reciben datos personales.
2. **Un plan de borrado como código** — por tabla y por campo: eliminar, poner a
   nulo, anonimizar, seudonimizar, o conservar con una razón legal documentada y
   una fecha de expiración.
3. **Los endpoints y el proceso** — solicitud, verificación, periodo de gracia,
   ejecución en todos los almacenes, verificación reconsultando, registro en una
   traza de auditoría y notificación.
4. **La propagación a los encargados** — el paso que se salta todo el mundo, y el
   que marca la diferencia entre un borrado y un borrado parcial.
5. **El test que falla cuando se añade una tabla nueva sin regla.** Esto es lo
   que mantiene el plan honesto dentro de seis meses.

Después, ejecuta el paquete completo:

```
/snr-privacy
```

Inventario → política (plantillas en inglés y español) → consentimiento que
realmente bloquea los scripts → el pipeline de derechos → página de subencargados
y plan de brechas.

---

## 5 · Tu sitio no aparece en las búsquedas

```
/snr-web https://tusitio.com
```

Primero ejecuta la comprobación en vivo y luego profundiza. Las dos cosas que
encuentra más a menudo, ambas invisibles en un navegador:

- **Un soft 404** — páginas inexistentes que devuelven `200`, con lo que cada URL
  mal escrita se convierte en una página indexable y pobre.
- **Un `robots.txt` de staging en producción** — `Disallow: /` elimina el sitio
  de las búsquedas por completo, y el tráfico decae durante semanas antes de que
  alguien se dé cuenta.

La tercera más común: todas las páginas con la canónica apuntando a la home, lo
que desindexa el sitio entero salvo una página.

Obtienes una tabla por página, hallazgos priorizados y —lo importante— **el texto
de reemplazo sugerido**. Títulos y metadescripciones escritos, no una nota
diciendo que deberías escribirlos.

---

## 6 · Lanzas el jueves

```
/snr-ship v1.0
```

Primero, doce comprobaciones de bloqueantes. Cualquiera de ellas hace que el
veredicto sea `NO GO`, y el informe es corto:

> **NO GO.** Tres bloqueantes. El mayor es que cualquier usuario autenticado
> puede leer las facturas de otro, lo que sería una brecha notificable el primer
> día. Estimado: 2 días para resolver los tres.

Si los bloqueantes están limpios, ejecuta la puerta completa de nueve áreas y te
da `GO` o `GO WITH RISK` — con cada riesgo aceptado nombrado, mitigado y
asignado a una persona que lo aceptó.

También captura la **línea base previa al lanzamiento**. Sin ella, el viernes por
la mañana no puedes saber si los números son malos.

---

## 7 · Quieres una segunda opinión sobre un diseño antes de construirlo

```
"usa el agente snr-architect para revisar este plan: <tu plan>"
```

Obtienes las siete preguntas estructurales respondidas, las puertas de un solo
sentido nombradas como ADR, el primer cuello de botella de escala identificado y
—lo más útil— **la costura que va a doler en las próximas tres funcionalidades**,
nombrada antes de que cueste un trimestre.

También te frenará ante la complejidad prematura. Si propones microservicios para
un producto sin usuarios, te lo dirá en dos frases y luego diseñará lo que
pediste con la suposición declarada.

---

## 8 · Pasada de seguridad antes de un pentest

```
/snr-harden
```

Trabaja de arriba abajo por rendimiento real: primero secretos (incluido el
historial de git), luego autorización a nivel de objeto, luego inyección. Las dos
comprobaciones que encuentran los problemas más graves:

**Secretos en el historial de git.** Si aparece algo, el orden de remediación es
fijo: rotar la credencial, revisar el registro de auditoría del proveedor y
*después* purgar el historial. Purgar sin rotar deja la clave viva y hace que el
repositorio parezca limpio — el error más común en esta área.

**La prueba entre usuarios.** Autentícate como el usuario A y pide el recurso del
usuario B cambiando un identificador. Un `200` es un P0. Esta única comprobación
encuentra más vulnerabilidades graves en aplicaciones reales que ninguna otra.

Pídele correcciones y trabajará en orden de severidad, un hallazgo por commit,
con el test de regresión escrito primero.

---

## 9 · Uso diario, sin comandos

Las skills se activan solas. No necesitas pensar en cuál.

| Tú dices | Qué se carga |
|---|---|
| "añade un endpoint de login" | `security-hardening` + `api-contracts` |
| "escribe una migración para añadir una tabla de equipos" | `database-engineering` |
| "este modal no funciona con el teclado" | `accessibility-audit` |
| "configura CI para este repo" | `devops-platform` + `testing-strategy` |
| "estamos teniendo muchos 500 y no sabemos por qué" | `observability-slo` |
| "añade un campo de email al formulario de registro" | `privacy-compliance` |
| "¿qué stack debería usar para esto?" | `project-blueprint` |

La última merece atención: añadir un campo de email a un formulario es un evento
de privacidad, y la suite lo trata como tal — sin que se lo pidas.

---

## 10 · Hacerlo menos estricto

Se calibra según lo que el proyecto dice ser. Díselo:

> Esto es un proyecto personal de fin de semana, sin usuarios y sin planes de
> tenerlos. Evalúalo en consecuencia.

Bajará el peso de escalabilidad, proceso, observabilidad y documentación, y te
dirá qué hallazgos está bajando de prioridad.

**Cuatro cosas nunca se bajan**, y lo dirá: secretos en git, acceso a datos de
otros usuarios, ausencia de copias de seguridad, y afirmaciones de privacidad que
no son ciertas. Esas causan el mismo daño sin importar lo pequeño que sea el
proyecto.

---

## 11 · Un proveedor dice que tus secretos pudieron quedar expuestos

Un host, un CI o un registro anuncia acceso no autorizado a los sistemas que guardan
tus variables de entorno (el comunicado de Railway de octubre de 2026 es el ejemplo
resuelto de la suite).

```
/snr-incident Railway dice que nuestras variables de entorno pudieron quedar expuestas
```

Lo clasifica como brecha de proveedor, lee el comunicado original del proveedor y
ejecuta la respuesta en orden: inventario solo de nombres de cada secreto que el repo
lee, plan de rotación por radio de impacto (nube, base de datos, claves de firma,
pagos, claves de IA, registros), **primero en el emisor** — crear la credencial nueva
en el emisor, desplegar, revocar la vieja y luego demostrar que está muerta con un
`401`. Después te lleva a los logs de auditoría de los emisores, porque el atacante no
los controlaba.

```
/snr-rotate all
```

genera el seguimiento fila a fila. Una fila está terminada solo cuando el valor viejo
está probado muerto. Después, `/snr-cloud` muestra cómo hacer que la *próxima* variable
robada valga poco: alcance estrecho, listas de red permitida, topes de gasto, sin
claves largas en CI.

## 12 · Se anuncia una vulnerabilidad crítica de PHP

```
/snr-php
```

Encuentra cada PHP que ejecutas — declaraciones del repo, imágenes base, configuración
de hosting, copias incluidas en otro software — resuelve el build que realmente
**sirve** el tráfico (el CLI de tu shell suele ser otra instalación), lo compara con
las versiones corregidas de CVE-2026-109618 y CVE-2026-109619 y comprueba que los
workers se reiniciaron. Si hoy no puedes parchear, lista las mitigaciones temporales
con responsable y fecha de retirada, y luego hace la evaluación de compromiso: asume
exposición desde el primer intento reportado, rota lo que el proceso PHP podía leer y
caza shells lanzados por workers web. Verifica tú mismo los hechos del aviso en php.net
y en tu distribución — la skill los fecha y enlaza las fuentes.

## 13 · Probar tu propio sistema como lo haría un atacante

```
/snr-pentest https://staging.example.com
```

Antes de enviar tráfico pide confirmación escrita de que eres dueño o estás autorizado
a probar el objetivo, escribe un `scope.txt` con fecha de caducidad y ejecuta
`scope-guard` para cada host. Después: control de acceso con dos cuentas por rol, el
OWASP API Top 10 como plan de prueba, inyección con marcadores inertes, lógica de
negocio y condiciones de carrera en staging. Cada hallazgo trae corrección, test de
regresión y señal de detección; `--retest` demuestra las correcciones. No ejecutará
denegación de servicio, malware, persistencia ni post-explotación, y sin alcance solo
revisará tu código o trabajará en un laboratorio local.

## 14 · Asegurar una función de IA o un agente

```
/snr-ai-security el chatbot de soporte
```

Inventaría llamadas a modelos, herramientas, fuentes de datos y servidores MCP, y busca
la combinación peligrosa: **datos privados + contenido no confiable + una vía para
enviar cosas fuera** en una misma sesión. Los prompts no lo arreglan; el diseño debe
romper una pata. También revisa permisos de herramientas y aprobaciones, manejo de
salidas, aislamiento de inquilinos en el almacén vectorial, alcance y topes de gasto de
las claves del proveedor, y arma una batería de ataques que ejecutas en CI.
