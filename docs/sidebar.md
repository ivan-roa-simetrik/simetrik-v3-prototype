# Sidebar

> Última actualización: 2026-08-12
> Archivos relacionados: `shared/tokens.css` (estilos), `shared/shell.js` (comportamiento), markup vive dentro de cada flujo (hoy solo `flows/home/index.html`)

> **Nota de idioma (2026-08-12):** "Proyectos" → "Projects", "Recientes" → "Recent", y `data-nav="proyectos"` → `data-nav="projects"` (el JS de `sectionCopy`/`onNavSectionChange` usa la key en inglés ahora). El resto de este documento describe la estructura, que no cambió — solo el idioma del copy y del atributo `data-nav`.

## Propósito

Es la única fuente de verdad de "a dónde podés ir" dentro de la plataforma (patrón canónico Simetrik: Sidebar = navegación, no hay breadcrumb/tabs todavía porque solo existe una pantalla). Agrupa 3 tipos de colección (Proyectos, Apps, Agents) más el historial de chats sueltos.

## Estructura definida (tal como la especificó el usuario)

```
Sidebar
├── Header
│   ├── Logomark Simetrik
│   ├── Buscar (ícono lupa)
│   └── Notificaciones (ícono campana)
├── Nav principal
│   ├── + New Chat
│   ├── Proyectos   (ícono carpeta · hover revela "+ Agregar un nuevo proyecto")
│   ├── Apps        (ícono grid · hover revela "+", sección propia a futuro)
│   └── Agents      (ícono bot · hover revela "+", sección propia a futuro)
├── Sección "Proyectos" (lista, no la misma cosa que el nav "Proyectos" de arriba)
│   └── Por proyecto: ícono carpeta + nombre, expandible → chats anidados debajo
├── Sección "Recientes"
│   └── Chats generales, sin proyecto asociado (lista plana)
└── Footer
    └── Avatar (2 iniciales) + nombre de cuenta + ícono de info
```

Todo el sidebar es colapsable/expandible (ícono rail: se ocultan labels, quedan solo los íconos centrados).

## Decisiones tomadas

- **"Proyectos" existe dos veces con roles distintos.** Arriba, como ítem de nav (con affordance de "+" para crear), y abajo, como sección de listado real con jerarquía Proyecto → Chats anidados. Es el mismo patrón que Cursor/Codex-style sidebars: un acceso rápido de alto nivel + un árbol navegable debajo. No es una duplicación accidental.

- **Los chats de un proyecto viven anidados bajo su carpeta, no en una lista plana aparte.** Refleja la jerarquía natural que describió el usuario: "cuando se esté creando una carpeta, debajo, los chats que estén asociados a ese proyecto también". Expand/collapse por click en la fila del proyecto, con chevron que rota (200ms ease-out).

- **"Recientes" es una colección separada, plana, sin jerarquía.** Son chats generales que no pertenecen a ningún proyecto — el usuario los distinguió explícitamente de la sección "Proyectos".

- **El "+" de New Chat, Proyectos, Apps y Agents solo aparece en hover.** No está siempre visible para no meter ruido visual en el estado default (ley de densidad organizada). New Chat es la excepción: es un botón siempre visible porque es la acción primaria de la pantalla.

- **Apps y Agents no tienen listado propio todavía.** A diferencia de "Proyectos", que sí tiene su sección de listado abajo, Apps y Agents solo existen como ítems de nav por ahora. El usuario indicó que sus secciones específicas "se desarrollan más adelante" — se dejó el nav item funcional (con affordance de "+") pero sin la sección de listado equivalente a la de Proyectos.

## Estado actual de implementación

- ✅ Collapse/expand del sidebar completo (ícono rail)
- ✅ Expand/collapse de cada proyecto individual (revela/oculta chats anidados)
- ✅ Hover reveal del "+" en los 3 nav items
- ✅ Estado activo (highlight) al clickear Proyectos/Apps/Agents
- ⛔ El "+" de cada nav item y de cada sección no está conectado a ninguna acción real (visual únicamente)
- ⛔ No hay estado de "proyecto seleccionado" que filtre o resalte algo en el chat central todavía
- ⛔ Búsqueda y notificaciones del header son solo íconos, sin funcionalidad

## Pendiente / abierto

- ¿Qué aparece cuando "Apps" o "Agents" sí tengan su sección de listado (paralela a la de "Proyectos")? Hoy son placeholders de empty state en el área principal, no listas en el propio sidebar.
- ¿Clickear un chat anidado bajo un proyecto debería cargar ese chat en el área central? Hoy los `<a>` de chats son enlaces sin destino (`href="#"`).
- ¿El header (logo/buscar/notificaciones) necesita un estado de resultados de búsqueda, o abre un Command Palette (Cmd+K, mencionado en las leyes raíz pero no implementado todavía)?

## Archivos relacionados

- `shared/tokens.css` — todas las clases `.sidebar*`, `.nav-item*`, `.project-*`, `.chat-row`, `.user-chip`
- `shared/shell.js` — `initSidebarCollapse()`, `initProjectExpand()`, `initNavActive()`
- `flows/home/index.html` — markup concreto con el mock data de proyectos/chats
