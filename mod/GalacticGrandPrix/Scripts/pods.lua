-- v0.40.0 (owner 2026-11-25: "i like your ideas, draft up some tasks"; TASKS §1h P2-P3): the PODRACER CUP's races.
-- Recon: docs/podracing-recon-2026-11-25.md (tools/recon/PodTry, 4 pod races). A pod race is the bare pod track
-- launched through LaunchCustomRace (race.lua), with:
--   - the game mode GMV_Race's grid make-up set to config Pods.Grid (title.lua's gridCut: the originals in the save,
--     put back at the menu) and CharacterList.Opponents = the pod racers (the same call);
--   - you in your pilot's podracer: your pilot if they own one (Pods.Owners), else Shade; that pilot's and the other
--     car racers' in the field PreferredVehicleType set to 1 (the plane) for the race;
--   - the track's own cinematic chains taken off (TrackTry / PodTry: a track's chains can carry story scenes).
-- Everything changed is written into the save (K.data.podRestore) BEFORE it changes, and put back when the main menu
-- returns (race.lua R.restoreBuild) - or at the next start after a crash. Nothing kept between ticks.
-- Deliberately left as the game has it (v0.40): the pod build (no league parts, abilities or tune-ups written), the bots'
-- kits, the looks, the paint. Pacing is the owner's (P8).
local C = require('core')
local cfg = require('config')
local K = require('gp')
local log, try, alive = C.log, C.try, C.alive

local P = {}
local function conf() return type(cfg.Pods) == 'table' and cfg.Pods or {} end
function P.on() return conf().On ~= false end

local RACERS = '/Game/Griffin/Narrative/CharacterDefs/Racers/'
local CHAINS = { 'IntroCinematic', 'PreRaceCinematicChain', 'SideBettingCinematicChain', 'IgnitionCinematicChain',
  'EventCompleteCinematicChain', 'EventFailedCinematicChain', 'ResultsCinematicChain' }

-- v0.42 (TASKS §1h-L PL2b): the pilots with a pod (config Pods.Pilots: { key, pod }), in the PILOT tile's order
function P.pilots()
  local list = conf().Pilots
  if type(list) == 'table' and #list > 0 then return list end
  local out = {}
  for k in pairs(conf().Owners or {}) do out[#out + 1] = { key = k } end
  table.sort(out, function(a, b) return a.key < b.key end)
  return out
end
function P.pilot(key)
  for _, p in ipairs(P.pilots()) do if p.key == key then return p end end
  return nil
end
local function locked(key)
  local okR, RC = pcall(require, 'racer')
  return okR and RC.locked and RC.locked(key) or false
end
P.locked = locked
-- the pilot you race as: `current` when they own a pod (and are not locked: Kestar until beaten), else Shade
function P.racerKey(current)
  if current and P.pilot(current) and not locked(current) then return current end
  return conf().Fallback or 'DarkEnigma'
end
-- the pod pilot picked on the pods start screen (saved apart from your car pilot: podRacer); before any pick your car
-- pilot when they own a pod, else Shade
function P.chosen()
  local k = K.data and K.data.podRacer
  if k and P.pilot(k) and not locked(k) then return k end
  local okR, RC = pcall(require, 'racer')
  local cur = okR and RC.current and (RC.current() or {}).key or nil
  return P.racerKey(cur)
end
-- Select on the PILOT tile: the next pilot with a pod (a locked one skipped), saved -> the new key
function P.cycle(dir)
  local list, cur = P.pilots(), P.chosen()
  local at = 1
  for i, p in ipairs(list) do if p.key == cur then at = i end end
  for step = 1, #list do
    local p = list[((at - 1 + step * (dir or 1)) % #list) + 1]
    if not locked(p.key) then
      K.data.podRacer = p.key
      K.save()
      return p.key
    end
  end
  return cur
end
-- the pod's name for a pilot ('MythP3'), or nil
function P.podName(key) local p = P.pilot(key); return p and p.pod or nil end
-- the field's racer def paths (Pods.Field: 'DA_PlaneRacer_Cabbage', ..., 'DA_Racer_Antagonist'), minus the one you race as
-- (v0.42: and their pod-racer twin, config Pods.Twins - racing as Sebulba put him on the grid twice)
function P.fieldPaths(youKey)
  local out = {}
  local twin = (conf().Twins or {})[tostring(youKey)]
  for _, n in ipairs(conf().Field or {}) do
    if n ~= 'DA_Racer_' .. tostring(youKey) and n ~= twin then out[#out + 1] = RACERS .. n end
  end
  return out
end
-- the car racers whose vehicle must be the pod for the race: you, and every DA_Racer_ in the field (+ Shade, who takes
-- your grid slot when you race as one of them - racer.lua)
function P.lendKeys(youKey)
  local keys, seen = {}, {}
  local function add(k) if k and not seen[k] then seen[k] = true; keys[#keys + 1] = k end end
  add(youKey)
  for _, n in ipairs(conf().Field or {}) do add(n:match('^DA_Racer_(.+)$')) end
  add('DarkEnigma')
  return keys
end

function P.pending() return type(K.data.podRestore) == 'table' end

-- before LaunchCustomRace: e = the TrackDef, youKey = the pilot you race as. Returns the game mode to launch with, or
-- nil + why (then nothing is left changed)
function P.prepare(e, youKey)
  if P.pending() then log('[pods] an earlier pod race was still to be put back - done before this launch'); P.restore('before launch') end
  local modePath = conf().Mode or '/Game/Griffin/Gameplay/Campaign/GameModes/GMV_Race'
  local gmv = C.asset(modePath)
  if not alive(gmv) then return nil, 'game mode not found: ' .. modePath end
  -- what will change, into the save first
  local rec = { chains = {}, pref = {} }
  local trackPath = try(function() return e:GetFullName() end)
  trackPath = trackPath and trackPath:match('^%S+%s+(.+)$')
  for _, f in ipairs(CHAINS) do
    local c = try(function() return e[f] end)
    if alive(c) then
      local cp = try(function() return c:GetFullName() end)
      cp = cp and cp:match('^%S+%s+(.+)$')
      if trackPath and cp then rec.chains[#rec.chains + 1] = { trackPath, f, cp } end
    end
  end
  local defs = {}
  for _, k in ipairs(P.lendKeys(youKey)) do
    local d = C.asset(RACERS .. 'DA_Racer_' .. k)
    local was = d and try(function() return tonumber(d.PreferredVehicleType) end)
    if was and was ~= 1 then rec.pref[#rec.pref + 1] = { RACERS .. 'DA_Racer_' .. k, was }; defs[#defs + 1] = { d = d, k = k } end
  end
  K.data.podRestore = rec
  K.save()
  -- now the changes
  local cleared = 0
  for _, c in ipairs(rec.chains) do
    if pcall(function() e[c[2]] = CreateInvalidObject() end) then cleared = cleared + 1 end
  end
  local lent = {}
  for _, x in ipairs(defs) do
    if pcall(function() x.d.PreferredVehicleType = 1 end) then lent[#lent + 1] = x.k end
  end
  -- the grid: the make-up of the game mode and the opponents (title.lua; its own save record, gridRestore)
  local paths = P.fieldPaths(youKey)
  local n = math.min(#paths, (tonumber(conf().Grid) or 8) - 1)
  local cut = {}
  for i = 1, n do cut[i] = paths[i] end
  local okG, got = pcall(function() return require('title').gridCut(gmv, modePath, cut, 'the pods') end)
  if not (okG and got) then log('[pods] grid not set: ' .. tostring(got) .. ' - the mode\'s own grid') end
  log(('[pods] ready: %d cinematic chains off the track, pods for %s, a grid of %d'):format(cleared,
    #lent > 0 and table.concat(lent, ', ') or 'nobody new', n + 1))
  return gmv
end

-- the main menu is back (race.lua R.restoreBuild), a failed launch, or a start after a crash
function P.restore(why)
  local rec = K.data.podRestore
  if type(rec) ~= 'table' then return 0 end
  -- (full object names, '/Game/.../TRAK_X.TRAK_X': found as they are, else loaded by their package path)
  local function byName(full)
    local o = try(StaticFindObject, full)
    if alive(o) then return o end
    return C.asset((tostring(full):gsub('%.[^./]+$', '')))
  end
  local n = 0
  for _, c in ipairs(rec.chains or {}) do
    local o, v = byName(c[1]), byName(c[3])
    if o and v and pcall(function() o[c[2]] = v end) then n = n + 1 end
  end
  local m = 0
  for _, x in ipairs(rec.pref or {}) do
    local d = C.asset(x[1])
    if d and pcall(function() d.PreferredVehicleType = x[2] end) then m = m + 1 end
  end
  K.data.podRestore = nil
  K.save()
  log(('[pods] put back (%s): %d cinematic chains, %d pilots\' vehicles'):format(tostring(why), n, m))
  return n + m
end

return P
