-- v0.8: track records (best time / lap per track and league, v0.26: still per exact event path), perfect cups, cup
-- standings and the league champion.
-- A race read through race.lua (time and lap from the RaceEventComponent), then K.record directly for the rest.
local M = require('mock')
local W = require('world')
local T = require('util')
local EV = '/Game/Griffin/Gameplay/Events/Planets/'
local WAR = EV .. 'Mastiff/Loop_A/EVT_MAS_LOOP_A_REV_HARD' -- (v0.26: the tests' Jakku draw opens on The War Fields reverse, scorching)
T.boot({ version = 3, races = 3, cups = 0, class = 'riffraff', racer = 'Rager', -- (v0.15: Biddy Blas rides a bike)
  run = { class = 'riffraff', cup = 'jakku', vehicle = 'bike', race = 1, races = 4, points = {}, last = {}, history = {} },
  restores = {}, abilityRestores = {} })
local K = require('gp')
local CU = require('cup')

-- fmtTime
T.check(K.fmtTime(124.31) == '2:04.31', 'fmtTime 124.31 -> 2:04.31 (' .. K.fmtTime(124.31) .. ')')
T.check(K.fmtTime(58.1) == '0:58.10', 'fmtTime 58.1 -> 0:58.10')
T.check(K.fmtTime(59.999) == '1:00.00', 'fmtTime rounds to centiseconds without 1:60.00')
T.check(K.fmtTime(0) == '0:00.00' and K.fmtTime(600) == '10:00.00', 'fmtTime 0 and 10 minutes')
T.check(K.fmtTime(nil) == '-' and K.fmtTime('x') == '-', 'fmtTime nil / junk -> -')

-- a new save: the fields are there, nothing in them
local sv = K.data
T.check(type(sv.records) == 'table' and type(sv.perfect) == 'table' and type(sv.standings) == 'table' and sv.version == 3,
  'records / perfect / standings filled in a save that had none (no clean start); version stays 3')
T.check(not T.logHas('a clean start'), 'no clean start for a v3 save')
T.check(K.recordFor('riffraff', WAR) == nil and K.champion('riffraff') == nil and K.perfect('riffraff', 'jakku') == false,
  'no record, no champion, no perfect cup yet')

-- race 1 of the cup through the menu: the time and lap come from the race read
M.press('F6'); M.tick(6)
T.clickTitle('RIFF-RAFF'); M.tick(3)
T.clickTitle('JAKKU CUP')
T.check(M.called('LaunchQuickRace') == 1, 'race 1 launched')
W.race(11); M.tick(5)
W.lap(60.5, 2); M.tick(25)           -- lap 1 done
W.lap(58.1, 2); M.tick(25)           -- a better lap read later
for i, b in ipairs(W.bots) do
  local rec = rawget(rawget(b, '__props').RaceEventComponent, '__props')
  rec.EventPosition = i + 1; rec.bHasFinishedEvent = true
end
W.finish(1, 124.31, 58.1); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
sv = T.save()
local rec = sv.records['riffraff'] and sv.records['riffraff'][WAR]
T.check(rec and rec.time == 124.31 and rec.lap == 58.1, 'record written from the race: time 2:04.31, lap 0:58.10')
T.check(rec and rec.vehicle == 'bike' and rec.at == os.date('%Y-%m-%d'), 'with the cup\'s vehicle (Biddy Blas: the bike) and today\'s date')
T.check(T.logHas('NEW RECORD THE WAR FIELDS (REVERSE, SCORCHING) RIFF-RAFF: 2:04.31') and not T.logHas('2:04.31 (was '), 'NEW RECORD logged, no "was" the first time')
T.check(T.logHas('RESULT THE WAR FIELDS (REVERSE, SCORCHING): 1st (time 2:04.31, best lap 0:58.10'), 'RESULT line shows the time and lap')
T.check(sv.last.time == 124.31 and sv.last.lap == 58.1, 'last race keeps its time and lap')
T.check(sv.run and sv.run.race == 2 and sv.run.points.YOU == 15, 'the cup went on: race 2 next, you 15 points')
T.check(K.recordFor('riffraff', EV .. 'Mastiff/P2P_A/EVT_MAS_P2P_FWD') == nil and K.recordFor('riffraff', EV .. 'Mastiff/Loop_A/EVT_MAS_LOOP_A_REV') == nil,
  'v0.26: per exact event path - The War Fields reverse without scorching has no record of its own yet')

-- the same track again, outside the cup (no cup / race in ev): slower -> the record stays; a better lap counts
local ev = { path = WAR, title = 'THE WAR FIELDS', class = 'riffraff' }
local field = { { name = 'Kestar Bool', pos = 1, finished = true }, { name = 'Dwayne', you = true, pos = 2, finished = true } }
local out = K.record(ev, 2, field, { time = 130, lap = 57.5, top = 500 })
rec = K.recordFor('riffraff', WAR)
T.check(rec.time == 124.31 and not out.newRecord and out.oldTime == nil, 'a slower race keeps the record')
T.check(rec.lap == 57.5 and out.newLap, 'but the better lap is the new best lap')
T.check(out.time == 130 and out.lap == 57.5, 'the result carries this race\'s time and lap')
-- faster: the record moves, with the old one in the result and the log
local m = T.mark()
out = K.record(ev, 1, field, { time = 120.5, lap = 59, top = 500 })
T.check(out.newRecord and out.oldTime == 124.31 and K.recordFor('riffraff', WAR).time == 120.5, 'a faster race: new record, old time given')
T.check(not out.newLap and K.recordFor('riffraff', WAR).lap == 57.5, 'a slower lap keeps the best lap')
T.check(T.logHas('NEW RECORD THE WAR FIELDS RIFF-RAFF: 2:00.50 (was 2:04.31)', m), 'NEW RECORD ... (was ...) logged')
-- a DNF: the lap counts, the time never (race.lua passes no time; even if it did, pos nil = not finished)
out = K.record(ev, nil, { { name = 'Dwayne', you = true, pos = 5, finished = false } }, { time = nil, lap = 50, top = 400 })
rec = K.recordFor('riffraff', WAR)
T.check(rec.time == 120.5 and rec.lap == 50 and out.newLap and not out.newRecord, 'DNF: the lap is written, the time kept')
-- another league is separate; a race with no league writes nothing
K.record({ path = WAR, title = 'THE WAR FIELDS', class = 'ace' }, 1, field, { time = 100, lap = 40 })
T.check(K.recordFor('ace', WAR).time == 100 and K.recordFor('riffraff', WAR).time == 120.5, 'records are per league')
K.record({ path = EV .. 'X/EVT_X', title = 'X' }, 1, field, { time = 100, lap = 40 })
T.check(K.recordFor('riffraff', EV .. 'X/EVT_X') == nil, 'no league: no record')
T.check(sv.records ~= nil and T.save().records['riffraff'][WAR].time == 120.5, 'the records are in the save file')

-- a perfect cup: 1st in every race; the final standings saved
K.forfeit()
local function won(i)
  local f = { { name = 'Dwayne', you = true, pos = 1, finished = true } }
  for j, n in ipairs({ 'Kestar Bool', 'Katja Mox', 'Sen Fira' }) do f[#f + 1] = { name = n, pos = j + 1, finished = true } end
  return f
end
-- (v0.26: the cup's next race is the next of its draw, K.nextRace)
local function cupEv() return K.nextRace() end
K.startCup('riffraff', 'ando', 'car')
local andoList = K.run().list
for i = 1, 4 do out = K.record(cupEv(), 1, won(i), { time = 100 + i, lap = 40 }) end
T.check(out.cupOver and out.rank == 1 and out.perfect == true, 'four wins: cup over, 1st, perfect')
T.check(K.perfect('riffraff', 'ando') == true and T.save().perfect['riffraff'].ando == true, 'perfect cup saved')
T.check(T.logHas('cup over: RIFF-RAFF ando - you 1st with 60 points, GOLD trophy - PERFECT CUP'), 'PERFECT CUP logged')
local st = K.standings('riffraff', 'ando')
T.check(st and st.YOU == 60 and st['Kestar Bool'] == 48 and st['Sen Fira'] == 36, 'final standings saved: YOU 60, Kestar 48, Sen Fira 36')
T.check(T.save().standings['riffraff'].ando.YOU == 60, 'in the save file')
T.check(K.recordFor('riffraff', andoList[3].path).time == 103, 'each race of the cup set its track record (by its exact path)')
T.check(K.recordFor('riffraff', andoList[3].path).vehicle == 'car', 'with the cup\'s vehicle')

-- a cup won but not perfectly (2nd in one race): gold, not perfect; standings saved
K.startCup('riffraff', 'crait', 'car')
for i = 1, 4 do
  local f = won(i)
  if i == 3 then f[1].pos = 2; f[2].pos = 1 end -- Kestar wins race 3
  out = K.record(cupEv(), i == 3 and 2 or 1, f, { time = 100, lap = 40 })
end
T.check(out.cupOver and out.rank == 1 and out.trophy == 'GOLD' and out.perfect == false, 'gold without a perfect cup')
T.check(K.perfect('riffraff', 'crait') == false and (T.save().perfect['riffraff'] or {}).crait == nil, 'not marked perfect')
T.check(CU.perfect({ races = 4, history = { { { key = 'YOU', place = 1 } } } }) == false, 'CU.perfect: not every race run yet -> false')

-- champion: the racer with the most points over the saved planet cups (YOU left out, the Galactic Cup too)
local name, pts = K.champion('riffraff')
T.check(name == 'Kestar Bool' and pts == 48 + 51, 'champion at Riff-Raff from two cups: Kestar Bool, 99 points (' .. tostring(name) .. ', ' .. tostring(pts) .. ')')
K.data.standings['riffraff'].galactic = { YOU = 10, ['Katja Mox'] = 999 }
K.data.standings['riffraff'].jakku_remix = { ['Katja Mox'] = 999 } -- (a cup no longer in the config)
T.check(K.champion('riffraff') == 'Kestar Bool', 'the Galactic Cup and unknown cups don\'t count')
K.data.standings['riffraff'].jakku = { YOU = 200, ['Katja Mox'] = 60 }
name, pts = K.champion('riffraff')
T.check(name == 'Katja Mox' and pts == 40 + 40 + 60, 'a third cup turns it: Katja Mox, 140 (' .. tostring(name) .. ', ' .. tostring(pts) .. ')')
T.check(K.champion('ace') == nil, 'no planet cup finished at Ace: no champion')

-- counts for the league tile
local g, of = K.golds('riffraff')
local tr = K.trophies('riffraff')
T.check(g == 2 and of == #K.cups() and of == 6, 'golds: 2 of 6 cups (5 planets + Galactic) (' .. g .. ' / ' .. of .. ')')
T.check(tr == 2, 'trophies: 2')
K.data.best['riffraff'].jakku = 3
T.check(K.golds('riffraff') == 2 and K.trophies('riffraff') == 3, 'a bronze counts as a trophy, not a gold')

-- reset clears them too
K.reset()
sv = T.save()
T.check(next(sv.records) == nil and next(sv.perfect) == nil and next(sv.standings) == nil, 'RESET PROGRESS clears records, perfect cups and standings')
T.finish()
