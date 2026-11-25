-- Offline only: in a party of 2 the tab shows why and nothing launches. A save with builds left to put back
-- (a crash mid-race) is fixed at the main menu.
local M = require('mock')
local W = require('world')
local T = require('util')
local B = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base'
T.boot({ version = 1, races = 2, restores = { [B] = { [0] = 1, 2, 3, 4, 5, 6 } } })
M.tick(3)
T.check(T.levels('VBD_Car_Base') == '0=1 1=2 2=3 3=4 4=5 5=6', 'left-over build put back at the menu')
T.check(next(T.save().restores) == nil, 'and cleared from the save')
-- v0.32: the game's tiles locked (an online queue): START refuses, nothing launched
W.pickTab('Mod_GrandPrix'); M.tick(4)
local ui = rawget(_G, 'GU_TEST_SCREENS').S.ui
T.check(ui ~= nil and #ui.items > 0, 'the home page is up (' .. (ui and #ui.items or 0) .. ' tiles)')
local R = require('race')
local tile = ui.items[1].btn
rawget(tile, '__props').GetLocked = function() return true end
local mark = T.mark()
local ok = R.launch({ path = '/Game/x', title = 'X' }, 'riffraff', 'car')
T.check(ok == false and M.called('LaunchQuickRace') == 0 and T.logHas('[menu] the game has locked its tiles (an online queue?) - nothing launched', mark),
  'a locked tile (the game\'s online queue): launch refused, logged')
rawget(tile, '__props').GetLocked = function() return false end
rawget(tile, '__props').GetIsEnabled = function() return false end
ok = R.launch({ path = '/Game/x', title = 'X' }, 'riffraff', 'car')
T.check(ok == false and T.logHas('[menu] the game has disabled its tiles (an online queue?) - nothing launched', mark), 'a disabled tile: refused too')
rawget(tile, '__props').GetIsEnabled = function() return true end
ok = R.launch({ path = '/Game/x', title = 'X' }, 'riffraff', 'car')
T.check(ok == true and M.called('LaunchQuickRace') == 1, 'tiles live again: the launch goes')
W.race(2); M.tick(5); W.finish(1); M.tick(25)
do local t0 = os.time(); while os.time() - t0 < 3 do end end
W.backToMenu(); M.tick(45)
M.add('PartyManager', M.new('PartyManager', { GetNumPlayersInParty = function() return 2 end }))
W.pickTab('Campaign'); M.tick(4)
W.pickTab('Mod_GrandPrix'); M.tick(4)
T.check(T.logHas('[menu] you are in a party (2 players)') and T.logHas('[menu] offline'), 'party of 2: the offline page')
ok = R.launch({ path = '/Game/x', title = 'X' }, 'riffraff', 'car')
T.check(ok == false and M.called('LaunchQuickRace') == 1, 'party of 2: launch refused')
T.finish()
