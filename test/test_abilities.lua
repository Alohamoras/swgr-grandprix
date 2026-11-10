-- v0.3: your four abilities (picked per category, level by class) go into the launch build and come back out after
-- the race; every AI racer gets their own four (one per category, _AI mines), never yours, never Autopilot.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot()
M.press('F6'); M.tick(6)
T.clickTitle('150CC'); M.tick(3)
T.clickTitle('JAKKU CUP'); M.tick(3)
T.clickTitle('ABILITIES'); M.tick(3)
T.check(T.titles() == 'OFFENSIVE|DEFENSIVE|UTILITY|WILDCARD|DONE', 'four categories (' .. T.titles() .. ')')
T.clickTitle('OFFENSIVE'); M.tick(3)
T.check(T.titles() == 'CONCUSSIVE BOLT|MULTI-BOLT|MAGNETIC SHOCKWAVE|VECTORED SHOCKWAVE|BACK', '150cc offensive: level-2 branches (' .. T.titles() .. ')')
T.clickTitle('VECTORED SHOCKWAVE'); M.tick(3)
T.clickTitle('UTILITY'); M.tick(3)
T.clickTitle('FLAME VENT'); M.tick(3)
T.clickTitle('WILDCARD'); M.tick(3)
T.check(T.titles() == 'CONCUSSION MINE II|FREEZING MINE|CONCUSSIVE BOLT|MULTI-BOLT|AUTO-SCRUBBER|MULTI-SCRUBBER|IMPACT SURGE|OVERTAKING SURGE|BACK',
  'wildcard: mines + the families not picked (' .. T.titles() .. ')')
T.clickTitle('MULTI-BOLT'); M.tick(3)
-- picking a Bolt as the offensive now makes the wildcard bolt clash: it falls back to the default (mines)
T.clickTitle('OFFENSIVE'); M.tick(3)
T.clickTitle('CONCUSSIVE BOLT'); M.tick(3)
T.check(T.logHas('wildcard changed to Concussion Mine II') or T.save().picks.wildcard == 'mine.double', 'a clash resets the wildcard (to mines)')
local p = T.save().picks
T.check(p.offensive == 'bolt.concuss' and p.defensive == 'shield.impact' and p.utility == 'vent.flame' and p.wildcard == 'mine.double', 'picks saved')

T.clickTitle('DONE'); M.tick(3)
T.clickTitle('START CUP')
local slots = W.buildSlots['VBD_Car_Base']
local function names(list) local t = {}; for i = 1, 4 do t[i] = rawget(list[i], '__dead') and '-' or rawget(list[i], '__name') end; return table.concat(t, ',') end
T.check(names(slots) == 'BP_Ability_Disruptor_Concuss_C,BP_Ability_Shield_Charged_C,BP_Ability_Vent_Flame_C,BP_Ability_Mine_Double_C',
  'launch build: your four at level 2, your (non-_AI) mines (' .. names(slots) .. ')')
T.check(T.save().run.picks.utility == 'vent.flame', 'the cup keeps its own copy of the picks')
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
