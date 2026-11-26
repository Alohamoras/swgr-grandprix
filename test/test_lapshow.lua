-- v0.39.0 (TASKS §1g-16): TIME TO BEAT through the countdown (lapshow.lua). The text from the save's lap record; no
-- job on a finale or a title race; off with config TimeToBeat.On = false. (The drawing itself is game-only: KNOWLEDGE.md.)
local M = require('mock')
local T = require('util')
T.boot({ version = 3, races = 0, cups = 0, class = 'riffraff', restores = {}, abilityRestores = {} })
local K = require('gp')
local cfg = require('config')
local LS = require('lapshow')

local EV = '/Game/Griffin/Gameplay/Events/Planets/Mastiff/Loop_A/EVT_MAS_LOOP_A'
local ev = { path = EV, title = 'THE WAR FIELDS', class = 'riffraff', laps = 3 }
T.check(LS.on() and cfg.TimeToBeat.Route == 'viewport', 'on by default, the viewport route')
T.check(LS.text(ev) == 'NO LAP SET', 'no record yet: NO LAP SET')
K.record(ev, 1, { { name = 'Dwayne', you = true, pos = 1, finished = true } }, { time = 100, lap = 72.4 })
T.check(LS.text(ev) == 'TIME TO BEAT  ' .. K.fmtTime(72.4), 'the lap record: ' .. tostring(LS.text(ev)))
T.check(LS.text({ path = EV, title = 'X', class = 'ace' }) == 'NO LAP SET', 'records are per league')
local job = LS.start(ev)
T.check(job and job.text:find('TIME TO BEAT', 1, true) and not job.done, 'a job at launch')
T.check(LS.start({ path = EV, class = 'riffraff', boss = true }) == nil, 'not on the finale')
T.check(LS.start({ path = EV, class = 'riffraff', titleRace = true }) == nil, 'not on a title race')
-- the tick: no countdown widget in the mock world - nothing drawn; the start ends the job
local r = { ls = job, startedAt = nil }
LS.tick(r)
T.check(not job.ref and not job.done, 'no countdown widget: nothing drawn, still waiting')
r.startedAt = 1
job.last = -1e9
LS.tick(r)
T.check(job.done, 'the green light ends the job')
cfg.TimeToBeat.On = false
T.check(LS.start(ev) == nil, 'TimeToBeat.On = false: off')
cfg.TimeToBeat.On = true
-- the lap line (off by default)
T.check(not LS.lapOn() and cfg.TimeToBeat.LapLine == false, 'the lap line is off by default')
T.check(LS.lapText(2, 48.92, 48.57) == 'LAP 2   ' .. K.fmtTime(48.92) .. '   +0.35', 'a slower lap: +0.35 (' .. tostring(LS.lapText(2, 48.92, 48.57)) .. ')')
local s, best = LS.lapText(3, 48.1, 48.57)
T.check(s == 'NEW BEST LAP  ' .. K.fmtTime(48.1) and best, 'a faster lap: NEW BEST LAP')
T.check(LS.lapText(1, 50, nil) == 'LAP 1   ' .. K.fmtTime(50), 'no record: the time alone')
T.check(LS.lapText(1, 0, 40) == nil, 'no time: nothing')
T.finish()
