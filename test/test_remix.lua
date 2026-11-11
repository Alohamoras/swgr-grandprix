-- v0.6.2 remix cups; owner 2026-11-10: they open from 150cc (Progression.RemixClass; the summit gates nothing).
-- After a trophy in all five planet cups at 150cc they're open at every class; a remix cup launches its own remix
-- events and has its own trophy. (v0.8 flow: Select on a cup tile launches its next race; B goes home.)
local M = require('mock')
local W = require('world')
local T = require('util')
local five = function(v) return { jakku = v, lantaana = v, ando = v, crait = v, sentinel = v } end
-- the badge of the tile titled `title` (nil = no such tile)
local function badgeOf(title)
  local titles, badges = {}, {}
  for s in (T.titles() .. '|'):gmatch('([^|]*)|') do titles[#titles + 1] = s end
  for s in (T.badges() .. '|'):gmatch('([^|]*)|') do badges[#badges + 1] = s end
  for i, s in ipairs(titles) do if s == title then return badges[i] or '' end end
  return nil
end
T.boot({ version = 2, races = 60, cups = 15, class = '150', vehicle = 'car',
  best = { ['100'] = five(1), ['150'] = { jakku = 2, lantaana = 2, ando = 2, crait = 2 } },
  restores = {}, abilityRestores = {} })
M.press('F6'); M.tick(6)
T.clickTitle('150CC'); M.tick(3)
local t = T.titles()
T.check(t:find('JAKKU REMIX|LANTAANA REMIX|ANDO REMIX|CRAIT REMIX|SENTINEL REMIX', 1, true) ~= nil and t:find('SENTINEL CONDITIONS', 1, true) ~= nil,
  'the five remix cups and the conditions cups on the cups page (' .. t .. ')')
T.check(badgeOf('JAKKU REMIX') == 'LOCKED' and badgeOf('SENTINEL REMIX') == 'LOCKED' and badgeOf('OUTER RIM CUP') == 'LOCKED'
  and badgeOf('SENTINEL CONDITIONS') == 'LOCKED', 'four 150cc silvers: remix, bonus and conditions cups locked (' .. T.badges() .. ')')
local n = M.called('LaunchQuickRace')
T.clickTitle('JAKKU REMIX'); M.tick(3)
T.check(M.called('LaunchQuickRace') == n and T.titles():find('JAKKU CUP', 1, true) ~= nil, 'a locked remix cup can\'t be started')
T.clickTitle('SENTINEL CUP')
T.check(M.called('LaunchQuickRace') == n + 1, 'the Sentinel Cup starts (race 1)')
W.race(11); M.tick(5); W.finish(3); M.tick(25)
-- the trophy needs the cup over: finish it quickly (4 races)
for _ = 1, 3 do
  local t0 = os.time(); while os.time() - t0 < 3 do end
  W.backToMenu(); M.tick(45)
  T.clickTitle('NEXT RACE')
  W.race(11); M.tick(5); W.finish(1); M.tick(25)
end
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.logHas('unlocked: 200cc, ') and T.logHas('REMIX CUPS'), 'the fifth 150cc trophy unlocks 200cc and the remix cups')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(badgeOf('JAKKU REMIX') ~= 'LOCKED' and badgeOf('SENTINEL REMIX') ~= 'LOCKED' and badgeOf('OUTER RIM CUP') == 'LOCKED',
  'remix cups open at 150cc, the bonus cups still locked there (' .. T.badges() .. ')')
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('100CC'); M.tick(3)
T.check(badgeOf('JAKKU REMIX') ~= 'LOCKED' and badgeOf('OUTER RIM CUP') ~= 'LOCKED' and badgeOf('JAKKU CONDITIONS') ~= 'LOCKED'
  and select(2, T.badges():gsub('LOCKED', '')) == 0, '... and at 100cc, where everything is open (' .. T.badges() .. ')')
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('200CC'); M.tick(3)
T.check(T.titles():find('JAKKU CUP', 1, true) ~= nil and badgeOf('JAKKU REMIX') ~= 'LOCKED' and badgeOf('OUTER RIM CUP') == 'LOCKED'
  and badgeOf('JAKKU CONDITIONS') == 'LOCKED', '... and at 200cc, just opened: its bonus and conditions cups locked (' .. T.badges() .. ')')
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('100CC'); M.tick(3)
local mark = T.mark()
T.clickTitle('JAKKU REMIX')
T.check(T.logHas("LAUNCH EVT_MAS_LOOP_A_REV (THE WAR FIELDS (REVERSE) - Circuit) class=100", mark), 'race 1 = The War Fields reversed')
T.check(T.save().run.cup == 'jakku_remix', 'the remix cup is its own cup in the save')
T.finish()
