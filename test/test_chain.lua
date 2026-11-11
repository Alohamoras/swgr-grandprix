-- v0.19 (TASKS.md "Next" 2, DESIGN.md §15): cups without the main menu. After a cup race (not the last) the standings
-- go on the game's results screen with a NEXT RACE button; NEXT RACE writes the next event into the race recipe and
-- resets the race (a new race world, no main menu). Scenarios (one process, T.reset between them):
--   A. ChainRaces.On = false: today's flow, nothing in the race world (the reference for B)
--   B. a 4-race cup chained end to end: the same points / records / rival / save as A, the set-up done for every race,
--      the put-backs once at the end
--   C. CONTINUE instead of NEXT RACE mid-cup: the standings at the main menu (not recorded twice), B there leaves the cup
--   D. a reset that gives no new race world: the fallback (CONTINUE -> the main menu -> the standings -> NEXT RACE)
--   E. a recipe write that can't be made: the fallback before any reset
--   F. CrossPlanet = false: the Galactic Cup's planet change uses the main-menu flow
local M = require('mock')
local W = require('world')
local T = require('util')

local TIMES = { 101.25, 62.5, 99.75, 71.0 }
local PLACES = { 2, 1, 1, 3 } -- yours in races 1-4 (test_flow's: you 52 points, Biddy Blas 54)
local TRACKS = { 'EVT_MAS_LOOP_A_FWD_DAWN', 'EVT_MAS_P2P_FWD', 'EVT_MAS_LOOP_B_FWD_HARD', 'EVT_MAS_LOOP_A_SHORT_02_HARD' }
local SAVE = { racer = 'Thrall' } -- Sen Fira, one of the 11 opponents (the swap puts Shade in her grid slot); a bike

local function start(cfg)
  T.reset()
  cfg = cfg or {}
  cfg.Progression = { On = false }
  T.boot(SAVE, cfg)
  W.cupEvents()
  M.press('F6'); M.tick(6)
  T.clickTitle('150CC'); M.tick(3)
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
local KEEP = { 'races', 'cups', 'best', 'records', 'perfect', 'standings', 'rivals', 'run', 'last', 'titles' }
local function outcome(sv)
  local o = {}
  for _, k in ipairs(KEEP) do o[k] = strip(sv[k]) end
  return o
end
local function lastLaunch() return rawget(M.lastCall('LaunchQuickRace').args[2], '__name') end

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
local refSave = outcome(T.save())
ended('A')

---------------------------------------------------------------------------------------------------------------------
-- B. the same cup chained: one launch from the menu, then three races from the results screen
start()
T.check(T.logHas('v0.19.0 loaded'), 'B: v0.19.0')
T.clickTitle('JAKKU CUP')
T.check(M.called('LaunchQuickRace') == 1 and lastLaunch() == TRACKS[1], 'B: race 1 launched from the main menu')
W.race(11); W.tune(3)
local origStage = W.stageEvent(W.activeStage())
for k = 1, 3 do
  local mark = T.mark()
  runRace(k)
  T.check(T.logHas(('[chain] race %d of 4 finished: next'):format(k), mark), 'B: race ' .. k .. ': the chain looks for the results screen')
  T.check(T.levels('VBD_Bike_Base') == '0=7 1=7 2=7 3=7 4=7 5=7', 'B: race ' .. k .. ': the bike at parts 7 (' .. T.levels('VBD_Bike_Base') .. ')')
  T.check(W.ai.DefaultPacingSettings.MaxAiCatchupScale == 1.0 and W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.85
    and W.rp.Default.PacingSettingsConfig.MaxAiCatchupScale == 1.0, 'B: race ' .. k .. ': the 150cc AI profile on DA_AIConfig and RP_Default')
  local calls = #M.calls + 1
  W.results(); M.tick(4)
  T.check(T.logHas('[chain] panel added: on Default_Results', mark), 'B: race ' .. k .. ': the standings panel on the results screen')
  T.check(T.logCount('RESULT ', mark) == 1 and T.save().run.race == k + 1, 'B: race ' .. k .. ' recorded once, on the results screen; the cup at race ' .. (k + 1))
  local txt = W.textsSince(calls)
  T.check(txt:find('STANDINGS', 1, true) and txt:find('THIS RACE', 1, true) and txt:find('POINTS', 1, true) and txt:find('MOVED', 1, true)
    and txt:find(('race %d of 4'):format(k), 1, true), 'B: race ' .. k .. ': the panel has the cup line and the table')
  local nxt = require('config').Cups[1].races['150'][k + 1].title
  T.check(txt:find(('NEXT RACE: race %d of 4, %s.'):format(k + 1, nxt), 1, true) and txt:find('CONTINUE: the main menu', 1, true),
    'B: race ' .. k .. ': the prompt says what NEXT RACE and CONTINUE do')
  T.check(txt:find('NEW RECORD', 1, true) ~= nil, 'B: race ' .. k .. ': NEW RECORD on the panel (a first time on the track)')
  if k == 1 then T.check(txt:find('LEADING', 1, true) or txt:find('BEHIND', 1, true), 'B: the stakes line on the panel') end
  T.check(W.chainBtn ~= nil and #W.canvasKids == 2, 'B: race ' .. k .. ': the panel and NEXT RACE on the canvas')
  T.check(not T.logHas('[menu] standings', mark), 'B: race ' .. k .. ': no main menu')
  W.pressNext(); M.tick(3); W.tune(3)
  T.check(T.logHas('[chain] NEXT RACE pressed (the NEXT RACE button)', mark), 'B: race ' .. k .. ': NEXT RACE pressed')
  T.check(T.logHas('[chain] next race written: ' .. TRACKS[k + 1], mark), 'B: the recipe holds ' .. TRACKS[k + 1])
  T.check(W.resets == k and T.logHas('[chain] reset called', mark), 'B: RequestResetRace ' .. k .. ' time(s)')
  M.tick(3)
  T.check(T.logHas('[chain] new race world', mark) and T.logHas(TRACKS[k + 1], T.logAt('[chain] new race world', mark)), 'B: the new race world runs ' .. TRACKS[k + 1])
end
local mark4 = T.mark()
runRace(4)
T.check(T.logHas('[chain] not chaining: race 4 of 4: the cup result at the main menu', mark4), 'B: race 4: the last race goes to the main menu')
W.results(); M.tick(10)
T.check(#W.canvasKids == 0, 'B: nothing on the last race\'s results screen')
T.check(not T.logHas('build put back', 1), 'B: nothing put back during the chain')
W.backToMenu(); M.tick(45)
T.check(T.logHas('[menu] standings (1 tiles)', mark4), 'B: the cup result at the main menu')
T.check(M.called('LaunchQuickRace') == 1 and W.resets == 3, 'B: one menu launch, three resets')
T.check(T.logCount('LAUNCH ') == 4 and T.logCount('RESULT ') == 4 and T.logCount('[gaps] ') == 4 and T.logCount('PERF ') == 4, 'B: 4 launches, 4 results, 4 gap lines, 4 PERF lines')
-- the set-up of every race (the same as a menu launch)
T.check(T.logCount('build for this race: VBD_Bike_Base 0=7 1=7 2=7 3=7 4=7 5=7') == 4, 'B: the class parts on the build for every race')
T.check(T.logCount('your abilities for this race:') == 4, 'B: your abilities for every race')
T.check(T.logCount('[ai] class 150: pressure') == 4 and T.logCount('[aiset] race class=150') == 4, 'B: the AI profile (and its read-back) for every race')
T.check(T.logCount('[ai] applied to') >= 4, 'B: the rubber band on every race\'s tune objects')
T.check(T.logCount('[loadout] 150, 11 racers') == 4, 'B: the AI racers\' abilities for every race (' .. T.logCount('[loadout] 150, 11 racers') .. ')')
T.check(T.logCount('[racer] racing as Sen Fira (DA_Racer_Thrall): CharacterList.Player set') == 4, 'B: the racer swap for every race')
T.check(T.logCount('[racer] racing as Sen Fira (DA_Racer_Thrall); Shade put back') == 4, 'B: the racer list settled in every race')
-- the put-backs: once, at the end
T.check(T.logCount('build put back (') == 1 and T.logCount('ability slots put back (') == 1, 'B: the build and abilities put back once')
T.check(T.logCount('[ai] AI config put back (main menu): DA_AIConfig') == 1, 'B: the AI config put back once')
T.check(T.logCount('[chain] recipe put back (main menu)') == 1, 'B: the race recipe put back once')
local back, l4 = T.logAt('build put back ('), T.logAt('LAUNCH ' .. TRACKS[4])
T.check(back and l4 and back > l4, 'B: the put-back after race 4 (not between the chained races)')
T.check(T.levels('VBD_Bike_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'B: the build back to 0')
T.check(W.ai.DefaultPacingSettings.MaxAiCatchupScale == 1.3 and W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75
  and W.rp.Default.PacingSettingsConfig.MaxAiCatchupScale == 1.2, 'B: DA_AIConfig and RP_Default back to the game\'s values')
T.check(W.charsText():find('^Player=DarkEnigma Opp=Mercenary,ElegantProfessional,Star,InnerHonour,Thrall,') ~= nil, 'B: the character list as the game had it')
T.check(W.stageEvent(W.activeStage()) == origStage, 'B: the subsystem recipe back to race 1\'s event (' .. W.stageEvent(W.activeStage()) .. ')')
local sv = T.save()
T.check(sv.run == nil and sv.races == 4 and sv.cups == 1 and sv.best['150'].jakku == 2, 'B: the cup over, silver, 4 races')
local diffs = {}
same(refSave, outcome(sv), 'save', diffs)
T.check(#diffs == 0, 'B: points, records, best, standings, rival, last race: identical to the menu flow (A)' .. (#diffs > 0 and (' - ' .. table.concat(diffs, '; ')) or ''))
T.check(T.logHas('cup over: 150 jakku - you 2nd with 52 points, SILVER trophy'), 'B: cup over, 2nd, silver (as A)')
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
W.backToMenu(); M.tick(45)
T.check(T.logHas('[chain] the results went to the main menu before NEXT RACE', mark), 'C: logged: the results went to the menu first')
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
-- D. the reset gives no new race world: after LoadTimeoutS the fallback presses CONTINUE; the standings at the main menu
start()
T.clickTitle('JAKKU CUP')
W.race(11)
runRace(1)
W.results(); M.tick(4)
W.resetMode = 'nothing'
mark = T.mark()
W.pressNext(); M.tick(3)
T.check(W.resets == 1 and T.logHas('[chain] reset called', mark), 'D: NEXT RACE: the reset called')
M.tick(100)
T.check(not T.logHas('[chain] fallback', mark), 'D: no fallback before LoadTimeoutS')
M.tick(60)
T.check(T.logHas('[chain] fallback: no new race world 15 s after the reset', mark), 'D: the fallback after 15 s')
T.check(W.continued == 1 and T.logHas('[chain] fallback: the results screen\'s CONTINUE pressed', mark), 'D: CONTINUE pressed for the player')
W.backToMenu(); M.tick(45)
T.check(T.logHas('[chain] main menu after the fallback: the standings of race 1', mark), 'D: the main menu: race 1\'s standings')
T.check(T.titles() == 'NEXT RACE' and T.badges() == 'RACE 2 / 4' and T.save().run.race == 2, 'D: today\'s standings page, the cup at race 2')
T.check(T.logCount('RESULT ') == 1 and T.logCount('build put back (') == 1 and T.logCount('[chain] recipe put back (main menu)') == 1,
  'D: recorded once, everything put back once')
T.check(T.levels('VBD_Bike_Base') == '0=0 1=0 2=0 3=0 4=0 5=0' and W.charsText():find('^Player=DarkEnigma') ~= nil, 'D: build and racer back')
T.clickTitle('NEXT RACE')
T.check(M.called('LaunchQuickRace') == 2 and lastLaunch() == TRACKS[2], 'D: NEXT RACE on the page launches race 2 from the menu')
ended('D')

---------------------------------------------------------------------------------------------------------------------
-- E. the recipe can't be written (no active recipe): the fallback before any reset
start()
W.noRecipe = true
T.clickTitle('JAKKU CUP')
W.race(11)
runRace(1)
W.results(); M.tick(4)
mark = T.mark()
W.pressNext(); M.tick(3)
T.check(T.logHas('[chain] fallback: no EventRecipeSubsystem.ActiveRecipe', mark) and W.resets == 0, 'E: the write failed: fallback, no reset')
T.check(W.continued == 1, 'E: CONTINUE pressed for the player')
W.backToMenu(); M.tick(45)
T.check(T.logHas('[menu] standings', mark) and T.titles() == 'NEXT RACE' and T.logCount('RESULT ') == 1, 'E: the standings at the main menu, recorded once')
T.check(T.logCount('build put back (') == 1, 'E: put back once')
ended('E')

---------------------------------------------------------------------------------------------------------------------
-- F. CrossPlanet = false: the Galactic Cup (a new planet every race) keeps the main-menu flow
start()
local CH = require('chain')
T.check(CH.samePlanet('/Game/Griffin/Gameplay/Events/Planets/Mastiff/Loop_A/EVT_A', '/Game/Griffin/Gameplay/Events/Planets/Mastiff/P2P_A/EVT_B'), 'F: same planet: the folder after /Planets/')
T.check(CH.samePlanet('/x/Planets/Husky/LOOP_A/E', '/x/Planets/husky/P2P/F') and not CH.samePlanet('/x/Planets/Mastiff/a/E', '/x/Planets/Dalmatian/a/F')
  and not CH.samePlanet('/x/E', '/x/F'), 'F: case-insensitive; another planet or no planet = not the same')
T.clickTitle('GALACTIC CUP')
W.race(11)
mark = T.mark()
runRace(1)
T.check(T.logHas('[chain] not chaining: the next race is on another planet (Dalmatian -> Corgi) and CrossPlanet is off', mark), 'F: the planet change logged')
W.results(); M.tick(10)
T.check(#W.canvasKids == 0 and not T.logHas('[chain] panel', mark), 'F: nothing on the results screen')
W.backToMenu(); M.tick(45)
T.check(T.logHas('[menu] standings', mark) and T.titles() == 'NEXT RACE' and T.logCount('RESULT ') == 1, 'F: today\'s standings at the main menu')
ended('F')
-- (a planet cup at every class stays on its planet: test_config checks every race of a planet cup is on its planet)

T.finish()
