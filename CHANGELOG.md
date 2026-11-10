# Changelog

## v0.5.1 (2026-11-10): menu fixes seen in game
- A short row of tiles (CONFIRM's NO / YES, the standings' NEXT RACE / LATER) is filled out with empty cells, so the
  tiles sit side by side (the v0.5.0 width fix didn't take: the uniform grid shares its width over the columns used).
- NO and RESET PROGRESS on a darker tile: focused, their white title vanished on the pale art.
- Class tiles: blurb + "Gold n / 7" only (the text ran past the tile).

## v0.5.0 (2026-11-10): progression - class and bonus-cup unlocks
- 50cc and 100cc open from the start. 150cc opens with a trophy in all five planet cups at 100cc, 200cc with the same
  at 150cc (`Progression.Unlock = 'gold'` makes it gold). Outer Rim and Galactic open at a class with gold in all
  five planet cups there.
- Locked tiles: dimmed, badge LOCKED, "To open: A trophy in all 5 planet cups at 100cc (2 / 5)". They can't be
  entered (START CUP checks too).
- Worked out from the saved best finishes, nothing new saved. A class or cup you've already raced through, or have a
  cup in progress in, stays open. RESET PROGRESS locks everything again. `Progression.On = false`: no locks.
- The cup result says what it unlocked.
- Fixes from the first look in game: a short row of tiles (NEXT RACE / LATER) was spread over four columns; the class
  tile text was cut off.
- Tests: `test_prog`, `test_unlocks`; older flow tests run with the locks off.

## v0.3.11 (2026-11-10): trophy badges, race N of 4, reset progress
- Cup tiles carry a badge with your best trophy at that class (GOLD / SILVER / BRONZE TROPHY), or IN PROGRESS 3 / 4;
  class tiles show how many of the 7 cups have a trophy. (The tile's own small extra line, unused until now.)
- "Race N of 4" everywhere a cup goes on: CONTINUE CUP (also your place and points so far), the cup screen and NEXT
  RACE ("RACE 4 / 4", "the final race"). Owner, 2026-11-10: race 4 of a cup left from the day before looked like a
  single race winning a cup trophy.
- RESET PROGRESS on the class screen: asks first (NO first); clears trophies, best finishes, the cup in progress and
  the cups count; keeps abilities, vehicle and race count; backs the save up first.
- New `test_trophies`.

## v0.3.10 (2026-11-10): free pick abilities
- Owner: pick any four abilities, one per family (Bolt, Shockwave, Mines, Shield, Scrubber, Vent, Surge). The
  ABILITIES screen shows your four by name; picking a slot lists every family the other three don't hold (and the
  branches from 150cc). No Autopilot. The AI racers keep their category fours.
- Picks are a list of four now. Old saves (offensive / defensive / utility / wildcard) and a cup in progress holding
  the old form are read as the list in that order, unchanged.
- The old rule stays as a setting: `Abilities.Rule = 'categories'` in config.lua.
- Tests: `test_abil` covers both rules; `test_abilities` the free-pick screens; new `test_oldpicks` an old save with
  a cup in progress.

## v0.3.9 (2026-11-10): the stutter's real cause
- The v0.3.7 real-clock timing showed our race check taking 11.7 ms on average (worst 74 ms) every 100 ms. Cause, in
  UE4SS.log: "Failed to find FUObjectHashTables::Get()" - UE4SS has no object hash tables in this game, so every
  lookup by name or path (StaticFindObject, so C.deref / C.asset / C.cached) is a full scan of the object list
  (~10 ms). v0.3.1-0.3.8 looked race objects up by path several times a second, believing it cheap.
- Now no lookups at all while racing: one sweep of the player states every 2 s reads all 12 racers (your position,
  finish and speed included); the main menu is noticed by a notification (NotifyOnNewObject on
  /Script/Griffin.FrontEndGameMode) or when a read finds no racers, then confirmed with one sweep.
- PERF: tick gaps and our tick time from the game's clock (no world lookup); the frame-time sample is gone.
- `test_perf` now also fails on any lookup by path during a race.

## v0.3.8 (2026-11-10): the ranking screen
- Owner: fewer screens; after the game's race results, one screen with the ranking by points. The STANDINGS page is
  now a table of all 12: place, racer, points this race (or DNF), total, places moved since the race before (green
  up / red down); your row highlighted in gold. NEXT RACE / LATER underneath.
- After race 4 it's the same screen with the trophy (or your place) on top: the separate trophy page is gone.
- The cup screen of a cup in progress shows the same table.
- The main menu flash between the race and the ranking is covered by the game's own loading screen
  (`WBP_LoadingScreen`) until the ranking is up (config `HideMenuFlash`).

## v0.3.7 (2026-11-09): our tick timed with a real clock
- The PERF line times our own tick with the game's clock (KismetMathLibrary:Now, FDateTime): the race watch and the
  garbage step separately, average / worst, and how many ticks took over 5 / 20 ms. The War Fields at old-100cc
  (owner felt stutter) read 5 checks 100+ ms late but 12.6% 40+ ms late (smooth races 7-9%).
- One-off race-count fix: race_fix.txt in the mod folder (a number added to the count, then deleted). The owner's
  was written with -199 (the v0.3.4 bug).

## v0.3.6 (2026-11-09): four classes
- 50cc: no upgrades at all (parts 0), abilities level 1. 100cc: parts 3, level 1. 150cc: parts 6, level 2. 200cc:
  parts 10 (maxed), level 3. (Owner's idea; the old 50 / 100 / 150cc were parts 3 / 6 / 10.)
- Save version 2: everything stored by class moves up one (old 50cc trophies are now 100cc, 100 -> 150,
  150 -> 200; also the cup in progress). The old save is kept as save.backup-v1-<date>.lua.

## v0.3.5 (2026-11-09): fix - the menu didn't come back after a race
- v0.3.4's Lua-memory figure in the PERF line used %d for a decimal number: an error right after the result was
  recorded, before the race was marked over, so the end of the race ran again every tick (the race counted ~90
  times, no menu). The race is now marked over first, and the RESULT / PERF log lines can't stop anything.
  `test_perf` reproduces it (8 recordings before the fix, 1 after). The cup itself was unaffected (a race is only
  added to the cup once); the owner's race count was put back by hand (211 -> 12).
- The first v0.3.4 race (Griffin's Flight) didn't feel stuttery (owner).

## v0.3.4 (2026-11-09): stutter, part 3
- Owner: stutter still builds up during Grand Prix races; the game's Arcade races are smooth. The PERF line showed
  frames fine between our ticks but our 100 ms ticks often 100+ ms late (Dai Bendu: 220 of 1,646) - the hitches sit
  on our ticks. Suspect: Lua garbage (every engine object touched leaves a wrapper; collected in big batches).
- A small garbage-collection step every tick (config `GcStep` / `GcStepKB`); the 12 racers read every ~1 s instead
  of 0.5 s (straight after the start too); Lua memory (start / peak / end) in the PERF line.
- You're always in a race's result, even when you quit before the racers were first read.

## v0.3.3 (2026-11-09): better stutter measurement
- The PERF line also measures the real time between our own ticks (asked for every 100 ms): any hitch, ours
  included, makes a gap longer. The frame-time sample alone can't see a hitch we cause (it reads the frame before
  ours). Scrap Spiral (owner felt stutter) read average 10.6 ms, 2 frames over 33 ms on the old measure.
- The meaningless "our tick" time (os.clock under Proton) is gone.

## v0.3.2 (2026-11-09): stutter hunt, part 2
- Owner: the stutter came back in race 2. Two v0.3.1 problems: the main menu was still searched for every 3 s while
  racing (one full object sweep), and checking the loading race every 250 ms was too slow for the AI's abilities
  (race 2: "too late", the AI kept the game's copy of yours). Now: no sweeps at all while the race world is there;
  loading checked every tick again.
- PERF line in the log after each race: the game's frame time sampled every 100 ms (average, worst, how many over
  33 / 50 / 100 ms) and how long our own tick took - so stutter can be measured, not guessed.
- Also: StreamlineCampaign v0.5.1 stops its repeated searches during races; TestAutopilot disabled in game.

## v0.3.1 (2026-11-09): smoother races
- Owner: steady frame stutter in Grand Prix races, not in the campaign. Cause: while racing the mod swept the game's
  whole object list (FindAllOf) about 22 times a second (race state and main menu every 100 ms, the racers every
  0.5 s). Now the race state and the racers are found once and looked up by path + address; the main menu is only
  searched for once the race is over (or every 3 s); checks every 250 ms. 220 sweeps per 10 s of racing -> 5
  (`test/test_perf.lua`).

## v0.3.0 (2026-11-09): abilities
- ABILITIES on the cup screen: pick one OFFENSIVE (Ion Bolt / Shockwave), DEFENSIVE (Shield), UTILITY (Status
  Scrubber / Vent / Surge) and WILDCARD (mines, or any family not already picked). The class sets the level
  (50cc 1, 100cc 2, 150cc 3); from level 2 you pick the branch. Autopilot is never offered.
- Your four go into the build you race with and are put back after the race (originals saved first). A cup keeps the
  four it started with.
- Every AI racer gets four too, one per category, sorted from their Underground signature kits by style (config
  `Abilities.Racers`; anyone else gets the default four), at the class's level, written while the race loads. They
  never get yours or Autopilot.

## v0.2.0 (2026-11-09): cups
- A cup is 4 races in a row: START CUP on the cup screen, then NEXT RACE after each race.
- Points for all 12 racers by place (15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1; config `Points`). Not finishing (or
  quitting the race) scores 0. Every racer's position is read during the race (names from `PlayerNamePrivate`).
- Standings screen after each race (this race's points + the cup table); ties go to the better finish in the latest
  race. After race 4: the trophy screen (1st GOLD, 2nd SILVER, 3rd BRONZE), best finish saved per class and cup and
  shown on the cup tiles; gold count per class on the class tiles.
- The cup in progress is in the save: LATER / BACK leave it waiting (CONTINUE CUP on the class screen); one cup at a
  time; QUIT CUP (with a confirm) forfeits it.
- The vehicle is picked before the cup and kept for all 4 races. The single-race tiles of v0.1 are gone.

## v0.1.0 (2026-11-09): skeleton
- The GRAND PRIX tab on the main menu (F6): speed class (50cc / 100cc / 150cc) -> cup (7 cups of 4 races) -> race.
- Every part of your vehicle at the class's level (3 / 6 / 10) for the race, put back afterwards (originals kept in
  the save first, so a crash mid-race is fixed at the next main menu).
- Landspeeder, speeder bike or skim speeder (VEHICLE tile on the cup screen).
- Result screen after each race. One race at a time: points and the 4-race cup flow come in v0.2.
- Offline only (party / matchmaking refused). Plumbing (tab, tiles, launch, put-back) copied from the Underground.
