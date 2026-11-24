-- TrackTry v0.1.0: launch a track that has no event of its own, through the front end's LaunchCustomRace (the path
-- FreeRace uses), from the main menu on a key. A one-off tool to try the hidden Jakku sprint (TRAK_MAS_P2P_SHORT_03)
-- and the mines layouts. Offline only; nothing is kept between ticks; no soft pointers are read (Map, Planet,
-- BasedOnTrack stay untouched).
local VERSION = '0.1.0'
local ok, cfg = pcall(require, 'config')
if not ok or type(cfg) ~= 'table' then cfg = {} end
cfg.Tracks = cfg.Tracks or {}
cfg.Mode = cfg.Mode or 'GMV_Race'
cfg.Vehicle = tonumber(cfg.Vehicle) or 0
cfg.Build = cfg.Build or '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base'
if cfg.ClearCinematics == nil then cfg.ClearCinematics = true end

local function log(s) print('[TrackTry] ' .. tostring(s) .. '\n') end
local function try(f, ...) local r, v = pcall(f, ...); if r then return v end; return nil end
local function alive(o) return o ~= nil and try(function() return o:IsValid() end) == true end
local function idname(o) return try(function() return o:GetFName():ToString() end) or '?' end
local function text(o, f) return try(function() return o[f]:ToString() end) end
local function tag(t) local s = try(function() return t.TagName:ToString() end); return (s and s ~= '' and s ~= 'None') and s or nil end

local function find(cls)
  local got, out = try(FindAllOf, cls), {}
  if type(got) == 'table' then for _, o in ipairs(got) do if alive(o) and not idname(o):find('^Default__') then out[#out + 1] = o end end end
  return out
end
local function first(cls) return find(cls)[1] end
local function asset(path)
  local full = path .. '.' .. path:match('([^/]+)$')
  local o = try(StaticFindObject, full)
  if alive(o) then return o end
  try(LoadAsset, path)
  o = try(StaticFindObject, full)
  return alive(o) and o or nil
end

-- the vehicle archetype with this number (0 car, 2 bike, 3 skimmer)
local function archetype(n)
  for _, v in ipairs(find('VehicleArchetype')) do if try(function() return tonumber(v.archetype) end) == n then return v end end
end
-- a quick race game mode by name
local function mode(name)
  local el = first('GfnEventList')
  local arr = alive(el) and try(function() return el.QuickRaceGameModes end)
  local n = arr and try(function() return #arr end) or 0
  local fallback
  for i = 1, n do
    local m = try(function() return arr[i] end)
    if alive(m) then
      if idname(m) == name then return m end
      fallback = fallback or m
    end
  end
  return fallback
end

-- the cinematic chains taken off a track: { [trackFullName] = { field = chainFullName } }, put back at the main menu
local CHAINS = { 'IntroCinematic', 'PreRaceCinematicChain', 'SideBettingCinematicChain', 'IgnitionCinematicChain',
  'EventCompleteCinematicChain', 'EventFailedCinematicChain', 'ResultsCinematicChain' }
local taken = {}
local function describe(tr)
  local conds = {}
  local layers = try(function() return tr.TrackConditionDataLayers end)
  local n = layers and try(function() return #layers end) or 0
  for i = 1, math.min(n, 12) do
    local t = tag(try(function() return layers[i].Tag end))
    if t then conds[#conds + 1] = t end
  end
  log(('track %s: "%s" internal "%s" dev "%s" p2p=%s reverse=%s laps=%s mines=%s route=%s vehicle=%s conditions=[%s]'):format(
    idname(tr), tostring(text(tr, 'PlayerFacingName')), tostring(text(tr, 'InternalName')), tostring(text(tr, 'DevStatusText')),
    tostring(try(function() return tr.bIsPointToPoint end)), tostring(try(function() return tr.bIsReverse end)),
    tostring(try(function() return tr.DefaultLapCount end)), tostring(try(function() return tr.bHasMines end)),
    tostring(tag(try(function() return tr.RouteTag end))), tostring(tag(try(function() return tr.VehicleTypeTag end))),
    table.concat(conds, ' ')))
  for _, f in ipairs(CHAINS) do
    local c = try(function() return tr[f] end)
    if alive(c) then log('  ' .. f .. ' = ' .. (try(function() return c:GetFullName() end) or '?')) end
  end
  return conds
end
local function clearChains(tr)
  local key = try(function() return tr:GetFullName() end)
  if not key then return end
  taken[key] = taken[key] or {}
  for _, f in ipairs(CHAINS) do
    local c = try(function() return tr[f] end)
    if alive(c) then
      taken[key][f] = try(function() return c:GetFullName() end)
      local okc = pcall(function() tr[f] = CreateInvalidObject() end)
      log('  ' .. f .. (okc and ' cleared' or ' NOT cleared'))
    end
  end
end
local function putBack()
  for key, fields in pairs(taken) do
    local tr = try(StaticFindObject, (key:gsub('^%S+ ', '')))
    if alive(tr) then
      for f, full in pairs(fields) do
        local c = try(StaticFindObject, (full:gsub('^%S+ ', '')))
        if alive(c) then pcall(function() tr[f] = c end) end
      end
      log('put back the cinematics of ' .. idname(tr))
    end
    taken[key] = nil
  end
end

local function online()
  local pm = first('PartyManager')
  return alive(pm) and try(function() return pm:IsInParty() end) == true
end

local function launch(i)
  local t = cfg.Tracks[i]
  if not t then log('no Tracks[' .. i .. '] in config'); return end
  local fe = first('FrontEndGameMode')
  if not alive(fe) then log('not at the main menu (no FrontEndGameMode): nothing launched'); return end
  if online() then log('in a party: nothing launched'); return end
  local tr = asset(t.path)
  if not tr then log('track not found: ' .. t.path); return end
  local conds = describe(tr)
  local cond = t.condition
  if cond and #conds > 0 then
    local hit = false
    for _, c in ipairs(conds) do if c == cond then hit = true end end
    if not hit then log('condition ' .. cond .. ' is not one of the track\'s; using ' .. conds[1]); cond = conds[1] end
  end
  local v, m, b = archetype(cfg.Vehicle), mode(cfg.Mode), asset(cfg.Build)
  if not (alive(v) and alive(m) and b) then
    log(('cannot launch: vehicle %s, mode %s, build %s'):format(tostring(alive(v)), tostring(alive(m)), tostring(b ~= nil)))
    return
  end
  if cfg.ClearCinematics then clearChains(tr) end
  log(('LAUNCH %s: mode %s, vehicle %d, build %s, condition %s'):format(idname(tr), idname(m), cfg.Vehicle, idname(b), tostring(cond)))
  local okl, err = pcall(function() fe:LaunchCustomRace(v, m, tr, { TagName = FName(cond or 'None') }, b, nil) end)
  if not okl then log('launch failed: ' .. tostring(err)); putBack() end
end

-- key presses only raise a flag; the game-thread loop does the work (and puts cinematics back once the menu is up)
local want, gone = nil, false      -- gone: the main menu has been seen away since the launch (the race world is up)
local KEYS = { { 'HOME', 0x24, 1 }, { 'PAGE_UP', 0x21, 2 }, { 'PAGE_DOWN', 0x22, 3 }, { 'DEL', 0x2E, 4 } }
for _, k in ipairs(KEYS) do
  local code = (Key and Key[k[1]]) or k[2]
  local okk = pcall(RegisterKeyBind, code, function() want = k[3] end)
  if not okk then log('could not bind ' .. k[1]) end
end
local last = 0
LoopInGameThreadWithDelay(500, function()
  local okt, err = pcall(function()
    local i = want
    want = nil
    if i then
      if os.time() - last < 5 then log('ignored (pressed again within 5 s)'); return end
      last = os.time()
      launch(i)
      gone = false
      return
    end
    if next(taken) then
      local atMenu = alive(first('FrontEndGameMode'))
      if not atMenu then gone = true
      elseif gone then putBack() end                   -- the menu is back after the race: put the chains back
    end
  end)
  if not okt then log('tick error: ' .. tostring(err)) end
  return false
end)
log(('v%s loaded: %d tracks (HOME / PAGE UP / PAGE DOWN / DELETE at the main menu), mode %s, vehicle %d'):format(
  VERSION, #cfg.Tracks, cfg.Mode, cfg.Vehicle))
