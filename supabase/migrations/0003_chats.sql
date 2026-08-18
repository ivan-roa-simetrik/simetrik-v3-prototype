-- Chats y sus mensajes. Un chat pertenece a lo sumo a UN contexto (project,
-- app o agent) o a ninguno (chat suelto) — nunca a varios a la vez, decisión
-- confirmada 2026-08-14 (ver memoria "supabase-migration-diagnosis"), mismo
-- shape { type, id } que CHATS_DATA ya usa hoy en flows/home/index.html.
--
-- organization_id vive en la propia tabla (no solo derivado del contexto)
-- porque un chat suelto (sin project/app/agent) igual necesita quedar
-- scoped a una organización para que las políticas de RLS apliquen.
--
-- chat_messages no existe hoy en ninguna parte (los mensajes del chat viven
-- solo en el DOM, ver docs de la migración) — tabla nueva, no migración de
-- datos existentes.

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  project_id uuid references public.projects(id) on delete cascade,
  app_id uuid references public.apps(id) on delete cascade,
  agent_id uuid references public.agents(id) on delete cascade,
  owner_user_id uuid references auth.users(id) on delete set null,
  pinned boolean not null default false,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  constraint chats_single_context check (
    (case when project_id is not null then 1 else 0 end)
    + (case when app_id is not null then 1 else 0 end)
    + (case when agent_id is not null then 1 else 0 end) <= 1
  )
);

do $$
begin
  if not exists (select 1 from pg_type where typname = 'chat_message_role') then
    create type public.chat_message_role as enum ('user', 'assistant');
  end if;
end $$;

-- Append-only por convención de la app (sin políticas de update/delete) —
-- mismo principio que chatMessages en el backend real de Simetrik v3
-- (docs/reference, D40): los mensajes no se editan ni se borran.
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  role public.chat_message_role not null,
  content text not null,
  created_at timestamptz not null default now()
);

alter table public.chats enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "Members can view their organization's chats" on public.chats;
create policy "Members can view their organization's chats"
  on public.chats for select
  using (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can create chats in their organization" on public.chats;
create policy "Members can create chats in their organization"
  on public.chats for insert
  with check (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can update their organization's chats" on public.chats;
create policy "Members can update their organization's chats"
  on public.chats for update
  using (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()))
  with check (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can delete their organization's chats" on public.chats;
create policy "Members can delete their organization's chats"
  on public.chats for delete
  using (organization_id in (select organization_id from public.organization_members where user_id = auth.uid()));

drop policy if exists "Members can view messages in their organization's chats" on public.chat_messages;
create policy "Members can view messages in their organization's chats"
  on public.chat_messages for select
  using (
    chat_id in (
      select c.id from public.chats c
      join public.organization_members om on om.organization_id = c.organization_id
      where om.user_id = auth.uid()
    )
  );

drop policy if exists "Members can add messages to their organization's chats" on public.chat_messages;
create policy "Members can add messages to their organization's chats"
  on public.chat_messages for insert
  with check (
    chat_id in (
      select c.id from public.chats c
      join public.organization_members om on om.organization_id = c.organization_id
      where om.user_id = auth.uid()
    )
  );

-- Seed: los 8 chats que hoy viven hardcodeados en CHATS_DATA
-- (flows/home/index.html), enlazados a los proyectos/apps/agentes ya
-- sembrados en 0002. Sin created_at real de "hace 2 días" etc. — ese texto
-- relativo era decorativo en el mock; created_at real queda en el momento
-- del insert.
insert into public.chats (organization_id, name, project_id)
select o.id, c.name, p.id
from public.organizations o
join public.projects p on p.organization_id = o.id
cross join (values
  ('July period close', 'LATAM Bank Reconciliation'),
  ('Nequi source differences', 'LATAM Bank Reconciliation'),
  ('Manual entries review', 'Q2 Journal Entry Audit'),
  ('Base vs. optimistic scenario', 'Q3 Treasury Forecast')
) as c(name, project_name)
where o.slug = 'simetrik' and p.name = c.project_name
on conflict do nothing;

insert into public.chats (organization_id, name, app_id)
select o.id, 'Reconciliation Summary check-in', a.id
from public.organizations o
join public.apps a on a.organization_id = o.id and a.name = 'Bank Reconciliation Summary'
where o.slug = 'simetrik'
on conflict do nothing;

insert into public.chats (organization_id, name, agent_id)
select o.id, 'Period close agent review', ag.id
from public.organizations o
join public.agents ag on ag.organization_id = o.id and ag.name = 'Period Close Assistant'
where o.slug = 'simetrik'
on conflict do nothing;

insert into public.chats (organization_id, name)
select o.id, c.name
from public.organizations o
cross join (values ('How do I build a reconciliation rule?'), ('This week''s anomaly summary')) as c(name)
where o.slug = 'simetrik'
on conflict do nothing;
