-- Galactic Grand Prix: AI strength per speed class (DESIGN.md §4, docs/research-2026-11-10.md "Difficulty").
-- (From the Underground's ai.lua, minus the leagues / power maths: here the class carries the profile.)
--
-- Two layers, both memory-only and put back at the menu:
--  1. Pressure (config AI.Profiles[class].pressure + AI.Adjust): the rubber-band tune values the game's own difficulties
--     use (-1 Cadet / Story, 0 the game's own, 1 Nightmare, 2 Champion), interpolated, applied to every racer's
--     GameTuneComponent.RaceTuneData.Config while the race loads and until 3 s after the start (A.begin / A.apply /
--     A.restore - the tune objects are found by a sweep, so this runs at most every 500 ms and stops itself).
--  2. The AI config asset /Game/Griffin/AI/DA_AIConfig (RaceAIComponentConfig): pacing (honest = no slowing down when
--     ahead), forced errors, perfect start, aggression. Read at race start, so it's written at launch, at the main menu
--     (A.launch) and put back when the race returns to the menu (A.restoreConfig). The originals go into the save
--     first (K.data.aiRestores, like restores / modRestores for the parts and mods), so a crash mid-race is put right at
--     the next menu (race.lua R.pendingRestore / R.restoreBuild).
-- Every engine access is guarded: a field that can't be read is never written (the mock has fewer fields than the game).
local C = require('core')
local K = require('gp')
local cfg = require('config')
local try, alive, log = C.try, C.alive, C.log

local A = {}
A.CONFIG = '/Game/Griffin/AI/DA_AIConfig'

---------------------------------------------------------------------------------------------------------------------
-- pressure -> rubber-band tune ops

-- per field: { add, mul } at each preset level; new value = old * mul + add (missing field = { 0, 1 })
-- (the game's own, read 2026-11-10: every Modifier 0, every Multiplier 1; Cadet = max x0.65 / min -3 s)
local PRESETS = {
  [-1] = { AiMaxTimeAheadMultiplier = { 0, 0.65 }, AiMinTimeAheadModifier = { -3, 1 }, AiAbilityChanceMultiplier = { -0.25, 1 },
    AiAggressionVPlayerChanceMultiplier = { -0.35, 1 }, AiAggressionVPlayerCooldownMultiplier = { 1.25, 1 },
    AiCountdownToSlamPlayerModifier = { 0.8, 1 } },
  [0] = {},
  [1] = { AiMaxTimeAheadModifier = { 2.5, 1 }, AiMinTimeAheadModifier = { 1.5, 1 }, AiAbilityChanceMultiplier = { 0.5, 1 },
    AiAggressionVPlayerChanceMultiplier = { 1, 1 }, AiAggressionVPlayerCooldownMultiplier = { 0, 0.75 },
    AiCountdownToSlamPlayerModifier = { -0.2, 1 } },
  [2] = { AiMaxTimeAheadModifier = { 5, 1 }, AiMinTimeAheadModifier = { 3, 1 }, AiAbilityChanceMultiplier = { 1.25, 1 },
    AiAggressionVPlayerChanceMultiplier = { 2.5, 1 }, AiAggressionVPlayerCooldownMultiplier = { 0, 0.5 },
    AiCountdownToSlamPlayerModifier = { -0.4, 1 } },
}
local FIELDS = { 'AiMaxTimeAheadModifier', 'AiMinTimeAheadModifier', 'AiMaxTimeAheadMultiplier', 'AiMinTimeAheadMultiplier',
  'AiTimeAheadSlowdownModifier', 'AiAggressionVPlayerCooldownMultiplier', 'AiAggressionVPlayerChanceMultiplier',
  'AiCountdownToSlamPlayerModifier', 'AiAbilityChanceMultiplier' }
A.FIELDS = FIELDS

local function op(level, f) return PRESETS[level][f] or { 0, 1 } end
-- the { add, mul } for field f at pressure p (clamped to -1..2, linear between presets)
function A.opFor(p, f)
  p = math.max(-1, math.min(2, p))
  local lo = math.floor(p)
  if lo >= 2 then return op(2, f) end
  local hi, t = lo + 1, p - lo
  local a, b = op(lo, f), op(hi, f)
  return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t }
end

local function aiCfg() return cfg.AI or {} end
function A.enabled() return aiCfg().Enabled ~= false end
function A.profile(classKey) return (aiCfg().Profiles or {})[tostring(classKey)] or {} end
-- the pressure for a class: its profile's + the hidden Adjust knob, kept within -1..2
function A.pressure(classKey)
  local p = (A.profile(classKey).pressure or 0) + (tonumber(aiCfg().Adjust) or 0)
  return math.max(-1, math.min(2, p))
end
function A.label(p)
  if p < -0.5 then return 'RELAXED' elseif p < 0.25 then return 'NORMAL' elseif p < 0.75 then return 'TOUGH'
  elseif p < 1.25 then return 'HARD' elseif p < 1.75 then return 'BRUTAL' end
  return 'CHAMPION'
end
-- the tune ops a class applies to field f: the pressure's, then the profile's own explicit op (ops[f] = { add, mul })
function A.classOp(classKey, f)
  local o = A.opFor(A.pressure(classKey), f)
  local x = (A.profile(classKey).ops or {})[f]
  if type(x) == 'table' then return { o[1] * (x[2] or 1) + (x[1] or 0), o[2] * (x[2] or 1) } end
  return o
end
-- a tune value through a class's ops (Multipliers never below 0)
function A.tuneValue(classKey, f, v)
  local o = A.classOp(classKey, f)
  local nv = v * o[2] + o[1]
  if f:find('Multiplier$') then nv = math.max(0, nv) end
  return nv
end

---------------------------------------------------------------------------------------------------------------------
-- the AI config asset: what a class profile writes

-- a dotted field path on an object: the struct that holds the last segment, and that segment
local function walk(obj, path)
  local segs = {}
  for s in path:gmatch('[^%.]+') do segs[#segs + 1] = s end
  if #segs == 0 then return nil end
  local o = obj
  for i = 1, #segs - 1 do
    local seg = segs[i]
    o = try(function() return o[seg] end)
    if o == nil then return nil end
  end
  return o, segs[#segs]
end
local function readNum(obj, path)
  local o, k = walk(obj, path)
  local v = o and try(function() return o[k] end)
  return type(v) == 'number' and v or nil
end
local function near(a, b) return a and b and math.abs(a - b) < 1e-4 end
-- read the struct, set the field on it (as race.lua does for SlotToUpgradeLevelMap); true when it reads back
local function writeNum(obj, path, v)
  local o, k = walk(obj, path)
  if not o then return false end
  pcall(function() o[k] = v end)
  return near(readNum(obj, path), v)
end

-- the writes a profile asks for: field path -> { set = value } and / or { mul = factor } (set first, then mul)
function A.plan(classKey)
  local prof = A.profile(classKey)
  local w = {}
  local function want(path, t)
    w[path] = w[path] or {}
    for k, v in pairs(t) do w[path][k] = v end
  end
  for f, v in pairs(prof.pacing or {}) do if type(v) == 'number' then want('DefaultPacingSettings.' .. f, { set = v }) end end
  if type(prof.catchup) == 'number' then want('DefaultPacingSettings.MaxAiCatchupScale', { mul = prof.catchup }) end
  if type(prof.errors) == 'number' then want('ForcedErrorChance', { mul = prof.errors }) end
  if type(prof.perfectStart) == 'number' then want('DefaultPercentageChancePerfectStart', { set = prof.perfectStart }) end
  if type(prof.aggression) == 'table' then
    if type(prof.aggression.chance) == 'number' then want('AggressionConfig.VersusPlayer.Chance', { mul = prof.aggression.chance }) end
    if type(prof.aggression.cooldown) == 'number' then want('AggressionConfig.VersusPlayer.Cooldown', { mul = prof.aggression.cooldown }) end
  end
  for path, v in pairs(prof.config or {}) do if type(v) == 'number' then want(path, { set = v }) end end
  return w
end
-- the value a planned write gives, from the current one
function A.planned(t, cur)
  local v = t.set ~= nil and t.set or cur
  if t.mul then v = v * t.mul end
  return v
end

local function restores()
  K.data.aiRestores = type(K.data.aiRestores) == 'table' and K.data.aiRestores or {}
  return K.data.aiRestores
end
function A.pending() return K.data ~= nil and next(restores()) ~= nil end

-- at launch (the main menu): the class's writes on the AI config asset, the originals into the save first.
-- Returns the number of fields written (0 = nothing to do or the asset wasn't found).
function A.launch(classKey)
  if not A.enabled() then return 0 end
  local plan = A.plan(classKey)
  if next(plan) == nil then return 0 end
  local obj = C.asset(A.CONFIG)
  if not alive(obj) then log('[ai] AI config asset not found: ' .. A.CONFIG); return 0 end
  local paths = {}
  for path in pairs(plan) do paths[#paths + 1] = path end
  table.sort(paths)
  local rest = restores()
  local mine = rest[A.CONFIG] or {}
  local parts, n = {}, 0
  for _, path in ipairs(paths) do
    local cur = readNum(obj, path)
    if cur == nil then
      log('[ai] AI config has no readable ' .. path .. ' - left alone')
    else
      -- the original: what the save already holds (a put-back still pending) or what's there now
      local orig = mine[path]
      if orig == nil then orig = cur end
      local nv = A.planned(plan[path], orig)
      if near(nv, cur) then
        parts[#parts + 1] = ('%s %g (as is)'):format(path, cur)
      else
        if mine[path] == nil then mine[path] = orig; rest[A.CONFIG] = mine; K.save() end
        if writeNum(obj, path, nv) then
          n = n + 1
          parts[#parts + 1] = ('%s %g -> %g'):format(path, cur, nv)
        else
          parts[#parts + 1] = ('%s %g -> %g FAILED'):format(path, cur, nv)
        end
      end
    end
  end
  log(('[ai] class %s: AI config (%s) %s'):format(tostring(classKey), A.CONFIG:match('([^/]+)$'), table.concat(parts, ', ')))
  return n
end

-- at the menu (race.lua R.restoreBuild): every saved original back on the asset. Returns the number of assets put
-- back (the caller saves) - also when the AI is switched off, so nothing is ever left changed.
function A.restoreConfig(why)
  if K.data == nil then return 0 end
  local rest = restores()
  local done = 0
  for path, fields in pairs(rest) do
    local obj = C.asset(path)
    if alive(obj) then
      local parts, bad = {}, 0
      local keys = {}
      for f in pairs(fields) do keys[#keys + 1] = f end
      table.sort(keys)
      for _, f in ipairs(keys) do
        if writeNum(obj, f, fields[f]) then parts[#parts + 1] = ('%s=%g'):format(f, fields[f])
        else bad = bad + 1; parts[#parts + 1] = ('%s=%g FAILED'):format(f, fields[f]) end
      end
      log(('[ai] AI config put back (%s): %s %s'):format(why or '', path:match('([^/]+)$'), table.concat(parts, ' ')))
    else
      log('[ai] restore: AI config asset not found ' .. path .. ' (its values are dropped)')
    end
    rest[path] = nil
    done = done + 1
  end
  return done
end

---------------------------------------------------------------------------------------------------------------------
-- the rubber band on the race's tune objects: begin at launch, apply from race.watch while the race loads and for
-- 3 s after the start, restore at the menu

function A.begin(classKey)
  if not A.enabled() then return nil end
  local p = A.pressure(classKey)
  local adj = tonumber(aiCfg().Adjust) or 0
  log(('[ai] class %s: pressure %.2f (%s)%s'):format(tostring(classKey), p, A.label(p),
    adj ~= 0 and (' - Adjust %+g'):format(adj) or ''))
  return { class = classKey, p = p, at = C.clock, done = {}, orig = {}, last = -1e9, logged = 0 }
end

-- (a sweep every 500 ms: never for a whole race - if the start is never seen, it stops after GIVE_UP_MS anyway)
local GIVE_UP_MS = 120000
function A.apply(st, started, sinceStart)
  if not st or st.finished then return end
  if C.clock - st.last < 500 then return end
  st.last = C.clock
  if C.clock - (st.at or C.clock) > GIVE_UP_MS then
    st.finished = true
    log('[ai] the start of the race was never seen - the tune objects stay as they are (sweeps stopped)')
    return
  end
  local n = 0
  for _, tc in ipairs(C.find('GameTuneComponent')) do
    local rtd = try(function() return tc.RaceTuneData end)
    local key = alive(rtd) and C.addr(rtd)
    local conf = key and not st.done[key] and try(function() return rtd.Config end)
    if conf then
      st.done[key] = true
      local rec, was, now = { ref = C.ref(rtd), vals = {} }, {}, {}
      for _, f in ipairs(FIELDS) do
        local v = try(function() return conf[f] end)
        if type(v) == 'number' then
          rec.vals[f] = v
          local nv = A.tuneValue(st.class, f, v)
          try(function() conf[f] = nv end)
          was[#was + 1] = ('%s=%g'):format(f:gsub('^Ai', ''), v)
          local back = try(function() return conf[f] end)
          now[#now + 1] = ('%g'):format(type(back) == 'number' and back or -1)
        end
      end
      if next(rec.vals) ~= nil and rec.ref then st.orig[#st.orig + 1] = rec end
      if st.logged < 1 then
        st.logged = st.logged + 1
        log(('[ai] %s -> %s'):format(table.concat(was, ' '), table.concat(now, ' ')))
      end
      n = n + 1
    end
  end
  if n > 0 then log(('[ai] applied to %d tune objects (%d total)'):format(n, #st.orig)) end
  if started and (sinceStart or 0) >= 3000 then st.finished = true end
end

function A.restore(st)
  if not st then return end
  st.finished = true
  if #st.orig == 0 then return end
  local n = 0
  for _, rec in ipairs(st.orig) do
    -- looked up again by path + address: most tune objects were freed with the race world (never touch those)
    local obj = C.deref(rec.ref)
    local conf = obj and try(function() return obj.Config end)
    if conf then
      for f, v in pairs(rec.vals) do try(function() conf[f] = v end) end
      n = n + 1
    end
  end
  st.orig = {}
  log(('[ai] put back on %d tune objects (the rest went with the race)'):format(n))
end

return A
