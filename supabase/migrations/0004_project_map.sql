-- Project Map: nodos, edges y versionado con snapshot completo.
-- Ver memoria "supabase-migration-diagnosis" (sección "Modelo de relaciones",
-- 2026-08-14) para el razonamiento completo. Resumen de las decisiones que
-- este esquema encarna:
--
-- - Sin tabla "map" intermedia: nodos/edges cuelgan directo de project_id,
--   igual que el repo real (Simetrik v3/backend/src/db/schema.ts).
-- - 3 tipos de nodo (integracion/dataset/function), no los 2 que tiene hoy
--   el M2 shippeado del producto real — divergencia deliberada ya confirmada
--   en el plan del Project View Map (Function adoptado antes que el roadmap
--   real, que lo tiene en M7).
-- - Autoría por columna en la propia fila (created_by_user_id,
--   origin_message_id) — mismo patrón que la decisión D40 del repo real.
-- - Versionado = SNAPSHOT COMPLETO por versión (no solo un log liviano de
--   cambios) — decisión explícita del usuario, adelantando a esquema lo que
--   el plan del mapa tenía como backlog P3 ("full Audit mode"). Igual
--   contrato que AUDIT_ROLLBACK_EXAMPLE del mock: un rollback crea una
--   versión NUEVA apuntando hacia atrás via source_version_id, nunca borra
--   ni reescribe historial.

do $$
begin
  if not exists (select 1 from pg_type where typname = 'map_node_type') then
    create type public.map_node_type as enum ('integracion', 'dataset', 'function');
  end if;
  if not exists (select 1 from pg_type where typname = 'map_version_status') then
    create type public.map_version_status as enum ('current', 'superseded');
  end if;
end $$;

create table if not exists public.map_nodes (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  type public.map_node_type not null,
  -- Estructura interna específica por tipo: dirección (entrada/salida) para
  -- integración, tags/conciliación libre para dataset, lifecycle para
  -- function. jsonb en vez de columnas separadas por tipo — mismo criterio
  -- que nodes.config en el repo real, evita una tabla por tipo de nodo para
  -- algo que todavía está cambiando de forma.
  config jsonb not null default '{}'::jsonb,
  created_by_user_id uuid references auth.users(id) on delete set null,
  origin_message_id uuid references public.chat_messages(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.map_edges (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  source_node_id uuid not null references public.map_nodes(id) on delete cascade,
  target_node_id uuid not null references public.map_nodes(id) on delete cascade,
  -- Nombre del output del nodo fuente que alimenta este edge — mismo patrón
  -- que nodeEdges.salida en el repo real; determina unicidad del edge.
  salida text not null default 'default',
  posicion integer not null default 0,
  created_at timestamptz not null default now(),
  unique (source_node_id, salida)
);

create table if not exists public.map_versions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  version_number integer not null,
  label text not null default '',
  status public.map_version_status not null default 'current',
  -- Copia completa de nodos + edges tal como quedaron después de este
  -- cambio — permite "ver el mapa como estaba en la versión N" con un solo
  -- select, sin tener que reconstruir aplicando un log.
  snapshot jsonb not null,
  -- Diff legible contra la versión anterior: { added: [...], modified: [...], removed: [...] }
  change_set jsonb not null default '{}'::jsonb,
  source_version_id uuid references public.map_versions(id) on delete set null,
  created_by_user_id uuid references auth.users(id) on delete set null,
  origin_message_id uuid references public.chat_messages(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (project_id, version_number)
);

alter table public.map_nodes enable row level security;
alter table public.map_edges enable row level security;
alter table public.map_versions enable row level security;

-- Las 3 tablas se filtran por membresía a la organización dueña del
-- project_id — ninguna tiene organization_id propio (ver nota de arriba:
-- sin tabla "map" intermedia, project_id ya es la fuente de scoping).

drop policy if exists "Members can view map nodes of their organization's projects" on public.map_nodes;
create policy "Members can view map nodes of their organization's projects"
  on public.map_nodes for select
  using (
    project_id in (
      select p.id from public.projects p
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  );

drop policy if exists "Members can manage map nodes of their organization's projects" on public.map_nodes;
create policy "Members can manage map nodes of their organization's projects"
  on public.map_nodes for all
  using (
    project_id in (
      select p.id from public.projects p
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  )
  with check (
    project_id in (
      select p.id from public.projects p
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  );

drop policy if exists "Members can view map edges of their organization's projects" on public.map_edges;
create policy "Members can view map edges of their organization's projects"
  on public.map_edges for select
  using (
    project_id in (
      select p.id from public.projects p
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  );

drop policy if exists "Members can manage map edges of their organization's projects" on public.map_edges;
create policy "Members can manage map edges of their organization's projects"
  on public.map_edges for all
  using (
    project_id in (
      select p.id from public.projects p
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  )
  with check (
    project_id in (
      select p.id from public.projects p
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  );

drop policy if exists "Members can view map versions of their organization's projects" on public.map_versions;
create policy "Members can view map versions of their organization's projects"
  on public.map_versions for select
  using (
    project_id in (
      select p.id from public.projects p
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  );

-- map_versions es append-only desde la app (cada cambio inserta una versión
-- nueva, nunca se actualiza una vieja) — solo policy de insert, sin update.
drop policy if exists "Members can create map versions in their organization's projects" on public.map_versions;
create policy "Members can create map versions in their organization's projects"
  on public.map_versions for insert
  with check (
    project_id in (
      select p.id from public.projects p
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  );

-- Sin seed: el mapa arranca vacío por decisión de producto (ver memoria
-- "project-view-map-plan" — el primer mensaje del chat del proyecto dispara
-- la revelación animada de nodos, no hay datos de demo precargados).
