-- v0.26: the oldest saves (v1, the three-class layout of v0.3.5) get the same clean start as a v2 save
-- (test_leagues): backed up, progress cleared, the garage kept; race_fix.txt still applies once afterwards.
-- (Until v0.25 a v1 save was converted class by class: 50cc -> 100cc ...; that conversion is gone.)
local M = require('mock')
local W = require('world')
local T = require('util')
local f = io.open(T.dir .. '/race_fix.txt', 'w'); f:write('5\n'); f:close()
T.boot({ version = 1, races = 211, cups = 3, class = '50', vehicle = 'car', racer = 'Nomad',
  picks = { 'shockwave.vectored', 'shield.surging', 'vent.flame', 'mine.frozen' }, mods = { 'brawler', 'nope', false, false },
  best = { ['50'] = { jakku = 1, outerrim = 1, lantaana = 1 }, ['150'] = { crait = 2 } },
  run = { class = '100', cup = 'ando', vehicle = 'car', race = 2, races = 4, points = { YOU = 15 }, last = {}, history = { {} } },
  restores = {}, abilityRestores = {} })
local sv = T.save()
T.check(sv.version == 3, 'save is version 3')
T.check(next(sv.best) == nil and sv.run == nil and sv.class == nil and sv.vehicle == nil, 'the old medals, the last class, the vehicle pick and the cup are gone')
T.check(not T.logHas('dropped at boot'), 'no cup left to drop at boot (the clean start cleared it)')
T.check(sv.racer == 'Nomad' and sv.picks[1] == 'shockwave.vectored' and sv.picks[3] == 'vent.flame' and sv.picks[4] == 'mine.frozen',
  'the garage kept: racer and the four picks (branches kept)')
T.check(sv.mods[1] == 'brawler' and sv.mods[2] == false, 'the tune-ups kept, normalised (an unknown key emptied)')
T.check(T.logHas('[save] v0.26: three leagues - a clean start (backup save.backup-v1-'), 'the clean start logged once, with the backup')
T.check(T.logCount('[save] v0.26: three leagues') == 1, 'logged once')
T.check(sv.races == 5, 'race_fix.txt applied once after the clean start (0 + 5)')
T.check(io.open(T.dir .. '/race_fix.txt') == nil, 'race_fix.txt deleted after use')
local p = io.popen('ls "' .. T.dir .. '"'); local files = p:read('a'); p:close()
T.check(files:find('save.backup-v1-', 1, true) ~= nil, 'the old save kept as a backup')
M.press('F6'); M.tick(6)
T.check(T.titles():find('JUNKER|CHALLENGER|ACE', 1, true) ~= nil, 'three leagues on the first screen (' .. T.titles() .. ')')
T.clickTitle('JUNKER'); M.tick(3)
local n = M.called('LaunchQuickRace')
T.clickTitle('JAKKU CUP'); M.tick(3)
T.check(M.called('LaunchQuickRace') == n + 1 and T.save().run.class == 'riffraff', 'a new cup starts at once (nothing left to block it)')
T.finish()
