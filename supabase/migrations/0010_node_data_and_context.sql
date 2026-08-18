-- Estructura interna de nodo (2026-08-18), definida junto al usuario antes
-- de construir la Fase 5 real — corrobora contra la arquitectura real
-- (uploads, ClickHouse, rulesets, tags, ver docs/project-map.md) y confirma
-- 2 conceptos ya anticipados como pestañas del drawer de detalle desde el
-- plan original del mapa ("Data"/"Context"), sin definir hasta ahora:
--
-- 1. "Data" — cada nodo que transporta filas (Integración, Dataset; NO
--    Function, que solo opera sobre datos ajenos) documenta su propia
--    lista de rows, con la forma de columnas que le corresponda en esa
--    etapa del pipeline (varía nodo a nodo tras transformaciones).
--    Divergencia deliberada del producto real: ahí solo el Dataset tiene
--    tabla propia (ClickHouse) — acá cada nodo que mueve datos la tiene.
--    Tabla propia (`map_node_data`) en vez de un array dentro de
--    `map_nodes.config`: es contenido de una pestaña navegable/paginable,
--    no config estructural del nodo.
--
-- 2. "Context" — interpretación en lenguaje natural de qué hace el nodo,
--    sin precedente en el producto real (ahí ni node ni dataset tienen
--    descripción semántica, solo projects.description manual). Construida
--    y mantenida por el AGENTE a medida que impacta el nodo desde el chat
--    — no es un campo que el usuario edite a mano. Columna propia en
--    map_nodes (no dentro de config): es un concepto único por nodo,
--    transversal a los 3 tipos, no específico de uno.
--
-- Tags: sin cambios — confirmado con el usuario que siguen siendo
-- informativos/libres (para filtrar más adelante), nunca disparan
-- ejecución — ya viven dentro de map_nodes.config desde 0004, no necesitan
-- columna ni tabla propia.

alter table public.map_nodes
  add column if not exists agent_context text;

comment on column public.map_nodes.agent_context is
  'Interpretación en lenguaje natural de qué hace el nodo. La construye y actualiza el agente al impactar el nodo desde el chat — no es un campo editable a mano por el usuario.';

create table if not exists public.map_node_data (
  id uuid primary key default gen_random_uuid(),
  node_id uuid not null references public.map_nodes(id) on delete cascade,
  -- Una fila real = un objeto jsonb — la cantidad/forma de columnas varía
  -- libremente entre nodos y entre etapas del pipeline, sin pelear con un
  -- esquema fijo de columnas SQL.
  row_data jsonb not null,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists map_node_data_by_node
  on public.map_node_data (node_id, position);

alter table public.map_node_data enable row level security;

-- Mismo scoping que map_nodes/map_edges: cualquier miembro de la
-- organización dueña del proyecto (vía el nodo) puede ver/gestionar — sin
-- roles finos todavía (Fase 6).
drop policy if exists "Members can view node data of their organization's projects" on public.map_node_data;
create policy "Members can view node data of their organization's projects"
  on public.map_node_data for select
  using (
    node_id in (
      select n.id from public.map_nodes n
      join public.projects p on p.id = n.project_id
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  );

drop policy if exists "Members can manage node data of their organization's projects" on public.map_node_data;
create policy "Members can manage node data of their organization's projects"
  on public.map_node_data for all
  using (
    node_id in (
      select n.id from public.map_nodes n
      join public.projects p on p.id = n.project_id
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  )
  with check (
    node_id in (
      select n.id from public.map_nodes n
      join public.projects p on p.id = n.project_id
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  );

-- Realtime: consistente con el resto de las tablas de escritura real. Nota
-- de escala (no aplica a un prototipo, sí a producción real): una carga
-- masiva de filas dispararía un evento por fila — aceptable acá porque
-- "Data" son muestras representativas, no volúmenes reales de producción.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'map_node_data'
  ) then
    alter publication supabase_realtime add table public.map_node_data;
  end if;
end $$;
