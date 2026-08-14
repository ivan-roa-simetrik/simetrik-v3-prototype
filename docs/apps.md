# Apps (concepto de dominio)

> Última actualización: 2026-08-14
> Este archivo es distinto a los demás de `docs/`: no documenta una pantalla todavía construida, documenta el **modelo conceptual** detrás de la entidad "App" — qué es, cómo se relaciona con Proyectos y con Chats, y cómo se crea/abre una — antes de escribir código. Mismo criterio que `proyecto.md` tuvo para la entidad Proyecto: sentar el marco primero, para que la implementación no arrastre un malentendido de producto.

## Propósito

Hasta el 2026-08-14, "Apps" en el prototipo era un nav item con un empty state genérico ("Connect apps to your agents... this section will be built out in the next prototype iteration") y mock data que describía **integraciones externas** (`Slack`, `Snowflake`, `Google Drive`) — como si una App fuera un conector a un sistema de terceros.

Esa idea queda **descartada explícitamente**. Este documento registra la definición real, dada directamente por el usuario, antes de construir nada:

1. Para que la vista, el mock data y el copy que se construyan después no arrastren el framing viejo de "integraciones" sin querer.
2. Para que quede claro *por qué* el comportamiento de abrir/crear una App se calca del que ya existe para abrir/crear un Proyecto — no es una coincidencia de UI, es la misma mecánica aplicada a una entidad distinta.
3. Como referencia obligatoria antes de tocar el nav item Apps, la futura vista de listado, o el tab "App" del panel lateral del chat.

## Modelo conceptual

### Qué es una App

Una App **no es una integración ni una conexión a una aplicación externa**. Es un **artefacto persistido, construido conversacionalmente con el agente**, que opera sobre datos financieros para resolver una necesidad puntual del usuario. Según la necesidad, una App puede:

- Analizar un proyecto (o varios).
- Tomar decisiones a partir de esos datos.
- Generar informes.
- Generar comunicados.
- Hacer análisis ad hoc.
- Ingestar o accionar sobre datos de un proyecto (a nivel de datos, no solo lectura) — el alcance exacto de "accionar" queda abierto, ver Pendiente.

No hay un catálogo cerrado de "tipos de App" — el usuario define, chateando, qué necesita que la App haga. Una App es, en ese sentido, más parecida al concepto de "Artifact" persistido con nombre propio que a una integración de terceros.

### Relación con Projects: muchos a muchos

A diferencia de un Proyecto (que es dueño de su propia data/fuente), **una App es transversal a los Proyectos**:

```
App
├── puede jalar información de 0 proyectos   (App standalone, sin proyecto asociado)
├── puede jalar información de 1 proyecto    (App scoped a un solo proyecto)
└── puede jalar información de N proyectos   (App que cruza data de varios — ej. un
                                               informe que combina 3 proyectos distintos)
```

No existe una jerarquía de "la App vive dentro del Proyecto" — es una relación de referencia (`app.projects: [] | [id] | [id, id, ...]`), no de contención. Un Proyecto no "tiene" Apps propias; una App "referencia" Proyectos.

### Relación con Chats: igual mecánica que un Proyecto, aplicada a App

Una App puede tener **varios chats asociados** a lo largo del tiempo, igual que ya pasa con un Proyecto (ver `docs/chats-and-tasks.md` — `context: {type, id}` ya soporta `type: 'app'` desde que existe esa vista, sin necesitar cambios):

- El **primer chat** de una App es el que la crea (ver ciclo de vida abajo) — de esa conversación, el agente deriva el nombre de la App y una descripción de contexto.
- Los chats **siguientes** son iteraciones sobre una App ya construida: pedir un cambio, hacer una pregunta, refinar el análisis — no vuelven a crear la App, operan sobre la ya existente.
- Igual que un Proyecto, una App pineada en el sidebar debería poder mostrar sus chats anidados (mismo mecanismo ya construido para Proyectos en `Pinned`).

### Qué NO es una App (para no reintroducir el concepto viejo)

- No es un conector/integración a un sistema externo (Slack, Snowflake, Google Drive). Ese framing queda completamente descartado.
- No es un Agente. Un Agente (ver nav item "Agents", todavía sin definir a fondo) es una entidad distinta — la relación entre Agentes y Apps (¿un Agente puede invocar/usar una App como herramienta?) es una pregunta abierta, no parte de este documento.
- No vive "dentro" de un único Proyecto — ver relación muchos a muchos arriba.

## Ciclo de vida / interacción

Ambos flujos (crear y abrir) comparten el mismo mecanismo de layout que ya existe para Proyectos (`openProjectChat()` en `flows/home/index.html`, ver `docs/home.md` → "Clic en una card/fila: abre el chat del proyecto") — la diferencia es qué contenido termina en el panel derecho y en qué punto arranca ese contenido.

### Abrir una App existente

1. Colapsa el sidebar de navegación (si estaba expandido).
2. Entra directo al hilo de chat angosto (greeting propio, cero mensajes) — no a la pantalla de saludo completa.
3. El panel lateral derecho se auto-abre con esa App como su único tab, renderizando **el artefacto ya construido** (no un placeholder de textura, como sí sigue teniendo hoy el tab de Project con la vista de mapa).
4. El usuario decide: operar directo sobre la App renderizada, o conversar en el chat (a la izquierda) para pedir un cambio o hacer una pregunta sobre ella.

### Crear una App nueva

Mismo mecanismo, arrancando en blanco — **no** un modal de formulario (nombre + descripción a mano):

1. Disparado desde el "+" del nav item Apps (o equivalentes que se agreguen después — ver Pendiente).
2. Mismo chat angosto + panel auto-abierto, pero sin ninguna App todavía.
3. El greeting pregunta el objetivo — qué quiere construir el usuario / para qué necesita la App.
4. El panel derecho arranca **vacío y empieza a construirse en vivo** a medida que avanza la conversación — mismo espíritu que la decisión ya tomada para el Project Map (ver memoria `project-view-map-plan`: "el mapa empieza vacío; el primer mensaje del chat dispara el reveal animado"). No hay contenido sembrado de antemano.
5. De esa conversación inicial, **el agente deriva el nombre de la App y una descripción de contexto** (qué hace, para qué sirve) — mismo mecanismo que ya deriva el título de un chat a partir del primer prompt (`deriveChatTitle()`), aplicado ahora también a nombrar la entidad App, no solo el chat que la contiene.
6. Al cerrarse ese intercambio inicial, la App queda registrada en el catálogo (equivalente conceptual a `createProject()` + `registerNewChat()` combinados, aplicado a App).

## Modelo de datos previsto (para cuando se construya)

Todavía no implementado — esta es la forma que debería tener `APPS_DATA` cuando se construya la vista real, análoga a `PROJECTS_DATA`:

```js
{
  id: 'slug-generado-del-nombre',
  name: 'Nombre derivado por el agente en la conversación inicial',
  description: 'Descripción de contexto derivada por el agente',
  icon: 'lucide-icon-name',
  projects: [],          // 0..N ids de PROJECTS_DATA — nunca un solo projectId obligatorio
  status: 'active' | 'draft', // por confirmar al construir, ver Pendiente
  pinned: false,
  archived: false,
}
```

Los chats de una App no se duplican acá — siguen viviendo en `CHATS_DATA` con `context: {type: 'app', id}`, mismo mecanismo que ya existe para Project.

## Estado actual de implementación (2026-08-14 — construido)

Todo lo descrito arriba ya está implementado en `flows/home/index.html`. Detalle completo del build en `docs/home.md` → sección "Apps"; acá solo el resumen frente al modelo conceptual:

- ✅ **Vista de catálogo real** (`#appsView`): grid/list, buscador, Filter by project (multi-select sobre los proyectos que al menos una App referencia), tabs All/Pinned/Archived, loading skeleton (mismo patrón 700ms/400ms/debounce 300ms que Projects), ellipsis con Edit detail/Pin-unpin/Archive (Edit detail/Delete si está archivada).
- ✅ **3 Apps sembradas**, demostrando el rango 0/1/N de proyectos: `Bank Reconciliation Summary` (1 proyecto), `Quarterly Anomaly Digest` (2 proyectos), `Board Update Draft` (0 proyectos, `status: 'draft'`).
- ✅ **Ciclo de vida completo**: `openAppChat()`/`showAppChatGreeting()` (abrir una App existente, generalización 1:1 de `openProjectChat`) y `startNewAppFlow()`/`createApp()` (crear una App nueva, generalización de `startNewProjectFlow`) — mismo mecanismo de `pendingNameFromChat` que ya usaba Project, extendido a App dentro de `startChat()`.
- ✅ **El tab `app` del panel lateral ya no es placeholder de texto** — `renderAppArtifactTab()` muestra un estado "not built yet" (mismo lenguaje visual que el empty state del Project Map) mientras `pendingNameFromChat` es `true`, y el artefacto real (ícono/nombre/status, proyectos de origen como pills, cuerpo generado) una vez definido por el primer mensaje.
- ✅ **Mock de integraciones reemplazado en todos los lugares donde se listaban Apps**: `PANEL_APPS_DATA` (picker del panel lateral, selector de contexto del chat, menciones `@`) pasó a ser `APPS_DATA`; `SEARCH_DATA.apps` (modal Cmd+K) actualizado a los 3 nombres reales; el chat de ejemplo con contexto App en `CHATS_DATA` (antes `google-drive-sync-check`) se retargeteó a `bank-reconciliation-summary`.
- ✅ El "+" de "New App" (nav item, hover-reveal) y el botón "New App" dentro de la propia vista Apps ambos disparan `startNewAppFlow()`.
- ⛔ **Pin/Unpin es local a esta vista, no sincroniza con el sidebar** — a diferencia de Projects (cuyo Pin/Unpin sí crea/oculta una fila en `Pinned`), togglear el pin de una App solo mueve su visibilidad entre las tabs All/Pinned de `#appsView`. Decisión explícita de esta pasada para no invadir el lado del sidebar (propiedad de otra persona en este prototipo) — ver Pendiente.
- ⛔ El ícono "Project chats"/"New chat" del header del hilo de chat sigue siendo específico de Project (`isProjectChat` en `updateChatThreadHeader`) — abrir una App no muestra un histórico equivalente de "App chats" todavía, aunque el modelo de datos (`CHATS_DATA.context.type === 'app'`) ya lo soportaría.

## Pendiente / abierto

- **Pin/Unpin de una App en el sidebar**: hoy no crea una fila en `Pinned` como sí hace Projects (`ensureSidebarPinnedItem`) — generalizar ese mecanismo (o construir uno propio, `.sidebar-pinned-app-*`) es la extensión natural, pendiente de instrucción explícita.
- **"App chats" en el header del hilo**: el ícono de historial que ya existe para Project (`#chatHistoryToggle`) podría generalizarse para mostrar los chats de una App también, ya que `CHATS_DATA.context` ya soporta ese caso — no se tocó en esta pasada para no ampliar de más el alcance de `updateChatThreadHeader`.
- **¿Qué significa "accionar sobre datos de un proyecto" en la práctica?** El usuario mencionó que una App podría "ingestar o tomar decisiones dentro del mismo proyecto a nivel de datos" — no se implementó ninguna escritura real hacia `PROJECTS_DATA`, el artefacto renderizado es de solo lectura/mock.
- **Edición de proyectos vinculados ya está resuelta** (el modal "Edit detail" incluye un checklist de proyectos, `appEditProjectsList`) — lo que sigue abierto es si además debería poder pedirse conversacionalmente ("agregá el proyecto X a esta app") en vez de solo desde el modal.
- **Relación con Agents**: ¿un Agente puede usar una App como herramienta/capacidad? Sigue sin resolver — Agents no tiene su propio documento conceptual todavía.
- **`SEARCH_DATA.apps` sigue desacoplado de `APPS_DATA`** (mismo criterio ya aceptado para `SEARCH_DATA.projects`) — una App creada por el usuario no aparece en el buscador Cmd+K.
- **Status de una App** (`active`/`draft`): semántica todavía no confirmada explícitamente por el usuario más allá de la extrapolación de Projects (`production`/`draft`) — hoy solo cambia mostrando el badge, no dispara ningún comportamiento distinto.

## Archivos relacionados

- `flows/home/index.html` — `sectionCopy.apps` (empty state a reemplazar), `PANEL_APPS_DATA`/`SEARCH_DATA.apps` (mock a reemplazar), `renderPanelTabContent` (tab `app` del panel, hoy placeholder de texto), `openProjectChat()` (mecánica de referencia a generalizar para App)
- `docs/home.md` → sección "Clic en una card/fila: abre el chat del proyecto" — el comportamiento exacto que este documento pide replicar para Apps
- `docs/chat.md` → "Pendiente / abierto" — el gap de "Generación de apps desde el chat" que este documento empieza a resolver conceptualmente
- `docs/chats-and-tasks.md` — `CHATS_DATA.context`, ya preparado para `type: 'app'`
- `docs/proyecto.md` — mismo tipo de documento (concepto de dominio, no de pantalla), mismo criterio de "sentar el modelo antes de construir"
