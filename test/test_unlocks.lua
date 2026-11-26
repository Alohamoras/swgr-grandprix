-- v0.5 / v0.8 / v0.11 / v0.26: unlocks in the menus. A save with four Riff-Raff golds: Challenger / Ace, the Galactic
-- Cup is a locked tile that says what opens it and can't be entered. Winning the fifth planet cup at Riff-Raff opens
-- Challenger and the Riff-Raff Galactic Cup, said on the cup result screen; (v0.33) a Galactic Cup trophy adds
-- Kestar's finale to the cup itself - no title race any more.
-- (v0.9: the Sentinel cup left in the save is dropped at boot and raced whole.)
local M = require('mock')
local W = require('world')
local T = require('util')

T.boot({ version = 3, races = 30, cups = 4, class = 'riffraff',
  best = { riffraff = { jakku = 1, lantaana = 1, ando = 1, crait = 1 } },
  run = { class = 'riffraff', cup = 'sentinel', vehicle = 'car', race = 4, races = 4,
    points = { YOU = 45, ['Katja Mox'] = 30 }, last = {}, history = { {}, {}, {} } },
  restores = {}, abilityRestores = {} })
local NCUPS = #dofile(T.dir .. '/Scripts/config.lua').Cups
T.check(T.logHas('[cup] sentinel JUNKER dropped at boot (race 4 of 4): cups cannot be resumed') and T.save().run == nil, 'the cup in the save dropped at boot')
M.press('F6'); M.tick(6)
T.check(T.locks() == '||LOCKED||' and T.pips('JUNKER') == 'GGGG----.', 'home: Ace locked (v0.27.2: Challenger open from the start); Riff-Raff: four golds as pips (' .. T.marks() .. ')')
T.clickTitle('ACE'); M.tick(3)
T.check(T.titles():find('JUNKER|CHALLENGER', 1, true) == 1, 'a locked league can\'t be entered')
T.clickTitle('JUNKER'); M.tick(3)
local b = T.badges()
T.check(T.medals():find('^GOLD|GOLD|GOLD|GOLD||') ~= nil, 'Riff-Raff: the four golds, Sentinel not raced (' .. T.medals() .. ')')
-- locked: the Galactic Cup (v0.33: no title race tile)
b = T.locks()
T.check(select(2, b:gsub('LOCKED', '')) == 1 and b:find('|LOCKED||$') ~= nil, 'the Galactic Cup locked until five trophies (the Rally Cup open) (' .. b .. ')')
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
T.check(T.logHas('unlocked: GALACTIC CUP at JUNKER'), 'the fifth gold unlocks the Riff-Raff Galactic Cup (v0.27.2: Challenger was open already)')
T.check(T.save().best.riffraff.sentinel == 1, 'Sentinel gold saved')
T.clickTitle('CONTINUE'); M.tick(3)
b = T.badges()
T.check(T.medals():find('^GOLD|GOLD|GOLD|GOLD|GOLD|') ~= nil, 'Riff-Raff: five golds (' .. T.medals() .. ')')
b = T.locks()
T.check(select(2, b:gsub('LOCKED', '')) == 0, 'Riff-Raff: the Galactic Cup open, nothing locked (' .. b .. ')')
-- the Galactic Cup: four races on four planets (the tests' draw: Jakku, Lantaana, Ando, then the finals); v0.33: a
-- trophy adds Kestar's finale as race 5 (test_finale has the detail)
local mark = T.mark()
T.clickTitle('GALACTIC CUP')
T.check(T.logHas('LAUNCH EVT_MAS_LOOP_A_REV_HARD (THE WAR FIELDS (REVERSE, SCORCHING)', mark), 'the Galactic Cup starts on its first race drawn')
T.check(T.drawn()[4] == 'EVT_WHP_LOOP_A_FWD_RACE', 'and ends on The Galactic Gauntlet')
cup()
T.check(T.logHas('the finale added as race 5: KESTAR BOOL', mark) and T.titles() == 'NEXT RACE' and T.badges() == 'RACE 5 / 5',
  'v0.33: a Galactic Cup trophy adds the finale as race 5 (' .. T.titles() .. ' ' .. T.badges() .. ')')
T.clickTitle('NEXT RACE')
W.race(1); M.tick(5); W.finish(1); M.tick(25)
do local t0 = os.time(); while os.time() - t0 < 3 do end end
W.backToMenu(); M.tick(45)
T.check(T.logHas('FINALE JUNKER: WON - you are the JUNKER champion vs Kestar Bool (try 1)', mark) and not T.logHas('unlocked: TITLE RACE', mark),
  'the finale won: the Junker champion; no title race to unlock')
T.check(T.save().best.riffraff.galactic == 1 and T.save().titles.riffraff.won == true, 'Galactic gold and the title saved')
T.clickTitle('CONTINUE'); M.tick(3)
b = T.badges()
T.check(select(2, b:gsub('LOCKED', '')) == 0 and not T.titles():find('TITLE RACE', 1, true), 'Riff-Raff: everything open, no title race tile')
M.press('BACKSPACE'); M.tick(3)
T.check(T.locks() == '||LOCKED||' and T.pips('JUNKER'):find('^[GSB][GSB][GSB][GSB][GSB][GSB]%-%-%*') ~= nil, 'home: 6 / 6 trophies at Riff-Raff and the champion\'s star, Challenger open, Ace still locked (' .. T.marks() .. ')')
T.clickTitle('CHALLENGER'); M.tick(3)
b = T.locks()
T.check(T.titles() == 'JAKKU CUP|LANTAANA CUP|ANDO CUP|CRAIT CUP|SENTINEL CUP|GALACTIC CUP|RALLY CUP|PODRACER CUP' and select(2, b:gsub('LOCKED', '')) == 1,
  'Challenger: planet cups open, the Galactic Cup locked (' .. b .. ')')
T.finish()
