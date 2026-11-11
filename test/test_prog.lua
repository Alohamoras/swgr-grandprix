-- prog.lua on its own: class, Galactic Cup and title race unlocks from the saved best finishes (v0.11).
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
local cfg = require('config')
local P = require('prog')
local failed = false
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then failed = true end end
local function d(best, run) return { best = best or {}, run = run } end
local five = function(v) return { jakku = v, lantaana = v, ando = v, crait = v, sentinel = v } end

local new = d()
check(P.classOpen(new, '50') and P.classOpen(new, '100'), 'a new save: 50cc and 100cc open')
local ok, why = P.classOpen(new, '150')
check(not ok and why == 'A trophy in all 5 planet cups at 100cc (0 / 5)', '150cc locked, says what opens it (' .. tostring(why) .. ')')
check(not P.classOpen(new, '200'), '200cc locked')
local four = d({ ['100'] = { jakku = 1, lantaana = 3, ando = 2, crait = 1, galactic = 1 } })
ok, why = P.classOpen(four, '150')
check(not ok and why:find('(4 / 5)', 1, true), 'four planet cups (the Galactic Cup doesn\'t count) -> still locked (' .. why .. ')')
local bronze = d({ ['100'] = { jakku = 3, lantaana = 3, ando = 3, crait = 3, sentinel = 3 } })
check(P.classOpen(bronze, '150'), 'a trophy (bronze) in all five planet cups at 100cc opens 150cc')
check(not P.classOpen(bronze, '200'), '... but not 200cc')
check(not P.classOpen(d({ ['100'] = five(4) }), '150'), '4th place is no trophy')
cfg.Progression.Unlock = 'gold'
ok, why = P.classOpen(bronze, '150')
check(not ok and why:find('^Gold in all 5'), 'Unlock = gold: bronzes are not enough (' .. why .. ')')
check(P.classOpen(d({ ['100'] = five(1) }), '150'), 'Unlock = gold: five golds open it')
cfg.Progression.Unlock = 'trophy'

-- the Galactic Cup (v0.11): a trophy (any colour) in all five planet cups at that class
ok, why = P.cupOpen(new, '50', 'galactic')
check(not ok and why == 'A trophy in all 5 planet cups at 50cc (0 / 5)', 'Galactic at 50cc locked, says what opens it (' .. tostring(why) .. ')')
check(P.cupOpen(new, '50', 'jakku') and P.cupOpen(new, '100', 'sentinel'), 'planet cups open')
ok, why = P.cupOpen(four, '100', 'galactic')
check(ok, 'kept: the Galactic Cup already raced at 100cc')
ok, why = P.cupOpen(d({ ['100'] = { jakku = 1, lantaana = 3, ando = 2, crait = 1 } }), '100', 'galactic')
check(not ok and why:find('(4 / 5)', 1, true), 'four trophies: still locked (' .. tostring(why) .. ')')
check(P.cupOpen(bronze, '100', 'galactic'), 'five bronzes open the Galactic Cup at that class')
check(not P.cupOpen(bronze, '50', 'galactic'), '... only at that class')
check(not P.cupOpen(d({ ['100'] = five(4) }), '100', 'galactic'), '4th places are no trophies')
cfg.Progression.Unlock = 'gold'
ok, why = P.cupOpen(bronze, '100', 'galactic')
check(not ok and why == 'Gold in all 5 planet cups at 100cc (0 / 5)', 'Unlock = gold: bronzes leave it locked (' .. tostring(why) .. ')')
check(P.cupOpen(d({ ['100'] = five(1) }), '100', 'galactic'), 'Unlock = gold: five golds open it')
cfg.Progression.Unlock = 'trophy'
ok, why = P.cupOpen(new, '200', 'jakku')
check(not ok and why:find('100cc', 1, true) == nil and why:find('150cc', 1, true), 'a cup in a locked class: the class lock is the reason (' .. why .. ')')
ok, why = P.cupOpen(new, '150', 'galactic')
check(not ok and why:find('100cc', 1, true), 'the Galactic Cup in a locked class: the class lock is the reason (' .. why .. ')')
check(P.remixClass == nil and P.remixOpen == nil and P.conditionsOpen == nil, 'v0.11: the remix and conditions rules are gone')

-- kept: what you've already raced stays open (the owner's save, 2026-11-10)
local owner = d({ ['100'] = { jakku = 1, lantaana = 1, galactic = 4 }, ['150'] = { jakku = 1 }, ['200'] = { jakku = 1, lantaana = 1 } },
  { class = '200', cup = 'crait', race = 2, races = 4 })
check(P.classOpen(owner, '150') and P.classOpen(owner, '200'), 'kept: classes you have trophies in stay open')
check(P.cupOpen(owner, '100', 'galactic'), 'kept: Galactic at 100cc (already raced)')
check(not P.cupOpen(owner, '150', 'galactic'), 'not kept: Galactic at 150cc (never raced)')
check(P.classOpen(d({}, { class = '150', cup = 'ando', race = 1, races = 4 }), '150'), 'kept: a class with a cup in progress')

-- what a cup unlocked
local before = P.openSet(d({ ['100'] = { jakku = 1, lantaana = 1, ando = 1, crait = 1 } }))
local after = P.openSet(d({ ['100'] = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 3 } }))
local nw = P.newlyOpen(before, after)
check(table.concat(nw, ', ') == '150cc, GALACTIC CUP at 100cc', 'newly open after the fifth trophy: 150cc and the Galactic Cup (' .. table.concat(nw, ', ') .. ')')
local nt = P.newlyOpen(after, P.openSet(d({ ['100'] = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 3, galactic = 2 } })))
check(table.concat(nt, ', ') == 'TITLE RACE at 100cc', 'a Galactic Cup trophy opens the title race (' .. table.concat(nt, ', ') .. ')')

cfg.Progression.On = false
check(P.classOpen(new, '200') and P.cupOpen(new, '200', 'galactic'), 'On = false: everything open')
cfg.Progression.On = true

-- the title race (v0.8; v0.11: a trophy in the Galactic Cup at the class); a class's own lock comes first; once tried
-- it stays open
do
  local t5 = { jakku = 3, lantaana = 1, ando = 2, crait = 3, sentinel = 1 }
  local ok, why = P.titleOpen(d(), '100')
  check(not ok and why == 'A trophy in the GALACTIC CUP at 100cc', 'title race: locked on a new save, says what opens it (' .. tostring(why) .. ')')
  check(not P.titleOpen(d({ ['100'] = t5 }), '100'), 'title race: five planet trophies are not enough any more')
  local g = { jakku = 3, lantaana = 1, ando = 2, crait = 3, sentinel = 1, galactic = 3 }
  check(P.titleOpen(d({ ['100'] = g }), '100'), 'title race: a Galactic Cup bronze opens it')
  check(not P.titleOpen(d({ ['100'] = g }), '50'), '... only at that class')
  local g4 = { jakku = 3, lantaana = 1, ando = 2, crait = 3, sentinel = 1, galactic = 4 }
  check(not P.titleOpen(d({ ['100'] = g4 }), '100'), 'a 4th place in the Galactic Cup is no trophy')
  cfg.Progression.Unlock = 'gold'
  ok, why = P.titleOpen(d({ ['100'] = g }), '100')
  check(not ok and why == 'Gold in the GALACTIC CUP at 100cc', 'Unlock = gold: the Galactic Cup gold (' .. tostring(why) .. ')')
  cfg.Progression.Unlock = 'trophy'
  ok, why = P.titleOpen(d({ ['100'] = { jakku = 1 } }), '150')
  check(not ok and why:find('150cc', 1, true) == nil and why:find('100cc', 1, true), 'a locked class: its own lock is the reason (' .. tostring(why) .. ')')
  local tried = d({ ['100'] = { jakku = 1 } }); tried.titles = { ['100'] = { tries = 1 } }
  check(P.titleOpen(tried, '100'), 'once tried it stays open')
end
-- v0.10: 200cc is an optional extra - nothing outside 200cc opens from its results (owner, docs/PHILOSOPHY.md)
do
  local base = { ['50'] = five(1), ['100'] = five(1), ['150'] = five(4) }
  local with200 = {}
  for k, v in pairs(base) do with200[k] = v end
  local all200 = five(1); all200.galactic = 1
  with200['200'] = all200
  with200 = d(with200); with200.titles = { ['200'] = { tries = 1, won = true } }
  local a, b = P.openSet(d(base)), P.openSet(with200)
  local diff = {}
  for k in pairs(b) do if not a[k] and not k:find('200cc', 1, true) then diff[#diff + 1] = k end end
  check(#diff == 0, 'golds and the title at 200cc open nothing outside 200cc (' .. table.concat(diff, ', ') .. ')')
  check(not P.titleOpen(with200, '150') and not P.cupOpen(with200, '150', 'galactic'), '... the 150cc Galactic Cup and title race still need the 150cc trophies')
end
if failed then os.exit(1) end
