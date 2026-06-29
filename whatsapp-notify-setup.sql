-- ============================================================
--  DreamLife Community Chat — WhatsApp-Benachrichtigungen (CallMeBot)
--  Einmal komplett in den Supabase SQL-Editor einfügen und "Run".
--  Voraussetzung: supabase-setup.sql wurde bereits ausgeführt.
-- ============================================================

-- 1) pg_net aktivieren (erlaubt der Datenbank ausgehende HTTP-Aufrufe)
create extension if not exists pg_net;

-- 2) Private Benachrichtigungs-Einstellungen pro Nutzer
--    WICHTIG: RLS an, aber KEINE Policy für anon -> Clients können
--    Telefonnummern/Keys weder lesen noch direkt schreiben. Zugriff
--    nur über die security-definer-Funktionen unten.
create table if not exists public.notify_settings (
  user_id          text primary key references public.profiles(id) on delete cascade,
  wa_phone         text,
  wa_apikey        text,
  wa_enabled       boolean not null default true,
  wa_last_notified timestamptz
);
alter table public.notify_settings enable row level security;

-- 3) URL-Encoder für den Nachrichtentext (Umlaute, Leerzeichen etc.)
create or replace function public.url_encode(input text) returns text
language sql immutable as $$
  select coalesce(string_agg(
    case
      when ch ~ '[A-Za-z0-9_.~-]' then ch
      else regexp_replace(upper(encode(convert_to(ch,'UTF8'),'hex')), '(..)', '%\1', 'g')
    end, ''), '')
  from regexp_split_to_table(coalesce(input,''), '') as ch
$$;

-- 4) Eigene Settings sicher speichern (leere/null Werte überschreiben nichts)
create or replace function public.save_notify_settings(
  p_user_id text, p_phone text, p_apikey text, p_enabled boolean
) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into public.notify_settings(user_id, wa_phone, wa_apikey, wa_enabled)
  values (p_user_id, p_phone, p_apikey, coalesce(p_enabled, true))
  on conflict (user_id) do update set
    wa_phone   = coalesce(excluded.wa_phone,   public.notify_settings.wa_phone),
    wa_apikey  = coalesce(excluded.wa_apikey,  public.notify_settings.wa_apikey),
    wa_enabled = coalesce(excluded.wa_enabled, public.notify_settings.wa_enabled);
end $$;
grant execute on function public.save_notify_settings(text,text,text,boolean) to anon, authenticated;

-- 5) Trigger: bei neuer Nachricht offline-Empfänger via CallMeBot benachrichtigen
--    Regeln: nur Empfänger (nicht Absender), nur mit aktivem Setup,
--    nur wenn offline (>2 Min keine Aktivität) und max. 1 Reminder / 5 Min.
create or replace function public.notify_new_message() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  sender_name text;
  rec record;
  body_txt text;
  url text;
begin
  select display_name into sender_name from public.profiles where id = NEW.sender_id;

  for rec in
    select ns.user_id, ns.wa_phone, ns.wa_apikey
    from public.conversation_members cm
    join public.notify_settings ns on ns.user_id = cm.user_id
    join public.profiles p          on p.id      = cm.user_id
    where cm.conversation_id = NEW.conversation_id
      and cm.user_id <> NEW.sender_id
      and ns.wa_enabled is true
      and ns.wa_phone  is not null
      and ns.wa_apikey is not null
      and (p.last_seen        is null or p.last_seen        < now() - interval '2 minutes')
      and (ns.wa_last_notified is null or ns.wa_last_notified < now() - interval '5 minutes')
  loop
    body_txt := 'Eine neue Nachricht von ' || coalesce(sender_name, 'jemandem') || ' aus der Dreamlife Community';
    url := 'https://api.callmebot.com/whatsapp.php?phone=' || public.url_encode(rec.wa_phone)
        || '&text='   || public.url_encode(body_txt)
        || '&apikey=' || public.url_encode(rec.wa_apikey);

    perform net.http_get(url := url);
    update public.notify_settings set wa_last_notified = now() where user_id = rec.user_id;
  end loop;

  return NEW;
end $$;

drop trigger if exists trg_notify_new_message on public.messages;
create trigger trg_notify_new_message
  after insert on public.messages
  for each row execute function public.notify_new_message();

-- ============================================================
--  Fertig. Jeder Nutzer trägt im Profil seine WhatsApp-Nummer +
--  CallMeBot-APIKEY ein und bekommt dann Reminder bei neuen Nachrichten.
-- ============================================================
