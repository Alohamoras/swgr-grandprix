-- config.lua and gp.lua's read helpers on their own: the classes (parts 0 / 3 / 7 / 9, mods 0 / 1 / 2 / 2), the
-- 6 cups and their race list per class (v0.11), every race's laps, planet and base track, the Planets table,
-- planetOf / raceLine / cupPlanets / cupConditions.
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
check(keys(cfg.Classes, 'parts') == '0,3,7,9', 'parts 0 / 3 / 7 / 9 (v0.10: 200cc the extra at 9) (' .. keys(cfg.Classes, 'parts') .. ')')
-- v0.10: 200cc races the 150cc AI profile (a deep compare, so tuning one apart later shows up here)
local function same(a, b)
  if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
  for k, v in pairs(a) do if not same(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
-- (v0.21: 200cc = the 150cc profile plus pressure 0.5, owner: "the difficulty could be a little tougher")
local p200 = {}
for k, v in pairs(cfg.AI.Profiles['200']) do p200[k] = v end
p200.pressure = 0
check(same(p200, cfg.AI.Profiles['150']) and cfg.AI.Profiles['200'].pressure == 0.5, 'v0.21: 200cc AI profile = the 150cc one plus pressure 0.5')
check(keys(cfg.Classes, 'mods') == '0,1,2,2', 'mod slots 0 / 1 / 2 / 2 (' .. keys(cfg.Classes, 'mods') .. ')')
check(keys(cfg.Classes, 'abilities') == '1,1,2,3', 'ability levels 1 / 1 / 2 / 3')
-- v0.21 (owner: less clutter): the class blurbs are gone
local blurbs = false
for _, c in ipairs(cfg.Classes) do blurbs = blurbs or c.blurb ~= nil end
check(not blurbs, 'v0.21: no class blurbs')
check(cfg.Rival == nil, 'v0.21: no Rival config')
check(cfg.PageBackdrop == false, 'v0.21: PageBackdrop = false (no grey page panel)')
check(cfg.Boss and cfg.Boss.Class == '150' and cfg.Boss.Event:find('EVT_WHP_SHORTBOSS_FAIR', 1, true) and cfg.Title.Event == nil,
  'v0.21: the Showdown is the final boss at 150cc, no longer the title race')
local defOk = true
for _, c in ipairs(cfg.Classes) do
  local k = cfg.Title.Default[c.key]
  local found = false
  for _, r in ipairs(cfg.Racers) do if r.key == k and not r.unlockBoss then found = true end end
  defOk = defOk and found
end
check(defOk, 'v0.21: every class has a default title opponent, a racer in config (not Kestar)')
check(cfg.Progression.RemixClass == nil and cfg.Classes[4].raceList == '150' and cfg.Classes[3].raceList == nil,
  'v0.11: no RemixClass; 200cc races the 150cc lists')

-- cups (v0.11): five planet cups with a list per class, then the Galactic Cup (the same four at every class)
check(#cfg.Cups == 6, '6 cups (' .. #cfg.Cups .. ')')
check(keys(cfg.Cups) == 'jakku,lantaana,ando,crait,sentinel,galactic', 'cup order: the five planets, then Galactic (' .. keys(cfg.Cups) .. ')')
local flagsOk = true
for i, cup in ipairs(cfg.Cups) do
  flagsOk = flagsOk and (cup.final == true) == (i == 6) and not (cup.bonus or cup.remix or cup.conditions or cup.planet)
end
check(flagsOk, 'only the Galactic Cup is final; no bonus / remix / conditions flags left')
local KINDS = { Circuit = true, Sprint = true, ['Short circuit'] = true }
local fourEach, lapsOk, sprintsOk, planetsOk, noRepeat, samePlanet, baseOk = true, true, true, true, true, true, true
local repeats = {}
local events = {}
for _, cup in ipairs(cfg.Cups) do
  for _, c in ipairs(cfg.Classes) do
    local list = K.races(cup, c.key)
    fourEach = fourEach and #list == 4
    local bases = {}
    for _, r in ipairs(list) do
      lapsOk = lapsOk and math.type(r.laps) == 'integer' and r.laps >= 1 and r.laps <= 8 and KINDS[r.kind] == true
      sprintsOk = sprintsOk and ((r.kind == 'Sprint') == (r.laps == 1))
      local p = K.planetOf(r.path)
      planetsOk = planetsOk and p ~= nil
      if not cup.final then samePlanet = samePlanet and p ~= nil and p.key == cup.key end
      baseOk = baseOk and type(r.base) == 'string' and #r.base > 0 and not r.base:find('(', 1, true)
        and r.title:sub(1, #r.base) == r.base
      if bases[r.base] then noRepeat = false; repeats[#repeats + 1] = cup.key .. ' ' .. c.key .. ': ' .. r.base end
      bases[r.base] = true
      events[r.path] = true
    end
  end
end
check(fourEach, 'every cup has four races at every class')
check(lapsOk, 'every race has a lap count (1-8) and a known kind')
check(sprintsOk, 'sprints are the one-lap races and nothing else is')
check(planetsOk, 'every race path names a known planet')
check(samePlanet, 'a planet cup races only on its own planet, at every class')
check(baseOk, 'every race has its base track: the title without the (direction / conditions)')
check(noRepeat, 'no cup at any class races the same base track twice' .. (#repeats > 0 and (': ' .. table.concat(repeats, '; ')) or ''))
local n = 0
for _ in pairs(events) do n = n + 1 end
check(n == 59, 'distinct events across the cups and classes: 59 (' .. n .. ')')
-- the base by hand for the tricky titles
local function find(title)
  for _, cup in ipairs(cfg.Cups) do for _, c in ipairs(cfg.Classes) do for _, r in ipairs(K.races(cup, c.key)) do
    if r.title == title then return r end end end end
end
check(find('MORO KEHN TUNNELS (REVERSE, WET)').base == 'MORO KEHN TUNNELS' and find('MORO KEHN TUNNELS (REVERSE, WET)').cond == 'WET',
  'base and cond: MORO KEHN TUNNELS (REVERSE, WET)')
check(find('THE WAR FIELDS (REVERSE)').cond == nil and find("THE GIANTS' GRAVEYARD").base == "THE GIANTS' GRAVEYARD", 'a reverse is no condition; a plain title is its own base')
check(find('CRIMSON MINES (MINES, NIGHT)').base == 'CRIMSON MINES' and find('CRIMSON MINES (MINES, NIGHT)').cond == 'MINES, NIGHT', 'Crimson Mines with mines: the base is the track name')
-- per class
local function titles(cupKey, cls) local out = {}; for _, r in ipairs(K.races(cupKey, cls)) do out[#out + 1] = r.title end; return table.concat(out, ',') end
check(titles('jakku', '50') == "THE WAR FIELDS,THE GIANTS' GRAVEYARD,DEBRIS DUNES,FALLEN EMPIRE", '50cc: the classic Jakku Cup (' .. titles('jakku', '50') .. ')')
local sameAll, same200 = true, true
for _, cup in ipairs(cfg.Cups) do
  same200 = same200 and K.races(cup, '200') == K.races(cup, '150') and titles(cup.key, '200') == titles(cup.key, '150')
  if cup.final then sameAll = titles(cup.key, '50') == titles(cup.key, '100') and titles(cup.key, '100') == titles(cup.key, '150') end
end
check(same200, 'the 200cc lists are the 150cc ones, every cup')
check(sameAll, 'the Galactic Cup: the same four at every class')
local revOk, condOk = true, true
for _, cup in ipairs(cfg.Cups) do
  if not cup.final then
    for _, r in ipairs(K.races(cup, '50')) do revOk = revOk and r.cond == nil and not r.title:find('(', 1, true) end
    local nc = 0
    for _, r in ipairs(K.races(cup, '150')) do if r.cond then nc = nc + 1 end end
    condOk = condOk and nc >= 3 and #K.cupConditions(cup, '150') > 0
  end
end
check(revOk, '50cc: plain titles, no conditions')
check(condOk, '150cc: at least three races under conditions in every planet cup')
local OR = { 'Mastiff/Loop_B/EVT_MAS_LOOP_B_SHORT_01', 'Dalmatian/P2P/EVT_DAL_P2P_FWD', 'Corgi/P2P/EVT_COR_P2P_REV', 'Spaniel/Loop_B/EVT_SPA_Loop_B_SHORT_02' }
local orOk = true
for i, cupKey in ipairs({ 'jakku', 'lantaana', 'ando', 'crait' }) do
  local hit = false
  for _, r in ipairs(K.races(cupKey, '100')) do if r.path:find(OR[i] .. '$') then hit = true end end
  orOk = orOk and hit
end
check(orOk, 'the Outer Rim tracks moved into the 100cc lists (Scrap Spiral, Geothermal Tour, Dai Bendu Ascension, Crystal Caverns)')
check(table.concat(K.cupConditions('lantaana', '150'), ',') == 'NIGHT,WET' and #K.cupConditions('lantaana', '50') == 0, 'cupConditions: Lantaana at 150cc is night and wet')
check(table.concat(K.cupConditions('ando', '200'), ',') == 'NIGHT,SNOW', 'cupConditions: Ando at 200cc (the 150cc list) night and snow')

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
local jakku = K.races('jakku', '50')
check(K.raceLine(jakku[1]) == 'THE WAR FIELDS  -  Jakku  -  circuit, 2 laps', 'raceLine: circuit (' .. K.raceLine(jakku[1]) .. ')')
check(K.raceLine(jakku[2]) == "THE GIANTS' GRAVEYARD  -  Jakku  -  sprint", 'raceLine: a sprint has no lap count (' .. K.raceLine(jakku[2]) .. ')')
check(K.raceLine(jakku[4]) == 'FALLEN EMPIRE  -  Jakku  -  short circuit, 6 laps', 'raceLine: short circuit (' .. K.raceLine(jakku[4]) .. ')')
check(K.raceLine(K.races('ando', '150')[2]) == 'MONASTERY MOUNTAINS (SNOW)  -  Ando Prime  -  circuit, 3 laps', 'raceLine: the conditions in the title (' .. K.raceLine(K.races('ando', '150')[2]) .. ')')
check(K.raceLine({ path = '/x', title = 'X', kind = 'Circuit' }) == 'X  -  ?  -  circuit', 'raceLine: no planet, no laps')
check(table.concat(K.cupPlanets(K.cup('jakku'), '150'), ',') == 'Jakku', 'cupPlanets: one planet')
check(table.concat(K.cupPlanets(K.cup('galactic'), '100'), ',') == 'Lantaana,Ando Prime,Sentinel I,Derven Acos', 'cupPlanets: the Galactic Cup ends on Derven')
check(#K.cupPlanets(nil) == 0, 'cupPlanets: nothing for no cup')

if failed then os.exit(1) end
