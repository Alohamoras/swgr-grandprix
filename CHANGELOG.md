# Changelog

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
