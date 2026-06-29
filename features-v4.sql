-- ============================================================
--  DreamLife Community Chat — Features v4
--  Eigener Umsatz-Post: Betrag + Art (Setup / Retainer)
--  Einmal komplett in den Supabase SQL-Editor einfügen und "Run".
--  Voraussetzung: features-v3.sql lief bereits (Tabelle wins).
-- ============================================================

alter table public.wins add column if not exists amount       numeric;
alter table public.wins add column if not exists revenue_type text;   -- 'setup' | 'retainer'

-- ============================================================
--  Fertig. (wins ist bereits im Realtime + RLS aus v3.)
-- ============================================================
