-- MenuRecon: read-only property dumps at the main menu (research, 2026-11-10). Test-only, not shipped. Offline only.
-- Files in Mods/MenuRecon/ (checked once a second at the main menu):
--   classes.txt  class names, one per line (e.g. RaceTuneConfig); every live instance is dumped, CDOs marked
--   assets.txt   asset paths, one per line (/Game/...); loaded with LoadAsset and dumped
--   dump.txt     trigger: dump classes.txt + assets.txt into menurecon.log, then the file is removed
-- Reads only. Keeps no UObject between ticks. Only plain property types are read (v1 read everything and crashed the
-- game on GfnGameInstance: soft pointers, delegates and the like must never be touched from Lua).
local DIR = (debug.getinfo(1, 'S').source:match('^@(.*[/\\])Scripts[/\\]') or '')
local LOG = DIR .. 'menurecon.log'

local function try(f, ...)
  local r = table.pack(pcall(f, ...))
  if r[1] then return table.unpack(r, 2, r.n) end
  return nil, tostring(r[2])
end
local function alive(o) return o ~= nil and type(o) == 'userdata' and try(function() return o:IsValid() end) == true end
local out = {}
local function log(m) out[#out + 1] = tostring(m) end
local function flush()
  local f = io.open(LOG, 'a')
  if f then f:write(table.concat(out, '\n') .. '\n'); f:close() end
  out = {}
end
local function nm(o) return alive(o) and (try(function() return o:GetFName():ToString() end) or '?') or '-' end
local function full(o) return alive(o) and (try(function() return o:GetFullName() end) or '?') or '-' end
local function exists(f) local h = io.open(DIR .. f, 'r'); if h then h:close(); return true end; return false end
local function lines(f)
  local t, h = {}, io.open(DIR .. f, 'r')
  if not h then return t end
  for l in h:lines() do l = l:gsub('%s+$', ''); if l ~= '' and not l:match('^#') then t[#t + 1] = l end end
  h:close(); return t
end

-- property types we read; everything else is only named
local PLAIN = { Bool = 1, Int = 1, Int8 = 1, Int16 = 1, Int64 = 1, UInt16 = 1, UInt32 = 1, UInt64 = 1, Float = 1, Double = 1,
  Byte = 1, Enum = 1, Name = 1, Str = 1, Text = 1 }
local function ptype(p) return ((try(function() return p:GetClass():GetFName():ToString() end) or '?'):gsub('Property$', '')) end

local fmtProp
local function fmtPlain(v)
  local t = type(v)
  if t ~= 'userdata' then
    if t == 'number' and v % 1 ~= 0 then return ('%.3f'):format(v) end
    return tostring(v)
  end
  local s = try(function() return v:ToString() end)
  if type(s) == 'string' then return '"' .. s .. '"' end
  return '<' .. tostring(try(function() return v:type() end) or 'userdata') .. '>'
end
local function fmtStruct(v, st, depth)
  if depth > 2 then return '{...}' end
  local parts, n = {}, 0
  try(function()
    st:ForEachProperty(function(p)
      n = n + 1
      if n > 48 then return end
      local pn = p:GetFName():ToString()
      parts[#parts + 1] = pn .. '=' .. fmtProp(p, function() return v[pn] end, depth + 1)
    end)
  end)
  return '{' .. table.concat(parts, ', ') .. '}'
end
-- p: the property; get: a function reading its value (only called for plain types)
fmtProp = function(p, get, depth)
  local pt = ptype(p)
  if PLAIN[pt] then return fmtPlain(try(get)) end
  if pt == 'Object' or pt == 'Class' then
    local v = try(get)
    return alive(v) and ('<' .. full(v) .. '>') or tostring(v)
  end
  if pt == 'Struct' then
    local st = try(function() return p:GetStruct() end)
    local v = try(get)
    if st and v ~= nil then return fmtStruct(v, st, depth) .. ' (' .. nm(st) .. ')' end
    return '<struct>'
  end
  if pt == 'Array' then
    local inner = try(function() return p:GetInner() end)
    local it = inner and ptype(inner) or '?'
    local v = try(get)
    local num = v ~= nil and try(function() return v:GetArrayNum() end) or '?'
    if inner and (PLAIN[it] or it == 'Object' or it == 'Class' or it == 'Struct') and depth <= 2 and type(num) == 'number' then
      local items = {}
      try(function() v:ForEach(function(i, el)
        if #items < 20 then items[#items + 1] = fmtProp(inner, function() return el:get() end, depth + 1) end
      end) end)
      return ('[%s x%s: %s%s]'):format(it, num, table.concat(items, ', '), num > 20 and ', ...' or '')
    end
    return ('[%s x%s]'):format(it, tostring(num))
  end
  return '<' .. pt .. '>'
end

local function dumpObject(o, label)
  log(('%s %s'):format(label or '-', full(o)))
  local cls = try(function() return o:GetClass() end)
  local seen, chain = {}, 0
  while alive(cls) and chain < 12 do
    chain = chain + 1
    local cn = nm(cls)
    local props = {}
    try(function()
      cls:ForEachProperty(function(p)
        local pn = p:GetFName():ToString()
        if not seen[pn] then
          seen[pn] = true
          props[#props + 1] = ('    %s (%s) = %s'):format(pn, ptype(p), fmtProp(p, function() return o[pn] end, 0))
        end
      end)
    end)
    if #props > 0 then
      log('  [' .. cn .. ']')
      for _, l in ipairs(props) do log(l) end
    end
    flush()
    if cn == 'Object' or cn == 'Actor' or cn == 'ActorComponent' then break end
    cls = try(function() return cls:GetSuperStruct() end)
  end
end

local function dumpClass(c)
  local got = try(FindAllOf, c)
  local list = type(got) == 'table' and got or {}
  log(('== class %s: %d objects'):format(c, #list)); flush()
  local n = 0
  for _, o in ipairs(list) do
    if alive(o) then
      n = n + 1
      if n > 30 then log('  ... more'); break end
      dumpObject(o, nm(o):find('^Default__') and '  CDO' or '  obj')
    end
  end
  flush()
end

local function asset(path)
  local full_ = path:find('%.') and path or (path .. '.' .. path:match('([^/]+)$'))
  local o = try(StaticFindObject, full_)
  if alive(o) then return o end
  try(LoadAsset, (full_:gsub('%..*$', '')))
  o = try(StaticFindObject, full_)
  return alive(o) and o or nil
end
local function dumpAsset(path)
  local o = asset(path)
  if not o then log('== asset ' .. path .. ': not found'); flush(); return end
  log('== asset ' .. path); flush()
  dumpObject(o, '  asset')
  local cdo = try(function() return o:GetClassDefaultObject() end)
  if alive(cdo) then dumpObject(cdo, '  CDO') end
  flush()
end

local function atMenu()
  local got = try(FindAllOf, 'FrontEndGameMode')
  for _, o in ipairs(type(got) == 'table' and got or {}) do if alive(o) and not nm(o):find('^Default__') then return true end end
  return false
end

local busy = false
LoopAsync(1000, function()
  if busy or not exists('dump.txt') then return false end
  busy = true
  ExecuteInGameThread(function()
    local ok, err = pcall(function()
      os.remove(DIR .. 'dump.txt')
      log(os.date('%H:%M:%S') .. ' dump: at menu = ' .. tostring(atMenu())); flush()
      for _, c in ipairs(lines('classes.txt')) do dumpClass(c) end
      for _, p in ipairs(lines('assets.txt')) do dumpAsset(p) end
      log(os.date('%H:%M:%S') .. ' dump done'); flush()
    end)
    if not ok then log('dump error: ' .. tostring(err)); flush() end
    busy = false
  end)
  return false
end)
