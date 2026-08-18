-- Corrección de modelo (2026-08-18, encontrada por el usuario): "pinear" un
-- Proyecto o App no puede ser una columna en la fila compartida
-- (`projects.pinned`/`apps.pinned`) — Proyectos y Apps SÍ son compartidos
-- por toda la organización (a diferencia de los Chats, ver
-- 0005_chats_private_per_user.sql), así que una sola columna `pinned`
-- reflejaba la curación de UN usuario para TODOS los que tienen acceso.
-- Ejemplo: si vos pineás el Proyecto 1, Juan (que también tiene acceso)
-- lo vería pineado en su propio sidebar sin haberlo pineado él.
--
-- Mismo patrón que el repo real de Simetrik v3 ya usa para esto exacto
-- (`project_user_state`, preferencia vs. entidad — visto durante la
-- investigación de la Fase 0): el pin es una preferencia PERSONAL sobre una
-- entidad compartida, vive en su propia tabla por (usuario, entidad), no
-- como columna de la entidad.
--
-- `projects.pinned`/`apps.pinned` quedan en la tabla, sin usar — mismo
-- criterio ya aplicado en este repo a `projects.status` cuando se agregó
-- `environments` (dropear una columna es más difícil de revertir que
-- dejarla dormida).

create table if not exists public.project_user_state (
  user_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  pinned boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (user_id, project_id)
);

create table if not exists public.app_user_state (
  user_id uuid not null references auth.users(id) on delete cascade,
  app_id uuid not null references public.apps(id) on delete cascade,
  pinned boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (user_id, app_id)
);

alter table public.project_user_state enable row level security;
alter table public.app_user_state enable row level security;

drop policy if exists "Users can view their own project pin state" on public.project_user_state;
create policy "Users can view their own project pin state"
  on public.project_user_state for select
  using (user_id = auth.uid());

drop policy if exists "Users can upsert their own project pin state" on public.project_user_state;
create policy "Users can upsert their own project pin state"
  on public.project_user_state for insert
  with check (user_id = auth.uid());

drop policy if exists "Users can update their own project pin state" on public.project_user_state;
create policy "Users can update their own project pin state"
  on public.project_user_state for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "Users can view their own app pin state" on public.app_user_state;
create policy "Users can view their own app pin state"
  on public.app_user_state for select
  using (user_id = auth.uid());

drop policy if exists "Users can upsert their own app pin state" on public.app_user_state;
create policy "Users can upsert their own app pin state"
  on public.app_user_state for insert
  with check (user_id = auth.uid());

drop policy if exists "Users can update their own app pin state" on public.app_user_state;
create policy "Users can update their own app pin state"
  on public.app_user_state for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Backfill: lo que hoy aparece pineado (columna compartida) se asigna al
-- primer org_admin de cada organización, para no perder visualmente lo que
-- ya estaba pineado en la única cuenta usada hasta ahora. Si en el futuro
-- hay más usuarios, cada uno arranca sin nada pineado — es lo correcto
-- dado que pinear siempre fue, conceptualmente, personal.
insert into public.project_user_state (user_id, project_id, pinned)
select om.user_id, p.id, true
from public.projects p
join public.organization_members om on om.organization_id = p.organization_id and om.role = 'org_admin'
where p.pinned = true
on conflict (user_id, project_id) do nothing;

insert into public.app_user_state (user_id, app_id, pinned)
select om.user_id, a.id, true
from public.apps a
join public.organization_members om on om.organization_id = a.organization_id and om.role = 'org_admin'
where a.pinned = true
on conflict (user_id, app_id) do nothing;

-- Realtime (Fase 4): sin esto, el pin state de un usuario no se sincroniza
-- en vivo entre sus propias pestañas — RLS ya scopea cada fila a
-- user_id = auth.uid(), así que un canal acá nunca entrega el pin de otro
-- usuario, solo sirve para que las pestañas propias no queden desfasadas.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'project_user_state'
  ) then
    alter publication supabase_realtime add table public.project_user_state;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'app_user_state'
  ) then
    alter publication supabase_realtime add table public.app_user_state;
  end if;
end $$;
