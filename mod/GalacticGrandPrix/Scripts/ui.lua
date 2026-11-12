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
local function ARTDIM(path) local ok, A = pcall(require, 'art'); return ok and A.dim and A.dim(path) or nil end
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

-- v0.14 (TASKS.md A7): how much text fits on a tile. The tile is the game's WBP_FE_TileCommon_Btn with the game's
-- own fonts (not ours to size), so the budget is measured on screenshots of 520 x 350 tiles (the v0.8 shots
-- v08-garage.png / v08-garage2.png / v08-home.png / v08-cups.png in ~/Projects/swgr-underground/autotest/shots:
-- 1280 x 720 captures of the 3840 x 2160 game, a tile about 168 px wide there):
--   title (TxtLabel, big caps): 'LANDSPEEDER' / 'HEAT SHIELD' (11) take the whole line (the tile shrinks the font a
--     little to fit); longer names wrap at spaces ('STATUS / SCRUBBER', 'CONTINUE / CUP'). Budget: 12 a line (no
--     margin: the shrinking is the margin), 2 lines; hyphens break too ('AUTO- / SCRUBBER II').
--   badge (TxtSupplemental, small italic caps, top left): 'TUNE-UP 1 - FROM' (16) fits a line, the rest ('100CC')
--     wraps onto a second line over the title. Budget: 15 (one under the measured fit), one line; 13 when the medal
--     icon sits at the top right ('GOLD TROPHY' nearly touched it on the smaller v0.8 cup tiles).
--   description (TxtDescription, under the title; the game shows it on the focused tile): 'Select: next vehicle' (20)
--     fits a line, 'Immune to Burning and' (21) wraps. Two lines show under a one-line title, one under a two-line
--     title, the rest is cut ('Select: next' under 'Immune to Burning / and Frozen'; 'Next: MONASTERY...' half
--     shown under 'CONTINUE / CUP'). Budget: 19 a line (one under the measured fit), capitals counting 1.3 (they
--     are wider than the mixed case measured), and title lines + description lines <= 3.
-- Everything scales with the tile width (520 = the measured tiles). Checked for every string the menus can show by
-- test/test_tiletext.lua; long text belongs in the screen's info line (item.info), not on the tile.
U.FIT = { width = 520, title = 12, titleLines = 2, badge = 15, badgeIcon = 13, desc = 19, lines = 3, caps = 1.3 }
local function textWidth(s, weighted)
  local n = 0
  for ch in tostring(s):gmatch('.') do n = n + ((weighted and ch:match('%u')) and U.FIT.caps or 1) end
  return n
end
-- greedy word wrap as the game's text does it (breaks at spaces and after hyphens) -> lines, or nil + the word that
-- doesn't fit on a line of its own
local function wrap(s, per, weighted)
  local lines = {}
  for para in (tostring(s) .. '\n'):gmatch('(.-)\n') do
    local cur = ''
    for word, sp in para:gmatch('([^%s%-]*%-?)(%s*)') do
      if word ~= '' then
        if textWidth(word, weighted) > per then return nil, word end
        local try1 = cur .. word
        if cur ~= '' and textWidth((try1:gsub('%s+$', '')), weighted) > per then
          lines[#lines + 1] = (cur:gsub('%s+$', ''))
          cur = word
        else cur = try1 end
        if sp ~= '' then cur = cur .. ' ' end
      end
    end
    lines[#lines + 1] = (cur:gsub('%s+$', ''))
  end
  return lines
end
U.wrapText = wrap
-- does a tile's text fit (it = { title, badge, desc, icon }; w = the tile width, default the layout's)? -> true, or
-- false + what doesn't (every problem, '; ' between)
function U.tileFits(it, w)
  local F = U.FIT
  local sc = (w or U.TILE_W) / F.width
  local probs = {}
  local tl, bad = wrap(it.title or '', F.title * sc)
  if not tl then probs[#probs + 1] = ('title word too long: %q'):format(bad); tl = { '', '' }
  elseif #tl > F.titleLines then probs[#probs + 1] = ('title takes %d lines: %q'):format(#tl, it.title) end
  if it.badge then
    local max = (it.icon and F.badgeIcon or F.badge) * sc
    if it.badge:find('\n') or textWidth(it.badge) > max then probs[#probs + 1] = ('badge over %d: %q'):format(math.floor(max), it.badge) end
  end
  if it.desc and it.desc ~= '' then
    local dl, bad2 = wrap(it.desc, F.desc * sc, true)
    local room = math.min(F.lines - 1, F.lines - math.min(#tl, F.titleLines))
    if not dl then probs[#probs + 1] = ('description word too long: %q'):format(bad2)
    elseif #dl > room then
      probs[#probs + 1] = ('description takes %d lines, %d show under a %d-line title: %q'):format(#dl, room, #tl, it.desc)
    end
  end
  if #probs > 0 then return false, table.concat(probs, '; ') end
  return true
end

-- a widget's slot settings (size, padding, alignment), to put a widget back as it was (as tab.lua does)
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

-- v0.20 (menu review 3: the focused tile brightens its art and its small top label vanishes): a dark strip behind a
-- tile's text widget `w` - a Border (U.STRIP) put in w's place in its parent panel with w inside it. The panel has no
-- InsertChildAt from Lua, so w and the children after it are taken off and put back after the border, each with its
-- slot settings (tab.lua's way of placing our page). The text widget keeps being the tile's own (the tile's code
-- still sets its text and visibility; a collapsed text leaves an empty, zero-size border). make = a widget maker on
-- the menu's tree. -> true, parent class / false, why. Nothing is kept.
U.STRIP = { R = 0.0, G = 0.0, B = 0.0, A = 0.6 }
function U.stripBehind(make, w, pad)
  if not alive(w) then return false, 'no text widget' end
  local parent = try(function() return w:GetParent() end)
  if not alive(parent) then return false, 'no parent' end
  local pcls = C.clsname(parent)
  local n = tonumber((try(function() return parent:GetChildrenCount() end)))
  local at = tonumber((try(function() return parent:GetChildIndex(w) end)))
  if not (n and at and at >= 0 and at < n) then return false, 'parent ' .. pcls .. ' gives no child index' end
  local b = make('/Script/UMG.Border')
  if not alive(b) then return false, 'no border' end
  local moved = {}
  for i = at, n - 1 do
    local c = try(function() return parent:GetChildAt(i) end)
    if alive(c) then moved[#moved + 1] = { w = c, p = slotOf(c) } end
  end
  for _, m in ipairs(moved) do try(function() parent:RemoveChild(m.w) end) end
  try(function() b:SetBrushColor(U.STRIP) end)
  try(function() b:SetPadding(pad or { Left = 0, Top = 0, Right = 0, Bottom = 0 }) end)
  try(function() b:SetContent(w) end)
  local function add(x) return try(function() return parent:AddChild(x) end) end
  applySlot(add(b), moved[1] and moved[1].p)
  for i = 2, #moved do applySlot(add(moved[i].w), moved[i].p) end
  return true, pcls
end
-- the tile's badge and description get the strip (config TileLabelStrip, default on); the badge also a text shadow.
-- Logged once per screen build: `[tiles] label strip: ...`
local stripSaid
local function tileStrips(make, t, it)
  if cfg.TileLabelStrip == false then return end
  local said = {}
  local badge = try(function() return t.Txt_Label_Supplemental end)
  if it.badge and alive(badge) then
    try(function() badge:SetShadowOffset({ X = 1.5, Y = 1.5 }) end)
    try(function() badge:SetShadowColorAndOpacity({ R = 0, G = 0, B = 0, A = 0.9 }) end)
    local ok, why = U.stripBehind(make, badge, { Left = 6, Top = 1, Right = 6, Bottom = 1 })
    said[#said + 1] = 'badge ' .. (ok and ('in ' .. why) or ('not done (' .. tostring(why) .. ')'))
  end
  local desc = try(function() return t.RT_Description end)
  if it.desc and alive(desc) then
    local ok, why = U.stripBehind(make, desc)
    said[#said + 1] = 'description ' .. (ok and ('in ' .. why) or ('not done (' .. tostring(why) .. ')'))
  end
  if #said > 0 and not stripSaid then stripSaid = true; log('[tiles] label strip: ' .. table.concat(said, ', ')) end
end

local function makeTile(lib, pc, it, make)
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
    -- v0.15.1: the brightest pictures drawn darker so the white title reads on a focused tile (art.lua A.DIM)
    local d = it.dim or ARTDIM(it.art)
    if d then try(function() t.Img_TileArt:SetColorAndOpacity({ R = d, G = d, B = d, A = 1 }) end) end
  else try(function() t.Img_TileArt:SetVisibility(1) end) end
  -- v0.7: a picture in the tile's icon slot (the trophy medal), else the slot stays hidden
  local icon = (not it.noTileIcon) and texture(it.icon) or nil
  if icon then
    try(function() t.Img_Icon:SetBrushFromTexture(icon, false) end)
    try(function() t.Img_Icon:SetVisibility(4) end) -- SelfHitTestInvisible
    -- the tile draws its icon as a shape in one colour (seen in game): white, or the item's colour (medals)
    -- v0.20 (menu review 7: bronze and gold looked the same in game, v16-cups-100-lantaana.png - the image's colour
    -- set here did not hold): the colour goes on the brush tint, the image's own colour white (multiplied together:
    -- whatever the tile's look then puts on the image, the medals stay apart)
    local c = it.iconColor or { 1, 1, 1 }
    try(function() t.Img_Icon:SetColorAndOpacity({ R = 1, G = 1, B = 1, A = 1 }) end)
    try(function() t.Img_Icon:SetBrushTintColor({ SpecifiedColor = { R = c[1], G = c[2], B = c[3], A = 1 }, ColorUseRule = 0 }) end)
    -- to the top right corner, off the title (the slot sits over it)
    try(function() t.Img_Icon:SetRenderTranslation({ X = 85, Y = -38 }) end)
  else try(function() t.Img_Icon:SetVisibility(1) end) end
  try(function() t:SetText(FText(it.title)) end)
  -- v0.25 (seen in game: with no grey strips, a white title vanished on bright art when focused): a dark drop shadow
  -- on the tile's title, badge and description (config TileTextShadow = false: none)
  if cfg.TileTextShadow ~= false then
    for _, k in ipairs({ 'Txt_Label_Title', 'Txt_Label_Supplemental', 'RT_Description' }) do
      local tb = try(function() return t[k] end)
      if alive(tb) then
        try(function() tb:SetShadowOffset({ X = 2.5, Y = 2.5 }) end)
        try(function() tb:SetShadowColorAndOpacity({ R = 0, G = 0, B = 0, A = 0.85 }) end)
      end
    end
  end
  if make then tileStrips(make, t, it) end
  if it.disabled then try(function() t:SetRenderOpacity(0.5) end) end
  U.makeToggle(t)
  return t
end

-- v0.22 (owner: the gold and white text is too light on the menu's own pale art): while a page without a picture
-- behind it is built, every text colour is swapped for dark grey (U.ink); pages with a picture keep the light colours
local inkOn = false
local function textBlock(make, s, size, color, wrapAt)
  local t = make('/Script/UMG.TextBlock')
  if not alive(t) then return nil end
  try(function() t:SetText(FText(s)) end)
  local c = color or { 1, 1, 1 }
  if inkOn then c = U.ink(c) end
  try(function() t:SetColorAndOpacity({ SpecifiedColor = { R = c[1], G = c[2], B = c[3], A = 1 }, ColorUseRule = 0 }) end)
  if size then try(function() local f = t.Font; f.Size = math.floor(size * (U.TEXT or 1) + 0.5); t:SetFont(f) end) end
  if wrapAt then
    try(function() t:SetAutoWrapText(true) end)
    try(function() t.WrapTextAt = wrapAt end)
  end
  return t
end

local GOLD, GREY, WHITE = { 1, 0.82, 0.35 }, { 0.72, 0.74, 0.78 }, { 1, 1, 1 }
U.GOLD, U.GREY, U.WHITE = GOLD, GREY, WHITE
-- the dark inks (v0.22): white and gold -> dark grey, the light grey (small print) -> a lighter dark grey
U.DARK, U.DARK2 = { 0.12, 0.13, 0.14 }, { 0.26, 0.27, 0.29 }
function U.ink(c)
  if c == GREY then return U.DARK2 end
  return U.DARK
end

-- a screen's text lines ({ text, size, color }) into a vertical box, wrapped at `wrap`; top = the space above each
local function addLines(box, make, lines, wrap, top)
  for _, ln in ipairs(lines or {}) do
    if ln[1] and ln[1] ~= '' then
      local t = textBlock(make, ln[1], ln[2] or 18, ln[3] or GREY, wrap)
      local sl = t and try(function() return box:AddChildToVerticalBox(t) end)
      if sl then try(function() sl:SetPadding({ Left = 0, Top = top or 4, Right = 0, Bottom = 0 }) end) end
    end
  end
end

-- a table (spec.table, see below) into a vertical box: one horizontal box per row
local function addTable(box, make, tb)
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
-- v0.20 (menu review 1a): a big picture with lines beside it (spec.hero = { icon = texture, color = {r,g,b} (the tint:
-- the medals are one-colour shapes), size = px, lines = { {text, size, color} ... } }): the cup result's medal. With no
-- picture found, the lines alone.
local function addHero(box, make, hero, wrap)
  local hb = make('/Script/UMG.HorizontalBox')
  local col = make('/Script/UMG.VerticalBox')
  if not (alive(hb) and alive(col)) then addLines(box, make, hero.lines, wrap); return end
  local tex = texture(hero.icon)
  local img = tex and make('/Script/UMG.Image')
  if alive(img) then
    local sz = hero.size or 190
    try(function() img:SetBrushFromTexture(tex, false) end)
    local c = hero.color or { 1, 1, 1 }
    try(function() img:SetBrushTintColor({ SpecifiedColor = { R = c[1], G = c[2], B = c[3], A = 1 }, ColorUseRule = 0 }) end)
    try(function() img:SetColorAndOpacity({ R = 1, G = 1, B = 1, A = 1 }) end)
    local sb = make('/Script/UMG.SizeBox')
    local cell = img
    if alive(sb) then
      try(function() sb:SetWidthOverride(sz); sb:SetHeightOverride(sz) end)
      try(function() sb:SetContent(img) end)
      cell = sb
    end
    local sl = try(function() return hb:AddChildToHorizontalBox(cell) end)
    if sl then try(function() sl:SetPadding({ Left = 0, Top = 6, Right = 28, Bottom = 0 }); sl:SetVerticalAlignment(2) end) end
  end
  addLines(col, make, hero.lines, wrap - (hero.size or 190) - 28)
  local sl2 = try(function() return hb:AddChildToHorizontalBox(col) end)
  if sl2 then try(function() sl2:SetVerticalAlignment(2) end) end
  local sl3 = try(function() return box:AddChildToVerticalBox(hb) end)
  if sl3 then try(function() sl3:SetPadding({ Left = 0, Top = 8, Right = 0, Bottom = 4 }) end) end
end

-- a table's width (its columns and their gaps)
local function tableWidth(tb)
  local w = 0
  for _, col in ipairs((tb or {}).cols or {}) do w = w + (col.w or 0) + 24 end
  return w > 0 and w or nil
end

-- a screen: { title, lines = { {text, size, color} ... }, table = (see below), items = { {title, desc, art, badge, disabled} ... },
-- hint }
-- table (v0.3.8, the ranking): { size = text size, cols = { { w = width, align = 'left'|'right'|'center' } ... },
--   header = { cell text ... }, rows = { { cells = { text ... }, color = {r,g,b} (default white), colors = { [col] =
--   {r,g,b} }, highlight = true } ... } } - one horizontal box per row, each cell in a box of its column's width, so
--   the columns line up whatever the font.
-- returns { w, items (each with .btn), scroll } or nil


-- v0.23 (TASKS round 3 item 2): a page in rows of tiles, each row its own tile size, in place of the one uniform
-- grid. spec.rows = { { w = tile width, h = tile height, n = tiles in the row (the last row: the rest) } ... }; the
-- items fill the rows in order; an item's span (default 1) makes it that many tiles wide (the Galactic Cup).
-- An item with a medal (it.icon) gets it as our own picture over the tile's top right corner (U.MEDAL_PX): the
-- tile's icon slot draws every medal in one colour (gold and bronze looked alike in game, v0.20).
U.GAP = 20
U.MEDAL_PX = 120
local function rowItems(rows, n)
  local out, at = {}, 1
  for r, row in ipairs(rows) do
    local take = (r == #rows) and (n - at + 1) or math.min(row.n or n, n - at + 1)
    out[r] = { from = at, to = at + take - 1 }
    at = at + take
  end
  return out
end
U.rowItems = rowItems
function U.itemWidth(row, it) local k = it.span or 1; return row.w * k + U.GAP * (k - 1) end
-- the widest row (the page's text wraps at it); items unknown here, so each row as n tiles of its width
function U.rowsWidth(rows)
  local w = 0
  for _, row in ipairs(rows) do w = math.max(w, (row.n or 4) * (row.w + U.GAP)) end
  return w
end
-- the D-pad map of a rows page: { [i] = { left, right, up, down } } (indices; nil at an edge). Up / down go to the
-- tile in the next row whose middle is nearest this tile's middle (rows are centred, so the x's are from the middle).
function U.rowsNav(rows, items)
  local spans = rowItems(rows, #items)
  local mids = {}
  for r, sp in ipairs(spans) do
    local row, total = rows[r], 0
    for i = sp.from, sp.to do total = total + U.itemWidth(row, items[i]) + U.GAP end
    local x = -total / 2
    for i = sp.from, sp.to do
      local w = U.itemWidth(row, items[i]) + U.GAP
      mids[i] = { r = r, x = x + w / 2 }
      x = x + w
    end
  end
  local function nearest(r, x)
    local sp = spans[r]
    if not sp or sp.to < sp.from then return nil end
    local best, bd
    for j = sp.from, sp.to do
      local d = math.abs(mids[j].x - x)
      if not bd or d < bd - 0.01 then best, bd = j, d end
    end
    return best
  end
  local nav = {}
  for i = 1, #items do
    local m, sp = mids[i], spans[mids[i].r]
    nav[i] = { left = (i > sp.from) and i - 1 or nil, right = (i < sp.to) and i + 1 or nil,
      up = nearest(m.r - 1, m.x), down = nearest(m.r + 1, m.x) }
  end
  return nav
end
-- v0.24 (owner: "i don't like the text on the tiles with a dark grey background ... find a prettier way"): pictures
-- drawn over a rows tile, each the game's own icon tinted (the icons are one-colour shapes):
--   it.icon / it.iconColor  the medal, top right (U.MEDAL_PX)
--   it.corner = { {tex, color}, ... }  more small icons beside it, top right (the lock, the perfect-cup star)
--   it.pips = { {tex, color, alpha}, ... }  a row of small icons top left, where the badge was (a league's medals)
--   it.glyph = {tex, color, px}  one big icon, top middle (an ability's or a tune-up's icon)
U.PIP_PX, U.CORNER_PX = 66, 72
function U.hasDecor(it) return (it.icon or it.corner or it.pips or it.glyph or it.tag) and true or false end
local function picture(make, tex, color, px, alpha)
  local img = make('/Script/UMG.Image')
  if not alive(img) then return nil end
  try(function() img:SetBrushFromTexture(tex, false) end)
  local c = color or { 1, 1, 1 }
  try(function() img:SetBrushTintColor({ SpecifiedColor = { R = c[1], G = c[2], B = c[3], A = 1 }, ColorUseRule = 0 }) end)
  try(function() img:SetColorAndOpacity({ R = 1, G = 1, B = 1, A = alpha or 1 }) end)
  try(function() img:SetVisibility(4) end) -- SelfHitTestInvisible: clicks go to the tile
  local sb = make('/Script/UMG.SizeBox')
  if not alive(sb) then return img end
  -- v0.27.4 (owner: icons stretched tall): px is the height; the width keeps the texture's own shape (the ability
  -- badges are 472 x 244 - drawn square they were stretched to twice their height), at most 2.5 x px
  local w = px
  local sx = try(function() return tex:Blueprint_GetSizeX() end)
  local sy = try(function() return tex:Blueprint_GetSizeY() end)
  if type(sx) == 'number' and type(sy) == 'number' and sx > 0 and sy > 0 then w = math.min(px * sx / sy, px * 2.5) end
  try(function() sb:SetWidthOverride(w); sb:SetHeightOverride(px) end)
  try(function() sb:SetContent(img) end)
  return sb
end
U.picture = picture
-- a row of pictures -> a horizontal box (nil when none could be made)
local function pictureRow(make, list, px, gap)
  local hb = make('/Script/UMG.HorizontalBox')
  if not alive(hb) then return nil end
  local n = 0
  for _, p in ipairs(list) do
    local tex = texture(p[1])
    local pic = tex and picture(make, tex, p[2], p.px or px, p[3])
    local sl = pic and try(function() return hb:AddChildToHorizontalBox(pic) end)
    if sl then n = n + 1; try(function() sl:SetPadding({ Left = gap or 4, Top = 0, Right = 0, Bottom = 0 }); sl:SetVerticalAlignment(2) end) end
  end
  return n > 0 and hb or nil
end
-- (EHorizontalAlignment Left 1 / Center 2 / Right 3; EVerticalAlignment Top 1 / Center 2 / Bottom 3)
local function place(ov, w, h, v, pad)
  local sl = w and try(function() return ov:AddChildToOverlay(w) end)
  if sl then try(function() sl:SetHorizontalAlignment(h); sl:SetVerticalAlignment(v); sl:SetPadding(pad) end) end
end
function U.decorate(make, ov, it)
  if it.glyph and it.glyph[1] then
    local tex = texture(it.glyph[1])
    place(ov, tex and picture(make, tex, it.glyph[2], it.glyph[3] or 150, it.glyph[4]), 2, 1, { Left = 0, Top = 34, Right = 0, Bottom = 0 })
  end
  local corner = {}
  -- (v0.26: an entry may carry its own size, c.px - the leagues' speed chevrons)
  for _, c in ipairs(it.corner or {}) do corner[#corner + 1] = { c[1], c[2], c[3], px = c.px or U.CORNER_PX } end
  if it.icon then corner[#corner + 1] = { it.icon, it.iconColor, px = U.MEDAL_PX } end
  if #corner > 0 then place(ov, pictureRow(make, corner, U.CORNER_PX, 6), 3, 1, { Left = 0, Top = 10, Right = 14, Bottom = 0 }) end
  if it.pips and #it.pips > 0 then
    place(ov, pictureRow(make, it.pips, U.PIP_PX, 6), 1, 1, { Left = 12, Top = 14, Right = 0, Bottom = 0 })
  end
  -- v0.27.4 (owner: tune-ups and abilities looked alike): it.tag = { text, color } - a small caption top left, in
  -- its own colour whatever the page's ink (it sits on the tile's picture), with a dark shadow
  if it.tag and it.tag[1] then
    local t = make('/Script/UMG.TextBlock')
    if alive(t) then
      local c = it.tag[2] or WHITE
      try(function() t:SetText(FText(it.tag[1])) end)
      try(function() t:SetColorAndOpacity({ SpecifiedColor = { R = c[1], G = c[2], B = c[3], A = 1 }, ColorUseRule = 0 }) end)
      try(function() local f = t.Font; f.Size = math.floor(U.TAG_SIZE * (U.TEXT or 1) + 0.5); t:SetFont(f) end)
      try(function() t:SetShadowColorAndOpacity({ R = 0, G = 0, B = 0, A = 0.85 }); t:SetShadowOffset({ X = 2, Y = 2 }) end)
      try(function() t:SetVisibility(4) end)
      place(ov, t, 1, 1, { Left = 16, Top = 12, Right = 0, Bottom = 0 })
    end
  end
end
U.TAG_SIZE = 15

-- builds the rows into box -> the list of items made (each with .btn, and .cell: what holds it)
function U.buildRows(spec, box, make, lib, pc)
  local list = {}
  local items = spec.items or {}
  local spans = rowItems(spec.rows, #items)
  for r, sp in ipairs(spans) do
    local row = spec.rows[r]
    local hb = make('/Script/UMG.HorizontalBox')
    if alive(hb) and sp.to >= sp.from then
      for i = sp.from, sp.to do
        local it = items[i]
        local w, h = U.itemWidth(row, it), row.h
        -- v0.24: the tile's pictures over it (U.decorate): the corner medal / lock / star, the medal pips, the big icon.
        -- No Overlay from the game: the medal stays in the tile's own icon slot, as before v0.23.
        local ov = U.hasDecor(it) and make('/Script/UMG.Overlay')
        it.noTileIcon = alive(ov) or nil
        local saveW, saveH = U.TILE_W, U.TILE_H
        U.TILE_W, U.TILE_H = w, h
        local t = makeTile(lib, pc, it, make)
        U.TILE_W, U.TILE_H = saveW, saveH
        if t then
          local cell = t
          local sb = make('/Script/UMG.SizeBox')
          if alive(sb) then
            try(function() sb:SetWidthOverride(w); sb:SetHeightOverride(h) end)
            try(function() sb:SetContent(t) end)
            cell = sb
          end
          if alive(ov) then
            try(function() ov:AddChildToOverlay(cell) end)
            U.decorate(make, ov, it)
            cell = ov
          end
          local sl = try(function() return hb:AddChildToHorizontalBox(cell) end)
          if sl then try(function() sl:SetPadding({ Left = U.GAP / 2, Top = U.GAP / 2, Right = U.GAP / 2, Bottom = U.GAP / 2 }) end) end
          it.btn, it.cell = t, cell
          list[#list + 1] = it
        end
      end
      local rs = try(function() return box:AddChildToVerticalBox(hb) end)
      -- each row centred under the one above (Center = 2)
      if rs then try(function() rs:SetHorizontalAlignment(2) end) end
      if rs and r == 1 then try(function() rs:SetPadding({ Left = 0, Top = 14, Right = 0, Bottom = 0 }) end) end
    end
  end
  return list
end

-- v0.21: the page panel's colour: v0.20's translucent grey with PageBackdrop = true, else fully transparent (alpha 0)
U.PAGE_GREY = { R = 0.01, G = 0.012, B = 0.016, A = 0.6 }
function U.pageColor(hasPicture)
  if cfg.PageBackdrop == true or hasPicture then return U.PAGE_GREY end
  return { R = 0, G = 0, B = 0, A = 0 }
end
local backdropSaid = false

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
  -- the page panel (on the game's own menu background). v0.21 (owner: the grey see-through background isn't needed):
  -- fully transparent unless config PageBackdrop = true; a page with its own picture (spec.backdrop: the standings, the
  -- cup result, the title result - tables and big lines over the menu's busy art) keeps it either way
  local bd = texture(spec.backdrop)
  try(function() border:SetBrushColor(U.pageColor(bd ~= nil)) end)
  inkOn = (bd == nil) and cfg.PageBackdrop ~= true and cfg.DarkText ~= false
  -- v0.7: a picture behind the page (spec.backdrop), darkened so the text stays readable
  if bd then
    try(function() border:SetBrushFromTexture(bd) end)
    try(function() border:SetBrushColor({ R = 0.45, G = 0.45, B = 0.45, A = 0.92 }) end)
  end
  if not backdropSaid then
    backdropSaid = true
    log(('[menu] page backdrop: %s (config PageBackdrop = %s); the standings, cup result and title result keep their picture'):format(
      cfg.PageBackdrop == true and 'the v0.20 grey panel' or 'none, transparent', tostring(cfg.PageBackdrop == true)))
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

  local wrap = spec.rows and U.rowsWidth(spec.rows) or (U.TILE_W + 20) * U.COLS
  local t1 = (spec.title or '') ~= '' and textBlock(make, spec.title, 34, WHITE) or nil
  if t1 then try(function() box:AddChildToVerticalBox(t1) end) end
  if spec.hero then addHero(box, make, spec.hero, wrap) end
  addLines(box, make, spec.lines, wrap)

  -- v0.6: an info line (spec.info = true): the full text of the focused tile (its item.info), set on every focus change
  -- (tile descriptions are cut after two lines; for mods the description is the point)
  local info
  if spec.info then
    info = textBlock(make, ' ', 20, GOLD, wrap)
    local sl = info and try(function() return box:AddChildToVerticalBox(info) end)
    if sl then try(function() sl:SetPadding({ Left = 0, Top = 6, Right = 0, Bottom = 0 }) end) end
  end

  if spec.table then addTable(box, make, spec.table) end
  addLines(box, make, spec.after, wrap, 8)

  local list = {}
  stripSaid = false
  if spec.rows then
    list = U.buildRows(spec, box, make, lib, pc)
  else
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

    for _, it in ipairs(spec.items or {}) do
      local t = makeTile(lib, pc, it, make)
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
  end
  if spec.hint then
    local th = textBlock(make, spec.hint, 15, GREY, wrap)
    if th then try(function() box:AddChildToVerticalBox(th) end) end
  end
  if #list == 0 then log('[menu] no tiles'); return nil end

  local screen = { w = border, host = host, items = list, scroll = (not spec.rows and alive(scroll)) and scroll or nil, pc = pc,
    grid = grid, info = info, cols = U.COLS, rows = spec.rows ~= nil,
    nav = spec.rows and U.rowsNav(spec.rows, list) or nil }
  try(function() host.panel:ClearChildren() end)
  local sl = try(function() return host.panel:AddChildToVerticalBox(border) end)
  if not alive(sl) then sl = try(function() return host.panel:AddChild(border) end) end
  -- (v0.23: spec.center - the page at its own width in the middle of the screen; EHorizontalAlignment Center = 2)
  if sl then try(function() sl:SetHorizontalAlignment(spec.center and 2 or 0); sl:SetVerticalAlignment(0) end) end
  U.wire(screen)
  return screen
end

-- D-pad links between the tiles from their grid positions (the game's own navigation then moves focus). Edges are
-- left to the game (up from the top row reaches the tab bar). EUINavigation: Left 0, Right 1, Up 2, Down 3.
function U.wire(screen)
  if screen.nav then
    for i, it in ipairs(screen.items) do
      local n = screen.nav[i] or {}
      for dir, k in pairs({ left = 0, right = 1, up = 2, down = 3 }) do
        local j = n[dir]
        if j and screen.items[j] then try(function() it.btn:SetNavigationRuleExplicit(k, screen.items[j].btn) end) end
      end
    end
    return
  end
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
    -- (v0.23: a rows page scales and dims the tile's holder, so its medal goes with it)
    local w = it.cell or it.btn
    try(function() w:SetRenderScale({ X = sc, Y = sc }) end)
    -- (a disabled tile is already at half opacity on its own: its holder isn't halved again)
    -- v0.25 (seen in game 2026-11-11: with no page backdrop, faded tiles look milky on the menu's pale art): a rows
    -- page dims the other tiles by darkening them (the tile's colour), not by fading them
    if it.cell then
      local d = (on or U.DIM == 1) and 1 or U.DIM
      try(function() it.btn:SetColorAndOpacity({ R = d, G = d, B = d, A = 1 }) end)
      try(function() w:SetRenderOpacity(1) end)
    else
      local op = (it.disabled and 0.5 or 1) * ((on or U.DIM == 1) and 1 or U.DIM)
      try(function() w:SetRenderOpacity(op) end)
    end
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

-- v0.19 (chain.lua): a standings panel built into another screen's widget tree (the game's race results screen):
-- the title, spec.lines, spec.table, then spec.after (the prompt), on a dark box. opts = { minW, minH }: the box's
-- least size (to cover what is under it). v0.19.1: the box is opaque (alpha 1, and the size box behind it a second
-- opaque border: v0.19.0's 0.92 let the game's table show through). Returns the outermost widget (not yet added
-- anywhere), or nil + why.
-- Nothing is kept: the widgets go with the screen.
U.PANEL_BG = { R = 0.01, G = 0.012, B = 0.016, A = 1 }
function U.panel(spec, tree, opts)
  opts = opts or {}
  if not alive(tree) then return nil, 'no widget tree' end
  local function make(path) return try(function() return StaticConstructObject(StaticFindObject(path), tree) end) end
  local border, box = make('/Script/UMG.Border'), make('/Script/UMG.VerticalBox')
  if not (alive(border) and alive(box)) then return nil, 'could not build the panel' end
  try(function() border:SetBrushColor(U.PANEL_BG) end)
  try(function() border:SetPadding({ Left = 48, Top = 32, Right = 48, Bottom = 32 }) end)
  try(function() border:SetContent(box) end)
  -- (the text wraps at the table's width or the panel's least width, whichever is wider: one panel width)
  local wrap = math.max(tableWidth(spec.table) or 0, (opts.minW or 1600) - 96)
  local t1 = (spec.title or '') ~= '' and textBlock(make, spec.title, 34, WHITE) or nil
  if t1 then try(function() box:AddChildToVerticalBox(t1) end) end
  if spec.hero then addLines(box, make, spec.hero.lines, wrap) end -- (v0.20: the cup result's lines, no picture here)
  addLines(box, make, spec.lines, wrap)
  if spec.table then
    local gap = make('/Script/UMG.SizeBox')
    if alive(gap) then try(function() gap:SetHeightOverride(12) end); try(function() box:AddChildToVerticalBox(gap) end) end
    addTable(box, make, spec.table)
  end
  addLines(box, make, spec.after, wrap, 18)
  if not (opts.minW or opts.minH) then return border end
  local sb = make('/Script/UMG.SizeBox')
  if not alive(sb) then return border end
  if opts.minW then try(function() sb:SetMinDesiredWidth(opts.minW) end) end
  if opts.minH then try(function() sb:SetMinDesiredHeight(opts.minH) end) end
  try(function() sb:SetContent(border) end)
  -- (an opaque backing border around the size box: whatever the inner one draws, nothing under the panel shows)
  local back = make('/Script/UMG.Border')
  if not alive(back) then return sb end
  try(function() back:SetBrushColor(U.PANEL_BG) end)
  try(function() back:SetPadding({ Left = 0, Top = 0, Right = 0, Bottom = 0 }) end)
  try(function() back:SetContent(sb) end)
  return back
end

-- v0.8: a screen can ask for its own grid (spec.layout = { cols, rows, w, h }): the cups page (config CupsLayout;
-- v0.11: 4 + 3 tiles) fits one page without scrolling. The layout is put back after the build.
function U.build(spec, host)
  local saved = { U.TILE_W, U.TILE_H, U.COLS, U.ROWS }
  local L = spec and spec.layout
  if L then U.TILE_W, U.TILE_H, U.COLS, U.ROWS = L.w or U.TILE_W, L.h or U.TILE_H, L.cols or U.COLS, L.rows or U.ROWS end
  local ok, res = pcall(buildInner, spec, host)
  inkOn = false
  U.TILE_W, U.TILE_H, U.COLS, U.ROWS = saved[1], saved[2], saved[3], saved[4]
  if not ok then log('[menu] build error: ' .. tostring(res)); return nil end
  return res
end

return U
