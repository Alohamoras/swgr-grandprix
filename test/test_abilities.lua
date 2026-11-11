-- v0.3.10: your four abilities (free pick, one per family; level by class) go into the launch build and come back out after
-- the race; every AI racer gets their own four (one per category, _AI mines), never yours, never Autopilot.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } }) -- (unlocks: test_prog, test_unlocks)
M.press('F6'); M.tick(6)
T.clickTitle('150CC'); M.tick(3)   -- (the garage shows the picks at the level of the class picked last)
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('GARAGE'); M.tick(5)
T.check(T.titles():find('CONCUSSIVE BOLT|IMPACT SHIELD|IMPACT SURGE|CONCUSSION MINE II', 1, true) ~= nil, 'free pick: your four by name, defaults at 150cc (' .. T.titles() .. ')')
-- Select cycles a slot through every ability the other three slots' families don't hold (level-2 branches), in the
-- families' order, wrapping. cycleTo presses the slot's tile until it shows `want`.
local function cycleTo(tileNo, want)
  for _ = 1, 16 do
    if T.titles():find('|' .. want .. '|', 1, true) or T.titles():find('|' .. want .. '$') then return true end
    T.click(tileNo); M.tick(5)
  end
  return false
end
T.clickTitle('CONCUSSIVE BOLT'); M.tick(5)
T.check(T.titles():find('|MULTI-BOLT|IMPACT SHIELD|', 1, true) ~= nil, 'slot 1: Select -> MULTI-BOLT (' .. T.titles() .. ')')
T.clickTitle('MULTI-BOLT'); M.tick(5)
T.check(T.titles():find('|MAGNETIC SHOCKWAVE|IMPACT SHIELD|', 1, true) ~= nil, 'slot 1 -> MAGNETIC SHOCKWAVE (' .. T.titles() .. ')')
T.check(cycleTo(3, 'VECTORED SHOCKWAVE'), 'slot 1 -> VECTORED SHOCKWAVE (' .. T.titles() .. ')')
T.clickTitle('IMPACT SURGE'); M.tick(5)
T.check(T.titles():find('|OVERTAKING SURGE|', 1, true) ~= nil, 'slot 3 -> OVERTAKING SURGE (' .. T.titles() .. ')')
T.clickTitle('OVERTAKING SURGE'); M.tick(5)
T.check(T.titles():find('|CONCUSSIVE BOLT|CONCUSSION', 1, true) ~= nil, 'slot 3 wraps to CONCUSSIVE BOLT (no Shockwave / Shield: held by slots 1 and 2) (' .. T.titles() .. ')')
T.check(cycleTo(5, 'FLAME VENT'), 'slot 3 -> FLAME VENT (' .. T.titles() .. ')')
T.clickTitle('CONCUSSION MINE II'); M.tick(5)
T.check(T.titles():find('|FREEZING MINE', 1, true) ~= nil, 'slot 4 -> FREEZING MINE (' .. T.titles() .. ')')
T.check(cycleTo(6, 'MULTI-BOLT'), 'slot 4 -> MULTI-BOLT (' .. T.titles() .. ')')
T.check(T.titles():find('VECTORED SHOCKWAVE|IMPACT SHIELD|FLAME VENT|MULTI-BOLT', 1, true) ~= nil, 'your four now (' .. T.titles() .. ')')
local p = T.save().picks
T.check(p[1] == 'shockwave.vectored' and p[2] == 'shield.impact' and p[3] == 'vent.flame' and p[4] == 'bolt.multi', 'picks saved as a list')

M.press('BACKSPACE'); M.tick(3)
T.clickTitle('150CC'); M.tick(3)
T.clickTitle('JAKKU CUP')
local slots = W.buildSlots['VBD_Car_Base']
local function names(list) local t = {}; for i = 1, 4 do t[i] = rawget(list[i], '__dead') and '-' or rawget(list[i], '__name') end; return table.concat(t, ',') end
T.check(names(slots) == 'BP_Ability_Shockwave_Punch_C,BP_Ability_Shield_Charged_C,BP_Ability_Vent_Flame_C,BP_Ability_Disruptor_Multi_C',
  'launch build: your four at level 2 (' .. names(slots) .. ')')
T.check(T.save().run.picks[3] == 'vent.flame', 'the cup keeps its own copy of the picks')
T.check(T.logHas('[loadout] class 150: AI racers get their four'), 'AI loadout armed')

W.race(11); M.tick(5)
T.check(W.slots(W.bots[2]) == 'BP_Ability_Disruptor_Concuss_C,BP_Ability_Shield_Charged_C,BP_Ability_Surge_Aggressive_C,BP_Ability_Shockwave_Punch_C',
  'Kestar Bool: his four at level 2 (' .. W.slots(W.bots[2]) .. ')')
T.check(W.slots(W.bots[1]) == 'BP_Ability_Shockwave_Punch_C,BP_Ability_Shield_Charged_C,BP_Ability_Vent_Flame_C,BP_Ability_Surge_Aggressive_C',
  'Biddy Blas: hers (' .. W.slots(W.bots[1]) .. ')')
T.check(W.slots(W.bots[5]):find('Mine_Double_AI_C', 1, true) ~= nil, 'Sen Fira: the bots\' _AI mines (' .. W.slots(W.bots[5]) .. ')')
T.check(W.slots(W.bots[4]) == 'BP_Ability_Disruptor_Concuss_C,BP_Ability_Shield_Charged_C,BP_Ability_Surge_Aggressive_C,BP_Ability_Mine_Double_AI_C',
  'an unknown racer: the default four (' .. W.slots(W.bots[4]) .. ')')
local leak = false
for _, b in ipairs(W.bots) do if W.slots(b):find('Autopilot') then leak = true end end
T.check(not leak, 'no bot keeps Autopilot / your copied build')

W.finish(1); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(names(slots) == '-,-,-,-', 'build slots put back after the race (' .. names(slots) .. ')')
T.check(next(T.save().abilityRestores) == nil, 'nothing left to put back')
T.finish()
