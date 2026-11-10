-- Galactic Grand Prix: launching a race, the class's part levels on your build, watching the race.
-- (From the Underground's race.lua: the same launch, put-back and offline checks; career, AI and abilities removed.)
local C = require('core')
local K = require('gp')
local AB = require('abil')
local LO = require('loadout')
local try, alive, addr, log = C.try, C.alive, C.addr, C.log

local R = { run = nil }
local MULTIPLAYER_FLOW = 4

---------------------------------------------------------------------------------------------------------------------
-- guard

-- Real online activity: a party with someone else in it, or matchmaking under way.
-- (PrimaryFlow turns Multiplayer as soon as the MULTIPLAYER tab is shown, even offline and alone, so the flow alone
-- can't be the test.) Returns a reason, false when clearly offline, or nil when it can't tell.
local function online()
  local known = false
  local pm = C.first('PartyManager')
  if alive(pm) then
    local n = try(function() return tonumber(pm:GetNumPlayersInParty()) end)
    if n then known = true; if n > 1 then return 'you are in a party (' .. n .. ' players)' end end
  end
  local mm = C.first('PlayfabOnlineMatchmaking')
  if alive(mm) then
    local busy = try(function() return mm:IsMatchmaking() end)
    if busy ~= nil then known = true; if busy == true then return 'matchmaking is running' end end
  end
  if known then return false end
  return nil
end

function R.atMainMenu()
  local fe = C.first('FrontEndGameMode')
  if not alive(fe) then return nil, 'not at the main menu' end
  local why = online()
  if why then return nil, why end
  if why == nil then
    -- couldn't read party / matchmaking: fall back to the stricter flow test
    local gi = C.first('GfnGameInstance')
    local flow = alive(gi) and try(function() return tonumber(gi.PrimaryFlow) end)
    if flow == MULTIPLAYER_FLOW then return nil, 'multiplayer is active' end
  end
  return fe
end

---------------------------------------------------------------------------------------------------------------------
-- your build: the class's part levels in before launch, the originals back at the menu. The originals are in the
-- save (K.data.restores) before anything changes, so a reload or crash mid-race can still put them back.

local function readLevels(build)
  local t = {}
  try(function() build.SlotToUpgradeLevelMap:ForEach(function(k, v) t[tonumber(k:get())] = tonumber(v:get()) end) end)
  return t
end
R.readLevels = readLevels
function R.levelsText(t)
  local p = {}
  for s = 0, 5 do if t[s] then p[#p + 1] = s .. '=' .. t[s] end end
  return #p > 0 and table.concat(p, ' ') or '(empty)'
end
local function writeLevels(build, want)
  local have = readLevels(build)
  try(function() build.SlotToUpgradeLevelMap:ForEach(function(k, v)
    local w = want[tonumber(k:get())]
    if w then v:set(w) end
  end) end)
  for s = 0, 5 do
    if have[s] == nil and want[s] and want[s] ~= 0 then
      try(function() build.SlotToUpgradeLevelMap:Add(s, want[s]) end)
    end
  end
end

function R.pendingRestore() return next(K.data.restores) ~= nil or next(K.data.abilityRestores) ~= nil end

-- ability slots (v0.3): a class object -> its path ('' = empty)
local function slotPath(c)
  if not alive(c) then return '' end
  local full = try(function() return c:GetFullName() end)
  return type(full) == 'string' and full:match('^%S+%s+(.+)$') or ''
end
local function setSlot(slots, i, path)
  local cls = path ~= '' and C.uclass(path) or nil
  return pcall(function() slots[i] = cls or CreateInvalidObject() end)
end
-- your four picks into the launch build's slots (originals into the save first). A slot holding Autopilot was put
-- there by the test-only TestAutopilot (it drives test races) and is left alone; the Grand Prix never gives Autopilot.
local function applyAbilities(path, b, want)
  local slots = try(function() return b.AbilitySlots end)
  local n = slots and try(function() return slots:GetArrayNum() end) or 0
  if n == 0 then log('abilities: the build has no ability slots'); return end
  local cur = {}
  for i = 1, n do cur[i] = slotPath(try(function() return slots[i] end)) end
  if not K.data.abilityRestores[path] then
    local orig = {}
    for i = 1, n do if not cur[i]:find('Autopilot') then orig[i] = cur[i] end end
    K.data.abilityRestores[path] = orig
    K.save()
  end
  local k, names = 1, {}
  for i = 1, n do
    if not cur[i]:find('Autopilot') then
      local p = want[k] or ''
      k = k + 1
      if not setSlot(slots, i, p) then log('ability slot ' .. i .. ' refused ' .. p) end
      if p ~= '' then names[#names + 1] = p:match('BP_Ability_([%w_]+)%.') or p end
    end
  end
  if k <= #want then log(('abilities: only %d of %d fit (a slot holds Autopilot)'):format(k - 1, #want)) end
  log('your abilities for this race: ' .. (#names > 0 and table.concat(names, ', ') or 'none'))
end

function R.restoreBuild(why)
  local done = {}
  for path, orig in pairs(K.data.restores) do
    local b = C.asset(path)
    if b then
      writeLevels(b, orig)
      log(('build put back (%s): %s %s'):format(why, path:match('([^/]+)$'), R.levelsText(readLevels(b))))
    else
      log('restore: build not found ' .. path)
    end
    done[#done + 1] = path
  end
  for _, path in ipairs(done) do K.data.restores[path] = nil end
  for path, orig in pairs(K.data.abilityRestores) do
    local b = C.asset(path)
    local slots = b and try(function() return b.AbilitySlots end)
    if slots then
      for i, p in pairs(orig) do setSlot(slots, i, p) end
      log(('ability slots put back (%s): %s'):format(why, path:match('([^/]+)$')))
    end
    K.data.abilityRestores[path] = nil
    done[#done + 1] = path
  end
  if #done > 0 then K.save() end
end

local function applyBuild(path, b, levels)
  if not K.data.restores[path] then K.data.restores[path] = readLevels(b); K.save() end
  writeLevels(b, levels)
  log(('build for this race: %s %s'):format(path:match('([^/]+)$'), R.levelsText(readLevels(b))))
end

-- an event's vehicle tag (Vehicle.Standard, Vehicle.Standard.Car, ...), cached per event
local tags = {}
function R.eventTag(ev)
  if tags[ev.path] ~= nil then return tags[ev.path] or nil end
  local e = C.asset(ev.path)
  local t = e and C.tag(try(function() return e.VehicleTypeTag end))
  tags[ev.path] = t or false
  return t
end
-- can this vehicle enter? Vehicle.Standard (or no tag) takes any car / bike / skimmer; Vehicle.Standard.Car etc. one.
local NEEDS = { Car = 'car', Bike = 'bike', Skimmer = 'skimmer' }
function R.fits(vehKey, tag)
  if not tag or tag == 'Vehicle.Standard' or tag == 'Vehicle' then return true end
  local need = NEEDS[tag:match('%.(%a+)$') or '']
  return need == nil or need == vehKey
end

---------------------------------------------------------------------------------------------------------------------
-- launch

local function archetype(n)
  for _, v in ipairs(C.find('VehicleArchetype')) do
    if try(function() return tonumber(v.archetype) end) == n then return v end
  end
  return nil
end

-- ev = { path, title, kind, cup, class, race }; picks = your four abilities (abil.lua) or nil for none.
-- Returns true, or false + a message for the player.
function R.launch(ev, classKey, vehKey, picks)
  if R.run then return false, 'A race is already running' end
  local fe, why = R.atMainMenu()
  if not fe then return false, 'Cannot launch: ' .. why end
  local e = C.asset(ev.path)
  if not e then log('event not found: ' .. ev.path); return false, 'Event not found: ' .. ev.path:match('([^/]+)$') end
  local veh = K.vehicle(vehKey)
  local tag = C.tag(try(function() return e.VehicleTypeTag end))
  if not R.fits(veh.key, tag) then return false, ('The %s can\'t enter %s (it needs: %s)'):format(veh.name, ev.title, tostring(tag)) end
  local arch = archetype(veh.arch)
  local build = C.asset(veh.build)
  if not (alive(arch) and build) then log('vehicle or build not found: ' .. veh.key); return false, 'Vehicle or build not found' end
  applyBuild(veh.build, build, K.levelsFor(classKey))
  if picks then
    local okA, errA = pcall(applyAbilities, veh.build, build, AB.classPaths(picks, AB.levelFor(classKey)))
    if not okA then log('abilities not set: ' .. tostring(errA)) end
  end
  local oldGs = C.first('RacingGameState')
  local ok, err = try(function() fe:LaunchQuickRace(arch, e, build); return true end)
  if not ok then
    log('launch failed: ' .. tostring(err))
    R.restoreBuild('launch failed')
    return false, 'Launch failed - see grandprix.log'
  end
  ev.class = classKey
  log(('LAUNCH %s (%s - %s) class=%s vehicle=%s tag=%s mode=%s'):format(ev.path:match('([^/]+)$'), ev.title, ev.kind or '',
    tostring(classKey), veh.key, tostring(tag), C.idname(try(function() return e.EventMode end))))
  R.run = { ev = ev, at = C.clock, oldGs = addr(oldGs), oldFe = addr(fe), phase = 'loading', top = 0, field = {}, ticks = 0 }
  local ok3, lo = pcall(LO.begin, classKey)
  if ok3 then R.run.lo = lo else log('[loadout] ' .. tostring(lo)) end
  return true
end

---------------------------------------------------------------------------------------------------------------------
-- watching: returns the result once the race is over and we're back at the main menu

local function playerRow(r)
  -- the player state is kept as path + address (C.ref), never as the object: it's freed with the race world
  local me = C.deref(r.psRef)
  if not me then
    r.psRef = nil
    for _, ps in ipairs(C.find('GfnPlayerState')) do
      if try(function() return ps.bIsABot end) == false then me = ps; r.psRef = C.ref(ps); break end
    end
    if not me then return nil end
  end
  local rec = try(function() return me.RaceEventComponent end)
  if not alive(rec) then return nil end
  local pawn = try(function() return me.PawnPrivate end)
  local kph = alive(pawn) and try(function() local v = pawn:GetVelocity(); return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) * 0.036 end) or 0
  return { pos = try(function() return tonumber(rec.EventPosition) end),
    done = try(function() return rec.bHasFinishedEvent end) == true, kph = kph or 0 }
end

-- every racer's name, position and finished flag (v0.2, the cup's points). Strings and numbers only, read again each
-- time: a racer's position is kept once they've finished. Returns the number of racers seen.
-- (PlayerNamePrivate first: that's what the Underground's loadout and recon read in game, 2026-11-09)
local function pilotName(ps)
  local n = C.text(ps, 'PlayerNamePrivate')
  if not n then n = try(function() return ps:GetPlayerName():ToString() end) end
  return (type(n) == 'string' and n ~= '') and n or nil
end
local function readField(r)
  local n, seen = 0, {}
  for _, ps in ipairs(C.find('GfnPlayerState')) do
    local rec = try(function() return ps.RaceEventComponent end)
    local name = pilotName(ps)
    if alive(rec) and name then
      local you = try(function() return ps.bIsABot end) == false
      local key = you and '@you' or name
      -- two racers with the same name (shouldn't happen): keep them apart, in the order the game lists them
      if seen[key] then
        local i = 2
        while seen[key .. ' #' .. i] do i = i + 1 end
        key = key .. ' #' .. i
        name = name .. ' #' .. i
      end
      seen[key] = true
      local f = r.field[key] or { name = name, you = you }
      r.field[key] = f
      if not f.finished then
        local pos = try(function() return tonumber(rec.EventPosition) end)
        if pos and pos > 0 then f.pos = pos end
        if try(function() return rec.bHasFinishedEvent end) == true then f.finished = true end
      end
      n = n + 1
    end
  end
  return n
end
local function fieldList(r)
  local out = {}
  for _, f in pairs(r.field) do out[#out + 1] = { name = f.name, you = f.you, pos = f.pos, finished = f.finished } end
  return out
end
R.fieldList = fieldList

function R.watch()
  local r = R.run
  if not r then return nil end
  if r.phase == 'loading' then
    for _, gs in ipairs(C.find('RacingGameState')) do
      if addr(gs) ~= r.oldGs then
        local ksl = C.lib('KismetSystemLibrary')
        local standalone = try(function() return ksl:IsStandalone(gs) end)
        log(('race world loaded, standalone=%s'):format(tostring(standalone)))
        if standalone ~= true then
          log('NOT an offline race - Grand Prix stops here, build put back')
          R.restoreBuild('not offline'); R.run = nil; return { failed = 'not offline' }
        end
        r.gs, r.phase = addr(gs), 'racing'
        local ok, err = pcall(LO.apply, r.lo)
        if not ok then log('[loadout] apply failed: ' .. tostring(err)); r.lo = nil end
        return nil
      end
    end
    if C.clock - r.at > 120000 then
      log('no race world after 120 s - giving up')
      R.restoreBuild('timeout'); R.run = nil
      return { failed = 'timeout' }
    end
    return nil
  end

  local gs
  for _, g in ipairs(C.find('RacingGameState')) do if addr(g) == r.gs then gs = g end end
  local fe = C.first('FrontEndGameMode')
  if alive(fe) and (not gs or addr(fe) ~= r.oldFe) then
    R.restoreBuild('main menu')
    local fl = fieldList(r)
    -- your finish counts as read at the moment you crossed the line
    for _, f in ipairs(fl) do if f.you then f.finished = r.finished; f.pos = r.finished and r.pos or f.pos end end
    local out = K.record(r.ev, r.finished and r.pos or nil, fl)
    log(('RESULT %s: %s (top speed %d kph, last position seen %s)'):format(r.ev.title,
      r.finished and C.ordinal(r.pos) or 'DNF', math.floor(r.top), tostring(r.lastPos)))
    R.run = nil
    return out
  end
  if not gs then return nil end
  if r.lo and not r.lo.done then
    local ok, err = pcall(LO.apply, r.lo)
    if not ok then log('[loadout] apply failed: ' .. tostring(err)); r.lo = nil end
  end
  local started = try(function() return gs.bIsRaceStarted end) == true
  if not started then return nil end
  -- the field: every 5th tick, and right away when you finish (the bots behind you keep racing for a while)
  r.ticks = r.ticks + 1
  if r.ticks % 5 == 0 then
    local n = readField(r)
    if not r.fieldLogged and n > 0 then r.fieldLogged = true; log(('field: %d racers'):format(n)) end
  end
  if r.finished then return nil end
  local row = playerRow(r)
  if row then
    if row.kph > r.top then r.top = row.kph end
    if row.pos ~= r.lastPos then r.lastPos = row.pos end
    if row.done then
      r.finished, r.pos = true, row.pos
      readField(r)
      log(('finished %s'):format(C.ordinal(row.pos)))
    end
  end
  return nil
end

return R
