-- LookSpike v2 (test-only, 2026-11-11, TASKS.md B7): can YOUR vehicle wear a racer's own preset look (parts AND
-- livery colours) in a Grand Prix race? Report only: nothing here goes into the Grand Prix mod. See README.md.
--
-- v1 (2026-11-11 morning) sent Client_SetOverrideVehicleRecipe after the pawn existed and never found the pawn's
-- CstCustomisationComponent (K2_GetComponentsByClass gave nothing), so the effect was unproven. v2 tries three routes,
-- one plan entry per race (PLAN below), and reads the look back after each:
--   C  race recipe: your entry in EventRecipeSubsystem.ActiveRecipe.RecipeState.Racers[] gets VehicleCustomisation =
--      the preset class (a plain TSubclassOf pointer) while the race loads, before your vehicle is built.
--   A  FreeRace's route: PlayerVehicleCustomisationComponent:Server_UpdateVehicleRecipe(FCstSavedVehicleRecipeData),
--      the struct built field by field from the preset's default object (same fields as UCstVehiclePresetRecipe).
--   O  v1's call, but at load: Client_SetOverrideVehicleRecipe(presetClass) before the vehicle is built.
--   B  the vehicle itself: its CstCustomisationComponent found another way (all its components by class name, a
--      presentation component's CustomisationComponent, or one FindAllOf filtered to your pawn), then
--      SetActiveVehicleRecipeFromPreset(presetCDO).
-- A later route in the same race runs only if the look isn't on yet. Everything is put back at the next main menu.
--
-- House rules: LoopInGameThreadWithDelay only, no RegisterHook (NotifyOnNewObject callbacks only set a flag), no soft
-- pointers / TMaps read, no UObject kept between ticks (path + address, looked up again), every engine call in pcall,
-- a handful of lookups per race (each is a ~10 ms sweep), none per tick once the race runs.

---------------------------------------------------------------------------------------------------------------------
-- CONFIG
local CONFIG = {
  -- the look to put on your vehicle (must be your vehicle's type: a Car preset for the landspeeder). Nik Skandaro's:
  PRESET = '/GriffinSharedVehicles/Griffin/Vehicles/Cars/Presets/PRE_Car_Hammerhead_QuietStrength',
  -- one entry per race since the game started: race 1 tries C, race 2 B, race 3 A, race 4 O. An entry may list
  -- several routes ('C,B'; 'load' routes first): they run in that order, a later one only if the read-back of the
  -- earlier one didn't find the look on. One route per race tells which one did it. After the list: nothing is tried.
  PLAN = { 'C', 'B', 'A', 'O' },
  -- when each route runs: 'load' = as soon as the race world appears (before your vehicle is built), 'after' =
  -- AFTER_S seconds after your vehicle first shows up. B needs a vehicle: 'load' is treated as 'after' with 0 s.
  WHEN = { C = 'load', A = 'load', O = 'load', B = 'after' },
  AFTER_S = 4,
  -- 'load': if the race's data isn't there yet, look again this many times, one tick (250 ms) apart, then give up
  LOAD_RETRIES = 12,
  CHECK_S = 3,       -- read the look back this long after each route
  SURVIVE_S = 25,    -- and once more this long after your vehicle showed up (after the countdown: did it stay?)
  B_REFRESH = false, -- B: also call RefreshRecipe() after SetActiveVehicleRecipeFromPreset
}
local VERSION = 'v2.0'
---------------------------------------------------------------------------------------------------------------------

local here = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
local dir = (here:match('^(.*)[/\\][^/\\]+$') or '.'):match('^(.*)[/\\][Ss]cripts$') or '.'
local LOGF = io.open(dir .. '/lookspike.log', 'a')
local function log(s)
  print('[LookSpike] ' .. s .. '\n')
  if LOGF then LOGF:write(os.date('%Y-%m-%d %H:%M:%S ') .. s .. '\n'); LOGF:flush() end
end
local function try(f, ...) local ok, r = pcall(f, ...); if ok then return r end end
local function alive(o) return o ~= nil and try(function() return o:IsValid() end) == true end
local function addr(o) return alive(o) and try(function() return o:GetAddress() end) or nil end
local function oname(o) return alive(o) and (try(function() return o:GetFName():ToString() end) or '?') or 'none' end
local function cname(o) return alive(o) and (try(function() return o:GetClass():GetFName():ToString() end) or '?') or 'none' end
local function full(o) return alive(o) and (try(function() return o:GetFullName() end) or '?') or 'none' end
local function rname(r) return alive(r) and (try(function() return r.RecipeName:ToString() end) or '?') or nil end
local function ref(o) -- path + address (never the object itself)
  local f = full(o); local p = f:match('^%S+%s+(.+)$'); local a = addr(o)
  return (p and a) and { path = p, addr = a } or nil
end
local function deref(r)
  if not r then return nil end
  local o = try(StaticFindObject, r.path)
  return (alive(o) and addr(o) == r.addr) and o or nil
end
local ARCH = { [0] = 'Car', [1] = 'Plane', [2] = 'Bike', [3] = 'Skimmer' }

log(('LookSpike %s loaded; preset %s; plan %s'):format(VERSION, CONFIG.PRESET, table.concat(CONFIG.PLAN, ' | ')))

-- the preset: its class and default object, found by path each time (a sweep), loaded once if missing
local function preset()
  local short = CONFIG.PRESET:match('([^/]+)$')
  local clsPath = CONFIG.PRESET .. '.' .. short .. '_C'
  local cls = try(StaticFindObject, clsPath)
  if not alive(cls) then try(LoadAsset, CONFIG.PRESET); cls = try(StaticFindObject, clsPath) end
  if not alive(cls) then return nil end
  local cdo = try(StaticFindObject, CONFIG.PRESET .. '.Default__' .. short .. '_C')
  if not alive(cdo) then cdo = try(function() return cls:GetCDO() end) end
  if not alive(cdo) then return nil end
  return cls, cdo
end

-- you: the player state that isn't a bot (one sweep), its vehicle and its customisation component
local function you()
  for _, s in ipairs(try(FindAllOf, 'GfnPlayerState') or {}) do
    if alive(s) and try(function() return s.bIsABot end) == false then
      local pawn = try(function() return s.PawnPrivate end)
      return s, alive(pawn) and pawn or nil
    end
  end
end
local function psRecipe(ps) -- what your player state's customisation component holds (ACstVehicleRecipe actor)
  local vc = try(function() return ps.VehicleCustomisationComponent end)
  if not alive(vc) then return 'no VehicleCustomisationComponent' end
  local vr = try(function() return vc.VehicleRecipe end)
  if not alive(vr) then return 'none' end
  local units = try(function() return vr.UnitRecipes:GetArrayNum() end)
  return ('"%s" (%s, %s units)'):format(tostring(rname(vr)), oname(vr), tostring(units))
end

-- B's finder. Returns the component and how it was found. diag = log what was looked at (first time per race).
local function cstOf(pawn, diag, allowSweep)
  local pawnName = oname(pawn)
  local seen, viaPres = {}, nil
  local acomp = try(StaticFindObject, '/Script/Engine.ActorComponent')
  local comps = alive(acomp) and try(function() return pawn:K2_GetComponentsByClass(acomp) end)
  local found
  if comps then
    try(function() comps:ForEach(function(_, c)
      local o = c:get()
      if alive(o) then
        local cn = cname(o)
        seen[#seen + 1] = cn
        if not found and cn:find('CstCustomisationComponent') then found = o end
        if not viaPres and cn:find('PresentationComponent') then
          local cc = try(function() return o.CustomisationComponent end)
          if alive(cc) then viaPres = cc end
        end
      end
    end) end)
  end
  if diag then log(('B: %s has %d components: %s'):format(pawnName, #seen, table.concat(seen, ', '):sub(1, 900))) end
  if found then return found, 'own component' end
  if viaPres then return viaPres, 'presentation component' end
  if not allowSweep then return nil, 'not on the vehicle' end
  -- one sweep of every customisation component, kept only if it belongs to your vehicle
  local pa, all, pick = addr(pawn), try(FindAllOf, 'CstCustomisationComponent') or {}, nil
  for i, c in ipairs(all) do
    if alive(c) then
      local owner = try(function() return c:GetOwner() end)
      local up = alive(owner) and try(function() return owner.Owner end)
      local att = alive(owner) and try(function() return owner:GetAttachParentActor() end)
      local mine = (addr(owner) == pa) or (addr(up) == pa) or (addr(att) == pa)
        or (full(c):find('%.' .. pawnName:gsub('%p', '%%%0') .. '%.') ~= nil)
      if diag and i <= 16 then
        log(('B: CstCustomisationComponent %d/%d %s owner %s (%s)%s'):format(i, #all, oname(c), oname(owner), cname(owner),
          mine and '  <- yours' or ''))
      end
      if mine and not pick then pick = c end
    end
  end
  if diag and #all == 0 then log('B: FindAllOf(CstCustomisationComponent) found none') end
  return pick, pick and 'FindAllOf, owner = your vehicle' or 'not found'
end
local function wears(pawn, allowSweep)
  local c = alive(pawn) and cstOf(pawn, false, allowSweep)
  local r = alive(c) and try(function() return c.ActiveRecipe end)
  return alive(r) and rname(r) or nil
end

-- the race's recipe (EventRecipeSubsystem.ActiveRecipe), your entry in RecipeState.Racers[] (1-based) or nil
local function raceRecipe(diag)
  local sub = try(FindFirstOf, 'EventRecipeSubsystem')
  local inst = alive(sub) and try(function() return sub.ActiveRecipe end)
  if not alive(inst) then return nil, nil, 'no active recipe' end
  local racers = try(function() return inst.RecipeState.Racers end)
  local n = racers and try(function() return racers:GetArrayNum() end) or 0
  local mine, lines = nil, {}
  for i = 1, n do
    local e = racers[i]
    local p = try(function() return e.Player end)
    local bot = alive(p) and try(function() return p.bIsABot end)
    local cust = try(function() return e.VehicleCustomisation end)
    lines[#lines + 1] = ('%d:%s/%s/%s%s'):format(i, oname(try(function() return e.Pilot end)),
      ARCH[tonumber(try(function() return e.vehicleType end) or -1)] or '?', oname(cust), bot == false and '*' or '')
    if bot == false and not mine then mine = i end
  end
  if diag then log(('C: race recipe %s, %d racers (* = you): %s'):format(oname(inst), n, table.concat(lines, ' '))) end
  return inst, mine, n == 0 and 'no racers yet' or (mine and 'ok' or 'your entry has no player yet')
end

-- CstSubsystem.VehicleRecipeDatas (the cloud-saved CUSTOMIZE recipes): names only, to prove A didn't change them
local function savedRecipes()
  local sub = try(FindFirstOf, 'CstSubsystem')
  if not alive(sub) then return 'no CstSubsystem' end
  local out = {}
  try(function() sub.VehicleRecipeDatas:ForEach(function(_, r)
    local d = r:get()
    out[#out + 1] = ('%s=%s'):format(ARCH[tonumber(try(function() return d.VehicleArchetype end) or -1)] or '?',
      try(function() return d.RecipeName:ToString() end) or '?')
  end) end)
  return #out > 0 and table.concat(out, ', ') or 'none'
end

-- A's struct: FCstSavedVehicleRecipeData, field by field from the preset's default object
local function tag(t) return { TagName = try(function() return t.TagName end) } end
local function savedFromPreset(cdo)
  local units, parts = {}, 0
  local ok = pcall(function() cdo.UnitRecipes:ForEach(function(_, u)
    local unit = u:get()
    local list = {}
    unit.Parts:ForEach(function(_, p)
      local part = p:get()
      list[#list + 1] = { ParentPartType = part.ParentPartType, PartType = part.PartType, vehicleKit = part.vehicleKit }
    end)
    parts = parts + #list
    local jelly = unit.JellyConfiguration
    units[#units + 1] = { UnitName = unit.UnitName, VehicleArchetype = unit.VehicleArchetype, Parts = list,
      JellyConfiguration = alive(jelly) and jelly or nil }
  end) end)
  if not ok or #units == 0 then return nil, 'could not read the preset units' end
  local phys = try(function() return cdo.RootPhysicsConfiguration end)
  local s = {
    RecipeName = rname(cdo) or '',
    VehicleArchetype = cdo.VehicleArchetype,
    UnitLayoutName = cdo.UnitLayoutName,
    UnitRecipes = units,
    RootPhysicsConfiguration = alive(phys) and phys or nil,
    LiveryPaletteTag = tag(cdo.LiveryPaletteTag), LiveryMaskTag = tag(cdo.LiveryMaskTag),
    IconPaletteTag = tag(cdo.IconPaletteTag), IconMaskTag = tag(cdo.IconMaskTag), PatinaTag = tag(cdo.PatinaTag),
  }
  local function t(x) return try(function() return x.TagName:ToString() end) or '?' end
  return s, ('%d units, %d parts, layout %s, livery %s / %s, icon %s / %s, patina %s'):format(#units, parts,
    try(function() return cdo.UnitLayoutName:ToString() end) or '?', t(cdo.LiveryPaletteTag), t(cdo.LiveryMaskTag),
    t(cdo.IconPaletteTag), t(cdo.IconMaskTag), t(cdo.PatinaTag))
end

---------------------------------------------------------------------------------------------------------------------
-- the routes. Each returns true once it has acted (or given up for good), false to be tried again (load retries).
local undo = nil   -- C's put-back: { inst = ref, index, orig = class path or nil }
local savedBefore = nil

-- the load routes run before your vehicle exists: your entry's vehicleType in the race recipe must match the preset's
-- archetype first (true / false / nil = not known yet). Read once (a sweep), kept as a number.
local function typeOk(job)
  if job.vt == nil then
    local inst, i = raceRecipe(false)
    if i then job.vt = tonumber(try(function() return inst.RecipeState.Racers[i].vehicleType end) or -1) end
  end
  if job.vt == nil then return nil end
  if job.vt ~= job.parch and not job.typeLogged then
    job.typeLogged = true
    log(('STOP: the preset is a %s look, your entry in the race is a %s'):format(ARCH[job.parch] or '?', ARCH[job.vt] or '?'))
  end
  return job.vt == job.parch
end

local R = {}
function R.C(r, job)
  local cls = preset()
  if not alive(cls) then log('C: preset not loaded'); return true end
  local inst, i, why = raceRecipe(r.tries == 0 or r.tries == CONFIG.LOAD_RETRIES)
  if not i then
    if r.tries < CONFIG.LOAD_RETRIES then return false end
    log('C: gave up: ' .. why); return true
  end
  if typeOk(job) == false then return true end
  local e = inst.RecipeState.Racers[i]
  local orig = try(function() return e.VehicleCustomisation end)
  local origPath = alive(orig) and full(orig):match('^%S+%s+(.+)$') or nil
  local ok, err = pcall(function() inst.RecipeState.Racers[i].VehicleCustomisation = cls end)
  local now = try(function() return inst.RecipeState.Racers[i].VehicleCustomisation end)
  log(('C: your entry %d VehicleCustomisation %s -> %s: %s, reads back %s'):format(i, oname(orig), oname(cls),
    ok and 'written' or ('FAILED ' .. tostring(err)), oname(now)))
  if ok then undo = { inst = ref(inst), index = i, orig = origPath } end
  local _, pawn = you()
  log('C: your vehicle exists already at the write: ' .. tostring(pawn ~= nil) .. ' (yes = the write may be too late)')
  return true
end
-- 'go', 'wait' (not known yet, retries left) or 'stop'
local function gate(name, r, job)
  local ok = typeOk(job)
  if ok == true then return 'go' end
  if ok == false then return 'stop' end
  if r.tries < CONFIG.LOAD_RETRIES then return 'wait' end
  log(name .. ': skipped: your vehicle type is not known (race recipe not read)')
  return 'stop'
end
function R.A(r, job)
  local _, cdo = preset()
  if not alive(cdo) then log('A: preset not loaded'); return true end
  local g = gate('A', r, job); if g ~= 'go' then return g == 'stop' end
  local ps = you()
  local vc = alive(ps) and try(function() return ps.VehicleCustomisationComponent end)
  if not alive(vc) then
    if r.tries < CONFIG.LOAD_RETRIES then return false end
    log('A: gave up: no player state / VehicleCustomisationComponent'); return true
  end
  savedBefore = savedBefore or savedRecipes()
  log('A: saved CUSTOMIZE recipes before: ' .. savedBefore)
  local s, what = savedFromPreset(cdo)
  if not s then log('A: ' .. what); return true end
  log(('A: player state holds %s; sending "%s" (%s)'):format(psRecipe(ps), s.RecipeName, what))
  local ok, err = pcall(function() vc:Server_UpdateVehicleRecipe(s) end)
  log('A: Server_UpdateVehicleRecipe ' .. (ok and 'sent' or ('FAILED ' .. tostring(err))) .. '; player state now holds ' .. psRecipe(ps))
  return true
end
function R.O(r, job)
  local cls = preset()
  if not alive(cls) then log('O: preset not loaded'); return true end
  local g = gate('O', r, job); if g ~= 'go' then return g == 'stop' end
  local ps, pawn = you()
  local vc = alive(ps) and try(function() return ps.VehicleCustomisationComponent end)
  if not alive(vc) then
    if r.tries < CONFIG.LOAD_RETRIES then return false end
    log('O: gave up: no VehicleCustomisationComponent'); return true
  end
  savedBefore = savedBefore or savedRecipes()
  local ok, err = pcall(function() vc:Client_SetOverrideVehicleRecipe(cls) end)
  log(('O: Client_SetOverrideVehicleRecipe(%s) %s (vehicle built already: %s); player state now holds %s'):format(
    oname(cls), ok and 'sent' or ('FAILED ' .. tostring(err)), tostring(pawn ~= nil), psRecipe(ps)))
  return true
end
function R.B(r, job)
  local _, cdo = preset()
  if not alive(cdo) then log('B: preset not loaded'); return true end
  local _, pawn = you()
  if not alive(pawn) then log('B: no vehicle'); return true end
  local c, how = cstOf(pawn, true, true)
  if not alive(c) then log('B: customisation component ' .. how); return true end
  log(('B: component %s (%s, %s) wears "%s"'):format(oname(c), cname(c), how,
    tostring(rname(try(function() return c.ActiveRecipe end)))))
  local ok, err = pcall(function() c:SetActiveVehicleRecipeFromPreset(cdo) end)
  log('B: SetActiveVehicleRecipeFromPreset ' .. (ok and 'sent' or ('FAILED ' .. tostring(err))))
  if ok and CONFIG.B_REFRESH then
    local ok2, err2 = pcall(function() c:RefreshRecipe() end)
    log('B: RefreshRecipe ' .. (ok2 and 'sent' or ('FAILED ' .. tostring(err2))))
  end
  log('B: now wears "' .. tostring(rname(try(function() return c.ActiveRecipe end))) .. '"')
  return true
end

-- the read-back after each route: what your player state and your vehicle hold (one sweep or two)
local function readBack(job, label)
  local ps, pawn = you()
  local w = alive(pawn) and wears(pawn, true) or nil
  log(('check (%s): player state holds %s; vehicle %s wears "%s" (want "%s") -> %s'):format(label,
    alive(ps) and psRecipe(ps) or 'no player state', oname(pawn), tostring(w), job.want,
    w == job.want and 'ON' or (w and 'not on' or 'unknown')))
  if w == job.want then job.on = true end
end

---------------------------------------------------------------------------------------------------------------------
-- put back at the main menu
local function putBack()
  if undo then
    local inst = deref(undo.inst)
    if not inst then
      log('put back: C: the race recipe is gone (freed with the race); nothing to put back')
    else
      local val
      if undo.orig then val = try(StaticFindObject, undo.orig); if not alive(val) then val = nil end
      else val = CreateInvalidObject() end
      if val == nil then
        log('put back: C: the original class ' .. undo.orig .. ' was not found; left as is')
      else
        local ok = pcall(function() inst.RecipeState.Racers[undo.index].VehicleCustomisation = val end)
        local now = try(function() return inst.RecipeState.Racers[undo.index].VehicleCustomisation end)
        log(('put back: C: entry %d VehicleCustomisation -> %s: %s, reads back %s'):format(undo.index,
          undo.orig or 'empty', ok and 'done' or 'FAILED', oname(now)))
      end
    end
    undo = nil
  end
  if savedBefore then
    local now = savedRecipes()
    log('put back: A/O: nothing to undo (your player state went with the race world); saved CUSTOMIZE recipes now: ' .. now
      .. (now == savedBefore and ' (unchanged)' or ('  WARNING: CHANGED, was ' .. savedBefore)))
    savedBefore = nil
  end
end

---------------------------------------------------------------------------------------------------------------------
-- the loop: 250 ms; at the menu one race-world sweep every 2 s (or at once on the notification); in a race a few
-- lookups only: the load routes (retried at most LOAD_RETRIES ticks), one player-state sweep a second until your
-- vehicle shows up, then the timed routes and read-backs.
local flags = { race = false, menu = false }
pcall(NotifyOnNewObject, '/Script/Griffin.RacingGameState', function() flags.race = true end)
pcall(NotifyOnNewObject, '/Script/Griffin.FrontEndGameMode', function() flags.menu = true end)

local TICK = 250
local t, races, seenGs, job = 0, 0, {}, nil
local function sec(n) return math.floor(n * 1000 / TICK + 0.5) end

local function startRace(gs)
  races = races + 1
  local entry = CONFIG.PLAN[races]
  local ksl = try(StaticFindObject, '/Script/Engine.Default__KismetSystemLibrary')
  local standalone = alive(ksl) and try(function() return ksl:IsStandalone(gs) end)
  log(('race %d: world %s, standalone=%s, plan %s'):format(races, oname(gs), tostring(standalone), tostring(entry)))
  if standalone ~= true or not entry then
    if standalone ~= true then log('not an offline race: nothing tried') else log('plan done: nothing tried') end
    return nil
  end
  local cls, cdo = preset()
  if not alive(cls) then log('preset did not load: ' .. CONFIG.PRESET); return nil end
  local j = { routes = {}, at = t, want = rname(cdo) or '?', parch = tonumber(try(function() return cdo.VehicleArchetype end) or -1) }
  for r in tostring(entry):gmatch('[ABCO]') do
    local when = CONFIG.WHEN[r] == 'load' and r ~= 'B' and 'load' or 'after'
    j.routes[#j.routes + 1] = { name = r, when = when, done = false, tries = 0 }
  end
  log(('preset "%s" (%s, %s); routes %s'):format(j.want, oname(cls), ARCH[j.parch] or '?',
    table.concat((function() local o = {} for _, r in ipairs(j.routes) do o[#o + 1] = r.name .. '@' .. r.when end return o end)(), ' ')))
  return j
end

LoopInGameThreadWithDelay(TICK, function()
  local ok, err = pcall(function()
    t = t + 1
    if t == sec(5) then -- load the preset once at the menu, so it is ready when the race loads
      local cls, cdo = preset()
      log(alive(cls) and ('preset loaded: recipe "%s", archetype %s'):format(tostring(rname(cdo)),
        ARCH[tonumber(try(function() return cdo.VehicleArchetype end) or -1)] or '?') or ('preset did NOT load: ' .. CONFIG.PRESET))
    end
    if flags.menu then
      flags.menu = false
      if job then log(('race %d over: main menu back'):format(races)) end
      job = nil
      putBack()
      return
    end
    if not job then
      if not (flags.race or t % sec(2) == 0) then return end
      flags.race = false
      -- (a finished race's game state can linger into the menus: only one not seen before counts)
      local gs
      for _, g in ipairs(try(FindAllOf, 'RacingGameState') or {}) do
        local a = addr(g)
        if a and not seenGs[a] then seenGs[a] = true; gs = gs or g end
      end
      if not gs then return end
      job = startRace(gs) or { idle = true }
      return
    end
    if job.idle then return end
    -- vehicle archetype check once your vehicle is known; the wrong type stops everything
    if not job.pawnAt and (t - job.at) % sec(1) == 0 then
      local _, pawn = you()
      if pawn then
        job.pawnAt = t
        local arch = tonumber(try(function() return pawn:GetVehicleArchetype() end) or -1)
        log(('your vehicle: %s (%s), %0.2f s after the race world; wears "%s"'):format(oname(pawn), ARCH[arch] or '?',
          (t - job.at) * TICK / 1000, tostring(wears(pawn, false) or '? (no look component on the vehicle itself)')))
        if arch ~= job.parch then
          log(('STOP: the preset is a %s look, your vehicle a %s: nothing more tried'):format(ARCH[job.parch] or '?', ARCH[arch] or '?'))
          job.idle = true; return
        end
      elseif t - job.at > sec(120) then log('no vehicle after 120 s: stopping'); job.idle = true; return end
    end
    -- the routes, in plan order; one acts per tick
    for _, r in ipairs(job.routes) do
      if not r.done then
        local due = r.when == 'load' or (job.pawnAt and t - job.pawnAt >= sec(CONFIG.AFTER_S))
        if not due then break end
        if job.on then log(r.name .. ': skipped, the look is on already'); r.done = true; break end
        if r.when == 'load' and job.pawnAt and r.tries == 0 then log(r.name .. ': (your vehicle was built before this route ran)') end
        local okR, fin = pcall(R[r.name], r, job)
        if not okR then log(r.name .. ': error ' .. tostring(fin)); fin = true end
        r.tries = r.tries + 1
        if fin then r.done = true; r.checkAt = t + sec(CONFIG.CHECK_S) end
        return
      end
    end
    -- read-backs: CHECK_S after each route, and once SURVIVE_S after the vehicle showed up
    if not job.pawnAt then return end
    for _, r in ipairs(job.routes) do
      if r.done and r.checkAt and t >= r.checkAt then r.checkAt = nil; readBack(job, 'after ' .. r.name); return end
    end
    if not job.survived and t - job.pawnAt >= sec(CONFIG.SURVIVE_S) then
      job.survived = true
      readBack(job, CONFIG.SURVIVE_S .. ' s after your vehicle showed up')
      log('done for this race; screenshot the car now (README.md)')
    end
  end)
  if not ok then log('loop error: ' .. tostring(err)) end
end)
