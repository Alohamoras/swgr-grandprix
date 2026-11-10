-- Galactic Grand Prix (from the Underground): building screens out of the game's own tile button, plus hiding the game's main menu.
local C = require('core')
local cfg = require('config')
local try, alive, log = C.try, C.alive, C.log

local U = {}

local TILE = '/Game/Griffin/UI/Widgets/Buttons/WBP_FE_TileCommon_Btn.WBP_FE_TileCommon_Btn_C'
local ART = '/Game/Griffin/UI/Library/Textures/Content/MainMenu/'

-- tile layout on the tab page (config.TabLayout)
function U.setLayout()
  local L = cfg.TabLayout or {}
  U.TILE_W = L.TileWidth or 520
  U.TILE_H = L.TileHeight or 350
  U.COLS = L.Columns or 4
  U.ROWS = L.VisibleRows or 3
  U.TEXT = L.TextScale or 1
  U.FOCUS = L.FocusScale or 1.04
  U.DIM = L.DimOthers or 1
end
U.setLayout()

local function texture(name)
  if not name then return nil end
  return C.asset(ART .. name)
end

-- A click on a toggle button (controller A, Enter or mouse - however the game's UI took it) flips its selected
-- state through the game's own code; the menu tick watches for that (main.lua syncGameUI). No hooks needed.
function U.makeToggle(t)
  try(function() t:SetIsSelectable(true) end)
  try(function() t:SetIsToggleable(true) end)
  try(function() t:SetShouldSelectUponReceivingFocus(false) end)
  try(function() t:SetIsInteractableWhenSelected(true) end)
end

local function makeTile(lib, pc, it)
  local cls = C.uclass(TILE)
  local t = cls and try(function() return lib:Create(pc, cls, pc) end)
  if not alive(t) then return nil end
  local art = texture(it.art)
  if art then try(function() t.TileArt = art end) end
  try(function() t.TxtLabel = FText(it.title) end)
  try(function() t.TxtSupplemental = FText('') end)
  try(function() t.ShowSupplementalText = false end)
  try(function() t.TxtDescription = FText(it.desc or '') end)
  try(function() t.ShowDescriptionText = it.desc ~= nil end)
  try(function() t.UseLargeLabel = false end)
  try(function() t['In Width Override'] = U.TILE_W end)
  try(function() t['In Height Override'] = U.TILE_H end)
  try(function() t:PreConstruct(false) end)
  try(function() t.SzB_SizeOverride:SetWidthOverride(U.TILE_W) end)
  try(function() t.SzB_SizeOverride:SetHeightOverride(U.TILE_H) end)
  if art then try(function() t.Img_TileArt:SetBrushFromTexture(art, false) end)
  else try(function() t.Img_TileArt:SetVisibility(1) end) end
  try(function() t.Img_Icon:SetVisibility(1) end)
  try(function() t:SetText(FText(it.title)) end)
  if it.disabled then try(function() t:SetRenderOpacity(0.5) end) end
  U.makeToggle(t)
  return t
end

local function textBlock(make, s, size, color, wrapAt)
  local t = make('/Script/UMG.TextBlock')
  if not alive(t) then return nil end
  try(function() t:SetText(FText(s)) end)
  local c = color or { 1, 1, 1 }
  try(function() t:SetColorAndOpacity({ SpecifiedColor = { R = c[1], G = c[2], B = c[3], A = 1 }, ColorUseRule = 0 }) end)
  if size then try(function() local f = t.Font; f.Size = math.floor(size * (U.TEXT or 1) + 0.5); t:SetFont(f) end) end
  if wrapAt then
    try(function() t:SetAutoWrapText(true) end)
    try(function() t.WrapTextAt = wrapAt end)
  end
  return t
end

-- a screen: { title, lines = { {text, size, color} ... }, items = { {title, desc, art, disabled} ... }, hint }
-- returns { w, items (each with .btn), scroll } or nil

local GOLD, GREY, WHITE = { 1, 0.82, 0.35 }, { 0.72, 0.74, 0.78 }, { 1, 1, 1 }
U.GOLD, U.GREY, U.WHITE = GOLD, GREY, WHITE

-- host: { tree = the main menu's widget tree, panel = our page panel } - the screen is built into the tab's page
function U.build(spec, host)
  local pc, lib = C.localPC(), C.lib('WidgetBlueprintLibrary', 'UMG')
  if not (alive(pc) and alive(lib)) then log('[menu] no player controller yet'); return nil end
  local tree = host and host.tree
  if not alive(tree) then log('[menu] no widget tree'); return nil end
  local function make(path) return try(function() return StaticConstructObject(StaticFindObject(path), tree) end) end

  local border, box = make('/Script/UMG.Border'), make('/Script/UMG.VerticalBox')
  local sizer, scroll, grid = make('/Script/UMG.SizeBox'), make('/Script/UMG.ScrollBox'), make('/Script/UMG.UniformGridPanel')
  if not (alive(border) and alive(box) and alive(grid)) then log('[menu] could not build panels'); return nil end
  -- the page panel (on the game's own menu background)
  try(function() border:SetBrushColor({ R = 0.01, G = 0.012, B = 0.016, A = 0.6 }) end)
  try(function() border:SetPadding({ Left = 36, Top = 24, Right = 36, Bottom = 24 }) end)
  local content = box
  if spec.side then
    local hb = make('/Script/UMG.HorizontalBox')
    local ok, sw = pcall(spec.side, lib, pc)
    if alive(hb) and ok and alive(sw) then
      try(function() hb:AddChildToHorizontalBox(box) end)
      local sl = try(function() return hb:AddChildToHorizontalBox(sw) end)
      -- (starts below the game's Party box at the top right)
      if sl then try(function() sl:SetPadding({ Left = 30, Top = 70, Right = 0, Bottom = 0 }) end) end
      content = hb
    elseif not ok then log('[menu] side panel error: ' .. tostring(sw)) end
  end
  if content == box then
    -- no side panel: still inside a horizontal box, which gives the tile grid only the width it asks
    -- for (straight in the border it's stretched across the whole page and the tiles spread apart)
    local hb = make('/Script/UMG.HorizontalBox')
    if alive(hb) then try(function() hb:AddChildToHorizontalBox(box) end); content = hb end
  end
  try(function() border:SetContent(content) end)

  local wrap = (U.TILE_W + 20) * U.COLS
  local t1 = textBlock(make, spec.title or '', 34, WHITE)
  if t1 then try(function() box:AddChildToVerticalBox(t1) end) end
  for _, ln in ipairs(spec.lines or {}) do
    if ln[1] and ln[1] ~= '' then
      local t = textBlock(make, ln[1], ln[2] or 18, ln[3] or GREY, wrap)
      local sl = t and try(function() return box:AddChildToVerticalBox(t) end)
      if sl then try(function() sl:SetPadding({ Left = 0, Top = 4, Right = 0, Bottom = 0 }) end) end
    end
  end

  try(function() grid:SetSlotPadding({ Left = 10, Top = 10, Right = 10, Bottom = 10 }) end)
  local holder = grid
  if alive(scroll) and alive(sizer) then
    try(function() scroll:AddChild(grid) end)
    try(function() sizer:SetContent(scroll) end)
    local rows = math.ceil(#(spec.items or {}) / U.COLS)
    local h = math.min(rows, U.ROWS) * (U.TILE_H + 20) + 10
    try(function() sizer:SetHeightOverride(h) end)
    try(function() sizer:SetWidthOverride(wrap + 10) end)
    holder = sizer
  end
  local gs = try(function() return box:AddChildToVerticalBox(holder) end)
  if gs then try(function() gs:SetPadding({ Left = 0, Top = 14, Right = 0, Bottom = 8 }) end) end
  -- left, at its own width: a filling slot stretches the grid past the size box and spreads the tiles apart
  if gs then try(function() gs:SetHorizontalAlignment(0) end) end

  local list = {}
  for _, it in ipairs(spec.items or {}) do
    local t = makeTile(lib, pc, it)
    if t then
      local n = #list
      -- each tile in a box of the tile size (the tile asks for more width than its art, which spreads the grid
      -- apart); the tile itself still takes focus and clicks
      local cell = t
      local box1 = make('/Script/UMG.SizeBox')
      if alive(box1) then
        try(function() box1:SetWidthOverride(U.TILE_W); box1:SetHeightOverride(U.TILE_H) end)
        try(function() box1:SetContent(t) end)
        cell = box1
      end
      try(function() grid:AddChildToUniformGrid(cell, n // U.COLS, n % U.COLS) end)
      it.btn = t
      list[#list + 1] = it
    end
  end
  if spec.hint then
    local th = textBlock(make, spec.hint, 15, GREY, wrap)
    if th then try(function() box:AddChildToVerticalBox(th) end) end
  end
  if #list == 0 then log('[menu] no tiles'); return nil end

  local screen = { w = border, host = host, items = list, scroll = alive(scroll) and scroll or nil, pc = pc, grid = grid }
  try(function() host.panel:ClearChildren() end)
  local sl = try(function() return host.panel:AddChildToVerticalBox(border) end)
  if not alive(sl) then sl = try(function() return host.panel:AddChild(border) end) end
  if sl then try(function() sl:SetHorizontalAlignment(0); sl:SetVerticalAlignment(0) end) end
  U.wire(screen)
  return screen
end

-- D-pad links between the tiles from their grid positions (the game's own navigation then moves focus). Edges are
-- left to the game (up from the top row reaches the tab bar). EUINavigation: Left 0, Right 1, Up 2, Down 3.
function U.wire(screen)
  local items, cols = screen.items, U.COLS
  local n = #items
  for i, it in ipairs(items) do
    local r, c = (i - 1) // cols, (i - 1) % cols
    local function at(rr, cc)
      if rr < 0 or cc < 0 or cc >= cols then return nil end
      local j = rr * cols + cc + 1
      return j <= n and items[j] or nil
    end
    local left, right, up = at(r, c - 1), at(r, c + 1), at(r - 1, c)
    local down = at(r + 1, c)
    if not down and r + 1 <= (n - 1) // cols then down = items[n] end   -- short last row: its last tile
    if left then try(function() it.btn:SetNavigationRuleExplicit(0, left.btn) end) end
    if right then try(function() it.btn:SetNavigationRuleExplicit(1, right.btn) end) end
    if up then try(function() it.btn:SetNavigationRuleExplicit(2, up.btn) end) end
    if down then try(function() it.btn:SetNavigationRuleExplicit(3, down.btn) end) end
  end
end

-- highlight the focused tile and keep it in view
-- give a tile the game UI's focus (pad / keyboard): every route UMG has, since the game's UI system can hand focus
-- elsewhere right after we open
function U.grabFocus(btn, pc)
  if alive(pc) then try(function() btn:SetUserFocus(pc) end) end
  try(function() btn:SetKeyboardFocus() end)
  try(function() btn:SetFocus() end)
end

-- the focused tile: a little bigger, the others a little dimmer (look only: render scale / opacity never touch focus)
function U.highlight(screen, i)
  for j, it in ipairs(screen.items) do
    local on = j == i
    local sc = on and U.FOCUS or 1.0
    try(function() it.btn:SetRenderScale({ X = sc, Y = sc }) end)
    local op = (it.disabled and 0.5 or 1) * ((on or U.DIM == 1) and 1 or U.DIM)
    try(function() it.btn:SetRenderOpacity(op) end)
  end
end

function U.focus(screen, i)
  U.highlight(screen, i)
  local it = screen.items[i]
  if not it then return end
  U.grabFocus(it.btn, screen.pc)
  if screen.scroll then try(function() screen.scroll:ScrollWidgetIntoView(it.btn, true, 0, 0) end) end
end

return U
