-- Galactic Grand Prix: a cup in progress - points, standings, trophy (DESIGN.md §6). Pure logic, no game objects
-- (tested in test/test_cup.lua). The cup's state lives in the save (gp.lua: K.data.run).
--
-- A race result ("field") is a list of { name, you = bool, pos = n, finished = bool } read from the race (race.lua).
-- You are always the key YOU (your pilot name changes with the character you pick); bots by their pilot name.
local CU = {}

CU.YOU = 'YOU'
CU.DEFAULT_POINTS = { 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }

-- v0.30 (the Rally Cup): opts = { timed = true, dnfPenalty = s, gapGuess = s, rivals = { racer keys } } makes a TIMED
-- cup: the standings by total time over the stages (st.times), not points (the points are still counted, unused).
-- A racer who did not finish a stage takes the slowest finisher's time + dnfPenalty; one who finished but whose time
-- could not be read (rare: the gap log shows 11-12 of 12 timed) takes the slowest timed finisher's + gapGuess per
-- place behind it (flagged est). rivals = the bots on the cup's small grid (race.lua cuts the grid to them).
function CU.new(classKey, cupKey, vehicleKey, nRaces, opts)
  local st = { class = classKey, cup = cupKey, vehicle = vehicleKey, race = 1, races = nRaces or 4,
    points = {}, last = {}, history = {} }
  if type(opts) == 'table' and opts.timed then
    st.timed, st.times = true, {}
    st.dnfPenalty = tonumber(opts.dnfPenalty) or 30
    st.gapGuess = tonumber(opts.gapGuess) or 2
    st.rivals = opts.rivals
  end
  return st
end
local function secs(x) return ('%.1f S'):format(math.abs(tonumber(x) or 0)) end

-- the race's finishing order: racers with a position, by position; you, if you didn't finish, go last (no points).
-- timed (v0.30): by race time (finished racers with a time first, fastest first), then the finished without a time by
-- position, then everyone who did not finish (bots too)
function CU.order(field, timed)
  local list = {}
  for _, r in ipairs(field or {}) do
    local key = r.you and CU.YOU or r.name
    if key then
      local t = tonumber(r.time)
      if not (r.finished and t and t > 0) then t = nil end
      list[#list + 1] = { key = key, pos = tonumber(r.pos) or 99, t = t,
        dnf = timed and (not r.finished) or (r.you and not r.finished) == true }
    end
  end
  table.sort(list, function(a, b)
    if a.dnf ~= b.dnf then return not a.dnf end
    if timed and (a.t ~= nil) ~= (b.t ~= nil) then return a.t ~= nil end
    if timed and a.t and b.t and a.t ~= b.t then return a.t < b.t end
    if a.pos ~= b.pos then return a.pos < b.pos end
    return a.key < b.key
  end)
  return list
end

-- add a finished race: points by place (the n-th racer in order gets points[n]; a DNF gets none).
-- Returns the race's rows { key, place, pts, dnf } (timed: + t = the stage time counted, est / pen when made up).
function CU.addRace(st, field, points)
  points = points or CU.DEFAULT_POINTS
  local rows = {}
  st.last = {}
  local order = CU.order(field, st.timed)
  if st.timed then
    local slowest
    for _, r in ipairs(order) do if r.t then slowest = r.t end end
    slowest = slowest or 0
    local k = 0
    for _, r in ipairs(order) do
      if not r.t then
        k = k + 1
        if r.dnf then r.t, r.pen = slowest + st.dnfPenalty, true
        else r.t, r.est = slowest + st.gapGuess * k, true end
      end
    end
  end
  for i, r in ipairs(order) do
    local pts = r.dnf and 0 or (points[i] or 0)
    st.points[r.key] = (st.points[r.key] or 0) + pts
    st.last[r.key] = r.dnf and 99 or i
    local row = { key = r.key, place = i, pts = pts, dnf = r.dnf }
    if st.timed then
      row.t, row.est, row.pen = r.t, r.est, r.pen
      st.times[r.key] = (st.times[r.key] or 0) + r.t
    end
    rows[#rows + 1] = row
  end
  -- a racer from earlier races who wasn't in this one keeps their points (and finishes last on ties)
  for k in pairs(st.points) do if st.last[k] == nil then st.last[k] = 100 end end
  st.history[#st.history + 1] = rows
  st.race = st.race + 1
  return rows
end

function CU.finished(st) return st.race > st.races end

-- the standings: { key, pts, rank } by points; ties go to the better finish in the latest race.
-- timed: { key, pts, time, rank } by total time, fastest first (the same tie rule)
local function sorter(timed)
  return function(a, b)
    if timed then
      if a.time ~= b.time then return a.time < b.time end
    elseif a.pts ~= b.pts then return a.pts > b.pts end
    if a.last ~= b.last then return a.last < b.last end
    return a.key < b.key
  end
end
function CU.standings(st)
  local list = {}
  for k, p in pairs(st.points) do
    list[#list + 1] = { key = k, pts = p, last = st.last[k] or 100, time = st.timed and (st.times[k] or 0) or nil }
  end
  table.sort(list, sorter(st.timed))
  for i, r in ipairs(list) do r.rank = i end
  return list
end

-- the ranking after race k (k = 0 .. races run): { key, pts, rank }, same tie rule as the standings (better finish
-- in race k first; racers who weren't in race k after those who were)
function CU.rankAt(st, k)
  local pts, last, tm = {}, {}, {}
  for i = 1, math.min(k, #st.history) do
    for _, r in ipairs(st.history[i]) do
      pts[r.key] = (pts[r.key] or 0) + r.pts
      tm[r.key] = (tm[r.key] or 0) + (tonumber(r.t) or 0)
      if i == k then last[r.key] = r.dnf and 99 or r.place end
    end
  end
  local list = {}
  for key, p in pairs(pts) do list[#list + 1] = { key = key, pts = p, last = last[key] or 100, time = st.timed and tm[key] or nil } end
  table.sort(list, sorter(st.timed))
  local byKey = {}
  for i, r in ipairs(list) do r.rank = i; byKey[r.key] = r end
  return list, byKey
end

-- the ranking table after the latest race: { rank, key, gain (points this race), total, move (places up since the
-- race before; nil after race 1), dnf, you }. timed: gain / total are seconds, + gap = seconds behind the leader
-- (0 for the leader), est / pen when this stage's time was made up
function CU.table(st)
  local k = #st.history
  local now = CU.rankAt(st, k)
  local _, before = CU.rankAt(st, k - 1)
  local race = {}
  for _, r in ipairs(st.history[k] or {}) do race[r.key] = r end
  local out = {}
  local lead = now[1] and now[1].time or 0
  for _, r in ipairs(now) do
    local rr = race[r.key]
    local row = { rank = r.rank, key = r.key, total = r.pts, gain = rr and rr.pts or 0, dnf = rr and rr.dnf or false,
      raced = rr ~= nil, you = r.key == CU.YOU,
      move = (k > 1 and before[r.key]) and (before[r.key].rank - r.rank) or nil }
    if st.timed then
      row.total, row.gain, row.gap = r.time, rr and rr.t or 0, r.time - lead
      row.est, row.pen = rr and rr.est or nil, rr and rr.pen or nil
    end
    out[#out + 1] = row
  end
  return out
end

-- -> rank, points (timed: rank, points, total time)
function CU.yourRank(st)
  for _, r in ipairs(CU.standings(st)) do if r.key == CU.YOU then return r.rank, r.pts, r.time end end
  return nil, 0
end

-- a perfect cup (v0.8 records): every race of the cup run, and you first in each of them (history rows: place 1, no DNF)
function CU.perfect(st)
  if #st.history == 0 or #st.history < (st.races or 0) then return false end
  for _, rows in ipairs(st.history) do
    local won = false
    for _, r in ipairs(rows) do if r.key == CU.YOU and r.place == 1 and not r.dnf then won = true end end
    if not won then return false end
  end
  return true
end

-- 1 gold, 2 silver, 3 bronze
CU.TROPHIES = { 'GOLD', 'SILVER', 'BRONZE' }
function CU.trophy(rank) return rank and CU.TROPHIES[rank] or nil end

---------------------------------------------------------------------------------------------------------------------
-- v0.12: the stakes line after races 1 to (races - 1), and the trophy near miss at the end (docs/PHILOSOPHY.md points
-- 2 and 4). Pure. Never claims anything the points can't back:
--   "out of reach" only when even 1st in every race left (and the others scoring nothing) can't get you there;
--   "is yours" / "wins the cup" only when it holds whatever the others do (any of them winning every race left);
--   "silver is not" (out of reach) only when one real finishing order gets you there: you win every race left, the
--   racers you let pass take the places right behind you, the rest finish in reverse order of their points.
-- Ties go to the better finish in the latest race (CU.standings): winning the last race wins any tie.

local function ord(n)
  local s = 'TH'
  if n % 100 < 11 or n % 100 > 13 then s = ({ 'ST', 'ND', 'RD' })[n % 10] or 'TH' end
  return n .. s
end
local function pts(n) return n == 1 and '1 POINT' or (n .. ' POINTS') end
local function racesLeft(n) return n == 1 and '1 RACE LEFT' or (n .. ' RACES LEFT') end
local function upper(key) return tostring(key):upper() end

-- can you still end the cup at rank `t` or better? -> 'no' (certainly not), 'yes' (one finishing order gets you
-- there), nil (can't say cheaply). others = the standings without you (best first), left = races left.
local function reach(others, mine, t, left, points)
  local top = points[1] or 0
  local ceiling = mine + top * left
  local above = 0
  for _, o in ipairs(others) do if o.pts > ceiling then above = above + 1 end end
  if above >= t then return 'no' end
  local n = #others + 1
  for i = t, #others do
    -- others[t..] finish behind you, the one with most points last: places n, n-1, ... t+1
    local place = n - (i - t)
    if others[i].pts + left * (points[place] or 0) > ceiling then return nil end
  end
  return 'yes'
end

-- the one stakes line between races: "2 POINTS BEHIND BIDDY BLAS, 1 RACE LEFT", "LEADING BY 4 OVER SEN FIRA, 2 RACES
-- LEFT", "LEADING BY 4 OVER SEN FIRA: 6TH OR BETTER WINS THE CUP", "GOLD IS OUT OF REACH, SILVER IS NOT", ...
-- nil before the first race, after the last, or when you are not in the standings.
local function stagesLeft(n) return n == 1 and '1 STAGE LEFT' or (n .. ' STAGES LEFT') end
-- timed (v0.30): "LEADING BY 4.2 S OVER BIDDY BLAS, 3 STAGES LEFT" / "4.2 S BEHIND BIDDY BLAS, 3 STAGES LEFT" /
-- "LEVEL WITH BIDDY BLAS, 3 STAGES LEFT"
local function timedStakes(st, left)
  local mine, others = nil, {}
  for _, r in ipairs(CU.standings(st)) do
    if r.key == CU.YOU then mine = r else others[#others + 1] = r end
  end
  if not mine or #others == 0 then return nil end
  local other = others[1]
  local d = other.time - mine.time
  if math.abs(d) < 0.05 then return ('LEVEL WITH %s, %s'):format(upper(other.key), stagesLeft(left)) end
  if d > 0 then return ('LEADING BY %s OVER %s, %s'):format(secs(d), upper(other.key), stagesLeft(left)) end
  return ('%s BEHIND %s, %s'):format(secs(d), upper(other.key), stagesLeft(left))
end
function CU.stakes(st, points)
  points = points or CU.DEFAULT_POINTS
  local done = #(st.history or {})
  local left = (st.races or 4) - done
  if done < 1 or left < 1 then return nil end
  if st.timed then return timedStakes(st, left) end
  local mine, rank
  local others = {}
  for _, r in ipairs(CU.standings(st)) do
    if r.key == CU.YOU then mine, rank = r.pts, r.rank else others[#others + 1] = r end
  end
  if not mine or #others == 0 then return nil end
  local top = points[1] or 0
  if rank == 1 then
    local second = others[1]
    local lead = mine - second.pts
    -- a DNF in every race left and the second winning them all still leaves you ahead
    if lead > top * left then return ('GOLD IS YOURS: %s CLEAR, %s'):format(pts(lead), racesLeft(left)) end
    local head = lead == 0 and ('LEVEL ON POINTS WITH %s'):format(upper(second.key))
      or ('LEADING BY %d OVER %s'):format(lead, upper(second.key))
    if left == 1 then
      -- finishing p-th (p >= 2) gives you points[p] while anyone else can win the race (top); strictly more is
      -- needed, since a racer level with you who finished ahead in the last race ranks ahead
      local p
      for i = 2, #points do if mine + points[i] > second.pts + top then p = i end end
      if p and p >= #others + 1 then return head .. ': ANY FINISH WINS THE CUP' end
      if p then return ('%s: %s OR BETTER WINS THE CUP'):format(head, ord(p)) end
      -- winning: you +top, anyone else at most points[2], and you take any tie
      return head .. ': A WIN TAKES THE CUP'
    end
    return ('%s, %s'):format(head, racesLeft(left))
  end
  local leader = others[1]
  if reach(others, mine, 1, left, points) ~= 'no' then
    local d = leader.pts - mine
    if d == 0 then return ('LEVEL ON POINTS WITH %s, %s'):format(upper(leader.key), racesLeft(left)) end
    return ('%s BEHIND %s, %s'):format(pts(d), upper(leader.key), racesLeft(left))
  end
  for t = 2, 3 do
    local r = reach(others, mine, t, left, points)
    if r ~= 'no' then
      local out = CU.TROPHIES[t - 1] .. ' IS OUT OF REACH, '
      if r == 'yes' then return out .. CU.TROPHIES[t] .. ' IS NOT' end
      -- (you are below rank t here: at rank t the finishing order above always works)
      return out .. ('%s FROM %s'):format(pts(math.max(0, others[t].pts - mine)), CU.TROPHIES[t])
    end
  end
  return 'THE TROPHIES ARE OUT OF REACH'
end

-- after the last race: how close you came to the next trophy colour up (rank 2 -> gold, 3 -> silver, 4th or lower ->
-- bronze), when within `within` points: "1 POINT FROM GOLD", "TIED FOR GOLD, LOST ON THE LAST RACE"; nil otherwise
-- (gold, not close, no threshold)
-- timed: within = seconds ("0.8 S FROM GOLD")
function CU.nearTrophy(st, within)
  within = tonumber(within)
  if not within or within < 0 or not CU.finished(st) then return nil end
  local std = CU.standings(st)
  local mine, rank
  for _, r in ipairs(std) do if r.key == CU.YOU then mine, rank = (st.timed and r.time or r.pts), r.rank end end
  if not rank or rank == 1 then return nil end
  local t = math.min(rank - 1, 3)
  if st.timed then
    local gap = mine - std[t].time
    if gap > within then return nil end
    if gap < 0.05 then return ('TIED FOR %s, LOST ON THE LAST STAGE'):format(CU.TROPHIES[t]) end
    return ('%s FROM %s'):format(secs(gap), CU.TROPHIES[t])
  end
  local gap = std[t].pts - mine
  if gap > within then return nil end
  if gap <= 0 then return ('TIED FOR %s, LOST ON THE LAST RACE'):format(CU.TROPHIES[t]) end
  return ('%s FROM %s'):format(pts(gap), CU.TROPHIES[t])
end

return CU
