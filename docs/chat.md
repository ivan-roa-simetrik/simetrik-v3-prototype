# Chat

> Última actualización: 2026-08-13
> Archivo relacionado: `flows/home/index.html` (markup + `<style>` + script, todo inline al final del archivo)

## Propósito

Es el eje central del producto: la forma en la que el usuario crea proyectos, artefactos y agentes. No es un asistente lateral bolt-on (ese es el patrón `AiChat` de las leyes raíz, pensado para chat contextual sobre una pantalla ya existente) — acá el chat ES la pantalla principal.

El comportamiento y la acción bar del composer están calcados del prototipo interno real (`mock-v3/flows/build/index.html`), no inventados: mode/model picker, voz real, e ícono de envío que cambia según haya texto o no.

## Decisiones tomadas

### Dos estados de layout

- **Vacío (greeting)**: heading + composer + suggestion chips, centrados verticalmente en el panel.
- **Activo (hilo)**: se oculta el estado vacío y aparece el hilo de mensajes con un composer "acoplado" (docked) abajo, más un header de contexto arriba (ver más abajo).

Son el mismo archivo/página, dos estados de JS (`#chatEmpty` / `#chatThread`, toggle por `hidden`) — no dos pantallas separadas.

### Composer: acción bar completa, no un input suelto

El composer (`.chat-input-shell`) es una réplica funcional del composer real, con textarea arriba y una toolbar abajo (`justify-content: space-between` para que la toolbar quede siempre pegada al fondo del shell, incluso cuando el shell tiene una altura mínima mayor que el contenido, como en el estado vacío):

- **Add context** (`+`): abre un popover hacia abajo con una sola opción, "Add images, PDFs, or CSVs", que dispara un `<input type="file">` oculto (Finder real del navegador). Cierra su propio tooltip al hacer clic (`tooltip-suppressed`) para no competir visualmente con el popover recién abierto. Su tooltip ahora es el rico (`.tooltip-bubble`, no el de atributo) con un `<kbd>@</kbd>` al lado — apunta al atajo real de mencionar contexto escribiendo `@` (ver más abajo).
- **Model picker**: pill con ícono + label (`Auto` por defecto, ícono asterisco). Popover hacia abajo, máx. 250px de alto con scroll, ancho 256px. Lista: Auto → Sonnet 4.6 / Sonnet 5 / Opus 4.8 / Opus 5 (logo real de Claude/Anthropic) → Gemini 3.1 Pro / GPT-5.6 / Grok 4.5 (logos reales de cada vendor) → sección "Small models": Gemini 3.5 Flash. Fable 5 queda deshabilitado (placeholder para un modelo futuro). Al seleccionar una opción, el trigger actualiza tanto el label como el ícono (clona el ícono de la opción elegida), y al cargar la página el trigger se inicializa con el ícono de "Auto".
  - Los logos de terceros (Claude, Gemini, ChatGPT, Grok) se usan únicamente porque identifican el modelo específico de ese vendor dentro de un selector de modelos — no como ícono genérico de "IA".
- **Voice**: dictado real, no simulado. `getUserMedia` pide permiso de micrófono, `AudioContext` + `AnalyserNode` alimentan un `<canvas>` con un waveform reactivo al audio real, y `SpeechRecognition`/`webkitSpeechRecognition` transcribe a texto dentro del textarea. El dibujo del waveform está calcado 1:1 de `drawVoiceWaveform`/`initVoiceCanvasSize` de la referencia: 90 líneas verticales delgadas (no barras rellenas), gris neutro `#9CA3AF` (no el azul de marca), `analyser.fftSize = 256` para más resolución/granularidad, muestreadas con el mismo `step = floor(bufferLength / barCount)` — se ve y se mueve como un waveform de audio real, no como un EQ genérico. Al activarse, **tanto el textarea como toda la toolbar se ocultan por completo** (Add context, Model picker, mic) y solo queda `.composer-voice-row` (waveform + Cancel/Send) — igual que `showVoiceRow(true)` en la referencia, que también reemplaza el input y la toolbar enteros, no los superpone.
- **Send**: el ícono cambia según el estado del input — vacío muestra `audio-lines` con tooltip "Talk to the agent" (invita a hablar en vez de escribir); en cuanto hay texto, cambia a `arrow-up` con tooltip "Send". Misma lógica que `updateConversationalButtonIcon` de la referencia.
- **Mode (Build/Ask)**: se evaluó pero se removió por instrucción explícita — no forma parte del composer final.

### Selector de contexto (barra gris): Project, App o Agent

Solo existe en el **estado vacío**, antes de que arranque la conversación — una vez el chat pasa a hilo activo, la barra desaparece por completo (`display: none` sobre el dropdown dentro de `.project-select-wrap--docked`) y el composer docked queda igual que si el selector no existiera.

No es un selector project-only: cualquiera de los tres (un Proyecto, una App o un Agente) puede ser el tema de una conversación, así que la barra deja elegir entre los tres.

- **Forma**: barra gris (`--color-surface-sunken`, sin border), 550px fijos, centrada respecto al composer, que se posiciona detrás de este y asoma ~14px por encima (overlap logrado con `padding-bottom` + `margin-bottom` negativo en la barra, y `z-index` mayor en el `.chat-input-shell`). Sin border — solo el fondo gris la distingue del panel.
- **Animación cíclica en el estado vacío**: mientras nada está seleccionado, el trigger rota cada 2.2s entre "Select a project" (folder) → "Select an app" (layout-grid) → "Select an agent" (bot), con un crossfade de ícono+texto (`.project-select-trigger-content.is-fading`, opacity, **320ms, `ease-in-out`** — se subió de 200ms/`--ease-out` para que se sienta más suave, no un "snap"). El mismo fade también corre al **seleccionar** un ítem y al **limpiar** con la "x" (antes esos dos casos cambiaban el ícono+texto de golpe, sin transición).
- **Popover** (abre hacia arriba, 300px de ancho — no 260px: con 4 tabs en una fila ese ancho hacía que "Agents" se fuera a una segunda línea): buscador en vivo + tabs **All / Projects / Apps / Agents** (`.panel-filter-tab`, la misma clase decoupled-de-`.search-tab` que ya usa el picker del panel lateral) + resultados agrupados por categoría (`.panel-open-results`/`.panel-open-item`, también reutilizados del picker del panel — mismo componente visual, redimensionado a 220px de alto para este popover más chico).
- **Una sola fuente de datos mock**: reusa directamente `PROJECTS_DATA`/`PANEL_APPS_DATA`/`PANEL_AGENTS_DATA` y los mapas `PANEL_OPEN_ICONS`/`PANEL_OPEN_LABELS` que ya existían para el picker del panel lateral — no se inventó un segundo set de proyectos/apps/agentes para esta barra.
- **Al seleccionar algo**: la barra **mantiene su tamaño y forma originales** (550px, mismo radio, mismo padding) — no se contrae ni se convierte en badge. Solo cambia el ícono+label (al ítem elegido) y aparece un ícono "x" al extremo derecho para limpiar la selección. Al hacer clic en la "x", el ciclo de animación se reactiva y vuelve al estado inicial.
- **"New project" agregado dentro del grupo Projects (2026-08-13, agregado desde Projects).** Entry point 3 de 3 de "Crear proyecto" (ver `home.md` → sección "Create project"): un ítem con tinte primario y ícono `plus` aparece siempre al final del grupo Projects de `renderContextResults` — a diferencia de los proyectos/apps/agentes reales, no se filtra por `term` (sigue visible aunque la búsqueda no matchee ningún proyecto), porque es una acción, no un dato. Clickearlo cierra este popover y abre el modal de creación (`openCreateProjectModal`) con un callback que selecciona el proyecto recién creado en **esta misma barra** una vez existe — es la razón de tenerlo acá y no solo en la vista Projects. Apps y Agents siguen sin su propio "New app"/"New agent" — no existe flujo de creación para esos todavía.

### Menciones con `@` (etiquetar contexto desde el texto)

Escribir `@` dentro del textarea (en cualquiera de los dos composers, vacío o docked) abre un panel para etiquetar un Project, App o Agent inline en el mensaje — un segundo camino hacia el mismo contexto que ya cubre la barra gris, pero disparado desde el texto en vez de un control aparte.

- **Ancho igual al del input, no un popover angosto.** `.mention-panel` es `position: absolute; width: 100%` respecto a `.chat-input-shell` — ocupa el mismo ancho que el área de texto/composer completo, a diferencia de los demás popovers del composer (Model, Add context, selector de contexto) que son angostos y centrados/alineados a un trigger puntual.
- **Abre hacia arriba, no hacia abajo.** Se pidió inicialmente que abriera debajo del chat, pero el composer docked está a solo ~20px del borde inferior del viewport — un panel de ~250px de alto abriendo hacia abajo ahí quedaría casi completamente recortado por el `overflow: hidden` de `.chat-pane`/`.chat-thread-main`. Se abre hacia arriba (mismo lado que el popover de la barra gris) para que se vea completo en ambos estados del chat.
- **Detección del `@` activo**: `getMentionQuery()` busca hacia atrás desde el cursor un `@` que (a) esté al inicio del texto o precedido de un espacio, y (b) no tenga un espacio entre él y el cursor todavía — el mismo criterio estándar de menciones (Slack/Notion/Linear). Evita que algo como `test@example.com` dispare el panel a mitad de palabra.
- **Tabs + resultados**: mismas All/Projects/Apps/Agents (`.panel-filter-tab`) y mismos datos mock (`PROJECTS_DATA`/`PANEL_APPS_DATA`/`PANEL_AGENTS_DATA` vía `panelOpenDataFor`) que ya usan el selector de contexto y el picker del panel lateral — un tercer punto de entrada a la misma información, no una cuarta lista inventada.
- **Filtro en vivo**: el texto escrito después del `@` (antes de un espacio) filtra la lista al vuelo, combinado con la tab activa — igual que el resto de los pickers del prototipo.
- **Insertar mantiene el foco en el textarea.** Los clics en tabs y en resultados usan `mousedown` con `preventDefault()` para que el textarea nunca pierda el foco/cursor antes de que el `click` inserte el texto — sin eso, el navegador movería el foco al botón clickeado y se perdería la posición de inserción.
- **Al seleccionar un ítem**: reemplaza el `@query` escrito por `@Nombre completo ` (con espacio final) y cierra el panel. Escape también lo cierra sin insertar nada. Un espacio después del `@` sin haber seleccionado nada también lo cierra (la mención "terminó").

### Header del hilo de chat

Aparece en la parte superior del estado activo (`.chat-thread-header`, franja de **50px** con borde inferior — mismo alto que `.sidebar-header` y que la barra de tabs del panel lateral, para que los íconos de acción de las tres queden alineados horizontalmente en vez de desfasados), y se calcula una sola vez al arrancar la conversación (`updateChatThreadHeader`):

- **Sin contexto asociado**: ícono `message-circle-more` + nombre del chat.
- **Con contexto asociado** (si se había seleccionado un Project/App/Agent en la barra gris antes de mandar el primer mensaje): ícono del tipo elegido (folder/layout-grid/bot, según corresponda) + su nombre (tono más tenue, `--color-ink-faint`, como ancestro del breadcrumb) → separador literal "`/`" → ícono de chat + nombre del chat (tono pleno, `--color-ink`, como ítem activo).
- **Nombre del chat**: se deriva del primer prompt del usuario (`deriveChatTitle`) — se usa tal cual si mide ≤48 caracteres, o se trunca a 48 + "…" si es más largo. No hay edición manual del nombre todavía.

### Mensajes y microinteracciones

- **Suggestion chips como atajo, no como único camino.** 3 prompts precocinados para probar el prototipo sin escribir; el input siempre acepta texto libre.
- **El primer mensaje del usuario siempre dispara una respuesta canned.** Simplificación deliberada: en producción no toda respuesta sería inmediata ni fija, pero para *validar la experiencia* del mecanismo de conversación conviene que sea predecible en la demo.
- **Typing indicator de 3 puntos antes de cada respuesta** (900ms en el primer mensaje, 800ms en los siguientes) — microinteracción pedagógica que muestra que el agente está "trabajando" antes de que aparezca la respuesta. Es el **único lugar del chat que muestra el ícono del agente** (`simetrik-agent-icon.png`, 18px) — con una animación de pulso (`scale(1)` → `scale(1.2)`, 1.2s en loop) que refuerza la idea de "procesando". Sigue teniendo su propio fondo de "burbuja" (`--color-surface-sunken`) porque es un estado de carga transitorio, no un mensaje.
- **Respuestas de la IA: texto libre, no burbuja, sin avatar.** `.msg--ai .msg-bubble` no tiene fondo, radio ni padding — el texto del agente queda como texto plano, sin contenedor visual y sin ícono al lado (a diferencia del typing indicator, que sí lo tiene). Decisión explícita: que el usuario sienta que le está "hablando" el agente, no que recibe una tarjeta.
- **Burbuja del usuario, más liviana, sin avatar.** Fondo `--color-primary-tint` (el mismo azul clarito que el estado activo del sidebar) con texto `--color-ink` (negro), en vez del azul sólido con texto blanco que tenía antes. Tampoco lleva avatar (se removieron las iniciales "IR" que tenía antes) — la burbuja alineada a la derecha ya es suficiente para identificarlo, y sin avatar compite menos visualmente con la respuesta del agente.
- **Ningún mensaje real (ni usuario ni IA) lleva avatar hoy** — es exclusivo del typing indicator. `align-items: center` en `.msg` y `.typing-indicator` evita que un mensaje de dos líneas deforme el ícono circular (bug real encontrado y corregido, en su momento aplicado a los avatares que sí existían ahí).
- **Sin panel de artefacto.** Se prototipó un panel split-pane ("Reconciliation Summary") en una iteración anterior y se removió por completo (markup, CSS y JS) porque no correspondía al comportamiento real de la referencia.
- **Copy: "artifact" → "app".** Todas las menciones a "artifact" en el copy visible (greeting, suggestion chip "Generate a sample app") se cambiaron a "app", alineado con que el chat debe poder construir Apps, no "artefactos" sueltos (ver Pendiente / abierto).

### Brillo del saludo ("What do you want to build today?")

Una ola de luz recorre el headline del estado vacío, en loop. Cada letra de `#chatGreetingHeadline` se envuelve en su propio `<span class="glow-letter">` (`initGreetingShine()`), animando `color` entre `--color-ink` y `--color-ink-faint` con un delay escalonado de 60ms por letra — eso es lo que crea la sensación de ola viajando de izquierda a derecha en vez de todo el texto pulsando junto.

- **Sin gradient-text.** La técnica "obvia" (`background-clip: text` + gradiente animado) está explícitamente prohibida por las leyes de diseño de Simetrik. Se descartó a propósito y se usó animación de `color` plano por letra en su lugar — mismo efecto percibido, sin violar la regla.
- **Banda angosta, no un parche difuso.** El pico de brillo por letra es corto (2.7%–5.4% del ciclo) — como máximo 2-3 letras se ven "encendidas" a la vez, no media oración pálida a la vez.
- **Fluida, con pausa entre repeticiones.** Ciclo total de 4.6s con easing `ease-in-out` (no `--ease-out`, que se siente más "snap" que "glow"): el barrido completo tarda ~1.4s en recorrer las 32 letras, y después queda quieto (`--color-ink` completo) durante **~3 segundos** antes de repetirse — para que no se sienta repetitivo.
- **Accesible**: el `<h1>` tiene `aria-label` con el texto completo sin fragmentar, así que un screen reader lee la oración normal en vez de 32 `<span>` sueltos.

### Panel lateral del chat (Project / App / Agent, mecanismo de tabs)

> Documentación completa movida a [`chat-side-panel.md`](./chat-side-panel.md) — el detalle de comportamiento acumuló suficiente complejidad (open picker con buscador/filtros, tabs, posición del "+", bugs encontrados y corregidos) como para merecer su propio archivo. Acá queda solo el resumen.

Botón `panel-right` (`#chatPanelToggle`, esquina superior derecha del chat) que colapsa la columna de conversación a 370px y revela `.chat-side-panel` al lado. Dentro, dos estados excluyentes vía `[hidden]`:

- **Open picker** (`#panelOpenPicker`, sin tabs abiertos): "What do you want to open?" con buscador en vivo + tabs de filtro (All/Projects/Apps/Agents) sobre tres fuentes (`PROJECTS_DATA`, `PANEL_APPS_DATA`, `PANEL_AGENTS_DATA`) — Map no es una opción separada, es una vista dentro de un tab de Project.
- **Tabs view** (`#panelTabs`, ≥1 tab abierto): barra de tabs (50px, alineada con `.chat-thread-header`) + contenido placeholder del tab activo. El "+" para agregar otro tab tiene posición fija (respeta el espacio de los botones de acción) y alineación de popover dinámica (start/end) para no cortarse contra el borde del panel.
- **Expand / Restore width**: botón adicional junto a "Hide panel" — modo foco que además de expandir el panel al 100% (colapsando la conversación a 0) también fuerza colapsado el sidebar de navegación de la app, para dejar toda la pantalla dedicada al panel.

Se resetea (tabs + búsqueda + filtro + modo foco) al iniciar un chat nuevo. Ver el archivo dedicado para el detalle completo, los bugs encontrados/corregidos y el estado de implementación.

## Estado actual de implementación

- ✅ Transición estado vacío → hilo de chat, con mensajes de usuario/IA animados (fade + translateY, 320ms)
- ✅ Composer completo: Add context (popover + file picker real), Model picker (con logos reales por vendor e ícono sincronizado en el trigger), Voice (dictado real con waveform fiel a la referencia, toolbar completa se oculta al grabar), Send (ícono dinámico)
- ✅ Selector de contexto en el estado vacío: barra con animación cíclica (Project/App/Agent) + popover con tabs, búsqueda, selección y limpieza vía "x" — todas las transiciones (ciclo/selección/limpieza) fadean suave (320ms, ease-in-out)
- ✅ Menciones con `@` en el textarea (ambos composers): panel del mismo ancho que el input, tabs + resultados, filtro en vivo, inserta `@Nombre `
- ✅ Header del hilo con breadcrumb condicional (contexto/chat o solo chat, ícono según el tipo elegido) y nombre de chat derivado del primer prompt
- ✅ Typing indicator (único lugar con avatar del agente, con pulso) y respuestas canned (texto libre, sin burbuja ni avatar; burbuja del usuario en azul clarito con texto negro, sin avatar)
- ✅ Brillo animado del headline de saludo (ola letra por letra, con pausa entre repeticiones)
- ✅ Panel lateral: mecanismo completo (open picker con buscador/filtros, sistema de tabs) — ver [`chat-side-panel.md`](./chat-side-panel.md) para el detalle
- ⛔ Todo el contenido de la IA es canned (2-3 respuestas fijas), no hay generación real
- ⛔ La respuesta del agente es siempre la misma (resumen de conciliación en texto), no varía según lo que escriba el usuario ni según el contexto seleccionado
- ⛔ **Generación de apps desde el chat: todavía no implementada.** El chat debe eventualmente permitir crear/configurar Apps (no artefactos sueltos) como una de sus salidas principales — hoy no existe ningún flujo, mock ni respuesta canned que lo represente.
- ✅ "New project" dentro del grupo Projects del selector de contexto, abre el modal de creación y auto-selecciona el resultado en la misma barra (ver sección arriba)
- ⛔ El selector de contexto sigue sin "New app"/"New agent"; esos dos siguen usando los mismos datos mock fijos del picker del panel lateral
- ⛔ Sin manejo de error (¿qué pasa si el "agente" no puede resolver el pedido?)
- ⛔ El nombre del chat no se puede editar manualmente ni persiste (se recalcula solo al arrancar un chat nuevo)

## Pendiente / abierto

- **Panel lateral** (contenido de cada tab, persistencia, límite de tabs): ver [`chat-side-panel.md`](./chat-side-panel.md) → sección "Pendiente / abierto".
- ¿Cómo se ve el chat cuando el pedido es "crear un agente" o "crear una app" en vez de "generar un artefacto"? Hoy todo pedido termina en la misma respuesta canned — falta explorar la bifurcación de intención (app vs. agente vs. proyecto nuevo).
- **Generación de apps**: es una capacidad que el chat debe tener (definición de producto), todavía sin prototipar. Falta decidir cómo se ve el momento en que el agente propone o construye una app a partir de la conversación.
- ¿El composer docked (una vez la conversación arrancó) debería poder cambiar el contexto también, o queda fijo una vez elegido al inicio? Hoy la barra desaparece por completo al pasar a hilo activo.
- Estado de error / "no entendí tu pedido" — no se prototipó todavía.
- ¿Vale la pena poder editar el nombre del chat manualmente (como en Claude/ChatGPT), o el auto-título basado en el primer prompt es suficiente para el prototipo?
- "New project" ya resuelto para Projects (ver arriba) — ¿los otros dos (App/Agent) necesitan su propio flujo real de "crear nuevo" también, o quedan como picker sobre datos mock fijos permanentemente en el prototipo?
- **Menciones con `@`**: hoy insertan texto plano (`@Nombre `) en el textarea, sin ningún tratamiento visual especial una vez insertado (no queda resaltado, no es un "chip" removible) — falta decidir si una mención ya insertada necesita su propio estilo o comportamiento (editar/quitar) dentro del texto.
- ¿La barra gris y las menciones con `@` deberían compartir estado (si ya etiquetaste un proyecto por `@`, la barra gris debería reflejarlo), o son intencionalmente independientes?

## Archivos relacionados

- `flows/home/index.html` — todo vive acá: markup del composer (`.chat-input-shell`, `.project-select-*`, `.composer-*`, `.mention-panel`), header del hilo (`.chat-thread-header`), headline animado (`#chatGreetingHeadline`, `.glow-letter`), y el script con `startChat`, `continueChat`, `addMessage`, `showTyping`/`removeTyping`, `wireComposerVoice`, `startDictation`/`stopDictation`, `drawVoiceWaveform`, `updateSendButtonIcon`, `deriveChatTitle`, `updateChatThreadHeader`, `initGreetingShine`, el selector de contexto (`CONTEXT_CYCLE`, `contextState`, `initContextSelector`, `renderContextResults`, `selectContext`, `clearContext`) y las menciones con `@` (`mentionState`, `getMentionQuery`, `renderMentionResults`, `insertMention`, `wireMention`) — estos últimos dos reusan `PROJECTS_DATA`/`PANEL_APPS_DATA`/`PANEL_AGENTS_DATA`/`PANEL_OPEN_ICONS`/`panelOpenDataFor` ya definidos para el picker del panel lateral.
- `shared/tokens.css` — tokens de color/radio/sombra/duración que consume todo lo anterior, más el sistema de tooltips (`.tooltip-bottom`, `.tooltip-end`).
- [`chat-side-panel.md`](./chat-side-panel.md) — panel lateral (`.chat-thread-main`, `.chat-side-panel`, `#chatPanelToggle`): documentación completa aparte.
