-- shared test helpers
local M = require('mock')
local W = require('world')
local T = { failed = false }
T.main = os.getenv('MOD_MAIN')
T.dir = T.main:match('^(.*)/Scripts/main.lua$')

-- cfg: config overrides. The Grand Prix is a tab on the game's main menu: a menu with a tab bar is set up and given
-- time to settle (the mod waits ~3 s before touching it), unless cfg.NoTabMenu.
function T.boot(save, cfg)
  cfg = cfg or {}
  -- v0.17: the boot into the GRAND PRIX tab is off in tests unless asked for (test_boot): the scenarios start from
  -- the game's own main menu, as before
  if cfg.BootToGrandPrix == nil then cfg.BootToGrandPrix = false end
  _G.GU_TEST_CFG = cfg
  W.setup()
  for _, b in ipairs({ 'VBD_Car_Base', 'VBD_Bike_Base', 'VBD_Skimmer_Base' }) do W.build('/Game/Griffin/Gameplay/Campaign/Builds/' .. b) end
  if save then
    local C = dofile(T.dir .. '/Scripts/core.lua')
    local f = io.open(T.dir .. '/save.lua', 'w'); f:write('return ' .. C.serialize(save) .. '\n'); f:close()
    package.loaded.core = nil
  end
  local ok, err = pcall(dofile, T.main)
  assert(ok, 'load failed: ' .. tostring(err))
  if not cfg.NoTabMenu and not cfg.Manual then W.tabMenu(); M.tick(18) end
end
-- v0.19: a fresh start inside the same test file (test_chain runs several scenarios): the fake engine's objects, loops,
-- key binds, calls and log emptied, every mod module unloaded, the save deleted. Then T.boot again.
function T.reset()
  M.loops, M.binds, M.objects, M.assets, M.notifies, M.calls, M.log, M.hooks = {}, {}, {}, {}, {}, {}, {}, {}
  M.deadTouches, M.deadLog = 0, {}
  local p = io.popen('ls "' .. T.dir .. '/Scripts"')
  for f in p:lines() do local m = f:match('^(.-)%.lua$'); if m then package.loaded[m] = nil end end
  p:close()
  os.remove(T.dir .. '/save.lua')
  for _, k in ipairs({ 'tiles', 'pending', 'backs', 'tabbed', 'tab', 'chainBtn', 'screen', 'canvasKids', 'yourAbility',
    'buildAffixes', 'buildSlots', 'gs', 'player', 'bots', 'rec', 'fe', 'mm' }) do W[k] = nil end
end
-- how many log lines contain s (from line `from` on)
function T.logCount(s, from)
  local n = 0
  for i = from or 1, #M.log do if M.log[i]:find(s, 1, true) then n = n + 1 end end
  return n
end
-- the first log line index containing s (from `from` on), or nil
function T.logAt(s, from)
  for i = from or 1, #M.log do if M.log[i]:find(s, 1, true) then return i end end
  return nil
end
function T.logHas(s, from)
  for i = from or 1, #M.log do if M.log[i]:find(s, 1, true) then return true end end
  return false
end
function T.mark() return #M.log + 1 end
function T.check(cond, what)
  io.stdout:write((cond and 'PASS ' or 'FAIL ') .. what .. '\n')
  if not cond then T.failed = true end
end
function T.key(k, n) for _ = 1, n or 1 do M.press(k); M.tick(5) end end
-- click the n-th tile of the screen on show: the game's UI turns the toggle tile selected (A / Enter / mouse)
function T.click(n)
  local t = W.tiles and W.tiles[n]
  assert(t, 'no tile ' .. n)
  rawget(t, '__props').__sel = true
  M.tick(5)
end
local function label(t)
  local l = rawget(t, '__props').TxtLabel
  return l and rawget(l, '__props').__text or ''
end
-- click the first tile whose title is `title` (or starts with it)
function T.clickTitle(title)
  for i, t in ipairs(W.tiles or {}) do
    if label(t) == title or label(t):sub(1, #title) == title then T.click(i); return true end
  end
  local all = {}
  for _, t in ipairs(W.tiles or {}) do all[#all + 1] = label(t) end
  error('no tile ' .. title .. ' among: ' .. table.concat(all, ', '))
end
function T.titles()
  local all = {}
  for _, t in ipairs(W.tiles or {}) do all[#all + 1] = label(t) end
  return table.concat(all, '|')
end
-- the small extra line on each tile (the trophy badge), '' where none: 'GOLD TROPHY||...'
function T.badges()
  local all = {}
  for _, t in ipairs(W.tiles or {}) do
    local p = rawget(t, '__props')
    local b = p.ShowSupplementalText and p.TxtSupplemental and rawget(p.TxtSupplemental, '__props').__text or ''
    all[#all + 1] = b
  end
  return table.concat(all, '|')
end
function T.ntiles() return W.tiles and #W.tiles or 0 end
function T.save() return dofile(T.dir .. '/save.lua') end
-- a launch build's part levels as text '0=3 1=3 ...'
function T.levels(name)
  local M2 = require('mock')
  local b = M2.assets['/Game/Griffin/Gameplay/Campaign/Builds/' .. name .. '.' .. name]
  local st = rawget(b, '__props').SlotToUpgradeLevelMap.__store
  local p = {}
  for s = 0, 5 do p[#p + 1] = s .. '=' .. tostring(st[s]) end
  return table.concat(p, ' ')
end
function T.finish()
  if M.deadTouches > 0 then print("DEADTOUCH " .. M.deadTouches .. "\n" .. M.deadLog[1]) end
  if os.getenv('VERBOSE') then for _, l in ipairs(M.log) do io.stderr:write('  log: ' .. tostring(l)) end end
  for _, l in ipairs(M.log) do
    -- (v0.16: a study line names the AI profile's `errors=` key; not an error)
    if l:gsub('errors=', ''):find('error', 1, true) then io.stdout:write('FAIL error in log: ' .. l); T.failed = true end
  end
  if T.failed then os.exit(1) end
end
return T
