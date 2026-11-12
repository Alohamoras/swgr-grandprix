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
-- House rules: no hooks (the key bind only sets a flag; the button is read by polling), every engine call guarded,
-- nothing kept between ticks but C.ref (path + address) of the screen and our button, looked up again (a sweep, at most
-- every POLL_MS) only while the panel is up. Soft pointers: the stage struct holds one (ExtraWinCriteria), so it is
-- never read whole - only its four plain fields. The recipe's originals are put back at the main menu (CH.putBack,
-- from race.lua R.restoreBuild); they are memory only, so a game restart undoes them too.
local C = require('core')
local cfg = require('config')
local K = require('gp')
local try, alive, log = C.try, C.alive, C.log

local CH = { key = false, back = false }
CH.RESULTS = 'WBP_SimpleRaceResultsScreen_C'
-- the results screen's own CONTINUE click (FreeRace's retry.lua presses CONTINUE the same way)
CH.CONTINUE_EVENT = 'BndEvt__WBP_SimpleRaceResultsScreen_WBP_Common_Btn_K2Node_ComponentBoundEvent_1_CommonButtonBaseClicked__DelegateSignature'
local LOOK_MS = 300   -- the results screen looked for this often once you have finished (a sweep each time)
local POLL_MS = 200   -- our NEXT RACE button read this often while the panel is up (a lookup each time)
local FOCUS_MS = 1500 -- focus given back to NEXT RACE for this long after it is added (the screen may take it once)
local GAP = 80        -- canvas units between NEXT RACE and CONTINUE (v0.19.1: was 40, and they overlapped in game)
local MIN_BTN_W = 420 -- the least width taken for a button when its own can't be read

local function conf() return type(cfg.ChainRaces) == 'table' and cfg.ChainRaces or {} end
function CH.on() return conf().On == true end
-- v0.19.1: the reset route only on request (proven for Loop_A -> Loop_A only); CrossPlanet is gone (the via-the-menu
-- flow works for every cup; the reset route needs the same layout folder, which is always the same planet)
function CH.resetOn() return conf().Reset == true end
function CH.loadTimeoutMs() return (tonumber(conf().LoadTimeoutS) or 15) * 1000 end
function CH.watchdogMs() return (tonumber(conf().WatchdogS) or 20) * 1000 end
function CH.settleMs() return (tonumber(conf().MenuSettleS) or 5) * 1000 end

-- v0.19.1: the via-the-menu request: { cup, class, race = the race number to launch, title, at = C.clock } (plain
-- values only), set by NEXT RACE (route 'menu') or a failure of the reset route; read and cleared by main.lua at the
-- main menu. nil = CONTINUE's meaning: today's standings page.
CH.via = nil
-- v0.21: B on the results screen's panel: { cup, class, race = the race just run } (plain values), read and cleared
-- by main.lua at the main menu ("Leave the cup?" straight away)
CH.leaveAsk = nil
local function hideContinue() return (conf().Panel or {}).HideContinue ~= false end
CH.hideContinue = hideContinue
local function resultsWaitMs() return (tonumber(conf().ResultsWaitS) or 90) * 1000 end

-- the launch arguments of the cup's next race: class, vehicle, picks, mods (main.lua sets this to the same values its
-- NEXT RACE tile passes, so a chained race is set up exactly like a menu launch)
function CH.args(run) return run.class, run.vehicle, run.picks, run.mods end

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

-- the prompt under the standings: what the button(s) do (v0.21: NEXT RACE and B; HideContinue = false: v0.20's)
function CH.prompt(out)
  local nxt, run = K.nextRace(), out and out.run
  if not (nxt and run) then return nil end
  if hideContinue() then return ('NEXT RACE: race %d of %d, %s.   B: leave the cup.'):format(nxt.race, run.races, nxt.title) end
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

-- a widget's width on the canvas: the largest of its desired size (laid out by now: the screen has been up a moment),
-- its width override and its slot's size; nil when none can be read
local function widthOf(w, slot)
  local best
  local function take(v) v = tonumber(v); if v and v > 0 and (not best or v > best) then best = v end end
  take(try(function() return w:GetDesiredSize().X end))
  take(try(function() return w.WidthOverride end))
  take(slot and try(function() return slot:GetSize().X end))
  return best
end
CH.widthOf = widthOf -- (tests)

-- NEXT RACE beside CONTINUE: a button of CONTINUE's own class (so it looks and takes the pad like it), toggleable so a
-- press (pad A, Enter, a click) flips its selected state through the game's own code. v0.19.1: side by side, never
-- overlapping (v0.19.0's 300-unit guess overlapped in game): both centred on their own half (alignment X 0.5), NEXT
-- RACE left of where CONTINUE was, CONTINUE right of it, GAP apart, each by the wider of the two (NEXT RACE's longer
-- label: its width taken as CONTINUE's x 1.2, at least MIN_BTN_W). Returns the button (and the layout text) or nil + why.
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
  local al = try(function() return v2(cs:GetAlignment()) end) or { X = 0.5, Y = 1 }
  local ctr = { X = 0.5, Y = al.Y }
  try(function() slot:SetAlignment(ctr) end)
  try(function() slot:SetAutoSize(cs:GetAutoSize()) end)
  try(function() slot:SetZOrder(cs:GetZOrder()) end)
  local P = conf().Panel or {}
  local gap = tonumber(P.ButtonGap) or GAP
  local wc = math.max(widthOf(cont, cs) or 0, MIN_BTN_W)
  local w = math.max(wc * 1.2, tonumber(P.ButtonWidth) or 0)
  local pos = try(function() return v2(cs:GetPosition()) end) or { X = 0, Y = -76 }
  -- CONTINUE's centre where it was (by its own alignment), then the two centres either side of it
  local mid = pos.X + (0.5 - (al.X or 0.5)) * wc
  try(function() btn.WidthOverride = w end)
  if hideContinue() then
    -- v0.21: NEXT RACE alone, centred where the two buttons were (CONTINUE's centre); CONTINUE hidden (Collapsed: no
    -- focus, no click; the fallbacks still press its event from code)
    try(function() slot:SetPosition({ X = mid, Y = pos.Y }) end)
    local okH = pcall(function() cont:SetVisibility(1) end)
    require('ui').grabFocus(btn, pc)
    return btn, ('NEXT RACE alone at x %d (centred; slot %d wide); the game\'s CONTINUE %s'):format(math.floor(mid), math.floor(w),
      okH and 'hidden' or 'NOT hidden (SetVisibility refused)'), okH
  end
  local half = w / 2 + gap / 2
  try(function() cs:SetAlignment(ctr) end)
  try(function() slot:SetPosition({ X = mid - half, Y = pos.Y }) end)
  try(function() cs:SetPosition({ X = mid + half, Y = pos.Y }) end)
  -- (and a fixed width each, so neither grows into the other)
  try(function() btn:SetNavigationRuleExplicit(1, cont) end)  -- EUINavigation Right
  try(function() cont:SetNavigationRuleExplicit(0, btn) end)  -- Left
  require('ui').grabFocus(btn, pc)
  return btn, ('NEXT RACE at x %d, CONTINUE at x %d (centres; CONTINUE %d wide, slot %d, gap %d)'):format(math.floor(mid - half),
    math.floor(mid + half), math.floor(wc), math.floor(w), math.floor(gap))
end

-- v0.21: an invisible Back screen in the panel (tab.lua's trick for our page): an activatable widget that handles
-- Back, so the pad's B deactivates it - read as B (CH.tick). Made in the results screen's own canvas; kept as C.ref.
-- Returns its ref, or nil + why.
local ACTIVATABLE = '/Script/CommonUI.CommonActivatableWidget'
local function addBackScreen(host, tree)
  local pc, lib, cls = C.localPC(), C.lib('WidgetBlueprintLibrary', 'UMG'), C.uclass(ACTIVATABLE)
  local h = (alive(pc) and alive(lib) and cls) and try(function() return lib:Create(pc, cls, pc) end)
  if not alive(h) then return nil, 'the Back screen was not made' end
  try(function() h.bSupportsActivationFocus = false end)
  try(function() h.bIsBackHandler = true end)
  try(function() h.bAutoActivate = true end)
  local box = try(function() return StaticConstructObject(StaticFindObject('/Script/UMG.SizeBox'), tree) end)
  if alive(box) then
    try(function() box:SetWidthOverride(1); box:SetHeightOverride(1) end)
    try(function() box:AddChild(h) end)
    try(function() box:SetRenderOpacity(0) end)
    try(function() box:SetVisibility(3) end) -- HitTestInvisible
  end
  local slot = try(function() return host:AddChildToCanvas(alive(box) and box or h) end)
  if not alive(slot) then return nil, 'the canvas refused the Back screen' end
  try(function() h:ActivateWidget() end)
  return C.ref(h)
end

-- v0.19.1: the game's own results table (WBP_Simple_RaceResultsPanel_C, RaceFlowSpike B9: the mode rules'
-- ResultsTableWidget) hidden while our panel is over it (it showed through in v0.19.0). One sweep, once; it goes with
-- the results screen. Returns how many were hidden.
CH.GAME_TABLE = 'WBP_Simple_RaceResultsPanel_C'
local function hideGameTable()
  if (conf().Panel or {}).HideGameTable == false then return 0 end
  local n = 0
  for _, t in ipairs(C.find(CH.GAME_TABLE)) do
    if try(function() return t:IsVisible() end) == true and pcall(function() t:SetVisibility(2) end) then n = n + 1 end -- Hidden
  end
  return n
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
  local hidden = hideGameTable()
  local btn, bwhy, contHidden = addButton(cont, host)
  st.btn = btn and C.ref(btn) or nil
  st.contHidden = contHidden == true
  -- v0.21: B leaves the cup (the pad's B through our Back screen; Backspace / Escape through the flag)
  local back, backWhy = nil, nil
  if hideContinue() then back, backWhy = addBackScreen(host, tree) end
  st.back = back
  CH.back = false
  local rows = spec.table and #spec.table.rows or 0
  return true, ('on %s (%s): %d lines, %d table rows, opaque; the game\'s table %s; %s%s'):format(C.idname(host), C.clsname(host), #spec.lines, rows,
    hidden > 0 and ('hidden (' .. hidden .. ')') or 'not found (left as it is)',
    btn and ((st.contHidden and 'NEXT RACE button, focused: ' or 'NEXT RACE button left of CONTINUE, focused: ') .. bwhy)
      or ('no NEXT RACE button (' .. tostring(bwhy) .. '): key ' .. tostring(conf().Key or '-') .. ' only'),
    hideContinue() and ('; B: ' .. (back and 'the Back screen (pad) and Backspace / Escape' or ('Backspace / Escape only (' .. tostring(backWhy) .. ')'))) or '')
end

---------------------------------------------------------------------------------------------------------------------
-- leaving the race world for the main menu the game's own way: the results screen's CONTINUE (its bound click event,
-- as FreeRace's retry.lua presses it), else RacingGameMode:RequestReturnToMenus(). r = the run whose screen / race
-- state to use. Returns true when one of them was called.

function CH.leave(r, noScreen)
  local w = (not noScreen and r.screenRef) and C.deref(r.screenRef) or nil
  local cont = w and try(function() return w.WBP_Common_Btn_Continue end)
  if w and alive(cont) and pcall(function() w[CH.CONTINUE_EVENT](w, cont) end) then
    log('[chain] the results screen\'s CONTINUE pressed')
    return true
  end
  local gs = r.gsRef and C.deref(r.gsRef) or nil
  local gm = gs and try(function() return gs.AuthorityGameMode end)
  if not alive(gm) then gm = C.first('RacingGameMode') end
  if alive(gm) and pcall(function() gm:RequestReturnToMenus() end) then
    log('[chain] RacingGameMode:RequestReturnToMenus() called')
    return true
  end
  log('[chain] could not leave for the main menu by itself - press CONTINUE (or quit from the pause menu)')
  return false
end

-- v0.19.1: the via-the-menu request for the cup's next race (plain values). Returns it, or nil (no cup race next).
function CH.setVia()
  local run, nxt = K.run(), K.nextRace()
  if not (run and nxt) then CH.via = nil; return nil end
  CH.via = { cup = run.cup, class = run.class, race = nxt.race, races = run.races, title = nxt.title, at = C.clock }
  return CH.via
end

-- NEXT RACE by the menu (route 'menu'): the request set, then the results to the main menu (main.lua does the rest)
function CH.goViaMenu(r)
  local v = CH.setVia()
  if not v then log('[chain] via the menu: no cup race to run next - the main menu as usual'); return CH.leave(r) end
  log(('[chain] via the menu: race %d of %d (%s) launches from the main menu under the cover - leaving the results now'):format(
    v.race, v.races or 4, v.title))
  if CH.leave(r) then return true end
  CH.via = nil
  log('[chain] via the menu: dropped (the results screen could not be left) - CONTINUE goes to the standings page')
  return false
end

-- the results screen went before NEXT RACE (seen here, or by race.lua when the main menu came first). v0.21: with
-- CONTINUE hidden only B (the game's own back handling) can close it: "Leave the cup?" at the main menu; else (v0.20's
-- CONTINUE, or a failed panel) today's standings page.
function CH.goneBeforeNext(r, what)
  local st = r.chain
  if not st or st.done then return end
  st.done = true
  local run = K.run()
  if st.contHidden and run then
    CH.leaveAsk = { cup = run.cup, class = run.class, race = r.ev and r.ev.race }
    log(('[chain] %s before NEXT RACE with CONTINUE hidden (the game\'s own B / Escape): "Leave the cup?" at the main menu'):format(what))
  else
    log(('[chain] %s before NEXT RACE (CONTINUE, or the game moved on): the standings at the main menu'):format(what))
  end
end

-- v0.21: B on the panel: "Leave the cup?" at the main menu (main.lua), the results left the game's own way
function CH.goLeave(r, how)
  local run = K.run()
  CH.via = nil
  CH.leaveAsk = run and { cup = run.cup, class = run.class, race = r.ev and r.ev.race } or nil
  log(('[chain] B on the results screen (%s): to the main menu, then "Leave the cup?"'):format(how))
  return CH.leave(r)
end

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
-- every tick once you have finished (race.lua R.watch). api = race.lua's own { readField(r), record(r), launch(r) }.

function CH.tick(r, api)
  local st = r.chain
  if not st then
    st = CH.plan(r)
    st.at = C.clock
    r.chain = st
    if st.want then
      CH.key = false
      log(('[chain] race %d of %d finished: next %s (%s) - looking for the results screen'):format(r.ev.race or 0,
        (K.run() or {}).races or 4, st.next.title, st.how))
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
    CH.goneBeforeNext(r, 'the results screen went')
    return
  end
  -- v0.21: B (the keyboard flag at once; the pad's B through our Back screen, read with the button)
  local backHow = CH.back and 'Backspace / Escape' or nil
  CH.back = false
  if not backHow and st.back then
    local h = C.deref(st.back)
    if h then
      local active = try(function() return h:IsActivated() end) == true
      if active then st.backOn = true
      elseif st.backOn then backHow = 'the pad\'s B'
      else try(function() h:ActivateWidget() end) end
    end
  end
  if backHow and st.contHidden then
    st.done = true
    if btn then try(function() btn:SetIsEnabled(false) end) end
    CH.goLeave(r, backHow)
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
  if st.route == 'reset' then
    local ok, why = api.launch(r)
    if not ok then CH.fallback(r, why, true) end
  else
    CH.goViaMenu(r)
  end
end

return CH
