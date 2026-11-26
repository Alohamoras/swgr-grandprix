-- v0.26 (owner 2026-11-12, TASKS "Random cups"): each planet cup = 4 tracks drawn at random from the planet's pool,
-- each with a random variant, never the same base track twice; the Galactic Cup = 4 races from 4 different planets
-- (the finals at Derven Acos last). Every pool event is a real event of the game (docs/data/events-2026-11-12.txt, the
-- pak listing), and the pools hold every planet race but the left-out kinds. The draw is made when the cup is picked,
-- shown on the start screen, saved with the cup run (it survives a reload mid-cup) and raced exactly; records stay per
-- exact event path.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 3, races = 0, cups = 0, restores = {}, abilityRestores = {} }, { StartScreen = true, Progression = { On = false } })
local K, cfg = require('gp'), require('config')
local H = rawget(_G, 'GU_TEST_SCREENS')
local S = H.S

-- a small seeded generator (the draws repeatable whatever math.random does)
local function lcg(seed)
  local x = seed
  return function(n)
    x = (x * 1103515245 + 12345) % 2147483648
    return x % n + 1
  end
end

---------------------------------------------------------------------------------------------------------------------
-- 1. the pools against the game's event list
local root = arg[0]:match('^(.*)/test/[^/]+$') or '.'
local list = io.open(root .. '/docs/data/events-2026-11-12.txt')
T.check(list ~= nil, 'the event list is in the repo (docs/data/events-2026-11-12.txt)')
local game = {}   -- lower-case '<planet>/<layout>/<evt>' -> the listed spelling
local nGame = 0
for line in list:lines() do
  local rel = line:match('Gameplay/Events/Planets/(.-)%.uasset$')
  if rel then game[rel:lower()] = rel; nGame = nGame + 1 end
end
list:close()
T.check(nGame == 178, 'the list holds the 178 planet events (' .. nGame .. ')')
local EV = '/Game/Griffin/Gameplay/Events/Planets/'
local notReal, inPool, n = {}, {}, 0
for key, pool in pairs(cfg.Pools) do
  for _, r in ipairs(key == 'pods' and {} or pool) do -- (v0.40: the pods are tracks, not events: test_pods / test_config)
    if key ~= 'rally' then n = n + 1 end -- (v0.30: the rally pool reuses the planets' events)
    local rel = r.path:sub(#EV + 1)
    if r.path:sub(1, #EV) ~= EV or not game[rel:lower()] then notReal[#notReal + 1] = r.path end
    inPool[rel:lower()] = true
  end
end
T.check(#notReal == 0, 'every pool event is a real path from the game\'s list (' .. table.concat(notReal, ', ') .. ')')
-- the left-out kinds, and nothing else left out
local OUT = { 'ELIMINATOR', 'KNOCKOUT_TOUR', '_Act%d', 'CampaignIntro', '/EVT_SHK_', '/EVT_DAL_CAR_Race_', 'Shakedown', 'MID_BOSS', 'SHORTBOSS' }
local function leftOut(rel) for _, p in ipairs(OUT) do if rel:find(p) then return true end end return false end
local wrongIn, missing = {}, {}
for low, rel in pairs(game) do
  if leftOut(rel) and inPool[low] then wrongIn[#wrongIn + 1] = rel end
  if not leftOut(rel) and not inPool[low] then missing[#missing + 1] = rel end
end
table.sort(missing)
T.check(#wrongIn == 0, 'no eliminator, knockout, 1 v 1 arena, story act, campaign intro, challenge, special car race or Shakedown in the pools (' .. table.concat(wrongIn, ', ') .. ')')
T.check(#missing == 0, 'every other planet race is in a pool (' .. table.concat(missing, ', ') .. ')')
T.check(n == 86, 'the pools hold 86 races (' .. n .. ')')

---------------------------------------------------------------------------------------------------------------------
-- 2. the draws: four races of the planet's pool, four different base tracks, a variant each; many seeds
local function poolSet(key) local s = {}; for _, r in ipairs(K.pool(key)) do s[r.path] = r end; return s end
local bad, seenVariants, seenFirst = {}, {}, {}
for _, cup in ipairs(K.cups()) do
  if not cup.final and not cup.rally and not cup.pods then
    local set = poolSet(cup.pool)
    for seed = 1, 300 do
      local d = K.draw(cup, lcg(seed))
      local bases = {}
      if #d ~= 4 then bad[#bad + 1] = cup.key .. ' seed ' .. seed .. ': ' .. #d .. ' races' end
      for _, r in ipairs(d) do
        local p = set[r.path]
        if not p or p.title ~= r.title or p.laps ~= r.laps or p.kind ~= r.kind then bad[#bad + 1] = cup.key .. ': not from its pool ' .. r.path end
        if bases[r.base] then bad[#bad + 1] = cup.key .. ' seed ' .. seed .. ': ' .. r.base .. ' twice' end
        bases[r.base] = true
        seenVariants[r.path] = true
      end
      seenFirst[cup.key .. d[1].base] = true
    end
  end
end
T.check(#bad == 0, 'planet cups: 4 races from the pool, never the same base track twice (300 draws each) (' .. table.concat(bad, '; ') .. ')')
local nv, np = 0, 0
for _ in pairs(seenVariants) do nv = nv + 1 end
for key, pool in pairs(cfg.Pools) do if key ~= 'derven' and key ~= 'rally' and key ~= 'pods' then np = np + #pool end end
T.check(nv == np, 'every variant of every planet pool came up in the draws (' .. nv .. ' of ' .. np .. ')')
T.check(seenFirst['jakkuSCRAP SPIRAL'] and seenFirst['jakkuTHE WAR FIELDS'], 'any base track can open a cup (the order is drawn too)')
-- the default draw (math.random) is valid as well
local okDefault = true
for _ = 1, 200 do
  local d = K.draw('lantaana')
  local bases = {}
  for _, r in ipairs(d) do if bases[r.base] or not poolSet('lantaana')[r.path] then okDefault = false end; bases[r.base] = true end
  okDefault = okDefault and #d == 4
end
T.check(okDefault, 'math.random draws (K.random) are valid too')
K.random = T.RND

---------------------------------------------------------------------------------------------------------------------
-- 3. the Galactic Cup: four races on four different planets, the finals at Derven Acos last
local gbad, planetsSeen = {}, {}
for seed = 1, 300 do
  local d = K.draw('galactic', lcg(seed))
  local ps = {}
  for i, r in ipairs(d) do
    local p = K.planetOf(r.path)
    if not p or ps[p.key] then gbad[#gbad + 1] = 'seed ' .. seed .. ': planet twice or none' end
    ps[p and p.key or '?'] = true
    if p and not poolSet(p.key)[r.path] then gbad[#gbad + 1] = 'not from its pool: ' .. r.path end
    if i < 4 and p then planetsSeen[p.key] = true end
  end
  if #d ~= 4 or d[4].path ~= K.pool('derven')[1].path then gbad[#gbad + 1] = 'seed ' .. seed .. ': not 4 races ending on the Gauntlet' end
end
T.check(#gbad == 0, 'the Galactic Cup: 4 races, 4 different planets, the Gauntlet last (300 draws) (' .. table.concat(gbad, '; ') .. ')')
T.check(planetsSeen.jakku and planetsSeen.lantaana and planetsSeen.ando and planetsSeen.crait and planetsSeen.sentinel and not planetsSeen.derven,
  'its first three races come from all five planets over the draws, never Derven')
local gal = K.cup('galactic')
local was = gal.last
gal.last = nil
local free = K.draw(gal, lcg(7))
local fps = {}
for _, r in ipairs(free) do fps[K.planetOf(r.path).key] = true end
local nfp = 0
for _ in pairs(fps) do nfp = nfp + 1 end
T.check(#free == 4 and nfp == 4, 'config: last = nil draws all four alike, still four planets')
gal.last = was

---------------------------------------------------------------------------------------------------------------------
-- 4. through the menu: the cup picked -> the draw on the start screen; B and again -> drawn again; START races it
K.random = lcg(42)
M.press('F6'); M.tick(6)
T.clickTitle('CHALLENGER'); M.tick(3)
T.clickTitle('SENTINEL CUP'); M.tick(5)
T.check(S.screen == 'garage' and S.start and #S.start.draw == 4, 'picking the cup draws its four races (start screen)')
local first = {}
for i, r in ipairs(S.start.draw) do first[i] = r.path end
-- (v0.28.3: no race list on the start screen by default - the game's intro shows each track; StartRaceList = true)
require('config').StartRaceList = true
local spec = H.SCREENS.garage()
require('config').StartRaceList = nil
local shown = true
for i, r in ipairs(S.start.draw) do shown = shown and spec.lines[i + 1][1] == ('%d   %s'):format(i, r.title) end
T.check(shown and spec.lines[1][1] == 'CHALLENGER', 'the start screen (StartRaceList) shows the league, then the four drawn races')
M.press('BACKSPACE'); M.tick(3)
T.check(S.screen == 'cups' and T.save().run == nil, 'B: back to the cups, nothing started')
T.clickTitle('SENTINEL CUP'); M.tick(5)
local same = true
for i, r in ipairs(S.start.draw) do same = same and r.path == first[i] end
T.check(not same, 'picking the cup again draws again')
local want = {}
for i, r in ipairs(S.start.draw) do want[i] = r.path:match('([^/]+)$') end
T.clickTitle('START'); M.tick(5)
T.check(T.launched() == want[1], 'START launches race 1 of the draw shown (' .. tostring(T.launched()) .. ')')
T.check(table.concat(T.drawn(), ',') == table.concat(want, ','), 'the draw is saved with the cup run, as shown')

-- race 1 finished; the mod reloaded mid-cup (the save read again): the draw is still there, race 2 next
W.race(11); M.tick(5); W.finish(3, 140.25, 70); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.save().run.race == 2, 'race 1 recorded, race 2 next')
K.data = nil
K.load()
T.check(K.run() and table.concat((function() local o = {}; for i, r in ipairs(K.run().list) do o[i] = r.path:match('([^/]+)$') end; return o end)(), ',')
  == table.concat(want, ','), 'a reload mid-cup: the draw survives in the save')
T.check(K.nextRace().path:match('([^/]+)$') == want[2] and K.nextRace().race == 2, 'the next race is race 2 of the draw')
-- (the trip through the main menu between races keeps it as well: NEXT RACE launches race 2)
T.clickTitle('NEXT RACE'); M.tick(5)
T.check(T.launched() == want[2], 'NEXT RACE launches race 2 of the draw (' .. tostring(T.launched()) .. ')')

---------------------------------------------------------------------------------------------------------------------
-- 5. records per exact event path: two variants of one base track are two records
local A = EV .. 'Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD'
local B = EV .. 'Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD_HARD'
local field = { { name = 'Dwayne', you = true, pos = 1, finished = true }, { name = 'Sen Fira', pos = 2, finished = true } }
K.record({ path = A, title = 'THE WAR FIELDS', class = 'ace' }, 1, field, { time = 100, lap = 50 })
K.record({ path = B, title = 'THE WAR FIELDS (SCORCHING)', class = 'ace' }, 1, field, { time = 110, lap = 55 })
T.check(K.recordFor('ace', A).time == 100 and K.recordFor('ace', B).time == 110, 'records per exact path: The War Fields and its scorching variant apart')
local p1 = K.run().list[1].path
local rr = T.save().records
T.check(rr.challenger[p1] and rr.challenger[p1].time == 140.25 and (rr.ace or {})[p1] == nil,
  'the cup race\'s record: under its own league and exact path (' .. p1:match('([^/]+)$') .. ')')
T.finish()
