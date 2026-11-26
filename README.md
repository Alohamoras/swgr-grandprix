# Galactic Grand Prix (STAR WARS Galactic Racer, UE4SS Lua mod)

Kart-racer-style cups for STAR WARS Galactic Racer as a GRAND PRIX tab on the main menu: three leagues (JUNKER /
CHALLENGER / ACE), random cups of four races per planet plus the Galactic Cup and (v0.30) the Rally Cup - seven point-to-point stages, four cars, total time -, (v0.31) any vehicle for any pilot with that pilot's paint, pilot faces and signature kits, points and trophies, (v0.33) Kestar Bool's 1 v 1 as the Galactic Cup's finale for the league title, pilot
strength, four abilities and tune-ups, (v0.41-v0.43) PODRACING as a fourth league - the PODRACER CUP at LEARNER or
PRO (abilities on every pod). Offline only. Players' readme: docs/release/README.txt.

Where things are: DESIGN.md (the design), TASKS.md (open work; history in docs/TASKS-done.md), OWNER.md (questions and
playtests for the owner), CHANGELOG.md (per version), docs/ (research and decisions). Shared lessons for all the
Galactic Racer mods: ~/Projects/swgr-underground/KNOWLEDGE.md.

## Commands
- `test/all.sh` - every test against a fake game (no game needed; `SANDBOX_DIR=/tmp/<x>` when runs overlap).
- `./deploy.sh [tag] [--dev]` - install a tagged version into the game (game closed). `--dev` turns the test switches
  on (config `DevTools`: `experiment.lua`, `logbuilds.txt` in the mod folder - AI and race-type research).
- `tools/package.sh [tag]` - the release zip for players in `dist/` (Scripts, enabled.txt, README.txt; never the save
  or the log; refuses if DevTools is on or the README still has a placeholder).
- `tools/mods-toggle.sh [on|off]` - all UE4SS mods off for multiplayer (renames dwmapi.dll), and back on.
- In game: the GRAND PRIX tab or F6. Log: `Mods/GalacticGrandPrix/grandprix.log`; save: `Mods/GalacticGrandPrix/save.lua`.
