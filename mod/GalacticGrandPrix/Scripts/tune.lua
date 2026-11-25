-- Galactic Grand Prix v0.32: tune sets made at run time (docs/freerace-review-2026-11-25.md §3.6, §6.3; the FreeRace
-- mod's technique, checked against the header dump).
--
-- The game tunes a vehicle through UTuneSet data assets: a list of FTuneOperation { Category (the tuning struct's name
-- without its F: 'VehicleThrustConfig', 'VehicleHealthConfig'...), Property (a field of it), Operation
-- (ETuneOperations: 3 FloatAdd, 7 FloatMultiply, 1 BoolSetTrue, 2 BoolSetFalse, 19 Vector2DMultiply), FloatParam ... }.
-- One can be built in memory - StaticConstructObject of the TuneSet class (taken from a tune set the game has
-- loaded) with the racer's tune component as its outer, its Operations filled in - and applied to ONE vehicle with the
-- pawn's own RequestApplyTuneSet(TuneSet, times) (AVehiclePawn; the component's Server_ApplyTuneSet is the fallback).
-- Nothing is written to a game asset and nothing needs putting back: the set lives and dies with the race world.
-- (The object is never kept between ticks; a caller that wants to re-apply builds a new one.)
local C = require('core')
local try, alive, log = C.try, C.alive, C.log

local TU = {}
TU.OP = { BoolTrue = 1, BoolFalse = 2, FloatAdd = 3, FloatMultiply = 7, Vector2DMultiply = 19 }
-- a tune set the game always has loaded (the Shield condition's), for its class
TU.TEMPLATE = '/Game/Griffin/Gameplay/StatusEffects/TNS_Condition_Shield'

-- a tune set with these ops ({ category, property, operation, float[, vector2d] } each), made under `outer`.
-- Returns the set and a text of what it holds, or nil + why.
function TU.set(outer, ops, what)
  local tmpl = C.asset(TU.TEMPLATE)
  local cls = tmpl and try(function() return tmpl:GetClass() end)
  if not alive(cls) then return nil, 'TuneSet class not found (' .. TU.TEMPLATE .. ')' end
  local ts = try(StaticConstructObject, cls, outer)
  if not alive(ts) then return nil, 'could not make a tune set' end
  local arr = try(function() return ts.Operations end)
  if not arr then return nil, 'the tune set has no Operations' end
  for i, w in ipairs(ops) do
    local ok = pcall(function()
      arr[i] = { Priority = 0, FloatParam = w[4] or 0, IntParam = 0, Vector2DParam = w[5] or { X = 0, Y = 0 },
        VectorParam = { X = 0, Y = 0, Z = 0 }, Operation = w[3], Category = FName(w[1]), Property = FName(w[2]) }
    end)
    if not ok then return nil, ('op %d (%s.%s) refused'):format(i, w[1], w[2]) end
  end
  local n = try(function() return arr:GetArrayNum() end)
  if n ~= #ops then return nil, ('the set holds %s of %d ops'):format(tostring(n), #ops) end
  local parts = {}
  for _, w in ipairs(ops) do parts[#parts + 1] = ('%s.%s op%d %g'):format(w[1], w[2], w[3], w[4] or 0) end
  return ts, (what or 'tune set') .. ': ' .. table.concat(parts, ', ')
end

-- the vehicle's tune component (AVehiclePawn.TuneComponent), or nil
function TU.component(pawn)
  local c = try(function() return pawn.TuneComponent end)
  return alive(c) and c or nil
end

-- apply a set to a vehicle, `times` times (1): the pawn's RequestApplyTuneSet, else the component's Server_ApplyTuneSet.
-- Returns the name of the call that took it, or nil
function TU.apply(pawn, ts, times)
  times = times or 1
  if try(function() pawn:RequestApplyTuneSet(ts, times); return true end) == true then return 'RequestApplyTuneSet' end
  local comp = TU.component(pawn)
  if comp and try(function() comp:Server_ApplyTuneSet(ts, times); return true end) == true then return 'Server_ApplyTuneSet' end
  return nil
end
-- how many times a set is on a vehicle's component (SetsApplied), or nil when it can't be read
function TU.count(pawn, ts)
  local comp = TU.component(pawn)
  if not comp then return nil end
  local want, n = C.addr(ts), nil
  try(function() comp.SetsApplied:ForEach(function(k, v)
    local key = k:get()
    if alive(key) and C.addr(key) == want then n = tonumber(v:get()) end
  end) end)
  return n
end

return TU
