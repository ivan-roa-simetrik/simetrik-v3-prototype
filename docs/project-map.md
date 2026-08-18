# Project View Map (concepto: modelo de nodos)

> Última actualización: 2026-08-14
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

## Pendiente / abierto

- ✅ **Íconos confirmados e implementados** (ver `map.md` → Fase 2) — dos niveles, no uno: el del header es genérico por tipo/dirección (`arrow-down-to-line`/`arrow-up-from-line` Integración, `database-zap` Dataset, `square-function` Function); el de la card blanca (content) es específico por nodo (banco, ERP, transacciones, conciliación, proceso manual...), asociado al proceso real de cada uno.
- ✅ **Tags: siempre visibles en la tarjeta**, en la zona gris exterior — resuelto al implementar Fase 2 (ver `map.md`).
- **Function como nodo del mapa está en M7 del roadmap real** — decisión consciente de adelantarlo en el prototipo; no implica que el producto real vaya a tenerlo pronto.

## Archivos relacionados

- `docs/map.md` — la pantalla completa donde este modelo de nodos ya está implementado (Fase 0, 1 y 2), fase por fase.
- Artifact **"Planos del Mapa"** — inventario de funcionalidades del mapa y priorización P0–P3, anterior a esta definición de nodos.
