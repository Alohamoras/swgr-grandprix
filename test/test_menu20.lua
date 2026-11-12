-- v0.20 (TASKS "Next" 3 and 4, docs/menu-review-2026-11-11.md 1-7): the cup result screen of its own (the medal large
-- and tinted, PERFECT CUP, the top 3, ONE what's-next line: an unlock / the nearest unlock / the near miss on the race
-- line) and (v0.21) CONTINUE's focus on the cup just raced; HOME's focus on the class last raced (v0.21: no Next: line,
-- no blurbs); no rival marks (v0.21); the game's footer hidden while our tab is up and put back after (and only
-- logged with HideFooter = false); the dark strip behind the tiles' labels; the small text changes (no how-to on the
-- cups page, no League line on HOME, no best lap on a sprint, trophies on every class tile, medal icons tinted).
local M = require('mock')
local W = require('world')
local T = require('util')

local function texts(lines)
  local o = {}
  for _, l in ipairs(lines or {}) do o[#o + 1] = tostring(l[1]) end
  return o
end
local function joined(lines) return table.concat(texts(lines), ' | ') end
local function hasText(lines, s) for _, t in ipairs(texts(lines)) do if t == s then return true end end return false end
local function findText(lines, s) for _, t in ipairs(texts(lines)) do if t:find(s, 1, true) then return t end end return nil end

---------------------------------------------------------------------------------------------------------------------
-- 1. the cup result screen (spec level, from real results through K.record)
T.boot({ version = 2, races = 0, cups = 0, class = '100', restores = {}, abilityRestores = {},
  best = { ['100'] = { jakku = 1, lantaana = 1, ando = 1, crait = 1 } } })
local H = rawget(_G, 'GU_TEST_SCREENS')
local SC, S = H.SCREENS, H.S
local K, ART, SD, PR, CU = require('gp'), require('art'), require('standings'), require('prog'), require('cup')
local cfg = require('config')

local BOTS = { 'Biddy Blas', 'Sen Fira', 'Katja Mox', 'Lyren Shok', 'Ary Quill', 'Nik Skandaro', 'Shade', 'Fola Kanjen', 'Soren Zaks', 'Malis Vazosk', 'Griff Halloran' }
-- you finish `you`; the bots in BOTS order in the other places
local function field(you)
  local f, p = { { name = 'Dwayne', you = true, pos = you, finished = true } }, 1
  for _, n in ipairs(BOTS) do
    if p == you then p = p + 1 end
    f[#f + 1] = { name = n, pos = p, finished = true }; p = p + 1
  end
  return f
end
local function runCup(classKey, cupKey, places)
  K.startCup(classKey, cupKey, 'car')
  local out
  for i = 1, 4 do out = K.record(K.nextRace(), places[i], field(places[i]), { time = 100 + i, lap = 50 }) end
  return out
end

-- a) the fifth 100cc gold: unlocks 150cc and the Galactic Cup; perfect; the medal gold
local out = runCup('100', 'sentinel', { 1, 1, 1, 1 })
S.result = out
local spec = SC.standings()
T.check(spec.title == '' and spec.hero ~= nil, 'the cup result is its own screen (a hero block; v0.22: no title)')
T.check(spec.hero.icon == ART.medal(1) and spec.hero.color == ART.medalColor(1) and (spec.hero.size or 0) >= 150,
  'the medal large, gold, tinted gold (' .. tostring(spec.hero.icon) .. ')')
T.check(spec.hero.lines[1][1] == 'GOLD TROPHY' and spec.hero.lines[1][2] >= 44, 'the trophy named big beside the medal')
T.check(hasText(spec.hero.lines, 'PERFECT CUP'), 'PERFECT CUP as a badge (' .. joined(spec.hero.lines) .. ')')
T.check(spec.table and #spec.table.rows == 3 and spec.table.rows[1].cells[2] == 'YOU' and spec.table.rows[1].cells[1] == '1st',
  'the final top 3 only (' .. (spec.table and #spec.table.rows or 0) .. ' rows)')
T.check(hasText(spec.after, 'UNLOCKED:  150cc   -   GALACTIC CUP at 100cc'), 'what\'s next: what it unlocked (' .. joined(spec.after) .. ')')
T.check(not findText(spec.after, 'Next:'), 'one what\'s-next line only')
T.check(not findText(spec.after, 'Last race') and findText(spec.after, 'NEW RECORD') ~= nil, 'v0.22: no Last race line, its record kept (' .. joined(spec.after) .. ')')
local cont = spec.items[1]
T.check(cont.title == 'CONTINUE' and cont.desc == 'Back to the cups' and S.focusMem.cups == 5,
  'v0.21: CONTINUE lands on the cup just raced, the Sentinel Cup (' .. tostring(cont.desc) .. ', ' .. tostring(S.focusMem.cups) .. ')')
T.check(cont.icon == ART.medal(1) and cont.iconColor == ART.medalColor(1), 'CONTINUE carries the gold medal')

-- b) 150cc: Jakku gold, Lantaana bronze, Ando silver now -> 2 more trophies open its Galactic Cup and 200cc
K.data.best['150'] = { jakku = 1, lantaana = 3 }
out = runCup('150', 'ando', { 2, 2, 2, 2 })
S.result = out
spec = SC.standings()
T.check(out.trophy == 'SILVER' and spec.hero.icon == ART.medal(2) and spec.hero.color == ART.medalColor(2), 'silver: the silver medal, tinted silver')
T.check(not hasText(spec.hero.lines, 'PERFECT CUP'), 'no PERFECT CUP badge when not')
T.check(#spec.table.rows == 3 and spec.table.rows[2].cells[2] == 'YOU', 'you 2nd in the top 3 (' .. spec.table.rows[2].cells[2] .. ')')
T.check(not findText(spec.after, 'Next:'), 'v0.22 (owner: no goal lines): no Next: line (' .. joined(spec.after) .. ')')
T.check(spec.items[1].desc == 'Back to the cups' and S.focusMem.cups == 3, 'v0.21: CONTINUE lands on the Ando Cup, the cup just raced')
-- v0.21: no rival - the winner's row plain, no call-out; the leader saved for the title race
T.check(spec.table.rows[1].cells[2] == 'Biddy Blas' and spec.table.rows[1].color == require('ui').WHITE, 'v0.21: no RIVAL tag or colour')
T.check(not findText(spec.after, 'RIVAL'), 'v0.21: no rival call-out on the cup result')
T.check(K.data.rivals == nil and K.data.leader['150'].name == 'Biddy Blas' and K.data.leader['150'].cup == 'ando',
  'v0.21: the 150cc leader saved: Biddy Blas from the Ando Cup')

-- c) 5th place, outside the top 3: your row under them; one race away from opening 150cc's Galactic Cup
K.data.best['150'] = { jakku = 1, lantaana = 3, ando = 2, crait = 1 }
out = runCup('150', 'sentinel', { 5, 5, 5, 5 })
S.result = out
spec = SC.standings()
T.check(spec.hero.icon == nil and spec.hero.lines[1][1] == '5TH PLACE', 'no trophy: no medal, 5TH PLACE')
T.check(#spec.table.rows == 4 and spec.table.rows[4].cells[2] == 'YOU' and spec.table.rows[4].cells[1] == '5th', 'the top 3 and your row under them')
T.check(not findText(spec.after, 'Next:'), 'v0.22: no Next: line here either')

-- d) nothing left to open at the class: the near miss on the race line, no Next: line
local run = CU.new('100', 'jakku', 'car', 4)
run.points, run.last, run.race = { YOU = 50, ['Sen Fira'] = 51, Shade = 20 }, { YOU = 2, ['Sen Fira'] = 1, Shade = 3 }, 5
run.history = { {}, {}, {}, { { key = 'Sen Fira', place = 1, pts = 15 }, { key = 'YOU', place = 2, pts = 12 }, { key = 'Shade', place = 3, pts = 10 } } }
K.data.best['100'] = { jakku = 3, lantaana = 1, ando = 1, crait = 1, sentinel = 1, galactic = 1 }
K.data.titles = { ['100'] = { tries = 1, won = true } }
S.result = { cupOver = true, run = run, ev = { title = 'X', race = 4, laps = 2 }, trophy = 'SILVER', rank = 2, pts = 50, pos = 2, time = 120 }
spec = SC.standings()
T.check(PR.nextUnlock(K.data, '100') == nil, 'nothing left to unlock at 100cc')
T.check(findText(spec.after, '1 POINT FROM GOLD') ~= nil and not findText(spec.after, 'Next:'), 'what\'s next: the near miss (' .. joined(spec.after) .. ')')
T.check(spec.items[1].desc == 'Back to the cups' and S.focusMem.cups == 1, 'v0.21: every other cup golden: CONTINUE still lands on the cup just raced (Jakku)')

-- e) the standings page (and the results panel: the same SD.spec): v0.21 no rival marks
run.race, run.history = 2, { run.history[4] }
spec = SD.spec({ run = run, ev = { title = 'X', race = 1, laps = 2 }, pos = 2, time = 120, lap = 60 })
local marked
for _, r in ipairs(spec.table.rows) do if tostring(r.cells[2]):find('RIVAL', 1, true) then marked = r end end
T.check(not marked, 'v0.21: the standings: no row marked RIVAL')
T.check(not findText(spec.lines, '(best lap'), 'v0.22: no best lap on your line (a new one is a note)')
spec = SD.spec({ run = run, ev = { title = 'X', race = 1, laps = 1, kind = 'Sprint' }, pos = 2, time = 120, lap = 120, newLap = true })
T.check(not findText(spec.lines, 'best lap') and not findText(spec.lines, 'BEST LAP'), 'a sprint: no best lap (' .. joined(spec.lines) .. ')')
-- review 8: the seconds on your line, from the race's gaps
local gp2 = K.gaps({ { name = 'Dwayne', you = true, pos = 2, finished = true, time = 100.4 }, { name = 'Biddy Blas', pos = 1, finished = true, time = 100 },
  { name = 'Sen Fira', pos = 3, finished = true, time = 103 } })
T.check(SD.margin(gp2) == '0.4 s behind Biddy Blas', 'the margin: 0.4 s behind the car ahead (' .. tostring(SD.margin(gp2)) .. ')')
local gp1 = K.gaps({ { name = 'Dwayne', you = true, pos = 1, finished = true, time = 100 }, { name = 'Sen Fira', pos = 2, finished = true, time = 107.8 } })
T.check(SD.margin(gp1) == '7.8 s ahead', 'the margin when you won: 7.8 s ahead')
T.check(SD.margin(nil) == nil and SD.margin(K.gaps({ { name = 'Dwayne', you = true, pos = 1, finished = true } })) == nil, 'no times: no margin')
spec = SD.spec({ run = run, ev = { title = 'X', race = 1, laps = 2 }, pos = 2, time = 100.4, gaps = gp2 })
T.check(findText(spec.lines, '2nd   -   1:40.40   -   0.4 s behind Biddy Blas') ~= nil and not findText(spec.lines, 'You:'), 'on your line (' .. joined(spec.lines) .. ')')

-- f) HOME (v0.21: no Next: line, no blurbs), the same measure on every class tile, no League line; the cups page: no
-- how-to, no blurb, no levels line
K.data.titles = {}
K.data.best = { ['100'] = { jakku = 1, lantaana = 1, ando = 2, crait = 3 } }
local home = SC.home()
T.check(#home.lines == 1 and home.lines[1][1] == '' and not findText(home.lines, 'Next:'), 'v0.21: HOME: no Next: line (' .. joined(home.lines) .. ')')
T.check(not findText(home.lines, 'Galactic League') and not findText(home.lines, 'Cups finished'), 'HOME: no League line, no counts')
local infos = {}
for _, it in ipairs(home.items) do infos[#infos + 1] = tostring(it.info) end
T.check(not table.concat(infos, '|'):find('division', 1, true) and not table.concat(infos, '|'):find('League proper', 1, true),
  'v0.21: no class blurbs in HOME\'s info lines')
T.check(not home.items[2].info:find('%a'), 'v0.22: a class has no info line (' .. home.items[2].info .. ')')
local measures = {}
for _, it in ipairs(home.items) do
  if it.classKey and not it.disabled then
    local p = {}
    for _, x in ipairs(it.pips or {}) do p[#p + 1] = x[3] and '-' or 'm' end
    measures[#measures + 1] = tostring(it.badge) .. '/' .. tostring(it.desc) .. '/' .. table.concat(p)
  end
end
T.check(table.concat(measures, ' ; ') == 'nil/nil/------- ; nil/nil/mmmm---', 'v0.24 HOME: no words, a medal pip per cup (4 trophies at 100cc) and the title star (' .. table.concat(measures, ' ; ') .. ')')
K.data.best = {}
T.check(not findText(SC.home().lines, 'Next:'), 'v0.21: a fresh save: no Next: line either')
S.class = '100'
local cups = SC.cups()
T.check(not findText(cups.lines, 'Select a cup') and not findText(cups.lines, 'LANDSPEEDER') and not findText(cups.lines, 'Parts level')
  and not findText(cups.lines, 'League'), 'v0.21: the cups page: no how-to, no blurb, no levels line (' .. joined(cups.lines) .. ')')
-- a sprint's record on the cups page: no lap
local sprintRace
for _, cup in ipairs(K.cups()) do
  for _, r in ipairs(K.races(cup, '100')) do if not sprintRace and SD.sprint(r) then sprintRace = { cup = cup, r = r } end end
end
T.check(sprintRace ~= nil, 'a sprint in the 100cc cups')
K.data.records['100'] = { [sprintRace.r.path] = { time = 61, lap = 61 } }
cups = SC.cups()
local info
for _, it in ipairs(cups.items) do if it.title == sprintRace.cup.name then info = it.info end end
T.check(info and info:find('GRAVEYARD     1:01.00', 1, true) and not info:find('lap', 1, true), 'the cups page: a record is the time alone (v0.22) (' .. tostring(info) .. ')')
K.data.records = {}
T.finish()

---------------------------------------------------------------------------------------------------------------------
-- 2. through the menu: HOME's focus on the class last raced, the label strip, the footer hidden and put back, medal tints
T.reset()
T.boot({ version = 2, races = 4, cups = 1, class = '50', restores = {}, abilityRestores = {},
  last = { class = '100', title = 'X', pos = 1 }, best = { ['100'] = { jakku = 1, lantaana = 3 } } })
H = rawget(_G, 'GU_TEST_SCREENS')
S = H.S
-- the menu's footer: a WBP_ActionBar_C two panels down from the root
local bar = M.new('WBP_ActionBar_C_7', {}, 'WBP_ActionBar_C')
local bp = rawget(bar, '__props')
bp.__vis = 4
bp.GetVisibility = function() return bp.__vis end
bp.SetVisibility = function(_, v) bp.__vis = v end
local function footerMenu()
  local tree = rawget(W.mm, '__props').WidgetTree
  rawget(tree, '__props').RootWidget = W.panel({ M.new('Img_Bg', {}, 'FuseImage'), W.panel({ M.new('Txt_Build', {}, 'FuseTextBlock'), bar }, 'FuseHorizontalBox') }, 'FuseOverlay')
end
footerMenu()
local mark = T.mark()
M.press('F6'); M.tick(6)
T.check(S.screen == 'home' and S.focus == 2, 'HOME opens with the focus on 100CC, the class last raced (' .. tostring(S.focus) .. ')')
T.check(T.logHas('[footer] found WBP_ActionBar_C_7 (WBP_ActionBar_C) at depth 2', mark) and T.logHas('hidden while the GRAND PRIX tab is up', mark),
  'the footer found and logged')
T.check(bp.__vis == 1, 'the footer hidden (collapsed) on our tab')
-- v0.24 (owner: no dark grey bars behind tile text): the label strip is off by default (config TileLabelStrip)
T.check(not T.logHas('[tiles] label strip', mark), 'no label strip made')
-- B into 50CC and back: HOME remembers the tile; a fresh open goes to the class last raced again
rawget(W.tiles[2], '__props').__focus = false
rawget(W.tiles[1], '__props').__focus = true -- (the player moves to 50CC)
M.tick(3)
T.clickTitle('50CC'); M.tick(3)
M.press('BACKSPACE'); M.tick(5)
T.check(S.screen == 'home' and S.focus == 1, 'back from 50cc: the focus stays on 50CC')
-- the medal icons on the 100cc cups: gold and bronze in their own colours (the brush tint)
mark = #M.calls + 1
T.clickTitle('100CC'); M.tick(3)
local tints = {}
for i = mark, #M.calls do
  local c = M.calls[i]
  if c.name == 'SetBrushTintColor' and type(c.args[1]) == 'table' and c.args[1].SpecifiedColor then
    local col = c.args[1].SpecifiedColor
    tints[#tints + 1] = ('%.2f,%.2f,%.2f'):format(col.R, col.G, col.B)
  end
end
local g, b = ART.medalColor(1), ART.medalColor(3)
local function has(s) for _, t in ipairs(tints) do if t == s then return true end end return false end
T.check(has(('%.2f,%.2f,%.2f'):format(g[1], g[2], g[3])) and has(('%.2f,%.2f,%.2f'):format(b[1], b[2], b[3])),
  'the cup tiles\' medal icons tinted gold and bronze (' .. table.concat(tints, ' ; ') .. ')')
-- leaving the tab: the footer put back
mark = T.mark()
W.pickTab('Campaign'); M.tick(6)
T.check(T.logHas('[footer] put back (visibility 4)', mark) and bp.__vis == 4, 'another tab: the footer put back as it was')
-- the tab again: hidden again
W.pickTab('Mod_GrandPrix'); M.tick(6)
T.check(bp.__vis == 1, 'our tab again: hidden again')
T.finish()

---------------------------------------------------------------------------------------------------------------------
-- 3. HideFooter = false and TileLabelStrip = false: the footer only found and logged, the tiles untouched; a menu
-- without the footer says what its root holds
T.reset()
T.boot({ version = 2, races = 0, cups = 0, restores = {}, abilityRestores = {}, best = { ['100'] = { jakku = 1 } } },
  { HideFooter = false, TileLabelStrip = false })
H = rawget(_G, 'GU_TEST_SCREENS')
S = H.S
bp.__vis = 4
footerMenu()
mark = T.mark()
M.press('F6'); M.tick(6)
T.check(T.logHas('not hidden (HideFooter = false)', mark) and bp.__vis == 4, 'HideFooter = false: found, logged, left alone')
T.check(not T.logHas('[tiles] label strip', mark), 'TileLabelStrip = false: no strip')
T.check(rawget(rawget(rawget(W.tiles[2], '__props').VB_ContentLayout, '__props'), '__kids')[2] == rawget(W.tiles[2], '__props').Txt_Label_Supplemental,
  'the badge left in place')
T.check(S.focus == 1, 'no class raced yet: the focus on the first tile')
T.finish()

T.reset()
T.boot({ version = 2, races = 0, cups = 0, restores = {}, abilityRestores = {} })
mark = T.mark()
M.press('F6'); M.tick(6)
T.check(T.logHas('[footer] not found (', mark), 'no footer on the menu: logged with what the root holds')
T.finish()
