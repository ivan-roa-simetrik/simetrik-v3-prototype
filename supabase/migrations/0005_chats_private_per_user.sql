-- Corrección de modelo (2026-08-18): un Chat es privado a quien lo inició,
-- NUNCA compartido por todos los miembros con acceso al proyecto/app al que
-- está asociado. Ejemplo del usuario: si vos y Juan tienen acceso al mismo
-- Proyecto 1, cada uno ve solo SUS PROPIOS chats bajo ese proyecto — ninguno
-- ve los del otro, aunque ambos "estén en" el mismo proyecto compartido.
--
-- Esto es distinto de Projects/Apps, que SÍ siguen siendo compartidos por
-- toda la organización (sin cambios ahí) — la corrección es específica a
-- Chats y chat_messages. Las policies de 0003 scopeaban por membresía de
-- organización completa (cualquier miembro veía/editaba todos los chats de
-- la org); se reemplazan acá por scoping a owner_user_id = auth.uid().

drop policy if exists "Members can view their organization's chats" on public.chats;
create policy "Users can view their own chats"
  on public.chats for select
  using (owner_user_id = auth.uid());

-- Insert se mantiene con el check de membresía (hay que pertenecer a la
-- organización para crear un chat en ella) y suma el check de ownership:
-- nadie puede insertar un chat a nombre de otro usuario.
drop policy if exists "Members can create chats in their organization" on public.chats;
create policy "Members can create their own chats in their organization"
  on public.chats for insert
  with check (
    owner_user_id = auth.uid()
    and organization_id in (select organization_id from public.organization_members where user_id = auth.uid())
  );

drop policy if exists "Members can update their organization's chats" on public.chats;
create policy "Users can update their own chats"
  on public.chats for update
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

drop policy if exists "Members can delete their organization's chats" on public.chats;
create policy "Users can delete their own chats"
  on public.chats for delete
  using (owner_user_id = auth.uid());

-- chat_messages hereda el scoping de su chat por ownership, no por
-- membresía de organización — mismo criterio que arriba.
drop policy if exists "Members can view messages in their organization's chats" on public.chat_messages;
create policy "Users can view messages in their own chats"
  on public.chat_messages for select
  using (
    chat_id in (select id from public.chats where owner_user_id = auth.uid())
  );

drop policy if exists "Members can add messages to their organization's chats" on public.chat_messages;
create policy "Users can add messages to their own chats"
  on public.chat_messages for insert
  with check (
    chat_id in (select id from public.chats where owner_user_id = auth.uid())
  );

-- Los 8 chats sembrados en 0003 quedaron con owner_user_id NULL (ningún
-- usuario existía todavía en ese momento) — con las policies nuevas, NULL
-- != auth.uid() para cualquier usuario real, así que hoy no los ve nadie.
-- Se asignan al primer org_admin de "Simetrik" para no dejarlos huérfanos
-- e inaccesibles; si preferís borrarlos en vez de asignarlos, comentá este
-- bloque y corré un `delete from public.chats where owner_user_id is null`.
update public.chats
set owner_user_id = (
  select om.user_id
  from public.organization_members om
  join public.organizations o on o.id = om.organization_id
  where o.slug = 'simetrik' and om.role = 'org_admin'
  limit 1
)
where owner_user_id is null;
