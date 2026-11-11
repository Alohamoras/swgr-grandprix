-- RaceFlowSpike v1 (test-only, 2026-11-11, TASKS.md B9 and B6). Report only: nothing here goes into the Grand Prix
-- mod. Two spikes in one mod, each with its own key, log and README section (README.md next to Scripts/).
--
-- B9 (F9, in an offline race): "the standings at the end of the race, then straight into the next race, no main menu".
--   (a) the results screen: which results widget is up, and can a plain text panel (our standings) be added to it?
--   (b) the next race from the race world, one route per F9 press (CONFIG.B9.PLAN):
--       A = swap the event in the race's recipe (EventRecipeSubsystem.ActiveRecipe.recipe.EventStages[] and the race
--           state's EventRecipe copy: AuthoredEvent, TrackDef, LapCount, trackConditions), then the game's restart:
--           the pause menu's RETRY RACE button event when a pause menu is up, else ARacingGameMode:RequestResetRace().
--       B = FrontEndGameMode:LaunchQuickRace (race.lua's launch) called from the race world: on a live front-end game
--           mode if there is one (there shouldn't be), else on its default object (CONFIG.B9.LAUNCH_ON_CDO).
--       T = UArcadeSubsystem:TravelToEvent(an arcade event) (a game-instance subsystem, so alive in the race world).
--       After a route: one sweep every 2 s for 90 s: a new race world (its event name), a reset of this one, or the
--       main menu.
-- B6 (F10 at the main menu): a two-car grid on a NORMAL event (The War Fields) with a chosen opponent (Sen Fira).
--   Logs the event's grid make-up (GridMakeup.Entries[]), the Showdown's for reference, CharacterList.Opponents, then
--   trims the field per press (CONFIG.B6.PLAN) and launches with race.lua's LaunchQuickRace. The grid is logged at
--   race load (the recipe's Racers[], the stage's game-mode variant grid) and 10 s in (the race state's Racers[]).
--   Originals go into b6_state.lua BEFORE anything changes; put back at the next main menu, or at the next boot.
--   Ctrl+F10 = the same launch with nothing trimmed (a plain 12-car race for B9 tests).
--
-- House rules: LoopInGameThreadWithDelay only, no RegisterHook (key binds and NotifyOnNewObject only set flags), no
-- soft pointers / TMaps read (FRaceEventInstance holds a soft-pointer array, ExtraWinCriteria: never touched; no
-- struct is read whole), no UObject kept between ticks (path + address), every engine call in pcall, a handful of
-- lookups per action, nothing per tick in a race (one sweep every 2 s only while a route is being watched).

---------------------------------------------------------------------------------------------------------------------
-- CONFIG
local EV = '/Game/Griffin/Gameplay/Events/Planets/'
local CAR = { arch = 0, build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base' } -- (race.lua's landspeeder)
local CONFIG = {
  KEYS = { B9 = 'F9', B6 = 'F10' }, -- (TestAutopilot also uses F9: it forces a garbage collection. README.md)
  B9 = {
    ON = true,
    -- one route per F9 press since the game started; past the end of the list F9 only probes the results screen
    PLAN = { 'A', 'B' },
    -- the "next race" (A writes it into the recipe; B launches it; same planet and layout as The War Fields, so a
    -- restart in the same world has a chance)
    NEXT_EVENT = EV .. 'Mastiff/Loop_A/EVT_MAS_LOOP_A_SHORT_02',
    SWAP = { AuthoredEvent = true, TrackDef = true, LapCount = true, trackConditions = true },
    RESTART = 'auto',     -- A's restart: 'auto' (pause menu's RETRY RACE if a pause menu is up, else the game mode),
                          -- 'mode' (ARacingGameMode:RequestResetRace) or 'pause' (the pause menu's button only)
    PANEL = true,         -- (a): add a text panel to the results screen when F9 finds one
    PANEL_HOLD_S = 3,     -- the route runs this long after the panel went up (screenshot time; the results screen
                          -- may move on to the main menu by itself ~7 s after it appears)
    LAUNCH_ON_CDO = true, -- B: allowed to call LaunchQuickRace on the default FrontEndGameMode (riskiest step)
    VEHICLE = CAR,        -- B's launch vehicle and build
    ARCADE_EVENT = '/Game/Griffin/Gameplay/Arcade/Events/TimeTrial/EVT_ARC_TT_CAR_MAS_A_SHORT_02', -- T only
    WATCH_S = 90,         -- after a route: how long to watch for a new race world / a reset / the main menu
  },
  B6 = {
    ON = true,
    EVENT = EV .. 'Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD', -- The War Fields
    OPPONENT = 'Thrall',  -- DA_Racer_<key>: Sen Fira
    -- one entry per F10 press since the game started (Ctrl+F10 doesn't count):
    --   'grid+front' = the event's grid make-up summed to GRID_TOTAL, the opponent moved to Opponents[1] (list kept)
    --   'grid+only'  = the grid make-up as above, Opponents = { opponent } (list trimmed to one)
    --   'only'       = Opponents = { opponent }, grid make-up untouched (riskiest: 12 slots, 1 name)
    PLAN = { 'grid+front', 'grid+only', 'only' },
    GRID_TOTAL = 2,       -- the make-up's NumEntrants sum (whether the player counts is one of the questions)
    ADD_ENTRY = true,     -- the event has no make-up entries: add one { PlayerChoice, GRID_TOTAL } (emptied after)
    REFERENCE = EV .. 'Whippet/FINALBOSS/EVT_WHP_SHORTBOSS_FAIR', -- the Showdown: a known 2-car grid, logged only
    VEHICLE = CAR,
    SETTLE_S = 10,        -- the grid read again this long after the race world appeared
  },
}
local VERSION = 'v1.0'
---------------------------------------------------------------------------------------------------------------------

local here = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
local dir = (here:match('^(.*)[/\\][^/\\]+$') or '.'):match('^(.*)[/\\][Ss]cripts$') or '.'
local FILES = { B9 = dir .. '/raceflow-b9.log', B6 = dir .. '/raceflow-b6.log' }
local STATE = dir .. '/b6_state.lua'
local function logTo(which, s)
  print(('[RaceFlowSpike %s] %s\n'):format(which, s))
  local f = io.open(FILES[which], 'a')
  if f then f:write(os.date('%Y-%m-%d %H:%M:%S ') .. s .. '\n'); f:close() end
end
local function L9(s) logTo('B9', s) end
local function L6(s) logTo('B6', s) end

-- (always ONE value back, nil on failure: `tostring(try(...))` with no value at all raises)
local function try(f, ...) local ok, r = pcall(f, ...); if ok then return r end return nil end
local function alive(o) return o ~= nil and try(function() return o:IsValid() end) == true end
local function addr(o) return alive(o) and try(function() return o:GetAddress() end) or nil end
local function oname(o) return alive(o) and (try(function() return o:GetFName():ToString() end) or '?') or 'none' end
local function cname(o) return alive(o) and (try(function() return o:GetClass():GetFName():ToString() end) or '?') or 'none' end
local function full(o) return alive(o) and (try(function() return o:GetFullName() end) or '?') or 'none' end
local function opath(o) return (full(o):match('^%S+%s+(.+)$')) end
local function text(o, f) local s = try(function() return o[f]:ToString() end); return (type(s) == 'string' and s ~= '') and s or nil end
local function tagName(t) local s = try(function() return t.TagName:ToString() end); return (s and s ~= 'None' and s ~= '') and s or 'none' end
local function num(v) return tonumber(v) end
local function ref(o) local p, a = opath(o), addr(o); return (p and a) and { path = p, addr = a } or nil end
local function deref(r)
  if not r then return nil end
  local o = try(StaticFindObject, r.path)
  return (alive(o) and addr(o) == r.addr) and o or nil
end
-- every live, non-default object of a class (a full sweep, ~10 ms) / the first one
local function find(cls)
  local out = {}
  for _, o in ipairs(try(FindAllOf, cls) or {}) do
    if alive(o) and not oname(o):find('^Default__') then out[#out + 1] = o end
  end
  return out
end
local function first(cls) return find(cls)[1] end
-- an asset by package path (/Game/.../Name), loaded when needed
local function asset(path)
  local short = path:match('([^/]+)$')
  local o = try(StaticFindObject, path .. '.' .. short)
  if alive(o) then return o end
  try(LoadAsset, path .. '.' .. short)
  o = try(StaticFindObject, path .. '.' .. short)
  return alive(o) and o or nil
end
local function lib(name, pkg) local o = try(StaticFindObject, '/Script/' .. (pkg or 'Engine') .. '.Default__' .. name); return alive(o) and o or nil end
local function arrN(a) return a and (num(try(function() return a:GetArrayNum() end)) or 0) or 0 end
local ARCH = { [0] = 'Car', [1] = 'Plane', [2] = 'Bike', [3] = 'Skimmer' }
local GRIDTYPE = { [0] = 'Car', [1] = 'Plane', [2] = 'Bike', [3] = 'Skimmer', [4] = 'PlayerChoice' }
-- ESimpleRaceGameModeState (Griffin_enums.hpp), for the race's flow state ids
local RSTATE = { [0] = 'Root', [1] = 'LoadingPhase', [2] = 'InRacePhase', [3] = 'PrepareForEventStart', [4] = 'Countdown',
  [5] = 'Racing', [6] = 'PostRacePhase', [9] = 'WaitForPlayersToArrive', [10] = 'WaitForLevelToLoad',
  [11] = 'WaitForClientsToBeReady', [12] = 'PreRacePhase', [13] = 'IntroSequence', [14] = 'Outro', [15] = 'Results',
  [17] = 'IgnitionSequence', [18] = 'RollingStart', [23] = 'IntermissionPhase', [24] = 'RollingRestart', [25] = 'SideBets',
  [28] = 'WaitForIntroMovieToFinish' }

for _, w in ipairs({ 'B9', 'B6' }) do
  logTo(w, ('RaceFlowSpike %s loaded (keys: B9 %s in a race; B6 %s at the main menu, Ctrl+%s = plain launch)'):format(
    VERSION, CONFIG.KEYS.B9, CONFIG.KEYS.B6, CONFIG.KEYS.B6))
end
L9(('plan %s; next event %s; restart %s; panel %s'):format(table.concat(CONFIG.B9.PLAN, ' | '),
  CONFIG.B9.NEXT_EVENT:match('([^/]+)$'), CONFIG.B9.RESTART, tostring(CONFIG.B9.PANEL)))
L6(('plan %s; event %s; opponent DA_Racer_%s; grid total %d'):format(table.concat(CONFIG.B6.PLAN, ' | '),
  CONFIG.B6.EVENT:match('([^/]+)$'), CONFIG.B6.OPPONENT, CONFIG.B6.GRID_TOTAL))

---------------------------------------------------------------------------------------------------------------------
-- shared: the offline guard (race.lua's), the race's recipe, the racers

-- at the main menu and offline: the FrontEndGameMode, or nil + why (race.lua R.atMainMenu)
local function atMainMenu()
  local fe = first('FrontEndGameMode')
  if not alive(fe) then return nil, 'not at the main menu' end
  local known = false
  local pm = first('PartyManager')
  if alive(pm) then
    local n = num(try(function() return pm:GetNumPlayersInParty() end))
    if n then known = true; if n > 1 then return nil, 'in a party of ' .. n end end
  end
  local mm = first('PlayfabOnlineMatchmaking')
  if alive(mm) then
    local busy = try(function() return mm:IsMatchmaking() end)
    if busy ~= nil then known = true; if busy == true then return nil, 'matchmaking is running' end end
  end
  if not known then
    local gi = first('GfnGameInstance')
    if num(alive(gi) and try(function() return gi.PrimaryFlow end)) == 4 then return nil, 'multiplayer flow' end
  end
  return fe
end
local function standalone(gs)
  local ksl = lib('KismetSystemLibrary')
  return alive(ksl) and try(function() return ksl:IsStandalone(gs) end) == true
end
local function pilotName(ps)
  local n = text(ps, 'PlayerNamePrivate') or try(function() return ps:GetPlayerName():ToString() end)
  return (type(n) == 'string' and n ~= '') and n or '?'
end
-- one stage of a recipe (FEventRecipe.EventStages[i]): named fields only, never the whole struct (it holds a
-- soft-pointer array). Returns a one-line description.
local function stageLine(st)
  if not st then return 'no stage' end
  local gmv = try(function() return st.GameModeVariant end)
  return ('event %s, track %s, laps %s, conditions %s, vehicle %s, internal "%s", mode variant %s'):format(
    oname(try(function() return st.AuthoredEvent end)), oname(try(function() return st.TrackDef end)),
    tostring(num(try(function() return st.LapCount end))), tagName(try(function() return st.trackConditions end)),
    ARCH[num(try(function() return st.vehicleType end)) or -1] or '?',
    tostring(try(function() return st.InternalName:ToString() end)), oname(gmv))
end
-- a recipe (FEventRecipe) + its state's ActiveStage -> the active stage (struct wrapper), its 1-based index, the count
local function activeStage(recipe, activeIx)
  local stages = try(function() return recipe.EventStages end)
  local n = arrN(stages)
  if n == 0 then return nil, nil, 0 end
  local i = math.max(1, math.min(n, (num(activeIx) or 0) + 1))
  return try(function() return stages[i] end), i, n
end
-- FRaceGridMakeup -> 'Car x4 + Bike x4 (sum 8)' (the plain bytes only)
local function gridLine(gm)
  local entries = try(function() return gm.Entries end)
  local n, parts, sum = arrN(entries), {}, 0
  for i = 1, n do
    local t = num(try(function() return entries[i].EntryType end))
    local c = num(try(function() return entries[i].NumEntrants end)) or 0
    parts[#parts + 1] = ('%s x%d'):format(GRIDTYPE[t or -1] or tostring(t), c)
    sum = sum + c
  end
  return n == 0 and 'no entries' or ('%s (sum %d)'):format(table.concat(parts, ' + '), sum), n, sum
end
-- the recipe's racers: '1:Shade(you)/Car 2:Sen Fira/Bike ...', count
local function racersLine(racers)
  local n, out = arrN(racers), {}
  for i = 1, n do
    local e = racers[i]
    local p = try(function() return e.Player end)
    local pilot = try(function() return e.Pilot end)
    local you = alive(p) and try(function() return p.bIsABot end) == false
    out[#out + 1] = ('%d:%s%s/%s'):format(i, text(pilot, 'CharacterName') or oname(pilot), you and '(you)' or '',
      ARCH[num(try(function() return e.vehicleType end)) or -1] or '?')
  end
  return table.concat(out, ' '), n
end
-- every racer in the race (one sweep of the player states): sorted by position, for the log and the panel
local function standings()
  local list = {}
  for _, ps in ipairs(find('GfnPlayerState')) do
    local rec = try(function() return ps.RaceEventComponent end)
    if alive(rec) then
      list[#list + 1] = { name = pilotName(ps), you = try(function() return ps.bIsABot end) == false,
        pos = num(try(function() return rec.EventPosition end)) or 99,
        done = try(function() return rec.bHasFinishedEvent end) == true }
    end
  end
  table.sort(list, function(a, b) return a.pos < b.pos end)
  return list
end
-- the race's flow state(s): every GameFlowStateMachineComponent's records -> 'Results(15) ...'
local function flowStates()
  local out = {}
  for _, c in ipairs(find('GameFlowStateMachineComponent')) do
    local recs = try(function() return c.ActiveStateMachines end)
    for i = 1, arrN(recs) do
      local id = num(try(function() return recs[i].CurrentStateId end))
      out[#out + 1] = ('%s:%s(%s)'):format(oname(try(function() return c:GetOwner() end)), RSTATE[id or -1] or '?', tostring(id))
    end
  end
  return #out > 0 and table.concat(out, ' ') or 'none found'
end

---------------------------------------------------------------------------------------------------------------------
-- B6: the two-car grid. The originals in b6_state.lua first; put back at the next main menu or the next boot.

local function serialize(v, ind)
  ind = ind or ''
  local t = type(v)
  if t == 'number' or t == 'boolean' then return tostring(v) end
  if t == 'string' then return ('%q'):format(v) end
  if t ~= 'table' then return 'nil' end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) if type(a) == type(b) then return a < b end return type(a) == 'number' end)
  local parts = {}
  for _, k in ipairs(keys) do
    local key = type(k) == 'number' and ('[' .. k .. ']') or (k:match('^[%a_][%w_]*$') and k or ('[%q]'):format(k))
    parts[#parts + 1] = ind .. '  ' .. key .. ' = ' .. serialize(v[k], ind .. '  ') .. ',\n'
  end
  return '{\n' .. table.concat(parts) .. ind .. '}'
end
local function writeState(st)
  local f = io.open(STATE .. '.tmp', 'w')
  if not f then return false end
  f:write('-- RaceFlowSpike B6: what to put back (written before any change)\nreturn ' .. serialize(st) .. '\n')
  f:close()
  os.remove(STATE)
  return os.rename(STATE .. '.tmp', STATE) == true
end
local function readState()
  local fn = loadfile(STATE, 't', {})
  local ok, st = pcall(fn or function() end)
  return (ok and type(st) == 'table') and st or nil
end

local LIST = '/Game/Griffin/Narrative/CharacterDefs/DA_CharacterList'
local RACERS = '/Game/Griffin/Narrative/CharacterDefs/Racers/DA_Racer_'
local function findList() -- (racer.lua's): the loaded asset, else through the game instance, else by path
  local l = first('CharacterList')
  if alive(l) then return l end
  local gi = first('GfnGameInstance')
  l = alive(gi) and try(function() return gi.CharacterList end) or nil
  if alive(l) then return l end
  return asset(LIST)
end
local function defPath(o) -- 'RacerDef /Game/.../DA_Racer_X.DA_Racer_X' -> '/Game/.../DA_Racer_X'
  local p = opath(o)
  return p and (p:match('^(.-)%.[^/]+$') or p) or nil
end
local function opponents(list)
  local out = {}
  local arr = try(function() return list.Opponents end)
  for i = 1, arrN(arr) do out[i] = defPath(try(function() return arr[i] end)) or '' end
  return out
end
local function oppLine(paths)
  local o = {}
  for i, p in ipairs(paths) do o[#o + 1] = i .. ':' .. (p:match('DA_Racer_([%w_]+)$') or p) end
  return #o .. ' [' .. table.concat(o, ' ') .. ']'
end
local function entries(e)
  local out = {}
  local arr = try(function() return e.GridMakeup.Entries end)
  for i = 1, arrN(arr) do
    out[i] = { t = num(try(function() return arr[i].EntryType end)), n = num(try(function() return arr[i].NumEntrants end)) }
  end
  return out
end
-- the opponents list made equal to the list of paths (only the slots that differ are written; a longer list is
-- emptied and filled again). Returns true when it reads back equal.
local function setOpponents(list, paths)
  local arr = try(function() return list.Opponents end)
  if not arr then return false end
  local cur = opponents(list)
  if #cur > #paths then pcall(function() arr:Empty() end); cur = {} end
  for i, p in ipairs(paths) do
    if cur[i] ~= p then
      local d = asset(p)
      if d then pcall(function() list.Opponents[i] = d end) end
    end
  end
  local now = opponents(list)
  if #now ~= #paths then return false end
  for i, p in ipairs(paths) do if now[i] ~= p then return false end end
  return true
end

local b6 = { press = 0 }
local function b6Restore(why)
  local st = readState()
  if not st then return end
  local okE, okO = 'n/a', 'n/a'
  if st.event and st.entries then
    local e = asset(st.event)
    if not e then okE = 'event not found'
    elseif st.added then
      pcall(function() e.GridMakeup.Entries:Empty() end)
      okE = (#entries(e) == 0) and 'emptied (added entry removed)' or 'FAILED (entry still there)'
    else
      for i, v in ipairs(st.entries) do pcall(function() e.GridMakeup.Entries[i].NumEntrants = v.n end) end
      local now, same = entries(e), true
      for i, v in ipairs(st.entries) do if not now[i] or now[i].n ~= v.n then same = false end end
      okE = (same and 'done' or 'FAILED') .. ' -> ' .. gridLine(try(function() return e.GridMakeup end))
    end
  end
  if st.opponents then
    local list = findList()
    if not list then okO = 'character list not found'
    else okO = (setOpponents(list, st.opponents) and 'done' or 'FAILED') .. ' -> ' .. oppLine(opponents(list)) end
  end
  os.remove(STATE)
  L6(('put back (%s): grid make-up %s; Opponents %s'):format(why, okE, okO))
end

-- F10 / Ctrl+F10 at the main menu. plain = launch without trimming anything.
local expect6 = nil -- { at, mode } a B6 launch: the next race world is ours
local tick
local function b6Launch(plain)
  local fe, why = atMainMenu()
  if not fe then L6('F10: refused: ' .. why); return end
  if readState() then L6('F10: an earlier change was still to be put back - done first'); b6Restore('before launch') end
  local e = asset(CONFIG.B6.EVENT)
  local list = findList()
  local opp = asset(RACERS .. CONFIG.B6.OPPONENT)
  if not (e and list and opp) then
    L6(('F10: refused: event %s, character list %s, opponent %s'):format(tostring(e ~= nil), tostring(list ~= nil), tostring(opp ~= nil)))
    return
  end
  local oppPath = RACERS .. CONFIG.B6.OPPONENT
  -- what the game has (logged every press)
  local refE = asset(CONFIG.B6.REFERENCE)
  if refE then
    L6(('reference %s: grid make-up %s; CustomOpponents %d; laps %s'):format(CONFIG.B6.REFERENCE:match('([^/]+)$'),
      (gridLine(try(function() return refE.GridMakeup end))), arrN(try(function() return refE.CustomOpponents end)),
      tostring(num(try(function() return refE.LapCount end)))))
  end
  local gl = gridLine(try(function() return e.GridMakeup end))
  L6(('event %s: grid make-up %s; CustomOpponents %d; laps %s; mode %s; vehicle tag %s'):format(CONFIG.B6.EVENT:match('([^/]+)$'),
    gl, arrN(try(function() return e.CustomOpponents end)), tostring(num(try(function() return e.LapCount end))),
    oname(try(function() return e.EventMode end)), tagName(try(function() return e.VehicleTypeTag end))))
  local consts = lib('GfnConstantFunctions', 'Griffin')
  L6(('constants: GetMaxRacersInAnEvent %s, GetMaxRacersPerTeam %s, GetMaxTeamsInAnEvent %s'):format(
    tostring(alive(consts) and try(function() return consts:GetMaxRacersInAnEvent() end)),
    tostring(alive(consts) and try(function() return consts:GetMaxRacersPerTeam() end)),
    tostring(alive(consts) and try(function() return consts:GetMaxTeamsInAnEvent() end))))
  local origOpp, origEnt = opponents(list), entries(e)
  L6(('CharacterList %s: Player %s; Opponents %s; opponent wanted %s (%s)'):format(oname(list),
    tostring((defPath(try(function() return list.Player end)) or '?'):match('DA_Racer_([%w_]+)$')), oppLine(origOpp),
    CONFIG.B6.OPPONENT, text(opp, 'CharacterName') or '?'))

  local mode = 'plain'
  if not plain then
    b6.press = b6.press + 1
    mode = CONFIG.B6.PLAN[b6.press]
    if not mode then L6(('F10 press %d: plan done, nothing more to try (Ctrl+F10 still launches plainly)'):format(b6.press)); return end
    local doGrid, oppMode = mode:find('grid') ~= nil, mode:match('(%a+)$')
    if oppMode == 'grid' then oppMode = nil end
    -- the originals, on disk before anything changes
    local st = { event = CONFIG.B6.EVENT, entries = origEnt, added = (#origEnt == 0 and doGrid and CONFIG.B6.ADD_ENTRY) or nil,
      opponents = origOpp, mode = mode, at = os.date('%Y-%m-%d %H:%M:%S') }
    if not writeState(st) then L6('F10: refused: could not write ' .. STATE); return end
    L6(('F10 press %d: mode %s (originals saved to b6_state.lua)'):format(b6.press, mode))
    local gridOk = true
    if doGrid then
      local want = CONFIG.B6.GRID_TOTAL
      if #origEnt == 0 then
        if CONFIG.B6.ADD_ENTRY then
          local ok, err = pcall(function() e.GridMakeup.Entries[1] = { EntryType = 4, NumEntrants = want } end)
          L6(('grid: the event has no make-up entries; added { PlayerChoice, %d }: %s'):format(want, ok and 'written' or ('FAILED ' .. tostring(err))))
        else
          L6('grid: the event has no make-up entries and ADD_ENTRY is off: grid left alone')
        end
      else
        -- the first entry takes the whole total, the others 0 (entry types kept)
        for i = 1, #origEnt do
          local n = i == 1 and want or 0
          local ok, err = pcall(function() e.GridMakeup.Entries[i].NumEntrants = n end)
          if not ok then L6(('grid: entry %d NumEntrants -> %d FAILED %s'):format(i, n, tostring(err))) end
        end
      end
      local line, _, sum = gridLine(try(function() return e.GridMakeup end))
      gridOk = sum == want
      L6(('grid: make-up now %s -> %s'):format(line, gridOk and 'as wanted' or 'NOT as wanted'))
    end
    if oppMode == 'front' then
      local paths, at = {}, nil
      for i, p in ipairs(origOpp) do paths[i] = p; if p == oppPath then at = i end end
      if at then paths[1], paths[at] = paths[at], paths[1] else paths[1] = oppPath end
      local ok = setOpponents(list, paths)
      L6(('Opponents: %s to the front (was at %s): %s -> %s'):format(CONFIG.B6.OPPONENT, tostring(at or 'none'),
        ok and 'done' or 'FAILED', oppLine(opponents(list))))
    elseif oppMode == 'only' then
      if doGrid and not gridOk then
        L6('Opponents: NOT trimmed: the grid make-up did not take, and 12 slots with one name could crash the load')
      else
        local ok = setOpponents(list, { oppPath })
        L6(('Opponents: trimmed to %s only: %s -> %s'):format(CONFIG.B6.OPPONENT, ok and 'done' or 'FAILED', oppLine(opponents(list))))
      end
    end
  else
    L6('Ctrl+F10: plain launch, nothing changed')
  end

  -- the launch: race.lua's call
  local v = CONFIG.B6.VEHICLE
  local arch
  for _, a in ipairs(find('VehicleArchetype')) do if num(try(function() return a.archetype end)) == v.arch then arch = a; break end end
  local build = asset(v.build)
  if not (alive(arch) and build) then L6('launch: vehicle archetype or build not found'); b6Restore('launch refused'); return end
  local ok, err = pcall(function() fe:LaunchQuickRace(arch, e, build) end)
  L6(('LAUNCH %s (%s, %s): %s'):format(CONFIG.B6.EVENT:match('([^/]+)$'), mode, ARCH[v.arch], ok and 'sent' or ('FAILED ' .. tostring(err))))
  if not ok then b6Restore('launch failed'); return end
  expect6 = { at = tick, mode = mode }
end

---------------------------------------------------------------------------------------------------------------------
-- B9 (a): the results screen and our panel

local RESULTS = { 'WBP_SimpleRaceResultsScreen_C', 'WBP_Simple_RaceResultsPanel_C', 'WBP_Simple_EliminatorResultsPanel_C',
  'WBP_Simple_ShakedownResultsPanel_C', 'WBP_RacingMemoryResults_C', 'WBP_Shakedown_Results_Presentation_C' }
local function shown(w)
  local vis = num(try(function() return w:GetVisibility() end))
  return ('visibility %s, IsVisible %s, IsInViewport %s'):format(tostring(vis), tostring(try(function() return w:IsVisible() end)),
    tostring(try(function() return w:IsInViewport() end)))
end
-- which results widgets exist now (one FindFirstOf each: ~6 sweeps, once per F9). Returns the screen to draw on.
local function resultsProbe(gs)
  local found, screen = {}, nil
  for _, cls in ipairs(RESULTS) do
    local w = first(cls)
    if alive(w) then
      found[#found + 1] = ('%s (%s; %s)'):format(cls, oname(w), shown(w))
      if not screen and cls == 'WBP_SimpleRaceResultsScreen_C' then screen = w end
    end
  end
  local rules = alive(gs) and try(function() return gs.ModeRules end)
  local tbl = alive(rules) and try(function() return rules.ResultsTableWidget end)
  L9(('results widgets: %s; the mode rules (%s) name ResultsTableWidget = %s'):format(#found > 0 and table.concat(found, ' | ') or 'none',
    cname(rules), oname(tbl)))
  return screen
end
-- a Border + TextBlock built into the screen's own widget tree, added to the panel that holds CONTINUE (FreeRace's
-- RETRY button goes there too), else to the tree's root panel. Nothing kept: the screen goes with the race world.
local function addPanel(w, lines)
  local tree = try(function() return w.WidgetTree end)
  if not alive(tree) then return false, 'the screen has no widget tree' end
  local cont = try(function() return w.WBP_Common_Btn_Continue end)
  local host = alive(cont) and try(function() return cont:GetParent() end) or nil
  local how = 'CONTINUE\'s parent'
  if not alive(host) then host = try(function() return tree.RootWidget end); how = 'the root widget' end
  if not alive(host) then return false, 'no panel to add to (no CONTINUE parent, no root widget)' end
  local hcls = cname(host)
  local before = num(try(function() return host:GetChildrenCount() end))
  local function make(path) return try(function() return StaticConstructObject(StaticFindObject(path), tree) end) end
  local border, tb = make('/Script/UMG.Border'), make('/Script/UMG.TextBlock')
  if not (alive(border) and alive(tb)) then return false, 'could not construct Border / TextBlock' end
  local s = table.concat(lines, '\n')
  try(function() tb:SetText(FText(s)) end)
  try(function() tb:SetColorAndOpacity({ SpecifiedColor = { R = 1, G = 0.82, B = 0.35, A = 1 }, ColorUseRule = 0 }) end)
  try(function() local f = tb.Font; f.Size = 20; tb:SetFont(f) end)
  try(function() border:SetBrushColor({ R = 0, G = 0, B = 0, A = 0.75 }) end)
  try(function() border:SetPadding({ Left = 16, Top = 12, Right = 16, Bottom = 12 }) end)
  try(function() border:SetContent(tb) end)
  local slot
  if hcls:find('CanvasPanel') then
    slot = try(function() return host:AddChildToCanvas(border) end)
    if alive(slot) then
      try(function() slot:SetAutoSize(true) end)
      try(function() slot:SetPosition({ X = 80, Y = 140 }) end)
      try(function() slot:SetZOrder(50) end)
    end
  elseif hcls:find('Overlay') then slot = try(function() return host:AddChildToOverlay(border) end)
  elseif hcls:find('VerticalBox') then slot = try(function() return host:AddChildToVerticalBox(border) end)
  else slot = try(function() return host:AddChild(border) end) end
  local after = num(try(function() return host:GetChildrenCount() end))
  local back = try(function() return tb:GetText():ToString() end)
  local parentOk = addr(try(function() return border:GetParent() end)) == addr(host)
  local ok = alive(slot) and parentOk
  return ok, ('%s %s (%s): children %s -> %s, slot %s, parent ok %s, text reads back %s, panel %s'):format(how, oname(host), hcls,
    tostring(before), tostring(after), cname(slot), tostring(parentOk), tostring(back == s), shown(border))
end

---------------------------------------------------------------------------------------------------------------------
-- B9 (b): the routes

local undo9 = nil -- A's put-back for the subsystem recipe: { inst = ref, ix, AuthoredEvent = path, TrackDef = path, LapCount, tag }

-- write the next event's fields into one stage (struct wrapper reached by `get()` each time: no wrapper kept)
local function swapStage(label, get, e, keep)
  local before = stageLine(try(get))
  local orig = { AuthoredEvent = opath(try(function() return get().AuthoredEvent end)),
    TrackDef = opath(try(function() return get().TrackDef end)), LapCount = num(try(function() return get().LapCount end)),
    tag = tagName(try(function() return get().trackConditions end)) }
  local res = {}
  local S = CONFIG.B9.SWAP
  if S.AuthoredEvent then res[#res + 1] = 'AuthoredEvent ' .. (pcall(function() get().AuthoredEvent = e end) and 'ok' or 'FAILED') end
  if S.TrackDef then
    local td = try(function() return e.TrackDef end)
    res[#res + 1] = 'TrackDef ' .. ((alive(td) and pcall(function() get().TrackDef = td end)) and 'ok' or 'FAILED')
  end
  if S.LapCount then
    local lc = num(try(function() return e.LapCount end))
    res[#res + 1] = 'LapCount ' .. ((lc and pcall(function() get().LapCount = lc end)) and 'ok' or 'FAILED')
  end
  if S.trackConditions then
    local tn = try(function() return e.TrackConditionTag.TagName end)
    res[#res + 1] = 'trackConditions ' .. ((tn ~= nil and pcall(function() get().trackConditions = { TagName = tn } end)) and 'ok' or 'FAILED')
  end
  L9(('A: %s before: %s'):format(label, before))
  L9(('A: %s writes: %s'):format(label, table.concat(res, ', ')))
  L9(('A: %s after:  %s'):format(label, stageLine(try(get))))
  if keep then return orig end
end

local function pauseMenu()
  for _, cls in ipairs({ 'WBP_PauseRacing_C', 'WBP_PauseArcadeRacing_C', 'WBP_Pause_C' }) do
    for _, w in ipairs(find(cls)) do
      if try(function() return w:IsVisible() end) == true or try(function() return w:IsInViewport() end) == true then return w, cls end
    end
  end
end
local RETRY_EVENTS = { 'BndEvt__WBP_Pause_Btn_RetryRace_K2Node_ComponentBoundEvent_27_CommonButtonBaseClicked__DelegateSignature',
  'BndEvt__WBP_Pause_Btn_RetryRace_K2Node_ComponentBoundEvent_14_CommonButtonBaseClicked__DelegateSignature' }

local R9 = {}
function R9.A(gs)
  local e = asset(CONFIG.B9.NEXT_EVENT)
  if not e then L9('A: next event not found: ' .. CONFIG.B9.NEXT_EVENT); return false end
  L9(('A: next event %s (%s): track %s, laps %s, conditions %s'):format(oname(e), text(e, 'PlayerFacingName') or '?',
    oname(try(function() return e.TrackDef end)), tostring(num(try(function() return e.LapCount end))),
    tagName(try(function() return e.TrackConditionTag end))))
  -- 1. the game instance's recipe (EventRecipeSubsystem.ActiveRecipe: lives on past the race world)
  local sub = first('EventRecipeSubsystem')
  local inst = alive(sub) and try(function() return sub.ActiveRecipe end)
  if alive(inst) then
    local active = try(function() return inst.RecipeState.ActiveStage end)
    local _, ix, n = activeStage(try(function() return inst.recipe end), active)
    L9(('A: subsystem recipe %s: %d stage(s), ActiveStage %s'):format(oname(inst), n, tostring(num(active))))
    if ix then
      local orig = swapStage('subsystem recipe stage ' .. ix, function() return inst.recipe.EventStages[ix] end, e, true)
      if orig then orig.inst, orig.ix = ref(inst), ix; undo9 = orig end
    end
  else
    L9('A: no EventRecipeSubsystem.ActiveRecipe')
  end
  -- 2. the race state's replicated copy (goes with the race world)
  local active = try(function() return gs.EventRecipeState_Replication.ActiveStage end)
  local _, ix, n = activeStage(try(function() return gs.EventRecipe end), active)
  L9(('A: race state recipe: %d stage(s), ActiveStage %s'):format(n, tostring(num(active))))
  if ix then swapStage('race state stage ' .. ix, function() return gs.EventRecipe.EventStages[ix] end, e, false) end
  -- 3. the game's restart
  local mode = CONFIG.B9.RESTART
  local pm, pcls = pauseMenu()
  if mode == 'pause' or (mode == 'auto' and pm) then
    if not pm then L9('A: restart: no pause menu up (RESTART = pause): press Esc, then F9 again'); return false end
    local btn = try(function() return pm.Btn_RetryRace end)
    L9(('A: restart: pause menu %s up; its RETRY RACE button %s (%s)'):format(pcls, oname(btn), alive(btn) and shown(btn) or 'missing'))
    for _, ev in ipairs(RETRY_EVENTS) do
      local ok, err = pcall(function() pm[ev](pm, btn) end)
      L9(('A: restart: %s ...%s: %s'):format(pcls, ev:match('(BoundEvent_%d+)'), ok and 'called' or ('FAILED ' .. tostring(err))))
      if ok then return true end
    end
    return false
  end
  local gm = try(function() return gs.AuthorityGameMode end)
  if not alive(gm) then gm = first('RacingGameMode') end
  if not alive(gm) then L9('A: restart: no racing game mode found'); return false end
  local ok, err = pcall(function() gm:RequestResetRace() end)
  L9(('A: restart: %s:RequestResetRace() %s'):format(cname(gm), ok and 'called' or ('FAILED ' .. tostring(err))))
  return ok
end
function R9.B()
  local v = CONFIG.B9.VEHICLE
  local e, build = asset(CONFIG.B9.NEXT_EVENT), asset(v.build)
  local arch
  for _, a in ipairs(find('VehicleArchetype')) do if num(try(function() return a.archetype end)) == v.arch then arch = a; break end end
  if not (e and build and alive(arch)) then
    L9(('B: refused: event %s, build %s, archetype %s'):format(tostring(e ~= nil), tostring(build ~= nil), tostring(alive(arch))))
    return false
  end
  local fe, how = first('FrontEndGameMode'), 'a live FrontEndGameMode'
  if not alive(fe) then
    if not CONFIG.B9.LAUNCH_ON_CDO then L9('B: no live FrontEndGameMode in the race world and LAUNCH_ON_CDO is off: stop'); return false end
    fe, how = try(StaticFindObject, '/Script/Griffin.Default__FrontEndGameMode'), 'the DEFAULT FrontEndGameMode (no live one)'
  end
  if not alive(fe) then L9('B: no FrontEndGameMode at all'); return false end
  L9(('B: LaunchQuickRace(%s, %s, %s) on %s (%s)'):format(oname(arch), oname(e), oname(build), how, oname(fe)))
  local ok, err = pcall(function() fe:LaunchQuickRace(arch, e, build) end)
  L9('B: LaunchQuickRace ' .. (ok and 'returned' or ('FAILED ' .. tostring(err))))
  return ok
end
function R9.T()
  local sub = first('ArcadeSubsystem')
  local e = asset(CONFIG.B9.ARCADE_EVENT)
  if not (alive(sub) and e) then L9(('T: refused: ArcadeSubsystem %s, arcade event %s'):format(tostring(alive(sub)), tostring(e ~= nil))); return false end
  if not cname(e):find('ArcadeEventDef') then L9('T: refused: ' .. oname(e) .. ' is a ' .. cname(e) .. ', not an ArcadeEventDef'); return false end
  L9(('T: ArcadeSubsystem:TravelToEvent(%s); LastPlayedArcadeEvent before: %s'):format(oname(e),
    oname(try(function() return sub.LastPlayedArcadeEvent end))))
  local ok, err = pcall(function() sub:TravelToEvent(e) end)
  L9('T: TravelToEvent ' .. (ok and 'returned' or ('FAILED ' .. tostring(err))))
  return ok
end

local function b9PutBack(why)
  if not undo9 then return end
  local u = undo9
  undo9 = nil
  local inst = deref(u.inst)
  if not inst then L9(('put back (%s): A: the subsystem recipe is gone (replaced or freed): nothing to put back'):format(why)); return end
  local function get() return inst.recipe.EventStages[u.ix] end
  local S, res = CONFIG.B9.SWAP, {}
  if S.AuthoredEvent and u.AuthoredEvent then
    local o = try(StaticFindObject, u.AuthoredEvent)
    res[#res + 1] = 'AuthoredEvent ' .. ((alive(o) and pcall(function() get().AuthoredEvent = o end)) and 'ok' or 'FAILED')
  end
  if S.TrackDef and u.TrackDef then
    local o = try(StaticFindObject, u.TrackDef)
    res[#res + 1] = 'TrackDef ' .. ((alive(o) and pcall(function() get().TrackDef = o end)) and 'ok' or 'FAILED')
  end
  if S.LapCount and u.LapCount then res[#res + 1] = 'LapCount ' .. (pcall(function() get().LapCount = u.LapCount end) and 'ok' or 'FAILED') end
  if S.trackConditions and u.tag and u.tag ~= 'none' then
    res[#res + 1] = 'trackConditions ' .. (pcall(function() get().trackConditions = { TagName = FName(u.tag) } end) and 'ok' or 'FAILED')
  end
  L9(('put back (%s): A: subsystem recipe stage %d: %s -> %s'):format(why, u.ix, table.concat(res, ', '), stageLine(try(get))))
end

---------------------------------------------------------------------------------------------------------------------
-- the loop (250 ms). Flags from the key binds and the two notifications; everything else happens here.

local flags = { b9 = false, b6 = false, b6plain = false, race = false, menu = false }
pcall(NotifyOnNewObject, '/Script/Griffin.RacingGameState', function() flags.race = true end)
pcall(NotifyOnNewObject, '/Script/Griffin.FrontEndGameMode', function() flags.menu = true end)
local function bind(key, mods, fn)
  local k = Key[key]
  if not k then logTo('B9', 'no such key ' .. tostring(key)); return end
  if mods then pcall(RegisterKeyBind, k, mods, fn) else pcall(RegisterKeyBind, k, fn) end
end
if CONFIG.B9.ON then bind(CONFIG.KEYS.B9, nil, function() flags.b9 = true end) end
if CONFIG.B6.ON then
  bind(CONFIG.KEYS.B6, nil, function() flags.b6 = true end)
  bind(CONFIG.KEYS.B6, { ModifierKey.CONTROL }, function() flags.b6plain = true end)
end

local TICK = 250
tick = 0
local function sec(n) return math.floor(n * 1000 / TICK + 0.5) end
local seenGs = {}
local race = nil    -- the race world we're in: { gs = ref, at, ours6, mode6, loadTries, gridLogged, settled }
local job9 = nil    -- the F9 job: { at, routeAt, route, watchUntil, from (gs address), lastLook, last }
local press9 = 0
local bootRestore = readState() ~= nil
if bootRestore then L6('boot: b6_state.lua is still there (a crash or a quit mid-race): put back at the first main menu') end

-- a race world not seen before (one sweep); finished race states can linger into the menus
local function newRaceWorld()
  for _, g in ipairs(find('RacingGameState')) do
    local a = addr(g)
    if a and not seenGs[a] then seenGs[a] = true; return g end
  end
end

local function onRaceWorld(gs)
  local sa = standalone(gs)
  race = { gs = ref(gs), at = tick, ours6 = expect6 ~= nil, mode6 = expect6 and expect6.mode, loadTries = 0, standalone = sa }
  expect6 = nil
  L6(('race world %s, standalone=%s%s'):format(oname(gs), tostring(sa), race.ours6 and (' (our F10 launch, ' .. race.mode6 .. ')') or ''))
  if job9 and job9.watchUntil then
    -- a route was being watched: this is the answer
    local active = try(function() return gs.EventRecipeState_Replication.ActiveStage end)
    local st = activeStage(try(function() return gs.EventRecipe end), active)
    L9(('NEW RACE WORLD after route %s (%.1f s): %s, standalone=%s; %s'):format(job9.route, (tick - job9.ranAt) * TICK / 1000,
      oname(gs), tostring(sa), stageLine(st)))
    job9.newWorld = true
  end
end

-- the grid at load (the recipe's Racers[] are there ~0.1 s after the race world appears): one sweep a tick, at most 16
local function gridAtLoad()
  local sub = first('EventRecipeSubsystem')
  local inst = alive(sub) and try(function() return sub.ActiveRecipe end)
  local racers = alive(inst) and try(function() return inst.RecipeState.Racers end)
  local line, n = racersLine(racers)
  race.loadTries = race.loadTries + 1
  if n == 0 and race.loadTries < 16 then return end
  race.gridLogged = true
  L6(('grid at load (%.2f s): recipe racers %d: %s'):format((tick - race.at) * TICK / 1000, n, line))
  local st = nil
  if alive(inst) then st = activeStage(try(function() return inst.recipe end), try(function() return inst.RecipeState.ActiveStage end)) end
  L6('grid at load: stage ' .. stageLine(st))
  local gmv = st and try(function() return st.GameModeVariant end)
  if alive(gmv) then
    L6(('grid at load: mode variant %s grid make-up %s (mode %s)'):format(oname(gmv), (gridLine(try(function() return gmv.GridMakeup end))),
      tostring(num(try(function() return gmv.GameMode end)))))
  end
  if alive(inst) then L9('race recipe at load: ' .. stageLine(st)) end
end
local function gridSettled()
  race.settled = true
  local gs = deref(race.gs)
  local arr = alive(gs) and try(function() return gs.Racers end)
  local names = {}
  for i = 1, arrN(arr) do
    local ps = try(function() return arr[i] end)
    names[#names + 1] = pilotName(ps) .. (try(function() return ps.bIsABot end) == false and '(you)' or '')
  end
  L6(('grid %d s in: race state Racers %d: %s; Vehicles %d; LapCount %s'):format(CONFIG.B6.SETTLE_S, arrN(arr),
    table.concat(names, ', '), arrN(alive(gs) and try(function() return gs.Vehicles end)),
    tostring(num(alive(gs) and try(function() return gs.LapCount end)))))
end

-- F9 pressed in a race
local function b9Start()
  if not race then L9('F9: not in a race world (the race world is noticed when it loads)'); return end
  local gs = deref(race.gs)
  if not gs then L9('F9: the race world is gone'); return end
  if race.standalone ~= true then L9('F9: refused: not an offline race (IsStandalone false)'); return end
  if job9 and not job9.done then L9('F9: a route is still running / being watched'); return end
  press9 = press9 + 1
  local route = CONFIG.B9.PLAN[press9]
  L9(('F9 press %d: route %s; race %s, started %s, finished %s; flow %s'):format(press9, tostring(route or 'none (plan done)'),
    oname(gs), tostring(try(function() return gs.bIsRaceStarted end)), tostring(try(function() return gs.bIsRaceFinished end)), flowStates()))
  -- (a) the results screen and our panel
  local screen = resultsProbe(gs)
  local hold = 0
  if screen and CONFIG.B9.PANEL then
    local list = standings()
    local lines = { 'GRAND PRIX STANDINGS (RaceFlowSpike test)' }
    for i, r in ipairs(list) do if i <= 12 then lines[#lines + 1] = ('%2d  %s%s'):format(r.pos, r.name, r.you and '  <- YOU' or '') end end
    local ok, why = addPanel(screen, lines)
    L9(('panel %s: %s'):format(ok and 'ADDED' or 'NOT added', why))
    if ok then hold = CONFIG.B9.PANEL_HOLD_S end
  elseif CONFIG.B9.PANEL then
    L9('panel: no WBP_SimpleRaceResultsScreen_C up: nothing added (press F9 on the results screen to test it)')
  end
  if not route then job9 = { done = true }; return end
  job9 = { route = route, routeAt = tick + sec(hold), from = addr(gs) }
  if hold > 0 then L9(('route %s in %d s (screenshot the panel now)'):format(route, hold)) end
end

local function b9Run()
  local gs = deref(race and race.gs)
  if not gs then L9('route ' .. job9.route .. ': the race world went away before it ran'); job9.done = true; return end
  local fn = R9[job9.route]
  if not fn then L9('route ' .. job9.route .. ': unknown (A, B or T)'); job9.done = true; return end
  local ok, res = pcall(fn, gs)
  if not ok then L9('route ' .. job9.route .. ': error ' .. tostring(res)) end
  job9.ranAt, job9.routeAt = tick, nil
  job9.watchUntil, job9.lastLook = tick + sec(CONFIG.B9.WATCH_S), tick
  job9.last = { started = try(function() return gs.bIsRaceStarted end), finished = try(function() return gs.bIsRaceFinished end) }
  L9(('route %s %s; watching %d s for a new race world, a reset of this one, or the main menu'):format(job9.route,
    (ok and res) and 'done' or 'did not act', CONFIG.B9.WATCH_S))
end

-- every 2 s while watching: the same race state reset? (one deref = one sweep); new worlds come through onRaceWorld
local function b9Watch()
  if job9.newWorld then job9.done = true; return end
  if tick >= job9.watchUntil then
    L9(('watch over (%d s): no new race world, no main menu'):format(CONFIG.B9.WATCH_S)); job9.done = true; return
  end
  if tick - job9.lastLook < sec(2) then return end
  job9.lastLook = tick
  local gs = deref(race and race.gs)
  if not gs then return end
  local now = { started = try(function() return gs.bIsRaceStarted end), finished = try(function() return gs.bIsRaceFinished end) }
  if now.started ~= job9.last.started or now.finished ~= job9.last.finished then
    local active = try(function() return gs.EventRecipeState_Replication.ActiveStage end)
    local st = activeStage(try(function() return gs.EventRecipe end), active)
    L9(('SAME race world changed (%.1f s after route %s): started %s -> %s, finished %s -> %s, LapCount %s; flow %s; %s'):format(
      (tick - job9.ranAt) * TICK / 1000, job9.route, tostring(job9.last.started), tostring(now.started), tostring(job9.last.finished),
      tostring(now.finished), tostring(num(try(function() return gs.LapCount end))), flowStates(), stageLine(st)))
    job9.last = now
  end
end

LoopInGameThreadWithDelay(TICK, function()
  local ok, err = pcall(function()
    tick = tick + 1
    -- the main menu came back (or a boot restore is due: a sweep every 2 s until the menu is seen)
    local menuNow = flags.menu
    if not menuNow and bootRestore and not race and tick % sec(2) == 0 then menuNow = alive(first('FrontEndGameMode')) end
    if menuNow then
      flags.menu, bootRestore = false, false
      if race then L6('main menu back') end
      if job9 and job9.watchUntil and not job9.done then
        L9(('MAIN MENU came back %.1f s after route %s'):format((tick - job9.ranAt) * TICK / 1000, job9.route)); job9.done = true
      end
      race = nil
      b6Restore('main menu')
      b9PutBack('main menu')
      flags.b9 = false
    end
    -- keys
    if flags.b6 or flags.b6plain then
      local plain = flags.b6plain
      flags.b6, flags.b6plain = false, false
      if race then L6('F10: refused: in a race (F10 works at the main menu)') else b6Launch(plain) end
    end
    if flags.b9 then flags.b9 = false; b9Start() end
    -- a new race world (the notification, or a sweep every 2 s while one of our actions expects one)
    local expecting = expect6 ~= nil or (job9 and job9.watchUntil and not job9.done)
    if flags.race or (expecting and tick % sec(2) == 0) then
      flags.race = false
      local gs = newRaceWorld()
      if gs then onRaceWorld(gs) end
      if expect6 and tick - expect6.at > sec(120) then L6('no race world 120 s after the launch: put back'); expect6 = nil; b6Restore('timeout') end
    end
    if race and not race.gridLogged then gridAtLoad() end
    if race and race.gridLogged and not race.settled and tick - race.at >= sec(CONFIG.B6.SETTLE_S) then gridSettled() end
    if job9 and not job9.done then
      if job9.routeAt and tick >= job9.routeAt then b9Run()
      elseif job9.watchUntil then b9Watch() end
    end
  end)
  if not ok then L9('loop error: ' .. tostring(err)); L6('loop error: ' .. tostring(err)) end
end)
