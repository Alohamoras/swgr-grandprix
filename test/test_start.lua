-- v0.24 (owner): the garage is every race's start screen. HOME has no GARAGE tile (v0.26: three leagues as tall
-- posters with medal pips, RESET; v0.27 the focused poster's tagline, no speed chevrons); a cup opens the garage with START focused, the cup's name,
-- the league and (v0.26) its four drawn races on top; START races exactly those; B goes back to the cups. The pictures
-- on the tiles: lock, medals, pips, chevrons, ability and tune-up icons.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 3, best = { challenger = { jakku = 1, lantaana = 3 } } }, { StartScreen = true, Progression = { On = false } })
local H = rawget(_G, 'GU_TEST_SCREENS')
local S = H.S
local ART = require('art')
M.press('F6'); M.tick(6)

-- HOME
T.check(T.titles() == 'JUNKER|CHALLENGER|ACE|RESET PROGRESS', 'HOME: the three leagues and RESET, no GARAGE (' .. T.titles() .. ')')
T.check(S.ui.rows and S.ui.nav ~= nil, 'HOME in rows (the D-pad map made)')
T.check(T.pips('CHALLENGER') == 'GB-----.', 'Challenger: gold, bronze, five faint medals, the title star not won (' .. tostring(T.pips('CHALLENGER')) .. ')')
T.check(T.badges() == '|||', 'no words on the HOME tiles (' .. T.badges() .. ')')
T.check(T.marks():find('^pips:%S+|pips:%S+|pips:%S+|$') ~= nil, 'v0.27: only the medal pips on the posters, no chevrons (' .. T.marks() .. ')')
T.check(S.ui.items[1].desc == 'Scrapyard junk with too much engine' and S.ui.items[3].desc == 'Money, maxed out, and a clean field',
  'v0.27: each poster\'s tagline (' .. tostring(S.ui.items[1].desc) .. ')')
T.check(S.ui.nav[1].down == 4 and S.ui.nav[4].up ~= nil, 'down from JUNKER reaches RESET, and back up')

-- the cups page -> the start screen
T.clickTitle('CHALLENGER'); M.tick(3)
local CP = H.SCREENS.cups()
T.check(CP.title == 'CHALLENGER' and CP.lines[1][1] == 'Balanced engines   -   two abilities   -   one tune-up', 'v0.27: the league\'s brief under its name on the cups page (' .. tostring(CP.lines[1][1]) .. ')')
local mark = T.mark()
local calls = #M.calls
T.clickTitle('JAKKU CUP'); M.tick(5)
local launched = false
for i = calls + 1, #M.calls do if M.calls[i].name == 'LaunchQuickRace' then launched = true end end
T.check(not launched and S.screen == 'garage', 'a cup opens the start screen, no race yet')
T.check(T.logHas('[menu] garage', mark), 'logged')
local its = S.ui.items
T.check(its[1].kind == 'racer' and its[1].span == 2, 'your racer first, two tiles wide')
T.check(its[#its].title == 'START' and S.focus == #its, 'START last, and focused (' .. tostring(S.focus) .. ' of ' .. #its .. ')')
local abil, tune = 0, 0
for _, it in ipairs(its) do
  if it.kind == 'ability' then abil = abil + 1; T.check(it.glyph and it.glyph[1]:find('LargeAbilityIcons', 1, true), 'ability ' .. abil .. ': the game\'s ability icon') end
  if it.kind == 'tuneup' then tune = tune + 1 end
end
T.check(abil == 4 and tune == 2, 'four abilities, two tune-up slots (the second opens at Ace)')
-- v0.27.4 (owner: tune-ups and abilities looked alike; icons stretched): captions; the Ace slot greyed and locked
local tags, t2 = {}, nil
for _, it in ipairs(its) do
  if it.tag then tags[#tags + 1] = it.tag[1] end
  if it.kind == 'tuneup' and it.disabled then t2 = it end
end
T.check(table.concat(tags, ',') == 'PILOT,VEHICLE,TUNE-UP,TUNE-UP,ABILITY,ABILITY,ABILITY,ABILITY', 'v0.27.4 (v0.31: PILOT and VEHICLE first): a caption on each slot (' .. table.concat(tags, ',') .. ')')
T.check(t2 and t2.title == 'TUNE-UP 2' and t2.corner and t2.corner[1][1] == ART.LOCK and t2.info == 'Tune-up 2 opens at ACE.',
  'v0.27.4: at Challenger the second tune-up slot greyed with a lock, says it opens at Ace')
T.check(T.marks():find('LOCK', 1, true) ~= nil, 'the lock drawn on the tile (' .. T.marks() .. ')')
local H1 = S.ui and H.SCREENS.garage()
local head = {}
for i = 1, 5 do head[i] = tostring((H1.lines[i] or {})[1]) end
T.check(H1.title == 'JAKKU CUP' and head[1] == 'CHALLENGER', 'v0.26: the cup, then the league on top (' .. head[1] .. ')')
local listed = false
for i = 2, #H1.lines do if tostring(H1.lines[i][1]):find('^%d   ') then listed = true end end
T.check(not listed, 'v0.28.3 (owner): no race list - the game\'s own intro shows each track (' .. table.concat(head, ' | ', 2) .. ')')
do
  require('config').StartRaceList = true
  local H2 = H.SCREENS.garage()
  require('config').StartRaceList = nil
  T.check(H2.lines[2] and H2.lines[2][1] == '1   THE WAR FIELDS (REVERSE, SCORCHING)' and H2.lines[5] and H2.lines[5][1] == '4   FALLEN EMPIRE (SCORCHING)',
    'StartRaceList = true: the four drawn races back')
end

-- B goes back to the cups, nothing started
M.press('BACKSPACE'); M.tick(3)
T.check(S.screen == 'cups' and T.save().run == nil, 'B: back to the cups, no cup begun')

-- a tune-up picked on the start screen, then START
T.clickTitle('JAKKU CUP'); M.tick(5)
local n = 0
for i, it in ipairs(S.ui.items) do if it.kind == 'tuneup' and n == 0 then n = i end end
T.click(n); M.tick(5)
T.check(S.screen == 'garage' and S.ui.items[n].title == 'HEAT SHIELD', 'a tune-up changed on the start screen (' .. tostring(S.ui.items[n].title) .. ')')
T.check(S.focus == n, 'the focus stays on the tile you changed')
calls = #M.calls
T.clickTitle('START'); M.tick(5)
launched = false
for i = calls + 1, #M.calls do if M.calls[i].name == 'LaunchQuickRace' then launched = true end end
T.check(launched and T.save().run and T.save().run.cup == 'jakku' and T.save().run.class == 'challenger', 'START: the Jakku Cup at Challenger, race 1 launched')
T.check(T.launched() == 'EVT_MAS_LOOP_A_REV_HARD' and T.drawn()[1] == T.launched(), 'START launches race 1 of the draw shown')
T.check(T.save().run.mods and T.save().run.mods[1] == 'heat_shield', 'the cup keeps the tune-up picked on its start screen')
T.check(S.start == nil, 'the start request is used up')
T.finish()
