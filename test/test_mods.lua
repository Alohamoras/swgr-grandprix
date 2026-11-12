-- v0.8: your tune-ups. Picked in place on the GARAGE's TUNE-UP tiles (Select cycles the package), written into
-- the launch build's Affixes at launch together with the AI tiers' packages; at load every racer's race copy loses
-- what isn't theirs (the Elite keep theirs, you keep yours); put back at the menu. Riff-Raff: no mods at all.
-- (v0.26: Challenger opens one slot, Ace two)
local M = require('mock')
local W = require('world')
local T = require('util')
-- an old (v0.6) save holding catalogue keys: dropped with a log line
T.boot({ version = 3, mods = { 'Conditions_FreezeProtection', 'Cooled_GainWhileSlipstream', false, false } }, { Progression = { On = false } })
M.press('F6'); M.tick(6)
T.clickTitle('GARAGE'); M.tick(3)
T.check(T.titles():find('|NONE|NONE$') ~= nil, 'garage: two empty tune-up slots, the old catalogue keys gone (' .. T.titles() .. ')')
local H0 = rawget(_G, 'GU_TEST_SCREENS')
local its = H0.S.ui.items
T.check(its[#its].kind == 'tuneup' and its[#its - 1].kind == 'tuneup' and not T.badges():find('TUNE', 1, true), 'the tune-up slots, last (v0.24: no TUNE-UP badge)')
-- v0.14: which league opens a slot is in the focused tile's info line (it ran past the badge)
local function infoOf(i)
  local n0 = #M.calls + 1
  for j, t in ipairs(W.tiles) do rawget(t, '__props').__focus = (j == i) end
  M.tick(6)
  local info
  for k = n0, #M.calls do
    local c = M.calls[k]
    local s = c.name == 'SetText' and type(c.args[1]) == 'table' and rawget(rawget(c.args[1], '__props') or {}, '__text')
    if s then info = s end
  end
  return info or ''
end
T.check(infoOf(T.ntiles() - 1):find('(Tune-up 1: from CHALLENGER.)', 1, true) ~= nil and infoOf(T.ntiles()):find('(Tune-up 2: from ACE.)', 1, true) ~= nil,
  'the slots say which league opens them, in the info line')
T.check(T.logHas('[tune-ups] dropped from the save (not tune-ups): Conditions_FreezeProtection, Cooled_GainWhileSlipstream'), 'the old keys logged')
local n = T.ntiles()
T.click(n - 1); M.tick(5)
T.check(T.titles():find('|HEAT SHIELD|NONE$') ~= nil, 'Select on slot 1: the first package, HEAT SHIELD (' .. T.titles() .. ')')
T.click(n); M.tick(5)
T.check(T.titles():find('|HEAT SHIELD|ARMOUR$') ~= nil, 'slot 2 skips HEAT SHIELD (in slot 1): ARMOUR (' .. T.titles() .. ')')
local all = require('modsel').all()
for _ = 1, #all do
  if T.titles():find('|HEAT SHIELD|SLIPSTREAMER$') then break end
  T.click(n); M.tick(5)
end
T.check(T.titles():find('|HEAT SHIELD|SLIPSTREAMER$') ~= nil, 'cycling slot 2 reaches SLIPSTREAMER (' .. T.titles() .. ')')
local sv = T.save().mods
T.check(sv[1] == 'heat_shield' and sv[2] == 'slipstreamer' and sv[3] == nil, 'tune-up keys saved')
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('CHALLENGER'); M.tick(3)

-- Challenger (one slot): the Elite carry HEAT SHIELD too (the launch build = yours, nothing extra: you have it)
T.clickTitle('JAKKU CUP')
local aff = W.buildAffixes.VBD_Car_Base
local function names(l) local o = {}; for i, a in ipairs(l) do o[i] = rawget(a, '__name') end; return table.concat(o, ',') end
T.check(names(aff) == 'AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection',
  'launch build: your one open slot\'s two affixes, the Elite\'s the same (' .. names(aff) .. ')')
T.check(T.logHas('mods in the launch build for this race: AFX_Conditions_BurningProtection, AFX_Conditions_FreezeProtection'), 'logged')
T.check(T.save().run.mods[2] == 'slipstreamer', 'the cup keeps its own copy of the tune-ups')
T.check(T.save().modRestores.VBD_Car_Base == nil and next(T.save().modRestores) ~= nil, 'the build\'s own list saved before the race')

-- (AI driving spike step 1: logbuilds.txt in the mod folder -> every racer's race copy logged at load, read only)
local lbf = io.open(T.dir .. '/logbuilds.txt', 'w'); lbf:write(''); lbf:close()
local bmark = T.mark()
W.race(11); M.tick(5)
os.remove(T.dir .. '/logbuilds.txt')
local nb = 0
for i = bmark + 1, #M.log do if M.log[i]:find('[builds]', 1, true) then nb = nb + 1 end end
T.check(T.logHas('[builds] Biddy Blas pilot=', bmark) and T.logHas(' (YOU) pilot=', bmark) and T.logHas(' power=', bmark) and T.logHas('affixes AFX_Conditions_BurningProtection', bmark)
  and not T.logHas('[builds] read failed', bmark) and not T.logHas('read error', bmark),
  'logbuilds.txt: every racer\'s race copy logged at load, before our changes (' .. nb .. ' lines)')
T.check(T.logHas('[loadout] mods: you=HEAT SHIELD Elite=HEAT SHIELD (Biddy Blas, Sen Fira, Lyren Shok) (64 bot slots cleared)'),
  'logged: 8 bots x 4 copies x 2 affixes = 64 cleared, the Elite keep theirs, nothing from your copy')
T.check(W.affixes(W.bots[1]) == 'AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection,-,-', 'Biddy Blas (Elite): HEAT SHIELD only (' .. W.affixes(W.bots[1]) .. ')')
T.check(W.affixes(W.bots[5]):find('^AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection,%-,%-$') ~= nil and W.affixes(W.bots[6]) == W.affixes(W.bots[5]), 'Sen Fira, Lyren Shok (Elite): the same')
T.check(W.affixes(W.bots[2]) == '-,-,-,-' and W.affixes(W.bots[11]) == '-,-,-,-' and W.affixes(W.bots[4]) == '-,-,-,-', 'Kestar, Goli (the Challenger tier: none in the Challenger league), an unknown racer: no mods')
T.check(W.affixes(W.player) == 'AFX_Conditions_BurningProtection,AFX_Conditions_FreezeProtection,-,-', 'you: yours (' .. W.affixes(W.player) .. ')')
W.finish(2); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(#aff == 0, 'launch build: mods put back after the race (' .. #aff .. ' left)')
T.check(T.logHas('mods put back (main menu): VBD_Car_Base (0)'), 'put back logged')
T.check(next(T.save().modRestores) == nil, 'nothing left to put back')

-- Ace with different packages: the launch build carries yours + the AI's extras; each racer keeps only theirs
M.press('BACKSPACE'); M.tick(3) -- leave the cup (v0.9: B on the standings asks; YES first)
T.clickTitle('YES'); M.tick(3)
T.clickTitle('GARAGE'); M.tick(3)
n = T.ntiles()
for _ = 1, #all + 1 do
  if T.titles():find('|REDLINER|SLIPSTREAMER$') then break end
  T.click(n - 1); M.tick(5)
end
T.check(T.titles():find('|REDLINER|SLIPSTREAMER$') ~= nil, 'slot 1 cycled on to REDLINER (' .. T.titles() .. ')')
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('ACE'); M.tick(3)
T.clickTitle('JAKKU CUP')
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

-- Riff-Raff: pure driving (and no AI packages there: the launch build stays empty)
M.press('BACKSPACE'); M.tick(3) -- leave the cup (v0.9: B on the standings asks; YES first)
T.clickTitle('YES'); M.tick(3)
T.clickTitle('RIFF-RAFF'); M.tick(3)
local mark = T.mark()
T.clickTitle('JAKKU CUP')
T.check(#aff == 0 and not T.logHas('mods in the launch build', mark), 'Riff-Raff: no mods on the build, none logged')
W.race(11); M.tick(5)
T.check(not T.logHas('[loadout] mods:', mark) and W.affixes(W.bots[1]) == '-,-,-,-', 'Riff-Raff: nothing to sort out, the Elite race clean')
T.finish()
