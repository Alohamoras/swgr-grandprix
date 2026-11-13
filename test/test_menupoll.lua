-- v0.13.1 (TASKS.md A5): the main menu is not looked up several times a second. Every lookup is a full sweep of the
-- object list in this game (~10 ms); the menu's game mode comes from a notification, with one real sweep every few
-- seconds as a safety net.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot()
local R = require('race')
M.press('F6'); M.tick(6)
T.check(T.titles():find('GARAGE', 1, true) ~= nil, 'HOME is up: ' .. T.titles())

-- idle on HOME: 50 ticks = 10 s of the 200 ms main-menu poll (and 5 s of the 100 ms tick)
M.resetSweeps()
local from = T.mark()
M.tick(50)
local fe, all = M.sweepCount('FrontEndGameMode'), M.sweepCount()
T.check(fe >= 1 and fe <= 5, ('idle on HOME: at most one menu sweep every 2 s (%d in 10 s; v0.13.0: 100)'):format(fe))
T.check(not T.logHas('[menu] closed', from) and T.ntiles() > 0, 'the page stays up')
io.stdout:write(('info: every sweep in 10 s idle on HOME: %d (the rest: the tab\'s menu checks)\n'):format(all))

-- the menu goes without our launch (the game's own modes): noticed by the safety-net sweep within a few seconds
from = T.mark()
M.kill(W.fe); M.kill(W.mm)
M.tick(20)
T.check(not R.menuUp() and T.logHas('[menu] the main menu went away', from), 'a menu that went away is noticed by the safety net')
T.check(M.deadTouches == 0, 'nothing of the old menu touched (' .. M.deadTouches .. ')')

-- a new menu: the notification says so straight away, no sweep needed
M.resetSweeps()
W.frontEnd(); W.tabMenu()
T.check(R.menuUp() and M.sweepCount('FrontEndGameMode') == 0, 'a new menu is known from its notification, without a sweep')
M.tick(25)
M.press('F6'); M.tick(6)
T.check(T.titles():find('GARAGE', 1, true) ~= nil, 'HOME is up again on the new menu')

-- our launch: the menu is gone with it; back at the menu after the race the notification brings it back
T.clickTitle('JUNKER'); M.tick(3)
T.clickTitle('JAKKU CUP')
T.check(R.run ~= nil and not R.menuUp(), 'launching a race: the menu counts as gone')
W.race(11); M.tick(30)
W.finish(1); M.tick(25)
W.backToMenu(); M.tick(45)
T.check(R.run == nil and R.menuUp(), 'back at the menu after the race')
T.check(T.save().races == 1, 'the race is recorded')
T.finish()
