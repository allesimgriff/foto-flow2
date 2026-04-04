# AI_RULES.md

# AI Rules

1. Arbeite nur im angegebenen Modul.
2. Ändere keine anderen Bereiche ohne ausdrückliche Anweisung.
3. Halte Änderungen minimal.
4. Füge keine neuen Features hinzu.
5. Erkläre nur, was ausdrücklich verlangt wird.
6. Wenn etwas unklar ist, frage nach statt Annahmen zu treffen.
7. Keine Interpretation.
8. Keine Vorschläge ohne Auftrag.
9. Kein Refactoring.
10. Keine neue Architektur.
11. Keine Änderungen außerhalb des Auftrags.
12. Immer nur EIN Schritt.
13. Jeder Schritt muss klein, testbar und reversibel sein.

## ARBEITSWEISE CHATGPT

AUSGABEFORMAT IST IMMER:

1. kopierbarer Prompt (in einem Codeblock)
2. RUN: ja/nein
3. GIT: ja/nein

REGELN:

- ChatGPT liefert IMMER zuerst den Prompt
- ChatGPT sagt IMMER klar:
  - ob zuerst Curt ausgeführt werden soll
  - oder ob direkt selbst getestet werden soll
- Keine Erklärungen außerhalb dieses Formats (außer ausdrücklich verlangt)
- Nach jedem Schritt wird getestet

# APP-MANIFEST – Foto-Flow2

## GRUNDPRINZIP

- Ein Screen = klare Hauptaktion
- So einfach wie möglich
- Keine Überladung
- Nutzer kann nichts kaputt machen
- Keine technischen Konzepte sichtbar

## LAYOUT

- oben: Kontext (z. B. Titel)
- mitte: Hauptinhalt
- unten: klare Hauptaktion
- Kein Scrollen notwendig für Hauptaktion

## AKTIONEN

- Immer genau eine dominante Hauptaktion
- Eine sekundäre Aktion ist erlaubt, wenn:
  - sie klar schwächer dargestellt ist
  - sie logisch notwendig ist
  - sie leicht verständlich ist
  - sie gut antippbar bleibt
- Sekundäre Aktionen dürfen kleiner sein als die Hauptaktion, aber nicht versteckt
- Typische Beispiele: Rückweg, Abbrechen, „Album verlassen“

## TEXTSPRACHE

- Kurze, einfache Sätze
- Alltagssprache
- Keine technischen Begriffe

## ENTWICKLUNGSREGELN

- Keine Änderung am Flow ohne explizite Anweisung
- Keine Änderung an Logik ohne explizite Anweisung
- Keine neue Architektur
- Kein Refactoring
- Keine unnötigen Änderungen
- Keine Interpretation
- Keine „Verbesserungen“
- Immer nur EIN Schritt
- Jeder Schritt muss:
  - klein
  - testbar
  - reversibel sein

## TECHNIK

- Zustand aktuell über `app_state.dart`
- Keine Erweiterung ohne Auftrag
- Keine neuen globalen Zustände ohne Auftrag

## PROJEKTKONTEXT

- Projekt: Foto-Flow2
- Flutter-App
- Entwicklung über Cursor
- Keine manuelle Codebearbeitung
- Änderungen ausschließlich über Prompts

## AKTUELLER FLOW (DARF NICHT GEÄNDERT WERDEN)

1. Start → Kamera (ReviewPhotoScreen)
2. Erstes Foto:
   - Neues Album
   - Album auswählen
3. Danach → zurück zur Kamera
4. Weitere Fotos → werden dem gewählten Album zugeordnet

## AKTUELLE PHASE

- Dummy-Kamera ersetzen durch echte Kamera
- Flow bleibt exakt unverändert
- Keine Speicherung
- Kein Backend