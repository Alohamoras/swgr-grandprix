-- v0.10: the gap log after each race (gp.lua K.gaps / K.gapsLine, race.lua reads every racer's EventFinishTime).
-- Pure checks first (you 1st, you mid-field, a DNF bot, you DNF), then one race read through race.lua.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } })
local K = require('gp')

local ev = { title = 'THE WAR FIELDS', class = '150' }
local function racer(name, pos, time, finished)
  return { name = name, pos = pos, time = time, finished = finished ~= false, you = name == 'YOU' or nil }
end

-- you 1st
local g = K.gaps({ racer('YOU', 1, 102.39), racer('Goli & 02-R0', 2, 104.23), racer('Sen Fira', 3, 110.5), racer('Biddy Blas', 12, 116.59) })
local line = K.gapsLine(ev, g)
T.check(line == 'THE WAR FIELDS 150cc: you 1st 1:42.39; next behind Goli & 02-R0 +1.84 s; winner -; field spread 1st-4th 14.2 s',
  'you 1st: next behind, no winner gap, spread (' .. line .. ')')
T.check(g.place == 1 and g.winner == nil and g.ahead == nil and math.abs(g.behind.gap - 1.84) < 1e-9, 'you 1st: the numbers')

-- you 4th of 6, a DNF bot and a finisher with no time skipped
g = K.gaps({ racer('Biddy Blas', 1, 100), racer('Sen Fira', 2, 101.5), racer('Lyren Shok', 3, 103.6), racer('YOU', 4, 104),
  racer('Shade', 5, 104.8), racer('Ary Quill', 6, 0), racer('Kestar Bool', 7, nil, false), racer('Katja Mox', 8, 109) })
line = K.gapsLine(ev, g)
T.check(line == 'THE WAR FIELDS 150cc: you 4th 1:44.00; winner Biddy Blas -4.00 s; next ahead Lyren Shok -0.40 s; next behind Shade +0.80 s; field spread 1st-6th 9.0 s',
  'you mid-field: winner, next ahead, next behind; DNF and no-time racers skipped (' .. line .. ')')
T.check(g.n == 6, 'six timed racers (the DNF and the 0 time left out)')

-- you 2nd: the car ahead is the winner, named once
line = K.gapsLine(ev, K.gaps({ racer('Biddy Blas', 1, 100), racer('YOU', 2, 101), racer('Shade', 3, 103) }))
T.check(line == 'THE WAR FIELDS 150cc: you 2nd 1:41.00; winner Biddy Blas -1.00 s; next behind Shade +2.00 s; field spread 1st-3rd 3.0 s',
  'you 2nd (' .. line .. ')')
-- you last: nobody behind
line = K.gapsLine(ev, K.gaps({ racer('Biddy Blas', 1, 100), racer('YOU', 2, 101) }))
T.check(line:find('next behind -', 1, true) ~= nil, 'you last: next behind - (' .. line .. ')')
-- you DNF
line = K.gapsLine(ev, K.gaps({ racer('Biddy Blas', 1, 100), racer('Shade', 2, 103), racer('YOU', 5, nil, false) }))
T.check(line == 'THE WAR FIELDS 150cc: you no time (DNF); winner Biddy Blas 1:40.00; field spread 1st-2nd 3.0 s', 'you DNF (' .. line .. ')')
-- no times at all
T.check(K.gaps({ racer('YOU', 3, nil, false) }) == nil and K.gapsLine(ev, nil) == 'THE WAR FIELDS 150cc: no finish times read', 'no times: one short line')

-- through race.lua: 11 bots, bot 11 (Goli) a DNF; you 3rd
M.press('F6'); M.tick(6)
T.clickTitle('150CC'); M.tick(3)
T.clickTitle('JAKKU CUP')
T.check(M.called('LaunchQuickRace') == 1, 'race launched')
W.race(11); M.tick(5)
for i = 1, 10 do W.botFinish(i, i < 3 and i or i + 1, 100 + i) end -- 101, 102 ahead of you; 103... behind
W.botFinish(11, 12, nil, false)
M.tick(25)
local mark = T.mark()
W.finish(3, 102.5); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
local want = '[gaps] THE WAR FIELDS 150cc: you 3rd 1:42.50; winner Biddy Blas -1.50 s; next ahead Kestar Bool -0.50 s; next behind Katja Mox +0.50 s; field spread 1st-11th 9.0 s'
T.check(T.logHas(want, mark), 'the gap line logged after the race, the DNF bot skipped')
local got
for i = mark, #M.log do if M.log[i]:find('[gaps]', 1, true) then got = M.log[i] end end
if not T.logHas(want, mark) then print('  got: ' .. tostring(got)) end
local r1, rg = 0, 0
for i = mark, #M.log do
  if M.log[i]:find('RESULT THE WAR FIELDS', 1, true) then r1 = i end
  if M.log[i]:find('[gaps]', 1, true) then rg = i end
end
T.check(r1 > 0 and rg == r1 + 1, 'right after the RESULT line')
local sv = T.save()
T.check(sv.last.gaps and sv.last.gaps.you == 102.5 and sv.last.gaps.n == 11 and sv.last.gaps.winner.name == 'Biddy Blas'
  and math.abs(sv.last.gaps.behind.gap - 0.5) < 1e-9, 'the last race\'s gaps kept in the save (last.gaps)')
T.finish()
