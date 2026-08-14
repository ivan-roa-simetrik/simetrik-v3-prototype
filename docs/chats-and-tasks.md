# Chats and Tasks

> Última actualización: 2026-08-14
> Archivo relacionado: `flows/home/index.html` (markup + `<style>` + script, todo inline al final del archivo)
> Ver también: [`sidebar.md`](./sidebar.md) → nav item "Chats and Tasks" (dispara esta vista), [`home.md`](./home.md) → vista Projects (el patrón visual que esta vista replica)

## Propósito

Vista global de todos los chats de la cuenta, sin el recorte que ya aplican **Pinned** (chats anidados dentro de sus proyectos) y **Recent** (chats sueltos sin proyecto) en el sidebar — a diferencia de esas dos, acá se listan *todos*, con o sin contexto. Se abre desde el nav item del sidebar, que hasta la primera pasada solo mostraba el empty state genérico compartido con Apps/Agents.

**Nota de alcance (2026-08-13):** el concepto de "Task" no está definido todavía — por instrucción explícita del usuario, esta vista solo modela **Chats**. No hay ningún tratamiento visual de "Task" en la UI. Cuando ese concepto se defina, esta vista es donde debería aparecer.

**Rebautizado a "Chats" (2026-08-13, quinta pasada).** El label del nav item, su tooltip y el `<h1>` de esta vista pasaron de "Chats and Tasks" a **"Chats"** — pedido explícito del usuario para sacar la palabra "task" del copy visible mientras el concepto siga sin definir. El nombre interno (`data-nav="chats-tasks"`, este archivo `chats-and-tasks.md`, nombres de función/variable en el código) se mantiene sin cambios — es el identificador de la sección, no copy que el usuario vea.

## Modelo de datos: qué es un chat acá

Un chat es el inicio de una conversación con un agente. Puede:
- estar **suelto** (sin ningún contexto asociado), o
- estar asociado a un **Project**, una **App**, o un **Agent** — los mismos tres tipos que ya modelan el selector de contexto gris del composer y el picker del panel lateral del chat (`PROJECTS_DATA`/`PANEL_APPS_DATA`/`PANEL_AGENTS_DATA`).

Un chat nunca "es" de naturaleza project/app/agent — el contexto es un atributo del chat, no una categoría exclusiva de chat. Eso es justo lo que `CHATS_DATA` modela: cada entrada tiene `context: { type: 'project'|'app'|'agent', id } | null`.

`CHATS_DATA` consolida en un solo array los 6 nombres de chat que ya existían repartidos en dos lugares sin relación entre sí (markup estático de Pinned/Recent en el sidebar, y `SEARCH_DATA.chats` del modal Cmd+K — ninguno de los dos tenía un campo de contexto real). Se agregaron 2 chats nuevos (`Google Drive sync check`, `Period close agent review`) únicamente para que las filas de contexto App y Agent tuvieran al menos un ejemplo real — el resto de los nombres ya existía en el prototipo. `createdAt` es texto fijo por ítem ("2 days ago", "1 week ago"...), no una fecha real calculada — mismo criterio de mock data estática que el resto del prototipo.

**No conectado a otras fuentes de datos — con una excepción nueva (2026-08-14).** Igual que `PROJECTS_DATA` vs. el markup estático de Pinned, o `SEARCH_DATA` vs. `PROJECTS_DATA`: los 6 nombres mock originales de `CHATS_DATA` no derivan ni sincronizan con Pinned/Recent/Search, y archivar/renombrar un chat acá tampoco toca esos otros lugares. La excepción es hacia adelante, no hacia atrás: **arrancar un chat nuevo** (`registerNewChat`, ver `docs/chat.md`) sí hace `CHATS_DATA.unshift(...)` **y** agrega la fila equivalente al Recent del sidebar en el mismo momento — así que, de acá en más, un chat recién creado existe consistentemente en ambos lugares desde el arranque. Lo que sigue sin sincronizarse son los cambios *posteriores* (archivar, renombrar, pinear) y los 6 chats mock que ya existían antes de este mecanismo.

## Decisiones tomadas

- **Mismo patrón visual que la vista Projects, pero simplificado.** Título + buscador en el header, sin Filter (no hay tags en un chat) y sin toggle grid/list (solo lista, por instrucción explícita — un chat es una fila, no una card). Clases propias (`.chats-*`, `.chat-list-row*`), copiadas 1:1 del look de `.projects-view-header`/`.project-list-row` en vez de compartir el nombre de clase — este archivo ya se golpeó dos veces con colisiones de clase entre componentes visualmente iguales pero funcionalmente independientes (`.project-row`, `.search-tab`; ver `home.md`), así que cada vista nueva parte de clases propias por default.
- **Click en una fila: no-op**, mismo criterio que las cards de Projects, las filas de Pinned/Recent y los resultados del modal Search — ninguno de esos navega a nada real todavía, y esta vista no rompe esa consistencia.
- **Campos por fila**: ícono de chat (`message-circle-more`, el mismo que ya usa "New Chat" y el header del hilo sin contexto) + nombre del chat + ícono y nombre del contexto (Project/App/Agent) si tiene, en blanco si no tiene + fecha de creación (texto fijo). El ícono de contexto reusa `iconForItem()`/`findPanelItem()`, las mismas funciones que ya resuelven esto para el header del hilo de chat y el panel lateral — ningún ícono nuevo, ninguna lógica de resolución nueva.
- **Selección masiva ("Select").** Botón al lado de "New Chat" que entra a un modo de selección: aparece un checkbox por fila, las filas se vuelven clickeables (toggle de selección, único lugar donde el click en una fila SÍ hace algo), la ellipsis por fila se oculta, y los controles del header (buscador, Select, New Chat) se reemplazan por una barra de "N selected" + Cancel + Archive. **Archive es la única acción masiva** — explícitamente no hay Delete ni "mover a proyecto". Sin vista de "Archived" para verlos después, mismo gap ya aceptado para el Archive de Projects.
- **"New Chat" del header de esta vista dispara el mismo botón de siempre** (`document.getElementById('newChatBtn').click()`) en vez de reimplementar el reset — un solo lugar de verdad para "qué pasa al iniciar un chat nuevo".
- **Ellipsis por fila: una sola acción, "Rename chat", visible pero sin implementar.** Por instrucción explícita, no abre ningún modal ni campo inline todavía — clickearla solo cierra el popover, mismo criterio placeholder que otras acciones no cableadas del prototipo (ej. "Edit detail" antes de tener su modal).
- **Loading skeleton, mismo tratamiento que Projects (2026-08-13, agregado en la segunda pasada).** `queryChatsWithLoading(delay)` centraliza el ciclo (oculta lista/empty reales, muestra el skeleton, espera `delay` ms, renderiza) — 700ms al entrar a la sección (`loadChatsView`), 400ms en cada re-búsqueda con debounce de 300ms (mismo criterio que Projects). Nunca se dispara en Select/Archive, mismo criterio ya usado por Projects para Pin/Unpin/Archive. Reusa el mismo `@keyframes skeletonShimmer` que ya usa el skeleton de Projects, con clases propias (`.chat-skeleton-*`) — no comparte nombre con `.project-skeleton-*`.
- **Reset del modo selección al entrar a la sección.** Cada vez que se navega a "Chats and Tasks" desde el nav, `setChatsSelectMode(false)` fuerza el estado por defecto — evita quedar "atrapado" en modo selección de una visita anterior sin darse cuenta.

## Pin / Unpin: impacta el Pinned del sidebar (2026-08-13, tercera pasada)

Nueva primera opción en la ellipsis de cada fila: **Pin chat / Unpin chat** (ícono `pin`/`pin-off` según `chat.pinned`), antes de "Rename chat". Pedido explícito del usuario: que fijar un chat acá **impacte directamente** el listado de Pinned del sidebar, y que un chat ya pineado tenga **las mismas acciones de la ellipsis disponibles directamente desde el sidebar**.

- **Un solo Pinned, no dos listas.** Pinear un chat lo agrega como fila nueva dentro del mismo `<ul class="project-list">` donde ya viven los 3 proyectos pineados — Pinned es una sola lista curada por el usuario (proyectos y chats mezclados), no una sección de "chats pineados" aparte debajo.
- **Mismo principio que `toggleProjectPinned`/`ensureSidebarPinnedItem`** (el mecanismo que ya existía para que un proyecto recién creado se pinee sin tener markup estático previo): `toggleChatPinned(id)` es el único punto de verdad, llamado tanto desde la ellipsis de esta vista como desde la ellipsis del sidebar — nunca dos implementaciones de "la misma acción". Como ningún chat tiene fila estática en el sidebar (a diferencia de los 3 proyectos originales), **todo chat pineado pasa por la rama dinámica**: `ensureSidebarPinnedChatItem(chat)` crea el `<li>` + su popover portal la primera vez que se pinea; unpinear solo lo oculta (`hidden`), no lo destruye — volver a pinear el mismo chat reutiliza el mismo `<li>`/popover en vez de duplicarlo.
- **La fila en el sidebar es un botón plano, sin expandir/colapsar** — a diferencia de los proyectos (folder↔folder-open + chats anidados), un chat no tiene sub-items que revelar. Mismo ícono de chat (`message-circle-more`) que el resto del prototipo.
- **Ellipsis del sidebar: popover propio por chat pineado** (portal, mismo motivo de overflow-clipping que ya obliga a los popovers de proyecto a vivir fuera del subárbol del sidebar — ver `sidebar.md`), con 2 acciones: **Unpin chat** (siempre esta label, nunca "Pin chat" — el popover solo existe una vez el chat ya está pineado, no hay ambigüedad que resolver) y **Rename chat** (llama a la misma función `renameChat()` que la ellipsis de esta vista — ver sección siguiente).
- **Clases 100% propias** (`.sidebar-pinned-chat-*`), viven en `shared/tokens.css` junto a `.sidebar-project-actions-*` — nunca comparten nombre con `.project-row`/`.sidebar-project-actions-*`, mismo criterio que el resto del archivo.
- **Todos los chats arrancan sin pinear** (`pinned: false` en `CHATS_DATA`) — a diferencia de los 3 proyectos mock (que ya nacen `pinned: true` porque así estaban en el sidebar desde el principio), acá no hay ningún estado previo que replicar, así que el punto de partida honesto es vacío.
- **Verificado end-to-end con Chrome headless** (no solo lectura de código): click real en la ellipsis → "Pin chat" → aparece en el sidebar con el nombre correcto → la ellipsis de esta vista refleja "Unpin chat" al reabrirse → click en la ellipsis del sidebar → "Unpin chat" ahí → la fila del sidebar se oculta. Los 3 tipos de contexto (Project/App/Agent) se probaron pineados a la vez.

## Rename chat: modal real (2026-08-13, cuarta pasada)

"Rename chat" deja de ser no-op — abre un modal real (`#renameChatModalBackdrop`/`.rename-chat-modal`) con el mismo tratamiento visual que el resto de los modales del prototipo (backdrop con blur, scale-in centrado, header con título + cerrar, footer con Cancel/acción primaria), pedido explícito del usuario ("con las definiciones que tenemos de modal").

- **Un solo campo**: input de texto "Chat name", pre-rellenado con el nombre actual y con foco + selección automática al abrir (para poder empezar a escribir el nombre nuevo inmediatamente). Reusa `.create-project-field`/`.create-project-field-label` — el mismo primitivo genérico de campo-con-label que ya reusa el modal de Edit project, nada nuevo que mantener.
- **"Save changes" arranca deshabilitado solo si el campo queda vacío** — mismo criterio mínimo de validación que el resto de los formularios del prototipo (Create project, Edit project). Enter en el input también dispara el guardado si está habilitado.
- **Una sola instancia compartida por las dos ellipsis** (la de esta vista y la del sidebar): `renameChat(id)` — la función que antes solo cerraba el popover — ahora llama a `openRenameChatModal(id)`, que busca el chat en `CHATS_DATA` y prellena el modal. Mismo principio que `openProjectEditModal`: construir el formulario una sola vez es lo que hace que renombrar funcione desde cualquiera de los dos entry points sin wiring adicional.
- **Actualiza el nombre directamente en `CHATS_DATA`** (`chat.name = ...`) al guardar, y re-renderiza la lista de esta vista (`applyChatsFilters()`). Si el chat está pineado, también empuja el nombre nuevo al `<span class="sidebar-pinned-chat-name">` de su fila en el sidebar — a diferencia del rename de Projects (que necesita buscar la fila del sidebar *por el nombre viejo antes* de sobreescribirlo, porque `findSidebarPinnedItem` matchea por texto), acá `findSidebarPinnedChatItem` matchea por `data-chat-id` — el id nunca cambia, así que no importa en qué momento se haga la búsqueda.
- **Verificado end-to-end con Chrome headless**: pinear un chat → abrir su ellipsis → "Rename chat" → modal abre pre-rellenado con foco automático → cambiar el texto → "Save changes" → el modal cierra, la fila de esta vista muestra el nombre nuevo, y la fila correspondiente en el sidebar Pinned también.
- **Fuera de alcance**: no valida nombres duplicados, no hay confirmación de "cambios sin guardar" al cerrar sin guardar (Cancel/X/Escape/click afuera descartan directamente, mismo criterio que el resto de los modales del prototipo).

## Tabs All / Archived (2026-08-13, quinta pasada)

Nuevas tabs debajo del header, arriba de la lista: **All** / **Archived** — pedido explícito del usuario, en anticipación a que se archiven chats desde acá (bulk Archive ya existía, pero no había ningún lugar para volver a verlos). Mismo patrón que las tabs de ownership de Projects (`.projects-ownership-tab`), simplificado a solo 2 (acá no hay concepto de "owner").

- **Clase propia** (`.chats-view-tab`), copiada 1:1 de `.projects-ownership-tab` en vez de reusada — mismo motivo de siempre: el modal Search tiene un wiring global sobre `.search-tab` que stompearía el estado activo de cualquier tab que comparta ese nombre.
- **`chatsTab` ('all' | 'archived')** es la segunda dimensión de filtro, combinada con la búsqueda en `getFilteredChats()`: `CHATS_DATA.filter(c => c.archived === showArchived)`. El buscador sigue funcionando dentro de cada tab (buscar en Archived busca solo entre los archivados).
- **Mensaje de empty state dedicado**: "No archived chats." en vez del genérico "No chats match your search." cuando la tab activa es Archived y no hay nada — mismo criterio que ya usa Projects para su propia tab Archived.
- **"Select" se oculta en la tab Archived** — no tiene sentido archivar en bulk algo que ya está archivado (la única acción masiva que existe hoy es Archive). Si el usuario estaba en modo selección y cambia de tab, `setChatsSelectMode(false)` lo saca automáticamente — evita dejar ids seleccionados de una lista que ya no se ve.
- **Ellipsis de un chat archivado: solo "Rename chat", sin Pin/Unpin.** Mismo criterio que Projects ya aplica a sus propias cards archivadas (ver comentario en `projectActionsMenuMarkup`): pinear algo en estado terminal "archivado" podría resucitar en silencio una fila del sidebar para un chat que ya no aparece en la tab All. `chatActionsMenuMarkup(c)` ahora ramifica por `c.archived`.
- **La tab seleccionada persiste entre visitas a la sección** (no se resetea a "All" al re-entrar) — mismo criterio que Projects, que tampoco resetea su filtro de ownership ni el término de búsqueda al volver a la vista. Solo el modo de selección masiva se resetea siempre (`setChatsSelectMode(false)` en `onNavSectionChange`).
- **Verificado end-to-end con Chrome headless**: archivar un chat vía Select → desaparece de All → aparece en Archived → su ellipsis ahí solo tiene Rename (no Pin) → "Select" está oculto en Archived → volver a All lo sigue mostrando correctamente excluido.
- **Fuera de alcance / pendiente**: no hay acción de "Unarchive"/restaurar todavía — un chat archivado se queda ahí permanentemente en este prototipo, mismo gap que Projects tiene hoy para sus propios archivados (solo tienen Delete, no restore).

## Estado actual de implementación

- ✅ Vista real reemplaza el empty state genérico para `data-nav="chats-tasks"` — `sectionCopy['chats-tasks']` se eliminó, ya no hace falta.
- ✅ Header título + buscador (mismo mecanismo morph botón↔input que Projects, clases propias)
- ✅ Lista de filas con ícono + nombre + contexto (Project/App/Agent o ninguno) + fecha
- ✅ Selección masiva: checkboxes, contador, Cancel, Archive (única acción real)
- ✅ Ellipsis por fila con "Rename chat", abre un modal real (ver sección abajo)
- ✅ "New Chat" del header reusa el botón real del sidebar
- ✅ Loading skeleton en entrada a la sección y en cada búsqueda (ver arriba)
- ✅ Pin/Unpin sincroniza en ambas direcciones con el sidebar, incluida la ellipsis dinámica por chat pineado ahí (ver sección arriba)
- ✅ Rename chat actualiza `CHATS_DATA` y sincroniza con el sidebar si el chat está pineado (ver sección abajo)
- ⛔ Sin persistencia — recargar la página vuelve `CHATS_DATA` a su estado inicial (chats archivados/pineados vuelven a su estado inicial)
- ⛔ El concepto de "Task" sigue sin definir — nada en esta vista lo representa todavía
- ✅ Archivar un chat pineado (bulk Archive) también oculta su fila del sidebar Pinned, mismo criterio que el Archive de Projects
- ✅ Tabs All / Archived con su propio filtro, empty state dedicado y ellipsis recortada para archivados (ver sección arriba)
- ✅ Nav item, tooltip y título de la vista dicen "Chats" (ya no "Chats and Tasks")

## Bug encontrado y corregido: el margin-top de la vista no se aplicaba

Al construir la vista, `.chats-view { flex: 1; overflow-y: auto; padding: 32px 40px; }` nunca llegaba a renderizarse — la vista quedaba pegada arriba del todo, sin el padding de 32px que sí tiene Projects. Causa raíz: el comentario CSS que documenta la sección contenía, sin querer, la secuencia literal `*/` dentro del texto (`(.chats-*/.chat-list-row*)`, `.projects-*/.project-list-row`) — eso cierra el comentario a mitad de frase, y todo lo que sigue hasta el siguiente punto de recuperación del parser (incluida la regla `.chats-view` real) queda corrompido y se descarta silenciosamente. Se reprodujo con Chrome headless real (no solo lectura de código): `getComputedStyle('#chatsView')` mostraba `flex: 0 1 auto` y `padding: 0px` (los valores por defecto, como si la regla no existiera). Fix: reescrito el comentario para no formar `*/` accidentalmente (`.chats-*` y `.chat-list-row*` en vez de `.chats-*/.chat-list-row*`). Verificado de nuevo con Chrome headless: `flex: 1 1 0%`, `padding: 32px 40px`, altura completa. **Lección para el resto del prototipo**: cualquier comentario CSS que mencione selectores con `*` (wildcard/prefijo) separados por `/` puede formar `*/` sin querer — revisar antes de escribir ese patrón en un comentario.

## Pendiente / abierto

- **Definir qué es una Task** y cómo convive con los Chats en esta misma vista (¿tipo de ítem distinto con su propio ícono/status, o una etiqueta sobre un chat existente?).
- **"Rename chat" propagado a Recent/Search**: el nombre editado se propaga a `CHATS_DATA` y al sidebar Pinned si el chat está ahí, pero no a `SEARCH_DATA.chats` (Cmd+K) ni al markup estático de Recent — esos siguen siendo mocks independientes.
- **¿Archivar un chat acá debería reflejarse en Recent/Search?** Hoy no toca esos dos — solo el sidebar Pinned (si estaba ahí). Mismo tipo de brecha ya documentada entre `PROJECTS_DATA` y el markup estático de Pinned.
- **Sin "Unarchive"/restaurar** — un chat archivado se queda ahí permanentemente en este prototipo (ver sección de tabs arriba), mismo gap que tiene Projects hoy (solo Delete, no restore).

## Archivos relacionados

- `flows/home/index.html` — markup (`#chatsView`), estilos inline (`.chats-*`, `.chat-list-row*`, `.chat-actions-menu`), y el script: `CHATS_DATA`, `getFilteredChats`, `renderChatsList`, `applyChatsFilters`, `loadChatsView`, `setChatsSelectMode`, `toggleChatSelected`, `archiveSelectedChats`, `wireChatsListDelegation`, `initChatsView` — reusa `findPanelItem`/`iconForItem`/`PANEL_OPEN_ICONS` ya definidos para el picker del panel lateral y el selector de contexto.
- [`sidebar.md`](./sidebar.md) — nav item "Chats and Tasks", ahora resuelto (ver su propia sección "Pendiente / abierto").
- [`home.md`](./home.md) — vista Projects, el patrón visual/de header que esta vista replica.
