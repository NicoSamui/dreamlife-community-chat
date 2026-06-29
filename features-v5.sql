-- ============================================================
--  DreamLife Community Chat — Features v5
--  Umsatz: Setup UND Retainer gleichzeitig möglich.
--  Einmal komplett in den Supabase SQL-Editor einfügen und "Run".
--  Voraussetzung: features-v4.sql lief bereits (Spalten amount, revenue_type).
-- ============================================================

-- Neue Spalte: Retainer pro Monat (der wiederkehrende Anteil)
alter table public.wins add column if not exists amount_monthly numeric;

-- Konvention vereinheitlichen:
--   amount         = Setup / einmaliger Betrag
--   amount_monthly = Retainer / monatlich
-- Bisherige reine 'retainer'-Posts hatten den mtl. Betrag in `amount` ->
-- in amount_monthly verschieben, damit Anzeige + Summen stimmen.
update public.wins
   set amount_monthly = amount,
       amount = null
 where revenue_type = 'retainer'
   and amount_monthly is null;

-- ============================================================
--  Fertig. (wins ist bereits im Realtime + RLS aus v3.)
-- ============================================================
