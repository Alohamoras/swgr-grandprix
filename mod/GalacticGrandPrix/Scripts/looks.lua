-- Galactic Grand Prix v0.29 (owner 2026-11-12: "adding some rust to existing models to make them look less good (for
-- the junker class)"; docs/custom-vehicle-models-2026-11-12.md "The cheap alternative"). At a league with
-- config Looks[league]: each car's look roughed up while the race loads, three levers, each its own switch:
--   patina - the game's own All Rust finish (LP_AllRust, the livery system's patinas) on the car's
--            VehicleMaterialsComponent.PatinaData, then the component's OnVehicleFinalised() to re-apply its materials;
--   dirt   - VehicleMaterialsComponent.Dirt (0..1; the race builds dirt up by surface - this starts it high), and the
--            customisation component's DebugDirtOverrideValue;
--   damage - the customisation component's DebugApplyAllVehicleDamage(value): the crash damage look (dents, scratches).
-- Applied twice: once the field is read (the cars exist), and again ~12 s after the launch (after the countdown, in
-- case the start resets anything). Each time: one sweep at most (the components found through each pawn's own
-- component list first; a FindAllOf fallback). Nothing kept between ticks. Unproven in game: whether the patina /
-- debug levers do anything in the shipping build - every apply logs what reads back.
local C = require('core')
local cfg = require('config')
local try, alive, log = C.try, C.alive, C.log

local L = {}
L.RUST = '/GriffinSharedVehicles/Griffin/Vehicles/Common/Liveries/Patinas/LP_AllRust'
L.COMP = '/Script/Griffin.VehicleMaterialsComponent'

-- the looks for a league: { patina = bool, dirt = 0..1, damage = 0..1, field = bool } or nil
function L.forLeague(league)
  local all = cfg.Looks
  if type(all) ~= 'table' or all.On == false then return nil end
  local l = all[tostring(league)]
  return type(l) == 'table' and l or nil
end

-- the materials components of the cars wanted: { comp, who } - you only, or the whole field (look.field)
local function components(look)
  local want, out, seen = {}, {}, {}
  for _, ps in ipairs(C.find('GfnPlayerState')) do
    local you = try(function() return ps.bIsABot end) == false
    if you or look.field then
      local pawn = try(function() return ps.PawnPrivate end)
      if alive(pawn) then want[#want + 1] = { pawn = pawn, who = you and 'you' or (C.text(ps, 'PlayerNamePrivate') or 'bot') } end
    end
  end
  local cls = try(StaticFindObject, L.COMP)
  local missing = {}
  for _, w in ipairs(want) do
    local list = alive(cls) and try(function() return w.pawn:K2_GetComponentsByClass(cls) end)
    -- (a plain Lua list, or a TArray: read by index, at most 16 - never an open-ended iterator over an unknown object)
    local n = 0
    if type(list) == 'table' and getmetatable(list) == nil then n = #list
    elseif list ~= nil then n = tonumber(try(function() return list:GetArrayNum() end)) or 0 end
    local comp
    for i = 1, math.min(n, 16) do
      local c = try(function() return list[i] end)
      if alive(c) then comp = c; break end
    end
    if comp then
      local key = C.addr(comp)
      if not seen[key] then seen[key] = true; out[#out + 1] = { comp = comp, who = w.who } end
    else missing[#missing + 1] = w end
  end
  if #missing > 0 then
    -- (fallback: one sweep of the components, matched to the pawns by their Pawn field)
    local byPawn = {}
    for _, w in ipairs(missing) do local a = C.addr(w.pawn); if a then byPawn[a] = w.who end end
    for _, c in ipairs(C.find('VehicleMaterialsComponent')) do
      local p = try(function() return c.Pawn end)
      local who = alive(p) and byPawn[C.addr(p)]
      if who and not seen[C.addr(c)] then seen[C.addr(c)] = true; out[#out + 1] = { comp = c, who = who } end
    end
  end
  return out, #want
end

-- one pass over the cars: returns the log text
function L.apply(look, pass)
  local rust = look.patina and C.asset(L.RUST) or nil
  if look.patina and not rust then log('[looks] All Rust patina not found: ' .. L.RUST) end
  local comps, wanted = components(look)
  local parts = {}
  for _, e in ipairs(comps) do
    local c, did = e.comp, {}
    if rust then
      pcall(function() c.PatinaData = rust end)
      local now = try(function() return c.PatinaData end)
      did[#did + 1] = 'patina ' .. (alive(now) and C.idname(now) or '?')
    end
    local cst = try(function() return c.CustomisationComponent end)
    if tonumber(look.dirt) then
      pcall(function() c.Dirt = look.dirt end)
      if alive(cst) then pcall(function() cst.DebugDirtOverrideValue = look.dirt end) end
      did[#did + 1] = ('dirt %s'):format(tostring(try(function() return c.Dirt end)))
    end
    if rust or tonumber(look.dirt) then
      local ok = pcall(function() c:OnVehicleFinalised() end)
      did[#did + 1] = ok and 'refreshed' or 'refresh failed'
    end
    if tonumber(look.damage) then
      local ok = alive(cst) and pcall(function() cst:DebugApplyAllVehicleDamage(look.damage) end)
      did[#did + 1] = ('damage %s%s'):format(tostring(look.damage), ok and '' or ' (no customisation component)')
    end
    parts[#parts + 1] = e.who .. ': ' .. table.concat(did, ', ')
  end
  local txt = ('[looks] %s, %d of %d cars: %s'):format(pass, #comps, wanted, #parts > 0 and table.concat(parts, '; ') or 'none found')
  log(txt)
  return txt
end

-- every tick of a race (race.lua R.watch), cheap until a pass is due: r.looks = { look, done1, done2 }
function L.tick(r)
  local st = r.looks
  if not st or st.done2 then return end
  if not st.done1 then
    if not r.fieldLogged then return end
    st.done1 = true
    pcall(L.apply, st.look, 'at load')
    return
  end
  if C.clock - r.at >= (tonumber(st.look.againS) or 12) * 1000 then
    st.done2 = true
    pcall(L.apply, st.look, 'after the start')
  end
end

return L
