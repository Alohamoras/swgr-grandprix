-- Galactic Grand Prix: the save file, the classes, cups and vehicles (config.lua).
-- Save (save.lua, the mod's own file, never the game's): what's needed to put launch builds back after a crash, the
-- cup in progress (run, see cup.lua), the best finish per class and cup (best[class][cup] = 1 gold / 2 silver /
-- 3 bronze / 4+), and counts.
local C = require('core')
local cfg = require('config')
local CU = require('cup')
local PR = require('prog')
local log = C.log

local K = { data = nil }
K.SAVE_VERSION = 2

-- v2 (v0.3.6): four classes instead of three. What was 50cc (parts 3) is now 100cc, 100cc (6) is 150cc, 150cc (10)
-- is 200cc, so everything stored by class key moves up one: best finishes, the cup in progress, the last class.
local SHIFT = { ['150'] = '200', ['100'] = '150', ['50'] = '100' }
function K.convert(d, from)
  if from < 2 then
    local best = {}
    for k, v in pairs(d.best or {}) do best[SHIFT[k] or k] = v end
    d.best = best
    if type(d.run) == 'table' and d.run.class then d.run.class = SHIFT[d.run.class] or d.run.class end
    if d.class then d.class = SHIFT[d.class] or d.class end
    if type(d.last) == 'table' and d.last.class then d.last.class = SHIFT[d.last.class] or d.last.class end
  end
  d.version = K.SAVE_VERSION
  return d
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
  d.class = type(d.class) == 'string' and d.class or nil -- the class picked last
  d.vehicle = type(d.vehicle) == 'string' and d.vehicle or 'car'
  d.racer = type(d.racer) == 'string' and d.racer or nil -- v0.8: your pilot (racer.lua, config Racers key); nil = the game's own. racerRestore = the list to put back
  -- v0.2: the cup in progress (nil = none) and best finishes
  d.run = type(d.run) == 'table' and d.run or nil
  d.best = type(d.best) == 'table' and d.best or {}
  d.cups = tonumber(d.cups) or 0
  -- v0.8 (records): per class, the best race time and best lap per track
  --   records[classKey][eventPath] = { time = s, lap = s, at = 'YYYY-MM-DD', vehicle = key }
  -- (the time only from a finished race; the lap from any race), the cups won with 1st in every race
  -- (perfect[classKey][cupKey] = true) and every finished cup's final points (standings[classKey][cupKey] =
  -- { [racerName] = points, YOU = points }: the class champion is worked out from these). Filled when missing,
  -- so the save version stays 2.
  d.records = type(d.records) == 'table' and d.records or {}
  d.perfect = type(d.perfect) == 'table' and d.perfect or {}
  d.standings = type(d.standings) == 'table' and d.standings or {}
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

function K.load()
  local f = io.open(C.DIR .. '/save.lua', 'r')
  if f then
    local s = f:read('a'); f:close()
    local chunk = load(s, '=save.lua', 't', {})
    local ok, t = false, nil
    if chunk then ok, t = pcall(chunk) end
    if ok and type(t) == 'table' then
      local was = tonumber(t.version) or 1
      if was < K.SAVE_VERSION then
        -- keep the old save next to the new one before converting
        local name = ('save.backup-v%d-%s.lua'):format(was, os.date('%Y%m%d-%H%M%S'))
        local b = io.open(C.DIR .. '/' .. name, 'w'); if b then b:write(s); b:close() end
        K.data = fill(K.convert(t, was))
        K.save()
        log(('save converted from version %d to %d (four classes; old save kept as %s)'):format(was, K.SAVE_VERSION, name))
      else
        K.data = fill(t)
      end
      -- one-off fix: race_fix.txt in the mod folder holds a number to add to the race count, then is deleted
      -- (v0.3.7: the v0.3.4 bug recorded one race ~200 times)
      local fx = io.open(C.DIR .. '/race_fix.txt', 'r')
      if fx then
        local n = tonumber((fx:read('a') or ''):match('%-?%d+')); fx:close()
        os.remove(C.DIR .. '/race_fix.txt')
        if n then
          local was = K.data.races
          K.data.races = math.max(0, K.data.races + n)
          K.save()
          log(('race count corrected: %d -> %d (race_fix.txt)'):format(was, K.data.races))
        end
      end
      log(('save loaded: %d races'):format(K.data.races))
      return
    end
    log('save.lua unreadable - starting a new save (old file kept as save_bad.lua)')
    local b = io.open(C.DIR .. '/save_bad.lua', 'w'); if b then b:write(s); b:close() end
  end
  K.data = fill({})
  K.save()
  log('new save started')
end

---------------------------------------------------------------------------------------------------------------------
-- classes, cups, vehicles

function K.classes() return cfg.Classes or {} end
function K.class(key)
  for _, c in ipairs(K.classes()) do if c.key == key then return c end end
  return nil
end
function K.cups() return cfg.Cups or {} end
function K.cup(key)
  for _, c in ipairs(K.cups()) do if c.key == key then return c end end
  return nil
end
function K.vehicles() return cfg.Vehicles or {} end
function K.vehicle(key)
  for _, v in ipairs(K.vehicles()) do if v.key == key then return v end end
  return K.vehicles()[1]
end

-- every part slot (0-5) at the class's level
function K.levelsFor(classKey)
  local c = K.class(classKey)
  local lv = c and c.parts or 0
  local t = {}
  for s = 0, 5 do t[s] = lv end
  return t
end

---------------------------------------------------------------------------------------------------------------------
-- the cup in progress

function K.run() return K.data.run end
function K.startCup(classKey, cupKey, vehicleKey, picks, mods)
  local cup = K.cup(cupKey)
  K.data.run = CU.new(classKey, cupKey, vehicleKey, cup and #cup.races or 4)
  K.data.run.picks = picks
  K.data.run.mods = mods
  K.save()
  log(('cup started: %s %s, %s'):format(classKey, cupKey, vehicleKey))
  return K.data.run
end
-- give up the cup (no trophy, nothing saved but the count)
function K.forfeit()
  local run = K.data.run
  if not run then return end
  log(('cup forfeited: %s %s after %d of %d races'):format(run.class, run.cup, run.race - 1, run.races))
  K.data.run = nil
  K.save()
end
-- v0.3.11 (owner, 2026-11-10): start over. Clears every trophy / best finish, the cup in progress and the cups
-- count; keeps your abilities, vehicle, race count and anything still to put back in the game's builds. The save
-- is copied to save.backup-reset-<date>.lua first. Returns the backup's name.
function K.reset()
  local name = ('save.backup-reset-%s.lua'):format(os.date('%Y%m%d-%H%M%S'))
  local b = io.open(C.DIR .. '/' .. name, 'w')
  if not b then log('reset: could not write the backup - nothing reset'); return nil end
  b:write('-- Galactic Grand Prix save\nreturn ', C.serialize(K.data), '\n')
  b:close()
  K.data.best, K.data.run, K.data.cups = {}, nil, 0
  K.data.records, K.data.perfect, K.data.standings = {}, {}, {}
  K.save()
  log('progress reset: trophies, best finishes, track records, perfect cups, cup standings and the cup in progress cleared (backup ' .. name .. ')')
  return name
end
-- the next race of the cup in progress, as a launchable event
function K.nextRace()
  local run = K.data.run
  local cup = run and K.cup(run.cup)
  local r = cup and cup.races[run.race]
  if not r then return nil end
  return { path = r.path, title = r.title, kind = r.kind, cup = run.cup, race = run.race, class = run.class }
end
function K.best(classKey, cupKey) return (K.data.best[classKey] or {})[cupKey] end

local function names(rows)
  local p = {}
  for _, r in ipairs(rows) do p[#p + 1] = ('%d %s%s'):format(r.place, r.key, r.dnf and ' (DNF)' or '') end
  return table.concat(p, ', ')
end

---------------------------------------------------------------------------------------------------------------------
-- v0.8: track records, perfect cups, cup standings and the class champion (pure; test/test_records.lua)

-- seconds -> '2:04.31' (nil / not a number -> '-')
function K.fmtTime(s)
  s = tonumber(s)
  if not s or s < 0 then return '-' end
  local cs = math.floor(s * 100 + 0.5)
  return ('%d:%02d.%02d'):format(cs // 6000, (cs % 6000) // 100, cs % 100)
end
-- the record for a track at a class: { time, lap, at, vehicle } or nil
function K.recordFor(classKey, path) return ((K.data.records or {})[classKey] or {})[path] end
-- the final standings of a finished cup at a class: { [name] = points, YOU = points } or nil
function K.standings(classKey, cupKey) return ((K.data.standings or {})[classKey] or {})[cupKey] end
-- was the cup won with 1st place in every race at that class?
function K.perfect(classKey, cupKey) return ((K.data.perfect or {})[classKey] or {})[cupKey] == true end
-- how many of the cups (every cup in the config: planet, bonus, remix, ...) have a best finish at least `need`
local function countBest(classKey, need)
  local n = 0
  for _, c in ipairs(K.cups()) do
    local b = K.best(classKey, c.key)
    if b and b <= need then n = n + 1 end
  end
  return n, #K.cups()
end
-- golds at a class -> golds, cups in all
function K.golds(classKey) return countBest(classKey, 1) end
-- trophies (gold, silver or bronze) at a class -> trophies, cups in all
function K.trophies(classKey) return countBest(classKey, 3) end
-- the cup page's record lines, one per race: 'THE WAR FIELDS  2:04.31 / lap 0:58.10' (a lap but no time:
-- 'no time yet / lap 0:58.10'; nothing: 'no time yet'). cup = a cup (config) or its key.
-- Returns the lines joined with newlines, and the list of lines.
function K.recordsText(cup, classKey)
  if type(cup) ~= 'table' then cup = K.cup(cup) end
  local lines = {}
  for _, r in ipairs(cup and cup.races or {}) do
    local rec = K.recordFor(classKey, r.path)
    local s = rec and rec.time and K.fmtTime(rec.time) or 'no time yet'
    if rec and rec.lap then s = s .. ' / lap ' .. K.fmtTime(rec.lap) end
    lines[#lines + 1] = r.title .. '  ' .. s
  end
  return table.concat(lines, '\n'), lines
end
-- a planet cup: neither bonus, remix nor conditions (by flag or key)
local function planetCup(c)
  if c.bonus or c.remix or c.conditions then return false end
  local k = c.key or ''
  return not (k:find('bonus', 1, true) or k:find('remix', 1, true) or k:find('conditions', 1, true))
end
-- the class champion: the racer (never you) with the most points over the planet cups finished at that class
-- -> name, points; nil when no planet cup has been finished there. Ties: the first name in alphabetical order.
function K.champion(classKey)
  local sum, any = {}, false
  for _, c in ipairs(K.cups()) do
    local st = planetCup(c) and K.standings(classKey, c.key)
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

-- the record entry for a race's track and class, updated from this race: extra = { time, lap } (seconds; the time
-- only when you finished - race.lua). Fills out.time / lap / newRecord / newLap / oldTime.
local function updateRecord(ev, out, extra, vehicle)
  out.time, out.lap = extra.time, extra.lap
  if not (ev.class and ev.path) then return end
  local byClass = K.data.records[ev.class] or {}
  local rec = byClass[ev.path] or {}
  local changed = false
  if extra.lap and extra.lap > 0 and (not rec.lap or extra.lap < rec.lap) then
    rec.lap, out.newLap, changed = extra.lap, true, true
  end
  if extra.time and extra.time > 0 and (not rec.time or extra.time < rec.time) then
    out.oldTime, out.newRecord, changed = rec.time, true, true
    rec.time = extra.time
    local c = K.class(ev.class)
    log(('NEW RECORD %s %s: %s%s'):format(ev.title or ev.path:match('([^/]+)$'), c and c.name or ev.class,
      K.fmtTime(extra.time), out.oldTime and (' (was ' .. K.fmtTime(out.oldTime) .. ')') or ''))
  end
  if changed then
    rec.at, rec.vehicle = os.date('%Y-%m-%d'), vehicle
    byClass[ev.path] = rec
    K.data.records[ev.class] = byClass
  end
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
  local run = K.data.run
  updateRecord(ev, out, extra, run and run.vehicle or K.data.vehicle)
  if run and ev.cup == run.cup and ev.race == run.race and ev.class == run.class then
    out.rows = CU.addRace(run, field, cfg.Points)
    log(('cup %s race %d: %s'):format(run.cup, run.race - 1, names(out.rows)))
    out.run = run
    if CU.finished(run) then
      local before = PR.openSet(K.data)
      local rank, pts = CU.yourRank(run)
      out.cupOver, out.rank, out.pts, out.trophy = true, rank, pts, CU.trophy(rank)
      K.data.best[run.class] = K.data.best[run.class] or {}
      local was = K.data.best[run.class][run.cup]
      if rank and (not was or rank < was) then K.data.best[run.class][run.cup] = rank; out.newBest = true end
      K.data.cups = K.data.cups + 1
      -- v0.8: the final points of every racer (the class champion is read from these), and a perfect cup
      local final = {}
      for k, p in pairs(run.points) do final[k] = p end
      K.data.standings[run.class] = K.data.standings[run.class] or {}
      K.data.standings[run.class][run.cup] = final
      out.perfect = CU.perfect(run)
      if out.perfect then
        K.data.perfect[run.class] = K.data.perfect[run.class] or {}
        K.data.perfect[run.class][run.cup] = true
      end
      log(('cup over: %s %s - you %s with %d points%s%s'):format(run.class, run.cup, C.ordinal(rank), pts,
        out.trophy and (', ' .. out.trophy .. ' trophy') or '', out.perfect and ' - PERFECT CUP' or ''))
      K.data.run = nil
      -- v0.5: what this cup opened (a class, a bonus cup)
      out.unlocked = PR.newlyOpen(before, PR.openSet(K.data))
      if #out.unlocked > 0 then log('unlocked: ' .. table.concat(out.unlocked, ', ')) end
    end
  end
  K.save()
  return out
end

return K
