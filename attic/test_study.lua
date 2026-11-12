-- v0.16: study mode (test-only, studymode.lua). Nothing happens without study.lua; with it (found within 5 s at the
-- menu) each job's single race launches at the main menu with the class's parts and the job's AI profile, no cup;
-- a result line per job in the log and a CSV row; the AI config and tune put back after each; the page is closed
-- first when open; "all N jobs done" at the end and nothing more.
local M = require('mock')
local W = require('world')
local T = require('util')

for _, f in ipairs({ 'study.lua', 'study_state.lua', 'study_results.csv' }) do os.remove(T.dir .. '/' .. f) end
T.boot({ version = 2, races = 5, cups = 0, class = '50', best = {}, restores = {}, abilityRestores = {} }, { Progression = { On = false } })
local cfg = require('config')
local function exists(name) local f = io.open(T.dir .. '/' .. name, 'r'); if f then f:close() end; return f ~= nil end
local function wait3() local t0 = os.time(); while os.time() - t0 < 3 do end end

-- nothing without study.lua
local mark = T.mark()
M.tick(80)
T.check(M.called('LaunchQuickRace') == 0, 'no study.lua: nothing launched')
T.check(not T.logHas('[study]', 1), 'no study.lua: no [study] lines')
T.check(not exists('study_state.lua') and not exists('study_results.csv'), 'no study.lua: no study files written')

-- the study: job 1 at 150cc (a full profile), job 2 at 100cc (catch-up only)
local f = io.open(T.dir .. '/study.lua', 'w')
f:write([[return {
  { class = '150', cup = 'jakku', race = 1, label = 'p1 honest catch0.8',
    ai = { pressure = 1, pacing = { MaxAiSlowdownScale = 1.0, MaxAiCatchupScale = 0.8 }, errors = 0.25, perfectStart = 90,
      ops = { AiAbilityChanceMultiplier = { 0.5, 2 } } } },
  { class = '100', cup = 'lantaana', race = 2, label = '100, catch x0.5', ai = { pressure = 0, catchup = 0.5 } },
}
]])
f:close()
mark = T.mark()
M.tick(26)
T.check(T.logHas('[study] study.lua found: 2 jobs, next job 1', mark), 'study.lua found within 5 s at the menu')
T.check(M.called('LaunchQuickRace') == 0, 'no launch before the menu settled')
M.tick(30)
T.check(M.called('LaunchQuickRace') == 1, 'job 1 launched')
local ev1 = cfg.Cups[1].races['150'][1]
T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name') == ev1.path:match('([^/]+)$'), 'job 1: Jakku race 1 at 150cc (' .. ev1.title .. ')')
local p150 = cfg.Classes[3].parts
T.check(T.levels('VBD_Car_Base') == ('0=%d 1=%d 2=%d 3=%d 4=%d 5=%d'):format(p150, p150, p150, p150, p150, p150), 'job 1: 150cc parts on the build')
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 1 and W.ai.DefaultPacingSettings.MaxAiCatchupScale == 0.8
  and W.ai.ForcedErrorChance == 3.75 and W.ai.DefaultPercentageChancePerfectStart == 90, 'job 1: the job\'s AI config written (honest, catch-up 0.8, errors 3.75, perfect start 90)')
T.check(T.logHas("[study] job 1/2 'p1 honest catch0.8' start: " .. ev1.title .. ' 150cc (jakku race 1), AI errors=0.25 ops.AiAbilityChanceMultiplier=0.5/2 pacing.MaxAiCatchupScale=0.8 pacing.MaxAiSlowdownScale=1 perfectStart=90 pressure=1'), 'job 1 start logged')
T.check(T.logHas('[ai] class 150 (study profile): pressure 1.00 (HARD)'), 'the study profile\'s pressure')
local sv = T.save()
T.check(sv.run == nil, 'no cup run created')
local st = dofile(T.dir .. '/study_state.lua')
T.check(st.next == 1 and st.started == 1 and st.tries == 1, 'state: job 1 started')

-- job 1's race: the tune ops are the job's (pressure 1 + the explicit op)
local confs = W.tune(2)
W.race(11); M.tick(5)
T.check(math.abs(confs[1].AiMaxTimeAheadModifier - 2.5) < 1e-9 and math.abs(confs[1].AiAbilityChanceMultiplier - 3.5) < 1e-9,
  'job 1 tune: max time ahead +2.5, ability chance (1 x 1 + 0.5) x 2 + 1.5 = 3.5')
W.finish(1, 151.37, 50.1)
local times = { 162.54, 164.37, 165, 166, 171.57, 172, 173, 180, 185, 190, 195.47 }
for i = 1, 11 do W.botFinish(i, i + 1, times[i]) end
M.tick(25); wait3()
W.backToMenu(); M.tick(5)
T.check(T.logHas("[study] job 1/2 'p1 honest catch0.8' " .. ev1.title .. ' 150cc: you 1st 2:31.37, P2 +11.17 s (Biddy Blas), P3 +13.0, P6 +20.2, P12 +44.1, AI spread 32.9 s'),
  'job 1 result line')
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75 and W.ai.DefaultPacingSettings.MaxAiCatchupScale == 1.3 and W.ai.ForcedErrorChance == 15
  and W.ai.DefaultPercentageChancePerfectStart == 75, 'job 1: DA_AIConfig put back')
T.check(confs[1].AiMaxTimeAheadModifier == 0 and confs[1].AiAbilityChanceMultiplier == 1, 'job 1: tune put back')
T.check(T.levels('VBD_Car_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'job 1: build put back')
sv = T.save()
T.check(sv.run == nil and next(sv.best) == nil and sv.cups == 0 and sv.races == 6, 'no cup, no trophy; the race counted')
T.check(sv.records['150'] and sv.records['150'][ev1.path] and sv.records['150'][ev1.path].time == 151.37, 'the record written as usual')
st = dofile(T.dir .. '/study_state.lua')
T.check(st.next == 2 and st.started == nil, 'state: next job 2')
T.check(not T.logHas('[menu] standings') and not T.logHas('[menu] titleResult'), 'no result page opened for a study race')

-- our page open when job 2 is due: closed first, then the launch (the settle stretched so the tab can come back first)
require('studymode').SETTLE_MS = 9000
M.tick(18)
M.press('F6'); M.tick(6)
T.check(T.logHas('[menu] home'), 'page open')
mark = T.mark()
M.tick(40)
T.check(T.logHas('[menu] closed (study job)', mark), 'the page closed for the job')
T.check(M.called('LaunchQuickRace') == 2, 'job 2 launched')
local ev2 = cfg.Cups[2].races['100'][2]
T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name') == ev2.path:match('([^/]+)$'), 'job 2: Lantaana race 2 at 100cc (' .. ev2.title .. ')')
local p100 = cfg.Classes[2].parts
T.check(T.levels('VBD_Car_Base') == ('0=%d 1=%d 2=%d 3=%d 4=%d 5=%d'):format(p100, p100, p100, p100, p100, p100), 'job 2: 100cc parts')
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75 and math.abs(W.ai.DefaultPacingSettings.MaxAiCatchupScale - 0.65) < 1e-9
  and W.ai.ForcedErrorChance == 15, 'job 2: only catch-up x0.5 (job 1\'s values gone)')
confs = W.tune(1)
W.race(5); M.tick(5)
T.check(confs[1].AiMaxTimeAheadModifier == 0 and confs[1].AiAbilityChanceMultiplier == 1, 'job 2 tune: pressure 0 = the game\'s own')
W.finish(3, 120, 40)
local t2 = { { 1, 118.5 }, { 2, 119 }, { 4, 121 }, { 5, 122 }, { 6, 125.3 } }
for i, x in ipairs(t2) do W.botFinish(i, x[1], x[2]) end
M.tick(25); wait3()
W.backToMenu(); M.tick(5)
T.check(T.logHas("[study] job 2/2 '100, catch x0.5' " .. ev2.title .. ' 100cc: you 3rd 2:00.00, P1 -1.50 s (Biddy Blas), P2 -1.0, P6 +5.3, P12 -, AI spread 6.8 s'),
  'job 2 result line (not 1st: the winner first, negative; no 12th)')
T.check(W.ai.DefaultPacingSettings.MaxAiCatchupScale == 1.3, 'job 2: put back')
M.tick(60)
T.check(T.logHas('[study] all 2 jobs done'), 'all done logged')
T.check(M.called('LaunchQuickRace') == 2, 'nothing more launched')
M.tick(60)
local n = 0
for _, l in ipairs(M.log) do if l:find('[study] all 2 jobs done', 1, true) then n = n + 1 end end
T.check(n == 1, 'all done logged once')

-- the CSV
local lines = {}
for l in io.lines(T.dir .. '/study_results.csv') do lines[#lines + 1] = l end
T.check(#lines == 3, 'csv: header + 2 rows (' .. #lines .. ')')
T.check(lines[1] == 'job,label,class,event,your_pos,your_time,gap_p1,gap_p2,gap_p3,gap_p6,gap_p12,ai_spread,settings', 'csv header')
T.check(lines[2] == ('1,p1 honest catch0.8,150cc,%s,1,151.37,0.00,11.17,13.00,20.20,44.10,32.93,errors=0.25 ops.AiAbilityChanceMultiplier=0.5/2 pacing.MaxAiCatchupScale=0.8 pacing.MaxAiSlowdownScale=1 perfectStart=90 pressure=1'):format(ev1.title),
  'csv row 1: ' .. lines[2])
T.check(lines[3] == ('2,"100, catch x0.5",100cc,%s,3,120.00,-1.50,-1.00,0.00,5.30,,6.80,catchup=0.5 pressure=0'):format(ev2.title), 'csv row 2: ' .. lines[3])
T.check(T.save().run == nil, 'still no cup')
T.finish()
