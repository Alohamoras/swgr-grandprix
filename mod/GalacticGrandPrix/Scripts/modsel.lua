-- Galactic Grand Prix: your tune-ups (v0.8; was the v0.4-0.6 mod picker). Pure logic (test/test_modsel.lua).
-- A tune-up is a named package of one to three catalogue affixes (config TuneUps, keys from mods.lua). Your picks are
-- MS.MAX slots { package key or false, ... }, kept in the save (data.mods); the league opens the first N (config
-- Leagues[].mods: Riff-Raff 0, Challenger 1, Ace 2). One package per slot, never the same one twice. Picked in place on the
-- garage tile: MS.cycle gives the next / previous package for a slot, MS.line its one-line description (the info line).
local cfg = require('config')
local DATA = require('mods')
local okC, C = pcall(require, 'core')
local function log(m) if okC and type(C) == 'table' and C.log then C.log(m) end end

local MS = {}
MS.MAX = 2

local BY = {} -- the catalogue's effects by key
for _, e in ipairs(DATA.effects) do BY[e.key] = e end

-- the packages, in config order: { key, name, line, group, tag, mods = { catalogue keys }, affixes = { effects },
-- paths = { affix object paths }, missing = { unknown catalogue keys } }. desc = line (what a tile's text shows).
local PK, LIST, GROUPS = {}, {}, {}
for _, p in ipairs(cfg.TuneUps or {}) do
  local pkg = { key = p.key, name = p.name or p.key, line = p.line or '', group = p.group, mods = {}, affixes = {}, paths = {}, missing = {} }
  pkg.desc = pkg.line
  local protect = true
  for _, k in ipairs(p.mods or {}) do
    local e = BY[k]
    pkg.mods[#pkg.mods + 1] = k
    if e then
      pkg.affixes[#pkg.affixes + 1] = e
      pkg.paths[#pkg.paths + 1] = e.path
      if e.tag ~= 'protect' then protect = false end
      pkg.group = pkg.group or e.group
    else
      pkg.missing[#pkg.missing + 1] = k
      log(('[tune-ups] %s: unknown mod %s (not in the catalogue)'):format(pkg.name, k))
    end
  end
  pkg.tag = (#pkg.affixes > 0 and protect) and 'protect' or 'style'
  if pkg.key and not PK[pkg.key] then
    PK[pkg.key] = pkg
    LIST[#LIST + 1] = pkg
    if pkg.group then
      local seen = false
      for _, g in ipairs(GROUPS) do if g == pkg.group then seen = true end end
      if not seen then GROUPS[#GROUPS + 1] = pkg.group end
    end
  end
end

function MS.all() return LIST end
function MS.effect(key) return key and PK[key] or nil end -- the package (name, line, affixes, paths, tag, group)
function MS.line(key) local p = MS.effect(key); return p and p.line or '' end
function MS.catalogue(key) return key and BY[key] or nil end -- a catalogue affix by its key (tests, the AI's lists)
function MS.slotsFor(classKey)
  for _, c in ipairs(cfg.Leagues or {}) do if c.key == classKey then return math.min(MS.MAX, c.mods or 0) end end
  return 0
end

-- picks made valid: MS.MAX slots; unknown keys (the v0.6 catalogue keys of an old save) and repeats emptied (false)
function MS.normalize(list)
  local out, seen, dropped = {}, {}, {}
  for i = 1, MS.MAX do
    local k = type(list) == 'table' and list[i] or nil
    if type(k) == 'string' and PK[k] and not seen[k] then out[i] = k; seen[k] = true
    else
      out[i] = false
      if type(k) == 'string' and not PK[k] then dropped[#dropped + 1] = k end
    end
  end
  if type(list) == 'table' then
    for i = MS.MAX + 1, #list do if type(list[i]) == 'string' and not PK[list[i]] then dropped[#dropped + 1] = list[i] end end
  end
  if #dropped > 0 then log('[tune-ups] dropped from the save (not tune-ups): ' .. table.concat(dropped, ', ')) end
  return out
end

-- the packages fitted in the OTHER slots
local function taken(list, slot)
  local t = {}
  for i = 1, MS.MAX do if i ~= slot and type(list) == 'table' and list[i] then t[list[i]] = true end end
  return t
end

-- the next (dir = 1) or previous (dir = -1) choice for a slot, cycling through "empty" and every package not fitted in
-- another slot. Returns the new value for list[slot]: a package key, or false for empty. (Pure: the caller stores it.)
function MS.cycle(list, slot, dir)
  local skip = taken(list, slot)
  local ring = { false }
  for _, p in ipairs(LIST) do if not skip[p.key] then ring[#ring + 1] = p.key end end
  local cur = type(list) == 'table' and list[slot] or false
  local at = 1
  for i, k in ipairs(ring) do if k == cur then at = i end end
  local step = (dir or 1) < 0 and -1 or 1
  return ring[(at - 1 + step) % #ring + 1]
end

-- the packages of a group you can put in slot i (those in another slot left out). groups(): the distinct groups, in
-- order. (The v0.6 MODS screens still run on these until the garage tile replaces them.)
function MS.groups() return GROUPS end
function MS.choices(group, list, slot)
  local skip = taken(list, slot)
  local out = {}
  for _, p in ipairs(LIST) do if (group == nil or p.group == group) and not skip[p.key] then out[#out + 1] = p end end
  return out
end
function MS.count(group) return #MS.choices(group, nil, 0) end

-- the packages that race with you at a class: the set ones in the open slots
function MS.active(list, classKey)
  local out = {}
  for i = 1, MS.slotsFor(classKey) do local p = MS.effect(type(list) == 'table' and list[i]); if p then out[#out + 1] = p end end
  return out
end
function MS.fitted(list, classKey)
  local out = {}
  for _, p in ipairs(MS.active(list, classKey)) do out[#out + 1] = p.key end
  return out
end
function MS.names(list, classKey)
  local out = {}
  for _, p in ipairs(MS.active(list, classKey)) do out[#out + 1] = p.name end
  return out
end
-- the affix object paths of a list of package keys (each once), and of your fitted packages at a class
function MS.pathsOf(keys)
  local out, seen = {}, {}
  for _, k in ipairs(keys or {}) do
    for _, path in ipairs((MS.effect(k) or {}).paths or {}) do
      if not seen[path] then seen[path] = true; out[#out + 1] = path end
    end
  end
  return out
end
function MS.paths(list, classKey) return MS.pathsOf(MS.fitted(list, classKey)) end
-- the affix asset name of a path ('AFX_X_v3') - what a race copy's slot shows; and the set of them for package keys
function MS.assetName(path) return tostring(path):match('([^/.]+)$') end
function MS.assetNames(keys)
  local set = {}
  for _, path in ipairs(MS.pathsOf(keys)) do set[MS.assetName(path)] = true end
  return set
end
-- package names joined for a log line ('HEAT SHIELD+ARMOUR', or 'none')
function MS.label(keys)
  local names = {}
  for _, k in ipairs(keys or {}) do local p = MS.effect(k); if p then names[#names + 1] = p.name end end
  return #names > 0 and table.concat(names, '+') or 'none'
end

return MS
