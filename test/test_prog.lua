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
check(table.concat(nw, ', ') == '150cc, OUTER RIM CUP at 100cc, GALACTIC CUP at 100cc, SENTINEL CONDITIONS at 100cc',
  'newly open after the fifth gold (' .. table.concat(nw, ', ') .. ')')

-- remix cups (v0.6.2; owner 2026-11-10: from Progression.RemixClass = 150cc, the summit gates nothing): a trophy in
-- every planet cup at 150cc, then open at every open class
check(P.remixClass().key == '150', 'RemixClass is 150cc')
ok, why = P.cupOpen(d({ ['100'] = five(1) }), '100', 'jakku_remix')
check(not ok and why == 'A trophy in all 5 planet cups at 150cc (0 / 5)', 'remix locked until 150cc is done (' .. tostring(why) .. ')')
local top = d({ ['100'] = five(1), ['150'] = five(3) })
check(P.cupOpen(top, '150', 'sentinel_remix') and P.cupOpen(top, '100', 'jakku_remix') and P.cupOpen(top, '50', 'crait_remix')
  and P.cupOpen(top, '200', 'ando_remix'), 'a trophy in all five at 150cc opens the remix cups at every class (200cc opens with them)')
cfg.Progression.Unlock = 'gold'
ok, why = P.cupOpen(top, '150', 'jakku_remix')
check(not ok and why == 'Gold in all 5 planet cups at 150cc (0 / 5)', 'Unlock = gold: five 150cc bronzes leave the remix cups locked (' .. tostring(why) .. ')')
cfg.Progression.Unlock = 'trophy'
check(not P.remixOpen(d({ ['100'] = five(1), ['150'] = { jakku = 1, lantaana = 1, ando = 1, crait = 1 }, ['200'] = five(1) })),
  '200cc gates nothing: five 200cc golds without the fifth 150cc trophy leave the remix cups locked')
check(P.cupOpen(d({ ['100'] = { jakku_remix = 2 } }), '100', 'jakku_remix'), 'kept: a remix cup already raced')
local nb = P.newlyOpen(P.openSet(d({ ['100'] = five(1), ['150'] = { jakku = 1, lantaana = 1, ando = 1, crait = 1 } })),
  P.openSet(d({ ['100'] = five(1), ['150'] = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 3 } })))
check(table.concat(nb, ', ') == '200cc, REMIX CUPS', 'the fifth 150cc trophy says 200cc and REMIX CUPS once (' .. table.concat(nb, ', ') .. ')')
check(select(2, P.classOpen(new, '150')) == 'A trophy in all 5 planet cups at 100cc (0 / 5)', 'remix and conditions cups don\'t count as planet cups')
cfg.Progression.RemixClass = nil
check(P.remixClass().key == '150', 'RemixClass unset: the class before the top one')
cfg.Progression.RemixClass = '200'
check(select(2, P.remixOpen(new)) == 'A trophy in all 5 planet cups at 200cc (0 / 5)', 'RemixClass = 200: the old rule')
cfg.Progression.RemixClass = '150'

-- conditions cups: gold in that planet's cup at that class, per cup and per class
ok, why = P.cupOpen(new, '50', 'jakku_cond')
check(not ok and why == 'Gold in the JAKKU CUP at 50cc', 'Jakku Conditions locked, says what opens it (' .. tostring(why) .. ')')
local jg = d({ ['50'] = { jakku = 1, lantaana = 2 } })
check(P.cupOpen(jg, '50', 'jakku_cond'), 'gold in the Jakku Cup at 50cc opens Jakku Conditions at 50cc')
check(not P.cupOpen(jg, '50', 'lantaana_cond'), 'silver in the Lantaana Cup does not open Lantaana Conditions')
check(not P.cupOpen(jg, '100', 'jakku_cond'), '... only at that class')
check(P.cupOpen(d({ ['100'] = { ando_cond = 4 } }), '100', 'ando_cond'), 'kept: a conditions cup already raced')
local s = P.openSet(jg)
check(s['JAKKU CONDITIONS at 50cc'] and not s['LANTAANA CONDITIONS at 50cc'] and not s['JAKKU CONDITIONS at 100cc'], 'openSet lists the open conditions cups per class')
local nc = P.newlyOpen(P.openSet(d({ ['100'] = { jakku = 2 } })), P.openSet(d({ ['100'] = { jakku = 1 } })))
check(table.concat(nc, ', ') == 'JAKKU CONDITIONS at 100cc', 'a planet gold says which conditions cup it opened (' .. table.concat(nc, ', ') .. ')')
ok, why = P.cupOpen(new, '150', 'crait_cond')
check(not ok and why:find('100cc', 1, true), 'a conditions cup in a locked class: the class lock is the reason (' .. why .. ')')

cfg.Progression.On = false
check(P.classOpen(new, '200') and P.cupOpen(new, '200', 'galactic'), 'On = false: everything open')
cfg.Progression.On = true

-- v0.8: the title race opens with a trophy in every planet cup at the class; a class's own lock comes first; once
-- tried it stays open
cfg.Progression.On = true
do
  local t5 = { jakku = 3, lantaana = 1, ando = 2, crait = 3, sentinel = 1 }
  local ok, why = P.titleOpen(d(), '100')
  check(not ok and why == 'A trophy in all 5 planet cups at 100cc (0 / 5)', 'title race: locked on a new save (' .. tostring(why) .. ')')
  check(P.titleOpen(d({ ['100'] = t5 }), '100'), 'title race: five trophies open it')
  ok, why = P.titleOpen(d({ ['100'] = { jakku = 1 } }), '150')
  check(not ok and why:find('150cc', 1, true) == nil and why:find('100cc', 1, true), 'a locked class: its own lock is the reason (' .. tostring(why) .. ')')
  local tried = d({ ['100'] = { jakku = 1 } }); tried.titles = { ['100'] = { tries = 1 } }
  check(P.titleOpen(tried, '100'), 'once tried it stays open')
end
if failed then os.exit(1) end
