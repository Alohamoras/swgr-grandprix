-- Galactic Grand Prix (from the Underground's loadout.lua, v0.10): AI racers' abilities (DESIGN.md §5).
-- The game copies the launch build - YOUR abilities included - to every AI racer, but each racer holds its own copy
-- (RacerBuildState.VehicleBuilds) and the copies can be changed while the race loads: they exist ~0.1 s after the
-- race world appears and the ability actors spawn from them ~0.7 s later (recon 2026-11-09). So while a race loads we
-- give every bot its four (config Abilities.Racers, one per category), the same every race; the class sets the level.
-- Nothing to put back: the copies go with the race world. Your own build is never touched.
local C = require('core')
local cfg = require('config')
local AB = require('abil')
local MS = require('modsel')
local try, alive, log = C.try, C.alive, C.log

local L = {}
local RACERS = '/Game/Griffin/Narrative/CharacterDefs/Racers/DA_Racer_'
local GIVE_UP_MS = 20000

local function conf() return cfg.Abilities or {} end
local function tconf() return cfg.TuneUps or {} end
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
-- the AI's tune-ups (v0.8, config TuneUps.AI / Tiers): per class, per tier, the packages those bots race with

-- tier -> package keys at a class ({} when the class has none)
function L.aiPackages(classKey)
  local ai = tconf().AI
  return (type(ai) == 'table' and ai[tostring(classKey)]) or {}
end
-- the tiers at a class, the strongest first (the campaign's ranking; anything else after, by name)
local RANK = { Ace = 1, Elite = 2, Challenger = 3, ['Riff-Raff'] = 4, Loser = 5 }
local function tierNames(classKey)
  local out = {}
  for tier in pairs(L.aiPackages(classKey)) do out[#out + 1] = tier end
  table.sort(out, function(a, b)
    local ra, rb = RANK[a] or 99, RANK[b] or 99
    if ra ~= rb then return ra < rb end
    return a < b
  end)
  return out
end
-- a racer's tier (racer config key -> Tiers), or nil
local function tierOf(racerKey)
  for tier, keys in pairs(tconf().Tiers or {}) do
    for _, k in ipairs(keys) do if k == racerKey then return tier end end
  end
  return nil
end
L.tierOf = tierOf

-- the affix paths the launch build carries for a race: yours, then the AI tiers' extras (the bots copy the launch
-- build; at load each racer's race copy loses what isn't theirs, yours included). TuneUps.AIExtra = false: the AI only
-- keeps what you also carry, so the launch build is yours only.
function L.launchPaths(yours, classKey)
  local out, seen = {}, {}
  local function add(p) if not seen[p] then seen[p] = true; out[#out + 1] = p end end
  for _, p in ipairs(yours or {}) do add(p) end
  if tconf().AIExtra ~= false then
    local ai = L.aiPackages(classKey)
    for _, tier in ipairs(tierNames(classKey)) do for _, p in ipairs(MS.pathsOf(ai[tier])) do add(p) end end
  end
  return out
end

---------------------------------------------------------------------------------------------------------------------
-- during the race load (called every tick from race.watch until it's done)

-- modNames: every affix asset name in the launch build (race.lua); yourKeys: your fitted packages (nil = every one of
-- them is yours). The bots copy the launch build, so at load each racer's race copy is cleared of the affixes that
-- aren't theirs (recon 2026-11-10: the bots' passives aren't made yet at that point): a bot keeps its tier's packages
-- (TuneUps.AI), you keep yours.
function L.begin(classKey, modNames, yourKeys)
  local all = {}
  for _, n in ipairs(modNames or {}) do all[n] = true end
  local hasMods = next(all) ~= nil
  if not L.enabled() and not hasMods then return nil end
  if L.enabled() then
    local n, bad = L.preload(classKey)
    log(('[loadout] league %s: AI racers get their four abilities at load (%d abilities ready%s)'):format(tostring(classKey), n - bad,
      bad > 0 and (', ' .. bad .. ' missing') or ''))
  end
  local mods
  if hasMods then
    mods = { all = all, you = yourKeys and MS.assetNames(yourKeys) or all, youLabel = yourKeys and MS.label(yourKeys) or 'all',
      tiers = {}, order = tierNames(classKey) }
    local ai = L.aiPackages(classKey)
    for _, tier in ipairs(mods.order) do
      mods.tiers[tier] = { keep = MS.assetNames(ai[tier]), label = MS.label(ai[tier]), who = {} }
    end
  end
  return { class = classKey, at = C.clock, done = false, abil = L.enabled(), mods = mods }
end

-- one racer's race copies (AffixSlots[].PrimaryAffix): every launch-build affix not in `keep` is cleared.
-- Returns cleared, failed.
local function stripOne(ps, all, keep)
  local cleared, failed = 0, 0
  local vb = ps.RacerBuildState.VehicleBuilds
  for b = 1, vb:GetArrayNum() do
    local slots = try(function() return vb[b].AffixSlots end)
    for j = 1, (slots and slots:GetArrayNum() or 0) do
      local a = try(function() return slots[j].PrimaryAffix end)
      local n = alive(a) and try(function() return a:GetFName():ToString() end)
      if n and all[n] and not keep[n] then
        local ok = pcall(function() slots[j].PrimaryAffix = CreateInvalidObject(); slots[j].Status = 0 end)
        if ok and not alive(try(function() return slots[j].PrimaryAffix end)) then cleared = cleared + 1 else failed = failed + 1 end
      end
    end
  end
  return cleared, failed
end

local function psName(ps)
  return C.text(ps, 'PlayerNamePrivate') or try(function() return ps:GetPlayerName():ToString() end)
end
local function isBot(ps) return try(function() return ps.bIsABot end) == true end

-- the launch build's affixes sorted out at load: each bot keeps its tier's packages, you keep yours. Logs one line:
-- '[loadout] mods: you=... Elite=... (N bot slots cleared)'.
local function sortMods(bots, me, mods)
  local cleared, failed, mine, parts = 0, 0, 0, {}
  for _, ps in ipairs(bots) do
    local key = nameIndex()[psName(ps) or ''] or ''
    local tier = tierOf(key)
    local t = tier and mods.tiers[tier] -- (a tier with no packages at this class keeps nothing)
    local c, f = stripOne(ps, mods.all, t and t.keep or {})
    cleared, failed = cleared + c, failed + f
    if t then t.who[#t.who + 1] = psName(ps) or key end
  end
  if me then
    local c, f = stripOne(me, mods.all, mods.you)
    mine, failed = c, failed + f
  end
  parts[#parts + 1] = 'you=' .. mods.youLabel
  for _, tier in ipairs(mods.order) do
    local t = mods.tiers[tier]
    parts[#parts + 1] = ('%s=%s (%s)'):format(tier, t.label, #t.who > 0 and table.concat(t.who, ', ') or 'nobody in this race')
  end
  log(('[loadout] mods: %s (%d bot slots cleared%s%s)'):format(table.concat(parts, ' '), cleared,
    mine > 0 and (', ' .. mine .. ' cleared from your race copy') or '', failed > 0 and (', ' .. failed .. ' FAILED') or ''))
end

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

-- AI driving spike, step 1 (TASKS.md section 1): with a file `logbuilds.txt` in the mod folder, every racer's race
-- copy is logged once at load, BEFORE any of our changes - read only: plain ints and object names (no TMap / TOptional
-- / soft pointers; the AI build state's maps are never touched). Lines start `[builds]`.
local function nameOf(o) return alive(o) and (try(function() return o:GetFName():ToString() end) or '?') or '-' end
local function buildLine(b)
  local up = {}
  local us = b.UpgradeSlots
  for i = 1, (try(function() return us:GetArrayNum() end) or 0) do
    local u = us[i]
    up[#up + 1] = ('%s:p%s/s%s/+%s'):format((nameOf(try(function() return u.TunesetToApply end)):gsub('^TNS_', '')),
      tostring(try(function() return u.PowerLevel end)), tostring(try(function() return u.StacksToApply end)),
      tostring(try(function() return u.UserFacingStatIncrease end)))
  end
  local af = {}
  local as = b.AffixSlots
  for i = 1, (try(function() return as:GetArrayNum() end) or 0) do
    local a = as[i]
    af[#af + 1] = nameOf(try(function() return a.PrimaryAffix end)) .. '/' .. nameOf(try(function() return a.SecondaryAffix end))
  end
  return ('%s arch=%s power=%s override=%s remainder=%s resil=%s | upgrades %s | affixes %s'):format(
    nameOf(try(function() return b.VehicleBuildDef end)), tostring(try(function() return b.BuildArchetype end)),
    tostring(try(function() return b.PowerLevel end)), tostring(try(function() return b.OverridenPowerLevel end)),
    tostring(try(function() return b.PowerLevelMaxRemainder end)), tostring(try(function() return b.BaseResilienceOverride end)),
    #up > 0 and table.concat(up, ' ') or '-', #af > 0 and table.concat(af, ' ') or '-')
end
local function listNames(arr)
  local out = {}
  for i = 1, (try(function() return arr:GetArrayNum() end) or 0) do out[#out + 1] = nameOf(try(function() return arr[i] end)) end
  return #out > 0 and table.concat(out, ',') or '-'
end
function L.logBuilds(all)
  local f = io.open(C.DIR .. '/logbuilds.txt', 'r')
  if not f then return end
  f:close()
  for _, ps in ipairs(all) do
    local rb = ps.RacerBuildState
    local vb = rb.VehicleBuilds
    log(('[builds] %s%s pilot=%s style=%s passives=%s modifiers=%s'):format(psName(ps) or '?', isBot(ps) and '' or ' (YOU)',
      nameOf(try(function() return ps.Pilot end)), nameOf(try(function() return ps.RacerStyle end)),
      listNames(rb.AppliedPassives), listNames(rb.AppliedModifiers)))
    for b = 1, (try(function() return vb:GetArrayNum() end) or 0) do
      local ok, line = pcall(buildLine, vb[b])
      log('[builds]   ' .. (ok and line or ('read error: ' .. tostring(line))))
    end
  end
end

-- v0.28 pilot strength (config AI.Strength) and the AI spike's test switch (ai.lua A.experiment: botStacks /
-- botStacksBy, which win when present): each bot's stacking part upgrades (the `_Max` tune sets: one stack a level)
-- moved by d levels on its race copy, at load, before the upgrades are applied (proven in game 2026-11-12: +2 =
-- ~3-4 s). Its PowerLevel field follows. Nothing to put back: the copies go with the race world.
local function strengthConf() local a = cfg.AI or {}; return a.Strength end
function L.strengthFor(name, league)
  local sc = strengthConf()
  if type(sc) ~= 'table' then return 0 end
  local key = nameIndex()[name or '']
  local tier = key and (sc.Pilots or {})[key]
  local per = sc[tostring(league)]
  return (tier and type(per) == 'table' and tonumber(per[tier])) or 0
end
function L.botParts(bots, exp, league)
  local testing = exp and (exp.botStacks ~= nil or exp.botStacksBy ~= nil)
  if not testing and type(strengthConf()) ~= 'table' then return end
  local parts = {}
  for _, ps in ipairs(bots) do
    local name = psName(ps) or '?'
    local d
    if testing then d = (type(exp.botStacksBy) == 'table' and exp.botStacksBy[name]) or tonumber(exp.botStacks) or 0
    else d = L.strengthFor(name, league) end
    if d ~= 0 then
      local vb = ps.RacerBuildState.VehicleBuilds
      local changed, lvl = 0, nil
      for b = 1, (try(function() return vb:GetArrayNum() end) or 0) do
        local us = vb[b].UpgradeSlots
        for i = 1, (try(function() return us:GetArrayNum() end) or 0) do
          local u = us[i]
          local s = try(function() return u.StacksToApply end)
          -- v0.28.4 (crash at every JUNKER race load, UE4SS.dll+0x2ace27, a null read at +0x18 = an empty object's
          -- name): a part slot at level 0 has no tune set - never call anything on it; only a live one is named
          local ts = type(s) == 'number' and s >= 1 and try(function() return u.TunesetToApply end) or nil
          local tn = alive(ts) and (try(function() return ts:GetFName():ToString() end) or '') or ''
          if type(s) == 'number' and s >= 1 and alive(ts) and (s > 1 or tn:find('_Max$')) then
            local nv = math.max(1, s + d)
            pcall(function() u.StacksToApply = nv end)
            pcall(function() u.PowerLevel = nv end)
            if try(function() return u.StacksToApply end) == nv then changed = changed + 1; lvl = nv end
          end
        end
      end
      parts[#parts + 1] = ('%s %+d (%d upgrades, now %s)'):format(name, d, changed, tostring(lvl))
    end
  end
  log((testing and '[exp] bot parts: ' or ('[ai] pilot strength (%s): '):format(tostring(league)))
    .. (#parts > 0 and table.concat(parts, ', ') or 'none changed'))
end

function L.apply(st)
  if not st or st.done then return end
  if C.clock - st.at > GIVE_UP_MS then
    st.done = true
    log('[loadout] gave up: the AI racers never appeared (the game\'s abilities stay)')
    return
  end
  local bots, me = {}, nil
  for _, ps in ipairs(C.find('GfnPlayerState')) do
    local n = try(function() return ps.RacerBuildState.VehicleBuilds:GetArrayNum() end) or 0
    if isBot(ps) then
      if n == 0 then return end -- a bot without its build yet: wait
      bots[#bots + 1] = ps
    elseif n > 0 and try(function() return ps.bIsABot end) == false then
      me = me or ps -- your race copy (the same kind of copy; its extras are cleared the same way)
    end
  end
  if #bots == 0 then return end
  st.done = true
  do
    local all = {}
    if me then all[1] = me end
    for _, b in ipairs(bots) do all[#all + 1] = b end
    local okB, errB = pcall(L.logBuilds, all)
    if not okB then log('[builds] read failed: ' .. tostring(errB)) end
    local okE, errE = pcall(L.botParts, bots, require('ai').experiment(), st.class)
    if not okE then log('[exp] bot parts failed: ' .. tostring(errE)) end
  end
  if st.mods then
    local okS, err = pcall(sortMods, bots, me, st.mods)
    if not okS then log('[loadout] could not sort the mods out between the racers: ' .. tostring(err)) end
  end
  if not st.abil then return end
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
