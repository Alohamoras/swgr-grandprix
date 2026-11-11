-- Galactic Grand Prix: progression - which classes and cups are open (DESIGN.md §8, v0.5). Pure logic, worked out
-- from the saved best finishes every time (nothing extra saved), so trophies won before v0.5 count and RESET
-- PROGRESS locks everything again.
--   Classes: those with `open = true` are open from the start (50cc, 100cc - owner, 2026-11-10). Each other class
--     opens with a trophy (or gold: Progression.Unlock) in every planet cup of the class before it.
--   Bonus cups (`bonus = true`: Outer Rim, Galactic): gold in every planet cup at that class.
--   Remix cups (`remix = true`, v0.6.2): a trophy (or gold: Unlock) in every planet cup at Progression.RemixClass
--     (owner 2026-11-10: the class before the top one, 150cc; the summit gates nothing); then open at every open
--     class.
--   Conditions cups (`conditions = true`, planet = a planet cup's key): gold in that planet's cup at that class,
--     per cup and per class.
--   Kept: a class or cup you have already raced through (a best finish) or have a cup in progress in stays open,
--     so v0.5 never takes away what you were playing.
local cfg = require('config')

local P = {}
local function conf() return cfg.Progression or {} end
function P.on() return conf().On ~= false end

local function bestOf(data, classKey, cupKey) return ((data.best or {})[classKey] or {})[cupKey] end
local function planetCups()
  local out = {}
  for _, c in ipairs(cfg.Cups or {}) do if not (c.bonus or c.remix or c.conditions) then out[#out + 1] = c end end
  return out
end
local function cupByKey(key) for _, c in ipairs(cfg.Cups or {}) do if c.key == key then return c end end return nil end
local function classByKey(key) for _, c in ipairs(cfg.Classes or {}) do if c.key == key then return c end end return nil end
local function className(key) local c = classByKey(key); return c and c.name or key end
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
  local cup = cupByKey(cupKey)
  if not (cup and (cup.bonus or cup.remix or cup.conditions)) then return true end
  if raced(data, classKey, cupKey) then return true end
  if cup.remix then
    local ok, why = P.remixOpen(data)
    return ok, why
  end
  if cup.conditions then
    local ok, why = P.conditionsOpen(data, classKey, cupKey)
    return ok, why
  end
  local n, of = count(data, classKey, 1)
  if n >= of then return true end
  return false, ('Gold in all %d planet cups at %s (%d / %d)'):format(of, className(classKey), n, of)
end

-- the class whose planet-cup trophies open the remix cups: Progression.RemixClass, else the one before the top
function P.remixClass()
  local list = cfg.Classes or {}
  local c = conf().RemixClass and classByKey(conf().RemixClass)
  return c or list[math.max(1, #list - 1)]
end

-- the remix cups: a trophy (or gold: Unlock) in every planet cup at the remix class -> open, why
function P.remixOpen(data)
  if not P.on() then return true end
  local at = P.remixClass()
  if not at then return true end
  local gold = conf().Unlock == 'gold'
  local n, of = count(data, at.key, gold and 1 or 3)
  if n >= of then return true end
  return false, ('%s in all %d planet cups at %s (%d / %d)'):format(gold and 'Gold' or 'A trophy', of, at.name, n, of)
end

-- a conditions cup at a class: gold in its planet's cup at that class -> open, why (the class lock is not checked
-- here: cupOpen does that)
function P.conditionsOpen(data, classKey, cupKey)
  if not P.on() then return true end
  local cup = cupByKey(cupKey)
  local planet = cup and cup.planet and cupByKey(cup.planet)
  if not planet then return true end
  local b = bestOf(data, classKey, planet.key)
  if b and b <= 1 then return true end
  return false, ('Gold in the %s at %s'):format(planet.name, className(classKey))
end

-- the title race at a class (v0.8, title.lua): a trophy (or gold: Unlock) in every planet cup at that class; once
-- raced (a result saved under titles[class]) it stays open -> open, why
function P.titleOpen(data, classKey)
  if not P.on() then return true end
  local okC, whyC = P.classOpen(data, classKey)
  if not okC then return false, whyC end
  if ((data.titles or {})[classKey] or {}).tries then return true end
  local gold = conf().Unlock == 'gold'
  local n, of = count(data, classKey, gold and 1 or 3)
  if n >= of then return true end
  return false, ('%s in all %d planet cups at %s (%d / %d)'):format(gold and 'Gold' or 'A trophy', of, className(classKey), n, of)
end

-- everything open, as a set of names ('150cc', 'OUTER RIM CUP at 100cc', 'JAKKU CONDITIONS at 100cc') - compared
-- before / after a cup to say what it unlocked
function P.openSet(data)
  local s = {}
  for _, c in ipairs(cfg.Classes or {}) do
    if P.classOpen(data, c.key) then
      s[c.name] = true
      for _, cup in ipairs(cfg.Cups or {}) do
        if (cup.bonus or cup.conditions) and P.cupOpen(data, c.key, cup.key) then s[cup.name .. ' at ' .. c.name] = true end
      end
    end
  end
  if P.remixOpen(data) then s['REMIX CUPS'] = true end
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
  if after['REMIX CUPS'] and not before['REMIX CUPS'] then out[#out + 1] = 'REMIX CUPS' end
  return out
end

return P
