-- v0.19 / v0.19.1 (TASKS.md "Next" 2, DESIGN.md §15): cups without the main menu. After a cup race (not the last) the
-- standings go on the game's results screen with a NEXT RACE button. v0.19.1: NEXT RACE goes VIA THE MENU (the results
-- to the main menu the game's way, the cover up there, the next race launched by itself - no standings page). (The
-- v0.19.0 reset route and its scenarios E-I are in attic/ since v0.21.0.) Scenarios (one process, T.reset between them):
--   A. ChainRaces.On = false: today's flow, nothing in the race world (the reference for B)
--   B. a 4-race cup via the menu end to end: the same points / records / put-backs / save as A, the cover, no standings
--      page between races, the cup result at the end; the panel opaque, the game's table hidden, the buttons apart
--   C. v0.21: B instead of NEXT RACE mid-cup (Backspace / Escape, the pad's B, or the screen closing by itself with
--      CONTINUE hidden): the main menu and straight to "Leave the cup?" (not recorded twice); NO = the standings with
--      NEXT RACE, YES = the cup left
--   D. the auto-launch at the menu fails: the cover off, today's standings page (NEXT RACE there works)
--   J. the Galactic Cup (a new planet every race) chains via the menu too
local M = require('mock')
local W = require('world')
local T = require('util')

local TIMES = { 101.25, 62.5, 99.75, 71.0 }
local PLACES = { 2, 1, 1, 3 } -- yours in races 1-4 (test_flow's: you 52 points, Biddy Blas 54)
-- (v0.26: the Jakku Cup's draw under the tests' fixed rnd, util.lua T.RND)
local TRACKS = { 'EVT_MAS_LOOP_A_REV_HARD', 'EVT_MAS_P2P_FWD', 'EVT_MAS_LOOP_B_REV_HARD', 'EVT_MAS_LOOP_A_SHORT_02_HARD' }
local SAVE = { racer = 'Thrall' } -- Sen Fira, one of the 11 opponents (the swap puts Shade in her grid slot); a bike
local MENU_TICKS = 90 -- after the results go to the menu: the race noticed gone (2 s), the menu settled (5 s), the launch

local function start(cfg)
  T.reset()
  cfg = cfg or {}
  cfg.Progression = { On = false }
  T.boot(SAVE, cfg)
  W.cupEvents()
  M.press('F6'); M.tick(6)
  T.clickTitle('CHALLENGER'); M.tick(3)
end
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
local KEEP = { 'races', 'cups', 'best', 'records', 'perfect', 'standings', 'leader', 'boss', 'run', 'last', 'titles' }
local function outcome(sv)
  local o = {}
  for _, k in ipairs(KEEP) do o[k] = strip(sv[k]) end
  return o
end
local function lastLaunch() return rawget(M.lastCall('LaunchQuickRace').args[2], '__name') end
-- the set-up and put-back lines of a whole cup (A's are the reference for B)
local COUNTS = { 'LAUNCH ', 'RESULT ', '[gaps] ', 'PERF ', 'build for this race: VBD_Bike_Base 0=7 1=7 2=7 3=7 4=7 5=7',
  'your abilities for this race:', '[ai] league challenger: pressure', '[aiset] race league=challenger', '[loadout] challenger, 11 racers',
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
T.check(T.logHas('cup over: CHALLENGER jakku - you 2nd with 52 points, SILVER trophy'), 'A: cup over, 2nd, silver')
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
  T.check(not txt:find('STANDINGS', 1, true) and txt:find('THIS RACE', 1, true) and txt:find('POINTS', 1, true) and (k > 1 or not txt:find('MOVED', 1, true))
    and txt:find(('race %d of 4'):format(k), 1, true), 'B: race ' .. k .. ': the panel has the cup line and the table')
  -- v0.21: no rival marked on the panel
  T.check(not txt:find('RIVAL', 1, true), 'B: race ' .. k .. ': no RIVAL on the panel (v0.21)')
  local nxt = T.save().run.list[k + 1].title
  T.check(txt:find(('NEXT RACE: race %d of 4, %s.   B: leave the cup.'):format(k + 1, nxt), 1, true) and not txt:find('CONTINUE:', 1, true),
    'B: race ' .. k .. ': the prompt says what NEXT RACE and B do (no CONTINUE)')
  T.check(W.contVis == 1, 'B: race ' .. k .. ': the game\'s CONTINUE hidden (Collapsed)')
  if k == 1 then
    T.check(txt:find('LEADING', 1, true) or txt:find('BEHIND', 1, true), 'B: the stakes line on the panel')
    T.check(T.logHas('opaque; the game\'s table hidden (1)', mark) and W.tableVis == 2, 'B: the panel opaque, the game\'s own table hidden under it')
    local U = require('ui')
    T.check(U.PANEL_BG.A == 1, 'B: the panel background alpha 1')
    local _, x = buttonXs(calls)
    T.check(x == 0, ('B: NEXT RACE alone, centred where the two buttons were (x %s, CONTINUE\'s centre)'):format(tostring(x)))
    T.check(T.logHas('NEXT RACE button, focused: NEXT RACE alone at x 0 (centred; slot 504 wide); the game\'s CONTINUE hidden', mark)
      and T.logHas('; B: the Back screen (pad) and Backspace / Escape', mark), 'B: the button layout, CONTINUE hidden and B logged')
  end
  T.check(W.chainBtn ~= nil and #W.canvasKids == 3 and W.resultsBack ~= nil, 'B: race ' .. k .. ': the panel, NEXT RACE and the Back screen on the canvas')
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
T.check(W.contVis == 0, 'B: the last race keeps the game\'s CONTINUE (to the cup result)')
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
T.check(sv.run == nil and sv.races == 4 and sv.cups == 1 and sv.best['challenger'].jakku == 2, 'B: the cup over, silver, 4 races')
local diffs = {}
same(refSave, outcome(sv), 'save', diffs)
T.check(#diffs == 0, 'B: points, records, best, standings, rival, last race: identical to the menu flow (A)' .. (#diffs > 0 and (' - ' .. table.concat(diffs, '; ')) or ''))
T.check(T.logHas('cup over: CHALLENGER jakku - you 2nd with 52 points, SILVER trophy'), 'B: cup over, 2nd, silver (as A)')
T.check(require('chain').via == nil, 'B: no via-the-menu request left over')
ended('B')

---------------------------------------------------------------------------------------------------------------------
-- C. v0.21: B instead of NEXT RACE: the main menu and straight to "Leave the cup?"
-- C1: Backspace (the keyboard's B; a press during the race doesn't count) -> the question; NO -> the standings page
start()
T.clickTitle('JAKKU CUP')
W.race(11)
M.press('ESCAPE') -- (the pause key during the race: the flag is cleared when the panel goes up)
runRace(1)
W.results(); M.tick(4)
T.check(T.logHas('[chain] panel added'), 'C1: the panel on the results screen')
local mark = T.mark()
M.tick(5)
T.check(not T.logHas('[chain] B on the results screen', mark) and W.continued == 0, 'C1: an Escape pressed during the race is not B')
M.press('BACKSPACE'); M.tick(3)
T.check(T.logHas('[chain] B on the results screen (Backspace / Escape): to the main menu, then "Leave the cup?"', mark), 'C1: B logged')
T.check(W.continued == 1 and T.logHas('[chain] the results screen\'s CONTINUE pressed', mark), 'C1: the hidden CONTINUE pressed from code')
W.backToMenu(); M.tick(MENU_TICKS)
T.check(T.logHas('[chain] B on the results screen: "Leave the cup?" at the main menu (CHALLENGER jakku, race 2 of 4 next)', mark), 'C1: straight to the question, logged')
T.check(T.titles() == 'YES|NO' and T.logHas('[menu] confirm', mark) and not T.logHas('[menu] standings', mark), 'C1: "Leave the cup?" (YES / NO as before), no standings page first')
T.check(not T.logHas('[chain] via the menu', mark) and M.called('LaunchQuickRace') == 1, 'C1: no via-the-menu launch')
T.check(T.logCount('RESULT ') == 1 and T.save().races == 1, 'C1: the race recorded once (on the results screen, not again at the menu)')
T.check(T.logCount('build put back (') == 1, 'C1: the put-backs at the main menu')
T.clickTitle('NO'); M.tick(3)
T.check(T.titles() == 'NEXT RACE' and T.badges() == 'RACE 2 / 4' and T.save().run.race == 2, 'C1: NO: the standings with NEXT RACE, RACE 2 / 4')
T.clickTitle('NEXT RACE')
T.check(M.called('LaunchQuickRace') == 2 and lastLaunch() == TRACKS[2], 'C1: NEXT RACE there launches race 2')
ended('C1')
-- C2: the pad's B (the game deactivates our Back screen on the panel) -> the question; YES -> the cup left
start()
T.clickTitle('JAKKU CUP')
W.race(11)
runRace(1)
W.results(); M.tick(4)
mark = T.mark()
W.padB(); M.tick(3)
T.check(T.logHas('[chain] B on the results screen (the pad\'s B): to the main menu', mark) and W.continued == 1, 'C2: the pad\'s B read, CONTINUE pressed from code')
W.backToMenu(); M.tick(MENU_TICKS)
T.check(T.titles() == 'YES|NO', 'C2: "Leave the cup?"')
T.clickTitle('YES'); M.tick(3)
T.check(T.logHas('cup forfeited: CHALLENGER jakku after 1 of 4 races') and T.save().run == nil, 'C2: YES: the cup is left')
T.check(T.logCount('build put back (') == 1 and M.called('LaunchQuickRace') == 1, 'C2: nothing put back twice, nothing launched')
ended('C2')
-- C3: the results screen closes by itself (the game's own back handling took B first; CONTINUE was hidden) -> the
-- question too
start()
T.clickTitle('JAKKU CUP')
W.race(11)
runRace(1)
W.results(); M.tick(4)
mark = T.mark()
W.backToMenu(); M.tick(MENU_TICKS)
T.check(T.logHas('before NEXT RACE with CONTINUE hidden (the game\'s own B / Escape): "Leave the cup?" at the main menu', mark), 'C3: logged')
T.check(T.titles() == 'YES|NO' and T.logCount('RESULT ') == 1, 'C3: "Leave the cup?", the race recorded once (' .. T.titles() .. ')')
ended('C3')
-- C4: HideContinue = false: v0.20's two buttons, CONTINUE visible; the screen leaving -> today's standings page
start({ ChainRaces = { On = true, Key = 'N', ResultsWaitS = 90, MenuSettleS = 5, Panel = { HideContinue = false } } })
T.clickTitle('JAKKU CUP')
W.race(11)
runRace(1)
local calls = #M.calls + 1
W.results(); M.tick(4)
local x1, x2 = buttonXs(calls)
T.check(W.contVis == 0 and x1 and x2 and x2 - x1 >= 420 * 1.2 + 80 and #W.canvasKids == 2 and W.resultsBack == nil,
  'C4: HideContinue = false: CONTINUE visible, NEXT RACE left of it, no Back screen')
T.check(W.textsSince(calls):find('CONTINUE: the main menu', 1, true) ~= nil, 'C4: the v0.20 prompt')
mark = T.mark()
W.backToMenu(); M.tick(MENU_TICKS)
T.check(T.logHas('[chain] the results went to the main menu before NEXT RACE', mark) and T.titles() == 'NEXT RACE', 'C4: CONTINUE: today\'s standings page')
ended('C4')

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
-- J. the Galactic Cup (a new planet every race) chains via the menu like any cup
start()
T.clickTitle('GALACTIC CUP')
local g2 = T.drawn()[2]
T.check(g2 and require('gp').planetOf(T.save().run.list[2].path) ~= require('gp').planetOf(T.save().run.list[1].path), 'J: the draw puts race 2 on another planet')
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

---------------------------------------------------------------------------------------------------------------------
-- T. v0.27 (owner: "it skips over the finish times screen"): the game's own results (the finish times) stay up for
-- Panel.TimesS, CONTINUE invisible and disabled meanwhile, then the standings panel; B while the times show leaves
start({ TimesS = 6 })
T.clickTitle('JAKKU CUP')
W.race(11)
mark = T.mark()
runRace(1)
W.results(); M.tick(4)
T.check(not T.logHas('[chain] panel added', mark) and #W.canvasKids == 0 and W.tableVis == 4,
  'T: the game\'s finish times first - no panel yet, its table showing')
T.check(T.logHas('[chain] the game\'s results (finish times) up for 6 s, then the standings; its CONTINUE invisible and disabled meanwhile', mark),
  'T: the wait logged')
T.check(W.contEnabled == false and W.contOpacity == 0 and W.continued == 0, 'T: CONTINUE invisible and disabled: a stray A can\'t skip the times')
T.check(T.save().run.race == 2, 'T: the race recorded when the screen came (the cup at race 2)')
M.tick(50)
T.check(not T.logHas('[chain] panel added', mark), 'T: still the times at 5.4 s')
M.tick(10)
T.check(T.logHas('[chain] panel added: on Default_Results', mark) and W.chainBtn ~= nil, 'T: the standings panel after 6 s')
T.check(W.contEnabled == true and W.contOpacity == 1 and W.contVis == 1, 'T: CONTINUE given back, then hidden (Collapsed) as before')
W.pressNext(); M.tick(3)
T.check(T.logHas('[chain] NEXT RACE pressed', mark), 'T: NEXT RACE works after the wait')
W.backToMenu(); M.tick(MENU_TICKS)
T.check(M.called('LaunchQuickRace') == 2, 'T: race 2 launched via the menu')
-- B while the times show
mark = T.mark()
W.race(11)
runRace(2)
W.results(); M.tick(10)
M.press('BACKSPACE'); M.tick(3)
T.check(T.logHas('[chain] B on the results screen (Backspace / Escape, during the finish times)', mark) and W.continued == 1,
  'T: B during the times: the cup left the panel\'s way (CONTINUE pressed from code)')
T.check(not T.logHas('[chain] panel added', mark), 'T: no panel after B')
W.backToMenu(); M.tick(MENU_TICKS)
T.check(T.logHas('"Leave the cup?" at the main menu', mark), 'T: "Leave the cup?" at the main menu')
ended('T')

T.finish()
