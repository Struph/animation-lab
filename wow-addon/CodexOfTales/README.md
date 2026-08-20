# CodexOfTales (WoW Addon Skeleton)

Dieses Geruest ist **WoW-kompatibel** (Lua/.toc), ohne Browser/JS.

## Features

- Fraktionscover (Allianz/Horde) per `UnitFactionGroup("player")`
- Buch-Open-Transition (Cover fade out, Seiten fade in)
- Verbesserte Blaetter-Pipeline:
  - Flip-Frame-Sequenz (`Flip/flip-01` ... `flip-12`)
  - Seiten-Nudge (leichter Positionsimpuls)
  - Schatten-Pulse im Bund
- Lesezeichen unten fuer direkten Sprung auf Seite
- Slash-Commands:
  - `/codex` (toggle)
  - `/codex close`
  - `/codex page 3`

## Installation

1. Ordner `CodexOfTales` nach:
   - `_retail_/Interface/AddOns/CodexOfTales/`
2. WoW neustarten oder `/reload`
3. Im Chat: `/codex`

## Wichtig: benoetigte Assets

Lege deine Texturen unter:

- `Media/cover-alliance`
- `Media/cover-horde`
- `Media/book-open`
- `Media/page-shadow`
- `Media/bookmark-ribbon`
- `Media/Flip/flip-01` ... `flip-12`

Du kannst `.blp` oder `.tga` nutzen. Passe bei Bedarf die Pfade in `CodexOfTales.lua` an.
