-- v0.5: unlocks in the menus. A new save: 150cc / 200cc and the bonus cups are locked tiles that say what opens them
-- and can't be entered. Winning the fifth planet cup at 100cc opens 150cc and the 100cc bonus cups, said on the cup
-- result screen.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 2, races = 30, cups = 4, class = '100', vehicle = 'car',
  best = { ['100'] = { jakku = 1, lantaana = 1, ando = 1, crait = 1 } },
  run = { class = '100', cup = 'sentinel', vehicle = 'car', race = 4, races = 4,
    points = { YOU = 45, ['Katja Mox'] = 30 }, last = {}, history = { {}, {}, {} } },
  restores = {}, abilityRestores = {} })
M.press('F6'); M.tick(6)
T.check(T.badges() == 'RACE 4 / 4||4 / 12 TROPHIES|LOCKED|LOCKED||', 'class screen: 150cc and 200cc locked (' .. T.badges() .. ')')
T.clickTitle('150CC'); M.tick(3)
T.check(T.titles():find('^CONTINUE CUP|50CC') ~= nil, 'a locked class can\'t be entered')
T.clickTitle('100CC'); M.tick(3)
local b = T.badges()
T.check(b == 'GOLD TROPHY|GOLD TROPHY|GOLD TROPHY|GOLD TROPHY|IN PROGRESS  4 / 4|LOCKED|LOCKED|LOCKED|LOCKED|LOCKED|LOCKED|LOCKED|', '100cc: Outer Rim locked until five golds (' .. b .. ')')
T.clickTitle('OUTER RIM CUP'); M.tick(3)
T.check(T.titles():find('JAKKU CUP', 1, true) ~= nil, 'a locked cup can\'t be entered')
T.clickTitle('SENTINEL CUP'); M.tick(3)
T.clickTitle('NEXT RACE')
W.race(11); M.tick(5); W.finish(1); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.logHas('unlocked: 150cc, OUTER RIM CUP at 100cc, GALACTIC CUP at 100cc'), 'the fifth gold unlocks 150cc and the 100cc bonus cups')
T.check(T.save().best['100'].sentinel == 1, 'Sentinel gold saved')
T.clickTitle('CONTINUE'); M.tick(3)
b = T.badges()
T.check(b == 'GOLD TROPHY|GOLD TROPHY|GOLD TROPHY|GOLD TROPHY|GOLD TROPHY|||LOCKED|LOCKED|LOCKED|LOCKED|LOCKED|', '100cc: Outer Rim and Galactic open now, the remix cups still locked (' .. b .. ')')
T.clickTitle('BACK'); M.tick(3)
T.check(T.badges() == '|5 / 12 TROPHIES||LOCKED||', 'class screen: 150cc open, 200cc still locked (' .. T.badges() .. ')')
T.clickTitle('150CC'); M.tick(3)
b = T.badges()
T.check(T.titles():find('JAKKU CUP', 1, true) ~= nil and select(2, b:gsub('LOCKED', '')) == 7, '150cc: planet cups open, its bonus and remix cups locked (' .. b .. ')')
T.finish()
