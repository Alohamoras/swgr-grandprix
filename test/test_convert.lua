-- v0.3.6: four classes. A three-class save (v1) moves up one class: 50cc -> 100cc (parts 3), 100 -> 150, 150 -> 200.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 1, races = 12, cups = 3, class = '50', vehicle = 'car',
  best = { ['50'] = { jakku = 1, outerrim = 1, lantaana = 1 }, ['150'] = { crait = 2 } },
  run = { class = '100', cup = 'ando', vehicle = 'car', race = 2, races = 4, points = { YOU = 15 }, last = {}, history = { {} } },
  restores = {}, abilityRestores = {} })
local sv = T.save()
T.check(sv.version == 2, 'save is version 2')
T.check(sv.best['100'] and sv.best['100'].jakku == 1 and sv.best['100'].outerrim == 1 and sv.best['100'].lantaana == 1,
  'the three 50cc golds (won with parts 3) are now 100cc golds')
T.check(sv.best['50'] == nil, 'nothing left under the new 50cc (no upgrades)')
T.check(sv.best['200'] and sv.best['200'].crait == 2, 'old 150cc -> 200cc')
T.check(sv.run.class == '150' and sv.class == '100', 'the cup in progress and the last class move up too')
T.check(sv.races == 12 and sv.run.points.YOU == 15, 'nothing else changed')
T.check(T.logHas('save converted from version 1 to 2'), 'conversion logged')
local p = io.popen('ls "' .. T.dir .. '"'); local files = p:read('a'); p:close()
T.check(files:find('save.backup-v1-', 1, true) ~= nil, 'the old save kept as a backup')
M.press('F6'); M.tick(6)
T.check(T.titles():find('50CC|100CC|150CC|200CC', 1, true) ~= nil, 'four classes on the first screen (' .. T.titles() .. ')')
T.clickTitle('50CC'); M.tick(3)
T.clickTitle('JAKKU CUP'); M.tick(3)
T.check(T.titles():find('GO TO IT', 1, true) ~= nil, 'the 150cc cup in progress still blocks a new one')
T.finish()
