-- LookSpike (test-only, 2026-11-11, TASKS.md B7): does a racer's own preset go on YOUR vehicle in a race?
-- 1. At start: logs PreferredVehicleType (a plain enum byte) of every racer def (14 known codenames).
-- 2. In a race: once your pawn exists, puts Look (below) on it: first the player state's override recipe
--    (Client_SetOverrideVehicleRecipe), then, if that didn't take, the pawn's customisation component
--    (SetActiveVehicleRecipeFromPreset). Logs what it wears before and after. Memory only.
-- House rules: LoopInGameThreadWithDelay only, no hooks, no soft pointers read, no UObjects kept between ticks
-- (the preset class/CDO are default objects of a loaded asset: looked up again by path each time).
local LOOK = '/GriffinSharedVehicles/Griffin/Vehicles/Bikes/Presets/PRE_Bike_Sidewinder_Rager'
local here = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
local dir = (here:match('^(.*)[/\\][^/\\]+$') or '.'):match('^(.*)[/\\][Ss]cripts$') or '.'
local LOGF = io.open(dir .. '/lookspike.log', 'a')
local function log(s)
  local line = os.date('%Y-%m-%d %H:%M:%S ') .. s
  print('[LookSpike] ' .. s .. '\n')
  if LOGF then LOGF:write(line .. '\n'); LOGF:flush() end
end
local function try(f) local ok, r = pcall(f); if ok then return r end end
local function alive(o) return o ~= nil and try(function() return o:IsValid() end) == true end
local function rname(r) return try(function() return r.RecipeName:ToString() end) or '?' end

log('LookSpike loaded; look = ' .. LOOK)
local CODES = { 'DarkEnigma', 'Protege', 'Mercenary', 'QuietStrength', 'Veteran', 'Ghost', 'InnerHonour', 'Nomad',
  'ElegantProfessional', 'Thrall', 'Rager', 'Star', 'Mentor', 'Antagonist' }
local ARCH = { [0] = 'Car', [1] = 'Plane', [2] = 'Bike', [3] = 'Skimmer' }
local readTypes = false

local function preset()
  local short = LOOK:match('([^/]+)$')
  local clsPath = LOOK .. '.' .. short .. '_C'
  local cls = try(function() return StaticFindObject(clsPath) end)
  if not alive(cls) then try(function() return LoadAsset(LOOK) end); cls = try(function() return StaticFindObject(clsPath) end) end
  if not alive(cls) then return nil end
  local cdo = try(function() return StaticFindObject(LOOK .. '.Default__' .. short .. '_C') end)
  if not alive(cdo) then cdo = try(function() return cls:GetCDO() end) end
  return cls, cdo
end
local function cst(pawn)
  local cc = try(function() return StaticFindObject('/Script/Griffin.CstCustomisationComponent') end)
  if not alive(cc) then return nil end
  local found
  local comps = try(function() return pawn:K2_GetComponentsByClass(cc) end)
  if comps then try(function() comps:ForEach(function(_, c) local o = c:get(); if not found and alive(o) then found = o end end) end) end
  return found
end
local function wears(pawn)
  local c = cst(pawn); local r = c and try(function() return c.ActiveRecipe end)
  return alive(r) and rname(r) or nil
end

local job -- { pawn = full name, step, at }
local t = 0
LoopInGameThreadWithDelay(1000, function()
  t = t + 1
  if not readTypes and t >= 5 then
    readTypes = true
    local out = {}
    for _, k in ipairs(CODES) do
      local p = '/Game/Griffin/Narrative/CharacterDefs/Racers/DA_Racer_' .. k
      local d = try(function() return StaticFindObject(p .. '.DA_Racer_' .. k) end)
      if not alive(d) then try(function() return LoadAsset(p) end); d = try(function() return StaticFindObject(p .. '.DA_Racer_' .. k) end) end
      local v = alive(d) and try(function() return d.PreferredVehicleType end)
      out[#out + 1] = k .. '=' .. (v ~= nil and (ARCH[tonumber(v)] or tostring(v)) or '?')
    end
    log('PreferredVehicleType: ' .. table.concat(out, ' '))
  end
  if t % 2 ~= 0 then return end -- one player-state sweep every 2 s
  local ps, pawn
  for _, s in ipairs(FindAllOf('GfnPlayerState') or {}) do
    if alive(s) and try(function() return s.bIsABot end) == false then ps = s; pawn = try(function() return s.PawnPrivate end) end
  end
  if not alive(pawn) then if job then job = nil end return end
  local name = try(function() return pawn:GetFullName() end) or '?'
  if not job or job.pawn ~= name then
    local arch = try(function() return pawn:GetVehicleArchetype() end)
    job = { pawn = name, step = 0, at = t }
    log('your vehicle: ' .. name:sub(1, 120) .. ' archetype ' .. tostring(arch and ARCH[tonumber(arch)]))
    return
  end
  if job.step >= 3 or t - job.at < 4 then return end
  local cls, cdo = preset()
  if not alive(cls) then log('preset did not load: ' .. LOOK); job.step = 3; return end
  local want = rname(cdo)
  if job.step == 0 then
    log('wears "' .. tostring(wears(pawn)) .. '"; want "' .. want .. '"')
    local vc = try(function() return ps.VehicleCustomisationComponent end)
    log('override recipe: ' .. ((alive(vc) and pcall(function() vc:Client_SetOverrideVehicleRecipe(cls) end)) and 'sent' or 'FAILED'))
    job.step, job.at = 1, t
  elseif job.step == 1 then
    local w = wears(pawn)
    if w == want then log('ON via override recipe: ' .. w); job.step = 3; return end
    local c = cst(pawn)
    log('still "' .. tostring(w) .. '"; preset on the component: ' .. ((alive(c) and pcall(function() c:SetActiveVehicleRecipeFromPreset(cdo) end)) and 'sent' or 'FAILED'))
    job.step, job.at = 2, t
  elseif job.step == 2 then
    log('after the component call: wears "' .. tostring(wears(pawn)) .. '"')
    job.step = 3
  end
end)
