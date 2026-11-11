-- v0.3.11 / v0.8 / v0.9: trophy badges on the cup and class tiles, a cup left in the save dropped at boot (cups
-- cannot be resumed), and RESET PROGRESS (asks first, NO first, backs the save up, keeps your abilities / racer /
-- race count).
local M = require('mock')
local W = require('world')
local T = require('util')

T.boot({ version = 2, races = 25, cups = 5, class = '200', vehicle = 'bike', racer = 'Rager',
  picks = { 'bolt.multi', 'shield.surging', 'vent.flame', 'mine.frozen' },
  best = { ['100'] = { jakku = 1, lantaana = 2, galactic = 3 }, ['200'] = { jakku = 1, crait = 5 } },
  run = { class = '200', cup = 'lantaana', vehicle = 'car', race = 4, races = 4,
    points = { YOU = 37, ['Katja Mox'] = 40 }, last = {}, history = { {}, {}, {} } },
  restores = {}, abilityRestores = {} })
local NCUPS = #dofile(T.dir .. '/Scripts/config.lua').Cups
-- v0.9: the cup in the save (the game was closed or crashed mid-cup) is dropped at boot, logged
T.check(T.logHas('[cup] lantaana 200cc dropped at boot (race 4 of 4): cups cannot be resumed'), 'the cup in the save is dropped at boot, logged')
T.check(T.save().run == nil, 'no cup in the save any more')
T.check(T.save().best['200'].jakku == 1 and T.save().races == 25, 'trophies and counts untouched')
M.press('F6'); M.tick(6)
T.check(T.titles() == '50CC|100CC|150CC|200CC|GARAGE|RESET PROGRESS', 'home: no cup tiles (' .. T.titles() .. ')')
T.check(T.badges() == ('|3 / %d TROPHIES|LOCKED|1 / %d TROPHIES||'):format(NCUPS, NCUPS), 'badges (v0.20: trophies on every class) per class, 150cc locked, 200cc kept open (' .. T.badges() .. ')')
T.clickTitle('100CC'); M.tick(3)
local b = T.badges()
T.check(b:find('^GOLD TROPHY|SILVER TROPHY|') ~= nil, 'cups at 100cc: Jakku gold, Lantaana silver (' .. b .. ')')
T.check(b:find('|BRONZE TROPHY|', 1, true) ~= nil and T.titles():find('|GALACTIC CUP|TITLE RACE$') ~= nil, 'Galactic Cup bronze, the sixth tile (' .. b .. ')')
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('200CC'); M.tick(3)
b = T.badges()
T.check(b:find('^GOLD TROPHY|LANTAANA|') ~= nil, 'cups at 200cc: Jakku gold, Lantaana not in progress any more (' .. b .. ')')
M.press('BACKSPACE'); M.tick(3)

-- reset: NO first, and NO keeps everything
T.clickTitle('RESET PROGRESS'); M.tick(3)
T.check(T.titles() == 'NO|YES', 'the confirm screen puts NO first (' .. T.titles() .. ')')
T.clickTitle('NO'); M.tick(3)
T.check(T.save().best['100'].jakku == 1 and T.save().cups == 5, 'NO: nothing cleared')
T.clickTitle('RESET PROGRESS'); M.tick(3)
T.clickTitle('YES'); M.tick(3)
local sv = T.save()
T.check(next(sv.best) == nil and sv.run == nil and sv.cups == 0, 'YES: trophies, best finishes and the cups count cleared')
T.check(sv.picks[1] == 'bolt.multi' and sv.racer == 'Rager' and sv.vehicle == nil and sv.races == 25, 'kept: your abilities, racer, race count (v0.15: the old vehicle pick dropped)')
T.check(T.logHas('progress reset'), 'reset logged')
local p = io.popen('ls "' .. T.dir .. '"'); local files = p:read('a'); p:close()
local bk = files:match('(save%.backup%-reset%-[%d%-]+%.lua)')
T.check(bk ~= nil, 'a backup made first (' .. tostring(bk) .. ')')
local old = bk and dofile(T.dir .. '/' .. bk)
T.check(old and old.best['100'].jakku == 1 and old.best['200'].crait == 5 and old.cups == 5, 'the backup holds the old progress')
T.check(T.titles() == '50CC|100CC|150CC|200CC|GARAGE|RESET PROGRESS' and T.badges() == '||LOCKED|LOCKED||', 'home clean, 150cc and 200cc locked again (' .. T.badges() .. ')')
T.finish()
