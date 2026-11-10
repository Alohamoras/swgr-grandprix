# Changelog

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
