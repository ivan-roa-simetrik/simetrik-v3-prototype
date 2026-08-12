# Chat

> Última actualización: 2026-08-12
> Archivo relacionado: `flows/home/index.html` (script inline al final del archivo)

> **Nota de idioma (2026-08-12):** todos los mensajes canned (usuario/IA) y el contenido del artefacto (Resumen de Conciliación → "Reconciliation Summary") pasaron a inglés, incluyendo términos de glosario que normalmente NO se traducen (Fuente → Source, Asiento contable → Journal entry, Período contable → Accounting period). Decisión explícita del usuario, documentada también en `login.md`.

## Propósito

Es el eje central del producto: la forma en la que el usuario crea proyectos, artefactos y agentes. No es un asistente lateral bolt-on (ese es el patrón `AiChat` de las leyes raíz, pensado para chat contextual sobre una pantalla ya existente) — acá el chat ES la pantalla principal.

## Decisiones tomadas

- **Dos estados de layout: vacío (greeting) y activo (hilo).** El estado vacío centra verticalmente un heading + input + suggestion chips. Al primer mensaje, se oculta ese estado y aparece el hilo de mensajes con un input "acoplado" (docked) abajo. Son el mismo archivo/página, dos estados de JS — no dos pantallas separadas (regla del skill: los sub-estados no se fragmentan en archivos).

- **Suggestion chips como atajo, no como único camino.** Se ofrecen 3 prompts precocinados ("Crear proyecto de Conciliación", "Generar artefacto de ejemplo", "Diseñar un agente") para que el prototipo se pueda probar sin escribir, pero el input siempre acepta texto libre.

- **El primer mensaje del usuario siempre dispara un artefacto.** Es una simplificación deliberada del prototipo: en producción no todo mensaje generaría un artefacto, pero para *validar la experiencia* del mecanismo chat → artefacto, conviene que sea inmediato y predecible en la demo.

- **Typing indicator de 3 puntos antes de cada respuesta (900ms en el primer mensaje, 800ms en los siguientes).** Es una microinteracción pedagógica (ley de motion): le muestra al usuario que la IA está "trabajando" antes de que aparezca el artefacto, en vez de que el artefacto aparezca de golpe sin transición.

- **Al mandar un mensaje de seguimiento con el artefacto ya abierto, el panel hace un "pulse" (destello de borde, 320ms) en vez de recargarse.** Comunica "esto se actualizó en vivo" sin necesidad de reconstruir el artefacto completo — es el gesto mínimo que valida la idea de "artefacto vivo" sin implementar la lógica real de regeneración.

- **Panel de artefacto en split-pane (decisión tomada junto con `home.md`).** Trade-off evaluado contra fullscreen (corta la conversación) y tabs (menos inmediato). Split-pane gana porque el chat sigue siendo el eje central incluso cuando ya hay un artefacto generado.

- **El artefacto mockeado es un "Resumen de Conciliación" con datos de ejemplo, no un placeholder gris.** Se construyó con contenido realista (Fuentes, Asientos contables, Período contable) siguiendo el glosario obligatorio, en vez de lorem ipsum, porque el objetivo es que se sienta como un instrumento de precisión y no como un mockup genérico (test del "AI slop").

## Fix de centrado (2026-08-12)

Auditoría de contenedores flex del chat encontró un bug real: `.msg` y `.typing-indicator` (avatar + burbuja/dots) no tenían `align-items` explícito. Con el default `stretch`, un mensaje de IA de dos líneas estiraba el avatar circular de 26px hasta deformarlo en óvalo. Se agregó `align-items: center` a ambos — el avatar ahora se mantiene circular y centrado verticalmente respecto a la burbuja sin importar cuántas líneas tenga el mensaje.

## Estado actual de implementación

- ✅ Transición estado vacío → hilo de chat
- ✅ Mensajes de usuario y de IA con animación de entrada (fade + translateY, 320ms)
- ✅ Typing indicator (dots bounce)
- ✅ Reveal del artefacto con split-pane animado
- ✅ Pulse de "actualización" en mensajes de seguimiento
- ✅ Cierre del artefacto (colapsa el split, vuelve el chat a ancho completo)
- ⛔ Todo el contenido de la IA es canned (2-3 respuestas fijas), no hay generación real
- ⛔ No hay múltiples artefactos ni historial de versiones del artefacto
- ⛔ El artefacto siempre es el mismo (resumen de conciliación); no varía según lo que escriba el usuario
- ⛔ Sin manejo de error (¿qué pasa si el "agente" no puede resolver el pedido?)

## Pendiente / abierto

- ¿Cómo se ve el chat cuando el pedido es "crear un agente" en vez de "generar un artefacto"? Hoy todo pedido termina en el mismo artefacto de conciliación — falta explorar la bifurcación de intención (artefacto vs. agente vs. proyecto nuevo).
- ¿El artefacto puede tener más de una versión visible a la vez (ej. comparar antes/después de un ajuste), o siempre se pisa el contenido anterior?
- Estado de error / "no entendí tu pedido" — no se prototipó todavía.
- ¿El chat necesita distinguir visualmente cuándo está "dentro de un proyecto" vs. un chat suelto de "Recientes"? Hoy no hay ninguna indicación en el área de chat de a qué proyecto pertenece la conversación activa.

## Archivos relacionados

- `flows/home/index.html` — todo el comportamiento vive en el `<script>` inline al final (funciones `startChat`, `continueChat`, `revealArtifact`, `pulseArtifact`)
- `shared/tokens.css` — clases `.chat-*`, `.msg*`, `.typing-*`, `.artifact-*`
