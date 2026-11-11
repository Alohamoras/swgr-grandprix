-- Galactic Grand Prix: your rival per class (v0.13, docs/PHILOSOPHY.md point 3: "a rival, not just a field").
-- Pure logic, no game objects (test/test_rival.lua). Config: Rival.
--
-- The rule (DESIGN.md §13): after every cup race at a class, each racer within Window (6) points of you in that cup's
-- standings scores Window minus the gap, Ahead (2) more if ranked just ahead of you; the first to Form (30) becomes
-- your rival at the class, and another racer takes over only when their tally beats the rival's by Margin (10),
-- more than one race can give, so one odd race never flips it.
-- v0.20 (TASKS "Next" 3, menu review 2a): a rival from the first race. After a cup race at a class with no rival yet,
-- the racer who finished nearest you in that race (just ahead preferred, else just behind; the excluded skipped)
-- becomes your rival at once (config Rival.FirstRace, default on); from then on the tally above decides changes.
-- An old save's rival is kept; an old save with a tally but no rival gets one at its next cup race there.
--
-- Save: rivals[classKey] = { name = 'Sen Fira' or nil, scores = { [racerName] = tally } } (optional; missing = none).
-- You (CU.YOU) and the Exclude names (Kestar Bool: never on a cup grid) are never scored. Shade is scored like any
-- racer: he is on the grid only when you race as someone else.
local CU = require('cup')
local cfg = require('config')

local RV = {}

local function conf()
  local c = cfg.Rival
  if c == false then return nil end
  return type(c) == 'table' and c or {}
end
function RV.on() return conf() ~= nil end

local function num(v, d) return tonumber(v) or d end
local function excluded(name, c)
  if name == CU.YOU then return true end
  for _, n in ipairs(c.Exclude or {}) do if n == name then return true end end
  return false
end

-- the class's entry in the save (made when missing, or when an old / broken one is found)
function RV.entry(data, classKey)
  data.rivals = type(data.rivals) == 'table' and data.rivals or {}
  local e = data.rivals[classKey]
  if type(e) ~= 'table' then e = {}; data.rivals[classKey] = e end
  e.scores = type(e.scores) == 'table' and e.scores or {}
  if type(e.name) ~= 'string' then e.name = nil end
  return e
end

-- the rival at a class: name or nil (never makes an entry)
function RV.name(data, classKey)
  if not RV.on() then return nil end
  local e = type(data) == 'table' and type(data.rivals) == 'table' and data.rivals[classKey]
  return type(e) == 'table' and type(e.name) == 'string' and e.name or nil
end

-- this race's closeness: { [racer] = points } from a cup's standings after the race (run = the cup, cup.lua)
function RV.gains(run)
  local c = conf()
  if not c then return {} end
  local window, ahead = num(c.Window, 6), num(c.Ahead, 2)
  local std = CU.standings(run)
  -- your points, and the scored racer ranked just above you (the excluded skipped)
  local mine, above, prev
  for _, r in ipairs(std) do
    if r.key == CU.YOU then mine, above = r.pts, prev
    elseif not excluded(r.key, c) then prev = r.key end
    if mine then break end
  end
  local out = {}
  if not mine then return out end
  for _, r in ipairs(std) do
    if not excluded(r.key, c) then
      local g = window - math.abs(r.pts - mine)
      if g > 0 then
        if r.key == above then g = g + ahead end
        out[r.key] = g
      end
    end
  end
  return out
end

-- v0.20: the racer who finished nearest you in the cup's latest race: the one just ahead (the excluded skipped), else
-- the one just behind; nil when you weren't in it or nobody else was
function RV.nearest(run)
  local c = conf()
  if not (c and run and run.history) then return nil end
  local rows = run.history[#run.history]
  if type(rows) ~= 'table' then return nil end
  local list = {}
  for _, r in ipairs(rows) do list[#list + 1] = r end
  table.sort(list, function(a, b) return (a.place or 99) < (b.place or 99) end)
  local at
  for i, r in ipairs(list) do if r.key == CU.YOU then at = i end end
  if not at then return nil end
  for i = at - 1, 1, -1 do if not excluded(list[i].key, c) then return list[i].key end end
  for i = at + 1, #list do if not excluded(list[i].key, c) then return list[i].key end end
  return nil
end

-- add a cup race to the class's tally and maybe change the rival. Returns the rival's name (or nil), and what
-- happened: 'new' (a first rival; v0.20: 'first' when picked from the race just run, the nearest finisher),
-- 'switch' (another racer took over; third value = the old one) or nil.
function RV.update(data, run)
  local c = conf()
  if not (c and run and run.class) then return nil end
  local e = RV.entry(data, run.class)
  for name, g in pairs(RV.gains(run)) do e.scores[name] = (e.scores[name] or 0) + g end
  local best, bestScore
  for name, s in pairs(e.scores) do
    if type(s) == 'number' and not excluded(name, c) and (not best or s > bestScore or (s == bestScore and name < best)) then
      best, bestScore = name, s
    end
  end
  if not e.name and c.FirstRace ~= false then
    local near = RV.nearest(run)
    if near then e.name = near; return near, 'first' end
  end
  if not best then return e.name end
  if not e.name then
    if bestScore >= num(c.Form, 30) then e.name = best; return best, 'new' end
    return nil
  end
  if best ~= e.name and bestScore >= (e.scores[e.name] or 0) + num(c.Margin, 10) then
    local old = e.name
    e.name = best
    return best, 'switch', old
  end
  return e.name
end

-- the call-out for the standings: "RIVAL: SEN FIRA, AHEAD BY 3" (the rival has more points in this cup) / "RIVAL: SEN
-- FIRA, 5 BEHIND YOU" / "RIVAL: SEN FIRA, LEVEL ON POINTS"; nil when there is no rival or they aren't in this cup
function RV.callout(name, run)
  if not (name and run and run.points) then return nil end
  local theirs, mine = run.points[name], run.points[CU.YOU]
  if type(theirs) ~= 'number' or type(mine) ~= 'number' then return nil end
  local d = theirs - mine
  local who = 'RIVAL: ' .. name:upper()
  if d > 0 then return ('%s, AHEAD BY %d'):format(who, d) end
  if d < 0 then return ('%s, %d BEHIND YOU'):format(who, -d) end
  return who .. ', LEVEL ON POINTS'
end

-- the stakes line already naming the rival says so instead of a second line: "2 POINTS BEHIND YOUR RIVAL SEN FIRA,
-- 1 RACE LEFT". Returns the new line and true when merged; the line unchanged and false otherwise.
function RV.merge(stakes, name)
  if not (stakes and name) then return stakes, false end
  local up = name:upper()
  local i, j = stakes:find(up, 1, true)
  if not i then return stakes, false end
  return stakes:sub(1, i - 1) .. 'YOUR RIVAL ' .. up .. stakes:sub(j + 1), true
end

return RV
