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
local C = require('core')
local cfg = require('config')
local K = require('gp')
local try, alive, log = C.try, C.alive, C.log

local RC = {}
local RACERS = '/Game/Griffin/Narrative/CharacterDefs/Racers/DA_Racer_'
local LIST = '/Game/Griffin/Narrative/CharacterDefs/DA_CharacterList'
local DEFAULT = { key = 'DarkEnigma', name = 'Shade', line = 'The campaign\'s racer' }
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
function RC.current() return RC.get(K.data.racer) or RC.list()[1] end
function RC.path(key) return RACERS .. key end
-- the next (dir = 1) or previous (-1) pilot, saved. Returns the entry. (v0.9: no lock while a cup runs - the garage
-- can't be reached mid-cup without leaving the cup, since cups cannot be resumed.)
function RC.cycle(dir)
  local list = RC.list()
  local cur, at = RC.current(), 1
  for i, r in ipairs(list) do if r.key == cur.key then at = i end end
  local r = list[((at - 1 + (dir or 1)) % #list) + 1]
  K.data.racer = r.key
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
local function setPlayer(list, def, path)
  local ok = pcall(function() list.Player = def end)
  return ok and playerPath(list) == path
end
local function setOpponent(list, i, def, path)
  local ok = pcall(function() list.Opponents[i] = def end)
  return ok and defPath(try(function() return list.Opponents[i] end)) == path
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
  if cur == wantPath then log(('[racer] racing as %s (DA_Racer_%s): the game\'s own pilot'):format(want.name, want.key)); return true end
  if not cur then log('[racer] CharacterList.Player unreadable - racing as the game\'s own pilot'); return false, 'player unreadable' end
  local def = C.asset(wantPath)
  if not def then log('[racer] pilot not found: ' .. wantPath); return false, 'pilot not found' end
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
