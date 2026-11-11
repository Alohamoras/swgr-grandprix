-- v0.8: after a crash mid-race the save still holds the AI config's originals (aiRestores): a new boot at the main
-- menu puts them back, even with the AI switched off. With AI.Enabled = false nothing else is touched.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ aiRestores = { ['/Game/Griffin/AI/DA_AIConfig'] = { ['DefaultPacingSettings.MaxAiSlowdownScale'] = 0.75, ForcedErrorChance = 15,
  ['AggressionConfig.VersusPlayer.Chance'] = 50 },
  -- v0.16.1: a pacing asset's originals too
  ['/Game/Griffin/AI/Pacing/Default/RP_Default'] = { ['PacingSettingsConfig.MaxAiSlowdownScale'] = 0.75 } } },
  { Progression = { On = false }, AI = { Enabled = false }, NoTabMenu = true })
-- the asset as the crashed race left it
W.ai.DefaultPacingSettings.MaxAiSlowdownScale = 1
W.ai.ForcedErrorChance = 7.5
W.ai.AggressionConfig.VersusPlayer.Chance = 75
W.rp.Default.PacingSettingsConfig.MaxAiSlowdownScale = 1
W.tabMenu(); M.tick(18)
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75 and W.ai.ForcedErrorChance == 15 and W.ai.AggressionConfig.VersusPlayer.Chance == 50,
  'left over from a crash: DA_AIConfig put back at the first menu tick')
T.check(T.logHas('[ai] AI config put back (left over from an earlier race): DA_AIConfig AggressionConfig.VersusPlayer.Chance=50 DefaultPacingSettings.MaxAiSlowdownScale=0.75 ForcedErrorChance=15'),
  'put back logged (nested struct fields included)')
T.check(W.rp.Default.PacingSettingsConfig.MaxAiSlowdownScale == 0.75
  and T.logHas('[ai] AI config put back (left over from an earlier race): RP_Default PacingSettingsConfig.MaxAiSlowdownScale=0.75'),
  'v0.16.1: left over from a crash: RP_Default put back too')
T.check(not T.logHas('[aiset]'), 'AI off: no [aiset] read-back at boot')
T.check(next(T.save().aiRestores) == nil, 'the save is clear')
T.check(T.logHas('build put back') == false, 'nothing else was pending')

-- AI off: a launch changes nothing, the race's tune objects are left alone
M.press('F6'); M.tick(6)
T.clickTitle('150CC'); M.tick(3)
T.clickTitle('JAKKU CUP'); M.tick(3)
local mark = T.mark()
T.check(M.called('LaunchQuickRace') == 1, 'launched')
T.check(W.ai.DefaultPacingSettings.MaxAiSlowdownScale == 0.75 and W.ai.ForcedErrorChance == 15, 'AI off: DA_AIConfig untouched')
T.check(not T.logHas('[ai]', mark), 'AI off: nothing logged')
local confs = W.tune(2)
W.race(11); M.tick(40)
T.check(confs[1].AiMaxTimeAheadModifier == 0 and confs[2].AiAbilityChanceMultiplier == 1, 'AI off: tune objects untouched')
T.check(not T.logHas('[ai]', mark), 'AI off: still nothing logged')
W.finish(1); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.logHas('build put back (main menu)') and not T.logHas('[ai]', mark), 'the build put back as usual, the AI silent')
T.finish()
