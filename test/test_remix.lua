-- v0.6.2: remix cups. After a trophy in all five planet cups at 200cc they're open at every class; a remix cup
-- launches its own remix events and has its own trophy.
local M = require('mock')
local W = require('world')
local T = require('util')
local five = function(v) return { jakku = v, lantaana = v, ando = v, crait = v, sentinel = v } end
T.boot({ version = 2, races = 60, cups = 15, class = '100', vehicle = 'car',
  best = { ['100'] = five(1), ['150'] = five(2), ['200'] = { jakku = 3, lantaana = 3, ando = 3, crait = 3 } },
  restores = {}, abilityRestores = {} })
M.press('F6'); M.tick(6)
T.clickTitle('200CC'); M.tick(3)
local t = T.titles()
T.check(t:find('JAKKU REMIX|LANTAANA REMIX|ANDO REMIX|CRAIT REMIX|SENTINEL REMIX|BACK', 1, true) ~= nil, 'five remix cups after the planet and bonus cups (' .. t .. ')')
T.check(select(2, T.badges():gsub('LOCKED', '')) == 7, 'four 200cc trophies: remix cups (and the bonus cups) still locked (' .. T.badges() .. ')')
T.clickTitle('JAKKU REMIX'); M.tick(3)
T.check(T.titles():find('^JAKKU CUP') ~= nil, 'a locked remix cup can\'t be entered')
T.clickTitle('SENTINEL CUP'); M.tick(3)
T.clickTitle('START CUP')
W.race(11); M.tick(5); W.finish(3); M.tick(25)
-- the bronze needs the cup over: finish it quickly (4 races)
for _ = 1, 3 do
  local t0 = os.time(); while os.time() - t0 < 3 do end
  W.backToMenu(); M.tick(45)
  T.clickTitle('NEXT RACE')
  W.race(11); M.tick(5); W.finish(1); M.tick(25)
end
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.logHas('unlocked: REMIX CUPS'), 'the fifth 200cc trophy unlocks the remix cups')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(not T.badges():find('LOCKED|LOCKED|LOCKED|LOCKED|LOCKED|$'), 'remix cups open at 200cc (' .. T.badges() .. ')')
T.clickTitle('BACK'); M.tick(3)
T.clickTitle('100CC'); M.tick(3)
T.check(select(2, T.badges():gsub('LOCKED', '')) == 0, '... and at 100cc (' .. T.badges() .. ')')
T.clickTitle('JAKKU REMIX'); M.tick(3)
local mark = T.mark()
T.clickTitle('START CUP')
T.check(T.logHas("LAUNCH EVT_MAS_LOOP_A_REV (THE WAR FIELDS (REVERSE) - Circuit) class=100", mark), 'race 1 = The War Fields reversed')
T.check(T.save().run.cup == 'jakku_remix', 'the remix cup is its own cup in the save')
T.finish()
