-- abil.lua on its own: options per category and level, the wildcard rule, normalising picks, paths, AI sets.
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
local AB = require('abil')
local failed = false
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then failed = true end end
local function names(list) local o = {}; for _, x in ipairs(list) do o[#o + 1] = x.name end; return table.concat(o, ', ') end

check(names(AB.options('offensive', 1)) == 'Ion Bolt, Shockwave', 'offensive at level 1: one per family (' .. names(AB.options('offensive', 1)) .. ')')
check(names(AB.options('offensive', 2)) == 'Concussive Bolt, Multi-Bolt, Magnetic Shockwave, Vectored Shockwave',
  'offensive at level 2: the branches (' .. names(AB.options('offensive', 2)) .. ')')
check(names(AB.options('defensive', 3)) == 'Impact Shield II, Surging Shield II', 'defensive = the Shield family')
check(names(AB.options('utility', 2)):find('Vent II, Flame Vent', 1, true) ~= nil, 'vent at level 2: Vent II once (two branches share it), Flame Vent')
local wc = AB.options('wildcard', 1, { offensive = 'bolt.concuss', defensive = 'shield.impact', utility = 'surge.impact' })
check(names(wc) == 'Concussion Mine, Shockwave, Status Scrubber, Vent', 'wildcard: mines + families not picked (' .. names(wc) .. ')')
for _, cat in ipairs({ 'offensive', 'defensive', 'utility', 'wildcard' }) do
  for lv = 1, 3 do
    for _, o in ipairs(AB.options(cat, lv)) do
      if o.rel:find('Autopilot') then check(false, 'Autopilot offered') end
    end
  end
end
check(true, 'no Autopilot offered anywhere')

check(AB.rel('mine.double', 2) == 'Mine/BP_Ability_Mine_Double', 'your mines: the player version (no _AI)')
check(AB.rel('mine.double', 2, true) == 'Mine/BP_Ability_Mine_Double_AI', 'the bots\' mines: the _AI version')
check(AB.classPath(AB.rel('bolt.concuss', 3)) == '/Game/Griffin/Gameplay/Abilities/Disruptor/BP_Ability_Disruptor_ConcussV2.BP_Ability_Disruptor_ConcussV2_C', 'class path')

local p = AB.normalize({ offensive = 'bolt.multi', defensive = 'shield.surging', utility = 'vent.flame', wildcard = 'bolt.concuss' }, 2)
check(p.offensive == 'bolt.multi' and p.utility == 'vent.flame', 'valid picks kept')
check(p.wildcard == 'mine.double', 'wildcard = a family already picked -> back to the default (mines)')
local d = AB.normalize(nil, 1)
check(d.offensive == 'bolt.concuss' and d.defensive == 'shield.impact' and d.utility == 'surge.impact' and d.wildcard == 'mine.double', 'no picks -> the defaults')
local bad = AB.normalize({ offensive = 'shield.impact', utility = 'mine.double' }, 1)
check(bad.offensive == 'bolt.concuss' and bad.utility == 'surge.impact', 'a family in the wrong category is replaced')
check(#AB.classPaths(d, 1) == 4, 'four class paths for the build')

local k = AB.racerPicks('Antagonist')
check(k.offensive == 'bolt.concuss' and k.wildcard == 'shockwave.vectored', 'Kestar\'s four')
check(AB.racerPicks('Nobody').utility == 'surge.impact', 'an unknown racer gets the defaults')
check(AB.levelFor('150') == 3 and AB.levelFor('50') == 1, 'class levels 1 / 3')
if failed then os.exit(1) end
