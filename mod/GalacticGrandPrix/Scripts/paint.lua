-- A pilot's own vehicle is already theirs (Sebulba's Rook, Nik's Hammerhead Quiet Strength). The other two
-- categories launch the shared base build, which has no preset. Each rider has a scheme for those two:
-- a style (ace, enforcer, raider, vintage, robotic) and a finish (paint, rust, steel), on a preset that
-- actually exists for that body. It is written onto the racer before the race is built, the same place the
-- game already reads for their own vehicle (PreferredCustomisationForVehicleArchetype). It is taken off
-- again at the menu. Never applied once the world is loading: SetActiveVehicleRecipeFromPreset there went
-- to a black screen and crashed (2026-11-22 23:57:58).
local C = require('core')
local try, alive, log = C.try, C.alive, C.log

local P = {}
local ROOT = '/GriffinSharedVehicles/Griffin/Vehicles/'
-- v0.31: what to take off again is in the save first (K.data.paintRestore = { path, arch, name }), like the part
-- levels and the grid: a crash mid-race is put right at the next boot's menu (race.lua R.restoreBuild).
local K = require('gp')

local function pre(kind, name)
  local folder = (kind == 'car' and 'Cars') or (kind == 'bike' and 'Bikes') or 'Skimmers'
  return ROOT .. folder .. '/Presets/Shakedown/' .. name
end

-- the two vehicles that are not this pilot's own. The preferred category is absent on purpose.
local SCHEME = {
  DarkEnigma          = { bike = pre('bike', 'PRE_Bike_Lancehead_Robotic02_Robotic03Colour_AllSteel'),
                          skimmer = pre('skimmer', 'PRE_Skimmer_Jackdaw_Robotic02_Robotic02Colour_AllSteel') },
  Protege             = { bike = pre('bike', 'PRE_Bike_Taipan_Ace02_Ace02Colour_AllRust'),
                          skimmer = pre('skimmer', 'PRE_Skimmer_Merlin_Ace02_Ace02Colour_AllRust') },
  QuietStrength       = { bike = pre('bike', 'PRE_Bike_Sidewinder_Enforcer01_Enforcer01Colour_AllPaint'),
                          skimmer = pre('skimmer', 'PRE_Skimmer_Saker_Enforcer01_Enforcer01Colour_AllPaint') },
  Veteran             = { car = pre('car', 'PRE_Car_Bowhead_Enforcer02_Enforcer03Colour_AllPaint'),
                          bike = pre('bike', 'PRE_Bike_Hognose_Enforcer03_Enforcer02Colour_AllPaint') },
  Ghost               = { car = pre('car', 'PRE_Car_Orca_Robotic01_Robotic01Colour_AllPaint'),
                          bike = pre('bike', 'PRE_Bike_Kingsnake_Robotic02_Robotic02Colour_AllPaint') },
  InnerHonour         = { bike = pre('bike', 'PRE_Bike_Bushmaster_Raider02_Raider02Colour_AllPaint'),
                          skimmer = pre('skimmer', 'PRE_Skimmer_Albatross_Raider02_Raider02Colour_AllPaint') },
  Nomad               = { car = pre('car', 'PRE_Car_Minke_Vintage02_Vintage03Colour_AllPaint'),
                          bike = pre('bike', 'PRE_Bike_Cobra_Vintage03_Vintage02Colour_AllPaint') },
  ElegantProfessional = { car = pre('car', 'PRE_Car_Tarpon_Vintage02_Vintage02Colour_AllPaint'),
                          skimmer = pre('skimmer', 'PRE_Skimmer_Needletail_Vintage02_Vintage03Colour_AllPaint') },
  Thrall              = { car = pre('car', 'PRE_Car_Mako_Enforcer02_Enforcer02Colour_AllRust'),
                          skimmer = pre('skimmer', 'PRE_Skimmer_Stork_Enforcer02_Enforcer03Colour_AllRust') },
  Rager               = { car = pre('car', 'PRE_Car_Beluga_Ace02_Ace03Colour_AllRust'),
                          skimmer = pre('skimmer', 'PRE_Skimmer_Peregrine_Ace03_Ace02Colour_AllRust') },
  Mentor              = { car = pre('car', 'PRE_Car_Minke_Vintage02_Vintage02Colour_AllSteel'),
                          bike = pre('bike', 'PRE_Bike_Cobra_Vintage02_Vintage03Colour_AllSteel') },
  Antagonist          = { bike = pre('bike', 'PRE_Bike_Cottonmouth_Ace03_Ace03Colour_AllPaint'),
                          skimmer = pre('skimmer', 'PRE_Skimmer_Peregrine_Ace03_Ace03Colour_AllPaint') },
  Mercenary           = { car = pre('car', 'PRE_Car_Bluefin_Raider03_Raider02Colour_AllRust'),
                          skimmer = pre('skimmer', 'PRE_Skimmer_Albatross_Raider03_Raider02Colour_AllRust') },
  Star                = { car = pre('car', 'PRE_Car_Beluga_Ace02_Ace02Colour_AllPaint'),
                          bike = pre('bike', 'PRE_Bike_Cottonmouth_Ace02_Ace02Colour_AllPaint') },
}

P.scheme = SCHEME

-- the preset's class (the map holds TSubclassOf<UCstVehiclePresetRecipe>): found, else loaded by its package path
-- (v0.31: LoadAsset wants the package path, core.lua v0.29.4 - the full object name loaded nothing)
local function loadPreset(path)
  local name = path:match('([^/]+)$')
  local names = { path .. '.' .. name .. '_C', path .. '.' .. name }
  for _, full in ipairs(names) do
    local o = try(StaticFindObject, full)
    if alive(o) then return o end
  end
  try(LoadAsset, path)
  for _, full in ipairs(names) do
    local o = try(StaticFindObject, full)
    if alive(o) then return o end
  end
  return nil
end

local function unwrap(x)
  if x == nil then return nil end
  local g = try(function() return x:get() end)
  if alive(g) then return g end
  if alive(x) then return x end
  return nil
end
local function keyNum(k)
  local n = tonumber(k)
  if n then return n end
  local g = try(function() return k:get() end)
  n = tonumber(g)
  if n then return n end
  if g ~= nil then n = tonumber(try(function() return g.archetype end)) end
  return n
end
local function customs(def)
  local map = try(function() return def.PreferredCustomisationForVehicleArchetype end)
  if map == nil then return nil, 'no customisation map' end
  local list, why = {}, nil
  local ok, err = pcall(function()
    map:ForEach(function(k, v)
      local obj = unwrap(v)
      if alive(obj) then list[#list + 1] = { arch = keyNum(k), name = C.idname(obj) } end
    end)
  end)
  if not ok then why = tostring(err) end
  return list, why
end

-- before LaunchQuickRace (race.lua prepare, after the pilot is set). Their own category is left alone.
function P.arm(racerKey, vehKey)
  local RC = require('racer')
  local pref = RC.vehicle(racerKey)
  if not pref or pref.key == vehKey then return end
  local who = RC.displayName(racerKey)
  local path = SCHEME[racerKey] and SCHEME[racerKey][vehKey]
  if not path then log('[paint] ' .. who .. ': no scheme for ' .. tostring(vehKey)); return end
  local veh = require('gp').vehicle(vehKey)
  local arch = veh and veh.arch
  if arch == nil then log('[paint] ' .. who .. ': no archetype for ' .. tostring(vehKey)); return end
  local preset = loadPreset(path)
  if not alive(preset) then log('[paint] ' .. who .. ': preset not loaded: ' .. path); return end
  local def = C.asset(RC.path(racerKey))
  if not alive(def) then log('[paint] ' .. who .. ': racer not loaded'); return end
  local list, why = customs(def)
  if why or not list then log('[paint] ' .. who .. ': ' .. tostring(why or 'no customisation map')); return end
  for _, e in ipairs(list) do
    if e.arch == arch then
      log(('[paint] %s %s: already %s'):format(who, vehKey, e.name or '?'))
      return
    end
  end
  local map = try(function() return def.PreferredCustomisationForVehicleArchetype end)
  -- the put-back record first (save), then the change
  K.data.paintRestore = { path = RC.path(racerKey), arch = arch, name = C.idname(preset) }
  K.save()
  local ok, err = pcall(function() map:Add(arch, preset) end)
  if not ok then
    K.data.paintRestore = nil; K.save()
    log('[paint] ' .. who .. ': the racer refused the scheme (' .. tostring(err) .. ')'); return
  end
  local got
  for _, e in ipairs(customs(def) or {}) do if e.arch == arch then got = e end end
  if not got then K.data.paintRestore = nil; K.save(); log('[paint] ' .. who .. ': the scheme did not stay on the racer'); return end
  K.data.paintRestore.name = got.name
  K.save()
  log(('[paint] %s %s: %s, before the race'):format(who, vehKey, got.name))
end

-- at the menu (race.lua restoreBuild; after a crash, at the next boot's menu from the save). Only the key we added,
-- and only while it is still ours.
function P.restore(why)
  local rec = K.data.paintRestore
  if type(rec) ~= 'table' then return end
  K.data.paintRestore = nil
  K.save()
  local def = C.asset(rec.path)
  local map = alive(def) and try(function() return def.PreferredCustomisationForVehicleArchetype end)
  if map == nil then log('[paint] put back (' .. tostring(why) .. '): racer map not found'); return end
  local cur
  for _, e in ipairs(customs(def) or {}) do if e.arch == rec.arch then cur = e end end
  if not cur or cur.name ~= rec.name then log(('[paint] put back (%s): %s not on the racer any more'):format(tostring(why), tostring(rec.name))); return end
  local ok, err = pcall(function() map:Remove(rec.arch) end)
  log(('[paint] put back (%s): %s%s'):format(tostring(why), rec.name, ok and '' or (' FAILED ' .. tostring(err))))
end

return P
