-- v0.29 (owner: rust for the Junker league): looks.lua at a league with config Looks[league] - the All Rust patina, dirt
-- and the damage look on each car's VehicleMaterialsComponent (found through the pawn's components), twice: once the
-- field is read, again after the start. Challenger (no Looks): nothing.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 3 }, { StartScreen = true, Progression = { On = false },
  Looks = { riffraff = { patina = true, dirt = 1.0, damage = 0.6, field = true, againS = 12 } } }) -- (all three levers; the shipped config has no damage)

-- a VehicleMaterialsComponent on every pawn of the race now; returns the components (yours first)
local function giveComponents()
  local comps = {}
  local players = { W.player }
  for _, b in ipairs(W.bots) do players[#players + 1] = b end
  for i, ps in ipairs(players) do
    local pawn = rawget(ps, '__props').PawnPrivate
    local cst = M.new('cst' .. i, { DebugDirtOverrideValue = -1, damaged = nil })
    rawget(cst, '__props').DebugApplyAllVehicleDamage = function(self, v) rawget(self, '__props').damaged = v end
    local comp = M.new('vmc' .. i, { Dirt = 0, PatinaData = nil, CustomisationComponent = cst, Pawn = pawn, finalised = 0 })
    rawget(comp, '__props').OnVehicleFinalised = function(self) local p = rawget(self, '__props'); p.finalised = p.finalised + 1 end
    rawget(pawn, '__props').K2_GetComponentsByClass = function() return { comp } end
    comps[i] = comp
  end
  return comps
end
local function p(o) return rawget(o, '__props') end

-- Junker: all three levers on every car, twice
M.press('F6'); M.tick(6)
T.clickTitle('JUNKER'); M.tick(3)
T.clickTitle('JAKKU CUP'); M.tick(5)
local mark = T.mark()
T.clickTitle('START'); M.tick(5)
W.zeroSlots = { true, false, true, false, false, true } -- (Junker's parts: Grip, Resilience and Advanced at level 0)
M.resetSweeps()
-- (v0.29.4: in game the All Rust patina isn't in memory until loaded by its package path - v0.29.0-v0.29.3 asked for
-- it by its full object name and never found it: only the dirt showed)
M.unloaded['/Game/Griffin/Vehicles/Common/Liveries/Patinas/LP_AllRust.LP_AllRust'] = true
W.race(11)
local comps = giveComponents()
M.tick(30)
W.zeroSlots = nil
T.check((W.nullNamed or 0) == 0 and T.logHas('[ai] pilot strength (riffraff): ', mark),
  'v0.28.4: Junker pilot strength never names an empty part slot (the crash at every Junker race load) (' .. tostring(W.nullNamed) .. ')')
local me = p(comps[1])
T.check(me.PatinaData and rawget(me.PatinaData, '__name') == 'LP_AllRust' and me.Dirt == 1.0 and p(me.CustomisationComponent).damaged == 0.6
  and p(me.CustomisationComponent).DebugDirtOverrideValue == 1.0 and me.finalised == 1, 'Junker, at load: your car - All Rust, dirt 1, damage 0.6, refreshed')
T.check(p(comps[5]).Dirt == 1.0 and p(comps[5]).PatinaData ~= nil, 'field = true: the AI cars too')
T.check(not T.logHas('All Rust patina not found', mark), 'v0.29.4: the All Rust patina loaded by its package path')
T.check(T.logHas('[looks] at load, 12 of 12 cars: you: patina LP_AllRust, dirt 1', mark), 'logged (' .. tostring(T.logHas('[looks]', mark)) .. ')')
M.tick(100)
T.check(T.logHas('[looks] after the start, 12 of 12 cars', mark) and me.finalised == 2, 'the second pass ~12 s after the launch')
M.tick(100)
T.check(T.logCount('[looks]') == 2, 'two passes only')
T.check(M.sweepCount('FindAllOf VehicleMaterialsComponent') == 0 and M.sweepCount('StaticFindObject /Script/Griffin.VehicleMaterialsComponent') == 2,
  'the components found through each pawn: no fallback sweep, one class lookup a pass (' .. M.sweepCount('VehicleMaterialsComponent') .. ')')
W.backToMenu(); M.tick(45)
M.press('BACKSPACE'); M.tick(3); T.clickTitle('YES'); M.tick(3)

-- Challenger: no Looks entry, nothing
T.clickTitle('CHALLENGER'); M.tick(3)
T.clickTitle('JAKKU CUP'); M.tick(5)
mark = T.mark()
T.clickTitle('START'); M.tick(5)
W.race(11)
comps = giveComponents()
M.tick(200)
T.check(not T.logHas('[looks]', mark) and p(comps[1]).Dirt == 0 and p(comps[1]).PatinaData == nil, 'Challenger: no looks')
T.finish()
