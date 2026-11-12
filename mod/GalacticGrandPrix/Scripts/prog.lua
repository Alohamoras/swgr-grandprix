-- Galactic Grand Prix: progression - which leagues and cups are open (DESIGN.md §8, v0.5). Pure logic, worked out
-- from the saved best finishes every time (nothing extra saved), so trophies won before v0.5 count and RESET
-- PROGRESS locks everything again.
--   Leagues (v0.26): those with `open = true` are open from the start (Riff-Raff - owner, 2026-11-12). Each other league
--     opens with a trophy (or gold: Progression.Unlock) in every planet cup of the league before it (Challenger from
--     Riff-Raff, Ace from Challenger).
--   The Galactic Cup (`final = true`, v0.11): a trophy (or gold: Unlock) in every planet cup at that class.
--   The title race (title.lua, v0.11): a trophy (or gold: Unlock) in the Galactic Cup at that class.
--   Kept: a class or cup you have already raced through (a best finish) or have a cup in progress in stays open,
--     so v0.5 never takes away what you were playing.
-- (v0.26: a league is what was a speed class; the code and the save keep the word "class" for it)
local cfg = require('config')

local P = {}
local function conf() return cfg.Progression or {} end
function P.on() return conf().On ~= false end

local function bestOf(data, classKey, cupKey) return ((data.best or {})[classKey] or {})[cupKey] end
local function planetCups()
  local out = {}
  for _, c in ipairs(cfg.Cups or {}) do if not c.final then out[#out + 1] = c end end
  return out
end
local function cupByKey(key) for _, c in ipairs(cfg.Cups or {}) do if c.key == key then return c end end return nil end
local function classByKey(key) for _, c in ipairs(cfg.Leagues or {}) do if c.key == key then return c end end return nil end
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

-- v0.14: the short form of what opens a locked thing, for its tile ('5 trophies at RIFF-RAFF'; the full why goes in the
-- screen's info line)
local function shortCount(gold, of, name) return ('%d %s at %s'):format(of, gold and 'golds' or 'trophies', name) end
local function titleCase(s) return (tostring(s):lower():gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end)) end

-- is a class open? -> open, why (the text for a locked tile's info: what opens it), short (the same for the tile)
function P.classOpen(data, classKey)
  if not P.on() then return true end
  local list, prev = cfg.Leagues or {}, nil
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
  return false, ('%s in all %d planet cups at %s (%d / %d)'):format(gold and 'Gold' or 'A trophy', of, prev.name, n, of),
    shortCount(gold, of, prev.name)
end

-- is a cup open at a class? (the class must be open too) -> open, why, short
function P.cupOpen(data, classKey, cupKey)
  if not P.on() then return true end
  local okC, whyC, shortC = P.classOpen(data, classKey)
  if not okC then return false, whyC, shortC end
  local cup = cupByKey(cupKey)
  if not (cup and cup.final) then return true end
  if raced(data, classKey, cupKey) then return true end
  local gold = conf().Unlock == 'gold'
  local n, of = count(data, classKey, gold and 1 or 3)
  if n >= of then return true end
  return false, ('%s in all %d planet cups at %s (%d / %d)'):format(gold and 'Gold' or 'A trophy', of, className(classKey), n, of),
    shortCount(gold, of, className(classKey))
end

-- the finale cup (the Galactic Cup), or nil
local function finalCup() for _, c in ipairs(cfg.Cups or {}) do if c.final then return c end end return nil end

-- the title race at a class (v0.8, title.lua; v0.11): a trophy (or gold: Unlock) in the Galactic Cup at that class;
-- once raced (a result saved under titles[class]) it stays open -> open, why, short
function P.titleOpen(data, classKey)
  if not P.on() then return true end
  local okC, whyC, shortC = P.classOpen(data, classKey)
  if not okC then return false, whyC, shortC end
  if ((data.titles or {})[classKey] or {}).tries then return true end
  local fin = finalCup()
  if not fin then return true end
  local gold = conf().Unlock == 'gold'
  local b = bestOf(data, classKey, fin.key)
  if b and b <= (gold and 1 or 3) then return true end
  return false, ('%s in the %s at %s'):format(gold and 'Gold' or 'A trophy', fin.name, className(classKey)),
    ('%s %s'):format(titleCase(fin.name), gold and 'gold' or 'trophy')
end

-- everything open, as a set of names ('CHALLENGER', 'GALACTIC CUP at RIFF-RAFF', 'TITLE RACE at RIFF-RAFF') - compared before /
-- after a cup to say what it unlocked
function P.openSet(data)
  local s = {}
  for _, c in ipairs(cfg.Leagues or {}) do
    if P.classOpen(data, c.key) then
      s[c.name] = true
      for _, cup in ipairs(cfg.Cups or {}) do
        if cup.final and P.cupOpen(data, c.key, cup.key) then s[cup.name .. ' at ' .. c.name] = true end
      end
      if P.titleOpen(data, c.key) then s['TITLE RACE at ' .. c.name] = true end
    end
  end
  return s
end
-- what's open in `after` and wasn't in `before`, in config order (classes first)
function P.newlyOpen(before, after)
  local out = {}
  for _, c in ipairs(cfg.Leagues or {}) do
    if after[c.name] and not before[c.name] then out[#out + 1] = c.name end
  end
  for _, c in ipairs(cfg.Leagues or {}) do
    for _, cup in ipairs(cfg.Cups or {}) do
      local k = cup.name .. ' at ' .. c.name
      if after[k] and not before[k] then out[#out + 1] = k end
    end
    local k = 'TITLE RACE at ' .. c.name
    if after[k] and not before[k] then out[#out + 1] = k end
  end
  return out
end

---------------------------------------------------------------------------------------------------------------------
-- v0.20 (menu review 1b / 4b, docs/PHILOSOPHY.md point 6: "one thing just out of reach"): the nearest unlock, worked
-- out from the same rules as above (nothing new): what is still locked that this class's results open, and how many
-- more trophies (or golds: Unlock) that takes. Pure; the menus put 'Next: ' in front.
local function titleOn() return (cfg.Title or {}).On ~= false end
local function joinNames(list)
  if #list <= 1 then return list[1] or '' end
  return table.concat(list, ', ', 1, #list - 1) .. ' and ' .. list[#list]
end
-- -> nil (nothing locked that this class opens), or { need = n, opens = { names }, cup = the one cup still needed
-- (need 1) or nil, class = classKey, text = '2 more trophies at RIFF-RAFF open the GALACTIC CUP and CHALLENGER' / 'a trophy
-- in the Ando Cup at CHALLENGER opens the GALACTIC CUP' / 'a trophy in the Galactic Cup at RIFF-RAFF opens the TITLE RACE' }
function P.nextUnlock(data, classKey)
  if not P.on() or not P.classOpen(data, classKey) then return nil end
  local gold = conf().Unlock == 'gold'
  local word = gold and 'gold' or 'trophy'
  local cname = className(classKey)
  local fin = finalCup()
  local cands = {}
  -- the planet cups' count: the Galactic Cup here, and the next class
  local n, of = count(data, classKey, gold and 1 or 3)
  if n < of then
    local opens = {}
    if fin and not P.cupOpen(data, classKey, fin.key) then opens[#opens + 1] = fin.name end
    local list = cfg.Leagues or {}
    for i, c in ipairs(list) do
      if c.key == classKey and list[i + 1] and not P.classOpen(data, list[i + 1].key) then opens[#opens + 1] = list[i + 1].name end
    end
    if #opens > 0 then
      local need, missing = of - n, nil
      if need == 1 then
        for _, c in ipairs(planetCups()) do
          local b = bestOf(data, classKey, c.key)
          if not (b and b <= (gold and 1 or 3)) then missing = c.name end
        end
      end
      local text
      if missing then
        text = ('a %s in the %s at %s opens the %s'):format(word, titleCase(missing), cname, joinNames(opens))
      else
        text = ('%d more %s at %s open the %s'):format(need, gold and 'golds' or 'trophies', cname, joinNames(opens))
      end
      cands[#cands + 1] = { need = need, opens = opens, cup = missing, class = classKey, text = text }
    end
  end
  -- the title race: a trophy in the Galactic Cup (once that cup is open)
  if titleOn() and fin and P.cupOpen(data, classKey, fin.key) and not P.titleOpen(data, classKey) then
    cands[#cands + 1] = { need = 1, opens = { 'TITLE RACE' }, cup = fin.name, class = classKey,
      text = ('a %s in the %s at %s opens the TITLE RACE'):format(word, titleCase(fin.name), cname) }
  end
  table.sort(cands, function(a, b) return a.need < b.need end)
  return cands[1]
end

-- HOME's goal: the nearest unlock over the open classes (fewest results needed; ties: the class `prefer`, then the
-- first); with nothing left to unlock, the nearest gold (or an unwon title race) instead. -> { need, class, text } or nil
function P.nextGoal(data, prefer)
  local best
  local function better(c)
    if not c then return end
    if not best or c.need < best.need or (c.need == best.need and c.class == prefer and best.class ~= prefer) then best = c end
  end
  for _, c in ipairs(cfg.Leagues or {}) do better(P.nextUnlock(data, c.key)) end
  if best then return best end
  for _, c in ipairs(cfg.Leagues or {}) do
    if P.classOpen(data, c.key) then
      local missing, last = 0, nil
      for _, cup in ipairs(cfg.Cups or {}) do
        if not cup.final or P.cupOpen(data, c.key, cup.key) then
          if bestOf(data, c.key, cup.key) ~= 1 then missing = missing + 1; last = cup.name end
        end
      end
      if missing > 0 then
        better({ need = missing, class = c.key, text = missing == 1 and ('gold in the %s at %s'):format(titleCase(last), c.name)
          or ('%d more golds at %s'):format(missing, c.name) })
      end
      local t = (data.titles or {})[c.key]
      if titleOn() and P.titleOpen(data, c.key) and not (t and t.won) then
        better({ need = 1, class = c.key, text = ('win the TITLE RACE at %s'):format(c.name) })
      end
    end
  end
  return best
end

return P
