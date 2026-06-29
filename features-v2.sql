-- ============================================================
--  DreamLife Community Chat — Features v2
--  Öffentliche/Private Gruppen · Reaktionen · Lösch-Realtime
--  Einmal komplett in den Supabase SQL-Editor einfügen und "Run".
--  Voraussetzung: supabase-setup.sql lief bereits.
-- ============================================================

-- 1) Gruppen öffentlich/privat
alter table public.conversations
  add column if not exists is_public boolean not null default false;

-- 2) Nachrichten-Reaktionen (Emoji pro Nutzer pro Nachricht)
create table if not exists public.message_reactions (
  message_id uuid references public.messages(id) on delete cascade,
  user_id    text references public.profiles(id) on delete cascade,
  emoji      text not null,
  created_at timestamptz default now(),
  primary key (message_id, user_id, emoji)
);
alter table public.message_reactions enable row level security;
drop policy if exists p_reactions_all on public.message_reactions;
create policy p_reactions_all on public.message_reactions
  for all using (true) with check (true);

create index if not exists idx_reactions_msg on public.message_reactions(message_id);
create index if not exists idx_conv_public   on public.conversations(is_public) where is_public;

-- 3) Realtime für Reaktionen einschalten
do $$
begin
  begin alter publication supabase_realtime add table public.message_reactions; exception when duplicate_object then null; end;
end $$;

-- 4) Vollständige Alt-Zeile bei DELETE/UPDATE (damit Realtime weiß,
--    welche Nachricht/Reaktion in welchem Chat entfernt wurde)
alter table public.messages          replica identity full;
alter table public.message_reactions replica identity full;

-- ============================================================
--  Fertig.
-- ============================================================
