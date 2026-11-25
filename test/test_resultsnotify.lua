-- v0.32: the results screen told by the game (chain.lua): no sweep for it after your finish when the notification came;
-- the fallback sweep every 3 s when it did not; a screen told of but freed before it showed is let go.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ racer = 'Thrall' }, { Progression = { On = false } })
W.cupEvents()
M.press('F6'); M.tick(6)
T.clickTitle('CHALLENGER'); M.tick(3)
T.clickTitle('JAKKU CUP')
T.check(M.called('LaunchQuickRace') == 1, 'race 1 launched')
local function wait3() local t0 = os.time(); while os.time() - t0 < 3 do end end
local function runRace()
  W.race(11); M.tick(5)
  for i in ipairs(W.bots) do W.botFinish(i, i + 1, 100 + i) end
  M.tick(110)
  W.finish(1, 99.5, 33.0)
  M.tick(25)
end

-- A. told by the game: the panel comes, no sweep for the screen
runRace()
M.resetSweeps()
local mark = T.mark()
M.tick(10)
T.check(T.logHas('looking for the results screen') and M.sweepCount('FindAllOf WBP_SimpleRaceResultsScreen_C') == 0,
  'A: a second of looking without the screen: no sweep for it (' .. M.sweepCount('FindAllOf WBP_SimpleRaceResultsScreen_C') .. ')')
W.results(); M.tick(4)
T.check(T.logHas('[chain] the results screen found (told by the game)', mark), 'A: the screen found through the notification')
T.check(T.logHas('[chain] panel added', mark) or T.logHas('STANDINGS button', mark), 'A: the panel (or the STANDINGS button) on it')
T.check(M.sweepCount('FindAllOf WBP_SimpleRaceResultsScreen_C') == 0, 'A: still no sweep for the results screen')
-- on to the main menu, the next race (the chain's own flow)
W.pressNext(); M.tick(5)
W.dropRaceWorld(); W.backToMenu(); M.tick(90)
T.check(M.called('LaunchQuickRace') == 2, 'A: race 2 launched via the menu')

-- B. no notification (a screen made some other way): the fallback sweep finds it, every 3 s at most
runRace()
M.resetSweeps()
mark = T.mark()
W.results({ quiet = true }); M.tick(2)
T.check(not T.logHas('[chain] the results screen found', mark) or T.logHas('found (a sweep)', mark), 'B: not found by a notification')
M.tick(30)
T.check(T.logHas('[chain] the results screen found (a sweep)', mark), 'B: the fallback sweep found it')
local n = M.sweepCount('FindAllOf WBP_SimpleRaceResultsScreen_C')
T.check(n >= 1 and n <= 2, 'B: one sweep in 3 s, not ten (' .. n .. ')')
W.pressNext(); M.tick(5)
W.dropRaceWorld(); W.backToMenu(); M.tick(90)
T.check(M.called('LaunchQuickRace') == 3, 'B: race 3 launched via the menu')

-- C. told of a screen that is freed before it shows: let go, the sweep carries on, no freed object touched
runRace()
local ghost = M.new('WBP_SimpleRaceResultsScreen_C_ghost', { IsInViewport = function() return false end }, 'WBP_SimpleRaceResultsScreen_C')
M.add('WBP_SimpleRaceResultsScreen_C', ghost)
M.fireNew('/Script/UMG.UserWidget', ghost)
M.tick(2)
M.kill(ghost)
local dead = M.deadTouches
mark = T.mark()
M.tick(10)
T.check(require('chain').fresh == nil and M.deadTouches == dead, 'C: a freed screen told of is let go, never touched (' .. (M.deadTouches - dead) .. ')')
W.results(); M.tick(4)
T.check(T.logHas('[chain] the results screen found (told by the game)', mark), 'C: the real screen found through its notification')
T.finish()
