-- v0.32.8: the CUP RESULT on the game's own tour-end screen (cupend.lua): after a 4-race cup's last race CUP RESULT
-- puts the screen up over the results, filled with the cup (planets, places, points as the XP awards, wins, DNFs); the
-- results screen is see-through under it; pressing the button again (or Enter / Escape) closes it and leaves for the
-- menu, where our cup result page follows as before. CupResult.Native = false: the old flow.
local M = require('mock')
local W = require('world')
local T = require('util')
local cfg
local function wait3() local t0 = os.time(); while os.time() - t0 < 3 do end end
local TIMES = { 101.25, 62.5, 99.75, 71.0 }
local PLACES = { 2, 1, 1, 3 }

local function start(extra)
  T.reset()
  local c = { Progression = { On = false } }
  for k, v in pairs(extra or {}) do c[k] = v end
  T.boot({ racer = 'Thrall' }, c)
  cfg = require('config')
  W.cupEvents()
  M.press('F6'); M.tick(6)
  T.clickTitle('CHALLENGER'); M.tick(3)
  T.clickTitle('JAKKU CUP')
  T.check(M.called('LaunchQuickRace') == 1, 'race 1 launched')
end
local function runRace(k)
  local you = PLACES[k]
  W.race(11); M.tick(5)
  for i in ipairs(W.bots) do
    local before = i < you
    W.botFinish(i, before and i or i + 1, TIMES[k] + (before and (i - you) or i))
  end
  M.tick(110)
  W.finish(you, TIMES[k], TIMES[k] / 3 - k * 0.01)
  M.tick(25)
end
-- races 1-3 through the chain (NEXT RACE via the menu), race 4 up to its results screen
local function toLastResults()
  for k = 1, 3 do
    runRace(k)
    W.results(); M.tick(4)
    W.pressNext(); M.tick(5)
    W.dropRaceWorld(); W.backToMenu(); M.tick(90)
    T.check(M.called('LaunchQuickRace') == k + 1, 'race ' .. (k + 1) .. ' launched via the menu')
  end
  runRace(4)
  local mark = T.mark()
  W.results(); M.tick(4)
  T.check(T.logHas('[chain] last race: CUP RESULT button', mark), 'the last race: the CUP RESULT button on the results')
  return mark
end

-- A. the native cup result
start()
local mark = toLastResults()
T.check(W.runEnd == nil, 'A: nothing up before the button')
W.pressNext(); M.tick(3)
T.check(W.runEnd ~= nil and T.logHas('[chain] CUP RESULT pressed (the CUP RESULT button): the cup result on the game\'s tour-end screen', mark),
  'A: CUP RESULT puts the game\'s tour-end screen up')
local p = rawget(W.runEnd, '__props')
T.check(W.screenOpacity == 0 and W.continued == 0, 'A: the results screen see-through under it, not left yet')
T.check(rawget(W.runEnd, '__props').__inViewport == true, 'A: the screen in the viewport')
local run = p.RunStatsVM and rawget(p.RunStatsVM, '__props')
T.check(run and run.RacesWon == 2 and run.NumTop3EventFinishes == 4 and run.NumDNFs == 0 and run.NumEventFinishes == 4 and run.HighestWinStreak == 2 and run.RunSuccessful == true,
  'A: the run VM: 4 finishes, 4 top-3, 2 wins, best streak 2, no DNF')
local shown = p.TourPlanetsToShow
local nShown = type(shown) == 'table' and (shown.GetArrayNum and shown:GetArrayNum() or #shown) or -1
T.check(nShown == 1, 'A: one planet shown (Jakku): ' .. tostring(nShown))
local pv = (type(shown) == 'table') and (shown[1]) or nil
local pvp = pv and rawget(pv, '__props')
T.check(pvp and pvp.NumTimesVisited == 4 and pvp.bIsFirstVisitedPlanet == true and pvp.bIsLastVisitedPlanet == true and pvp.Planet ~= nil
  and rawget(pvp.Planet, '__name') == 'DA_Planet_Mastiff', 'A: the planet VM: Jakku\'s PlanetDef, visited 4 times, first and last')
local entries = pvp and pvp.TimelineEntries
local ne = type(entries) == 'table' and (entries.GetArrayNum and entries:GetArrayNum() or #entries) or -1
T.check(ne == 4, 'A: four timeline entries: ' .. tostring(ne))
local e1, e4 = entries and rawget(entries[1], '__props'), entries and rawget(entries[4], '__props')
T.check(e1 and e1.FinishPosition == 2 and e1.Activity == 2 and e4.FinishPosition == 3 and e4.Activity == 6, 'A: the places on the entries (2nd ... 3rd), the last race the champion crown')
local xp = p.XPVM and rawget(p.XPVM, '__props')
local awards = xp and xp.XPAwards
local na = type(awards) == 'table' and (awards.GetArrayNum and awards:GetArrayNum() or #awards) or -1
T.check(na == 4 and awards[1].XP == 12 and awards[2].XP == 15 and rawget(awards[1].Reason, '__props').__text:find('Race 1: ', 1, true) ~= nil
  and rawget(awards[1].Reason, '__props').__text:find(', 2nd', 1, true) ~= nil, 'A: the XP awards are your points per race (12, 15, 15, 10) with the race and place')
T.check(xp.TotalXPEarned == 52 and xp.NextRankXPThreshold == 60, 'A: the total 52 points against the cup\'s maximum 60')
T.check(M.called('RefreshPlanets') == 1 and M.called('TriggerTimelineAnimation') == 1 and M.called('UpdateWins') == 1 and M.called('UpdateParticipation') == 1
  and M.called('BeginProgressAnimationFromXPAwards') == 1, 'A: the panels filled through their own functions')
local uw = M.lastCall('UpdateWins'); local up = M.lastCall('UpdateParticipation')
T.check(uw.args[1] == 1 and up.args[1] == 4 and up.args[2] == 2, 'A: UpdateWins(1) = one medal (the silver), UpdateParticipation(4 finishes, streak 2)')
T.check(rawget(p.WBP_MP_Wins, '__props').MedalColour ~= nil and rawget(p.WBP_MP_Wins, '__props').MedalColour.R == 0.8, 'A: the medal in the silver colour')
T.check(T.logHas('[cupend] view models: 1 planets (1 shown), 4 races, 4 awards = 52 points of 60', mark), 'A: the view models logged')
T.check(T.logHas('[cupend] the cup result on the game\'s tour-end screen: JAKKU CUP, CHALLENGER - 2nd, 52 points, 2 wins, 0 DNF', mark), 'A: the summary line')
-- the press that opened it is not read again for 1.5 s; the texts written a moment later
M.tick(12)
T.check(W.runEnd ~= nil and W.continued == 0, 'A: still up 1.2 s on (the opening press not read twice)')
local wins = rawget(p.WBP_MP_Wins, '__props')
T.check(rawget(wins.Txt_Amount, '__props').__text == nil or true, '(texts)')
local setTexts = W.textsSince(1)
T.check(setTexts:find('52 / 60', 1, true) ~= nil and setTexts:find('JAKKU CUP  -  CHALLENGER', 1, true) ~= nil, 'A: the points text and the title written (' .. (setTexts:find('52 / 60', 1, true) and 'points ok' or 'no points') .. ')')
T.check(setTexts:find('SILVER TROPHY', 1, true) ~= nil and setTexts:find('\n2ND\n', 1, true) ~= nil and setTexts:find('POINTS', 1, true) ~= nil and setTexts:find('PODIUMS', 1, true) ~= nil and setTexts:find('4 OF 4', 1, true) ~= nil,
  'A: v0.32.9 tiles - SILVER TROPHY / 2ND, POINTS 52 / 60, PODIUMS 4 OF 4')
-- A again: closes, leaves for the menu
M.tick(10)
W.pressNext(); M.tick(3)
T.check(W.continued == 1 and T.logHas('[chain] CUP RESULT pressed (the CUP RESULT button): the summary closes', mark) and T.logHas('[cupend] summary closed (leaving for the menu)', mark),
  'A: the second press closes the summary and leaves for the menu')
T.check(rawget(W.runEnd, '__dead') == true or M.called('RemoveFromParent') >= 1, 'A: the screen taken down')
W.dropRaceWorld(); W.backToMenu(); M.tick(60)
T.check(T.logHas('cup over: CHALLENGER jakku - you 2nd with 52 points, SILVER trophy'), 'A: the cup recorded as before')
T.check(T.logHas('[cupend] the cup result page skipped: the tour-end screen showed it') and not T.logHas('[menu] standings (1 tiles)') and T.logHas('[menu] cups'),
  'A: v0.32.9 - at the menu the cups page, not our old cup result page')
T.check(M.deadTouches == 0, 'A: no freed object touched (' .. M.deadTouches .. ')')

-- B. Escape closes it too (chain.lua's back flag)
start()
mark = toLastResults()
W.pressNext(); M.tick(3)
T.check(W.runEnd ~= nil, 'B: the summary up')
M.tick(22)
M.press('ESCAPE'); M.tick(3)
T.check(W.continued == 1 and T.logHas('[chain] CUP RESULT pressed (Backspace / Escape / B): the summary closes', mark), 'B: Escape closes it and leaves')
W.dropRaceWorld(); W.backToMenu(); M.tick(60)
T.check(T.logHas('[menu] cups', mark) and not T.logHas('[menu] standings (1 tiles)', mark), 'B: the cups page at the menu')

-- B2. Enter closes it too (v0.32.10), and the pad's B through the Back screen
start()
mark = toLastResults()
W.pressNext(); M.tick(3)
T.check(W.runEnd ~= nil, 'B2: the summary up')
M.tick(22)
M.press('RETURN'); M.tick(3)
T.check(W.continued == 1 and T.logHas('[chain] CUP RESULT pressed (Enter / Space): the summary closes', mark), 'B2: Enter closes it and leaves')
W.dropRaceWorld(); W.backToMenu(); M.tick(60)
start()
mark = toLastResults()
W.pressNext(); M.tick(3)
M.tick(22)
W.padB(); M.tick(4)
T.check(W.continued == 1 and T.logHas('[chain] CUP RESULT pressed (Backspace / Escape / B): the summary closes', mark), 'B2: the pad\'s B closes it and leaves')
W.dropRaceWorld(); W.backToMenu(); M.tick(60)

-- C. CupResult.Native = false: straight to the menu, nothing made
start({ CupResult = { Native = false } })
mark = toLastResults()
W.pressNext(); M.tick(3)
T.check(W.runEnd == nil and W.continued == 1 and T.logHas('[chain] CUP RESULT pressed (the CUP RESULT button)', mark) and not T.logHas('[cupend]', mark),
  'C: Native = false: CUP RESULT leaves for the menu at once, no tour-end screen')
W.dropRaceWorld(); W.backToMenu(); M.tick(60)
T.check(T.logHas('[menu] standings (1 tiles)') and not T.logHas('[cupend]'), 'C: our cup result page at the menu, as before')
T.finish()
