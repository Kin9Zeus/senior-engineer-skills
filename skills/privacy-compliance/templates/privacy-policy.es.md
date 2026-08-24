<!--
════════════════════════════════════════════════════════════════════════════════
  PLANTILLA DE POLÍTICA DE PRIVACIDAD  ·  Devleck Senior Engineer Skills
════════════════════════════════════════════════════════════════════════════════

  CÓMO USARLA

  1. Construye PRIMERO el inventario de datos (references/data-inventory.md).
     Todas las tablas de abajo se generan a partir de él. Rellenar esto sin el
     inventario produce un documento que describe otro producto.

  2. Sustituye cada <MARCADOR>. Elimina toda sección que no aplique — una
     sección inaplicable es peor que una ausente, porque describe tratamientos
     que no realizas.

  3. Contrasta la tabla "Con quién compartimos" contra el código:

       grep -rhoE 'googletagmanager|google-analytics|gtag\(|connect\.facebook\.net|
         hotjar|segment|mixpanel|posthog|intercom|clarity\.ms|sentry\.io|stripe|
         paypal|fonts\.googleapis|recaptcha' . --exclude-dir={node_modules,.git}

     Cualquier proveedor en esa salida que no esté en la tabla es un hallazgo P1.

  4. Haz que un abogado especializado la revise antes de publicarla,
     especialmente en sectores regulados, datos de menores o categorías
     especiales.

  NUNCA: declares una certificación que no tienes · describas tratamientos que
  no haces · prometas un borrado que no puedes ejecutar · indiques un plazo de
  conservación que nada hace cumplir. Cada uno es una declaración falsa y es lo
  primero que se comprueba.
════════════════════════════════════════════════════════════════════════════════
-->

# Política de Privacidad

**Última actualización: <AAAA-MM-DD>** · **Versión <N>** · [Versiones anteriores](<ENLACE>)

<NOMBRE DE LA EMPRESA> ("nosotros") opera <PRODUCTO/SITIO> en <URL>. Esta
política explica qué datos personales recogemos, para qué, con quién los
compartimos, cuánto tiempo los conservamos y qué opciones tienes.

Está redactada en lenguaje claro de forma deliberada. Si algo no se entiende,
escribe a <privacidad@DOMINIO> y te lo explicamos.

**En resumen**
- Recogemos el mínimo necesario para que <PRODUCTO> funcione.
- No vendemos tus datos personales.
- Las cookies no esenciales solo se cargan después de que las aceptes.
- Puedes [descargar todo lo que tenemos sobre ti](<ENLACE EXPORTAR>) o
  [eliminar tu cuenta y tus datos](<ENLACE BORRAR>) cuando quieras, tú mismo.

---

## 1. Quiénes somos

| | |
|---|---|
| **Responsable del tratamiento** | <RAZÓN SOCIAL> |
| **Domicilio social** | <DIRECCIÓN COMPLETA> |
| **CIF / NIF / RUC** | <NÚMERO> |
| **Contacto de privacidad** | <privacidad@DOMINIO> |
| **Delegado de Protección de Datos (DPD)** | <NOMBRE / "No estamos obligados a designar un DPD. Las consultas de privacidad se atienden en la dirección anterior."> |
| **Representante en la UE/RU** | <NOMBRE Y DIRECCIÓN, si estás fuera de la UE/RU y ofreces servicios en ella> |

---

## 2. Qué recogemos y para qué

<!-- Generado desde el inventario de datos. Sé ESPECÍFICO. "Cierta información"
     no es una divulgación. Elimina las filas que no apliquen. -->

### 2.1 Datos que nos facilitas

| Qué | Cuándo | Para qué | Base jurídica |
|---|---|---|---|
| Nombre y correo electrónico | Al crear una cuenta | Crear y proteger tu cuenta y comunicarnos contigo sobre el servicio | Ejecución de un contrato |
| Contraseña (almacenada solo como hash criptográfico — nunca la vemos) | Registro | Autenticación | Ejecución de un contrato |
| Nombre de facturación, dirección, país, identificación fiscal | Al suscribirte | Procesar el pago y emitir una factura conforme a la ley | Contrato; obligación legal |
| Contenido que subes (<DESCRIBIR: archivos, mensajes, documentos>) | Durante el uso de <PRODUCTO> | Prestar el servicio | Ejecución de un contrato |
| Mensajes de soporte y adjuntos | Al contactarnos | Responderte y mejorar nuestro soporte | Contrato; interés legítimo |
| Preferencias de marketing | Al suscribirte | Enviarte lo que has solicitado | Consentimiento |

### 2.2 Datos recogidos automáticamente

| Qué | Para qué | Base jurídica |
|---|---|---|
| Dirección IP, tipo de navegador y dispositivo, sistema operativo | Seguridad, prevención del fraude y diagnóstico de fallos | Interés legítimo |
| Páginas visitadas, funciones usadas, marcas de tiempo, URL de referencia | Entender cómo se usa <PRODUCTO> y mejorarlo | Consentimiento (cookies analíticas) |
| Informes de error, incluida la traza técnica y tu identificador de usuario | Detectar y corregir fallos | Interés legítimo |
| Cookies y tecnologías similares | Ver la sección 6 | Ver la sección 6 |

**Nota.** Una dirección IP y un identificador de cookie **son datos personales**.
Los tratamos como tales.

### 2.3 Datos de otras fuentes

| Fuente | Qué | Para qué |
|---|---|---|
| <Proveedor de SSO, p. ej. Google> | Nombre, correo, foto de perfil | Permitirte iniciar sesión sin una contraseña aparte |
| <Proveedor de pagos> | Estado del pago, últimos cuatro dígitos de la tarjeta, marca | Gestionar tu suscripción |
| <ELIMINAR SI NO APLICA> | | |

### 2.4 Qué **no** recogemos deliberadamente

<!-- Opcional y desproporcionadamente eficaz para generar confianza. Incluye
     únicamente lo que sea cierto. -->

- No almacenamos números de tarjeta. Los pagos los gestiona íntegramente
  <PROVEEDOR>; los datos de la tarjeta se introducen en sus sistemas y nunca
  llegan a los nuestros.
- No recogemos categorías especiales de datos (salud, biometría, origen racial o
  étnico, religión, opiniones políticas, orientación sexual, afiliación
  sindical).
- No usamos herramientas de grabación de sesión ni mapas de calor.
- <PRODUCTO> no está dirigido a menores de <EDAD> años y no recogemos sus datos
  conscientemente.

---

## 3. Con quién compartimos tus datos

<!-- ══════════════════════════════════════════════════════════════════════════
     LA TABLA MÁS IMPORTANTE DE ESTE DOCUMENTO.

     Todo tercero presente en tu código que reciba datos personales debe
     aparecer aquí — incluidos analítica, seguimiento de errores, fuentes
     tipográficas, incrustaciones, widgets de chat y CDN. Un encargado que esté
     en el código y no aquí es una declaración falsa a los usuarios, no un
     simple fallo documental.
     ══════════════════════════════════════════════════════════════════════════ -->

**No vendemos** tus datos personales ni los compartimos para publicidad
comportamental entre contextos.

Solo los compartimos con los proveedores indicados a continuación, únicamente
para la finalidad señalada y siempre bajo un contrato de encargo del
tratamiento.

| Proveedor | Qué recibe | Para qué | Dónde | Garantía de transferencia | Su política |
|---|---|---|---|---|---|
| <AWS / alojamiento> | Todos los datos que almacenas con nosotros | Alojar <PRODUCTO> | <REGIÓN> | <— / CCT> | <ENLACE> |
| <Stripe> | Nombre, correo, dirección de facturación, historial de compras | Cobrar y emitir facturas | <EE. UU.> | <CCT> | <ENLACE> |
| <Postmark> | Nombre, correo | Enviar correos de cuenta y transaccionales | <EE. UU.> | <CCT> | <ENLACE> |
| <Sentry> | Identificador de usuario, IP, datos técnicos del error | Detectar y corregir fallos | <UE> | <—> | <ENLACE> |
| <PostHog> | Eventos de uso, IP, datos del dispositivo | Analítica de producto — **solo si aceptas las cookies analíticas** | <UE> | <—> | <ENLACE> |
| <Intercom> | Nombre, correo, conversación de soporte | Atención al cliente | <EE. UU.> | <CCT> | <ENLACE> |

<!-- Incluye también, si están en tu código: Google Fonts (recibe la IP de cada
     visitante), reCAPTCHA, incrustaciones de YouTube/Vimeo, Google Tag Manager,
     CDN que sirvan scripts, y cualquier API de IA a la que envíes contenido. -->

La lista actualizada de subencargados está en <ENLACE A SUBENCARGADOS>. Te
avisaremos con al menos <30> días de antelación antes de incorporar uno nuevo.

**También podemos comunicar datos personales:**
- para cumplir una obligación legal, una orden judicial o un requerimiento
  legítimo de una autoridad — y te lo comunicaremos salvo prohibición legal;
- para formular, ejercer o defender reclamaciones;
- para proteger los derechos, la seguridad o los bienes de nuestros usuarios o
  del público;
- a un adquirente, en caso de fusión, adquisición o venta de activos — se te
  notificará y esta política seguirá aplicándose a los datos transferidos.

---

## 4. Transferencias internacionales

<ELIMINAR SI TODO EL TRATAMIENTO OCURRE EN UNA SOLA JURISDICCIÓN>

Algunos de nuestros proveedores están fuera de <TU REGIÓN>. Cuando se
transfieren datos personales fuera del <EEE/RU>, nos amparamos en:

- una **decisión de adecuación** de la Comisión Europea, cuando exista para ese
  país; o
- las **Cláusulas Contractuales Tipo** de la Comisión Europea, junto con medidas
  técnicas adicionales (cifrado en tránsito y en reposo, y controles de acceso)
  cuando la evaluación de riesgo de la transferencia así lo exija.

Puedes solicitar una copia de las garantías aplicadas escribiendo a
<privacidad@DOMINIO>.

---

## 5. Cuánto tiempo los conservamos

<!-- Cada fila debe estar respaldada por un proceso real. "El tiempo necesario"
     por sí solo no es una política de conservación. -->

| Dato | Conservación | Después |
|---|---|---|
| Datos de la cuenta | Mientras la cuenta esté activa, y **30 días** más | Eliminados o anonimizados de forma permanente |
| Contenido que subes | Mientras la cuenta esté activa, y **30 días** más | Eliminado permanentemente |
| Registros de sesión | **7 días** tras su expiración | Eliminados |
| Registros de servidor con direcciones IP | **90 días** (la IP se elimina a los 30) | Eliminados |
| Datos analíticos | **14 meses** | Eliminados |
| Conversaciones de soporte | **3 años** tras el cierre | Eliminadas |
| Facturas y registros fiscales | **<7> años** | Exigido por <LEY FISCAL>. Se conservan incluso tras eliminar la cuenta, minimizando los datos personales |
| Registros de consentimiento de marketing | Hasta su retirada, y **3 años** más | Conservados como prueba de la retirada |
| Copias de seguridad | **30 días** | Destruidas automáticamente |

---

## 6. Cookies y tecnologías similares

Usamos cookies y tecnologías similares (almacenamiento local, píxeles).
**No se carga nada más allá de las cookies estrictamente necesarias hasta que
das tu consentimiento.**

| Categoría | Qué hace | ¿Requiere consentimiento? |
|---|---|---|
| **Estrictamente necesarias** | Mantiene tu sesión, protege los formularios, recuerda tu elección sobre cookies | No — el servicio no puede funcionar sin ellas |
| **Funcionales** | Recuerda tu idioma y preferencias de visualización | Sí |
| **Analíticas** | Nos ayuda a entender qué funciones se usan | Sí |
| **Marketing** | <Mide la publicidad / ELIMINAR SI NO APLICA> | Sí |

Puedes cambiar tu elección cuando quieras en <ENLACE A PREFERENCIAS>. Rechazar
es tan fácil como aceptar, y rechazar no limita tu acceso a <PRODUCTO>.

La lista completa de cookies, con nombres y duraciones, está en
<ENLACE A POLÍTICA DE COOKIES>.

---

## 7. Tus derechos

Tienes derecho a:

| Derecho | Qué significa | Cómo ejercerlo |
|---|---|---|
| **Acceso** | Obtener una copia de los datos personales que tenemos sobre ti | [Descargar tus datos](<ENLACE EXPORTAR>) — inmediato, autoservicio |
| **Rectificación** | Corregir lo que sea inexacto | [Ajustes de la cuenta](<ENLACE AJUSTES>), o escríbenos |
| **Supresión** | Que se eliminen tus datos | [Eliminar tu cuenta](<ENLACE BORRAR>) — autoservicio. Ver sección 8 |
| **Portabilidad** | Recibir tus datos en un formato legible por máquina | [Descargar tus datos](<ENLACE EXPORTAR>) — se entrega en JSON |
| **Limitación** | Pedirnos que pausemos el tratamiento mientras se resuelve una discrepancia | <privacidad@DOMINIO> |
| **Oposición** | Oponerte al tratamiento basado en interés legítimo | <privacidad@DOMINIO> |
| **Retirar el consentimiento** | Retirarlo en cualquier momento, sin afectar a lo ya realizado | [Preferencias de cookies](<ENLACE COOKIES>); marketing: el enlace de baja de cualquier correo |
| **Reclamar** | Presentar una reclamación ante una autoridad de control | Ver sección 11 |

Respondemos **en el plazo de un mes**. Si la solicitud es compleja podemos
prorrogarlo dos meses más, y te lo comunicaremos dentro del primer mes. Ejercer
tus derechos es gratuito.

Podemos pedirte que verifiques tu identidad antes de atender una solicitud. Esto
te protege: sin verificación, otra persona podría solicitar tus datos o eliminar
tu cuenta.

---

## 8. Eliminar tus datos

Puedes eliminar tu cuenta y tus datos tú mismo, en cualquier momento:

**<ENLACE AJUSTES> → Privacidad y datos → Eliminar mi cuenta**

**Qué ocurre:**

1. Te pedimos que lo confirmes — introduciendo de nuevo tu contraseña o
   pulsando un enlace que te enviamos por correo.
2. Tu cuenta queda **suspendida de inmediato** y deja de ser accesible.
3. Tras un **periodo de gracia de <30> días** — durante el cual puedes cancelar
   la solicitud y recuperar la cuenta contactándonos — la eliminación se ejecuta
   automáticamente.
4. La eliminación retira tus datos de nuestra base de datos, nuestro
   almacenamiento de archivos, nuestras cachés y nuestro índice de búsqueda, y
   se propaga a los proveedores de la sección 3 a través de sus propias
   interfaces de borrado.
5. Verificamos que la eliminación se ha completado y te enviamos una
   confirmación.

**Qué conservamos y por qué:**

| Se conserva | Por qué | Cuánto tiempo |
|---|---|---|
| Facturas y registros de pago | Exigido por <LEY FISCAL> | <7> años, minimizando los datos personales |
| Registro de que se solicitó y completó una eliminación | Para acreditar que la atendimos | <3> años — no contiene datos personales más allá de un hash unidireccional |
| Estadísticas de uso anonimizadas | Datos agregados que ya no permiten identificarte | Indefinidamente |

**Copias de seguridad.** Nuestras copias se conservan **30 días** y luego se
destruyen de forma permanente. No es técnicamente posible eliminar un registro
individual de un archivo de copia cifrado sin restaurarlo. El acceso a las
copias está restringido y registrado, y si alguna vez se restaura una copia, las
solicitudes de eliminación ya completadas se vuelven a aplicar automáticamente
antes de que vuelva a producción.

Si no tienes cuenta pero crees que tenemos datos sobre ti, escribe a
<privacidad@DOMINIO> y atenderemos tu solicitud del mismo modo.

---

## 9. Cómo protegemos tus datos

Aplicamos las siguientes medidas. Es un resumen, no una lista exhaustiva, y
ningún sistema puede garantizarse completamente seguro.

- Cifrado en tránsito (TLS) y en reposo.
- Contraseñas almacenadas únicamente como hashes criptográficos con sal; no
  podemos leerlas.
- Acceso a los sistemas de producción restringido al personal que lo necesita,
  protegido con autenticación multifactor y registrado.
- Supervisión automatizada de dependencias y vulnerabilidades.
- <Pruebas de penetración / revisiones de seguridad periódicas — ELIMINAR SI NO
  ES CIERTO>.
- Un proceso de respuesta a incidentes con plazos de notificación definidos.

<!-- No declares SOC 2, ISO 27001 ni ninguna certificación salvo que la tengas
     vigente. Una declaración falsa es fácilmente comprobable. -->

**Si se produce una brecha** que probablemente entrañe un riesgo para tus
derechos, lo notificaremos a la autoridad de control competente en un plazo de
**72 horas** desde que tengamos conocimiento, y te lo comunicaremos directamente
y sin dilación indebida cuando el riesgo para ti sea alto.

---

## 10. Menores

<PRODUCTO> no está dirigido a menores de <EDAD> años y no recogemos sus datos
personales conscientemente. Si crees que un menor nos ha facilitado datos
personales, escribe a <privacidad@DOMINIO> y los eliminaremos con prontitud.

---

## 11. Reclamaciones

Si no estás conforme con cómo tratamos tus datos, contáctanos primero en
<privacidad@DOMINIO> — nos gustaría tener la oportunidad de resolverlo.

También tienes derecho a reclamar ante una autoridad de protección de datos:

- **España** — Agencia Española de Protección de Datos (AEPD), <aepd.es>.
- **México** — <AUTORIDAD COMPETENTE>.
- **Colombia** — Superintendencia de Industria y Comercio (SIC), <sic.gov.co>.
- **Argentina** — Agencia de Acceso a la Información Pública (AAIP), <argentina.gob.ar/aaip>.
- **UE** — la autoridad de control de tu país de residencia, de tu lugar de
  trabajo o del lugar donde se produjo el problema.
- **<OTRA JURISDICCIÓN>** — <AUTORIDAD Y ENLACE>.

---

## 12. Información regional

<!-- Incluye solo lo que te aplique. Elimina el resto. -->

### Residentes de California (CCPA/CPRA)

En los últimos 12 meses hemos recogido las categorías de información personal
descritas en la sección 2: identificadores, información comercial, actividad en
internet y geolocalización inferida de la dirección IP. Las fuentes, finalidades
y destinatarios se detallan en las secciones 2 y 3.

**No vendemos tu información personal ni la compartimos para publicidad
comportamental entre contextos.** Por ello no ofrecemos un enlace de "Do Not
Sell or Share My Personal Information" — si eso cambiara, actualizaríamos esta
política e incluiríamos el enlace.

Tienes derecho a saber, eliminar, corregir y a oponerte a la venta o cesión, y a
no sufrir discriminación por ejercer esos derechos. Usa los enlaces de
autoservicio de la sección 7 o escribe a <privacidad@DOMINIO>. Puedes actuar a
través de un agente autorizado. Respetamos la señal **Global Privacy Control**.

### Brasil (LGPD) · <OTRA>

<Añade las secciones equivalentes que apliquen, o elimina.>

---

## 13. Cambios en esta política

Actualizaremos esta política cuando cambien nuestras prácticas. La versión y la
fecha figuran al principio, y las versiones anteriores se archivan en <ENLACE>.

Ante cambios **sustanciales** — una nueva finalidad, una nueva categoría de
datos o un nuevo destinatario — te lo notificaremos por correo electrónico y,
cuando el cambio se base en el consentimiento, te lo solicitaremos de nuevo
antes de que surta efecto.

---

## 14. Contacto

| | |
|---|---|
| **Privacidad** | <privacidad@DOMINIO> |
| **Correo postal** | <RAZÓN SOCIAL, DIRECCIÓN COMPLETA> |
| **Comunicación de vulnerabilidades** | <seguridad@DOMINIO> · <URL>/.well-known/security.txt |
| **Compromiso de respuesta** | Respondemos a las consultas de privacidad en <2 días hábiles> y completamos las solicitudes en el plazo de un mes |

---

<!--
  LISTA DE VERIFICACIÓN antes de publicar
  ───────────────────────────────────────
  [ ] Todos los marcadores sustituidos; secciones inaplicables eliminadas
  [ ] Sección 3 contrastada con el código (grep al principio de este archivo)
  [ ] Cada plazo de la sección 5 está respaldado por un proceso real y vigilado
  [ ] El flujo de borrado de la sección 8 coincide con lo que hace el sistema
  [ ] Los enlaces de autoservicio funcionan y están a ≤3 clics dentro del producto
  [ ] La sección 9 no afirma nada falso — ninguna certificación no obtenida
  [ ] Banner de cookies probado en ventana privada: nada carga antes del consentimiento
  [ ] Enlazada desde el pie de todas las páginas, y desde el registro y el pago
  [ ] Revisada por un abogado especializado en protección de datos
  [ ] Existe un recordatorio en el calendario para la revisión anual
-->
