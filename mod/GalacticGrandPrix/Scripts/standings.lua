-- Galactic Grand Prix: the standings text after a cup race (v0.19: moved out of main.lua so the main menu's standings
-- page and the panel over the game's results screen (chain.lua) are built from the same lines and table).
-- Pure: strings and numbers from a race result (gp.lua K.record's out), no game objects.
-- v0.20: the cup result is a screen of its own (SD.cupSpec: the medal large, PERFECT CUP, the top 3, one "what's next"
-- line; menu review 1); no best lap on a sprint (menu review 6). v0.21: no rival (owner) - no marks, no call-outs.
-- (The cup's own stakes line still names the racer you chase or lead: cup.lua CU.stakes.)
local C = require('core')
local cfg = require('config')
local K = require('gp')
local CU = require('cup')
local PR = require('prog')
local U = require('ui')
local ART = require('art')
local ordinal = C.ordinal

local SD = {}

function SD.shortName(key) return key == CU.YOU and 'YOU' or key end

-- after a race: ONE screen (owner, 2026-11-10: fewer screens) - the ranking by points, as a table: place, racer,
-- points this race, total, places moved.
local GREEN, RED = { 0.45, 0.9, 0.5 }, { 1, 0.5, 0.45 }
function SD.rankingTable(run)
  local rows = {}
  for _, r in ipairs(CU.table(run)) do
    local move, mc = '', nil
    if r.move and r.move > 0 then move, mc = '+' .. r.move, GREEN
    elseif r.move and r.move < 0 then move, mc = tostring(r.move), RED end
    rows[#rows + 1] = {
      cells = { ordinal(r.rank), SD.shortName(r.key), r.dnf and 'DNF' or (r.raced and ('+' .. r.gain) or '-'), tostring(r.total), move },
      color = r.you and U.GOLD or U.WHITE, colors = { [5] = mc }, highlight = r.you,
    }
  end
  return { size = 20, header = { '', 'RACER', 'THIS RACE', 'POINTS', 'MOVED' },
    cols = { { w = 90, align = 'right' }, { w = 460 }, { w = 220, align = 'right' }, { w = 180, align = 'right' }, { w = 160, align = 'right' } },
    rows = rows }
end

-- v0.20: the cup result's table: the final top 3 (and your row under them when you are lower), place / racer / points
function SD.podiumTable(run)
  local rows = {}
  for _, r in ipairs(CU.standings(run)) do
    if r.rank <= 3 or r.key == CU.YOU then
      rows[#rows + 1] = { cells = { ordinal(r.rank), SD.shortName(r.key), tostring(r.pts) },
        color = r.key == CU.YOU and U.GOLD or U.WHITE, highlight = r.key == CU.YOU }
    end
  end
  return { size = 24, cols = { { w = 90, align = 'right' }, { w = 460 }, { w = 120, align = 'right' } }, rows = rows }
end

-- a sprint (one lap): its best lap is the race, so it isn't shown
local function sprint(ev)
  return ev and (tonumber(ev.laps) == 1 or tostring(ev.kind or ''):lower() == 'sprint') or false
end
SD.sprint = sprint

-- v0.20 (menu review 8): the seconds to the car ahead of you (or, when you won, to the one behind), from the race's
-- gaps (K.gaps): '0.4 s behind Biddy Blas' / '7.8 s ahead'; nil without finish times
function SD.margin(g)
  if type(g) ~= 'table' or not g.you then return nil end
  if g.place == 1 then return g.behind and ('%.1f s ahead'):format(math.abs(g.behind.gap)) or nil end
  local a = g.ahead or g.winner
  return a and ('%.1f s behind %s'):format(math.abs(a.gap), SD.shortName(a.name)) or nil
end
-- your line: 'You: 2nd in this race   -   1:45.07  (best lap 0:48.12)   -   0.4 s behind Biddy Blas' (no best lap
-- on a sprint)
local function yourLine(r, ev, head)
  local you = (head or 'You: %s in this race'):format(r.pos and ordinal(r.pos) or 'did not finish')
  if r.time and K.fmtTime then
    you = you .. ('   -   %s'):format(K.fmtTime(r.time)) .. ((r.lap and not sprint(ev)) and ('  (best lap %s)'):format(K.fmtTime(r.lap)) or '')
  end
  local m = SD.margin(r.gaps)
  if m then you = you .. '   -   ' .. m end
  return you
end
-- the record / best lap / near-record notes of a race -> list, big
local function raceNotes(r, ev)
  local note, big = {}, false
  if r.newRecord and K.fmtTime then
    note[#note + 1] = ('NEW RECORD  %s%s'):format(K.fmtTime(r.time), r.oldTime and ('   (was %s)'):format(K.fmtTime(r.oldTime)) or ''); big = true
  else
    local near = K.nearRecord and K.nearRecord(r)
    if near then note[#note + 1] = near; big = true end
    if r.newLap and K.fmtTime and r.lap and not sprint(ev) then note[#note + 1] = ('NEW BEST LAP  %s'):format(K.fmtTime(r.lap)) end
  end
  return note, big
end

-- v0.20: the cup result's "what's next" line: what the cup unlocked, else the nearest unlock at the class (prog.lua's
-- rules) - nil when neither (the near miss, "1 POINT FROM GOLD", is on the race line already)
function SD.whatsNext(r)
  if r.unlocked and #r.unlocked > 0 then return 'UNLOCKED:  ' .. table.concat(r.unlocked, '   -   ') end
  local run = r.run
  local nu = run and PR.nextUnlock and PR.nextUnlock(K.data, run.class)
  return nu and ('Next: ' .. nu.text) or nil
end

-- v0.20 (menu review 1): the cup result, a screen of its own. hero = the medal large with the trophy, the cup and
-- PERFECT CUP beside it; table = the top 3 (+ you); after = the last race in one line, what's next.
local TROPHY_INDEX = { GOLD = 1, SILVER = 2, BRONZE = 3 }
SD.TROPHY_INDEX = TROPHY_INDEX
function SD.cupSpec(r)
  r = r or {}
  local ev = r.ev or { title = '?' }
  local run = r.run
  local cup = run and K.cup(run.cup) or { name = '?' }
  local cls = run and K.class(run.class) or { name = '?' }
  local idx = r.trophy and TROPHY_INDEX[r.trophy]
  local medalColor = idx and ART.medalColor(idx) or nil
  local hero = { icon = idx and ART.medal(idx) or nil, color = medalColor, size = 190, lines = {} }
  hero.lines[#hero.lines + 1] = { r.trophy and (r.trophy .. ' TROPHY') or ('%s PLACE'):format(ordinal(r.rank or 0):upper()), 48,
    medalColor or U.GREY }
  hero.lines[#hero.lines + 1] = { ('%s   -   %s   -   %d points%s'):format(cup.name, cls.name, r.pts or 0, r.newBest and '   -   NEW BEST' or ''), 22, U.WHITE }
  if r.perfect then hero.lines[#hero.lines + 1] = { 'PERFECT CUP', 30, U.GOLD } end
  local after = {}
  -- the last race in one line: your place and time, then its record / near misses and the cup's near miss
  local line = yourLine(r, ev, 'Last race: %s')
  local note = raceNotes(r, ev)
  local nearCup = run and CU.nearTrophy(run, (cfg.Near or {}).TrophyPoints) or nil
  if nearCup then note[#note + 1] = nearCup end
  if #note > 0 then line = line .. '   -   ' .. table.concat(note, '   -   ') end
  after[#after + 1] = { line, 20, #note > 0 and U.GOLD or U.GREY }
  local nxt = SD.whatsNext(r)
  if nxt then after[#after + 1] = { nxt, 24, U.GOLD } end
  return { key = 'standings', title = 'CUP RESULT', hero = hero, lines = {}, after = after,
    table = run and SD.podiumTable(run) or nil, backdrop = ART.BACKDROP, cupOver = true }
end

-- the standings screen's text from a race result r (K.record's out): { key, title, lines, table, backdrop } (no tiles:
-- the main menu's page adds NEXT RACE / CONTINUE, the results-screen panel its own prompt). The cup result: SD.cupSpec.
function SD.spec(r)
  r = r or {}
  if r.cupOver then return SD.cupSpec(r) end
  local ev = r.ev or { title = '?' }
  local run = r.run
  local cup = run and K.cup(run.cup) or { name = '?' }
  local lines = {}
  lines[#lines + 1] = { ('%s   -   %s   -   race %d of %d'):format(cup.name, ev.title, ev.race or 0, run and run.races or 4), 22, U.WHITE }
  lines[#lines + 1] = { yourLine(r, ev), 18 }
  -- v0.12 (docs/PHILOSOPHY.md points 2 and 4): between races one stakes line from the points left (it names the racer
  -- you chase or lead); then ONE line for the record, the best lap and the near misses together
  local stakes = run and K.run() and CU.stakes(run, cfg.Points) or nil
  if stakes then lines[#lines + 1] = { stakes, 22, U.WHITE } end
  local note, big = raceNotes(r, ev)
  if #note > 0 then lines[#lines + 1] = { table.concat(note, '   -   '), big and 22 or 20, U.GOLD } end
  return { key = 'standings', title = 'STANDINGS', lines = lines,
    table = run and SD.rankingTable(run) or nil, backdrop = ART.BACKDROP }
end

return SD
