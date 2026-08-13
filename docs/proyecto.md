# Proyecto (concepto de dominio)

> Última actualización: 2026-08-13
> Este archivo es distinto a los demás de `docs/`: no documenta una pantalla, documenta el **modelo conceptual** detrás de la entidad "Proyecto" — organización, administración de cuenta, invitaciones, roles y permisos. Sirve de referencia antes de decidir cuánto de esto el prototipo simula visualmente vs. cuánto queda como contexto para una implementación real futura.

## Propósito

Hasta el 2026-08-13 el prototipo trataba "Proyecto" como un dato plano: 3 proyectos mock con nombre, tags y estado (Production/Draft), sin ningún concepto de organización, usuarios, invitaciones ni permisos detrás. Este documento define **el modelo funcional real** que un Proyecto debería tener, según lo explicado por el usuario, para que:

1. El resto de la documentación (`home.md`, `sidebar.md`) y el prototipo mismo tengan un marco de referencia consistente cuando se agregue más fidelidad (vistas de equipo, invitaciones, roles).
2. Quede registrado *por qué* ciertas decisiones de UI (ej. quién puede ver "New project", quién puede ver qué proyectos) eventualmente deberían reflejar reglas de negocio reales, no solo mock data arbitrario.

## Modelo conceptual

### Jerarquía

```
Organización (cuenta)
├── Administrador de cuenta (rol a nivel de organización)
│    └── Puede crear Proyectos nuevos
│
├── Proyecto A
│    └── Usuarios invitados a A, cada uno con:
│         ├── Rol (dentro de A)
│         └── Acciones/permisos específicos (dentro de A)
│
├── Proyecto B
│    └── Usuarios invitados a B (pueden ser otros usuarios, otros roles —
│         independiente de lo que tengan en A)
│
└── Usuario miembro de la organización, sin invitación a ningún proyecto
     └── No ve ni accede a ningún Proyecto. No puede crear Proyectos
         (esa capacidad es exclusiva del Administrador de cuenta).
```

### Reglas clave

- **Crear un Proyecto es una capacidad exclusiva del Administrador de cuenta.** Un usuario que solo tiene acceso a la organización (pero no es admin) no puede crear proyectos, sin importar cuántos proyectos existan o a cuáles tenga acceso.
- **El acceso a un Proyecto es por invitación directa, proyecto por proyecto.** Pertenecer a la organización no implica ver ningún Proyecto — hace falta que alguien (el admin, u otro rol con esa capacidad — ver Pendiente) invite explícitamente al usuario a ese Proyecto puntual.
- **Los permisos son scoped al Proyecto, no globales.** Un usuario invitado a un Proyecto recibe un rol + acciones específicas *dentro de ese Proyecto*. Ese mismo usuario puede no tener ningún acceso a otros Proyectos de la misma organización, o tener un rol distinto en cada uno.
- **La organización gobierna el marco de roles/permisos.** El *catálogo* de roles y qué acciones habilita cada uno se controla a nivel de organización — un Proyecto no inventa su propio sistema de permisos desde cero, aplica el que la organización define.
- **Un usuario puede estar "dentro" de la organización y "fuera" de todo Proyecto a la vez.** Este es un estado válido y esperado, no un caso de error: cuenta creada, cero proyectos visibles, cero capacidad de crear uno.

## Decisiones funcionales: cómo funciona hoy en el prototipo

Desde que se escribió este documento, varias piezas de UI se construyeron sobre (o alrededor de) este modelo conceptual. Esta sección conecta cada una con las reglas de arriba — qué tan fiel es a la regla real, y qué es simulación/atajo de prototipo. Es la lectura obligatoria antes de tocar cualquiera de estas piezas, para no romper la coherencia con el modelo sin darse cuenta.

- **Tabs de ownership (All / Created by you / Shared projects), vista Projects.** Primer punto donde el modelo conceptual tocó una UI real:
  - *"Created by you"* ≈ proyectos donde el usuario actual es (o actúa como) quien lo creó — en el modelo real esto correspondería al Administrador de cuenta que originó ese Proyecto.
  - *"Shared projects"* ≈ proyectos a los que el usuario fue invitado por otra persona, no los creó él.
  - *"All"* ≈ todos los proyectos a los que el usuario tiene acceso — nunca "todos los proyectos de la organización", eso rompería la regla de acceso scoped por invitación.
  - **Qué tan real es esto:** nada. El campo `owner: 'you' | 'shared'` en `PROJECTS_DATA` es una etiqueta fija por proyecto (2 `'you'`, 1 `'shared'`, elegido arbitrariamente para que ambos filtros devuelvan algo en la demo) — no hay una lista de invitaciones detrás que se evalúe para decidir el valor. Es una *simulación de la distinción*, no la distinción real.

- **Pin / Unpin (elipsis de cada card/fila).** Es la única pieza con estado cruzado real entre vistas: togglear sincroniza con el `<li>` correspondiente en el sidebar (Pinned). Relación con el modelo: **Pinned no es lo mismo que "tener acceso".** Es una curación personal sobre proyectos a los que el usuario *ya* tiene acceso — Unpin en este prototipo nunca revoca acceso, solo saca al proyecto de la lista curada. Lo más parecido a "perder la relación con un proyecto" es Archive (ver abajo), no Unpin.

- **Invite members (elipsis de cada card/fila).** La pieza más directamente ligada a la regla "el acceso a un Proyecto es por invitación directa, proyecto por proyecto" — es, a la fecha, la única superficie de UI que *menciona* esa regla explícitamente (el texto de ayuda del formulario: "They'll only get access to this project, not the rest of the organization"). Implementación deliberadamente honesta y acotada: solo email, sin selector de rol (el catálogo de roles sigue sin existir — ver Pendiente), sin lista de miembros ya invitados, sin estado "invitación pendiente de aceptar". "Send invite" no manda nada real.

- **Archive (elipsis de cada card/fila).** Remueve el proyecto de la vista y, con el mismo mecanismo que Unpin, lo saca del sidebar. **Nota:** el concepto de "archivar un Proyecto" no estaba en la definición original del usuario para este documento — es una extrapolación razonable (llevarlo a un estado inactivo) hecha al construir la UI, no una regla de negocio confirmada. Marcarla como decisión de producto abierta, no como parte del modelo validado.

- **Loading skeleton de la vista Projects.** Sin relación con el modelo de organización/roles — es puramente percepción de carga (shimmer mientras se simula un fetch). Se menciona acá solo para trazar la línea clara entre "mecánica de carga mock" (esto) y "modelo de acceso" (todo lo anterior en esta sección), para que no se mezclen al leer el código.

- **Qué sigue sin estar conectado:** "New project" (sidebar y vista Projects) sigue siendo un botón no-op — crear un proyecto real debería, según el modelo, volver automáticamente Administrador de ese Proyecto al usuario que lo creó, y no dispara nada de eso hoy.

## Estado actual de implementación (en el prototipo)

- ⛔ No existe el concepto de organización, administrador de cuenta, ni roles/permisos en ningún archivo del prototipo.
- ⛔ Los 3 proyectos de `PROJECTS_DATA` (`flows/home/index.html`) son mock data plano — nombre, tags, status, `pinned`, `archived`.
- ⛔ El campo `owner: 'you' | 'shared'` agregado el 2026-08-13 a `PROJECTS_DATA` (para las tabs "All / Created by you / Shared projects" de la vista Projects) **es solo una etiqueta visual** para separar proyectos en la demo — no implementa invitaciones, roles ni el modelo de permisos descrito acá. No confundir uno con el otro.
- ✅ **Primer stub de UI, 2026-08-13 (misma sesión que este documento):** el elipsis de cada card/fila de proyecto ahora tiene una opción **"Invite members"** que abre un formulario mínimo (email + botón "Send invite") con un texto de ayuda que refuerza la regla "acceso scoped a este Proyecto, no a la organización". Es solo la superficie visual de la regla de "invitación directa, proyecto por proyecto" — **no** hay lista real de miembros invitados, no hay selector de rol (el catálogo de roles sigue sin definirse, ver Pendiente), no hay validación de email, y "Send invite" no manda nada real (no-op con confirmación falsa, se cierra solo). Ver `home.md` → sección "Invite members en el popover de acciones".
- ⛔ No hay una vista de "miembros del proyecto ya invitados" ni de "roles y permisos" todavía, ni en el prototipo ni planeada en `home.md`/`sidebar.md` más allá del stub de arriba.
- ⛔ No hay una vista de detalle de un Proyecto individual (click en una card no lleva a ningún lado, ver `home.md` → sección Projects).

## Pendiente / abierto

- **Terminología vs. glosario oficial**: el usuario habló de "organización" — el glosario obligatorio de Simetrik (`ux-writer` → `glosario.md`) usa **"Espacio de trabajo"** (Workspace) como término oficial para el contenedor de alto nivel. Falta confirmar si "Organización" y "Espacio de trabajo" son el mismo concepto acá, o si hay una jerarquía adicional (ej. una Organización con varios Espacios de trabajo, cada uno con sus Proyectos). No se debe introducir copy de UI para esto sin resolver primero esta equivalencia.
- **¿El Administrador de cuenta es único por organización, o puede haber varios?** No se especificó.
- **¿Puede alguien invitado a un Proyecto con un rol de "administrador de proyecto" (no de cuenta) invitar a su vez a otros usuarios a ese mismo Proyecto?** El mensaje original solo dice que el Administrador de cuenta puede crear proyectos e implícitamente gestionarlos — no queda claro si la capacidad de invitar usuarios a un Proyecto es exclusiva de ese admin o delegable.
- **Catálogo concreto de roles y acciones**: no se definieron los roles (ej. Viewer/Editor/Admin del proyecto) ni las acciones específicas que cada uno habilita (ver, conciliar, exportar, invitar, eliminar...).
- **¿Dónde vive la gestión de esto en la UI?** ¿Una vista de "Team"/"Members" por proyecto? ¿Un tab dentro del detalle de un Proyecto (que hoy no existe)? ¿Algo a nivel de organización separado del nav de Projects? Sin definir todavía.
- **Relación con "Pinned" del sidebar**: Pinned muestra proyectos curados por el usuario actual (ver `sidebar.md`) — presumiblemente solo debería listar proyectos a los que el usuario *tiene acceso* (organización + invitación), pero esa validación no existe hoy porque no hay modelo de acceso real.
- **"Archive" no es parte de la definición original**: se agregó como acción de UI (ver "Decisiones funcionales" arriba) sin haber sido especificada por el usuario como parte del modelo — falta confirmar si "archivar un Proyecto" es un estado real del negocio (¿quién puede archivar? ¿un proyecto archivado sigue siendo visible para los usuarios ya invitados, o desaparece para todos?) o si debería reemplazarse por algo distinto una vez se defina.
- **¿Las tabs "Created by you" / "Shared projects" deberían derivarse de invitaciones reales en cuanto exista ese modelo?** Hoy son una etiqueta fija por proyecto (`owner`), no el resultado de evaluar quién invitó a quién — es la brecha más directa entre este documento y el mock actual.

## Archivos relacionados

- `docs/home.md` — sección "Projects", incluye la nota de que `owner` es solo mock visual, no permisos reales
- `docs/sidebar.md` — estructura de Pinned, que eventualmente debería filtrarse por acceso real del usuario
- `flows/home/index.html` — `PROJECTS_DATA`, vista Projects (grid/list, tabs de ownership)
