-- Galactic Grand Prix: the standings text after a cup race (v0.19: moved out of main.lua so the main menu's standings
-- page and the panel over the game's results screen (chain.lua) are built from the same lines and table).
-- Pure: strings and numbers from a race result (gp.lua K.record's out), no game objects.
local C = require('core')
local cfg = require('config')
local K = require('gp')
local CU = require('cup')
local RV = require('rival')
local U = require('ui')
local ART = require('art')
local ordinal = C.ordinal

local SD = {}

function SD.shortName(key) return key == CU.YOU and 'YOU' or key end

-- after a race: ONE screen (owner, 2026-11-10: fewer screens) - the ranking by points, as a table: place, racer,
-- points this race, total, places moved. After the last race the same table with the trophy on top.
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

-- the standings screen's text from a race result r (K.record's out): { key, title, lines, table, backdrop } (no tiles:
-- the main menu's page adds NEXT RACE / CONTINUE, the results-screen panel its own prompt)
function SD.spec(r)
  r = r or {}
  local ev = r.ev or { title = '?' }
  local run = r.run
  local cup = run and K.cup(run.cup) or { name = '?' }
  local cls = run and K.class(run.class) or { name = '?' }
  local lines = {}
  if r.cupOver then
    lines[#lines + 1] = { r.trophy and (r.trophy .. ' TROPHY') or ('%s PLACE'):format(ordinal(r.rank or 0):upper()), 44, r.trophy and U.GOLD or U.GREY }
    lines[#lines + 1] = { ('%s   -   %s   -   %d points%s%s'):format(cup.name, cls.name, r.pts or 0, r.newBest and '   -   NEW BEST' or '',
      r.perfect and '   -   PERFECT CUP' or ''), 22, U.WHITE }
    if r.unlocked and #r.unlocked > 0 then
      lines[#lines + 1] = { 'UNLOCKED:  ' .. table.concat(r.unlocked, '   -   '), 24, U.GOLD }
    end
  else
    lines[#lines + 1] = { ('%s   -   %s   -   race %d of %d'):format(cup.name, ev.title, ev.race or 0, run and run.races or 4), 22, U.WHITE }
  end
  local you = ('You: %s in this race'):format(r.pos and ordinal(r.pos) or 'did not finish')
  if r.time and K.fmtTime then you = you .. ('   -   %s'):format(K.fmtTime(r.time)) .. (r.lap and ('  (best lap %s)'):format(K.fmtTime(r.lap)) or '') end
  lines[#lines + 1] = { you, 18 }
  local youLine = lines[#lines]
  -- v0.12 (docs/PHILOSOPHY.md points 2 and 4): between races one stakes line from the points left; then ONE line for
  -- the record, the best lap and the near misses together, so the screen never grows past its v0.8 height (races 1-3:
  -- 4 lines; the cup result: 5 lines, as before)
  local stakes = (not r.cupOver) and run and K.run() and CU.stakes(run, cfg.Points) or nil
  -- v0.13 (point 3): the rival with their gap in this cup. A stakes line naming them already says "YOUR RIVAL" instead
  -- of a second line ("2 POINTS BEHIND YOUR RIVAL SEN FIRA, 1 RACE LEFT")
  local rivalName = run and RV.name(K.data, run.class)
  local rival = RV.callout(rivalName, run)
  local merged
  stakes, merged = RV.merge(stakes, rival and rivalName)
  if merged then rival = nil end
  if stakes then lines[#lines + 1] = { stakes, 22, U.WHITE } end
  local rivalAt = #lines + 1
  local note, big = {}, false
  if r.newRecord and K.fmtTime then
    note[#note + 1] = ('NEW RECORD  %s%s'):format(K.fmtTime(r.time), r.oldTime and ('   (was %s)'):format(K.fmtTime(r.oldTime)) or ''); big = true
  else
    local near = K.nearRecord and K.nearRecord(r)
    if near then note[#note + 1] = near; big = true end
    if r.newLap and K.fmtTime and r.lap then note[#note + 1] = ('NEW BEST LAP  %s'):format(K.fmtTime(r.lap)) end
  end
  local nearCup = r.cupOver and run and CU.nearTrophy(run, (cfg.Near or {}).TrophyPoints) or nil
  if nearCup then note[#note + 1] = nearCup; big = true end
  if #note > 0 then lines[#lines + 1] = { table.concat(note, '   -   '), big and 22 or 20, U.GOLD } end
  -- the rival's own line (after the stakes / your line) while the screen has room under its height (races 1-3: 4
  -- lines, the cup result: 5); else it goes on the end of your line
  if rival then
    if #lines < (r.cupOver and 5 or 4) then table.insert(lines, rivalAt, { rival, 20, U.WHITE })
    else youLine[1] = youLine[1] .. '   -   ' .. rival end
  end
  return { key = 'standings', title = r.cupOver and 'CUP RESULT' or 'STANDINGS', lines = lines,
    table = run and SD.rankingTable(run) or nil, backdrop = ART.BACKDROP }
end

return SD
