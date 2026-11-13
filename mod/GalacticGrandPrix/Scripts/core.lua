-- Galactic Grand Prix (from the Underground): shared helpers (guarded engine access, logging, object search, assets, formatting).
local C = { DIR = '.', clock = 0 }

local TAG = '[GalacticGrandPrix] '

function C.try(f, ...)
  local r = table.pack(pcall(f, ...))
  if r[1] then return table.unpack(r, 2, r.n) end
  return nil, tostring(r[2])
end
local try = C.try

function C.alive(o)
  if o == nil then return false end
  local ok, v = pcall(function() return o:IsValid() end)
  return ok and v == true
end
local alive = C.alive

function C.idname(o) return alive(o) and (try(function() return o:GetFName():ToString() end) or '') or '' end
function C.clsname(o) return alive(o) and (try(function() return o:GetClass():GetFName():ToString() end) or '') or '' end
function C.addr(o) return alive(o) and try(function() return o:GetAddress() end) or nil end
function C.text(o, field)
  local s = try(function() return o[field]:ToString() end)
  return (type(s) == 'string' and s ~= '') and s or nil
end
function C.tag(t)
  local s = try(function() return t.TagName:ToString() end)
  return (type(s) == 'string' and s ~= '' and s ~= 'None') and s or nil
end

function C.log(msg)
  msg = tostring(msg)
  print(TAG .. msg .. '\n')
  local f = io.open(C.DIR .. '/grandprix.log', 'a')
  if f then f:write(os.date('%Y-%m-%d %H:%M:%S ') .. msg .. '\n'); f:close() end
end

-- every live, non-template object of a class (a full sweep: use at menus / launch, not every frame)
function C.find(cls)
  local got = try(FindAllOf, cls)
  local out = {}
  if type(got) == 'table' then
    for _, o in ipairs(got) do
      if alive(o) and not C.idname(o):find('^Default__') then out[#out + 1] = o end
    end
  end
  return out
end
function C.first(cls) return C.find(cls)[1] end

-- Keeping objects between ticks: never keep the object itself. Once the game frees it, calling anything on the old
-- reference (even IsValid) reads freed memory - fine until that memory is reused, then a crash in UE4SS
-- (v0.9.2: idle crash on the hub after the game rebuilt its main menu). Keep its path + address instead and look it
-- up again each time: StaticFindObject only finds objects that still exist.
function C.ref(o)
  if not alive(o) then return nil end
  local full = try(function() return o:GetFullName() end)
  local path = type(full) == 'string' and full:match('^%S+%s+(.+)$')
  local a = C.addr(o)
  if not (path and a) then return nil end
  return { path = path, addr = a }
end
function C.deref(r)
  if not r then return nil end
  local o = try(StaticFindObject, r.path)
  if o and alive(o) and C.addr(o) == r.addr then return o end
  return nil
end

-- an object kept between ticks, looked up again (at most every `retry` seconds) once it has gone
-- (wall-clock seconds, so it works whichever loop is running)
local kept = {}
function C.cached(cls, retrySeconds)
  local k = kept[cls]
  local o = k and C.deref(k.r)
  if o then return o end
  if k and os.time() - k.at < (retrySeconds or 2) then return nil end
  o = C.first(cls)
  kept[cls] = { r = C.ref(o), at = os.time() }
  return o
end

-- an asset by path (/Game/.../Name), loading it when needed
function C.asset(path)
  local obj = path:match('([^/]+)$')
  local full = path .. '.' .. obj
  local o = try(StaticFindObject, full)
  if alive(o) then return o end
  try(LoadAsset, full)
  o = try(StaticFindObject, full)
  if alive(o) then return o end
  -- v0.29.4: LoadAsset wants the package path (as MenuRecon and C.uclass load); the full object name loaded nothing
  -- for an asset not yet in memory (the All Rust patina was never found - only the dirt showed)
  try(LoadAsset, path)
  o = try(StaticFindObject, full)
  return alive(o) and o or nil
end
-- a class by full path (/Script/... or /Game/....Name_C)
function C.uclass(path)
  local c = try(StaticFindObject, path)
  if not alive(c) and path:find('^/Game/') then
    try(LoadAsset, (path:gsub('%.[^%.]+_C$', '')))
    c = try(StaticFindObject, path)
  end
  return alive(c) and c or nil
end

-- Run fn every `ms` on the game thread, for as long as the game runs.
-- v0.10: LoopInGameThreadWithDelay, not LoopAsync -> ExecuteInGameThread. The old way made a new game-thread callback
-- from UE4SS's async thread every tick; with several mods doing it every 100 ms UE4SS's callback references got mixed
-- up ("Ref was not function", "FindAllOf cannot be called with 0 parameters") and the game froze or crashed
-- (2026-11-09). The old way is kept only for a UE4SS without the new function.
function C.gameLoop(ms, fn, name)
  local function body()
    local ok, err = pcall(fn)
    if not ok then C.log((name or 'loop') .. ' error: ' .. tostring(err)) end
  end
  if type(LoopInGameThreadWithDelay) == 'function' then
    return LoopInGameThreadWithDelay(ms, body)
  end
  LoopAsync(ms, function() ExecuteInGameThread(body); return false end)
end

local libs = {}
function C.lib(name, pkg)
  local o = libs[name]
  if not alive(o) then
    o = try(StaticFindObject, '/Script/' .. (pkg or 'Engine') .. '.Default__' .. name)
    libs[name] = o
  end
  return alive(o) and o or nil
end

function C.localPC()
  for _, pc in ipairs(C.find('PlayerController')) do
    if try(function() return pc:IsLocalPlayerController() end) == true then return pc end
  end
  return nil
end

function C.commas(n)
  local s = tostring(math.floor(n or 0))
  local out = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
  return (out:gsub('^,', ''))
end
function C.ordinal(n)
  if not n then return '?' end
  local s = ({ 'st', 'nd', 'rd' })[n % 10]
  if not s or (n % 100 >= 11 and n % 100 <= 13) then s = 'th' end
  return n .. s
end

-- Lua table -> source text ("return" not included); plain data only
function C.serialize(v, indent)
  indent = indent or ''
  local t = type(v)
  if t == 'number' or t == 'boolean' then return tostring(v) end
  if t == 'string' then return ('%q'):format(v) end
  if t ~= 'table' then return 'nil' end
  local keys = {}
  for k in pairs(v) do if type(k) == 'string' or type(k) == 'number' then keys[#keys + 1] = k end end
  table.sort(keys, function(a, b)
    if type(a) == type(b) then return a < b end
    return type(a) == 'number'
  end)
  local inner, parts = indent .. '  ', {}
  for _, k in ipairs(keys) do
    local key = (type(k) == 'string' and k:match('^[%a_][%w_]*$')) and k or ('[' .. C.serialize(k) .. ']')
    parts[#parts + 1] = inner .. key .. ' = ' .. C.serialize(v[k], inner) .. ',\n'
  end
  return '{\n' .. table.concat(parts) .. indent .. '}'
end

return C
