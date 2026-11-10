-- prog.lua on its own: class and bonus-cup unlocks from the saved best finishes.
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
local four = d({ ['100'] = { jakku = 1, lantaana = 3, ando = 2, crait = 1, outerrim = 1 } })
ok, why = P.classOpen(four, '150')
check(not ok and why:find('(4 / 5)', 1, true), 'four planet cups (the bonus cup doesn\'t count) -> still locked (' .. why .. ')')
local bronze = d({ ['100'] = { jakku = 3, lantaana = 3, ando = 3, crait = 3, sentinel = 3 } })
check(P.classOpen(bronze, '150'), 'a trophy (bronze) in all five planet cups at 100cc opens 150cc')
check(not P.classOpen(bronze, '200'), '... but not 200cc')
check(not P.classOpen(d({ ['100'] = five(4) }), '150'), '4th place is no trophy')
cfg.Progression.Unlock = 'gold'
ok, why = P.classOpen(bronze, '150')
check(not ok and why:find('^Gold in all 5'), 'Unlock = gold: bronzes are not enough (' .. why .. ')')
check(P.classOpen(d({ ['100'] = five(1) }), '150'), 'Unlock = gold: five golds open it')
cfg.Progression.Unlock = 'trophy'

-- bonus cups
ok, why = P.cupOpen(new, '50', 'outerrim')
check(not ok and why == 'Gold in all 5 planet cups at 50cc (0 / 5)', 'Outer Rim at 50cc locked (' .. tostring(why) .. ')')
check(P.cupOpen(new, '50', 'jakku'), 'planet cups open')
check(not P.cupOpen(bronze, '100', 'galactic'), 'bronzes don\'t open the bonus cups')
local golds = d({ ['100'] = five(1) })
check(P.cupOpen(golds, '100', 'outerrim') and P.cupOpen(golds, '100', 'galactic'), 'gold in all five opens Outer Rim and Galactic at that class')
check(not P.cupOpen(golds, '150', 'outerrim'), '... only at that class')
ok, why = P.cupOpen(new, '200', 'jakku')
check(not ok and why:find('100cc', 1, true) == nil and why:find('150cc', 1, true), 'a cup in a locked class: the class lock is the reason (' .. why .. ')')

-- kept: what you've already raced stays open (the owner's save, 2026-11-10)
local owner = d({ ['100'] = { jakku = 1, lantaana = 1, outerrim = 1 }, ['150'] = { jakku = 1 }, ['200'] = { jakku = 1, lantaana = 1 } },
  { class = '200', cup = 'crait', race = 2, races = 4 })
check(P.classOpen(owner, '150') and P.classOpen(owner, '200'), 'kept: classes you have trophies in stay open')
check(P.cupOpen(owner, '100', 'outerrim'), 'kept: Outer Rim at 100cc (already won)')
check(not P.cupOpen(owner, '100', 'galactic'), 'not kept: Galactic at 100cc (never raced)')
check(P.classOpen(d({}, { class = '150', cup = 'ando', race = 1, races = 4 }), '150'), 'kept: a class with a cup in progress')

-- what a cup unlocked
local before = P.openSet(d({ ['100'] = { jakku = 1, lantaana = 1, ando = 1, crait = 1 } }))
local after = P.openSet(d({ ['100'] = five(1) }))
local nw = P.newlyOpen(before, after)
check(table.concat(nw, ', ') == '150cc, OUTER RIM CUP at 100cc, GALACTIC CUP at 100cc', 'newly open after the fifth gold (' .. table.concat(nw, ', ') .. ')')

cfg.Progression.On = false
check(P.classOpen(new, '200') and P.cupOpen(new, '200', 'galactic'), 'On = false: everything open')
cfg.Progression.On = true
if failed then os.exit(1) end
