-- Galactic Grand Prix: the four ability picks (DESIGN.md §5). Pure logic (tested in test/test_abil.lua).
-- A pick is 'family.branch' (e.g. 'bolt.concuss'); the class sets the level (1-3). At level 1 every branch of a family
-- is the same ability, so the branch only matters from level 2. Picks: { offensive, defensive, utility, wildcard }.
local cfg = require('config')

local AB = {}
local ROOT = '/Game/Griffin/Gameplay/Abilities/'

local function conf() return cfg.Abilities or {} end
local function lines(fam) return (conf().Lines or {})[fam] or {} end
function AB.categories() return conf().Categories or {} end
function AB.category(key) for _, c in ipairs(AB.categories()) do if c.key == key then return c end end end

-- 'family.branch' -> the ability's relative path at a level ('Disruptor/BP_Ability_Disruptor_Concuss'), or nil.
-- forBots keeps the game's _AI versions (mines); yours drop the _AI.
function AB.rel(pick, level, forBots)
  local fam, br = tostring(pick or ''):match('^(%w+)%.(%w+)$')
  local line = fam and lines(fam)[br]
  local rel = line and line[math.max(1, math.min(#line, level or 1))]
  if not rel then return nil end
  return forBots and rel or (rel:gsub('_AI$', ''))
end
function AB.classPath(rel)
  local n = rel:match('([^/]+)$')
  return ROOT .. rel .. '.' .. n .. '_C'
end
function AB.name(rel)
  local f = rel and rel:gsub('_AI$', ''):match('BP_Ability_([%w_]+)$')
  return (conf().Names or {})[f or ''] or f or tostring(rel)
end
function AB.family(pick) return tostring(pick or ''):match('^(%w+)%.') end
function AB.label(pick, level) return AB.name(AB.rel(pick, level)) end
function AB.blurb(pick) return (conf().Blurb or {})[AB.family(pick) or ''] or '' end

-- the class's ability level
function AB.levelFor(classKey)
  for _, c in ipairs(cfg.Classes or {}) do if c.key == classKey then return c.abilities or 1 end end
  return 1
end

-- the choices for a category at a level: { pick, name } - one per distinct ability (branches that are the same
-- ability at this level are offered once). The wildcard leaves out families already picked in the other categories.
function AB.options(catKey, level, picks)
  local cat = AB.category(catKey)
  if not cat then return {} end
  local taken = {}
  if catKey == 'wildcard' then
    for k, p in pairs(picks or {}) do if k ~= 'wildcard' then taken[AB.family(p) or ''] = true end end
  end
  local out, seen = {}, {}
  for _, fam in ipairs(cat.families) do
    if not taken[fam] then
      local branches = {}
      for br in pairs(lines(fam)) do branches[#branches + 1] = br end
      table.sort(branches)
      for _, br in ipairs(branches) do
        local pick = fam .. '.' .. br
        local rel = AB.rel(pick, level)
        if rel and not seen[rel] then
          seen[rel] = true
          out[#out + 1] = { pick = pick, name = AB.name(rel), rel = rel }
        end
      end
    end
  end
  return out
end

-- is this pick allowed in this category (the same ability as one of the options, at this level)?
local function allowed(catKey, pick, level, picks)
  local rel = AB.rel(pick, level)
  for _, o in ipairs(AB.options(catKey, level, picks)) do if o.rel == rel then return true end end
  return false
end

-- picks made valid: anything missing or not allowed falls back to the default, then to the first option.
-- (Order matters: the wildcard is checked last, against the other three.)
function AB.normalize(picks, level)
  local out, def = {}, conf().Default or {}
  for _, c in ipairs(AB.categories()) do
    local p = (picks or {})[c.key]
    if not (p and allowed(c.key, p, level, out)) then
      p = def[c.key]
      if not (p and allowed(c.key, p, level, out)) then
        local o = AB.options(c.key, level, out)[1]
        p = o and o.pick or nil
      end
    end
    out[c.key] = p
  end
  return out
end

-- class paths for the build's 4 slots, in category order
function AB.classPaths(picks, level, forBots)
  local out = {}
  for _, c in ipairs(AB.categories()) do
    local rel = AB.rel((picks or {})[c.key], level, forBots)
    if rel then out[#out + 1] = AB.classPath(rel) end
  end
  return out
end

-- an AI racer's four (config Racers by key), else the default four
function AB.racerPicks(racerKey)
  local r = racerKey and (conf().Racers or {})[racerKey]
  local out = {}
  for _, c in ipairs(AB.categories()) do out[c.key] = (r and r[c.key]) or (conf().Default or {})[c.key] end
  return out
end

return AB
