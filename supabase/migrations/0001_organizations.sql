-- Organizaciones (tenants) y sus miembros. Multi-org desde el día 1 (decisión
-- confirmada 2026-08-14, ver memoria "supabase-migration-diagnosis"), mismo
-- patrón ya validado en el prototipo hermano mock-v3
-- (supabase/migrations/0001_organizations.sql de ese repo) — proyecto Supabase
-- separado, pero mismo diseño de tabla.

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  created_at timestamptz not null default now()
);

do $$
begin
  if not exists (select 1 from pg_type where typname = 'organization_role') then
    create type public.organization_role as enum ('org_admin', 'builder', 'operator', 'auditor');
  end if;
end $$;

create table if not exists public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.organization_role not null default 'org_admin',
  created_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;

drop policy if exists "Members can view their organizations" on public.organizations;
create policy "Members can view their organizations"
  on public.organizations for select
  using (
    id in (select organization_id from public.organization_members where user_id = auth.uid())
  );

drop policy if exists "Users can view their own memberships" on public.organization_members;
create policy "Users can view their own memberships"
  on public.organization_members for select
  using (user_id = auth.uid());

-- Seed: org "Simetrik". El insert en organization_members solo pega si
-- ivan.roa@simetrik.com YA existe en auth.users (Supabase Auth crea esa fila
-- recién en el primer signup/login real) — si corrés esta migración antes de
-- haber iniciado sesión una vez con ese correo, este insert no hace nada
-- (0 filas, sin error). Volvé a correr este bloque después del primer login
-- para que quede como org_admin.
insert into public.organizations (name, slug) values
  ('Simetrik', 'simetrik')
on conflict (slug) do nothing;

insert into public.organization_members (organization_id, user_id, role)
select o.id, u.id, 'org_admin'
from public.organizations o
cross join auth.users u
where o.slug = 'simetrik' and u.email = 'ivan.roa@simetrik.com'
on conflict (organization_id, user_id) do nothing;
