-- v0.32: tune sets made at run time (tune.lua) and the per-bot thrust dial (AI.Thrust / experiment botThrust): built
-- from the Shield tune set's class, the ops filled in, applied to the pawn with RequestApplyTuneSet; the thrust set
-- goes on each bot after the start grace, the bots' top speed logged before and after.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } })
local TU = require('tune')
local R = require('race')
local cfg = require('config')
local function wait3() local t0 = os.time(); while os.time() - t0 < 3 do end end

-- the fake engine: a constructed tune set carries an Operations array
local made = {}
_G.StaticConstructObject = function(cls, outer)
  local ops = {}
  local ts = M.new('TNS_made_' .. M.nextAddr, { Operations = M.tarr(ops) }, 'TuneSet')
  made[#made + 1] = { ts = ts, ops = ops, outer = outer }
  return ts
end
local pawn = M.new('pawn', { TuneComponent = M.new('tc', { SetsApplied = M.tmap({}) }, 'VehicleTuneComponent') }, 'VehiclePawn')
local ts, txt = TU.set(pawn.TuneComponent, { { 'VehicleThrustConfig', 'MaxRPM', TU.OP.FloatMultiply, 1.1 },
  { 'VehicleHealthConfig', 'DamageToCrashVsWorld', TU.OP.FloatAdd, 1000 } }, 'test')
T.check(ts ~= nil and #made == 1 and made[1].outer == pawn.TuneComponent, 'a tune set made under the component')
T.check(#made[1].ops == 2 and made[1].ops[1].Category == 'VehicleThrustConfig' and made[1].ops[1].Property == 'MaxRPM'
  and made[1].ops[1].Operation == 7 and made[1].ops[1].FloatParam == 1.1 and made[1].ops[2].Operation == 3, 'its two ops as asked (category, property, op, value)')
T.check(txt == 'test: VehicleThrustConfig.MaxRPM op7 1.1, VehicleHealthConfig.DamageToCrashVsWorld op3 1000', 'described (' .. tostring(txt) .. ')')
T.check(TU.apply(pawn, ts) == 'RequestApplyTuneSet' and M.called('RequestApplyTuneSet') == 1, 'applied with the pawn\'s RequestApplyTuneSet')
-- no template: nil + why
local full = TU.TEMPLATE .. '.TNS_Condition_Shield'
local gone = M.new('TNS_Condition_Shield', {}, 'TuneSet'); rawset(gone, '__dead', true)
local keep = M.assets[full]; M.assets[full] = gone
local bad, why = TU.set(pawn.TuneComponent, {}, 'x')
M.assets[full] = keep
T.check(bad == nil and tostring(why):find('TuneSet class not found', 1, true) ~= nil, 'without the template: nil + why (' .. tostring(why) .. ')')

-- the thrust dial on the bots: AI.Thrust per league tier, applied 15 s after the start, top speeds logged
cfg.AI.Thrust = { Pilots = { Rager = 'elite', Antagonist = 'elite', ElegantProfessional = 'weak' }, challenger = { elite = 1.1, weak = 0.9 } }
cfg.AI.Grace = { Seconds = 15 }
made = {}
local ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'JAKKU', kind = 'Circuit' }, 'challenger', 'car')
T.check(ok == true, 'launched')
W.race(4)
local tops = { 300, 310, 320, 330 }
for i, b in ipairs(W.bots) do
  local p = rawget(b, '__props')
  rawget(p.PawnPrivate, '__props').TuneComponent = M.new('tc' .. i, { SetsApplied = M.tmap({}) }, 'VehicleTuneComponent')
  rawget(p.PawnPrivate, '__props').BodyState = { TopSpeedKmph = tops[i] }
end
local mark = T.mark()
M.tick(100) -- 10 s: nothing yet (the start grace)
T.check(#made == 0 and not T.logHas('[thrust]', mark), 'nothing before the start grace is over (10 s)')
M.tick(80) -- 18 s
T.check(#made == 3, 'three bots tuned (Biddy +, Kestar +, Katja -; Zed Unknown unlisted = as he is): ' .. #made)
local line = M.log[T.logAt('[thrust] challenger:', mark) or 0] or ''
T.check(line:find('Biddy Blas x1.1', 1, true) and line:find('Katja Mox x0.9', 1, true) and line:find('RequestApplyTuneSet', 1, true),
  'the thrust line names each bot, its factor and the call (' .. line:gsub('%s+$', '') .. ')')
local o = made[1].ops
T.check(#o == 4 and o[1].Category == 'VehicleThrustConfig' and o[1].Operation == 7 and o[1].FloatParam == 1.1 and o[4].Property == 'HighSpeedAcceleration',
  'the set: MaxRPM and the three accelerations x1.1')
-- the top speeds read again later
for i, b in ipairs(W.bots) do rawget(rawget(b, '__props').PawnPrivate, '__props').BodyState.TopSpeedKmph = tops[i] * 1.1 end
M.tick(220)
T.check(T.logHas('[thrust] top speeds 20 s on: Biddy Blas 300 -> 330', mark), 'the top speeds before and after logged')
W.finish(1); M.tick(25); wait3(); W.backToMenu(); M.tick(45)

-- experiment.lua's botThrust (DevTools): every bot the same factor, the config's tiers ignored
cfg.DevTools = true
cfg.AI.Thrust = false
local f = io.open(T.dir .. '/experiment.lua', 'w'); f:write("return { label = 'thrust', botThrust = 1.2 }\n"); f:close()
made = {}
mark = T.mark()
ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'JAKKU', kind = 'Circuit' }, 'challenger', 'car')
W.race(2)
for i, b in ipairs(W.bots) do
  rawget(rawget(b, '__props').PawnPrivate, '__props').TuneComponent = M.new('tc' .. i, { SetsApplied = M.tmap({}) }, 'VehicleTuneComponent')
end
M.tick(180)
T.check(#made == 2 and made[1].ops[1].FloatParam == 1.2 and T.logHas('[thrust] challenger: Biddy Blas x1.2', mark), 'experiment botThrust 1.2 on every bot')
os.remove(T.dir .. '/experiment.lua')
W.finish(1); M.tick(25); wait3(); W.backToMenu(); M.tick(45)
-- off: nothing
cfg.DevTools = false
made = {}
mark = T.mark()
ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'JAKKU', kind = 'Circuit' }, 'challenger', 'car')
W.race(2); M.tick(180)
T.check(#made == 0 and not T.logHas('[thrust]', mark), 'AI.Thrust = false and no experiment: no tune set')
W.finish(1); M.tick(25); wait3(); W.backToMenu(); M.tick(45)
T.finish()
