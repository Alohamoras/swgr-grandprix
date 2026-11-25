-- v0.21 (owner, OWNER.md "Done" 2026-11-11): RESET PROGRESS clears ALL progress, titles included - trophies, golds,
-- best finishes, records, perfect cups, standings, titles, the final boss, the leaders, the counts - everything but the
-- garage picks (racer, abilities, tune-ups; Kestar Bool falls back to Shade once he is locked again), behind TWO
-- questions, NO first on both. A backup of the save is made first. Also: HOME has no Next: line, the page backdrop is
-- off (config PageBackdrop) except behind the standings / results.
local M = require('mock')
local W = require('world')
local T = require('util')

local full = { version = 3, races = 44, cups = 11, class = 'challenger', racer = 'Antagonist',
  picks = { 'bolt.concuss', 'shield.impact', 'surge.impact', 'mine.double' }, mods = { 'heat_shield', 'armour' },
  best = { ['riffraff'] = { jakku = 1 }, ['challenger'] = { jakku = 1, galactic = 2 } }, perfect = { ['riffraff'] = { jakku = true } },
  records = { ['riffraff'] = { ['/x'] = { time = 100 } } }, standings = { ['riffraff'] = { jakku = { YOU = 60 } } },
  titles = { ['challenger'] = { won = true, tries = 1, vs = 'Biddy Blas' } }, boss = { beaten = true, tries = 2 },
  leader = { ['challenger'] = { name = 'Biddy Blas', cup = 'jakku' } }, last = { class = 'challenger', title = 'X', pos = 1 },
  restores = {}, abilityRestores = {} }
T.boot(full)
local H = rawget(_G, 'GU_TEST_SCREENS')
local S = H.S
local mark = T.mark()
M.press('F6'); M.tick(6)
T.check(S.screen == 'home', 'HOME')
local home = H.SCREENS.home()
local function joined(lines) local o = {}; for _, l in ipairs(lines) do o[#o + 1] = tostring(l[1]) end; return table.concat(o, ' | ') end
T.check(#home.lines == 1 and not joined(home.lines):find('Next:', 1, true), 'HOME: no Next: line (' .. joined(home.lines) .. ')')
-- the page backdrop: off on HOME (alpha 0), logged once
local alphas = {}
for _, c in ipairs(M.calls) do
  if c.name == 'SetBrushColor' and type(c.args[1]) == 'table' and c.args[1].A ~= nil and c.args[1].R ~= nil then alphas[#alphas + 1] = c.args[1].A end
end
T.check(alphas[1] == 0, 'PageBackdrop = false: HOME\'s page panel fully transparent (alpha ' .. tostring(alphas[1]) .. ')')
T.check(T.logHas('[menu] page backdrop: none, transparent (config PageBackdrop = false); the standings, cup result and title result keep their picture', mark),
  'the backdrop logged')
local rs
for _, it in ipairs(home.items) do if it.title == 'RESET PROGRESS' then rs = it end end
T.check(rs and rs.desc == nil and not rs.info:find('%a'), 'v0.22: the RESET tile has no extra words (the two questions say it)')

-- 1. NO on the first question: nothing cleared
T.clickTitle('RESET PROGRESS'); M.tick(3)
T.check(T.titles() == 'NO|YES' and S.focus == 1, 'question 1: NO first, focused')
T.check(S.confirm.text == 'Wipe the record books? Every trophy, lap record and title goes.', 'question 1 text')
T.clickTitle('NO'); M.tick(3)
T.check(S.screen == 'home' and T.save().titles['challenger'].won == true, 'NO: HOME, nothing cleared')
-- 2. YES, then NO on the second: nothing cleared
T.clickTitle('RESET PROGRESS'); M.tick(3)
T.clickTitle('YES'); M.tick(3)
T.check(T.titles() == 'NO|YES' and S.focus == 1 and S.confirm.text == 'There is no way back. Wipe them?', 'question 2: NO first, its own text')
T.clickTitle('NO'); M.tick(3)
T.check(S.screen == 'home' and T.save().boss.beaten == true and not T.logHas('progress reset'), 'NO on question 2: HOME, nothing cleared')
-- 3. YES, YES: everything cleared but the garage
T.clickTitle('RESET PROGRESS'); M.tick(3)
T.clickTitle('YES'); M.tick(3)
T.clickTitle('YES'); M.tick(3)
local sv = T.save()
local cleared = next(sv.best) == nil and next(sv.records) == nil and next(sv.perfect) == nil and next(sv.standings) == nil
  and next(sv.titles) == nil and sv.boss == nil and next(sv.leader) == nil and sv.races == 0 and sv.cups == 0 and sv.last == nil and sv.class == nil
T.check(cleared, 'YES, YES: trophies, records, perfect cups, standings, titles, the boss, leaders, counts, last race all cleared')
T.check(sv.picks and sv.picks[1] == 'bolt.concuss' and sv.mods and sv.mods[1] == 'heat_shield', 'the garage kept: abilities and tune-ups')
T.check(sv.racer == 'DarkEnigma' and T.logHas('Racer Kestar Bool is locked again: racing as Shade.'), 'Kestar locked again: the racer falls back to Shade')
T.check(T.logHas('progress reset: everything cleared') and T.logHas('(44 races, 11 cups)'), 'logged with what was there')
T.check(S.screen == 'home' and S.message == 'A clean slate.', 'back on HOME with a message')
local p = io.popen('ls "' .. T.dir .. '"')
local backup = false
for f in p:lines() do if f:find('^save%.backup%-reset%-') then backup = true end end
p:close()
T.check(backup, 'a backup of the save was made first')
T.finish()

-- 4. a racer that isn't locked stays; PageBackdrop = true: the v0.20 grey panel
T.reset()
T.boot({ version = 3, races = 3, racer = 'Rager', best = { ['riffraff'] = { jakku = 2 } }, restores = {}, abilityRestores = {} }, { PageBackdrop = true })
M.press('F6'); M.tick(6)
local a2
for _, c in ipairs(M.calls) do
  if not a2 and c.name == 'SetBrushColor' and type(c.args[1]) == 'table' and c.args[1].A ~= nil and c.args[1].R ~= nil then a2 = c.args[1].A end
end
T.check(a2 == 0.6, 'PageBackdrop = true: the v0.20 grey panel (alpha ' .. tostring(a2) .. ')')
require('gp').reset()
T.check(T.save().racer == 'Rager' and not T.logHas('locked again'), 'reset: Biddy Blas kept as the racer')
T.finish()
