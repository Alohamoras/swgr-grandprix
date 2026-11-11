-- v0.3.6: four classes. A three-class save (v1) moves up one class: 50cc -> 100cc (parts 3), 100 -> 150, 150 -> 200.
local M = require('mock')
local W = require('world')
local T = require('util')
local f = io.open(T.dir .. '/race_fix.txt', 'w'); f:write('-199\n'); f:close()
T.boot({ version = 1, races = 211, cups = 3, class = '50', vehicle = 'car',
  best = { ['50'] = { jakku = 1, outerrim = 1, lantaana = 1 }, ['150'] = { crait = 2 } },
  run = { class = '100', cup = 'ando', vehicle = 'car', race = 2, races = 4, points = { YOU = 15 }, last = {}, history = { {} } },
  restores = {}, abilityRestores = {} })
local sv = T.save()
T.check(sv.version == 2, 'save is version 2')
T.check(sv.best['100'] and sv.best['100'].jakku == 1 and sv.best['100'].lantaana == 1,
  'the 50cc golds (won with parts 3) are now 100cc golds')
-- (v0.11: the Outer Rim Cup is gone - its gold is dropped after the conversion, logged)
T.check(sv.best['100'].outerrim == nil and T.logHas('[cups] dropped from the save (remix, conditions and Outer Rim cups are gone; records kept): best 100 outerrim'),
  'the Outer Rim gold dropped, logged')
T.check(sv.best['50'] == nil, 'nothing left under the new 50cc (no upgrades)')
T.check(sv.best['200'] and sv.best['200'].crait == 2, 'old 150cc -> 200cc')
-- (the cup in progress moves up too, then is dropped at boot: v0.9, cups cannot be resumed)
T.check(sv.class == '100' and sv.run == nil, 'the last class moves up; the cup in progress is gone')
T.check(T.logHas('[cup] ando 150cc dropped at boot (race 2 of 4): cups cannot be resumed'), 'the converted cup dropped at boot (logged as 150cc)')
T.check(sv.races == 12, 'race_fix.txt applied once (211 - 199 = 12)')
T.check(io.open(T.dir .. '/race_fix.txt') == nil, 'race_fix.txt deleted after use')
T.check(T.logHas('save converted from version 1 to 2'), 'conversion logged')
local p = io.popen('ls "' .. T.dir .. '"'); local files = p:read('a'); p:close()
T.check(files:find('save.backup-v1-', 1, true) ~= nil, 'the old save kept as a backup')
M.press('F6'); M.tick(6)
T.check(T.titles():find('50CC|100CC|150CC|200CC', 1, true) ~= nil, 'four classes on the first screen (' .. T.titles() .. ')')
T.clickTitle('50CC'); M.tick(3)
local n = M.called('LaunchQuickRace')
T.clickTitle('JAKKU CUP'); M.tick(3)
T.check(M.called('LaunchQuickRace') == n + 1 and T.save().run.class == '50', 'a new cup starts at once (nothing left to block it)')
T.finish()
