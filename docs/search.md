# Search

> Última actualización: 2026-08-18
> Archivos relacionados: `flows/home/index.html` (markup + estilos inline del modal + script), sin dependencia de `shared/tokens.css` más allá de las variables de color/radio/sombra/duración que ya expone.

## Propósito

Buscador global tipo command-palette (referencia visual: paleta estilo Claude Desktop/Linear), disparado desde los dos botones de lupa del sidebar (header expandido, rail colapsado) o `⌘K` / `Ctrl+K` desde cualquier parte de la pantalla. Permite encontrar Chats, Projects, Apps y Agents sin salir del contexto actual.

## Estructura

```
Search modal
├── Input de búsqueda (con ícono lupa, placeholder genérico)
├── Tabs de filtro: All · Chats · Projects · Apps · Agents
└── Resultados
    ├── En "All": agrupados por categoría, con subtítulo (Chats/Projects/Apps/Agents)
    └── En una tab específica: lista plana de esa sola categoría, sin subtítulo repetido
```

Cada resultado: ícono de categoría (Chats = `message-circle-more`, Projects = `folder`, Apps = `layout-grid`, Agents = `bot`) + nombre. Algunos ítems de ejemplo llevan un atajo `⌘1`/`⌘2` a la derecha, replicando el detalle de la referencia visual. El ícono de Chats coincide con el que ya usan "New Chat" en el sidebar y el header del hilo de chat — mismo lenguaje de íconos en todo el prototipo.

## Decisiones tomadas

- **Es un modal centrado con backdrop, no un Sheet lateral.** Excepción deliberada al patrón Simetrik de "modal solo cuando la tarea exige atención modal" — un command-palette es justamente ese caso (overlay transitorio, se abre y cierra con teclado, no compite con contenido persistente). Mismo criterio que ya se usó para el login (excepción documentada, no generalizable al resto del producto).
- **Altura fija de 500px, centrado en ambos ejes, y la posición no cambia al filtrar.** El modal usa `height: 500px` (no `max-height`) para que su caja nunca se redimensione según la cantidad de resultados — filtrar (por texto o por tab) solo cambia el contenido de `.search-modal-results` (que sí tiene `flex: 1; overflow-y: auto`), nunca la posición ni el tamaño del modal completo. Esto evita el "salto" visual de un modal que se encoge/agranda con cada tecla. El backdrop centra con `align-items: center; justify-content: center` (antes solo centraba horizontal, con un padding-top fijo desde arriba).
- **Búsqueda en vivo, sin botón de submit.** Cada tecla filtra inmediatamente contra `SEARCH_DATA`, sin debounce (dataset chico, no hace falta).
- **Tabs mutuamente excluyentes**, no multi-select — coherente con que "All" ya es la unión de las 4 categorías.
- **Navegación por teclado completa**: ↑/↓ mueve el resaltado entre resultados visibles, Enter selecciona el resaltado, Escape cierra, click fuera del modal cierra.
- **Seleccionar un resultado solo cierra el modal.** No navega a ningún destino real todavía — ver Pendiente.
- **Datos mock**: Chats y Projects reusan los nombres reales que ya viven en el sidebar (Pinned + Recent). Apps y Agents, que todavía no tienen datos reales en el producto, usan nombres inventados pero plausibles (Slack, Snowflake, Google Drive; Reconciliation Agent, Anomaly Watcher, Period Close Assistant).

## Loading skeleton (2026-08-14)

Pedido explícito del usuario: los resultados no tenían ningún estado de carga — cada "consulta" (abrir el modal, tipear, cambiar de tab) mostraba el resultado final de inmediato. Se agregó el mismo mecanismo ya establecido para Projects/Apps/Chats and Tasks y el open picker del panel lateral del chat: `skeletonShimmer` (keyframe global) + gradient compartido, clases propias (`.search-skeleton-item`/`-icon`/`-line`) para no depender de las de otros componentes.

- **Plano, no agrupado por categoría.** A diferencia del resultado real en la tab "All" (agrupado con subtítulo por categoría), el esqueleto es una lista simple de filas placeholder — misma simplificación que ya usa el esqueleto del open picker del panel lateral (`panelOpenSkeletonMarkup`): un loading state no necesita imitar la forma exacta de lo que viene, solo leerse como "resultados en camino". Anchos de línea variados por fila para que se lea como texto placeholder, no un bloque idéntico repetido.
- **Clase propia, no `.search-result-item`.** Los ítems reales usan esa clase para el hover, el click-to-seleccionar y la navegación por teclado (↑/↓/Enter, ver `updateSearchHighlight()`) — si el esqueleto la compartiera, una fila shimmer sería "resaltable"/"seleccionable" mientras todavía es solo un placeholder. `.search-skeleton-item` es una clase completamente aparte (con `pointer-events: none` + `tabindex="-1"` + `aria-hidden="true"` de todos modos, por las dudas), sí replicando el mismo padding/gap que `.search-result-item` para que el cambio esqueleto→contenido no salte.
- **Dos velocidades, mismo criterio que el resto del prototipo**: 700ms al abrir el modal (`openSearchModal()`, sensación de "primera carga"), 400ms al tipear o cambiar de tab (`querySearchWithLoading(400)`, sensación de "ya cargado, solo refiltrando"). Un solo timer (`searchQueryTimer`, no uno por escopo como el picker del panel, que tiene dos instancias simultáneas) cancela cualquier "fetch" simulado anterior si llega uno nuevo antes de que termine.

## Tabs de filtro: pill → underline (2026-08-18)

Pedido explícito del usuario: las tabs `All`/`Chats`/`Projects`/`Apps`/`Agents` dejan de ser un pill/badge (fondo redondeado `border-radius: 999px`, tinte `--color-primary-tint` en la activa) y pasan a ser tabs de subrayado — texto plano, con un borde inferior de 2px en la activa.

- **`--color-ink`, no un `#000` literal**, para el borde/texto de la tab activa — es el token de texto "más oscuro" que ya usa todo el prototipo, no un negro puntual inventado para esto.
- **`margin-bottom: -1px` original, revertido en la misma sesión** (ver sección siguiente): la primera versión solapaba el borde de la tab activa sobre el separador que tenía `.search-modal-tabs`. Ese separador se removió a pedido explícito poco después, así que el truco ya no tenía nada contra qué alinearse — se sacó junto con el separador.
- **Gap aumentado de 4px a 20px.** Los pills necesitaban poco espacio entre sí porque el propio fondo redondeado ya marcaba el límite de cada uno; texto plano sin fondo necesita más aire entre etiquetas para no leerse pegado.
- **Alcance acotado a `.search-tab` únicamente — no se tocó a sus primos.** Varios componentes ya habían copiado 1:1 el estilo pill de `.search-tab` en clases propias, específicamente para no compartir el nombre de clase (el modal de Search engancha un wiring global `document.querySelectorAll('.search-tab')` que rompía cualquier otra tab que compartiera el nombre — ver `home.md`): `.projects-ownership-tab`, `.panel-filter-tab`, `.chats-view-tab`, `.apps-view-tab`. Ninguno de estos se actualizó — siguen con el look pill viejo. Si en algún momento se quiere el mismo tratamiento de underline en todos, es un cambio a pedir explícitamente por separado (y a repetir en cada uno, ya que ninguno hereda de `.search-tab`).

## Dividers removidos + footer de atajos (2026-08-18, misma sesión)

Pedido explícito del usuario, sobre el mismo rediseño de tabs de arriba:

- **Los dos `border-bottom` que separaban input→tabs y tabs→resultados se sacaron.** `.search-modal-input-row` y `.search-modal-tabs` tenían cada uno su propia línea divisoria — con las tabs ya en formato underline, esas líneas quedaban de más (la tab activa ya aporta su propia señal visual). El modal ahora solo tiene una línea divisoria en total: el `border-top` del footer nuevo (ver abajo).
- **Footer de atajos, tono gris (`--color-surface-sunken`)**, calcado del pie de un command-palette típico (Linear/Raycast/GitHub): `↑` `↓` **Move** y `↵` **Select**, en dos grupos separados. Es la única línea divisoria que le queda al modal (`border-top`), ya que las de arriba se removieron.
- **Los `<kbd>` usan `--color-surface` (blanco), no `--color-surface-sunken`.** Si usaran el mismo gris que el fondo del footer, quedarían invisibles — necesitan contraste contra esa franja para leerse como "teclas" reales, con un borde sutil (`--color-border-strong`) para definir el borde de cada tecla.
- **Glifos de texto (`↑` `↓` `↵`) adentro del `<kbd>`, no un ícono embebido.** El usuario pidió "el ícono de ENTER", pero ningún otro `<kbd>` de este archivo mete un componente de ícono adentro (`⌘K`, `⌘J`, `⌘B` son todos caracteres Unicode literales) — `↵` es el mismo símbolo visual que el ícono de "return" que se pedía, sin romper esa convención.
- **Labels "Move"/"Select": sentence-case, no mayúscula forzada.** Primera versión: `text-transform: uppercase` vía CSS sobre el markup en sentence-case (mismo patrón que `.sidebar-section-title`). **Corrección (mismo día, feedback directo):** el usuario pidió que quedaran con solo la primera letra en mayúscula ("Move"/"Select" tal cual, no "MOVE"/"SELECT") — se sacó el `text-transform: uppercase`, el markup ya estaba bien escrito, solo la transformación visual sobraba.

## Hint de "Enter" al hacer hover/highlight de un resultado (2026-08-18, misma sesión)

Pedido explícito del usuario: cuando un resultado está en hover o resaltado por teclado (↑/↓), debe aparecer un `<kbd>↵</kbd>` en la esquina derecha de esa fila, indicando que Enter lo selecciona — mismo lenguaje que ya usa el footer nuevo (ver sección de arriba).

- **`.search-result-enter-kbd` en TODAS las filas de resultado, siempre presente en el markup pero invisible por defecto** (`opacity: 0`) — se hace visible (`opacity: 1`) con el mismo trigger que ya tenía el tinte de fondo de la fila. No hace falta JS nuevo — es puro CSS reaccionando a clases que ya existían.
- **`--color-surface` (blanco), no `--color-surface-sunken`** — mismo motivo que los `<kbd>` del footer: la fila misma pasa a `--color-surface-sunken` en ese mismo hover/highlight, así que un kbd del mismo tono quedaría invisible justo cuando se supone que debe aparecer.
- **Reemplaza a los `⌘1`/`⌘2` decorativos, no convive con ellos.** Esos dos atajos de ejemplo (en `July period close` y `Nequi source differences`, `SEARCH_DATA.chats`) eran puramente ilustrativos — documentado explícitamente en este mismo archivo como "no funcionan como shortcuts reales". Con el nuevo hint de Enter universal en cada fila, mantenerlos habría significado dos kbds compitiendo por el mismo espacio a la derecha. Se sacó el campo `kbd` de esos dos ítems y la clase `.search-result-kbd` que los pintaba — ya no queda ningún uso de esa clase en el archivo.
- **Fix (mismo día, feedback directo): dejó de mostrarse en mouse hover.** La primera versión lo activaba en `.search-result-item:hover` **y** `.is-highlighted`. El usuario aclaró que es un hint de navegación por teclado ("solo en los que estén asociados directamente al teclado con las flechas") — un click de mouse ya selecciona directo, así que mostrar "press Enter" ahí no aportaba y podía confundir. Se sacó `:hover` del selector; el tinte de fondo de la fila (`.search-result-item:hover, .is-highlighted { background: ... }`) sigue reaccionando a ambos sin cambios, solo el hint de Enter quedó acotado a `.is-highlighted`.
- **Fix, primer intento (mismo día, feedback directo): el glifo `↵` se veía descentrado horizontalmente.** No era un problema del centrado flex del `<kbd>` (`justify-content`/`align-items` ya centraban la caja correctamente) sino de la métrica propia del carácter U+21B5 en la tipografía — su tinta visible no queda centrada dentro de su propio ancho de avance en la mayoría de fuentes. Primer intento: el glifo envuelto en `<span class="kbd-glyph-enter">` con un `transform: translateX(1px)` — un nudge a ciegas, sin navegador para verificar el resultado.
- **Fix, segundo intento (mismo día, feedback directo otra vez): el nudge no lo arregló.** Sin forma de confirmar visualmente si la dirección o la magnitud del nudge eran las correctas, seguir ajustando píxeles a ciegas no era confiable. Se cambió de enfoque: en vez de seguir dependiendo del glifo de texto, `↵` se reemplazó por el ícono real de Lucide `corner-down-left` (la misma flecha de "return", pero como SVG con su propio `viewBox` — centrado geométrico garantizado, no sujeto a cómo la tipografía renderiza ese carácter puntual). Aplicado en los dos lugares que usaban `↵` (el hint por fila y el del footer); los glifos `↑`/`↓` del footer siguen siendo texto plano, nunca se reportaron descentrados. Es una excepción deliberada y acotada a la regla de "los kbd de este archivo son siempre texto Unicode, nunca un ícono embebido" (⌘K/⌘J/⌘B la siguen sin cambios) — se rompe acá únicamente porque el glifo de texto demostró no poder arreglarse de forma confiable sin verificación en vivo, no por preferencia.

## Tags de Projects: mostradas en el resultado + filtro por tag (2026-08-18, misma sesión)

Pedido explícito del usuario, con dos decisiones confirmadas antes de implementar: (1) las tags filtran los resultados, combinadas con el texto y la tab activa — no son solo decorativas; (2) las tags se leen en vivo de `PROJECTS_DATA`, no de una copia mock propia del buscador.

- **`SEARCH_DATA.projects` eliminado.** Hasta ahora era una lista estática de 3 nombres, desacoplada a propósito de `PROJECTS_DATA` (documentado como decisión explícita en `home.md`). Se reemplazó por `getSearchItems(cat)`, que para `'projects'` lee `PROJECTS_DATA.filter(p => !p.archived).map(p => ({ name: p.name, tags: p.tags }))` — para cualquier otra categoría (`chats`/`apps`/`agents`) sigue devolviendo `SEARCH_DATA[cat]` tal cual, esas siguen desacopladas (no tienen tags todavía). Esto también resuelve de paso un gap ya documentado (`home.md`): renombrar un proyecto vía "Edit detail" ya no deja a `SEARCH_DATA.projects` con el nombre viejo, porque ya no existe esa copia separada.
- **Proyectos archivados excluidos** — mismo criterio que cualquier otra vista que lista Projects; encontrar uno acá que no es alcanzable/visible en ningún otro lado sería un callejón sin salida.
- **Tags en texto plano después del nombre: "Name - tag - tag"**, no pills coloreados como los `.project-tag-pill` de las cards de Projects — pedido explícito ("en forma de texto, separados únicamente"). Viven **adentro** de `.search-result-name` (un `<span class="search-result-tags">` anidado), no como hermano — así "nombre + tags" se trunca como una sola unidad de texto compartiendo el mismo `text-overflow: ellipsis` del padre, en vez de necesitar coordinar el shrink entre dos elementos flex separados. **Ajuste (mismo día, feedback directo): gris más claro** — `--color-ink-faint` (el token más claro de tinta que existe en `shared/tokens.css`) más `opacity: .7` encima, mismo idioma que ya usa este archivo para "mismo color, más claro" (ej. `.folder-icon`) en vez de inventar un gris hardcodeado nuevo.
- **Botón "Filter by tag" nuevo, arriba a la derecha de la fila de búsqueda.** Primera versión: texto completo (label/valor + chevron), mismo patrón que Projects/Apps. **Refinado en la misma sesión (feedback directo):** pasó a ser un ícono solo (`settings-2`, `.icon-btn` reusado directamente — es un primitivo genérico de verdad, sin wiring atado a su nombre de clase, a diferencia de `.search-tab`/`.project-row`) con tooltip ("Filter by tag") en vez de label visible. Un **dot azul** (`.dot`, el mismo primitivo ya definido en `shared/tokens.css` para "hay algo activo") aparece en la esquina superior derecha del ícono cuando hay 1+ tags seleccionadas, oculto si no hay ninguna — reemplaza al texto "all"/tag/"N tags" que mostraba la versión anterior.
- **Buscador agregado adentro del popover** (`#searchFilterSearchInput`, arriba de la lista de tags) — pedido explícito para poder "buscar y seleccionar uno o varios" en vez de solo scrollear una lista plana. Filtra la lista de tags en vivo, tecla a tecla — sin skeleton ni delay, porque es un filtro instantáneo sobre una lista ya cargada en memoria, no una simulación de fetch (mismo criterio que ya usa el propio popover de tags de Projects). Estado vacío propio (`.search-filter-empty`, "No tags match...") si el término no matchea ninguna tag.
- **"Clear filters" se mantiene sin cambios** de comportamiento — mismo pedido explícito de conservar lo que ya funcionaba. **Fix de tamaño (mismo día, feedback directo):** el botón solo tenía la clase base `.composer-menu-option` (pensada para opciones de dos líneas título+descripción, `padding: 8px 10px` + `align-items: flex-start`), así que se veía notoriamente más alto/con más padding que las filas de tags de arriba (esas sí usan `.composer-menu-option--model`, compacta de una sola línea). Mismo override que ya tiene `#projectsFilterClear` en el popover de Projects (`min-height: 32px; padding: 0 8px; align-items: center;` + `.opt-icon { margin-top: 0; }`) — se había copiado el resto del patrón pero se pasó por alto justo este detalle la primera vez.
- **"Clear filters" ahora arranca `disabled` y solo se habilita con 1+ tags activas** (pedido explícito) — `updateSearchFilterButton()` (ya se llama en cada cambio de `searchActiveTags`: seleccionar/deseleccionar una tag, abrir el modal, o el propio click en "Clear filters") ahora también hace `clearBtn.disabled = searchActiveTags.size === 0`. Se generalizó un estado `.composer-menu-option[disabled]` en `shared/tokens.css` (opacidad + `cursor: not-allowed`, mismo idioma que ya usa `.btn-primary[disabled]`) — primer consumidor de ese estado, pero queda disponible para cualquier otro `.composer-menu-option` que necesite deshabilitarse condicionalmente en el futuro.
- **Selección OR, no AND** — mismo criterio que el filtro de tags de Projects (`getFilteredProjects`): un ítem matchea si tiene **al menos una** de las tags activas, no todas. Combinable con el texto y con la tab de categoría — los tres criterios se aplican en cadena dentro del mismo `.filter()`.
- **Un filtro de tag activo excluye categorías sin tags.** Como hoy solo Projects tiene `.tags`, activar cualquier tag en la tab "All" hace que Chats/Apps/Agents desaparezcan de los resultados (no tienen tags que puedan matchear) — comportamiento esperado, no un bug, hasta que otras categorías tengan sus propias tags ("pronto").
- **Fresh reset en cada apertura del modal** (`searchActiveTags.clear()` + el buscador de tags se vacía + `renderSearchFilterMenu()` + `updateSearchFilterButton()` dentro de `openSearchModal()`) — el menú de tags se re-renderiza (no solo se limpia) porque `PROJECTS_DATA` puede haber cambiado desde la última vez que se abrió el modal (llega de Supabase, ver `supabase.md`).
- **Divisor real sobre "Clear filters", a diferencia del original de Projects.** El popover de Projects tiene un `<div class="project-select-divider">` sin ninguna regla CSS (no pinta nada, es markup muerto) — la versión de Search usa `.search-filter-clear-row { border-top: ... }` en su lugar, una línea que sí se ve.
- **Riesgo conocido, sin resolver:** el popover del filtro vive dentro de `.search-modal`, que tiene `height: 500px` fijo + `overflow: hidden` (a diferencia de Projects, cuyo propio filtro vive en una página con scroll normal, sin esa restricción). Con el pool de tags actual (5, ~200px de popover) entra sin problema, pero si el catálogo de tags creciera mucho podría recortarse contra el borde inferior del modal — mismo tipo de bug ya resuelto antes para los popovers del sidebar (ver `sidebar.md`), no aplicado acá todavía porque no hace falta con los datos de hoy.

## Subtítulos de categoría: menos grosor, más peso visual (2026-08-18, misma sesión)

Pedido explícito del usuario sobre `.search-group-title` (los subtítulos "Chats"/"Projects"/"Apps"/"Agents" que agrupan los resultados en la tab "All"): "bájale el grosor, pero con mucho peso visual" — menos bold, pero sin perder presencia.

- **`font-weight: 700 → 600`** (bold → semibold) — menos grosor, tal como se pidió.
- **`letter-spacing: .02em → .04em`** — el tracking extra refuerza la lectura como *label*/categoría (mismo lenguaje tipográfico que etiquetas pequeñas en mayúscula/tracked usan para leerse "importantes" sin depender del grosor).
- **Color: probado más oscuro, revertido en la misma sesión.** Primer intento: `color` pasó de `--color-ink-faint` a `--color-ink-soft` para compensar el grosor menor con más presencia. El usuario pidió después dejarlo en gris claro — vuelto a `--color-ink-faint`. El "peso visual" final queda sostenido solo por el `letter-spacing` extra, sin oscurecer el color.

## Bug encontrado y corregido: el modal se auto-enganchaba como trigger

Los dos botones de lupa reales y el propio contenedor del modal (`.search-modal`) compartían el mismo `aria-label="Search"` (el del modal era solo para accesibilidad). El JS que engancha el click para *abrir* el modal usaba el selector `[aria-label="Search"]`, que también matcheaba el modal mismo — cualquier click adentro (incluyendo las tabs) burbujeaba hasta el modal y volvía a disparar `openSearchModal()`, que resetea la tab activa a "All". Efecto visible: las tabs "no filtraban" (el filtro se aplicaba y se deshacía en el mismo frame).

Fix: los triggers ahora usan una clase dedicada `.search-trigger` en vez de depender del `aria-label` compartido; el modal quedó con su propio `aria-label="Search everything"`. Verificado con una simulación de DOM en Node/jsdom (no solo por inspección de código) antes de darlo por resuelto.

**Lección para el resto del prototipo:** no reusar el mismo `aria-label`/atributo entre un trigger y el contenedor que ese trigger abre, si algún selector JS hace match por ese atributo.

## Estado actual de implementación

- ✅ Abrir/cerrar: click en cualquiera de las dos lupas, `⌘K`/`Ctrl+K`, Escape, click fuera
- ✅ Filtro por tab (All/Chats/Projects/Apps/Agents) — corregido, ver bug arriba
- ✅ Filtro por texto en vivo, combinable con la tab activa
- ✅ Navegación y selección por teclado (↑/↓/Enter)
- ✅ Subtítulos de categoría en sentence-case (no uppercase forzado)
- ✅ Loading skeleton al abrir el modal, tipear, o cambiar de tab (ver sección propia arriba)
- ✅ Footer de atajos (`↑`/`↓` Move, `↵` Select) + hint `↵` por fila en hover/highlight (ver secciones propias arriba) — resuelve el pendiente de los `⌘1`/`⌘2` decorativos, que se sacaron
- ✅ Tags de Projects mostradas en el resultado + filtro real por tag, leído en vivo de `PROJECTS_DATA` (ver sección propia arriba) — Chats/Apps/Agents siguen sin tags
- ⛔ Seleccionar un resultado no carga ese chat/proyecto/app/agente real — solo cierra el modal
- ⛔ Sin estado vacío ilustrado más allá de un texto simple ("No results for…")

## Pendiente / abierto

- ¿Seleccionar un chat en Recent/Pinned desde acá debería abrir ese chat en el área central? Es el mismo pendiente que ya existe para los links del sidebar.
- ¿Los datos mock de Apps/Agents deberían alinearse con nombres reales una vez el producto los defina, o quedan como placeholder permanente del prototipo?
- Sin diseño de empty state "propositivo" (ilustración + acción sugerida) — hoy es solo texto plano, más básico que el resto de empty states del prototipo (Apps/Agents en el sidebar sí tienen uno más elaborado).

## Archivos relacionados

- `flows/home/index.html` — todo vive acá: markup del modal, `<style>` con las clases `.search-modal*` (incluye `.search-modal-footer`/`.search-modal-hint*`), `.search-tab*`, `.search-result*` (incluye `.search-result-tags`/`.search-result-enter-kbd`), `.search-filter-*`, `.search-skeleton-*`, y el script con `SEARCH_DATA`, `getSearchItems()` (Projects lee de `PROJECTS_DATA`, el resto de `SEARCH_DATA`), `renderSearchResults()`, `renderSearchFilterMenu()`/`updateSearchFilterButton()`, `querySearchWithLoading()`/`showSearchSkeleton()`/`searchSkeletonMarkup()`, `openSearchModal()`/`closeSearchModal()`, y el listener global de teclado.
