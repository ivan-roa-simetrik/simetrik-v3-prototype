-- Modelo de ambientes del Project Map (2026-08-18, definido junto al
-- usuario antes de construir la Fase 5). Decisión: UN solo grafo de nodos
-- por proyecto (map_nodes/map_edges/map_versions de 0004, sin cambios) —
-- los ambientes NO son mapas paralelos independientes, son puntos de
-- promoción sobre esa misma línea de tiempo. Mismo espíritu que D17 del
-- producto real (ambientes ↔ branches de git, deploy = taguear una
-- versión) — acá, "promover" una versión del mapa a un ambiente en vez de
-- taguear un commit.
--
-- Por qué append-only en vez de un puntero "current_version_id" por
-- (proyecto, ambiente): mismo criterio ya elegido para map_versions —
-- conservar el historial completo de promociones (quién, cuándo, qué
-- versión) en vez de solo el estado actual, evitando además una segunda
-- fuente de verdad que puede desincronizarse (lección ya aprendida en este
-- repo con SEARCH_DATA/sidebar Pinned vs. los arrays reales). "El ambiente
-- actual" = la promoción más reciente para ese (project_id, environment).
--
-- Regla de aplicación (no impuesta en SQL, es de la app que construya la
-- Fase 5): cada map_version nueva creada por el chat se promueve
-- automáticamente a 'dev' (construir = commitear); promover a 'qa'/'prod'
-- es una acción explícita del usuario, nunca automática.

create table if not exists public.project_environment_promotions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  -- Reusa el enum project_environment ya creado en 0006_project_environments.sql
  environment public.project_environment not null,
  version_id uuid not null references public.map_versions(id) on delete cascade,
  promoted_by_user_id uuid references auth.users(id) on delete set null,
  promoted_at timestamptz not null default now()
);

create index if not exists project_environment_promotions_lookup
  on public.project_environment_promotions (project_id, environment, promoted_at desc);

alter table public.project_environment_promotions enable row level security;

-- Mismo scoping que map_versions: cualquier miembro de la organización
-- dueña del proyecto puede ver/promover — sin roles finos todavía (Fase 6).
drop policy if exists "Members can view environment promotions of their organization's projects" on public.project_environment_promotions;
create policy "Members can view environment promotions of their organization's projects"
  on public.project_environment_promotions for select
  using (
    project_id in (
      select p.id from public.projects p
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  );

drop policy if exists "Members can create environment promotions in their organization's projects" on public.project_environment_promotions;
create policy "Members can create environment promotions in their organization's projects"
  on public.project_environment_promotions for insert
  with check (
    project_id in (
      select p.id from public.projects p
      join public.organization_members om on om.organization_id = p.organization_id
      where om.user_id = auth.uid()
    )
  );

-- Habilita Realtime — igual que el resto de las tablas de escritura real
-- (ver 0007_enable_realtime.sql), para que una promoción hecha desde otra
-- sesión se refleje en vivo cuando se construya la Fase 5.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'project_environment_promotions'
  ) then
    alter publication supabase_realtime add table public.project_environment_promotions;
  end if;
end $$;
