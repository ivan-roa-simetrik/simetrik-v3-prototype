-- Environment visibility per project (2026-08-18, explicit request): a
-- project can now show which of a fixed set of environments it has —
-- production / qa / dev — as badges under its name (see
-- renderEnvironmentBadges in flows/home/index.html). Modeled the same way
-- `tags text[]` already is in 0002 (a fixed-vocabulary array), except this
-- one IS a closed vocabulary so it gets its own enum instead of free text.
--
-- This also absorbs the old `status` badge (Production/Draft) that used to
-- sit in the card footer: "production" is now just one possible value of
-- `environments` instead of a separate boolean-ish field, so the footer
-- stops rendering `status` at all. `status` itself is left in place
-- untouched (still a real column, still set on insert) since nothing else
-- reads it yet and dropping a column is harder to walk back than leaving
-- it unused — same call as leaving the old create-project modal code
-- dormant rather than deleting it.
--
-- Corrected same day: the 3rd value is "qa", not "coa" — a mis-
-- transcription in the original request. Also: rather than each project
-- carrying an arbitrary subset, the initial rule is simpler — every
-- project starts with all 3 (`production`, `qa`, `dev`), which is why the
-- column's own default is the full set instead of `'{}'`.
--
-- IMPORTANT — run as TWO separate executions in the SQL Editor, not one
-- paste-and-run: an earlier attempt at this migration already created the
-- `project_environment` enum in the live DB with the wrong 3rd value
-- (`coa`). STEP 1 adds `qa` to that existing enum. Postgres will not let a
-- brand-new enum value be *used* (e.g. in the STEP 2 update below) inside
-- the same transaction/script that added it — hence the split. Running
-- STEP 1 again on an already-fixed DB is harmless (`add value if not
-- exists`).

-- ── STEP 1 — run this alone, then wait for it to finish ──────────────────
do $$
begin
  if not exists (select 1 from pg_type where typname = 'project_environment') then
    create type public.project_environment as enum ('production', 'qa', 'dev');
  end if;
end $$;

alter type public.project_environment add value if not exists 'qa';

-- ── STEP 2 — run this after STEP 1 above has completed ────────────────────
alter table public.projects
  add column if not exists environments public.project_environment[]
    not null default array['production', 'qa', 'dev']::public.project_environment[];

alter table public.projects
  alter column environments set default array['production', 'qa', 'dev']::public.project_environment[];

-- Backfill every existing project (seed or real) — "todos tengan los
-- badges de Production, QA y Dev", not just the 3 seed rows from 0002.
update public.projects set environments = array['production', 'qa', 'dev']::public.project_environment[];
