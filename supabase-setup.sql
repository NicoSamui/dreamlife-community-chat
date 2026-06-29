-- ============================================================
--  DreamLife Community Chat  —  Supabase Setup
--  ------------------------------------------------------------
--  So benutzt du diese Datei:
--  1. Supabase-Projekt öffnen  ->  linke Leiste "SQL Editor"
--  2. "New query"  ->  kompletten Inhalt dieser Datei einfügen
--  3. unten rechts auf "Run" klicken
--  Fertig. Du kannst das Skript gefahrlos mehrfach laufen lassen.
-- ============================================================


-- 1) PROFILE  ----------------------------------------------------------
--    Eine Zeile pro Mitglied, das den Chat geöffnet hat.
--    id = die Learning-Suite User-ID (kommt aus dem Embed-Platzhalter).
create table if not exists public.profiles (
  id           text primary key,
  display_name text not null,
  avatar_url   text,
  is_visible   boolean not null default true,   -- nur sichtbare erscheinen im Verzeichnis
  last_seen    timestamptz default now(),
  created_at   timestamptz default now()
);


-- 2) UNTERHALTUNGEN  (Privat-Chat ODER Gruppe)  ------------------------
create table if not exists public.conversations (
  id              uuid primary key default gen_random_uuid(),
  type            text not null check (type in ('dm','group')),
  title           text,                          -- Gruppenname (bei DM leer)
  dm_key          text unique,                   -- nur DM: "idA:idB" sortiert -> verhindert Doppel-Chats
  created_by      text,
  created_at      timestamptz default now(),
  last_message_at timestamptz default now()
);


-- 3) MITGLIEDER EINER UNTERHALTUNG  ------------------------------------
create table if not exists public.conversation_members (
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id         text references public.profiles(id)      on delete cascade,
  joined_at       timestamptz default now(),
  primary key (conversation_id, user_id)
);


-- 4) NACHRICHTEN  ------------------------------------------------------
create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  sender_id       text references public.profiles(id),
  body            text not null,
  created_at      timestamptz default now()
);


-- Indizes (machen das Laden schnell)  ---------------------------------
create index if not exists idx_messages_conv on public.messages(conversation_id, created_at);
create index if not exists idx_members_user  on public.conversation_members(user_id);
create index if not exists idx_conv_last      on public.conversations(last_message_at desc);


-- 5) REALTIME einschalten  --------------------------------------------
--    Damit neue Nachrichten/Chats sofort (ohne Neuladen) ankommen.
do $$
begin
  begin alter publication supabase_realtime add table public.messages;             exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.conversations;        exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.conversation_members; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.profiles;             exception when duplicate_object then null; end;
end $$;


-- 6) ZUGRIFFS-REGELN (Row Level Security)  ----------------------------
--    RLS ist AN. Die Policies erlauben Zugriff über den öffentlichen
--    anon-Key. Die eigentliche Schutzschicht ist der Mitglieder-Bereich
--    in Learning Suite, in dem der Chat eingebettet ist.
--    >> Höhere Sicherheit später: siehe "Sicherheit" in der Anleitung. <<
alter table public.profiles              enable row level security;
alter table public.conversations         enable row level security;
alter table public.conversation_members  enable row level security;
alter table public.messages              enable row level security;

drop policy if exists p_profiles_all on public.profiles;
create policy p_profiles_all on public.profiles
  for all using (true) with check (true);

drop policy if exists p_conversations_all on public.conversations;
create policy p_conversations_all on public.conversations
  for all using (true) with check (true);

drop policy if exists p_members_all on public.conversation_members;
create policy p_members_all on public.conversation_members
  for all using (true) with check (true);

drop policy if exists p_messages_all on public.messages;
create policy p_messages_all on public.messages
  for all using (true) with check (true);


-- 7) PROFILBILDER-SPEICHER  -------------------------------------------
--    Öffentlicher Bucket "avatars" für hochgeladene Profilbilder.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists p_avatars_read on storage.objects;
create policy p_avatars_read on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists p_avatars_insert on storage.objects;
create policy p_avatars_insert on storage.objects
  for insert with check (bucket_id = 'avatars');

drop policy if exists p_avatars_update on storage.objects;
create policy p_avatars_update on storage.objects
  for update using (bucket_id = 'avatars');

-- ============================================================
--  Fertig. Weiter geht's mit der index.html (Frontend).
-- ============================================================
