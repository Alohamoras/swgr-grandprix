-- v0.8: the title race. Locked until a trophy in the Galactic Cup at the class (v0.11; test_prog, test_unlocks);
-- Select launches the Showdown with the class's parts; a win makes you the class champion (saved, shown on the class
-- tile and the TITLE RACE tile); a loss can be run again. Never part of a cup, no points.
local M = require('mock')
local W = require('world')
local T = require('util')
local five = { jakku = 3, lantaana = 1, ando = 2, crait = 3, sentinel = 1 }
T.boot({ version = 2, races = 20, cups = 5, class = '100', vehicle = 'car', best = { ['100'] = five },
  restores = {}, abilityRestores = {} }, { Progression = { On = false } })
M.press('F6'); M.tick(6)
T.check(T.titles():find('GARAGE', 1, true) ~= nil, 'home')
local cfg = dofile(T.dir .. '/Scripts/config.lua')
T.clickTitle('100CC'); M.tick(3)
T.check(T.titles():find('|TITLE RACE$') ~= nil, 'the TITLE RACE tile is the last one on the cups page (' .. T.titles() .. ')')
T.check(T.badges():find('VS ' .. cfg.Title.Opponent:upper(), 1, true) ~= nil, 'it names the opponent (' .. T.badges() .. ')')
T.clickTitle('TITLE RACE')
T.check(M.called('LaunchQuickRace') == 1, 'Select launches the title race')
T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name'):find('EVT_WHP_SHORTBOSS_FAIR', 1, true) ~= nil, 'the Stadium Showdown')
local parts = cfg.Classes[2].parts
T.check(T.levels('VBD_Car_Base') == ('0=%d 1=%d 2=%d 3=%d 4=%d 5=%d'):format(parts, parts, parts, parts, parts, parts), '100cc parts')
T.check(T.save().run == nil, 'no cup started')
-- lose it: 2nd of two
W.race(1); M.tick(5)
W.finish(2); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.logHas('TITLE RACE 100: lost, 2nd vs ' .. cfg.Title.Opponent .. ' (try 1)'), 'the loss logged')
T.check(T.logHas('[menu] titleResult'), 'the title result screen')
local sv = T.save()
T.check(sv.titles['100'] and sv.titles['100'].tries == 1 and not sv.titles['100'].won and sv.races == 21, 'saved: one try, not won; the race counted')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(T.badges():find('VS ' .. cfg.Title.Opponent:upper(), 1, true) ~= nil, 'back on the cups: the title race can be run again')
-- win it
T.clickTitle('TITLE RACE')
W.race(1); M.tick(5)
W.finish(1); M.tick(25)
t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.logHas('TITLE RACE 100: WON - you are the champion vs ' .. cfg.Title.Opponent .. ' (try 2)'), 'the win logged')
sv = T.save()
T.check(sv.titles['100'].won == true and sv.titles['100'].tries == 2 and sv.titles['100'].vs == cfg.Title.Opponent, 'saved: won on the second try')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(T.badges():find('CHAMPION', 1, true) ~= nil, 'the tile says CHAMPION (' .. T.badges() .. ')')
M.press('BACKSPACE'); M.tick(3)
T.check(T.logHas('[menu] home'), 'home again')
T.finish()
