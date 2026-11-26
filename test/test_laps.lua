-- v0.38.0 (owner 2026-11-25: "at the end of the track a 'best lap' time"; TASKS §1g-16): the standings say your best
-- lap beside your race time, NEW BEST LAP on a lap record (also after NEW RECORD, on the same row), and the lap's near
-- miss "0.4 S OFF YOUR LAP RECORD"; never on a sprint; config LapTimes = false = the v0.37 panel.
local M = require('mock')
local T = require('util')
T.boot({ version = 3, races = 0, cups = 0, class = 'riffraff', restores = {}, abilityRestores = {} })
local K = require('gp')
local cfg = require('config')
local SD = require('standings')

-- K.nearLap (Near.LapSeconds = 0.5)
T.check(cfg.Near.LapSeconds == 0.5 and cfg.LapTimes == true, 'defaults: LapSeconds 0.5, LapTimes on')
T.check(K.nearLap({ lapOffBy = 0.4 }) == '0.4 S OFF YOUR LAP RECORD', '0.4 s off the lap record')
T.check(K.nearLap({ lapOffBy = 0.7 }) == nil, '0.7 s: not close')
T.check(K.nearLap({ lapOffBy = 0 }) == 'LEVEL WITH YOUR LAP RECORD', 'equal')
T.check(K.nearLap({ lapOffBy = 0.2, newLap = true }) == nil and K.nearLap(nil) == nil, 'a new lap record is never "off"')

-- through K.record: lapOffBy / oldLap
local EV = '/Game/Griffin/Gameplay/Events/Planets/Mastiff/Loop_A/EVT_MAS_LOOP_A'
local ev = { path = EV, title = 'THE WAR FIELDS', class = 'riffraff', laps = 3 }
local me = { { name = 'Dwayne', you = true, pos = 1, finished = true } }
local o1 = K.record(ev, 1, me, { time = 100, lap = 32 })
T.check(o1.newLap and o1.newRecord and o1.lapOffBy == nil, 'first race: new record and new best lap')
local o2 = K.record(ev, 2, me, { time = 101, lap = 32.3 })
T.check(not o2.newLap and math.abs(o2.lapOffBy - 0.3) < 1e-9, 'slower lap: lapOffBy 0.3')
local o3 = K.record(ev, 1, me, { time = 99, lap = 31.5 })
T.check(o3.newLap and o3.oldLap == 32 and o3.newRecord, 'faster: new lap record, the old one kept in oldLap')
T.check(K.data.records.riffraff[EV].lap == 31.5, 'the save holds the new lap record')

local function textOf(spec)
  local t = {}
  for _, l in ipairs(spec.lines or {}) do t[#t + 1] = l[1] end
  for _, l in ipairs(spec.after or {}) do t[#t + 1] = l[1] end
  return table.concat(t, ' | ')
end
-- the standings (no cup run: the race lines alone)
local s2 = textOf(SD.spec(o2))
T.check(s2:find('2nd   -   ' .. K.fmtTime(101) .. '   -   best lap ' .. K.fmtTime(32.3), 1, true) ~= nil, 'your line: the race time, then the best lap (' .. s2 .. ')')
T.check(s2:find('1.0 S OFF YOUR RECORD   -   0.3 S OFF YOUR LAP RECORD', 1, true) ~= nil, 'the race and lap near misses share one row')
local s3 = textOf(SD.spec(o3))
T.check(s3:find('NEW RECORD  ' .. K.fmtTime(99) .. ', was ' .. K.fmtTime(100) .. '   -   NEW BEST LAP  ' .. K.fmtTime(31.5), 1, true) ~= nil,
  'NEW RECORD and NEW BEST LAP on the same row (' .. s3 .. ')')
-- a sprint: no lap anywhere
local spr = { path = EV .. '_P2P', title = 'SPRINT', class = 'riffraff', laps = 1 }
local os1 = K.record(spr, 1, me, { time = 60, lap = 60 })
local ss = textOf(SD.spec(os1))
T.check(not ss:find('best lap', 1, true) and not ss:find('BEST LAP', 1, true), 'a sprint: no best lap (' .. ss .. ')')
-- switch off: the old line, NEW BEST LAP only without a race record
cfg.LapTimes = false
local s3off = textOf(SD.spec(o3))
T.check(not s3off:find('best lap', 1, true) and not s3off:find('NEW BEST LAP', 1, true), 'LapTimes = false: no lap beside a new record (v0.37)')
local s2off = textOf(SD.spec(o2))
T.check(not s2off:find('LAP RECORD', 1, true), 'LapTimes = false: no lap near miss')
cfg.LapTimes = true
T.finish()
