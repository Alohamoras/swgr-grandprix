-- modsel.lua + mods.lua + config TuneUps on their own: the catalogue, the twelve tune-up packages, slots by class,
-- cycling a slot, normalising a save, the AI tiers' lists and the launch build's slot budget.
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
local logged = {}
require('core').log = function(m) logged[#logged + 1] = tostring(m) end -- (no grandprix.log on disk from this test)
local MS = require('modsel')
local DATA = require('mods')
local cfg = require('config')
local failed = false
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then failed = true end end

-- the catalogue (generated; unchanged)
check(#DATA.effects == 105, ('105 mods in the catalogue (%d)'):format(#DATA.effects))
local power, pod, top, paths = 0, 0, true, true
for _, e in ipairs(DATA.effects) do
  if e.tag ~= 'protect' and e.tag ~= 'style' then power = power + 1 end
  if e.path:find('PlaneTrait', 1, true) then pod = pod + 1 end
  if e.desc:find('{', 1, true) then top = false end
  if not e.path:match('^/Game/Griffin/Vehicles/Common/Upgrades/Affixes/AFX_[%w_]+%.AFX_[%w_]+$') then paths = false end
end
check(power == 0 and pod == 0, 'no pure-power or podracer mods (owner)')
check(top, 'every description has its numbers filled in')
check(paths, 'every mod has a full object path')
check(MS.catalogue('Conditions_FreezeProtection') and MS.catalogue('Conditions_FreezeProtection').tag == 'protect', 'catalogue lookup by key')

-- the packages
local all = MS.all()
check(#all == 12, ('twelve tune-ups (%d)'):format(#all))
local keys, bad = {}, {}
local usedAffix = {}
for _, p in ipairs(all) do
  keys[#keys + 1] = p.key
  if #p.missing > 0 then bad[#bad + 1] = p.key .. ' unknown ' .. table.concat(p.missing, ',') end
  if #p.affixes < 1 or #p.affixes > 3 then bad[#bad + 1] = p.key .. ' has ' .. #p.affixes .. ' affixes' end
  if #p.line > 60 or #p.line == 0 then bad[#bad + 1] = p.key .. ' line ' .. #p.line .. ' chars' end
  if p.name ~= p.name:upper() then bad[#bad + 1] = p.key .. ' name not upper case' end
  if not MS.effect(p.key) or MS.effect(p.key) ~= p then bad[#bad + 1] = p.key .. ' not found by key' end
  for _, e in ipairs(p.affixes) do
    if e.strong then bad[#bad + 1] = p.key .. ' bundles a "check" mod ' .. e.key end
    if e.tag ~= 'protect' and e.tag ~= 'style' then bad[#bad + 1] = p.key .. ' bundles a power mod ' .. e.key end
    if usedAffix[e.key] then bad[#bad + 1] = e.key .. ' in two packages' end
    usedAffix[e.key] = true
  end
  if #p.paths ~= #p.affixes then bad[#bad + 1] = p.key .. ' paths' end
  if p.desc ~= p.line then bad[#bad + 1] = p.key .. ' desc ~= line' end
end
check(#bad == 0, 'every package: 1-3 real catalogue affixes, none "check", none twice, line <= 60 (' .. table.concat(bad, '; ') .. ')')
check(table.concat(keys, ',') == 'heat_shield,armour,ice_cold,redliner,ramjet_rider,afterburner,brawler,survivor,slipstreamer,firebug,engineer,tenacious',
  'the twelve in config order (' .. table.concat(keys, ',') .. ')')
local hs = MS.effect('heat_shield')
check(hs.name == 'HEAT SHIELD' and hs.tag == 'protect' and hs.group == 'Status protection', 'HEAT SHIELD: a protection package in the Status protection group')
check(hs.paths[1]:find('AFX_Conditions_BurningProtection', 1, true) and hs.paths[2]:find('AFX_Conditions_FreezeProtection', 1, true), 'HEAT SHIELD = Burn + Frost Protection paths')
check(MS.effect('slipstreamer').tag == 'style' and MS.effect('afterburner').tag == 'style', 'playstyle packages tagged style')
check(MS.line('heat_shield') == 'Immune to Burning and Frozen' and MS.line('nonsense') == '' and MS.line(nil) == '', 'MS.line: the tile line, empty for unknown')
check(MS.effect('Conditions_FreezeProtection') == nil, 'a catalogue key is not a package')
check(#MS.groups() >= 5 and #MS.choices('Ramjet', nil, 0) == 2 and MS.count('Ramjet') == 2, 'groups and choices still work on the packages (REDLINER + RAMJET RIDER in Ramjet)')

-- slots by class (min of MS.MAX and config)
check(MS.MAX == 2, 'two slots at most')
check(MS.slotsFor('riffraff') == 0 and MS.slotsFor('challenger') == 1 and MS.slotsFor('ace') == 2 and MS.slotsFor('x') == 0,
  ('slots 0 / %d / %d (v0.26: Riff-Raff, Challenger, Ace)'):format(MS.slotsFor('challenger'), MS.slotsFor('ace')))

-- normalise
local n = MS.normalize({ 'heat_shield', 'Conditions_FreezeProtection', 'armour' })
check(n[1] == 'heat_shield' and n[2] == false and n[3] == nil, 'normalise: an old catalogue key dropped, two slots')
check(logged[#logged] == '[tune-ups] dropped from the save (not tune-ups): Conditions_FreezeProtection', 'the dropped key logged (' .. tostring(logged[#logged]) .. ')')
n = MS.normalize({ 'armour', 'armour' })
check(n[1] == 'armour' and n[2] == false, 'normalise: a repeat emptied')
check(#MS.normalize(nil) == 2 and MS.normalize(nil)[1] == false and MS.normalize('x')[2] == false, 'nothing saved -> two empty slots')
n = MS.normalize({ false, 'redliner' })
check(n[1] == false and n[2] == 'redliner', 'an empty first slot stays empty')

-- cycle: empty -> first package -> ... -> last -> empty; packages in the other slot skipped; backwards wraps
local list = { false, false }
local seq = {}
local v = false
for _ = 1, 13 do v = MS.cycle({ v, false }, 1, 1); seq[#seq + 1] = tostring(v) end
check(seq[1] == 'heat_shield' and seq[12] == 'tenacious' and seq[13] == 'false', 'cycle forward: the twelve then empty (' .. table.concat(seq, ',') .. ')')
check(MS.cycle({ false, false }, 1, -1) == 'tenacious' and MS.cycle({ 'heat_shield', false }, 1, -1) == false, 'cycle back wraps to the last, then to empty')
check(MS.cycle({ false, 'heat_shield' }, 1, 1) == 'armour', 'cycle skips the package in the other slot')
check(MS.cycle({ 'armour', 'heat_shield' }, 1, -1) == false and MS.cycle({ 'tenacious', 'heat_shield' }, 1, 1) == false, 'skipping at both ends')
check(MS.cycle({ 'heat_shield', 'tenacious' }, 2, 1) == false and MS.cycle({ 'heat_shield', false }, 2, -1) == 'tenacious', 'slot 2 the same')
check(MS.cycle(nil, 1, 1) == 'heat_shield' and MS.cycle({}, 2) == 'heat_shield', 'no list / no dir: the first package')
-- a round trip never repeats a package or the other slot's
local seen, dup = {}, false
v = false
for _ = 1, 12 do v = MS.cycle({ 'firebug', v }, 2, 1); if v then if seen[v] or v == 'firebug' then dup = true end; seen[v] = true end end
check(not dup and seen.heat_shield and seen.tenacious and not seen.firebug, 'a full turn: eleven packages once each, never the other slot\'s')

-- what races with you
list = { 'heat_shield', 'slipstreamer' }
check(#MS.active(list, 'riffraff') == 0 and #MS.paths(list, 'riffraff') == 0, 'Riff-Raff: nothing races')
check(table.concat(MS.names(list, 'challenger'), ',') == 'HEAT SHIELD', 'Challenger: the first slot')
check(table.concat(MS.names(list, 'ace'), ',') == 'HEAT SHIELD,SLIPSTREAMER' and table.concat(MS.fitted(list, 'ace'), ',') == 'heat_shield,slipstreamer', 'Ace: both')
local p4 = MS.paths(list, 'ace')
check(#p4 == 4 and p4[1]:find('BurningProtection', 1, true) and p4[4]:find('Cooled_GainWhileSlipstream', 1, true), 'Ace: four affix paths, in package order')
check(#MS.paths({ 'heat_shield', 'nonsense' }, 'ace') == 2 and #MS.paths({ 'Conditions_FreezeProtection', false }, 'ace') == 0, 'unknown keys skipped by paths()')
check(MS.assetName(p4[1]) == 'AFX_Conditions_BurningProtection', 'asset name from a path')
local set = MS.assetNames({ 'heat_shield' })
check(set.AFX_Conditions_BurningProtection and set.AFX_Conditions_FreezeProtection and not set.AFX_Shielded_GainOnRaceStart, 'asset-name set of packages')
check(MS.label({ 'heat_shield', 'armour' }) == 'HEAT SHIELD+ARMOUR' and MS.label({}) == 'none', 'label for the log')
check(#MS.pathsOf({ 'heat_shield', 'heat_shield' }) == 2, 'pathsOf: each path once')

-- the AI tiers (config TuneUps.AI) resolve to packages; the launch build never needs more than its 10 affix slots
local T = cfg.TuneUps
check(T.AI['challenger'].Elite[1] == 'heat_shield' and #T.AI['ace'].Elite == 2 and T.AI['ace'].Challenger[1] == 'heat_shield' and T.AI['riffraff'] == nil,
  'AI: Elite heat shield from Challenger, + armour at Ace, the Challenger tier heat shield at Ace, none at Riff-Raff')
local aiBad = {}
for class, tiers in pairs(T.AI) do
  for tier, pk in pairs(tiers) do
    if not T.Tiers[tier] then aiBad[#aiBad + 1] = class .. ' ' .. tier .. ' has no racers' end
    for _, k in ipairs(pk) do if not MS.effect(k) then aiBad[#aiBad + 1] = class .. ' ' .. tier .. ' unknown ' .. k end end
  end
end
check(#aiBad == 0, 'every AI tier names real packages and racers (' .. table.concat(aiBad, '; ') .. ')')
check(#T.Tiers.Elite == 3 and T.Tiers.Challenger[1] == 'Ghost', 'tiers: Elite = Thrall, Rager, Star (Sen Fira, Biddy Blas, Lyren Shok); Challenger = Ghost (Goli & 02-R0)')
local racers = cfg.Abilities.Racers
local known = true
for _, ks in pairs(T.Tiers) do for _, k in ipairs(ks) do if not racers[k] then known = false end end end
check(known, 'every tier racer is an Abilities.Racers key')
local sizes = {}
for _, p in ipairs(all) do sizes[#sizes + 1] = #p.affixes end
table.sort(sizes, function(a, b) return a > b end)
local worst = 0
for class, tiers in pairs(T.AI) do
  local union = {}
  for _, pk in pairs(tiers) do for _, k in ipairs(pk) do union[k] = true end end
  local u = {}
  for k in pairs(union) do u[#u + 1] = k end
  local n = #MS.pathsOf(u)
  for i = 1, MS.slotsFor(class) do n = n + (sizes[i] or 0) end
  if n > worst then worst = n end
end
check(worst <= 10 and MS.MAX * sizes[1] <= 8, ('launch build: at most %d affixes (yours + the AI\'s), your fitted ones at most %d (limit 10 / 8)'):format(worst, MS.MAX * sizes[1]))
if failed then os.exit(1) end
