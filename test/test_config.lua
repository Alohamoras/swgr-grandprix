-- config.lua and gp.lua's read helpers on their own: the classes (parts 0 / 3 / 7 / 10, mods 0 / 1 / 2 / 2), the
-- 17 cups in order, every race's laps and planet, the Planets table, planetOf / raceLine / cupPlanets.
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
-- gp.lua only needs core's log at load time
package.loaded.core = { log = function() end, DIR = '.', serialize = tostring, ordinal = tostring }
local cfg = require('config')
local K = require('gp')
local failed = false
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then failed = true end end
local function keys(list, field) local out = {}; for _, x in ipairs(list) do out[#out + 1] = x[field or 'key'] end; return table.concat(out, ',') end

-- classes
check(keys(cfg.Classes) == '50,100,150,200', 'class keys unchanged (used in the save)')
check(keys(cfg.Classes, 'parts') == '0,3,7,10', 'parts 0 / 3 / 7 / 10 (' .. keys(cfg.Classes, 'parts') .. ')')
check(keys(cfg.Classes, 'mods') == '0,1,2,2', 'mod slots 0 / 1 / 2 / 2 (' .. keys(cfg.Classes, 'mods') .. ')')
check(keys(cfg.Classes, 'abilities') == '1,1,2,3', 'ability levels 1 / 1 / 2 / 3')
local blurbs = true
for _, c in ipairs(cfg.Classes) do blurbs = blurbs and type(c.blurb) == 'string' and #c.blurb > 10 and not c.blurb:find('\n') end
check(blurbs, 'every class has a one-line intro')
check(cfg.Progression.RemixClass == '150', 'Progression.RemixClass = 150')

-- cups: 5 planet, 2 bonus, 5 remix, 5 conditions
check(#cfg.Cups == 17, '17 cups (' .. #cfg.Cups .. ')')
check(keys(cfg.Cups) == 'jakku,lantaana,ando,crait,sentinel,outerrim,galactic,jakku_remix,lantaana_remix,ando_remix,crait_remix,sentinel_remix,'
  .. 'jakku_cond,lantaana_cond,ando_cond,crait_cond,sentinel_cond', 'cup order: planet, bonus, remix, conditions (' .. keys(cfg.Cups) .. ')')
local KINDS = { Circuit = true, Sprint = true, ['Short circuit'] = true }
local fourEach, lapsOk, sprintsOk, planetsOk, condUnique = true, true, true, true, true
local seen, condPaths = {}, {}
for _, cup in ipairs(cfg.Cups) do
  fourEach = fourEach and #cup.races == 4
  for _, r in ipairs(cup.races) do
    lapsOk = lapsOk and math.type(r.laps) == 'integer' and r.laps >= 1 and r.laps <= 8 and KINDS[r.kind] == true
    sprintsOk = sprintsOk and ((r.kind == 'Sprint') == (r.laps == 1))
    planetsOk = planetsOk and K.planetOf(r.path) ~= nil
    if cup.conditions then condPaths[#condPaths + 1] = r.path end
    seen[r.path] = (seen[r.path] or 0) + 1
  end
end
for _, p in ipairs(condPaths) do condUnique = condUnique and seen[p] == 1 end
check(fourEach, 'four races in every cup')
check(lapsOk, 'every race has a lap count (1-8) and a known kind')
check(sprintsOk, 'sprints are the one-lap races and nothing else is')
check(planetsOk, 'every race path names a known planet')
check(condUnique, 'the conditions cups use events no other cup uses')
local condOk = true
for _, cup in ipairs(cfg.Cups) do
  if cup.conditions then
    local planet = K.cup(cup.planet)
    condOk = condOk and planet ~= nil and not (planet.bonus or planet.remix or planet.conditions) and cup.key == cup.planet .. '_cond'
      and cup.name == planet.name:gsub(' CUP$', ' CONDITIONS')
    for _, r in ipairs(cup.races) do condOk = condOk and K.planetOf(r.path).key == cup.planet end
  end
end
check(condOk, 'every conditions cup names its planet cup, and all four of its races are on that planet')
local flags = 0
for _, cup in ipairs(cfg.Cups) do if (cup.bonus and 1 or 0) + (cup.remix and 1 or 0) + (cup.conditions and 1 or 0) > 1 then flags = flags + 1 end end
check(flags == 0, 'a cup is planet, bonus, remix or conditions, never two of those')

-- planets
check(keys({ cfg.Planets.Mastiff, cfg.Planets.Dalmatian, cfg.Planets.Corgi, cfg.Planets.Spaniel, cfg.Planets.Husky, cfg.Planets.Whippet })
  == 'jakku,lantaana,ando,crait,sentinel,derven', 'six planets by codename, keyed like the planet cups')
check(cfg.Planets.Corgi.name == 'Ando Prime' and cfg.Planets.Husky.name == 'Sentinel I' and cfg.Planets.Whippet.name == 'Derven Acos', 'the game\'s planet names')
local lines = true
for _, p in pairs(cfg.Planets) do lines = lines and type(p.line) == 'string' and #p.line > 20 end
check(lines, 'every planet has its flavour line')
check(K.planetOf('/Game/Griffin/Gameplay/Events/Planets/Whippet/KNOCKOUT/EVT_WHP_LOOP_A_FWD_RACE').name == 'Derven Acos', 'planetOf: Derven from the path')
check(K.planetOf('/Game/Griffin/Gameplay/Arcade/Events/X') == nil and K.planetOf(nil) == nil, 'planetOf: nil for anything else')

-- raceLine and cupPlanets
local jakku = K.cup('jakku')
check(K.raceLine(jakku.races[1]) == 'THE WAR FIELDS  -  Jakku  -  circuit, 2 laps', 'raceLine: circuit (' .. K.raceLine(jakku.races[1]) .. ')')
check(K.raceLine(jakku.races[2]) == "THE GIANTS' GRAVEYARD  -  Jakku  -  sprint", 'raceLine: a sprint has no lap count (' .. K.raceLine(jakku.races[2]) .. ')')
check(K.raceLine(jakku.races[4]) == 'FALLEN EMPIRE  -  Jakku  -  short circuit, 6 laps', 'raceLine: short circuit (' .. K.raceLine(jakku.races[4]) .. ')')
check(K.raceLine({ path = '/x', title = 'X', kind = 'Circuit' }) == 'X  -  ?  -  circuit', 'raceLine: no planet, no laps')
check(table.concat(K.cupPlanets(jakku), ',') == 'Jakku', 'cupPlanets: one planet')
check(table.concat(K.cupPlanets(K.cup('outerrim')), ',') == 'Jakku,Lantaana,Ando Prime,Crait', 'cupPlanets: the Outer Rim Cup in race order')
check(table.concat(K.cupPlanets(K.cup('galactic')), ',') == 'Lantaana,Ando Prime,Sentinel I,Derven Acos', 'cupPlanets: the Galactic Cup ends on Derven')
check(table.concat(K.cupPlanets(K.cup('lantaana_cond')), ',') == 'Lantaana', 'cupPlanets: a conditions cup stays on its planet')
check(#K.cupPlanets(nil) == 0, 'cupPlanets: nothing for no cup')

if failed then os.exit(1) end
