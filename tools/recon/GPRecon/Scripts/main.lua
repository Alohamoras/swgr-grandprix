-- GPRecon: recon for Galactic Grand Prix (DESIGN.md §10, TASKS.md §1). Test-only, not shipped. Offline only.
-- Launches campaign races from the main menu (quick race) from a plan, and logs what the design needs:
--   R1 every racer's finishing position, time and best lap      R2 who is in each race (the field)
--   R3 crash limit: does a memory-only change switch "health" off (ShouldUseHealth, VehicleHealth, wrecks)
--   R4 class speed: your part level per race, your time and top speed     R5/R6 vehicle tags, laps (dump)
-- Files in Mods/GPRecon/ (checked once a second, so no keyboard needed):
--   plan.txt   one race per line:  <event path> <car|bike|skimmer> <part level 0-10> [health=none|def|state|tune]
--   go.txt     launch the next plan line (when at the main menu)
--   auto.txt   while it exists, launch the next line 8 s after each race returns to the menu
--   dump.txt   log vehicle tag, laps, mode and track of every event in events.txt (one path per line; default: the
--              plan's events)
-- Progress: planpos.txt (next line). Log: gprecon.log. Changes only memory (build part levels, UseHealth, crash
-- allowance), always put back when the race returns to the menu. Keeps no UObject between ticks.
local DIR = (debug.getinfo(1, 'S').source:match('^@(.*[/\\])Scripts[/\\]') or '')
local LOG = DIR .. 'gprecon.log'

local function try(f, ...)
  local r = table.pack(pcall(f, ...))
  if r[1] then return table.unpack(r, 2, r.n) end
  return nil, tostring(r[2])
end
local function alive(o) return o ~= nil and try(function() return o:IsValid() end) == true end
local function log(m)
  local f = io.open(LOG, 'a')
  if f then f:write(os.date('%H:%M:%S ') .. tostring(m) .. '\n'); f:close() end
end
local function nm(o) return alive(o) and (try(function() return o:GetFName():ToString() end) or '?') or '-' end
local function addr(o) return alive(o) and try(function() return o:GetAddress() end) or nil end
local function num(v) if type(v) == 'number' and v % 1 ~= 0 then return ('%.2f'):format(v) end; return tostring(v) end
local function find(c)
  local got, out = try(FindAllOf, c), {}
  for _, o in ipairs(type(got) == 'table' and got or {}) do
    if alive(o) and not nm(o):find('^Default__') then out[#out + 1] = o end
  end
  return out
end
local function first(c) return find(c)[1] end
local function asset(path)
  local full = path .. '.' .. path:match('([^/]+)$')
  local o = try(StaticFindObject, full)
  if alive(o) then return o end
  try(LoadAsset, full)
  o = try(StaticFindObject, full)
  return alive(o) and o or nil
end
local function tag(t) local s = try(function() return t.TagName:ToString() end); return (s and s ~= 'None' and s ~= '') and s or '-' end
local function exists(f) local h = io.open(DIR .. f, 'r'); if h then h:close(); return true end; return false end
local function readAll(f) local h = io.open(DIR .. f, 'r'); if not h then return nil end; local s = h:read('a'); h:close(); return s end
local function writeAll(f, s) local h = io.open(DIR .. f, 'w'); if h then h:write(s); h:close() end end

local VEH = {
  car = { arch = 0, build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base' },
  bike = { arch = 2, build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Bike_Base' },
  skimmer = { arch = 3, build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Skimmer_Base' },
}

---------------------------------------------------------------------------------------------------- offline guard
local function online()
  local pm = first('PartyManager')
  local n = alive(pm) and try(function() return pm:GetNumPlayersInParty() end)
  if type(n) == 'number' and n > 1 then return 'party' end
  local mm = first('PlayfabOnlineMatchmaking')
  if alive(mm) and try(function() return mm:IsMatchmaking() end) == true then return 'matchmaking' end
  return nil
end

---------------------------------------------------------------------------------------------------- plan
local function planLines()
  local out = {}
  for l in (readAll('plan.txt') or ''):gmatch('[^\r\n]+') do
    if not l:match('^%s*#') and l:match('%S') then out[#out + 1] = l end
  end
  return out
end
local function parse(l)
  local path, veh, lv, rest = l:match('^%s*(%S+)%s+(%S+)%s+(%d+)%s*(.*)$')
  if not path or not VEH[veh] then return nil end
  return { path = path, veh = veh, level = tonumber(lv), health = rest:match('health=(%w+)') or 'none' }
end

---------------------------------------------------------------------------------------------------- build changes
local restore = {} -- { build path = { levels = {slot=level}, useHealth = bool } }, tune = { [i] = allowance } (numbers)
local function levels(b)
  local t = {}
  try(function() b.SlotToUpgradeLevelMap:ForEach(function(k, v) t[tonumber(k:get())] = tonumber(v:get()) end) end)
  return t
end
local function setLevels(b, want)
  local have = levels(b)
  try(function() b.SlotToUpgradeLevelMap:ForEach(function(k, v) local w = want[tonumber(k:get())]; if w then v:set(w) end end) end)
  for s = 0, 5 do if have[s] == nil and want[s] and want[s] ~= 0 then try(function() b.SlotToUpgradeLevelMap:Add(s, want[s]) end) end end
end
local function lvText(t) local p = {}; for s = 0, 5 do p[#p + 1] = tostring(t[s]) end; return table.concat(p, ',') end

local function putBack(why)
  for path, r in pairs(restore.builds or {}) do
    local b = asset(path)
    if b then
      setLevels(b, r.levels)
      if r.useHealth ~= nil then pcall(function() b.UseHealth = r.useHealth end) end
      log(('put back (%s): %s levels %s UseHealth=%s'):format(why, path:match('[^/]+$'), lvText(levels(b)), tostring(try(function() return b.UseHealth end))))
    end
  end
  restore.builds = nil
  if restore.tune then
    local rtd = asset('/Game/Griffin/Gameplay/Config/Race/DA_RaceTuneConfig')
    for _, tc in ipairs(find('GameTuneComponent')) do
      local d = try(function() return tc.RaceTuneData end)
      if alive(d) then pcall(function() d.Config.TotalCrashAllowance = restore.tune end) end
    end
    if alive(rtd) then pcall(function() rtd.Config.TotalCrashAllowance = restore.tune end) end
    log(('put back (%s): TotalCrashAllowance %s'):format(why, tostring(restore.tune)))
    restore.tune = nil
  end
end

---------------------------------------------------------------------------------------------------- race state
local PRELOADED -- os.clock() time the launch builds were loaded at the menu
local AUTO_AT -- os.clock() time to launch the next plan line (auto.txt)
-- run = { line, ev, oldGs, oldFe, phase, gs, at, startedAt, seen = {name = {...}}, top, logged... } (no objects)
local run

local function racers()
  local out = {}
  for _, ps in ipairs(find('GfnPlayerState')) do
    local rec = try(function() return ps.RaceEventComponent end)
    local name = try(function() return ps:GetPlayerName():ToString() end) or try(function() return ps.PlayerNamePrivate:ToString() end) or nm(ps)
    out[#out + 1] = { ps = ps, rec = alive(rec) and rec or nil, name = name, bot = try(function() return ps.bIsABot end) ~= false }
  end
  return out
end

local function tuneComponents(fn)
  local n = 0
  for _, tc in ipairs(find('GameTuneComponent')) do
    local d = try(function() return tc.RaceTuneData end)
    if alive(d) then n = n + 1; fn(d) end
  end
  return n
end

local function launch(line)
  local p = parse(line)
  if not p then log('plan: bad line: ' .. line); return false end
  local fe = first('FrontEndGameMode')
  if not alive(fe) then log('launch: not at the main menu'); return false end
  local why = online()
  if why then log('launch refused: ' .. why); return false end
  local e = asset(p.path)
  if not e then log('launch: event not found ' .. p.path); return false end
  local v = VEH[p.veh]
  local arch
  for _, a in ipairs(find('VehicleArchetype')) do if try(function() return tonumber(a.archetype) end) == v.arch then arch = a end end
  local b = asset(v.build)
  if not (alive(arch) and b) then log('launch: vehicle or build missing for ' .. p.veh); return false end
  restore.builds = { [v.build] = { levels = levels(b), useHealth = try(function() return b.UseHealth end) } }
  local want = {}
  for s = 0, 5 do want[s] = p.level end
  setLevels(b, want)
  if p.health == 'def' then pcall(function() b.UseHealth = false end) end
  if p.health == 'tune' then
    local rtd = asset('/Game/Griffin/Gameplay/Config/Race/DA_RaceTuneConfig')
    restore.tune = alive(rtd) and try(function() return rtd.Config.TotalCrashAllowance end) or nil
    if alive(rtd) then pcall(function() rtd.Config.TotalCrashAllowance = 99 end) end
    log(('tune: DA_RaceTuneConfig %s, TotalCrashAllowance %s -> 99'):format(alive(rtd) and 'found' or 'NOT found', tostring(restore.tune)))
  end
  local evMode, track = nm(try(function() return e.EventMode end)), nm(try(function() return e.TrackDef end))
  local ok, err = try(function() fe:LaunchQuickRace(arch, e, b); return true end)
  if not ok then log('launch failed: ' .. tostring(err)); putBack('launch failed'); return false end
  log(('==== LAUNCH %s | %s parts %d health=%s | mode %s track %s laps %s tag %s | build %s UseHealth=%s'):format(
    p.path:match('[^/]+$'), p.veh, p.level, p.health, evMode, track, num(try(function() return e.LapCount end)),
    tag(try(function() return e.VehicleTypeTag end)), lvText(levels(b)), tostring(try(function() return b.UseHealth end))))
  run = { p = p, oldGs = addr(first('RacingGameState')), oldFe = addr(fe), phase = 'loading', at = os.clock(),
    seen = {}, top = 0, health = {}, order = 0 }
  return true
end

local function watch()
  if not run then return end
  local now = os.clock()
  if run.phase == 'loading' then
    for _, gs in ipairs(find('RacingGameState')) do
      if addr(gs) ~= run.oldGs then
        local ksl = try(StaticFindObject, '/Script/Engine.Default__KismetSystemLibrary')
        local standalone = alive(ksl) and try(function() return ksl:IsStandalone(gs) end)
        log('race world loaded, standalone=' .. tostring(standalone))
        if standalone == false then log('NOT offline - stopping'); putBack('not offline'); run = nil; return end
        run.gs, run.phase = addr(gs), 'racing'
        return
      end
    end
    if now - run.at > 120 then log('no race world after 120 s'); putBack('timeout'); run = nil end
    return
  end
  local gs
  for _, g in ipairs(find('RacingGameState')) do if addr(g) == run.gs then gs = g end end
  local fe = first('FrontEndGameMode')
  if alive(fe) and (not gs or addr(fe) ~= run.oldFe) then
    -- back at the menu: the summary (R1 / R4 / R6)
    local rows = {}
    for name, s in pairs(run.seen) do rows[#rows + 1] = { name = name, s = s } end
    table.sort(rows, function(a, b) return (a.s.pos or 99) < (b.s.pos or 99) end)
    log(('RESULTS %s (%s parts %d health=%s), your top speed %d kph:'):format(run.p.path:match('[^/]+$'), run.p.veh,
      run.p.level, run.p.health, math.floor(run.top)))
    for _, r in ipairs(rows) do
      local s = r.s
      log(('  %2s. %-18s %s time %s best lap %s %s%s'):format(tostring(s.pos), r.name, s.bot and 'bot' or 'YOU',
        num(s.time), num(s.lap), s.finished and 'finished' or 'NOT finished', s.wrecked and ' WRECKED' or ''))
    end
    putBack('main menu')
    run.done = os.clock()
    local auto = exists('auto.txt')
    run = nil
    if auto then AUTO_AT = os.clock() + 8 end
    return
  end
  if not gs then return end
  local rs = racers()
  local started = try(function() return gs.bIsRaceStarted end) == true
  -- at load: R2 the field, and the 'state' experiment on your build copy
  if not run.grid and #rs >= 2 then
    run.grid = true
    local names = {}
    for _, r in ipairs(rs) do names[#names + 1] = (r.bot and '' or '*') .. tostring(r.name) end
    table.sort(names)
    log(('FIELD (%d): %s'):format(#rs, table.concat(names, ', ')))
  end
  if run.p.health == 'state' and not run.stateDone then
    for _, r in ipairs(rs) do
      if not r.bot then
        local n = try(function() return r.ps.RacerBuildState.VehicleBuilds:GetArrayNum() end) or 0
        if n > 0 then
          run.stateDone = true
          local ok = pcall(function() r.ps.RacerBuildState.VehicleBuilds:ForEach(function(_, el) el:get().UseHealth = false end) end)
          log('state: your RacerBuildState copies UseHealth=false: ' .. tostring(ok))
        end
      end
    end
  end
  if run.p.health == 'tune' and not run.tuneDone then
    run.tuneDone = true
    local n = tuneComponents(function(d)
      if restore.tune == nil then restore.tune = try(function() return d.Config.TotalCrashAllowance end) end
      pcall(function() d.Config.TotalCrashAllowance = 99 end)
    end)
    log('tune: TotalCrashAllowance=99 on ' .. n .. ' tune objects')
  end
  if not started then return end
  run.startedAt = run.startedAt or now
  -- R3: 3 s after the start, everyone's health state
  if not run.healthLogged and now - run.startedAt > 3 then
    run.healthLogged = true
    local parts = {}
    for _, r in ipairs(rs) do
      if r.rec then
        parts[#parts + 1] = ('%s%s useHealth=%s health=%s/%s'):format(r.bot and '' or '*', tostring(r.name),
          tostring(try(function() return r.rec:ShouldUseHealth() end)), tostring(try(function() return r.rec.VehicleHealth end)),
          tostring(try(function() return r.rec.StartingVehicleHealth end)))
      end
    end
    local allow = {}
    tuneComponents(function(d) allow[#allow + 1] = tostring(try(function() return d.Config.TotalCrashAllowance end)) end)
    log('HEALTH ' .. table.concat(parts, ' | ') .. ' || crash allowance per tune object: ' .. table.concat(allow, ','))
  end
  for _, r in ipairs(rs) do
    if r.rec then
      local s = run.seen[r.name] or { bot = r.bot }
      run.seen[r.name] = s
      local pos = try(function() return tonumber(r.rec.EventPosition) end)
      if pos and pos > 0 and not s.finished then s.pos = pos end
      local wrecked = try(function() return r.rec.bHasVehicleWrecked end) == true
      if wrecked and not s.wrecked then s.wrecked = true; log(('WRECKED: %s (position %s)'):format(tostring(r.name), tostring(pos))) end
      if not s.finished and try(function() return r.rec.bHasFinishedEvent end) == true then
        s.finished, s.pos = true, pos
        s.time = try(function() return r.rec.EventFinishTime end)
        s.lap = try(function() return r.rec.BestLapTime end)
        run.order = run.order + 1
        log(('finish #%d: %s position %s time %s best lap %s dnf=%s'):format(run.order, tostring(r.name), tostring(pos),
          num(s.time), num(s.lap), tostring(try(function() return r.rec:IsDNF() end))))
      end
      if not r.bot then
        local h = try(function() return r.rec.VehicleHealth end)
        if h ~= nil and h ~= run.health.you then
          if run.health.you ~= nil then log(('your health %s -> %s'):format(tostring(run.health.you), tostring(h))) end
          run.health.you = h
        end
        local pawn = try(function() return r.ps.PawnPrivate end)
        local kph = alive(pawn) and try(function() local v = pawn:GetVelocity(); return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) * 0.036 end) or 0
        if kph > run.top then run.top = kph end
      end
    end
  end
end

---------------------------------------------------------------------------------------------------- dump (R5/R6)
local function dump()
  log('==== DUMP plan events')
  local seen = {}
  local list = {}
  for l in (readAll('events.txt') or ''):gmatch('[^\r\n]+') do
    if l:match('^%s*/Game/') then list[#list + 1] = { path = l:match('^%s*(%S+)') } end
  end
  if #list == 0 then for _, l in ipairs(planLines()) do list[#list + 1] = parse(l) end end
  for _, p in ipairs(list) do
    if p and not seen[p.path] then
      seen[p.path] = true
      local e = asset(p.path)
      if e then
        log(('event %s | name %s | tag %s | laps %s | mode %s | track %s | grid %s | custom opponents %s'):format(
          p.path:match('[^/]+$'), tostring(try(function() return e.PlayerFacingName:ToString() end)),
          tag(try(function() return e.VehicleTypeTag end)), num(try(function() return e.LapCount end)),
          nm(try(function() return e.EventMode end)), nm(try(function() return e.TrackDef end)),
          nm(try(function() return e.GridMakeup end)), tostring(try(function() return e.CustomOpponents:GetArrayNum() end))))
      else
        log('event NOT FOUND ' .. p.path)
      end
    end
  end
  log('==== DUMP done')
end

---------------------------------------------------------------------------------------------------- loop
local tick = 0
LoopInGameThreadWithDelay(250, function()
  tick = tick + 1
  local ok, err = pcall(watch)
  if not ok then log('watch error: ' .. tostring(err)) end
  if tick % 4 ~= 0 then return false end
  local go = exists('go.txt')
  if go then os.remove(DIR .. 'go.txt') end
  if exists('dump.txt') then os.remove(DIR .. 'dump.txt'); pcall(dump) end
  -- keep all three launch builds loaded at the menu, so TestAutopilot (v1.3) can arm the bike / skimmer ones too
  if not run and alive(first('FrontEndGameMode')) and not PRELOADED then
    for _, v in pairs(VEH) do asset(v.build) end
    PRELOADED = os.clock()
    log('launch builds loaded (car, bike, skimmer)')
  end
  if go and (not PRELOADED or os.clock() - PRELOADED < 3) then
    writeAll('go.txt', '') -- not yet: TestAutopilot needs a moment to arm the builds; try again next second
    go = false
  end
  if not run and (go or (AUTO_AT and os.clock() >= AUTO_AT and exists('auto.txt'))) then
    AUTO_AT = nil
    local lines = planLines()
    local pos = tonumber(readAll('planpos.txt') or '') or 1
    if pos > #lines then log('plan finished (' .. #lines .. ' races)')
    else
      local ok2, launched = pcall(launch, lines[pos])
      if not ok2 then log('launch error: ' .. tostring(launched)) end
      if ok2 and launched then writeAll('planpos.txt', tostring(pos + 1)) end
    end
  end
  return false
end)

log('GPRecon loaded (plan.txt / go.txt / auto.txt / dump.txt)')
