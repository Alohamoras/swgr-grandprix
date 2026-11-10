-- cup.lua on its own: points by place, DNF, standings and ties, trophies.
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
local CU = require('cup')
local T = { failed = false }
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then T.failed = true end end

local function field(order, youPos, youFinished)
  local f = {}
  for i, name in ipairs(order) do f[#f + 1] = { name = name, pos = i < youPos and i or i + 1, finished = true } end
  f[#f + 1] = { name = 'Dwayne', you = true, pos = youPos, finished = youFinished ~= false }
  return f
end
local BOTS = { 'Kestar Bool', 'Shade', 'Katja Mox', 'Sen Fira', 'Lyren Shok', 'Ary Quill', 'Biddy Blas', 'Nik Skandaro',
  'Fola Kanjen', 'Goli & 02-R0', 'Griff Halloran' }

local st = CU.new('100', 'jakku', 'car')
local rows = CU.addRace(st, field(BOTS, 2))
check(rows[1].key == 'Kestar Bool' and rows[1].pts == 15, 'race 1: 1st gets 15')
check(rows[2].key == CU.YOU and rows[2].pts == 12, 'race 1: you 2nd, 12 points (as YOU, not your pilot name)')
check(rows[12].pts == 1, '12th gets 1')
check(st.race == 2 and not CU.finished(st), 'next race is 2')

CU.addRace(st, field(BOTS, 1))           -- you win: 15 (27); Kestar 2nd: 12 (27)
local s = CU.standings(st)
check(s[1].key == CU.YOU and s[1].pts == 27 and s[2].key == 'Kestar Bool' and s[2].pts == 27,
  'tie on 27: you ahead (better finish in the latest race)')

CU.addRace(st, field(BOTS, 5, false))    -- you DNF: 0
local r3 = st.history[3]
check(r3[12].key == CU.YOU and r3[12].pts == 0 and r3[12].dnf, 'DNF: last, no points')
check(r3[1].key == 'Kestar Bool' and r3[1].pts == 15, 'the others move up')

CU.addRace(st, field(BOTS, 1))
check(CU.finished(st), 'after race 4 the cup is over')
local rank, pts = CU.yourRank(st)
check(pts == 42 and rank == 2, 'you: 12+15+0+15 = 42, 2nd behind Kestar (15+12+15+12 = 54)  [' .. tostring(rank) .. ', ' .. pts .. ']')
check(CU.trophy(rank) == 'SILVER', 'silver trophy')
check(CU.trophy(4) == nil, 'no trophy for 4th')

-- a racer missing from a race keeps their points
local st2 = CU.new('50', 'ando', 'bike')
CU.addRace(st2, { { name = 'A', pos = 1, finished = true }, { name = 'Dwayne', you = true, pos = 2, finished = true } })
CU.addRace(st2, { { name = 'B', pos = 1, finished = true }, { name = 'Dwayne', you = true, pos = 2, finished = true } })
local s2 = CU.standings(st2)
check(s2[1].key == CU.YOU and s2[1].pts == 24, 'you 12+12 on top')
check(s2[2].key == 'B' and s2[2].pts == 15 and s2[3].key == 'A' and s2[3].pts == 15, 'A keeps 15 though missing race 2; tied with B, B ahead (won the latest race)')

if T.failed then os.exit(1) end
