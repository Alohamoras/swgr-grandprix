-- Galactic Grand Prix: progression - which classes and cups are open (DESIGN.md §8, v0.5). Pure logic, worked out
-- from the saved best finishes every time (nothing extra saved), so trophies won before v0.5 count and RESET
-- PROGRESS locks everything again.
--   Classes: those with `open = true` are open from the start (50cc, 100cc - owner, 2026-11-10). Each other class
--     opens with a trophy (or gold: Progression.Unlock) in every planet cup of the class before it.
--   Bonus cups (`bonus = true`: Outer Rim, Galactic): gold in every planet cup at that class.
--   Kept: a class or cup you have already raced through (a best finish) or have a cup in progress in stays open,
--     so v0.5 never takes away what you were playing.
local cfg = require('config')

local P = {}
local function conf() return cfg.Progression or {} end
function P.on() return conf().On ~= false end

local function bestOf(data, classKey, cupKey) return ((data.best or {})[classKey] or {})[cupKey] end
local function planetCups()
  local out = {}
  for _, c in ipairs(cfg.Cups or {}) do if not c.bonus then out[#out + 1] = c end end
  return out
end
local function className(key) for _, c in ipairs(cfg.Classes or {}) do if c.key == key then return c.name end end return key end
-- how many planet cups at a class have a result at least `need` (1 = gold, 3 = any trophy)
local function count(data, classKey, need)
  local n, all = 0, planetCups()
  for _, c in ipairs(all) do
    local b = bestOf(data, classKey, c.key)
    if b and b <= need then n = n + 1 end
  end
  return n, #all
end
local function raced(data, classKey, cupKey)
  local run = data.run
  if run and run.class == classKey and (cupKey == nil or run.cup == cupKey) then return true end
  if cupKey then return bestOf(data, classKey, cupKey) ~= nil end
  return next((data.best or {})[classKey] or {}) ~= nil
end

-- is a class open? -> open, why (the text for a locked tile: what opens it)
function P.classOpen(data, classKey)
  if not P.on() then return true end
  local list, prev = cfg.Classes or {}, nil
  for i, c in ipairs(list) do
    if c.key == classKey then
      if c.open or i == 1 then return true end
      prev = list[i - 1]
      break
    end
  end
  if not prev then return true end
  if raced(data, classKey) then return true end
  local gold = conf().Unlock == 'gold'
  local n, of = count(data, prev.key, gold and 1 or 3)
  if n >= of then return true end
  return false, ('%s in all %d planet cups at %s (%d / %d)'):format(gold and 'Gold' or 'A trophy', of, prev.name, n, of)
end

-- is a cup open at a class? (the class must be open too) -> open, why
function P.cupOpen(data, classKey, cupKey)
  if not P.on() then return true end
  local okC, whyC = P.classOpen(data, classKey)
  if not okC then return false, whyC end
  local cup
  for _, c in ipairs(cfg.Cups or {}) do if c.key == cupKey then cup = c end end
  if not (cup and cup.bonus) then return true end
  if raced(data, classKey, cupKey) then return true end
  local n, of = count(data, classKey, 1)
  if n >= of then return true end
  return false, ('Gold in all %d planet cups at %s (%d / %d)'):format(of, className(classKey), n, of)
end

-- everything open, as a set of names ('150cc', 'Outer Rim Cup at 100cc') - compared before / after a cup to say
-- what it unlocked
function P.openSet(data)
  local s = {}
  for _, c in ipairs(cfg.Classes or {}) do
    if P.classOpen(data, c.key) then
      s[c.name] = true
      for _, cup in ipairs(cfg.Cups or {}) do
        if cup.bonus and P.cupOpen(data, c.key, cup.key) then s[cup.name .. ' at ' .. c.name] = true end
      end
    end
  end
  return s
end
-- what's open in `after` and wasn't in `before`, in config order (classes first)
function P.newlyOpen(before, after)
  local out = {}
  for _, c in ipairs(cfg.Classes or {}) do
    if after[c.name] and not before[c.name] then out[#out + 1] = c.name end
  end
  for _, c in ipairs(cfg.Classes or {}) do
    for _, cup in ipairs(cfg.Cups or {}) do
      local k = cup.name .. ' at ' .. c.name
      if after[k] and not before[k] then out[#out + 1] = k end
    end
  end
  return out
end

return P
