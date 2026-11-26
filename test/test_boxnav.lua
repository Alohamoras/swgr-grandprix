-- v0.32.7: the D-pad map from the tiles' boxes (ui.lua U.boxNav): the rows page, the uniform grid with a short last
-- row, a spanning tile; and the home page's map through the mod itself.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } })
local U = require('ui')

-- a grid of 4 columns, 6 tiles (a short last row of 2)
local nav = U.boxNav(U.gridBoxes(6, 4, 400, 300))
T.check(nav[1].right == 2 and nav[2].left == 1 and nav[4].right == nil and nav[1].left == nil, 'grid: left / right within the row, nil at its edges')
T.check(nav[1].down == 5 and nav[2].down == 6 and nav[5].up == 1 and nav[6].up == 2, 'grid: down / up between the rows, column by column')
T.check(nav[3].down == 6 and nav[4].down == 6, 'grid: a short last row - down from the columns past it reaches its nearest (last) tile')
T.check(nav[1].up == nil and nav[5].down == nil and nav[5].left == nil and nav[6].right == nil, 'grid: nothing above the top row or below the last')

-- a rows page: 3 tiles over 2 (centred), then one wide bar (span 3)
local rows = { { w = 400, h = 300, n = 3 }, { w = 400, h = 300, n = 2 }, { w = 400, h = 120 } }
local items = { {}, {}, {}, {}, {}, { span = 3 } }
local boxes = U.rowBoxes(rows, items)
T.check(#boxes == 6 and boxes[6].w == 400 * 3 + U.GAP * 2 and boxes[4].y == 300 + U.GAP and boxes[6].y == 2 * (300 + U.GAP), 'rows: boxes stacked by row height, the spanning tile 3 wide')
T.check(math.abs((boxes[2].x + boxes[2].w / 2)) < 1e-6 and math.abs(boxes[4].x + boxes[4].w / 2 + (400 + U.GAP) / 2) < 1e-6, 'rows: each row centred on x = 0')
nav = U.boxNav(boxes)
T.check(nav[1].right == 2 and nav[3].right == nil and nav[4].right == 5 and nav[4].left == nil, 'rows: left / right stay in the row')
T.check(nav[1].down == 4 and nav[2].down == 4 and nav[3].down == 5, 'rows: down to the nearest centre in the row below (the middle tile ties to the left one)')
T.check(nav[4].up == 1 and nav[5].up == 2, 'rows: up to the nearest centre above (a tie goes to the left one, as before)')
T.check(nav[4].down == 6 and nav[5].down == 6 and nav[6].up == 4 and nav[6].left == nil and nav[6].right == nil, 'rows: the wide bar is reached from both tiles above it and goes back up to the one under its middle (the tie)')
T.check(nav[1].up == nil and nav[6].down == nil, 'rows: edges')

-- the mod's own home page: JUNKER | CHALLENGER | ACE | PODRACING over GARAGE | RESET (test_start's expectation kept)
M.press('F6'); M.tick(6)
local S = rawget(_G, 'GU_TEST_SCREENS').S
T.check(T.titles() == 'JUNKER|CHALLENGER|ACE|PODRACING|GARAGE|RESET PROGRESS', 'home: six tiles (' .. T.titles() .. ')')
local n2 = S.ui.nav
T.check(n2[1].right == 2 and n2[3].left == 2 and n2[3].right == 4 and n2[4].right == nil, 'home: the leagues side by side')
T.check(n2[1].down == 5 and n2[5].up ~= nil and n2[6].up ~= nil and n2[5].right == 6, 'home: down from JUNKER reaches the bottom row, and back up')
T.check(#S.ui.boxes == 6 and S.ui.boxes[5].y > S.ui.boxes[1].y and S.ui.boxes[4].y == S.ui.boxes[1].y, 'home: the boxes kept on the screen (rows stacked)')
-- the game's own navigation got the same links
T.check(M.called('SetNavigationRuleExplicit') >= 8, 'the map pushed into the game\'s navigation rules (' .. M.called('SetNavigationRuleExplicit') .. ' links)')
-- (the arrows are the game's own: it moves focus along the rules U.wire pushed; the mod only follows)
T.finish()
