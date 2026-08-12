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

- ¿"Proyectos" como nav de primer nivel debería eventualmente abrir una vista propia (grid con últimos proyectos, metadata de actividad), o el listado del sidebar es suficiente para siempre? Hoy no tiene vista propia por decisión de scope, no por descarte definitivo.
- Definir qué pasa en el chat cuando el usuario pide explícitamente "crear un agente" — ¿el artefacto pane se convierte en un formulario de configuración de agente, o es un flujo separado? Todavía no se ha explorado.
- Responsive/mobile no se evaluó — el layout de dos columnas fijas asume desktop.

## Archivos relacionados

- `flows/home/index.html` — markup + JS del home completo
- `shared/tokens.css` — estilos de shell (sidebar) reutilizados acá
- `shared/shell.js` — collapse de sidebar, expand de proyectos
