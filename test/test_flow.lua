-- v0.2 / v0.8: a whole cup. GRAND PRIX tab -> 150cc -> Jakku Cup (Select starts it: no cup page); 4 races with points
-- for all 12 racers, standings after each, the trophy at the end; parts at the class level for each race and put back after.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } }) -- (unlocks: test_prog, test_unlocks)
T.check(W.tab.label == 'GRAND PRIX', 'tab added with the label GRAND PRIX')
M.press('F6'); M.tick(6)
T.check(T.logHas('[menu] home'), 'F6 opens the home screen')
T.check(T.titles() == '50CC|100CC|150CC|200CC|GARAGE|RESET PROGRESS', 'home: the four classes, GARAGE, RESET (no EXIT) (' .. T.titles() .. ')')
T.clickTitle('150CC'); M.tick(3)
T.check(T.ntiles() == #require('config').Cups + 1, 'every cup of the class plus the title race on one page, no BACK (' .. T.ntiles() .. ')')
T.check(T.titles():find('^JAKKU CUP|LANTAANA CUP|ANDO CUP|CRAIT CUP|SENTINEL CUP|') ~= nil, 'planet cups first (' .. T.titles() .. ')')
T.check(T.logHas('[menu] cups'), 'cups page')

-- one race: bots finish around you; you finish `you`
local function race(n, you)
  W.race(11); M.tick(5)
  for i, b in ipairs(W.bots) do
    local rec = rawget(rawget(b, '__props').RaceEventComponent, '__props')
    rec.EventPosition = i < you and i or i + 1
    rec.bHasFinishedEvent = true
  end
  M.tick(5)
  W.finish(you); M.tick(25)
  local t0 = os.time(); while os.time() - t0 < 3 do end
  W.backToMenu(); M.tick(45)
end

T.clickTitle('JAKKU CUP')
T.check(M.called('LaunchQuickRace') == 1, 'Select on a cup launches race 1 straight away')
T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name'):find('EVT_MAS_LOOP_A_FWD', 1, true) ~= nil, 'race 1 = The War Fields')
local parts = require('config').Classes[3].parts
T.check(T.levels('VBD_Car_Base') == ('0=%d 1=%d 2=%d 3=%d 4=%d 5=%d'):format(parts, parts, parts, parts, parts, parts), '150cc: every part at ' .. parts)
T.check(T.save().run and T.save().run.race == 1, 'the cup is in the save (race 1)')

race(1, 2)
T.check(T.levels('VBD_Car_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'build put back after the race')
T.check(T.logHas('field: 12 racers'), 'all 12 racers read')
T.check(T.logHas('cup jakku race 1: 1 Biddy Blas, 2 YOU, 3 Kestar Bool'), 'race 1 order logged')
T.check(T.logHas('[menu] standings'), 'standings after race 1')
T.check(T.logHas('[cover] on') and T.logHas('[cover] off'), 'the menu is covered while it is rebuilt, and uncovered for the ranking')
local sv = T.save()
T.check(sv.run.race == 2 and sv.run.points.YOU == 12 and sv.run.points['Biddy Blas'] == 15, 'points: you 12, Biddy 15')

local launches = { 'EVT_MAS_P2P_FWD', 'EVT_MAS_LOOP_B_FWD', 'EVT_MAS_LOOP_A_SHORT_02' }
for i, you in ipairs({ 1, 1, 3 }) do
  if i == 2 then
    -- from the cups page: the cup in progress launches its next race on Select
    T.clickTitle('LATER'); M.tick(3)
    T.check(T.badges():find('IN PROGRESS  3 / 4', 1, true) ~= nil, 'the cup tile says IN PROGRESS 3 / 4 (' .. T.badges() .. ')')
    T.clickTitle('JAKKU CUP')
  else
    T.clickTitle('NEXT RACE')
  end
  T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name'):find(launches[i], 1, true) ~= nil, 'race ' .. (i + 1) .. ' = ' .. launches[i])
  race(i + 1, you)
end
-- you: 12 + 15 + 15 + 10 = 52; Biddy: 15 + 12 + 12 + 15 = 54
T.check(T.logHas('cup over: 150 jakku - you 2nd with 52 points, SILVER trophy'), 'cup over: 2nd, silver')
T.check(T.logHas('[menu] standings (1 tiles)'), 'after race 4: the one ranking screen (trophy on top), CONTINUE only')
sv = T.save()
T.check(sv.run == nil, 'no cup in progress any more')
T.check(sv.best['150'].jakku == 2 and sv.cups == 1 and sv.races == 4, 'best = 2nd saved; 1 cup, 4 races')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(T.titles():find('JAKKU CUP', 1, true) ~= nil, 'CONTINUE -> the cups')
T.check(T.badges():find('^SILVER TROPHY|') ~= nil, 'Jakku shows its silver (' .. T.badges() .. ')')
M.press('BACKSPACE'); M.tick(3)
T.check(T.logHas('[menu] home'), 'B from the cups goes home')
T.check(T.badges():find('1 / ' .. #require('config').Cups .. ' TROPHIES', 1, true) ~= nil, '150cc shows its trophy count (' .. T.badges() .. ')')
T.finish()
