-- Galactic Grand Prix: a cup in progress - points, standings, trophy (DESIGN.md §6). Pure logic, no game objects
-- (tested in test/test_cup.lua). The cup's state lives in the save (gp.lua: K.data.run).
--
-- A race result ("field") is a list of { name, you = bool, pos = n, finished = bool } read from the race (race.lua).
-- You are always the key YOU (your pilot name changes with the character you pick); bots by their pilot name.
local CU = {}

CU.YOU = 'YOU'
CU.DEFAULT_POINTS = { 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }

function CU.new(classKey, cupKey, vehicleKey, nRaces)
  return { class = classKey, cup = cupKey, vehicle = vehicleKey, race = 1, races = nRaces or 4,
    points = {}, last = {}, history = {} }
end

-- the race's finishing order: racers with a position, by position; you, if you didn't finish, go last (no points)
function CU.order(field)
  local list = {}
  for _, r in ipairs(field or {}) do
    local key = r.you and CU.YOU or r.name
    if key then list[#list + 1] = { key = key, pos = tonumber(r.pos) or 99, dnf = (r.you and not r.finished) == true } end
  end
  table.sort(list, function(a, b)
    if a.dnf ~= b.dnf then return not a.dnf end
    if a.pos ~= b.pos then return a.pos < b.pos end
    return a.key < b.key
  end)
  return list
end

-- add a finished race: points by place (the n-th racer in order gets points[n]; a DNF gets none).
-- Returns the race's rows { key, place, pts, dnf }.
function CU.addRace(st, field, points)
  points = points or CU.DEFAULT_POINTS
  local rows = {}
  st.last = {}
  for i, r in ipairs(CU.order(field)) do
    local pts = r.dnf and 0 or (points[i] or 0)
    st.points[r.key] = (st.points[r.key] or 0) + pts
    st.last[r.key] = r.dnf and 99 or i
    rows[#rows + 1] = { key = r.key, place = i, pts = pts, dnf = r.dnf }
  end
  -- a racer from earlier races who wasn't in this one keeps their points (and finishes last on ties)
  for k in pairs(st.points) do if st.last[k] == nil then st.last[k] = 100 end end
  st.history[#st.history + 1] = rows
  st.race = st.race + 1
  return rows
end

function CU.finished(st) return st.race > st.races end

-- the standings: { key, pts, rank } by points; ties go to the better finish in the latest race
function CU.standings(st)
  local list = {}
  for k, p in pairs(st.points) do list[#list + 1] = { key = k, pts = p, last = st.last[k] or 100 } end
  table.sort(list, function(a, b)
    if a.pts ~= b.pts then return a.pts > b.pts end
    if a.last ~= b.last then return a.last < b.last end
    return a.key < b.key
  end)
  for i, r in ipairs(list) do r.rank = i end
  return list
end

-- the ranking after race k (k = 0 .. races run): { key, pts, rank }, same tie rule as the standings (better finish
-- in race k first; racers who weren't in race k after those who were)
function CU.rankAt(st, k)
  local pts, last = {}, {}
  for i = 1, math.min(k, #st.history) do
    for _, r in ipairs(st.history[i]) do
      pts[r.key] = (pts[r.key] or 0) + r.pts
      if i == k then last[r.key] = r.dnf and 99 or r.place end
    end
  end
  local list = {}
  for key, p in pairs(pts) do list[#list + 1] = { key = key, pts = p, last = last[key] or 100 } end
  table.sort(list, function(a, b)
    if a.pts ~= b.pts then return a.pts > b.pts end
    if a.last ~= b.last then return a.last < b.last end
    return a.key < b.key
  end)
  local byKey = {}
  for i, r in ipairs(list) do r.rank = i; byKey[r.key] = r end
  return list, byKey
end

-- the ranking table after the latest race: { rank, key, gain (points this race), total, move (places up since the
-- race before; nil after race 1), dnf, you }
function CU.table(st)
  local k = #st.history
  local now = CU.rankAt(st, k)
  local _, before = CU.rankAt(st, k - 1)
  local race = {}
  for _, r in ipairs(st.history[k] or {}) do race[r.key] = r end
  local out = {}
  for _, r in ipairs(now) do
    local rr = race[r.key]
    out[#out + 1] = { rank = r.rank, key = r.key, total = r.pts, gain = rr and rr.pts or 0, dnf = rr and rr.dnf or false,
      raced = rr ~= nil, you = r.key == CU.YOU,
      move = (k > 1 and before[r.key]) and (before[r.key].rank - r.rank) or nil }
  end
  return out
end

function CU.yourRank(st)
  for _, r in ipairs(CU.standings(st)) do if r.key == CU.YOU then return r.rank, r.pts end end
  return nil, 0
end

-- 1 gold, 2 silver, 3 bronze
CU.TROPHIES = { 'GOLD', 'SILVER', 'BRONZE' }
function CU.trophy(rank) return rank and CU.TROPHIES[rank] or nil end

return CU
