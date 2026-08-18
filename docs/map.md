# Project View Map (pantalla)

> Última actualización: 2026-08-18
> Archivo relacionado: `flows/home/index.html` — todo vive en el mismo `<script>`/`<style>` inline del resto del home, dentro del tab de tipo `project` del panel lateral del chat.
> Ver también: [`project-map.md`](./project-map.md) — el modelo **conceptual** de los nodos (por qué son 3 tipos y no otra cantidad, por qué la conciliación es un tag). Este archivo documenta la **pantalla**: cómo se ve y se comporta, fase por fase. [`chat-side-panel.md`](./chat-side-panel.md) — el mecanismo de tabs donde este vive (abrir/cerrar, dedupe, "···" para agregar otro).
> Este archivo reemplaza y amplía lo que hasta ahora vivía como 2 subsecciones dentro de `home.md` ("Project View Map — Fase 0" y "Fase 1: navegación del canvas") — se extrajo a un archivo propio por el mismo motivo que `chat-side-panel.md` se separó de `chat.md`: volumen de decisiones acumuladas en una sola pieza. `home.md` conserva un resumen de 2 líneas que apunta acá.

## Propósito

Es el mapa del proyecto — el pilar 2 de la visión de producto ("canvas/mapa del workflow"): donde el usuario ve y entiende lo que el agente construyó. Vive dentro del tab de tipo `project` del panel lateral del chat (ver `chat-side-panel.md`) — no es una vista de página completa aparte, es contenido de ese tab.

Se llega clickeando una card/fila de la vista Projects (`openProjectChat()`) o mandando el primer mensaje de un chat con un Project seleccionado en el composer — los dos abren el panel con este tab ya activo.

## Fase 0 — El empty state real (2026-08-14)

Reemplazó el placeholder de texto genérico (`"Project view — {nombre}"}`) que el tab de tipo `project` tenía antes de esto. `renderProjectMapTab()` (nueva en ese momento, hoy mucho más grande — ver Fase 2) empezó escribiendo el mismo lenguaje visual que ya usan las secciones vacías de Apps/Agents (`.section-empty`: ícono en círculo + título + body): *"This project doesn't have nodes yet"* / *"Describe what you want to reconcile in the chat and I'll build the map for you."*

Tres decisiones de producto ya cerradas antes de esa pasada, y que siguen vigentes:
1. **El modelo de nodos** — ver [`project-map.md`](./project-map.md).
2. **El detalle de un nodo vive en un drawer inferior no-modal** (D42 del producto real) — no en un panel lateral. Todavía sin construir (ver Pendiente).
3. **El mapa arranca vacío**; es el primer mensaje del chat del proyecto el que lo construye — nada de mock data sembrada *como comportamiento final*. (Fase 2, más abajo, introduce una excepción temporal a esto — ver esa sección.)

## Fase 1 — Navegación del canvas (2026-08-14)

Canvas real con pan y zoom, construido antes de que existiera un solo nodo — la mecánica se valida sola, sin depender de contenido.

- **Estructura**: `.project-map-canvas` (el área completa del tab) → `.project-map-zoom-content` (la capa que se panea/zoomea, `transform: translate() scale()`).
- **La retícula de puntos vive en `.project-map-zoom-content`, no fija en el fondo** — decisión deliberada, distinta del mock de referencia (ahí el fondo queda fijo y solo los nodos se mueven): en Fase 1, sin nodos todavía, la retícula era el único contenido visible, así que tenía que ser lo que se mueve para que pan/zoom se sintieran reales. Sigue siendo así en Fase 2 — no se revirtió.
- **`.project-map-zoom-content` es deliberadamente enorme** (`inset: -2000px`, constante `PROJECT_MAP_ZOOM_CONTENT_INSET` en JS, tiene que coincidir con el CSS) — un arrastre nunca se queda sin grilla que revelar.
- **Pan**: arrastre con botón izquierdo (`initProjectMapCanvas`), traduce en píxeles crudos de pantalla — funciona igual a cualquier zoom porque `translate()` va *antes* que `scale()` en el mismo `transform`.
- **Zoom**: botones +/− y rueda, rango 0.6×–1.2× en pasos de 0.1. Ancla siempre al **centro del panel**, no al cursor — anclar al puntero queda pendiente (ver Pendiente).
- **Porcentaje de zoom visible** (2026-08-18, pedido explícito): un label (`.project-map-zoom-label`, `data-map-zoom-label`) entre los botones de −/+ muestra `Math.round(zoom * 100)%` — se actualiza dentro de `setZoom()`, así que cubre botones, rueda, y el reset de "Fit to view" sin lógica aparte. `min-width: 38px` fijo para que el bloque de controles no cambie de ancho entre "60%" y "120%".
- **Fit to view**: hoy es la vista de reposo (`pan 0,0`, `zoom 1×`), no un encuadre real contra el bounding box del grafo — con el centrado automático de Fase 2 (ver abajo) ya se ve completo a esa vista por diseño, pero el cálculo real sigue pendiente.
- **Controles de navegación (zoom in/out/fit) solo se muestran si el proyecto tiene nodos** — ajuste posterior (2026-08-14, misma semana), pedido explícito: antes de que hubiera nodos, no tenía sentido mostrar botones para navegar algo vacío. `renderProjectMapTab()` decide esto con `tieneNodos = graph.nodes.length > 0`, no con CSS `hidden`: los controles directamente no se emiten al `innerHTML` si no hay nodos. Pan (arrastre) y zoom con rueda siguen activos siempre — son gestos sobre el canvas, no elementos de UI que haya que ocultar.
- **Botón de Filter** (2026-08-18, pedido explícito, todavía sin funcionalidad): esquina superior derecha del canvas (`.project-map-filter`, espejo de `.project-map-controls` que vive abajo-izquierda), mismo `.project-map-control-btn` visualmente, ícono `filter`. Sigue el mismo criterio de visibilidad que el resto de los controles — solo con nodos. Sin `onclick`, decorativo hasta que se defina qué filtra.
- **El empty state de Fase 0 y el grafo son mutuamente excluyentes**, mismo mecanismo que los controles: solo uno de los dos se emite según `tieneNodos`.
- **Retícula de puntos, tres ajustes seguidos (2026-08-18, los tres pedidos explícitos):**
  1. **Radio subido de 1px a 1.8px** — "hago zoom out... los puntos ya no son visibles". A `PROJECT_MAP_ZOOM_MIN` (0.6×) un punto de 1px terminaba renderizando a ~0.6px reales, y el navegador lo antialiasea casi hasta la invisibilidad contra un fondo tan claro (`--color-sidebar-bg`, el nuevo gris de esta misma sesión).
  2. **Color aclarado de `--color-border-strong` a `--color-border`** — "¿puedes dejar los puntos un poco más claros?", una vez resuelta la visibilidad en zoom out el radio más grande los dejaba un poco marcados de más al 100%/120%.
  3. **Radio bajado a 1.3px + color a `rgba(23,23,31,.08)`** — "deben ser aún más claros y más pequeños". `--color-border` ya era el token de borde más claro de la paleta (no hay uno más suave), así que aclarar más pidió opacidad en vez de un color distinto — ink al 8%. El radio de 1.3px sigue por encima del 1px original (a 0.6× de zoom deja ~0.78px reales) para no reintroducir del todo el problema del primer ajuste, aunque con menos margen que el 1.8px anterior.

## Fase 2 — Los nodos (2026-08-18)

Referencia de diseño: mockup **"Nodos del Mapa"** (artifact de esta sesión, iterado varias rondas con feedback directo antes de portarlo acá). Ver [`project-map.md`](./project-map.md) para el modelo de datos completo — acá solo el **cómo se ve y se comporta**.

### Estructura de la card — 2 capas

Patrón compartido por el usuario (referencia visual tipo Zapier/n8n), con una card GRIS exterior y una BLANCA interior:

```
┌─ .node-card (gris, borde de color por familia, SIN padding propio) ─┐
│  [ícono chico] Tipo · dirección                                     │  ← .node-card-header (header), su propio padding
│  ┌─ .node-card-inner (blanca, "content") ────────────────────────┐  │
│  │  [ícono grande, chip de color]  Nombre                         │  │
│  │                                  [estado / lifecycle]           │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  [tags libres]                                                      │  ← .node-card-extra (footer), su propio padding
│  🕐 Last updated DD/MM/AAAA, HH:MM                                   │
└──────────────────────────────────────────────────────────────────────┘
```

- **`.node-card` no tiene padding propio** (2026-08-18, pedido explícito: "a nivel de estructura, el nodo a nivel global no tenga ningún padding"). El padding vive en cada sección por separado: `.node-card-header` (`padding: 10px 10px 0`, header), `.node-card-inner` (`margin: 0 2px`, ya que su propio `padding: 9px` es el inset del contenido de la card blanca — dos cosas distintas, "content"), `.node-card-extra` (`padding: 0 10px 10px`, "footer"). El único punto en común entre las 3 secciones es el `gap: 8px` que sigue viviendo en `.node-card`, separándolas entre sí.
- **Margin horizontal de `.node-card-inner`: 10px → 2px → 4px** (2026-08-18, dos pedidos explícitos seguidos, el segundo ajuste fino sobre el primero) — la card blanca queda casi al ras del borde gris exterior en vez de con un respiro de 10px a cada lado. El `padding: 9px` interno (el inset del ícono/nombre dentro de la card blanca) no se tocó en ninguno de los dos pasos.
- **El fondo gris es igual para los 3 tipos** — "grises normales", palabras del feedback directo. Ajustado a `--color-sidebar-bg` (2026-08-18, pedido explícito: "el gris claro del fondo del chat"), más claro que el `--color-surface-sunken` con el que había arrancado.
- **El borde también es igual para los 3 tipos — gris, `--color-border-strong`** (2026-08-18, pedido explícito: "remo el border de color que tienen las cartas... todas tienen que quedar con borde gris"). Antes cada tipo tenía su propio color de borde (azul Integración, violeta Function, gris Dataset) — se descartó esa distinción. El color de familia sigue existiendo, pero solo en los íconos (header y card blanca), nunca más en el borde ni en el fondo.
- **Violeta es un token nuevo** (`--color-accent`/`--color-accent-tint`/`--color-accent-ink`, `shared/tokens.css`) — no existía ninguna variante disponible en la paleta que no chocara semánticamente con success/warning/danger.
- **El header no tiene caja propia** — ícono chico (mismo glifo que el de adentro, sin chip de fondo) + etiqueta de tipo. **Sin menú "···"** — sacado del todo (2026-08-18, pedido explícito), junto con su CSS y el guard de click que existía solo para separarlo del toggle de colapso. `min-height: 20px` en el header evita que la fila quede "aplastada" contra la esquina superior — bug real encontrado en el mockup (sin una altura mínima propia, el ícono se leía pegado arriba-izquierda en vez de centrado en su franja).
- **Etiqueta de tipo: sentence case, no ALL CAPS, justificada a la izquierda** (2026-08-18, pedido explícito — "capital letter, o sea, solo la primera letra mayúscula"). Antes tenía `text-transform: uppercase` + `letter-spacing`; ahora `nodeTypeLabel()` ya devuelve el string con la capitalización correcta ("Integration · inbound", "Integration · outbound", "Dataset", "Function") y el CSS no le aplica ningún transform encima que lo pise — `text-align: left` explícito, aunque ya salía así por default.
- **Peso de esa etiqueta bajado de 700 a 500** (2026-08-18, pedido explícito: "el texto está muy grueso"). 700 sigue siendo correcto en `.node-card-name` — es lo primero que hay que leer de la card; la etiqueta de tipo es secundaria, no necesita competir con eso.
- **"Last updated": 10.5px → 8.5px → 9px** (2026-08-18, pedido explícito: "que no ocupe tanto espacio", seguido de un ajuste fino subiéndolo medio punto) — el ícono de reloj se achicó en la misma pasada (11px → 9px, sin volver a tocarse en el ajuste fino) para que siga leyéndose como un solo bloque con el texto, no como dos elementos de escalas distintas.
- **Ícono del header — genérico por tipo/dirección** (`nodeIconName()`): `arrow-down-to-line` (Integración entrada), `arrow-up-from-line` (Integración salida), `database-zap` (Dataset — reemplaza a `database` liso, pedido explícito), `square-function` (Function).
- **Ícono del content — específico por nodo, no por tipo** (2026-08-18, corrige la decisión anterior de esta misma sesión, pedido explícito: "el ícono... tiene que estar asociado un poco con el proceso que está internamente"). Antes header y content compartían el mismo glifo genérico; ahora `nodeContentIcon()` lee `n.icon` de cada nodo del grafo — sí hay equivalente a "logo por instancia" acá, a diferencia de lo que se había asumido al portar la referencia de Zapier. Con `DEMO_MAP_GRAPH`: `landmark` (Bank statement feed), `building-2` (ERP export feed), `arrow-left-right` (ds_bank_transactions), `book-text` (ds_erp_journal), `scale` (ds_reconciliation — el clásico símbolo contable de balance/conciliación, no `git-compare`: mismo criterio ya aplicado al ícono de Function real, evitar la familia "git" por la connotación de jerarquía que no aplica acá), `hand` (Apply manual match — "proceso manual", pedido literal), `file-check` (Settlement report). Si un nodo no trae `icon` (el modelo real todavía no define de dónde saldría este dato), cae de vuelta al genérico de `nodeIconName()`.
- **Chip del ícono de content: gris parejo, ícono oscuro, para los 3 tipos** (2026-08-18, pedido explícito: "tienen que ser de tono gris, con el ícono negro como está ahorita" — usando el tratamiento que ya tenía Dataset como referencia). Se descartó el chip coloreado por familia (azul/violeta) — mismo criterio que ya se aplicó al borde de la card: el color de familia dejó de vivir acá, ahora el ícono específico de cada nodo es lo que lo identifica.
- **Padding de la card blanca a la mitad: 9px → 4.5px** (2026-08-18, pedido explícito).
- **La card blanca interior ("content")** lleva el ícono grande + el nombre + el estado/lifecycle.
- **"Last updated" se movió adentro de la card blanca (content)** (2026-08-18, pedido explícito: "vamos a dejar el last updated dentro del contenedor blanco") — ya no vive en la zona extra/footer. Ahora es el último elemento dentro de `.node-card-title`, debajo del nombre y el estado/lifecycle, en los 3 tipos de nodo.
- **La zona extra ("footer")** queda solo con tags libres (acá es donde "conciliación" aparece como tag, nunca como tipo — ver `project-map.md`) — **"footer" queda libre para otra cosa todavía sin definir** (palabras del usuario: "el footer lo utilizamos para otra cosa"), ver Pendiente.

### Handles y aristas

- **Un solo look para los dos**: borde gris (`--color-border-strong`), relleno blanco, tanto de entrada como de salida — se descartó una versión anterior que los distinguía rellenos/huecos por dirección (feedback directo: no hacía falta esa distinción).
- **Integración tiene un solo handle**, nunca los dos — de entrada (`salida` del handle) si es outbound, de salida si es inbound. Nunca ambos.
- **Function tiene solo handle de entrada** — lee un Dataset, nunca alimenta el flujo hacia adelante.
- **Dataset tiene los dos** — puede recibir de una Integración u otro Dataset, y alimentar a otros.
- **Aristas**: trazo sólido gris para flujo de datos normal; **punteado** (`.node-edge--governed`) para la arista que alimenta a una Function — comunica "lectura gobernada", no flujo de datos real.
- **Cálculo de aristas — decisión técnica importante**: nodos y aristas viven en el MISMO espacio de coordenadas local (ambos son hijos de `.project-map-graph`, sin transformar entre sí), así que las aristas se calculan una sola vez con `offsetLeft/offsetTop/offsetWidth/offsetHeight` — medidas propias del elemento, **no afectadas** por el `transform: scale()` del pan/zoom de Fase 1. Esto es distinto (y más simple) que el mockup, que medía contra el viewport con `getBoundingClientRect()` porque ahí no había ningún transform de por medio. Consecuencia: **no hace falta recalcular aristas al panear o hacer zoom** — solo cuando un nodo cambia de tamaño (colapsa/expande), y ahí sí se sigue la transición CSS de ~200ms con un loop de `requestAnimationFrame`, mismo criterio que ya usa el pan/zoom de Fase 1 para no verse "saltar" al final del cambio.

### Estados — completo y colapsado

Solo 2 niveles (se descartó un tercer nivel intermedio "básico" que tenía el mock de referencia — feedback directo).

- **Completo**: la estructura de 2 capas de arriba, entera.
- **Colapsado**: cuadrado redondeado (4 esquinas parejas, `--radius-md` — no un círculo, y no una sola esquina redondeada, que era una lectura posible antes de confirmarlo con el usuario), 48×48px, **solo el ícono** de la card blanca interior. El header y la zona extra desaparecen del todo (no solo se ocultan detrás — dejan de ocupar espacio). **No muestra el nombre**, ni siquiera una etiqueta chica debajo — la única forma de leerlo es un **tooltip al hover** (nombre + estado/lifecycle), mismo lenguaje visual que `.tooltip-bubble` (fondo ink, texto blanco, 6px de radio) en vez de uno inventado.
- **Bug de centrado del ícono, corregido dos veces antes de portarlo**: una primera versión encadenaba `width:100%`/`height:100%` a través de varios niveles de flexbox (card → inner → ícono) — correcta en teoría, se seguía viendo desfasada en la práctica. La versión final ancla `.node-card-inner` y `.node-card-icon` con `position:absolute; inset:0` directo contra `.node-card` (que ya es `position:absolute`), sin pasar por ningún cálculo de porcentaje de flexbox que pueda fallar.
- **Click en la card (fuera del "···") alterna completo ↔ colapsado.** No hay drag de nodo todavía (ver Pendiente).

### El grafo de demo — divergencia temporal, documentada a propósito

**`DEMO_MAP_GRAPH` es un grafo hardcodeado (7 nodos, escenario "LATAM Bank Reconciliation") que hoy se muestra en CUALQUIER proyecto**, no en uno en particular. Dos razones, ambas de esta sesión:

1. `PROJECTS_DATA` dejó de ser un array estático — ahora sale de Supabase (`docs/supabase.md`, Fase 1 de esa migración, ya aplicada) con ids reales que no se pueden anticipar acá ni saber de antemano qué proyectos existen realmente sembrados.
2. El objetivo explícito de esta pasada era la **visualización de nodos** — cards, estructura, modos, handles, estados — no todavía la Fase 2 completa del plan original (nodos reales + reveal disparado por el chat + drawer). Un grafo de ejemplo siempre visible es lo que permite revisar el sistema visual sin depender de que el reveal por chat exista.

Esto es una **divergencia deliberada y temporal** de la Decisión 3 de `project-map.md` ("el mapa arranca vacío"). Se cierra cuando el primer mensaje del chat dispare el reveal real — ver Pendiente.

**Centrado automático del grafo**: `renderMapGraph()` mide el bounding box real de los nodos ya insertados (`offsetLeft/Top/Width/Height`, así no hay que adivinar alturas — varían según si el nodo tiene tags o no) y posiciona `.project-map-graph` para que ese bounding box quede centrado bajo el canvas VISIBLE en ese render — no un valor fijo en CSS, que solo quedaría bien centrado por casualidad según el ancho real del panel (chat colapsado/expandido, distintas resoluciones).

## Estado actual de implementación

- ✅ Canvas con pan (arrastre) + zoom (botones/rueda), rango 0.6×–1.2×
- ✅ Empty state real (Fase 0) y grafo de demo (Fase 2), mutuamente excluyentes
- ✅ Controles de navegación visibles solo con nodos, con porcentaje de zoom visible entre −/+
- ✅ Botón de Filter (esquina superior derecha), sin funcionalidad todavía
- ✅ Retícula de puntos visible en todo el rango de zoom (0.6×–1.2×)
- ✅ 3 tipos de nodo (Integración con dirección, Dataset, Function) con sus handles, colores y header
- ✅ 2 estados por nodo (completo/colapsado) con tooltip en colapsado
- ✅ Tags libres + "Last updated" en los 3 tipos
- ✅ Aristas dirigidas, con estilo punteado para la arista que alimenta a una Function
- ✅ Grafo centrado automáticamente contra el tamaño real del canvas
- ⛔ El grafo es de demo (`DEMO_MAP_GRAPH`), no datos reales — se muestra en cualquier proyecto
- ⛔ Sin reveal animado disparado por el primer mensaje del chat
- ⛔ Sin drawer inferior de detalle (D42) — clickear un nodo hoy solo colapsa/expande
- ⛔ Sin persistencia — nada de esto pasa por `map_nodes`/`map_edges`/`map_versions` (esas tablas ya existen en Supabase, `supabase/migrations/0004_project_map.sql`, pero conectarlas es la Fase 5 de esa migración — explícitamente la última, después de proyectos/apps/chats)
- ⛔ Verificado solo por trazado de código + chequeo de sintaxis del `<script>` — sin confirmación visual en navegador en ninguna de las 3 fases (la extensión de Chrome no estuvo conectada en ninguna sesión hasta ahora)

## Pendiente / abierto

- **El grafo real**: reemplazar `DEMO_MAP_GRAPH` por datos reales del proyecto, y el primer mensaje del chat disparando el reveal animado (nodos apareciendo uno por uno, con anillo pulsante) — el pendiente más grande, cierra la divergencia de la Decisión 3.
- **Drawer inferior de detalle** (D42) — clickear un nodo hoy solo alterna completo/colapsado; abrir su detalle real todavía no existe. El menú "···" que hubiera podido llevar a esto se sacó del todo (2026-08-18) en vez de dejarse decorativo — si hace falta una acción por nodo más adelante, se vuelve a evaluar entonces.
- **Filter real** — el botón existe (esquina superior derecha) pero no filtra nada todavía; falta definir qué (¿por tipo de nodo, como el "Layers" de los mocks? ¿por tag?).
- **Footer (zona extra) para otra cosa** — hoy solo tiene tags; el usuario mencionó explícitamente que lo van a reusar para algo distinto, todavía sin definir qué.
- **Logo/ícono de "Banco" específico** — el usuario ofreció compartir una referencia visual de un logo de banco con el estilo del nombre del nodo ("Bank statement feed"); no llegó ninguna imagen adjunta al pedido, así que el ícono `landmark` sigue siendo el placeholder hasta que se reciba esa referencia.
- **Zoom anclado al cursor**, no al centro del panel.
- **Fit to view real** — hoy es la vista de reposo, no un cálculo contra el bounding box real del grafo (aunque el centrado automático de Fase 2 hace que hoy ya se vea bien a esa vista).
- **Drag de nodo** — posición fija desde datos, no arrastrable todavía (igual que el producto real, donde el drag existe pero no persiste).
- **Persistencia real** (`map_nodes`/`map_edges`/`map_versions`) — Fase 5 de la migración a Supabase, todavía lejos en la secuencia de esa migración (ver `docs/supabase.md`).
- **Verificación visual en navegador real** — pendiente en las 3 fases.

## Archivos relacionados

- `flows/home/index.html` — todo el código: `renderProjectMapTab`, `initProjectMapCanvas`, `renderMapGraph`, `buildNodeCardHtml`, `buildMapGraph`, `DEMO_MAP_GRAPH`, `projectMapNodeCount`, `nodeIconName`/`nodeTypeLabel`/`nodeHasInHandle`/`nodeHasOutHandle`, constantes `PROJECT_MAP_ZOOM_*`.
- `shared/tokens.css` — `--color-accent`/`--color-accent-tint`/`--color-accent-ink`, el único token nuevo que esta pantalla necesitó.
- [`project-map.md`](./project-map.md) — el modelo conceptual de nodos (por qué 3 tipos, por qué la conciliación es un tag).
- [`chat-side-panel.md`](./chat-side-panel.md) — el tab donde este mapa vive.
- [`home.md`](./home.md) — resumen corto + el flujo de `openProjectChat()` que abre este tab.
- `docs/supabase.md` — estado de la migración a Supabase, incluida la Fase 5 (todavía no alcanzada) que eventualmente reemplaza `DEMO_MAP_GRAPH` por datos reales.
