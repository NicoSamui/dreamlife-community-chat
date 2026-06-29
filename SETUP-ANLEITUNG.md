# DreamLife Community Chat — Setup-Anleitung

Ein eigener Echtzeit-Chat für deine Learning Suite: Mitglieder-Verzeichnis, Privat-Chats, Gruppen, Online-Status, Profilbilder. Im DreamLife-Design.

**Wie es funktioniert (in einem Satz):** Eine `index.html` (das Sichtbare) liegt auf Netlify. Die Daten (Mitglieder, Nachrichten, Gruppen) liegen in **Supabase** (kostenlose Datenbank mit Echtzeit). In Learning Suite bindest du das Ganze als iframe ein und gibst die User-ID deines Mitglieds per Platzhalter mit — dadurch braucht niemand ein zweites Login.

Plan-Zeit fürs erste Mal: **ca. 20–30 Minuten.** Du brauchst keine Programmierkenntnisse — nur Copy & Paste.

---

## Die 4 Bausteine

```
[ Learning Suite ]  --iframe + [[USER_ID]]-->  [ index.html auf Netlify ]  <--Echtzeit-->  [ Supabase (Daten) ]
        (wo dein Mitglied ist)                       (die Chat-Oberfläche)                    (Mitglieder, Chats, Nachrichten)
```

---

## SCHRITT 1 — Supabase einrichten (das "Backend")

1. Geh auf **supabase.com** → *Start your project* → mit GitHub oder E-Mail anmelden (kostenlos).
2. **New Project** → Name z.B. `dreamlife-chat`, ein **Datenbank-Passwort** vergeben (notieren, brauchst du selten), Region **Frankfurt (eu-central)** wählen → *Create*. (1–2 Minuten warten.)
3. Links in der Leiste auf **SQL Editor** → **New query**.
4. Öffne die Datei **`supabase-setup.sql`** (liegt neben dieser Anleitung), **kopiere den kompletten Inhalt** rein und klick unten rechts **Run**.
   → Es sollte „Success. No rows returned" erscheinen. Damit stehen alle Tabellen, Echtzeit, Sicherheit und der Profilbilder-Speicher.
5. Links auf **Project Settings** (Zahnrad) → **API**. Hier findest du zwei Werte, die du gleich brauchst:
   - **Project URL** (z.B. `https://abcdxyz.supabase.co`)
   - **anon public** Key (ein sehr langer Text-Schlüssel)

> Der „anon public"-Key darf öffentlich sein — er ist genau dafür gemacht. **Nimm niemals den `service_role`-Key** für die Webseite, der ist geheim.

---

## SCHRITT 2 — Deine 2 Werte in die index.html eintragen

1. Öffne **`index.html`** in einem Text-Editor (TextEdit, VS Code, Notepad — egal).
2. Ganz oben findest du diesen Block:

```js
window.CHAT_CONFIG = {
  SUPABASE_URL:      "DEINE_SUPABASE_URL",
  SUPABASE_ANON_KEY: "DEIN_SUPABASE_ANON_KEY"
};
```

3. Ersetze die beiden Platzhalter durch deine Werte aus Schritt 1.5 — **die Anführungszeichen bleiben stehen**:

```js
window.CHAT_CONFIG = {
  SUPABASE_URL:      "https://abcdxyz.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOi....(dein langer Key)....",
};
```

4. Speichern. Fertig.

> **Vorab testen ohne alles:** Doppelklick auf **`vorschau-demo.html`** zeigt den Chat mit Fake-Daten (Viktoria, Philipp, Ploy) — so siehst du Look & Funktion sofort, noch bevor Supabase steht.

---

## SCHRITT 3 — Auf Netlify hochladen (das "Hosting")

**Variante A — Schnell (Drag & Drop), ideal zum Starten:**

1. Geh auf **netlify.com** → anmelden (kostenlos).
2. Auf der Startseite (*Sites*) gibt es ein Feld **„Drag and drop your site output folder here"**.
3. Zieh **den ganzen Ordner** `10-Community-Chat` da rein (oder nur die `index.html`).
4. Netlify gibt dir sofort eine Live-URL, z.B. `https://glittering-otter-123.netlify.app`. **Diese URL merken.**
5. Den Namen kannst du unter *Site configuration → Change site name* anpassen (z.B. `dreamlife-community`).

**Variante B — GitHub Auto-Deploy (wenn du später öfter änderst):**

1. Lege auf **github.com** ein neues Repository an (z.B. `dreamlife-chat`, *Private* ist ok).
2. Lade die `index.html` rein (Web-Oberfläche: *Add file → Upload files*).
3. In Netlify: **Add new site → Import an existing project → GitHub → dein Repo wählen** → *Deploy*.
4. Ab jetzt gilt: Du änderst die `index.html` auf GitHub → Netlify baut in ~30 Sekunden automatisch neu. Kein manuelles Hochladen mehr.

> Du kannst mit Variante A starten und später jederzeit auf B umstellen.

---

## SCHRITT 4 — In Learning Suite einbetten (die Identität)

Das ist der entscheidende Teil: Damit jedes Mitglied **automatisch erkannt** wird, gibst du seine User-ID über den Learning-Suite-Platzhalter in die iframe-URL.

1. In Learning Suite die Seite/den Hub öffnen → ein **Custom-Code / HTML-Widget** einfügen.
2. Diesen Code einsetzen und **zwei Dinge anpassen** (siehe unten):

```html
<iframe
  src="https://DEINE-NETLIFY-URL.netlify.app/?uid=[[USER_ID]]&name=[[VORNAME]]"
  style="width:100%; height:78vh; border:0; border-radius:24px;"
  loading="lazy"
  title="DreamLife Community Chat">
</iframe>
```

**Anpassen:**

- **`DEINE-NETLIFY-URL.netlify.app`** → deine echte Netlify-Adresse aus Schritt 3.
- **`[[USER_ID]]`** → der Learning-Suite-Platzhalter, der die **eindeutige User-ID** des eingeloggten Mitglieds einsetzt (das, was du erwähnt hast). Den genauen Variablen-Namen siehst du in deinem Learning-Suite-Konto im Embed-/Variablen-Feld.
- **`[[VORNAME]]`** → optional ein Platzhalter für den Namen, damit er nicht selbst eingetippt werden muss. Hast du keinen, lass den `&name=...`-Teil einfach weg — das Mitglied wählt seinen Namen dann einmalig selbst.

**Optional noch besser** (wenn Learning Suite eine Profilbild-URL als Variable liefert):

```
src="https://DEINE-NETLIFY-URL.netlify.app/?uid=[[USER_ID]]&name=[[VORNAME]]&avatar=[[PROFILBILD_URL]]"
```

### Was passiert, wenn ein Platzhalter mal nicht ankommt?
Der Chat ist abgesichert: Kommt **keine** User-ID an, bekommt das Mitglied eine stabile lokale Kennung und einen freundlichen „Wie heißt du?"-Bildschirm. Es funktioniert also immer — mit Identität aus Learning Suite ist es nur komfortabler.

---

## So benutzt es dein Mitglied
- Öffnet die Seite in Learning Suite → ist **sofort drin** (kein Login).
- Tab **Mitglieder**: sieht alle, die sich sichtbar gemacht haben, klickt jemanden an → **Privat-Chat**.
- Button **Neue Gruppe**: Name + Mitglieder wählen → **Gruppenchat**.
- Oben links aufs eigene Profil: **Name ändern, Profilbild hochladen, Sichtbarkeit an/aus**.
- Grüner Punkt = **gerade online**. Neue Nachrichten kommen in **Echtzeit**, ohne Neuladen.

---

## Sicherheit — ehrlich erklärt

Diese erste Version **vertraut der User-ID aus Learning Suite**. Die eigentliche Schutzmauer ist, dass der Chat nur in deinem Mitglieder-Bereich eingebettet ist. Für eine Community ist das der übliche, praxistaugliche Weg.

Was das heißt: Ein technisch sehr versierter Nutzer könnte theoretisch eine fremde User-ID „behaupten", weil die Seite die Identität (noch) nicht kryptografisch prüft. Für private/heikle Inhalte ist das relevant, für einen Community-Austausch in aller Regel nicht.

**Wenn du es später härter absichern willst** (echte, fälschungssichere Identität): Das geht über eine kleine Netlify-Funktion, die aus der Learning-Suite-ID ein signiertes Token macht (Supabase Auth). Sag einfach Bescheid — das ist Phase 2 und baue ich dir dann obendrauf.

Was schon jetzt sicher ist: Der `anon`-Key ist absichtlich öffentlich, der geheime `service_role`-Key bleibt bei dir, und „Row Level Security" ist in der Datenbank aktiv.

---

## Test-Checkliste (5 Minuten)
1. Netlify-URL direkt im Browser öffnen mit `?uid=test1&name=Anna` dahinter → du landest als „Anna" im Chat.
2. Zweites Browserfenster (oder Handy) mit `?uid=test2&name=Ben` → als „Ben".
3. Bei Anna im Tab **Mitglieder** auf Ben klicken, Nachricht schreiben → erscheint **sofort** bei Ben. ✅
4. Gruppe erstellen, beide rein, schreiben → kommt bei beiden an. ✅
5. Profilbild hochladen, Sichtbarkeit testen.

Wenn 1–4 klappen, läuft das Fundament. Danach in Learning Suite einbetten und mit zwei echten Test-Accounts gegenprüfen.

---

## Dateien in diesem Ordner
- **`index.html`** — die fertige Chat-App (hier deine 2 Supabase-Werte eintragen).
- **`supabase-setup.sql`** — einmal in Supabase ausführen.
- **`vorschau-demo.html`** — Doppelklick = Vorschau mit Fake-Daten (kein Setup nötig).
- **`SETUP-ANLEITUNG.md`** — diese Anleitung.

---

## Spätere Ausbaustufen (wenn du willst)
- Nachrichten löschen/bearbeiten, „tippt gerade…", Lesebestätigungen.
- Datei-/Bild-Versand im Chat.
- Push-/E-Mail-Benachrichtigung bei neuen Nachrichten.
- Mitglieder-Verzeichnis automatisch aus der Learning-Suite-API befüllen (statt „wer reinkommt").
- Fälschungssichere Identität (Phase-2-Sicherheit, siehe oben).

Sag einfach, was als Nächstes dran ist.
