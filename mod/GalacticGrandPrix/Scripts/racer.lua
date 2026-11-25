-- Galactic Grand Prix: your racer (v0.8). Race as any of the game's named pilots (config Racers).
--
-- How (FreeRace's method, menu dumps 2026-11-10): the game instance's character list (the data asset
-- /Game/Griffin/Narrative/CharacterDefs/DA_CharacterList, class CharacterList) has `Player` = the RacerDef you race as
-- (the campaign's Shade, DA_Racer_DarkEnigma) and `Opponents` = the 11 RacerDefs on every quick-race grid. Before
-- launch `Player` is set to the pilot you picked; if that pilot is one of the Opponents, the original Player (Shade)
-- takes their slot so the grid stays 12. The race takes its own copy, so the list goes back once the race is under way
-- (RC.settle, from race.lua's 2 s read) and again at the main menu (RC.restore, from R.restoreBuild). What to put back
-- is in the save first (K.data.racerRestore), so a crash mid-race is put right at the next menu, like the part levels.
--
-- Memory only, nothing kept between ticks (the list is found again each time: a full sweep, at launch / the menu / the
-- one settle read), every engine access in try / pcall. Object pointers only (Player, Opponents[]): no soft pointers.
--
-- v0.15: config Racers[].vehicle (car / bike / skimmer) is that pilot's own category. RC.vehicle(key) is that.
-- The category you actually launch is separate (K.data.vehicle): RC.chosenVehicle(). Choosing a pilot sets it back
-- to theirs; the vehicle tile then cycles the three. At launch the picked racer's URacerDef.PreferredVehicleType
-- (a plain enum byte: 0 car, 2 bike, 3 skimmer) is read once
-- per racer per session from the def already in hand and a mismatch with config is logged (no extra sweep, no soft
-- pointers). Kestar Bool (unlockBoss, v0.21; was unlockTitle = '150') is locked until you beat him as the final boss
-- (title.lua): RC.cycle skips him, and a save that still has him picked races as Shade (logged once).
-- The racer's own look comes with the swap (LookSpike v2, 2026-11-11): the race's recipe list (RecipeState.Racers[])
-- already gives your entry the racer's preset (Nik Skandaro -> PRE_Car_Hammerhead_QuietStrength), and your vehicle
-- reads "Hammerhead Quiet Strength" through the race. Nothing to add here; the owner judges the screenshots.
local C = require('core')
local cfg = require('config')
local K = require('gp')
local try, alive, log = C.try, C.alive, C.log

local RC = {}
local RACERS = '/Game/Griffin/Narrative/CharacterDefs/Racers/DA_Racer_'
local LIST = '/Game/Griffin/Narrative/CharacterDefs/DA_CharacterList'
local DEFAULT = { key = 'DarkEnigma', name = 'Shade', vehicle = 'car', line = 'The campaign\'s racer' }
-- the list goes back this long after the race world appeared: past the grid and the countdown, so the race has
-- surely taken its copy (FreeRace puts it back "once started"); race.lua checks it inside its 2 s read
RC.SETTLE_MS = 10000

---------------------------------------------------------------------------------------------------------------------
-- the pick (save: K.data.racer = key; nil = the first = the game's own)

function RC.list()
  local l = cfg.Racers
  return (type(l) == 'table' and #l > 0) and l or { DEFAULT }
end
function RC.get(key)
  for _, r in ipairs(RC.list()) do if r.key == key then return r end end
  return nil
end
-- v0.15: is the racer (an entry or a key) still locked? v0.21: only a racer with unlockBoss is: until you beat the final
-- boss (title.lua, K.data.boss.beaten)
function RC.locked(r)
  if type(r) == 'string' then r = RC.get(r) end
  if not (type(r) == 'table' and r.unlockBoss) then return false end
  return not require('title').bossBeaten(K.data)
end
-- 'To unlock: beat Kestar Bool after the ACE title' (nil when the racer has no lock)
function RC.unlockText(r)
  if type(r) == 'string' then r = RC.get(r) end
  if not (type(r) == 'table' and r.unlockBoss) then return nil end
  local TI = require('title')
  local c = K.league(TI.bossClass())
  return ('To unlock: beat %s after the %s title'):format(TI.bossName(), c and c.name or TI.bossClass())
end
-- the pick; a locked pick (an old save, or a lock come back) is Shade, saved and logged
function RC.current()
  local r = RC.get(K.data.racer)
  if r and RC.locked(r) then
    local fb = RC.list()[1]
    log(('[racer] %s is locked (%s) - racing as %s'):format(r.name, RC.unlockText(r):lower(), fb.name))
    K.data.racer = fb.key
    K.data.vehicle = fb.vehicle
    local okA, AB = pcall(require, 'abil')
    if okA then K.data.picks = AB.racerPicks(fb.key); K.data.picksRacer = fb.key end
    K.save()
    r = nil
  end
  return r or RC.list()[1]
end
function RC.path(key) return RACERS .. key end
-- v0.15: the pilot's own category (a config Vehicles entry). No key = the current pilot's. The launch uses RC.chosenVehicle.
function RC.vehicle(key)
  local r = key == nil and RC.current() or RC.get(key)
  return K.vehicle(r and r.vehicle or 'car')
end
-- the category this launch uses. A saved one wins; otherwise the current pilot's own.
function RC.chosenVehicle()
  local k = K.data.vehicle
  local v = k and K.vehicle(k)
  if v and v.key == k then return v end
  return RC.vehicle()
end
-- the next (dir = 1) or previous (-1) of the three categories, saved. The pilot's own is what a new pilot starts on.
function RC.cycleVehicle(dir)
  local list = K.vehicles()
  if #list == 0 then return nil end
  local cur = RC.chosenVehicle().key
  local at = 1
  for i, v in ipairs(list) do if v.key == cur then at = i end end
  at = ((at - 1 + (dir or 1)) % #list) + 1
  K.data.vehicle = list[at].key
  K.save()
  return list[at]
end
-- the vehicle type in words for the menu: 'Speeder bike'. No key = the category you launch with.
function RC.vehicleText(key)
  local n = tostring((key == nil and RC.chosenVehicle() or RC.vehicle(key)).name or '?')
  return n:sub(1, 1):upper() .. n:sub(2):lower()
end
-- the next (dir = 1) or previous (-1) pilot, saved. Returns the entry. (v0.9: no lock while a cup runs - the garage
-- can't be reached mid-cup without leaving the cup, since cups cannot be resumed.) v0.15: a locked racer is skipped.
function RC.cycle(dir)
  local list = RC.list()
  local cur, at = RC.current(), 1
  for i, r in ipairs(list) do if r.key == cur.key then at = i end end
  local r = cur
  for _ = 1, #list do
    at = ((at - 1 + (dir or 1)) % #list) + 1
    if not RC.locked(list[at]) then r = list[at]; break end
  end
  K.data.racer = r.key
  K.data.vehicle = r.vehicle
  K.save()
  return r
end
-- the pilot's name for the UI: the pick (no key), or a given key ('?' for an unknown one)
function RC.displayName(key)
  local r = key == nil and RC.current() or RC.get(key)
  return r and r.name or '?'
end
-- something still to put back (a swap not yet settled, or left over from a crash)
function RC.pending() return type(K.data.racerRestore) == 'table' end

---------------------------------------------------------------------------------------------------------------------
-- the engine side

-- 'RacerDef /Game/.../DA_Racer_X.DA_Racer_X' -> '/Game/.../DA_Racer_X' (what C.asset takes)
local function defPath(o)
  local full = alive(o) and try(function() return o:GetFullName() end)
  if type(full) ~= 'string' then return nil end
  return full:match('^%S+%s+(.-)%.[^/]+$') or full:match('^%S+%s+(.+)$')
end
local function keyOf(path) return path and path:match('DA_Racer_([%w_]+)$') or nil end
-- the name shown for a def path: config, else the def's own CharacterName, else the key
local function nameOf(path)
  local k = keyOf(path)
  local r = k and RC.get(k)
  if r then return r.name end
  local def = path and C.asset(path)
  return (def and C.text(def, 'CharacterName')) or k or tostring(path)
end
-- the character list: a loaded asset at the menu (one sweep), else through the game instance, else loaded by path
local function findList()
  local l = C.first('CharacterList')
  if alive(l) then return l end
  local gi = C.first('GfnGameInstance')
  l = alive(gi) and try(function() return gi.CharacterList end) or nil
  if alive(l) then return l end
  return C.asset(LIST)
end
local function playerPath(list) return defPath(try(function() return list.Player end)) end
local function opponentPaths(list)
  local out = {}
  try(function() list.Opponents:ForEach(function(_, el) out[#out + 1] = defPath(el:get()) or '' end) end)
  return out
end
-- (v0.21: title.lua's two-car grid uses the same list)
RC.findList, RC.opponentPaths, RC.defPath = findList, opponentPaths, defPath
local function setPlayer(list, def, path)
  local ok = pcall(function() list.Player = def end)
  return ok and playerPath(list) == path
end
local function setOpponent(list, i, def, path)
  local ok = pcall(function() list.Opponents[i] = def end)
  return ok and defPath(try(function() return list.Opponents[i] end)) == path
end

-- v0.15: the game's own vehicle type for the racer (URacerDef.PreferredVehicleType, a plain enum byte) against
-- config, once per racer per session, from a def already in hand (no lookup of its own). Logs only a mismatch.
local typeChecked = {}
local function checkType(want, def)
  if typeChecked[want.key] or not alive(def) then return end
  typeChecked[want.key] = true
  local b = try(function() return tonumber(def.PreferredVehicleType) end)
  local veh = RC.vehicle(want.key)
  if b ~= nil and b ~= veh.arch then
    log(('[racer] %s: the game\'s PreferredVehicleType is %s, config says %s (arch %s) - racing the config\'s %s'):format(
      want.name, tostring(b), tostring(veh.key), tostring(veh.arch), tostring(veh.key)))
  end
end

-- at launch (race.lua, before LaunchQuickRace): the picked pilot into CharacterList.Player. Returns true when the
-- list is as wanted (also when the pick is already the game's own pilot), false + why when not (the race still
-- launches, as the game's own pilot).
function RC.begin(key)
  local want = RC.get(key) or RC.list()[1]
  if RC.pending() then
    log('[racer] an earlier swap was still to be put back - done before this launch')
    RC.restore('before launch')
  end
  local list = findList()
  if not list then log('[racer] character list not found - racing as the game\'s own pilot'); return false, 'no character list' end
  local cur = playerPath(list)
  local wantPath = RC.path(want.key)
  if cur == wantPath then
    checkType(want, try(function() return list.Player end))
    log(('[racer] racing as %s (DA_Racer_%s): the game\'s own pilot'):format(want.name, want.key)); return true
  end
  if not cur then log('[racer] CharacterList.Player unreadable - racing as the game\'s own pilot'); return false, 'player unreadable' end
  local def = C.asset(wantPath)
  if not def then log('[racer] pilot not found: ' .. wantPath); return false, 'pilot not found' end
  checkType(want, def)
  -- what to put back, in the save before anything changes
  local rec = { key = want.key, player = cur, list = defPath(list) or LIST }
  for i, p in ipairs(opponentPaths(list)) do
    if p == wantPath then rec.opp = { i = i, path = p } end
  end
  K.data.racerRestore = rec
  K.save()
  if not setPlayer(list, def, wantPath) then
    log('[racer] CharacterList.Player refused DA_Racer_' .. want.key .. ' - racing as the game\'s own pilot')
    K.data.racerRestore = nil
    K.save()
    return false, 'player refused'
  end
  local swap = ''
  if rec.opp then
    -- the pick is one of the 11 opponents: the original pilot (Shade) takes their grid slot, the field stays 12
    local orig = C.asset(cur)
    if orig and setOpponent(list, rec.opp.i, orig, cur) then
      swap = ('; %s out of Opponents[%d], %s in'):format(want.name, rec.opp.i, nameOf(cur))
    else
      log(('[racer] Opponents[%d] refused %s - %s may be on the grid twice'):format(rec.opp.i, nameOf(cur), want.name))
      rec.opp = nil
      K.save()
    end
  end
  log(('[racer] racing as %s (DA_Racer_%s): CharacterList.Player set (was %s)%s'):format(want.name, want.key, nameOf(cur), swap))
  return true
end

-- the list back as it was, from the save's record. why = for the log; racing = true for the in-race settle line.
local function putBack(why, racing)
  local rec = K.data.racerRestore
  if type(rec) ~= 'table' then return false end
  local list = findList()
  if not list then
    log(('[racer] put back (%s): character list not found - left as is'):format(why))
    K.data.racerRestore = nil
    K.save()
    return false
  end
  local name = RC.displayName(rec.key)
  local orig = rec.player and C.asset(rec.player)
  local okP = orig and setPlayer(list, orig, rec.player)
  local oppLine = ''
  if rec.opp then
    local d = C.asset(rec.opp.path)
    local okO = d and setOpponent(list, rec.opp.i, d, rec.opp.path)
    oppLine = (' (Opponents[%d] = %s again%s)'):format(rec.opp.i, nameOf(rec.opp.path), okO and '' or ' - FAILED')
  end
  K.data.racerRestore = nil
  K.save()
  local who = nameOf(rec.player)
  if racing then
    log(('[racer] racing as %s (DA_Racer_%s); %s put back%s%s'):format(name, tostring(rec.key), who, okP and '' or ' - FAILED', oppLine))
  else
    log(('[racer] %s put back (%s)%s%s'):format(who, why, okP and '' or ' - FAILED', oppLine))
  end
  return okP == true
end

-- in the race (race.lua, inside the 2 s read, RC.SETTLE_MS after the race world appeared): the race has its own copy
-- of the pilot, the list goes back
function RC.settle()
  if not RC.pending() then return false end
  return putBack('settle', true)
end
-- at the main menu (R.restoreBuild: after a race, a failed launch, or left over from a crash)
function RC.restore(why)
  if not RC.pending() then return false end
  return putBack(why or 'main menu', false)
end

return RC
