-- PodTry v0.1.0 (TASKS §1h P1): launch a podracer race from the main menu on a key, and log the field, the finish and
-- the results screen. Read-mostly: the only writes are the CharacterList (opponents, your pod), the pilots'
-- PreferredVehicleType and the cinematic chains of the event / track launched - all put back when the main menu
-- returns (or at the next start: none of it is saved by the game). Offline only (refuses in a party; logs IsStandalone).
-- No hooks; nothing kept between ticks (paths are kept and looked up again); no soft pointers read.
local VERSION = '0.1.0'
local ok, cfg = pcall(require, 'config')
if not ok or type(cfg) ~= 'table' then cfg = {} end
cfg.Launches = cfg.Launches or {}

local LOGF = (function()
  local src = debug.getinfo(1, 'S').source:gsub('^@', '')
  return (src:match('^(.*)[/\\]Scripts[/\\]') or '.') .. '/podtry.log'
end)()
local function log(s)
  local line = os.date('%Y-%m-%d %H:%M:%S ') .. tostring(s)
  print('[PodTry] ' .. tostring(s) .. '\n')
  local f = io.open(LOGF, 'a'); if f then f:write(line .. '\n'); f:close() end
end
local function try(f, ...) local r, v = pcall(f, ...); if r then return v end; return nil end
local function alive(o) return o ~= nil and try(function() return o:IsValid() end) == true end
local function idname(o) return alive(o) and (try(function() return o:GetFName():ToString() end) or '?') or 'none' end
local function full(o) local s = alive(o) and try(function() return o:GetFullName() end); return s and s:gsub('^%S+ ', '') or nil end
local function text(o, f) local s = try(function() return o[f]:ToString() end); return (s and s ~= '') and s or nil end
local function tag(t) local s = try(function() return t.TagName:ToString() end); return (s and s ~= '' and s ~= 'None') and s or nil end
local function find(cls)
  local got, out = try(FindAllOf, cls), {}
  if type(got) == 'table' then for _, o in ipairs(got) do if alive(o) and not idname(o):find('^Default__') then out[#out + 1] = o end end end
  return out
end
local function first(cls) return find(cls)[1] end
local function asset(path)
  local fullp = path .. '.' .. path:match('([^/]+)$')
  local o = try(StaticFindObject, fullp)
  if alive(o) then return o end
  try(LoadAsset, path)
  o = try(StaticFindObject, fullp)
  if alive(o) then return o end
  try(LoadAsset, fullp)          -- (KNOWLEDGE §3: some assets load only by their full object name)
  o = try(StaticFindObject, fullp)
  return alive(o) and o or nil
end
local function racerDef(n) return asset('/Game/Griffin/Narrative/CharacterDefs/Racers/' .. n) end
local function count(arr) return arr and (try(function() return #arr end) or 0) or 0 end
local function entries(m)
  local out = {}
  local arr = try(function() return m.GridMakeup.Entries end)
  for i = 1, count(arr) do out[i] = tonumber(try(function() return arr[i].NumEntrants end)) or 0 end
  return out
end
local function setEntries(m, list)
  for i, n in ipairs(list) do pcall(function() m.GridMakeup.Entries[i].NumEntrants = n end) end
end

---------------------------------------------------------------------------------------------------------------------
-- the dump (PAGE DOWN at the menu)
local CHAINS_T = { 'IntroCinematic', 'PreRaceCinematicChain', 'SideBettingCinematicChain', 'IgnitionCinematicChain',
  'EventCompleteCinematicChain', 'EventFailedCinematicChain', 'ResultsCinematicChain' }
local CHAINS_E = { 'IntroCinematic', 'PreRaceCinematicChain', 'EventCompleteCinematicChain', 'EventFailedCinematicChain',
  'ResultsCinematicChain', 'NextEventInChain' }
local function describeTrack(tr, pre)
  local conds = {}
  local layers = try(function() return tr.TrackConditionDataLayers end)
  for i = 1, math.min(count(layers), 12) do
    local t = tag(try(function() return layers[i].Tag end))
    if t then conds[#conds + 1] = t end
  end
  log(('%strack %s: "%s" internal "%s" dev "%s" p2p=%s reverse=%s laps=%s vehicle=%s conditions=[%s]'):format(pre or '',
    idname(tr), tostring(text(tr, 'PlayerFacingName')), tostring(text(tr, 'InternalName')), tostring(text(tr, 'DevStatusText')),
    tostring(try(function() return tr.bIsPointToPoint end)), tostring(try(function() return tr.bIsReverse end)),
    tostring(try(function() return tr.DefaultLapCount end)), tostring(tag(try(function() return tr.VehicleTypeTag end))),
    table.concat(conds, ' ')))
  for _, f in ipairs(CHAINS_T) do
    local c = try(function() return tr[f] end)
    if alive(c) then log(('%s  %s = %s'):format(pre or '', f, idname(c))) end
  end
  return conds
end
local function describeEvent(e)
  local tr = try(function() return e.TrackDef end)
  local gm = try(function() return e.GridMakeup end)
  local ents = gm and try(function() return gm.Entries end)
  local grid = {}
  for i = 1, math.min(count(ents), 8) do grid[#grid + 1] = tostring(try(function() return ents[i].NumEntrants end)) end
  log(('event %s: "%s" laps=%s vehicle=%s mode=%s skipCountdown=%s grid=[%s] customOpponents=%d track=%s'):format(idname(e),
    tostring(text(e, 'PlayerFacingName')), tostring(try(function() return e.LapCount end)),
    tostring(tag(try(function() return e.VehicleTypeTag end))), idname(try(function() return e.EventMode end)),
    tostring(try(function() return e.bShouldSkipCountdown end)), table.concat(grid, ','),
    count(try(function() return e.CustomOpponents end)), idname(tr)))
  for _, f in ipairs(CHAINS_E) do
    local c = try(function() return e[f] end)
    if alive(c) then log('  ' .. f .. ' = ' .. idname(c)) end
  end
  if alive(tr) then describeTrack(tr, '  ') end
end
local function dump()
  log('--- dump')
  for _, p in ipairs(cfg.Dump or {}) do
    local o = asset(p)
    if not o then log('not found: ' .. p)
    elseif p:match('/EVT_') then describeEvent(o) else describeTrack(o) end
  end
  for _, n in ipairs(cfg.PodPilots or {}) do
    local r = racerDef(n)
    log(('pilot %s: "%s" PreferredVehicleType=%s'):format(n, tostring(r and text(r, 'CharacterName')),
      tostring(r and try(function() return r.PreferredVehicleType end))))
  end
  local cl = first('CharacterList')
  if cl then
    local opp, names = try(function() return cl.Opponents end), {}
    for i = 1, count(opp) do names[#names + 1] = idname(try(function() return opp[i] end)) end
    log(('CharacterList %s: Player=%s Opponents(%d)=%s'):format(idname(cl), idname(try(function() return cl.Player end)), #names, table.concat(names, ' ')))
  end
  for _, v in ipairs(find('VehicleArchetype')) do
    log(('archetype %s = %s'):format(idname(v), tostring(try(function() return v.archetype end))))
  end
  local el = first('GfnEventList')
  local arr = alive(el) and try(function() return el.QuickRaceGameModes end)
  for i = 1, count(arr) do
    local m = try(function() return arr[i] end)
    if alive(m) then log(('quick race mode %s: "%s" mode %s grid [%s]'):format(idname(m), tostring(text(m, 'PlayerFacingName')),
      tostring(try(function() return m.GameMode end)), table.concat(entries(m), ','))) end
  end
  log('--- dump end')
end

---------------------------------------------------------------------------------------------------------------------
-- the launch, and everything put back
local restore = nil      -- { chains = { {objPath, field, valuePath} }, opponents = {paths}, player = path, pref = { {path, was} } }
local function takeChains(o, fields)
  for _, f in ipairs(fields) do
    local c = try(function() return o[f] end)
    if alive(c) then
      restore.chains[#restore.chains + 1] = { full(o), f, full(c) }
      local okc = pcall(function() o[f] = CreateInvalidObject() end)
      log(('  %s.%s %s'):format(idname(o), f, okc and 'cleared' or 'NOT cleared'))
    end
  end
end
local function putBack()
  if not restore then return end
  for _, c in ipairs(restore.chains) do
    local o, v = try(StaticFindObject, c[1]), try(StaticFindObject, c[3])
    if alive(o) and alive(v) then pcall(function() o[c[2]] = v end) end
  end
  local cl = first('CharacterList')
  if cl and restore.opponents then
    local arr = try(function() return cl.Opponents end)
    try(function() arr:Empty() end)
    for i, p in ipairs(restore.opponents) do
      local r = try(StaticFindObject, p)
      if alive(r) then try(function() arr[i] = r end) end
    end
  end
  for _, x in ipairs(restore.pref or {}) do
    local r = try(StaticFindObject, x[1])
    if alive(r) then pcall(function() r.PreferredVehicleType = x[2] end) end
  end
  if restore.grid then
    local m = try(StaticFindObject, restore.grid[1])
    if alive(m) then setEntries(m, restore.grid[2]) end
  end
  log(('put back: %d chains, opponents %d, %d pilots\' vehicles'):format(#restore.chains, restore.opponents and #restore.opponents or 0, #(restore.pref or {})))
  restore = nil
end

local function archetype(n)
  for _, v in ipairs(find('VehicleArchetype')) do if try(function() return tonumber(v.archetype) end) == n then return v end end
end
local function mode(name)
  local el = first('GfnEventList')
  local arr = alive(el) and try(function() return el.QuickRaceGameModes end)
  local fallback
  for i = 1, count(arr) do
    local m = try(function() return arr[i] end)
    if alive(m) then if idname(m) == name then return m end; fallback = fallback or m end
  end
  return fallback
end
local function online()
  local pm = first('PartyManager')
  local n = alive(pm) and try(function() return pm:GetNumPlayersInParty() end)
  return type(n) == 'number' and n > 1
end

local FALLBACK_BUILD = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Plane_Base'
local race = nil       -- the race being watched: { at, kind, logged = {} }
local function launch(i)
  local L = cfg.Launches[i]
  if not L then log('no Launches[' .. i .. ']'); return end
  local fe = first('FrontEndGameMode')
  if not alive(fe) then log('not at the main menu: nothing launched'); return end
  if online() then log('in a party: nothing launched'); return end
  if restore then putBack() end
  restore = { chains = {}, pref = {} }
  local v, b = archetype(1), asset(L.build)
  if not b and L.build ~= FALLBACK_BUILD then
    log('build not found: ' .. tostring(L.build) .. ' - trying ' .. FALLBACK_BUILD)
    b = asset(FALLBACK_BUILD)
  end
  if not (alive(v) and b) then log(('cannot launch: pod archetype %s, build %s'):format(tostring(alive(v)), tostring(b ~= nil))); restore = nil; return end
  -- the field
  local cl = first('CharacterList')
  if cl and cfg.PodPilots then
    local arr = try(function() return cl.Opponents end)
    restore.opponents = {}
    for j = 1, count(arr) do restore.opponents[j] = full(try(function() return arr[j] end)) end
    local defs = {}
    for _, n in ipairs(cfg.PodPilots) do local r = racerDef(n); if r then defs[#defs + 1] = r end end
    try(function() arr:Empty() end)
    for j, r in ipairs(defs) do try(function() arr[j] = r end) end
    log(('CharacterList.Opponents = %d pod pilots (was %d)'):format(count(arr), #restore.opponents))
  end
  if cfg.LendPods and cl then
    local lend = { try(function() return cl.Player end) }
    for _, n in ipairs(cfg.PodPilots or {}) do if n:match('^DA_Racer_') then lend[#lend + 1] = racerDef(n) end end
    for _, r in ipairs(lend) do
      local was = alive(r) and try(function() return tonumber(r.PreferredVehicleType) end)
      if was and was ~= 1 then
        restore.pref[#restore.pref + 1] = { full(r), was }
        pcall(function() r.PreferredVehicleType = 1 end)
        log(('%s drives a pod this race (PreferredVehicleType %d -> %s)'):format(idname(r), was, tostring(try(function() return r.PreferredVehicleType end))))
      end
    end
  end
  local okl, err
  if L.kind == 'quick' then
    local e = asset(L.event)
    if not e then log('event not found: ' .. tostring(L.event)); putBack(); return end
    describeEvent(e)
    takeChains(e, CHAINS_E)
    local tr = try(function() return e.TrackDef end)
    if alive(tr) then takeChains(tr, CHAINS_T) end
    log(('LAUNCH quick %s, pod archetype, build %s'):format(idname(e), idname(b)))
    okl, err = pcall(function() fe:LaunchQuickRace(v, e, b) end)
  else
    local tr = asset(L.track)
    if not tr then log('track not found: ' .. tostring(L.track)); putBack(); return end
    local conds = describeTrack(tr)
    takeChains(tr, CHAINS_T)
    local m = mode(L.mode or 'GMV_Race')
    local cond = L.condition or conds[1] or 'None'
    if L.grid and alive(m) then
      local was = entries(m)
      local want = {}
      for i = 1, #was do want[i] = i == 1 and L.grid or 0 end
      setEntries(m, want)
      restore.grid = { full(m), was }
      log(('%s grid make-up [%s] -> [%s] (read back)'):format(idname(m), table.concat(was, ','), table.concat(entries(m), ',')))
    end
    log(('LAUNCH custom %s, mode %s, condition %s, build %s'):format(idname(tr), idname(m), cond, idname(b)))
    okl, err = pcall(function() fe:LaunchCustomRace(v, m, tr, { TagName = FName(cond) }, b, nil) end)
  end
  if not okl then log('launch failed: ' .. tostring(err)); putBack(); return end
  race = { at = os.time(), kind = L.kind, logged = {}, n = 0 }
end

---------------------------------------------------------------------------------------------------------------------
-- watching the race (every 2 s while a race world is up; one sweep a read)
local function readRace()
  local gs = first('RacingGameState')
  if not gs then return false end
  local R = race
  if not R.logged.world then
    R.logged.world = true
    local ksl = try(StaticFindObject, '/Script/Engine.Default__KismetSystemLibrary')
    log(('race world up %d s after the launch, standalone=%s, laps=%s'):format(os.time() - R.at,
      tostring(alive(ksl) and try(function() return ksl:IsStandalone(gs) end)), tostring(try(function() return gs.LapCount end))))
  end
  local started = try(function() return gs.bIsRaceStarted end) == true
  local states = find('GfnPlayerState')
  if #states > 0 and (not R.logged.field or (started and not R.logged.field2)) then
    if started then R.logged.field2 = true else R.logged.field = true end
    local parts = {}
    for _, ps in ipairs(states) do
      local rec = try(function() return ps.RaceEventComponent end)
      parts[#parts + 1] = ('%s%s p%s'):format(text(ps, 'PlayerNamePrivate') or '?', try(function() return ps.bIsABot end) == false and ' (YOU)' or '',
        tostring(alive(rec) and try(function() return rec.EventPosition end)))
    end
    log(('field (%s, %d): %s'):format(started and 'started' or 'loading', #states, table.concat(parts, ', ')))
    -- who drives what: the race recipe (plain pointers: Pilot, vehicleType, VehicleCustomisation class)
    local sub = first('EventRecipeSubsystem')
    local ar = sub and try(function() return sub.ActiveRecipe end)
    local rs = ar and try(function() return ar.RecipeState end)
    local racers = rs and try(function() return rs.Racers end)
    local rows = {}
    for j = 1, math.min(count(racers), 16) do
      local x = try(function() return racers[j] end)
      if x then rows[#rows + 1] = ('%s/%s/%s'):format(idname(try(function() return x.Pilot end)),
        tostring(try(function() return x.vehicleType end)), idname(try(function() return x.VehicleCustomisation end))) end
    end
    log(('recipe racers (%d): %s'):format(#rows, table.concat(rows, ', ')))
    local pc = first('PlayerController')
    local pawn = pc and try(function() return pc.Pawn end)
    log(('your pawn: %s'):format(alive(pawn) and (try(function() return pawn:GetClass():GetFName():ToString() end) or '?') or 'none'))
  end
  -- your finish
  if not R.finished then
    for _, ps in ipairs(states) do
      if try(function() return ps.bIsABot end) == false then
        local rec = try(function() return ps.RaceEventComponent end)
        if alive(rec) and try(function() return rec.bHasFinishedEvent end) == true then
          R.finished, R.finAt = true, os.time()
          log(('YOU finished: position %s, time %s, best lap %s'):format(tostring(try(function() return rec.EventPosition end)),
            tostring(try(function() return rec.EventFinishTime end)), tostring(try(function() return rec.BestLapTime end))))
          local times = {}
          for _, q in ipairs(states) do
            local rq = try(function() return q.RaceEventComponent end)
            times[#times + 1] = ('%s %s'):format(text(q, 'PlayerNamePrivate') or '?', tostring(alive(rq) and try(function() return rq.EventFinishTime end)))
          end
          log('finish times now: ' .. table.concat(times, ', '))
        end
      end
    end
  end
  -- the results screen: the user widgets that look like it, a few looks after your finish
  if R.finished and (R.looks or 0) < 6 and os.time() - R.finAt >= 3 * ((R.looks or 0) + 1) then
    R.looks = (R.looks or 0) + 1
    local seen = {}
    for _, w in ipairs(find('UserWidget')) do
      local c = try(function() return w:GetClass():GetFName():ToString() end) or ''
      if (c:find('Result') or c:find('PostRace') or c:find('Podium') or c:find('Standing')) and not seen[c] then
        seen[c] = true
      end
    end
    local list = {}
    for c in pairs(seen) do list[#list + 1] = c end
    table.sort(list)
    log(('look %d after the finish: %s'):format(R.looks, #list > 0 and table.concat(list, ', ') or 'no results widgets'))
  end
  return true
end

---------------------------------------------------------------------------------------------------------------------
local want = nil
local KEYS = { { 'HOME', 0x24, 1 }, { 'PAGE_UP', 0x21, 2 }, { 'DEL', 0x2E, 3 }, { 'PAGE_DOWN', 0x22, 'dump' } }
for _, k in ipairs(KEYS) do
  local code = (Key and Key[k[1]]) or k[2]
  local okk = pcall(RegisterKeyBind, code, function() want = k[3] end)
  if not okk then log('could not bind ' .. k[1]) end
end
local last, tickN = 0, 0
LoopInGameThreadWithDelay(500, function()
  local okt, err = pcall(function()
    tickN = tickN + 1
    local w = want
    want = nil
    if w then
      if os.time() - last < 5 then log('ignored (pressed again within 5 s)'); return end
      last = os.time()
      if w == 'dump' then dump() else launch(w) end
      return
    end
    if race and tickN % 4 == 0 then
      local inRace = readRace()
      if not inRace and os.time() - race.at > 10 then
        if alive(first('FrontEndGameMode')) and (race.logged.world or os.time() - race.at > 120) then
          log(('back at the main menu (%d s after the launch)'):format(os.time() - race.at))
          race = nil
          putBack()
        end
      end
    end
  end)
  if not okt then log('tick error: ' .. tostring(err)) end
  return false
end)
log(('v%s loaded: %d launches (HOME / PAGE UP / DELETE), PAGE DOWN = dump'):format(VERSION, #cfg.Launches))
