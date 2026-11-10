# Work plan: Galactic Grand Prix

Design: DESIGN.md. Shared playbook and house rules: ~/Projects/swgr-underground/AUTOMATION.md.
One git tag per chunk; push after each tag.

## 0. Repo and design (2026-11-09)
- [x] Repo, DESIGN.md, this plan.
- [ ] Owner answers the open questions (DESIGN.md §11).

## 1. Recon (one session, a read-only mod `tools/recon/GPRecon`, plus a few memory-only experiments)
Uses quick races from the main menu (the Underground's launch code). Races can be driven by TestAutopilot.
- [ ] **R1 finishing order:** at the results, log every racer's name and final position (`EventPosition` or the
      results data), and DNFs.
- [ ] **R2 the field:** launch the same cup's 4 races, log the 11 opponents each time. Are they the same? Is there a
      safe way to choose them (grid makeup, racer setup), without touching soft pointers?
- [ ] **R3 crash limit:** try `TotalCrashAllowance` (high) and `UseHealth = false` on the launch build; crash on
      purpose until the game would normally wreck you. Which works, and does the crash counter on the HUD go?
- [ ] **R4 class speed:** one track at parts 3 / 6 / 10 with car, bike and skimmer: lap times and top speed.
- [ ] **R5 vehicle types:** read `VehicleTypeTag` of all 28 cup races.
- [ ] **R6 race length:** laps and times of the 28 races; adjust cups to ~15–20 min.
- [ ] Write the results into DESIGN.md §10 and adjust the design.

## 2. v0.1 Skeleton: a race from the GRAND PRIX tab
- [ ] Copy from the Underground: `core`, `tab`, `ui`, `race` (launch, results, put-back, multiplayer guard), test
      harness. Rename everything, strip the career, shop, garage and leagues.
- [ ] GRAND PRIX tab → class → cup → launch race 1 with a fixed build (parts at the class level), back to the tab.
- [ ] Tests; tag v0.1.0.

## 3. v0.2 Cup flow and points
- [ ] Results for all 12 racers (R1) → points; standings screen; Continue launches the next race.
- [ ] After race 4: final standings, trophy, save best trophy per cup and class (own save file).
- [ ] Quit / resume rules (owner's answer).
- [ ] Tests (full cup on the mock world); tag v0.2.0.

## 4. v0.3 Speed classes
- [ ] Parts per class on your build (R4 values); AI pressure per class (`ai.lua`); AI ability kits per class
      (`loadout.lua`), Autopilot never given.
- [ ] Tag v0.3.0. Play one cup per class (owner) to tune.

## 5. v0.4 Your four abilities
- [ ] Pick screen: Offensive / Defensive / Utility / Wildcard, branch picks at levels 2 and 3, no duplicates, no
      Autopilot. Picks into the launch build, put back at the menu.
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
