-- prog.lua on its own: league, Galactic Cup and title race unlocks from the saved best finishes (v0.11; v0.26: the
-- three leagues - Riff-Raff open, Challenger from Riff-Raff, Ace from Challenger, as 150cc opened from 100cc).
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
local cfg = require('config')
local P = require('prog')
local failed = false
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then failed = true end end
local function d(best, run) return { best = best or {}, run = run } end
local five = function(v) return { jakku = v, lantaana = v, ando = v, crait = v, sentinel = v } end

local new = d()
check(P.classOpen(new, 'riffraff'), 'a new save: Riff-Raff open')
local ok, why, short = P.classOpen(new, 'challenger')
check(not ok and why == 'A trophy in all 5 planet cups at RIFF-RAFF (0 / 5)', 'Challenger locked, says what opens it (' .. tostring(why) .. ')')
check(short == '5 trophies at RIFF-RAFF', 'the short form for the tile (' .. tostring(short) .. ')')
ok, why = P.classOpen(new, 'ace')
check(not ok and why == 'A trophy in all 5 planet cups at CHALLENGER (0 / 5)', 'Ace locked: opens from Challenger (' .. tostring(why) .. ')')
local four = d({ riffraff = { jakku = 1, lantaana = 3, ando = 2, crait = 1, galactic = 1 } })
ok, why = P.classOpen(four, 'challenger')
check(not ok and why:find('(4 / 5)', 1, true), 'four planet cups (the Galactic Cup doesn\'t count) -> still locked (' .. why .. ')')
local bronze = d({ riffraff = five(3) })
check(P.classOpen(bronze, 'challenger'), 'a trophy (bronze) in all five planet cups at Riff-Raff opens Challenger')
check(not P.classOpen(bronze, 'ace'), '... but not Ace')
check(P.classOpen(d({ riffraff = five(3), challenger = five(2) }), 'ace'), 'a trophy in all five planet cups at Challenger opens Ace')
check(not P.classOpen(d({ riffraff = five(4) }), 'challenger'), '4th place is no trophy')
cfg.Progression.Unlock = 'gold'
ok, why = P.classOpen(bronze, 'challenger')
check(not ok and why:find('^Gold in all 5'), 'Unlock = gold: bronzes are not enough (' .. why .. ')')
check(P.classOpen(d({ riffraff = five(1) }), 'challenger'), 'Unlock = gold: five golds open it')
cfg.Progression.Unlock = 'trophy'

-- the Galactic Cup (v0.11): a trophy (any colour) in all five planet cups at that league
ok, why = P.cupOpen(new, 'riffraff', 'galactic')
check(not ok and why == 'A trophy in all 5 planet cups at RIFF-RAFF (0 / 5)', 'Galactic at Riff-Raff locked, says what opens it (' .. tostring(why) .. ')')
check(P.cupOpen(new, 'riffraff', 'jakku') and P.cupOpen(new, 'riffraff', 'sentinel'), 'planet cups open')
ok, why = P.cupOpen(four, 'riffraff', 'galactic')
check(ok, 'kept: the Galactic Cup already raced at Riff-Raff')
ok, why = P.cupOpen(d({ riffraff = { jakku = 1, lantaana = 3, ando = 2, crait = 1 } }), 'riffraff', 'galactic')
check(not ok and why:find('(4 / 5)', 1, true), 'four trophies: still locked (' .. tostring(why) .. ')')
check(P.cupOpen(bronze, 'riffraff', 'galactic'), 'five bronzes open the Galactic Cup at that league')
check(not P.cupOpen(bronze, 'challenger', 'galactic'), '... only at that league')
check(not P.cupOpen(d({ riffraff = five(4) }), 'riffraff', 'galactic'), '4th places are no trophies')
cfg.Progression.Unlock = 'gold'
ok, why = P.cupOpen(bronze, 'riffraff', 'galactic')
check(not ok and why == 'Gold in all 5 planet cups at RIFF-RAFF (0 / 5)', 'Unlock = gold: bronzes leave it locked (' .. tostring(why) .. ')')
check(P.cupOpen(d({ riffraff = five(1) }), 'riffraff', 'galactic'), 'Unlock = gold: five golds open it')
cfg.Progression.Unlock = 'trophy'
ok, why = P.cupOpen(new, 'ace', 'jakku')
check(not ok and why:find('CHALLENGER', 1, true), 'a cup in a locked league: the league lock is the reason (' .. why .. ')')
ok, why = P.cupOpen(new, 'challenger', 'galactic')
check(not ok and why:find('RIFF-RAFF', 1, true), 'the Galactic Cup in a locked league: the league lock is the reason (' .. why .. ')')
check(P.remixClass == nil and P.remixOpen == nil and P.conditionsOpen == nil, 'v0.11: the remix and conditions rules are gone')

-- kept: what you've already raced stays open
local raced = d({ riffraff = { jakku = 1, lantaana = 1, galactic = 4 }, challenger = { jakku = 1 }, ace = { jakku = 1, lantaana = 1 } },
  { class = 'ace', cup = 'crait', race = 2, races = 4 })
check(P.classOpen(raced, 'challenger') and P.classOpen(raced, 'ace'), 'kept: leagues you have results in stay open')
check(P.cupOpen(raced, 'riffraff', 'galactic'), 'kept: Galactic at Riff-Raff (already raced)')
check(not P.cupOpen(raced, 'challenger', 'galactic'), 'not kept: Galactic at Challenger (never raced)')
check(P.classOpen(d({}, { class = 'challenger', cup = 'ando', race = 1, races = 4 }), 'challenger'), 'kept: a league with a cup in progress')

-- what a cup unlocked
local before = P.openSet(d({ riffraff = { jakku = 1, lantaana = 1, ando = 1, crait = 1 } }))
local after = P.openSet(d({ riffraff = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 3 } }))
local nw = P.newlyOpen(before, after)
check(table.concat(nw, ', ') == 'CHALLENGER, GALACTIC CUP at RIFF-RAFF', 'newly open after the fifth trophy: Challenger and the Galactic Cup (' .. table.concat(nw, ', ') .. ')')
local nt = P.newlyOpen(after, P.openSet(d({ riffraff = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 3, galactic = 2 } })))
check(table.concat(nt, ', ') == 'TITLE RACE at RIFF-RAFF', 'a Galactic Cup trophy opens the title race (' .. table.concat(nt, ', ') .. ')')
local na = P.newlyOpen(P.openSet(d({ riffraff = five(1), challenger = { jakku = 1, lantaana = 1, ando = 1, crait = 1 } })),
  P.openSet(d({ riffraff = five(1), challenger = five(1) })))
check(table.concat(na, ', ') == 'ACE, GALACTIC CUP at CHALLENGER', 'the fifth Challenger trophy opens Ace and its Galactic Cup (' .. table.concat(na, ', ') .. ')')

cfg.Progression.On = false
check(P.classOpen(new, 'ace') and P.cupOpen(new, 'ace', 'galactic'), 'On = false: everything open')
cfg.Progression.On = true

-- the title race (v0.8; v0.11: a trophy in the Galactic Cup at the league); a league's own lock comes first; once
-- tried it stays open
do
  local t5 = { jakku = 3, lantaana = 1, ando = 2, crait = 3, sentinel = 1 }
  local ok, why = P.titleOpen(d(), 'riffraff')
  check(not ok and why == 'A trophy in the GALACTIC CUP at RIFF-RAFF', 'title race: locked on a new save, says what opens it (' .. tostring(why) .. ')')
  check(not P.titleOpen(d({ riffraff = t5 }), 'riffraff'), 'title race: five planet trophies are not enough')
  local g = { jakku = 3, lantaana = 1, ando = 2, crait = 3, sentinel = 1, galactic = 3 }
  check(P.titleOpen(d({ riffraff = g }), 'riffraff'), 'title race: a Galactic Cup bronze opens it')
  check(not P.titleOpen(d({ riffraff = g }), 'challenger'), '... only at that league')
  local g4 = { jakku = 3, lantaana = 1, ando = 2, crait = 3, sentinel = 1, galactic = 4 }
  check(not P.titleOpen(d({ riffraff = g4 }), 'riffraff'), 'a 4th place in the Galactic Cup is no trophy')
  cfg.Progression.Unlock = 'gold'
  ok, why = P.titleOpen(d({ riffraff = g }), 'riffraff')
  check(not ok and why == 'Gold in the GALACTIC CUP at RIFF-RAFF', 'Unlock = gold: the Galactic Cup gold (' .. tostring(why) .. ')')
  cfg.Progression.Unlock = 'trophy'
  ok, why = P.titleOpen(d({ riffraff = { jakku = 1 } }), 'challenger')
  check(not ok and why:find('RIFF-RAFF', 1, true), 'a locked league: its own lock is the reason (' .. tostring(why) .. ')')
  local tried = d({ riffraff = { jakku = 1 } }); tried.titles = { riffraff = { tries = 1 } }
  check(P.titleOpen(tried, 'riffraff'), 'once tried it stays open')
end
-- v0.26: Ace is the top of the ladder - nothing outside Ace opens from its results (Kestar follows its title: title.lua)
do
  local base = { riffraff = five(1), challenger = five(4) }
  local withAce = {}
  for k, v in pairs(base) do withAce[k] = v end
  local allAce = five(1); allAce.galactic = 1
  withAce.ace = allAce
  withAce = d(withAce); withAce.titles = { ace = { tries = 1, won = true } }
  local a, b = P.openSet(d(base)), P.openSet(withAce)
  local diff = {}
  for k in pairs(b) do if not a[k] and not k:find('ACE', 1, true) then diff[#diff + 1] = k end end
  check(#diff == 0, 'golds and the title at Ace open nothing outside Ace (' .. table.concat(diff, ', ') .. ')')
  check(not P.titleOpen(withAce, 'challenger') and not P.cupOpen(withAce, 'challenger', 'galactic'), '... the Challenger Galactic Cup and title race still need the Challenger trophies')
end
-- the nearest unlock (v0.20): league names, no cc
do
  local nu = P.nextUnlock(d({ riffraff = { jakku = 1, lantaana = 1, ando = 1 } }), 'riffraff')
  check(nu and nu.text == '2 more trophies at RIFF-RAFF open the GALACTIC CUP and CHALLENGER', 'nextUnlock: ' .. tostring(nu and nu.text))
end
if failed then os.exit(1) end
