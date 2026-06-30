-- ============================================================
--  DreamLife Community Chat — Features v7
--  Alte Chats (lokale Geräte-ID) sicher auf die neue
--  Learning-Suite-ID (system.user.id) übertragen.
--
--  Sicherheit: überträgt NUR, wenn
--    - die alte ID eine 'local-…'-ID ist  UND
--    - alte und neue Anzeigenamen identisch sind.
--  Die App ruft das zusätzlich nur bei eindeutigem Namens-
--  Treffer und nach ausdrücklicher Nutzer-Bestätigung auf.
-- ============================================================

create or replace function public.claim_legacy_chats(p_old text, p_new text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_name text;
  v_new_name text;
begin
  if p_old is null or p_new is null or p_old = p_new then
    raise exception 'invalid ids';
  end if;

  select display_name into v_old_name from public.profiles where id = p_old;
  select display_name into v_new_name from public.profiles where id = p_new;

  if v_old_name is null or v_new_name is null then
    raise exception 'profile not found';
  end if;

  -- Schutz: nur alte lokale Profile, nur bei exaktem Namensgleichstand
  if p_old not like 'local-%' then
    raise exception 'only legacy local profiles can be claimed';
  end if;
  if lower(trim(v_old_name)) <> lower(trim(v_new_name)) then
    raise exception 'name mismatch';
  end if;

  -- conversation_members (PK conversation_id,user_id): Konflikte zuerst entfernen
  delete from public.conversation_members cm
   where cm.user_id = p_old
     and exists (select 1 from public.conversation_members c2
                  where c2.conversation_id = cm.conversation_id and c2.user_id = p_new);
  update public.conversation_members set user_id = p_new where user_id = p_old;

  -- Nachrichten + Ersteller + Erfolge
  update public.messages       set sender_id  = p_new where sender_id  = p_old;
  update public.conversations  set created_by = p_new where created_by = p_old;
  update public.wins           set user_id    = p_new where user_id    = p_old;

  -- DM-Schlüssel mitziehen (für DM-Dedupe)
  update public.conversations
     set dm_key = replace(dm_key, p_old, p_new)
   where dm_key like '%' || p_old || '%';

  -- conversation_reads (PK conversation_id,user_id)
  delete from public.conversation_reads cr
   where cr.user_id = p_old
     and exists (select 1 from public.conversation_reads c2
                  where c2.conversation_id = cr.conversation_id and c2.user_id = p_new);
  update public.conversation_reads set user_id = p_new where user_id = p_old;

  -- message_reactions (PK message_id,user_id,emoji)
  delete from public.message_reactions mr
   where mr.user_id = p_old
     and exists (select 1 from public.message_reactions m2
                  where m2.message_id = mr.message_id and m2.user_id = p_new and m2.emoji = mr.emoji);
  update public.message_reactions set user_id = p_new where user_id = p_old;

  -- Badges zusammenführen
  update public.profiles n
     set badges = (select array(select distinct unnest(coalesce(n.badges,'{}') || coalesce(o.badges,'{}')))
                     from public.profiles o where o.id = p_old)
   where n.id = p_new;

  -- private Benachrichtigungs-Einstellungen des Alt-Profils verwerfen
  delete from public.notify_settings where user_id = p_old;

  -- altes Profil entfernen (alles ist übertragen)
  delete from public.profiles where id = p_old;
end;
$$;

grant execute on function public.claim_legacy_chats(text, text) to anon, authenticated;

-- ============================================================
--  Fertig.
-- ============================================================
