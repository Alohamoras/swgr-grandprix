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
- [ ] **R1 finishing order** of all 12 racers: checked on the first real race of v0.2 (the logging is ready in GPRecon
      and the race component has `EventPosition` / `bHasFinishedEvent` / `EventFinishTime` for every racer).
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
- [ ] In game: a whole cup. Check `grandprix.log`: `field: 12 racers`, the `cup <cup> race n:` order matches the
      game's own results screen (R1), standings and trophy screens look right, B on standings / trophy works.

## 4. v0.3 Speed classes
- [ ] Parts per class on your build (R4 values; 150cc = 10); AI pressure per class (`ai.lua`).
- [ ] Tag v0.3.0. Play one cup per class (owner) to tune.

## 5. v0.4 Your four abilities
- [ ] Pick screen: Offensive / Defensive (Shield) / Utility / Wildcard (mines or any unpicked family), branch picks
      at levels 2 and 3, no duplicates, no Autopilot. Picks into the launch build, put back at the menu.
- [ ] The AI's four per racer (one per category, by style), level by class, via `loadout.lua`; Autopilot never.
- [ ] Tag v0.4.0.

## 6. v0.5 No crash limit
- [ ] The R3 control, set before each race, put back at the menu. Tag v0.5.0.

## 7. v0.6 Progression
- [ ] Class unlocks, Outer Rim / Galactic cups, reverse cups, Champion Showdown; trophies on the cup tiles.
- [ ] Tag v0.6.0.

## 8. v0.7 Polish
- [ ] Tile art per cup (planet art), standings layout, short intro text, controller check (owner's pad).
- [ ] Tag v0.7.0.

## 9. v1.0 Tuning
- [ ] Owner plays every cup at every class; tune parts per class, AI pressure, AI kits, points.
- [ ] Tag v1.0.0.

## Later
- Podracer cup. A 200cc class. The crash ability as a fifth pick. Time-trial ghosts per track (the game has a
  time-trial mode). Records per track.
