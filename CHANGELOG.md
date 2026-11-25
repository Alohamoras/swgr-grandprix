# Changelog

## v0.34.3 (2026-11-25): the Rally Cup's rivals catch up (owner)
- Owner: "for the rally cup, the enemies need a much stronger catch up factor". Every league profile switches the
  game's catch-up off (MaxAiCatchupScale 1.0), which on the rally's point-to-point stages with a 4-car grid left the
  rivals 15-57 s behind over a 1:46 stage (the owner's Challenger rally, grandprix.log 2026-11-25 16:27-16:30). Config
  `Rally.AI` now goes on top of the league's profile for every rally stage (ai.lua `A.merged`, race.lua at launch):
  `MaxAiCatchupScale 1.6` (the game's own 1.3) after `AiBehindTimeToMaxCatchup 0.5 s` behind (the game's 2), on
  DA_AIConfig and both pacing assets, put back at the menu as always. The slowdown when ahead stays as the league has
  it (off at Challenger / Ace: they don't wait for you either). The log says `[ai] league challenger (rally profile): ...`
  and the `[aiset] race league=challenger (rally profile)` read-back shows the values. `Rally.AI = false` = the
  league's profile as it is. Untested in game: the owner's next rally tells - the `[gaps]` lines per stage should
  shrink from 15-57 s to a few seconds.
- Tests: test_rally (the profile on the config and the pacing assets, the league's pressure kept), test_ai (A.merged).

## v0.34.2 (2026-11-25): the cup result screen - the trophy and your standing, the streak tile gone (owner)
- Owner, after the Ando cup: "the results screen at the end of the cup needs some work. Participation streak and win
  count seem superfluous, replace those with just the trophy or ending standing of the cup". cupend.lua, config
  `CupResult.Tiles = 'trophy'`: the participation tile (races in a row / best streak) is collapsed and its function
  never called; the WINS tile is the trophy - the medal in its colour, "GOLD TROPHY" over your standing "1ST" ("NO
  TROPHY" over "5TH") - and the screen's title line says it too ("ANDO CUP  -  JUNKER  -  GOLD TROPHY, 1ST"), so the
  verdict shows even if the tile's texts turn out to be bound to the game's own numbers. A fourth text pass at 20 s
  reads the tiles back first and logs what they hold (`[cupend] tiles read back`): if the owner still sees "WINS" and
  a streak there, that line says why. `Tiles = 'result'` is v0.32.9's layout, `'streaks'` the game's.
- Tests: test_cupend updated (the participation tile hidden, the title line, no POINTS / PODIUMS tile).

## v0.34.1 (2026-11-25): the planets off the cup tiles (owner)
- Owner, after seeing v0.33.0's planet pictures on the cup tiles in game: "didn't really turn out like I wanted them
  to, go ahead and revert that change". Config `CupPlanets = false`: the cup tiles are as they were before v0.33.0
  (the poster, the cup's name). The code stays behind the switch (0.86 brings it back); the once-per-cup-result
  `[cupend] the timeline's planet widgets` recon line stays too. Tests: test_finale updated.

## v0.34.0 (2026-11-25): the car per league - Junker engine 10, Challenger 7, Ace 10 (owner; L1 of §1b)
- Owner (docs/league-styles-2026-11-12.md "2026-11-25"): "for ace let's set everything to 10 ... take the afterburner
  and ramjet to 10" at Junker. Config `Leagues[].parts`: Junker `{ [1] = 10, [3] = 10, [4] = 2 }` (afterburner and
  ramjet 6 -> 10, battery 2, cornering / resilience / drift stock), Challenger 7 everywhere (was 5; **owner to
  confirm**, OWNER.md), Ace 10 everywhere (was 9). Every bot races a copy of your car, so each league's car is the
  whole field's. Taglines: Challenger "Balanced rigs and pilots out to make a name", Ace "Money, maxed out, and a clean
  field"; briefs "Balanced engines" / "Maxed-out engines".
- `AI.Strength.ace` shifted down to `{ elite = 0, contender = -1, weak = -3 }`: with your car at 10 the old +2 / +1 had
  nowhere to go, so the Elite race your car, contenders 9, the weak 7. (Open: the game's own level 10 writes 13 stacks,
  so stacks above 10 may still count - a held race would tell; docs/league-styles §"2026-11-25".) Challenger 7 + 2 = 9
  keeps its room. The `[builds]` log lines show each tier's levels at load as before.
- Config only, no code. Tests: test_config, test_leagues, test_start, test_menu20, test_experiment, test_vehicles,
  test_title, test_racervehicle updated to the new levels; 50 files pass.

## v0.33.0 (2026-11-25): Kestar closes the Galactic Cup, no title race; the planets on the cup tiles (owner)
- Owner: "ditch the title race and put the Kestar race at the end of the Galactic Cup" - his pick: race 5, only with
  a trophy. The Galactic Cup's four points races decide the trophy as before; a trophy (config `Boss.Gate`: 'trophy' /
  'gold' / 'always') adds Kestar Bool's Stadium Showdown as race 5 of the same cup - no points (the standings and the
  tie rule stay as the points races left them), the standings page says "BRONZE TROPHY SECURED - NEXT: KESTAR BOOL,
  1 v 1 FOR THE JUNKER TITLE" and NEXT RACE carries his face. Win it and you are that league's champion (the star on the
  league's HOME tile, `titles[league]` in the save); at Ace it also unlocks him as a racer. Off the podium the cup just
  ends. The cup result (both screens) says CHAMPION or "KESTAR BOOL KEEPS THE TITLE"; the tour-end screen's crown goes
  on the finale only when you won it, its points line reads "Finale: KESTAR BOOL 1 v 1, won - ACE CHAMPION". The
  TITLE RACE tile and the KESTAR BOOL tile are gone: seven tiles per league. `Title.On = true` / `Boss.Where = 'tile'`
  keep the old flow (test_title, test_leagues cover it under that config).
- Owner: "for the cup selection screen, let's try and use the planets from the end of cup screen": every cup tile
  now carries the game's round planet picture (`Content/Planets/T_UI_Planet_<code>`, the set the tour-end timeline
  draws from) flush left at 0.86 of the tile's height, the cup's name to its right (config `CupPlanets`: a share of
  the height, or false). The Galactic Cup shows Derven Acos (the ringed one), the Rally Cup Ando Prime. Not yet seen
  in game: the exact texture the timeline draws is logged once per cup result (`[cupend] the timeline's planet
  widgets: ...`) so the tiles can be matched to it if they differ.
- Tests: test_finale (48 checks, new), test_cups / flow / leagues / pacing / prog / racervehicle / title / trophies /
  unlocks updated; 50 files, 1537 checks.

## v0.32.10 (2026-11-25): the cup result screen closes on A, Enter, Space, B or Escape (fix)
- The first one in game closed by its 120 s timer, not by the owner: with the summary over the results our CUP RESULT
  button lost the focus, so the pad's A reached nothing, and Enter was never bound. Now, while the summary is up, the
  button is kept focused (A presses it), Enter / Space set a flag chain.lua reads only then, and the pad's B works
  through a Back screen the last race's results now get too (Backspace / Escape as before). Tests: test_cupend (58).

## v0.32.9 (2026-11-25): the cup result screen says how you did (owner, after the first one in game)
- Owner: "I love the layout of the screen and the recap of the cup, however I'm not sure how useful the wins in a row
  and races in a row stats are ... I'd rather have something more prominent that just says how I did overall in the
  cup (gold / silver medal etc.)". cupend.lua: the WINS tile now carries the trophy - one medal drawn in the trophy's
  colour (`MedalColour`), "GOLD TROPHY" over "1ST" (no trophy: "NO TROPHY" over the place) - and the other tile your
  points ("POINTS 47 / 60") and podiums ("PODIUMS 3 OF 4"). Config `CupResult.Tiles = 'streaks'` keeps the game's
  meaning.
- Owner: "after the new results screen it took me back to the original screen you built, we probably don't need that
  anymore": after the tour-end screen the menu opens on the cups page, not our old cup result page
  (`CupResult.MenuPage = true` keeps it). The old page stays for `Native = false`.
- Seen in game 2026-11-25 (Sentinel Cup, Ace, gold): the screen made, the planet found, all five panel calls took,
  the four race widgets given their place boxes. Tests: test_cupend (45 checks).

## v0.32.8 (2026-11-25): the CUP RESULT on the game's own tour-end screen (owner's pick 10 of the FreeRace list)
- cupend.lua (`docs/freerace-review-2026-11-25.md` §6.1: the FreeRace mod's TOUR summary technique, our own code):
  after a cup's last race, CUP RESULT first puts the game's PvP tour-end screen (`WBP_PostRace_InstantAction_RunEnd`)
  over the results, filled with the cup - one planet on the timeline per planet raced (one for a planet cup, five for
  the Galactic Cup, six for the rally) with a dot per race showing your place (the last race gets the champion crown),
  the WINS and finishes tiles, the XP panel carrying your POINTS (one award per race: "Race 2: THE WAR FIELDS, 2nd",
  the bar your total against the cup's maximum), the cup and league as the title. The results screen stays under it,
  see-through, with our button focused: A (the button again), Enter or Escape close it and leave for the menu, where
  our cup result page follows as before. Taken from FreeRace's dozen builds: never activate the screen, the timeline's
  own planet list starts empty, the progress panel sums the awards itself, the place boxes are shown for every race
  (not only a podium) while the timeline plays in. Closed by itself after 120 s. Config `CupResult` (Native = false:
  the old flow). **Not yet seen in game**: the first cup end tells. Tests: test_cupend (42 checks).
- chain.lua `CH.pollFinal`: the summary's flow (the opening press not read twice; the screen gone = leave).

## v0.32.7 (2026-11-25): the D-pad map from the tiles' boxes (owner's pick 11 of the FreeRace list)
- ui.lua `U.boxNav` (`docs/freerace-review-2026-11-25.md` §4.2, the FreeRace mod's idea with our own rules): every
  tile gets a box in layout units and the map { left, right, up, down } is worked out from the boxes alone, the same
  way for every layout - the rows page (`U.rowBoxes`), the uniform grid (`U.gridBoxes`; its arithmetic links are gone),
  a spanning tile, a short last row. Up / down go to the nearest row first, then the nearest centre (a tie to the left
  one, as before); left / right stay in the row, nil at its edge. The map is pushed into the game's own navigation
  (`SetNavigationRuleExplicit`) for every screen now, and kept as `screen.boxes` / `screen.nav`. No page changes its
  links today (every test holds); a tile added or moved never needs a link by hand. Test: test_boxnav.

## v0.32.6 (2026-11-25): the back of the grid stays in the race (owner's pick 9 of the FreeRace list)
- ai.lua `A.launchRows`, config `AI.BackRows` (`docs/freerace-review-2026-11-25.md` §3.7): the pacing assets' tier
  windows (`PacingConfigs[].AIMaxTimeAhead / AIMinTimeAhead`, curve-table rows named by tier) set the RiffRaff and
  Losers bots to trail you, out of the race by design. At launch those rows are renamed to the league's tier
  (Challengers at Junker and Challenger, Elite at Ace), on both pacing assets, the names into the save first
  (`aiRowRestores`) and back at the menu, at a failed launch, or at the next boot after a crash. The rows the game
  really has are logged at the first launch (`[ai] league x: pacing rows on RP_Default: ...`). `BackRows[league] =
  false` keeps the game's own. Test: test_pacingrows.

## v0.32.5 (2026-11-25): START refuses while the game's tiles are locked (an online queue)
- race.lua / main.lua (FreeRace's 2026-11-08 lesson, `docs/freerace-review-2026-11-25.md` §6.5): while you are queued
  for an online match the game locks every `WBP_FE_TileCommon_Btn` - ours are that class. Before any launch (START,
  NEXT RACE, the via-menu relaunch) our page's tiles are read: one locked (CommonUI's `GetLocked`) or disabled refuses
  the launch with "the game has locked its tiles (an online queue?)", logged `[menu]`. One more guard for the
  offline-only rule; nothing to see in normal play. Test: test_guard.

## v0.32.4 (2026-11-25): the results screen told by the game, not swept for
- chain.lua (FreeRace's 2026-11-11 lesson, `docs/freerace-review-2026-11-25.md` §6.5: "a full sweep here every look,
  from the featured racer's finish on, was a dropped frame each time while the rest of the field raced home"): the
  results screen is now caught as the game makes it (`NotifyOnNewObject` on user widgets, its class name read, the
  screen kept as path + address) and looked up once per look until it is in the viewport; the sweep stays as the
  fallback, every `ChainRaces.SweepS` (3) instead of every 300 ms. `[chain] the results screen found (told by the
  game | a sweep)`. Tests: test_resultsnotify; test_chain unchanged (167 checks).

## v0.32.3 (2026-11-25): the start grace (owner: the field launching away at the green light)
- ai.lua, config `AI.Grace` (FreeRace's fix, `docs/freerace-review-2026-11-25.md` §3.2): for the first 15 s after the
  start the race tune carries `AiAbilityChanceMultiplier` 0 (no bot fires anything in the first corner) and the
  league's lift of `AiMinTimeAheadModifier` held at the game's value (Ace's +0.75 s waits; a league below the game's
  keeps its own); then one more sweep writes the league's values on every tune object, late ones included. The
  originals are recorded once and the league's values always come from them. Our profiles already run no catch-up
  boost, so nothing to hold there. The AI's perfect-start chance 75 -> 45 % at every league (`perfectStart`). Lines:
  `[ai] ... (start grace: for 15 s)`, `[ai] start grace over`. `Grace = false` switches it off. Tests: test_ai,
  test_aiset updated.
- TASKS.md §1g: the FreeRace follow-ups - the six built, the sixteen to come back to; OWNER.md: the v0.32 playtest.

## v0.32.2 (2026-11-25): a per-bot thrust dial, as a test (tune.lua, thrust.lua)
- tune.lua: tune sets made at run time (the FreeRace technique, `docs/freerace-review-2026-11-25.md` §3.6): a
  `UTuneSet` constructed from the Shield condition's class under the racer's tune component, its operations filled in
  (category, property, ETuneOperations, value), applied to ONE vehicle with the pawn's own `RequestApplyTuneSet`
  (`Server_ApplyTuneSet` on the component as the fallback). Nothing written to a game asset, nothing to put back.
- thrust.lua: KNOWLEDGE.md §5 says the bots' pace follows the shared launch template and their parts barely move it.
  FreeRace's lever: `VehicleThrustConfig.MaxRPM` and the three accelerations multiplied per bot by such a set, after
  the start. Off unless asked: config `AI.Thrust` (the shape of `AI.Strength`: pilots -> tier -> factor per league) or,
  for the held-race test, experiment.lua's `botThrust = 1.2` / `botThrustBy = { ['Biddy Blas'] = 1.1 }` (DevTools).
  Applied `AI.ThrustAfterS` (15) after the start; one `[thrust]` line names each bot, its factor and the call that
  took it, and each bot's `BodyState.TopSpeedKmph` is logged then and 20 s later - the log tells whether the dial did
  anything before a race is timed. **Test before trusting**: three held races (TASKS.md). Tests: test_tune.

## v0.32.1 (2026-11-25): the bots use their kits (aiuse.lua)
- loadout.lua hands every bot four abilities at load, but (FreeRace's finding, `docs/freerace-review-2026-11-25.md`
  §3.1, §6.2; the owner's open question R7) a bot only fires its SELECTED ability, and only one the AI's ability
  configs list. So, read inside race.lua's 2 s sweep of the player states (no extra lookups, nothing kept):
  - every 4 s each bot's `SelectedAbilityIx` moves on to the next ability (config `Abilities.AICycleS`);
  - once a race the kit classes of the league are checked against `RaceAIComponentConfig.AbilityConfigCollection`:
    a class no config lists joins its family's config for the race (`AICover`; the lists go into the save first,
    `aiCoverRestores`, and back at the menu - or at the next boot after a crash); a family with no config at all is
    reported as never fired;
  - a bot's own `AbilityConfig` copy gets a recharge by class-name part (`AICooldowns`: mines 30 s, Disruptors 15 s;
    a shared config is left alone);
  - uses are counted from the ability states (Ready -> Active / WarmingUp): one `[aiuse] fired so far` line a minute
    (up to 5) and one with the RESULT.
  `Abilities.AIUse = false` switches all of it off. Tests: test_aiuse.

## v0.32.0 (2026-11-25): the Precision buoys off The Galactic Gauntlet
- hazards.lua: the Precision run's floating buoys (`PrecisionRunBuoy`) sit in the route layer of The Galactic Gauntlet
  and load in every race there, shoving or crashing a car that passes close at speed (the FreeRace mod's finding,
  `docs/freerace-review-2026-11-25.md` §3.3). Our Galactic Cup's final runs that track. In a race on an event named
  by config `Hazards.BuoyEvents` (`EVT_WHP_`) every buoy is hidden, its collision and ticking off: a sweep every 3 s
  for the first 45 s of the race world (the layer can stream in late), then every 10 s for the rest of the race (the
  game shows them again after a rewind); buoys made later are told by `NotifyOnNewObject` and hidden from their path
  half a second on. Never destroyed (the rewind tracks them); nothing to put back (level actors). Lines `[hazards]`,
  one with the RESULT. `Hazards.Buoys = false` turns it off. Test: test_hazards.
- (The FreeRace 1.1c and 1.3 read, with the rest of the list to come back to: `docs/freerace-review-2026-11-25.md`.)

## v0.31.1 (2026-11-25): the rider's scheme actually loads (fix)
- The v0.31.0 playtest (owner: "playtest was good" - the faces, the tiles, the kept picks) logged
  `[paint] ... preset not loaded` for every alternate vehicle: `LoadAsset` by package path does not load a cooked
  Blueprint class (the package holds `PRE_X_C`, no `PRE_X`). paint.lua now tries the full class name first (the PR's
  form), then the package path, and logs which one worked (`[paint] <name>: preset PRE_..._C (loaded by class name)`).
  The v0.29.4 note that the full name "loaded nothing" came from the rust's wrong path (fixed in v0.29.5).

## v0.31.0 (2026-11-25): pilot faces, any vehicle for any pilot, signature kits (PR #1 by MilkManEX, reworked)
From [PR #1](https://github.com/Alohamoras/swgr-grandprix/pull/1) (MilkManEX, 2026-11-24): thank you. Merged with
these changes:
- **Pilot faces from the game, nothing shipped.** The PR bundled 14 PNG portraits extracted from the game and imported
  them at runtime (`ImportFileAsTexture2D`, the texture held across ticks). Those are the game's own 256 px
  `MainIcon` textures (every racer's CharacterDef names one), so config `Portraits` now points at them in the paks:
  the garage's pilot tile, the title race tile and Kestar's tile draw the face on the left (ui.lua `glyph.side`).
- **A VEHICLE tile in the garage** (PR): a new pilot starts on their own category; the other two launch the shared
  base build wearing that rider's preset (paint.lua: a model, faction swatch and finish per rider and body, written
  into the racer's `PreferredCustomisationForVehicleArchetype` before the race, taken off at the menu). Changes: the
  preset class loads by its package path (the PR's full-name LoadAsset found nothing not already in memory); the
  put-back record is in the save first (`paintRestore`), so a crash mid-race is put right at the next boot; the title
  race and the boss race use the picked vehicle too (they raced the pilot's own).
- **Signature kits** (PR): choosing a pilot starts your four abilities as that pilot's kit (the four their bot races
  with); edits stay until the pilot changes. Change: an existing save keeps its four (they become the current
  pilot's) - the PR reset every player's picks on the first launch after the upgrade.
- Save fields `vehicle`, `picksRacer`, `paintRestore` registered; the PR's dead `P.tick` dropped; its three failing
  tests pass (one was the picks reset, two were expectations).

## v0.30.0 (2026-11-24): the RALLY CUP (owner: "a rally cup, all the tracks that are point to point")
- A seventh cup on every league's cups page (after the title race and Kestar): **seven point-to-point stages**, one
  per route and direction, in tour order - The Giants' Graveyard (Jakku), Geothermal Tour (Lantaana), Rhodochrosite
  Run (Crait), Bool River Run both ways (Sentinel I), Mountain to Sea and Dai Bendu Ascension (Ando Prime). The night /
  weather variant of each stage is drawn when the cup starts; the finale is always Dai Bendu Ascension at night.
- **The weather stays a surprise:** the start screen's list, the NEXT RACE tile and the results-screen prompt name the
  route only (`Rally.HideWeather`); the stage shows itself when it loads. The log knows (`[cup] ... drawn:`).
- **Four cars:** you and three rivals drawn from the racers when the cup starts, the same three on every stage, through
  the title race's grid cut (`GridMakeup` 4 entrants, `CharacterList.Opponents` = the three; put back at the menu).
- **Standings by total time** (cup.lua `timed`): THIS STAGE / TOTAL / GAP table, stakes in seconds ("1.5 S BEHIND BIDDY
  BLAS, 6 STAGES LEFT"), the near miss in seconds (`Near.TrophySeconds` 5), the cup result "11:40.00 in all". A racer
  who does not finish a stage takes the slowest finisher's time + 30 s (`Rally.DnfPenaltyS`); a finisher whose time
  can't be read, the slowest timed + 2 s a place (`*`).
- The Rally Cup counts for no planet-cup unlock (Challenger, Ace, the Galactic Cup) and sets no title-race leader.
- Also: tools/recon/TrackTry (a LaunchCustomRace launcher for TrackDefs with no event; the hidden Jakku track is Star
  Destroyer Speedway, a 5-lap short circuit, nothing special).
## v0.29.9 (2026-11-13): AI test - your level on your own race copy (test-only)
- `experiment.lua` (DevTools only): `yourCopy = true` puts the shared launch build at the bots' level
  (`botStacksAbs`) and your `yourLevels` onto your own race copy at load. Round B2 showed the bots still ~15 s slower
  with your car at level 1 even with their parts and power fixed: the suspect is the shared launch build.

## v0.29.8 (2026-11-13): AI test - the copies' power level (test-only)
- `experiment.lua` (DevTools only): `botPower = true` with `botStacksAbs = N` also sets each bot copy's own PowerLevel
  (copied from your build like the parts) to 6 x N; the `[exp] bot parts absolute` line logs the old and new value.
  (Round B of the fixed-league test ran the bots ~15 s slower with your car at level 1 than at 10, parts equal.)

## v0.29.7 (2026-11-13): AI test switches (test-only)
- `experiment.lua` (DevTools only - players never get it): `yourLevels = N` (or `{ [slot] = N }`) sets your part
  levels for the race; `botStacksAbs = N` sets every bot's parts to level N whatever your build (stacked upgrades to
  N, the Battery item swapped for its level-N one; empty level-0 slots counted, never named). For the Underground's
  fixed-league AI test (`~/Projects/swgr-underground/docs/ai-fixed-difficulty-plan-2026-11-13.md`). Test:
  `test_aitest.lua`. Nothing changes with DevTools off.

## v0.29.6 (2026-11-13): first release build
- Same code as v0.29.5; the release texts final (the UE4SS link, "grimy" Junker cars, no licence - the owner uses
  Nexus's own permission settings). Built with `tools/package.sh v0.29.6`.

## v0.29.5 (2026-11-13): the rust's real path
- The patinas live in the GriffinSharedVehicles plugin: `/GriffinSharedVehicles/Griffin/Vehicles/Common/Liveries/
  Patinas/LP_AllRust` (the manifest's `Griffin/Plugins/GriffinSharedVehicles/Content/...`), not `/Game/...`. Seen in
  game: v0.29.4 still logged "not found" with the right load call.

## v0.29.4 (2026-11-13): the rust actually applies; MIT licence; release texts filled in
- **Fix: the All Rust patina never applied** (every Junker race since v0.29.0 logged `[looks] All Rust patina not
  found`; what showed was the dirt and the dents). core.lua `C.asset` asked `LoadAsset` for the full object name; it
  needs the package path (as MenuRecon and `C.uclass` load). Now it tries both. test_looks models an asset not yet in
  memory.
- MIT licence (LICENSE; LICENSE.txt in the release zip). The UE4SS link (Nexus mod 2) in the player README and the
  Nexus description.

## v0.29.3 (2026-11-13): release pass
- **Test switches off for players:** `experiment.lua` / `logbuilds.txt` only work with config `DevTools = true`
  (default false; `./deploy.sh <tag> --dev` turns it on).
- **Fix:** looks.lua looped forever when a pawn's component lookup gave back an object instead of a plain list (seen
  in the tests; the game gave a list). Now read by index, at most 16.
- **Release tooling:** `tools/package.sh` (the player zip in `dist/`, with checks: no save / log, DevTools off, every
  script compiles, no local paths, no placeholder left), the player README (docs/release/README.txt) and the Nexus
  description (docs/release/nexus-description.bbcode), `tools/mods-toggle.sh` (all mods off for multiplayer).

## v0.29.2 (2026-11-13): race types research tools
- `[elim] n: <racer> eliminated|wrecked <s> after the launch (position, fail reasons)`: every racer's eliminated /
  wrecked flag, logged once each, in order, from the field read already done every 2 s (no extra lookups) - the
  elimination order an eliminator / knockout round would score by.
- `experiment.lua` (test-only): `eventPath` (launch any event by path, e.g. the eliminator) and `modeFrom` (this
  launch borrows another event's race mode, e.g. the War Fields eliminator's TimeEliminatorConfig; memory only, put
  back at the main menu).

## v0.29.1 (2026-11-12): Junker afterburner and ramjet 6
- Owner: another +2 at JUNKER - parts slots 1 and 3 (afterburner, ramjet) 4 -> 6, battery 2 (set in the installed
  config by the other session, carried here).
- Seen in game (owner): the JUNKER crash is fixed; the looks show. The dents were "a little overboard" (on top of the
  rust): `Looks.riffraff` is now rust + dirt only (the damage lever stays in looks.lua, off).

## v0.29.0 (2026-11-12): the JUNKER crash fixed; rust, dirt and damage at Junker
- **Fix: every JUNKER race crashed while loading** (since v0.28.0; UE4SS.dll+0x2ace27, a null read at +0x18). Pilot
  strength (loadout.lua `L.botParts`) named each part upgrade's tune set before checking it had one; Junker's parts
  slots at level 0 (Grip, Resilience, Advanced) have none, and naming an empty object reads its name at +0x18.
  Challenger and Ace fill every slot, so they never crashed. Now only a live tune set is named or changed.
  test_looks reproduces it (an empty slot named 48 times on the old code).
- **Junker looks** (owner: "adding some rust ... for the junker class"; looks.lua, config `Looks.riffraff`): at each
  Junker race load, every car (`field = true`) gets the game's own All Rust finish (`LP_AllRust` on its
  VehicleMaterialsComponent), dirt 1 and the crash-damage look 0.6, applied at load and again ~12 s in. Log: `[looks]`.
  Unproven in game: whether the patina / debug levers show - the owner looks. Each lever has its own switch.

## v0.28.3 (2026-11-12): JUNKER, more engine, no race list
- **RIFF-RAFF is now JUNKER** (owner). The key stays `riffraff` (the save uses it); tagline "Scrapyard junk with too
  much engine", brief "Hot-rodded junk - one ability - no tune-ups".
- **Junker's afterburner and ramjet +2** (owner: "racing a piece of junk that can go faster than it probably should"):
  parts slots 1 and 3 2 -> 4, battery stays 2.
- **No race list on the start screen** (owner): the game's own track intro (the flyover with the track's name) plays
  in our races since StreamlineCampaign is off. `StartRaceList = true` puts the list back.

## v0.28.2 (2026-11-12): test switch quitAfterS (launch checks)
- `experiment.lua` `quitAfterS = N`: N s after the launch (once the field is read) the race goes back to the main menu
  the game's own way (`RequestReturnToMenus`) - a DNF; for launching every race variant once. A swapped `event` is now
  a copy of the pool's entry (the pool stays clean).

## v0.28.1 (2026-11-12): the cup flow's two gaps closed
- **The last race of a cup**: our CUP RESULT button on the game's results screen (focused, the game's CONTINUE hidden,
  as after races 1-3); A (or B, or N) goes to the cup result at the main menu. `ChainRaces.Panel.LastRace = false`
  for the old way.
- **A DNF** (wrecked, eliminated or timed out: `bHasVehicleWrecked` / `bHasBeenEliminated` / `bHasTimedOut` on your
  race event component) now runs the same results-screen flow as a finish: the standings panel and NEXT RACE once
  the others are done (up to `ChainRaces.OutWaitS`, 600 s). Log: `out of the race (wrecked): a DNF`.

## v0.28.0 (2026-11-12): pilot strength - the same few drivers to beat
The AI driving spike (docs/ai-driving-results-2026-11-12.md) found every bot races an exact copy of your car, so
nothing told the pilots apart and the winner was mostly whoever crashed least. Held-race tests: a bot's parts change
its pace (+2 levels = ~3-4 s on a ~110 s race), and giving the Elite +2 put them on top. The owner: no per-race
randomness - "the same few drivers should be competitive for the cup".
- **Pilot strength** (config `AI.Strength`, loadout.lua): at load each bot's car gets its tier's parts levels on top
  of yours. Elite (Sen Fira, Biddy Blas, Lyren Shok, Kestar Bool) +2, contenders (Goli & 02-R0, Griff Halloran,
  Nik Skandaro) +1, weak (Malis Vazosk, Ary Quill) -1, the rest as you. Riff-Raff: the Elite +1 only. Fixed, no
  rubber band. Logged: `[ai] pilot strength (<league>): ...`.
- The boost-rule change tested in the spike had no effect: not used.

## v0.27.7 (2026-11-12): AI driving spike tools (test-only, nothing changes without their files)
Step 1 done (docs/ai-driving-results-2026-11-12.md); step 2's switches:
- `logbuilds.txt` in the mod folder: every racer's race copy logged at load (`[builds]`), read only.
- `experiment.lua` in the mod folder (ai.lua `A.experiment`): driving style writes (DS_Car / Bike / Skimmer_Base,
  put back like the AI config), extra DA_AIConfig fields, the bots' part stacks at load (`botStacks`,
  `botStacksBy`), a fixed `event`, and `[exp] result` with every racer's time. test_experiment.
- tools/recon/MenuRecon: LoopInGameThreadWithDelay (house rule); the AI dump list and log in `ai-2026-11-12/`.

## v0.27.6 (2026-11-12): a press while the next race waits can't start the campaign
The owner, mid-cup (Sentinel, Challenger): after race 3 the game went to the campaign's paddock. The log: NEXT RACE
-> the main menu under the loading cover, waiting 5 s to settle before launching race 4; at 15:50:20 the launch found
the main menu already gone ("Cannot launch: not at the main menu") - the game was loading the campaign. The cover
takes no input, and the menu under it sat on the game's Recommended page with the campaign tile focused, so an A press
in those seconds started the campaign. The cup was lost; the put-backs had all run first.
- While the next race waits under the cover, our tab is picked with a **wait page** (one tile that does nothing; B
  does nothing; picked again if the tab is left), so stray presses land on it. The launch drops the page without the
  usual trip back to the game's first tab. Log: `[chain] via the menu: the wait page in our tab under the cover`.

## v0.27.5 (2026-11-12): the tab at game start
- `BootToGrandPrix = false`: the game opens on its own main menu; pick GRAND PRIX (or F6).
- The tab appears sooner: while the menu is up without our tab, the mod looks every 200 ms (was 1 s, for 5 s at
  most); `TabSettleS` 1.0 -> 0.5 (1.0 if the menu misbehaves).

## v0.27.4 (2026-11-12): the garage's icons and tune-up slots
The owner (via another session): some garage icons stretched tall; tune-ups hard to tell from abilities.
- **Icons keep their shape** (ui.lua `picture`): the size given is the height, the width comes from the texture's own
  size (at most 2.5 x). The ability badges are 472 x 244: drawn in a square they were stretched to twice their height.
  The ability badge is now 100 high (194 wide), the tune-up picture 120.
- **Captions**: a small gold TUNE-UP or pale blue ABILITY top left on each slot (`it.tag`, drawn in its own colour on
  the tile's picture).
- **A tune-up slot your league doesn't have** (the second at Challenger, both at Riff-Raff) is greyed with a lock,
  titled TUNE-UP 2; Select says where it opens ("Tune-up 2 opens at ACE"). Only on the start screen (its league is
  known); the old standalone garage cycles every slot as before.

## v0.27.3 (2026-11-12): STANDINGS during the finish times
Seen in the owner's play of v0.27.2 (14:05): in races 2 and 3 of a cup the results screen closed during the 6 s of
finish times and the mod read it as B ("Leave the cup?"). With CONTINUE only disabled nothing had focus, so the pad's
A went to the results screen, which moved on.
- While the finish times show, our button is on at once, labelled **STANDINGS** and focused (CONTINUE hidden, the Back
  screen up). A = the standings now; after 6 s they come by themselves. The same button then becomes NEXT RACE, so the
  A that brought the standings is not also NEXT RACE. B leaves the cup as on the panel.
- Tests: test_chain section T rewritten (the button, A during the times, the pad's B during the times).

## v0.27.2 (2026-11-12): Challenger open from the start
The owner: "for now Riff-Raff and the middle league should be unlocked by default, only the top league should be
gated". Config `Leagues`: Challenger `open = true`. Ace still opens with a trophy in all five Challenger planet cups;
the Galactic Cup and the title race keep their locks in every league. (`open = nil` on Challenger brings the
Riff-Raff -> Challenger gate back; test_prog still tests that rule.)

## v0.27.1 (2026-11-12): the finish times stay up
The owner (playing v0.26): "at the end of the race, it skips over the finish times screen, I see it for just a split
second". Cause: after a cup race that isn't the last, our standings panel went over the game's results screen the
moment it was found (one 0.3 s look), hiding the game's own finish-times table.
- The game's results (the finish times) now stay up for `ChainRaces.Panel.TimesS` (6 s), then the standings panel
  comes, as before. Meanwhile the game's CONTINUE is invisible and disabled (a stray A can't skip to the menu); the
  N key brings the panel at once; Backspace / Escape leaves the cup as on the panel. TimesS = 0: the old way.
- The last race of a cup is unchanged (no panel: the game's own screen and CONTINUE, then the cup result).
- Tests: test_chain section T (the wait, CONTINUE held and given back, B during the times).

## v0.27.0 (2026-11-12): league taglines, a livelier Riff-Raff
The owner's notes of 2026-11-12. Tested against the fake game, **not yet seen in game**.
- **No speed chevrons on the HOME posters**: beside the medal pips they read as progress, and their meaning wasn't
  obvious. The top of each poster now shows progress only.
- **A Star Wars tagline on the focused poster** (the game shows a tile's description on the focused tile only):
  Riff-Raff "Outer Rim junkers and scrapyard hopefuls", Challenger "Tuned rigs and pilots out to make a name", Ace
  "The fastest pilots in the galaxy" (config `Leagues[].tagline`).
- **The league's brief under its name on the cups page**: "Stock engines - one ability - no tune-ups" / "Tuned
  engines - two abilities - one tune-up" / "Full-power engines - three abilities - two tune-ups" (`Leagues[].brief`).
- **Riff-Raff gets its speed parts**: afterburner, ramjet and battery (energy) at level 2, cornering, resilience and
  drift stock. `Leagues[].parts` may now be a table by slot (`EVehiclePartSlot` 0-5); `K.levelsFor` reads either.
  The slot-to-stat-bar order (1 = afterburner, 3 = ramjet, 4 = battery) is read from the stat bars' order, still to
  confirm in the garage's stat bars in game.

## v0.26.0 (2026-11-12): three leagues (RIFF-RAFF, CHALLENGER, ACE) and random cups
The owner's decisions of 2026-11-12 (TASKS "Three leagues" and "Random cups"). Tested against the fake game, **not
yet seen in game**; 27 race variants have never been raced by the Grand Prix (OWNER.md has the list to launch once).
- **Three leagues replace the four cc classes**, named after the game's racer ranks. Save keys `riffraff`,
  `challenger`, `ace` (config `Leagues`; the save and the cup run keep the field name `class` for a league).

  | | RIFF-RAFF | CHALLENGER | ACE |
  |---|---|---|---|
  | Parts (every slot) | 0 | 5 | 9 |
  | Ability level | 1 | 2 | 3 |
  | Tune-up slots | 0 | 1 | 2 |
  | AI profile | the 50cc one (pressure -1, mercy 0.4, forced errors) | the 150cc one (honest, pressure 0) | the 200cc one (pressure 0.5) |
  | AI tiers' tune-ups | none | Elite: HEAT SHIELD | Elite: HEAT SHIELD + ARMOUR, Challenger tier: HEAT SHIELD |

  - **No "cc" anywhere a player sees it**: HOME's posters, the cups page title, the start screen, the cup result, the
    title result ("ACE CHAMPION"), the lock texts ("To open: 5 trophies at RIFF-RAFF"), the tune-up slot info
    ("Tune-up 2: from ACE."), Kestar's lock ("beat Kestar Bool after the ACE title") and the log lines
    (`[ai] league ace: ...`, `LAUNCH ... league=challenger`, `cup over: CHALLENGER jakku ...`).
  - **The speed as a picture**: 1, 2 or 3 chevrons in each league poster's top right corner (the game's
    `Icons/Leaderboard/T_UI_SimpleArrow_Icn`, a solid right-pointing wedge, white, 56 px; art.lua `A.speed`); the medal
    pips stay top left. The posters are wider (`HomeRows` 760, three of them) so both fit. Banners: Riff-Raff the
    sage difficulty banner, Challenger the blue, Ace the red (the gold one is no longer used).
  - **Unlocks** (prog.lua, the rule that opened 150cc from 100cc): Riff-Raff is open from the start; Challenger opens
    with a trophy in all five planet cups at Riff-Raff, Ace with one in all five at Challenger. Galactic Cup and title
    race per league as before.
  - **Title race at every league**, a 1 v 1 against the league leader; defaults before any cup: Riff-Raff Griff
    Halloran, Challenger Biddy Blas, Ace Sen Fira. Never your own racer.
  - **Kestar Bool is the final boss after the ACE title** (config `Boss.League = 'ace'`); beating him unlocks him.
  - **A clean start for older saves** (save version 3): at the first load a v1 / v2 save is copied to
    `save.backup-v<N>-<date>.lua`, every bit of progress is cleared (medals, records, perfect cups, standings, titles,
    the boss, leaders, counts, the last race, the cup in progress) and only the garage is kept - the racer, the four
    ability picks and the tune-ups (normalised to the slots) - with the put-back records. Kestar is locked again (a
    Kestar pick races as Shade). One log line: `[save] v0.26: three leagues - a clean start (backup save.backup-v2-...);
    kept: racer, abilities, tune-ups. Racer Kestar Bool is locked again: racing as Shade.` The old migrations (v1 class
    shift, the v0.11 cup drop, the v0.21 rival drop / boss migration, the v0.15 vehicle drop) are gone with it.
- **Random cups** (config `Pools`, gp.lua `K.draw`):
  - **A planet cup = 4 base tracks drawn at random from its planet's pool, each with a random variant**, never the
    same base track twice, the same rule in every league. The pools: every base track in docs/tracks-by-planet.md with
    every race variant - Jakku 13, Lantaana 22, Ando Prime 24, Crait 13, Sentinel I 13 (85 races, 31 base tracks), plus
    Derven Acos 1 (The Galactic Gauntlet). Left out: eliminators, knockouts, the 1 v 1 arenas, the story acts, the
    campaign intro, every `EVT_SHK_*` challenge event, the `EVT_DAL_CAR_Race_*` special car races, the Shakedown.
  - **The Galactic Cup**: 3 races from 3 different planets drawn from the five, then The Galactic Gauntlet at Derven
    Acos - 4 planets (config `last = 'derven'`; `nil` draws all four alike).
  - **New titles** in today's style: "THE WAR FIELDS (REVERSE, SCORCHING)", "MORO KEHN TUNNELS (REVERSE, NIGHT)",
    "CLOISTER RUN (SNOW)" ... `kind` / `laps` are display only (the start screen, the title tile, the LAUNCH line,
    `SD.sprint`); the new variants take their layout's values (the races raced before keep the events dump's own).
  - **The draw happens when you pick the cup**; the start screen shows the cup, the league and the four races with
    their conditions (one per line, in place of the single header line); START races exactly those. The draw is kept
    in the cup run in the save (`run.list`), so it survives the trips through the main menu between races. B and
    picking the cup again draws again. Logged: `[cup] ACE jakku drawn: ... / ... / ... / ...`. `math.random`, seeded
    once at load (tests inject their own: `K.random`).
  - **Cup tiles**: the medal and the perfect star, no conditions line. The focused cup's info names its planet's
    tracks (the Galactic Cup: the planets, then the finals); no per-race records there any more.
  - **Records stay per exact event path** (unchanged); medals and perfect cups per league per cup - a gold means
    "won a Jakku Cup at Ace".
  - **The title race track**: the first race of the leader's most recent cup run at that league (saved with the
    leader: `leader[league].path`). No leader yet: the first race of a random Jakku draw, made once per league and
    saved (`titleTrack`), so the title tile shows a stable track.
- **Removed** (no dead code): the per-class race lists, `Classes`, `raceList`, `K.races`, `K.raceClass`,
  `K.cupConditions`, `K.cupPlanets`, `K.raceLine`, `K.recordsText`, the cups page's conditions line, main.lua's unused
  `modsText` / `picksText`, the 100cc AI profile, and the old save migrations above.
- **Tests** (`SANDBOX_DIR=/tmp/gp_v26 test/all.sh`): reworked for three leagues and drawn cups (a fixed draw in the
  tests, `T.RND`), and two new files: `test_random_cups.lua` (every pool path is in the game's event list,
  docs/data/events-2026-11-12.txt, and every other planet race but the left-out kinds is pooled; 300 draws per cup
  never repeat a base track; the Galactic Cup spans four planets; the draw on the start screen, saved, surviving a
  reload mid-cup; START and NEXT RACE launch the draw; records per path) and `test_leagues.lua` (the clean start, the
  leagues' parts / abilities / slots / AI on real launches, the unlock ladder, Kestar after the Ace title).
  test_tiletext checks every pool title on the NEXT RACE tile.

## v0.25.0 (2026-11-11 night): fixes from the first look in game at v0.22-v0.24
Claude's in-game check (owner away; save backed up and restored, md5 checked; autopilot). Seen working: the faster
tab (1-2 s), HOME's medal pips and title stars, the cups page in rows with clear gold / bronze medals, the start
screen (header, START focused, ability and tune-up icons), NEXT RACE alone on the results panel, B on the results
panel -> "Leave the cup?", the cup result, CONTINUE -> the cup just raced, RESET's two questions. Fixed:
- **HOME opened on RESET** instead of the class last raced: the game hands focus to a tile of its own the moment a
  page appears; for the first second our focus is now kept (config `FocusHoldMs`, 1000).
- **Unfocused tiles looked milky** on the menu's pale art (they were faded): a rows page now darkens them instead.
- **Tile text without the grey bars** was hard to read on bright art when focused: a dark drop shadow on every
  tile's title, badge and description (config `TileTextShadow = false`: none).
- **The racers' portraits drew broken** (Kestar's tile: white with scraps of picture; the game's large
  `Content/Characters/*_Fallback` textures don't work through the tile's picture): none are used, the stadium
  picture is back (config `Portraits = {}`).
- Bigger medal pips on HOME (66 px).
- The yes / no questions centred in a row; the standings page and the cup result centred; the MOVED column only
  once someone has moved.

## v0.24.0 (2026-11-11): the garage is the start screen; pictures, not words, on the tiles
TASKS.md "Round 3: the UI" item 3 (owner: "build it into v0.24 ... i don't like the look of the text on the tiles
that has a dark grey background behind it, the title race should just get a medal when you complete it, the
progress tracking of the cc tiles can be on the tiles, but we need to find a prettier way to display it"). Tested
against the fake game, **not yet seen in game**.
- **The garage is every race's start screen**: a cup (or the title race, or Kestar) opens it with START focused and
  your last picks kept - one press to race, or change your racer, abilities or tune-ups first, for this race. On
  top: the cup, the class and its conditions ("150CC - Dawn, scorching"), or the title race's opponent and track.
  B goes back to the cups. Rows: your racer (two tiles wide) and the tune-ups; the four abilities; START. HOME has no
  GARAGE tile any more. Config `StartScreen = false` brings back the v0.23 way.
- **No grey bars behind tile text** (config `TileLabelStrip` now false), and no badge words: no "LOCKED", "N / 6
  TROPHIES", "Gold N / 6", "Champion: YOU", "CHAMPION", "FINAL BOSS", "BEATEN", "RACER", "ABILITY n", "TUNE-UP n".
- **Pictures instead** (the game's own icons, tinted; ui.lua `U.decorate`):
  - a lock in the corner of a locked tile;
  - on HOME, each class tile a row of medals, one per cup (gold / silver / bronze, faint grey when none yet), then
    a star for the class title (gold once won);
  - the title race and Kestar's tile get a gold medal once won / beaten;
  - a perfect cup a gold star beside its medal;
  - each ability its big ability icon, each tune-up its first affix's icon (art.lua `A.ability`, `A.tuneUp`).
- **HOME in rows**, centred: the four classes as tall posters, RESET small below (config `HomeRows`).
- The tile you press is the one the page comes back to (the start screen opens on START).

## v0.23.0 (2026-11-11): the cups page in rows, medals as pictures, faces on the title tiles
TASKS.md "Round 3: the UI" item 2. Tested against the fake game, **not yet seen in game**.
- **Rows of tiles** (ui.lua `U.buildRows`): a page can be laid out as rows, each with its own tile size, centred, in
  place of the one grid of equal tiles. Its D-pad map goes to the nearest tile in the next row (`U.rowsNav`; the keys
  use it too). Pages without rows are unchanged.
- **The cups page:** the five planet cups in one row; below, the GALACTIC CUP two tiles wide, the TITLE RACE and (at
  150cc after its title) KESTAR BOOL; the page centred. Config `CupsRows` (nil = the v0.22 grid, `CupsLayout`).
- **Medals as their own picture**, bigger (120 px), over the tile's top right corner and tinted by medal: the tile's
  icon slot drew every medal in one colour, so gold and bronze looked alike. Without the game's Overlay widget the
  medal stays in the tile's icon slot.
- **Faces:** the title race tile shows the opponent's portrait and Kestar's tile his (config `Portraits`, the
  game's character art: Lyren Shok, Sen Fira, Goli & 02-R0, Malis Vazosk, Kestar Bool). Racers without known art
  keep the stadium picture. The match is by name only: to check in game.

## v0.22.0 (2026-11-11): the quiet pass - dark text, stray text cut, the tab in ~1 s, old code to attic/
TASKS.md "Round 3: the UI" item 1 (owner: "clean up the UI more, there's plenty of stray text"). Tested against the
fake game, **not yet seen in game**.
- **Dark grey text** on the pages without a picture behind them (HOME, the cups page, the garage, the questions; owner:
  the gold and white text is too light on the menu's pale art). The standings, cup result and title result keep their
  picture and light text. Config `DarkText = false` brings the light colours back.
- **Stray text cut:**
  - HOME: no "GALACTIC GRAND PRIX" title (the tab says it), no info line on open classes, GARAGE or RESET, no
    "Asks twice".
  - Cups page: the title is the class alone ("100CC"); no medal words on tiles ("BRONZE TROPHY": the medal icon says
    it), no planet badge ("JAKKU", "4 PLANETS"), no "Not raced yet" / "Best: 4th" (a tile shows its conditions, and
    "Perfect cup"); the focused cup's info is its four tracks with your record time (no best line, conditions,
    planet, kind, laps or best lap).
  - Garage: no "Select: next" on tiles, no "Select: next racer." or "Levels up with the class" in the info, a
    shorter empty tune-up line.
  - Standings: no "STANDINGS" title; your line is "2nd   -   1:40.40   -   0.4 s behind Biddy Blas" (no "You:", no
    best lap - a new best lap is still a note).
  - Cup result: no "CUP RESULT" title, no "Last race" line, no "Next:" goal line (owner: no goal lines); its record /
    near-miss notes and what it UNLOCKED stay.
  - Title result: no title, one line under the headline at most.
  - The questions: no "CONFIRM" title.
- **The GRAND PRIX tab shows ~1 s after the main menu** (owner: it took ~3 s): the menu settles on time (config
  `TabSettleS`, 1 s; was 3 looks a second apart), the menu is looked at every poll (200 ms) while it settles, and
  the boot opens our page 0.3 s after the tab is in (was 1 s).

Unused code out (owner: "take out the unused code and save it somewhere as old code"). Kept in the new `attic/`
folder, which is not loaded, deployed or tested; see attic/README.md. No change in what you see in game.
- **Study mode is gone** (v0.16, the AI study driver): studymode.lua, its wiring in main.lua (`ST.poll`, `studyEnv`,
  the study result in the tick) and BootToGrandPrix's "skipped when study jobs are pending" check. A study.lua left in
  the mod folder is ignored. The `[aiset]` read-back and the `[gaps]` log stay. Tests test_study / test_study_resume
  moved to attic/. test_boot's study scenarios were replaced by one that checks a leftover study.lua changes nothing.
- **The same-layout reset route for chained races is gone** (`ChainRaces.Reset`, off by default since v0.19.1 after
  it hung on PLEASE WAIT across layouts): the recipe write / put-back, `R.chainLaunch` / `RequestResetRace`, the load
  timeout, the watchdog, `CH.fallback` and the fallback phase, and config `Reset`, `LoadTimeoutS` and `WatchdogS`
  (an old config with them still loads; they are ignored). NEXT RACE always goes via the menu, as it has by default
  since v0.19.1, and that path is unchanged. test_chain's reset scenarios (E to I) moved to attic/.
- attic/README.md also lists other code that is switched off or has no caller ("Candidates, not removed").

## v0.21.0 (2026-11-11): the leader's title race, Kestar the final boss, no rival, less clutter
TASKS.md "Next, round 2" item 1 (the owner's answers after a 50cc and a 100cc cup, OWNER.md "Done"). Built and tested
against the fake game, **not yet seen in game**. DESIGN.md §17.
- **A little harder at 50cc and 100cc**: the bots' mercy slowdown when ahead (`MaxAiSlowdownScale`) 0.3 -> 0.4 at
  50cc, 0.3 -> 0.45 at 100cc. Catch-up stays 1.0.
- **Tougher from 100cc up** (owner after a 200cc Jakku cup - 2nd, 3rd, 2nd, 1st, gold - and a 150cc Galactic silver:
  "200cc is fast and brutal, i crash a lot and still get ~2nd place, so overall the difficulty could be a little
  tougher"): the bots no longer ease off while you crash at 100 / 150 / 200cc (pacing `AiSlowdownDuringCrash` 1.0 on
  DA_AIConfig, RP_Default and RP_Honest; the game's 0.5 / 0.9 stay at 50cc), and 200cc is a notch above 150cc
  (pressure 0.5; 150cc stays 0).
- **The rival is gone**: rival.lua, config `Rival`, the RIVAL marks and colour, the "YOUR RIVAL" stakes wording, the
  rival on HOME and on the cup result. The stakes line still names who you chase or lead. An old save's `rivals` is
  dropped at load (`[save] the rivals are dropped ...`, once).
- **The title race is a 1 v 1 against the class leader on a normal track**: the best bot of your most recent finished
  cup at the class (the 2nd if you won it), saved when a cup ends (`leader`, `[title] 100cc leader: ...`); the track is
  the first race of that cup's list. No cup yet: Griff Halloran (50cc), Lyren Shok (100cc), Biddy Blas (150cc), Sen
  Fira (200cc) on the Jakku Cup's first race. The tile: TITLE RACE / "vs Biddy Blas". Launched with the two-car grid
  (the event's GridMakeup 2 entrants, CharacterList.Opponents cut to the leader; RaceFlowSpike B6), originals in the
  save (`gridRestore`) and put back once at the menu, or at the next boot after a crash (`[title] grid cut ...` /
  `[title] grid put back (...)`). Your racer swap still applies. No cup track record from a title race.
- **Kestar Bool is the final boss**: the Stadium Showdown (the old title race, cinematics fix kept) is a KESTAR BOOL
  tile on the 150cc cups page once the 150cc title is won (FINAL BOSS / BEATEN); beating him saves `boss` and unlocks
  him as a racer (was: the 150cc title). Old saves with the 150cc title won (against Kestar) count him beaten. The cups
  page: 7 tiles, 8 at 150cc with the boss (4 + 4), never scrolls.
- **CONTINUE at the end of a cup** goes to the class's cups page with the focus on the cup just raced.
- **Less clutter**: no "Next:" line on HOME; no class blurbs (config, HOME, the cups page); no levels line on the cups
  page; HOME's info lines one short line each. The cups page's race list and the garage's help line stay.
- **No grey see-through page panel** (config `PageBackdrop = false`): HOME, the cups page, the garage and the questions
  sit straight on the game's menu; the standings, cup result and title result keep their picture backdrop.
- **RESET PROGRESS clears everything**, titles, the boss, leaders and counts included, except the garage picks (racer,
  abilities, tune-ups; Kestar falls back to Shade), behind two questions, NO first: "Reset all progress? Every
  trophy, record and title is cleared." then "Are you sure? This can't be undone." The backup is still made first.
- **The results-screen panel after a cup race (not the last): no CONTINUE** (owner: redundant and misleading). Only
  NEXT RACE, centred; the game's CONTINUE is collapsed (`ChainRaces.Panel.HideContinue`). The prompt: "NEXT RACE: race
  N of 4, <name>.   B: leave the cup." B (the pad through a hidden Back screen in the panel; Backspace / Escape on the
  keyboard) goes to the main menu and straight to "Leave the cup? Your points are lost." (NO = the standings with NEXT
  RACE). The screen closing by itself before NEXT RACE counts as B. The last race keeps the game's CONTINUE.
- **The Ando short track** (Loop_B SHORT_01, on the Monastery Mountains loop) is named **CLOISTER RUN** (records are
  kept by event path: nothing in the save changes).
- Tests: test_rival removed; new test_reset (two questions, everything cleared, the backup, HOME without Next:,
  PageBackdrop); test_title rewritten (leader, default, two-car grid and put-back, crash put-back at the next boot,
  the boss tile / unlock / old-save migration); test_chain (no CONTINUE, B by key / pad / the screen closing, NO / YES,
  the last race keeps CONTINUE, HideContinue = false); test_menu20, test_ai, test_config, test_tiletext,
  test_trophies, test_racervehicle, test_nearmiss updated.

## v0.20.1 (2026-11-11): footer fix
- In game v0.20.0 logged `[footer] error: tab.lua:71: bad argument #2 to 'tonumber'`: `C.try` returns `nil, error` when
  a call fails (here GetChildrenCount on a widget that isn't a panel), and `tonumber(nil, 'message')` raises. Every
  `tonumber(try(...))` now keeps only the first value (tab.lua, chain.lua).

## v0.20.0 (2026-11-11): the rival you can see, and the menu polish
TASKS.md "Next" 3 (the rival part; the title race waits for the owner) and 4, from docs/menu-review-2026-11-11.md.
Built and tested against the fake game, **not yet seen in game**. DESIGN.md §16.
- **A rival from the first race**: after the first cup race at a class with no rival, the racer who finished nearest
  you (just ahead, else just behind; never Kestar Bool) is your rival there; the v0.13 tally decides changes after
  that. Old saves keep their rival. `Rival.FirstRace = false` = the old rule.
- **The rival's row marked** on every standings (the standings page, the panel on the game's results screen, the cup
  result's top 3): light blue and "RIVAL" after the name. The call-out and "YOUR RIVAL" stakes lines stay.
- **The cup result is a screen of its own**: the medal large and tinted (bronze / silver / gold), the trophy big,
  PERFECT CUP as a badge, the final top 3 only (and your row under them when lower), the last race in one line (with
  the record and "1 POINT FROM GOLD" near misses), the rival call-out, and one what's-next line: what the cup unlocked,
  else how close the next unlock is ("Next: 2 more trophies at 150cc open the GALACTIC CUP and 200cc"). CONTINUE (and
  B) land on the next cup at the class without a gold, named on the tile ("Next: CRAIT CUP").
- **HOME**: one "Next:" line naming the nearest goal (from the existing unlock rules); the focus opens on the class
  you last raced; the League line and the counts are gone; every class tile shows trophies on the badge and golds under
  the title; "Champion: <bot>" is gone (your own title stays), the class info names the rival.
- **A dark strip behind every tile's small top label and its description** (config `TileLabelStrip`), so they read
  on a focused, brightened tile.
- **The game's footer hidden on our tab** ("Select / C Restart Campaign / Settings", the main menu's
  `WBP_ActionBar_C`, as the FreeRace mod does), put back when you pick another tab (config `HideFooter`; `[footer]`
  log lines). The C key itself is not unbound.
- **Small ones**: the cups page loses "Select a cup to start it: ..." and the vehicle name ("Parts level 3, abilities
  level 1" stays); no best lap on sprints; the cup tiles' medal icons tinted through the brush tint (gold and bronze
  looked the same in game); the seconds on your line, from the race's gaps ("0.4 s behind Biddy Blas" / "7.8 s
  ahead", review 8). Review 9 (per-ability art) not done.
- Tests: test_menu20 (new: the cup result for an unlock / a near unlock / a near miss and CONTINUE's focus, the rival
  row, HOME's Next: line and focus, the footer hidden / put back / only logged, the label strip, the small texts);
  test_rival (the first-race rival, `RV.nearest`, FirstRace off, an old rival kept), test_chain (the rival marked on the
  panel), test_tiletext (the new tile texts) and the badge / text expectations of test_trophies, test_unlocks,
  test_nearmiss updated.

## v0.19.1 (2026-11-11): NEXT RACE via the menu
**What failed in game with v0.19.0** (2026-11-11 17:35, Jakku 150cc): race 1 (The War Fields dawn, Mastiff/Loop_A)
finished, the panel showed on the results screen, N was pressed, The Giants' Graveyard (Mastiff/P2P_A) was written
into the race recipe and read back, `RequestResetRace` was called and a new race world even logged `EVT_MAS_P2P_FWD`
0.3 s later - but the screen stayed on the game's black PLEASE WAIT loading screen for good (2+ minutes, Escape did
nothing, the game had to be killed; `field: 1 racers`, `[loadout] gave up: the AI racers never appeared`). **Why:**
`RequestResetRace` re-uses the track world that is loaded; a race in another layout folder (another map) never
loads. The B9 spike only proved Loop_A FWD -> Loop_A SHORT_02 (one map). Only 8 of the cups' 48 race-to-race steps
stay in one layout folder. Also the game's results table showed through our panel, and NEXT RACE overlapped CONTINUE.
Built and tested, **not yet seen in game**. DESIGN.md §15.
- **NEXT RACE now goes via the main menu** (the default, every cup, the Galactic Cup too): the results leave for the
  main menu the game's own way (the results screen's CONTINUE click, else `RequestReturnToMenus` - what the v0.19.0
  fallback did), and at the menu the cover goes up instead of the standings page; once the menu has settled (the
  study mode's rules: menu up, no race, put-backs done, `ChainRaces.MenuSettleS` = 5 s) the next cup race launches
  through `R.launch`, exactly as NEXT RACE on the standings page does. The cover comes off when the race world is
  there. You never see the menu. A failed launch: the cover off and today's standings page (logged with why).
- **The reset route only on request and only within one layout**: `ChainRaces.Reset = true` (default false) AND the
  next race in the same layout folder (planet + the folder after it, e.g. `Mastiff/Loop_A`, without case). Proven
  for Loop_A -> Loop_A only. New **watchdog**: no AI racer or no race start 20 s after the reset (`WatchdogS`) ->
  `RequestReturnToMenus` and the next race via the menu. Every other failure after NEXT RACE (no new world in
  `LoadTimeoutS`, the menu coming instead, a recipe write that fails, a world running another event) now also
  carries the cup on via the menu rather than stopping at the standings page.
- **`CrossPlanet` removed**: it no longer matters (the menu route works across planets; the reset route needs one
  layout folder, which is always one planet). An old config line with it is ignored.
- **Panel**: an opaque dark background (alpha 1, a second opaque border behind it; was 0.92) and the game's own
  results table (`WBP_Simple_RaceResultsPanel_C`) hidden under it (`Panel.HideGameTable`). NEXT RACE left of CONTINUE,
  side by side: both centred, a slot each of CONTINUE's width x 1.2 (its desired size / width override / slot size,
  at least 420), `Panel.ButtonGap` (80) apart; the positions are logged on `[chain] panel added`. Text unchanged.
- **CONTINUE** keeps its meaning: the main menu and today's standings page, where B leaves the cup.
- Tests: test_chain rewritten (10 scenarios): ChainRaces off as the reference; a whole Jakku cup via the menu with
  the save, the set-up lines and the put-backs identical to the menu flow, the cover, no standings page between the
  races, the cup result at the end; CONTINUE + B leaving; a failed auto-launch -> the standings page; Reset on with
  the same layout (Crait race 2 -> 3) uses the reset and the watchdog is satisfied; Reset on with another layout
  uses the menu; the watchdog firing (a world with you only); no world after the reset; a failed recipe write; the
  Galactic Cup via the menu. The fake world: `W.resetMode = 'empty'`, the game's results table on the results screen.

## v0.19.0 (2026-11-11): cups without the main menu
TASKS "Next" 2, from the B9 spike (RaceFlowSpike). Built and tested, **not yet seen in game**. DESIGN.md §15.
- **After a cup race (not the last), the standings go on the game's own results screen**: the standings page's text
  (cup / race line, your line, stakes, NEW RECORD / near miss, the table with THIS RACE / POINTS / MOVED) on a dark
  panel over the game's table, one prompt line (`NEXT RACE: race 3 of 4, FALLEN EMPIRE.  CONTINUE: the main menu (to
  leave the cup).`), and a **NEXT RACE** button beside CONTINUE (made from CONTINUE's own class, focused: pad A /
  Enter on it; or the key N, config `ChainRaces.Key`).
- **NEXT RACE starts the next cup race in the race world**: the same set-up as a launch from the menu (race.lua
  `prepare`, now shared by `R.launch` and the new `R.chainLaunch`: parts, abilities, tune-ups, AI profile + pacing
  assets with the `[aiset]` read-back, a fresh rubber band, racer swap, AI loadout), the next event written into the
  race recipe's active stage (both copies, read back), then `RequestResetRace`. The race is recorded on the results
  screen by the same code the menu uses (race.lua `recordRace`), so points, records, cup progress, rival tally, near
  misses and the gap log are identical; the menu never records it twice.
- **CONTINUE** (or the game moving on by itself) goes to the main menu and today's standings page, where B still
  asks "Leave the cup? Your points are lost." B on the results screen itself is not read.
- **Put-backs once**, at the main menu when the chain ends (cup over, CONTINUE, a fallback): build, abilities,
  tune-ups, AI config and pacing assets, racer, and (new) the subsystem recipe's stage.
- **Same planet only** (config `ChainRaces = { On = true, CrossPlanet = false, ... }`): the folder after `/Planets/`
  in the two event paths, without case. Planet cups chain all four races; the Galactic Cup (a planet change every
  race) keeps the main-menu flow. The last race of a cup always goes to the menu and the cup result.
- **Fallbacks** to CONTINUE -> main menu -> standings page, each logged: no results screen in `ResultsWaitS` (90 s),
  the panel not added, a failed set-up / recipe write / read-back / reset call, no new race world in `LoadTimeoutS`
  (15 s), the menu coming instead, a new world running another event. `[chain]` log lines for every step.
- The standings text moved from main.lua to standings.lua (shared by the page and the panel); ui.lua's line / table
  drawing is shared by the page and `U.panel`. The race-world watch takes the first race state not seen before
  (name + address) as the new one (was: not the one at launch).
- Tests: test_chain (new, 6 scenarios in one file with `T.reset`: ChainRaces off = today's flow; a 4-race cup
  chained end to end with the save compared to the menu flow's; CONTINUE + B leaving; a reset that gives no world;
  a recipe write that fails; the Galactic Cup's planet change). The fake world (test/world.lua) has the race recipe
  (subsystem + race state copies), the results screen with CONTINUE on its canvas, and `RequestResetRace` making a
  new race world.
## v0.18.1 (2026-11-11): AI profiles after the check races
12 autopilot check races on The War Fields (docs/data/study-v018check-*, study-100calib-*):
- v0.18 made 100cc harder than 150cc: at 100cc the best bot beat a clean autopilot (118 s against ~120); at 150cc it
  lost by 6-11 s. Your car gains more from the class parts than the bots do.
- Slowdown 0.5-0.85 barely slows the bots; 0.3 (the game's own) does (100cc best bot ~123 s).
- Now: 50cc and 100cc slowdown 0.3 (50cc keeps pressure -1 and the forced errors), 150cc and 200cc 1.0 (honest:
  best bot ~105 s at The War Fields dawn against the owner's 1:42.4). Catch-up stays off everywhere.

## v0.18.0 (2026-11-11): AI profiles from the study
TASKS "Next" 1. From the AI study (docs/ai-study-2026-11-11.md, 36 autopilot races): races read their pacing from
RP_Default, whose default slowdown 0.3 is what held the field back; with the band off the bots are as quick as a
clean autopilot and steady. New profiles (config AI.Profiles), written to DA_AIConfig, RP_Default and RP_Honest:
| Class | pressure | catch-up | slowdown when a bot leads you | speed matching | forced errors |
|---|---|---|---|---|---|
| 50cc | -1 (Cadet) | off (1.0) | 0.5 | off | the game's |
| 100cc | 0 | off | 0.7 | off | off |
| 150cc | 0 (was 0.5) | off | 0.85 (was 1.0, never reached the race) | off | off (was x0.5) |
| 200cc | as 150cc | | | | |
- No catch-up anywhere: a lead you build is yours. The slowdown is the mercy rule: it lets you catch a leader back,
  less of it as the class goes up.
- Not yet raced by the owner: one cup at 100cc and one at 150cc decide the numbers (`[gaps]` lines).
- Tests: test_ai checks the v0.18 profiles; it and test_aiset drive the mechanism with the old profiles pinned.

## v0.17.0 (2026-11-11): boot straight into the Grand Prix
TASKS.md 11 (owner: "i want the game to launch and go directly to the grand prix menu, pressing b would still back
out to the main menu"). Built and tested, not yet seen in game.
- **At the first main menu after the game starts, the GRAND PRIX tab opens by itself on HOME** (`[boot] opening the
  GRAND PRIX tab (BootToGrandPrix)`). Same path as the menu key (main.lua `openPage` -> `show` -> `TB.select`: our
  tab picked by its id; never by stepping through the game's tabs, so never MULTIPLAYER). It waits for our tab on a
  settled menu (after `[tab] GRAND PRIX tab added`), for every put-back to be done (parts, abilities, tune-ups, AI
  config, racer, title: `R.pendingRestore`) and no cup (an old one is dropped at load as before), then 1 s more.
  2-3 s later one line says whether the tab stayed up (`[boot] the GRAND PRIX tab is up` / `did not stay selected`;
  not retried).
- **Once per launch**: a flag set the moment it opens (or gives up) and never cleared, so B, a race, leaving the tab
  or a rebuilt menu never reopen it. B on HOME goes back to the game's first tab as before; the standings after a
  cup race still open as before (their own flow).
- Not opened (and logged) when: `BootToGrandPrix = false` (new, config.lua next to MenuKey, on by default); a study
  with jobs pending (study.lua; `[boot] not opening the GRAND PRIX tab: study mode has jobs pending ...` - the study
  needs the plain menu; studymode.lua `ST.pending`); the page already open or a race under way; the tab could not be
  added.
- Tests: test_boot (new; four scenarios each in its own Lua: opens once at the first menu after the drop and the put
  back, B / a rebuilt menu / a cup race + B don't reopen it, the standings still come after the race, only our tab
  and the first tab are ever picked; switch off; study pending; study all done). The harness (test/util.lua) sets
  `BootToGrandPrix = false` unless a test asks for it, so the other scenarios start from the game's menu as before.

## v0.16.1 (2026-11-11): AI study Phase 0 logging
For the AI tuning study's Phase 0 (TASKS.md B10, docs/ai-tuning-research-2026-11-11.md (c)). Built and tested, not
yet run in game.
- **`[aiset]` read-back**: the values actually on the assets, read back after the AI settings are written. Once at
  the main menu after boot (`[aiset] menu at boot | ...`, after any crash put-back) and once per race at launch
  (`[aiset] race class=150[ study] | DA_AIConfig: ... | RP_Default: ... | RP_Honest: ...`): DA_AIConfig's
  DefaultPacingSettings (6 fields), the SpeedMatching fields, forced errors, perfect start, aggression vs player;
  each pacing asset's `PacingConfigs.Num` and its PacingSettingsConfig (6 fields). Plain numbers / bools only; `?` =
  unreadable, `missing` = asset not found. Plus one `[aiset] race tune class=150 | ...` line per race with the shared
  race tune's values after our writes (from the tune object the rubber band already finds; no extra lookup).
- **Pacing to both places** (config `AI.WritePacingAssets = true`): every DefaultPacingSettings write on DA_AIConfig
  (`pacing`, `catchup`, also a study profile's) goes to `RP_Default` and `RP_Honest`'s PacingSettingsConfig too (a
  set is the same value, `catchup` multiplies each asset's own original), originals in the save's `aiRestores` under
  each asset's path, put back at the menu like DA_AIConfig (also after a crash, at the next boot).
- The three assets are looked up once per race at launch (3 lookups at the menu, none in the race).
- Tests: test_aiset (new: boot line once, RP writes + put-back, WritePacingAssets=false, study profile, one line per
  race, missing asset); test_ai_restore (an RP original left over from a crash is put back). The test world has
  made-up RP assets (their game values aren't read yet).

## v0.16.0 (2026-11-11): study mode (test-only)
For the AI tuning study (TASKS.md B10, DESIGN.md §14). Built and tested, not yet run in game.
- **v0.16.0 - study mode (test-only)**: a `study.lua` in the mod folder lists jobs (class, cup, race number, label, a
  whole AI profile). At the main menu each job's single race launches like the title race (class parts, your racer,
  abilities, tune-ups) with the job's AI profile in place of the class's; no cup run, no points or trophies (records
  and the race count as usual). The menu must be back and settled (put-back done) for 5 s between jobs; our page is
  closed first if open.
- One `[study] job i/N ...` start line and one result line per job (your place and time, the gaps of P1/P2/P3/P6/P12
  to you, the AI's spread) and a row per job in `study_results.csv`. `study_state.lua` holds the next job, so a
  restart resumes; an interrupted race is run again once, then skipped; a job that can't launch is logged and skipped.
  `[study] all N jobs done` at the end.
- ai.lua takes an optional profile (`A.launch / A.begin / A.plan / A.tuneValue`), race.lua `R.launch(..., opts)`
  passes `opts.ai`; the AI config and tune objects are put back after each race as before. race.lua's result now
  carries the field (`out.field`).
- Nothing changes without study.lua: an `io.open` at boot and every 5 s at the menu, no game lookups.
- Tests: test_study (nothing without study.lua; two jobs back to back: parts, DA_AIConfig writes, tune ops, put-back,
  page closed first, log lines, CSV, no cup), test_study_resume (resume from study_state, a retry, a bad job, a failed
  launch, all done, a twice-interrupted job skipped). The test harness's "error in the log" check ignores `errors=`.

## v0.15.1 (2026-11-11): bright tile pictures drawn darker
Seen in game: the game brightens a focused tile's picture, and the white name was hard to read on the brightest
ones. The 50cc banner (75%), the 100cc banner (80%) and Kestar Bool's portrait (70%) are now tinted darker
(art.lua `A.DIM`, ui.lua tints the tile's picture). Factors from the textures' brightness under the title
(136 / 130 / 151, against 104 / 112 for the 150cc / 200cc banners that read fine). Not yet seen in game: whether
the game's focus highlight keeps the tint.

## v0.15.0 (2026-11-11): the racer decides the vehicle
Queue item A6 (TASKS.md, owner-decided). Built and tested, not yet seen in game.
- **Your racer's vehicle**: config `Racers[].vehicle` (car / bike / skimmer) is the source of truth, the same as the
  game's `URacerDef.PreferredVehicleType` read in game 2026-11-11: Malis Vazosk, Katja Mox, Sen Fira, Biddy Blas ride
  speeder bikes; Shade, Ary Quill, Nik Skandaro, Soren Zaks, Kestar Bool drive landspeeders; Griff Halloran, Goli &
  02-R0, Fola Kanjen, Lyren Shok, Sebulba fly skim speeders. Shade drives the base landspeeder (owner). The launch build
  is the racer's type's (config `Vehicles`, unchanged); the class part levels go on it and are put back as before.
- At launch the picked racer's `PreferredVehicleType` (a plain byte, from the def already in hand) is compared with
  config once per racer per session; a mismatch is logged and config wins.
- **The garage has no VEHICLE tile** (RACER, ABILITY 1-4, TUNE-UP 1-2). The RACER tile's second line is the vehicle
  type ("Speeder bike"); its info reads "Biddy Blas - speeder bike:  <bio>.  Select: next racer." HOME's GARAGE tile
  shows the racer and the vehicle type.
- **Kestar Bool is locked until you win the 150cc title race**: Select on the RACER tile skips him, and the info line
  says "Kestar Bool is locked. To unlock: win the 150cc title." A save with him picked while locked races as Shade
  (`[racer] Kestar Bool is locked (to unlock: win the 150cc title) - racing as Shade`).
- **Old saves**: the `vehicle` pick is dropped once at load (`[save] the old vehicle pick (bike) is dropped ...`);
  the racer pick stays.
- Not in this version: the racer's own look (livery preset). It is unproven (TASKS.md B7): you race the plain build
  of your racer's vehicle type for now.
- Tests: test_racervehicle (new: the 14 racers' builds, the lock, cycling with and without the 150cc title, the
  garage and HOME text, the byte check, part levels on and off the skimmer build); test_vehicles now an old save with
  the bike picked and Shade (races the car build), then a bike racer from the RACER tile; test_tiletext, test_racer,
  test_abilities, test_records, test_trophies updated for the missing VEHICLE tile and pick.

## v0.14.2 (2026-11-11): two menu trims seen in game
- The confirm screen's YES / NO tiles lose the "Yes" / "Cancel" line under them (it said the title again).
- The garage header is just "Select a tile to change it." (the rest was about resuming cups, gone in v0.9).
- In game the same morning (v0.14.1, autopilot, a copy of the owner's save): HOME, every class's cups page, the
  garage, the standings with the stakes line, the leave question, the boot drop after a restart, the four new
  events, a race as Kestar Bool and as Biddy Blas on the bike. Details in TASKS.md (queue B1-B8).

## v0.14.1 (2026-11-11): the class tiles name only your title
Seen in game on v0.14.0 (HOME, 2026-11-11 morning): the focused 50CC tile read "Champion: GRIFF / HALLORAN", the
champion's name split over two lines. A class tile now names only your own title ("Champion: YOU"); another
champion's name stays in HOME's info line, as before. test_tiletext checks it (fails on v0.14.0).
Also seen: on a focused class tile the class name (white) is hard to read on the bright 50cc and 100cc posters - the
game's focus highlight brightens the art. Not changed yet (art choice; part of the B8 screenshot pass).

## v0.14.0 (2026-11-11): every tile's text fits
Queue item A7 (TASKS.md; owner 2026-11-10: "can't fully read the tune-up tiles in the garage"). Built and tested,
not yet seen in game: the screenshot check (B8) is still to come.
- **The budget** (ui.lua `U.FIT`, `U.tileFits`): measured on the v0.8 screenshots of 520 x 350 tiles (the game's own
  tile and fonts): title 12 characters a line, 2 lines (the game shrinks a full line a little); badge 15, one line
  (13 beside the medal); the line under the title 19 a line, capitals counting 1.3, and title + that text 3 lines at
  most (2 under a one-line title, 1 under a two-line one: the rest was cut). Scales with the tile width.
- **test_tiletext**: every screen built in every state that changes a tile (HOME and every class's cups page with
  nothing / each trophy / a place / perfect cups / titles, every champion name, every lock; the garage at each class
  level cycling every vehicle, racer, ability in each slot and tune-up in both slots; the standings before every
  race of every cup at every class and after a cup; the title result, the confirms, the offline page): 3537 tiles,
  all within the budget. It failed on 260 distinct tiles before the fix.
- **Moved to the focused tile's info line** (the tile keeps the name and at most a short line):
  - GARAGE tune-ups: the effect line ("Immune to Burning and Frozen") was on the tile with "Select: next" (cut);
    the badge "TUNE-UP 1  -  FROM 100CC" (two lines over the name) is "TUNE-UP 1", the class in the info ("(Tune-up
    1: from 100cc.)"). Tile: "Select: next" ("Select to fit one" on an empty slot).
  - GARAGE abilities: the blurb ("Shrug off hits for a while") -> info only. Racer: the bio -> info only. Vehicle:
    "Select: next vehicle" -> "Select: next". Every garage tile now reads "Select: next".
  - HOME classes: the blurb -> the info's first line (HOME's info is two lines now: blurb, then the class line); the
    tile keeps "Champion: X". The GARAGE tile: vehicle, racer and the four abilities -> info ("LANDSPEEDER  -  Shade
    -  Ion Bolt, Shield, ..."), the tile the vehicle. RESET PROGRESS: "Start over / (asks first)" -> "Asks first".
  - Locks: "To open: A trophy in all 5 planet cups at 100cc (2 / 5)" -> "To open: 5 trophies at 100cc" on the tile
    (prog.lua returns a short form too), the full text in the info; the title race "To open: Galactic Cup trophy".
  - Cups: "Best: GOLD trophy  -  PERFECT" + the first race -> your best only when the badge doesn't show a trophy
    ("Not raced yet", "Best: 5th", "Perfect cup") over the conditions; the conditions alone when both don't fit
    (Sentinel's "Blue hour, overcast, storm"). The info's first line: your best and the conditions; then the races.
  - TITLE RACE: "1 v 1 against Kestar Bool / Select to race" and "You hold the title / (defend it: select)" -> no line
    (the badge says VS KESTAR BOOL / CHAMPION); the info says "You hold the title: defend it." when you do.
  - Standings NEXT RACE: "Race 4 of 4 - the final race / FALLEN EMPIRE (Short circuit)" -> the race's name (the
    badge says RACE 4 / 4), without its conditions when they don't fit ("CAUSTIC FIELDS").
- Tests: test_tiletext (new; 29 tests); test_cups, test_mods, test_rival follow the moves.

## v0.13.1 (2026-11-11): a cheaper main-menu poll
Queue item A5 (TASKS.md, and the section 4 item). Built and tested, not yet seen in game. Every lookup by class,
name or path is a full sweep of the object list here (~10 ms; AUTOMATION.md §3).
- **The menu's game mode without lookups** (race.lua `R.menuPoll` / `R.menuUp`): a new FrontEndGameMode is learned of
  from the existing `NotifyOnNewObject` notification, the menu's going away from our race launch; one real sweep every
  3 s while the menu is thought up (it can also go when the game's own modes load a race: logged `[menu] the main
  menu went away`) and every 2 s while it is not (the mod loaded at the menu). Nothing is kept but a flag.
- Gone: the poll's `C.cached('FrontEndGameMode')` (a lookup by path 5x a second) and the tick's
  `C.first('FrontEndGameMode')` while our page is up or a build waits to be put back (10x a second). The tab's
  discovery sweeps the main menus once a second instead of twice.
- Idle on HOME, 10 s: menu game-mode sweeps 100 -> 3; every sweep 230 -> 123. **Still left:** the tab's checks that
  the menu widget it is drawn in is still alive (`C.deref`, ~12 a second while our page is up). They are what keeps
  us off a freed menu (v0.9.2), and the game can rebuild its menu without a notification we can catch, so they stay
  until a cheaper safe signal is found.
- Tests: test_menupoll (sweeps counted by the mock: `M.sweeps`, `M.sweepCount`); 28 tests.

## v0.13.0 (2026-11-11): a rival per class
Queue item A4 (TASKS.md), from docs/PHILOSOPHY.md point 3. Built and tested, not yet seen in game. Not the title-race
opponent: that is still Kestar Bool until the two-car grid spike (B6).
- **The rule** (rival.lua, config `Rival = { Window = 6, Ahead = 2, Form = 30, Margin = 10, Exclude = { 'Kestar Bool'
  } }`, false = off): after every cup race at a class, each racer within 6 points of you in that cup's standings
  scores 6 minus the gap (2 more if ranked just ahead of you); the first to 30 becomes your rival at the class (about
  two cups of close racing), and another racer takes over only when their tally beats the rival's by 10, more than
  one race can give, so one odd race never flips it. You and Kestar Bool are never scored; Shade is, like anyone.
  Logged: `[rival] 100cc: Sen Fira is your rival` / `... is your rival now (was ...)`.
- **Save:** `rivals[class] = { name, scores = { [racer] = tally } }`, optional (old saves load with none); RESET
  PROGRESS clears it.
- **Standings call-out** with the gap in this cup: "RIVAL: SEN FIRA, AHEAD BY 3" / "RIVAL: SEN FIRA, 5 BEHIND YOU" /
  "RIVAL: SEN FIRA, LEVEL ON POINTS". Its own line while the screen is under its v0.12 height (4 lines after races
  1-3, 5 after the cup); else on the end of your line ("You: 3rd in this race   -   1:58.00   -   RIVAL: SEN FIRA,
  AHEAD BY 3"). When the stakes line already names the rival it says "YOUR RIVAL" instead ("8 POINTS BEHIND YOUR RIVAL
  SEN FIRA, 1 RACE LEFT") and there is no second mention. Nothing when the rival isn't in this cup.
- **HOME:** the class tile's info line names the rival next to the champion ("100cc: parts level 3, abilities 1.  Gold
  0 / 6, trophies 1 / 6.  Champion: BIDDY BLAS.  Rival: SEN FIRA"; "Champion and rival: X" when the same racer).
  "every part at level N, abilities level M" became "parts level N, abilities M" to keep it on one line.
- Tests: test_rival (27 tests).

## v0.12.0 (2026-11-11): stakes and near misses
Queue item A3 (TASKS.md), from docs/PHILOSOPHY.md points 2, 4 and 6. Built and tested, not yet seen in game.
- **Stakes line** on the standings after races 1-3 (cup.lua `CU.stakes`), worked out from the points table (config
  `Points`) and the races left: "3 POINTS BEHIND BIDDY BLAS, 1 RACE LEFT", "LEADING BY 4 OVER SEN FIRA, 2 RACES LEFT",
  "LEVEL ON POINTS WITH SEN FIRA, 2 RACES LEFT"; before the last race when you lead, "LEADING BY 9 OVER SEN FIRA: 6TH
  OR BETTER WINS THE CUP" / "...: ANY FINISH WINS THE CUP" / "...: A WIN TAKES THE CUP"; "GOLD IS YOURS: 16 POINTS
  CLEAR, 1 RACE LEFT"; when the leader can't be caught "GOLD IS OUT OF REACH, SILVER IS NOT" / "SILVER IS OUT OF
  REACH, BRONZE IS NOT" / "GOLD IS OUT OF REACH, 14 POINTS FROM SILVER" / "THE TROPHIES ARE OUT OF REACH". Never
  claims what the points can't back: ties go to the better finish in the latest race (as `CU.standings` ranks them);
  "out of reach" only when winning every race left can't do it, "wins the cup" only when it holds whatever the others
  do, "silver is not" only when a real finishing order gets you there. test/test_stakes.lua checks every claim
  against every way the races left can go on 460 random cups. One line, 70 characters at most.
- **Near misses** (config `Near = { RecordSeconds = 1.0, TrophyPoints = 3 }`, false = off): a finished race within
  1 s of your record at the class without beating it, "0.4 S OFF YOUR RECORD" (gp.lua `K.nearRecord`, from the new
  `offBy` of `K.record`; never with a NEW RECORD, never after a DNF); the cup result within 3 points of the next
  trophy colour up, "1 POINT FROM GOLD" / "2 POINTS FROM SILVER" / "TIED FOR GOLD, LOST ON THE LAST RACE"
  (`CU.nearTrophy`).
- **No taller screen:** the record, best lap and near misses share the one line the NEW RECORD line had
  ("0.4 S OFF YOUR RECORD   -   NEW BEST LAP  0:58.50"); the standings after races 1-3 are 4 lines at most, the cup
  result 5, as before.
- **Unlock pacing check** (test/test_pacing.lua): a fresh save walked cup by cup (50cc first with bronzes, 100cc
  first with golds; 48 steps). At every step something locked can be opened by racing only what is open now and
  shows as a LOCKED tile saying "To open: ..." on HOME or a cups page; no single cup result opens more than two
  things (the most: the fifth 100cc / 150cc planet trophy opens the next class and that class's Galactic Cup). The
  current rules pass; no config change. Nothing added to HOME or the cups page: the locked tiles already say it.
- Tests: test_stakes, test_nearmiss, test_pacing (26 tests).

## v0.11.0 (2026-11-11): conditions folded into the cups
Queue item A2 (TASKS.md), from docs/PHILOSOPHY.md "Cups": one cup per planet, and the race list changes with the
class, so the same cup gets harder in character as well as speed. Built and tested, not yet seen in game.
- **Cups:** JAKKU, LANTAANA, ANDO, CRAIT, SENTINEL CUP, four races each, always on that planet; then the GALACTIC CUP
  (the same four at every class) and the TITLE RACE. The cups page is 7 tiles, 4 + 3 at the home page's tile size
  (`CupsLayout = { cols = 4, rows = 2, w = 520, h = 350 }`), no scrolling.
- **Race lists per class** (config `races['50' / '100' / '150']`, `gp.lua K.races(cup, class)`): 50cc the classic
  forward layouts (the old planet cups, unchanged); 100cc the reverse layouts, filled up with the planet's other plain
  tracks (the Outer Rim Cup's four went here: Scrap Spiral - Jakku, Geothermal Tour - Lantaana, Dai Bendu Ascension -
  Ando, Crystal Caverns - Crait); 150cc the conditions (dawn, scorching, night, wet, snow, mines, overcast, blue
  hour, storm); 200cc races the 150cc lists (`Classes[200].raceList = '150'`). No cup at any class races the same base
  track twice (each race has `base` = the title without its "(...)", and `cond` = its conditions). 59 distinct events;
  four of them new to the mod, read from the events dump (12-car TeamRace, Vehicle.Standard): Moro Kehn Tunnels
  reversed, Dhunkri River Circuit (clear), Ice Field Circuit reversed, Monastery Mountains reversed.
- **No longer raced** (were in the remix / conditions cups): The War Fields (scorching), Debris Dunes (reverse,
  scorching), Griffin's Flight (wet), Moro Kehn Tunnels (night), The Pyroducts (wet), Ahlren Jungle Speedway (night),
  Ice Field Circuit (reverse, snow), Monastery Mountains (reverse, snow), Vonium Pipeline (night), Crimson Mines
  (mines), Crimson Mines (reverse, mines), Salt Circle (mines). A planet has only four slots at 150cc.
- **Conditions shown before Select:** the cup tile's second line names the class's conditions ("Dawn, scorching",
  "Night, snow", "Mines, night"...), the focused cup's info starts with "Conditions: ..." and each race line's title
  carries them ("MONASTERY MOUNTAINS (SNOW)"), so the tune-up choice is made knowing the cup.
- **Unlocks:** the Galactic Cup opens at a class with a trophy (any colour; gold with `Unlock = 'gold'`) in all five
  planet cups at that class (was gold); the title race with a trophy in the Galactic Cup at that class (was a trophy
  in all five planet cups). The cup result says "UNLOCKED: TITLE RACE at 100cc". Classes unchanged.
- **Gone:** the Outer Rim Cup, the five remix cups, the five conditions cups, `Progression.RemixClass`,
  `P.remixClass` / `P.remixOpen` / `P.conditionsOpen`, the bonus / remix / conditions flags (the Galactic Cup is
  `final = true`), art.lua's remix (dark scene) and conditions (other vehicle) posters.
- **Save:** at the first load the best finishes, perfect cups and final standings of the removed cups (`*_remix`,
  `*_cond`, `outerrim`) are dropped, with one log line: `[cups] dropped from the save (remix, conditions and Outer Rim
  cups are gone; records kept): best 100 crait_remix, best 100 jakku_remix`. **What the owner loses:** the 100cc
  Crait Remix gold and the Jakku Remix 4th place (and any other remix / conditions / Outer Rim trophies). Track
  records stay (they are kept per event path). A planet cup's best at a class now means that class's list (the
  planet-cup trophies already in the save were won on the 50cc list and are kept as they are).
- Counts: "N / M GOLD" and the class info count 6 cups (5 planets + Galactic).
- Tests: test_cups (new: the save migration with the owner's save shape, logged once, records kept; 7 tiles at every
  class; the conditions on the tiles; Jakku at 100cc reversed; Ando at 200cc on the 150cc list); test_config (6 cups,
  four races at every class, no base track twice, same planet, 200cc = 150cc, the Outer Rim tracks in the 100cc lists,
  base / cond, cupConditions); test_prog (the Galactic Cup and title-race gates, Unlock = gold, newly open); test_unlocks
  (the fifth trophy opens 150cc and the Galactic Cup; a Galactic Cup win opens the title race); test_flow (7 tiles, the
  layout, the 150cc launches); test_remix removed; test_art, test_convert, test_records, test_trophies, test_gaps,
  test_vehicles, test_ai updated. 23 tests, 557 checks.

## v0.10.0 (2026-11-11): gap log, 200cc as an extra
Queue item A1 (TASKS.md), from docs/PHILOSOPHY.md: put a number next to "did my clean race pull away?", and make
200cc the optional extra. Built and tested, not yet seen in game. The rubber band numbers are unchanged.
- **Gap log:** after every race one line in grandprix.log right after RESULT, e.g. `[gaps] THE WAR FIELDS 150cc: you
  3rd 1:42.50; winner Biddy Blas -1.50 s; next ahead Kestar Bool -0.50 s; next behind Katja Mox +0.50 s; field
  spread 1st-11th 9.0 s` (1st: `next behind X +1.84 s; winner -`; you DNF: the winner's time and the spread).
  Every racer's `EventFinishTime` is read from its RaceEventComponent in the field read race.lua already does
  every 2 s (once per racer, after it finishes; no new lookups or sweeps). Racers with no time (DNF, or not yet
  finished when the race world went) are skipped. The most recent race's numbers are in the save as `last.gaps`
  (`gp.lua K.gaps` / `K.gapsLine`).
- **200cc, the extra:** parts 9 (was 10), the 150cc AI profile (was pressure 1.2, catch-up x1.15, perfect start 90),
  blurb "The extra: raw speed for the brave". Nothing was gated on 200cc results (prog.lua: remix cups open from
  150cc, the title race and bonus cups go by their own class); now a test says so. Still harsher than 150cc:
  ability level 3 and the AI tiers' extra tune-ups at 200cc (left as they were).
- Tests: test_gaps (new: you 1st, 2nd, 4th, last, DNF; a DNF bot and a 0 time skipped; a race read through
  race.lua, the line right after RESULT, `last.gaps` saved), test_prog (200cc opens nothing elsewhere), test_config
  (parts 0 / 3 / 7 / 9, the 200cc profile = 150cc's, the blurb), test_vehicles (200cc at 9), test_ai (pressures;
  the catch-up and perfect-start levers tested on a stand-in profile). world.lua: `W.botFinish` (a bot's place and
  time). 23 tests, 528 checks.

## v0.9.0 (2026-11-10): cups are not resumable
Owner's rule: like Mario Kart, leaving a Grand Prix loses it. A cup exists only from its first race's launch to the
standings screen of its last race; quitting mid-cup just loses that cup's progress. (Not yet seen in game.)
- **Gone:** the CONTINUE CUP and QUIT CUP tiles on HOME (HOME = 50CC, 100CC, 150CC, 200CC, GARAGE, RESET PROGRESS,
  always); the IN PROGRESS cup tile, the "finish or quit the cup first" block on the other cups and on the title
  race, and the "Select launches the next race" path on the cups page; LATER on the standings; the garage's racer
  lock while a cup runs (`RC.locked`: the garage can't be reached mid-cup any more); "and the cup in progress" in
  the RESET PROGRESS question.
- **Standings after races 1-3:** NEXT RACE only. B there asks "Leave the cup? Your points are lost." - YES first
  (forfeits, goes HOME), NO second (back to the standings). After race 4 nothing changed (CONTINUE / B go to the
  cups). The menu key (F6) while on the standings closes the page and reopens the standings, not HOME.
- **Boot:** a cup found in the save when the mod loads (the game was restarted or crashed mid-cup) is dropped:
  `[cup] jakku 150cc dropped at boot (race 3 of 4): cups cannot be resumed` (`K.drop`). The run still lives in the
  save between the races of a cup (race.lua / racer.lua read it across a race load); only the resume paths went.
  Safety net: a run still alive when HOME is shown (a next race that never loaded lands on the cups page; B from
  there) is dropped the same way, `... dropped at the home screen ...`; `K.startCup` forfeits any such leftover.
- Kept: quitting a race from the game's pause menu is a DNF and the cup goes on (test_vehicles); the cup's own copy
  of vehicle / picks / tune-ups (`run.vehicle` / `run.picks` / `run.mods`, race.lua launches with them); the save
  conversion still moves an old run's class up (it is then dropped at boot, logged under the new class).
- Tests: test_flow (NEXT RACE only; B -> NO; F6 twice keeps the cup; B after race 4 = the cups), test_vehicles (B ->
  YES forfeits; a timed-out launch's leftover dropped at HOME), test_trophies / test_unlocks / test_convert /
  test_oldpicks (a run in the save dropped at boot, logged; the Sentinel cup now raced whole), test_racer (no lock),
  test_mods / test_ai (leave the cup through B -> YES). 22 tests, 511 checks.

## v0.8.1 (2026-11-10): v0.8 seen in game; the title race comes back to the menu
- Seen in game (test copy of the owner's save, TestAutopilot driving): HOME, the 18-tile CUPS page (5 x 4, no
  scrolling, the focused cup's four races and records in the info lines, steady height), GARAGE (vehicle, racer,
  abilities and tune-ups cycle in place), a 150cc cup race (AI config written `MaxAiSlowdownScale 0.75 -> 1,
  ForcedErrorChance 15 -> 7.5` and put back; pressure applied to the one shared tune object and put back; racer swap
  to Kestar Bool and Shade put back 10 s in; tune-ups in the launch build, 64 bot slots cleared; 3rd, NEW RECORD
  1:48.63, top speed 653 kph at parts 7), the standings with the NEW RECORD line, and the title race (won, result
  screen, CHAMPION badge, "Champion: YOU").
- **Fix:** the Stadium Showdown's EventCompleteCinematicChain is the campaign's Act 2 victory scene: outside the
  campaign the win led to a black screen (Streamline skipped the cutscene, then nothing). The title race now takes
  that chain and the failed-race chain off the event at launch (memory only, originals' paths in the save as
  `titleRestore`) and puts them back at the menu or the next start. Seen: `story cinematics taken off ... / put back
  (main menu): 2`, the game's own results, our result screen.
- TestAutopilot v1.4 (separate repo): puts Autopilot into your race copy's slot 1 while the race loads, since the
  Grand Prix writes the launch build's ability slots at launch.
- Not seen: the HUD / results name while racing as another pilot (the log shows the swap and the put-back); a cup
  with tune-ups the AI doesn't share (the "cleared from your race copy" path); conditions cup events launching.

## v0.8.0 (2026-11-10): the research round built - two-level menu, title race, your racer, AI profiles, records, tune-ups, conditions cups (NOT yet seen in game)
Built from the research doc (docs/research-2026-11-10.md) by five parallel subagents in worktrees plus the
integrator; every piece has tests against the fake game; nothing has been checked in the real game yet (the owner was
playing when the checks were due). First v0.8 load: a v0.6/v0.7 save's catalogue mod keys are dropped (logged).
- **Two-level menu** (owner's rules: never more than two deep, no words you don't need, no scrolling). HOME: the cup
  in progress (CONTINUE CUP launches its next race; QUIT CUP), the four classes (badge: golds, desc: intro line and
  the class champion), GARAGE, RESET PROGRESS. No EXIT (B leaves the tab). CUPS: every cup of a class on one page
  (5 x 4 grid of smaller tiles; `spec.layout` in ui.lua): planet cups, remix cups, conditions cups, the bonus cups
  and the TITLE RACE. Focusing a cup shows its four races with planet, kind, laps and your records in the info
  lines; Select starts the cup (the first race launches straight away) or launches the next race of the cup in
  progress. No cup page, no BACK. GARAGE: VEHICLE, RACER, ABILITY 1-4, TUNE-UP 1-2 tiles; Select cycles the option
  in place (no pick screens, no DONE). The standings screen is unchanged (NEW RECORD / PERFECT CUP lines added).
- **Title race** (`title.lua`): 1 v 1 against the class champion at the end of each class - the game's Stadium
  Showdown against Kestar Bool (6 laps; he copies your build, so he scales with the class). Opens with a trophy in
  every planet cup at the class (prog.lua). A win makes you the class champion (saved `titles[class]`, badge
  CHAMPION, "Champion: YOU" on the class tile); a loss can be run again. Never part of a cup, no points. The class
  leader as the opponent (a two-car grid on a normal event) is not built: needs an in-game check first.
- **Your racer** (`racer.lua`, config `Racers`): the RACER tile cycles the game's 14 named pilots (Shade = the game's
  own, first); at launch `CharacterList.Player` is swapped to your pick (an opponent you pick is swapped out of the
  field for Shade), put back 10 s into the race and at the menu (the save keeps what to put back). Locked while a
  cup is in progress.
- **AI profile per class** (`ai.lua`, config `AI`): the rubber band pressure per class (-1 Cadet at 50cc, 0 at
  100cc, 0.5 at 150cc, 1.2 at 200cc; FreeRace's presets, blended) written to every racer's tune data while the race
  loads and put back at the menu (the Underground's proven mechanism); plus "honest pacing" from 150cc: the AI config
  asset's MaxAiSlowdownScale 0.75 -> 1 (the AI no longer slows down when ahead), forced errors halved, at 200cc
  catch-up x1.15 and perfect starts 90%, written at launch and put back with the build (crash-safe through the
  save). `AI.Adjust` = a hidden dial on every class; `AI.Enabled = false` switches it off.
- **Records and marks** (gp.lua): best race time and best lap per track and class (`records`, read from your
  RaceEventComponent on the existing 2 s sweep), NEW RECORD / NEW BEST LAP on the standings, perfect cups
  (`perfect`), every cup's final points (`standings`), the class champion = most points across the planet cups
  (`K.champion`), golds count on the class tile. RESET PROGRESS clears them too.
- **Tune-ups** (modsel.lua, config `TuneUps`): the mods trimmed to twelve named packages (HEAT SHIELD, ARMOUR, ICE
  COLD, REDLINER, RAMJET RIDER, AFTERBURNER, BRAWLER, SURVIVOR, SLIPSTREAMER, FIREBUG, ENGINEER, TENACIOUS), two
  affixes each, protection and plain playstyle only. Slots 0 / 1 / 2 / 2 by class, picked in place. The AI's Elite
  (Sen Fira, Biddy Blas, Lyren Shok) race with HEAT SHIELD from 150cc and HEAT SHIELD + ARMOUR at 200cc, the
  Challenger (Goli & 02-R0) with HEAT SHIELD at 200cc: the launch build carries yours plus theirs, at load each
  racer's race copy (yours included) loses what isn't theirs (`loadout.lua`). `TuneUps.AIExtra = false` = yours only.
- **Classes and gates** (config / prog.lua): parts 0 / 3 / 7 / 10 (100cc and 150cc were 50 kph apart, 200cc 120 kph
  above); one intro line per class; the remix cups (and the title race) open from 150cc, 200cc gates nothing.
- **Conditions cups**: five more cups (night / wet / snow / scorching / mines line-ups from the game's unused
  12-car events, plus Dhunkri River Circuit and Mineral Loop, never raced before), one per planet, opened by gold
  in that planet's cup at the class. Laps per race in the config; planet names and flavour lines (`Planets`).
- Tests: every flow test rewritten for the new screens; new test_records, test_ai, test_ai_restore, test_racer,
  test_title, test_config. `autotest/race.sh` drives a Grand Prix race with TestAutopilot.

## v0.7.1 (2026-11-10): the art fitted to the tiles (seen in game)
- The tile draws its art through the game's own material, which zooms by `ImageScale` (default 0.44, made for the
  game's big tiles). Ours showed only the top-left corner. Now each texture is scaled to just cover the tile, and
  tall posters are moved up to their vehicle art. The art is no longer set on the image directly (that skipped the
  material).
- Trophy medals: moved to the top-right corner (they sat on the title) and tinted gold / silver / bronze (the tile
  draws icons as one-colour shapes).
- MODS tile: the darker Afterburner picture; white text was hard to read on the bright desert one when focused.
- Seen in game: classes, cups (medals, posters, remix scenes), cup page, mods, mod groups, cup in progress.
  Not seen yet: the standings / cup result backdrop (needs a race).

## v0.7.0 (2026-11-10): menu art (owner: "I like all of those, just go for it")
- Every picture is one of the game's own textures, loaded by path (`art.lua`; research page and the extractor in
  `tools/art/`).
- Class tiles: the game's four difficulty banners, sage / gold / blue / red for 50 / 100 / 150 / 200cc.
- Cup tiles: each planet's Arcade poster in your vehicle's version (falls back when the game has none: Crait has
  no car poster, Sentinel only a car one). Remix cups show the planet's dark full-colour scene instead. Outer Rim
  and Galactic use the BGL and WHP art. NEXT RACE, START CUP, CONTINUE CUP and GO TO IT show the cup's art.
- Trophies: a won cup shows its gold / silver / bronze medal in the tile's icon slot (the text badge stays); the
  cup result's CONTINUE tile shows the medal won.
- ABILITIES and MODS tiles, the nine mod groups and the mods in them: the game's racer-style pictures.
- VEHICLE tile: the car / bike / skimmer main-menu tile.
- Standings and cup result: a dark backdrop behind the points table.
- One screen looks each picture up once (lookups are full sweeps in this game).

## v0.6.3 (2026-11-10): remix cups seen in game
- The Sentinel Remix's last race is Corrosion Hypersphere (its real name, read from the game's track data). The
  Ando Remix's short circuit has no name in the game (a developer label only); it is a finished, lit 5-lap ice
  circuit with a full field, so it stays as "ANDO SHORT CIRCUIT".
- In game: the five remix cups show and open at 200cc with the unlock earned; the Sentinel Remix's first race
  launched (Sentinel Lakes forward, overcast, 12 racers, mods yours only).

## v0.6.2 (2026-11-10): remix cups
- Five remix cups (owner): the planet cups reversed where the game has a reverse layout, else night / wet / snow /
  mines / scorching versions, else another track from the planet (Scrap Spiral, an Ando short circuit, a Sentinel
  special circuit in a storm). Every event read in game first: normal 12-car team races, any vehicle.
- Open after a trophy in all five planet cups at the top class (200cc), then at every open class; the cup result
  says "UNLOCKED: REMIX CUPS". Own trophies; remix cups don't count as planet cups for the class unlocks.
- Tests: `test_remix`; `test_prog` +6.

## v0.6.1 (2026-11-10): full mod descriptions
- Seen in game: tile descriptions are cut after two lines ("Choked no longer cancels active Ramjet..."). The MODS and
  mod list screens now have a gold info line under the header with the focused mod's full name and description
  (`spec.info` / `item.info` in ui.lua, set on every focus change).

## v0.6.0 (2026-11-10): mods (the planned v0.4)
- MODS on the cup screen, next to ABILITIES: 2 / 3 / 4 slots at 100 / 150 / 200cc, none at 50cc (pure driving).
  Slot -> group -> mod; one mod per effect; REMOVE empties a slot. Kept until you change them; a cup keeps its own copy.
- 105 mods in 9 groups, generated from the in-game recon (`tools/gen_mods.py` -> `Scripts/mods.lua`). Owner's rule:
  mods change how you race, not how fast - protections / rule-changers and playstyle mods only, no pure-power or
  podracer ones; the 23 big-payoff ("check") ones kept; every mod at its top step.
- At launch your mods go into the launch build's `Affixes` (the build's own list saved first, put back at the menu,
  also after a crash). The AI copies them at load; loadout.lua clears them from every bot's race copy then, so the
  AI races without mods.
- Tests: `test_modsel`, `test_mods`.

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
