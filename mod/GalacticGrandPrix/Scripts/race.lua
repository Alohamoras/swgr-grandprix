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
  R.menuSeen = false
  local ok3, lo = pcall(LO.begin, classKey)
  if ok3 then R.run.lo = lo else log('[loadout] ' .. tostring(lo)) end
  return true
end

---------------------------------------------------------------------------------------------------------------------
-- watching: returns the result once the race is over and we're back at the main menu

-- every racer's name, position and finished flag (v0.2, the cup's points). Strings and numbers only, read again each
-- time: a racer's position is kept once they've finished. Returns the number of racers seen.
-- (PlayerNamePrivate first: that's what the Underground's loadout and recon read in game, 2026-11-09)
local function pilotName(ps)
  local n = C.text(ps, 'PlayerNamePrivate')
  if not n then n = try(function() return ps:GetPlayerName():ToString() end) end
  return (type(n) == 'string' and n ~= '') and n or nil
end
-- every racer, read from ONE sweep of the player states (v0.3.9). Lookups by name or path are full object sweeps in
-- this game under UE4SS (its object hash tables weren't found: "Failed to find FUObjectHashTables::Get()" in UE4SS.log),
-- so nothing is kept or looked up between reads; all values come from objects found in this same call. You too:
-- position, finished, speed (for the top speed). Returns the number of racers seen.
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
      if you then
        local pawn = try(function() return ps.PawnPrivate end)
        local kph = alive(pawn) and try(function() local v = pawn:GetVelocity(); return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) * 0.036 end) or 0
        if kph > r.top then r.top = kph end
        if f.pos then r.lastPos = f.pos end
        if f.finished and not r.finished then
          r.finished, r.pos = true, f.pos
          log(('finished %s'):format(C.ordinal(f.pos)))
        end
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

-- PERF (stutter hunt): the real time between our ticks (asked for every 100 ms; a hitch anywhere makes a gap longer)
-- and Lua memory. v0.3.9: from the game's clock (KismetMathLibrary:Now) - no world lookup (the frame-time sample
-- needed one, and lookups are full sweeps here).
function R.perf(r)
  local p = r.perf or { gaps = 0, gapMax = 0, late40 = 0, late100 = 0, kb0 = collectgarbage('count'), kbMax = 0 }
  r.perf = p
  local kb = collectgarbage('count')
  if kb > p.kbMax then p.kbMax = kb end
  local now = R.nowMs()
  if now then
    if p.lastReal then
      local gap = now - p.lastReal
      if gap > 0 and gap < 2000 then -- (a pause or a long load isn't a hitch)
        p.gaps = p.gaps + 1
        if gap > p.gapMax then p.gapMax = gap end
        if gap > 140 then p.late40 = p.late40 + 1 end
        if gap > 200 then p.late100 = p.late100 + 1 end
      end
    end
    p.lastReal = now
  end
end
-- v0.3.6: a real clock for timing our own tick - the game's KismetMathLibrary:Now() (FDateTime, 100 ns ticks).
-- (os.clock under Proton counts the whole game's CPU time.) Returns milliseconds, or nil if the clock can't be read.
local clockBroken, clockLogged = false, false
function R.nowMs()
  if clockBroken then return nil end
  local kml = C.lib('KismetMathLibrary')
  local t = kml and try(function() return kml:Now() end)
  local ticks = t ~= nil and try(function() return t.Ticks end)
  if type(ticks) ~= 'number' then
    clockBroken = true
    if not clockLogged then clockLogged = true; log('[perf] no real clock (KismetMathLibrary:Now gave ' .. tostring(t) .. ') - tick times not measured') end
    return nil
  end
  return ticks / 10000
end
-- our tick's parts in ms: the race watch and the garbage step (counted while a race runs)
function R.perfTick(watchMs, gcMs)
  local r = R.run
  if not (r and r.perf) or not watchMs then return end
  local p = r.perf
  p.tN = (p.tN or 0) + 1
  p.wSum, p.wMax = (p.wSum or 0) + watchMs, math.max(p.wMax or 0, watchMs)
  p.gSum, p.gMax = (p.gSum or 0) + (gcMs or 0), math.max(p.gMax or 0, gcMs or 0)
  if watchMs + (gcMs or 0) > 5 then p.over5 = (p.over5 or 0) + 1 end
  if watchMs + (gcMs or 0) > 20 then p.over20 = (p.over20 or 0) + 1 end
end
local function perfLine(r)
  local p = r.perf
  if not p then return 'no data' end
  return ('tick gaps (asked 100 ms): %d, worst %.0f ms, 40+ ms late %d (%.1f%%), 100+ ms late %d'):format(
    p.gaps, p.gapMax, p.late40, 100 * p.late40 / math.max(1, p.gaps), p.late100)
    .. (' | Lua memory: start %.0f KB, peak %.0f KB, end %.0f KB'):format(p.kb0, p.kbMax, collectgarbage('count'))
    .. ((p.tN or 0) > 0 and (' | our tick (real clock): %d ticks, race watch average %.2f ms / worst %.1f ms, garbage step average %.2f ms / worst %.1f ms, ticks over 5 ms %d, over 20 ms %d'):format(
      p.tN, p.wSum / p.tN, p.wMax, p.gSum / p.tN, p.gMax, p.over5 or 0, p.over20 or 0) or ' | our tick: not measured')
end

-- the main menu coming back (v0.3.9): a notification when its game mode is created - no polling, no sweeps
R.menuSeen = false
pcall(NotifyOnNewObject, '/Script/Griffin.FrontEndGameMode', function() R.menuSeen = true end)

function R.watch()
  local r = R.run
  if not r then return nil end
  if r.phase == 'loading' then
    -- (loading: a sweep for the new race state every tick - the AI's abilities must be set within ~0.7 s of the race
    -- world appearing (loadout.lua); v0.3.1's 250 ms here was too slow once: "too late" in race 2. Loading is short.)
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

  -- racing (v0.3.9): no lookups at all between reads. Every 2 s one sweep reads all 12 racers (readField); the main
  -- menu is noticed by its notification (R.menuSeen) or when a read finds no racers any more (the world is gone), and
  -- only then confirmed with one sweep. (v0.3.1-0.3.8 looked objects up by path several times a second, believing it
  -- cheap; here every such lookup is a full sweep - ~10 ms each, the stutter.)
  if r.lo and not r.lo.done then
    local ok, err = pcall(LO.apply, r.lo)
    if not ok then log('[loadout] apply failed: ' .. tostring(err)); r.lo = nil end
  end
  R.perf(r)
  local due = C.clock - (r.lastRead or -1e9) >= 2000
  if not (R.menuSeen or due or r.gone) then return nil end
  local n = 0
  if not R.menuSeen and due then
    r.lastRead = C.clock
    n = readField(r)
    if n > 0 then
      if not r.fieldLogged then r.fieldLogged = true; log(('field: %d racers'):format(n)) end
      return nil
    end
  end
  -- no racers (or the menu notified): the race world is gone; is the main menu back? (one sweep, at most every 500 ms)
  if C.clock - (r.lastFe or -1e9) < 500 then return nil end
  r.lastFe, r.gone = C.clock, true
  local fe = C.first('FrontEndGameMode')
  if not (alive(fe) and addr(fe) ~= r.oldFe) then return nil end
  R.restoreBuild('main menu')
  local fl = fieldList(r)
  -- you're always in the result (even if you quit before the racers were first read)
  local me
  for _, f in ipairs(fl) do if f.you then me = f end end
  if not me then me = { name = 'YOU', you = true }; fl[#fl + 1] = me end
  me.finished = r.finished; me.pos = r.finished and r.pos or me.pos
  -- (v0.3.5: the race is marked over BEFORE anything that could fail)
  R.run = nil
  local out = K.record(r.ev, r.finished and r.pos or nil, fl)
  pcall(function()
    log(('RESULT %s: %s (top speed %d kph, last position seen %s)'):format(r.ev.title,
      r.finished and C.ordinal(r.pos) or 'DNF', math.floor(r.top), tostring(r.lastPos)))
  end)
  local okP, line = pcall(perfLine, r)
  log('PERF ' .. r.ev.title .. ': ' .. (okP and line or ('(error: ' .. tostring(line) .. ')')))
  return out
end

return R
