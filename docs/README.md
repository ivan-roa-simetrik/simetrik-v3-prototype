# Documentación del prototipo — Simetrik Agéntico

Este directorio documenta las decisiones de UX/UI que se van tomando a medida que se itera el prototipo con `/simetrik-ui prototype`. No es una spec de producción (eso lo produce `handoff` una vez validada la experiencia) — es el registro vivo de *por qué* el prototipo se ve y se comporta como se ve, para no perder contexto entre sesiones.

Un archivo por sección. Se actualiza en cada iteración, no se reescribe desde cero.

## Secciones documentadas

| Sección | Archivo | Qué cubre |
|---|---|---|
| Login | [`login.md`](./login.md) | Layout split light/dark, referencia visual usada, excepción a Ley 6 |
| Home | [`home.md`](./home.md) | Layout general post-login, estado inicial, relación sidebar/chat/artefacto |
| Sidebar | [`sidebar.md`](./sidebar.md) | Jerarquía de navegación, estructura de Proyectos/Apps/Agents, comportamiento collapse |
| Chat | [`chat.md`](./chat.md) | El eje central: estados, generación de artefactos, microinteracciones |

**Nota de idioma (2026-08-12):** por instrucción explícita del usuario, todo el copy del prototipo (login, home, sidebar, chat) pasó de español a inglés. Los `.md` de esta carpeta se siguen escribiendo en español (son para el equipo interno), pero el copy citado dentro de cada uno ya refleja el inglés real de la UI.

## Convención de cada archivo

1. **Propósito** — qué resuelve esta sección en la experiencia
2. **Decisiones tomadas** — con fecha y el porqué, no solo el qué
3. **Estado actual de implementación** — qué está real (interactivo) vs. mock/placeholder
4. **Pendiente / abierto** — lo que se difirió a otra iteración, para no perderlo
5. **Archivos relacionados** — dónde vive el código

## Estado global del prototipo

- **Modo técnico:** HTML standalone multi-flujo (no hay `Prototype/components.json` en este repo)
- **Journey cubierto hoy:** Login → Home (sidebar + chat) → primer artefacto generado
- **No cubierto todavía:** contenido real de Apps y Agents, vista de "todos los proyectos", creación de proyecto/agente vía chat con lógica real, persistencia de estado
- **Login:** ver decisiones de propuesta de valor en el propio `index.html` (todavía no tiene `.md` dedicado porque es una sola pantalla sin mucha ambigüedad de estructura; si gana complejidad se documenta aparte)

## Historial de sesiones

| Fecha | Qué se agregó/cambió |
|---|---|
| 2026-08-12 | Primera versión: login split-screen, home Codex-style, sidebar completo, chat con split-pane de artefacto |
| 2026-08-12 | Assets de marca reales aplicados: `Simetrik_logo.svg` (wordmark) en el login, `Simetrik_isologo.png` (marca reducida) en el logomark del sidebar y en el avatar del agente dentro del chat. Ver `assets/img/` para el resto de recursos recibidos, pendientes de definición (ver nota abajo). |
| 2026-08-12 | Login reconstruido a partir de imagen de referencia: split light (login)/dark (propuesta de valor), mockup flotante de workflow, `Cover.png` como fondo del panel oscuro. Todo el prototipo (login, home, sidebar, chat) traducido a inglés. Naming del producto ajustado a "Simetrik V3" / "Simetrik as Code" siguiendo la referencia. |
| 2026-08-12 | Auditoría de centrado de contenedores en el login (checklist agregado a `login.md`): todos los flex containers icono+texto ya usaban `align-items: center` explícito. Confirmado que el logo queda justificado a la izquierda, encima de "Welcome to Simetrik V3". Pendiente: confirmación visual en navegador real (no se pudo capturar screenshot en este entorno). **Home todavía no se toca — se espera indicación explícita del usuario.** |
| 2026-08-12 | Cambios del home aplicados: fix real de centrado en `.msg` y `.typing-indicator` (avatar se deformaba en mensajes de 2 líneas por falta de `align-items`). Confirmado que logomark del sidebar y naming "Simetrik V3" en el `<title>` ya estaban correctos, sin cambios necesarios ahí. |
| 2026-08-12 | Centrado del login ajustado: panel izquierdo centrado en los dos ejes (logo se separó a `position: absolute` top-left para no interferir), panel derecho centrado solo verticalmente (simétrico) manteniendo el texto justificado a la izquierda. |
| 2026-08-12 | Revisión del mismo día: logo del login vuelve a estar en flujo (ya no `position: absolute`), directamente encima de "Welcome to Simetrik V3", más grande (24px → 36px). Panel derecho ahora también centrado en ambos ejes (antes solo vertical). Favicon agregado (`Simetrik_isologo.png`), por ahora solo en `index.html`. |
| 2026-08-12 | Fix: `.mockup-wrap` ("Workflow · Period close") se había angostado como efecto secundario del centrado del panel derecho (pasó de `stretch` a `shrink-to-fit` sin querer). Se le dio `width: 560px` explícito para que vuelva a su ancho original. |
| 2026-08-12 | `simetrik-agent-icon.png` confirmado como ícono oficial del agente (no era un archivo suelto). Reemplaza al isologo genérico en el headline "Everything goes through the agent." del login, agrandado de 30px a 36px. |
| 2026-08-12 | Campos de login prellenados para demo: email real (`ivan.roa@simetrik.com`), password ficticia (`demo1234`, no la real que se pidió originalmente — ver `login.md` para el porqué). |
| 2026-08-12 | Logo: +24px de separación con el título. Panel derecho: tratamiento de tarjeta flotante (margin 24px + border-radius 24px, flush a la izquierda). Mockup card: loop de animación (tipeo del prompt → pasos del pipeline se encienden en secuencia → badges aparecen como respuesta del agente → reset). Corrección: eyebrow/headline/subhead vuelven a estar justificados a la izquierda (pills y mockup card siguen centrados). Favicon confirmado sin cambios — coincide con `Simetrik_isologo.png` ya aplicado. |
| 2026-08-12 | Panel derecho del login: `max-width: 700px` agregado — deja de estirarse a lo ancho de la columna del grid en pantallas anchas. |
| 2026-08-12 | Revertido: se sacó el `max-width: 700px` del panel derecho, vuelve a ocupar toda su columna del grid. |
| 2026-08-12 | Panel derecho: padding horizontal 64px → 224px (izq/der). Animación del mockup: se agregó avatar de persona (ícono `user`) junto a la burbuja del chat, para que se sienta como alguien chateando de verdad. |

## Nota sobre assets pendientes (actualizada 2026-08-12)

En `assets/img/` hay más recursos de los que ya se aplicaron, todavía sin instrucción clara de uso:

- `Simetrik_logo_white.svg` / `Simetrik_logo_white_.svg` — variante blanca del wordmark, sin uso definido todavía (ningún panel del prototipo es de fondo sólido de color por ahora)
- ~~`simetrik-agent-icon.png` / `descarga.png` — mismo archivo duplicado~~ **Resuelto:** confirmado como el ícono oficial del agente (distinto del isologo de la marca). Ya aplicado en el headline del login. `descarga.png` (el duplicado) sigue sin usarse.
- `agent-icon.svg`, `onboarding-intro.mp4`, `user_profile.jpeg` — sin instrucción de uso todavía; `user_profile.jpeg` podría reemplazar las iniciales "IR" del avatar del footer si se confirma
- `Cover.png` — fondo degradado azul/negro, propósito sin confirmar
- `claude-logo_svgstack_com_...svg` — **es el isotipo de Claude/Anthropic (marca de terceros). Por instrucción explícita del usuario, NO se usa en el prototipo por el momento.** Queda en la carpeta sin referenciar en ningún HTML.
- Pendiente de recibir: tipografía "Belong" (sin archivo todavía) y recurso de referencia para el responsive del sidebar (sin archivo todavía)
