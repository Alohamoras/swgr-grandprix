-- modsel.lua + mods.lua on their own: the catalogue, slots by class, one per effect, normalising.
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
local MS = require('modsel')
local DATA = require('mods')
local failed = false
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then failed = true end end

check(#DATA.effects == 105 and #MS.groups() == 9, ('105 mods in 9 groups (%d, %d)'):format(#DATA.effects, #MS.groups()))
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
check(MS.effect('Afterburner_FasterRecharge') == nil and MS.effect('Ramjet_MorePower') == nil, 'Improved Regulators / Ramjet Power left out')
local fp = MS.effect('Conditions_FreezeProtection')
check(fp and fp.name == 'Frost Protection' and fp.tag == 'protect', 'Frost Protection kept, tagged protection')
local cs = MS.effect('Afterburner_CooledAfterFullUse')
check(cs and cs.path:find('_v3', 1, true) and cs.desc:find('15s', 1, true), 'top step everywhere (Coolant Cycler III: 15s)')
check(MS.effect('Landing_PerfectBoost') and MS.effect('Landing_PerfectBoost').strong, 'the "check" mods are kept (Repulsormod)')

check(MS.slotsFor('50') == 0 and MS.slotsFor('100') == 2 and MS.slotsFor('150') == 3 and MS.slotsFor('200') == 4, 'slots 0 / 2 / 3 / 4')
local n = MS.normalize({ 'Conditions_FreezeProtection', 'nonsense', 'Conditions_FreezeProtection', 'Cooled_GainWhileSlipstream', 'extra' })
check(n[1] == 'Conditions_FreezeProtection' and n[2] == false and n[3] == false and n[4] == 'Cooled_GainWhileSlipstream' and n[5] == nil,
  'normalise: unknown and repeated mods emptied, four slots')
check(#MS.normalize(nil) == 4 and MS.normalize(nil)[1] == false, 'no mods saved -> four empty slots')
local list = { 'Conditions_FreezeProtection', 'Conditions_BurningProtection', 'Cooled_GainWhileSlipstream', 'Ramjet_NoHeatWhileAirborne' }
check(#MS.active(list, '50') == 0, '50cc: no mods race')
check(table.concat(MS.names(list, '100'), ',') == 'Frost Protection,Burn Protection', '100cc: the first two slots')
check(#MS.paths(list, '200') == 4, '200cc: all four')
local ch = MS.choices('Status protection', list, 1)
local has = {}
for _, e in ipairs(ch) do has[e.key] = true end
check(has.Conditions_FreezeProtection and not has.Conditions_BurningProtection, 'choices: this slot\'s own mod stays, another slot\'s is left out')
check(MS.assetName(fp.path) == 'AFX_Conditions_FreezeProtection', 'asset name from a path')
if failed then os.exit(1) end
