-- Galactic Grand Prix v0.32: track hazards that don't belong in a cup race.
--
-- The Precision run's buoys (PrecisionRunBuoy: the floating blue markers of the game's Precision mode) sit in the
-- route layer of The Galactic Gauntlet and load in EVERY race there - a car passing close at speed is shoved or
-- crashed by them (the FreeRace mod found this; docs/freerace-review-2026-11-25.md §3.3). Our Galactic Cup final runs
-- that track. So in a race on an event the config names (Hazards.BuoyEvents, patterns on the event's path) every buoy
-- is hidden and its collision and ticking (the shove / crash checks) switched off. Never destroyed: the game's rewind
-- keeps track of them. The game can show one again (at the start, after a rewind), so they are checked now and then
-- for the whole race and hidden again.
--
-- How, within the house rules (AUTOMATION.md: no objects kept between ticks, sweeps only where they're cheap):
--   * a sweep (FindAllOf PrecisionRunBuoy, ~20 ms) every ScanS while the race loads and until ScanUntilS after the
--     race world came (the route layer can stream in late), then one every RecheckS for the rest of the race - the
--     re-hide pass. Nothing is kept from a sweep.
--   * buoys made later are told by NotifyOnNewObject and kept as path + address (C.ref), looked up once ~0.5 s later
--     (they need a moment to start up) and hidden; the ref is dropped either way.
-- Level actors: nothing to put back - they go with the race world.
local C = require('core')
local cfg = require('config')
local try, alive, log = C.try, C.alive, C.log

local HZ = { live = nil }
HZ.BUOY = 'PrecisionRunBuoy'
local WAIT_MS = 500            -- a new buoy is looked at this long after it was made
local MAX_FRESH = 200

local function conf() return type(cfg.Hazards) == 'table' and cfg.Hazards or {} end
local function secs(k, d) return (tonumber(conf()[k]) or d) * 1000 end

-- does this event's track carry the buoys? (Hazards.BuoyEvents = patterns on the event path; {} = every race)
function HZ.wants(ev)
  local c = conf()
  if c.Buoys == false then return false end
  local pats = c.BuoyEvents
  if type(pats) ~= 'table' or #pats == 0 then return true end
  local path = tostring(ev and ev.path or '')
  for _, p in ipairs(pats) do if path:find(p, 1, true) then return true end end
  return false
end

function HZ.begin(ev)
  local st = { at = C.clock, done = {}, n = 0, back = 0, backLogs = 0, lastScan = -1e9, lastCheck = -1e9, fresh = {}, scans = 0 }
  HZ.live = st
  log(('[hazards] %s: the Precision buoys will be hidden (scans every %d s for %d s, then every %d s)'):format(
    tostring(ev and ev.title or '?'), secs('ScanS', 3) // 1000, secs('ScanUntilS', 45) // 1000, secs('RecheckS', 10) // 1000))
  return st
end
function HZ.stop() HZ.live = nil end

-- the game tells us a buoy was made: its path + address only (never the object)
pcall(NotifyOnNewObject, '/Script/Griffin.' .. HZ.BUOY, function(o)
  local st = HZ.live
  if not st or #st.fresh >= MAX_FRESH then return end
  local r = C.ref(o)
  if r then st.fresh[#st.fresh + 1] = { ref = r, at = C.clock } end
end)

local function off(a)
  local ok = pcall(function() a:SetActorHiddenInGame(true) end)
  pcall(function() a:SetActorEnableCollision(false) end)
  pcall(function() a:SetActorTickEnabled(false) end)
  return ok
end
local function showing(a)
  return try(function() return a.bHidden end) == false or try(function() return a:GetActorEnableCollision() end) == true
end
-- one buoy: hidden once (by address); true when it was new
local function take(st, a)
  if not alive(a) then return false end
  local k = C.addr(a)
  if not k or st.done[k] then return false end
  st.done[k] = true
  off(a)
  st.n = st.n + 1
  return true
end

-- every tick of the race (race.lua R.watch, racing phase); racingAt = when the race world came
function HZ.tick(st, racingAt)
  if not st then return end
  -- late ones, a moment after they were made (one lookup each, once)
  if #st.fresh > 0 then
    local keep, late = {}, 0
    for _, e in ipairs(st.fresh) do
      if C.clock - e.at >= WAIT_MS then
        local a = C.deref(e.ref)
        if a and take(st, a) then late = late + 1 end
      else keep[#keep + 1] = e end
    end
    st.fresh = keep
    if late > 0 then
      st.late = (st.late or 0) + late
      log(('[hazards] precision buoys: %d hidden as they were made (%d this race)'):format(late, st.n))
    end
  end
  local since = C.clock - (racingAt or st.at)
  local loading = since <= secs('ScanUntilS', 45)
  local every = loading and secs('ScanS', 3) or secs('RecheckS', 10)
  if C.clock - st.lastScan < every then return end
  st.lastScan = C.clock
  st.scans = st.scans + 1
  local new, back = 0, 0
  for _, a in ipairs(C.find(HZ.BUOY)) do
    if take(st, a) then new = new + 1
    elseif showing(a) then off(a); back = back + 1 end
  end
  if new > 0 then log(('[hazards] precision buoys: %d hidden (%d this race)'):format(new, st.n)) end
  if back > 0 then
    st.back = st.back + back
    st.backLogs = st.backLogs + 1
    if st.backLogs <= 5 then log(('[hazards] precision buoys: %d shown again by the game, hidden again'):format(back)) end
  end
  if not loading and not st.said then
    st.said = true
    if st.n == 0 then log(('[hazards] no Precision buoys on this track (%d sweeps)'):format(st.scans)) end
  end
end

-- one line for the RESULT block
function HZ.summary(st)
  if not st then return nil end
  return ('[hazards] precision buoys: %d hidden, %d re-hidden, %d sweeps'):format(st.n, st.back, st.scans)
end

return HZ
