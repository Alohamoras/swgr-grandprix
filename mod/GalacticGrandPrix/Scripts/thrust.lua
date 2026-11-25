-- Galactic Grand Prix v0.32: a per-bot pace dial, as a TEST first (docs/freerace-review-2026-11-25.md §6.3).
--
-- Every bot races a copy of your car, and KNOWLEDGE.md §5 says the bots' pace follows the shared launch template:
-- their own parts barely move it (v0.28's pilot strength edits the part stacks on each copy for ~1.5-2 s a level). The
-- FreeRace mod found another lever: a tune set made at run time (tune.lua) on the bot's vehicle multiplying its thrust
-- config - VehicleThrustConfig.MaxRPM (the speed follows the engine's top) and the three accelerations - applied to
-- that one vehicle after the start. Independent of the template and the parts, if it works here.
--
-- Two ways to drive it, both off unless asked:
--   config AI.Thrust = { Pilots = { Rager = 'elite', ... }, <league> = { elite = 1.1, contender = 1.0, weak = 0.9 } }
--     (the shape of AI.Strength): each named bot's factor at the league; an unlisted bot or a factor of 1 = as it is.
--   experiment.lua (DevTools): botThrust = 1.2 (every bot), or botThrustBy = { ['Biddy Blas'] = 1.1 } (per bot),
--     which win over the config - the held-race test: three bots at x1.1, x1.0, x0.9, their finish times compared.
-- Applied once per bot, AI.ThrustAfterS after the start (the start grace, ai.lua: the launch stays the game's own),
-- one `[thrust]` line for the field; each bot's BodyState.TopSpeedKmph is read then and 20 s later and logged, so the
-- log says whether the dial did anything before any race is timed. Nothing to put back: the set lives and dies with the
-- race world. The set object is never kept: everything here is a number or a name.
local C = require('core')
local cfg = require('config')
local TU = require('tune')
local try, alive, log = C.try, C.alive, C.log

local TH = {}
local FIELDS = { 'MaxRPM', 'LowSpeedAcceleration', 'MidSpeedAcceleration', 'HighSpeedAcceleration' }
local AGAIN_MS = 20000

local function aiCfg() return cfg.AI or {} end
local function afterMs()
  local s = tonumber(aiCfg().ThrustAfterS)
  if not s then local g = aiCfg().Grace; s = type(g) == 'table' and tonumber(g.Seconds) or 15 end
  return s * 1000
end

-- the factor for a bot (by the name the game shows), or nil
local function factorFor(st, name)
  local exp = st.exp
  if exp then
    if type(exp.botThrustBy) == 'table' and tonumber(exp.botThrustBy[name]) then return tonumber(exp.botThrustBy[name]) end
    if tonumber(exp.botThrust) then return tonumber(exp.botThrust) end
  end
  local t = aiCfg().Thrust
  if type(t) ~= 'table' then return nil end
  local key = require('loadout').racerKey(name)
  local tier = key and (t.Pilots or {})[key]
  local per = t[tostring(st.class)]
  local f = tier and type(per) == 'table' and tonumber(per[tier])
  return f
end

function TH.begin(classKey)
  local okE, exp = pcall(function() return require('ai').experiment() end)
  exp = okE and exp or nil
  local on = type(aiCfg().Thrust) == 'table' or (exp and (tonumber(exp.botThrust) or type(exp.botThrustBy) == 'table'))
  if not on then return nil end
  local st = { class = classKey, exp = exp, done = {}, pending = {}, n = 0, logged = false }
  log(('[thrust] %s: the bots\' thrust dial is on (%s), applied %d s after the start'):format(tostring(classKey),
    exp and (tonumber(exp.botThrust) and ('experiment x' .. exp.botThrust) or 'experiment, per bot') or 'config AI.Thrust', afterMs() // 1000))
  return st
end

local function ops(f)
  local out = {}
  for i, k in ipairs(FIELDS) do out[i] = { 'VehicleThrustConfig', k, TU.OP.FloatMultiply, f } end
  return out
end
local function topOf(pawn) return try(function() return tonumber(pawn.BodyState.TopSpeedKmph) end) end

-- one bot's player state on race.lua's 2 s read, once the race has started (startedAt)
function TH.onBot(st, ps, name, startedAt)
  if not (st and startedAt) or C.clock - startedAt < afterMs() then return end
  local d = st.done[name]
  local pawn = try(function() return ps.PawnPrivate end)
  if d and d.skipped then return end
  if d then
    -- the top speed again, AGAIN_MS on, once
    if not d.after and C.clock - d.at >= AGAIN_MS then
      d.after = alive(pawn) and topOf(pawn) or false
      st.again = (st.again or 0) + 1
      if st.again == st.n then
        local parts = {}
        for who, x in pairs(st.done) do
          if x.how then parts[#parts + 1] = ('%s %s -> %s'):format(who, x.top0 and ('%.0f'):format(x.top0) or '?', x.after and ('%.0f'):format(x.after) or '?') end
        end
        table.sort(parts)
        log(('[thrust] top speeds %d s on: %s'):format(AGAIN_MS // 1000, table.concat(parts, ', ')))
      end
    end
    return
  end
  local f = factorFor(st, name)
  if not f or math.abs(f - 1) < 1e-6 then st.done[name] = { skipped = true }; return end
  if not alive(pawn) then return end -- (no vehicle yet: next read)
  local comp = TU.component(pawn)
  local rec = { at = C.clock, f = f, top0 = topOf(pawn) }
  if not comp then
    rec.how = nil; rec.why = 'no tune component'
  else
    local ts, txt = TU.set(comp, ops(f), name)
    if not ts then rec.why = txt
    else
      rec.how = TU.apply(pawn, ts)
      if not rec.how then rec.why = 'neither RequestApplyTuneSet nor Server_ApplyTuneSet took it' end
      rec.count = rec.how and TU.count(pawn, ts) or nil
    end
  end
  st.done[name] = rec
  st.n = st.n + 1
  st.pending[#st.pending + 1] = ('%s x%g (%s%s)'):format(name, f, rec.how or ('FAILED: ' .. tostring(rec.why)),
    rec.top0 and (', top %.0f kph'):format(rec.top0) or '')
end
-- after a read: the bots tuned in it, one line
function TH.flush(st)
  if not st or #st.pending == 0 then return end
  log(('[thrust] %s: %s'):format(tostring(st.class), table.concat(st.pending, ', ')))
  st.pending = {}
end

return TH
