-- ATTIC (not loaded, not deployed). The same-layout reset route for chained races (ChainRaces.Reset), as it was in
-- v0.21.0: NEXT RACE on the results screen wrote the next event into the race recipe (both copies, read back) and
-- called BP_RacingGameMode_C:RequestResetRace(), with a load timeout and a watchdog falling back to the menu route.
-- Off by default since v0.19.1 (Mastiff/Loop_A -> Mastiff/P2P_A hung on PLEASE WAIT for good in v0.19.0); removed
-- after v0.21.0. The menu route (results panel -> NEXT RACE -> the main menu -> auto-launch) stays in chain.lua.
-- Excerpts in file order; each block names the file and the place it came from. See attic/README.md.
-- Tests: attic/test_chain_reset.lua (needs test/world.lua's recipe / RequestResetRace mock, which is still there).

---------------------------------------------------------------------------------------------------------------------
-- FROM chain.lua: the header as of v0.21.0 (the live header was rewritten without the reset route)
-- Galactic Grand Prix v0.19: cups without the main menu (TASKS.md "Next" 2, DESIGN.md §15).
-- Proven by RaceFlowSpike B9 (tools/recon/RaceFlowSpike, raceflow-b9-20261111.log): (a) a panel added to the game's
-- results screen WBP_SimpleRaceResultsScreen_C on its canvas Default_Results (CONTINUE's parent) shows over it; (b) the
-- next event written into the active stage of the race recipe (AuthoredEvent, TrackDef, LapCount, trackConditions) on
-- both EventRecipeSubsystem.ActiveRecipe and the race state's EventRecipe, then BP_RacingGameMode_C:RequestResetRace()
-- -> a new race world with that event in 0.5 s - BUT only within the same track world (Loop_A FWD -> Loop_A SHORT_02).
-- v0.19.0 in game (2026-11-11 17:35, Jakku 150cc): Mastiff/Loop_A -> Mastiff/P2P_A by the reset hung on the black
-- PLEASE WAIT screen for good (`field: 1 racers`, Escape dead, game killed): the reset re-uses the loaded map.
--
-- v0.19.1: NEXT RACE goes VIA THE MENU by default. The flow, after a cup race that isn't the cup's last (race.lua
-- R.watch calls CH.tick once you have finished):
--   1. CH.plan: chain this race? (ChainRaces.On, a cup race with a next race - any cup, the Galactic Cup too). The route:
--      'menu' (default), or 'reset' when ChainRaces.Reset = true AND the next race is in the same layout folder
--      ('Mastiff/Loop_A', CH.layout). Not chaining: nothing in the race world, the main menu as before.
--   2. Look for the results screen (one sweep every LOOK_MS, up to ResultsWaitS). Found: the race is recorded right
--      then by race.lua's own recording (K.record - the main menu then hands back this result instead of recording
--      again), and our panel goes on the screen: the standings (standings.lua) on an opaque dark box (the game's own
--      table hidden under it), a prompt, and a NEXT RACE button of CONTINUE's own class left of CONTINUE, focused.
--   3. NEXT RACE (the button's selected state, polled; or ChainRaces.Key):
--      'menu':  CH.via is set (plain values: cup, class, race number) and the results go to the main menu the game's
--               own way (CH.leave: the screen's CONTINUE click, else RequestReturnToMenus). At the menu main.lua sees
--               CH.via: the cover goes up instead of the standings page, and once the menu has settled (the study
--               mode's rules: menu up, no race, put-backs done, settled ChainRaces.MenuSettleS) the next race launches
--               through R.launch, exactly as NEXT RACE on the standings page would. A failed launch: the cover off,
--               today's standings page.
--      'reset': race.lua R.chainLaunch (the B9 route: the recipe written, read back, RequestResetRace), watched: no new
--               race world in LoadTimeoutS, or no AI racer / no start WatchdogS after the reset -> RequestReturnToMenus
--               and CH.via set, so the via-the-menu flow carries the cup on. Proven for Loop_A -> Loop_A only.
--   4. CONTINUE (or the game moving on by itself) instead: the main menu, and today's standings page (CH.via unset).
--      v0.21 (owner: "there doesn't need to be a continue button ... redundant and misleading"): the game's CONTINUE is
--      hidden (Collapsed: it can't be focused or clicked; ChainRaces.Panel.HideContinue) once NEXT RACE is in place,
--      NEXT RACE centred where the two buttons were. B leaves the cup: our own hidden Back screen in the panel (the
--      tab page's trick, tab.lua) reads the pad's B, the key binds Backspace / Escape set CH.back (flags only). B ->
--      CH.leaveAsk set, the results left for the main menu (CONTINUE's event pressed from code, hidden or not), and
--      main.lua opens "Leave the cup?" straight away (NO = the standings with NEXT RACE). The results screen closing
--      on its own with CONTINUE hidden (the game's own back handling B first) counts as B too. The last race of a
--      cup is never chained: the game's CONTINUE stays (the cup result).
-- Every failure after NEXT RACE carries the cup on via the menu (CH.fallback with via = true); every other one ends
-- at today's standings page; each with a `[chain]` log line.
--

---------------------------------------------------------------------------------------------------------------------
-- FROM chain.lua: the reset route's switches (after CH.on)
-- v0.19.1: the reset route only on request (proven for Loop_A -> Loop_A only); CrossPlanet is gone (the via-the-menu
-- flow works for every cup; the reset route needs the same layout folder, which is always the same planet)
function CH.resetOn() return conf().Reset == true end
function CH.loadTimeoutMs() return (tonumber(conf().LoadTimeoutS) or 15) * 1000 end
function CH.watchdogMs() return (tonumber(conf().WatchdogS) or 20) * 1000 end

---------------------------------------------------------------------------------------------------------------------
-- FROM chain.lua: the launch arguments for R.chainLaunch (main.lua replaced it with its cupArgs)
-- the launch arguments of the cup's next race: class, vehicle, picks, mods (main.lua sets this to the same values its
-- NEXT RACE tile passes, so a chained race is set up exactly like a menu launch)
function CH.args(run) return run.class, run.vehicle, run.picks, run.mods end

---------------------------------------------------------------------------------------------------------------------
-- FROM chain.lua: same layout (the reset route's condition)
---------------------------------------------------------------------------------------------------------------------
-- same layout (v0.19.1): the planet's codename folder and the folder after it in the event path
-- ('.../Planets/Mastiff/Loop_A/EVT_...' -> 'Mastiff/Loop_A'), compared without case (the paths mix cases:
-- 'Husky/LOOP_A'). Unknown = not the same. The reset route only re-uses the loaded track world: a race in another
-- layout folder (another map) never loads (v0.19.0 in game).

function CH.planet(path) return type(path) == 'string' and path:match('/Planets/([^/]+)/') or nil end
function CH.layout(path)
  if type(path) ~= 'string' then return nil end
  local p, l = path:match('/Planets/([^/]+)/([^/]+)/')
  return p and (p .. '/' .. l) or nil
end
function CH.sameLayout(a, b)
  local x, y = CH.layout(a), CH.layout(b)
  return x ~= nil and y ~= nil and x:lower() == y:lower()
end

---------------------------------------------------------------------------------------------------------------------
-- FROM chain.lua: CH.plan as of v0.21.0 (with the reset route)
-- chain this race? -> { want = true, next = the next race (config entry), route = 'menu' | 'reset', how = text } or
-- { why = the reason not (for the log) }.
-- r = race.lua's run (r.ev = the race just finished)
function CH.plan(r)
  -- (off: nothing at all in the race world, not even a log line - today's flow)
  if not CH.on() then return { quiet = true, why = 'ChainRaces is off' } end
  local ev, run = r.ev or {}, K.run()
  if ev.titleRace or not (run and ev.cup == run.cup and ev.race == run.race and ev.class == run.class) then
    return { quiet = true, why = 'not a cup race' }
  end
  local nxt = K.races(K.cup(run.cup), run.class)[(ev.race or 0) + 1]
  if not nxt then return { why = ('race %d of %d: the cup result at the main menu'):format(ev.race or 0, run.races) } end
  if CH.resetOn() and CH.sameLayout(ev.path, nxt.path) then
    return { want = true, next = nxt, route = 'reset', how = ('same layout %s, Reset on: NEXT RACE by the reset'):format(tostring(CH.layout(nxt.path))) }
  end
  local how = 'NEXT RACE via the menu'
  if CH.resetOn() then how = ('%s -> %s is another layout: NEXT RACE via the menu'):format(tostring(CH.layout(ev.path)), tostring(CH.layout(nxt.path))) end
  return { want = true, next = nxt, route = 'menu', how = how }
end

---------------------------------------------------------------------------------------------------------------------
-- FROM chain.lua: the race recipe (write, put back, read the new world's event)
---------------------------------------------------------------------------------------------------------------------
-- the recipe (KNOWLEDGE.md §3: the B9 route): the next event into the active stage of both copies, read back

-- the active stage of a recipe holder (FEventRecipe: .EventStages) for an ActiveStage index (0-based) -> 1-based index
local function stageIx(recipe, active)
  local n = tonumber((try(function() return recipe.EventStages:GetArrayNum() end))) or 0
  if n == 0 then return nil, 0 end
  return math.max(1, math.min(n, (tonumber(active) or 0) + 1)), n
end
local function pathOf(o)
  local full = alive(o) and try(function() return o:GetFullName() end)
  return type(full) == 'string' and full:match('^%S+%s+(.+)$') or nil
end
-- one stage's four fields as text, read one by one (never the whole struct)
local function stageText(get)
  return ('event %s, track %s, laps %s, conditions %s'):format(C.idname(try(function() return get().AuthoredEvent end)),
    C.idname(try(function() return get().TrackDef end)), tostring(tonumber((try(function() return get().LapCount end)))),
    tostring(C.tag(try(function() return get().trackConditions end)) or 'none'))
end
-- write the four fields of one stage (get() reaches the struct each time: no wrapper kept), then read them back
local function writeStage(get, w)
  pcall(function() get().AuthoredEvent = w.e end)
  pcall(function() get().TrackDef = w.track end)
  pcall(function() get().LapCount = w.laps end)
  if w.tagName ~= nil then pcall(function() get().trackConditions = { TagName = w.tagName } end) end
  local bad = {}
  if C.idname(try(function() return get().AuthoredEvent end)) ~= w.ev then bad[#bad + 1] = 'AuthoredEvent' end
  if C.idname(try(function() return get().TrackDef end)) ~= w.trackName then bad[#bad + 1] = 'TrackDef' end
  if tonumber((try(function() return get().LapCount end))) ~= w.laps then bad[#bad + 1] = 'LapCount' end
  if C.tag(try(function() return get().trackConditions end)) ~= w.tag then bad[#bad + 1] = 'trackConditions' end
  return #bad == 0, bad
end

-- the event the recipe's put-back restores (the first one written over in this cup; CH.putBack at the main menu)
CH.undo = nil

-- gs = the race state (in hand), e = the next event's asset. Returns true, or false + why.
function CH.writeRecipe(gs, e)
  local w = { e = e, ev = C.idname(e) }
  w.track = try(function() return e.TrackDef end)
  w.trackName = C.idname(w.track)
  w.laps = tonumber((try(function() return e.LapCount end)))
  w.tagName = try(function() return e.TrackConditionTag.TagName end)
  w.tag = C.tag(try(function() return e.TrackConditionTag end))
  if w.ev == '' or w.trackName == '' or not w.laps then
    return false, ('the next event %s has no track / lap count to write'):format(w.ev ~= '' and w.ev or '?')
  end
  local sub = C.first('EventRecipeSubsystem')
  local inst = alive(sub) and try(function() return sub.ActiveRecipe end) or nil
  if not alive(inst) then return false, 'no EventRecipeSubsystem.ActiveRecipe' end
  local ix = stageIx(try(function() return inst.recipe end), try(function() return inst.RecipeState.ActiveStage end))
  if not ix then return false, 'the subsystem recipe has no stages' end
  local function subStage() return inst.recipe.EventStages[ix] end
  if not CH.undo then
    -- the originals, once per cup: what the menu launch put there (paths and plain values only)
    CH.undo = { inst = C.ref(inst), ix = ix, ev = pathOf(try(function() return subStage().AuthoredEvent end)),
      track = pathOf(try(function() return subStage().TrackDef end)), laps = tonumber((try(function() return subStage().LapCount end))),
      tag = C.tag(try(function() return subStage().trackConditions end)), text = stageText(subStage) }
  end
  local ok1, bad1 = writeStage(subStage, w)
  local ix2 = stageIx(try(function() return gs.EventRecipe end), try(function() return gs.EventRecipeState_Replication.ActiveStage end))
  local ok2, bad2 = false, { 'no stages' }
  local function gsStage() return gs.EventRecipe.EventStages[ix2] end
  if ix2 then ok2, bad2 = writeStage(gsStage, w) end
  local what = ('%s (track %s, %d laps, %s)'):format(w.ev, w.trackName, w.laps, w.tag or 'no conditions')
  if not (ok1 and ok2) then
    return false, ('the next race did not read back: subsystem recipe %s, race state %s'):format(
      ok1 and 'ok' or table.concat(bad1, '/'), ok2 and 'ok' or table.concat(bad2, '/'))
  end
  log(('[chain] next race written: %s on the subsystem recipe (stage %d) and the race state\'s copy (stage %d), read back ok'):format(what, ix, ix2))
  return true
end

-- the subsystem recipe back as the menu launch left it (at the main menu: race.lua R.restoreBuild). Quiet when
-- nothing was written.
function CH.putBack(why)
  local u = CH.undo
  if not u then return end
  CH.undo = nil
  local inst = C.deref(u.inst)
  if not inst then log(('[chain] recipe put back (%s): the subsystem recipe is gone (a new one per launch) - nothing to do'):format(why or '?')); return end
  local function get() return inst.recipe.EventStages[u.ix] end
  local res = {}
  local function one(name, fn) res[#res + 1] = name .. ((pcall(fn)) and ' ok' or ' FAILED') end
  if u.ev then local o = try(StaticFindObject, u.ev); if alive(o) then one('AuthoredEvent', function() get().AuthoredEvent = o end) end end
  if u.track then local o = try(StaticFindObject, u.track); if alive(o) then one('TrackDef', function() get().TrackDef = o end) end end
  if u.laps then one('LapCount', function() get().LapCount = u.laps end) end
  if u.tag then one('trackConditions', function() get().trackConditions = { TagName = FName(u.tag) } end) end
  log(('[chain] recipe put back (%s): %s -> %s'):format(why or '?', table.concat(res, ', '), stageText(get)))
end

-- the event of a race world's active stage (its own recipe copy; for the [chain] log and the check that the new world
-- runs the race we wrote): the event's object name, or nil
function CH.worldEvent(gs)
  local ix = stageIx(try(function() return gs.EventRecipe end), try(function() return gs.EventRecipeState_Replication.ActiveStage end))
  if not ix then return nil end
  local n = C.idname(try(function() return gs.EventRecipe.EventStages[ix].AuthoredEvent end))
  return n ~= '' and n or nil
end

---------------------------------------------------------------------------------------------------------------------
-- FROM chain.lua: CH.fallback (only the reset route called it)
-- the way out when something fails: to the main menu. via = true (a failure after NEXT RACE): the next race then
-- launches from the menu (CH.via); else today's standings page there. noScreen: RequestReturnToMenus straight away
-- (the reset's watchdog: the results screen is gone).
function CH.fallback(r, why, via, noScreen)
  log('[chain] fallback: ' .. tostring(why) .. (via and ' - to the main menu, the next race from there (via the menu)'
    or ' - CONTINUE to the main menu, the standings there'))
  if via and not CH.setVia() then via = false end
  local ok = CH.leave(r, noScreen)
  if not ok and via then CH.via = nil; log('[chain] via the menu: dropped - the standings page at the main menu') end
  return ok
end

---------------------------------------------------------------------------------------------------------------------
-- FROM chain.lua: the end of CH.tick (NEXT RACE pressed: the route)
  if st.route == 'reset' then
    local ok, why = api.launch(r)
    if not ok then CH.fallback(r, why, true) end
  else
    CH.goViaMenu(r)
  end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: R.restoreBuild (the recipe put back)
  -- v0.19: the race recipe's next-race writes (chain.lua; memory only)
  local okC, errC = pcall(function() return require('chain').putBack(why) end)
  if not okC then log('[chain] recipe put back failed: ' .. tostring(errC)) end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: R.chainLaunch (after R.launch)
-- v0.19 (chain.lua): the cup's next race from the results screen of the race `prev` just finished, without the main
-- menu: the same set-up as R.launch (prepare), the next event written into the race recipe (both copies, read back),
-- the old race's rubber band put back on its live tune objects (the new race's are set again at load), then the game's
-- RequestResetRace. The build, abilities, tune-ups and AI config stay changed across the chain (their originals are in
-- the save from the cup's first launch) and are put back once, at the main menu. Returns true, or false + why (the
-- caller falls back to the main menu; nothing to undo here: the main menu puts everything back).
function R.chainLaunch(prev)
  local CH = require('chain')
  local run, ev = K.run(), K.nextRace()
  if not (run and ev) then return false, 'no cup race to run next' end
  local gs = C.deref(prev.gsRef)
  if not gs then return false, 'the race world is gone' end
  local ksl = C.lib('KismetSystemLibrary')
  if try(function() return ksl:IsStandalone(gs) end) ~= true then return false, 'not an offline race' end
  local classKey, vehKey, picks, mods = CH.args(run)
  local p, why = prepare(ev, classKey, vehKey, picks, mods)
  if not p then return false, why end
  pcall(AI.restore, prev.ai)
  local okW, whyW = CH.writeRecipe(gs, p.e)
  if not okW then return false, whyW end
  local gm = try(function() return gs.AuthorityGameMode end)
  if not alive(gm) then gm = C.first('RacingGameMode') end
  if not alive(gm) then return false, 'no racing game mode to reset the race' end
  local skip = worldKeys()
  local okR, errR = pcall(function() gm:RequestResetRace() end)
  if not okR then return false, 'RequestResetRace refused: ' .. tostring(errR) end
  log(('[chain] reset called: %s:RequestResetRace() for race %d of %d, %s'):format(C.clsname(gm), ev.race, run.races, ev.title))
  startRun(ev, classKey, p, skip, { chained = true, prevOut = prev.recorded, gsRef = prev.gsRef, screenRef = prev.screenRef })
  return true
end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: readField counted the AI racers for the watchdog
      if not you then bots = bots + 1 end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: readField, before `return n`
  -- (v0.19.1: the most AI racers seen in one read - the reset's watchdog)
  if bots > (r.bots or 0) then r.bots = bots end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: chainApi had
  launch = function(r) return R.chainLaunch(r) end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: fallbackWatch (the reset route's way back to the menu)
-- v0.19: after a chain fallback, wait for the main menu (the notification, or a sweep every 2 s: the player may still
-- be in a race world), then put everything back and hand back the last recorded result: today's standings page, or
-- (v0.19.1, chain.lua CH.via set) the next cup race launched from the menu under the cover (main.lua)
local function fallbackWatch(r)
  if not R.menuSeen and C.clock - (r.lastFe or -1e9) < 2000 then return nil end
  r.lastFe = C.clock
  if not alive(C.first('FrontEndGameMode')) then return nil end
  R.restoreBuild('main menu')
  pcall(AI.restore, r.ai)
  R.run = nil
  log('[chain] main menu after the fallback: the result of race ' .. tostring(r.prevOut and r.prevOut.ev and r.prevOut.ev.race or '?')
    .. (require('chain').via and (' - race ' .. require('chain').via.race .. ' next, via the menu') or ' - the standings page'))
  return r.prevOut
end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: R.watch, first lines
  if r.phase == 'fallback' then return fallbackWatch(r) end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: R.watch, loading: the new race world from the reset
        if r.chained then
          -- v0.19: the new race world from the reset - its own recipe copy says which race it runs
          local CH = require('chain')
          local got = CH.worldEvent(gs)
          local want = r.ev.path:match('([^/]+)$')
          log(('[chain] new race world %s %.1f s after the reset: %s'):format(C.idname(gs), (C.clock - r.at) / 1000, tostring(got or '? (unreadable)')))
          if got and got ~= want then
            r.screenRef = nil
            CH.fallback(r, ('the new race world runs %s, not %s'):format(got, want), true, true)
            r.phase = 'fallback'
            return nil
          end
        end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: R.watch, loading: no new race world after the reset
    if r.chained and (R.menuSeen or C.clock - r.at > require('chain').loadTimeoutMs()) then
      -- v0.19: the reset gave no new race world (or the main menu came instead): the main menu, today's standings
      -- (v0.19.1: the next race then from the menu, CH.via)
      local CH = require('chain')
      if not R.menuSeen then CH.fallback(r, ('no new race world %d s after the reset'):format(CH.loadTimeoutMs() // 1000), true)
      else
        CH.setVia()
        log('[chain] the main menu came back instead of the next race' .. (CH.via and ': the next race from there (via the menu)' or ''))
      end
      r.phase = 'fallback'
      return nil
    end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: R.watch, racing: the reset's watchdog
  -- v0.19.1: the reset's watchdog (a race chained by RequestResetRace): WatchdogS after the reset, at least one AI
  -- racer seen and the race started - else (v0.19.0 in game: another layout hung on PLEASE WAIT with `field: 1
  -- racers`) RequestReturnToMenus and the next race from the menu (CH.via). One lookup of the race state, once.
  if r.chained and not r.watchOk and not R.menuSeen then
    local CH = require('chain')
    if (r.bots or 0) > 0 and r.startedAt then
      r.watchOk = true
      log(('[chain] watchdog: ok - %d AI racers, the race started %.1f s after the reset'):format(r.bots, (r.startedAt - r.at) / 1000))
    elseif C.clock - r.at > CH.watchdogMs() then
      if not r.startedAt then
        local gs = C.deref(r.gsRef)
        if gs and try(function() return gs.bIsRaceStarted end) == true then r.startedAt = C.clock end
      end
      if (r.bots or 0) > 0 and r.startedAt then
        r.watchOk = true
        log(('[chain] watchdog: ok - %d AI racers, the race started (seen late)'):format(r.bots))
      else
        local why = ('watchdog: %d s after the reset %s'):format(CH.watchdogMs() // 1000,
          (r.bots or 0) == 0 and 'no AI racer has appeared' or 'the race has not started')
        log('[chain] ' .. why .. ' - giving up on the reset')
        CH.fallback(r, why, true, true)
        r.phase = 'fallback'
        return nil
      end
    end
  end

---------------------------------------------------------------------------------------------------------------------
-- FROM race.lua: R.watch, after the chain tick
    if R.run ~= r then return nil end -- (the next race is on its way)

---------------------------------------------------------------------------------------------------------------------
-- FROM main.lua: cupArgs' comment
-- (v0.19: the same arguments for a race chained from the results screen, chain.lua / race.lua R.chainLaunch)

---------------------------------------------------------------------------------------------------------------------
-- FROM main.lua: after cupArgs
require('chain').args = cupArgs

---------------------------------------------------------------------------------------------------------------------
-- FROM config.lua: ChainRaces' comment
    -- Reset = true: the v0.19.0 route instead (the race recipe's stage swapped, then the game's RequestResetRace, no
    -- main menu) but ONLY when the next race is in the same layout folder (planet + the folder after it, e.g.
    -- 'Mastiff/Loop_A'). PROVEN ONLY FOR Loop_A -> Loop_A (RaceFlowSpike B9); another layout hung the game on PLEASE
    -- WAIT in v0.19.0. Its watchdog: no new race world LoadTimeoutS after the reset, or no AI racer / no start
    -- WatchdogS after it -> RequestReturnToMenus and the next race via the menu.

---------------------------------------------------------------------------------------------------------------------
-- FROM config.lua: ChainRaces as of v0.21.0
    ChainRaces = { On = true, Reset = false, Key = 'N', ResultsWaitS = 90, MenuSettleS = 5, LoadTimeoutS = 15, WatchdogS = 20,
        Panel = { Y = 330, MinWidth = 1700, MinHeight = 1250, ButtonGap = 80, HideGameTable = true, HideContinue = true } },
