-- Galactic Grand Prix: the save file, the leagues, the race pools and the cup draw, cups and vehicles (config.lua).
-- Save (save.lua, the mod's own file, never the game's): what's needed to put launch builds back after a crash, the
-- cup in progress (run, see cup.lua), the best finish per league and cup (best[league][cup] = 1 gold / 2 silver /
-- 3 bronze / 4+), and counts.
-- (v0.26: the four cc classes became three leagues. The save and the cup run keep their field name `class` - it holds
-- a league key: 'riffraff', 'challenger', 'ace'.)
local C = require('core')
local cfg = require('config')
local CU = require('cup')
local PR = require('prog')
local log = C.log

local K = { data = nil }
-- v3 (v0.26): the three leagues. An older save (v1 / v2: the cc classes) gets a clean start at its first load
-- (K.cleanStart): backed up, every bit of progress cleared, the garage kept.
K.SAVE_VERSION = 3

-- v0.41 (owner 2026-11-26: "Move to Learner"; TASKS §1h-L PL1): the v0.40 PODRACER CUP was raced at the car leagues;
-- its results there (best / perfect / standings under the cup key 'pods', and the lap records on the pod tracks) move
-- to the PODRACING league's first step: the best finish, the fastest time and lap per track. Once (podsMoved); logged.
function K.movePods(d)
  if d.podsMoved then return end
  local to = ((cfg.Pods or {}).Steps or {})[1]
  to = to and to.key
  if not to then return end
  local podPath = {}
  for _, r in ipairs((cfg.Pools or {}).pods or {}) do podPath[r.path] = true end
  local moved = 0
  for _, lg in ipairs(cfg.Leagues or {}) do
    local k = lg.key
    local b = (d.best[k] or {}).pods
    if b then
      d.best[to] = d.best[to] or {}
      local cur = d.best[to].pods
      if not cur or b < cur then d.best[to].pods = b end
      d.best[k].pods = nil
      moved = moved + 1
    end
    if (d.perfect[k] or {}).pods then
      d.perfect[to] = d.perfect[to] or {}
      d.perfect[to].pods = true
      d.perfect[k].pods = nil
    end
    local sd = (d.standings[k] or {}).pods
    if sd then
      d.standings[to] = d.standings[to] or {}
      if not d.standings[to].pods or (tonumber(sd.YOU) or 0) > (tonumber(d.standings[to].pods.YOU) or 0) then d.standings[to].pods = sd end
      d.standings[k].pods = nil
    end
    for path, rec in pairs(d.records[k] or {}) do
      if podPath[path] and type(rec) == 'table' then
        d.records[to] = d.records[to] or {}
        local cur = d.records[to][path]
        if not cur then d.records[to][path] = rec
        else
          local t1, t2 = tonumber(rec.time), tonumber(cur.time)
          if t1 and (not t2 or t1 < t2) then cur.time, cur.at, cur.vehicle = t1, rec.at, rec.vehicle end
          local l1, l2 = tonumber(rec.lap), tonumber(cur.lap)
          if l1 and (not l2 or l1 < l2) then cur.lap = l1 end
        end
        d.records[k][path] = nil
        moved = moved + 1
      end
    end
  end
  d.podsMoved = true
  if moved > 0 then log(('[save] v0.41: the PODRACER CUP is a league of its own - %d results from the car leagues moved to %s'):format(moved, to)) end
end

local function fill(d)
  d.version = tonumber(d.version) or K.SAVE_VERSION
  d.races = tonumber(d.races) or 0
  -- launch builds we changed: path -> original part levels { [slot] = level }, put back at the menu
  d.restores = type(d.restores) == 'table' and d.restores or {}
  -- v0.3: launch builds whose ability slots we changed: path -> { [slot] = original class path or '' }
  d.abilityRestores = type(d.abilityRestores) == 'table' and d.abilityRestores or {}
  -- v0.3: your four ability picks (abil.lua), kept between cups; a cup keeps its own copy (run.picks)
  d.picks = type(d.picks) == 'table' and d.picks or nil
  -- v0.4: your mods (modsel.lua: four slots), kept between cups; a cup keeps its own copy (run.mods). modRestores =
  -- the launch builds' own Affixes / UnlockedAffixSlots, put back at the menu like the parts and abilities.
  d.mods = type(d.mods) == 'table' and d.mods or nil
  d.modRestores = type(d.modRestores) == 'table' and d.modRestores or {}
  d.class = type(d.class) == 'string' and d.class or nil -- the league picked last
  d.racer = type(d.racer) == 'string' and d.racer or nil -- v0.8: your pilot (racer.lua, config Racers key); nil = the game's own. racerRestore = the list to put back
  -- v0.2: the cup in progress (nil = none; v0.9: dropped at boot, K.drop - cups cannot be resumed) and best finishes.
  -- v0.26: run.list = the cup's four drawn races (K.draw), saved with it, so the trips through the main menu between
  -- races keep them
  d.run = type(d.run) == 'table' and d.run or nil
  d.best = type(d.best) == 'table' and d.best or {}
  d.cups = tonumber(d.cups) or 0
  -- v0.8 (records): per league, the best race time and best lap per track (exact event path)
  --   records[league][eventPath] = { time = s, lap = s, at = 'YYYY-MM-DD', vehicle = key }
  -- (the time only from a finished race; the lap from any race), the cups won with 1st in every race
  -- (perfect[league][cupKey] = true) and every finished cup's final points (standings[league][cupKey] =
  -- { [racerName] = points, YOU = points }: the league champion is worked out from these).
  d.records = type(d.records) == 'table' and d.records or {}
  d.perfect = type(d.perfect) == 'table' and d.perfect or {}
  d.standings = type(d.standings) == 'table' and d.standings or {}
  d.titles = type(d.titles) == 'table' and d.titles or {} -- v0.8: the title races won per league (title.lua)
  -- v0.21: the title race's opponent per league, from the most recent finished cup there (title.lua); v0.26: path =
  -- the first race of that cup run (the title race's track):
  --   leader[league] = { name = 'Biddy Blas', cup = 'jakku', path = '/Game/.../EVT_MAS_LOOP_A_REV' }
  d.leader = type(d.leader) == 'table' and d.leader or {}
  -- v0.26: the title race's track per league before any cup has finished there (the first race of a random draw of
  -- config Title.DefaultCup, made once): titleTrack[league] = event path
  d.titleTrack = type(d.titleTrack) == 'table' and d.titleTrack or {}
  -- v0.21: the final boss (title.lua): boss = { beaten = true, tries = n, at = 'YYYY-MM-DD' } or nil (not raced)
  d.boss = type(d.boss) == 'table' and d.boss or nil
  -- v0.31 (PR #1): the vehicle picked in the garage (a config Vehicles key; nil = the pilot's own), the pilot whose
  -- signature kit the picks started from, the alternate-vehicle scheme to take off a racer (paint.lua)
  d.vehicle = type(d.vehicle) == 'string' and d.vehicle or nil
  d.picksRacer = type(d.picksRacer) == 'string' and d.picksRacer or nil
  d.paintRestore = type(d.paintRestore) == 'table' and d.paintRestore or nil
  -- v0.32: the AI ability configs' class lists to put back (aiuse.lua), by config path
  d.aiCoverRestores = type(d.aiCoverRestores) == 'table' and d.aiCoverRestores or {}
  -- v0.32.6: the pacing assets' row names to put back (ai.lua A.launchRows), by asset path
  d.aiRowRestores = type(d.aiRowRestores) == 'table' and d.aiRowRestores or {}
  -- v0.41: the PODRACING step picked last (config Pods.Steps key; nil = the first)
  d.podStep = type(d.podStep) == 'string' and d.podStep or nil
  K.movePods(d)
  return d
end

function K.save()
  local path = C.DIR .. '/save.lua'
  local tmp = path .. '.tmp'
  local f = io.open(tmp, 'w')
  if not f then log('could not write the save'); return false end
  f:write('-- Galactic Grand Prix save\nreturn ', C.serialize(K.data), '\n')
  f:close()
  os.remove(path)
  local ok = os.rename(tmp, path)
  if not ok then log('could not replace save.lua') end
  return ok
end

-- v0.21 (owner, OWNER.md "Done" 2026-11-11): RESET clears ALL progress, titles included: trophies, golds, best
-- finishes, records, perfect cups, cup standings, titles, the final boss, the leaders, the counts, the last race and
-- the cup in progress - everything except the garage picks (racer, abilities, tune-ups; Kestar Bool falls back to
-- Shade, locked again) and the put-back records (what the game's assets still need back: never dropped). The save
-- is copied to save.backup-reset-<date>.lua first. Returns the backup's name. (main.lua asks twice.) v0.26: the same
-- list is what an old save keeps at its clean start (K.cleanStart).
K.KEEP_ON_RESET = { 'version', 'racer', 'picks', 'mods', 'restores', 'abilityRestores', 'modRestores', 'aiRestores',
  'racerRestore', 'titleRestore', 'gridRestore', 'aiCoverRestores', 'aiRowRestores', 'paintRestore', 'podStep', 'podsMoved' }
local function keepGarage(was)
  local d = {}
  for _, k in ipairs(K.KEEP_ON_RESET) do d[k] = was[k] end
  return d
end
-- Kestar Bool is locked again once the boss is cleared: racing as him falls back to the first racer (Shade).
-- -> ' Racer X is locked again: racing as Shade.' or ''
local function relockRacer()
  local okR, RC = pcall(require, 'racer')
  if okR and K.data.racer and RC.locked and RC.locked(K.data.racer) then
    local fell = (' Racer %s is locked again: racing as %s.'):format(RC.displayName(K.data.racer), RC.list()[1].name)
    K.data.racer = RC.list()[1].key
    return fell
  end
  return ''
end
local function backup(name, text)
  local b = io.open(C.DIR .. '/' .. name, 'w')
  if not b then return false end
  b:write(text)
  b:close()
  return true
end

-- v0.26 (owner, 2026-11-12: "a clean start"): an older save (the cc classes, save version 1 or 2) at its first load.
-- Backed up as save.backup-v<N>-<date>.lua; every bit of progress cleared (medals, records, perfect cups, standings,
-- titles, the boss, the leaders, the counts, the last race, the cup in progress); only the garage kept - the racer,
-- the four ability picks and the tune-up picks (normalised to the slots) - with the put-back records. Kestar Bool is
-- locked again (the boss is cleared), so a Kestar pick goes back to Shade, as RESET does. Logged once. t = the old
-- save's table, was = its version, text = its file. Returns the backup's name (nil: none could be written).
function K.cleanStart(t, was, text)
  local name = ('save.backup-v%d-%s.lua'):format(was, os.date('%Y%m%d-%H%M%S'))
  if not backup(name, text) then
    log('[save] v0.26: could not write the backup of the old save - its progress is cleared all the same (the old file stays until the next save)')
    name = nil
  end
  local d = keepGarage(t)
  d.version = K.SAVE_VERSION
  local okA, AB = pcall(require, 'abil')
  if okA and d.picks ~= nil then d.picks = AB.normalize(d.picks, 3) end
  local okM, MS = pcall(require, 'modsel')
  if okM and d.mods ~= nil then d.mods = MS.normalize(d.mods) end
  K.data = fill(d)
  local fell = relockRacer()
  if name then K.save() end
  log(('[save] v0.26: three leagues - a clean start (backup %s); kept: racer, abilities, tune-ups.%s'):format(name or 'none', fell))
  return name
end

function K.load()
  local f = io.open(C.DIR .. '/save.lua', 'r')
  if f then
    local s = f:read('a'); f:close()
    local chunk = load(s, '=save.lua', 't', {})
    local ok, t = false, nil
    if chunk then ok, t = pcall(chunk) end
    if ok and type(t) == 'table' then
      local was = tonumber(t.version) or 1
      if was < K.SAVE_VERSION then K.cleanStart(t, was, s) else K.data = fill(t) end
      -- one-off fix: race_fix.txt in the mod folder holds a number to add to the race count, then is deleted
      -- (v0.3.7: the v0.3.4 bug recorded one race ~200 times)
      local fx = io.open(C.DIR .. '/race_fix.txt', 'r')
      if fx then
        local n = tonumber((fx:read('a') or ''):match('%-?%d+')); fx:close()
        os.remove(C.DIR .. '/race_fix.txt')
        if n then
          local was2 = K.data.races
          K.data.races = math.max(0, K.data.races + n)
          K.save()
          log(('race count corrected: %d -> %d (race_fix.txt)'):format(was2, K.data.races))
        end
      end
      log(('save loaded: %d races'):format(K.data.races))
      return
    end
    log('save.lua unreadable - starting a new save (old file kept as save_bad.lua)')
    backup('save_bad.lua', s)
  end
  K.data = fill({})
  K.save()
  log('new save started')
end

---------------------------------------------------------------------------------------------------------------------
-- leagues, cups, race pools, vehicles

function K.leagues() return cfg.Leagues or {} end
-- v0.41 (TASKS §1h-L): the PODRACING league's steps (config Pods.Steps), each its own league key in the save. Not in
-- K.leagues(): the car leagues' unlock chain, goals and cups pages never see them.
function K.podsOn() return (cfg.Pods or {}).On ~= false end
function K.podSteps() return (cfg.Pods or {}).Steps or {} end
local stepCache = {}
-- a step key -> a league-like table { key, name = 'PODRACING LEARNER', step = 'LEARNER', pods = true, line }, or nil
function K.podStep(key)
  if key == nil then return nil end
  for i, st in ipairs(K.podSteps()) do
    if st.key == key then
      local c = stepCache[key]
      if not c then
        local L = (cfg.Pods or {}).League or {}
        c = { key = st.key, step = st.name, name = ('%s %s'):format(L.name or 'PODRACING', st.name), line = st.line,
          pods = true, index = i, parts = 0, mods = 0, abilities = 0 }
        stepCache[key] = c
      end
      return c
    end
  end
  return nil
end
-- the step picked last (saved, podStep), the first step before any pick
function K.curPodStep()
  local k = K.data and K.data.podStep
  if K.podStep(k) then return k end
  return (K.podSteps()[1] or {}).key
end
function K.league(key)
  for _, c in ipairs(K.leagues()) do if c.key == key then return c end end
  return K.podStep(key)
end
-- a league's name for the screen and the log ('RIFF-RAFF'), or the key itself
function K.leagueName(key)
  local c = K.league(key)
  return c and c.name or tostring(key)
end
function K.cups() return cfg.Cups or {} end
function K.cup(key)
  for _, c in ipairs(K.cups()) do if c.key == key then return c end end
  return nil
end

-- v0.26: a planet's race pool (config Pools, by key: 'jakku' ... 'derven'), {} when none
function K.pool(key) return (cfg.Pools or {})[key] or {} end
-- every race in every pool, by event path (a race of a pool, or nil)
function K.raceByPath(path)
  if type(path) ~= 'string' then return nil end
  for _, pool in pairs(cfg.Pools or {}) do
    for _, r in ipairs(pool) do if r.path == path then return r end end
  end
  return nil
end
-- a pool grouped by base track, in pool order: { { base = 'THE WAR FIELDS', races = { r, r, ... } }, ... }
local function byBase(pool)
  local out, at = {}, {}
  for _, r in ipairs(pool) do
    local b = r.group or r.base or r.title -- (v0.40: group = the pods' reversed layouts, tracks of their own)
    if not at[b] then at[b] = #out + 1; out[#out + 1] = { base = b, races = {} } end
    local g = out[at[b]]
    g.races[#g.races + 1] = r
  end
  return out
end
-- a planet cup's base tracks (the pool's, in pool order): { 'THE WAR FIELDS', "THE GIANTS' GRAVEYARD", ... }
function K.bases(cup)
  if type(cup) ~= 'table' then cup = K.cup(cup) end
  local out = {}
  for _, g in ipairs(byBase(K.pool(cup and (cup.pool or cup.key)))) do out[#out + 1] = g.base end
  return out
end

-- v0.26 (owner, 2026-11-12, TASKS "Random cups"): the draw. A planet cup = config CupRaces (4) base tracks drawn at
-- random from its planet's pool, each with a random variant (direction / conditions): never the same base track twice.
-- The Galactic Cup = one race from each of `planets` different pools of `from` (`last`'s race closes it). The same
-- rule in every league. rnd(n) -> 1..n (default K.random, math.random seeded once at load in main.lua; tests pass
-- their own). Returns the races as plain copies (they go into the save with the cup run): { path, title, kind, laps,
-- base, cond }.
K.random = function(n) return math.random(n) end
local function copyRace(r)
  return { path = r.path, title = r.title, kind = r.kind, laps = r.laps, base = r.base, cond = r.cond, condTag = r.condTag, pod = r.pod }
end
local function shuffle(list, rnd)
  for i = #list, 2, -1 do
    local j = rnd(i)
    list[i], list[j] = list[j], list[i]
  end
  return list
end
local function drawFrom(pool, n, rnd)
  local groups = shuffle(byBase(pool), rnd)
  local out = {}
  for i = 1, math.min(n, #groups) do
    local g = groups[i]
    out[i] = copyRace(g.races[rnd(#g.races)])
  end
  return out
end
-- v0.30: the Rally Cup's draw: every base of its pool, in pool order (the tour), a random variant each; the last
-- stage's variant is one whose event path has cup.finale in it ('Night') when there is one
local function drawRally(cup, rnd)
  local groups = byBase(K.pool(cup.pool or cup.key))
  local out = {}
  for i, g in ipairs(groups) do
    local from = g.races
    if i == #groups and cup.finale then
      local fin = {}
      for _, r in ipairs(g.races) do if r.path:lower():find(tostring(cup.finale):lower(), 1, true) then fin[#fin + 1] = r end end
      if #fin > 0 then from = fin end
    end
    out[i] = copyRace(from[rnd(#from)])
  end
  return out
end
function K.draw(cup, rnd)
  rnd = rnd or K.random
  if type(cup) ~= 'table' then cup = K.cup(cup) end
  if not cup then return {} end
  if cup.rally then return drawRally(cup, rnd) end
  local n = tonumber(cfg.CupRaces) or 4
  if not cup.final then return drawFrom(K.pool(cup.pool or cup.key), n, rnd) end
  local from = {}
  for _, k in ipairs(cup.from or {}) do
    if k ~= cup.last and #K.pool(k) > 0 then from[#from + 1] = k end
  end
  shuffle(from, rnd)
  local out = {}
  local want = (tonumber(cup.planets) or n) - (cup.last and 1 or 0)
  for i = 1, math.min(want, #from) do out[#out + 1] = drawFrom(K.pool(from[i]), 1, rnd)[1] end
  if cup.last and #K.pool(cup.last) > 0 then out[#out + 1] = drawFrom(K.pool(cup.last), 1, rnd)[1] end
  return out
end
-- a cup run's races (the draw saved with it), {} when none
function K.runRaces(run) return type(run) == 'table' and type(run.list) == 'table' and run.list or {} end

function K.vehicles() return cfg.Vehicles or {} end
function K.vehicle(key)
  for _, v in ipairs(K.vehicles()) do if v.key == key then return v end end
  return K.vehicles()[1]
end

-- the planet of an event (config Planets, by the codename folder in Events/Planets/<codename>/...) -> { key, name,
-- line } or nil
local POD_PLANET = { BGL = 'Beagle', COR = 'Corgi', DAL = 'Dalmatian' }
function K.planetOf(path)
  local code = type(path) == 'string' and path:match('/Planets/([^/]+)/')
  -- (v0.40: the pod tracks live in Events/Plane_Memory: the planet from the codename in the track's name)
  if not code and type(path) == 'string' then code = POD_PLANET[path:match('/TRAK_(%u%u%u)_PLANE') or ''] end
  return code and (cfg.Planets or {})[code] or nil
end

-- every part slot (0-5) at the league's level. v0.27: parts may be a table by slot ({ [1] = 2, ... }; a slot not
-- listed = 0) - Riff-Raff's speed parts
function K.levelsFor(leagueKey)
  local c = K.league(leagueKey)
  local p = c and c.parts or 0
  local t = {}
  for s = 0, 5 do t[s] = type(p) == 'table' and (tonumber(p[s]) or 0) or (tonumber(p) or 0) end
  return t
end

---------------------------------------------------------------------------------------------------------------------
-- the cup in progress

function K.run() return K.data.run end
-- v0.9 (owner): cups cannot be resumed - like Mario Kart, leaving a Grand Prix loses it. A run only lives from its
-- first race's launch to the standings of its last race; it stays in the save between races (race.lua / racer.lua
-- read it across a race load). One left in the save at boot (the game closed or crashed mid-cup), or still there
-- when HOME is shown, is dropped. where = 'at boot' / 'at the home screen'. Returns true when one was dropped.
function K.drop(where)
  local run = K.data.run
  if not run then return false end
  log(('[cup] %s %s dropped %s (race %d of %d): cups cannot be resumed'):format(run.cup, K.leagueName(run.class),
    where or '?', run.race, run.races))
  K.data.run = nil
  K.save()
  return true
end
-- list = the cup's drawn races (K.draw; v0.26: picked on the start screen, raced exactly as shown); nil = a fresh draw
-- v0.30: the Rally Cup's rivals: n racer keys drawn from config Racers (racer.lua's list), never your own pick or a
-- locked racer, the same ones for every stage of the cup
function K.pickRivals(n, rnd)
  rnd = rnd or K.random
  local ok, RC = pcall(require, 'racer')
  if not ok then return {} end
  local mine = RC.current().key
  local pool = {}
  for _, r in ipairs(RC.list()) do
    if r.key ~= mine and not RC.locked(r) then pool[#pool + 1] = r.key end
  end
  shuffle(pool, rnd)
  local out = {}
  for i = 1, math.min(n, #pool) do out[i] = pool[i] end
  return out
end
function K.startCup(leagueKey, cupKey, vehicleKey, picks, mods, list)
  if K.data.run then K.forfeit() end -- (v0.9: a run left over from a race that never loaded; nothing can resume it)
  if type(list) ~= 'table' or #list == 0 then list = K.draw(cupKey) end
  local copy = {}
  for i, r in ipairs(list) do copy[i] = copyRace(r) end
  local cup = K.cup(cupKey)
  local opts
  if cup and cup.rally then
    local R = cfg.Rally or {}
    opts = { timed = true, dnfPenalty = R.DnfPenaltyS, gapGuess = R.GapGuessS,
      rivals = K.pickRivals((tonumber(R.Grid) or 4) - 1) }
    local okN, RC = pcall(require, 'racer')
    local names = {}
    for i, k in ipairs(opts.rivals) do names[i] = okN and RC.displayName(k) or k end
    log(('[rally] rivals for the cup: %s (a %d-car grid)'):format(table.concat(names, ', '), #opts.rivals + 1))
  end
  K.data.run = CU.new(leagueKey, cupKey, vehicleKey, #copy, opts)
  K.data.run.list = copy
  if cup and cup.pods then K.data.run.pods = true end -- (v0.40: the PODRACER CUP - pods.lua)
  K.data.run.picks = picks
  K.data.run.mods = mods
  K.save()
  local names = {}
  for i, r in ipairs(copy) do names[i] = r.title end
  log(('cup started: %s %s, %s - %s'):format(K.leagueName(leagueKey), cupKey, vehicleKey, table.concat(names, ' / ')))
  return K.data.run
end
-- give up the cup (no trophy, nothing saved but the count)
function K.forfeit()
  local run = K.data.run
  if not run then return end
  log(('cup forfeited: %s %s after %d of %d races'):format(K.leagueName(run.class), run.cup, run.race - 1, run.races))
  K.data.run = nil
  K.save()
end
function K.reset()
  local name = ('save.backup-reset-%s.lua'):format(os.date('%Y%m%d-%H%M%S'))
  if not backup(name, '-- Galactic Grand Prix save\nreturn ' .. C.serialize(K.data) .. '\n') then
    log('reset: could not write the backup - nothing reset'); return nil
  end
  local was = K.data
  K.data = fill(keepGarage(was))
  local fell = relockRacer()
  K.save()
  log(('progress reset: everything cleared - trophies, golds, best finishes, records, perfect cups, standings, titles, '
    .. 'the final boss, leaders, counts (%d races, %d cups) and the cup in progress; kept: racer, abilities, tune-ups.%s (backup %s)'):format(
    tonumber(was.races) or 0, tonumber(was.cups) or 0, fell, name))
  return name
end

-- the next race of the cup in progress, as a launchable event
function K.nextRace()
  local run = K.data.run
  local r = run and K.runRaces(run)[run.race]
  if not r then return nil end
  local ev = { path = r.path, title = r.title, kind = r.kind, laps = r.laps, base = r.base, cup = run.cup, race = run.race, class = run.class }
  -- v0.33: the Galactic Cup's finale (Kestar's Showdown: race.lua takes its story cinematics off)
  if r.boss then ev.boss, ev.finale = true, true end
  -- v0.40: a pod race (the bare pod track and its condition tag: race.lua / pods.lua)
  if r.pod or run.pods then ev.pod, ev.condTag = true, r.condTag end
  -- v0.30 (the Rally Cup): the small grid's rivals for race.lua, and the name to show BEFORE the stage (the weather
  -- kept secret: the route's base name) - chain.lua's NEXT RACE prompt and the via-the-menu line
  if run.timed then
    ev.rally, ev.rivals = true, run.rivals
    ev.shown = ((cfg.Rally or {}).HideWeather ~= false) and r.base or r.title
  end
  return ev
end

function K.best(leagueKey, cupKey) return (K.data.best[leagueKey] or {})[cupKey] end

local function names(rows)
  local p = {}
  for _, r in ipairs(rows) do p[#p + 1] = ('%d %s%s'):format(r.place, r.key, r.dnf and ' (DNF)' or '') end
  return table.concat(p, ', ')
end

---------------------------------------------------------------------------------------------------------------------
-- v0.8: track records, perfect cups, cup standings and the league champion (pure; test/test_records.lua)

-- seconds -> '2:04.31' (nil / not a number -> '-')
function K.fmtTime(s)
  s = tonumber(s)
  if not s or s < 0 then return '-' end
  local cs = math.floor(s * 100 + 0.5)
  return ('%d:%02d.%02d'):format(cs // 6000, (cs % 6000) // 100, cs % 100)
end
-- the record for a track at a league: { time, lap, at, vehicle } or nil
function K.recordFor(leagueKey, path) return ((K.data.records or {})[leagueKey] or {})[path] end
-- the final standings of a finished cup at a league: { [name] = points, YOU = points } or nil
function K.standings(leagueKey, cupKey) return ((K.data.standings or {})[leagueKey] or {})[cupKey] end
-- was the cup won with 1st place in every race at that league?
function K.perfect(leagueKey, cupKey) return ((K.data.perfect or {})[leagueKey] or {})[cupKey] == true end
-- how many of the cups (every cup in the config: the five planet cups and the Galactic Cup) have a best finish at
-- least `need`
local function countBest(leagueKey, need)
  local n = 0
  for _, c in ipairs(K.cups()) do
    local b = K.best(leagueKey, c.key)
    if b and b <= need then n = n + 1 end
  end
  return n, #K.cups()
end
-- golds at a league -> golds, cups in all
function K.golds(leagueKey) return countBest(leagueKey, 1) end
-- trophies (gold, silver or bronze) at a league -> trophies, cups in all
function K.trophies(leagueKey) return countBest(leagueKey, 3) end
-- a planet cup: not the Galactic Cup (final)
local function planetCup(c) return not c.final and not c.rally and not c.pods end
-- the league champion: the racer (never you) with the most points over the planet cups finished at that league
-- -> name, points; nil when no planet cup has been finished there. Ties: the first name in alphabetical order.
function K.champion(leagueKey)
  local sum, any = {}, false
  for _, c in ipairs(K.cups()) do
    local st = planetCup(c) and K.standings(leagueKey, c.key)
    if st then
      any = true
      for name, pts in pairs(st) do
        if name ~= CU.YOU and type(pts) == 'number' then sum[name] = (sum[name] or 0) + pts end
      end
    end
  end
  if not any then return nil end
  local best, bestPts
  for name, pts in pairs(sum) do
    if not best or pts > bestPts or (pts == bestPts and name < best) then best, bestPts = name, pts end
  end
  return best, bestPts
end

-- v0.12: the record near miss of a race result (K.record's out): '0.4 S OFF YOUR RECORD' when a finished race came
-- within config Near.RecordSeconds of the record at the class without beating it ('0.04 S' under 0.05 s, 'LEVEL WITH
-- YOUR RECORD' when equal); nil otherwise (a new record, a DNF, no record yet, not close, Near off)
function K.nearRecord(out)
  local within = tonumber((cfg.Near or {}).RecordSeconds)
  local d = out and not out.newRecord and tonumber(out.offBy)
  if not (within and d and d >= 0 and d <= within) then return nil end
  local s = ('%.1f'):format(d)
  if s == '0.0' then s = ('%.2f'):format(d) end
  if s == '0.00' then return 'LEVEL WITH YOUR RECORD' end
  return s .. ' S OFF YOUR RECORD'
end

-- v0.38.0 (owner 2026-11-25, TASKS §1g-16): the lap record's near miss, "0.4 S OFF YOUR LAP RECORD" (config
-- Near.LapSeconds; false = off) - nil unless this race's best lap missed the record by that little
function K.nearLap(out)
  local within = tonumber((cfg.Near or {}).LapSeconds)
  local d = out and not out.newLap and tonumber(out.lapOffBy)
  if not (within and d and d >= 0 and d <= within) then return nil end
  local s = ('%.1f'):format(d)
  if s == '0.0' then s = ('%.2f'):format(d) end
  if s == '0.00' then return 'LEVEL WITH YOUR LAP RECORD' end
  return s .. ' S OFF YOUR LAP RECORD'
end

-- the record entry for a race's track and class, updated from this race: extra = { time, lap } (seconds; the time
-- only when you finished - race.lua). Fills out.time / lap / newRecord / newLap / oldTime, and (v0.12) offBy = how
-- far a finished race that didn't beat the record was off it.
local function updateRecord(ev, out, extra, vehicle)
  out.time, out.lap = extra.time, extra.lap
  if not (ev.class and ev.path) then return end
  local byClass = K.data.records[ev.class] or {}
  local rec = byClass[ev.path] or {}
  local changed = false
  if extra.lap and extra.lap > 0 and (not rec.lap or extra.lap < rec.lap) then
    out.oldLap = rec.lap
    rec.lap, out.newLap, changed = extra.lap, true, true
  elseif extra.lap and extra.lap > 0 and rec.lap then
    out.lapOffBy = extra.lap - rec.lap -- v0.38.0: a best lap that didn't beat the lap record (0 = equal to it)
  end
  if extra.time and extra.time > 0 and (not rec.time or extra.time < rec.time) then
    out.oldTime, out.newRecord, changed = rec.time, true, true
    rec.time = extra.time
    log(('NEW RECORD %s %s: %s%s'):format(ev.title or ev.path:match('([^/]+)$'), K.leagueName(ev.class),
      K.fmtTime(extra.time), out.oldTime and (' (was ' .. K.fmtTime(out.oldTime) .. ')') or ''))
  elseif extra.time and extra.time > 0 and rec.time then
    out.offBy = extra.time - rec.time -- v0.12: a finished race that didn't beat the record (0 = equal to it)
  end
  if changed then
    rec.at, rec.vehicle = os.date('%Y-%m-%d'), vehicle
    byClass[ev.path] = rec
    K.data.records[ev.class] = byClass
  end
end

-- v0.10: the time gaps of a race, for the owner to set next to how the race felt (DESIGN.md §4, docs/PHILOSOPHY.md
-- point 1). field = every racer (race.lua: name, you, pos, finished, time = EventFinishTime in s once finished).
-- Racers without a finish time (DNF, or not read before the race world went) are skipped. Gaps are in seconds,
-- signed against you: negative = that racer finished before you. Returns nil when no racer has a time, else
-- { you = your time or nil, place = your place among the timed racers, pos = your finishing position, n = timed racers, spread = last - first,
--   winner = { name, gap }, ahead = { name, gap }, behind = { name, gap } (each nil when there is none) }.
function K.gaps(field)
  local timed = {}
  for _, f in ipairs(field or {}) do
    local t = tonumber(f.time)
    if f.finished and t and t > 0 then timed[#timed + 1] = { name = f.you and 'YOU' or f.name, you = f.you, t = t, pos = f.pos } end
  end
  if #timed == 0 then return nil end
  table.sort(timed, function(a, b)
    if a.t ~= b.t then return a.t < b.t end
    return (a.pos or 99) < (b.pos or 99)
  end)
  local g = { n = #timed, spread = timed[#timed].t - timed[1].t }
  local i
  for k, f in ipairs(timed) do if f.you then i = k end end
  local function at(k, base) local f = timed[k]; return f and { name = f.name, gap = f.t - base } or nil end
  if i then
    local mine = timed[i].t
    g.you, g.place, g.pos = mine, i, timed[i].pos
    if i > 1 then g.winner = at(1, mine) end
    if i > 2 then g.ahead = at(i - 1, mine) end
    g.behind = at(i + 1, mine)
  else
    g.winner = { name = timed[1].name, time = timed[1].t }
  end
  return g
end
-- the log line of K.gaps: 'THE WAR FIELDS CHALLENGER: you 1st 1:42.39; next behind Goli & 02-R0 +1.84 s; winner -;
-- field spread 1st-12th 14.2 s' (not 1st: 'winner X -2.31 s; next ahead Y -0.42 s; next behind Z +0.80 s')
function K.gapsLine(ev, g)
  local head = ('%s %s: '):format(ev and ev.title or '?', ev and ev.class and K.leagueName(ev.class) or '?')
  if not g then return head .. 'no finish times read' end
  local function gap(x) return x and ('%s %+.2f s'):format(x.name, x.gap) or '-' end
  local p = {}
  if g.you then
    p[#p + 1] = ('you %s %s'):format(C.ordinal(g.pos or g.place), K.fmtTime(g.you))
    if g.place == 1 then
      p[#p + 1] = 'next behind ' .. gap(g.behind)
      p[#p + 1] = 'winner -'
    else
      p[#p + 1] = 'winner ' .. gap(g.winner)
      if g.ahead then p[#p + 1] = 'next ahead ' .. gap(g.ahead) end
      p[#p + 1] = 'next behind ' .. gap(g.behind)
    end
  else
    p[#p + 1] = 'you no time (DNF)'
    p[#p + 1] = ('winner %s %s'):format(g.winner.name, K.fmtTime(g.winner.time))
  end
  p[#p + 1] = ('field spread 1st-%s %.1f s'):format(C.ordinal(g.n), g.spread)
  return head .. table.concat(p, '; ')
end

-- a finished race: counted, and added to the cup when it's the cup's next race. field = every racer (race.lua).
-- extra (v0.8) = { time = your race time in s (nil unless you finished), lap = your best lap in s, top = kph }.
-- Returns { ev, pos, rows (this race, with points), cupOver, rank, trophy, run (a copy of the cup's state),
--   time, lap (this race's), newRecord, oldTime, newLap, perfect (at cup end: 1st in every race) }.
function K.record(ev, pos, field, extra)
  extra = extra or {}
  K.data.races = K.data.races + 1
  K.data.last = { title = ev.title, pos = pos, class = ev.class, cup = ev.cup, at = os.date('%Y-%m-%d %H:%M'),
    time = extra.time, lap = extra.lap }
  local out = { ev = ev, pos = pos }
  -- v0.10: the time gaps (race.lua logs them); the most recent race's kept in the save with the rest of `last`
  local okG, g = pcall(K.gaps, field)
  if okG then out.gaps, K.data.last.gaps = g, g else log('gaps not worked out: ' .. tostring(g)) end
  local run = K.data.run
  -- (v0.15: outside a cup - the title race - the racer's vehicle; racer.lua requires gp, so it's loaded here lazily)
  local okV, veh = pcall(function() return run and run.vehicle or require('racer').vehicle().key end)
  local inRun = run and ev.cup == run.cup and ev.race == run.race and ev.class == run.class
  if ev.titleRace or ev.boss then
    -- v0.21: a title race runs a cup's track with two cars: its time is shown, but it is no cup record (v0.33: the
    -- finale's Showdown neither)
    out.time, out.lap = extra.time, extra.lap
  else
    updateRecord(ev, out, extra, okV and veh or nil)
  end
  -- v0.8: a title race (v0.21: 1 v 1 against the class leader) and the final boss are never part of a cup (v0.33: the
  -- boss as the Galactic Cup's finale is - below)
  if ev.titleRace or (ev.boss and not inRun) then
    local okT, res = pcall(function() return require('title').record(ev, pos) end)
    if okT then for k, v in pairs(res) do out[k] = v end else log('title race not recorded: ' .. tostring(res)) end
    K.save()
    return out
  end
  if inRun then
    local TI = require('title')
    if ev.boss then
      -- v0.33: the finale: no points; the champion and (at Ace) the racer unlock into the save
      out.rows = TI.finaleRows(run, pos)
      out.finale = TI.finale(ev, pos, run)
      log(('cup %s race %d (the finale): %s'):format(run.cup, run.race - 1, names(out.rows)))
    else
      out.rows = CU.addRace(run, field, cfg.Points)
      log(('cup %s race %d: %s'):format(run.cup, run.race - 1, names(out.rows)))
    end
    out.run = run
    if CU.finished(run) then
      local before = PR.openSet(K.data)
      local rank, pts, total = CU.yourRank(run)
      -- v0.33: the points races decided the trophy before the finale (run.decided); a trophy adds the finale as one
      -- more race of this run, and the cup goes on
      if type(run.decided) == 'table' then rank, pts, total = run.decided.rank, run.decided.pts, run.decided.total
      elseif TI.finaleDue(run, rank) then
        local fr = TI.finaleRace()
        run.list[#run.list + 1] = fr
        run.races, run.finale = #run.list, true
        run.decided = { rank = rank, pts = pts, total = total, trophy = CU.trophy(rank) }
        out.finaleNext = { rank = rank, trophy = CU.trophy(rank), vs = TI.bossName(), league = K.leagueName(run.class) }
        log(('cup %s %s: %s with %d points after %d races - %s; the finale added as race %d: %s'):format(K.leagueName(run.class),
          run.cup, C.ordinal(rank), pts, run.races - 1, CU.trophy(rank) and (CU.trophy(rank) .. ' trophy') or 'no trophy', run.races, fr.title))
        K.save()
        return out
      end
      out.cupOver, out.rank, out.pts, out.total, out.trophy = true, rank, pts, total, CU.trophy(rank)
      K.data.best[run.class] = K.data.best[run.class] or {}
      local was = K.data.best[run.class][run.cup]
      if rank and (not was or rank < was) then K.data.best[run.class][run.cup] = rank; out.newBest = true end
      K.data.cups = K.data.cups + 1
      -- v0.8: the final points of every racer (the league champion is read from these), and a perfect cup
      local final = {}
      for k, p in pairs(run.points) do final[k] = p end
      K.data.standings[run.class] = K.data.standings[run.class] or {}
      K.data.standings[run.class][run.cup] = final
      -- v0.21: the league leader for the title race - the best-placed bot of this cup (title.lua); v0.26: with the
      -- first race of this cup run, the title race's track
      local lead
      -- (v0.30: not from the Rally Cup - its small grid is three drawn rivals, and the title race stays on a circuit)
      if not run.timed and not run.pods then -- (v0.40: nor from the pods)
        for _, r in ipairs(CU.standings(run)) do if r.key ~= CU.YOU then lead = r.key; break end end
      end
      if lead then
        local first = K.runRaces(run)[1]
        K.data.leader[run.class] = { name = lead, cup = run.cup, path = first and first.path or nil }
        log(('[title] %s leader: %s (best bot of the %s) - the title race opponent, on %s'):format(K.leagueName(run.class),
          lead, run.cup, first and first.title or '?'))
      end
      out.perfect = CU.perfect(run)
      if out.perfect then
        K.data.perfect[run.class] = K.data.perfect[run.class] or {}
        K.data.perfect[run.class][run.cup] = true
      end
      log(('cup over: %s %s - you %s with %s%s%s'):format(K.leagueName(run.class), run.cup, C.ordinal(rank),
        run.timed and (K.fmtTime(total) .. ' in all') or (pts .. ' points'),
        out.trophy and (', ' .. out.trophy .. ' trophy') or '', out.perfect and ' - PERFECT CUP' or ''))
      K.data.run = nil
      -- v0.5: what this cup opened (a league, the Galactic Cup, a title race)
      out.unlocked = PR.newlyOpen(before, PR.openSet(K.data))
      if #out.unlocked > 0 then log('unlocked: ' .. table.concat(out.unlocked, ', ')) end
    end
  end
  K.save()
  return out
end

return K
