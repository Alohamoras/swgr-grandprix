-- v0.12: the stakes line between races and the trophy near miss at the end (cup.lua CU.stakes / CU.nearTrophy).
-- Named situations first (leading, behind, a tie each way, the last race, a DNF, out of reach), then every claim
-- checked against every way the races left can go, on a few hundred random cups (never something mathematically
-- wrong).
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
local CU = require('cup')
local cfg = require('config')
local failed = false
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then failed = true end end
local P = cfg.Points

-- a cup after `done` races with these points (YOU among them) and the latest race's places (for ties)
local function cup(points, last, done, races)
  local st = CU.new('100', 'jakku', 'car', races or 4)
  st.points, st.last = points, last or {}
  for _ = 1, done do st.history[#st.history + 1] = {} end
  st.race = done + 1
  return st
end
local function eq(st, want, what)
  local got = CU.stakes(st, P)
  check(got == want, what .. ' (' .. tostring(got) .. ')')
end
-- twelve racers like a real cup: the given ones, the rest well behind
local FILL = { 'Kestar Bool', 'Katja Mox', 'Lyren Shok', 'Ary Quill', 'Nik Skandaro', 'Fola Kanjen', 'Goli & 02-R0',
  'Griff Halloran', 'Shade', 'Soren Zaks', 'Malis Vazosk' }
local function twelve(t, base)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  for _, k in ipairs(FILL) do if n >= 12 then break end; if t[k] == nil then t[k] = base or 5; n = n + 1 end end
  return t
end

-- behind / leading
eq(cup(twelve({ YOU = 35, ['Biddy Blas'] = 37 }), { YOU = 1, ['Biddy Blas'] = 2 }, 3), '2 POINTS BEHIND BIDDY BLAS, 1 RACE LEFT', 'behind the leader, last race next')
eq(cup(twelve({ YOU = 26, ['Biddy Blas'] = 27 }), {}, 2), '1 POINT BEHIND BIDDY BLAS, 2 RACES LEFT', 'one point behind (singular)')
eq(cup(twelve({ YOU = 27, ['Sen Fira'] = 23 }), {}, 2), 'LEADING BY 4 OVER SEN FIRA, 2 RACES LEFT', 'leading, two races left')
eq(cup(twelve({ YOU = 15, ['Sen Fira'] = 12 }), {}, 1), 'LEADING BY 3 OVER SEN FIRA, 3 RACES LEFT', 'after race 1')
-- ties (the latest race decides: CU.standings)
eq(cup(twelve({ YOU = 27, ['Sen Fira'] = 27 }), { YOU = 1, ['Sen Fira'] = 2 }, 2), 'LEVEL ON POINTS WITH SEN FIRA, 2 RACES LEFT', 'tie, you ahead on the latest race')
eq(cup(twelve({ YOU = 27, ['Sen Fira'] = 27 }), { YOU = 2, ['Sen Fira'] = 1 }, 2), 'LEVEL ON POINTS WITH SEN FIRA, 2 RACES LEFT', 'tie, Sen Fira ahead on the latest race')
eq(cup(twelve({ YOU = 37, ['Sen Fira'] = 37 }), { YOU = 1, ['Sen Fira'] = 2 }, 3), 'LEVEL ON POINTS WITH SEN FIRA: A WIN TAKES THE CUP', 'tie before the last race')
-- the last race: what finish wins the cup (strictly more than the second winning it: 15)
eq(cup(twelve({ YOU = 40, ['Sen Fira'] = 36 }), {}, 3), 'LEADING BY 4 OVER SEN FIRA: 2ND OR BETTER WINS THE CUP', 'lead 4, last race: 2nd (12 > 11)')
eq(cup(twelve({ YOU = 40, ['Sen Fira'] = 31 }), {}, 3), 'LEADING BY 9 OVER SEN FIRA: 6TH OR BETTER WINS THE CUP', 'lead 9, last race: 6th (7 > 6, 7th ties and loses)')
eq(cup(twelve({ YOU = 40, ['Sen Fira'] = 37 }), {}, 3), 'LEADING BY 3 OVER SEN FIRA: A WIN TAKES THE CUP', 'lead 3: 2nd would tie and lose')
eq(cup(twelve({ YOU = 45, ['Sen Fira'] = 30 }), {}, 3), 'LEADING BY 15 OVER SEN FIRA: ANY FINISH WINS THE CUP', 'lead 15 of 12 racers: any finish (12th = 1)')
eq(cup(twelve({ YOU = 46, ['Sen Fira'] = 30 }), {}, 3), 'GOLD IS YOURS: 16 POINTS CLEAR, 1 RACE LEFT', 'lead 16: gold even with a DNF')
eq(cup(twelve({ YOU = 31, ['Sen Fira'] = 1 }, 0), {}, 2), 'LEADING BY 30 OVER SEN FIRA, 2 RACES LEFT', 'lead 30 with 2 left is not safe (30 = 2 x 15)')
-- out of reach (a DNF: you scored nothing in two races)
eq(cup(twelve({ YOU = 12, ['Biddy Blas'] = 30, ['Sen Fira'] = 20 }, 2), {}, 3), 'GOLD IS OUT OF REACH, SILVER IS NOT', 'DNF: gold out (12 + 15 < 30), silver still on')
eq(cup(twelve({ YOU = 10, ['Biddy Blas'] = 45, ['Sen Fira'] = 40, ['Katja Mox'] = 20 }, 2), {}, 3), 'SILVER IS OUT OF REACH, BRONZE IS NOT', 'two out of reach, bronze on')
eq(cup(twelve({ YOU = 0, ['Biddy Blas'] = 45, ['Sen Fira'] = 40, ['Katja Mox'] = 36 }, 2), {}, 3), 'THE TROPHIES ARE OUT OF REACH', 'three out of reach')
eq(cup({ YOU = 10, ['Biddy Blas'] = 40, ['Sen Fira'] = 24, ['Katja Mox'] = 24, ['Shade'] = 24 }, {}, 3), 'GOLD IS OUT OF REACH, 14 POINTS FROM SILVER',
  'a bunched field: silver not promised, the gap given')
-- an actual DNF through CU.addRace
do
  local st = CU.new('100', 'jakku', 'car')
  local function f(youPos, finished)
    local out = { { name = 'Dwayne', you = true, pos = youPos, finished = finished ~= false } }
    for i, n in ipairs({ 'Biddy Blas', 'Sen Fira', 'Katja Mox' }) do out[#out + 1] = { name = n, pos = i < youPos and i or i + 1, finished = true } end
    return out
  end
  CU.addRace(st, f(1)); CU.addRace(st, f(3, false))
  eq(st, '12 POINTS BEHIND BIDDY BLAS, 2 RACES LEFT', 'a DNF in race 2: you 15 + 0, Biddy Blas 12 + 15')
end
-- no line before race 1 or after the last
check(CU.stakes(cup({ YOU = 0 }, {}, 0), P) == nil, 'no stakes before race 1')
check(CU.stakes(cup(twelve({ YOU = 60 }), {}, 4), P) == nil, 'no stakes after the last race')
check(CU.stakes(cup({ ['Sen Fira'] = 10 }, {}, 1), P) == nil, 'no stakes without you in the standings')

-- one line that fits: the longest name, the longest wording (wraps at 2160 UI units; 70 characters at size 22 x 1.6
-- is about 1500)
do
  local longest = 0
  for _, s in ipairs({
    CU.stakes(cup(twelve({ YOU = 40, ['Griff Halloran'] = 28 }), {}, 3), P),
    CU.stakes(cup(twelve({ YOU = 37, ['Griff Halloran'] = 37 }), { YOU = 1, ['Griff Halloran'] = 2 }, 3), P),
    CU.stakes(cup(twelve({ YOU = 0, ['Griff Halloran'] = 99 }), {}, 1), P),
    CU.stakes(cup(twelve({ YOU = 37, ['Griff Halloran'] = 37 }), {}, 1), P),
    CU.stakes(cup({ YOU = 10, ['Biddy Blas'] = 40, ['Sen Fira'] = 24, ['Katja Mox'] = 24, ['Shade'] = 24 }, {}, 3), P),
    CU.stakes(cup(twelve({ YOU = 99, ['Griff Halloran'] = 0 }, 0), {}, 3), P),
  }) do longest = math.max(longest, #s) end
  check(longest <= 70, 'every stakes line fits on one line (longest ' .. longest .. ' characters)')
end

-- the trophy near miss after the cup (Near.TrophyPoints = 3)
local function over(points, last) return cup(points, last, 4) end
local N = cfg.Near.TrophyPoints
check(N == 3, 'Near.TrophyPoints = 3')
check(CU.nearTrophy(over({ YOU = 50, ['Sen Fira'] = 51, Shade = 20 }), N) == '1 POINT FROM GOLD', '2nd, 1 point behind: 1 POINT FROM GOLD')
check(CU.nearTrophy(over({ YOU = 48, ['Sen Fira'] = 51, Shade = 20 }), N) == '3 POINTS FROM GOLD', '3 points: still close')
check(CU.nearTrophy(over({ YOU = 47, ['Sen Fira'] = 51, Shade = 20 }), N) == nil, '4 points: nothing (stays special)')
check(CU.nearTrophy(over({ YOU = 51, ['Sen Fira'] = 51, Shade = 20 }, { YOU = 3, ['Sen Fira'] = 2 }), N) == 'TIED FOR GOLD, LOST ON THE LAST RACE', 'a tie lost on the last race')
check(CU.nearTrophy(over({ YOU = 51, ['Sen Fira'] = 51, Shade = 20 }, { YOU = 2, ['Sen Fira'] = 3 }), N) == nil, 'a tie won on the last race: gold, nothing')
check(CU.nearTrophy(over({ YOU = 40, ['Sen Fira'] = 51, Shade = 42 }), N) == '2 POINTS FROM SILVER', '3rd: the next colour up is silver')
check(CU.nearTrophy(over({ YOU = 30, A = 51, B = 42, Shade = 31 }), N) == '1 POINT FROM BRONZE', '4th: bronze')
check(CU.nearTrophy(over({ YOU = 30, A = 51, B = 42, C = 33, Shade = 31 }), N) == '3 POINTS FROM BRONZE', '5th: bronze is the next colour up')
check(CU.nearTrophy(over({ YOU = 60, ['Sen Fira'] = 59 }), N) == nil, 'gold: nothing')
check(CU.nearTrophy(cup({ YOU = 50, ['Sen Fira'] = 51 }, {}, 3), N) == nil, 'not after the last race: nothing')
check(CU.nearTrophy(over({ YOU = 50, ['Sen Fira'] = 51 }), false) == nil, 'Near off: nothing')

-- every claim against every outcome of the races left (the real points and tie rule: CU.addRace / CU.standings)
local function copy(st)
  local c = CU.new(st.class, st.cup, st.vehicle, st.races)
  for k, v in pairs(st.points) do c.points[k] = v end
  for k, v in pairs(st.last) do c.last[k] = v end
  for _, h in ipairs(st.history) do c.history[#c.history + 1] = h end
  c.race = st.race
  return c
end
local function perms(list)
  local out = {}
  local function go(a, n)
    if n <= 1 then out[#out + 1] = { table.unpack(a) }; return end
    for i = 1, n do a[i], a[n] = a[n], a[i]; go(a, n - 1); a[i], a[n] = a[n], a[i] end
  end
  go({ table.unpack(list) }, #list)
  return out
end
-- one race's possible fields: every order of the bots with you in every place, and you DNF
local function fields(bots)
  local out = {}
  for _, o in ipairs(perms(bots)) do
    for yp = 1, #o + 2 do
      local f, dnf = {}, yp == #o + 2
      local p = 1
      for i = 1, #o + 1 do
        if i == yp and not dnf then f[#f + 1] = { name = 'Dwayne', you = true, pos = p, finished = true }; p = p + 1 end
        if o[i] then f[#f + 1] = { name = o[i], pos = p, finished = true }; p = p + 1 end
      end
      if dnf then f[#f + 1] = { name = 'Dwayne', you = true, pos = 99, finished = false } end
      out[#out + 1] = { f = f, place = (not dnf) and yp or nil }
    end
  end
  return out
end
-- every way the rest of the cup can go -> list of { rank, places = { your place each race (nil = DNF) } }
local function outcomes(st, bots)
  local fs, res = fields(bots), {}
  local function go(s, places)
    if CU.finished(s) then res[#res + 1] = { rank = CU.yourRank(s), places = places }; return end
    for _, x in ipairs(fs) do
      local c = copy(s); CU.addRace(c, x.f, P)
      local pl = { table.unpack(places) }; pl[#pl + 1] = x.place or false
      go(c, pl)
    end
  end
  go(st, {})
  return res
end
local function claimsHold(st, bots)
  local line = CU.stakes(st, P)
  if not line then return true, 'no line' end
  local all = outcomes(st, bots)
  local function none(pred) for _, o in ipairs(all) do if pred(o) then return false end end return true end
  local function some(pred) return not none(pred) end
  local function every(pred) for _, o in ipairs(all) do if not pred(o) then return false end end return true end
  local ok = true
  local function finishedAll(o, best) for _, p in ipairs(o.places) do if not p or p > best then return false end end return true end
  if line:find('^GOLD IS YOURS') then ok = ok and every(function(o) return o.rank == 1 end) end
  local p = line:match(': (%d+)%a%a OR BETTER WINS THE CUP$')
  if p then ok = ok and every(function(o) return not finishedAll(o, tonumber(p)) or o.rank == 1 end) end
  if line:find('ANY FINISH WINS THE CUP$') then ok = ok and every(function(o) return not finishedAll(o, 99) or o.rank == 1 end) end
  if line:find('A WIN TAKES THE CUP$') then ok = ok and every(function(o) return not finishedAll(o, 1) or o.rank == 1 end) end
  if line:find('^GOLD IS OUT OF REACH') then ok = ok and none(function(o) return o.rank <= 1 end) end
  if line:find('^SILVER IS OUT OF REACH') then ok = ok and none(function(o) return o.rank <= 2 end) end
  if line:find('^THE TROPHIES ARE OUT OF REACH') then ok = ok and none(function(o) return o.rank <= 3 end) end
  if line:find('SILVER IS NOT$') then ok = ok and some(function(o) return o.rank <= 2 end) end
  if line:find('BRONZE IS NOT$') then ok = ok and some(function(o) return o.rank <= 3 end) end
  return ok, line
end
math.randomseed(20261111)
local kinds, bad, n = {}, nil, 0
local function randomCup(bots, races, done)
  local st = CU.new('100', 'jakku', 'car', races)
  local fs = fields(bots)
  for _ = 1, done do
    -- mostly you mid-pack; sometimes a DNF; bots in a random order
    CU.addRace(st, fs[math.random(#fs)].f, P)
  end
  return st
end
for _ = 1, 400 do
  local st = randomCup({ 'Biddy Blas', 'Sen Fira', 'Katja Mox', 'Shade' }, 4, 3) -- 1 race left, 5 racers
  local ok, line = claimsHold(st, { 'Biddy Blas', 'Sen Fira', 'Katja Mox', 'Shade' })
  n = n + 1
  kinds[(line:gsub('%d+', '#'):gsub('[A-Z]+ [A-Z]+ OVER', 'X OVER'):gsub('BEHIND .-,', 'BEHIND X,'):gsub('WITH .-[:,]', 'WITH X,'))] = true
  if not ok and not bad then bad = line end
end
for _ = 1, 60 do
  local st = randomCup({ 'Biddy Blas', 'Sen Fira', 'Katja Mox' }, 4, 2) -- 2 races left, 4 racers
  local ok, line = claimsHold(st, { 'Biddy Blas', 'Sen Fira', 'Katja Mox' })
  n = n + 1
  kinds[(line:gsub('%d+', '#'):gsub('[A-Z]+ [A-Z]+ OVER', 'X OVER'):gsub('BEHIND .-,', 'BEHIND X,'):gsub('WITH .-[:,]', 'WITH X,'))] = true
  if not ok and not bad then bad = line end
end
local nk = 0
for _ in pairs(kinds) do nk = nk + 1 end
check(bad == nil, ('every claim true in every outcome of %d random cups (%d kinds of line)%s'):format(n, nk, bad and (': WRONG ' .. bad) or ''))
check(nk >= 6, 'the random cups reach several kinds of line (' .. nk .. ')')
if failed then os.exit(1) end
