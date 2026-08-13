# Search

> Última actualización: 2026-08-12
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

Cada resultado: ícono de categoría (Chats = `message-square`, Projects = `folder`, Apps = `layout-grid`, Agents = `bot`) + nombre. Algunos ítems de ejemplo llevan un atajo `⌘1`/`⌘2` a la derecha, replicando el detalle de la referencia visual.

## Decisiones tomadas

- **Es un modal centrado con backdrop, no un Sheet lateral.** Excepción deliberada al patrón Simetrik de "modal solo cuando la tarea exige atención modal" — un command-palette es justamente ese caso (overlay transitorio, se abre y cierra con teclado, no compite con contenido persistente). Mismo criterio que ya se usó para el login (excepción documentada, no generalizable al resto del producto).
- **Búsqueda en vivo, sin botón de submit.** Cada tecla filtra inmediatamente contra `SEARCH_DATA`, sin debounce (dataset chico, no hace falta).
- **Tabs mutuamente excluyentes**, no multi-select — coherente con que "All" ya es la unión de las 4 categorías.
- **Navegación por teclado completa**: ↑/↓ mueve el resaltado entre resultados visibles, Enter selecciona el resaltado, Escape cierra, click fuera del modal cierra.
- **Seleccionar un resultado solo cierra el modal.** No navega a ningún destino real todavía — ver Pendiente.
- **Datos mock**: Chats y Projects reusan los nombres reales que ya viven en el sidebar (Pinned + Recent). Apps y Agents, que todavía no tienen datos reales en el producto, usan nombres inventados pero plausibles (Slack, Snowflake, Google Drive; Reconciliation Agent, Anomaly Watcher, Period Close Assistant).

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
- ⛔ Seleccionar un resultado no carga ese chat/proyecto/app/agente real — solo cierra el modal
- ⛔ Sin estado vacío ilustrado más allá de un texto simple ("No results for…")
- ⛔ Los atajos `⌘1`/`⌘2` mostrados en algunos ítems son decorativos, no funcionan como shortcuts reales

## Pendiente / abierto

- ¿Seleccionar un chat en Recent/Pinned desde acá debería abrir ese chat en el área central? Es el mismo pendiente que ya existe para los links del sidebar.
- ¿Los datos mock de Apps/Agents deberían alinearse con nombres reales una vez el producto los defina, o quedan como placeholder permanente del prototipo?
- Sin diseño de empty state "propositivo" (ilustración + acción sugerida) — hoy es solo texto plano, más básico que el resto de empty states del prototipo (Apps/Agents en el sidebar sí tienen uno más elaborado).

## Archivos relacionados

- `flows/home/index.html` — todo vive acá: markup del modal, `<style>` con las clases `.search-modal*`, `.search-tab*`, `.search-result*`, y el script con `SEARCH_DATA`, `renderSearchResults()`, `openSearchModal()`/`closeSearchModal()`, y el listener global de teclado.
