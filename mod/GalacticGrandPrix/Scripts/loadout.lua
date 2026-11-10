-- Galactic Grand Prix (from the Underground's loadout.lua, v0.10): AI racers' abilities (DESIGN.md §5).
-- The game copies the launch build - YOUR abilities included - to every AI racer, but each racer holds its own copy
-- (RacerBuildState.VehicleBuilds) and the copies can be changed while the race loads: they exist ~0.1 s after the
-- race world appears and the ability actors spawn from them ~0.7 s later (recon 2026-11-09). So while a race loads we
-- give every bot its four (config Abilities.Racers, one per category), the same every race; the class sets the level.
-- Nothing to put back: the copies go with the race world. Your own build is never touched.
local C = require('core')
local cfg = require('config')
local AB = require('abil')
local try, alive, log = C.try, C.alive, C.log

local L = {}
local RACERS = '/Game/Griffin/Narrative/CharacterDefs/Racers/DA_Racer_'
local GIVE_UP_MS = 20000

local function conf() return cfg.Abilities or {} end
function L.enabled() return conf().AI ~= false end

-- racer display name -> config key (the game's own CharacterName, read once; English fallback from config)
local names
local function nameIndex()
  if names then return names end
  names = {}
  for key, r in pairs(conf().Racers or {}) do
    if r.name then names[r.name] = key end
    local def = C.asset(RACERS .. key)
    local n = def and C.text(def, 'CharacterName')
    if n then names[n] = key end
  end
  return names
end
function L.resetNames() names = nil end

-- the four class paths a racer brings at a class (the _AI versions where the game has them), and their config key
function L.kitFor(racerName, classKey)
  local key = nameIndex()[racerName or '']
  return AB.classPaths(AB.racerPicks(key), AB.levelFor(classKey), true), key
end

---------------------------------------------------------------------------------------------------------------------
-- during the race load (called every tick from race.watch until it's done)

function L.begin(classKey)
  if not L.enabled() then return nil end
  local n, bad = L.preload(classKey)
  log(('[loadout] class %s: AI racers get their four abilities at load (%d abilities ready%s)'):format(tostring(classKey), n - bad,
    bad > 0 and (', ' .. bad .. ' missing') or ''))
  return { class = classKey, at = C.clock, done = false }
end

local function psName(ps)
  return C.text(ps, 'PlayerNamePrivate') or try(function() return ps:GetPlayerName():ToString() end)
end
local function isBot(ps) return try(function() return ps.bIsABot end) == true end

-- an ability actor already owned by a bot = too late (the game spawned them from the copied build)
local function botAbilitySpawned()
  for _, a in ipairs(C.find('GfnAbility')) do
    local owner = try(function() return a.OwningPlayer end)
    if alive(owner) and isBot(owner) then return true end
  end
  return false
end

-- an ability class, looked up each time (StaticFindObject finds only live objects; loading happens once). Only a real
-- class is returned: v0.10.0's first in-game Novice race got a non-class for one lookup ("Value must be UClass").
local missing = {}
local function isClass(c)
  local cn = alive(c) and try(function() return c:GetClass():GetFName():ToString() end)
  return type(cn) == 'string' and cn:find('Class$') ~= nil
end
local function class(path)
  if not path then return nil end
  local c = C.uclass(path)
  if not isClass(c) then
    if not missing[path] then missing[path] = true; log('[loadout] not a usable ability class: ' .. path) end
    return nil
  end
  return c
end

-- load every class a race at this class can need (called at launch, before the race world exists)
function L.preload(classKey)
  local n, bad, seen = 0, 0, {}
  local level = AB.levelFor(classKey)
  local function want(picks)
    for _, p in ipairs(AB.classPaths(picks, level, true)) do
      if not seen[p] then seen[p] = true; n = n + 1; if not class(p) then bad = bad + 1 end end
    end
  end
  for key in pairs(conf().Racers or {}) do want(AB.racerPicks(key)) end
  want(AB.racerPicks(nil))
  return n, bad
end

-- set every slot of every vehicle build of one bot, slot by slot: a slot that won't take its ability is emptied, so a
-- bot never keeps your abilities. Returns the kit text for the log and the number of slots that failed.
local function equip(ps, paths)
  local cls, labels = {}, {}
  for i, p in ipairs(paths) do
    cls[i] = class(p)
    labels[#labels + 1] = p:match('BP_Ability_([%w_]+)%.') or p
  end
  local kit = paths
  local vb = ps.RacerBuildState.VehicleBuilds
  local nb, short, bad = vb:GetArrayNum(), false, 0
  for b = 1, nb do
    local slots = vb[b].AbilitySlots
    local ns = slots:GetArrayNum()
    if ns < #kit then short = true end
    for j = 1, ns do
      local ok = cls[j] and pcall(function() slots[j] = cls[j] end)
      if not ok then
        if cls[j] then bad = bad + 1 end
        if not pcall(function() slots[j] = CreateInvalidObject() end) then bad = bad + 1 end
      end
    end
  end
  return table.concat(labels, '+') .. (short and ' (too few slots)' or '') .. (bad > 0 and (' (' .. bad .. ' slots emptied)') or ''), bad
end

function L.apply(st)
  if not st or st.done then return end
  if C.clock - st.at > GIVE_UP_MS then
    st.done = true
    log('[loadout] gave up: the AI racers never appeared (the game\'s abilities stay)')
    return
  end
  local bots = {}
  for _, ps in ipairs(C.find('GfnPlayerState')) do
    if isBot(ps) then
      local n = try(function() return ps.RacerBuildState.VehicleBuilds:GetArrayNum() end) or 0
      if n == 0 then return end -- a bot without its build yet: wait
      bots[#bots + 1] = ps
    end
  end
  if #bots == 0 then return end
  st.done = true
  if botAbilitySpawned() then
    log('[loadout] too late: the AI racers\' abilities had already spawned - this race keeps the game\'s')
    return
  end
  local parts, fails = {}, 0
  for _, ps in ipairs(bots) do
    local name = psName(ps) or '?'
    local paths = L.kitFor(name, st.class)
    local ok, txt = pcall(equip, ps, paths)
    if ok then parts[#parts + 1] = name .. '=' .. txt
    else fails = fails + 1; log('[loadout] could not set ' .. name .. ': ' .. tostring(txt)) end
  end
  log(('[loadout] %s, %d racers%s: %s'):format(tostring(st.class), #bots - fails, fails > 0 and (' (' .. fails .. ' failed)') or '',
    table.concat(parts, ', ')))
end

return L
