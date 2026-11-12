-- v0.5 / v0.8 / v0.11: unlocks in the menus. A save with four 100cc golds: 150cc / 200cc, the Galactic Cup and the
-- title race are locked tiles that say what opens them and can't be entered. Winning the fifth planet cup at 100cc
-- opens 150cc and the 100cc Galactic Cup, said on the cup result screen; a Galactic Cup trophy opens the title race.
-- (v0.9: the Sentinel cup left in the save is dropped at boot and raced whole.)
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
T.check(T.badges() == ('|4 / %d TROPHIES|LOCKED|LOCKED||'):format(NCUPS), 'home: 150cc and 200cc locked (' .. T.badges() .. ')')
T.clickTitle('150CC'); M.tick(3)
T.check(T.titles():find('^50CC|100CC') ~= nil, 'a locked class can\'t be entered')
T.clickTitle('100CC'); M.tick(3)
local b = T.badges()
T.check(T.medals():find('^GOLD|GOLD|GOLD|GOLD||') ~= nil, '100cc: the four golds, Sentinel not raced (' .. T.medals() .. ')')
-- locked: the Galactic Cup and the title race
T.check(select(2, b:gsub('LOCKED', '')) == 2 and b:find('|LOCKED|LOCKED$') ~= nil, 'the Galactic Cup and the title race locked until five trophies (' .. b .. ')')
local n = M.called('LaunchQuickRace')
T.clickTitle('GALACTIC CUP'); M.tick(3)
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
local function cup()
  race()
  for i = 2, 4 do
    T.check(T.titles() == 'NEXT RACE' and T.badges() == ('RACE %d / 4'):format(i), 'standings: NEXT RACE ' .. i .. ' / 4 (' .. T.badges() .. ')')
    T.clickTitle('NEXT RACE')
    race()
  end
end
cup()
T.check(T.logHas('unlocked: 150cc, GALACTIC CUP at 100cc'), 'the fifth gold unlocks 150cc and the 100cc Galactic Cup')
T.check(T.save().best['100'].sentinel == 1, 'Sentinel gold saved')
T.clickTitle('CONTINUE'); M.tick(3)
b = T.badges()
T.check(T.medals():find('^GOLD|GOLD|GOLD|GOLD|GOLD|') ~= nil, '100cc: five golds (' .. T.medals() .. ')')
T.check(select(2, b:gsub('LOCKED', '')) == 1 and b:find('|LOCKED$') ~= nil, '100cc: the Galactic Cup open, the title race still locked (' .. b .. ')')
-- the Galactic Cup: four races on four planets; a trophy opens the title race
local mark = T.mark()
T.clickTitle('GALACTIC CUP')
T.check(T.logHas('LAUNCH EVT_DAL_LOOP_A_SHORT_06 (OVERFLOW RALLY', mark), 'the Galactic Cup starts on Overflow Rally')
cup()
T.check(T.logHas('unlocked: TITLE RACE at 100cc', mark), 'a Galactic Cup trophy unlocks the title race')
T.check(T.save().best['100'].galactic == 1, 'Galactic gold saved')
T.clickTitle('CONTINUE'); M.tick(3)
b = T.badges()
local ttd
for _, it in ipairs(rawget(_G, 'GU_TEST_SCREENS').SCREENS.cups().items) do if it.title == 'TITLE RACE' then ttd = it.desc end end
T.check(select(2, b:gsub('LOCKED', '')) == 0 and tostring(ttd):find('^vs ') ~= nil, '100cc: everything open, the title race names its opponent (v0.21: ' .. tostring(ttd) .. ')')
M.press('BACKSPACE'); M.tick(3)
T.check(T.badges() == ('|6 / %d TROPHIES||LOCKED||'):format(NCUPS), 'home: 6 / 6 trophies at 100cc, 150cc open, 200cc still locked (' .. T.badges() .. ')')
T.clickTitle('150CC'); M.tick(3)
b = T.badges()
T.check(T.titles() == 'JAKKU CUP|LANTAANA CUP|ANDO CUP|CRAIT CUP|SENTINEL CUP|GALACTIC CUP|TITLE RACE' and select(2, b:gsub('LOCKED', '')) == 2,
  '150cc: planet cups open, the Galactic Cup and title race locked (' .. b .. ')')
T.finish()
