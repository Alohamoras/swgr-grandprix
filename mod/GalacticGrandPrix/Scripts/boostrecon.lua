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

-- exp.forceRamjetEvery = N (seconds; docs/boost-fix-test-plan.md test 2): from 15 s after the start, every N to 1.5 N s
-- (a random gap, so it isn't always the same straight) YOUR boost component is put into ramjet
-- (VehicleBoostComponent:Server_ChangeState(4)); the rows show whether it took and what the racer ahead does.
-- exp.ramjetInstalled = true: every vehicle's VehicleBoostComponent.RamjetInstalled set true at the first row (pods).
function BR.begin(exp, ev)
  write(('# %s | %s | %s'):format(os.date('%Y-%m-%d %H:%M:%S'), tostring(exp.label or '?'), tostring(ev and ev.title or '?')))
  write('t_s,you_kph,you_boost,you_pos,ahead,ahead_kph,ahead_boost,ahead_m,behind,behind_kph,behind_boost,behind_m')
  log('[boostrecon] on: rows every 0.5 s into boostrecon.csv')
  return { last = 0, rows = 0, every = tonumber(exp.forceRamjetEvery), nextForce = nil, forced = 0,
    install = exp.ramjetInstalled == true }
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
  -- (2026-11-26 pod races: BoostState read 2 all race for everyone, so the afterburner's State (0 active, 1 cooldown,
  -- 2 recovering) and the ramjet's RamjetState (1 ready, 2 engaging, 3 active, ...) are written beside it: "b/a/r")
  local bs, ab, rj = {}, {}, {}
  local function byOwner(cls, field, into)
    for _, b in ipairs(C.find(cls)) do
      local owner = try(function() return b:GetOwner() end)
      local a = alive(owner) and C.addr(owner)
      if a then into[a] = try(function() return tonumber(b[field]) end) end
    end
  end
  byOwner('VehicleBoostComponent', 'BoostState', bs)
  -- once: every vehicle's RamjetInstalled (pods: the ramjet never engaged), and (exp.ramjetInstalled) set it true
  if not st.installLogged then
    st.installLogged = true
    local vals, set = {}, 0
    for _, b in ipairs(C.find('VehicleBoostComponent')) do
      vals[#vals + 1] = tostring(try(function() return b.RamjetInstalled end))
      if st.install and pcall(function() b.RamjetInstalled = true end) then set = set + 1 end
    end
    log(('[boostrecon] RamjetInstalled on %d vehicles: %s%s'):format(#vals, table.concat(vals, ','),
      st.install and (' - set true on ' .. set) or ''))
  end
  byOwner('Afterburner', 'State', ab)
  byOwner('Ramjet', 'RamjetState', rj)
  local boost = setmetatable({}, { __index = function(_, a)
    return ('%s/%s/%s'):format(tostring(bs[a] or '-'), tostring(ab[a] or '-'), tostring(rj[a] or '-'))
  end })
  local byPos, you = {}, nil
  for _, ps in ipairs(C.find('GfnPlayerState')) do
    local rec = try(function() return ps.RaceEventComponent end)
    local pawn = try(function() return ps.PawnPrivate end)
    local pos = alive(rec) and try(function() return tonumber(rec.EventPosition) end)
    if pos and pos > 0 and alive(pawn) then
      local name = C.text(ps, 'PlayerNamePrivate') or '?'
      local x = { name = name, kph = kph(pawn), at = where(pawn), boost = boost[C.addr(pawn)], pos = pos, addr = C.addr(pawn) }
      byPos[pos] = x
      if try(function() return ps.bIsABot end) == false then you = x end
    end
  end
  if not you then return end
  -- test 2: your ramjet forced at random moments
  if st.every and C.clock - startedAt > 15000 then
    if not st.nextForce then st.nextForce = C.clock + st.every * 1000 end
    if C.clock >= st.nextForce then
      st.nextForce = C.clock + math.floor(st.every * 1000 * (1 + math.random() * 0.5))
      for _, b in ipairs(C.find('VehicleBoostComponent')) do
        local owner = try(function() return b:GetOwner() end)
        if alive(owner) and C.addr(owner) == you.addr then
          local ok = pcall(function() b:Server_ChangeState(4) end)
          st.forced = st.forced + 1
          write(('! forced ramjet %d at %.1f s%s'):format(st.forced, (C.clock - startedAt) / 1000, ok and '' or ' (call failed)'))
        end
      end
    end
  end
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
