-- v0.8: AI strength per class (ai.lua). Pressure -> rubber-band ops; the AI config asset written at launch and put
-- back at the menu (originals in the save); the tune objects changed while the race loads and put back at the menu.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } })
local A = require('ai')
local cfg = require('config')
-- v0.18: this test drives the mechanism with the v0.10-v0.17 profiles (pinned here); the real v0.18 profiles are
-- checked at the end
local REAL = cfg.AI.Profiles
cfg.AI.Profiles = {
  ['riffraff'] = { pressure = -1 },
  ['challenger'] = { pressure = 0.5, pacing = { MaxAiSlowdownScale = 1.0 }, errors = 0.5 },
  ['ace'] = { pressure = 0.5, pacing = { MaxAiSlowdownScale = 1.0 }, errors = 0.5 },
}

-- pressure -> ops
local o = A.opFor(0.5, 'AiMaxTimeAheadModifier')
T.check(math.abs(o[1] - 1.25) < 1e-9 and o[2] == 1, 'halfway to Nightmare adds 1.25 to MaxTimeAhead')
o = A.opFor(-1, 'AiMaxTimeAheadMultiplier')
T.check(math.abs(o[2] - 0.65) < 1e-9, 'Cadet multiplies MaxTimeAhead by 0.65')
o = A.opFor(1.5, 'AiAggressionVPlayerCooldownMultiplier')
T.check(math.abs(o[2] - 0.625) < 1e-9, 'between Nightmare and Champion the cooldown multiplier blends')
o = A.opFor(3, 'AiMaxTimeAheadModifier')
T.check(o[1] == 5, 'pressure above 2 is held at Champion')
T.check(A.pressure('riffraff') == -1 and A.pressure('challenger') == 0.5 and A.pressure('ace') == 0.5,
  'league pressures -1 / 0.5 / 0.5 (the pinned stand-ins)')
T.check(A.pressure('nope') == 0, 'an unknown class: the game\'s own')
cfg.AI.Adjust = 0.5
T.check(A.pressure('challenger') == 1 and A.pressure('ace') == 1 and A.pressure('riffraff') == -0.5, 'Adjust 0.5 moves every class up')
cfg.AI.Adjust = 2
T.check(A.pressure('ace') == 2, 'Adjust never takes a class past 2')
cfg.AI.Adjust = 0
T.check(math.abs(A.tuneValue('challenger', 'AiAbilityChanceMultiplier', 1) - 1.25) < 1e-9, '150cc: ability chance 1 -> 1.25')
T.check(A.tuneValue('riffraff', 'AiAbilityChanceMultiplier', 0.1) == 0, 'a multiplier never goes below 0')
cfg.AI.Profiles['challenger'].ops = { AiAbilityChanceMultiplier = { 0.5, 2 } }
T.check(math.abs(A.tuneValue('challenger', 'AiAbilityChanceMultiplier', 1) - 3) < 1e-9, 'an explicit op comes after the pressure (1.25 x 2 + 0.5)')
cfg.AI.Profiles['challenger'].ops = nil
T.check(A.label(-1) == 'RELAXED' and A.label(0) == 'NORMAL' and A.label(0.5) == 'TOUGH' and A.label(1.2) == 'HARD' and A.label(2) == 'CHAMPION', 'labels')

-- the AI config plan. v0.10: 200cc races the 150cc profile; the catch-up and perfect-start levers are still
-- tested here on a stand-in 200cc profile (the one it had up to v0.9), put back at the end of the test
local PRO200 = cfg.AI.Profiles['ace']
cfg.AI.Profiles['ace'] = { pressure = 1.2, pacing = { MaxAiSlowdownScale = 1.0 }, catchup = 1.15, errors = 0.5, perfectStart = 90 }
local p = A.plan('ace')
T.check(p['DefaultPacingSettings.MaxAiSlowdownScale'].set == 1 and math.abs(p['DefaultPacingSettings.MaxAiCatchupScale'].mul - 1.15) < 1e-9
  and p.ForcedErrorChance.mul == 0.5 and p.DefaultPercentageChancePerfectStart.set == 90, '200cc plan: honest, catch-up x1.15, errors x0.5, perfect start 90')
T.check(next(A.plan('riffraff')) == nil, 'Riff-Raff (stand-in): the AI config is left alone')
T.check(math.abs(A.planned(p['DefaultPacingSettings.MaxAiCatchupScale'], 1.3) - 1.495) < 1e-9, 'catch-up 1.3 x 1.15 = 1.495')

-- launch at 150cc: the asset written, the originals in the save
M.press('F6'); M.tick(6)
T.clickTitle('CHALLENGER'); M.tick(3)
T.clickTitle('JAKKU CUP')
T.check(M.called('LaunchQuickRace') == 1, 'launched')
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 1 and W.ai.ForcedErrorChance == 7.5, 'DA_AIConfig: honest pacing, errors halved')
T.check(W.ai.DefaultPacingSettings.MaxAiCatchupScale == 1.3 and W.ai.DefaultPercentageChancePerfectStart == 75 and W.ai.AggressionConfig.VersusPlayer.Chance == 50,
  '150cc: catch-up, perfect start and aggression untouched')
local sv = T.save()
local rest = sv.aiRestores and sv.aiRestores['/Game/Griffin/AI/DA_AIConfig']
T.check(rest and rest['DefaultPacingSettings.MaxAiSlowdownScale'] == 0.75 and rest.ForcedErrorChance == 15, 'originals in the save (aiRestores)')
T.check(T.logHas('[ai] league challenger: pressure 0.50 (TOUGH)'), 'pressure logged')
T.check(T.logHas('[ai] league challenger: AI config (DA_AIConfig) DefaultPacingSettings.MaxAiSlowdownScale 0.75 -> 1, ForcedErrorChance 15 -> 7.5'), 'AI config writes logged')

-- the race loads: three tune objects (in the game one shared asset + the fallback), changed once each
local confs, rtds = W.tune(3)
W.race(11); M.tick(5)
local c = confs[1]
T.check(math.abs(c.AiMaxTimeAheadModifier - 1.25) < 1e-9 and math.abs(c.AiMinTimeAheadModifier - 0.75) < 1e-9, 'rubber band: +1.25 s / +0.75 s')
T.check(math.abs(c.AiAbilityChanceMultiplier - 1.25) < 1e-9 and math.abs(c.AiAggressionVPlayerChanceMultiplier - 1.5) < 1e-9
  and math.abs(c.AiAggressionVPlayerCooldownMultiplier - 0.875) < 1e-9 and math.abs(c.AiCountdownToSlamPlayerModifier + 0.1) < 1e-9,
  'abilities 1.25, aggression 1.5, cooldown 0.875, slam -0.1')
T.check(c.AiMaxTimeAheadMultiplier == 1 and c.TotalCrashAllowance == 3, 'untouched fields stay (multiplier 1, crash allowance 3)')
T.check(math.abs(confs[3].AiMaxTimeAheadModifier - 1.25) < 1e-9, 'every tune object changed')
T.check(T.logHas('[ai] MaxTimeAheadModifier=0 MinTimeAheadModifier=0 MaxTimeAheadMultiplier=1'), 'one before -> after line')
T.check(T.logHas('[ai] applied to 3 tune objects (3 total)'), 'applied to 3 tune objects')
-- 3 s after the start it stops: a tune object appearing later is left alone, and nothing is swept any more
M.tick(40)
local late = W.tune(1)[1]
local mark = T.mark()
M.tick(10)
T.check(late.AiMaxTimeAheadModifier == 0 and not T.logHas('[ai] applied', mark), 'done 3 s after the start: a late tune object is left alone')
W.finish(2); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
-- the race world goes: tune object 3 is freed with it (1 and 2 live on, like the shared asset in game)
M.kill(rtds[3])
local before = M.deadTouches
W.backToMenu(); M.tick(45)
T.check(c.AiMaxTimeAheadModifier == 0 and confs[2].AiAbilityChanceMultiplier == 1 and c.AiAggressionVPlayerCooldownMultiplier == 1, 'tune put back at the menu')
T.check(M.deadTouches == before, 'the freed tune object was not touched (' .. (M.deadTouches - before) .. ')')
T.check(T.logHas('[ai] put back on 2 tune objects'), 'only the live ones put back')
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75 and W.ai.ForcedErrorChance == 15, 'DA_AIConfig put back at the menu')
T.check(T.logHas('[ai] AI config put back (main menu): DA_AIConfig DefaultPacingSettings.MaxAiSlowdownScale=0.75 ForcedErrorChance=15'), 'put back logged')
T.check(next(T.save().aiRestores) == nil, 'nothing left to put back')
T.check(T.levels('VBD_Car_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'the build put back too')

-- 50cc: Cadet pressure, the AI config untouched
M.press('BACKSPACE'); M.tick(3) -- leave the cup (v0.9: B on the standings asks; YES first)
T.clickTitle('YES'); M.tick(3)
T.clickTitle('JUNKER'); M.tick(3)
mark = T.mark()
T.clickTitle('JAKKU CUP'); M.tick(3)
T.check(M.called('LaunchQuickRace') == 2, 'launched at 50cc')
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75 and next(T.save().aiRestores) == nil and not T.logHas('AI config (DA_AIConfig)', mark),
  '50cc: DA_AIConfig untouched, nothing saved')
T.check(T.logHas('[ai] league riffraff: pressure -1.00 (RELAXED)', mark), 'Cadet pressure logged')
confs = W.tune(1)
W.race(11); M.tick(5)
c = confs[1]
T.check(math.abs(c.AiMaxTimeAheadMultiplier - 0.65) < 1e-9 and c.AiMinTimeAheadModifier == -3 and math.abs(c.AiAbilityChanceMultiplier - 0.75) < 1e-9,
  '50cc rubber band: max x0.65, min -3 s, abilities 0.75')
W.finish(1); M.tick(25)
t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(c.AiMaxTimeAheadMultiplier == 1 and c.AiMinTimeAheadModifier == 0, '50cc tune put back')

-- 200cc (stand-in profile) through the API (the class is locked in the menu flow): catch-up and perfect start too
local R = require('race')
local K = require('gp')
local ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'X', kind = 'Circuit' }, 'ace', 'car')
T.check(ok == true, 'launched at 200cc')
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 1 and math.abs(W.ai.DefaultPacingSettings.MaxAiCatchupScale - 1.495) < 1e-9
  and W.ai.ForcedErrorChance == 7.5 and W.ai.DefaultPercentageChancePerfectStart == 90, '200cc: honest, catch-up 1.495, errors 7.5, perfect start 90')
rest = K.data.aiRestores['/Game/Griffin/AI/DA_AIConfig']
T.check(rest['DefaultPacingSettings.MaxAiCatchupScale'] == 1.3 and rest.DefaultPercentageChancePerfectStart == 75, '200cc originals saved')
T.check(T.logHas('[ai] league ace: pressure 1.20 (HARD)'), '200cc pressure logged')
-- the launch failing: everything back at once
W.race(11); M.tick(5)
W.finish(1); M.tick(25)
t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(W.ai.DefaultPacingSettings.MaxAiCatchupScale == 1.3 and W.ai.DefaultPercentageChancePerfectStart == 75 and next(K.data.aiRestores) == nil, '200cc put back')
rawget(W.fe, '__props').LaunchQuickRace = function() error('boom') end
ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'X', kind = 'Circuit' }, 'ace', 'car')
T.check(ok == false and W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75 and next(K.data.aiRestores) == nil, 'a failed launch puts the AI config straight back')
cfg.AI.Profiles['ace'] = PRO200
p = A.plan('ace')
T.check(p['DefaultPacingSettings.MaxAiSlowdownScale'].set == 1 and p.ForcedErrorChance.mul == 0.5 and p['DefaultPacingSettings.MaxAiCatchupScale'] == nil
  and p.DefaultPercentageChancePerfectStart == nil, 'v0.10: the 200cc plan = 150cc\'s (honest, errors x0.5, no catch-up or perfect-start change)')
-- v0.18: the study's profiles - no catch-up anywhere, speed matching off, the mercy slowdown shrinking by class,
-- forced errors kept at 50cc only
-- (v0.21, owner: a little harder at 50 / 100cc: slowdown 0.4 and 0.45)
-- (v0.26: Riff-Raff = the 50cc profile, Challenger = 150cc, Ace = 200cc)
local want = { ['riffraff'] = 0.4, ['challenger'] = 1.0, ['ace'] = 1.0 }
cfg.AI.Profiles = REAL
for cls, slow in pairs(want) do
  local q = A.plan(cls)
  T.check(q['DefaultPacingSettings.MaxAiCatchupScale'].set == 1 and math.abs(q['DefaultPacingSettings.MaxAiSlowdownScale'].set - slow) < 1e-9
    and q.SpeedMatchingMaxMatchers.set == 0, 'v0.21 ' .. cls .. ': catch-up 1.0, slowdown ' .. slow .. ', speed matching off')
  T.check((cls == 'riffraff') == (q.ForcedErrorChance == nil), 'v0.18 ' .. cls .. ': forced errors ' .. (cls == 'riffraff' and 'kept' or 'off'))
  -- v0.21 (owner, 200cc: "i crash a lot and still get ~2nd place"): no easing off while you crash from 100cc up
  local crash = q['DefaultPacingSettings.AiSlowdownDuringCrash']
  if cls == 'riffraff' then T.check(crash == nil, 'v0.21 50cc: the game\'s slowdown while you crash kept')
  else T.check(crash and crash.set == 1, 'v0.21 ' .. cls .. ': AiSlowdownDuringCrash 1.0 (the bots don\'t ease off while you crash)') end
end
T.check(A.pressure('riffraff') == -1 and A.pressure('challenger') == 0 and A.pressure('ace') == 0.5, 'v0.26 pressures -1 / 0 / 0.5 (Ace a notch above Challenger)')
T.finish()
