# Galactic Grand Prix (STAR WARS Galactic Racer, UE4SS Lua mod)

Kart-racer-style cups for STAR WARS Galactic Racer: speed classes (50cc / 100cc / 150cc / 200cc), cups of 4 campaign tracks,
points and trophies, four abilities instead of upgrades, no crash limit. Offline only.

Status: v0.7.0 (cups with points and trophies; four abilities; mods; class and cup progression; five remix cups; the game's own art on every tile).
See DESIGN.md (the design), TASKS.md (the work plan), CHANGELOG.md.

**To playtest:** the list is at the top of TASKS.md ("Waiting on the owner's playtest").

## Install / test
- `./deploy.sh` installs the newest tagged version into the game (game closed); `./deploy.sh HEAD` the work in progress.
- `test/all.sh` runs every test against a fake game (no game needed).
- In game: the GRAND PRIX tab on the main menu, or F6. Log: `Mods/GalacticGrandPrix/grandprix.log`.
