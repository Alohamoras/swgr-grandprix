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
