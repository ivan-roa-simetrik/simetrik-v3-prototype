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

- **Add context** (`+`): abre un popover hacia abajo con una sola opción, "Add images, PDFs, or CSVs", que dispara un `<input type="file">` oculto (Finder real del navegador). Cierra su propio tooltip al hacer clic (`tooltip-suppressed`) para no competir visualmente con el popover recién abierto.
- **Model picker**: pill con ícono + label (`Auto` por defecto, ícono asterisco). Popover hacia abajo, máx. 250px de alto con scroll, ancho 256px. Lista: Auto → Sonnet 4.6 / Sonnet 5 / Opus 4.8 / Opus 5 (logo real de Claude/Anthropic) → Gemini 3.1 Pro / GPT-5.6 / Grok 4.5 (logos reales de cada vendor) → sección "Small models": Gemini 3.5 Flash. Fable 5 queda deshabilitado (placeholder para un modelo futuro). Al seleccionar una opción, el trigger actualiza tanto el label como el ícono (clona el ícono de la opción elegida), y al cargar la página el trigger se inicializa con el ícono de "Auto".
  - Los logos de terceros (Claude, Gemini, ChatGPT, Grok) se usan únicamente porque identifican el modelo específico de ese vendor dentro de un selector de modelos — no como ícono genérico de "IA".
- **Voice**: dictado real, no simulado. `getUserMedia` pide permiso de micrófono, `AudioContext` + `AnalyserNode` alimentan un `<canvas>` con un waveform reactivo al audio real, y `SpeechRecognition`/`webkitSpeechRecognition` transcribe a texto dentro del textarea. Al activarse, la toolbar se reemplaza por `.composer-voice-row` (waveform arriba, Cancel/Send abajo), calcado de la estructura del `#build-voice-row` de la referencia.
- **Send**: el ícono cambia según el estado del input — vacío muestra `audio-lines` con tooltip "Talk to the agent" (invita a hablar en vez de escribir); en cuanto hay texto, cambia a `arrow-up` con tooltip "Send". Misma lógica que `updateConversationalButtonIcon` de la referencia.
- **Mode (Build/Ask)**: se evaluó pero se removió por instrucción explícita — no forma parte del composer final.

### Selector de proyecto (barra gris)

Solo existe en el **estado vacío**, antes de que arranque la conversación — una vez el chat pasa a hilo activo, la barra desaparece por completo (`display: none` sobre el dropdown dentro de `.project-select-wrap--docked`) y el composer docked queda igual que si el selector no existiera.

- **Forma**: barra gris (`--color-surface-sunken`, sin border), 550px fijos, centrada respecto al composer, que se posiciona detrás de este y asoma ~14px por encima (overlap logrado con `padding-bottom` + `margin-bottom` negativo en la barra, y `z-index` mayor en el `.chat-input-shell`). Sin border — solo el fondo gris la distingue del panel.
- **Trigger**: ícono de folder (16px, mismo peso visual que el resto de íconos secundarios) + label, justificado a la izquierda. Por defecto dice "Select project".
- **Popover** (abre hacia arriba, 260px de ancho): buscador en vivo (ícono lupa 16px, mismo tamaño y color gris que el texto placeholder — no debe pesar más que el ícono de folder) + lista de proyectos (reusa los mismos nombres que Pinned en el sidebar) + "New project" al final, tras un divisor, con el mismo padding `4px 2px` que los ítems de la lista.
- **Al seleccionar un proyecto**: la barra **mantiene su tamaño y forma originales** (550px, mismo radio, mismo padding) — no se contrae ni se convierte en badge. Solo cambia el label (nombre del proyecto, justificado a la izquierda igual que "Select project") y aparece un ícono "x" al extremo derecho de la barra para limpiar la selección. Al hacer clic en la "x", vuelve exactamente al estado inicial ("Select project", sin proyecto).
- **New project**: hoy es un no-op (solo cierra el popover) — no hay flujo real de creación todavía, mismo estado que el botón "+" de Projects en el sidebar.

### Header del hilo de chat

Aparece en la parte superior del estado activo (`.chat-thread-header`, franja de 44px con borde inferior), y se calcula una sola vez al arrancar la conversación (`updateChatThreadHeader`):

- **Sin proyecto asociado**: ícono `message-circle-more` + nombre del chat.
- **Con proyecto asociado** (si se había seleccionado uno en la barra gris antes de mandar el primer mensaje): folder + nombre del proyecto (tono más tenue, `--color-ink-faint`, como ancestro del breadcrumb) → separador literal "`/`" → ícono de chat + nombre del chat (tono pleno, `--color-ink`, como ítem activo).
- **Nombre del chat**: se deriva del primer prompt del usuario (`deriveChatTitle`) — se usa tal cual si mide ≤48 caracteres, o se trunca a 48 + "…" si es más largo. No hay edición manual del nombre todavía.

### Mensajes y microinteracciones

- **Suggestion chips como atajo, no como único camino.** 3 prompts precocinados para probar el prototipo sin escribir; el input siempre acepta texto libre.
- **El primer mensaje del usuario siempre dispara una respuesta canned.** Simplificación deliberada: en producción no toda respuesta sería inmediata ni fija, pero para *validar la experiencia* del mecanismo de conversación conviene que sea predecible en la demo.
- **Typing indicator de 3 puntos antes de cada respuesta** (900ms en el primer mensaje, 800ms en los siguientes) — microinteracción pedagógica que muestra que el agente está "trabajando" antes de que aparezca la respuesta. Sigue teniendo su propio fondo de "burbuja" (`--color-surface-sunken`) porque es un estado de carga transitorio, no un mensaje — no se le aplicó el cambio de las respuestas de abajo.
- **Respuestas de la IA: texto libre, no burbuja.** `.msg--ai .msg-bubble` no tiene fondo, radio ni padding — el texto del agente queda simplemente al lado de su avatar, sin contenedor visual. Decisión explícita: que el usuario sienta que le está "hablando" el agente, no que recibe una tarjeta.
- **Burbuja del usuario, más liviana.** Fondo `--color-primary-tint` (el mismo azul clarito que el estado activo del sidebar) con texto `--color-ink` (negro), en vez del azul sólido con texto blanco que tenía antes — para que lo que envía el usuario no compita visualmente con la respuesta del agente.
- **Avatares**: solo la IA tiene avatar — `simetrik-agent-icon.png` (el pinwheel, no el isologo de marca) sin fondo (`background: none`), 16px. Los mensajes del usuario no llevan avatar (se removieron las iniciales "IR" que tenían antes); la burbuja alineada a la derecha es suficiente para identificarlos. `align-items: center` en `.msg` y `.typing-indicator` evita que un mensaje de dos líneas deforme el avatar circular del agente (bug real encontrado y corregido).
- **Sin panel de artefacto.** Se prototipó un panel split-pane ("Reconciliation Summary") en una iteración anterior y se removió por completo (markup, CSS y JS) porque no correspondía al comportamiento real de la referencia.

### Panel lateral del chat (Project / Map / App — contenido pendiente de definir)

Botón `panel-right` que colapsa la columna de conversación y abre un panel vacío al lado, para eventualmente elegir entre abrir un proyecto, una vista de mapa o una app ahí mismo. Solo se construyó el mecanismo de colapsar/expandir — el contenido de las 3 opciones todavía no se definió ni se implementó a propósito (instrucción explícita: no salirse de la definición inicial del comportamiento).

- **El botón le pertenece a la vista, no al chat.** Vive como hijo directo de `.chat-pane` (no dentro de `.chat-thread-header`) y se posiciona con `position: absolute; top: 8px; right: 20px` respecto a todo el panel — se queda anclado en esa esquina sin importar si el chat está a ancho completo o colapsado. Solo es visible una vez el chat está en estado de hilo activo (oculto en el estado vacío y en las vistas de Apps/Agents).
- **Comportamiento**: un clic colapsa `.chat-thread-main` a **370px fijos** y revela `.chat-side-panel` (vacío) ocupando el resto del ancho, a toda la altura. Otro clic revierte todo. Se resetea automáticamente al iniciar un chat nuevo.
- **Animación fluida (420ms, ease-out)**: ambas columnas están siempre en el layout flex (nunca `display: none`), animando `flex-grow`/`flex-basis` y `opacity` en vez de aparecer/desaparecer de golpe — así el colapso y la revelación del panel se sienten como una sola transición coordinada, no un salto instantáneo.
- **Estilo neutro, no de estado activo**: el ícono se mantiene siempre en el mismo gris tenue (`--color-ink-faint`), abierto o cerrado — no se pinta de azul primario al activarse, para no competir visualmente con el resto de la UI.
- **Panel vacío**: fondo `--color-sidebar-bg` (el mismo gris del sidebar, no blanco) — sin contenido todavía.
- **Tooltip**: "Show panel" / "Hide panel" según el estado, alineado al borde derecho del botón (`.tooltip-end`, nuevo modificador en `tokens.css`) en vez de centrado — evita que se salga de la pantalla al estar en la esquina superior derecha.

## Estado actual de implementación

- ✅ Transición estado vacío → hilo de chat, con mensajes de usuario/IA animados (fade + translateY, 320ms)
- ✅ Composer completo: Add context (popover + file picker real), Model picker (con logos reales por vendor e ícono sincronizado en el trigger), Voice (dictado real con waveform reactivo), Send (ícono dinámico)
- ✅ Selector de proyecto en el estado vacío: barra + popover con búsqueda, selección, limpieza vía "x", y "New project" (no-op)
- ✅ Header del hilo con breadcrumb condicional (proyecto/chat o solo chat) y nombre de chat derivado del primer prompt
- ✅ Typing indicator y respuestas canned (texto libre, sin burbuja; burbuja del usuario en azul clarito con texto negro)
- ✅ Panel lateral: mecanismo de colapsar/expandir el chat (370px) con animación fluida — sin contenido todavía (Project/Map/App pendientes)
- ⛔ Todo el contenido de la IA es canned (2-3 respuestas fijas), no hay generación real
- ⛔ La respuesta del agente es siempre la misma (resumen de conciliación en texto), no varía según lo que escriba el usuario ni según el proyecto seleccionado
- ⛔ **Generación de apps desde el chat: todavía no implementada.** El chat debe eventualmente permitir crear/configurar Apps (no artefactos sueltos) como una de sus salidas principales — hoy no existe ningún flujo, mock ni respuesta canned que lo represente.
- ⛔ "New project" no crea nada real; el picker de proyectos usa datos mock fijos (los mismos 3 de Pinned)
- ⛔ Sin manejo de error (¿qué pasa si el "agente" no puede resolver el pedido?)
- ⛔ El nombre del chat no se puede editar manualmente ni persiste (se recalcula solo al arrancar un chat nuevo)

## Pendiente / abierto

- **Contenido del panel lateral**: definir cómo se ve y funciona cada una de las 3 opciones (abrir un proyecto, vista de mapa, abrir una app) dentro de `.chat-side-panel` — hoy el panel abre y cierra pero está completamente vacío. Incluye definir si hay un selector inicial (tarjetas, tabs, dropdown) antes de elegir.
- ¿Cómo se ve el chat cuando el pedido es "crear un agente" o "crear una app" en vez de "generar un artefacto"? Hoy todo pedido termina en la misma respuesta canned — falta explorar la bifurcación de intención (app vs. agente vs. proyecto nuevo).
- **Generación de apps**: es una capacidad que el chat debe tener (definición de producto), todavía sin prototipar. Falta decidir cómo se ve el momento en que el agente propone o construye una app a partir de la conversación.
- ¿El composer docked (una vez la conversación arrancó) debería poder cambiar de proyecto también, o el proyecto queda fijo una vez elegido al inicio? Hoy la barra desaparece por completo al pasar a hilo activo.
- Estado de error / "no entendí tu pedido" — no se prototipó todavía.
- ¿Vale la pena poder editar el nombre del chat manualmente (como en Claude/ChatGPT), o el auto-título basado en el primer prompt es suficiente para el prototipo?
- "New project" sigue siendo un no-op — falta definir si el prototipo necesita simular la creación real de un proyecto desde acá.

## Archivos relacionados

- `flows/home/index.html` — todo vive acá: markup del composer (`.chat-input-shell`, `.project-select-*`, `.composer-*`), header del hilo (`.chat-thread-header`), panel lateral (`.chat-thread-main`, `.chat-side-panel`, `#chatPanelToggle`), y el script con `startChat`, `continueChat`, `addMessage`, `showTyping`/`removeTyping`, `wireComposerVoice`, `startDictation`/`stopDictation`, `updateSendButtonIcon`, `deriveChatTitle`, `updateChatThreadHeader`.
- `shared/tokens.css` — tokens de color/radio/sombra/duración que consume todo lo anterior, más el sistema de tooltips (`.tooltip-bottom`, `.tooltip-end`) que usa el botón del panel lateral. No tiene clases propias del chat en sí, esas viven inline en `home/index.html`.
