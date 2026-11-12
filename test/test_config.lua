-- config.lua and gp.lua's read helpers on their own: the leagues (v0.26: parts 0 / 5 / 9, tune-up slots 0 / 1 / 2,
-- abilities 1 / 2 / 3), the 6 cups and the race pools per planet (v0.26), every race's laps, planet and base track,
-- the Planets table, planetOf / bases / raceByPath / leagueName.
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
-- gp.lua only needs core's log at load time
package.loaded.core = { log = function() end, DIR = '.', serialize = tostring, ordinal = tostring }
local cfg = require('config')
local K = require('gp')
local failed = false
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then failed = true end end
local function keys(list, field) local out = {}; for _, x in ipairs(list) do out[#out + 1] = tostring(x[field or 'key']) end; return table.concat(out, ',') end

-- leagues (v0.26, owner 2026-11-12)
check(cfg.Classes == nil, 'v0.26: no Classes table any more')
check(keys(cfg.Leagues) == 'riffraff,challenger,ace', 'league keys (used in the save) (' .. keys(cfg.Leagues) .. ')')
check(keys(cfg.Leagues, 'name') == 'RIFF-RAFF,CHALLENGER,ACE', 'league names on screen, no "cc" (' .. keys(cfg.Leagues, 'name') .. ')')
check(cfg.Leagues[2].parts == 5 and cfg.Leagues[3].parts == 9, 'parts 5 / 9 at Challenger / Ace')
local rl = K.levelsFor('riffraff')
check(rl[0] == 0 and rl[1] == 2 and rl[2] == 0 and rl[3] == 2 and rl[4] == 2 and rl[5] == 0, 'v0.27: Riff-Raff afterburner, ramjet and battery at 2, the rest stock')
check(K.levelsFor('ace')[0] == 9 and K.levelsFor('ace')[5] == 9, 'Ace: every slot 9')
check(keys(cfg.Leagues, 'mods') == '0,1,2', 'tune-up slots 0 / 1 / 2 (' .. keys(cfg.Leagues, 'mods') .. ')')
check(keys(cfg.Leagues, 'abilities') == '1,2,3', 'ability levels 1 / 2 / 3')
check(cfg.Leagues[1].speed == nil and cfg.Leagues[3].speed == nil, 'v0.27: no speed chevrons')
for _, c in ipairs(cfg.Leagues) do
  check(type(c.tagline) == 'string' and #c.tagline <= 48 and type(c.brief) == 'string' and c.brief ~= '', c.key .. ': a tagline (poster) and a brief (cups page)')
end
check(cfg.Leagues[1].open == true and cfg.Leagues[2].open == true and not cfg.Leagues[3].open, 'v0.27.2: Riff-Raff and Challenger open from the start, only Ace gated')
check(K.leagueName('ace') == 'ACE' and K.leagueName('nope') == 'nope', 'leagueName: the name, or the key itself')
local function same(a, b)
  if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
  for k, v in pairs(a) do if not same(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
-- the AI profiles: Riff-Raff = today's 50cc (pressure -1, mercy 0.4, forced errors kept), Challenger = 150cc (honest,
-- pressure 0), Ace = 200cc (the Challenger one plus pressure 0.5)
local P = cfg.AI.Profiles
check(keys({ { key = P.riffraff and 'r' }, { key = P.challenger and 'c' }, { key = P.ace and 'a' } }) == 'r,c,a' and P['50'] == nil and P['150'] == nil,
  'one AI profile per league, none per cc class')
check(P.riffraff.pressure == -1 and P.riffraff.pacing.MaxAiSlowdownScale == 0.4 and P.riffraff.errors == nil, 'Riff-Raff: the 50cc profile')
check(P.challenger.pressure == 0 and P.challenger.pacing.MaxAiSlowdownScale == 1.0 and P.challenger.pacing.AiSlowdownDuringCrash == 1.0, 'Challenger: the 150cc profile')
local pAce = {}
for k, v in pairs(P.ace) do pAce[k] = v end
pAce.pressure = 0
check(same(pAce, P.challenger) and P.ace.pressure == 0.5, 'Ace: the Challenger profile plus pressure 0.5 (the 200cc one)')
check(cfg.TuneUps.AI.challenger and cfg.TuneUps.AI.ace and cfg.TuneUps.AI['150'] == nil and cfg.TuneUps.AI.riffraff == nil,
  "the AI tiers' tune-ups: Challenger (was 150cc) and Ace (was 200cc)")
local blurbs = false
for _, c in ipairs(cfg.Leagues) do blurbs = blurbs or c.blurb ~= nil end
check(not blurbs, 'v0.21: no league blurbs')
check(cfg.Rival == nil, 'v0.21: no Rival config')
check(cfg.PageBackdrop == false, 'v0.21: PageBackdrop = false (no grey page panel)')
check(cfg.Boss and cfg.Boss.League == 'ace' and cfg.Boss.Class == nil and cfg.Boss.Event:find('EVT_WHP_SHORTBOSS_FAIR', 1, true) and cfg.Title.Event == nil,
  'v0.26: the Showdown is the final boss after the Ace title')
local defOk = true
for _, c in ipairs(cfg.Leagues) do
  local k = cfg.Title.Default[c.key]
  local found = false
  for _, r in ipairs(cfg.Racers) do if r.key == k and not r.unlockBoss then found = true end end
  defOk = defOk and found
end
check(defOk, 'every league has a default title opponent, a racer in config (not Kestar)')
check(cfg.Title.Default.riffraff == 'Veteran' and cfg.Title.Default.challenger == 'Rager' and cfg.Title.Default.ace == 'Thrall',
  'default title opponents: Griff Halloran, Biddy Blas, Sen Fira')
check(K.cup(cfg.Title.DefaultCup) ~= nil and cfg.Title.DefaultCup == 'jakku', 'the title track before any cup: a Jakku draw')

-- cups: five planet cups, each drawing from its pool, then the Galactic Cup
check(#cfg.Cups == 6, '6 cups (' .. #cfg.Cups .. ')')
check(keys(cfg.Cups) == 'jakku,lantaana,ando,crait,sentinel,galactic', 'cup order: the five planets, then Galactic (' .. keys(cfg.Cups) .. ')')
local flagsOk = true
for i, cup in ipairs(cfg.Cups) do
  flagsOk = flagsOk and (cup.final == true) == (i == 6) and cup.races == nil and not (cup.bonus or cup.remix or cup.conditions or cup.planet)
    and (cup.final or (cup.pool == cup.key and #K.pool(cup.pool) > 0))
end
check(flagsOk, 'only the Galactic Cup is final; every planet cup has its pool, no fixed race lists')
local gal = K.cup('galactic')
check(gal.planets == 4 and gal.last == 'derven' and keys({ { key = gal.from[1] }, { key = gal.from[6] } }) == 'jakku,derven' and #gal.from == 6,
  'the Galactic Cup: 4 planets out of the five and Derven, the finals last')
check(cfg.CupRaces == 4, 'a cup is 4 races')

-- the pools
local KINDS = { Circuit = true, Sprint = true, ['Short circuit'] = true }
local lapsOk, sprintsOk, planetsOk, samePlanet, baseOk, uniq = true, true, true, true, true, true
local seen, sizes = {}, {}
for key, pool in pairs(cfg.Pools) do
  sizes[key] = #pool
  for _, r in ipairs(pool) do
    lapsOk = lapsOk and math.type(r.laps) == 'integer' and r.laps >= 1 and r.laps <= 8 and KINDS[r.kind] == true
    sprintsOk = sprintsOk and ((r.kind == 'Sprint') == (r.laps == 1))
    local p = K.planetOf(r.path)
    planetsOk = planetsOk and p ~= nil
    samePlanet = samePlanet and p ~= nil and p.key == key
    baseOk = baseOk and type(r.base) == 'string' and #r.base > 0 and not r.base:find('(', 1, true) and r.title:sub(1, #r.base) == r.base
    if seen[r.path] then uniq = false end
    seen[r.path] = true
  end
end
check(lapsOk, 'every race has a lap count (1-8) and a known kind')
check(sprintsOk, 'sprints are the one-lap races and nothing else is')
check(planetsOk, 'every race path names a known planet')
check(samePlanet, 'a pool holds only its own planet\'s races')
check(baseOk, 'every race has its base track: the title without the (direction / conditions)')
check(uniq, 'no event twice in the pools')
local sz = ('%d,%d,%d,%d,%d,%d'):format(sizes.jakku, sizes.lantaana, sizes.ando, sizes.crait, sizes.sentinel, sizes.derven)
check(sz == '13,22,24,13,13,1', 'pool sizes: Jakku 13, Lantaana 22, Ando 24, Crait 13, Sentinel 13, Derven 1 (' .. sz .. ')')
-- the base tracks per planet (docs/tracks-by-planet.md: 32 base tracks, Derven's arenas left out)
local nb = 0
for _, cup in ipairs(cfg.Cups) do if not cup.final then nb = nb + #K.bases(cup) end end
check(nb + #K.pool('derven') == 32 and #K.bases('jakku') == 5 and #K.bases('lantaana') == 7 and #K.bases('ando') == 7 and #K.bases('crait') == 5
  and #K.bases('sentinel') == 7, 'base tracks: Jakku 5, Lantaana 7, Ando 7, Crait 5, Sentinel 7, Derven 1 = 32 (' .. nb .. ' + 1)')
check(table.concat(K.bases('jakku'), ',') == "THE WAR FIELDS,THE GIANTS' GRAVEYARD,DEBRIS DUNES,FALLEN EMPIRE,SCRAP SPIRAL", 'bases: Jakku in pool order')
-- every race lasts the same laps as its layout's other variants, except the two raced before v0.26 with the events
-- dump's own counts (Fallen Empire scorching 4, Dhunkri River Circuit wet 5)
local lapsBy, odd = {}, {}
for _, pool in pairs(cfg.Pools) do
  for _, r in ipairs(pool) do
    local was = lapsBy[r.base]
    if was and was ~= r.laps then odd[#odd + 1] = r.title end
    lapsBy[r.base] = was or r.laps
  end
end
table.sort(odd)
check(table.concat(odd, ',') == 'DHUNKRI RIVER CIRCUIT (WET),FALLEN EMPIRE (SCORCHING)', 'laps: conditions keep their layout\'s laps (' .. table.concat(odd, ',') .. ')')
-- titles: today's style
local function find(title)
  for _, pool in pairs(cfg.Pools) do for _, r in ipairs(pool) do if r.title == title then return r end end end
end
check(find('MORO KEHN TUNNELS (REVERSE, WET)').base == 'MORO KEHN TUNNELS' and find('MORO KEHN TUNNELS (REVERSE, WET)').cond == 'WET',
  'base and cond: MORO KEHN TUNNELS (REVERSE, WET)')
check(find('THE WAR FIELDS (REVERSE)').cond == nil and find("THE GIANTS' GRAVEYARD").base == "THE GIANTS' GRAVEYARD", 'a reverse is no condition; a plain title is its own base')
check(find('CRIMSON MINES (MINES, NIGHT)').base == 'CRIMSON MINES' and find('CRIMSON MINES (MINES, NIGHT)').cond == 'MINES, NIGHT', 'Crimson Mines with mines: the base is the track name')
check(find('THE WAR FIELDS (REVERSE, SCORCHING)').path:find('EVT_MAS_LOOP_A_REV_HARD$') ~= nil, 'Mastiff _HARD = SCORCHING')
check(find('SENTINEL LAKES').path:find('EVT_HSK_LOOP_A_REV$') ~= nil and find('CAUSTIC FIELDS (FORWARD, BLUE HOUR)').cond == 'BLUE HOUR',
  "Sentinel: the default layouts are the reverse ones")
check(find('CLOISTER RUN (SNOW)').path:find('EVT_COR_Loop_B_SHORT_01_Overcast_Snow$') ~= nil, 'Corgi Loop_B SHORT_01 = CLOISTER RUN')
check(K.raceByPath(find('ANDOBI EDGE (SNOW)').path) == find('ANDOBI EDGE (SNOW)') and K.raceByPath('/x') == nil and K.raceByPath(nil) == nil,
  'raceByPath: a pool race by its path, nil for anything else')
check(#K.pool('derven') == 1 and K.pool('derven')[1].title == 'THE GALACTIC GAUNTLET' and #K.pool('nowhere') == 0, "Derven's pool: The Galactic Gauntlet only")

-- planets
check(keys({ cfg.Planets.Mastiff, cfg.Planets.Dalmatian, cfg.Planets.Corgi, cfg.Planets.Spaniel, cfg.Planets.Husky, cfg.Planets.Whippet })
  == 'jakku,lantaana,ando,crait,sentinel,derven', 'six planets by codename, keyed like the pools')
check(cfg.Planets.Corgi.name == 'Ando Prime' and cfg.Planets.Husky.name == 'Sentinel I' and cfg.Planets.Whippet.name == 'Derven Acos', 'the game\'s planet names')
local lines = true
for _, p in pairs(cfg.Planets) do lines = lines and type(p.line) == 'string' and #p.line > 20 end
check(lines, 'every planet has its flavour line')
check(K.planetOf('/Game/Griffin/Gameplay/Events/Planets/Whippet/KNOCKOUT/EVT_WHP_LOOP_A_FWD_RACE').name == 'Derven Acos', 'planetOf: Derven from the path')
check(K.planetOf('/Game/Griffin/Gameplay/Arcade/Events/X') == nil and K.planetOf(nil) == nil, 'planetOf: nil for anything else')

if failed then os.exit(1) end
