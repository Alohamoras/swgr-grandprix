-- v0.16: study mode resumes from study_state.lua after a restart (an interrupted job runs again, once more at most);
-- a bad job and a failed launch are logged and skipped; then "all N jobs done".
local M = require('mock')
local W = require('world')
local T = require('util')

local function write(name, text) local f = io.open(T.dir .. '/' .. name, 'w'); f:write(text); f:close() end
os.remove(T.dir .. '/study_results.csv')
write('study.lua', [[return {
  { class = '50', cup = 'jakku', race = 1, label = 'done before the restart', ai = { pressure = -1 } },
  { class = '100', cup = 'jakku', race = 1, label = 'interrupted', ai = { pressure = 0.25 } },
  { class = '100', cup = 'nope', race = 1, label = 'bad cup' },
  { class = '150', cup = 'crait', race = 1, label = 'launch fails', ai = { errors = 2 } },
}
]])
-- the game closed in job 2's race
write('study_state.lua', 'return { next = 2, started = 2, tries = 1 }\n')
T.boot({ version = 2, races = 0, cups = 0, best = {}, restores = {}, abilityRestores = {} }, { Progression = { On = false } })
local cfg = require('config')
T.check(T.logHas('[study] study.lua: 4 jobs, next job 2'), 'resumes at job 2')
M.tick(40)
T.check(M.called('LaunchQuickRace') == 1, 'job 2 launched (job 1 not again)')
T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name') == cfg.Cups[1].races['100'][1].path:match('([^/]+)$'), 'job 2: Jakku race 1 at 100cc')
T.check(T.logHas("[study] job 2/4 'interrupted' start: ") and T.logHas('- try 2 (the last one was interrupted)'), 'the second try logged')
local st = dofile(T.dir .. '/study_state.lua')
T.check(st.next == 2 and st.tries == 2, 'state: job 2, try 2')
W.race(3); M.tick(5)
W.finish(2, 100, 30)
W.botFinish(1, 1, 99.5); W.botFinish(2, 3, 101); W.botFinish(3, 4, 104)
M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu()
-- the next launch fails
rawget(W.fe, '__props').LaunchQuickRace = function() error('no launch today') end
M.tick(5)
T.check(not T.logHas("[study] job 3/4"), 'the next job waits for the menu to settle')
M.tick(30)
T.check(T.logHas("[study] job 2/4 'interrupted' THE WAR FIELDS (REVERSE) 100cc: you 2nd 1:40.00, P1 -0.50 s (Biddy Blas), P3 +1.0, P6 -, P12 -, AI spread 4.5 s"), 'job 2 result logged')
T.check(T.logHas("[study] job 3/4 'bad cup' skipped: no cup nope"), 'a job with an unknown cup is skipped')
M.tick(40)
T.check(T.logHas("[study] job 4/4 'launch fails' launch failed, skipped: Launch failed"), 'a failed launch is logged and skipped')
T.check(W.ai.ForcedErrorChance == 15 and next(T.save().aiRestores) == nil, 'the failed launch put the AI config back')
T.check(T.logHas('[study] all 4 jobs done'), 'all done')
st = dofile(T.dir .. '/study_state.lua')
T.check(st.next == 5 and st.done == true, 'state: done')
local n = 0
for _ in io.lines(T.dir .. '/study_results.csv') do n = n + 1 end
T.check(n == 2, 'csv: header + the one finished job')

-- a job interrupted twice is skipped
write('study_state.lua', 'return { next = 2, started = 2, tries = 2 }\n')
require('studymode').s.state = nil
require('studymode').s.jobs = nil
require('studymode').s.checkedAt = -1e9
rawget(W.fe, '__props').LaunchQuickRace = function() end
M.tick(40)
T.check(T.logHas("[study] job 2/4 'interrupted' skipped: its race was interrupted 2 times"), 'interrupted twice: skipped')
T.finish()
