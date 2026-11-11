-- v0.5 / v0.8: unlocks in the menus. A save with four 100cc golds: 150cc / 200cc and the bonus cups are locked tiles
-- that say what opens them and can't be entered. Winning the fifth planet cup at 100cc opens 150cc and the 100cc bonus
-- cups, said on the cup result screen. (v0.9: the Sentinel cup left in the save is dropped at boot and raced whole.)
local M = require('mock')
local W = require('world')
local T = require('util')

T.boot({ version = 2, races = 30, cups = 4, class = '100', vehicle = 'car',
  best = { ['100'] = { jakku = 1, lantaana = 1, ando = 1, crait = 1 } },
  run = { class = '100', cup = 'sentinel', vehicle = 'car', race = 4, races = 4,
    points = { YOU = 45, ['Katja Mox'] = 30 }, last = {}, history = { {}, {}, {} } },
  restores = {}, abilityRestores = {} })
local NCUPS = #dofile(T.dir .. '/Scripts/config.lua').Cups
T.check(T.logHas('[cup] sentinel 100cc dropped at boot (race 4 of 4): cups cannot be resumed') and T.save().run == nil, 'the cup in the save dropped at boot')
M.press('F6'); M.tick(6)
T.check(T.badges() == ('|4 / %d GOLD|LOCKED|LOCKED||'):format(NCUPS), 'home: 150cc and 200cc locked (' .. T.badges() .. ')')
T.clickTitle('150CC'); M.tick(3)
T.check(T.titles():find('^50CC|100CC') ~= nil, 'a locked class can\'t be entered')
T.clickTitle('100CC'); M.tick(3)
local b = T.badges()
T.check(b:find('^GOLD TROPHY|GOLD TROPHY|GOLD TROPHY|GOLD TROPHY|SENTINEL I|') ~= nil, '100cc: the four golds, Sentinel not raced (' .. b .. ')')
-- locked: the 2 bonus, 5 remix and Sentinel's conditions cup; the four golds opened their planets' conditions cups
T.check(select(2, b:gsub('LOCKED', '')) == NCUPS - 8, 'every other cup locked until five golds, but the four conditions cups the golds opened; the title race locked too (' .. b .. ')')
local n = M.called('LaunchQuickRace')
T.clickTitle('OUTER RIM CUP'); M.tick(3)
T.check(M.called('LaunchQuickRace') == n and T.titles():find('JAKKU CUP', 1, true) ~= nil, 'a locked cup can\'t be started')
T.clickTitle('SENTINEL CUP')
T.check(M.called('LaunchQuickRace') == n + 1, 'Select on the Sentinel cup launches its first race')
-- four wins (the bots finish behind you)
local function race()
  W.race(11); M.tick(5)
  for i, b in ipairs(W.bots) do
    local rec = rawget(rawget(b, '__props').RaceEventComponent, '__props')
    rec.EventPosition, rec.bHasFinishedEvent = i + 1, true
  end
  M.tick(5); W.finish(1); M.tick(25)
  local t0 = os.time(); while os.time() - t0 < 3 do end
  W.backToMenu(); M.tick(45)
end
race()
for i = 2, 4 do
  T.check(T.titles() == 'NEXT RACE' and T.badges() == ('RACE %d / 4'):format(i), 'standings: NEXT RACE ' .. i .. ' / 4 (' .. T.badges() .. ')')
  T.clickTitle('NEXT RACE')
  race()
end
T.check(T.logHas('unlocked: 150cc, OUTER RIM CUP at 100cc, GALACTIC CUP at 100cc, SENTINEL CONDITIONS at 100cc'),
  'the fifth gold unlocks 150cc, the 100cc bonus cups and Sentinel Conditions at 100cc')
T.check(T.save().best['100'].sentinel == 1, 'Sentinel gold saved')
T.clickTitle('CONTINUE'); M.tick(3)
b = T.badges()
T.check(b:find('^GOLD TROPHY|GOLD TROPHY|GOLD TROPHY|GOLD TROPHY|GOLD TROPHY|') ~= nil, '100cc: five golds (' .. b .. ')')
T.check(select(2, b:gsub('LOCKED', '')) == NCUPS - 12, '100cc: Outer Rim, Galactic and all five conditions cups open now, the remix cups still locked (' .. b .. ')')
M.press('BACKSPACE'); M.tick(3)
T.check(T.badges() == ('|5 / %d GOLD||LOCKED||'):format(NCUPS), 'home: 150cc open, 200cc still locked (' .. T.badges() .. ')')
T.clickTitle('150CC'); M.tick(3)
b = T.badges()
T.check(T.titles():find('JAKKU CUP', 1, true) ~= nil and select(2, b:gsub('LOCKED', '')) == NCUPS - 4, '150cc: planet cups open, its bonus, remix, conditions cups and title race locked (' .. b .. ')')
T.finish()
