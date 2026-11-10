-- Galactic Grand Prix: your mods (v0.4, DESIGN.md §5b). Pure logic (tested in test/test_modsel.lua).
-- Your picks are four slots { key or false, ... } (keys from mods.lua); the class opens the first N slots (config
-- Classes[].mods: 50cc 0, 100cc 2, 150cc 3, 200cc 4). One mod per effect. Each mod at its top step (owner).
local cfg = require('config')
local DATA = require('mods')

local MS = {}
MS.MAX = 4
local BY = {}
for _, e in ipairs(DATA.effects) do BY[e.key] = e end
function MS.groups() return DATA.groups end
function MS.effect(key) return key and BY[key] or nil end
function MS.slotsFor(classKey)
  for _, c in ipairs(cfg.Classes or {}) do if c.key == classKey then return math.min(MS.MAX, c.mods or 0) end end
  return 0
end

-- picks made valid: four slots, unknown keys and repeats emptied (false)
function MS.normalize(list)
  local out, seen = {}, {}
  for i = 1, MS.MAX do
    local k = type(list) == 'table' and list[i] or nil
    if type(k) == 'string' and BY[k] and not seen[k] then out[i] = k; seen[k] = true else out[i] = false end
  end
  return out
end

-- the effects of a group you can put in slot i (those already in another slot are left out)
function MS.choices(group, list, slot)
  local taken = {}
  for i = 1, MS.MAX do if i ~= slot and list[i] then taken[list[i]] = true end end
  local out = {}
  for _, e in ipairs(DATA.effects) do if e.group == group and not taken[e.key] then out[#out + 1] = e end end
  return out
end
function MS.count(group) local n = 0; for _, e in ipairs(DATA.effects) do if e.group == group then n = n + 1 end end; return n end

-- the mods that race with you at a class: the set ones in the open slots
function MS.active(list, classKey)
  local out = {}
  for i = 1, MS.slotsFor(classKey) do local e = MS.effect(list and list[i]); if e then out[#out + 1] = e end end
  return out
end
function MS.paths(list, classKey)
  local out = {}
  for _, e in ipairs(MS.active(list, classKey)) do out[#out + 1] = e.path end
  return out
end
function MS.names(list, classKey)
  local out = {}
  for _, e in ipairs(MS.active(list, classKey)) do out[#out + 1] = e.name end
  return out
end
-- the affix asset name of a path ('AFX_X_v3') - what a race copy's slot shows
function MS.assetName(path) return tostring(path):match('([^/.]+)$') end

return MS
