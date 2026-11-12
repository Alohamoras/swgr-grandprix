-- v0.26 (owner 2026-11-12, TASKS "Three leagues"): RIFF-RAFF, CHALLENGER and ACE replace the four cc classes.
--   1. an old save (v2, the cc classes) at its first load: a clean start - backed up, every bit of progress gone, the
--      garage kept (racer, four abilities, tune-ups normalised), Kestar locked again (a Kestar pick back to Shade),
--      logged once;
--   2. each league's parts, ability level, tune-up slots and AI profile, on a real launch;
--   3. the unlock ladder in the menus: Riff-Raff open, Challenger from Riff-Raff, Ace from Challenger;
--   4. Kestar Bool's tile on the Ace cups page after the Ace title (not after the Challenger one).
local M = require('mock')
local W = require('world')
local T = require('util')
local EV = '/Game/Griffin/Gameplay/Events/Planets/'

---------------------------------------------------------------------------------------------------------------------
-- 1. the clean start
local old = { version = 2, races = 140, cups = 31, class = '150', racer = 'Antagonist',
  picks = { 'bolt.multi', 'shield.surging', 'vent.flame', 'mine.frozen' }, mods = { 'Conditions_FreezeProtection', 'armour', 'brawler' },
  best = { ['50'] = { jakku = 1 }, ['100'] = { jakku = 1, lantaana = 2 }, ['150'] = { jakku = 1, galactic = 1 }, ['200'] = { crait = 3 } },
  perfect = { ['150'] = { jakku = true } }, standings = { ['150'] = { jakku = { YOU = 60 } } },
  records = { ['150'] = { [EV .. 'Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD_DAWN'] = { time = 101.2, lap = 49 } } },
  titles = { ['150'] = { won = true, tries = 2, vs = 'Biddy Blas' }, ['100'] = { won = true, tries = 1 } },
  boss = { beaten = true, tries = 3 }, leader = { ['150'] = { name = 'Biddy Blas', cup = 'jakku' } },
  last = { class = '150', title = 'X', pos = 1 }, vehicle = 'car', rivals = { ['100'] = { name = 'Sen Fira' } },
  run = { class = '200', cup = 'ando', vehicle = 'car', race = 2, races = 4, points = { YOU = 15 }, last = {}, history = { {} } },
  restores = {}, abilityRestores = {}, modRestores = {} }
T.boot(old, { Progression = { On = true } })
local K, cfg, RC = require('gp'), require('config'), require('racer')
local sv = T.save()
T.check(sv.version == 3, 'the save is version 3')
local gone = next(sv.best) == nil and next(sv.records) == nil and next(sv.perfect) == nil and next(sv.standings) == nil
  and next(sv.titles) == nil and sv.boss == nil and next(sv.leader) == nil and next(sv.titleTrack) == nil and sv.races == 0
  and sv.cups == 0 and sv.last == nil and sv.class == nil and sv.run == nil and sv.vehicle == nil and sv.rivals == nil
T.check(gone, 'every bit of progress gone: medals, records, perfect cups, standings, titles, the boss, leaders, counts, the last race, the cup, old fields')
T.check(sv.picks[1] == 'bolt.multi' and sv.picks[2] == 'shield.surging' and sv.picks[3] == 'vent.flame' and sv.picks[4] == 'mine.frozen',
  'the four ability picks kept (their branches too)')
T.check(sv.mods[1] == false and sv.mods[2] == 'armour' and sv.mods[3] == nil,
  'the tune-ups kept, normalised to the two slots (an old catalogue key emptied, a third dropped)')
T.check(sv.racer == 'DarkEnigma' and RC.locked('Antagonist'), 'Kestar locked again: the pick back to Shade')
T.check(sv.restores and sv.abilityRestores and sv.modRestores, 'the put-back records kept')
T.check(T.logCount('[save] v0.26: three leagues - a clean start (backup save.backup-v2-') == 1
  and T.logHas('kept: racer, abilities, tune-ups. Racer Kestar Bool is locked again: racing as Shade.'), 'logged once, naming the backup')
T.check(not T.logHas('dropped at boot'), 'the old cup is simply gone (no boot drop)')
local p = io.popen('ls "' .. T.dir .. '"'); local files = p:read('a'); p:close()
local bk = files:match('(save%.backup%-v2%-[%d%-]+%.lua)')
T.check(bk ~= nil, 'a backup of the old save (' .. tostring(bk) .. ')')
local b = bk and dofile(T.dir .. '/' .. bk)
T.check(b and b.version == 2 and b.best['150'].galactic == 1 and b.boss.beaten == true and b.racer == 'Antagonist', 'the backup is the old save as it was')
-- the next load: nothing again
local mark = T.mark()
K.data = nil
K.load()
T.check(not T.logHas('a clean start', mark) and K.data.version == 3 and K.data.picks[3] == 'vent.flame', 'the next load: a v3 save, no second clean start')
-- HOME: three leagues, no cc anywhere
M.press('F6'); M.tick(6)
T.check(T.titles() == 'RIFF-RAFF|CHALLENGER|ACE|GARAGE|RESET PROGRESS', 'HOME: the three leagues (' .. T.titles() .. ')')
local H = rawget(_G, 'GU_TEST_SCREENS')
local words = {}
for _, it in ipairs(H.SCREENS.home().items) do words[#words + 1] = tostring(it.title) .. ' ' .. tostring(it.desc) .. ' ' .. tostring(it.info) end
T.check(not table.concat(words, ' '):lower():find('%dcc'), 'no "cc" on HOME (' .. table.concat(words, ' / '):gsub('\n', ' ') .. ')')
T.finish()

---------------------------------------------------------------------------------------------------------------------
-- 2. each league on a launch: parts on your build, your ability level, the tune-up slots, the AI profile
T.reset()
T.boot({ version = 3, picks = { 'bolt.concuss', 'shield.impact', 'surge.impact', 'mine.double' }, mods = { 'heat_shield', 'ice_cold' },
  restores = {}, abilityRestores = {} }, { Progression = { On = false } })
K = require('gp')
local AB, MS, A = require('abil'), require('modsel'), require('ai')
local WANT = {
  riffraff = { parts = '0=0 1=2 2=0 3=2 4=2 5=0', level = 1, slots = 0, bolt = 'BP_Ability_Disruptor_C', pressure = -1 },
  challenger = { parts = 5, level = 2, slots = 1, bolt = 'BP_Ability_Disruptor_Concuss_C', pressure = 0 },
  ace = { parts = 9, level = 3, slots = 2, bolt = 'BP_Ability_Disruptor_ConcussV2_C', pressure = 0.5 },
}
M.press('F6'); M.tick(6)
for _, key in ipairs({ 'riffraff', 'challenger', 'ace' }) do
  local w = WANT[key]
  T.clickTitle(K.leagueName(key)); M.tick(3)
  mark = T.mark()
  T.clickTitle('JAKKU CUP'); M.tick(3)
  local lv = type(w.parts) == 'string' and w.parts or ('0=%d 1=%d 2=%d 3=%d 4=%d 5=%d'):format(w.parts, w.parts, w.parts, w.parts, w.parts, w.parts)
  T.check(T.levels('VBD_Car_Base') == lv, key .. ': the parts ' .. w.parts .. ' (' .. T.levels('VBD_Car_Base') .. ')')
  local slot1 = W.buildSlots['VBD_Car_Base'][1]
  T.check(AB.levelFor(key) == w.level and rawget(slot1, '__name') == w.bolt, key .. ': abilities at level ' .. w.level .. ' (' .. tostring(rawget(slot1, '__name')) .. ')')
  T.check(MS.slotsFor(key) == w.slots and #MS.fitted(K.data.mods, key) == w.slots, key .. ': ' .. w.slots .. ' tune-up slot(s) open')
  T.check(A.pressure(key) == w.pressure and T.logHas(('[ai] league %s: pressure %.2f'):format(key, w.pressure), mark), key .. ': the AI profile, pressure ' .. w.pressure)
  T.check(T.logHas(('league=%s'):format(key), mark), key .. ': the launch logged with the league')
  W.race(11); M.tick(5); W.finish(1); M.tick(25)
  local t0 = os.time(); while os.time() - t0 < 3 do end
  W.backToMenu(); M.tick(45)
  M.press('BACKSPACE'); M.tick(5)
  T.clickTitle('YES'); M.tick(3)
end
T.check(cfg.AI.Profiles.riffraff.pacing.MaxAiSlowdownScale == 0.4 and cfg.AI.Profiles.ace.pacing.MaxAiSlowdownScale == 1.0, 'Riff-Raff keeps the mercy, Ace is honest')
T.finish()

---------------------------------------------------------------------------------------------------------------------
-- 3. the unlock ladder in the menus
T.reset()
T.boot({ version = 3, restores = {}, abilityRestores = {} })
K = require('gp')
H = rawget(_G, 'GU_TEST_SCREENS')
M.press('F6'); M.tick(6)
T.check(T.locks() == '||LOCKED||', 'v0.27.2 (owner): a new save: Riff-Raff and Challenger open, Ace locked (' .. T.marks() .. ')')
local items = H.SCREENS.home().items
T.check(items[2].desc == 'Tuned rigs and pilots out to make a name' and items[3].desc == 'To open: 5 trophies at CHALLENGER',
  'Challenger shows its tagline; the Ace lock says what opens it (' .. tostring(items[2].desc) .. ' / ' .. tostring(items[3].desc) .. ')')
T.check(items[3].info:find('A trophy in all 5 planet cups at CHALLENGER (0 / 5)', 1, true) ~= nil, 'the full why in the info line')
T.clickTitle('ACE'); M.tick(3)
T.check(H.S.screen == 'home', 'a locked league can\'t be entered')
T.clickTitle('CHALLENGER'); M.tick(3)
T.check(H.S.screen == 'cups', 'Challenger entered on a new save')
M.press('BACKSPACE'); M.tick(3)
K.data.best = { riffraff = { jakku = 3, lantaana = 3, ando = 2, crait = 1, sentinel = 3 } }
M.press('F6'); M.tick(3); M.press('F6'); M.tick(6)
T.check(T.locks() == '||LOCKED||', 'five Riff-Raff trophies: Ace still locked (only Challenger trophies open it) (' .. T.marks() .. ')')
K.data.best.challenger = { jakku = 1, lantaana = 1, ando = 1, crait = 1 }
M.press('F6'); M.tick(3); M.press('F6'); M.tick(6)
T.check(T.locks() == '||LOCKED||', 'four Challenger trophies: Ace still locked')
K.data.best.challenger.sentinel = 2
M.press('F6'); M.tick(3); M.press('F6'); M.tick(6)
T.check(T.locks() == '||||', 'five Challenger trophies: Ace open (' .. T.marks() .. ')')
T.clickTitle('ACE'); M.tick(3)
T.check(H.S.screen == 'cups' and T.titles() == 'JAKKU CUP|LANTAANA CUP|ANDO CUP|CRAIT CUP|SENTINEL CUP|GALACTIC CUP|TITLE RACE', 'the Ace cups page')
T.finish()

---------------------------------------------------------------------------------------------------------------------
-- 4. Kestar Bool after the Ace title
T.reset()
local all = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 1, galactic = 1 }
T.boot({ version = 3, best = { riffraff = all, challenger = all, ace = all },
  titles = { riffraff = { won = true, tries = 1 }, challenger = { won = true, tries = 1 } }, restores = {}, abilityRestores = {} })
K = require('gp')
local TI = require('title')
RC = require('racer')
H = rawget(_G, 'GU_TEST_SCREENS')
T.check(TI.bossClass() == 'ace', 'the boss follows the Ace title')
M.press('F6'); M.tick(6)
T.clickTitle('CHALLENGER'); M.tick(3)
T.check(T.ntiles() == 7 and not T.titles():find('KESTAR', 1, true), 'the Challenger title won: no Kestar on its page')
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('ACE'); M.tick(3)
T.check(T.ntiles() == 7 and not T.titles():find('KESTAR', 1, true), 'Ace before its title: no Kestar')
mark = T.mark()
T.clickTitle('TITLE RACE')
W.race(1); M.tick(5); W.finish(1, 120, 55); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.logHas('TITLE RACE ACE: WON', mark) and T.logHas('unlocked: KESTAR BOOL (the final boss) on the ACE cups page', mark), 'the Ace title won: Kestar unlocked, logged')
local hl = {}
for _, l in ipairs(H.SCREENS.titleResult().lines) do hl[#hl + 1] = tostring(l[1]) end
T.check(hl[1] == 'ACE CHAMPION' and hl[2] == 'UNLOCKED:  KESTAR BOOL, the final boss', 'the title result: ACE CHAMPION, Kestar unlocked (' .. table.concat(hl, ' | ') .. ')')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(T.ntiles() == 8 and T.titles():find('|TITLE RACE|KESTAR BOOL$') ~= nil, 'the Ace cups page: KESTAR BOOL last (' .. T.titles() .. ')')
T.check(RC.unlockText('Antagonist') == 'To unlock: beat Kestar Bool after the ACE title', 'his lock names the Ace title')
T.finish()
