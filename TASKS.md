# Work plan: Galactic Grand Prix

Design: DESIGN.md. Shared playbook and house rules: ~/Projects/swgr-underground/AUTOMATION.md.
One git tag per chunk; push after each tag.

## Overnight queue for Claude (drafted 2026-11-10, to start after 1:10 am)
Kickoff prompt: "Work through the overnight queue in TASKS.md." Rules for the run: AUTOMATION.md §3 first (if the
game is running and Claude didn't start it, no game work at all, code only); back up the owner's save before any game
session and restore it after (md5 check); the code chunks go in order, one worktree each, merged and tagged before the
next starts (they all touch main.lua and config.lua); game sessions one at a time; push after each tag.

**A. Code and tests, no game needed**
1. [x] v0.10 code: the gap log after each race; 200cc at parts 9 with the 150cc AI profile, gated on nothing. Tag
   v0.10.0. The rubber band numbers stay as they are until B2 and the owner's play. (Built 2026-11-11, branch
   worktree-agent-a055e2119ffd4ab7f; see CHANGELOG v0.10.0.)
2. [x] v0.11 conditions folded into the cups: the whole section except its in-game line. Tag v0.11.0. (Built
   2026-11-11; see CHANGELOG v0.11.0.)
3. [x] v0.12 stakes and near-miss lines on the standings; the unlock pacing check on a fresh save (after v0.11, since
   it changes the unlocks). Tag v0.12.0. (Built 2026-11-11; see CHANGELOG v0.12.0.)
4. [x] v0.13 the rival rule and the standings call-out (not the title-race spike). Tag v0.13.0. (Built 2026-11-11;
   see CHANGELOG v0.13.0.)
5. [x] The main-menu poll made cheaper (section 4, one sweep 5x a second at the menu). (Built 2026-11-11 as v0.13.1;
   see CHANGELOG v0.13.1.)
6. [x] (Built 2026-11-11 as v0.15.0, see CHANGELOG: the vehicle type and build follow the racer, no VEHICLE tile,
   Kestar locked until the 150cc title (skipped by Select, named in the RACER info line), old saves' vehicle pick
   dropped. **Still to do: the racer's own look / livery preset**, unproven in game - B7; TODO in racer.lua and
   DESIGN.md §13. Not yet seen in game.)
   Racer = vehicle build (after B7 proves it, and after v0.11): picking a racer gives you their own vehicle and
   looks; VEHICLE leaves the garage; Shade drives the base landspeeder (no bike / skimmer choice, owner
   2026-11-10); each racer tile names the vehicle type; class parts go on the racer's build and are put back after.
   Kestar Bool is locked until you win the 150cc title race (`titles['150'].won`; the tile says how to unlock him);
   (2026-11-11 research: neither is a podracer; Kestar drives a landspeeder, Sebulba a skim speeder.) Old saves: the vehicle pick is
   dropped, a Shade pick stays Shade.
7. [x] Tile text that doesn't fit (owner 2026-11-10: can't fully read the tune-up tiles in the garage). Go through
   every screen and make every tile's title, badge and description fit: shorter wording in config, a length limit
   per tile size checked by a test (every string the menus can show, at every tile size), and long text (the
   tune-up's effect line) moved to the focused tile's info area instead of the tile. Check with B8.
   Tag as its own version. (Built 2026-11-11 as v0.14.0, see CHANGELOG; the budgets are estimates from the v0.8
   screenshots until B8 checks them.)

**B. In game with TestAutopilot (game closed, test save, owner's save restored after)**
(2026-11-11 overnight: not run, the screen was locked. Morning session with the owner's OK: see each item.)
(2026-11-11 overnight: not run. The screen was locked, so no keys or screenshots; only B5 is done, from the
owner's own play, and the offline half of B7.)
1. [x] (2026-11-11 morning, v0.14.1: one NEXT RACE tile, the stakes line; B -> "Leave the cup? Your points are
   lost." YES first; NO back to the standings; YES forfeits to HOME with "Cup abandoned"; game killed at the
   race-2 standings -> `[cup] lantaana 100cc dropped at boot (race 3 of 4)`, HOME without cup tiles. The pause-menu
   quit was not tried: the pause menu's only ways out are EXIT TO MAIN MENU (locked) and ABANDON TOUR.) v0.9 check: the standings' one tile, B -> the question (keyboard; the pad is the owner's), a restart mid-cup logs
   the drop and HOME shows no cup, a pause-menu quit still moves the cup on.
2. (2026-11-11: autopilot races at every class, gap log working: it won ALL six by 3-13 s - 50cc +12.9, 100cc
   +4.9 / +3.3 / +11.9 / +7.6, 150cc +11.2 / +9.2, 200cc +12.2. The game's Autopilot outdrives the AI at every
   class, so it can't stand in for the owner: the profile numbers need the owner's own races with the gap log. The
   lowered-catch-up run was skipped for that reason.) Rubber band research: one autopilot race per class with the gap log, plus one with MaxAiCatchupScale lowered;
   write what each AI field does to a lead into DESIGN.md §4 and propose profile numbers (not applied).
3. [x] (2026-11-11 afternoon: Dhunkri River Circuit clear launches and finishes (100cc Lantaana race 3).)
   (2026-11-11: the four never-launched events all launch and finish: Moro Kehn reversed, Ice Field reversed,
   Monastery Mountains reversed (100cc), plus Geothermal Tour; also Ice Field night (150/200cc), The War Fields
   dawn (150cc), Ice Field (50cc). Dhunkri River Circuit in the clear not yet raced. The rest were checked against
   the dump only.) v0.11 events: every new race in every class launches and finishes (a long run: about 60 events; sprints and the
   shortest lap counts first, stop at the first failure).
4. [x] (2026-11-11: as Kestar Bool at 150cc. The HUD shows no name at all; the game's results list shows YOUR
   player name ("Dwayne", the Steam name), not the pilot's; our standings say YOU. The pilot's figure and voice
   change.) Racing as another pilot: screenshots of the HUD and results name with Kestar Bool picked.
5. [x] (owner's own races, 2026-11-10 23:12: `you=REDLINER+ARMOUR Elite=HEAT SHIELD (...) (240 bot slots cleared, 8
   cleared from your race copy)`, no FAILED) Tune-ups the Elite don't share: the "cleared from your copy" log path.
6. [x] (2026-11-11, tools/recon/RaceFlowSpike, log raceflow-b6-20261111.log: **works.** Before LaunchQuickRace at the
   main menu: the event's `GridMakeup` set to 2 entrants and `CharacterList.Opponents` cut to the one racer -> a 1 v 1
   on The War Fields against Sen Fira (HUD POS x/2), finished, both put back at the menu. Moving the racer to the front
   of the list without cutting it gave a 2-car grid but a different opponent (Biddy Blas): the cut is needed. The
   third mode (list cut, grid untouched) not run: high crash risk, not needed.)
   Spike: a two-car grid on a normal event (the rival / class leader as title-race opponent). Report only.
   (RaceFlowSpike built 2026-11-11, not yet run: tools/recon/RaceFlowSpike, F10 at the main menu, three presses:
   grid make-up summed to 2 + Sen Fira to Opponents[1]; + Opponents trimmed to her; Opponents only. Logs the
   Showdown's make-up for reference and the grid at load (RecipeState.Racers[]). Install, key presses, risks: its
   README.md.)
7. [x] (2026-11-11 afternoon, LookSpike v2, log tools/recon/LookSpike/lookspike-v2-20261111.log: **the look already comes
   with the racer swap.** The race's recipe list gives your entry the racer's own preset before anything is written
   (Nik Skandaro -> PRE_Car_Hammerhead_QuietStrength), and the car reads "Hammerhead Quiet Strength" through the race
   in 3 races; as Griff Halloran the skim speeder is dark with red trim. Route B found no look component on the car
   (0 components; the 50 found belong to cinematic static vehicles). Route A (FreeRace's Server_UpdateVehicleRecipe)
   not tried: it can write into the game's own saved recipes. Screenshots autotest/shots/look1-a/b.png for the owner.)
   (race done 2026-11-11 with tools/recon/LookSpike, log lookspike-20261111.log: PreferredVehicleType read in
   game matches the table in docs/racer-vehicles exactly (Biddy, Sen, Katja, Malis = bike; Kestar, Shade, Ary, Nik,
   Soren = car; the rest skimmer). As Biddy on the bike at 150cc: parts 7 on VBD_Bike_Base, won by 9.2 s.
   PRE_Bike_Sidewinder_Rager loads (recipe "Sidewinder Rager"); Client_SetOverrideVehicleRecipe sent without
   error, but the pawn's CstCustomisationComponent wasn't found (K2_GetComponentsByClass), so whether the look
   changed is unproven; screenshot autotest/shots/g-biddy.png for the owner to judge. Next: find the look component
   another way, or set the recipe while the race loads (FreeRace's Server_UpdateVehicleRecipe).)
   (LookSpike v2 built 2026-11-11, not yet run: four routes, one per race, as Nik Skandaro on the landspeeder with
   PRE_Car_Hammerhead_QuietStrength: C = the race recipe's Racers[] entry, B = the car's look component found
   another way + SetActiveVehicleRecipeFromPreset, A = Server_UpdateVehicleRecipe with a struct built from the
   preset, O = the override call at load. Install, log lines and crash risk: tools/recon/LookSpike/README.md.)
   (offline half done 2026-11-11: docs/racer-vehicles-2026-11-11.md. Every racer has one preset, none a
   podracer: Kestar = landspeeder PRE_Car_Antagonist, Sebulba = skimmer. The race itself is still to do.)
   Spike for A6 (owner agreed 2026-11-10): find where each racer's own vehicle lives (racer def, AI build, livery)
   in the dumps, then one race as Biddy Blas in his own vehicle with the class parts set on that build and put back
   after (log + screenshot). Report what launches, what the looks are, and what Kestar / Sebulba fly.
8. (2026-11-11, v0.14.1: HOME, the cups pages at 50/100/150/200cc, the garage with a tune-up and the racer
   focused, the standings, the leave question - all text fits now. Still hard to read: the white name on a
   FOCUSED tile with bright art (50CC, 100CC, Kestar's portrait on RACER). Fixed in v0.14.2: the redundant "Yes" /
   "Cancel" under the confirm tiles and the garage header's stale cup wording. Title result not shot.)
   Screenshots of every menu screen (HOME, CUPS at each class, GARAGE with every tune-up and racer focused,
   standings, title result, the confirms) before and after A7; crop each tile and list any text cut off or
   overflowing. Hand the owner the before / after pair.

9. [x] (2026-11-11, tools/recon/RaceFlowSpike, log raceflow-b9-20261111.log: **both parts work.** (a) A text panel added
   to the game's results screen (`WBP_SimpleRaceResultsScreen_C`, canvas `Default_Results` next to CONTINUE) shows
   over it (screenshot autotest/shots/b9-panel.png). (b) Route A: write the next event into the race recipe's active
   stage (`AuthoredEvent`, `TrackDef`, `LapCount`, `trackConditions`) on both the EventRecipeSubsystem's recipe and the
   race state's copy, then `BP_RacingGameMode_C:RequestResetRace()` -> a new race world in 0.5 s on Fallen Empire
   (6 laps), raced and finished, put back at the menu. Only tried on the same planet (The War Fields -> Fallen
   Empire); a different planet's track is the next check. Route B (LaunchQuickRace from the race world) not run:
   not needed, high crash risk.)
   Spike (owner 2026-11-11): the standings at the end of the race, then straight into the next race with no main
   menu. Two parts: (a) draw the standings over the game's results screen in the race world; (b) start the next race
   from there: first try swapping the event in the race's recipe (UEventRecipeInstance.RecipeState /
   EventRecipeState) before the pause menu's restart, then other routes. Fallback if (b) fails: after the standings,
   the next race launches by itself after a short countdown, the menu hidden under the cover. Report only.
   Needs the desktop to Claude alone (the owner away).
   (RaceFlowSpike built 2026-11-11, not yet run: tools/recon/RaceFlowSpike, F9 on the results screen: (a) a text
   panel added to WBP_SimpleRaceResultsScreen_C's CONTINUE canvas; (b) route A = the next event written into
   EventRecipeSubsystem.ActiveRecipe.recipe.EventStages[ActiveStage] (AuthoredEvent, TrackDef, LapCount,
   trackConditions) and the race state's copy, then RacingGameMode:RequestResetRace (or the pause menu's RETRY
   RACE event); route B = LaunchQuickRace on the default FrontEndGameMode (riskiest). Install, key presses, risks:
   its README.md.)

10. (2026-11-11, two batches, 36 races: docs/ai-study-2026-11-11.md, data in docs/data/. Races read pacing from
   RP_Default (slowdown 0.3), not only DA_AIConfig; with the band off the bots are as fast as a clean autopilot or
   faster, and steady (best bot within 1 s across 4 runs). Proposal in the doc: catch-up off everywhere, mercy
   slowdown 0.5 / 0.7 / 0.85 / 0.85 by class, errors off from 100cc. Waiting on the owner's OK and races.)
   AI tuning study (owner 2026-11-11: "run a bunch of races with autopilot at different CC's ... tune the AI so it's
   challenging and consistent and we can lower the rubber band value as much as possible"). The autopilot is a
   fixed benchmark driver (it beats today's AI by 3-13 s); the owner's records map its pace to theirs (The War
   Fields 150cc: owner 1:42.39, autopilot 1:43.35 on the dawn version). Batches of races on a few fixed tracks per
   class, one AI setting changed at a time (pressure, catch-up, slowdown, forced errors, power level), gap log per
   race; plan in docs/ai-tuning-research-2026-11-11.md. Output: a table of gap vs setting and proposed profiles
   with as little catch-up as possible. Needs the desktop to Claude alone.
   v0.16.0: study mode built (study.lua jobs -> single races with a per-job AI profile, `[study]` log lines and
   study_results.csv; DESIGN.md §14). Not yet run in game.
   v0.16.1: Phase 0 logging built (`[aiset]` read-back; pacing written to RP_Default / RP_Honest too). Not yet run in game.

11. [x] (2026-11-11 in game: opened HOME 1 s after the tab was added, B went back to the game's menu, no reopen.
   The pad's B is the owner's to check.) (Built 2026-11-11 as v0.17.0, see CHANGELOG; not yet seen in game: check the tab opens on HOME at the first
   menu, stays up, B goes back, nothing reopens after a race.) Boot straight into the Grand Prix (owner 2026-11-11: "i want the game to launch and go directly to the grand
   prix menu, pressing b would still back out to the main menu"). At the first main menu after launch, open the
   GRAND PRIX tab by itself (HOME page). B on HOME goes back to the game's main menu as today. Only once per launch:
   coming back from a race or backing out must not reopen it. A config switch (`BootToGrandPrix`, on by default).
   Never pick the MULTIPLAYER tab on the way. Check the boot-drop of an old cup run still happens first.

12. [x] (2026-11-11: docs/menu-review-2026-11-11.md, 11 findings ranked; the owner picks what to build.)
   Menu review, whole-mod (owner 2026-11-11: "go through all the menus in grand prix and think holistically about
   them. How they are laid out, how engaging they are to use, think about what would make them better or more
   engaging"). Walk every screen in order (HOME, CUPS at each class, GARAGE, standings, leave question, title race,
   results, RESET) with screenshots, then judge them as one flow, not tile by tile: what you see first, how many
   presses to the next race, what each screen makes you want to do, where the stakes / rival / near misses / goals
   (docs/PHILOSOPHY.md) show or are missing, consistency of wording, art and layout between screens. Keep the
   owner's menu rules: never more than two menus deep, no words you don't need, never scroll, simplicity.
   Output: docs/menu-review-<date>.md with findings and a ranked list of proposals (mockups where useful) for the
   owner to pick from. Report only; nothing built until the owner chooses. Needs the desktop to Claude alone.

**C. Only the owner can do these (left for you)**
- The v0.10 rubber band feel at 100cc and 150cc (decides the profile numbers from B2).
- The pad: B on the standings, the v0.8 menus with a controller.
- Do AI racers fire their abilities, Shields included (R7)? Does the menu flash still show? Do the ability picks and
  badges read clearly?
- A name for the Ando short track.
- The v1.0 pass: every cup at every class.

## Next (owner 2026-11-11 evening: "make sure these are added to the task list, then go ahead")
From the afternoon's findings (docs/ai-study-2026-11-11.md, docs/menu-review-2026-11-11.md, B6 / B9 spikes), in order:
1. [x] (Built 2026-11-11 as v0.18.0, installed; waiting on the owner's two cups.) **v0.18 AI profiles from the study** (config only): catch-up off at every class (MaxAiCatchupScale 1.0, all three
   pacing assets), the mercy slowdown shrinking by class (50cc 0.5, 100cc 0.7, 150cc 0.85, 200cc 0.85; game default
   0.3), speed matching off, forced errors off from 100cc (50cc keeps them). Then the owner races one cup at 100cc and
   one at 150cc; read their `[gaps]` lines. Target: a good race wins by a few seconds, a messy one loses, the best bot
   steady from race to race.
2. [x] (2026-11-11 18:08 in game, v0.19.1: a whole 150cc Jakku cup chained: the standings panel on the game's results
   screen (opaque, NEXT RACE left of CONTINUE), N -> the next race launched from the menu under the cover 5-6 s after
   the results, 12 racers, no standings page between races; cup result at the menu, put-backs once. Pad A on NEXT
   RACE is the owner's to check.)
   (2026-11-11 17:35, v0.19.0 in game: the panel showed, but NEXT RACE by RequestResetRace to another layout
   (Mastiff/Loop_A -> P2P_A) hung on PLEASE WAIT for good - the reset only re-uses the loaded map; the game's table
   showed through the panel; NEXT RACE overlapped CONTINUE. **v0.19.1** (built, tested, NOT yet seen in game): NEXT
   RACE now goes via the main menu under the cover and launches the next race by itself (every cup); the reset route
   only with `ChainRaces.Reset = true` and the same layout folder, with a 20 s watchdog; the panel opaque with the
   game's table hidden; the buttons side by side. In-game check list: CHANGELOG v0.19.1 / the v0.19.1 report. The
   v0.19.0 list below is superseded where it says reset.)
   (Built 2026-11-11 as v0.19.0, see CHANGELOG / DESIGN.md §15; **not yet seen in game**. Check in game, in
   order: the panel and NEXT RACE on race 1's results screen (`[chain] panel added`, screenshot); NEXT RACE with the
   pad's A and with N (`[chain] NEXT RACE pressed`); race 2 loads with the right track, laps and conditions (`[chain]
   new race world ... EVT_MAS_P2P_FWD`), a layout change on one planet (Loop_A -> P2P_A) included; your racer, parts,
   abilities, the AI's kits and tune-ups in race 2 (`[racer] racing as`, `[loadout] ..., 11 racers`, `[aiset] race
   class=`); a whole Jakku cup to the cup result with ONE put-back (`build put back (main menu)` once); CONTINUE on
   the panel -> the standings page at the menu, B there leaves the cup; does the game go to the menu by itself ~7 s
   after the results (then `[chain] the results went to the main menu before NEXT RACE`); the Galactic Cup keeps the
   menu (`[chain] not chaining: the next race is on another planet`).) **Cups without the main menu** (B9 proven): the standings drawn over the game's results screen, NEXT RACE starts
   the next cup race from there (recipe stage swap + RequestResetRace). Planet cups stay on one planet (proven case);
   check a planet change for the Galactic Cup first, fall back to the main menu there if it fails. Put-backs (parts,
   abilities, AI, racer) must hold across chained races.
3. [ ] (Rival part built 2026-11-11 as v0.20.0, **not yet seen in game**: the rival from the first race at a class, their
   row marked RIVAL on every standings, HOME's info names them, "Champion: <bot>" gone; DESIGN.md §16. The title-race
   part (1 v 1 against the rival) waits for the owner.) **A real rival, raced in the title race** (menu review 2, B6 proven): rival picked from the first race at a class,
   their row marked on every standings; the title race a 1 v 1 on a real track against the rival (or the class leader)
   with GridMakeup 2 + Opponents cut; Kestar stays as the final boss (owner to confirm where).
4. [x] (Built 2026-11-11 as v0.20.0, **not yet seen in game**: the cup result screen (medal, PERFECT CUP, top 3, one
   what's-next line, CONTINUE on the next cup without a gold), the label strip (`TileLabelStrip`), HOME's Next: line
   and focus on the class last raced, the footer hidden on our tab (`HideFooter`), review 6-7's small ones; review 8
   (seconds on the standings) built too; 9 (per-ability art) not done. In-game check list: CHANGELOG v0.20.0 / the v0.20
   report. What the footer's C does on our page is still unknown: hiding the prompt doesn't unbind it.)
   **Menu polish pass** (menu review 1, 3, 4, 5): a proper cup result screen (big trophy, top 3, what it unlocked /
   what's next), a dark strip behind tile labels, a "Next:" goal line on HOME, check what the footer's C (Restart
   Campaign) does on our page and hide it. Then 6-9 of the review as small fixes.
Owner checks any time: the pad's B on the boot page; the racer looks (autotest/shots/look1-a/b.png, b6-2-race.png).

## Next, round 2 (owner 2026-11-11 night, after racing 50cc + 100cc; OWNER.md "Done")
1. **v0.21:** a little harder at 50 / 100cc (more of a gap to catch after a crash); CONTINUE at a cup's end -> that
   class's cups page, focus on the cup just raced; cut the rival (code, save field, standings marks, HOME line);
   the title race a 1 v 1 on a normal track vs the class leader (best bot of your last cup at that class; GridMakeup
   2 + Opponents cut, B6); Kestar = a final boss after 150cc (stadium 1 v 1 opened by the 150cc title, beating him
   unlocks him as a racer); less clutter on HOME and sub-screens (no "Next:" line); no grey see-through page
   background if text reads without it; RESET clears ALL progress incl. titles behind two "are you sure" questions;
   the Ando short track renamed on theme.
2. **Later: progress badges** on the right side of the screen showing every unlock / achievement at a glance (the
   base game has a dedicated badge screen; ours sits beside the menu), replacing goal lines.

## v0.9: cups are not resumable (owner, 2026-11-10; built, NOT yet seen in game)
Design rule (DESIGN.md §13): like Mario Kart, leaving a Grand Prix loses it. A cup exists only from its first
race's launch to the standings of its last race.
- [x] HOME loses CONTINUE CUP / QUIT CUP (always the four classes, GARAGE, RESET PROGRESS); the cups page loses the
      IN PROGRESS tile, the "finish or quit first" block and the next-race launch; the standings lose LATER.
- [x] B on the standings after races 1-3: "Leave the cup? Your points are lost." YES (first) forfeits and goes HOME,
      NO returns. After race 4 unchanged. F6 on the standings reopens the standings, not HOME.
- [x] A run in the save at boot is dropped and logged (`[cup] jakku 150cc dropped at boot (race 3 of 4): cups cannot
      be resumed`); one still alive when HOME is shown too. Quitting a race from the pause menu is still a DNF and
      the cup goes on.
- [x] The garage's racer lock while a cup runs removed (dead: the garage can't be reached mid-cup).
- [x] Tests updated and added (B -> NO / YES, F6, the boot drop, the HOME drop); 22 tests, 511 checks.
- [ ] In game: the standings' one tile and the B question (pad B through the hidden Back screen); a restart mid-cup
      logs the drop and HOME shows no cup; a pause-menu quit still moves the cup on. Tag v0.9.0 after.

## Engagement plan (owner, 2026-11-10; docs/PHILOSOPHY.md)
The why behind each chunk is in docs/PHILOSOPHY.md. Order: rubber band first (only the owner can judge it), then
the cups, then the rival. One tag per chunk.

### v0.10: rubber band per class, 200cc as an extra
- [x] Log the gaps after each race: your time against the winner's and the next car's, behind and ahead, so "did my
      clean race pull away?" has a number next to the owner's feel.
- [ ] Read what each field in the AI profile does to a lead (pressure, MaxAiSlowdownScale, MaxAiCatchupScale) on the
      dump and in one autopilot race per class; write it in DESIGN.md §4.
- [ ] Profiles: generous at 50cc (the AI waits for you), less and less up the classes; at 150cc a clean lead holds
      (catch-up lower than the game's own). Keep `AI.Adjust` as the one dial.
- [x] 200cc: parts 9 instead of 10, the 150cc AI profile, nothing gated on it (check prog.lua and the title race).
      Blurb says it is the extra. (Nothing was gated on 200cc: prog.lua's remix class is 150cc, the title race
      and bonus cups go by their own class; a test in test_prog checks it.)
- [ ] Owner plays a few cups at 100cc and 150cc and says whether a clean race shows. Retune, then tag.

### v0.11: conditions folded into the cups
- [x] Config: one race list per class for each planet cup (50 classics, 100 reverse, 150 conditions, 200 = the 150
      lists). Move the Outer Rim Cup's tracks into the planet lists. Every event used must already be in the
      events dump (12-car team race, any vehicle).
- [x] Test: no cup at any class races the same base layout twice; every cup has four races.
- [x] Remove the remix and conditions cups, their unlock rules, `Progression.RemixClass`, the conditions-cup art swap.
- [x] Galactic Cup opens with a trophy in the five planet cups at the class; the title race opens with a trophy in
      the Galactic Cup. Cups page = 7 tiles (layout to fit, no scrolling).
- [x] Save: old remix / conditions / Outer Rim trophies dropped at first load with a log line; records kept (stored
      per event).
- [x] The cup's info lines name the conditions (SCORCHING, SNOW...) so the tune-up choice is visible before Select.
- [ ] In game with the autopilot: every new event launches and finishes. Name the Ando short track (owner).

### v0.12: stakes and near misses on the standings
- [x] One stakes line after races 1-3: "2 POINTS BEHIND BIDDY BLAS, 1 RACE LEFT" / "LEADING BY 4" / "GOLD IS OUT
      OF REACH" (worked out from the points left).
- [x] Near misses after a race: "0.4 S OFF YOUR RECORD", after the cup: "1 POINT FROM GOLD". Only when close (a
      threshold in config), so they stay special.
- [x] Unlock pacing check: from a fresh save, there is always exactly one next thing to aim for; HOME or the cups
      page shows it. (test_pacing: always at least one visible LOCKED tile one step away, never more than two opened
      at once; a fresh save shows three: GALACTIC CUP at 50cc and 100cc, 150cc. Current rules pass, no change.)

### v0.13: a rival per class
- [x] Rule for the rival: the racer with the closest points to yours across the class's cups (ties: most finishes
      just ahead of you). Saved per class. (rival.lua: a closeness tally per class from each cup race's standings,
      formed at 30, switched only by a 10-point lead; DESIGN.md §13.)
- [x] Standings call the rival out ("RIVAL: SEN FIRA, AHEAD BY 3"), merged into the stakes line when it names them;
      HOME's class info names the rival next to the champion. 27 tests.
- [ ] Spike: the rival as the title-race opponent (a two-car grid on a normal event: `GridMakeup.Entries[].NumEntrants`
      + `CharacterList.Opponents`). If it fails, keep the Showdown against Kestar and name the rival in the intro.

## Waiting on the owner's playtest (v0.8.1 installed, 2026-11-10)
Things only a real play can answer. Tick them off (or note what felt wrong) as you go.
- [x] (moot in v0.8: the mods became twelve tune-ups without the "check" ones) **Mods:** which feel good, which feel too strong - the 23 "check" ones especially
      (catalogue page: https://claude.ai/artifact/4nFmiUyn62CRY21JBZRgx9).
- [x] (moot in v0.11: the remix cups were folded into the planet cups' 100cc / 150cc lists) **Remix cups:** race
      them (open at every class now). Name the Ando short track if you like (shown as "ANDO SHORT CIRCUIT" for now;
      it is in the Ando Cup at 100cc).
- [ ] **Points table after each race:** lines up and reads well; the loading-screen cover appears and goes. If it ever
      sticks or blocks input: `HideMenuFlash = false` in config.lua.
- [ ] **Unlock message:** a cup that opens something says "UNLOCKED: ..." on the result screen (gold in all five 100cc
      planet cups opens the 100cc Outer Rim cup).
- [ ] **Menu flash** between a race and the standings: still "much less noticeable"? (decides v0.7 item below)
- [ ] **Free ability pick and trophy badges:** do they read clearly?
- [ ] **AI abilities (R7):** do the AI racers fire their abilities, Shields included? Watch for it in races.

## v0.8: to see in game (built 2026-11-10 from the research; v0.8.1 checked by Claude in game, see CHANGELOG)
Research: https://claude.ai/artifact/7VSJrJnpopuMcBFQ2WyTV8 (copy docs/research-2026-11-10.md). Everything below has
tests against the fake game; the game was in use when the in-game checks were due. Install: `./deploy.sh v0.8.0`.
First load drops the old catalogue mod keys from the save (logged `[tune-ups] dropped from the save`); your trophies,
records-to-be, abilities and vehicle are kept.
- [x] (Claude, 2026-11-10; v0.9: CONTINUE / QUIT CUP are gone) **Menus:** HOME (classes, GARAGE, RESET; CONTINUE / QUIT CUP while a cup runs), the CUPS page (5 x 4 grid: do
      18 smaller tiles fit without scrolling, is the text readable, do the info lines show the four races and
      records when a cup is focused), GARAGE (Select cycles each tile). B goes back everywhere. Take screenshots.
- [x] (Claude: a 150cc Jakku race, 3rd, NEW RECORD; v0.9: no IN PROGRESS tile, no next-race launch from the page) **A cup from the cups page:** Select on a cup launches race 1 straight away; the tile says IN PROGRESS; Select
      on it launches the next race; standings unchanged; NEW RECORD line after a finished race; the class tile's
      gold count.
- [x] (Claude: all lines seen, no FAILED; the feel is yours to judge) **AI profile** (grandprix.log): at launch `[ai] class 150: pressure 0.50 ...` and `[ai] ... AI config
      (DA_AIConfig) DefaultPacingSettings.MaxAiSlowdownScale 0.75 -> 1, ForcedErrorChance 15 -> 7.5` (no FAILED);
      while loading `[ai] applied to N tune objects`; at the menu `[ai] put back ...` and `AI config put back`.
      Then the feel: at 150cc / 200cc the AI should not wait for you when you are ahead.
- [ ] (Claude: the log lines seen; the HUD / results name not seen) **Racer:** pick Kestar Bool in the garage; the HUD and results show his name; `[racer] ... CharacterList.Player
      set (was Shade)` then `Shade put back` ~10 s into the race; the standings still show YOU. Pick an opponent
      (Katja Mox): the grid has Shade instead of a second Katja.
- [ ] (Claude: HEAT SHIELD + Elite HEAT SHIELD seen in the log, 64 bot slots cleared; the 'cleared from your copy' case not seen) **Tune-ups:** 150cc with REDLINER: your passives = its two affixes only; Biddy Blas, Sen Fira, Lyren Shok carry
      Burn + Frost Protection; everyone else none (`[loadout] mods: you=... Elite=... (N bot slots cleared)`, no
      FAILED); `mods put back (main menu): VBD_Car_Base (0)` after. Unknown: whether clearing YOUR race copy at
      load really removes the AI's extras from your car (fallback `TuneUps.AIExtra = false`).
- [x] (Claude, v0.8.1: won it; the Showdown's story cinematic had to be taken off the event, see CHANGELOG) **Title race:** TITLE RACE tile (locked until a trophy in all five planet cups at the class; VS KESTAR BOOL);
      the Showdown launches with the class's parts; the result screen (win = CHAMPION, the class tile says
      "Champion: YOU"; a loss can be rerun); `TITLE RACE 100: ...` in the log. 1 v 1 field of 2 read correctly.
- [x] (moot in v0.11: folded into the planet cups' 150cc lists; their events are checked by queue item B3) **Conditions cups:** open with gold in the planet cup; every event launches (paths were checked against the
      event dump, not in game); art (the other vehicle's poster).
- [x] (Claude: 653 kph at parts 7 on The War Fields; was ~620 at parts 6) **Class spacing.**
- [ ] Later (research spikes): the class leader as the title-race opponent (two-car grid + Opponents list); (bot
      rename dropped by the owner 2026-11-11); per-racer pacing; podracer launch; the rival 1 v 1 ladder.

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
      also survives a restart; one cup at a time. (v0.9: the resume is gone - cups cannot be resumed; B on the
      standings asks and forfeits.)
- [x] Tests (`test_cup` scoring, `test_flow` a whole cup, `test_vehicles` bike / DNF / forfeit); tag v0.2.0.
- [x] In game (owner, 2026-11-09): whole Jakku Cup at 50cc, GOLD (54 points); all 12 racers read every race;
      standings and trophy screens worked.
- [x] (v0.3.8: the loading-screen cover hides it; owner to confirm it stays hidden) the ~3 s main-menu flash before the standings.

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
- [x] ~~Put the save's race count back~~ (moot: progress was reset 2026-11-10).

- [x] v0.3.9 (2026-11-10): real cause found - every lookup by path is a full sweep in this game (UE4SS has no object
      hash tables). No lookups while racing; one sweep every 2 s. In game: check the PERF "our tick" numbers.
- [x] v0.3.9 in game (owner, 2026-11-10, Lantaana 200cc): "better so far". Race watch average 0.95 ms (was 11.7),
      worst 21 ms; our ticks 100+ ms late 2 a race.
- [x] Menu: the main-menu poll (`C.cached('FrontEndGameMode')`, every 200 ms) is a lookup by path too = a sweep 5x a
      second at the menu. Not felt so far; make it cheaper (notification + rare checks) if the menus ever hitch.
      (v0.13.1: notification + a sweep every 2-3 s; the tick's own 10x a second went too. Still left: the tab's
      checks that the menu widget is alive, ~12 sweeps a second while our page is up - see CHANGELOG v0.13.1.)

## 5. v0.4 Mods: the vehicle's affixes (built as v0.6.0) (owner, 2026-11-09; DESIGN.md §5b)
- [x] **Recon M1 (2026-11-10):** works. Affixes in the launch build's `Affixes` (direct pointers) become active
      passives; the bots copy them too, and clearing the bots' race copies at load keeps them yours only
      (DESIGN.md §5b). 50cc stays mod-free (owner).
- [x] Catalogue dumped and grouped (`tools/recon/ModRecon`); shown to the owner as a page.
- [x] Owner (2026-11-10): no pure-speed mods; protections and playstyle mods only. Every effect tagged (24 power left
      out, 24 protection, 81 playstyle of which 23 "check"); page updated.
- [x] Owner: rescue / drop individual mods on the page; slots 2 / 3 / 4; top step everywhere or step by class;
      what to do with the 23 "check" ones (keep, drop, or try a few in game first).
- [x] Owner (2026-11-10): top step everywhere, keep the "check" ones, build it.
- [x] Built as **v0.6.0** (tags were already past v0.4): catalogue generated into `Scripts/mods.lua`
      (`tools/gen_mods.py`), MODS screens, launch build Affixes + put-back, bots cleared at load; tests.
- [x] In game (Claude, 2026-11-10, test copy of the save, 150cc Lantaana): MODS screens work (slots, groups, 16-mod
      list, PROTECTION badges, a fitted mod not offered again); Frost + Burn Protection on your car's passives, all 11
      AI cars none ("88 slots cleared"); "mods put back (main menu): VBD_Car_Base (0)" - `Empty()` works.
- [x] v0.6.1: tile descriptions were cut after two lines -> a gold info line with the focused mod's full text.
- [x] (moot: tune-ups, v0.8) Owner: play with mods; which ones feel good / too strong (the 23 "check" ones especially).
- [x] MODS screen next to ABILITIES: slots by class; kept for the cup; written at race load (v0.6.0).
- [x] Tests; tagged as v0.6.0.

## 5b. Trophy display and reset (owner, 2026-11-10)
- Owner saw a gold cup trophy after winning one race. Checked: not a bug. That race was race 4 of the Jakku cup
  left in progress the night before (races 1-3 on 2026-11-09; 15+12+10+15 = 54 points), carried into 150cc by the
  save conversion. Trophies are only written at the end of race 4 (`gp.lua` cupOver). The 200cc Jakku gold was a
  full cup (1st, 2nd, 3rd, 1st = 52).
- [x] v0.3.11: "race N of 4" on CONTINUE CUP, the cup screen, NEXT RACE (badge "RACE 4 / 4", "the final race")
      and CONTINUE CUP shows your place and points so far. (v0.9: only NEXT RACE's badge is left.)
- [x] v0.3.11: trophy badge on the cup tiles (the tile's own small extra line: GOLD / SILVER / BRONZE TROPHY, or
      IN PROGRESS 3 / 4 - gone in v0.9); class tiles show "3 / 7 TROPHIES".
- [x] v0.3.11: RESET PROGRESS (owner): last tile on the class screen; confirm with NO first; clears trophies, best
      finishes, the cup in progress (v0.9: none can be alive at HOME) and the cups count; keeps abilities, vehicle,
      race count; backup first (`save.backup-reset-<date>.lua`).
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
- [x] **Remix cups (v0.6.2, owner 2026-11-10):** only ~10 of the 28 cup races have a true reverse, so instead of a
      reverse option per cup: five remix cups (reverse where it exists, else night / wet / snow / mines / scorching,
      else another planet track), after a trophy in all five planet cups at 200cc, playable at every open class.
      Events dumped in game (GPRecon, 2026-11-10): all 12-car TeamRaceConfig, Vehicle.Standard. Path case matters
      (`Dalmatian/`, `Husky/LOOP_A/`). The COR P2P REV night / snow versions are tagged "NO LIGHTING PASS": left out.
- [x] In game (Claude, 2026-11-10, test copy of the save): remix cups open at 200cc; the Sentinel Remix launched
      (12 racers). Names read: Corrosion Hypersphere; the Ando short 01 has no player-facing name (finished-looking ice
      circuit, kept as ANDO SHORT CIRCUIT - owner may name it).
- [x] (moot in v0.11: no remix cups) Owner: race the remix cups once unlocked.
- [x] (old note, replaced by the remix cups) **Reverse cups (v0.5.x):** the five planet cups on reverse (or night / weather) variants. Needs the event paths
      (Underground config `Planets`) and a launch check in game for each. When do they open: after 150cc (DESIGN §3)
      or after the top class (owner's earlier note)? Ask the owner.
- [x] (built as the title race, v0.8 / v0.8.1) **Champion Showdown (v0.5.x):** the 1 v 1 against Kestar Bool (`EVT_WHP_SHORTBOSS_FAIR`) as a single bonus race
      (win / lose, no points), after gold in every 200cc cup. Needs a 1 v 1 result read in game.

## 6b. Points ranking after each race (owner, 2026-11-10)
- Owner: fewer screens is better; flow = the game's race results, then ONE screen with the ranking by points.
- [x] v0.3.8: our STANDINGS page becomes that screen: a clear table of all 12 (rank, racer, +points this race, total,
      places gained / lost), your row highlighted, NEXT RACE / LATER underneath. After race 4 the same table with the
      trophy on top (the trophy page and the standings page become one).
- [x] v0.3.8: nothing in between: the game's loading screen covers the ~3 s main-menu rebuild (`HideMenuFlash`).
- [ ] In game: the table lines up and reads well; the cover appears and goes (if it sticks or blocks input, set
      `HideMenuFlash = false`).

## 7. v0.7 Polish (was v0.6)
- [ ] (art v0.7, intro lines v0.8 done) Controller check with the owner's pad on the v0.8 menus (cycling tiles with A, B to go back, the 5 x 4 cups page).
- [x] Art research (2026-11-10): textures pulled from the paks (`tools/art/iotex.py`); page with previews and paths:
      https://claude.ai/artifact/6mLfAbAs7k8NeCqvpU8yML. All under `/Game/Griffin/UI/Library/Textures/`:
  - Classes: `Backgrounds/T_UI_DifficultySettings01..04_Bg` (sage / gold / blue / red = 50 / 100 / 150 / 200cc).
  - Cups: `Content/Arcade/T_UI_Arcade_<P>_<Vehicle>_Tile` posters, one colour per planet, per vehicle
    (Car / Bike / Skimmer / Plane). P: Jakku MAS, Lantaana DAL, Ando COR, Crait SPA, Sentinel HUS (events HSK),
    Galactic WHP, Outer Rim BGL (Plane only). Crait has no Car tile (Bike / Plane / Needle).
  - Remix cups: `Content/Arcade/T_UI_Arcade_<P>_<Vehicle>_Bg` (dark full-colour planet scenes).
  - Trophies: `Icons/Leaderboard/T_UI_Grit_Medals_Gold|Silver|Bronze` in the tile's `Img_Icon` (hidden today).
  - Showdown: `Content/RacerStyles/T_UI_RacerStyle_Antagonist_Bg` (Kestar); `Icons/Map/T_UI_Map_ChampionEvent_Icn`.
  - Mod groups: `Content/RacerStyles/T_UI_RacerStyle_<Afterburner|Ramjet|Cooling|Surging|Frozen|Abilities|Battling|
    Struggling|Airborne>_Bg`.
  - Standings / results backdrop: `Backgrounds/T_UI_Retro_A..D_Bg`, `T_UI_MainMenu_Bg`, `T_UI_Scenario_Bg`.
  - Not usable as-is: `Content/Planets/T_UI_Planet_*` are grey masks (detail in alpha, tinted by a material).
- [x] Owner (2026-11-10): "I like all of those, just go for it". Built as **v0.7.0** (`art.lua`, test_art).
- [x] In game (Claude, 2026-11-10): art cropped to its top-left corner -> fitted per texture (v0.7.1); medals moved
      and coloured; MODS art darker. Classes, cups, cup page, mods, groups, cup in progress all checked.
- [x] (backdrop seen 2026-11-10: dark stripes, readable) Still to see: the standings / cup result backdrop (`T_UI_Scenario_Bg`) after a race; the 50cc banner is light,
      so its white title is harder to read when focused (darker art or a crop if it bothers the owner).
- [x] (v0.7.1) (was) In game: screenshots of every screen; fix anything that crops or stretches badly. Was: pick from the art page; then `ui.lua` `texture()` takes full paths (today only `Content/MainMenu/`),
      cups get `art` per vehicle, won cups show their medal icon.
- [x] (the cover, v0.3.8; owner to confirm) Hide the ~3 s main-menu flash between a race and the standings (loading screen, or a shorter wait).
- [x] Tag v0.7.0 (and v0.7.1, v0.8.0, v0.8.1).

## 8. Maybe (moved to the end by the owner, 2026-11-09: might not be needed)
- [x] (built in v0.8: ai.lua profiles per class; tuning is v1.0) **AI difficulty per class:** AI pressure (`ai.lua`, the rubber band) on top of the class's part levels.
      Owner after the first cups: "difficult but fun" as it is.
- [-] (dropped by the owner 2026-11-11) **No crash limit:** pick the working control (GPRecon `health=def|state|tune`), set before each race, put back
      at the menu.

## 9. v1.0 Tuning
- [ ] Owner plays every cup at every class; tune parts per class, AI pressure, AI kits, points.
- [ ] Tag v1.0.0.

## Later
- Podracer cup. A 200cc class. The crash ability as a fifth pick. Time-trial ghosts per track (the game has a
  time-trial mode). Records per track.
