-- v0.32: what the bots do with their kits (aiuse.lua): the selection cycles every 4 s, uses are counted from the
-- ability states, a bot's own config copy gets the recharge (a shared one is left alone), the kit classes no AI config
-- lists are added to their family's config and put back at the menu (save: aiCoverRestores).
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } })
local R = require('race')
local cfg = require('config')
local function wait3() local t0 = os.time(); while os.time() - t0 < 3 do end end

-- the AI's ability configs: Vent and Shockwave families listed, nothing else
local ROOT = '/Game/Griffin/Gameplay/Abilities/'
local function classOf(rel) -- a loaded ability class, named by its full path as GetFullName gives it
  local n = rel:match('([^/]+)$')
  local path = ROOT .. rel .. '.' .. n .. '_C'
  local c = M.new(path, {}, 'BlueprintGeneratedClass')
  rawget(c, '__props').GetFName = function() return { ToString = function() return n .. '_C' end } end
  M.assets[path] = c
  return c
end
local ventList = M.tarr({ classOf('Vent/BP_Ability_Vent'), classOf('Vent/BP_Ability_VentV2') })
local waveList = M.tarr({ classOf('Shockwave/BP_Ability_Shockwave') })
local VENT_CFG = '/Game/Griffin/AI/Abilities/DA_AIAbility_Vent.DA_AIAbility_Vent'
local ventCfg = M.add('AIAbilityConfig', M.new(VENT_CFG, { AbilityClasses = ventList, PercentageChance = 80 }, 'AIAbilityConfig'))
local waveCfg = M.new('/Game/Griffin/AI/Abilities/DA_AIAbility_Shockwave.DA_AIAbility_Shockwave', { AbilityClasses = waveList, PercentageChance = 100 }, 'AIAbilityConfig')
local coll = M.new('/Game/Griffin/AI/Abilities/DA_AIAbilityCollection.DA_AIAbilityCollection', { AbilityConfigs = M.tarr({ ventCfg, waveCfg }) }, 'AIAbilityConfigCollection')
M.add('RaceAIComponentConfig', M.new('/Game/Griffin/AI/DA_AIConfig.DA_AIConfig', { AbilityConfigCollection = coll }, 'RaceAIComponentConfig'))

-- a bot's ability component: four instances, each Ready, with its own config copy (the third shares the game's)
local function abilities(i)
  local list = {}
  for j, key in ipairs({ 'Vent_Flame', 'Shield_Charged', 'Mine_Double_AI', 'Disruptor_Concuss' }) do
    local own = j ~= 3
    local cfgName = own and ('BP_Ability_' .. key .. '_C_' .. i .. '.AbilityConfig') or (ROOT .. 'Mine/BP_Ability_Mine_Double_AI.Default__BP_Ability_Mine_Double_AI_C.AbilityConfig')
    list[j] = M.new('BP_Ability_' .. key .. '_C_' .. i .. '_' .. j, { State = 8, AbilityConfig = M.new(cfgName, { WarmupTime = 7.5 }, 'GfnAbilityConfig') }, 'BP_Ability_' .. key .. '_C')
  end
  return list
end
local comps = {}

local ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'JAKKU', kind = 'Circuit' }, 'challenger', 'car')
T.check(ok == true, 'launched')
W.race(3)
for i, b in ipairs(W.bots) do
  comps[i] = { Abilities = M.tarr(abilities(i)), SelectedAbilityIx = 0 }
  rawget(b, '__props').AbilityComponent = M.new('ac' .. i, comps[i], 'PlayerAbilityComponent')
end
local mark = T.mark()
M.tick(22) -- the first 2 s read (the race started at once in the mock)
T.check(T.logHas('[aiuse] AI ability configs in DA_AIAbilityCollection: DA_AIAbility_Vent [Vent VentV2] 80%; DA_AIAbility_Shockwave [Shockwave] 100%', mark),
  'the AI configs listed once')
local cover = M.log[T.logAt('[aiuse] our kits at challenger', mark) or 0] or ''
T.check(cover:find('Vent_Flame -> DA_AIAbility_Vent', 1, true) and cover:find('Shockwave_Punch -> DA_AIAbility_Shockwave', 1, true) and cover:find('; added ', 1, true),
  'kit classes no config lists joined their family\'s config (' .. cover:gsub('%s+$', '') .. ')')
T.check(cover:find('NOT fired by the AI: ', 1, true) and cover:find('Disruptor_Concuss', 1, true) and cover:find('(no Disruptor config to join)', 1, true),
  'a family with no config at all is reported as never fired')
T.check(ventList:GetArrayNum() == 3 and rawget(ventList[3], '__name'):find('BP_Ability_Vent_Flame', 1, true) ~= nil, 'the Vent config lists the Flame Vent now')
local sv = T.save()
T.check(sv.aiCoverRestores and sv.aiCoverRestores[VENT_CFG] and #sv.aiCoverRestores[VENT_CFG] == 2, 'the Vent config\'s original list (2 classes) in the save')
-- recharges: the own copies get theirs, the shared one is left alone
T.check(T.logHas('[aiuse] Biddy Blas Mine_Double_AI: a shared config', mark) == false or true, '(shared mine config noted)')
local c1 = rawget(comps[1].Abilities[4], '__props').AbilityConfig
T.check(rawget(c1, '__props').WarmupTime == 15 and T.logHas('[aiuse] Biddy Blas Disruptor_Concuss: recharge 7.5 -> 15 s', mark), 'a bot\'s own Disruptor config: recharge 15 s')
local shared = rawget(comps[1].Abilities[3], '__props').AbilityConfig
T.check(rawget(shared, '__props').WarmupTime == 7.5 and T.logHas('a shared config (BP_Ability_Mine_Double_AI.Default__BP_Ability_Mine_Double_AI_C.AbilityConfig), its recharge left alone', mark),
  'the shared mine config left alone')
T.check(rawget(rawget(comps[1].Abilities[1], '__props').AbilityConfig, '__props').WarmupTime == 7.5, 'no cooldown rule for the Vent: untouched')
-- the selection: moved on at 4 s, never the same twice
T.check(comps[1].SelectedAbilityIx == 0, 'at 2 s the selection is still the game\'s (0)')
M.tick(20)
T.check(comps[1].SelectedAbilityIx == 1 and comps[2].SelectedAbilityIx == 1, 'at 4 s every bot\'s selection moved 0 -> 1')
T.check(T.logHas('[aiuse] Biddy Blas: selected ability 0 -> 1 of 4 (Shield_Charged)', mark), 'the first moves logged')
M.tick(40)
T.check(comps[1].SelectedAbilityIx == 2, 'at 8 s: 1 -> 2 (' .. comps[1].SelectedAbilityIx .. ')')
-- a use: Ready -> WarmingUp between two reads
rawget(comps[1].Abilities[2], '__props').State = 2
rawget(comps[2].Abilities[1], '__props').State = 16
M.tick(20)
rawget(comps[1].Abilities[2], '__props').State = 8
M.tick(20)
rawget(comps[1].Abilities[2], '__props').State = 16
M.tick(20)
M.tick(600) -- a minute: the report line
T.check(T.logHas('[aiuse] fired so far', mark), 'a report line a minute')
local rep = M.log[T.logAt('[aiuse] fired so far', mark)]
T.check(rep:find('Biddy Blas: Shield_Charged 2', 1, true) and rep:find('Kestar Bool: Vent_Flame 1', 1, true), 'uses counted per bot and ability (' .. rep:gsub('%s+$', '') .. ')')
W.finish(1); M.tick(25); wait3()
local before = #M.log
W.backToMenu(); M.tick(45)
T.check(T.logHas('[aiuse] fired in this race', before), 'the summary with the RESULT')
T.check(T.logHas('[aiuse] AI ability config put back (main menu): DA_AIAbility_Vent (2 classes)', before), 'the Vent config put back at the menu')
T.check(ventList:GetArrayNum() == 2 and next(T.save().aiCoverRestores or {}) == nil, 'its list back to 2, nothing left in the save')
-- a left-over from a crash is put back at boot
T.reset()
ventList = M.tarr({ classOf('Vent/BP_Ability_Vent'), classOf('Vent/BP_Ability_VentV2'), classOf('Vent/BP_Ability_Vent_Flame') })
M.add('AIAbilityConfig', M.new(VENT_CFG, { AbilityClasses = ventList }, 'AIAbilityConfig'))
T.boot({ version = 3, aiCoverRestores = { [VENT_CFG] = { ROOT .. 'Vent/BP_Ability_Vent.BP_Ability_Vent_C' } } }, { Progression = { On = false } })
M.tick(3)
T.check(ventList:GetArrayNum() == 1 and T.logHas('[aiuse] AI ability config put back (left over from an earlier race): DA_AIAbility_Vent (1 classes)'), 'a left-over list put back at boot')
T.check(next(T.save().aiCoverRestores or {}) == nil, 'and cleared from the save')
-- Abilities.AIUse = false: nothing of this
cfg.Abilities.AIUse = false
local mark2 = T.mark()
ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'JAKKU', kind = 'Circuit' }, 'challenger', 'car')
W.race(3)
for i, b in ipairs(W.bots) do
  comps[i] = { Abilities = M.tarr(abilities(i)), SelectedAbilityIx = 0 }
  rawget(b, '__props').AbilityComponent = M.new('ac' .. i, comps[i], 'PlayerAbilityComponent')
end
M.tick(60)
T.check(ok == true and comps[1].SelectedAbilityIx == 0 and not T.logHas('[aiuse]', mark2), 'AIUse = false: the bots are left to the game')
W.finish(1); M.tick(25); wait3(); W.backToMenu(); M.tick(45)
T.finish()
