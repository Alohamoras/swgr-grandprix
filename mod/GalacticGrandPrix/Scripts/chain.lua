-- Galactic Grand Prix v0.19: cups without the main menu (TASKS.md "Next" 2, DESIGN.md §15).
-- Proven by RaceFlowSpike B9 (tools/recon/RaceFlowSpike, raceflow-b9-20261111.log): (a) a panel added to the game's
-- results screen WBP_SimpleRaceResultsScreen_C on its canvas Default_Results (CONTINUE's parent) shows over it; (b) the
-- next event written into the active stage of the race recipe (AuthoredEvent, TrackDef, LapCount, trackConditions) on
-- both EventRecipeSubsystem.ActiveRecipe and the race state's EventRecipe, then BP_RacingGameMode_C:RequestResetRace()
-- -> a new race world with that event in 0.5 s. Proven on one planet only (config ChainRaces.CrossPlanet).
--
-- The flow, after a cup race that isn't the cup's last (race.lua R.watch calls CH.tick once you have finished):
--   1. CH.plan: chain this race? (ChainRaces.On, a cup race with a next race, same planet unless CrossPlanet). If not,
--      nothing happens in the race world: the main menu records the race and shows the standings, as before.
--   2. Look for the results screen (one sweep every LOOK_MS, up to ResultsWaitS). Found: the race is recorded right
--      then by race.lua's own recording (K.record: points, records, rival, near misses - the same call the main menu
--      makes; the main menu then hands back this result instead of recording again), and our panel goes on the
--      screen: the standings (standings.lua, the main menu page's own lines and table) and a prompt, plus a NEXT RACE
--      button made from CONTINUE's own class beside CONTINUE (FreeRace's RETRY button does the same), focused.
--   3. NEXT RACE (the button's selected state, polled; or ChainRaces.Key): race.lua R.chainLaunch - the same set-up as
--      a launch from the menu (race.lua prepare), the recipe written (CH.writeRecipe, read back), RequestResetRace.
--   4. CONTINUE (or the game moving on by itself) instead: the main menu, and today's standings page there.
-- Every failure falls back to the main menu and today's standings page (CH.fallback), with a `[chain]` log line.
--
-- House rules: no hooks (the key bind only sets a flag; the button is read by polling), every engine call guarded,
-- nothing kept between ticks but C.ref (path + address) of the screen and our button, looked up again (a sweep, at most
-- every POLL_MS) only while the panel is up. Soft pointers: the stage struct holds one (ExtraWinCriteria), so it is
-- never read whole - only its four plain fields. The recipe's originals are put back at the main menu (CH.putBack,
-- from race.lua R.restoreBuild); they are memory only, so a game restart undoes them too.
local C = require('core')
local cfg = require('config')
local K = require('gp')
local try, alive, log = C.try, C.alive, C.log

local CH = { key = false }
CH.RESULTS = 'WBP_SimpleRaceResultsScreen_C'
-- the results screen's own CONTINUE click (FreeRace's retry.lua presses CONTINUE the same way)
CH.CONTINUE_EVENT = 'BndEvt__WBP_SimpleRaceResultsScreen_WBP_Common_Btn_K2Node_ComponentBoundEvent_1_CommonButtonBaseClicked__DelegateSignature'
local LOOK_MS = 300   -- the results screen looked for this often once you have finished (a sweep each time)
local POLL_MS = 200   -- our NEXT RACE button read this often while the panel is up (a lookup each time)
local FOCUS_MS = 1500 -- focus given back to NEXT RACE for this long after it is added (the screen may take it once)
local GAP = 40        -- px between NEXT RACE and CONTINUE

local function conf() return type(cfg.ChainRaces) == 'table' and cfg.ChainRaces or {} end
function CH.on() return conf().On == true end
function CH.crossPlanet() return conf().CrossPlanet == true end
function CH.loadTimeoutMs() return (tonumber(conf().LoadTimeoutS) or 15) * 1000 end
local function resultsWaitMs() return (tonumber(conf().ResultsWaitS) or 90) * 1000 end

-- the launch arguments of the cup's next race: class, vehicle, picks, mods (main.lua sets this to the same values its
-- NEXT RACE tile passes, so a chained race is set up exactly like a menu launch)
function CH.args(run) return run.class, run.vehicle, run.picks, run.mods end

---------------------------------------------------------------------------------------------------------------------
-- same planet: the codename folder right after /Planets/ in the event path ('.../Planets/Mastiff/Loop_A/EVT_...' ->
-- 'Mastiff'), compared without case (the paths mix cases: 'Husky/LOOP_A'). Unknown = not the same.

function CH.planet(path) return type(path) == 'string' and path:match('/Planets/([^/]+)/') or nil end
function CH.samePlanet(a, b)
  local x, y = CH.planet(a), CH.planet(b)
  return x ~= nil and y ~= nil and x:lower() == y:lower()
end

-- chain this race? -> { want = true, next = the next race (config entry) } or { why = the reason not (for the log) }.
-- r = race.lua's run (r.ev = the race just finished)
function CH.plan(r)
  local ev, run = r.ev or {}, K.run()
  if ev.titleRace or not (run and ev.cup == run.cup and ev.race == run.race and ev.class == run.class) then
    return { quiet = true, why = 'not a cup race' }
  end
  if not CH.on() then return { why = 'ChainRaces is off: the standings at the main menu' } end
  local nxt = K.races(K.cup(run.cup), run.class)[(ev.race or 0) + 1]
  if not nxt then return { why = ('race %d of %d: the cup result at the main menu'):format(ev.race or 0, run.races) } end
  if not CH.samePlanet(ev.path, nxt.path) and not CH.crossPlanet() then
    return { why = ('the next race is on another planet (%s -> %s) and CrossPlanet is off: the standings at the main menu'):format(
      tostring(CH.planet(ev.path)), tostring(CH.planet(nxt.path))) }
  end
  return { want = true, next = nxt }
end

---------------------------------------------------------------------------------------------------------------------
-- the recipe (KNOWLEDGE.md §3: the B9 route): the next event into the active stage of both copies, read back

-- the active stage of a recipe holder (FEventRecipe: .EventStages) for an ActiveStage index (0-based) -> 1-based index
local function stageIx(recipe, active)
  local n = tonumber(try(function() return recipe.EventStages:GetArrayNum() end)) or 0
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
    C.idname(try(function() return get().TrackDef end)), tostring(tonumber(try(function() return get().LapCount end))),
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
  if tonumber(try(function() return get().LapCount end)) ~= w.laps then bad[#bad + 1] = 'LapCount' end
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
  w.laps = tonumber(try(function() return e.LapCount end))
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
      track = pathOf(try(function() return subStage().TrackDef end)), laps = tonumber(try(function() return subStage().LapCount end)),
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
-- the results screen: the panel and the NEXT RACE button

local used = {} -- results screens already given a panel (name@address: a finished race's screen can linger a moment)
local function key(o) return C.idname(o) .. '@' .. tostring(C.addr(o)) end
local function findScreen()
  for _, w in ipairs(C.find(CH.RESULTS)) do
    if not used[key(w)] and try(function() return w:IsInViewport() end) == true then return w end
  end
  return nil
end
local function v2(v) return v and { X = v.X, Y = v.Y } or nil end

-- the prompt under the standings: what the two buttons do
function CH.prompt(out)
  local nxt, run = K.nextRace(), out and out.run
  if not (nxt and run) then return nil end
  return ('NEXT RACE: race %d of %d, %s.     CONTINUE: the main menu (to leave the cup).'):format(nxt.race, run.races, nxt.title)
end

-- the button's label: the game's button keeps it in ButtonLabel and its text block (FreeRace's set_label)
local function setLabel(b, s)
  local t = FText(s)
  try(function() b.ButtonLabel = t end)
  try(function() b:SetText(t) end)
  local inner = try(function() return b.Txt_Label end)
  if alive(inner) then try(function() inner:SetText(t) end) end
  try(function() b:UpdateText() end)
end

-- NEXT RACE beside CONTINUE: a button of CONTINUE's own class (so it looks and takes the pad like it), toggleable so a
-- press (pad A, Enter, a click) flips its selected state through the game's own code; the two placed either side of
-- the centre. Returns the button or nil + why.
local function addButton(cont, host)
  local pc, lib = C.localPC(), C.lib('WidgetBlueprintLibrary', 'UMG')
  local cls = try(function() return cont:GetClass() end)
  if not (alive(pc) and alive(lib) and alive(cls)) then return nil, 'no player controller / widget library / button class' end
  local btn = try(function() return lib:Create(pc, cls, pc) end)
  if not alive(btn) then return nil, 'the button was not made' end
  require('ui').makeToggle(btn)
  try(function() btn:SetIsSelected(false, false) end)
  setLabel(btn, 'NEXT RACE')
  local slot = try(function() return host:AddChildToCanvas(btn) end)
  local cs = try(function() return cont.Slot end)
  if not (alive(slot) and alive(cs)) then try(function() btn:RemoveFromParent() end); return nil, 'the button was not placed' end
  local a = try(function() local x = cs:GetAnchors(); return { Minimum = v2(x.Minimum), Maximum = v2(x.Maximum) } end)
  if a and a.Minimum and a.Maximum then try(function() slot:SetAnchors(a) end) end
  local al = try(function() return v2(cs:GetAlignment()) end)
  if al then try(function() slot:SetAlignment(al) end) end
  try(function() slot:SetAutoSize(cs:GetAutoSize()) end)
  try(function() slot:SetZOrder(cs:GetZOrder()) end)
  local half = ((tonumber(try(function() return cont.WidthOverride end)) or 300) + GAP) / 2
  local pos = try(function() return v2(cs:GetPosition()) end) or { X = 0, Y = -76 }
  try(function() slot:SetPosition({ X = pos.X - half, Y = pos.Y }) end)
  try(function() cs:SetPosition({ X = pos.X + half, Y = pos.Y }) end)
  try(function() btn:SetNavigationRuleExplicit(1, cont) end)  -- EUINavigation Right
  try(function() cont:SetNavigationRuleExplicit(0, btn) end)  -- Left
  require('ui').grabFocus(btn, pc)
  return btn
end

-- the standings panel (and NEXT RACE) on the results screen w, for the recorded result out. Returns ok, text for the log.
function CH.addPanel(w, out, st)
  local tree = try(function() return w.WidgetTree end)
  local cont = try(function() return w.WBP_Common_Btn_Continue end)
  local host = alive(cont) and try(function() return cont:GetParent() end) or nil
  if not alive(tree) then return false, 'the results screen has no widget tree' end
  if not alive(host) then return false, 'the results screen has no CONTINUE button / canvas' end
  local U = require('ui')
  local spec = require('standings').spec(out)
  local prompt = CH.prompt(out)
  spec.after = prompt and { { prompt, 22, U.GOLD } } or nil
  local P = conf().Panel or {}
  local panel, why = U.panel(spec, tree, { minW = P.MinWidth, minH = P.MinHeight })
  if not panel then return false, why end
  local slot = try(function() return host:AddChildToCanvas(panel) end)
  if not alive(slot) then return false, ('the canvas %s refused the panel'):format(C.idname(host)) end
  try(function() slot:SetAnchors({ Minimum = { X = 0.5, Y = 0 }, Maximum = { X = 0.5, Y = 0 } }) end)
  try(function() slot:SetAlignment({ X = 0.5, Y = 0 }) end)
  try(function() slot:SetAutoSize(true) end)
  try(function() slot:SetPosition({ X = 0, Y = tonumber(P.Y) or 330 }) end)
  try(function() slot:SetZOrder(50) end)
  st.panel = true
  local btn, bwhy = addButton(cont, host)
  st.btn = btn and C.ref(btn) or nil
  local rows = spec.table and #spec.table.rows or 0
  return true, ('on %s (%s): %d lines, %d table rows; %s'):format(C.idname(host), C.clsname(host), #spec.lines, rows,
    btn and 'NEXT RACE button beside CONTINUE, focused' or ('no NEXT RACE button (' .. tostring(bwhy) .. '): key ' .. tostring(conf().Key or '-') .. ' only'))
end

---------------------------------------------------------------------------------------------------------------------
-- the way out when something fails: the game's own CONTINUE (to the main menu, where race.lua hands back the recorded
-- result and today's standings page shows). r = the run whose screen / race state to use.

function CH.fallback(r, why)
  log('[chain] fallback: ' .. tostring(why) .. ' - CONTINUE to the main menu, the standings there')
  local w = r.screenRef and C.deref(r.screenRef) or nil
  local cont = w and try(function() return w.WBP_Common_Btn_Continue end)
  if w and alive(cont) and pcall(function() w[CH.CONTINUE_EVENT](w, cont) end) then
    log('[chain] fallback: the results screen\'s CONTINUE pressed')
    return true
  end
  local gs = r.gsRef and C.deref(r.gsRef) or nil
  local gm = gs and try(function() return gs.AuthorityGameMode end)
  if not alive(gm) then gm = C.first('RacingGameMode') end
  if alive(gm) and pcall(function() gm:RequestReturnToMenus() end) then
    log('[chain] fallback: RacingGameMode:RequestReturnToMenus() called')
    return true
  end
  log('[chain] fallback: could not leave for the main menu by itself - press CONTINUE (or quit from the pause menu)')
  return false
end

---------------------------------------------------------------------------------------------------------------------
-- every tick once you have finished (race.lua R.watch). api = race.lua's own { readField(r), record(r), launch(r) }.

function CH.tick(r, api)
  local st = r.chain
  if not st then
    st = CH.plan(r)
    st.at = C.clock
    r.chain = st
    if st.want then
      CH.key = false
      log(('[chain] race %d of %d finished: next %s (same planet) - looking for the results screen'):format(r.ev.race or 0,
        (K.run() or {}).races or 4, st.next.title))
    elseif not st.quiet then
      log('[chain] not chaining: ' .. st.why)
    end
  end
  if not st.want or st.done then return end
  if not st.panel then
    if C.clock - (st.lastLook or -1e9) < LOOK_MS then return end
    st.lastLook = C.clock
    if C.clock - st.at > resultsWaitMs() then
      st.done = true
      log(('[chain] no results screen %d s after the finish: the standings at the main menu'):format(resultsWaitMs() // 1000))
      return
    end
    local w = findScreen()
    if not w then return end
    used[key(w)] = true
    st.screen, r.screenRef = C.ref(w), C.ref(w)
    -- the race recorded now, by race.lua's own recording (the main menu hands this result back instead of recording)
    api.readField(r)
    r.recordTried = true
    local out = api.record(r)
    r.recorded = out
    if not out or out.cupOver or not K.run() then
      st.done = true
      log('[chain] the race ended the cup after all: the cup result at the main menu')
      return
    end
    local ok, why = CH.addPanel(w, out, st)
    if not ok then
      st.done = true
      log('[chain] panel NOT added: ' .. tostring(why) .. ' - CONTINUE goes to the standings at the main menu')
      return
    end
    st.panelAt = C.clock
    log('[chain] panel added: ' .. why)
    return
  end
  -- the panel is up: NEXT RACE (the button, read every POLL_MS; the key at once)
  local keyed = CH.key
  if not keyed and C.clock - (st.lastPoll or -1e9) < POLL_MS then return end
  st.lastPoll = C.clock
  local btn = st.btn and C.deref(st.btn) or nil
  if st.btn and not btn then
    st.done = true
    log('[chain] the results screen went before NEXT RACE (CONTINUE, or the game moved on): the standings at the main menu')
    return
  end
  local how = keyed and ('key ' .. tostring(conf().Key)) or nil
  CH.key = false
  if btn and not how then
    if try(function() return btn:GetSelected() end) == true then how = 'the NEXT RACE button'
    elseif C.clock - (st.panelAt or 0) < FOCUS_MS and try(function() return btn:HasKeyboardFocus() end) ~= true then
      try(function() btn:SetFocus() end)
    end
  end
  if not how then return end
  st.done = true
  if btn then
    try(function() btn:SetIsSelected(false, false) end)
    try(function() btn:SetIsEnabled(false) end)
  end
  log('[chain] NEXT RACE pressed (' .. how .. ')')
  local ok, why = api.launch(r)
  if not ok then CH.fallback(r, why) end
end

return CH
