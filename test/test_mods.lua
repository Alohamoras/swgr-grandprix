-- v0.8: your tune-ups. Picked on MODS (slot -> group -> package, the v0.6 screens until the garage tile), written into
-- the launch build's Affixes at launch together with the AI tiers' packages; at load every racer's race copy loses
-- what isn't theirs (the Elite keep theirs, you keep yours); put back at the menu. 50cc: no mods at all.
local M = require('mock')
local W = require('world')
local T = require('util')
-- an old (v0.6) save holding catalogue keys: dropped with a log line
T.boot({ version = 2, mods = { 'Conditions_FreezeProtection', 'Cooled_GainWhileSlipstream', false, false } }, { Progression = { On = false } })
M.press('F6'); M.tick(6)
T.clickTitle('150CC'); M.tick(3)
T.clickTitle('JAKKU CUP'); M.tick(3)
T.clickTitle('MODS'); M.tick(3)
T.check(T.titles() == 'EMPTY SLOT|EMPTY SLOT|DONE', '150cc: two empty tune-up slots, the old catalogue keys gone (' .. T.titles() .. ')')
T.check(T.logHas('[tune-ups] dropped from the save (not tune-ups): Conditions_FreezeProtection, Cooled_GainWhileSlipstream'), 'the old keys logged')
T.clickTitle('EMPTY SLOT'); M.tick(3)
T.check(T.titles():find('^STATUS PROTECTION|SHIELDS, SURGES & SLIPSTREAM|') ~= nil and T.titles():find('BACK$') ~= nil, 'the groups the packages use (' .. T.titles() .. ')')
T.clickTitle('STATUS PROTECTION'); M.tick(3)
T.check(T.titles() == 'HEAT SHIELD|TENACIOUS|BACK', 'Status protection: HEAT SHIELD and TENACIOUS (' .. T.titles() .. ')')
T.clickTitle('HEAT SHIELD'); M.tick(3)
T.check(T.titles() == 'HEAT SHIELD|EMPTY SLOT|DONE', 'slot 1 fitted (' .. T.titles() .. ')')
T.check(T.badges():find('^PROTECTION|SLOT 2') ~= nil, 'badges: PROTECTION, SLOT 2 (' .. T.badges() .. ')')
T.click(2); M.tick(3)
T.clickTitle('STATUS PROTECTION'); M.tick(3)
T.check(T.titles() == 'TENACIOUS|BACK', 'slot 2: HEAT SHIELD not offered again')
T.clickTitle('BACK'); M.tick(3)
T.clickTitle('SHIELDS, SURGES & SLIPSTREAM'); M.tick(3)
T.clickTitle('SLIPSTREAMER'); M.tick(3)
T.check(T.titles() == 'HEAT SHIELD|SLIPSTREAMER|DONE', 'slot 2 fitted (' .. T.titles() .. ')')
local sv = T.save().mods
T.check(sv[1] == 'heat_shield' and sv[2] == 'slipstreamer' and sv[3] == nil, 'tune-up keys saved')

-- 150cc: the Elite carry HEAT SHIELD too (the launch build = yours, nothing extra: you have it)
T.clickTitle('DONE'); M.tick(3)
T.clickTitle('START CUP')
local aff = W.buildAffixes.VBD_Car_Base
local function names(l) local o = {}; for i, a in ipairs(l) do o[i] = rawget(a, '__name') end; return table.concat(o, ',') end
T.check(names(aff) == 'AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection,AFX_Slipstream_gainSurging_v3,AFX_Cooled_GainWhileSlipstream',
  'launch build: your two packages\' four affixes, the Elite\'s already among them (' .. names(aff) .. ')')
T.check(T.logHas('mods in the launch build for this race: AFX_Conditions_BurningProtection, AFX_Conditions_FreezeProtection, AFX_Slipstream_gainSurging_v3, AFX_Cooled_GainWhileSlipstream'), 'logged')
T.check(T.save().run.mods[2] == 'slipstreamer', 'the cup keeps its own copy of the tune-ups')
T.check(T.save().modRestores.VBD_Car_Base == nil and next(T.save().modRestores) ~= nil, 'the build\'s own list saved before the race')

W.race(11); M.tick(5)
T.check(T.logHas('[loadout] mods: you=HEAT SHIELD+SLIPSTREAMER Elite=HEAT SHIELD (Biddy Blas, Sen Fira, Lyren Shok) (152 bot slots cleared)'),
  'logged: 8 bots x 4 copies x 4 affixes + 3 Elite x 4 copies x 2 extra = 152 cleared, nothing from your copy')
T.check(W.affixes(W.bots[1]) == 'AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection,-,-', 'Biddy Blas (Elite): HEAT SHIELD only (' .. W.affixes(W.bots[1]) .. ')')
T.check(W.affixes(W.bots[5]):find('^AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection,%-,%-$') ~= nil and W.affixes(W.bots[6]) == W.affixes(W.bots[5]), 'Sen Fira, Lyren Shok (Elite): the same')
T.check(W.affixes(W.bots[2]) == '-,-,-,-' and W.affixes(W.bots[11]) == '-,-,-,-' and W.affixes(W.bots[4]) == '-,-,-,-', 'Kestar, Goli (Challenger: none at 150cc), an unknown racer: no mods')
T.check(W.affixes(W.player) == 'AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection,AFX_Slipstream_gainSurging_v3,AFX_Cooled_GainWhileSlipstream', 'you: yours (' .. W.affixes(W.player) .. ')')
W.finish(2); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(#aff == 0, 'launch build: mods put back after the race (' .. #aff .. ' left)')
T.check(T.logHas('mods put back (main menu): VBD_Car_Base (0)'), 'put back logged')
T.check(next(T.save().modRestores) == nil, 'nothing left to put back')

-- 200cc with different packages: the launch build carries yours + the AI's extras; each racer keeps only theirs
T.clickTitle('LATER'); M.tick(3)
T.clickTitle('QUIT CUP'); M.tick(3)
T.clickTitle('YES'); M.tick(3)
T.clickTitle('BACK'); M.tick(3)
T.clickTitle('200CC'); M.tick(3)
T.clickTitle('JAKKU CUP'); M.tick(3)
T.clickTitle('MODS'); M.tick(3)
T.clickTitle('HEAT SHIELD'); M.tick(3)
T.clickTitle('REMOVE'); M.tick(3)
T.check(T.titles() == 'EMPTY SLOT|SLIPSTREAMER|DONE', 'HEAT SHIELD removed (' .. T.titles() .. ')')
T.clickTitle('EMPTY SLOT'); M.tick(3)
T.clickTitle('RAMJET'); M.tick(3)
T.clickTitle('REDLINER'); M.tick(3)
T.clickTitle('DONE'); M.tick(3)
T.clickTitle('START CUP')
T.check(names(aff) == 'AFX_Ramjet_TempCanDropWhileBoosting,AFX_Ramjet_CooledWhenCritical_v3,AFX_Slipstream_gainSurging_v3,AFX_Cooled_GainWhileSlipstream,'
  .. 'AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection,AFX_Conditions_DisruptedProtection,AFX_Shielded_GainOnRaceStart',
  'launch build: yours first, then the Elite\'s HEAT SHIELD + ARMOUR (Challenger\'s is among them) = 8 (' .. names(aff) .. ')')
local b = M.assets['/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base.VBD_Car_Base']
T.check(rawget(b, '__props').UnlockedAffixSlots == 8, 'UnlockedAffixSlots raised to 8')
W.race(11); M.tick(5)
T.check(T.logHas('[loadout] mods: you=REDLINER+SLIPSTREAMER Elite=HEAT SHIELD+ARMOUR (Biddy Blas, Sen Fira, Lyren Shok) Challenger=HEAT SHIELD (Goli & 02-R0) '
  .. '(296 bot slots cleared, 16 cleared from your race copy)'), 'logged: 7 x 32 + 3 x 16 + 1 x 24 = 296 bot slots, your 4 copies x 4 extras = 16')
T.check(W.affixes(W.player) == 'AFX_Ramjet_TempCanDropWhileBoosting,AFX_Ramjet_CooledWhenCritical_v3,AFX_Slipstream_gainSurging_v3,AFX_Cooled_GainWhileSlipstream,-,-,-,-',
  'you: REDLINER + SLIPSTREAMER, the AI\'s cleared from your copy (' .. W.affixes(W.player) .. ')')
T.check(W.affixes(W.bots[1]) == '-,-,-,-,AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection,AFX_Conditions_DisruptedProtection,AFX_Shielded_GainOnRaceStart',
  'Biddy Blas (Elite): HEAT SHIELD + ARMOUR, yours gone (' .. W.affixes(W.bots[1]) .. ')')
T.check(W.affixes(W.bots[6]) == W.affixes(W.bots[1]) and W.affixes(W.bots[5]) == W.affixes(W.bots[1]), 'Lyren Shok, Sen Fira: the same')
T.check(W.affixes(W.bots[11]) == '-,-,-,-,AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection,-,-', 'Goli & 02-R0 (Challenger): HEAT SHIELD only (' .. W.affixes(W.bots[11]) .. ')')
T.check(W.affixes(W.bots[2]) == '-,-,-,-,-,-,-,-' and W.affixes(W.bots[7]) == '-,-,-,-,-,-,-,-', 'Kestar Bool, Shade: none')
W.finish(1); M.tick(25)
t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(#aff == 0 and rawget(b, '__props').UnlockedAffixSlots == 4, 'launch build and its slot count put back (' .. #aff .. ', ' .. tostring(rawget(b, '__props').UnlockedAffixSlots) .. ')')

-- 50cc: pure driving (and no AI packages at 50cc: the launch build stays empty)
T.clickTitle('LATER'); M.tick(3)
T.clickTitle('QUIT CUP'); M.tick(3)
T.clickTitle('YES'); M.tick(3)
T.clickTitle('BACK'); M.tick(3)
T.clickTitle('50CC'); M.tick(3)
T.clickTitle('JAKKU CUP'); M.tick(3)
T.clickTitle('MODS'); M.tick(3)
T.check(T.titles():find('^START CUP') ~= nil, '50cc: MODS doesn\'t open (no slots)')
local mark = T.mark()
T.clickTitle('START CUP')
T.check(#aff == 0 and not T.logHas('mods in the launch build', mark), '50cc: no mods on the build, none logged')
W.race(11); M.tick(5)
T.check(not T.logHas('[loadout] mods:', mark) and W.affixes(W.bots[1]) == '-,-,-,-', '50cc: nothing to sort out, the Elite race clean')
T.finish()
