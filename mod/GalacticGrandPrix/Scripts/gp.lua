-- Galactic Grand Prix: the save file, the classes, cups and vehicles (config.lua).
-- Save (save.lua, the mod's own file, never the game's): what's needed to put launch builds back after a crash, the
-- race count and the last race. Trophies and cup progress come with v0.2.
local C = require('core')
local cfg = require('config')
local log = C.log

local K = { data = nil }
K.SAVE_VERSION = 1

local function fill(d)
  d.version = tonumber(d.version) or K.SAVE_VERSION
  d.races = tonumber(d.races) or 0
  -- launch builds we changed: path -> original part levels { [slot] = level }, put back at the menu
  d.restores = type(d.restores) == 'table' and d.restores or {}
  d.class = type(d.class) == 'string' and d.class or nil -- the class picked last
  d.vehicle = type(d.vehicle) == 'string' and d.vehicle or 'car'
  return d
end

function K.save()
  local path = C.DIR .. '/save.lua'
  local tmp = path .. '.tmp'
  local f = io.open(tmp, 'w')
  if not f then log('could not write the save'); return false end
  f:write('-- Galactic Grand Prix save\nreturn ', C.serialize(K.data), '\n')
  f:close()
  os.remove(path)
  local ok = os.rename(tmp, path)
  if not ok then log('could not replace save.lua') end
  return ok
end

function K.load()
  local f = io.open(C.DIR .. '/save.lua', 'r')
  if f then
    local s = f:read('a'); f:close()
    local chunk = load(s, '=save.lua', 't', {})
    local ok, t = false, nil
    if chunk then ok, t = pcall(chunk) end
    if ok and type(t) == 'table' then
      K.data = fill(t)
      log(('save loaded: %d races'):format(K.data.races))
      return
    end
    log('save.lua unreadable - starting a new save (old file kept as save_bad.lua)')
    local b = io.open(C.DIR .. '/save_bad.lua', 'w'); if b then b:write(s); b:close() end
  end
  K.data = fill({})
  K.save()
  log('new save started')
end

---------------------------------------------------------------------------------------------------------------------
-- classes, cups, vehicles

function K.classes() return cfg.Classes or {} end
function K.class(key)
  for _, c in ipairs(K.classes()) do if c.key == key then return c end end
  return nil
end
function K.cups() return cfg.Cups or {} end
function K.cup(key)
  for _, c in ipairs(K.cups()) do if c.key == key then return c end end
  return nil
end
function K.vehicles() return cfg.Vehicles or {} end
function K.vehicle(key)
  for _, v in ipairs(K.vehicles()) do if v.key == key then return v end end
  return K.vehicles()[1]
end

-- every part slot (0-5) at the class's level
function K.levelsFor(classKey)
  local c = K.class(classKey)
  local lv = c and c.parts or 0
  local t = {}
  for s = 0, 5 do t[s] = lv end
  return t
end

-- a finished race (v0.1: just counted; points come with v0.2)
function K.record(ev, pos)
  K.data.races = K.data.races + 1
  K.data.last = { title = ev.title, pos = pos, class = ev.class, cup = ev.cup, at = os.date('%Y-%m-%d %H:%M') }
  K.save()
  return { ev = ev, pos = pos }
end

return K
