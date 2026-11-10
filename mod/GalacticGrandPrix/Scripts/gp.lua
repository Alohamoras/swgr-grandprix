-- Galactic Grand Prix: the save file, the classes, cups and vehicles (config.lua).
-- Save (save.lua, the mod's own file, never the game's): what's needed to put launch builds back after a crash, the
-- cup in progress (run, see cup.lua), the best finish per class and cup (best[class][cup] = 1 gold / 2 silver /
-- 3 bronze / 4+), and counts.
local C = require('core')
local cfg = require('config')
local CU = require('cup')
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
  d.class = type(d.class) == 'string' and d.class or nil -- the class picked last
  d.vehicle = type(d.vehicle) == 'string' and d.vehicle or 'car'
  -- v0.2: the cup in progress (nil = none) and best finishes
  d.run = type(d.run) == 'table' and d.run or nil
  d.best = type(d.best) == 'table' and d.best or {}
  d.cups = tonumber(d.cups) or 0
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
function K.startCup(classKey, cupKey, vehicleKey, picks)
  local cup = K.cup(cupKey)
  K.data.run = CU.new(classKey, cupKey, vehicleKey, cup and #cup.races or 4)
  K.data.run.picks = picks
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

-- a finished race: counted, and added to the cup when it's the cup's next race. field = every racer (race.lua).
-- Returns { ev, pos, rows (this race, with points), cupOver, rank, trophy, run (a copy of the cup's state) }.
function K.record(ev, pos, field)
  K.data.races = K.data.races + 1
  K.data.last = { title = ev.title, pos = pos, class = ev.class, cup = ev.cup, at = os.date('%Y-%m-%d %H:%M') }
  local out = { ev = ev, pos = pos }
  local run = K.data.run
  if run and ev.cup == run.cup and ev.race == run.race and ev.class == run.class then
    out.rows = CU.addRace(run, field, cfg.Points)
    log(('cup %s race %d: %s'):format(run.cup, run.race - 1, names(out.rows)))
    out.run = run
    if CU.finished(run) then
      local rank, pts = CU.yourRank(run)
      out.cupOver, out.rank, out.pts, out.trophy = true, rank, pts, CU.trophy(rank)
      K.data.best[run.class] = K.data.best[run.class] or {}
      local was = K.data.best[run.class][run.cup]
      if rank and (not was or rank < was) then K.data.best[run.class][run.cup] = rank; out.newBest = true end
      K.data.cups = K.data.cups + 1
      log(('cup over: %s %s - you %s with %d points%s'):format(run.class, run.cup, C.ordinal(rank), pts,
        out.trophy and (', ' .. out.trophy .. ' trophy') or ''))
      K.data.run = nil
    end
  end
  K.save()
  return out
end

return K
