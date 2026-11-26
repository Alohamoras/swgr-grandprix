-- v0.3.11 / v0.8 / v0.9: trophy badges on the cup and class tiles, a cup left in the save dropped at boot (cups
-- cannot be resumed), and RESET PROGRESS (v0.21: asks twice, NO first, backs the save up, clears everything but your
-- abilities / racer / tune-ups - the race count too; test_reset has the rest).
local M = require('mock')
local W = require('world')
local T = require('util')

T.boot({ version = 3, races = 25, cups = 5, class = 'ace', racer = 'Rager',
  picks = { 'bolt.multi', 'shield.surging', 'vent.flame', 'mine.frozen' },
  best = { riffraff = { jakku = 1, lantaana = 2, galactic = 3 }, ['ace'] = { jakku = 1, crait = 5 } },
  run = { class = 'ace', cup = 'lantaana', vehicle = 'car', race = 4, races = 4,
    points = { YOU = 37, ['Katja Mox'] = 40 }, last = {}, history = { {}, {}, {} } },
  restores = {}, abilityRestores = {} })
local NCUPS = #dofile(T.dir .. '/Scripts/config.lua').Cups
-- v0.9: the cup in the save (the game was closed or crashed mid-cup) is dropped at boot, logged
T.check(T.logHas('[cup] lantaana ACE dropped at boot (race 4 of 4): cups cannot be resumed'), 'the cup in the save is dropped at boot, logged')
T.check(T.save().run == nil, 'no cup in the save any more')
T.check(T.save().best['ace'].jakku == 1 and T.save().races == 25, 'trophies and counts untouched')
M.press('F6'); M.tick(6)
T.check(T.titles() == 'JUNKER|CHALLENGER|ACE|PODRACING|GARAGE|RESET PROGRESS', 'home: no cup tiles (' .. T.titles() .. ')')
T.check(T.locks() == '|||||' and T.pips('JUNKER'):gsub('-', ''):len() == 4 and T.pips('ACE'):gsub('-', ''):len() == 2,
  'v0.24: medal pips per league (Riff-Raff three trophies + the title star, Ace one), Challenger open (v0.27.2), Ace kept open (raced) (' .. T.marks() .. ')')
T.clickTitle('JUNKER'); M.tick(3)
local b = T.medals()
T.check(b:find('^GOLD|SILVER|') ~= nil and not T.badges():find('TROPHY', 1, true), 'cups at Riff-Raff: Jakku gold, Lantaana silver, as medals only (v0.22: no medal words) (' .. b .. ')')
T.check(b:find('|BRONZE|', 1, true) ~= nil and T.titles():find('|GALACTIC CUP|RALLY CUP$') ~= nil, 'Galactic Cup bronze, the sixth tile (' .. b .. ')')
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('ACE'); M.tick(3)
b = T.medals()
T.check(b:find('^GOLD||') ~= nil and T.badges():find('^|||') ~= nil, 'cups at Ace: Jakku gold, Lantaana not in progress any more (' .. b .. ')')
M.press('BACKSPACE'); M.tick(3)

-- reset: NO first, and NO keeps everything
T.clickTitle('RESET PROGRESS'); M.tick(3)
T.check(T.titles() == 'NO|YES', 'the confirm screen puts NO first (' .. T.titles() .. ')')
T.clickTitle('NO'); M.tick(3)
T.check(T.save().best.riffraff.jakku == 1 and T.save().cups == 5, 'NO: nothing cleared')
T.clickTitle('RESET PROGRESS'); M.tick(3)
T.clickTitle('YES'); M.tick(3)
T.check(T.titles() == 'NO|YES', 'v0.21: a second question, NO first')
T.clickTitle('YES'); M.tick(3)
local sv = T.save()
T.check(next(sv.best) == nil and sv.run == nil and sv.cups == 0 and sv.races == 0, 'YES, YES: trophies, best finishes and the counts cleared')
T.check(sv.picks[1] == 'bolt.multi' and sv.racer == 'Rager', 'kept: your abilities and racer')
T.check(T.logHas('progress reset'), 'reset logged')
local p = io.popen('ls "' .. T.dir .. '"'); local files = p:read('a'); p:close()
local bk = files:match('(save%.backup%-reset%-[%d%-]+%.lua)')
T.check(bk ~= nil, 'a backup made first (' .. tostring(bk) .. ')')
local old = bk and dofile(T.dir .. '/' .. bk)
T.check(old and old.best.riffraff.jakku == 1 and old.best['ace'].crait == 5 and old.cups == 5, 'the backup holds the old progress')
T.check(T.titles() == 'JUNKER|CHALLENGER|ACE|PODRACING|GARAGE|RESET PROGRESS' and T.locks() == '||LOCKED|||', 'home clean, Ace locked again (v0.27.2: Challenger always open) (' .. T.marks() .. ')')
T.finish()
