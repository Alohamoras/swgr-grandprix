-- Galactic Grand Prix v0.32: what the bots do with their kits. loadout.lua hands every bot four abilities while the
-- race loads; this module makes sure they get used (docs/freerace-review-2026-11-25.md §3.1 and §6.2, from the
-- FreeRace mod's findings, checked against the game's header dump):
--   1. A bot only fires its SELECTED ability (PlayerAbilityComponent.SelectedAbilityIx). With four in the kit, slot 0
--      was the one ever used. So every Abilities.AICycleS the selection moves on to the next ability, per bot.
--   2. A bot fires an ability only when one of the AI's ability configs (RaceAIComponentConfig
--      .AbilityConfigCollection.AbilityConfigs[].AbilityClasses) lists its class; the trigger rules are per config.
--      Once a race the kit classes of this league are checked against the collection; a class no config lists is
--      added to the config of its family (BP_Ability_<Family>...), so the family's rules fire it. The configs are
--      shared game data: the lists go into the save first (aiCoverRestores) and back at the menu.
--   3. An ability instance's own AbilityConfig copy carries WarmupTime, its recharge. Abilities.AICooldowns sets it
--      by class-name part (Mine, Disruptor...) on a bot's OWN copy only (a shared config is left alone): nothing to
--      put back, the copies go with the race.
--   4. A use = State Ready (8) -> Active (16) or WarmingUp (2) between two reads. Counted per bot and ability: one
--      [aiuse] line a minute (up to 5) and one with the RESULT - the first real answer to "do the bots fire them?".
-- Everything is read inside race.lua's 2 s sweep of the player states (readField): no extra lookups, no object kept
-- between ticks (the ability instances are told apart by address, a number).
local C = require('core')
local cfg = require('config')
local AB = require('abil')
local try, alive, log = C.try, C.alive, C.log

local AU = {}
local READY, ACTIVE, WARMING = 8, 16, 2
local SHARED = '/Game/Griffin/Gameplay/Abilities/'
local REPORT_MS, MAX_REPORTS = 60000, 5

local function conf() return cfg.Abilities or {} end
function AU.enabled() return conf().AIUse ~= false and conf().AI ~= false end
local function cycleMs() return (tonumber(conf().AICycleS) or 4) * 1000 end
local function short(cls) return (tostring(cls):gsub('^BP_Ability_', ''):gsub('_C$', '')) end
-- an object's short name (the last segment, should a full path come back)
local function nameOf(o) return (C.idname(o):match('([^%./]+)$') or '') end
-- the recharge for an ability (by class-name part, Abilities.AICooldowns), or nil
local function cooldownFor(key)
  local t = conf().AICooldowns
  if type(t) ~= 'table' then return nil end
  for part, s in pairs(t) do if type(s) == 'number' and key:find(part, 1, true) then return s end end
  return nil
end

function AU.begin(classKey)
  if not AU.enabled() then return nil end
  return { class = classKey, at = C.clock, bots = {}, seen = {}, uses = {}, cooled = {}, cycles = 0, cycleLogs = 0,
    coolLogs = 0, sharedLogs = 0, reports = 0, lastReport = C.clock }
end

-- one bot's player state, on race.lua's 2 s read (once the race has started)
function AU.onBot(st, ps, name)
  local comp = try(function() return ps.AbilityComponent end)
  if not alive(comp) then return end
  local arr = try(function() return comp.Abilities end)
  local n = arr and try(function() return arr:GetArrayNum() end) or 0
  if type(n) ~= 'number' or n == 0 then return end
  local b = st.bots[name]
  if not b then b = { last = C.clock, keys = {} }; st.bots[name] = b end
  for i = 1, n do
    local ab = try(function() return arr[i] end)
    if alive(ab) then
      local id, key = C.addr(ab), short(C.clsname(ab))
      b.keys[i] = key
      local state = try(function() return tonumber(ab.State) end)
      if id then
        local was = st.seen[id]
        if was == READY and (state == ACTIVE or state == WARMING) then
          local k = name .. '|' .. key
          st.uses[k] = (st.uses[k] or 0) + 1
        end
        st.seen[id] = state
        -- the recharge, once per instance, on its own config copy only
        if not st.cooled[id] then
          st.cooled[id] = true
          local cd = cooldownFor(key)
          if cd then
            local cf = try(function() return ab.AbilityConfig end)
            local full = alive(cf) and try(function() return cf:GetFullName() end) or ''
            local path = type(full) == 'string' and full:match('^%S+%s+(.+)$') or ''
            local own = path ~= '' and not path:find('Default__', 1, true) and path:sub(1, #SHARED) ~= SHARED
            if own then
              local wasCd = try(function() return tonumber(cf.WarmupTime) end)
              local ok = pcall(function() cf.WarmupTime = cd end)
              st.coolLogs = st.coolLogs + 1
              if st.coolLogs <= 6 then log(('[aiuse] %s %s: recharge %s -> %g s%s'):format(name, key, tostring(wasCd), cd, ok and '' or ' FAILED')) end
            elseif st.sharedLogs < 2 then
              st.sharedLogs = st.sharedLogs + 1
              log(('[aiuse] %s %s: a shared config (%s), its recharge left alone'):format(name, key, path ~= '' and path:match('([^/]+)$') or '?'))
            end
          end
        end
      end
    end
  end
  -- the selection moves on (never the same twice in a row)
  if n > 1 and C.clock - b.last >= cycleMs() then
    b.last = C.clock
    local ix = try(function() return tonumber(comp.SelectedAbilityIx) end)
    if type(ix) == 'number' then
      local nx = (ix + 1) % n
      local ok = pcall(function() comp.SelectedAbilityIx = nx end)
      if ok then st.cycles = st.cycles + 1 end
      st.cycleLogs = st.cycleLogs + 1
      if st.cycleLogs <= 3 then log(('[aiuse] %s: selected ability %d -> %d of %d (%s)%s'):format(name, ix, nx, n, b.keys[nx + 1] or '?', ok and '' or ' FAILED')) end
    elseif not st.noIx then
      st.noIx = true
      log('[aiuse] no SelectedAbilityIx on ' .. C.clsname(comp) .. ': the bots keep the game\'s own selection')
    end
  end
end

---------------------------------------------------------------------------------------------------------------------
-- coverage: every class our kits can carry at this league must be listed by one of the AI's ability configs

local K -- (gp.lua, required late: it requires config and core only)
local function restores()
  K = K or require('gp')
  K.data.aiCoverRestores = type(K.data.aiCoverRestores) == 'table' and K.data.aiCoverRestores or {}
  return K.data.aiCoverRestores
end
function AU.pending() local okK, g = pcall(require, 'gp'); return okK and g.data ~= nil and next(restores()) ~= nil end

-- 'BP_Ability_X_C' -> its class path, for every ability a bot can carry at this league
local function kitClasses(classKey)
  local names = {}
  local level = AB.levelFor(classKey)
  local function add(picks)
    for _, p in ipairs(AB.classPaths(picks, level, true)) do names[p:match('([^%.]+)$')] = p end
  end
  for key in pairs(conf().Racers or {}) do add(AB.racerPicks(key)) end
  add(AB.racerPicks(nil))
  return names
end
local function classPath(c)
  local full = alive(c) and try(function() return c:GetFullName() end)
  return type(full) == 'string' and full:match('^%S+%s+(.+)$') or nil
end
local function listOf(aic)
  local names, paths = {}, {}
  local arr = try(function() return aic.AbilityClasses end)
  for j = 1, (arr and try(function() return arr:GetArrayNum() end) or 0) do
    local c = try(function() return arr[j] end)
    if alive(c) then names[#names + 1] = nameOf(c); paths[#paths + 1] = classPath(c) or '' end
  end
  return names, paths
end

-- once a race, after the start (a sweep of the AI configs: one, at the 2 s read)
function AU.cover(st, classKey)
  if not st or st.covered then return end
  st.covered = true
  if conf().AICover == false then return end
  local colls, seen = {}, {}
  for _, o in ipairs(C.find('RaceAIComponentConfig')) do
    local coll = try(function() return o.AbilityConfigCollection end)
    local k = alive(coll) and C.addr(coll)
    if k and not seen[k] then seen[k] = true; colls[#colls + 1] = coll end
  end
  if #colls == 0 then log('[aiuse] no AI ability configs found in the race: coverage not checked'); return end
  local want = kitClasses(classKey or st.class)
  local nWant = 0
  for _ in pairs(want) do nWant = nWant + 1 end
  for _, coll in ipairs(colls) do
    local cfgs, have, lines = {}, {}, {}
    local arr = try(function() return coll.AbilityConfigs end)
    for i = 1, (arr and try(function() return arr:GetArrayNum() end) or 0) do
      local aic = try(function() return arr[i] end)
      if alive(aic) then
        local names, paths = listOf(aic)
        for _, n in ipairs(names) do have[n] = true end
        cfgs[#cfgs + 1] = { aic = aic, names = names, paths = paths }
        local shortNames = {}
        for _, n in ipairs(names) do shortNames[#shortNames + 1] = short(n) end
        lines[#lines + 1] = ('%s [%s] %s%%'):format(nameOf(aic), table.concat(shortNames, ' '), tostring(try(function() return aic.PercentageChance end)))
      end
    end
    log(('[aiuse] AI ability configs in %s: %s'):format(nameOf(coll), #lines > 0 and table.concat(lines, '; ') or 'none'))
    local missing = {}
    for n in pairs(want) do if not have[n] then missing[#missing + 1] = n end end
    table.sort(missing)
    local added, orphans = {}, {}
    for _, n in ipairs(missing) do
      local fam = n:match('^BP_Ability_(%a+)') or ''
      local donor
      for _, c in ipairs(cfgs) do
        for _, x in ipairs(c.names) do
          if not donor and (x == 'BP_Ability_' .. fam .. '_C' or x:find('^BP_Ability_' .. fam .. '_')) then donor = c end
        end
      end
      local cls = donor and C.uclass(want[n])
      local list = donor and try(function() return donor.aic.AbilityClasses end)
      local k = list and try(function() return list:GetArrayNum() end)
      if cls and type(k) == 'number' then
        local key = classPath(donor.aic)
        local rest = restores()
        if key and not rest[key] then rest[key] = donor.paths; K.save() end
        if pcall(function() list[k + 1] = cls end) then
          added[#added + 1] = short(n) .. ' -> ' .. nameOf(donor.aic)
          have[n] = true
        else
          orphans[#orphans + 1] = short(n) .. ' (the list would not take it)'
        end
      else
        orphans[#orphans + 1] = short(n) .. (donor and ' (class not loaded)' or (' (no ' .. fam .. ' config to join)'))
      end
    end
    log(('[aiuse] our kits at %s: %d classes, %d listed by the AI configs%s%s'):format(tostring(classKey or st.class), nWant,
      nWant - #missing, #added > 0 and ('; added ' .. table.concat(added, ', ')) or '',
      #orphans > 0 and ('; NOT fired by the AI: ' .. table.concat(orphans, ', ')) or ''))
  end
end

-- at the menu (race.lua R.restoreBuild): every config's list back as it was. Returns the number put back.
function AU.restoreCover(why)
  local okK, g = pcall(require, 'gp')
  if not okK or g.data == nil then return 0 end
  local rest = restores()
  local done = 0
  for path, paths in pairs(rest) do
    local aic = try(StaticFindObject, path)
    local list = alive(aic) and try(function() return aic.AbilityClasses end)
    if list then
      local ok = pcall(function()
        list:Empty()
        for i, p in ipairs(paths) do list[i] = C.uclass(p) or CreateInvalidObject() end
      end)
      log(('[aiuse] AI ability config put back (%s): %s (%d classes)%s'):format(why or '', path:match('([^/%.]+)$') or path, #paths, ok and '' or ' - FAILED'))
    else
      log('[aiuse] restore: AI ability config not found ' .. path .. ' (dropped)')
    end
    rest[path] = nil
    done = done + 1
  end
  return done
end

---------------------------------------------------------------------------------------------------------------------
-- what they fired

local function usesText(st)
  local by, order = {}, {}
  for k, n in pairs(st.uses) do
    local who, ab = k:match('^(.-)|(.*)$')
    if not by[who] then by[who] = {}; order[#order + 1] = who end
    by[who][#by[who] + 1] = ('%s %d'):format(ab, n)
  end
  table.sort(order)
  local parts = {}
  for _, who in ipairs(order) do table.sort(by[who]); parts[#parts + 1] = who .. ': ' .. table.concat(by[who], ', ') end
  return #parts > 0 and table.concat(parts, ' | ') or 'nothing yet'
end
-- a line a minute while the race runs (race.lua), up to MAX_REPORTS
function AU.report(st)
  if not st or st.reports >= MAX_REPORTS or C.clock - st.lastReport < REPORT_MS then return end
  st.lastReport, st.reports = C.clock, st.reports + 1
  log(('[aiuse] fired so far (%d selection moves): %s'):format(st.cycles, usesText(st)))
end
-- one line with the RESULT
function AU.summary(st)
  if not st then return nil end
  return ('[aiuse] fired in this race (%d selection moves): %s'):format(st.cycles, usesText(st))
end

return AU
