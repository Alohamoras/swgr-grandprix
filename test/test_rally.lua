-- v0.30 (owner 2026-11-24): the RALLY CUP. Seven point-to-point stages, one per route and direction in tour order
-- (the rally pool's order), the variant of each drawn at the start (the tests' rnd: the last variant of each base) and
-- kept from you until the stage loads (the NEXT RACE tile and the results prompt name the route only), the finale at
-- night; a four-car grid (you + three rivals drawn from the racers, the same three all cup, through the title race's
-- grid cut, put back at the menu); the standings by TOTAL TIME (a DNF = the slowest finisher + 30 s); the cup counts
-- for no planet-cup unlock and sets no title-race leader.
local M = require('mock')
local W = require('world')
local T = require('util')
local ORIG_OPP = 'Mercenary,ElegantProfessional,Star,InnerHonour,Thrall,Ghost,Rager,Nomad,Veteran,QuietStrength,Protege'
local function grid(path)
  local n = path:match('([^/]+)$')
  local e = M.assets[path .. '.' .. n]
  local ents = rawget(e, '__props').GridMakeup.Entries
  local s = {}
  for i = 1, ents:GetArrayNum() do s[i] = tostring(ents[i].NumEntrants) end
  return table.concat(s, ',')
end
local function wait3() local t0 = os.time(); while os.time() - t0 < 3 do end end
local function near(a, b) return a and b and math.abs(a - b) < 0.01 end

T.boot({ version = 3, races = 0, cups = 0, restores = {}, abilityRestores = {} }, { Progression = { On = false } })
W.cupEvents()
local K, cfg, CU, SD, CH = require('gp'), require('config'), require('cup'), require('standings'), require('chain')
local H = rawget(_G, 'GU_TEST_SCREENS')
local S = H.S
local EV = '/Game/Griffin/Gameplay/Events/Planets/'
local STAGE1 = EV .. 'Mastiff/P2P_A/EVT_MAS_P2P_FWD'

-- 1. the draw: tour order, the last variant of each base (the tests' rnd), the night finale
local d = K.draw('rally', T.RND)
local paths = {}
for i, r in ipairs(d) do paths[i] = r.path:match('([^/]+)$') end
T.check(#d == 7 and table.concat(paths, ' ') == 'EVT_MAS_P2P_FWD EVT_DAL_P2P_FWD_Overcast_Wet EVT_SPA_Loop_B_P2P_MINES EVT_HSK_P2P_REV EVT_HSK_P2P_FWD_Overcast EVT_COR_P2P_FWD_Overcast_Snow EVT_COR_P2P_REV_Night',
  'the draw: 7 stages in tour order, a variant each, the finale at night (' .. table.concat(paths, ' ') .. ')')
-- a different rnd: the finale is still a night stage
local nightOk = true
for seed = 1, 7 do
  local x = K.draw('rally', function(n) return (seed - 1) % n + 1 end)
  nightOk = nightOk and #x == 7 and x[7].path:find('_Night', 1, true) ~= nil and x[1].base == "THE GIANTS' GRAVEYARD"
end
T.check(nightOk, 'whatever is drawn, the last stage is Dai Bendu Ascension at night')

-- 2. the cups page: the RALLY CUP last; its info
M.press('F6'); M.tick(6)
T.clickTitle('JUNKER'); M.tick(3)
T.check(T.titles():find('|RALLY CUP$') ~= nil, 'the RALLY CUP tile on the cups page (' .. T.titles() .. ')')
local info
for _, it in ipairs(H.SCREENS.cups().items) do if it.title == 'RALLY CUP' then info = tostring(it.info) end end
T.check(info:find('Seven stages, four racers, the clock decides. Weather and nightfall are unknown until you arrive.', 1, true) ~= nil and info:find('DAI BENDU ASCENSION', 1, true) == nil,
  'its info: the stage count, the grid, the time standings, the routes (' .. info:gsub('\n', ' / ') .. ')')

-- 3. the start: the rivals drawn (the tests' rnd: the first three racers but you), the grid cut to 4, stage 1 launched
local mark = T.mark()
T.clickTitle('RALLY CUP')
T.check(T.logHas("[cup] JUNKER rally drawn: THE GIANTS' GRAVEYARD / GEOTHERMAL TOUR (WET) / RHODOCHROSITE RUN (MINES) / BOOL RIVER RUN / BOOL RIVER RUN (FORWARD, OVERCAST) / MOUNTAIN TO SEA (SNOW) / DAI BENDU ASCENSION (NIGHT)", mark),
  'the draw logged in full (the log may know the weather)')
T.check(T.logHas('[rally] rivals for the cup: Ary Quill, Malis Vazosk, Nik Skandaro (a 4-car grid)', mark), 'three rivals drawn, logged')
T.check(T.logHas("LAUNCH EVT_MAS_P2P_FWD (THE GIANTS' GRAVEYARD - Sprint) league=riffraff", mark), 'stage 1 launched')
-- v0.34.3: the rally's AI profile = the league's + Rally.AI (the catch-up back on, strong)
T.check(T.logHas('[ai] league riffraff (rally profile): AI config (DA_AIConfig)', mark)
  and T.logHas('DefaultPacingSettings.MaxAiCatchupScale 1.3 -> 1.6', mark) and T.logHas('DefaultPacingSettings.AiBehindTimeToMaxCatchup 2 -> 0.5', mark)
  and T.logHas('DefaultPacingSettings.MaxAiSlowdownScale 0.75 -> 0.4', mark),
  'v0.34.3: the rally profile on the AI config - catch-up x1.6 after 0.5 s, the league\'s own slowdown kept')
T.check(T.logHas('[ai] league riffraff (rally profile): pacing asset (RP_Default)', mark) and T.logHas('PacingSettingsConfig.AiBehindTimeToMaxCatchup 2 -> 0.5', mark),
  'v0.34.3: the same on the pacing assets')
T.check(T.logHas('[ai] league riffraff (rally profile): pressure -1.00', mark), 'v0.34.3: the league\'s pressure stays')
local sv = T.save()
T.check(sv.run and sv.run.cup == 'rally' and sv.run.races == 7 and #sv.run.list == 7 and sv.run.timed == true
  and table.concat(sv.run.rivals, ',') == 'Protege,Mercenary,QuietStrength' and sv.run.dnfPenalty == 30,
  'the run in the save: 7 stages, timed, the three rivals, the DNF penalty')
T.check(grid(STAGE1) == '4', 'the event\'s grid make-up: 4 entrants (' .. grid(STAGE1) .. ')')
T.check(W.charsText() == 'Player=DarkEnigma Opp=Protege,Mercenary,QuietStrength', 'CharacterList.Opponents = the three rivals (' .. W.charsText() .. ')')
T.check(T.logHas('[title] grid cut for the rally: EVT_MAS_P2P_FWD make-up 12 -> 4 entrants; CharacterList.Opponents 11 -> Protege,Mercenary,QuietStrength', mark), 'the cut logged')
T.check(sv.gridRestore and sv.gridRestore.event == STAGE1 and #sv.gridRestore.opponents == 11, 'the originals in the save (gridRestore)')

-- 4. stage 1: Biddy Blas 1st in 1:38.50, you 2nd in 1:40.00, Kestar 3rd in 1:41.20, Katja Mox out (a DNF: 1:41.20 + 30 s)
W.race(3); M.tick(5)
W.botFinish(1, 1, 98.5); W.botFinish(2, 3, 101.2); W.botFinish(3, 4, 0, false)
W.finish(2, 100.0, 100.0); M.tick(25)
wait3()
W.backToMenu(); M.tick(45)
sv = T.save()
local tm = sv.run and sv.run.times or {}
T.check(near(tm.YOU, 100) and near(tm['Biddy Blas'], 98.5) and near(tm['Kestar Bool'], 101.2) and near(tm['Katja Mox'], 131.2),
  ('the stage times: you 100, Biddy 98.5, Kestar 101.2, Katja 131.2 (DNF) (%s %s %s %s)'):format(tm.YOU, tm['Biddy Blas'], tm['Kestar Bool'], tm['Katja Mox']))
T.check(sv.run.history[1][4].key == 'Katja Mox' and sv.run.history[1][4].pen == true and sv.run.history[1][2].key == 'YOU' and sv.run.history[1][2].place == 2,
  'the stage rows: by time, the DNF last with the penalty flag')
T.check(grid(STAGE1) == '12' and W.charsText() == 'Player=DarkEnigma Opp=' .. ORIG_OPP, 'at the menu: the make-up and the list put back (' .. W.charsText() .. ')')
-- the standings screen: stage 1 of 7, the time table, the gap stakes line
local spec = SD.spec(S.result)
local function joined(lines) local t = {}; for _, l in ipairs(lines or {}) do t[#t + 1] = tostring(l[1]) end; return table.concat(t, ' | ') end
T.check(joined(spec.lines):find("RALLY CUP   -   THE GIANTS' GRAVEYARD   -   STAGE 1 OF 7", 1, true) ~= nil, 'the header counts stages (' .. joined(spec.lines) .. ')')
T.check(joined(spec.lines):find('1.5 S BEHIND BIDDY BLAS, 6 STAGES LEFT', 1, true) ~= nil, 'the stakes line in seconds (' .. joined(spec.lines) .. ')')
local tb = spec.table
local function row(i) return table.concat(tb.rows[i].cells, '/') end
T.check(tb.header[3] == 'THIS STAGE' and tb.header[4] == 'TOTAL' and tb.header[5] == 'GAP', 'the table: THIS STAGE / TOTAL / GAP (' .. table.concat(tb.header, '/') .. ')')
T.check(row(1) == '1st/Biddy Blas/1:38.50/1:38.50/' and row(2) == '2nd/YOU/1:40.00/1:40.00/+1.5' and row(4) == '4th/Katja Mox/DNF/2:11.20/+32.7',
  'the rows: times, the gap to the leader, DNF for the one out (' .. row(1) .. ' ; ' .. row(2) .. ' ; ' .. row(4) .. ')')
-- the next stage is named by its route only
local nxt = K.nextRace()
T.check(nxt.shown == 'GEOTHERMAL TOUR' and nxt.title == 'GEOTHERMAL TOUR (WET)' and nxt.rally == true and #nxt.rivals == 3,
  'the next stage: shown as GEOTHERMAL TOUR, really the wet one, the rivals along (' .. tostring(nxt.shown) .. ')')
T.check(CH.prompt(S.result) == 'NEXT   GEOTHERMAL TOUR          B   LEAVE THE CUP', 'the results prompt keeps the weather secret (' .. tostring(CH.prompt(S.result)) .. ')')
local tile
for _, it in ipairs(S.ui and S.ui.items or {}) do if it.title == 'NEXT RACE' then tile = it end end
T.check(tile and not tostring(tile.desc):find('WET', 1, true), 'the NEXT RACE tile too (' .. tostring(tile and tile.desc) .. ')')

-- 5. stages 2-7: you win each by a second; the cup result by total time, no planet-cup effect
local names = { 'GEOTHERMAL TOUR (WET)', 'RHODOCHROSITE RUN (MINES)', 'BOOL RIVER RUN', 'BOOL RIVER RUN (FORWARD, OVERCAST)', 'MOUNTAIN TO SEA (SNOW)', 'DAI BENDU ASCENSION (NIGHT)' }
local launched = true
for s = 2, 7 do
  mark = T.mark()
  T.clickTitle('NEXT RACE')
  launched = launched and T.logHas('LAUNCH ' .. paths[s] .. ' (' .. names[s - 1] .. ' - Sprint) league=riffraff', mark)
  W.race(3); M.tick(5)
  W.botFinish(1, 2, 101.0); W.botFinish(2, 3, 102.0); W.botFinish(3, 4, 103.0)
  W.finish(1, 100.0, 100.0); M.tick(25)
  wait3()
  W.backToMenu(); M.tick(45)
end
T.check(launched, 'stages 2-7 launched in the drawn order, weather and all')
sv = T.save()
-- totals: you 700.0; Biddy 98.5 + 6 x 101 = 704.5; Kestar 101.2 + 612 = 713.2; Katja 131.2 + 618 = 749.2
T.check(sv.run == nil and sv.best.riffraff.rally == 1 and sv.cups == 1 and sv.races == 7, 'the cup over: gold, counted')
T.check(T.logHas('cup over: JUNKER rally - you 1st with 11:40.00 in all, GOLD trophy'), 'the cup result logged in time, not points')
T.check(sv.leader.riffraff == nil, 'the Rally Cup sets no title-race leader')
T.check(sv.standings.riffraff.rally ~= nil and sv.perfect.riffraff == nil, 'standings kept; not a perfect cup (2nd on stage 1)')
spec = SD.spec(S.result)
T.check(spec.cupOver and joined(spec.hero.lines):find('RALLY CUP   -   JUNKER   -   11:40.00 in all', 1, true) ~= nil, 'the cup result: the total time (' .. joined(spec.hero.lines) .. ')')
T.check(spec.table.rows[1].cells[3] == '11:40.00' and spec.table.rows[2].cells[2] == 'Biddy Blas' and spec.table.rows[2].cells[3] == '11:44.50',
  'the podium in times (' .. table.concat(spec.table.rows[2].cells, '/') .. ')')

-- 6. the near miss in seconds, pure
local st = CU.new('ace', 'rally', 'car', 2, { timed = true, dnfPenalty = 30, gapGuess = 2 })
CU.addRace(st, { { name = 'A', pos = 1, finished = true, time = 100 }, { name = 'Dwayne', you = true, pos = 2, finished = true, time = 101.5 } })
T.check(CU.stakes(st) == '1.5 S BEHIND A, 1 STAGE LEFT', 'stakes: behind (' .. tostring(CU.stakes(st)) .. ')')
CU.addRace(st, { { name = 'A', pos = 1, finished = true, time = 100 }, { name = 'Dwayne', you = true, pos = 2, finished = true, time = 100.3 } })
T.check(CU.nearTrophy(st, 5) == '1.8 S FROM GOLD' and CU.nearTrophy(st, 1) == nil, 'near miss: 1.8 S FROM GOLD within 5 s, nothing within 1 (' .. tostring(CU.nearTrophy(st, 5)) .. ')')
-- a finished racer without a time: the slowest timed + 2 s a place, flagged
local st2 = CU.new('ace', 'rally', 'car', 1, { timed = true })
local rows = CU.addRace(st2, { { name = 'A', pos = 1, finished = true, time = 90 }, { name = 'B', pos = 2, finished = true, time = 0 }, { name = 'Dwayne', you = true, pos = 3, finished = true, time = 95 } })
T.check(rows[2].key == 'YOU' and rows[3].key == 'B' and near(rows[3].t, 97) and rows[3].est == true, 'no time read: after the timed, slowest + 2 s, flagged est (' .. tostring(rows[3].t) .. ')')
T.finish()
