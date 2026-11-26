-- Galactic Grand Prix: the boost recon (TASKS §1k, 2026-11-26; owner: "why the racers in front of you speed up so
-- quickly when you ramjet and afterburner") - TEST ONLY: config DevTools = true and experiment.lua `boostRecon = true`.
-- Every 0.5 s after the start (two sweeps: the player states and the vehicles' boost components, ~20 ms) one row into
-- boostrecon.csv in the mod folder: the race clock, your speed and boost state, then the racer directly ahead of you and
-- the one behind - name, speed, boost state, straight-line distance to you in metres. Boost states (EBoostState):
-- 0 none, 1 moving to afterburner, 2 afterburner, 3 moving to ramjet, 4 ramjet. A header row per race carries the
-- experiment's label. Read-only; nothing kept between ticks.
local C = require('core')
local log, try, alive = C.log, C.try, C.alive

local BR = {}
local function file() return C.DIR .. '/boostrecon.csv' end
local function write(line)
  local f = io.open(file(), 'a')
  if f then f:write(line .. '\n'); f:close() end
end

function BR.begin(exp, ev)
  write(('# %s | %s | %s'):format(os.date('%Y-%m-%d %H:%M:%S'), tostring(exp.label or '?'), tostring(ev and ev.title or '?')))
  write('t_s,you_kph,you_boost,you_pos,ahead,ahead_kph,ahead_boost,ahead_m,behind,behind_kph,behind_boost,behind_m')
  log('[boostrecon] on: rows every 0.5 s into boostrecon.csv')
  return { last = 0, rows = 0 }
end

local function kph(pawn)
  return try(function() local v = pawn:GetVelocity(); return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) * 0.036 end) or 0
end
local function where(pawn) return try(function() local l = pawn:K2_GetActorLocation(); return { l.X, l.Y, l.Z } end) end
local function dist(a, b)
  if not (a and b) then return nil end
  local dx, dy, dz = a[1] - b[1], a[2] - b[2], a[3] - b[3]
  return math.sqrt(dx * dx + dy * dy + dz * dz) / 100
end

-- every watch tick once the race has started; samples at most every 500 ms
function BR.tick(st, startedAt)
  if not startedAt or C.clock - st.last < 500 then return end
  st.last = C.clock
  local boost = {}
  for _, b in ipairs(C.find('VehicleBoostComponent')) do
    local owner = try(function() return b:GetOwner() end)
    local a = alive(owner) and C.addr(owner)
    if a then boost[a] = try(function() return tonumber(b.BoostState) end) end
  end
  local byPos, you = {}, nil
  for _, ps in ipairs(C.find('GfnPlayerState')) do
    local rec = try(function() return ps.RaceEventComponent end)
    local pawn = try(function() return ps.PawnPrivate end)
    local pos = alive(rec) and try(function() return tonumber(rec.EventPosition) end)
    if pos and pos > 0 and alive(pawn) then
      local name = C.text(ps, 'PlayerNamePrivate') or '?'
      local x = { name = name, kph = kph(pawn), at = where(pawn), boost = boost[C.addr(pawn)], pos = pos }
      byPos[pos] = x
      if try(function() return ps.bIsABot end) == false then you = x end
    end
  end
  if not you then return end
  local function cell(o)
    if not o then return ',,,' end
    local d = dist(you.at, o.at)
    return ('%s,%.0f,%s,%s'):format(o.name:gsub(',', ' '), o.kph, tostring(o.boost or ''), d and ('%.1f'):format(d) or '')
  end
  write(('%.1f,%.0f,%s,%d,%s,%s'):format((C.clock - startedAt) / 1000, you.kph, tostring(you.boost or ''), you.pos,
    cell(byPos[you.pos - 1]), cell(byPos[you.pos + 1])))
  st.rows = st.rows + 1
end

return BR
