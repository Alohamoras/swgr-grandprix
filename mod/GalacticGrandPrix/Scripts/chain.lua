-- Galactic Grand Prix v0.19: cups without the main menu (TASKS.md "Next" 2, DESIGN.md §15).
-- Proven by RaceFlowSpike B9 (tools/recon/RaceFlowSpike, raceflow-b9-20261111.log): a panel added to the game's results
-- screen WBP_SimpleRaceResultsScreen_C on its canvas Default_Results (CONTINUE's parent) shows over it.
-- (v0.19.0's other route, the next event written into the race recipe and BP_RacingGameMode_C:RequestResetRace(), hung
-- on PLEASE WAIT across layouts in game; off by default since v0.19.1, removed after v0.21.0:
-- attic/chain-reset-route.lua.)
--
-- v0.19.1: NEXT RACE goes VIA THE MENU. The flow, after a cup race that isn't the cup's last (race.lua R.watch calls
-- CH.tick once you have finished):
--   1. CH.plan: chain this race? (ChainRaces.On, a cup race with a next race - any cup, the Galactic Cup too).
--      Not chaining: nothing in the race world, the main menu as before.
--   2. Look for the results screen (one sweep every LOOK_MS, up to ResultsWaitS). Found: the race is recorded right
--      then by race.lua's own recording (K.record - the main menu then hands back this result instead of recording
--      again), and our panel goes on the screen: the standings (standings.lua) on an opaque dark box (the game's own
--      table hidden under it), a prompt, and a NEXT RACE button of CONTINUE's own class left of CONTINUE, focused.
--   3. NEXT RACE (the button's selected state, polled; or ChainRaces.Key): CH.via is set (plain values: cup, class,
--      race number) and the results go to the main menu the game's own way (CH.leave: the screen's CONTINUE click,
--      else RequestReturnToMenus). At the menu main.lua sees CH.via: the cover goes up instead of the standings page,
--      and once the menu has settled (menu up, no race, put-backs done, settled ChainRaces.MenuSettleS) the next race
--      launches through R.launch, exactly as NEXT RACE on the standings page would. A failed launch: the cover off,
--      today's standings page.
--   4. CONTINUE (or the game moving on by itself) instead: the main menu, and today's standings page (CH.via unset).
--      v0.21 (owner: "there doesn't need to be a continue button ... redundant and misleading"): the game's CONTINUE is
--      hidden (Collapsed: it can't be focused or clicked; ChainRaces.Panel.HideContinue) once NEXT RACE is in place,
--      NEXT RACE centred where the two buttons were. B leaves the cup: our own hidden Back screen in the panel (the
--      tab page's trick, tab.lua) reads the pad's B, the key binds Backspace / Escape set CH.back (flags only). B ->
--      CH.leaveAsk set, the results left for the main menu (CONTINUE's event pressed from code, hidden or not), and
--      main.lua opens "Leave the cup?" straight away (NO = the standings with NEXT RACE). The results screen closing
--      on its own with CONTINUE hidden (the game's own back handling B first) counts as B too. The last race of a
--      cup is never chained: the game's CONTINUE stays (the cup result).
-- A failure before NEXT RACE ends at today's standings page, with a `[chain]` log line.
--
-- House rules: no hooks (the key bind only sets a flag; the button is read by polling), every engine call guarded,
-- nothing kept between ticks but C.ref (path + address) of the screen and our button, looked up again (a sweep, at most
-- every POLL_MS) only while the panel is up.
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
function CH.settleMs() return (tonumber(conf().MenuSettleS) or 5) * 1000 end

-- v0.19.1: the via-the-menu request: { cup, class, race = the race number to launch, title, at = C.clock } (plain
-- values only), set by NEXT RACE; read and cleared by main.lua at the main menu. nil = CONTINUE's meaning: today's
-- standings page.
CH.via = nil
-- v0.21: B on the results screen's panel: { cup, class, race = the race just run } (plain values), read and cleared
-- by main.lua at the main menu ("Leave the cup?" straight away)
CH.leaveAsk = nil
local function hideContinue() return (conf().Panel or {}).HideContinue ~= false end
CH.hideContinue = hideContinue
local function resultsWaitMs() return (tonumber(conf().ResultsWaitS) or 90) * 1000 end

-- chain this race? -> { want = true, next = the next race (config entry), how = text } or { why = the reason not (for
-- the log) }.
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
  return { want = true, next = nxt, how = 'NEXT RACE via the menu' }
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

-- NEXT RACE by the menu: the request set, then the results to the main menu (main.lua does the rest)
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

---------------------------------------------------------------------------------------------------------------------
-- every tick once you have finished (race.lua R.watch). api = race.lua's own { readField(r), record(r) }.

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
  CH.goViaMenu(r)
end

return CH
