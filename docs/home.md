# Home

> Última actualización: 2026-08-12
> Archivo relacionado: `flows/home/index.html`

> **Nota de idioma (2026-08-12):** el copy de este flujo pasó de español a inglés (instrucción explícita del usuario). Las citas de copy más abajo son de la versión anterior en español; la estructura y las decisiones siguen vigentes, pero para el texto exacto actual ver `flows/home/index.html` directamente.

## Propósito

Es la pantalla a la que se llega después del login. Tipo Codex: layout de dos columnas, sidebar a la izquierda (navegación + Proyectos + Agents + Apps) y el chat como eje central a la derecha. Desde acá el usuario arranca cualquier cosa — crear un proyecto, generar un artefacto, diseñar un agente — conversando, no llenando formularios.

## Decisiones tomadas

- **Layout de dos columnas fijo, sin dashboard de métricas.** El home no es un tablero de KPIs ni una grilla de accesos directos. Es sidebar + chat. Motivo: el chat es el eje central del producto (Ley de identidad "plataforma agentizada, no caja de herramientas"); un dashboard tradicional hubiera competido por atención con la conversación.

- **Estado inicial = greeting/empty state, no dashboard poblado.** Al entrar, el chat arranca vacío con "¿Qué querés construir hoy?" + input + 3 suggestion chips, no con una lista de actividad reciente en el centro. Motivo explícito del usuario: el objetivo del prototipo es *vivir la experiencia completa* desde cero, no simular un usuario recurrente. El sidebar sí trae mock data (3 proyectos, chats recientes) para que no se sienta un producto sin uso, pero el centro de atención (el chat) arranca limpio.

- **El artefacto se muestra en split-pane, nunca reemplaza ni convive en tabs con el chat.** Cuando el chat genera un artefacto, el chat se achica a ~42% del ancho y el artefacto ocupa el resto. Se puede seguir escribiendo mientras se ve el artefacto. Alternativas descartadas: fullscreen (cortaba el eje conversacional) y tabs (menos fiel a "construir algo en paralelo a la charla"). Ver detalle de trade-offs en `chat.md`.

- **"Proyectos", "Apps" y "Agents" son navegación de primer nivel, con contenido específico diferido.** El usuario pidió que estas 3 entradas existan en el sidebar con comportamiento propio ("secciones específicas que desarrollamos más adelante"). Para no dejar clicks muertos, "Apps" y "Agents" muestran un empty state genérico explicando qué van a hacer; "Proyectos" no tiene vista propia todavía porque ya está representado en la lista del sidebar (ver `sidebar.md`).

## Estado actual de implementación

- ✅ Login → home funcional (navegación real vía `window.location`)
- ✅ Estado vacío del chat con suggestion chips funcionando
- ✅ Transición a hilo de chat + generación de artefacto mock (canned, no real)
- ✅ Split-pane funcional con animación de entrada (320ms ease-out)
- ✅ Empty states de Apps/Agents al clickear el nav correspondiente
- ⛔ Sin persistencia: recargar la página vuelve todo al estado inicial
- ⛔ Sin vista de "todos los proyectos" (grid/lista completa)
- ⛔ Sin lógica real de creación de proyecto — es simulación conversacional

## Pendiente / abierto

- Definir qué pasa en el chat cuando el usuario pide explícitamente "crear un agente" — ¿el artefacto pane se convierte en un formulario de configuración de agente, o es un flujo separado? Todavía no se ha explorado.
- Responsive/mobile no se evaluó — el layout de dos columnas fijas asume desktop.
- Projects: "New project" y el click en una card siguen siendo no-op — falta definir si el prototipo necesita simular la creación real de un proyecto o abrir un detalle al hacer click (ver sección Projects más abajo).

## Projects (2026-08-13)

`onNavSectionChange` ya no excluye `section === 'projects'` — el nav item abre una vista propia (`#projectsView`) en vez de no hacer nada, resolviendo el pendiente que existía acá arriba.

- **Patrón adoptado, con referencia concreta.** Se tomó como base la sección Projects de `mock-v3/flows2/home/index.html` (buscador + toggle grid/list + tag filters + cards/rows con estado y avatar) y se adaptó a los tokens y datos de este prototipo — no es una reimplementación 1:1, no hay componentes desyk reales ni backend detrás.
- **Reusa los 3 proyectos mock existentes** (`LATAM Bank Reconciliation`, `Q2 Journal Entry Audit`, `Q3 Treasury Forecast`) — mismos nombres que ya vivían en Pinned/composer/search, para no fragmentar el mock data del prototipo.
- **Fidelidad completa en metadata**: cada proyecto tiene tags (`source:...`, `region:...`, `period:...`) y un badge de estado (`Production`/`Draft`, clases `.badge--success`/`.badge--neutral` ya existentes en `shared/tokens.css`) — decisión explícita del usuario de no simplificar a solo nombre + ícono.
- **Buscador y tags filtran de verdad** (por nombre y por tag activo, combinables); grid/list es un toggle real, no decorativo.
- **Las cards/rows no navegan a ningún lado — decisión explícita.** A diferencia de la referencia (que deshabilita visualmente las cards sin detalle real detrás con `opacity-50`), acá se optó por **no** aplicar ningún tratamiento deshabilitado: mismo criterio que los chats de Pinned/Recent en el sidebar y los resultados del Search modal, que tampoco navegan a nada y tampoco se ven "rotos". El click no dispara ninguna acción.
- **"New project"** sigue siendo un botón visual sin acción, mismo no-op que el "+" de Projects en el sidebar y la opción "New project" del selector de proyecto en el composer.

### Header consolidado a 1 fila (2026-08-13, misma sesión)

Pasada de ajuste pedida por el usuario: el header original ocupaba 3 filas (título+botón, buscador+toggle, chips de tags). Se consolidó a **una sola fila** para no gastar tanto espacio vertical antes de mostrar un solo proyecto:

- **Buscador colapsado a ícono, al lado de Filter.** El input de texto ya no está siempre visible ni vive junto al título — es un botón `search` con el mismo tratamiento outline que Filter (`.projects-search-btn`: borde + fondo `--color-surface`, 32×32), ubicado inmediatamente a la izquierda de Filter. Al clickearlo "despliega" un campo inline que **crece hacia la izquierda** (el input vive antes del botón en el DOM/flex, así que al crecer ocupa el espacio vacío entre el título y los controles de la derecha, en vez de empujar Filter/toggle/New project — el grupo derecho ya está anclado al borde por el `justify-content: space-between` del header).
- **Botón e input nunca conviven — corrección 2026-08-13.** La primera versión mostraba el botón Y el input abierto al mismo tiempo; se corrigió a un solo control que "muta" entre dos estados: colapsado = solo el botón outline; abierto = el botón se oculta (`hidden`) y el input ocupa su lugar, con su propio ícono de lupa (leading, dentro del campo) y una X (trailing) que es la única forma de cerrarlo — cerrar limpia el término, vuelve a mostrar el botón, y re-filtra. Escape en el input también cierra.
- **"Filter" sin ícono, formato label/value + chevron.** Ya no es un botón con ícono de embudo — ahora lee como un selector compacto: "Filter by tag" en gris tenue (`--color-ink-faint`) + " : " + el valor activo en negro (`--color-ink`, ej. "all" sin selección, el tag mismo si hay 1, "N tags" si hay varios) + un chevron que rota 180° al abrir (vía `:has()` sobre el `.composer-menu.is-open` hermano — sin JS extra para mantenerlo sincronizado si el popover se cierra por click afuera). El popover interno no cambió: multi-select reusando `.composer-dropdown`/`.composer-menu`, cada tag alterna independiente (no exclusivo), el menú no se cierra al seleccionar, "Clear filters" al final.
- **Todo en una sola fila**: título a la izquierda; buscador + Filter + toggle grid/list + "New project" a la derecha (`.projects-header-left` / `.projects-header-right`, `justify-content: space-between`).
- **Altura uniforme de 32px** en todos los controles del header (búsqueda, Filter, toggle grid/list, "New project") **y en los ítems internos del popover de Filter** (cada tag + "Clear filters", vía `min-height: 32px` en `#projectsFilterList .composer-menu-option`/`#projectsFilterClear`) — pedido explícito del usuario para que quede alineado con inputs y botones del resto del prototipo.
- **Idioma: copy siempre en inglés.** "Filter by tag" / "all" / placeholder "Search projects" — el usuario aclaró explícitamente que da instrucciones en español pero el copy implementado debe ser siempre en inglés (corrige una pasada anterior de esta misma sesión que había dejado ese texto literal en español).
- Explícitamente fuera de esta pasada: el panel lateral que se abre desde el header del chat (`#chatSidePanel`, agregado en una iteración previa) — quedó pausado sin tocar, su contenido sigue sin definirse.

## Archivos relacionados

- `flows/home/index.html` — markup + JS del home completo
- `shared/tokens.css` — estilos de shell (sidebar) reutilizados acá
- `shared/shell.js` — collapse de sidebar, expand de proyectos
