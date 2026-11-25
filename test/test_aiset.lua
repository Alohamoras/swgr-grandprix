-- v0.16.1 (AI study Phase 0): the pacing writes go to the pacing assets RP_Default / RP_Honest too (config
-- AI.WritePacingAssets) and are put back with DA_AIConfig; the [aiset] read-back line once at the menu after boot and
-- once per race (the assets at launch, the race tune once it's found).
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } })
local A = require('ai')
local R = require('race')
local K = require('gp')
local cfg = require('config')
-- the writes below are checked against the v0.10-v0.17 150cc profile (v0.18 changed the real one; test_ai checks it)
cfg.AI.Profiles['challenger'] = { pressure = 0.5, pacing = { MaxAiSlowdownScale = 1.0 }, errors = 0.5 }
M.tick(5)

local function count(s, from)
  local n = 0
  for i = from or 1, #M.log do if M.log[i]:find(s, 1, true) then n = n + 1 end end
  return n
end
local function line(s, from)
  for i = from or 1, #M.log do if M.log[i]:find(s, 1, true) then return M.log[i] end end
  return ''
end
local RPD, RPH = '/Game/Griffin/AI/Pacing/Default/RP_Default', '/Game/Griffin/AI/Pacing/Default/RP_Honest'

-- at boot: one read-back at the main menu, never repeated
T.check(count('[aiset] menu at boot') == 1, 'one [aiset] line at the menu after boot')
local boot = line('[aiset] menu at boot')
T.check(boot:find('DA_AIConfig: RacePacingLowestSpeedMph=150 MaxAiCatchupScale=1.3 MaxAiSlowdownScale=0.75', 1, true) ~= nil
  and boot:find('EnableSpeedMatchingZone=true SpeedMatchingMinPlayerSpeedInMph=? SpeedMatchingMaxMatchers=2', 1, true) ~= nil
  and boot:find('ForcedErrorChance=15', 1, true) ~= nil, 'boot: DA_AIConfig pacing, speed matching (unreadable = ?), forced errors')
T.check(boot:find('| RP_Default: PacingConfigs.Num=5 RacePacingLowestSpeedMph=150 MaxAiCatchupScale=1.2 MaxAiSlowdownScale=0.75', 1, true) ~= nil
  and boot:find('| RP_Honest: PacingConfigs.Num=5 RacePacingLowestSpeedMph=150 MaxAiCatchupScale=1.25 MaxAiSlowdownScale=1', 1, true) ~= nil,
  'boot: both pacing assets read back')
M.tick(50)
T.check(count('[aiset] menu at boot') == 1, 'not repeated')

-- a 150cc race (pacing MaxAiSlowdownScale 1.0): written on all three, the originals saved
cfg.AI.Profiles['challenger'].catchup = 1.1
local ev = { path = cfg.Pools.jakku[1].path, title = 'X', kind = 'Circuit' }
local mark = T.mark()
T.check(R.launch(ev, 'challenger', 'car') == true, 'launched at 150cc')
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 1 and W.rp.Default.PacingSettingsConfig.MaxAiSlowdownScale == 1
  and W.rp.Honest.PacingSettingsConfig.MaxAiSlowdownScale == 1, 'honest pacing on DA_AIConfig, RP_Default and RP_Honest')
T.check(math.abs(W.rp.Default.PacingSettingsConfig.MaxAiCatchupScale - 1.32) < 1e-9
  and math.abs(W.ai.DefaultPacingSettings.MaxAiCatchupScale - 1.43) < 1e-9, 'catch-up x1.1 on each asset\'s own value (1.2 -> 1.32, 1.3 -> 1.43)')
local rest = K.data.aiRestores
T.check(rest[RPD] and rest[RPD]['PacingSettingsConfig.MaxAiSlowdownScale'] == 0.75 and rest[RPD]['PacingSettingsConfig.MaxAiCatchupScale'] == 1.2
  and rest[RPH] and rest[RPH]['PacingSettingsConfig.MaxAiCatchupScale'] == 1.25 and rest[RPH]['PacingSettingsConfig.MaxAiSlowdownScale'] == nil,
  'RP originals in the save (RP_Honest\'s slowdown was already 1: nothing to keep)')
T.check(T.save().aiRestores[RPD] ~= nil, 'saved to disk before the race (a crash puts them back at the next boot)')
T.check(T.logHas('[ai] league challenger: pacing asset (RP_Default) PacingSettingsConfig.MaxAiCatchupScale 1.2 -> 1.32, PacingSettingsConfig.MaxAiSlowdownScale 0.75 -> 1', mark)
  and T.logHas('[ai] league challenger: pacing asset (RP_Honest) PacingSettingsConfig.MaxAiCatchupScale 1.25 -> 1.375, PacingSettingsConfig.MaxAiSlowdownScale 1 (as is)', mark),
  'RP writes logged')
T.check(count('[aiset] race league=challenger', mark) == 1, 'one [aiset] line at launch')
local l = line('[aiset] race league=challenger', mark)
T.check(l:find('DA_AIConfig: RacePacingLowestSpeedMph=150 MaxAiCatchupScale=1.43 MaxAiSlowdownScale=1', 1, true) ~= nil
  and l:find('ForcedErrorChance=7.5', 1, true) ~= nil, 'the read-back has the written DA_AIConfig values')
T.check(l:find('| RP_Default: PacingConfigs.Num=5 RacePacingLowestSpeedMph=150 MaxAiCatchupScale=1.32 MaxAiSlowdownScale=1 AiAheadTimeToMaxSlowdown=1.5 AiBehindTimeToMaxCatchup=2 AiSlowdownDuringCrash=0.5 |', 1, true) ~= nil
  and l:find('| RP_Honest: PacingConfigs.Num=5 RacePacingLowestSpeedMph=150 MaxAiCatchupScale=1.375 MaxAiSlowdownScale=1', 1, true) ~= nil,
  'the read-back has the RP values as written')
-- the race: the tune line once, no lookups of the assets while racing
local confs = W.tune(2)
M.resetSweeps()
W.race(11); M.tick(60)
T.check(count('[aiset] race tune league=challenger', mark) == 1, 'one race tune line')
-- (v0.32: read back during the start grace - the min lift held at 0, abilities 0 - and says so)
T.check(line('[aiset] race tune league=challenger', mark):find('(start grace) | AiMaxTimeAheadModifier=1.25 AiMinTimeAheadModifier=0 ', 1, true) ~= nil
  and line('[aiset] race tune', mark):find('AiAbilityChanceMultiplier=0 ', 1, true) ~= nil
  and line('[aiset] race tune', mark):find('TotalCrashAllowance=3', 1, true) ~= nil, 'race tune read back after the writes (the start grace\'s values, named)')
T.check(M.sweepCount('RP_') == 0 and M.sweepCount('DA_AIConfig') == 0, 'no asset lookups during the race')
T.check(count('[aiset]', mark) == 2, 'two [aiset] lines for the race (assets, tune)')
W.finish(1); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(W.rp.Default.PacingSettingsConfig.MaxAiSlowdownScale == 0.75 and W.rp.Default.PacingSettingsConfig.MaxAiCatchupScale == 1.2
  and W.rp.Honest.PacingSettingsConfig.MaxAiCatchupScale == 1.25 and W.rp.Honest.PacingSettingsConfig.MaxAiSlowdownScale == 1
  and W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75, 'all three put back at the menu')
T.check(T.logHas('[ai] AI config put back (main menu): RP_Default PacingSettingsConfig.MaxAiCatchupScale=1.2 PacingSettingsConfig.MaxAiSlowdownScale=0.75'), 'RP put back logged')
T.check(next(T.save().aiRestores) == nil, 'nothing left to put back')
T.check(count('[aiset] menu at boot') == 1, 'no boot read-back after a race')

-- a second race: its own [aiset] line
mark = T.mark()
R.launch(ev, 'challenger', 'car')
T.check(count('[aiset] race league=challenger', mark) == 1, 'a second race: one more [aiset] line')
W.race(11); M.tick(60)
W.finish(1); M.tick(25)
t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)

-- WritePacingAssets = false: DA_AIConfig only, the RP assets left alone (still read back)
cfg.AI.WritePacingAssets = false
mark = T.mark()
R.launch(ev, 'challenger', 'car')
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 1 and W.rp.Default.PacingSettingsConfig.MaxAiSlowdownScale == 0.75
  and W.rp.Default.PacingSettingsConfig.MaxAiCatchupScale == 1.2 and W.rp.Honest.PacingSettingsConfig.MaxAiCatchupScale == 1.25,
  'WritePacingAssets=false: DA_AIConfig written, RP assets untouched')
T.check(K.data.aiRestores[RPD] == nil and K.data.aiRestores[RPH] == nil and not T.logHas('pacing asset', mark), 'nothing saved or logged for them')
T.check(line('[aiset] race league=challenger', mark):find('RP_Default: PacingConfigs.Num=5 RacePacingLowestSpeedMph=150 MaxAiCatchupScale=1.2 MaxAiSlowdownScale=0.75', 1, true) ~= nil,
  'still read back')
W.race(11); M.tick(60)
W.finish(1); M.tick(25)
t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75 and next(T.save().aiRestores) == nil, 'DA_AIConfig put back')
cfg.AI.WritePacingAssets = true

-- a study profile's pacing goes the same way
mark = T.mark()
R.launch(ev, 'challenger', 'car', nil, nil, { ai = { pressure = 0, pacing = { MaxAiCatchupScale = 1.0, MaxAiSlowdownScale = 1.0 } } })
T.check(W.rp.Default.PacingSettingsConfig.MaxAiCatchupScale == 1 and W.rp.Honest.PacingSettingsConfig.MaxAiCatchupScale == 1
  and W.ai.DefaultPacingSettings.MaxAiCatchupScale == 1, 'study profile pacing on all three')
T.check(count('[aiset] race league=challenger study', mark) == 1, 'study race: one [aiset] line')
W.race(11); M.tick(60)
W.finish(1); M.tick(25)
t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(W.rp.Default.PacingSettingsConfig.MaxAiCatchupScale == 1.2 and W.rp.Honest.PacingSettingsConfig.MaxAiCatchupScale == 1.25
  and next(T.save().aiRestores) == nil, 'study profile: put back')

-- a missing asset: 'missing', nothing breaks
M.assets[RPH .. '.RP_Honest'] = nil
local old = _G.StaticFindObject
_G.StaticFindObject = function(p) if tostring(p):find('RP_Honest', 1, true) then return nil end return old(p) end
mark = T.mark()
local out = A.readback('test')
T.check(out:find('| RP_Honest: missing', 1, true) ~= nil and out:find('RP_Default: PacingConfigs.Num=5', 1, true) ~= nil, 'a missing asset logs "missing"')
_G.StaticFindObject = old
T.finish()
