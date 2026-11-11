-- v0.19 / v0.19.1 (TASKS.md "Next" 2, DESIGN.md §15): cups without the main menu. After a cup race (not the last) the
-- standings go on the game's results screen with a NEXT RACE button. v0.19.1: NEXT RACE goes VIA THE MENU by default
-- (the results to the main menu the game's way, the cover up there, the next race launched by itself - no standings
-- page); the v0.19.0 reset route (recipe swap + RequestResetRace) only with ChainRaces.Reset = true and the next race
-- in the same layout folder, with a watchdog. Scenarios (one process, T.reset between them):
--   A. ChainRaces.On = false: today's flow, nothing in the race world (the reference for B)
--   B. a 4-race cup via the menu end to end: the same points / records / put-backs / save as A, the cover, no standings
--      page between races, the cup result at the end; the panel opaque, the game's table hidden, the buttons apart
--   C. CONTINUE instead of NEXT RACE mid-cup: the standings at the main menu (not recorded twice), B there leaves the cup
--   D. the auto-launch at the menu fails: the cover off, today's standings page (NEXT RACE there works)
--   E. Reset = true, the next race in the same layout (Crait 150cc race 2 -> 3, Loop_B -> Loop_B): the reset route,
--      watchdog ok (race 1 -> 2 is another layout: via the menu, also with Reset on)
--   F. Reset = true, the next race in another layout (Jakku 150cc, Loop_A -> P2P_A): the via-the-menu route
--   G. the reset's watchdog: a new race world with no AI racer (the v0.19.0 hang): RequestReturnToMenus, then the next
--      race via the menu
--   H. a reset that gives no new race world: CONTINUE pressed for you after LoadTimeoutS, then the next race via the menu
--   I. a recipe write that can't be made: the fallback before any reset, then the next race via the menu
--   J. the Galactic Cup (a new planet every race) chains via the menu too; CH.layout / CH.sameLayout
local M = require('mock')
local W = require('world')
local T = require('util')

local TIMES = { 101.25, 62.5, 99.75, 71.0 }
local PLACES = { 2, 1, 1, 3 } -- yours in races 1-4 (test_flow's: you 52 points, Biddy Blas 54)
local TRACKS = { 'EVT_MAS_LOOP_A_FWD_DAWN', 'EVT_MAS_P2P_FWD', 'EVT_MAS_LOOP_B_FWD_HARD', 'EVT_MAS_LOOP_A_SHORT_02_HARD' }
local CRAIT = { 'EVT_SPA_Loop_B_FWD_MINES', 'EVT_SPA_Loop_B_P2P_MINES' } -- Crait 150cc races 2-3: one layout (Loop_B)
local SAVE = { racer = 'Thrall' } -- Sen Fira, one of the 11 opponents (the swap puts Shade in her grid slot); a bike
local MENU_TICKS = 90 -- after the results go to the menu: the race noticed gone (2 s), the menu settled (5 s), the launch

local function start(cfg)
  T.reset()
  cfg = cfg or {}
  cfg.Progression = { On = false }
  T.boot(SAVE, cfg)
  W.cupEvents()
  M.press('F6'); M.tick(6)
  T.clickTitle('150CC'); M.tick(3)
end
local function resetCfg() return { ChainRaces = { On = true, Reset = true, Key = 'N', ResultsWaitS = 90, MenuSettleS = 5, LoadTimeoutS = 15, WatchdogS = 20, Panel = {} } } end
-- the race on now: the bots and you finish (`k` = the cup's race number), 11 s of racing first (the racer settles at 10 s)
local function runRace(k)
  local you = PLACES[k]
  M.tick(5)
  for i in ipairs(W.bots) do
    local before = i < you
    W.botFinish(i, before and i or i + 1, TIMES[k] + (before and (i - you) or i))
  end
  M.tick(110)
  W.finish(you, TIMES[k], TIMES[k] / 3 - k * 0.01)
  M.tick(25)
end
local function ended(name)
  if os.getenv('CHAIN_DUMP') == name then for _, l in ipairs(M.log) do io.stderr:write('  log: ' .. tostring(l)) end end
  local errs = 0
  for _, l in ipairs(M.log) do if l:gsub('errors=', ''):find('error', 1, true) then errs = errs + 1; io.stdout:write('  log: ' .. l .. '\n') end end
  T.check(errs == 0, name .. ': no error lines in the log')
  T.check(M.deadTouches == 0, name .. ': no freed object touched (' .. M.deadTouches .. ')' .. (M.deadLog[1] and ('\n' .. M.deadLog[1]) or ''))
end
-- the save without dates (records / last carry the day and minute)
local function strip(v)
  if type(v) ~= 'table' then return v end
  local o = {}
  for k, x in pairs(v) do if k ~= 'at' then o[k] = strip(x) end end
  return o
end
local function same(a, b, path, diffs)
  if type(a) ~= 'table' or type(b) ~= 'table' then
    if a ~= b then diffs[#diffs + 1] = path .. ': ' .. tostring(a) .. ' vs ' .. tostring(b) end
    return
  end
  for k, v in pairs(a) do same(v, b[k], path .. '.' .. tostring(k), diffs) end
  for k, v in pairs(b) do if a[k] == nil then diffs[#diffs + 1] = path .. '.' .. tostring(k) .. ': nil vs ' .. tostring(v) end end
end
local KEEP = { 'races', 'cups', 'best', 'records', 'perfect', 'standings', 'rivals', 'run', 'last', 'titles' }
local function outcome(sv)
  local o = {}
  for _, k in ipairs(KEEP) do o[k] = strip(sv[k]) end
  return o
end
local function lastLaunch() return rawget(M.lastCall('LaunchQuickRace').args[2], '__name') end
-- the set-up and put-back lines of a whole cup (A's are the reference for B)
local COUNTS = { 'LAUNCH ', 'RESULT ', '[gaps] ', 'PERF ', 'build for this race: VBD_Bike_Base 0=7 1=7 2=7 3=7 4=7 5=7',
  'your abilities for this race:', '[ai] class 150: pressure', '[aiset] race class=150', '[loadout] 150, 11 racers',
  '[racer] racing as Sen Fira (DA_Racer_Thrall): CharacterList.Player set', '[racer] racing as Sen Fira (DA_Racer_Thrall); Shade put back',
  'build put back (', 'ability slots put back (', '[ai] AI config put back (main menu): DA_AIConfig' }
local function counts()
  local t = {}
  for _, s in ipairs(COUNTS) do t[s] = T.logCount(s) end
  return t
end
-- the X of the last two SetPosition calls since call index `from` (NEXT RACE's slot, then CONTINUE's)
local function buttonXs(from)
  local xs = {}
  for i = from, #M.calls do
    local c = M.calls[i]
    if c.name == 'SetPosition' and type(c.args[1]) == 'table' and c.args[1].X then xs[#xs + 1] = c.args[1].X end
  end
  return xs[#xs - 1], xs[#xs]
end

---------------------------------------------------------------------------------------------------------------------
-- A. ChainRaces.On = false: today's flow (the results screen is up, nothing goes on it)
start({ ChainRaces = { On = false } })
T.clickTitle('JAKKU CUP')
for k = 1, 4 do
  T.check(lastLaunch() == TRACKS[k], 'A: race ' .. k .. ' launched from the main menu: ' .. TRACKS[k] .. ' (' .. lastLaunch() .. ')')
  W.race(11)
  local mark = T.mark()
  runRace(k)
  W.results(); M.tick(10)
  T.check(#W.canvasKids == 0 and not T.logHas('[chain]', mark), 'A: race ' .. k .. ': nothing on the results screen, no [chain] line')
  W.backToMenu(); M.tick(45)
  T.check(T.logHas(k < 4 and '[menu] standings' or '[menu] standings (1 tiles)', mark), 'A: race ' .. k .. ': the standings at the main menu')
  if k < 4 then T.clickTitle('NEXT RACE') end
end
T.check(M.sweepCount('WBP_SimpleRaceResultsScreen_C') == 0, 'A: the results screen never looked for')
T.check(M.called('LaunchQuickRace') == 4 and W.resets == 0, 'A: 4 launches from the menu, no reset')
T.check(T.logHas('cup over: 150 jakku - you 2nd with 52 points, SILVER trophy'), 'A: cup over, 2nd, silver')
T.check(T.logCount('[menu] standings') == 4, 'A: the standings page after every race (4)')
local refSave, refCounts = outcome(T.save()), counts()
ended('A')

---------------------------------------------------------------------------------------------------------------------
-- B. the same cup via the menu (the default): every launch from the main menu under the cover, no standings page
-- between the races
start()
T.check(T.logHas(' loaded - the GRAND PRIX tab'), 'B: the mod loaded')
T.clickTitle('JAKKU CUP')
T.check(M.called('LaunchQuickRace') == 1 and lastLaunch() == TRACKS[1], 'B: race 1 launched from the main menu')
W.race(11)
for k = 1, 3 do
  local mark = T.mark()
  runRace(k)
  T.check(T.logHas(('[chain] race %d of 4 finished: next'):format(k), mark) and T.logHas('(NEXT RACE via the menu) - looking for the results screen', mark),
    'B: race ' .. k .. ': the chain looks for the results screen (route: via the menu)')
  local calls = #M.calls + 1
  W.results(); M.tick(4)
  T.check(T.logHas('[chain] panel added: on Default_Results', mark), 'B: race ' .. k .. ': the standings panel on the results screen')
  T.check(T.logCount('RESULT ', mark) == 1 and T.save().run.race == k + 1, 'B: race ' .. k .. ' recorded once, on the results screen; the cup at race ' .. (k + 1))
  local txt = W.textsSince(calls)
  T.check(txt:find('STANDINGS', 1, true) and txt:find('THIS RACE', 1, true) and txt:find('POINTS', 1, true) and txt:find('MOVED', 1, true)
    and txt:find(('race %d of 4'):format(k), 1, true), 'B: race ' .. k .. ': the panel has the cup line and the table')
  -- v0.20: a rival from the first race at the class, and their row marked on the panel (the shared standings text)
  local riv = require('rival').name(require('gp').data, T.save().run.class)
  T.check(riv ~= nil and txt:find(riv .. '   RIVAL', 1, true) ~= nil, 'B: race ' .. k .. ': the rival (' .. tostring(riv) .. ') marked RIVAL on the panel')
  local nxt = require('config').Cups[1].races['150'][k + 1].title
  T.check(txt:find(('NEXT RACE: race %d of 4, %s.'):format(k + 1, nxt), 1, true) and txt:find('CONTINUE: the main menu', 1, true),
    'B: race ' .. k .. ': the prompt says what NEXT RACE and CONTINUE do')
  if k == 1 then
    T.check(txt:find('LEADING', 1, true) or txt:find('BEHIND', 1, true), 'B: the stakes line on the panel')
    T.check(T.logHas('opaque; the game\'s table hidden (1)', mark) and W.tableVis == 2, 'B: the panel opaque, the game\'s own table hidden under it')
    local U = require('ui')
    T.check(U.PANEL_BG.A == 1, 'B: the panel background alpha 1')
    local x1, x2 = buttonXs(calls)
    T.check(x1 and x2 and x2 - x1 >= 420 * 1.2 + 80, ('B: NEXT RACE (x %s) left of CONTINUE (x %s), a slot width + the gap apart'):format(tostring(x1), tostring(x2)))
    T.check(T.logHas('NEXT RACE button left of CONTINUE, focused: NEXT RACE at x', mark), 'B: the button layout logged')
  end
  T.check(W.chainBtn ~= nil and #W.canvasKids == 2, 'B: race ' .. k .. ': the panel and NEXT RACE on the canvas')
  W.pressNext(); M.tick(3)
  T.check(T.logHas('[chain] NEXT RACE pressed (the NEXT RACE button)', mark), 'B: race ' .. k .. ': NEXT RACE pressed')
  T.check(T.logHas(('[chain] via the menu: race %d of 4 (%s) launches from the main menu under the cover'):format(k + 1, nxt), mark),
    'B: race ' .. k .. ': via the menu logged')
  T.check(W.continued == 1 and T.logHas('[chain] the results screen\'s CONTINUE pressed', mark) and W.resets == 0,
    'B: race ' .. k .. ': the results screen\'s CONTINUE pressed for you, no reset')
  -- the game goes to the main menu
  local m2 = T.mark()
  W.backToMenu(); M.tick(MENU_TICKS)
  T.check(T.logHas('[cover] on', m2) and T.logHas('[chain] via the menu: at the main menu - the cover up', m2), 'B: race ' .. k .. ': the cover over the main menu')
  T.check(T.logHas(('[chain] via the menu: race %d of 4 launched from the main menu'):format(k + 1), m2), 'B: race ' .. (k + 1) .. ' launched via the menu')
  T.check(not T.logHas('[menu] standings', m2) and not T.logHas('[cover] off', m2), 'B: race ' .. k .. ': no standings page, the cover still up while race ' .. (k + 1) .. ' loads')
  T.check(M.called('LaunchQuickRace') == k + 1 and lastLaunch() == TRACKS[k + 1], 'B: LaunchQuickRace ' .. TRACKS[k + 1] .. ' (' .. lastLaunch() .. ')')
  W.race(11); M.tick(3)
  T.check(T.logHas('[cover] off', m2), 'B: race ' .. (k + 1) .. ': the cover off once its race world is there')
end
local mark4 = T.mark()
runRace(4)
T.check(T.logHas('[chain] not chaining: race 4 of 4: the cup result at the main menu', mark4), 'B: race 4: the last race goes to the main menu')
W.results(); M.tick(10)
T.check(#W.canvasKids == 0, 'B: nothing on the last race\'s results screen')
W.backToMenu(); M.tick(45)
T.check(T.logHas('[menu] standings (1 tiles)', mark4), 'B: the cup result at the main menu')
T.check(T.logCount('[menu] standings') == 1, 'B: no standings page between the races (only the cup result)')
T.check(M.called('LaunchQuickRace') == 4 and W.resets == 0, 'B: four launches from the menu, no reset')
local got = counts()
local bad = {}
for _, s in ipairs(COUNTS) do if got[s] ~= refCounts[s] then bad[#bad + 1] = ('%q %d vs %d'):format(s, got[s], refCounts[s]) end end
T.check(#bad == 0 and got['LAUNCH '] == 4 and got['build put back ('] == 4,
  'B: set-up and put-back lines as the menu flow (A): 4 launches, 4 results, 4 put-backs' .. (#bad > 0 and (' - ' .. table.concat(bad, '; ')) or ''))
T.check(T.levels('VBD_Bike_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'B: the build back to 0')
T.check(W.ai.DefaultPacingSettings.MaxAiCatchupScale == 1.3 and W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75
  and W.rp.Default.PacingSettingsConfig.MaxAiCatchupScale == 1.2, 'B: DA_AIConfig and RP_Default back to the game\'s values')
T.check(W.charsText():find('^Player=DarkEnigma Opp=Mercenary,ElegantProfessional,Star,InnerHonour,Thrall,') ~= nil, 'B: the character list as the game had it')
local sv = T.save()
T.check(sv.run == nil and sv.races == 4 and sv.cups == 1 and sv.best['150'].jakku == 2, 'B: the cup over, silver, 4 races')
local diffs = {}
same(refSave, outcome(sv), 'save', diffs)
T.check(#diffs == 0, 'B: points, records, best, standings, rival, last race: identical to the menu flow (A)' .. (#diffs > 0 and (' - ' .. table.concat(diffs, '; ')) or ''))
T.check(T.logHas('cup over: 150 jakku - you 2nd with 52 points, SILVER trophy'), 'B: cup over, 2nd, silver (as A)')
T.check(require('chain').via == nil, 'B: no via-the-menu request left over')
ended('B')

---------------------------------------------------------------------------------------------------------------------
-- C. CONTINUE instead of NEXT RACE (or the game moving on by itself): the standings at the main menu; B leaves the cup
start()
T.clickTitle('JAKKU CUP')
W.race(11)
runRace(1)
W.results(); M.tick(4)
T.check(T.logHas('[chain] panel added'), 'C: the panel on the results screen')
local mark = T.mark()
W.backToMenu(); M.tick(MENU_TICKS)
T.check(T.logHas('[chain] the results went to the main menu before NEXT RACE', mark), 'C: logged: the results went to the menu first')
T.check(not T.logHas('[chain] via the menu', mark) and M.called('LaunchQuickRace') == 1, 'C: no via-the-menu launch')
T.check(T.logCount('RESULT ') == 1 and T.save().races == 1, 'C: the race recorded once (on the results screen, not again at the menu)')
T.check(T.logHas('[menu] standings', mark) and T.titles() == 'NEXT RACE' and T.badges() == 'RACE 2 / 4', 'C: today\'s standings page: NEXT RACE, RACE 2 / 4')
T.check(T.logCount('build put back (') == 1, 'C: the put-backs at the main menu')
M.press('BACKSPACE'); M.tick(5)
T.check(T.titles() == 'YES|NO' and T.logHas('[menu] confirm', mark), 'C: B asks "Leave the cup?"')
T.clickTitle('YES'); M.tick(3)
T.check(T.logHas('cup forfeited: 150 jakku after 1 of 4 races') and T.save().run == nil, 'C: YES: the cup is left')
T.check(T.logCount('build put back (') == 1 and M.called('LaunchQuickRace') == 1, 'C: nothing put back twice, nothing launched')
ended('C')

---------------------------------------------------------------------------------------------------------------------
-- D. NEXT RACE via the menu, but the launch at the menu fails (the game's LaunchQuickRace refuses): the cover off,
-- today's standings page; NEXT RACE there launches it once it can
start()
T.clickTitle('JAKKU CUP')
W.race(11)
runRace(1)
W.results(); M.tick(4)
W.pressNext(); M.tick(3)
mark = T.mark()
W.backToMenu()
local feP = rawget(W.fe, '__props')
local origLaunch = feP.LaunchQuickRace
feP.LaunchQuickRace = function() error('refused by the test') end
M.tick(MENU_TICKS)
T.check(T.logHas('[chain] via the menu: the launch of race 2 failed (Launch failed - see grandprix.log) - the cover off, the standings page', mark),
  'D: the failed auto-launch logged with why')
T.check(T.logHas('[cover] off', mark) and T.logHas('[menu] standings', mark), 'D: the cover off, today\'s standings page')
T.check(T.titles() == 'NEXT RACE' and T.badges() == 'RACE 2 / 4' and T.save().run.race == 2, 'D: NEXT RACE, RACE 2 / 4, the cup at race 2')
T.check(M.called('LaunchQuickRace') == 1 and require('chain').via == nil, 'D: nothing launched, the request dropped')
T.check(T.logCount('RESULT ') == 1 and T.logCount('build put back (main menu)') == 1 and T.logCount('build put back (launch failed)') == 1,
  'D: recorded once; put back at the menu and after the failed launch')
feP.LaunchQuickRace = origLaunch
T.clickTitle('NEXT RACE')
T.check(M.called('LaunchQuickRace') == 2 and lastLaunch() == TRACKS[2], 'D: NEXT RACE on the page launches race 2 from the menu')
ended('D')

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

---------------------------------------------------------------------------------------------------------------------
-- J. the Galactic Cup (a new planet every race) chains via the menu like any cup
start()
local CH = require('chain')
T.check(CH.layout('/Game/Griffin/Gameplay/Events/Planets/Mastiff/Loop_A/EVT_A') == 'Mastiff/Loop_A', 'J: the layout: planet + the folder after it')
T.check(CH.sameLayout('/x/Planets/Husky/LOOP_A/E', '/x/Planets/husky/Loop_A/F') and not CH.sameLayout('/x/Planets/Mastiff/Loop_A/E', '/x/Planets/Mastiff/P2P_A/F')
  and not CH.sameLayout('/x/Planets/Mastiff/a/E', '/x/Planets/Dalmatian/a/F') and not CH.sameLayout('/x/E', '/x/F'),
  'J: same layout without case; another layout, planet or none = not the same')
local gal
for _, c in ipairs(require('config').Cups) do if c.final then gal = c end end
local g2 = gal.races[2].path:match('([^/]+)$')
T.clickTitle('GALACTIC CUP')
W.race(11)
mark = T.mark()
runRace(1)
T.check(T.logHas('(NEXT RACE via the menu) - looking for the results screen', mark), 'J: the Galactic Cup chains via the menu')
W.results(); M.tick(4)
T.check(T.logHas('[chain] panel added', mark), 'J: the panel on the results screen')
W.pressNext(); M.tick(3)
W.backToMenu(); M.tick(MENU_TICKS)
T.check(M.called('LaunchQuickRace') == 2 and lastLaunch() == g2 and not T.logHas('[menu] standings', mark), 'J: race 2 (' .. g2 .. ', another planet) launched via the menu')
ended('J')

T.finish()
