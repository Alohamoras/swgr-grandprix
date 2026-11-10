-- v0.2: a whole cup. GRAND PRIX tab -> 150cc -> Jakku Cup -> START CUP; 4 races with points for all 12 racers,
-- standings after each, the trophy at the end; parts at the class level for each race and put back after.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot()
T.check(W.tab.label == 'GRAND PRIX', 'tab added with the label GRAND PRIX')
M.press('F6'); M.tick(6)
T.check(T.logHas('[menu] classes'), 'F6 opens the class screen')
T.clickTitle('150CC'); M.tick(3)
T.check(T.ntiles() == 8, '7 cups + BACK (' .. T.ntiles() .. ')')
T.clickTitle('JAKKU CUP'); M.tick(3)
T.check(T.titles() == 'START CUP|ABILITIES|VEHICLE|BACK', 'a cup not started: START CUP, ABILITIES, VEHICLE, BACK (' .. T.titles() .. ')')

-- one race: bots finish around you; you finish `you`
local function race(n, you)
  W.race(11); M.tick(5)
  for i, b in ipairs(W.bots) do
    local rec = rawget(rawget(b, '__props').RaceEventComponent, '__props')
    rec.EventPosition = i < you and i or i + 1
    rec.bHasFinishedEvent = true
  end
  M.tick(5)
  W.finish(you); M.tick(3)
  local t0 = os.time(); while os.time() - t0 < 3 do end
  W.backToMenu(); M.tick(45)
end

T.clickTitle('START CUP')
T.check(M.called('LaunchQuickRace') == 1, 'START CUP launches race 1')
T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name'):find('EVT_MAS_LOOP_A_FWD', 1, true) ~= nil, 'race 1 = The War Fields')
T.check(T.levels('VBD_Car_Base') == '0=6 1=6 2=6 3=6 4=6 5=6', '150cc: every part at 6')
T.check(T.save().run and T.save().run.race == 1, 'the cup is in the save (race 1)')

race(1, 2)
T.check(T.levels('VBD_Car_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'build put back after the race')
T.check(T.logHas('field: 12 racers'), 'all 12 racers read')
T.check(T.logHas('cup jakku race 1: 1 Biddy Blas, 2 YOU, 3 Kestar Bool'), 'race 1 order logged')
T.check(T.logHas('[menu] standings'), 'standings after race 1')
local sv = T.save()
T.check(sv.run.race == 2 and sv.run.points.YOU == 12 and sv.run.points['Biddy Blas'] == 15, 'points: you 12, Biddy 15')

local launches = { 'EVT_MAS_P2P_FWD', 'EVT_MAS_LOOP_B_FWD', 'EVT_MAS_LOOP_A_SHORT_02' }
for i, you in ipairs({ 1, 1, 3 }) do
  T.clickTitle('NEXT RACE')
  T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name'):find(launches[i], 1, true) ~= nil, 'race ' .. (i + 1) .. ' = ' .. launches[i])
  race(i + 1, you)
end
-- you: 12 + 15 + 15 + 10 = 52; Biddy: 15 + 12 + 12 + 15 = 54
T.check(T.logHas('cup over: 150 jakku - you 2nd with 52 points, SILVER trophy'), 'cup over: 2nd, silver')
T.check(T.logHas('[menu] trophy'), 'the trophy screen after race 4')
sv = T.save()
T.check(sv.run == nil, 'no cup in progress any more')
T.check(sv.best['150'].jakku == 2 and sv.cups == 1 and sv.races == 4, 'best = 2nd saved; 1 cup, 4 races')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(T.titles():find('JAKKU CUP', 1, true) ~= nil, 'CONTINUE -> the cups')
T.finish()
