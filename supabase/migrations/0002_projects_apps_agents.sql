-- Projects, Apps (N:N con Projects vía apps_projects) y Agents, scoped por
-- organización. Columnas calcadas de las shapes reales hoy hardcodeadas en
-- flows/home/index.html: PROJECTS_DATA, APPS_DATA, PANEL_AGENTS_DATA.
--
-- Traducción deliberada de un campo: PROJECTS_DATA.owner hoy es el string
-- 'you' | 'shared', que es relativo a quién está mirando la UI, no un hecho
-- almacenable. Se normaliza a owner_user_id (quién lo creó de verdad); "you"
-- vs "shared" se deriva en el cliente comparando owner_user_id con auth.uid().

do $$
begin
  if not exists (select 1 from pg_type where typname = 'project_status') then
    create type public.project_status as enum ('draft', 'production');
  end if;
  if not exists (select 1 from pg_type where typname = 'app_status') then
    create type public.app_status as enum ('draft', 'active');
  end if;
end $$;

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  description text not null default '',
  icon text not null default 'folder',
  status public.project_status not null default 'draft',
  tags text[] not null default '{}',
  pinned boolean not null default false,
  archived boolean not null default false,
  owner_user_id uuid references auth.users(id) on delete set null,
  members_count integer not null default 1,
  -- Ver createProject() / docs/home.md: distingue un "New Project" placeholder
  -- (nombre/descripción aún sin definir) de uno ya nombrado — startChat()
  -- decide si derivar el nombre real del primer mensaje del chat.
  pending_name_from_chat boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.apps (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  description text not null default '',
  icon text not null default 'layout-grid',
  status public.app_status not null default 'draft',
  pinned boolean not null default false,
  archived boolean not null default false,
  pending_name_from_chat boolean not null default false,
  created_at timestamptz not null default now()
);

-- Una App puede tirar de varios Projects a la vez, uno, o ninguno (ver
-- APPS_DATA.projects en flows/home/index.html) — N:N real en vez del array
-- de ids que hoy vive solo en memoria.
create table if not exists public.apps_projects (
  app_id uuid not null references public.apps(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  primary key (app_id, project_id)
);

create table if not exists public.agents (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

alter table public.projects enable row level security;
alter table public.apps enable row level security;
alter table public.apps_projects enable row level security;
alter table public.agents enable row level security;

-- Cualquier miembro de la organización puede ver/crear/editar/borrar dentro
-- de ella — sin roles finos todavía (ver docs/proyecto.md, pendiente de
-- diseño de permisos por rol/proyecto). org_admin vs. builder/operator/auditor
-- ya existe como enum (0001) pero no se usa para restringir nada aún.

drop policy if exists "Members can view their organization's projects" on public.projects;
create policy "Members can view their organization's projects"
  on public.projects for select
  using (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can create projects in their organization" on public.projects;
create policy "Members can create projects in their organization"
  on public.projects for insert
  with check (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can update their organization's projects" on public.projects;
create policy "Members can update their organization's projects"
  on public.projects for update
  using (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()))
  with check (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can delete their organization's projects" on public.projects;
create policy "Members can delete their organization's projects"
  on public.projects for delete
  using (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can view their organization's apps" on public.apps;
create policy "Members can view their organization's apps"
  on public.apps for select
  using (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can create apps in their organization" on public.apps;
create policy "Members can create apps in their organization"
  on public.apps for insert
  with check (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can update their organization's apps" on public.apps;
create policy "Members can update their organization's apps"
  on public.apps for update
  using (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()))
  with check (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can delete their organization's apps" on public.apps;
create policy "Members can delete their organization's apps"
  on public.apps for delete
  using (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can manage their organization's app-project links" on public.apps_projects;
create policy "Members can manage their organization's app-project links"
  on public.apps_projects for all
  using (
    app_id in (
      select a.id from public.apps a
      join public.organization_members om on om.organization_id = a.organization_id
      where om.user_id = auth.uid()
    )
  )
  with check (
    app_id in (
      select a.id from public.apps a
      join public.organization_members om on om.organization_id = a.organization_id
      where om.user_id = auth.uid()
    )
  );

drop policy if exists "Members can view their organization's agents" on public.agents;
create policy "Members can view their organization's agents"
  on public.agents for select
  using (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can create agents in their organization" on public.agents;
create policy "Members can create agents in their organization"
  on public.agents for insert
  with check (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

-- Seed: los 3 proyectos, 3 apps (con sus vínculos a proyectos) y 3 agentes
-- que hoy viven hardcodeados en flows/home/index.html, para no perder la
-- demo existente al migrar. Todo bajo la organización "Simetrik".

insert into public.projects (organization_id, name, description, icon, status, tags, pinned, members_count)
select o.id, p.name, '', 'folder', p.status::public.project_status, p.tags, true, p.members_count
from public.organizations o
cross join (values
  ('LATAM Bank Reconciliation', 'production', array['source:bank-statement', 'region:LATAM'], 10),
  ('Q2 Journal Entry Audit', 'production', array['journal-entry', 'period:Q2'], 6),
  ('Q3 Treasury Forecast', 'draft', array['period:Q3'], 5)
) as p(name, status, tags, members_count)
where o.slug = 'simetrik'
on conflict do nothing;

insert into public.apps (organization_id, name, description, icon, status, pinned)
select o.id, a.name, a.description, a.icon, a.status::public.app_status, a.pinned
from public.organizations o
cross join (values
  ('Bank Reconciliation Summary', 'Pulls LATAM Bank Reconciliation data and drafts a period-close reconciliation report — balances, exceptions, and a plain-language summary.', 'file-check', 'active', true),
  ('Quarterly Anomaly Digest', 'Cross-checks Q2 Journal Entry Audit and Q3 Treasury Forecast data to flag anomalies worth reviewing before period close.', 'radar', 'active', false),
  ('Board Update Draft', 'Drafts a leadership-ready update on financial operations — pick which projects to pull from when you''re ready.', 'megaphone', 'draft', false)
) as a(name, description, icon, status, pinned)
where o.slug = 'simetrik'
on conflict do nothing;

insert into public.apps_projects (app_id, project_id)
select a.id, p.id
from public.apps a
join public.organizations o on o.id = a.organization_id and o.slug = 'simetrik'
join public.projects p on p.organization_id = o.id
where (a.name = 'Bank Reconciliation Summary' and p.name = 'LATAM Bank Reconciliation')
   or (a.name = 'Quarterly Anomaly Digest' and p.name in ('Q2 Journal Entry Audit', 'Q3 Treasury Forecast'))
on conflict do nothing;

insert into public.agents (organization_id, name)
select o.id, a.name
from public.organizations o
cross join (values ('Reconciliation Agent'), ('Anomaly Watcher'), ('Period Close Assistant')) as a(name)
where o.slug = 'simetrik'
on conflict do nothing;
