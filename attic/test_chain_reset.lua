-- ATTIC (not run by test/all.sh). Excerpts of test/test_chain.lua as of v0.21.0: the scenarios of the same-layout reset
-- route (ChainRaces.Reset, attic/chain-reset-route.lua) - E (same layout: the reset, watchdog ok), F (Reset on but
-- another layout: via the menu), G (the watchdog: no AI racer), H (no new race world: LoadTimeoutS), I (the recipe
-- can't be written), and J's CH.layout / CH.sameLayout checks. They used test_chain.lua's helpers (start, runRace,
-- ended, lastLaunch, MENU_TICKS, TRACKS) and test/world.lua's recipe / RequestResetRace mock (W.resets, W.resetMode,
-- W.noRecipe, W.stageEvent, W.activeStage), which is still in world.lua. See attic/README.md.

-- (the header as of v0.21.0)
-- v0.19 / v0.19.1 (TASKS.md "Next" 2, DESIGN.md §15): cups without the main menu. After a cup race (not the last) the
-- standings go on the game's results screen with a NEXT RACE button. v0.19.1: NEXT RACE goes VIA THE MENU by default
-- (the results to the main menu the game's way, the cover up there, the next race launched by itself - no standings
-- page); the v0.19.0 reset route (recipe swap + RequestResetRace) only with ChainRaces.Reset = true and the next race
-- in the same layout folder, with a watchdog. Scenarios (one process, T.reset between them):
--   A. ChainRaces.On = false: today's flow, nothing in the race world (the reference for B)
--   B. a 4-race cup via the menu end to end: the same points / records / put-backs / save as A, the cover, no standings
--      page between races, the cup result at the end; the panel opaque, the game's table hidden, the buttons apart
--   C. v0.21: B instead of NEXT RACE mid-cup (Backspace / Escape, the pad's B, or the screen closing by itself with
--      CONTINUE hidden): the main menu and straight to "Leave the cup?" (not recorded twice); NO = the standings with
--      NEXT RACE, YES = the cup left
--   D. the auto-launch at the menu fails: the cover off, today's standings page (NEXT RACE there works)
--   E. Reset = true, the next race in the same layout (Crait 150cc race 2 -> 3, Loop_B -> Loop_B): the reset route,
--      watchdog ok (race 1 -> 2 is another layout: via the menu, also with Reset on)
--   F. Reset = true, the next race in another layout (Jakku 150cc, Loop_A -> P2P_A): the via-the-menu route
--   G. the reset's watchdog: a new race world with no AI racer (the v0.19.0 hang): RequestReturnToMenus, then the next
--      race via the menu
--   H. a reset that gives no new race world: CONTINUE pressed for you after LoadTimeoutS, then the next race via the menu
--   I. a recipe write that can't be made: the fallback before any reset, then the next race via the menu
--   J. the Galactic Cup (a new planet every race) chains via the menu too; CH.layout / CH.sameLayout

local CRAIT = { 'EVT_SPA_Loop_B_FWD_MINES', 'EVT_SPA_Loop_B_P2P_MINES' } -- Crait 150cc races 2-3: one layout (Loop_B)

local function resetCfg() return { ChainRaces = { On = true, Reset = true, Key = 'N', ResultsWaitS = 90, MenuSettleS = 5, LoadTimeoutS = 15, WatchdogS = 20, Panel = {} } } end

---------------------------------------------------------------------------------------------------------------------
-- Crait 150cc with Reset = true: race 1 (Loop_A) -> race 2 (Loop_B) is another layout, so race 2 comes via the menu;
-- race 2 (Loop_B FWD) -> race 3 (Loop_B P2P) is the same layout: the reset route. Returns with race 2's world up.
local function craitRace2()
  start(resetCfg())
  T.clickTitle('CRAIT CUP')
  W.race(11)
  local m = T.mark()
  runRace(1)
  T.check(T.logHas('(Spaniel/Loop_A -> Spaniel/Loop_B is another layout: NEXT RACE via the menu)', m), 'Crait: race 1 -> 2 another layout: via the menu')
  W.results(); M.tick(4)
  W.pressNext(); M.tick(3)
  W.backToMenu(); M.tick(MENU_TICKS)
  T.check(M.called('LaunchQuickRace') == 2 and lastLaunch() == CRAIT[1] and W.resets == 0, 'Crait: race 2 launched via the menu (' .. lastLaunch() .. ')')
  W.race(11); W.tune(3)
end

---------------------------------------------------------------------------------------------------------------------
-- E. Reset = true and the next race in the same layout folder (Crait 150cc race 2 -> 3: Loop_B FWD -> Loop_B P2P):
-- the reset route, the watchdog satisfied
craitRace2()
local origStage = W.stageEvent(W.activeStage())
mark = T.mark()
runRace(2)
T.check(T.logHas('(same layout Spaniel/Loop_B, Reset on: NEXT RACE by the reset)', mark), 'E: the reset route chosen (same layout, Reset on)')
W.results(); M.tick(4)
T.check(T.logHas('[chain] panel added', mark), 'E: the panel on the results screen')
local mE = T.mark()
W.pressNext(); M.tick(3); W.tune(3)
T.check(T.logHas('[chain] next race written: ' .. CRAIT[2], mark) and W.resets == 1 and T.logHas('[chain] reset called', mark), 'E: the recipe written, RequestResetRace called')
T.check(not T.logHas('[chain] via the menu', mark) and W.continued == 0, 'E: not via the menu')
M.tick(30)
T.check(T.logHas('[chain] new race world', mark) and T.logHas(CRAIT[2], T.logAt('[chain] new race world', mark)), 'E: the new race world runs ' .. CRAIT[2])
T.check(T.logHas('[chain] watchdog: ok - 11 AI racers, the race started', mark), 'E: the watchdog sees the AI racers and the start')
M.tick(250)
T.check(W.toMenu == 0 and not T.logHas('[chain] fallback', mark), 'E: no fallback later on')
T.check(T.logCount('[loadout] 150, 11 racers', mE) == 1 and T.logCount('[racer] racing as Sen Fira (DA_Racer_Thrall): CharacterList.Player set', mE) == 1,
  'E: the set-up again for race 3 (loadout, racer)')
T.check(M.called('LaunchQuickRace') == 2, 'E: no launch from the menu for race 3')
W.backToMenu(); M.tick(45)
T.check(T.logCount('[chain] recipe put back (main menu)') == 1 and W.stageEvent(W.activeStage()) == origStage, 'E: the race recipe put back at the menu')
ended('E')

---------------------------------------------------------------------------------------------------------------------
-- F. Reset = true but the next race in another layout folder (Jakku 150cc: Loop_A -> P2P_A, the v0.19.0 hang): via
-- the menu
start(resetCfg())
T.clickTitle('JAKKU CUP')
W.race(11)
mark = T.mark()
runRace(1)
T.check(T.logHas('(Mastiff/Loop_A -> Mastiff/P2P_A is another layout: NEXT RACE via the menu)', mark), 'F: another layout: the via-the-menu route')
W.results(); M.tick(4)
W.pressNext(); M.tick(3)
T.check(W.resets == 0 and W.continued == 1 and T.logHas('[chain] via the menu: race 2 of 4', mark), 'F: no reset; CONTINUE pressed, via the menu')
W.backToMenu(); M.tick(MENU_TICKS)
T.check(M.called('LaunchQuickRace') == 2 and lastLaunch() == TRACKS[2] and T.logHas('[chain] via the menu: race 2 of 4 launched', mark),
  'F: race 2 launched from the main menu')
T.check(not T.logHas('[menu] standings', mark), 'F: no standings page')
ended('F')

---------------------------------------------------------------------------------------------------------------------
-- G. the reset's watchdog: the reset gives a new race world with you only, never an AI racer (as in game, v0.19.0):
-- 20 s after the reset RequestReturnToMenus, then the next race via the menu
craitRace2()
runRace(2)
W.results(); M.tick(4)
W.resetMode = 'empty'
mark = T.mark()
W.pressNext(); M.tick(3)
T.check(W.resets == 1 and T.logHas('[chain] reset called', mark), 'G: NEXT RACE: the reset called')
M.tick(5)
T.check(T.logHas('[chain] new race world', mark), 'G: a new race world (you only)')
M.tick(150)
T.check(not T.logHas('[chain] watchdog', mark) and W.toMenu == 0, 'G: nothing before WatchdogS')
M.tick(60)
T.check(T.logHas('[chain] watchdog: 20 s after the reset no AI racer has appeared - giving up on the reset', mark), 'G: the watchdog fires at 20 s')
T.check(W.toMenu == 1 and T.logHas('[chain] RacingGameMode:RequestReturnToMenus() called', mark), 'G: RequestReturnToMenus called')
T.check(require('chain').via and require('chain').via.race == 3, 'G: the next race (3) asked for via the menu')
W.backToMenu(); M.tick(MENU_TICKS)
T.check(T.logHas('[chain] main menu after the fallback: the result of race 2 - race 3 next, via the menu', mark), 'G: the main menu after the fallback')
T.check(M.called('LaunchQuickRace') == 3 and lastLaunch() == CRAIT[2] and T.logHas('[chain] via the menu: race 3 of 4 launched', mark),
  'G: race 3 launched from the main menu (' .. lastLaunch() .. ')')
T.check(not T.logHas('[menu] standings', mark) and T.logCount('RESULT ') == 2 and T.save().run.race == 3, 'G: no standings page, race 2 recorded once')
T.check(T.logCount('build put back (', mark) == 1 and T.logCount('[chain] recipe put back (main menu)', mark) == 1, 'G: put back once at the menu')
W.race(11); M.tick(3)
T.check(T.logHas('[cover] off', mark), 'G: the cover off in race 3')
ended('G')

---------------------------------------------------------------------------------------------------------------------
-- H. the reset gives no new race world: after LoadTimeoutS CONTINUE is pressed for you; the next race via the menu
craitRace2()
runRace(2)
W.results(); M.tick(4)
W.resetMode = 'nothing'
mark = T.mark()
W.pressNext(); M.tick(3)
T.check(W.resets == 1 and T.logHas('[chain] reset called', mark), 'H: NEXT RACE: the reset called')
M.tick(100)
T.check(not T.logHas('[chain] fallback', mark), 'H: no fallback before LoadTimeoutS')
M.tick(60)
T.check(T.logHas('[chain] fallback: no new race world 15 s after the reset - to the main menu, the next race from there (via the menu)', mark), 'H: the fallback after 15 s')
T.check(W.continued == 1 and T.logHas('[chain] the results screen\'s CONTINUE pressed', mark), 'H: CONTINUE pressed for the player')
W.backToMenu(); M.tick(MENU_TICKS)
T.check(M.called('LaunchQuickRace') == 3 and lastLaunch() == CRAIT[2] and not T.logHas('[menu] standings', mark), 'H: race 3 launched via the menu')
T.check(T.logCount('RESULT ', mark) == 0 and T.logCount('RESULT ') == 2 and T.logCount('build put back (', mark) == 1, 'H: race 2 recorded once, put back once')
ended('H')

---------------------------------------------------------------------------------------------------------------------
-- I. the recipe can't be written (no active recipe): the fallback before any reset; the next race via the menu
craitRace2()
W.noRecipe = true
rawget(W.sub, '__props').ActiveRecipe = nil
runRace(2)
W.results(); M.tick(4)
mark = T.mark()
W.pressNext(); M.tick(3)
T.check(T.logHas('[chain] fallback: no EventRecipeSubsystem.ActiveRecipe', mark) and W.resets == 0, 'I: the write failed: fallback, no reset')
T.check(W.continued == 1, 'I: CONTINUE pressed for the player')
W.backToMenu(); M.tick(MENU_TICKS)
T.check(M.called('LaunchQuickRace') == 3 and lastLaunch() == CRAIT[2] and T.logCount('RESULT ') == 2, 'I: race 3 launched via the menu, race 2 recorded once')
T.check(T.logCount('build put back (', mark) == 1, 'I: put back once')
ended('I')

local CH = require('chain')
T.check(CH.layout('/Game/Griffin/Gameplay/Events/Planets/Mastiff/Loop_A/EVT_A') == 'Mastiff/Loop_A', 'J: the layout: planet + the folder after it')
T.check(CH.sameLayout('/x/Planets/Husky/LOOP_A/E', '/x/Planets/husky/Loop_A/F') and not CH.sameLayout('/x/Planets/Mastiff/Loop_A/E', '/x/Planets/Mastiff/P2P_A/F')
  and not CH.sameLayout('/x/Planets/Mastiff/a/E', '/x/Planets/Dalmatian/a/F') and not CH.sameLayout('/x/E', '/x/F'),
  'J: same layout without case; another layout, planet or none = not the same')
