-- ============================================================
--  DreamLife Community Chat — Features v3
--  Unread-Zähler (korrekt) · Antworten/Zitate · Win-Wall (Erfolge + Badges)
--  Einmal komplett in den Supabase SQL-Editor einfügen und "Run".
--  Voraussetzung: supabase-setup.sql + features-v2.sql liefen bereits.
-- ============================================================

-- 1) Korrekter Ungelesen-Zähler: letzter Lesezeitpunkt pro Nutzer & Chat
create table if not exists public.conversation_reads (
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id         text references public.profiles(id)      on delete cascade,
  last_read_at    timestamptz not null default now(),
  primary key (conversation_id, user_id)
);
alter table public.conversation_reads enable row level security;
drop policy if exists p_reads_all on public.conversation_reads;
create policy p_reads_all on public.conversation_reads for all using (true) with check (true);

-- 2) Antworten/Zitate: Verweis auf die beantwortete Nachricht
alter table public.messages
  add column if not exists reply_to uuid references public.messages(id) on delete set null;

-- 3) Win-Wall: Erfolge-Feed + Meilenstein-Badges
create table if not exists public.wins (
  id         uuid primary key default gen_random_uuid(),
  user_id    text references public.profiles(id) on delete cascade,
  milestone  text not null,
  note       text,
  created_at timestamptz default now()
);
alter table public.wins enable row level security;
drop policy if exists p_wins_all on public.wins;
create policy p_wins_all on public.wins for all using (true) with check (true);
create index if not exists idx_wins_created on public.wins(created_at desc);

alter table public.profiles
  add column if not exists badges text[] not null default '{}';

-- 4) Realtime einschalten (für Konfetti + Live-Feed)
do $$
begin
  begin alter publication supabase_realtime add table public.wins;               exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.conversation_reads;  exception when duplicate_object then null; end;
end $$;

-- ============================================================
--  Fertig.
-- ============================================================
