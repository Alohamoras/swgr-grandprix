# Galactic Grand Prix (STAR WARS Galactic Racer, UE4SS Lua mod)

Kart-racer-style cups for STAR WARS Galactic Racer: speed classes (50cc / 100cc / 150cc / 200cc), cups of 4 campaign tracks,
points and trophies, four abilities instead of upgrades, no crash limit. Offline only.

Status: v0.8.0 built, not yet seen in game (two-level menu, title race per class, your racer, AI profile per class, track records, twelve tune-ups, conditions cups). v0.7.1 is the last version checked in game.
See DESIGN.md (the design), TASKS.md (the work plan), CHANGELOG.md.

**To check in game:** the list is at the top of TASKS.md ("v0.8: to see in game"). Research behind v0.8: docs/research-2026-11-10.md.

## Install / test
- `./deploy.sh` installs the newest tagged version into the game (game closed); `./deploy.sh HEAD` the work in progress.
- `test/all.sh` runs every test against a fake game (no game needed).
- In game: the GRAND PRIX tab on the main menu, or F6 (v0.17: the game starts on it, once per launch; config
  `BootToGrandPrix = false` turns that off). Log: `Mods/GalacticGrandPrix/grandprix.log`.
