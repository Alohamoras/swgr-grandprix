-- v0.11: conditions folded into the cups. One cup per planet with a race list per class (50cc classic, 100cc reverse,
-- 150cc conditions, 200cc = the 150cc lists), the Galactic Cup, the title race: 7 tiles. The old remix / conditions /
-- Outer Rim results are dropped from the save at the first load (one log line), records kept.
local M = require('mock')
local W = require('world')
local T = require('util')
local EV = '/Game/Griffin/Gameplay/Events/Planets/'
local REV = EV .. 'Mastiff/Loop_A/EVT_MAS_LOOP_A_REV'
local SNOW = EV .. 'Corgi/Loop_A/EVT_COR_Loop_A_REV_Overcast_Snow' -- (a remix-cup event no cup races any more)
-- the owner's save shape (2026-11-11): best['100'].crait_remix = 1 and jakku_remix = 4, plus every other kind of
-- old entry
T.boot({ version = 2, races = 80, cups = 12, class = '100', vehicle = 'car',
  best = { ['50'] = { jakku = 1, outerrim = 2 }, ['100'] = { jakku = 1, lantaana = 2, crait_remix = 1, jakku_remix = 4 },
    ['150'] = { jakku_cond = 1, sentinel = 3 } },
  perfect = { ['100'] = { jakku = true, crait_remix = true } },
  standings = { ['100'] = { jakku = { YOU = 60, ['Katja Mox'] = 40 }, jakku_remix = { YOU = 20, ['Katja Mox'] = 50 } } },
  records = { ['100'] = { [REV] = { time = 120.5, lap = 55, at = '2026-11-10', vehicle = 'car' },
    [SNOW] = { time = 130, lap = 60, at = '2026-11-10', vehicle = 'car' } } },
  restores = {}, abilityRestores = {} }, { Progression = { On = false } })

-- the save migration
local want = '[cups] dropped from the save (remix, conditions and Outer Rim cups are gone; records kept): best 50 outerrim, '
  .. 'best 100 crait_remix, best 100 jakku_remix, best 150 jakku_cond, perfect 100 crait_remix, standings 100 jakku_remix'
T.check(T.logHas(want), 'one log line lists what was dropped')
local n = 0
for _, l in ipairs(M.log) do if l:find('[cups] dropped', 1, true) then n = n + 1 end end
T.check(n == 1, 'logged once (' .. n .. ')')
local sv = T.save()
T.check(sv.best['100'].crait_remix == nil and sv.best['100'].jakku_remix == nil and sv.best['50'].outerrim == nil
  and sv.best['150'].jakku_cond == nil, 'the remix, conditions and Outer Rim results are gone from the save file')
T.check(sv.best['50'].jakku == 1 and sv.best['100'].jakku == 1 and sv.best['100'].lantaana == 2 and sv.best['150'].sentinel == 3,
  'the planet cups\' results kept')
T.check(sv.perfect['100'].jakku == true and sv.perfect['100'].crait_remix == nil, 'perfect: Jakku kept, the remix cup dropped')
T.check(sv.standings['100'].jakku.YOU == 60 and sv.standings['100'].jakku_remix == nil, 'standings: Jakku kept, the remix cup dropped')
T.check(sv.records['100'][REV].time == 120.5 and sv.records['100'][SNOW].time == 130, 'records kept (per event path), even for an event no cup races')
T.check(sv.races == 80 and sv.cups == 12, 'counts kept')
-- a second load: nothing left to drop, nothing logged
local K = require('gp')
local mark = T.mark()
K.load()
T.check(not T.logHas('[cups] dropped', mark), 'the next load drops nothing')

-- the cups page: 7 tiles at every class, the race list of that class
local function descs()
  local all = {}
  for _, t in ipairs(W.tiles or {}) do
    local d = rawget(t, '__props').TxtDescription
    all[#all + 1] = d and rawget(d, '__props').__text or ''
  end
  return all
end
M.press('F6'); M.tick(6)
local ALL = 'JAKKU CUP|LANTAANA CUP|ANDO CUP|CRAIT CUP|SENTINEL CUP|GALACTIC CUP|TITLE RACE'
for _, cls in ipairs({ '50CC', '100CC', '150CC', '200CC' }) do
  T.clickTitle(cls); M.tick(3)
  T.check(T.titles() == ALL, cls .. ': the 7 tiles (' .. T.titles() .. ')')
  local d = descs()
  -- (v0.14: the tile names the conditions under your best - the conditions alone when both don't fit; the races
  -- themselves are in the focused cup's info line)
  if cls == '150CC' or cls == '200CC' then
    T.check(d[1]:find('\nDawn, scorching$') ~= nil and d[2]:find('\nNight, wet$') ~= nil and d[3]:find('\nNight, snow$') ~= nil
      and d[4]:find('\nMines, night$') ~= nil and d[5] == 'Blue hour, overcast, storm',
      cls .. ': each planet tile names its conditions (' .. table.concat(d, ' / '):gsub('\n', ' ') .. ')')
    T.check(d[6] == 'Not raced yet', cls .. ': the Galactic Cup has none: your best only (' .. d[6] .. ')')
  else
    T.check(not d[1]:find('\n') and not d[2]:find('\n') and not d[3]:find('\n'), cls .. ': no conditions, your best only (' .. d[1] .. ')')
  end
  M.press('BACKSPACE'); M.tick(3)
end

-- a cup races its class's list: Jakku at 100cc opens reversed; Ando at 200cc races the 150cc list
T.clickTitle('100CC'); M.tick(3)
mark = T.mark()
T.clickTitle('JAKKU CUP')
T.check(T.logHas('LAUNCH EVT_MAS_LOOP_A_REV (THE WAR FIELDS (REVERSE) - Circuit) class=100', mark), '100cc Jakku: race 1 = The War Fields reversed')
T.check(T.save().run.cup == 'jakku' and T.save().run.races == 4, 'the planet cup, four races')
W.race(11); M.tick(5); W.finish(2); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
mark = T.mark()
T.clickTitle('NEXT RACE')
T.check(T.logHas("LAUNCH EVT_MAS_P2P_FWD (THE GIANTS' GRAVEYARD - Sprint) class=100", mark), 'race 2 from the 100cc list')
W.race(11); M.tick(5); W.finish(2); M.tick(25)
t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
M.press('BACKSPACE'); M.tick(5)
T.clickTitle('YES'); M.tick(3)
T.check(T.save().run == nil, 'left the cup')
T.clickTitle('200CC'); M.tick(3)
mark = T.mark()
T.clickTitle('ANDO CUP')
T.check(T.logHas('LAUNCH EVT_COR_Loop_A_FWD_Night (ICE FIELD CIRCUIT (NIGHT) - Circuit) class=200', mark), '200cc Ando: the 150cc list, Ice Field at night')
T.finish()
