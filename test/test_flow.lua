-- v0.1 flow: the GRAND PRIX tab -> class -> cup -> START launches race 1 with every part at the class level;
-- finish, back at the menu: build put back, result screen, CONTINUE back to the cup.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot()
T.check(W.tab.label == 'GRAND PRIX', 'tab added with the label GRAND PRIX')
M.press('F6'); M.tick(6)
T.check(T.logHas('[menu] classes'), 'F6 opens the class screen')
T.check(T.titles():find('50CC|100CC|150CC|EXIT', 1, true) ~= nil, 'three classes and EXIT (' .. T.titles() .. ')')

T.clickTitle('100CC'); M.tick(3)
T.check(T.logHas('[menu] cups'), 'class -> cups')
T.check(T.ntiles() == 8, '7 cups + BACK (' .. T.ntiles() .. ')')
T.clickTitle('JAKKU CUP'); M.tick(3)
T.check(T.logHas('[menu] cup'), 'cup -> the cup screen')
T.check(T.titles():find('1. THE WAR FIELDS', 1, true) ~= nil, 'the cup lists its races')

T.clickTitle('START')
T.check(M.called('LaunchQuickRace') == 1, 'START launches a race')
local args = M.lastCall('LaunchQuickRace').args
T.check(rawget(args[2], '__name'):find('EVT_MAS_LOOP_A_FWD', 1, true) ~= nil, 'race 1 of the Jakku Cup')
T.check(rawget(args[1], '__name') == 'VA_Car', 'with the landspeeder')
T.check(T.levels('VBD_Car_Base') == '0=6 1=6 2=6 3=6 4=6 5=6', '100cc: every part at 6 (' .. T.levels('VBD_Car_Base') .. ')')
T.check(T.save().restores['/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base'] ~= nil, 'originals in the save before the race')

W.race(11); M.tick(5)
T.check(T.logHas('standalone=true'), 'offline race seen')
W.finish(3); M.tick(3)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.logHas('RESULT THE WAR FIELDS: 3rd'), 'result recorded')
T.check(T.levels('VBD_Car_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'build put back after the race')
T.check(next(T.save().restores) == nil, 'nothing left to put back')
T.check(T.save().races == 1, 'races = 1')
T.check(T.logHas('[menu] result'), 'result screen after the race')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(T.logHas('[menu] cup ('), 'CONTINUE -> back to the cup')
T.finish()
