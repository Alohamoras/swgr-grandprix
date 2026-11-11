-- Galactic Grand Prix (from the Underground): the GRAND PRIX tab on the game's main menu.
--
-- Why a tab: CommonUI (the game's UI system) only hands the controller to *active screens*. v0.7-v0.8 drew the
-- Underground as an overlay over a hidden main menu, which isn't one, so the game kept taking focus back and A / B
-- never reached our tiles. A tab on the menu's own tab list puts our page inside the main menu, which is the active
-- screen: the game moves focus between our tiles and clicks them itself (approach learned from the FreeRace mod;
-- our own code).
--
-- How:
--   * the menu (WBP_FE_MainMenu_C) has WBP_Tab_List (the tab bar) and WS_ScreenContent (the switcher showing the
--     selected tab's page). Our tab is registered on the tab bar with the class of the bar's first button (looks and
--     behaves like the others) and a stub widget as its "content" (the switcher never shows it).
--   * our page is a panel placed right after WS_ScreenContent; while our tab is selected the switcher is collapsed
--     and our panel shown, and the other way round when another tab is picked.
--   * B: a sub-page holds an invisible activatable widget that handles Back; B makes the game deactivate it, which
--     we read as BACK (T.backPressed) and switch it on again.
--   * the menu is rebuilt after every race, so menus are re-discovered (about once a second, front end only).
-- No hooks anywhere (they never fired for the pad and went stale on reloads, followed by a crash: v0.8.5).
local C = require('core')
local cfg = require('config')
local try, alive, idname, clsname, log = C.try, C.alive, C.idname, C.clsname, C.log

local T = { ID = 'Mod_GrandPrix', screens = {}, failed = nil, ms = 0 }
local VIS = { visible = 0, collapsed = 1, hidden = 2, hitInvisible = 3, selfHitInvisible = 4 }
T.VIS = VIS

local said = {}
local function once(key, msg) if not said[key] then said[key] = true; log(msg) end end
-- breadcrumbs for crash hunting (v0.9.1): a line before each step that touches the game's menu, so a crash shows where
-- it was (the log is written line by line). config TabTrace = false turns them off once the tab is proven.
local function step(msg) if cfg.TabTrace ~= false then log('[tab] .. ' .. msg) end end
local function isActive(w) return try(function() return w:IsActivated() end) == true end
local function inView(w) return try(function() return w:IsInViewport() end) == true end
local function str(n)
  if type(n) == 'string' then return n end
  local s = try(function() return n:ToString() end)
  return type(s) == 'string' and s or nil
end
T.str = str

-- a plain UMG widget (box, text) owned by the menu's widget tree
function T.plain(sc, path)
  local cls = C.uclass(path)
  if not (cls and alive(sc.tree)) then return nil end
  local w = try(StaticConstructObject, cls, sc.tree)
  return alive(w) and w or nil
end

---------------------------------------------------------------------------------------------------------------------
-- placing our page next to the game's content switcher

local function slotOf(w)
  local sl = try(function() return w.Slot end)
  if not alive(sl) then return nil end
  return {
    size = try(function() return { SizeRule = tonumber(sl.Size.SizeRule) or 1, Value = sl.Size.Value or 1 } end),
    pad = try(function() local m = sl.Padding; return { Left = m.Left, Top = m.Top, Right = m.Right, Bottom = m.Bottom } end),
    h = try(function() return tonumber(sl.HorizontalAlignment) end),
    v = try(function() return tonumber(sl.VerticalAlignment) end),
  }
end
local function applySlot(slot, p)
  if not (alive(slot) and p) then return end
  if p.size then try(function() slot:SetSize(p.size) end) end
  if p.pad then try(function() slot:SetPadding(p.pad) end) end
  if p.h then try(function() slot:SetHorizontalAlignment(p.h) end) end
  if p.v then try(function() slot:SetVerticalAlignment(p.v) end) end
end
local function children(panel)
  local out, n = {}, tonumber(try(function() return panel:GetChildrenCount() end)) or 0
  for i = 0, n - 1 do
    local c = try(function() return panel:GetChildAt(i) end)
    if alive(c) then out[#out + 1] = c end
  end
  return out
end

-- returns a description of where the page went, or nil
local function place(sc, panel)
  step('reading where the content switcher sits')
  local parent = try(function() return sc.ws:GetParent() end)
  local kind = alive(parent) and clsname(parent) or '(none)'
  step('content switcher sits in ' .. kind)
  if kind:find('VerticalBox', 1, true) then
    local like = slotOf(sc.ws)
    local at = tonumber(try(function() return parent:GetChildIndex(sc.ws) end))
    if at and at >= 0 then
      local slot = try(function() return parent:InsertChildAt(at + 1, panel) end)
      if not alive(slot) then
        -- no InsertChildAt: take the children after the switcher off, add the panel, put them back as they were
        local after = {}
        local kids = children(parent)
        for i = at + 2, #kids do after[#after + 1] = { w = kids[i], p = slotOf(kids[i]) } end
        step(('switcher is child %d of %d; moving %d after it'):format(at, #kids, #after))
        for _, a in ipairs(after) do step('taking off ' .. idname(a.w)); try(function() parent:RemoveChild(a.w) end) end
        step('adding the page')
        slot = try(function() return parent:AddChildToVerticalBox(panel) end)
        for _, a in ipairs(after) do
          step('putting back ' .. idname(a.w))
          applySlot(try(function() return parent:AddChildToVerticalBox(a.w) end), a.p)
        end
      end
      if alive(slot) then applySlot(slot, like); return 'after the content switcher in ' .. kind end
    end
  elseif kind:find('Overlay', 1, true) then
    local slot = try(function() return parent:AddChildToOverlay(panel) end)
    if alive(slot) then
      applySlot(slot, slotOf(sc.ws))
      return 'over the content switcher in ' .. kind
    end
  end
  -- last resort: over the whole menu, kept clear of the tab bar and footer
  local root = try(function() return sc.tree.RootWidget end)
  local slot = alive(root) and (try(function() return root:AddChildToOverlay(panel) end) or try(function() return root:AddChild(panel) end))
  if alive(slot) then
    try(function() slot:SetPadding({ Left = 160, Top = 260, Right = 160, Bottom = 170 }) end)
    return 'over the whole menu (' .. clsname(root) .. '; the switcher sits in ' .. kind .. ')'
  end
  return nil
end

---------------------------------------------------------------------------------------------------------------------
-- the tab

local function tabButton(sc) return try(function() return sc.tl:GetTabButtonBaseByID(FName(T.ID)) end) end
local function tabIds(sc)
  local ids, n = {}, tonumber(try(function() return sc.tl:GetTabCount() end)) or 0
  for i = 0, n - 1 do ids[#ids + 1] = str(try(function() return sc.tl:GetTabIdAtIndex(i) end)) or '?' end
  return ids, n
end

local function register(sc)
  step('looking for our tab button')
  local b = tabButton(sc)
  if alive(b) then sc.tabBtn = b; return true end
  step('reading the tab bar')
  local ids, count = tabIds(sc)
  if count < 2 then return false, ('the tab bar has %d tabs (not built yet?)'):format(count), 'wait' end
  local firstId = try(function() return sc.tl:GetTabIdAtIndex(0) end)
  local first = firstId and try(function() return sc.tl:GetTabButtonBaseByID(firstId) end)
  local cls = alive(first) and try(function() return first:GetClass() end)
  sc.stub = alive(sc.stub) and sc.stub or T.plain(sc, '/Script/UMG.SizeBox')
  if not (alive(cls) and alive(sc.stub)) then
    return false, ('no button class (%s) or stub (%s)'):format(tostring(alive(cls)), tostring(alive(sc.stub)))
  end
  step(('RegisterTab (%d tabs: %s; button class %s)'):format(count, table.concat(ids, ', '), idname(cls)))
  local ok, err = try(function() return sc.tl:RegisterTab(FName(T.ID), cls, sc.stub, count) end)
  step('RegisterTab returned ' .. tostring(ok))
  b = tabButton(sc)
  if not alive(b) then return false, ('RegisterTab gave %s (%s), no button'):format(tostring(ok), tostring(err)) end
  try(function() b:SetText(FText(cfg.TabLabel or 'GRAND PRIX')) end)
  sc.tabBtn = b
  local after = tabIds(sc)
  log(('[tab] GRAND PRIX tab added (button %s); tabs now: %s'):format(clsname(b), table.concat(after, ', ')))
  return true
end

local function open(mm)
  step('reading the main menu ' .. idname(mm))
  local sc = { mm = mm, ref = C.ref(mm), key = C.addr(mm), tree = try(function() return mm.WidgetTree end) }
  sc.tl = try(function() return mm.WBP_Tab_List end)
  sc.ws = try(function() return mm.WS_ScreenContent end)
  if not (alive(sc.tl) and alive(sc.ws) and alive(sc.tree)) then
    return nil, ('menu parts missing: tab bar=%s content=%s widget tree=%s'):format(tostring(alive(sc.tl)),
      tostring(alive(sc.ws)), tostring(alive(sc.tree)))
  end
  sc.wsVis = tonumber(try(function() return sc.ws:GetVisibility() end)) or VIS.selfHitInvisible
  step('making the page panel')
  sc.panel = T.plain(sc, '/Script/UMG.VerticalBox')
  if not alive(sc.panel) then return nil, 'could not make the page panel' end
  try(function() sc.panel:SetVisibility(VIS.collapsed) end)
  local where = place(sc, sc.panel)
  if not where then return nil, 'could not place the page panel' end
  log('[tab] page placed ' .. where)
  return sc
end

local function fail(why)
  if T.failed then return end
  T.failed = why
  log('[tab] giving up on the tab: ' .. why .. ' - the Grand Prix will not show until the game is restarted')
  if T.onFail then pcall(T.onFail, why) end
end

-- Is this menu still there? Looked up by path + address (C.deref), never by calling the old reference: after the game
-- rebuilds its main menu the old one is freed, and touching it (or anything in its tree) can crash.
local function live(sc)
  local mm = C.deref(sc.ref)
  if not mm then return false end
  sc.mm = mm
  return true
end
-- a menu that has gone: forget it without touching any of its widgets
local function gone(key, sc)
  T.screens[key] = nil
  if T.current == sc then T.current = nil end
  if sc.shown then
    sc.shown = false
    log('[tab] the main menu with our page went away')
    if T.onGone then pcall(T.onGone, sc) end
  end
end

-- about once a second at the front end (never mid-race: it sweeps every widget of the class)
local openFails, regFails = 0, 0
-- A menu is only touched once it has been on screen and active for SETTLE passes in a row (~3 s): v0.9.0 crashed
-- the game seconds after the menu first appeared (cause not yet known: our tab code or the CampaignLogger mod).
local SETTLE = 3
local seen = {}
function T.discover()
  if T.failed then return end
  local now = {}
  local menus = C.find('WBP_FE_MainMenu_C') -- (one sweep for both passes below, v0.13.1; same tick, nothing kept)
  for _, mm in ipairs(menus) do
    local key = C.addr(mm)
    if key and not T.screens[key] and inView(mm) and isActive(mm) then
      now[key] = (seen[key] or 0) + 1
    end
  end
  seen = now
  for _, mm in ipairs(menus) do
    local key = C.addr(mm)
    if key and (seen[key] or 0) == 1 then step('main menu ' .. idname(mm) .. ' on screen - waiting for it to settle') end
    if key and not T.screens[key] and (seen[key] or 0) >= SETTLE then
      local sc, why = open(mm)
      if sc then T.screens[key] = sc; openFails = 0
      else
        openFails = openFails + 1
        once('open:' .. why, '[tab] main menu not usable yet: ' .. why)
        if openFails >= 8 then fail(why); return end
      end
    end
  end
  for key, sc in pairs(T.screens) do
    if not (live(sc) and alive(sc.tl)) then
      gone(key, sc)
    elseif not (sc.registered and alive(sc.tabBtn)) then
      local ok, why, wait = register(sc)
      sc.registered = ok
      if ok then regFails = 0
      elseif wait then
        -- the menu is still building its tabs (game start, sign-in checks): not a failure
        once('reg:wait', '[tab] waiting for the tab bar: ' .. tostring(why))
      else
        regFails = regFails + 1
        once('reg:' .. tostring(why), '[tab] could not add the tab yet: ' .. tostring(why))
        if regFails >= 10 then fail(why); return end
      end
    end
  end
end

---------------------------------------------------------------------------------------------------------------------
-- switching

-- another mod's page tab (FreeRace, Theater: ids start with Mod_) - that mod hides the game's page itself
local function otherModTab(sel) return type(sel) == 'string' and sel:sub(1, 4) == 'Mod_' and sel ~= T.ID end

---------------------------------------------------------------------------------------------------------------------
-- v0.20 (menu review 5): the game's footer ("Select / C Restart Campaign / Settings") is hidden while our tab is up.
-- The footer is the main menu's WBP_ActionBar_C (UFuseBoundActionBar inside; header dump WBP_ActionBar.hpp); the
-- FreeRace mod hides the same widget on its own tab (fr_menu.lua footer_parts: class name contains WBP_ActionBar,
-- found breadth first from the menu's root, user widgets' own trees too). Found again on each enter / leave (a short
-- walk, bounded), never kept: only its visibility number is kept, to put it back. config HideFooter = false: not
-- hidden, only found and logged. Hiding it does not unbind the game's C key (not known what C does on our page).
local FOOTER = 'WBP_ActionBar'
local WALK_MAX, WALK_DEPTH = 1500, 12
local function kids(w)
  local out = children(w)
  if #out > 0 then return out end
  local one = try(function() return w:GetContent() end)
  if alive(one) then out[1] = one end
  return out
end
-- -> the footer widget or nil, the depth, how many widgets were looked at, the root's children's classes
function T.findFooter(sc)
  local root = try(function() return sc.tree.RootWidget end)
  if not alive(root) then return nil, nil, 0, 'no root widget' end
  local top = {}
  for _, c in ipairs(kids(root)) do top[#top + 1] = idname(c) .. ' (' .. clsname(c) .. ')' end
  local queue, head, seen = { { root, 0 } }, 1, 0
  while head <= #queue and seen < WALK_MAX do
    local w, d = queue[head][1], queue[head][2]
    head = head + 1
    seen = seen + 1
    if clsname(w):find(FOOTER, 1, true) then return w, d, seen, table.concat(top, ', ') end
    if d < WALK_DEPTH then
      for _, k in ipairs(kids(w)) do queue[#queue + 1] = { k, d + 1 } end
      local inner = try(function() return w.WidgetTree.RootWidget end)
      if alive(inner) then queue[#queue + 1] = { inner, d + 1 } end
    end
  end
  return nil, nil, seen, table.concat(top, ', ')
end
local footerSaid = 0
local function footer(sc, hide)
  local on = cfg.HideFooter ~= false
  if hide and not on and footerSaid > 0 then return end -- (switched off: found and logged once per game start)
  if not hide and not sc.footerVis then return end
  local w, depth, seen, top = T.findFooter(sc)
  if not w then
    footerSaid = footerSaid + 1
    if footerSaid <= 2 then log(('[footer] not found (%d widgets looked at); the menu\'s root holds: %s'):format(seen, tostring(top))) end
    sc.footerVis = nil
    return
  end
  if hide then
    local vis = tonumber(try(function() return w:GetVisibility() end))
    if footerSaid < 3 then
      footerSaid = footerSaid + 1
      log(('[footer] found %s (%s) at depth %d (%d widgets looked at), visibility %s; %s'):format(idname(w), clsname(w),
        depth, seen, tostring(vis), on and 'hidden while the GRAND PRIX tab is up' or 'not hidden (HideFooter = false)'))
    end
    if not on then return end
    sc.footerVis = vis or VIS.selfHitInvisible
    try(function() w:SetVisibility(VIS.collapsed) end)
  else
    try(function() w:SetVisibility(sc.footerVis) end)
    log(('[footer] put back (visibility %d)'):format(sc.footerVis))
    sc.footerVis = nil
  end
end

local function enter(sc)
  sc.shown, sc.leftAt = true, nil
  try(function() sc.ws:SetVisibility(VIS.collapsed) end)
  try(function() sc.panel:SetVisibility(VIS.selfHitInvisible) end)
  T.current = sc
  log('[tab] GRAND PRIX tab selected')
  local okF, errF = pcall(footer, sc, true)
  if not okF then log('[footer] error: ' .. tostring(errF)) end
  if T.onEnter then
    local ok, err = pcall(T.onEnter, sc)
    if not ok then log('[tab] page error: ' .. tostring(err)) end
  end
end

local function leave(sc, sel)
  sc.shown = false
  try(function() sc.panel:SetVisibility(VIS.collapsed) end)
  if T.current == sc then T.current = nil end
  if T.onLeave then pcall(T.onLeave, sc) end
  try(function() sc.panel:ClearChildren() end)
  local okF, errF = pcall(footer, sc, false)
  if not okF then log('[footer] error: ' .. tostring(errF)) end
  if not otherModTab(sel) then
    try(function() sc.ws:SetVisibility(sc.wsVis or VIS.selfHitInvisible) end)
    sc.leftAt = T.ms
  end
  log('[tab] left the GRAND PRIX tab (now ' .. tostring(sel) .. ')')
end

-- leaving with LB / RB: the game focuses the next tab's content while it's still hidden, so nothing has focus and the
-- D-pad is dead. For two seconds, focus the now-visible page's own focus target until something in it has focus.
local function settle(sc)
  if T.ms - sc.leftAt > 2000 or not isActive(sc.mm) then sc.leftAt = nil; return end
  if T.ms - sc.leftAt < 200 then return end
  local shown = try(function() return sc.ws:GetActiveWidget() end)
  if not alive(shown) then return end
  if T.hasFocus(shown) then sc.leftAt = nil; return end
  local t = try(function() return shown:GetDesiredFocusTarget() end)
  if not alive(t) then t = shown end
  try(function() t:SetFocus() end)
  log('[tab] focus after leaving: ' .. idname(shown) .. ' -> ' .. idname(t))
  sc.leftAt = nil
end

-- every main-menu poll tick (dt: ms since the last call)
function T.update(dt)
  T.ms = T.ms + (dt or 200)
  for key, sc in pairs(T.screens) do
    if not (live(sc) and alive(sc.tl)) then
      gone(key, sc)
    elseif sc.registered then
      local sel = isActive(sc.mm) and str(try(function() return sc.tl:GetSelectedTabId() end)) or nil
      local want = sel == T.ID
      if want ~= (sc.shown == true) then
        if want then enter(sc) else leave(sc, sel) end
      end
      -- something (an animation, another mod) may show the game's page again under ours
      if sc.shown and tonumber(try(function() return sc.ws:GetVisibility() end)) ~= VIS.collapsed then
        try(function() sc.ws:SetVisibility(VIS.collapsed) end)
      end
      if sc.leftAt then settle(sc) end
    end
  end
end

-- the active main menu with our tab, or nil
function T.front()
  for _, sc in pairs(T.screens) do
    if sc.registered and live(sc) and isActive(sc.mm) then return sc end
  end
  return nil
end
function T.ready() return T.front() ~= nil end
function T.isShown() return T.current ~= nil and T.current.shown == true and live(T.current) end

-- select our tab (F5, coming back from a race); false if there's no menu with our tab yet
function T.select()
  local sc = T.front()
  if not sc then return false end
  local ok = try(function() return sc.tl:SelectTabByID(FName(T.ID), false) end)
  log('[tab] select GRAND PRIX: ' .. tostring(ok))
  return ok == true or ok == nil
end
-- back to the game's first tab (EXIT, B on the hub)
function T.selectHome()
  local sc = T.front()
  if not sc then return false end
  local id = try(function() return sc.tl:GetTabIdAtIndex(0) end)
  local ok = id and try(function() return sc.tl:SelectTabByID(id, false) end)
  log('[tab] back to the game tab ' .. tostring(str(id)) .. ': ' .. tostring(ok))
  return ok == true
end

---------------------------------------------------------------------------------------------------------------------
-- focus and Back

-- Does `w` (or something inside it) have keyboard focus? (v0.9.7: no HasUserFocus(pc) / HasUserFocusedDescendants(pc)
-- any more - passing the player controller on every check, many times a second, coincided with every idle crash
-- in UE4SS; keyboard focus is the controller's focus for the one local player.)
function T.hasFocus(w)
  if not alive(w) then return false end
  if try(function() return w:HasKeyboardFocus() end) == true then return true end
  return try(function() return w:HasFocusedDescendants() end) == true
end

-- an invisible screen that handles Back (B / circle): the game deactivates it on B. Put inside `parent` (our page).
-- Returns a handle for T.backPressed, or nil.
local ACTIVATABLE = '/Script/CommonUI.CommonActivatableWidget'
function T.backScreen(sc, parent)
  if not (sc and alive(parent)) then return nil end
  local lib, pc, cls = C.lib('WidgetBlueprintLibrary', 'UMG'), C.localPC(), C.uclass(ACTIVATABLE)
  local h = (alive(lib) and alive(pc) and cls) and try(function() return lib:Create(pc, cls, pc) end)
  if not alive(h) then once('back:create', '[tab] could not make the Back screen (B will not work; Backspace does)'); return nil end
  try(function() h.bSupportsActivationFocus = false end)
  try(function() h.bIsBackHandler = true end)
  try(function() h.bAutoActivate = true end)
  local wt = try(function() return h.WidgetTree end)
  if not alive(wt) then
    wt = try(StaticConstructObject, C.uclass('/Script/UMG.WidgetTree'), h)
    if alive(wt) then try(function() h.WidgetTree = wt end) end
  end
  local inner = alive(wt) and try(StaticConstructObject, C.uclass('/Script/UMG.SizeBox'), wt)
  if alive(inner) then try(function() wt.RootWidget = inner end) end
  local box = T.plain(sc, '/Script/UMG.SizeBox')
  if not alive(box) then return nil end
  try(function() box:SetWidthOverride(1); box:SetHeightOverride(1) end)
  try(function() box:AddChild(h) end)
  try(function() box:SetRenderOpacity(0) end)
  try(function() box:SetVisibility(VIS.hitInvisible) end)
  try(function() parent:AddChild(box) end)
  return { h = h, on = false, logged = 0 }
end

-- true once when B was pressed (the screen was on and the game turned it off); switches it on again
function T.backPressed(b)
  if not (b and alive(b.h)) then return false end
  if isActive(b.h) then b.on = true; return false end
  local pressed = b.on
  b.on = false
  try(function() b.h:ActivateWidget() end)
  if b.logged < 2 then
    b.logged = b.logged + 1
    log('[tab] Back screen ' .. (pressed and 'saw B' or 'switched on') .. ' (active=' .. tostring(isActive(b.h)) .. ')')
  end
  return pressed
end

-- F3 research: what the tab bar and the content area look like on the menu on screen
function T.describe()
  log(('[tab] state: host=%s failed=%s menus=%d shown=%s'):format(tostring(cfg.Host), tostring(T.failed),
    (function() local n = 0; for _ in pairs(T.screens) do n = n + 1 end; return n end)(), tostring(T.isShown())))
  for _, mm in ipairs(C.find('WBP_FE_MainMenu_C')) do
    local tl = try(function() return mm.WBP_Tab_List end)
    local ws = try(function() return mm.WS_ScreenContent end)
    local sc = { tl = tl }
    local ids = alive(tl) and tabIds(sc) or {}
    log(('[tab] menu %s: active=%s inView=%s tabs=[%s] selected=%s'):format(idname(mm), tostring(isActive(mm)),
      tostring(inView(mm)), table.concat(ids, ', '), tostring(alive(tl) and str(try(function() return tl:GetSelectedTabId() end)))))
    local p = alive(ws) and try(function() return ws:GetParent() end)
    if alive(p) then
      local names = {}
      for _, c in ipairs(children(p)) do names[#names + 1] = idname(c) .. ' (' .. clsname(c) .. ')' end
      log(('[tab] content switcher sits in %s (%s): %s'):format(idname(p), clsname(p), table.concat(names, ', ')))
    end
  end
end

return T
