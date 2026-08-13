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

## Pendiente / abierto

- Responsive del sidebar en mobile/tablet: sin definir, sigue sin recibirse una referencia.
- ¿Clickear un chat anidado (Pinned o Recent) debería cargar ese chat en el área central? Hoy son enlaces sin destino (`href="#"`).
- El Search del header no tiene función real de búsqueda todavía (ni el de Cmd+K).
- Los "+" de New Project/New App/New Agent son solo visuales, no disparan ninguna acción todavía.

## Archivos relacionados

- `shared/tokens.css` — todas las clases `.sidebar*`, `.nav-item*`, `.project-*`, `.chat-row`, `.user-chip`, `.tooltip*`, keyframes de animación
- `shared/shell.js` — `initSidebarCollapse()`, `initProjectExpand()`, `initSectionCollapse()`, `initNavActive()`
- `flows/home/index.html` — markup concreto, mock data de proyectos/chats, `onNavSectionChange`
- `assets/img/Simetrik_logo.svg`, `Simetrik_isologo.png`, `Cover.png` — assets de marca usados en el sidebar
