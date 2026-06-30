-- ============================================================
--  DreamLife Community Chat — Features v6
--  User-Eigenschaften aus Learning Suite ins Profil
--  (für Anzeige im Chat + Personalisierung jeder KI).
--  Einmal komplett in den Supabase SQL-Editor einfügen und "Run".
-- ============================================================

alter table public.profiles add column if not exists dienstleistung text;  -- was der/die macht
alter table public.profiles add column if not exists methode        text;  -- Methode / System
alter table public.profiles add column if not exists zielgruppe     text;  -- Zielgruppe / Branche
alter table public.profiles add column if not exists angebotssatz   text;  -- Angebotssatz

-- ============================================================
--  Fertig. (profiles ist bereits im Realtime + RLS aus dem Setup.)
-- ============================================================
