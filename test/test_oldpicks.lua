-- v0.3.10: a save from before free pick - category picks (the owner's save on 2026-11-10). A cup started with them
-- launches with the four; the garage shows them as a list. (v0.9: the cup in that save is dropped at boot - cups
-- cannot be resumed - so the launch is a fresh cup with the same four.)
local M = require('mock')
local W = require('world')
local T = require('util')
local old = { offensive = 'shockwave.magnetic', defensive = 'shield.impact', utility = 'surge.impact', wildcard = 'scrubber.auto' }
T.boot({ version = 2, races = 25, cups = 5, class = '200', vehicle = 'car', best = {},
  picks = old,
  run = { class = '200', cup = 'jakku', vehicle = 'car', race = 3, races = 4, points = { YOU = 27 }, last = {}, history = { {}, {} },
    picks = { offensive = 'shockwave.magnetic', defensive = 'shield.impact', utility = 'surge.impact', wildcard = 'scrubber.auto' } },
  restores = {}, abilityRestores = {} }, { Progression = { On = false } })
T.check(T.logHas('[cup] jakku 200cc dropped at boot (race 3 of 4): cups cannot be resumed') and T.save().run == nil, 'the old cup dropped at boot')
M.press('F6'); M.tick(6)
T.clickTitle('200CC'); M.tick(3)
T.clickTitle('JAKKU CUP')
local slots = W.buildSlots['VBD_Car_Base']
local function names(list) local t = {}; for i = 1, 4 do t[i] = rawget(list[i], '__dead') and '-' or rawget(list[i], '__name') end; return table.concat(t, ',') end
T.check(names(slots) == 'BP_Ability_Shockwave_MagneticConcussion_C,BP_Ability_Shield_ChargedV2_C,BP_Ability_Surge_AggressiveV2_C,BP_Ability_Repair_AutoV2_C',
  'a new cup launches with the old-style four (' .. names(slots) .. ')')
W.race(11); M.tick(5); W.finish(2); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(names(slots) == '-,-,-,-', 'put back after the race')
M.press('BACKSPACE'); M.tick(3) -- leave the cup: YES is the first tile
T.click(1); M.tick(3)
T.check(T.save().run == nil, 'the cup left')
T.clickTitle('GARAGE'); M.tick(3)
T.check(T.titles():find('MAGNETIC SHOCKWAVE II|IMPACT SHIELD II|IMPACT SURGE II|AUTO-SCRUBBER II', 1, true) ~= nil, 'your old four in the garage, at the last class\'s level (' .. T.titles() .. ')')
local p = T.save().picks
T.check((p[1] or p.offensive) == 'shockwave.magnetic' and (p[4] or p.wildcard) == 'scrubber.auto', 'your picks unchanged in the save')
T.clickTitle('IMPACT SURGE II'); M.tick(3)
T.check(T.titles():find('OVERTAKING SURGE II', 1, true) ~= nil, 'Select cycles the slot to the next ability (' .. T.titles() .. ')')
p = T.save().picks
T.check(p[1] == 'shockwave.magnetic' and p[3] == 'surge.overtake' and p[4] == 'scrubber.auto' and p.offensive == nil,
  'after a change: saved as a list of four')
T.finish()
