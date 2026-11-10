-- A fake UE4SS + game environment for running the Galactic Underground mod in plain Lua 5.4.
-- Catches nil errors, logic bugs and save/flow mistakes without the game. It does NOT prove engine calls work.
local M = { calls = {}, binds = {}, loops = {}, objects = {}, nextAddr = 1000, log = {} }

local function record(name, ...) M.calls[#M.calls + 1] = { name = name, args = { ... } } end
function M.called(name)
  local n = 0
  for _, c in ipairs(M.calls) do if c.name == name then n = n + 1 end end
  return n
end
function M.lastCall(name)
  for i = #M.calls, 1, -1 do if M.calls[i].name == name then return M.calls[i] end end
end

-- generic object: known fields from `props`, methods from `props` (functions get self), unknown -> a callable mock
local Obj = {}
local function callable(owner, key)
  return setmetatable({}, { __call = function(_, self, ...)
    record(key, ...)
    return M.new('ret:' .. key)
  end, __index = function() return nil end })
end
function M.new(name, props, cls)
  local o = { __name = name, __cls = cls or name, __props = props or {}, __addr = M.nextAddr }
  M.nextAddr = M.nextAddr + 1
  return setmetatable(o, Obj)
end
-- touching a freed object (even IsValid) is what crashes the real game: count it (M.deadTouches) so tests can check
M.deadTouches, M.deadLog = 0, {}
Obj.__index = function(o, k)
  if rawget(o, '__dead') and rawget(o, '__name') ~= 'null' then
    M.deadTouches = M.deadTouches + 1
    M.deadLog[#M.deadLog + 1] = rawget(o, '__name') .. '.' .. tostring(k) .. '\n' .. debug.traceback('', 2)
  end
  local p = rawget(o, '__props')
  if p[k] ~= nil then return p[k] end
  local base = Obj.methods[k]
  if base then return base end
  return callable(o, k)
end
Obj.__newindex = function(o, k, v) rawget(o, '__props')[k] = v end
Obj.methods = {
  IsValid = function(o) return rawget(o, '__dead') ~= true end,
  GetFName = function(o) local n = rawget(o, '__name'); return { ToString = function() return n end } end,
  GetClass = function(o) local c = rawget(o, '__cls'); return M.new(c, { GetFName = function() return { ToString = function() return c end } end }) end,
  GetAddress = function(o) return rawget(o, '__addr') end,
  GetFullName = function(o) return rawget(o, '__cls') .. ' ' .. rawget(o, '__name') end,
  ToString = function(o) return rawget(o, '__props').__text or rawget(o, '__name') end,
}

-- TMap<int,int> and TArray helpers
function M.tmap(t)
  local store = t or {}
  return {
    __store = store,
    ForEach = function(self, fn)
      local keys = {}
      for k in pairs(store) do keys[#keys + 1] = k end
      table.sort(keys)
      for _, k in ipairs(keys) do
        fn({ get = function() return k end }, { get = function() return store[k] end, set = function(_, v) store[k] = v end })
      end
    end,
    Add = function(self, k, v) store[k] = v end,
    Remove = function(self, k) store[k] = nil end,
  }
end
function M.tarray(list)
  return { ForEach = function(self, fn) for i, v in ipairs(list) do fn(i, { get = function() return v end }) end end,
    GetArrayNum = function() return #list end }
end

-- a TArray you can index and assign (arr[i], arr[i] = v), like UE4SS's
function M.tarr(list)
  local a = { __list = list }
  return setmetatable(a, {
    __index = function(_, k)
      if type(k) == 'number' then return list[k] end
      if k == 'GetArrayNum' then return function() return #list end end
      if k == 'ForEach' then return function(_, fn) for i, v in ipairs(list) do fn(i, { get = function() return v end }) end end end
      return nil
    end,
    __newindex = function(_, k, v) if type(k) == 'number' then list[k] = v end end,
  })
end

-- registry used by FindAllOf / StaticFindObject
function M.add(cls, obj) M.objects[cls] = M.objects[cls] or {}; table.insert(M.objects[cls], obj); return obj end
function M.clear(cls) M.objects[cls] = {} end
function M.kill(obj) rawset(obj, '__dead', true) end
M.assets = {}

function M.install()
  _G.FindAllOf = function(cls)
    local out = {}
    for _, o in ipairs(M.objects[cls] or {}) do if rawget(o, '__dead') ~= true then out[#out + 1] = o end end
    return #out > 0 and out or nil
  end
  _G.FindFirstOf = function(cls) local l = FindAllOf(cls); return l and l[1] end
  _G.StaticFindObject = function(path)
    -- a live registered object by its name (what C.ref / C.deref look up); dead ones are gone, like after a GC
    local deadMatch = false
    for _, list in pairs(M.objects) do
      for _, o in ipairs(list) do
        if rawget(o, '__name') == path then
          if not rawget(o, '__dead') then return o end
          deadMatch = true
        end
      end
    end
    if deadMatch then local n = M.new('null', {}, 'null'); rawset(n, '__dead', true); return n end
    if M.assets[path] then return M.assets[path] end
    local n = path:match('([^%./]+)$') or path
    -- a Blueprint class (/Game/...BP_X.BP_X_C) is a BlueprintGeneratedClass
    local o = M.new(n, {}, n:find('_C$') and 'BlueprintGeneratedClass' or path)
    M.assets[path] = o
    return o
  end
  _G.LoadAsset = function(path) record('LoadAsset', path) end
  _G.StaticConstructObject = function(cls, outer) return M.new('constructed', {}) end
  _G.CreateInvalidObject = function() local o = M.new('null', {}, 'None'); rawset(o, '__dead', true); return o end
  _G.FText = function(s) return M.new('FText', { __text = s }) end
  _G.FName = function(s) return s end
  _G.Key = setmetatable({}, { __index = function(_, k) return k end })
  _G.ModifierKey = { CONTROL = 'CTRL', SHIFT = 'SHIFT', ALT = 'ALT' }
  _G.RegisterKeyBind = function(k, a, b)
    local fn = b or a
    local mods = b and a or nil
    M.binds[#M.binds + 1] = { key = k, mods = mods, fn = fn }
  end
  _G.LoopAsync = function(ms, fn) M.loops[#M.loops + 1] = { ms = ms, fn = fn, live = true } end
  _G.LoopInGameThreadWithDelay = function(ms, fn) M.loops[#M.loops + 1] = { ms = ms, fn = function() fn() end, live = true }; return #M.loops end
  _G.ExecuteInGameThread = function(fn) record('ExecuteInGameThread'); fn() end
  _G.ExecuteWithDelay = function(ms, fn) fn() end
  -- NotifyOnNewObject(class path, fn): M.fireNew(path, obj) calls them (world.lua does for the main menu)
  M.notifies = {}
  _G.NotifyOnNewObject = function(path, fn) M.notifies[path] = M.notifies[path] or {}; table.insert(M.notifies[path], fn) end
  _G.print = function(s) M.log[#M.log + 1] = s end
  M.hooks = {}
  _G.RegisterHook = function(name, fn) M.hooks[name] = M.hooks[name] or {}; table.insert(M.hooks[name], fn) end
end

function M.fireNew(path, obj) for _, fn in ipairs(M.notifies[path] or {}) do fn(obj) end end
function M.fire(name, ctx) for _, fn in ipairs(M.hooks[name] or {}) do fn(ctx) end end
-- press a bound key (no modifiers)
function M.press(key)
  local hit = false
  for _, b in ipairs(M.binds) do if b.key == key and not b.mods then b.fn(); hit = true end end
  return hit
end
-- run the async loops n times
function M.tick(n)
  for _ = 1, n or 1 do
    for _, l in ipairs(M.loops) do
      if l.live then if l.fn() == true then l.live = false end end
    end
  end
end
return M
