# Sidebar

> Última actualización: 2026-08-12
> Archivos relacionados: `shared/tokens.css` (estilos y comportamiento vía clases de estado), `shared/shell.js` (JS de interacción), markup en `flows/home/index.html`
>
> Este documento describe la **definición final** del sidebar tal como quedó construido, no un historial de cambios. Para el registro turno a turno de cómo se llegó acá, ver `docs/README.md` → tabla de historial.

## Propósito

Única fuente de verdad de "a dónde podés ir" dentro de la plataforma (patrón canónico Simetrik: Sidebar = navegación). Agrupa acceso rápido a Projects/Apps/Agents, dos colecciones curadas (Pinned, Recent) y la gestión de cuenta del usuario. Es colapsable a un rail de íconos de 52px sin perder acceso a ninguna función.

## Estructura

```
Sidebar (260px expandido / 52px colapsado)
├── Header
│   ├── Wordmark completo (expandido) ↔ isologo con hover-to-expand (colapsado)
│   └── Header actions (solo expandido): Search · Close sidebar
├── Nav principal
│   ├── Search           (solo visible colapsado — el de expandido vive en el header)
│   ├── New Chat          (acción primaria, ícono +)
│   ├── Projects          (ícono folder, "+" en hover → New Project)
│   ├── Apps              (ícono layout-grid, "+" en hover → New App)
│   └── Agents            (ícono bot, "+" en hover → New Agent)
├── Pinned                (sección colapsable — proyectos pineados/curados)
│   └── Por proyecto: folder↔folder-open + nombre, expandible → chats anidados + línea guía
├── Recent                (sección colapsable — chats generales sin proyecto)
└── Footer
    └── Avatar (foto/gradiente + iniciales blancas) + nombre + cuenta + Log out
```

## Los dos estados

### Expandido (260px)

- Header: wordmark completo (`Simetrik_logo.svg`) a la izquierda, Search + Close sidebar (ícono `panel-left`) a la derecha.
- Nav: ícono + label de texto, uno debajo del otro.
- Pinned / Recent: header de sección muestra **solo texto** (sin ícono) + chevron, expandible/colapsable como categoría completa.
- Footer: avatar + nombre + cuenta + botón Log out, todos visibles.
- Los tooltips que duplicarían un texto ya visible (nav items, headers de sección, avatar) **no se muestran** en este estado — ver sección Tooltips.

### Colapsado (52px)

- Header: el wordmark se oculta, aparece el isologo. Al hacer **hover** sobre el isologo, cambia a un ícono `panel-right` ("Open sidebar") — clickeable para expandir.
- Header actions se ocultan completas; el ícono de Search reaparece como su propio nav-item, arriba de New Chat.
- Todos los nav items pasan a cajas fijas de **36×36px**, centradas en el rail (ícono solo, sin label).
- Pinned / Recent: el header de sección pasa a mostrar **solo el ícono** (pin / clock), también en caja de 36×36 centrada. Texto, chevron y la lista completa se ocultan — no hay espacio para leer una lista a 52px.
- Footer: solo el avatar (36×36) queda visible; el botón Log out se oculta (no entra sin desbordar).
- Los tooltips suprimidos en el estado expandido **sí se muestran** acá, porque ya no hay texto visible al lado del ícono.

Trigger de colapsar/expandir: el ícono `panel-left` del header (visible solo expandido) colapsa; el hover sobre el isologo (visible solo colapsado) expande. Son dos botones distintos, no uno que cambia de ícono.

## Nav principal: comportamiento "seleccionado"

New Chat, Projects, Apps y Agents comparten un sistema de estado activo mutuamente excluyente (`data-nav` + clase `.is-active`, manejado por `initNavActive()` en `shell.js`): clickear uno le agrega fondo `--color-primary-tint` + texto `--color-primary-ink`, y se lo saca a cualquier otro que lo tuviera. New Chat participa de este sistema (con `data-nav="new-chat"`) pero además dispara su propio handler que resetea el chat al estado vacío — ambos comportamientos conviven sin conflicto.

Projects y New Chat, al clickear, **no** abren una vista alternativa en el área principal (`onNavSectionChange` los excluye explícitamente). Apps y Agents sí — muestran un empty state genérico ("esta sección se desarrolla en la próxima iteración").

## Pinned y Recent: por qué son secciones, no solo nav items

Cada uno existe como una categoría colapsable independiente (clase `.sidebar-section--collapsible`), separada del nav principal:

- **Pinned**: proyectos curados/pineados por el usuario (no "todos los proyectos" — ese es el rol del nav item "Projects"). Cada fila usa folder↔folder-open (no chevron) para señalar abierto/cerrado, y al expandir revela sus chats anidados con una línea guía vertical a la izquierda.
- **Recent**: chats generales sin proyecto asociado, lista plana sin jerarquía.

Ambas se expanden/colapsan como grupo completo (chevron en el header de sección, mismo mecanismo grid `0fr↔1fr` que ya usaban las filas de proyecto individuales).

## Colores

- Fondo del sidebar: `--color-sidebar-bg` (`#FCFBFC`), variable propia — no comparte `--color-bg` con el resto de la app para poder ajustarse independientemente.
- Search y Close sidebar (header): peso visual reducido a propósito — `--color-ink-faint` en reposo, `--color-ink-soft` en hover. Los nav items principales usan `--color-ink` (más oscuro) para diferenciarlos como las acciones importantes.
- Avatar del footer: fondo con `Cover.png` (el mismo degradado azul/negro del panel derecho del login) + iniciales en blanco, cuadrado (`border-radius: var(--radius-sm)`), no circular.

## Tooltips

Sistema de dos capas:

1. **`[data-tooltip]` + `::after`** (texto plano vía `attr()`): usado en la mayoría de los íconos. Variante default = aparece a la derecha; clase `.tooltip-bottom` = aparece abajo (Search y Close sidebar del header la usan).
2. **`.tooltip-bubble`** (markup real): usado donde hace falta más que texto plano — Search (header y colapsado) muestra `Search` + un `<kbd>⌘K</kbd>`. Variante `.tooltip-bubble--right` para la versión colapsada, consistente con sus vecinos del rail.

**Regla de supresión:** cuando el sidebar está expandido, los tooltips de nav items, headers de sección y el avatar se ocultan (`display:none` sobre el `::after`) porque ya hay un texto visible al lado que dice lo mismo — mostrarlo sería redundante. Search, Close/Open sidebar y Log out **siempre** muestran su tooltip, en cualquier estado, porque nunca tienen un label de texto adyacente.

## Micro-animaciones (todas hover/click, ninguna en loop)

| Ícono | Animación | Duración |
|---|---|---|
| New Chat, "+" de Projects/Apps/Agents | Rotan 90° | 240ms |
| Search, Close sidebar, Projects, Apps | Pop de escala (crece a 1.18x y vuelve a 1x) — keyframe `navIconPop` | 320ms |
| Agents (bot) | Bounce vertical sutil, una vez | 320ms |
| Pinned (pin, header de sección) | Wiggle de rotación | 320ms |
| Open sidebar (isologo colapsado) | Nudge horizontal 2px hacia la derecha | 240ms |
| Log out | La flecha se desliza 2px hacia afuera | 120ms |
| Folder de cada proyecto en Pinned | Crossfade folder↔folder-open + opacidad/color, atado a `.is-expanded` (no a hover) | 320ms |
| Chevron de headers de sección (Pinned/Recent) | Rota 90° al expandir/colapsar | 120ms |
| Apps (layout-grid), Recent (clock) | Sin animación — no hay una metáfora de movimiento clara, animar sería decorativo |

## Lo que ya no existe

- **Divider** entre el nav y Pinned: removido (markup + CSS), a pedido explícito.
- **Chevron individual por fila de proyecto**: removido, reemplazado por el crossfade folder↔folder-open.
- **Nav item "Recent" duplicado**: existió brevemente entre Projects y Apps; se eliminó porque duplicaba la sección "Recent" de abajo (mismo ícono de reloj apareciendo dos veces).
- **Ícono de "info"** en el footer: reemplazado por el botón de Log out.

## Ellipsis de acciones por proyecto en Pinned (2026-08-13)

Cada fila de `Pinned` tiene ahora un botón de elipsis (`more-vertical`), oculto hasta hover — mismo patrón visual que el ellipsis ya existente en las cards/filas de la vista Projects (`.project-card-actions-btn`), pero con clases propias (`.sidebar-project-actions-btn`/`.sidebar-project-actions-menu`) para no repetir el error ya documentado de compartir nombre de clase entre el sidebar y otro componente (ver `home.md` → colisión de `.project-row`, y la de `.search-tab`).

- **Markup**: `.project-row` (el botón que expande/colapsa la fila) dejó de ocupar todo el ancho de la fila — ahora vive dentro de `.project-row-wrap` junto al nuevo `.sidebar-project-actions-wrap`, como hermanos, no anidados. Necesario porque `.project-row` ya es un `<button>` y un `<button>` no puede contener otro `<button>` (HTML inválido) — meter el ellipsis adentro habría roto el markup y además habría hecho bubble el click hacia el toggle de expandir/colapsar.
- **4 acciones en el popover, todas no-op por ahora**: Unpin project, Invite members, Archive project, Edit info — mismo set que ya existe en el menú de acciones de las cards de Projects (`Pin/Unpin`, `Invite members`, `Archive`) más una nueva, **Edit info**, que no existe en ningún otro lado del prototipo todavía. Decisión explícita del usuario: agregar las 4 como ítems del menú (abren/cierran el popover, look completo) sin desarrollar qué hace cada una — eso queda para una iteración futura, una vez se defina explícitamente qué dispara cada acción (para "Edit info" en particular, ni siquiera está definido qué campos del proyecto editaría).
- **`data-project-id` agregado a cada `<li class="project-item">`** (mismos ids que `PROJECTS_DATA` en `flows/home/index.html`: `latam-bank-reconciliation`, `q2-journal-entry-audit`, `q3-treasury-forecast`) — preparación para cuando se wireen las acciones de verdad (hoy el wiring de `initSidebarProjectActions()` en `shell.js` no lo usa, solo abre/cierra el popover vía `.closest()`; queda ahí para no tener que volver a tocar el markup en la próxima pasada).
- **CSS vive en `shared/tokens.css`**, no inline en `flows/home/index.html`, porque el resto del sidebar (`.project-row`, `.project-item`, `.chat-sublist`, etc.) ya vive ahí — consistencia de dónde se define cada cosa. Sí depende de `.composer-menu-option` (el primitivo de fila-de-opción reusado por los popovers de Filter/acciones de Projects), que está definido en el `<style>` inline de `flows/home/index.html` — mismo tipo de dependencia implícita que ya tenía el popover de acciones de Projects, no es nueva.
- **Wiring en `shared/shell.js`** (`initSidebarProjectActions()`), no en `flows/home/index.html`, porque el sidebar es shell compartido entre flujos — igual criterio que `initSidebarCollapse()`/`initProjectExpand()`/`initSectionCollapse()`. A diferencia del wiring de la vista Projects (que usa delegación de eventos porque sus cards se re-renderizan en cada filtro), acá el markup del sidebar es estático, así que `addEventListener` directo por elemento alcanza.
- **Fix (mismo día, feedback directo sobre la primera pasada): hover unificado.** La primera versión ponía el fondo de hover en `.project-row` (que solo ocupa su propio ancho flex, sin llegar al ellipsis) — el usuario reportó que se veían como dos zonas separadas: un recuadro tintado alrededor del nombre y, más allá, un hueco sin tintar antes de que apareciera el ellipsis. Corregido moviendo el fondo de hover a `.project-row-wrap` (el contenedor completo, nombre + ellipsis), con `.project-row` y `.sidebar-project-actions-btn` sin fondo propio — así toda la fila lee como una sola superficie continua al pasar el mouse, el ellipsis queda "adentro" del mismo hover en vez de flotar aparte.

## Pendiente / abierto

- **Qué hace cada acción del nuevo menú de Pinned.** Ahora mismo Unpin/Invite members/Archive/Edit info son placeholders puros (abren y cierran el popover, nada más). Falta definir: si Unpin/Archive deberían reusar `toggleProjectPinned()`/`archiveProject()` (ya existentes, hoy solo alcanzables desde la vista Projects) o tener su propia lógica; y qué campos del proyecto expondría "Edit info" (¿solo nombre? ¿status? ¿tags?) — sin definir todavía, ver `proyecto.md` para el trasfondo conceptual de qué es "información principal" de un Proyecto.
- Responsive del sidebar en mobile/tablet: sin definir, sigue sin recibirse una referencia.
- ¿Clickear un chat anidado (Pinned o Recent) debería cargar ese chat en el área central? Hoy son enlaces sin destino (`href="#"`).
- El Search del header no tiene función real de búsqueda todavía (ni el de Cmd+K).
- Los "+" de New Project/New App/New Agent son solo visuales, no disparan ninguna acción todavía.

## Archivos relacionados

- `shared/tokens.css` — todas las clases `.sidebar*`, `.nav-item*`, `.project-*`, `.sidebar-project-actions-*`, `.chat-row`, `.user-chip`, `.tooltip*`, keyframes de animación
- `shared/shell.js` — `initSidebarCollapse()`, `initProjectExpand()`, `initSectionCollapse()`, `initNavActive()`, `initSidebarProjectActions()`
- `flows/home/index.html` — markup concreto, mock data de proyectos/chats, `onNavSectionChange`, `.composer-menu-option` (reusado por el popover nuevo)
- `assets/img/Simetrik_logo.svg`, `Simetrik_isologo.png`, `Cover.png` — assets de marca usados en el sidebar
