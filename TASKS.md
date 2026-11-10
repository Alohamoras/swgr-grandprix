# Work plan: Galactic Grand Prix

Design: DESIGN.md. Shared playbook and house rules: ~/Projects/swgr-underground/AUTOMATION.md.
One git tag per chunk; push after each tag.

## 0. Repo and design (2026-11-09)
- [x] Repo, DESIGN.md, this plan.
- [x] Owner answers: mines = wildcard, AI follows the four-category rule, 150cc maxed, quit = forfeit.
- [x] Recon tools ready: `tools/recon/GPRecon` (plan.txt / events.txt), TestAutopilot v1.3 (arms bike and skimmer too).

## 1. Recon (trimmed by the owner, 2026-11-09)
- [x] **R5/R6 data dump** (2026-11-09, DESIGN.md §10): all 28 cup races take any car / bike / skimmer
      (`Vehicle.Standard`), all normal 12-car team races (`TeamRaceConfig`), no custom opponents; 1-8 laps.
- [x] **R1 finishing order** of all 12 racers: works (v0.2 in game, 2026-11-09: 12 racers, all named, from
      `PlayerNamePrivate` / `EventPosition` / `bHasFinishedEvent`).
- Dropped / later (owner):
  - R2 the same field across a cup: seen in the owner's playtests.
  - R3 crash limit: later; the three tries are ready in GPRecon (`health=def|state|tune`).
  - R4 class speed: not needed: parts 3 / 6 / 10 for every vehicle type, decided.
  - R7 AI Shields: seen in playtests once the AI has its four.

## 2. v0.1 Skeleton: a race from the GRAND PRIX tab
- [x] Copy from the Underground: `core`, `tab`, `ui`, `race` (launch, results, put-back, multiplayer guard), test
      harness. Rename everything, strip the career, shop, garage and leagues. (`gp.lua` = save, classes, cups.)
- [x] GRAND PRIX tab (F6) → class → cup → START (race 1) or any race tile, parts at the class level; VEHICLE tile
      cycles landspeeder / bike / skimmer; result screen → back to the cup.
- [x] Tests (`test/all.sh`: flow, vehicles, offline guard + crash put-back; 28 checks); tag v0.1.0.
- [x] In game (owner, 2026-11-09): War Fields at 50cc, 2nd; parts 3 in, put back after; result page logged.
      To watch: after the race the screen looked empty in a screenshot (no tab bar), and B on the result page
      logged nothing. Owner: not a bug (they backed out with B). Check again with the v0.2 cup flow.

## 3. v0.2 Cup flow and points
- [x] Results for all 12 racers (R1) → points; standings screen; NEXT RACE launches the next race.
- [x] After race 4: final standings, trophy, best finish per cup and class (own save file).
- [x] QUIT CUP forfeits the cup (owner). The cup in progress is kept in the save (LATER / CONTINUE CUP), so it
      also survives a restart; one cup at a time.
- [x] Tests (`test_cup` scoring, `test_flow` a whole cup, `test_vehicles` bike / DNF / forfeit); tag v0.2.0.
- [x] In game (owner, 2026-11-09): whole Jakku Cup at 50cc, GOLD (54 points); all 12 racers read every race;
      standings and trophy screens worked.
- [ ] (moved to v0.6 Polish) the ~3 s main-menu flash before the standings.

## 4. v0.3 Abilities (moved ahead of the AI difficulty, owner 2026-11-09)
- [x] Pick screens: ABILITIES on the cup screen → OFFENSIVE / DEFENSIVE (Shield) / UTILITY / WILDCARD (mines or any
      unpicked family); the class sets the level (1 / 2 / 3), branches offered from level 2; a clash resets the
      wildcard; no Autopilot. Picks saved; a cup keeps its own copy.
- [x] Your four into the launch build (originals in the save first; put back at the menu, like the parts).
- [x] The AI's four per racer (config `Abilities.Racers`, one per category, by style), level by class, the game's
      `_AI` mines, at race load (`loadout.lua` from the Underground); never yours, never Autopilot.
- [x] Tests (`test_abil`, `test_abilities`); tag v0.3.0.
- [x] In game (owner, 2026-11-09, 50cc Lantaana race 1): your four loaded (Shockwave, Shield, Surge, Status
      Scrubber); all 11 AI racers got their four at load; quitting the race = DNF, the cup moved on to race 2.
- [ ] Still to see: do the AI fire their abilities, Shields included (R7)?

- [x] v0.3.1: race stutter (owner) - full object sweeps cut from ~22/s to ~0.5/s while racing. Confirmed fixed in
      game by the owner (2026-11-09).

- [x] v0.3.2: stutter came back in race 2 (owner). Remaining sweeps removed; PERF line per race in the log.
      First readings (Jakku Cup at 50cc, gold, 2026-11-09): Debris Dunes average 10.3 ms a frame, 1 frame over 33 ms
      (89 ms); Fallen Empire average 10.3 ms, worst 14 ms. No stutter in the numbers. (The "our tick" time was
      meaningless under Proton and is gone in v0.3.3.)

- [ ] v0.3.4: stutter builds up in Grand Prix races only (Arcade smooth). Hitches line up with our ticks (PERF tick
      gaps). Per-tick GC step + fewer reads; Lua memory in PERF. If it persists: time our tick with a real clock
      (KismetMathLibrary Now) and try `GcStep = false` for a comparison.

## 5. v0.4 Mods: the vehicle's affixes (owner, 2026-11-09; DESIGN.md §5b)
- [ ] **Recon M1:** at race load, write one affix with an obvious effect into your race copy's `AffixSlots`
      (`PrimaryAffix`); does it show in the HUD / build and change the car? Also read the copy's affix slot count.
      If it's too late at load, try earlier (launch) or another route.
- [ ] Catalogue in config from the recon dump (name, description, rarity, group by effect, I/II/III steps).
- [ ] MODS screen next to ABILITIES: slots and rarity by class; kept for the cup; written at race load.
- [ ] Tests; tag v0.4.0.

## 6. v0.5 Progression (owner asked for it, 2026-11-09; DESIGN.md §8)
- [ ] Class unlocks: 50cc open; 100cc after a trophy in all five 50cc planet cups, 150cc likewise (setting
      `Unlock = 'trophy' | 'gold'`; owner to confirm). Locked tiles say what opens them.
- [ ] Outer Rim / Galactic cups after gold in all five planet cups at the class; reverse cups after 150cc;
      Champion Showdown after gold in every 150cc cup.
- [ ] Worked out from the saved best finishes (trophies already won count).
- [ ] Tag v0.5.0.

## 7. v0.6 Polish
- [ ] Tile art per cup (planet art), standings layout, short intro text, controller check (owner's pad).
- [ ] Hide the ~3 s main-menu flash between a race and the standings (loading screen, or a shorter wait).
- [ ] Tag v0.6.0.

## 8. Maybe (moved to the end by the owner, 2026-11-09: might not be needed)
- [ ] **AI difficulty per class:** AI pressure (`ai.lua`, the rubber band) on top of the class's part levels.
      Owner after the first cups: "difficult but fun" as it is.
- [ ] **No crash limit:** pick the working control (GPRecon `health=def|state|tune`), set before each race, put back
      at the menu.

## 9. v1.0 Tuning
- [ ] Owner plays every cup at every class; tune parts per class, AI pressure, AI kits, points.
- [ ] Tag v1.0.0.

## Later
- Podracer cup. A 200cc class. The crash ability as a fifth pick. Time-trial ghosts per track (the game has a
  time-trial mode). Records per track.
