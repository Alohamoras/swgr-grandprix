-- v0.3.11 / v0.8: trophy badges on the cup and class tiles, "race N of 4" on CONTINUE CUP, and RESET PROGRESS (asks
-- first, NO first, backs the save up, keeps your abilities / vehicle / race count).
local M = require('mock')
local W = require('world')
local T = require('util')

T.boot({ version = 2, races = 25, cups = 5, class = '200', vehicle = 'bike',
  picks = { 'bolt.multi', 'shield.surging', 'vent.flame', 'mine.frozen' },
  best = { ['100'] = { jakku = 1, lantaana = 2, outerrim = 3 }, ['200'] = { jakku = 1, crait = 5 } },
  run = { class = '200', cup = 'lantaana', vehicle = 'car', race = 4, races = 4,
    points = { YOU = 37, ['Katja Mox'] = 40 }, last = {}, history = { {}, {}, {} } },
  restores = {}, abilityRestores = {} })
local NCUPS = #dofile(T.dir .. '/Scripts/config.lua').Cups
M.press('F6'); M.tick(6)
T.check(T.titles() == 'CONTINUE CUP|QUIT CUP|50CC|100CC|150CC|200CC|GARAGE|RESET PROGRESS', 'home (' .. T.titles() .. ')')
T.check(T.badges() == ('RACE 4 / 4|||1 / %d GOLD|LOCKED|1 / %d GOLD||'):format(NCUPS, NCUPS), 'badges: race 4 / 4 on CONTINUE, golds per class, 150cc locked (' .. T.badges() .. ')')
T.clickTitle('100CC'); M.tick(3)
local b = T.badges()
T.check(b:find('^GOLD TROPHY|SILVER TROPHY|') ~= nil, 'cups at 100cc: Jakku gold, Lantaana silver (' .. b .. ')')
T.check(b:find('BRONZE TROPHY', 1, true) ~= nil, 'Outer Rim bronze')
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('200CC'); M.tick(3)
b = T.badges()
T.check(b:find('^GOLD TROPHY|IN PROGRESS  4 / 4|') ~= nil, 'cups at 200cc: Jakku gold, Lantaana in progress 4 / 4 (' .. b .. ')')
M.press('BACKSPACE'); M.tick(3)

-- reset: NO first, and NO keeps everything
T.clickTitle('RESET PROGRESS'); M.tick(3)
T.check(T.titles() == 'NO|YES', 'the confirm screen puts NO first (' .. T.titles() .. ')')
T.clickTitle('NO'); M.tick(3)
T.check(T.save().best['100'].jakku == 1 and T.save().run ~= nil, 'NO: nothing cleared')
T.clickTitle('RESET PROGRESS'); M.tick(3)
T.clickTitle('YES'); M.tick(3)
local sv = T.save()
T.check(next(sv.best) == nil and sv.run == nil and sv.cups == 0, 'YES: trophies, best finishes, the cup in progress and the cups count cleared')
T.check(sv.picks[1] == 'bolt.multi' and sv.vehicle == 'bike' and sv.races == 25, 'kept: your abilities, vehicle, race count')
T.check(T.logHas('progress reset'), 'reset logged')
local p = io.popen('ls "' .. T.dir .. '"'); local files = p:read('a'); p:close()
local bk = files:match('(save%.backup%-reset%-[%d%-]+%.lua)')
T.check(bk ~= nil, 'a backup made first (' .. tostring(bk) .. ')')
local old = bk and dofile(T.dir .. '/' .. bk)
T.check(old and old.best['100'].jakku == 1 and old.run and old.run.cup == 'lantaana', 'the backup holds the old progress')
T.check(T.titles() == '50CC|100CC|150CC|200CC|GARAGE|RESET PROGRESS' and T.badges() == '||LOCKED|LOCKED||', 'home clean, 150cc and 200cc locked again (' .. T.badges() .. ')')
T.finish()
