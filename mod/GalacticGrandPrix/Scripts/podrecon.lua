-- Galactic Grand Prix: the pod recon (TASKS §1h-L PL0, 2026-11-26) - TEST ONLY: runs only with config DevTools = true
-- and experiment.lua's `podRecon = true`. In a pod race it logs, as `[podrecon]` lines:
--   - at launch: the pod build's ability slots, part levels and affixes (race.lua preparePod: what we wrote, if asked);
--   - in the race (race.lua's 2 s read of your player state): your AbilityComponent's slots and instantiated abilities
--     with their states and energy, logged on every change, and (experiment `podFire = true`) each of your abilities
--     fired in turn with Server_Trigger(true) - TestAutopilot's call - once the race has run 20 s, one every 12 s,
--     the state read back 2 s later: does a pod carry and fire abilities;
--   - twice (20 s and 60 s after the start): how many Ramjet and Afterburner components exist and the Ramjet states -
--     does a pod have a ramjet at all.
-- Read-mostly: the only write is the trigger. Nothing kept between ticks: the player state comes in each read.
local C = require('core')
local log, try, alive = C.log, C.try, C.alive

local PRC = {}
local STATES = { [2] = 'warming', [8] = 'ready', [16] = 'active' }
local function stateName(s) return STATES[s] or tostring(s) end
local function short(cls) return (tostring(cls):gsub('^BP_Ability_', ''):gsub('_C$', '')) end

-- the pod build at launch: its slots, levels and affixes
function PRC.dumpBuild(b, levelsText)
  local slots = try(function() return b.AbilitySlots end)
  local n = slots and try(function() return slots:GetArrayNum() end) or 0
  local names = {}
  for i = 1, n do
    local c = try(function() return slots[i] end)
    names[i] = alive(c) and C.idname(c) or '-'
  end
  local aff = {}
  try(function() b.Affixes:ForEach(function(_, el) aff[#aff + 1] = C.idname(el:get()) end) end)
  log(('[podrecon] pod build: %d ability slots [%s], levels %s, affixes %d [%s], affix slots %s'):format(n,
    table.concat(names, ', '), tostring(levelsText), #aff, table.concat(aff, ', '),
    tostring(try(function() return b.UnlockedAffixSlots end))))
end

-- paths = ability class paths to equip on YOUR race copy at load (experiment podEquip; race 1 showed the pod build has
-- no ability slots but your race copy has 4), from slot `from` (2: slot 1 is TestAutopilot's)
function PRC.begin(exp, paths, ev)
  log('[podrecon] on: ' .. (exp.podFire and 'your abilities fired in turn from 20 s' or 'reading only')
    .. (paths and (', equip ' .. #paths .. ' on your race copy') or ''))
  -- the cup result's planet for this track (cupend.lua's load by codename, v0.43.1): logs the game's own name
  if exp.planetCheck and ev then
    local okC, CE = pcall(require, 'cupend')
    local d = okC and CE.defByCode and CE.defByCode(require('gp').planetOf(ev.path))
    log('[podrecon] planet check: ' .. (d and 'PlanetDef loaded' or 'NO PlanetDef'))
  end
  return { fire = exp.podFire == true, last = '', fired = 0, nextFire = nil, check = nil, ramjetChecks = 0,
    equip = paths, from = tonumber(exp.podEquipFrom) or 2, at = C.clock }
end

-- while the race loads (race.lua, every tick until done or 10 s): your picks into your race copy's ability slots, as
-- loadout.lua does for the bots and TestAutopilot for its Autopilot (RacerBuildState.VehicleBuilds[].AbilitySlots)
function PRC.equip(st)
  if not st.equip or st.equipped then return end
  if C.clock - st.at > 30000 then st.equipped = true; log('[podrecon] equip: gave up (no race copy of yours)'); return end
  for _, ps in ipairs(C.find('GfnPlayerState')) do
    if try(function() return ps.bIsABot end) == false then
      local vb = try(function() return ps.RacerBuildState.VehicleBuilds end)
      local nb = vb and try(function() return vb:GetArrayNum() end) or 0
      if nb == 0 then return end
      local n, names = 0, {}
      for b = 1, nb do
        local slots = try(function() return vb[b].AbilitySlots end)
        local ns = slots and try(function() return slots:GetArrayNum() end) or 0
        for k, p in ipairs(st.equip) do
          local j = st.from + k - 1
          local cls = j <= ns and C.uclass(p)
          if cls and pcall(function() slots[j] = cls end) then
            n = n + 1
            if b == 1 then names[#names + 1] = j .. '=' .. (p:match('BP_Ability_([%w_]+)%.') or p) end
          end
        end
      end
      st.equipped = true
      log(('[podrecon] equip: %d slot writes over %d race builds: %s'):format(n, nb, table.concat(names, ', ')))
      return
    end
  end
end

-- the ramjet / afterburner components in the race world (a sweep each: only twice a race)
local function ramjets(st, you)
  local rj, ab = C.find('Ramjet'), C.find('Afterburner')
  local yourAddr = alive(you) and C.addr(you) or nil
  local states, mine = {}, nil
  for _, r in ipairs(rj) do
    local s = try(function() return tonumber(r.RamjetState) end)
    states[#states + 1] = tostring(s)
    local owner = try(function() return r:GetOwner() end)
    if yourAddr and alive(owner) and C.addr(owner) == yourAddr then mine = s end
  end
  log(('[podrecon] ramjets: %d components (states %s), yours %s; afterburners: %d'):format(#rj, table.concat(states, ','),
    mine ~= nil and ('state ' .. tostring(mine)) or 'none found on your pawn', #ab))
end

-- your player state on race.lua's 2 s read; startedAt = the race start (clock) or nil
function PRC.onYou(st, ps, pawn, startedAt)
  local comp = try(function() return ps.AbilityComponent end)
  if not alive(comp) then
    if st.last ~= 'nocomp' then st.last = 'nocomp'; log('[podrecon] you: no AbilityComponent') end
    return
  end
  local parts = {}
  local slots = try(function() return comp.AbilitySlots end)
  local ns = slots and try(function() return slots:GetArrayNum() end) or 0
  local arr = try(function() return comp.Abilities end)
  local n = arr and try(function() return arr:GetArrayNum() end) or 0
  local list = {}
  for i = 1, n do
    local a = try(function() return arr[i] end)
    if alive(a) then
      local s = try(function() return tonumber(a.State) end)
      list[#list + 1] = { a = a, key = short(C.clsname(a)), s = s }
      parts[#parts + 1] = short(C.clsname(a)) .. ':' .. stateName(s)
    end
  end
  local line = ('%d slots, %d abilities [%s], energy %s, selected %s'):format(ns, n, table.concat(parts, ', '),
    tostring(try(function() return comp.CurrentAbilityEnergy end)), tostring(try(function() return comp.SelectedAbilityIx end)))
  if line ~= st.last then st.last = line; log('[podrecon] you: ' .. line) end
  if not startedAt then return end
  local since = C.clock - startedAt
  -- the ramjet count, twice
  if (st.ramjetChecks == 0 and since >= 20000) or (st.ramjetChecks == 1 and since >= 60000) then
    st.ramjetChecks = st.ramjetChecks + 1
    ramjets(st, pawn)
  end
  -- a fired ability's state, 2 s later
  if st.check and C.clock >= st.check.at then
    local now
    for _, x in ipairs(list) do if x.key == st.check.key then now = x.s end end
    log(('[podrecon] fired %s: %s -> %s 2 s later'):format(st.check.key, stateName(st.check.was), stateName(now)))
    st.check = nil
  end
  if not st.fire or since < 20000 or #list == 0 then return end
  if st.nextFire and C.clock < st.nextFire then return end
  st.nextFire = C.clock + 12000
  local pick
  for k = 1, #list do
    local x = list[((st.fired + k - 1) % #list) + 1]
    if not x.key:find('Autopilot', 1, true) then pick = x; break end
  end
  if not pick then return end
  st.fired = st.fired + 1
  local ok = pcall(function() pick.a:Server_Trigger(true) end)
  log(('[podrecon] fire %d: %s (state %s)%s'):format(st.fired, pick.key, stateName(pick.s), ok and '' or ' - the trigger failed'))
  st.check = { key = pick.key, was = pick.s, at = C.clock + 2000 }
end

return PRC
