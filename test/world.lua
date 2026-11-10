-- Scenario helpers on top of mock.lua: a main menu, a race, a return to the menu.
local M = require('mock')
local W = { pad = {} }

local function vec(x) return { X = x, Y = 0, Z = 0 } end

function W.widgetLib()
  local lib = StaticFindObject('/Script/UMG.Default__WidgetBlueprintLibrary')
  rawget(lib, '__props').Create = function(self, pc, cls, owner)
    local cname = rawget(cls, '__name') or 'W'
    local w = M.new('widget', {}, cname)
    local p = rawget(w, '__props')
    p.WidgetTree = M.new('WidgetTree', {})
    p.IsInViewport = function() return p.__inViewport == true end
    p.AddToViewport = function() p.__inViewport = true; M.add('UserWidget', w) end
    p.RemoveFromParent = function() p.__inViewport = false; M.kill(w) end
    p.IsHovered = function() return p.__hovered == true end
    p.SzB_SizeOverride = M.new('sz', {})
    p.Img_TileArt = M.new('img', {})
    p.Img_Icon = M.new('img', {})
    -- toggle tiles (v0.8.6+): selected state, and the game UI's focus
    p.GetSelected = function() return p.__sel == true end
    p.SetIsSelected = function(_, v) p.__sel = v end
    p.HasAnyUserFocus = function() return p.__focus == true end
    p.HasUserFocus = function() return p.__focus == true end
    p.HasKeyboardFocus = function() return p.__focus == true end
    if cname == 'UserWidget' then W.tiles = {}
    elseif cname:find('Tile') then
      W.tiles = W.tiles or {}; table.insert(W.tiles, w)
      W.pending = W.pending or {}; table.insert(W.pending, w)
    elseif cname == 'CommonActivatableWidget' then
      -- tab page (v0.9): the Back screen is made right after a page's tiles - those are the page on screen
      p.IsActivated = function() return p.__active == true end
      p.ActivateWidget = function() p.__active = true end
      p.DeactivateWidget = function() p.__active = false end
      W.backs = W.backs or {}; table.insert(W.backs, w)
      W.tiles, W.pending = W.pending or {}, {}
    end
    return w
  end
end

function W.frontEnd()
  M.clear('FrontEndGameMode'); M.clear('RacingGameState'); M.clear('GfnPlayerState')
  W.fe = M.add('FrontEndGameMode', M.new('FrontEndGameMode_' .. M.nextAddr, {
    LaunchQuickRace = function(self, arch, ev, build) table.insert(M.calls, { name = 'LaunchQuickRace', args = { arch, ev, build } }) end,
  }))
  W.mm = M.add('WBP_FE_MainMenu_C', M.new('WBP_FE_MainMenu_C_' .. M.nextAddr, {}, 'WBP_FE_MainMenu_C'))
  local mp = rawget(W.mm, '__props')
  mp.__vis = 4
  mp.IsInViewport = function() return true end
  mp.GetVisibility = function() return mp.__vis end
  mp.SetVisibility = function(_, v) mp.__vis = v end
  mp.IsActivated = function() return mp.__active ~= false end
end

-- a main menu with the game's tab bar and content switcher (v0.9 tab host)
local TAB_IDS = { 'Recommended', 'Campaign', 'Arcade', 'Multiplayer' }
function W.tabMenu()
  local ids, buttons = {}, {}
  for _, id in ipairs(TAB_IDS) do ids[#ids + 1] = id; buttons[id] = M.new('Btn_' .. id, {}, 'WBP_Tab_Btn_C') end
  W.tab = { ids = ids, buttons = buttons, selected = 'Recommended' }
  local tl = M.new('WBP_Tab_List', {
    GetTabCount = function() return #ids end,
    GetTabIdAtIndex = function(_, i) return ids[i + 1] end,
    GetTabButtonBaseByID = function(_, id) return buttons[id] end,
    GetSelectedTabId = function() return W.tab.selected end,
    SelectTabByID = function(_, id) if buttons[id] then W.tab.selected = id; return true end; return false end,
    RegisterTab = function(_, id, cls, stub, at)
      ids[#ids + 1] = id
      local b = M.new('Btn_' .. id, {}, 'WBP_Tab_Btn_C')
      rawget(b, '__props').SetText = function(_, t) W.tab.label = rawget(t, '__props').__text end
      buttons[id] = b
      return true
    end,
  }, 'WBP_Tab_List_C')
  local vb = M.new('VB_Content', {
    GetChildIndex = function() return 0 end,
    InsertChildAt = function(_, i, w) W.tab.page = w; return M.new('slot', {}) end,
  }, 'FuseVerticalBox')
  local ws = M.new('WS_ScreenContent', { GetParent = function() return vb end }, 'FuseWidgetSwitcher')
  local wp = rawget(ws, '__props')
  wp.__vis = 4
  wp.GetVisibility = function() return wp.__vis end
  wp.SetVisibility = function(_, v) wp.__vis = v end
  wp.GetActiveWidget = function() return M.new('WBP_FE_Recommended', {}) end
  local mp = rawget(W.mm, '__props')
  mp.WBP_Tab_List = tl
  mp.WS_ScreenContent = ws
  mp.WidgetTree = M.new('WidgetTree', { RootWidget = M.new('root', {}, 'Overlay') })
  mp.IsActivated = function() return mp.__active ~= false end
  W.tab.tl, W.tab.ws = tl, ws
  W.tabbed = true
end
-- simulate the player picking a tab (LB / RB / mouse)
function W.pickTab(id) W.tab.selected = id end

function W.setup()
  M.install()
  W.widgetLib()
  M.add('GfnGameInstance', M.new('GfnGameInstance', { PrimaryFlow = 0 }))
  W.pc = M.add('PlayerController', M.new('PC', {
    IsLocalPlayerController = function() return true end,
    IsInputKeyDown = function(self, k) return W.pad[k.KeyName] == true end,
  }))
  for i, n in ipairs({ 'VA_Car', 'VA_Plane', 'VA_Bike', 'VA_Skimmer' }) do
    M.add('VehicleArchetype', M.new(n, { archetype = i - 1 }))
  end
  local ksl = StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
  rawget(ksl, '__props').IsStandalone = function() return true end
  W.frontEnd()
end

-- a build asset with a slot map
function W.build(path, levels)
  local n = path:match('([^/]+)$')
  local full = path .. '.' .. n
  local slots = {}
  for i = 1, 4 do slots[i] = CreateInvalidObject() end
  local b = M.new(n, { SlotToUpgradeLevelMap = M.tmap(levels or { [0] = 0, 0, 0, 0, 0, 0 }), AbilitySlots = M.tarr(slots) }, 'VehicleBuildDef')
  W.buildSlots = W.buildSlots or {}
  W.buildSlots[n] = slots
  M.assets[full] = b
  return b
end
-- an event asset
function W.event(path, tag)
  local n = path:match('([^/]+)$')
  local e = M.new(n, { VehicleTypeTag = { TagName = { ToString = function() return tag or 'Vehicle.Standard' end } } }, 'RaceEventDef')
  M.assets[path .. '.' .. n] = e
  return e
end

-- a racer's build copies (one per vehicle type) with 4 ability slots each, starting as `slots`
local function buildCopies(slots)
  local copies = {}
  for i = 1, 4 do
    local list = {}
    for j = 1, 4 do list[j] = slots[j] or CreateInvalidObject() end
    copies[i] = { AbilitySlots = M.tarr(list) }
  end
  return M.tarr(copies)
end
W.buildCopies = buildCopies
W.BOT_NAMES = { 'Biddy Blas', 'Kestar Bool', 'Katja Mox', 'Zed Unknown', 'Sen Fira', 'Lyren Shok', 'Shade', 'Ary Quill',
  'Nik Skandaro', 'Fola Kanjen', 'Goli & 02-R0' }
-- race world with the player + bots. opts.noBuilds: bots have no build copies yet. Every racer starts with YOUR
-- abilities (W.yourAbility), as the game does.
function W.race(nBots, opts)
  opts = opts or {}
  M.kill(W.fe)
  M.kill(W.mm)
  W.yourAbility = W.yourAbility or M.new('BP_Ability_Autopilot_C', {}, 'Class')
  W.gs = M.add('RacingGameState', M.new('RacingGameState', { bIsRaceStarted = true }))
  W.rec = { EventPosition = 6, bHasFinishedEvent = false, CurrentLapNumber = 1 }
  W.player = M.add('GfnPlayerState', M.new('me', { bIsABot = false, RaceEventComponent = M.new('rec', W.rec),
    PlayerNamePrivate = FText('Dwayne'), RacerBuildState = { VehicleBuilds = buildCopies({ W.yourAbility }) },
    PawnPrivate = M.new('pawn', { GetVelocity = function() return vec(10000) end,
      BuildComponent = M.new('bc', { Active_Cornering = 1, Active_Acceleration = 2 }) }) }))
  W.bots = {}
  for i = 1, nBots or 3 do
    W.bots[i] = M.add('GfnPlayerState', M.new('bot' .. i, { bIsABot = true, RaceEventComponent = M.new('rec', { EventPosition = i }),
      PlayerNamePrivate = FText(W.BOT_NAMES[i] or ('Bot ' .. i)),
      RacerBuildState = { VehicleBuilds = opts.noBuilds and M.tarr({}) or buildCopies({ W.yourAbility }) },
      PawnPrivate = M.new('pawn', { GetVelocity = function() return vec(9000) end }) }))
  end
end
-- the slots of a racer's first build copy, as class names ('-' = empty)
function W.slots(ps, copy)
  local st = rawget(ps, '__props').RacerBuildState.VehicleBuilds[copy or 1]
  local out = {}
  for j = 1, st.AbilitySlots:GetArrayNum() do
    local c = st.AbilitySlots[j]
    out[j] = (c and not rawget(c, '__dead')) and rawget(c, '__name') or '-'
  end
  return table.concat(out, ',')
end
function W.finish(pos) W.rec.EventPosition = pos; W.rec.bHasFinishedEvent = true end
function W.backToMenu() M.kill(W.gs); W.frontEnd(); if W.tabbed then W.tabMenu() end end
return W
