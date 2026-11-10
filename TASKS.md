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
- [x] v0.3.10 (owner, 2026-11-10): free pick, any four abilities, one per family; kept until changed (it already was
      saved across races and restarts). Category rule kept as a setting.
      In game (Claude, 2026-11-10, 50cc Lantaana test cup on a copy of the save, owner's save put back after): your
      old four showed by name; Shockwave -> Vent offered Ion Bolt / Shockwave / Mine / Vent only; saved as a list;
      both races launched with Vent, Shield, Surge, Scrubber (four icons on the HUD wheel); put back after each race.
      Race watch 0.92-0.94 ms a tick.

- [x] v0.3.1: race stutter (owner) - full object sweeps cut from ~22/s to ~0.5/s while racing. Confirmed fixed in
      game by the owner (2026-11-09).

- [x] v0.3.2: stutter came back in race 2 (owner). Remaining sweeps removed; PERF line per race in the log.
      First readings (Jakku Cup at 50cc, gold, 2026-11-09): Debris Dunes average 10.3 ms a frame, 1 frame over 33 ms
      (89 ms); Fallen Empire average 10.3 ms, worst 14 ms. No stutter in the numbers. (The "our tick" time was
      meaningless under Proton and is gone in v0.3.3.)

- [x] v0.3.4/0.3.5: stutter built up in Grand Prix races only (Arcade smooth); hitches lined up with our ticks.
      Per-tick GC step + racers read ~1/s. Confirmed smooth (owner, Lantaana Cup, 2026-11-09): our ticks 100+ ms
      late 2-3 times a race (Dai Bendu before: 220); Lua memory steady at ~0.5-0.6 MB.
- [x] v0.3.6: four classes (owner): 50cc no upgrades (parts 0), 100cc 3, 150cc 6, 200cc 10 (maxed); abilities
      1 / 1 / 2 / 3. Save v2: trophies and the cup in progress move up one class (backup kept).
- [ ] Put the save's race count back (211 -> 13) with the game closed (the file has Windows line endings).

- [x] v0.3.9 (2026-11-10): real cause found - every lookup by path is a full sweep in this game (UE4SS has no object
      hash tables). No lookups while racing; one sweep every 2 s. In game: check the PERF "our tick" numbers.
- [x] v0.3.9 in game (owner, 2026-11-10, Lantaana 200cc): "better so far". Race watch average 0.95 ms (was 11.7),
      worst 21 ms; our ticks 100+ ms late 2 a race.
- [ ] Menu: the main-menu poll (`C.cached('FrontEndGameMode')`, every 200 ms) is a lookup by path too = a sweep 5x a
      second at the menu. Not felt so far; make it cheaper (notification + rare checks) if the menus ever hitch.

## 5. v0.4 Mods: the vehicle's affixes (owner, 2026-11-09; DESIGN.md §5b)
- [ ] **Recon M1:** at race load, write one affix with an obvious effect into your race copy's `AffixSlots`
      (`PrimaryAffix`); does it show in the HUD / build and change the car? Also read the copy's affix slot count.
      If it's too late at load, try earlier (launch) or another route.
- [ ] Catalogue in config from the recon dump (name, description, rarity, group by effect, I/II/III steps).
- [ ] MODS screen next to ABILITIES: slots and rarity by class; kept for the cup; written at race load.
- [ ] Tests; tag v0.4.0.

## 5b. Trophy display and reset (owner, 2026-11-10)
- Owner saw a gold cup trophy after winning one race. Checked: not a bug. That race was race 4 of the Jakku cup
  left in progress the night before (races 1-3 on 2026-11-09; 15+12+10+15 = 54 points), carried into 150cc by the
  save conversion. Trophies are only written at the end of race 4 (`gp.lua` cupOver). The 200cc Jakku gold was a
  full cup (1st, 2nd, 3rd, 1st = 52).
- [x] v0.3.11: "race N of 4" on CONTINUE CUP, the cup screen, NEXT RACE (badge "RACE 4 / 4", "the final race")
      and CONTINUE CUP shows your place and points so far.
- [x] v0.3.11: trophy badge on the cup tiles (the tile's own small extra line: GOLD / SILVER / BRONZE TROPHY, or
      IN PROGRESS 3 / 4); class tiles show "3 / 7 TROPHIES".
- [x] v0.3.11: RESET PROGRESS (owner): last tile on the class screen; confirm with NO first; clears trophies, best
      finishes, the cup in progress and the cups count; keeps abilities, vehicle, race count; backup first
      (`save.backup-reset-<date>.lua`).
- [x] In game (2026-11-10): the badges show at the top of the tiles ("3 / 7 TROPHIES", "RACE 3 / 4"). The ranking
      table reads well. Fixed in v0.5.0: two tiles sat two columns apart (LATER); the class tile text was cut off.

## 6. v0.5 Progression (owner asked for it, 2026-11-09; DESIGN.md §8)
- [x] v0.5.0 class unlocks (owner, 2026-11-10): **50cc and 100cc open from the start**; 150cc after a trophy in all
      five planet cups at 100cc; 200cc after the same at 150cc (`Progression.Unlock = 'trophy' | 'gold'`). Locked
      tiles: badge LOCKED, dimmed, "To open: ... (2 / 5)"; selecting one only says so.
- [x] v0.5.0 Outer Rim / Galactic cups: gold in all five planet cups at that class.
- [x] Worked out from the saved best finishes every time (trophies already won count; RESET PROGRESS locks again).
      **Kept:** a class or cup you've already raced through (a best finish) or have a cup in progress in stays open,
      so the owner's 150cc / 200cc stay open. `Progression.On = false` switches every lock off.
- [x] The cup result says what it unlocked ("UNLOCKED: 150cc - OUTER RIM CUP at 100cc ...").
- [x] Tests: `test_prog` (rules), `test_unlocks` (menus, a cup unlocking 150cc); tag v0.5.0.
- [x] In game (2026-11-10): your classes all stay open (kept); 100cc Galactic shows LOCKED, "To open: Gold in all 5
      planet cups at 100cc (2 / 5)", and selecting it only shows that message. v0.5.1 fixes the NO / YES spacing,
      the unreadable focused NO / RESET tiles and the class tile text.
- [ ] Still to see: a cup that unlocks something says so on the result screen.
- [ ] **Reverse cups (v0.5.x):** the five planet cups on reverse (or night / weather) variants. Needs the event paths
      (Underground config `Planets`) and a launch check in game for each. When do they open: after 150cc (DESIGN §3)
      or after the top class (owner's earlier note)? Ask the owner.
- [ ] **Champion Showdown (v0.5.x):** the 1 v 1 against Kestar Bool (`EVT_WHP_SHORTBOSS_FAIR`) as a single bonus race
      (win / lose, no points), after gold in every 200cc cup. Needs a 1 v 1 result read in game.

## 6b. Points ranking after each race (owner, 2026-11-10)
- Owner: fewer screens is better; flow = the game's race results, then ONE screen with the ranking by points.
- [x] v0.3.8: our STANDINGS page becomes that screen: a clear table of all 12 (rank, racer, +points this race, total,
      places gained / lost), your row highlighted, NEXT RACE / LATER underneath. After race 4 the same table with the
      trophy on top (the trophy page and the standings page become one).
- [x] v0.3.8: nothing in between: the game's loading screen covers the ~3 s main-menu rebuild (`HideMenuFlash`).
- [ ] In game: the table lines up and reads well; the cover appears and goes (if it sticks or blocks input, set
      `HideMenuFlash = false`).

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
