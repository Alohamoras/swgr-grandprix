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
M.add('PartyManager', M.new('PartyManager', { GetNumPlayersInParty = function() return 2 end }))
W.pickTab('Mod_GrandPrix'); M.tick(4)
T.check(T.logHas('[menu] you are in a party (2 players)') and T.logHas('[menu] offline'), 'party of 2: the offline page')
local R = require('race')
local ok = R.launch({ path = '/Game/x', title = 'X' }, 'riffraff', 'car')
T.check(ok == false and M.called('LaunchQuickRace') == 0, 'party of 2: launch refused')
T.finish()
