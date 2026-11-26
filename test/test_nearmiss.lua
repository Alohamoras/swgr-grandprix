-- v0.12: near misses and the stakes line on the standings screen. K.nearRecord on its own (near, new record, DNF,
-- not close, equal), then a whole Riff-Raff Jakku Cup through the menu: the stakes line after races 1-3 (behind, level
-- on points, behind before the last race), "0.4 S OFF YOUR RECORD" on the same line as the new best lap, a new record
-- that doesn't also say "off your record", and "1 POINT FROM GOLD" on the cup result.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 3, races = 0, cups = 0, class = 'riffraff', restores = {}, abilityRestores = {} })
local K = require('gp')
local cfg = require('config')

-- K.nearRecord (Near.RecordSeconds = 1.0)
T.check(cfg.Near.RecordSeconds == 1.0, 'Near.RecordSeconds = 1.0')
T.check(K.nearRecord({ offBy = 0.4 }) == '0.4 S OFF YOUR RECORD', '0.4 s off')
T.check(K.nearRecord({ offBy = 0.96 }) == '1.0 S OFF YOUR RECORD', '0.96 s: within the threshold')
T.check(K.nearRecord({ offBy = 1.2 }) == nil, '1.2 s: not close, nothing')
T.check(K.nearRecord({ offBy = 0.03 }) == '0.03 S OFF YOUR RECORD', 'under 0.05 s: hundredths')
T.check(K.nearRecord({ offBy = 0 }) == 'LEVEL WITH YOUR RECORD', 'equal to the record')
T.check(K.nearRecord({ offBy = 0.4, newRecord = true }) == nil, 'a new record is never "off your record"')
T.check(K.nearRecord({}) == nil and K.nearRecord(nil) == nil, 'no time: nothing')
-- through K.record: offBy only for a finished race that didn't beat the record
local EV = '/Game/Griffin/Gameplay/Events/Planets/Mastiff/Loop_A/EVT_MAS_LOOP_A'
local ev = { path = EV, title = 'THE WAR FIELDS', class = 'riffraff' }
local me = { { name = 'Dwayne', you = true, pos = 1, finished = true } }
local out = K.record(ev, 1, me, { time = 100 })
T.check(out.newRecord and out.offBy == nil and K.nearRecord(out) == nil, 'the first time on a track: a new record, no near miss')
out = K.record(ev, 1, me, { time = 100.4 })
T.check(not out.newRecord and math.abs(out.offBy - 0.4) < 1e-9 and K.nearRecord(out) == '0.4 S OFF YOUR RECORD', 'a slower race: 0.4 S OFF YOUR RECORD')
out = K.record(ev, 1, me, { time = 99.5 })
T.check(out.newRecord and out.offBy == nil and K.nearRecord(out) == nil, 'a faster race: NEW RECORD only')
out = K.record(ev, nil, { { name = 'Dwayne', you = true, pos = 4, finished = false } }, { time = nil, lap = 30 })
T.check(out.offBy == nil and K.nearRecord(out) == nil, 'a DNF: no near miss')
cfg.Near.RecordSeconds = false
out = K.record(ev, 1, me, { time = 99.8 })
T.check(K.nearRecord(out) == nil, 'Near.RecordSeconds = false: off')
cfg.Near.RecordSeconds = 1.0
K.reset()

-- the standings screen: the texts set since a mark
local function textsSince(n0)
  local out = {}
  for i = n0, #M.calls do
    local c = M.calls[i]
    if c.name == 'SetText' and type(c.args[1]) == 'table' then
      local s = rawget(rawget(c.args[1], '__props') or {}, '__text')
      if s then out[#out + 1] = s end
    end
  end
  return out
end
local function has(texts, s) for _, t in ipairs(texts) do if t == s then return true end end return false end
local function find(texts, pat) for _, t in ipairs(texts) do if t:find(pat, 1, true) then return t end end return nil end

-- records on the cup's tracks: race 1 at 2:00.00 / lap 0:59.00, race 2 at 2:00.00, race 4 at 1:50.00 (never close)
-- (v0.26: the cup's draw - the tests' fixed rnd draws the same four when the cup is picked below)
local R = K.draw('jakku')
K.data.records['riffraff'] = { [R[1].path] = { time = 120, lap = 59 }, [R[2].path] = { time = 120 }, [R[4].path] = { time = 110 } }
K.save()

-- a race: you finish `you`; bots[i] (W.BOT_NAMES: 1 Biddy Blas, 2 Kestar Bool, ...) in `order` (bot indices, best first)
-- take the other places
local function race(you, order, time, lap)
  W.race(11); M.tick(5)
  local used, p = {}, 1
  for _, i in ipairs(order) do
    if p == you then p = p + 1 end
    W.botFinish(i, p); used[i] = true; p = p + 1
  end
  for i = 1, #W.bots do
    if not used[i] then
      if p == you then p = p + 1 end
      W.botFinish(i, p); p = p + 1
    end
  end
  M.tick(5); W.finish(you, time, lap); M.tick(25)
  local t0 = os.time(); while os.time() - t0 < 3 do end
  local n0 = #M.calls + 1
  W.backToMenu(); M.tick(45)
  return textsSince(n0)
end

M.press('F6'); M.tick(6)
T.clickTitle('JUNKER'); M.tick(3)
T.clickTitle('JAKKU CUP')
-- race 1: Biddy Blas 1st, you 2nd (12 v 15), 0.4 s off the record with a better lap
local tx = race(2, { 1, 2 }, 120.4, 58.5)
T.check(T.titles() == 'NEXT RACE', 'race 1: the standings')
T.check(has(tx, '3 POINTS BEHIND BIDDY BLAS, 3 RACES LEFT'), 'race 1: the stakes line (' .. tostring(find(tx, 'BEHIND') or find(tx, 'LEADING')) .. ')')
T.check(has(tx, '0.4 S OFF YOUR RECORD   -   NEW BEST LAP  0:58.50'), 'race 1: the near miss and the best lap on one line (' .. tostring(find(tx, 'RECORD')) .. ')')
T.clickTitle('NEXT RACE')
-- race 2: you 1st, Biddy Blas 2nd (27 each, you ahead on the latest race); a new record
tx = race(1, { 1, 2 }, 118.0)
T.check(has(tx, 'LEVEL ON POINTS WITH BIDDY BLAS, 2 RACES LEFT'), 'race 2: level on points (' .. tostring(find(tx, 'LEVEL') or find(tx, 'BEHIND') or find(tx, 'LEADING')) .. ')')
T.check(find(tx, 'NEW RECORD  1:58.00, was 2:00.00') ~= nil and find(tx, 'OFF YOUR RECORD') == nil, 'race 2: NEW RECORD, and not "off your record"')
T.clickTitle('NEXT RACE')
-- race 3: Biddy Blas 1st, you 2nd (39 v 42), no record yet on this track: a new record, no near miss
tx = race(2, { 1, 2 }, 130.0)
T.check(has(tx, '3 POINTS BEHIND BIDDY BLAS, 1 RACE LEFT'), 'race 3: behind before the last race (' .. tostring(find(tx, 'BEHIND') or find(tx, 'LEADING')) .. ')')
T.check(find(tx, 'NEW RECORD  2:10.00') ~= nil and find(tx, 'OFF YOUR RECORD') == nil, 'race 3: the first time on a track is a record, no near miss')
T.clickTitle('NEXT RACE')
-- race 4: Kestar Bool 1st, you 2nd, Biddy Blas 3rd: Biddy 52, you 51 -> silver, 1 point from gold; 5 s off the record
tx = race(2, { 2, 1 }, 115.0)
T.check(T.titles() == 'CONTINUE' and T.save().best['riffraff'].jakku == 2, 'race 4: the cup result, silver')
T.check(find(tx, '1 POINT FROM GOLD') ~= nil, 'the cup result: 1 POINT FROM GOLD (' .. tostring(find(tx, 'FROM') or find(tx, 'RECORD')) .. ')')
T.check(find(tx, 'OFF YOUR RECORD') == nil and find(tx, 'RACES LEFT') == nil and find(tx, 'RACE LEFT') == nil, 'the cup result: no stakes line, 5 s off is not close')
T.finish()
