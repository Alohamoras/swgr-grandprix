-- v0.13: a rival per class (rival.lua). The rule on its own (closeness from the cup standings, the first to Form, no
-- flip on one race, a switch by Margin, Kestar Bool and you never scored, Shade scored), the rival forming over a
-- few 100cc cups through K.record, kept across a save reload and an old save without rivals, cleared by RESET
-- PROGRESS; then a whole 100cc Jakku Cup through the menu: the call-out with the right gap and side, on its own
-- line when the screen has room, on your line when it hasn't, merged into the stakes line when that names the rival
-- (never twice), and the screen no taller than v0.12's (4 lines after races 1-3, 5 after the cup).
local M = require('mock')
local W = require('world')
local T = require('util')
-- an old save: no rivals field
T.boot({ version = 2, races = 0, cups = 0, class = '100', vehicle = 'car', restores = {}, abilityRestores = {} })
local K = require('gp')
local CU = require('cup')
local RV = require('rival')
local cfg = require('config')
local P = cfg.Points

T.check(type(K.data.rivals) == 'table' and next(K.data.rivals) == nil, 'an old save without rivals loads: none')
T.check(RV.name(K.data, '100') == nil, 'no rival at first')
local RC = cfg.Rival
T.check(RC.Window + RC.Ahead < RC.Margin, 'one race can never give more than the margin (Window + Ahead < Margin)')

-- the rule on its own: a cup's standings -> this race's closeness
local function cup(points, last, done)
  local st = CU.new('100', 'jakku', 'car', 4)
  st.points, st.last = points, last or {}
  for _ = 1, done or 1 do st.history[#st.history + 1] = {} end
  st.race = (done or 1) + 1
  return st
end
local g = RV.gains(cup({ YOU = 20, ['Sen Fira'] = 22, ['Biddy Blas'] = 30, ['Katja Mox'] = 19, ['Kestar Bool'] = 21, Shade = 17 }))
T.check(g['Sen Fira'] == 6, 'just ahead by 2: 6 - 2 + 2 = 6 (' .. tostring(g['Sen Fira']) .. ')')
T.check(g['Katja Mox'] == 5, 'just behind by 1: 6 - 1 = 5 (' .. tostring(g['Katja Mox']) .. ')')
T.check(g['Biddy Blas'] == nil, '10 points away: nothing')
T.check(g['Kestar Bool'] == nil and g.YOU == nil, 'Kestar Bool and you are never scored')
T.check(g.Shade == 3, 'Shade (on the grid when you race as someone else) is scored like any racer (' .. tostring(g.Shade) .. ')')
g = RV.gains(cup({ YOU = 20, ['Sen Fira'] = 20, ['Katja Mox'] = 20 }, { ['Sen Fira'] = 1, YOU = 2, ['Katja Mox'] = 3 }))
T.check(g['Sen Fira'] == 8 and g['Katja Mox'] == 6, 'level on points: the one ranked just ahead (latest race) counts most')

-- forming and flipping with a set tally
local d = { rivals = {} }
local st = cup({ YOU = 20, ['Sen Fira'] = 22, ['Katja Mox'] = 19 })
d.rivals['100'] = { scores = { ['Sen Fira'] = 20 } }
local name, what = RV.update(d, st)
T.check(name == nil and what == nil, 'Sen Fira at 26 of 30: no rival yet')
name, what = RV.update(d, st)
T.check(name == 'Sen Fira' and what == 'new', 'Sen Fira at 32: your rival')
d.rivals['100'].scores = { ['Sen Fira'] = 40, ['Katja Mox'] = 41 }
local away = cup({ YOU = 20, ['Sen Fira'] = 40, ['Katja Mox'] = 20 }, { ['Katja Mox'] = 1, YOU = 2 })
name, what = RV.update(d, away)
T.check(name == 'Sen Fira' and what == nil and d.rivals['100'].scores['Katja Mox'] == 49,
  'one race with Katja Mox level and Sen Fira far off (49 v 40): no flip')
name, what = RV.update(d, away)
T.check(name == 'Katja Mox' and what == 'switch', 'a second such race (57 v 40, 10 clear): Katja Mox takes over')

-- the call-out: gap and side, from this cup's points
T.check(RV.callout('Sen Fira', cup({ YOU = 20, ['Sen Fira'] = 23 })) == 'RIVAL: SEN FIRA, AHEAD BY 3', 'rival ahead: AHEAD BY 3')
T.check(RV.callout('Sen Fira', cup({ YOU = 25, ['Sen Fira'] = 20 })) == 'RIVAL: SEN FIRA, 5 BEHIND YOU', 'rival behind: 5 BEHIND YOU')
T.check(RV.callout('Sen Fira', cup({ YOU = 20, ['Sen Fira'] = 20 })) == 'RIVAL: SEN FIRA, LEVEL ON POINTS', 'level: LEVEL ON POINTS')
T.check(RV.callout('Sen Fira', cup({ YOU = 20, ['Biddy Blas'] = 20 })) == nil, 'the rival not in this cup: nothing')
T.check(RV.callout(nil, cup({ YOU = 20 })) == nil, 'no rival: nothing')
local m, merged = RV.merge('2 POINTS BEHIND SEN FIRA, 1 RACE LEFT', 'Sen Fira')
T.check(merged and m == '2 POINTS BEHIND YOUR RIVAL SEN FIRA, 1 RACE LEFT', 'the stakes line naming the rival: merged (' .. m .. ')')
m, merged = RV.merge('LEADING BY 4 OVER GOLI & 02-R0, 2 RACES LEFT', 'Goli & 02-R0')
T.check(merged and m == 'LEADING BY 4 OVER YOUR RIVAL GOLI & 02-R0, 2 RACES LEFT', 'a name with pattern characters merges')
m, merged = RV.merge('2 POINTS BEHIND BIDDY BLAS, 1 RACE LEFT', 'Sen Fira')
T.check(not merged and m == '2 POINTS BEHIND BIDDY BLAS, 1 RACE LEFT', 'another racer named: unchanged')
cfg.Rival = false
T.check(RV.name({ rivals = { ['100'] = { name = 'Sen Fira' } } }, '100') == nil and RV.update(d, st) == nil, 'Rival = false: off')
cfg.Rival = RC

-- forming over a few cups through K.record: Sen Fira swaps places with you every race (2nd / 3rd), the others fixed
local function field(youPos, senPos)
  local f = { { name = 'Dwayne', you = true, pos = youPos, finished = true }, { name = 'Sen Fira', pos = senPos, finished = true } }
  local p = 1
  for _, n in ipairs({ 'Kestar Bool', 'Biddy Blas', 'Katja Mox', 'Lyren Shok', 'Ary Quill', 'Nik Skandaro' }) do
    while p == youPos or p == senPos do p = p + 1 end
    f[#f + 1] = { name = n, pos = p, finished = true }; p = p + 1
  end
  return f
end
local function runCup(cupKey)
  K.startCup('100', cupKey, 'car')
  local out
  for i = 1, 4 do
    local ev = K.nextRace()
    local you, sen = (i % 2 == 1) and 2 or 3, (i % 2 == 1) and 3 or 2
    out = K.record(ev, you, field(you, sen), { time = 100 + i })
  end
  return out
end
local mk = T.mark()
local o1 = runCup('jakku')
T.check(o1.cupOver and RV.name(K.data, '100') == nil, 'after one cup: no rival yet (' .. tostring(K.data.rivals['100'] and K.data.rivals['100'].scores['Sen Fira']) .. ' of 30)')
local o2 = runCup('lantaana')
T.check(RV.name(K.data, '100') == 'Sen Fira' and o2.rival == 'Sen Fira', 'after two cups: Sen Fira is your rival at 100cc')
T.check(T.logHas('[rival] 100cc: Sen Fira is your rival', mk), 'logged')
T.check(RV.name(K.data, '50') == nil and RV.name(K.data, '150') == nil, 'only at the class raced')
T.check(K.data.rivals['100'].scores['Kestar Bool'] == nil, 'Kestar Bool never in the tally')
-- kept across a save reload
K.data = nil
K.load()
T.check(RV.name(K.data, '100') == 'Sen Fira' and (K.data.rivals['100'].scores['Sen Fira'] or 0) >= 30, 'the rival survives a save reload')
T.check(T.save().rivals['100'].name == 'Sen Fira', 'in save.lua')

-- HOME's info names the rival next to the champion, on one line (about 110 characters at size 20 fit the 2160 wrap)
-- (the format of main.lua's class tile info, worst case: the longest champion and a different longest rival)
local longest = 0
for _, n in ipairs({ 'Goli & 02-R0', 'Malis Vazosk', 'Nik Skandaro' }) do
  local s = ('200cc: parts level 9, abilities 3.  Gold 6 / 6, trophies 6 / 6.  Champion: GRIFF HALLORAN.  Rival: %s'):format(n:upper())
  longest = math.max(longest, #s)
end
T.check(longest <= 112, 'the longest HOME info line with a rival: ' .. longest .. ' characters')

-- reset clears it
K.reset()
T.check(RV.name(K.data, '100') == nil and next(T.save().rivals) == nil, 'RESET PROGRESS clears the rivals')

---------------------------------------------------------------------------------------------------------------------
-- the standings screen, through the menu: Sen Fira already your rival at 100cc
K.data.rivals = { ['100'] = { name = 'Sen Fira', scores = { ['Sen Fira'] = 100 } } }
local R = K.races('jakku', '100')
-- records far faster than these races on tracks 1, 3, 4 (never near, never new); track 2 has none (a NEW RECORD)
K.data.records['100'] = { [R[1].path] = { time = 10 }, [R[3].path] = { time = 10 }, [R[4].path] = { time = 10 } }
K.save()

-- the standings' lines: the wrapped texts right after the last STANDINGS / CUP RESULT title
local function screenLines()
  local titleAt
  for i = #M.calls, 1, -1 do
    local c = M.calls[i]
    if c.name == 'SetText' and type(c.args[1]) == 'table' then
      local s = rawget(rawget(c.args[1], '__props') or {}, '__text')
      if s == 'STANDINGS' or s == 'CUP RESULT' then titleAt = i; break end
    end
  end
  local out = {}
  if not titleAt then return out end
  local i = titleAt + 1
  while i <= #M.calls do
    local c = M.calls[i]
    if c.name == 'SetText' then
      local s = type(c.args[1]) == 'table' and rawget(rawget(c.args[1], '__props') or {}, '__text')
      -- a line is a text that is wrapped before the next text is set
      local wrapped = false
      for j = i + 1, #M.calls do
        if M.calls[j].name == 'SetText' then break end
        if M.calls[j].name == 'SetAutoWrapText' then wrapped = true end
      end
      if not wrapped then break end
      out[#out + 1] = s
    end
    i = i + 1
  end
  return out
end
local function count(lines, pat)
  local n = 0
  for _, l in ipairs(lines) do local _, k = l:gsub(pat:gsub('%p', '%%%0'), ''); n = n + k end
  return n
end
local function has(lines, s) for _, l in ipairs(lines) do if l == s then return true end end return false end
local function show(lines) return table.concat(lines, ' | ') end

local function race(you, order, time)
  W.race(11); M.tick(5)
  local used, p = {}, 1
  for _, i in ipairs(order) do
    if p == you then p = p + 1 end
    W.botFinish(i, p); used[i] = true; p = p + 1
  end
  for i = 1, #W.bots do
    if not used[i] then
      if p == you then p = p + 1 end
      W.botFinish(i, p); p = p + 1
    end
  end
  M.tick(5); W.finish(you, time); M.tick(25)
  local t0 = os.time(); while os.time() - t0 < 3 do end
  W.backToMenu(); M.tick(45)
  return screenLines()
end

-- bots (W.BOT_NAMES): 1 Biddy Blas, 2 Kestar Bool, 3 Katja Mox, 4 Zed Unknown, 5 Sen Fira
M.press('F6'); M.tick(6)
T.clickTitle('100CC'); M.tick(3)
T.clickTitle('JAKKU CUP')
-- race 1: Biddy 15, you 12, Sen Fira 10. No record line: room for the rival's own line
local L = race(2, { 1, 5 }, 120)
T.check(has(L, '3 POINTS BEHIND BIDDY BLAS, 3 RACES LEFT') and has(L, 'RIVAL: SEN FIRA, 2 BEHIND YOU'),
  'race 1: the stakes, and the rival 2 behind you on its own line (' .. show(L) .. ')')
T.check(#L <= 4, 'race 1: 4 lines at most (' .. #L .. ')')
T.clickTitle('NEXT RACE')
-- race 2: Sen Fira 15 (25), Biddy 12 (27), you 10 (22); a new record on track 2: no room, the rival on your line
L = race(3, { 5, 1 }, 118)
T.check(has(L, '5 POINTS BEHIND BIDDY BLAS, 2 RACES LEFT'), 'race 2: the stakes (' .. show(L) .. ')')
T.check(has(L, 'You: 3rd in this race   -   1:58.00   -   RIVAL: SEN FIRA, AHEAD BY 3'), 'race 2: the rival ahead by 3, on your line')
T.check(#L == 4 and count(L, 'SEN FIRA') == 1, 'race 2: still 4 lines, the rival named once')
T.clickTitle('NEXT RACE')
-- race 3: Sen Fira 40, Biddy 39, you 32: the stakes line names the rival -> merged, no second mention
L = race(3, { 5, 1 }, 120)
T.check(has(L, '8 POINTS BEHIND YOUR RIVAL SEN FIRA, 1 RACE LEFT'), 'race 3: merged into the stakes line (' .. show(L) .. ')')
T.check(count(L, 'SEN FIRA') == 1 and count(L, 'RIVAL:') == 0 and #L <= 4, 'race 3: the rival named once, no RIVAL: line')
T.clickTitle('NEXT RACE')
-- race 4: you 1st (47), Biddy 2nd (51), Sen Fira 3rd (50): bronze, 3 points from silver
L = race(1, { 1, 5 }, 120)
T.check(T.titles() == 'CONTINUE', 'race 4: the cup result')
T.check(count(L, 'RIVAL: SEN FIRA, AHEAD BY 3') == 1 and count(L, 'SEN FIRA') == 1, 'the cup result: the rival ahead by 3, once (' .. show(L) .. ')')
T.check(#L <= 5, 'the cup result: 5 lines at most (' .. #L .. ')')
T.check(RV.name(K.data, '100') == 'Sen Fira', 'the rival kept through the cup (no flip)')
-- HOME: the 100cc tile's info names the champion (Biddy Blas, most points) and the rival
local n0 = #M.calls + 1
T.clickTitle('CONTINUE'); M.tick(3)
M.press('BACKSPACE'); M.tick(5)
-- the game's UI moves its focus to the 100CC tile
for i, t in ipairs(W.tiles) do rawget(t, '__props').__focus = (i == 2) end
M.tick(6)
local info
for i = n0, #M.calls do
  local c = M.calls[i]
  local s = c.name == 'SetText' and type(c.args[1]) == 'table' and rawget(rawget(c.args[1], '__props') or {}, '__text')
  if s and s:find('\n100cc: ') then info = s:match('\n(100cc: [^\n]*)') end -- (v0.14: under the class's blurb)
end
T.check(info == '100cc: parts level 3, abilities 1.  Gold 0 / 6, trophies 1 / 6.  Champion: BIDDY BLAS.  Rival: SEN FIRA',
  'HOME info names the rival next to the champion (' .. tostring(info) .. ')')
T.finish()
