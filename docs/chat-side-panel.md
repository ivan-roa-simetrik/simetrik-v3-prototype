# Panel lateral del chat

> Última actualización: 2026-08-13
> Archivo relacionado: `flows/home/index.html` (markup + `<style>` + script, todo inline al final del archivo)
> Ver también: [`chat.md`](./chat.md) — el chat en general (composer, mensajes, header del hilo). Este archivo es la extensión del panel lateral que ese documento solo resumía; se separó a un archivo propio por la cantidad de comportamiento/bugs acumulados en esta sola pieza.

## Propósito

Un panel que vive al lado de la conversación (no reemplaza el chat, convive con él) para eventualmente abrir Proyectos, Apps o Agentes sin salir del hilo — hoy es el mecanismo completo (abrir, tener varios a la vez como tabs, cerrar, buscar/filtrar), con contenido de cada uno todavía en placeholder. Se dispara con el botón `panel-right` (`#chatPanelToggle`), anclado en la esquina superior derecha del chat, visible solo una vez la conversación está en estado de hilo activo. Al lado, `#chatPanelExpandToggle` ("Expand"/"Restore width") lleva ese enfoque un paso más allá: un modo foco que oculta también la conversación y el sidebar de navegación, dejando la pantalla entera para el contenido del panel.

No es un sidebar de navegación (ese es `docs/sidebar.md`, un componente completamente distinto) — este panel es local al chat: solo existe dentro de `.chat-pane`, se resetea al iniciar un chat nuevo, y no tiene relación con la navegación general de la app.

## Estructura

```
.chat-side-panel (#chatSidePanel)
├── Open picker (#panelOpenPicker) ─── visible cuando NO hay tabs abiertos
│   └── .panel-open-inner (320px, centrado en los dos ejes del panel)
│       ├── Título: "What do you want to open?"
│       ├── Buscador en vivo (#panelOpenPickerSearch)
│       ├── Tabs de filtro: All / Projects / Apps / Agents (.panel-filter-tab)
│       └── Resultados (#panelOpenPickerResults, alto fijo 280px, scroll interno)
│           └── agrupados por categoría cuando el filtro es "All"
│
└── Tabs view (#panelTabs) ─── visible cuando SÍ hay ≥1 tab abierto
    ├── Barra de tabs (.panel-tabs-bar, 50px fijos de alto)
    │   ├── Lista de tabs (#panelTabsList, shrink-to-fit + scroll horizontal propio)
    │   │   └── por cada tab: ícono de categoría + nombre + botón de cerrar (x)
    │   └── Botón "+" (.panel-tab-add-btn) — hermano fijo de la lista, no un tab más
    │       └── Popover (#panelOpenMenu, 300px) — mismo buscador + tabs de filtro + resultados
    │           que el open picker, alineación dinámica align-start/align-end
    └── Contenido del tab activo (#panelTabContent) — placeholder de texto por ahora
```

`[hidden]` sobre `#panelOpenPicker`/`#panelTabs` hace que los dos estados sean mutuamente excluyentes — nunca se muestran ambos a la vez, y el picker vuelve a aparecer automáticamente en cuanto se cierra el último tab.

## Comportamiento

### Toggle: abrir/cerrar el panel

- El botón `#chatPanelToggle` (`panel-right`) le pertenece a la **vista**, no al chat en sí — vive como hijo directo de `.chat-pane` (no dentro de `.chat-thread-header`), posicionado `position: absolute; top: 11px; right: 20px` respecto a todo el pane. Se queda anclado ahí sin importar si el chat está a ancho completo o con el panel abierto.
- Solo es visible una vez el chat está en estado de hilo activo (oculto en el estado vacío y en las vistas de Apps/Agents/Projects del nav).
- Un clic colapsa `.chat-thread-main` (la columna de conversación) a **370px fijos** y revela `.chat-side-panel` ocupando el resto del ancho, a toda la altura. Otro clic revierte todo.
- **Los tabs abiertos se mantienen en memoria** al cerrar/reabrir el panel — no se pierden, solo se ocultan. Se resetean recién al iniciar un chat nuevo (`resetPanelTabs()`, ver más abajo).
- Animación fluida (420ms, ease-out): ambas columnas están siempre en el layout flex (nunca `display: none`), animando `flex-grow`/`flex-basis` y `opacity` — el colapso/revelación se siente como una sola transición coordinada, no un salto instantáneo.
- Estilo del ícono del toggle: siempre gris tenue (`--color-ink-faint`), abierto o cerrado — no se pinta de azul primario al activarse, para no competir visualmente con el resto de la UI.
- Tooltip: "Show panel" / "Hide panel" según el estado, alineado al borde derecho del botón (`.tooltip-end`) para no salirse de la pantalla estando en la esquina.
- Fondo del panel: `--color-sidebar-bg` (el mismo gris del sidebar de navegación, no blanco).

### Expand / Restore width: modo foco

Segunda acción, al lado de `#chatPanelToggle`, dentro del mismo wrapper (`.chat-panel-actions`, `position: absolute; top: 11px; right: 20px; display: flex; gap: 8px;` — agregar una acción más acá es solo sumar un hijo del flex, sin repetir la matemática de offset por separado en cada botón).

- **Botón `#chatPanelExpandToggle`** (ícono `maximize-2` / `minimize-2` según estado), visible solo cuando `#chatPanelToggle` también lo está (mismo ciclo de vida: aparece con `startChat`, se oculta al iniciar chat nuevo o navegar a Projects/Apps/Agents del nav).
- **Al activar "Expand"**:
  - `.chat-thread-main` (la columna de conversación) colapsa a **0** — no a 370px como con el toggle normal — y `.chat-side-panel` (ya `flex: 1 1 0%` bajo `.has-panel`) crece solo para ocupar el 100% de `.chat-pane`. Clase `.is-panel-expanded` en `.chat-thread`, reutiliza la misma transición de `flex-grow`/`opacity` que ya existía (420ms/320ms), solo empujada más lejos.
  - El **sidebar de navegación de la app** (`#sidebar`) se fuerza a colapsado (`classList.add('is-collapsed')`, la misma clase/mecanismo que usa su propio botón en `shell.js`) — el objetivo es un modo foco real, sin el nav ni la conversación compitiendo por atención, solo el contenido del panel.
  - Se recuerda si el sidebar **ya estaba colapsado antes** de activar Expand (`sidebarWasCollapsedBeforeExpand`). Si el usuario lo había colapsado a propósito de antemano, "Restore width" no se lo vuelve a expandir — solo revierte lo que Expand mismo cambió.
- **Al activar "Restore width"**: revierte `.is-panel-expanded` (la conversación vuelve a 370px) y restaura el sidebar a como estaba antes de Expand (expandido, salvo que ya estuviera colapsado).
- **Cierres en cascada**: cerrar el panel entero con `#chatPanelToggle` mientras está expandido también sale del modo foco (`setPanelExpanded(false)`) — "expandido" no tiene sentido sin panel abierto. Lo mismo al iniciar un chat nuevo o navegar a Projects/Apps/Agents del nav: se llama `setPanelExpanded(false)` junto con el reset de tabs, así el sidebar nunca queda colapsado "huérfano" sin que el usuario entienda por qué.
- **Reserva de espacio actualizada**: con dos botones (28px cada uno + 8px de separación = 64px) en vez de uno, `.chat-thread-header` y `.panel-tabs-bar` pasaron su `padding-right` de 56px a **92px** para seguir despejando el wrapper completo.

### Open picker: "What do you want to open?"

Es el estado por defecto del panel mientras no haya ningún tab abierto.

- **Tres fuentes**: **Projects** (reusa `PROJECTS_DATA`, los mismos proyectos de Pinned/composer/search), **Apps** (`PANEL_APPS_DATA`: Slack/Snowflake/Google Drive) y **Agents** (`PANEL_AGENTS_DATA`: Reconciliation Agent/Anomaly Watcher/Period Close Assistant). Cada fuente vive independiente de sus equivalentes en `SEARCH_DATA` (Cmd+K) y `PROJECTS_DATA` (vista Projects) — mismos nombres por convención, no una fuente de datos compartida.
- **Map no es una cuarta opción.** Es una interpretación/render de la vista de un proyecto (aparece *dentro* de un tab de tipo Project), no una entidad separada para elegir en el picker.
- **Buscador + tabs de filtro, no una lista plana**: las listas no están pensadas para ser exhaustivas — si hubiera 100 proyectos reales no se listarían todos de una. El buscador (`#panelOpenPickerSearch`) filtra en vivo por nombre a través de las tres categorías; los tabs de filtro (`All`/`Projects`/`Apps`/`Agents`, clase `.panel-filter-tab`) acotan a una sola categoría. Con "All" activo, los resultados se agrupan por categoría (mismo patrón que el modal Cmd+K); con un filtro específico, se listan sin agrupar.
  - `.panel-filter-tab` es una clase **propia**, no reusa `.search-tab` del modal Cmd+K — ese modal tiene un listener global (`document.querySelectorAll('.search-tab')`) que hubiera interferido con el estado activo de estos tabs. Mismo criterio que ya se usó para los tabs "Created by you / Shared projects" de la vista Projects.
- **Centrado en los dos ejes**: `.panel-open-picker` usa `align-items: center; justify-content: center`, y todo el bloque (título + buscador + tabs + resultados) vive en una columna de 320px (`.panel-open-inner`) — lee como un menú centrado en medio del panel, no un formulario estirado a todo el ancho.
- **Resultados con alto fijo, no `max-height`**: `#panelOpenPickerResults` mide siempre 280px (220px en el popover del "+"), sin importar cuántos resultados matcheen. Ver la nota de bug más abajo — con `max-height` el bloque completo se recentraba en cada tecla.
- **Ítems anchos**: `.panel-open-item` reusa el mismo look que `.search-result-item` del modal Cmd+K (ícono + nombre, padding generoso), no la lista angosta de 220px de la primera versión.

### Tabs: abrir, cerrar, cambiar

- Seleccionar un resultado (del open picker o del popover del "+") lo abre como un **tab** en la barra de arriba (`.panel-tab-wrap`): ícono según categoría (folder/layout-grid/bot para project/app/agent) + nombre + botón de cerrar (`x`) propio.
- Si el proyecto/app/agente seleccionado **ya tiene un tab abierto**, volver a seleccionarlo solo lo activa — no duplica tabs (dedupe por `key = "tipo:id"` en `panelTabsState`).
- Cerrar un tab activa automáticamente el tab vecino (el que quedó en su misma posición, o el anterior si era el último). **Cerrar el último tab** revierte el panel automáticamente al open picker.
- Tab activo en **gris neutro** (`--color-surface-sunken`/`--color-ink`), no azul primario — mismo criterio que el toggle grid/list de Projects y el ícono del propio toggle del panel: no debe competir visualmente con la navegación real del sidebar.
- **Barra de tabs a 50px fijos de alto** (`.panel-tabs-bar`), igual que `.chat-thread-header`/`.sidebar-header` — para que la línea de separación quede alineada horizontalmente con el header del hilo de al lado, en vez de tomar la altura de su contenido y desalinear las dos columnas.
- **Contenido de cada tab**: texto placeholder genérico (`"Project view — <nombre>"` / `"App view — <nombre>"` / `"Agent view — <nombre>"`) — el contenido real de cada vista es una iteración futura, a propósito (mismo criterio que las secciones Apps/Agents del nav).

### El botón "+": posición y popover

- Reutiliza el mecanismo `data-menu-trigger`/`.composer-menu` ya existente en el composer — abre un popover (`#panelOpenMenu`) con el mismo buscador + tabs de filtro + resultados que el open picker, pero con **estado de búsqueda/filtro independiente** del picker de pantalla completa.
- **Posición fija, no dentro de la lista de tabs.** El botón vive como **hermano** de `#panelTabsList` en `.panel-tabs-bar` (no como un miembro más de la lista) — así queda siempre inmediatamente después del último tab, sin importar cuántos haya, y "se corre" solo al final cuando se abre uno nuevo porque el tab nuevo se agrega al final de `panelTabsState`, no porque el botón se reordene.
- **`#panelTabsList` es shrink-to-fit** (sin `flex: 1`, con `min-width: 0` + `overflow-x: auto`) — no se estira a todo el ancho de la barra, así el "+" queda pegado al último tab en vez de varado en el extremo derecho con un hueco vacío en el medio.
- **Tope fijo antes del botón "Hide panel".** `.panel-tabs-bar` reserva `padding-right: 56px` — el mismo espacio que `.chat-thread-header` ya reserva para `.chat-panel-toggle` (28px de ancho + `right: 20px`, flotante `position: absolute` sobre todo `.chat-pane`, fuera del layout flex de esta barra). Con suficientes tabs abiertos, `#panelTabsList` se queda sin espacio antes de esa franja reservada y empieza a hacer scroll horizontal interno de sus propios tabs — el "+" se asienta en una posición fija y de ahí en más solo crece el scroll de la lista, nunca vuelve a moverse ni pisa el botón de Hide panel.
- **Scrollbar del scroll de tabs: pegado al borde inferior, invisible salvo hover, grosor tokenizado.** `#panelTabsList` tiene `align-self: stretch` para llenar los 50px completos de altura de `.panel-tabs-bar` (que por defecto centra a sus hijos) — así el borde inferior de la lista coincide exactamente con el `border-bottom` de la barra, y el scrollbar horizontal (que el navegador dibuja al fondo de la caja del elemento que scrollea) queda pegado a esa línea en vez de flotar a mitad de la barra. Los tabs adentro siguen centrados verticalmente vía el propio `align-items: center` de la lista, independiente de su altura estirada. Además, se sobrescribió el scrollbar global de `tokens.css` (thumb siempre visible) para que el thumb sea transparente en reposo y solo tome color (`--color-border-strong`, el mismo de siempre) al hacer hover sobre la lista — no debía quedar visible todo el tiempo cuando la mayoría de las veces no hay nada para scrollear. **Grosor**: referencia explícita a `var(--scrollbar-size)` (`shared/tokens.css`, 4px) vía `.panel-tabs-list::-webkit-scrollbar { height: var(--scrollbar-size); }` — no confía en heredar la regla universal, para que el grosor quede fijo en un solo lugar y no varíe entre componentes en futuras implementaciones (pedido explícito del usuario). `scrollbar-width: thin` global cubre el equivalente en Firefox (no soporta px arbitrarios).
- **Alineación dinámica del popover**: arranca en `align-start` (borde izquierdo del popover bajo el botón, abre hacia la derecha) porque al principio el "+" está cerca del inicio de la barra con espacio de sobra. `updatePanelOpenMenuAlign()` (llamada en cada render de la barra de tabs) mide con `getBoundingClientRect()` si abrir en `align-start` haría que el popover se pasara del borde derecho de `#chatSidePanel`; si es así, agrega `.panel-open-menu--end` (abre hacia la izquierda en cambio) — así nunca queda pisado ni cortado por el borde del panel (`.chat-side-panel` tiene `overflow: hidden`).

### Reset al iniciar un chat nuevo

`resetPanelTabs()` (llamado desde el handler de "New Chat"):
- Vacía `panelTabsState` y vuelve el panel al open picker.
- Limpia el término de búsqueda y el filtro activo (vuelve a "All") **en ambos scopes** (picker y popover del "+") — la próxima vez que se abra el panel arranca desde cero, no desde donde el usuario lo dejó.

## Bugs encontrados y corregidos durante esta iteración

Documentados acá porque las causas son específicas de este componente y vale la pena no repetirlas:

1. **Popover clippeado por `overflow-x: auto`.** Un ajuste intermedio insertaba el botón "+" (`appendChild`) dentro de `#panelTabsList` en cada render para que "viajara" con el último tab. Como esa lista tiene `overflow-x: auto`, el navegador computa `overflow-y` también como `auto` (regla del spec: si un eje deja de ser `visible`, el otro también). El popover del "+", posicionado `absolute` debajo del botón, quedaba clippeado por ese overflow y nunca se veía. **Fix**: el botón volvió a ser hermano fijo de la lista (no un miembro más) — ya de por sí queda siempre después del último tab sin necesitar reordenarse.
2. **Popover permanentemente visible.** Al arreglar el bug anterior, el popover resultó estar siempre `display: flex`, incluso sin la clase `.is-open` — `.composer-menu.panel-open-menu` y `.composer-menu.is-open` tienen la misma especificidad CSS (dos clases), y al estar la primera definida más abajo en la hoja, ganaba siempre. **Fix**: el `display: flex` se movió a `.composer-menu.panel-open-menu.is-open` (tres clases, gana por especificidad solo cuando ambas condiciones se cumplen).
3. **Bloque del picker "saltando" al escribir o cambiar de tab.** `#panelOpenPickerResults`/`#panelOpenMenuResults` usaban `max-height` — con menos resultados la caja se encogía, y como todo `.panel-open-inner` está centrado (`justify-content: center`), el bloque completo (título/buscador/tabs incluidos) se recentraba en cada tecla. **Fix**: `height` fija en vez de `max-height` — la caja siempre mide lo mismo, solo su contenido interno hace scroll.
4. **"+" varado en el extremo derecho de la barra, con hueco vacío antes.** `#panelTabsList` tenía `flex: 1`, estirándose a ocupar toda la barra mientras los tabs (empaquetados a la izquierda) dejaban ese espacio vacío en el medio. **Fix**: quitado el `flex: 1` (shrink-to-fit).
5. **"+" viajando hasta casi debajo del botón "Hide panel".** Con suficientes tabs abiertos y sin espacio reservado para `.chat-panel-toggle` (que flota fuera del layout de la barra), el "+" no tenía límite de cuánto podía correrse a la derecha. **Fix**: `padding-right: 56px` en `.panel-tabs-bar`, mismo valor que ya usa `.chat-thread-header` para el mismo botón.

## Estado actual de implementación

- ✅ Toggle abrir/cerrar con animación fluida (370px / resto del ancho)
- ✅ Open picker: buscador en vivo + tabs de filtro (All/Projects/Apps/Agents) + resultados agrupados, centrado en los dos ejes, alto fijo
- ✅ Tabs: abrir (con dedupe), cerrar (con activación automática del vecino), cambiar de tab activo
- ✅ "+" para agregar otro tab: popover con el mismo buscador/filtro, posición fija respetando el botón de Hide panel, alineación dinámica start/end
- ✅ Reset completo (tabs + búsqueda + filtro) al iniciar un chat nuevo
- ✅ Expand / Restore width: modo foco que colapsa la conversación a 0 y fuerza el sidebar de navegación a colapsado, recordando su estado previo para restaurarlo correctamente
- ⛔ **Contenido real de cada tab**: hoy es un placeholder de texto — falta diseñar qué se ve adentro de un tab de Project (¿resumen? ¿vista de mapa?), de App (¿detalle de la conexión?) y de Agent (¿configuración? ¿logs?)
- ⛔ Sin persistencia entre sesiones/recargas — los tabs y el picker viven solo en memoria de la página
- ⛔ Sin límite explícito de tabs simultáneos — depende del scroll horizontal de la barra, no probado con muchos tabs reales

## Pendiente / abierto

- **Contenido de cada tab** (el pendiente más grande): definir la vista real de Project/App/Agent dentro de un tab — incluye decidir si "Map" es una sub-vista/tab interno de un Project o algo más.
- ¿Los tabs abiertos deberían persistir entre sesiones/recargas, o alcanza con que se reseteen (como hoy) al iniciar un chat nuevo?
- ¿Hay un límite razonable de tabs abiertos simultáneamente, o el scroll horizontal de la barra alcanza para el prototipo?
- ¿Se puede reordenar tabs (drag) o cerrarlos todos de una (como "Close all tabs" de un navegador)?

## Archivos relacionados

- `flows/home/index.html` — todo vive acá: markup (`#chatSidePanel`, `#panelOpenPicker`, `#panelTabs`, `#panelOpenMenu`, `.chat-panel-actions`), CSS inline (`.panel-*`, `.chat-side-panel`, `.chat-panel-toggle`, `.is-panel-expanded`), y el script: `PANEL_APPS_DATA`/`PANEL_AGENTS_DATA`, `panelOpenDataFor`, `findPanelItem`, `panelOpenScopes`/`renderPanelOpenResults`/`wirePanelOpenScope`, `renderPanelTabsBar`, `renderPanelTabContent`, `updatePanelViewState`, `openPanelInThread`, `openPanelTab`, `closePanelTab`, `resetPanelTabs`, `updatePanelOpenMenuAlign`, `setPanelExpanded`.
- `shared/shell.js` — `initSidebarCollapse()` define el `#sidebar`/`.is-collapsed` que `setPanelExpanded()` reutiliza para forzar/restaurar el colapso del nav durante el modo foco.
- `shared/tokens.css` — tokens de color/radio/sombra/duración que consume todo lo anterior, más el sistema de tooltips (`.tooltip-bottom`, `.tooltip-end`). No tiene clases propias del panel, esas viven inline en `home/index.html`.
- [`chat.md`](./chat.md) — el resto del chat (composer, mensajes, header del hilo); su propia sección de panel lateral quedó reducida a un resumen que apunta acá.
