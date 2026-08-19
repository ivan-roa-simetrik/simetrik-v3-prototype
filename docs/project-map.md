# Project View Map (concepto: modelo de nodos)

> Última actualización: 2026-08-18
> Este archivo es distinto a los demás de `docs/`: como `proyecto.md` y `apps.md`, no documenta una pantalla — documenta el **modelo conceptual** de los nodos que van a vivir en el mapa de un proyecto, para que las fases de implementación (ver [`map.md`](./map.md)) no tengan que re-derivar estas decisiones cada vez que se agregue algo nuevo al mapa.
> Ver también: el artifact **"Planos del Mapa"** (misma sesión, previo a este documento) — inventario de funcionalidades del mapa cruzado con la arquitectura real, del que salió la priorización que llevó a construir Fase 0/Fase 1 antes de definir esto.

## Propósito

El mapa (pilar 2 de la visión de producto: "canvas/mapa del workflow") es donde el usuario ve y entiende lo que el agente construyó — un proyecto es un grafo de nodos. Antes de dibujar un solo nodo real en Simetrik v3.1 hacía falta cerrar **qué tipos de nodo existen**, porque esa decisión determina el layout, los íconos, y qué va en el drawer de detalle de cada uno. Este documento es el resultado de esa conversación, y el registro de por qué se descartaron dos versiones anteriores antes de llegar a la final.

## El modelo de nodos (decisión, 2026-08-14)

Solo **3 tipos de caja** visibles en el mapa:

| Nodo | Variante/propiedad | Qué es |
|---|---|---|
| **Integración** | `direccion: entrada \| salida` | Punto de entrada o salida del proyecto. Es **la misma caja con una propiedad de dirección**, no dos tipos separados: `entrada` = ingreso externo (archivo, FTP, partnership) que alimenta uno o más nodos Dataset; `salida` = egreso (ERP, banco, reporte), espejo de la de entrada. |
| **Dataset** | — (sin variantes) | El nodo central: siempre una tabla. Nace de una Integración o del resultado de un ruleset que procesa/cruza otros Datasets — pero visualmente **es siempre el mismo tipo de caja**. La diferencia entre "un dataset normal" y "un dataset que es el resultado de una conciliación" vive en **tags libres** sobre el nodo (ej. `conciliación`, `journal-entry`), nunca en el tipo del nodo ni en un glifo distinto. |
| **Function** | — | Operación gobernada (leer/escribir sobre un Dataset) que un App o Agente puede invocar, con su propio ciclo de vida (candidata → disponible → vinculada → otorgada → activa → pausada → superseded → deprecada → retirada). |

Y lo que **no** es una caja en el mapa, a propósito:

- **Ruleset** — el conjunto de reglas (puede ser SQL, puede ser otra lógica) que define de dónde vienen los datos de un Dataset, qué se hace con ellos y cómo se procesan. Es el **origen** de un Dataset — la razón por la que existe — pero vive **dentro** de él, no como una caja que el usuario ve como nodo independiente. Una arista del grafo nunca dice "esto es una conciliación"; eso lo dice un tag sobre el Dataset resultante, y el ruleset detrás (invisible como nodo) es lo que efectivamente lo produjo.

## Cómo se llegó acá (para no repetir el camino)

Tres versiones, cada una descartada por una razón concreta:

1. **Primer candidato — los 6 tipos de los mocks** (`Integration` / `Dataset` / `Ruleset` / `Output` / `Function` / `App`, tomados de `mock-v3/flows/build` y `mock-v3/flows2/home`). Descartado: es fiel a lo más *vistoso* de los mocks, no a la arquitectura real — trata a Ruleset y Output como cajas de primera clase cuando el vocabulario real no lo hace así.
2. **Segundo candidato — 2 tipos reales + variante "conciliación"** (`integracion` / `datos`, con un glifo `Blend` para conciliación), sacado directo del código ya shipped del producto real (`frontend/src/lib/grafo.ts`: `TipoNodo`/`VarianteNodo`, `NodoGrafo.tsx`: `ICONO`). Este modelo es correcto **para lo que el producto real ya construyó** (milestone M2), pero es una foto parcial: no incluye el vocabulario completo del glosario oficial (`docs/reference/glossary.md`, `status: living`), que define **4 tipos conceptuales** (integración, datos, App, Output) y aclara que Output es *"espejo del nodo de integración"* — exactamente la dirección `entrada`/`salida` que el modelo final usa. Corregido con esa fuente: Integración pasó a tener dirección, y se agregó Function como tercera familia (el glosario dice que un Nodo App *"genera un backend de lambda functions"* — Function es la pieza granular de eso, y es lo que los mocks más ricos, `flows2/home`, ya modelan como nodo propio con ciclo de vida).
3. **Versión final — se saca la variante "conciliación" del todo.** Corrección explícita del usuario: *"no hay diferencia real entre un tipo de dataset y otro. Todos son datasets, finalmente"* — un tag (metadata libre) puede decir que un Dataset es el resultado de una conciliación, pero no es una variante estructural ni un glifo distinto. De paso quedó explícito que el Ruleset (las reglas que producen el Dataset, sea SQL o no) **no es un nodo del mapa** — es el origen invisible detrás de un Dataset.

## Fuentes citadas

- `Simetrik v3/docs/reference/glossary.md` — *"Nodo — unidad del workflow, con entradas y salidas... Tipos: nodo de integración, nodo de datos, nodo App, nodo Output"*; *"Nodo Output — rulesets de salida para integraciones de egreso... Espejo del nodo de integración."*
- `Simetrik v3/docs/reference/workflow-model.md` — *"Lo que un nodo ejecuta es código versionado (ruleset)"*; *"La conciliación no es un tipo aparte."*
- `Simetrik v3/docs/plan/nodo-conciliacion.md` — confirma que en el código real `nodes.kind` solo tiene 2 valores y que la conciliación se distingue por su ruleset + 2 aristas entrantes, no por tipo — la fuente que informó (parcialmente) el segundo candidato, luego corregido por el usuario.
- `Simetrik v3/frontend/src/lib/grafo.ts` / `NodoGrafo.tsx` — `TipoNodo`/`VarianteNodo`/`ICONO` reales. Contexto, no vinculante para v3.1: este prototipo no está atado a la secuencia de build del producto real (que deja Function como nodo del mapa para **M7**, muy adelante) — es un prototipo de experiencia, así que puede mostrar el vocabulario completo antes de que el backend real lo soporte.
- `Mock/mock-v3/reference/map/concepts/objects/{integration,output,dataset}.md` — material exploratorio (`status: draft`), usado como referencia de lenguaje pero no como fuente autoritativa (a diferencia del glosario, este directorio tiene preguntas abiertas sin resolver, ej. *"¿son in y out el mismo objeto?"*).

## Ambientes y el mapa (decisión, 2026-08-18 — previa a la Fase 5 de persistencia)

Antes de conectar el mapa a datos reales (`docs/supabase.md` → Fase 5) hacía falta cerrar cómo se relacionan los **ambientes de un proyecto** (`production`/`qa`/`dev`, ver `home.md` → "Footer y tags") con el mapa — el usuario marcó explícitamente que la arquitectura de la Fase 5 dependía de esto.

Se investigaron 3 referencias antes de decidir (ninguna tenía ya resuelto "cada ambiente = su propio mapa"):
- **Este prototipo**: `environments` es hoy solo un badge decorativo por proyecto, sin ninguna relación con el mapa.
- **Producto real (D17)**: ambientes = branches de git del repo de configuración del proyecto; deploy = taguear una versión de esa branch. Un solo historial, promovido entre ambientes — no mapas paralelos.
- **mock-v3**: `environment` es un campo singular por proyecto (etapa de vida: Dev → Prod), no ambientes coexistiendo.

**Decisión (confirmada con el usuario): un solo grafo de nodos por proyecto — los ambientes son puntos de promoción sobre esa misma línea de tiempo, no mapas independientes.** Mismo espíritu que D17: construís en el chat (equivale a un commit en `dev`), y promovés explícitamente a `qa`/`prod` cuando corresponde (equivale a taguear un deploy). Implementado como `project_environment_promotions` (append-only: proyecto + ambiente + qué `map_version` se promovió + quién + cuándo) — ver `docs/supabase.md`. El "ambiente actual" de un proyecto es la promoción más reciente para ese par (proyecto, ambiente); un ambiente sin ninguna promoción todavía se ve vacío, no es un error.

**Regla de aplicación para cuando se construya el reveal real (pendiente más grande de este archivo):** cada `map_version` nueva creada por el chat se promueve automáticamente a `dev` — promover a `qa`/`prod` es siempre una acción explícita del usuario, nunca automática.

**Implicación de UI todavía sin construir**: el mapa va a necesitar un selector de ambiente (hoy no existe — el canvas de Fase 2 es agnóstico a esto). Sin selector, "el mapa" pasa a ser ambiguo en cuanto haya más de una promoción — cuál versión mostrar depende de qué ambiente se esté mirando.

## Estructura interna de nodo: Data y Context (decisión, 2026-08-18)

Antes de conectar la Fase 5, se corroboró la estructura interna de un nodo contra la arquitectura real (`uploads`, ClickHouse, `rulesetKey` — ver investigación citada en `docs/supabase.md`) y se cerraron 2 conceptos que el plan original del mapa ya anticipaba como pestañas del drawer de detalle sin definir ("Data"/"Context"):

- **Uploads**: confirmado que existe en el producto real tal como se esperaba — metadata de archivos (`filename`, `bytes`, `sha256`, `object_key` hacia un bucket externo; el archivo nunca vive en la base de datos). Un nodo de Integración referencia el/los uploads que lo originaron.
- **"Data" (rows del nodo) — corrección real importante encontrada**: en el producto real, la Integración *"lee un archivo y emite filas, no crea tablas"* — la tabla de filas es del nodo **Dataset** aguas abajo (en ClickHouse, no Postgres), nunca de la Integración misma. **Decisión para v3.1 (divergencia deliberada, confirmada con el usuario): "Data" es una sección que tienen TODOS los nodos que transportan filas — Integración Y Dataset —, no solo el Dataset.** Cada uno documenta su propia lista de rows, con la forma de columnas que le corresponda en esa etapa del pipeline (varía tras cada transformación). Function queda afuera — no transporta datos propios, opera sobre los de un Dataset. Tabla `map_node_data` (fila = `jsonb`, sin esquema de columnas fijo).
- **Tags — confirmado sin cambios**: siguen siendo informativos/libres, sin disparar ejecución — "la facilidad de poder etiquetar nodos", pensados para filtrar el mapa más adelante (y a futuro, tags también sobre columnas de un dataset, no solo sobre el nodo). Esto es una divergencia consciente frente al producto real, que no usa tags en absoluto — ahí la distinción (ej. qué dataset es resultado de un cruce) se resuelve con un discriminador estructurado en la config (`config.izquierda`/`config.derecha`), no con etiquetas. Se mantiene la decisión original de la Fase 0 (tags libres) tal cual.
- **"Context" — sin precedente en el producto real** (ahí ni node ni dataset tienen descripción semántica, solo `projects.description` manual). Nuevo para v3.1: interpretación en lenguaje natural de qué hace el nodo, **construida y mantenida por el agente** a medida que impacta el nodo desde el chat — nunca editada a mano por el usuario. Columna propia `map_nodes.agent_context`.
- **Rulesets — confirmado sin cambios**, con matiz: el ruleset de una Integración ("trata la data que ingresa") y el de un Dataset (inserta, o cruza si es conciliación) son conceptualmente distintos — coincide con lo ya modelado.

Ver `supabase/migrations/0010_node_data_and_context.sql`.

## Versionado: una sola línea de tiempo, no una tabla por nodo (decisión, 2026-08-18)

El usuario preguntó explícitamente si hacía falta un historial de versiones **por nodo individual**, separado del historial del mapa completo (`map_versions`). Se evaluó y se descartó: **`map_versions.snapshot` ya contiene la foto completa de todos los nodos en ese momento** — "la versión de un nodo" no es información que falte, es información que ya está adentro y se obtiene **filtrando**, no guardando aparte.

- **Consultar la versión de un nodo puntual** = abrir la fila de `map_versions` que corresponda y buscar ese nodo por id dentro de `snapshot.nodes`.
- **Comparar el mismo nodo entre dos versiones** = repetir esa búsqueda en las dos fotos y comparar — lógica de la aplicación, no una tabla nueva.
- **Por qué no una tabla `map_node_versions` aparte**: crearía dos líneas de tiempo corriendo en paralelo (la del mapa completo y la de cada nodo) que podrían desincronizarse, y necesitaría una tabla más solo para mapear qué versión de nodo corresponde a qué versión de mapa — mismo error de "segunda fuente de verdad" ya evitado antes en esta migración (pin de proyectos, `SEARCH_DATA`).

**Requisito para cuando se construya la Fase 5 real**: `map_versions.snapshot` debe tener una forma predecible, `{ nodes: [...], edges: [...] }` (cada nodo con su `id`), para que filtrar "solo este nodo" sea trivial.

## Alcance inicial: 2 ambientes, no 3 (decisión, 2026-08-18)

Aunque `project_environment` (0006) define 3 valores (`production`/`qa`/`dev`) y las cards de Projects ya muestran los 3 badges, **la Fase 5 real arranca trabajando solo con `dev` y `production`** — pedido explícito del usuario, para no complejizar el prototipo inicial. `qa` queda definido en el enum y visible como badge, pero sin flujo de promoción propio todavía. Ampliarlo a los 3 ambientes activos es trabajo futuro, no de esta fase.

## Pendiente / abierto

- ✅ **Íconos confirmados e implementados** (ver `map.md` → Fase 2) — dos niveles, no uno: el del header es genérico por tipo/dirección (`arrow-down-to-line`/`arrow-up-from-line` Integración, `database-zap` Dataset, `square-function` Function); el de la card blanca (content) es específico por nodo (banco, ERP, transacciones, conciliación, proceso manual...), asociado al proceso real de cada uno.
- ✅ **Tags: siempre visibles en la tarjeta**, en la zona gris exterior — resuelto al implementar Fase 2 (ver `map.md`).
- **Function como nodo del mapa está en M7 del roadmap real** — decisión consciente de adelantarlo en el prototipo; no implica que el producto real vaya a tenerlo pronto.
- **Selector de ambiente en el canvas** — el modelo de datos ya está resuelto (ver sección "Ambientes y el mapa" arriba), pero el canvas de Fase 2 no tiene ningún UI para elegir qué ambiente estás viendo. Necesario antes o durante la Fase 5 de `docs/supabase.md`, para que "el mapa" deje de ser ambiguo en cuanto un proyecto tenga más de una promoción.

## Archivos relacionados

- `docs/map.md` — la pantalla completa donde este modelo de nodos ya está implementado (Fase 0, 1 y 2), fase por fase.
- Artifact **"Planos del Mapa"** — inventario de funcionalidades del mapa y priorización P0–P3, anterior a esta definición de nodos.
