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

-- a texture by name (the main-menu set) or full path (v0.7 art.lua). Each lookup is a sweep of every object
-- (AUTOMATION.md), so one screen build looks each picture up once (memo cleared at every build; nothing kept
-- between ticks).
local memo = {}
local function texture(name)
  if not name then return nil end
  local path = name:sub(1, 1) == '/' and name or (ART .. name)
  local t = memo[path]
  if t == nil then t = C.asset(path) or false; memo[path] = t end
  return t or nil
end
U.texture = texture

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
  -- the tile's small extra line (v0.3.11): the trophy badge on cup and class tiles, 'RACE 4 / 4' on NEXT RACE
  try(function() t.TxtSupplemental = FText(it.badge or '') end)
  try(function() t.ShowSupplementalText = it.badge ~= nil end)
  try(function() t.TxtDescription = FText(it.desc or '') end)
  try(function() t.ShowDescriptionText = it.desc ~= nil end)
  try(function() t.UseLargeLabel = false end)
  try(function() t['In Width Override'] = U.TILE_W end)
  try(function() t['In Height Override'] = U.TILE_H end)
  try(function() t:PreConstruct(false) end)
  try(function() t.SzB_SizeOverride:SetWidthOverride(U.TILE_W) end)
  try(function() t.SzB_SizeOverride:SetHeightOverride(U.TILE_H) end)
  if art then
    -- v0.7 (seen in game 2026-11-10): the tile draws its art through the game's material, which zooms by
    -- ImageScale around ImageX/YOffset; the share of the texture shown is tile size / (texture size x scale). The
    -- game's 0.44 suits its own tiles only: scale each texture to just cover the tile (no repeats). Tall posters
    -- (vehicle art in the top half) are moved up. Setting the brush straight to the texture skips the material
    -- (drawn at full size, cropped) - not done.
    local sx = try(function() return art:Blueprint_GetSizeX() end)
    local sy = try(function() return art:Blueprint_GetSizeY() end)
    if type(sx) == "number" and type(sy) == "number" and sx > 0 and sy > 0 then
      local sc = math.max(U.TILE_W / sx, U.TILE_H / sy)
      try(function() t.ImageScale = sc end)
      if sy * sc > U.TILE_H * 1.2 then try(function() t.ImageYOffset = 0.3 end) end
      try(function() t:PreConstruct(false) end)
    end
  else try(function() t.Img_TileArt:SetVisibility(1) end) end
  -- v0.7: a picture in the tile's icon slot (the trophy medal), else the slot stays hidden
  local icon = texture(it.icon)
  if icon then
    try(function() t.Img_Icon:SetBrushFromTexture(icon, false) end)
    try(function() t.Img_Icon:SetVisibility(4) end) -- SelfHitTestInvisible
    -- the tile draws its icon as a shape in one colour (seen in game): white, or the item's colour (medals)
    local c = it.iconColor or { 1, 1, 1 }
    try(function() t.Img_Icon:SetColorAndOpacity({ R = c[1], G = c[2], B = c[3], A = 1 }) end)
    try(function() t.Img_Icon:SetBrushTintColor({ SpecifiedColor = { R = 1, G = 1, B = 1, A = 1 }, ColorUseRule = 0 }) end)
    -- to the top right corner, off the title (the slot sits over it)
    try(function() t.Img_Icon:SetRenderTranslation({ X = 85, Y = -38 }) end)
  else try(function() t.Img_Icon:SetVisibility(1) end) end
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

-- a screen: { title, lines = { {text, size, color} ... }, table = (see below), items = { {title, desc, art, badge, disabled} ... },
-- hint }
-- table (v0.3.8, the ranking): { size = text size, cols = { { w = width, align = 'left'|'right'|'center' } ... },
--   header = { cell text ... }, rows = { { cells = { text ... }, color = {r,g,b} (default white), colors = { [col] =
--   {r,g,b} }, highlight = true } ... } } - one horizontal box per row, each cell in a box of its column's width, so
--   the columns line up whatever the font.
-- returns { w, items (each with .btn), scroll } or nil

local GOLD, GREY, WHITE = { 1, 0.82, 0.35 }, { 0.72, 0.74, 0.78 }, { 1, 1, 1 }
U.GOLD, U.GREY, U.WHITE = GOLD, GREY, WHITE

-- host: { tree = the main menu's widget tree, panel = our page panel } - the screen is built into the tab's page
local function buildInner(spec, host)
  local pc, lib = C.localPC(), C.lib('WidgetBlueprintLibrary', 'UMG')
  if not (alive(pc) and alive(lib)) then log('[menu] no player controller yet'); return nil end
  local tree = host and host.tree
  if not alive(tree) then log('[menu] no widget tree'); return nil end
  local function make(path) return try(function() return StaticConstructObject(StaticFindObject(path), tree) end) end
  memo = {}

  local border, box = make('/Script/UMG.Border'), make('/Script/UMG.VerticalBox')
  local sizer, scroll, grid = make('/Script/UMG.SizeBox'), make('/Script/UMG.ScrollBox'), make('/Script/UMG.UniformGridPanel')
  if not (alive(border) and alive(box) and alive(grid)) then log('[menu] could not build panels'); return nil end
  -- the page panel (on the game's own menu background)
  try(function() border:SetBrushColor({ R = 0.01, G = 0.012, B = 0.016, A = 0.6 }) end)
  -- v0.7: a picture behind the page (spec.backdrop), darkened so the text stays readable
  local bd = texture(spec.backdrop)
  if bd then
    try(function() border:SetBrushFromTexture(bd) end)
    try(function() border:SetBrushColor({ R = 0.45, G = 0.45, B = 0.45, A = 0.92 }) end)
  end
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

  -- v0.6: an info line (spec.info = true): the full text of the focused tile (its item.info), set on every focus change
  -- (tile descriptions are cut after two lines; for mods the description is the point)
  local info
  if spec.info then
    info = textBlock(make, ' ', 20, GOLD, wrap)
    local sl = info and try(function() return box:AddChildToVerticalBox(info) end)
    if sl then try(function() sl:SetPadding({ Left = 0, Top = 6, Right = 0, Bottom = 0 }) end) end
  end

  if spec.table then
    local tb = spec.table
    local JUST = { left = 0, center = 1, right = 2 }
    local function row(cells, color, colors, highlight, size)
      local hb = make('/Script/UMG.HorizontalBox')
      if not alive(hb) then return end
      for i, col in ipairs(tb.cols) do
        local sb = make('/Script/UMG.SizeBox')
        local t = textBlock(make, tostring(cells[i] or ''), size, (colors and colors[i]) or color or WHITE)
        if t then try(function() t:SetJustification(JUST[col.align or 'left'] or 0) end) end
        if alive(sb) and t then
          try(function() sb:SetWidthOverride(col.w) end)
          try(function() sb:SetContent(t) end)
          local sl = try(function() return hb:AddChildToHorizontalBox(sb) end)
          if sl then try(function() sl:SetPadding({ Left = 0, Top = 0, Right = 24, Bottom = 0 }) end) end
        end
      end
      local holder = hb
      if highlight then
        local b = make('/Script/UMG.Border')
        if alive(b) then
          try(function() b:SetBrushColor({ R = 1, G = 0.82, B = 0.35, A = 0.16 }) end)
          try(function() b:SetPadding({ Left = 6, Top = 2, Right = 6, Bottom = 2 }) end)
          try(function() b:SetContent(hb) end)
          holder = b
        end
      end
      local sl = try(function() return box:AddChildToVerticalBox(holder) end)
      if sl then try(function() sl:SetPadding({ Left = highlight and 0 or 6, Top = 2, Right = 0, Bottom = 0 }) end) end
    end
    if tb.header then row(tb.header, GREY, nil, false, (tb.size or 20) - 2) end
    for _, r in ipairs(tb.rows or {}) do row(r.cells, r.color, r.colors, r.highlight, tb.size or 20) end
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
  -- a short screen (fewer tiles than a row): empty cells fill the row, else the uniform grid shares its width out
  -- over the tiles in use and two tiles sit two columns apart (seen in game, v0.3.11 / v0.5.0)
  for col = #list, U.COLS - 1 do
    local pad = make('/Script/UMG.SizeBox')
    if alive(pad) then
      try(function() pad:SetWidthOverride(U.TILE_W); pad:SetHeightOverride(U.TILE_H) end)
      try(function() grid:AddChildToUniformGrid(pad, 0, col) end)
    end
  end
  if spec.hint then
    local th = textBlock(make, spec.hint, 15, GREY, wrap)
    if th then try(function() box:AddChildToVerticalBox(th) end) end
  end
  if #list == 0 then log('[menu] no tiles'); return nil end

  local screen = { w = border, host = host, items = list, scroll = alive(scroll) and scroll or nil, pc = pc, grid = grid,
    info = info, cols = U.COLS }
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
  local it = screen.items[i]
  if screen.info and alive(screen.info) then try(function() screen.info:SetText(FText(it and it.info or ' ')) end) end
end

function U.focus(screen, i)
  U.highlight(screen, i)
  local it = screen.items[i]
  if not it then return end
  U.grabFocus(it.btn, screen.pc)
  if screen.scroll then try(function() screen.scroll:ScrollWidgetIntoView(it.btn, true, 0, 0) end) end
end

-- A cover over the main menu while it's rebuilt after a race (v0.3.8, owner: nothing between the race results and
-- the ranking): the game's own loading screen in the viewport, on top of everything, until our page is up. Kept as
-- path + address (C.ref), never as the object.
local COVER = '/Game/Griffin/UI/Screens/WBP_LoadingScreen.WBP_LoadingScreen_C'
local coverRef, coverAt
function U.cover(on)
  if on then
    if C.deref(coverRef) then return true end
    local pc, lib = C.localPC(), C.lib('WidgetBlueprintLibrary', 'UMG')
    local cls = C.uclass(COVER)
    local w = (alive(pc) and alive(lib) and cls) and try(function() return lib:Create(pc, cls, pc) end)
    if not alive(w) then log('[cover] could not make the loading screen'); return false end
    try(function() w:AddToViewport(9000) end)
    coverRef, coverAt = C.ref(w), C.clock
    log('[cover] on')
    return true
  end
  local w = C.deref(coverRef)
  if w then try(function() w:RemoveFromParent() end); log('[cover] off') end
  coverRef, coverAt = nil, nil
  return true
end
function U.coverAge() return coverAt and (C.clock - coverAt) or nil end

-- v0.8: a screen can ask for its own grid (spec.layout = { cols, rows, w, h }): the cups page (config CupsLayout;
-- v0.11: 4 + 3 tiles) fits one page without scrolling. The layout is put back after the build.
function U.build(spec, host)
  local saved = { U.TILE_W, U.TILE_H, U.COLS, U.ROWS }
  local L = spec and spec.layout
  if L then U.TILE_W, U.TILE_H, U.COLS, U.ROWS = L.w or U.TILE_W, L.h or U.TILE_H, L.cols or U.COLS, L.rows or U.ROWS end
  local ok, res = pcall(buildInner, spec, host)
  U.TILE_W, U.TILE_H, U.COLS, U.ROWS = saved[1], saved[2], saved[3], saved[4]
  if not ok then log('[menu] build error: ' .. tostring(res)); return nil end
  return res
end

return U
