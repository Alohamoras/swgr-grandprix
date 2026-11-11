-- Galactic Grand Prix: the title race (v0.8, research doc 2026-11-10 §"Rosters per class and the champion race").
-- One 1 v 1 at the end of each class against the class's champion: today the game's Stadium Showdown against Kestar
-- Bool (a proven launch; he copies your build, so he scales with the class). Opens with a trophy in every planet cup
-- at the class (prog.lua P.titleOpen). Winning it makes you the class champion (saved: titles[class]); the class tile
-- says so. Config: Title. Pure logic here; the launch goes through race.lua like any race (ev.titleRace = true).
local C = require('core')
local cfg = require('config')
local K = require('gp')
local log = C.log

local T = {}
local function conf() return cfg.Title or {} end
function T.on() return conf().On ~= false end

-- the class's champion: the title holder if you took it ('YOU'), else the racer with most points across the planet
-- cups at that class, else the fixed name from config (the lore: a title holder before any cup is raced)
function T.champion(classKey)
  local t = (K.data.titles or {})[classKey]
  if t and t.won then return 'YOU', 'title' end
  local name = K.champion and K.champion(classKey)
  if name then return name, 'points' end
  local fb = (conf().Fallback or {})[classKey]
  return fb or conf().Opponent or 'Kestar Bool', 'fixed'
end
-- the opponent of the title race (v0.8: always the Showdown's own driver, Kestar Bool; the class leader as the
-- opponent needs a two-car grid on a normal event, not yet checked in game)
function T.opponent(classKey) return conf().Opponent or 'Kestar Bool' end
function T.status(classKey) return (K.data.titles or {})[classKey] end

-- the launchable event: like K.nextRace, plus the title flag the result read looks for
function T.event(classKey)
  if not conf().Event then return nil end
  return { path = conf().Event, title = conf().Name or 'TITLE RACE', kind = '1 v 1', class = classKey, titleRace = true }
end

-- The Showdown event carries the campaign's story cinematics: EventCompleteCinematicChain = the Act 2 victory scene,
-- which outside the campaign leads to a black screen (seen in game, 2026-11-10: the race finished, the cutscene
-- was skipped by Streamline, then nothing). So before a title race these chains are taken off the event (memory
-- only) and put back at the menu; the originals' paths live in the save (titleRestore) so a crash is put right too.
T.CHAINS = { 'EventCompleteCinematicChain', 'EventFailedCinematicChain' }
local try, alive = C.try, C.alive
function T.prepare(e, path)
  local rec = { path = path, fields = {} }
  local n = 0
  for _, f in ipairs(T.CHAINS) do
    local o = try(function() return e[f] end)
    if alive(o) then
      local full = try(function() return o:GetFullName() end)
      if type(full) == 'string' then
        local obj = full:match('^%S+%s+(.+)$') or full
        rec.fields[f] = obj:match('^(.*)%.[^./]+$') or obj -- the package path (C.asset adds the object name)
        if pcall(function() e[f] = CreateInvalidObject() end) then n = n + 1 end
      end
    end
  end
  if n > 0 then
    K.data.titleRestore = rec
    K.save()
    local names = {}
    for f, p in pairs(rec.fields) do names[#names + 1] = f .. '=' .. p:match('([^/.]+)$') end
    log(('[title] story cinematics taken off %s for this race: %s'):format(path:match('([^/]+)$'), table.concat(names, ', ')))
  end
  return n
end
function T.pending() return type(K.data.titleRestore) == 'table' end
function T.restore(why)
  local rec = K.data.titleRestore
  if type(rec) ~= 'table' then return 0 end
  local e = C.asset(rec.path)
  local n = 0
  for f, p in pairs(rec.fields or {}) do
    local o = C.asset(p)
    if e and o and pcall(function() e[f] = o end) then n = n + 1 end
  end
  K.data.titleRestore = nil
  K.save()
  log(('[title] story cinematics put back (%s): %d'):format(why or '?', n))
  return n
end

-- a finished title race (called from K.record): won = 1st of the two. Returns what the result screen shows.
function T.record(ev, pos)
  local cls = ev.class
  K.data.titles = K.data.titles or {}
  local t = K.data.titles[cls] or { tries = 0 }
  t.tries = (t.tries or 0) + 1
  local won, was = pos == 1, t.won == true
  if won then t.won, t.at, t.vs = true, os.date('%Y-%m-%d'), T.opponent(cls) end
  K.data.titles[cls] = t
  log(('TITLE RACE %s: %s vs %s (try %d)'):format(cls, won and 'WON - you are the champion' or (pos and ('lost, ' .. C.ordinal(pos)) or 'DNF'),
    T.opponent(cls), t.tries))
  return { titleRace = true, won = won, vs = T.opponent(cls), tries = t.tries, firstWin = won and not was }
end

return T
