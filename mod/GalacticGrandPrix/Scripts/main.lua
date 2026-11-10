-- Galactic Grand Prix: kart-racer-style cups for STAR WARS Galactic Racer (DESIGN.md).
-- The GRAND PRIX tab on the game's main menu (or F6) -> speed class -> cup -> race. Races launch straight away through
-- the game's offline quick race (FrontEndGameMode:LaunchQuickRace) with every part at the class's level.
-- v0.1: one race at a time; the cup flow (4 races, points, trophies) comes in v0.2.
-- Design: DESIGN.md  Plan: TASKS.md  Save: save.lua  Log: grandprix.log

local VERSION = '0.1.0'

local here = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
local scripts = here:match('^(.*)[/\\][^/\\]+$') or '.'
package.path = scripts .. '/?.lua;' .. package.path
for _, m in ipairs({ 'core', 'config', 'gp', 'race', 'ui', 'tab' }) do package.loaded[m] = nil end

local C = require('core')
C.DIR = scripts:match('^(.*)[/\\][Ss]cripts$') or '.'
local cfg = require('config')
for k, v in pairs(rawget(_G, 'GU_TEST_CFG') or {}) do cfg[k] = v end -- test harness only (test/util.lua)
local K = require('gp')
local R = require('race')
local U = require('ui')
local TB = require('tab')
local try, alive, log, ordinal = C.try, C.alive, C.log, C.ordinal

K.load()

local function tabMode() return not TB.failed end
U.setLayout('tab')

---------------------------------------------------------------------------------------------------------------------
-- screen state

local S = {
  ui = nil,          -- the built screen { w, items, scroll, pc }
  screen = nil,      -- 'classes' | 'cups' | 'cup' | 'result' | 'offline'
  class = nil,       -- class key
  cup = nil,         -- cup key
  focus = 1,
  focusMem = {},     -- screen key -> focused tile
  shownAt = 0,
  message = nil,     -- one-line message on the next screen
  result = nil,      -- last race result for the result screen
  openAt = nil,      -- clock time to open the result screen after a race
}

local function msgLine() return { S.message or '', 20, U.GOLD } end
local HINT = 'Enter / A : select        Backspace / B : back        Q / E  or  LB / RB : other tabs'

local show -- forward
local startLoop -- forward

---------------------------------------------------------------------------------------------------------------------
-- screens: each returns a spec for ui.build; tile `act` functions change state and return true to redraw

local function go(screen) S.screen = screen; S.message = nil; return true end

local function launch(ev)
  local ok, why = R.launch(ev, S.class, K.data.vehicle)
  if ok then S.message = nil; return 'launched' end
  S.message = why
  return true
end

local SCREENS = {}

SCREENS.classes = function()
  local items = {}
  for _, c in ipairs(K.classes()) do
    items[#items + 1] = { title = c.name:upper(), art = 'T_UI_FE_Tile_Campaign_Hero',
      desc = ('%s\nEvery part at level %d'):format(c.blurb or '', c.parts),
      act = function() S.class = c.key; K.data.class = c.key; K.save(); return go('cups') end }
  end
  items[#items + 1] = { title = 'EXIT', art = 'T_UI_FE_Tile_03', desc = 'Back to the main menu', act = function() return 'close' end }
  return { key = 'classes', title = 'GALACTIC GRAND PRIX',
    lines = { { 'Pick a speed class', 24, U.WHITE }, { ('Races so far: %d'):format(K.data.races), 18 }, msgLine() },
    items = items, hint = HINT }
end

SCREENS.cups = function()
  local cls = K.class(S.class) or K.classes()[1]
  local items = {}
  for _, cup in ipairs(K.cups()) do
    local names = {}
    for _, r in ipairs(cup.races) do names[#names + 1] = r.title end
    items[#items + 1] = { title = cup.name, art = cup.art or 'T_UI_FE_Tile_01',
      desc = ('%d races\n%s'):format(#cup.races, table.concat(names, ', ', 1, math.min(2, #names)) .. (#names > 2 and ' ...' or '')),
      act = function() S.cup = cup.key; return go('cup') end }
  end
  items[#items + 1] = { title = 'BACK', art = 'T_UI_FE_Tile_03', desc = 'Pick another class', act = function() return go('classes') end }
  return { key = 'cups', title = cls.name:upper() .. '  -  CUPS',
    lines = { { 'Pick a cup', 24, U.WHITE }, { ('%s: every part of your vehicle at level %d'):format(cls.name, cls.parts), 18 }, msgLine() },
    items = items, hint = HINT }
end

SCREENS.cup = function()
  local cls = K.class(S.class) or K.classes()[1]
  local cup = K.cup(S.cup) or K.cups()[1]
  local veh = K.vehicle(K.data.vehicle)
  local items = {
    { title = 'START', art = 'T_UI_FE_Tile_Campaign_Hero', desc = ('Race 1: %s\n(v0.1: one race at a time)'):format(cup.races[1].title),
      act = function() return launch({ path = cup.races[1].path, title = cup.races[1].title, kind = cup.races[1].kind, cup = cup.key, race = 1 }) end },
  }
  for i, r in ipairs(cup.races) do
    items[#items + 1] = { title = ('%d. %s'):format(i, r.title), art = cup.art or 'T_UI_FE_Tile_01', desc = r.kind,
      act = function() return launch({ path = r.path, title = r.title, kind = r.kind, cup = cup.key, race = i }) end }
  end
  items[#items + 1] = { title = 'VEHICLE', art = 'T_UI_FE_Tile_05', desc = veh.name .. '\nSelect to change',
    act = function()
      local list, nxt = K.vehicles(), 1
      for i, v in ipairs(list) do if v.key == veh.key then nxt = i % #list + 1 end end
      K.data.vehicle = list[nxt].key; K.save()
      S.message = list[nxt].name .. ' selected'
      return true
    end }
  items[#items + 1] = { title = 'BACK', art = 'T_UI_FE_Tile_03', desc = 'All cups', act = function() return go('cups') end }
  return { key = 'cup', title = cup.name .. '  -  ' .. cls.name:upper(),
    lines = { { ('%s   -   %s, every part at level %d'):format(veh.name, cls.name, cls.parts), 22, U.WHITE }, msgLine() },
    items = items, hint = HINT }
end

-- shown in the tab when the multiplayer guard refuses (instead of an empty page)
SCREENS.offline = function()
  return {
    key = 'offline', title = 'GRAND PRIX',
    lines = { { 'The Grand Prix is offline only.', 26, U.WHITE }, { S.blocked or '', 20, U.GOLD },
      { 'Leave the party / stop matchmaking, then come back to this tab.', 18 } },
    items = { { title = 'EXIT', art = 'T_UI_FE_Tile_03', desc = 'Back to the main menu', act = function() return 'close' end } },
  }
end

SCREENS.result = function()
  local r = S.result or {}
  local ev = r.ev or { title = '?' }
  local lines = {}
  if r.pos then
    lines[#lines + 1] = { ('%s PLACE'):format(ordinal(r.pos):upper()), 44, U.GOLD }
  else
    lines[#lines + 1] = { 'DID NOT FINISH', 44, U.GREY }
  end
  lines[#lines + 1] = { ('%s   -   %s'):format(ev.title, ev.kind or 'Race'), 22, U.WHITE }
  lines[#lines + 1] = { 'Points and the cup standings come in v0.2', 18 }
  local items = {
    { title = 'CONTINUE', art = 'T_UI_FE_Tile_Campaign_Hero', desc = 'Back to the cup', act = function() return go('cup') end },
  }
  if r.ev then
    items[#items + 1] = { title = 'RACE AGAIN', art = 'T_UI_FE_Tile_02', desc = ev.title, act = function()
      local res = launch(r.ev)
      if res ~= 'launched' then S.screen = 'cup' end
      return res
    end }
  end
  return { key = 'result', title = 'RACE RESULT', lines = lines, items = items, hint = 'Enter / A : select' }
end

---------------------------------------------------------------------------------------------------------------------
-- showing / closing

-- the hidden Back screen of a tab page: switched off before the page goes (it's an activatable widget)
local function dropBack()
  local b = S.ui and S.ui.back
  if b and alive(b.h) then try(function() b.h:DeactivateWidget() end) end
end

local function close(why)
  dropBack()
  S.ui = nil
  log('[menu] closed (' .. (why or '?') .. ')')
  -- leaving the page = going back to the game's first tab (unless the tab was already left)
  if why ~= 'tab left' and TB.isShown() then TB.selectHome() end
end

local function setFocus(i)
  if not S.ui or #S.ui.items == 0 then return end
  S.focus = (i - 1) % #S.ui.items + 1
  S.focusMem[S.key or ''] = S.focus
  U.focus(S.ui, S.focus)
end

show = function()
  local fe, why = R.atMainMenu()
  local blocked = nil
  if not fe then
    log('[menu] ' .. why)
    -- in our tab, say why rather than leave the page empty (nothing else is built or launched)
    if not (TB.isShown() and why ~= 'not at the main menu') then return end
    blocked = why
  end
  if not tabMode() then log('[menu] the GRAND PRIX tab could not be added to the main menu - see the [tab] lines above'); return end
  if not TB.isShown() then
    -- the page is built when our tab is selected (TB.onEnter); ask for it
    S.pendingScreen = S.screen
    if not TB.select() then log('[menu] the GRAND PRIX tab is not ready yet') end
    return
  end
  dropBack()
  S.ui = nil
  S.screen = S.screen or 'classes'
  S.blocked = blocked
  local ok, spec = pcall(SCREENS[blocked and 'offline' or S.screen])
  if not ok then log('[menu] screen error: ' .. tostring(spec)); S.screen = 'classes'; spec = SCREENS.classes() end
  local sc = TB.current
  if not sc then return end
  local ui = U.build(spec, { tree = sc.tree, panel = sc.panel })
  if not ui then return end
  S.ui, S.key, S.shownAt = ui, spec.key, C.clock
  S.grabs = 0
  -- B on any page: the game turns this invisible screen off, which reads as BACK (tab.lua)
  ui.back = TB.backScreen(sc, sc.panel)
  setFocus(math.min(S.focusMem[spec.key] or 1, #ui.items))
  log(('[menu] %s (%d tiles)'):format(spec.key, #ui.items))
  startLoop()
end

local lastPress = -1e9
local function press(i, how)
  local it = S.ui and S.ui.items[i]
  if not it or not it.act then return end
  -- one press can arrive twice (our key/mouse handling and the game's own button click): act once
  if C.clock - lastPress < 400 then return end
  lastPress = C.clock
  if how then log('[menu] press ' .. i .. ' (' .. how .. ')') end
  local ok, res = pcall(it.act)
  if not ok then log('[menu] tile error: ' .. tostring(res)); return end
  if res == 'close' then S.message = nil; close('exit')
  elseif res == 'launched' then
    dropBack()
    S.ui = nil
    log('[menu] closed (race launched)')
  elseif res then show() end
end

---------------------------------------------------------------------------------------------------------------------
-- input

local BACK = { cups = 'classes', cup = 'cups', result = 'cup' }
local function handle(name)
  if name == 'menu' then
    if S.ui then close('menu key') else S.message = nil; S.screen = 'classes'; show() end
    return
  end
  if not S.ui or C.clock - S.shownAt < 350 then return end
  local ti = name:match('^tile:(%d+)$')
  if ti then press(tonumber(ti), 'game click'); return end
  local fi = name:match('^focus:(%d+)$')
  if fi then
    S.focus = tonumber(fi); S.focusMem[S.key or ''] = S.focus
    U.highlight(S.ui, S.focus)
    return
  end
  local cols = U.COLS
  if name == 'left' then setFocus(S.focus - 1)
  elseif name == 'right' then setFocus(S.focus + 1)
  elseif name == 'up' then setFocus(math.max(1, S.focus - cols))
  elseif name == 'down' then setFocus(math.min(#S.ui.items, S.focus + cols))
  elseif name == 'accept' then press(S.focus)
  elseif name == 'back' then
    if BACK[S.screen] then go(BACK[S.screen]); show() else close('back') end
  elseif name == 'click' then
    for i, it in ipairs(S.ui.items) do
      if try(function() return it.btn:IsHovered() end) == true then press(i); return end
    end
  end
end

-- the game's own UI driving our tiles (controller D-pad / A when CommonUI keeps the pad from the poll): follow the
-- tile it has focused, and act on a tile whose selected state flipped (they're toggle buttons, see U.makeToggle)
local loggedSync = false
local function syncGameUI()
  if not S.ui or C.clock - S.shownAt < 350 then return end
  for i, it in ipairs(S.ui.items) do
    if try(function() return it.btn:GetSelected() end) == true then
      try(function() it.btn:SetIsSelected(false, false) end)
      press(i, 'game click')
      return
    end
  end
  -- which tile has the game UI's focus: the one we think first (every tick), the rest every 3rd tick only - each
  -- check is an engine call, and fewer calls are kinder to UE4SS (v0.9.7)
  local function has(it) return TB.hasFocus(it.btn) end
  local focused
  local cur = S.ui.items[S.focus]
  if cur and has(cur) then focused = S.focus
  else
    S.scan = (S.scan or 0) + 1
    if S.scan % 3 ~= 0 and C.clock - S.shownAt >= 1500 then return end
    for i, it in ipairs(S.ui.items) do
      if i ~= S.focus and has(it) then focused = i; break end
    end
  end
  -- the menu may take focus once right after a redraw - give it back to our tile for 1.5 s, then leave the game alone
  -- (up from the top row may legitimately go to the tab bar)
  if not focused and C.clock - S.shownAt < 1500 and C.clock - (S.lastGrab or -1e9) >= 300 then
    S.lastGrab = C.clock
    local it = S.ui.items[S.focus]
    if it then try(function() it.btn:SetFocus() end) end
    S.grabs = (S.grabs or 0) + 1
    if S.grabs <= 2 then log('[menu] tab page: focus to tile ' .. S.focus .. ' (' .. S.grabs .. ')') end
  end
  if focused and focused ~= S.focus then
    if not loggedSync then loggedSync = true; log('[menu] the game\'s UI is moving focus on our tiles') end
    S.focus = focused; S.focusMem[S.key or ''] = focused
    U.highlight(S.ui, focused)
  end
end

---------------------------------------------------------------------------------------------------------------------
-- the tick: runs only while there's something to do

local TICK_MS = 100
local keys = {}
local function busy() return #keys > 0 or S.ui ~= nil or R.run ~= nil or S.openAt ~= nil or R.pendingRestore() end

local function tick()
  C.clock = C.clock + TICK_MS
  if R.pendingRestore() and not R.run and alive(C.first('FrontEndGameMode')) then R.restoreBuild('left over from an earlier race') end
  while #keys > 0 do
    local k = table.remove(keys, 1)
    local ok, err = pcall(handle, k)
    if not ok then log('key error: ' .. tostring(err)) end
  end
  -- tab page: its widgets live in the main menu's tree; check the menu is still there before touching any of them
  if S.ui and not TB.isShown() then S.ui = nil end
  if S.ui then
    if not alive(S.ui.w) or not alive(C.first('FrontEndGameMode')) then S.ui = nil
    else
      local ok, err = pcall(syncGameUI)
      if not ok then log('[menu] sync error: ' .. tostring(err)) end
      -- B through the hidden Back screen; LT / RT read here; the game does the D-pad and A itself
      if S.ui and S.ui.back and TB.backPressed(S.ui.back) then pcall(handle, 'back') end
    end
  end
  local ok, out = pcall(R.watch)
  if not ok then log('watch error: ' .. tostring(out))
  elseif out and out.failed then
    -- the launch went nowhere: ours back with a message
    S.message = out.failed == 'timeout' and 'The race never loaded - nothing was recorded.' or nil
    if out.failed == 'timeout' and alive(C.first('FrontEndGameMode')) then S.screen = 'cup'; show() end
  elseif out then S.result, S.openAt = out, C.clock end
  if S.openAt and C.clock >= S.openAt and not R.run then
    -- the menu is rebuilt after a race: wait for our tab on it, then open the result in the tab
    if TB.ready() then S.openAt = nil; S.screen = 'result'; S.message = nil; show() end
    if S.openAt and C.clock - S.openAt > 30000 then S.openAt = nil; log('the GRAND PRIX tab never came back - not opening the result') end
  end
end

-- one permanent game-thread loop (v0.10; it used to start and stop itself - see C.gameLoop)
local looping = false
startLoop = function()
  if looping then return end
  looping = true
  C.gameLoop(TICK_MS, function() if busy() then tick() end end, 'tick')
end
local function queue(action) keys[#keys + 1] = action end -- (key thread: only queue; the game-thread loop handles it)

-- Keys: the game's own UI does arrows / Enter / mouse on our page and Q / E switch its tabs, so only these are ours.
local function bind(keyName, action)
  local k = Key and Key[keyName]
  if not k then log('unknown key ' .. tostring(keyName)); return end
  local ok, err = pcall(RegisterKeyBind, k, function()
    if action ~= 'menu' and action ~= 'probe' and not S.ui then return end
    queue(action)
  end)
  if not ok then log('bind failed ' .. keyName .. ': ' .. tostring(err)) end
end
bind(cfg.MenuKey or 'F6', 'menu')
-- (no hooks: the Underground's v0.7.2-0.8.5 hooked the game's button events; none fired for the pad)
bind('BACKSPACE', 'back')

---------------------------------------------------------------------------------------------------------------------
-- the GRAND PRIX tab: our page is built when the tab is picked, and dropped when another tab is
TB.onEnter = function()
  S.screen = S.pendingScreen or (S.screen == 'result' and 'cup') or S.screen or 'classes'
  S.pendingScreen = nil
  show()
end
TB.onLeave = function() if S.ui then close('tab left') end end
-- the menu holding our page was freed: drop the page without touching its widgets (they went with it)
TB.onGone = function() S.ui = nil; log('[menu] closed (menu gone)') end
TB.onFail = function() S.ui = nil end

-- main menu poll (front end only, 200 ms): finds the menu and keeps our tab on it
do
  local seenMenu, ticks = false, 0
  local POLL_MS = 200
  C.gameLoop(POLL_MS, function()
    if R.run then return end
    local fe = C.cached('FrontEndGameMode', 2)
    if not alive(fe) then return end
    if not seenMenu then seenMenu = true end
    ticks = ticks + 1
    if tabMode() then
      if ticks % 5 == 1 then
        local ok, err = pcall(TB.discover)
        if not ok then log('[tab] discover error: ' .. tostring(err)) end
      end
      local ok, err = pcall(TB.update, POLL_MS)
      if not ok then log('[tab] update error: ' .. tostring(err)) end
    end
  end, 'poll')
end

startLoop()

log(('v%s loaded - the GRAND PRIX tab on the main menu (or %s) opens it'):format(VERSION, cfg.MenuKey or 'F6'))
