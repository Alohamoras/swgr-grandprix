-- abil.lua on its own: free pick (one per family) and the old category rule, levels, normalising, paths, AI sets.
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
local cfg = require('config')
local AB = require('abil')
local failed = false
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then failed = true end end
local function names(list) local o = {}; for _, x in ipairs(list) do o[#o + 1] = x.name end; return table.concat(o, ', ') end
local function noAutopilot()
  for i = 1, 4 do for lv = 1, 3 do for _, o in ipairs(AB.choices(i, lv, {})) do
    if o.rel:find('Autopilot') then return false end
  end end end
  return true
end

-- free pick (the default)
check(AB.rule() == 'free', 'the rule is free pick')
check(#AB.slots() == 4, 'four slots')
check(names(AB.choices(1, 1, {})) == 'Ion Bolt, Shockwave, Concussion Mine, Shield, Status Scrubber, Vent, Surge',
  'free, level 1, nothing else picked: one of every family (' .. names(AB.choices(1, 1, {})) .. ')')
local mine = { 'bolt.multi', 'shield.surging', 'vent.flame', 'mine.frozen' }
check(names(AB.choices(2, 2, mine)) == 'Magnetic Shockwave, Vectored Shockwave, Impact Shield, Surging Shield, Auto-Scrubber, Multi-Scrubber, Impact Surge, Overtaking Surge',
  'free: the other slots\' families are left out, this slot\'s own family stays (' .. names(AB.choices(2, 2, mine)) .. ')')
local all4 = AB.normalize({ 'bolt.concuss', 'shockwave.vectored', 'mine.double', 'surge.overtake' }, 3)
check(all4[1] == 'bolt.concuss' and all4[2] == 'shockwave.vectored' and all4[3] == 'mine.double' and all4[4] == 'surge.overtake',
  'free: an all-out attack four is fine (no defence needed)')
local dup = AB.normalize({ 'shield.impact', 'shield.surging', 'surge.impact', 'vent.auto' }, 2)
check(dup[1] == 'shield.impact' and AB.family(dup[2]) ~= 'shield', 'free: a second Shield is replaced (' .. tostring(dup[2]) .. ')')
local fams = {}
for _, p in ipairs(dup) do fams[AB.family(p)] = (fams[AB.family(p)] or 0) + 1 end
local once = true
for _, n in pairs(fams) do if n > 1 then once = false end end
check(once and #dup == 4, 'free: four picks, every family once')
local d = AB.normalize(nil, 1)
check(d[1] == 'bolt.concuss' and d[2] == 'shield.impact' and d[3] == 'surge.impact' and d[4] == 'mine.double', 'no picks -> the defaults')
local old = AB.normalize({ offensive = 'shockwave.magnetic', defensive = 'shield.impact', utility = 'surge.impact', wildcard = 'scrubber.auto' }, 2)
check(old[1] == 'shockwave.magnetic' and old[4] == 'scrubber.auto', 'an old save\'s category picks become the list, kept as they were')
local keep = AB.normalize({ 'bolt.multi', 'shield.surging', 'vent.flame', 'mine.frozen' }, 1)
check(keep[1] == 'bolt.multi' and AB.label(keep[1], 1) == 'Ion Bolt', 'a branch is kept at a lower class (runs as the level-1 ability)')
check(AB.normalize({ 'autopilot.x', 'shield.impact', 'surge.impact', 'vent.auto' }, 1)[1] == 'bolt.concuss', 'an unknown pick -> the default')
check(noAutopilot(), 'no Autopilot offered anywhere (free)')
check(#AB.classPaths(d, 1) == 4, 'four class paths for the build')

-- the old category rule (setting)
cfg.Abilities.Rule = 'categories'
check(AB.slots()[1].name == 'OFFENSIVE' and AB.slots()[4].wildcard, 'categories: the four categories')
check(names(AB.choices(1, 1, {})) == 'Ion Bolt, Shockwave', 'categories: offensive at level 1 (' .. names(AB.choices(1, 1, {})) .. ')')
check(names(AB.choices(1, 2, {})) == 'Concussive Bolt, Multi-Bolt, Magnetic Shockwave, Vectored Shockwave', 'categories: level-2 branches')
check(names(AB.choices(2, 3, {})) == 'Impact Shield II, Surging Shield II', 'categories: defensive = the Shield family')
check(names(AB.choices(3, 2, {})):find('Vent II, Flame Vent', 1, true) ~= nil, 'categories: Vent II offered once')
local wc = AB.choices(4, 1, { 'bolt.concuss', 'shield.impact', 'surge.impact' })
check(names(wc) == 'Concussion Mine, Shockwave, Status Scrubber, Vent', 'categories: wildcard = mines + families not picked (' .. names(wc) .. ')')
local p = AB.normalize({ 'bolt.multi', 'shield.surging', 'vent.flame', 'bolt.concuss' }, 2)
check(p[1] == 'bolt.multi' and p[3] == 'vent.flame' and p[4] == 'mine.double', 'categories: a wildcard clash -> mines')
local bad = AB.normalize({ 'shield.impact', 'shield.impact', 'mine.double', 'vent.auto' }, 1)
check(bad[1] == 'bolt.concuss' and bad[3] == 'surge.impact', 'categories: a family in the wrong category is replaced')
check(noAutopilot(), 'no Autopilot offered anywhere (categories)')
cfg.Abilities.Rule = 'free'

check(AB.rel('mine.double', 2) == 'Mine/BP_Ability_Mine_Double', 'your mines: the player version (no _AI)')
check(AB.rel('mine.double', 2, true) == 'Mine/BP_Ability_Mine_Double_AI', 'the bots\' mines: the _AI version')
check(AB.classPath(AB.rel('bolt.concuss', 3)) == '/Game/Griffin/Gameplay/Abilities/Disruptor/BP_Ability_Disruptor_ConcussV2.BP_Ability_Disruptor_ConcussV2_C', 'class path')
local k = AB.racerPicks('Antagonist')
check(k.offensive == 'bolt.concuss' and k.wildcard == 'shockwave.vectored', 'Kestar\'s four (the AI keeps categories)')
check(#AB.classPaths(k, 2, true) == 4, 'an AI four -> four class paths')
check(AB.racerPicks('Nobody').utility == 'surge.impact', 'an unknown racer gets the defaults')
check(AB.levelFor('ace') == 3 and AB.levelFor('challenger') == 2 and AB.levelFor('riffraff') == 1 and AB.levelFor('nope') == 1, 'league levels 1 / 2 / 3 (an unknown key: 1)')
if failed then os.exit(1) end
