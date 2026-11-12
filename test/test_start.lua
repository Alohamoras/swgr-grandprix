-- v0.24 (owner): the garage is every race's start screen. HOME has no GARAGE tile (four classes as tall posters with
-- medal pips, RESET); a cup opens the garage with START focused, the cup's name and conditions on top; START races;
-- B goes back to the cups. The pictures on the tiles: lock, medals, pips, ability and tune-up icons.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 2, best = { ['100'] = { jakku = 1, lantaana = 3 } } }, { StartScreen = true, Progression = { On = false } })
local H = rawget(_G, 'GU_TEST_SCREENS')
local S = H.S
local ART = require('art')
M.press('F6'); M.tick(6)

-- HOME
T.check(T.titles() == '50CC|100CC|150CC|200CC|RESET PROGRESS', 'HOME: the four classes and RESET, no GARAGE (' .. T.titles() .. ')')
T.check(S.ui.rows and S.ui.nav ~= nil, 'HOME in rows (the D-pad map made)')
T.check(T.pips('100CC') == 'GB----.', '100cc: gold, bronze, four faint medals, the title star not won (' .. tostring(T.pips('100CC')) .. ')')
T.check(T.badges() == '||||', 'no words on the HOME tiles (' .. T.badges() .. ')')
T.check(S.ui.nav[1].down == 5 and S.ui.nav[5].up ~= nil, 'down from 50CC reaches RESET, and back up')

-- the cups page -> the start screen
T.clickTitle('150CC'); M.tick(3)
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
T.check(abil == 4 and tune == 2, 'four abilities, two tune-up slots at 150cc')
local H1 = S.ui and H.SCREENS.garage()
T.check(H1.title == 'JAKKU CUP' and H1.lines[1][1]:find('^150CC   %-   ') ~= nil, 'the cup and its class and conditions on top (' .. tostring(H1.lines[1][1]) .. ')')

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
T.check(launched and T.save().run and T.save().run.cup == 'jakku' and T.save().run.class == '150', 'START: the Jakku Cup at 150cc, race 1 launched')
T.check(T.save().run.mods and T.save().run.mods[1] == 'heat_shield', 'the cup keeps the tune-up picked on its start screen')
T.check(S.start == nil, 'the start request is used up')
T.finish()
