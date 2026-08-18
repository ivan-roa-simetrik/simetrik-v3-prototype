-- Fase 4 (2026-08-18): habilita Realtime (postgres_changes) sobre las
-- tablas que ya tienen lectura/escritura real (Fases 1-2) — projects, apps,
-- su tabla puente apps_projects (para mantener sincronizado app.projects
-- sin depender de un embed que Realtime no entrega), y chats.
--
-- RLS ya filtra qué filas puede ver cada conexión — Realtime respeta esas
-- mismas políticas, así que un canal de 'chats' solo entrega eventos de los
-- chats del propio usuario (ver 0005_chats_private_per_user.sql). No se
-- habilita chat_messages acá: sincronizar en vivo un chat abierto en 2
-- pestañas del mismo usuario queda fuera de esta fase (ver docs/supabase.md
-- → Pendiente).
--
-- Idempotente: ALTER PUBLICATION ... ADD TABLE falla si la tabla ya está
-- agregada (p. ej. si se activó antes a mano desde el dashboard), así que
-- se chequea contra pg_publication_tables antes de cada ADD.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'projects'
  ) then
    alter publication supabase_realtime add table public.projects;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'apps'
  ) then
    alter publication supabase_realtime add table public.apps;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'apps_projects'
  ) then
    alter publication supabase_realtime add table public.apps_projects;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'chats'
  ) then
    alter publication supabase_realtime add table public.chats;
  end if;
end $$;
