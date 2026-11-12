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

-- the league's ability level (v0.26)
function AB.levelFor(classKey)
  for _, c in ipairs(cfg.Leagues or {}) do if c.key == classKey then return c.abilities or 1 end end
  return 1
end

-- v0.3.10 (owner, 2026-11-10): the rule. 'free' = any four, one per family (the default); 'categories' = one per
-- category (offensive / defensive / utility / wildcard), as in v0.3.0. Your picks are a list of four either way.
function AB.rule() return conf().Rule == 'categories' and 'categories' or 'free' end
function AB.families()
  if conf().Families then return conf().Families end
  local out = {}
  for fam in pairs(conf().Lines or {}) do out[#out + 1] = fam end
  table.sort(out)
  return out
end

-- the four slots: { name, families, wildcard } (free: every family in each)
function AB.slots()
  if AB.rule() == 'categories' then
    local out = {}
    for i, c in ipairs(AB.categories()) do out[i] = { name = c.name, families = c.families, wildcard = c.key == 'wildcard' } end
    return out
  end
  local out = {}
  for i = 1, 4 do out[i] = { name = 'ABILITY ' .. i, families = AB.families() } end
  return out
end

-- picks as a list of four; an old save's { offensive, defensive, utility, wildcard } becomes the list in that order
function AB.toList(picks)
  local out = {}
  if type(picks) ~= 'table' then return out end
  if picks[1] ~= nil or picks[2] ~= nil or picks[3] ~= nil or picks[4] ~= nil then
    for i = 1, 4 do out[i] = picks[i] end
    return out
  end
  for i, c in ipairs(AB.categories()) do out[i] = picks[c.key] end
  return out
end
function AB.defaults() return AB.toList(conf().Default) end

-- the families the other slots hold (free: every slot's one; categories: only for the wildcard)
local function takenBy(slot, list)
  local t, s = {}, AB.slots()[slot]
  if AB.rule() == 'free' or (s and s.wildcard) then
    for i = 1, 4 do if i ~= slot and list[i] then t[AB.family(list[i]) or ''] = true end end
  end
  return t
end

-- the choices for slot i at a level: { pick, name, rel } - one per distinct ability (branches that are the same
-- ability at this level are offered once), leaving out the families held by the other slots (see takenBy).
function AB.choices(slot, level, picks)
  local s = AB.slots()[slot]
  if not s then return {} end
  local taken = takenBy(slot, AB.toList(picks))
  local out, seen = {}, {}
  for _, fam in ipairs(s.families) do
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

-- is this pick allowed in slot i, given the slots before it?
local function allowed(slot, pick, level, before)
  local rel = AB.rel(pick, level)
  if not rel then return false end
  for _, o in ipairs(AB.choices(slot, level, before)) do if o.rel == rel then return true end end
  return false
end

-- picks made valid (a list of four): slot by slot against the slots before it; anything missing or not allowed falls
-- back to that slot's default, then any default not yet used, then the first choice.
function AB.normalize(picks, level)
  local list, def, out = AB.toList(picks), AB.defaults(), {}
  for i = 1, #AB.slots() do
    local p = list[i]
    if not (p and allowed(i, p, level, out)) then
      p = nil
      local tries = { def[i] }
      for j = 1, 4 do if j ~= i then tries[#tries + 1] = def[j] end end
      for _, d in ipairs(tries) do if d and allowed(i, d, level, out) then p = d; break end end
      if not p then
        local o = AB.choices(i, level, out)[1]
        p = o and o.pick or nil
      end
    end
    out[i] = p
  end
  return out
end

-- class paths for the build's 4 slots (your list, or an AI racer's { offensive, ... })
function AB.classPaths(picks, level, forBots)
  local out, list = {}, AB.toList(picks)
  for i = 1, 4 do
    local rel = AB.rel(list[i], level, forBots)
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
