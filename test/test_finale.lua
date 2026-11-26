-- v0.33 (owner 2026-11-25: "ditch the title race and put the Kestar race at the end of the Galactic Cup"; "use the
-- planets from the end of cup screen"): the Galactic Cup's four points races decide the trophy; a trophy (config
-- Boss.Gate) adds Kestar Bool's Stadium Showdown as race 5 of the same cup - no points; winning it makes you the
-- league champion (the star on the league's HOME tile), at Ace it unlocks Kestar as a racer; off the podium the cup
-- just ends. No title race tile, no boss tile. The cup tiles carry the game's round planet pictures on their left.
local M = require('mock')
local W = require('world')
local T = require('util')
local function wait3() local t0 = os.time(); while os.time() - t0 < 3 do end end
local EVB = '/Game/Griffin/Gameplay/Events/Planets/Whippet/FINALBOSS/EVT_WHP_SHORTBOSS_FAIR'
local PLANETS = '/Game/Griffin/UI/Library/Textures/Content/Planets/T_UI_Planet_'

T.boot({ version = 3, races = 20, cups = 5, class = 'riffraff', restores = {}, abilityRestores = {} }, { Progression = { On = false } })
W.cupEvents()
if not M.assets[EVB .. '.EVT_WHP_SHORTBOSS_FAIR'] then W.raceEvent(EVB, 6) end
local H = rawget(_G, 'GU_TEST_SCREENS')
local K, CU, TI, RC = require('gp'), require('cup'), require('title'), require('racer')
local cfg = require('config')

---------------------------------------------------------------------------------------------------------------------
-- 1. the cups page: seven tiles, no title race, no boss; the planets on the tiles; the Galactic Cup's info
M.press('F6'); M.tick(6)
T.clickTitle('JUNKER'); M.tick(3)
T.check(T.titles() == 'JAKKU CUP|LANTAANA CUP|ANDO CUP|CRAIT CUP|SENTINEL CUP|GALACTIC CUP|RALLY CUP' and T.ntiles() == 7,
  'the cups page: the seven cups, no TITLE RACE, no KESTAR BOOL (' .. T.titles() .. ')')
-- v0.34.1: the planets are off by default (owner); the code is still covered with the switch set
T.check(cfg.CupPlanets == false and H.SCREENS.cups().items[1].glyph == nil, 'v0.34.1: CupPlanets off by default, no planet on the tiles')
cfg.CupPlanets = 0.86
local items = H.SCREENS.cups().items
local function ball(i) local g = items[i].glyph; return g and g[1] or 'none' end
T.check(ball(1) == PLANETS .. 'Mas' and ball(2) == PLANETS .. 'Dal' and ball(3) == PLANETS .. 'Cor' and ball(4) == PLANETS .. 'Spa' and ball(5) == PLANETS .. 'Hus',
  'the planet cups carry their planet\'s round picture (' .. ball(1) .. ')')
T.check(ball(6) == PLANETS .. 'Whp' and ball(7) == PLANETS .. 'Cor', 'the Galactic Cup Derven Acos, the Rally Cup Ando Prime')
T.check(items[1].glyph.side == 'left' and items[1].glyph.scale == cfg.CupPlanets and cfg.CupPlanets == 0.86, 'on the left, at the config\'s share of the tile height')
T.check(items[6].info:find('Finish on the podium and Kestar Bool waits in the stadium. One race for the title.', 1, true) ~= nil, 'the Galactic Cup\'s info says the finale')
cfg.CupPlanets = false
T.check(H.SCREENS.cups().items[1].glyph == nil, 'CupPlanets = false: no planet')
T.check(T.pips('JUNKER') == nil, '(not on this page)')
M.press('BACKSPACE'); M.tick(3)
T.check(T.pips('JUNKER') == '-------.', 'home: no trophies, the champion\'s star grey (' .. tostring(T.pips('JUNKER')) .. ')')

---------------------------------------------------------------------------------------------------------------------
-- 2. the Galactic Cup at Junker, 3rd in every race: bronze, the finale added as race 5; lost to Kestar
local function race(you, nBots)
  W.race(nBots or 11); M.tick(5)
  for i, b in ipairs(W.bots) do
    local rec = rawget(rawget(b, '__props').RaceEventComponent, '__props')
    rec.EventPosition, rec.bHasFinishedEvent = (i < you) and i or i + 1, true
  end
  M.tick(5); W.finish(you); M.tick(25)
  wait3()
  W.backToMenu(); M.tick(45)
end
T.clickTitle('JUNKER'); M.tick(3)
local mark = T.mark()
T.clickTitle('GALACTIC CUP')
T.check(M.called('LaunchQuickRace') == 1 and T.save().run.races == 4 and not T.save().run.finale, 'the cup starts with its four races')
race(3)
for i = 2, 4 do
  T.check(T.titles() == 'NEXT RACE' and T.badges() == ('RACE %d / 4'):format(i), 'standings: NEXT RACE ' .. i .. ' / 4 (' .. T.badges() .. ')')
  T.clickTitle('NEXT RACE'); race(3)
end
T.check(T.logHas('cup JUNKER galactic: 3rd with 40 points after 4 races - BRONZE trophy; the finale added as race 5: KESTAR BOOL', mark), 'after race 4: bronze, the finale added (logged)')
local sv = T.save()
T.check(sv.run and sv.run.races == 5 and sv.run.finale == true and sv.run.decided.rank == 3 and sv.run.decided.trophy == 'BRONZE' and sv.run.list[5].boss == true and sv.run.list[5].path == EVB,
  'the run: five races, the finale flagged, the result decided by the points races')
T.check(T.titles() == 'NEXT RACE' and T.badges() == 'RACE 5 / 5', 'standings: NEXT RACE 5 / 5 (' .. T.badges() .. ')')
local it = H.S.ui.items[1]
T.check(it.desc == 'KESTAR BOOL  -  1 v 1' and tostring(it.art):find('Antagonist', 1, true) ~= nil, 'the tile: KESTAR BOOL - 1 v 1 on the stadium picture (' .. tostring(it.desc) .. ')')
local lines = {}
for _, l in ipairs(H.SCREENS.standings().lines or {}) do lines[#lines + 1] = type(l) == 'table' and tostring(l[1]) or tostring(l) end
local text = table.concat(lines, ' / ')
T.check(text:find('RACE 4 OF 5', 1, true) ~= nil and text:find('BRONZE TROPHY SECURED. KESTAR BOOL NEXT, ONE RACE FOR THE JUNKER TITLE', 1, true) ~= nil,
  'the standings say the trophy is secured and the finale is next (' .. text .. ')')
T.check(CU.stakes(sv.run, cfg.Points) == nil, 'no stakes line: the finale scores no points')
mark = T.mark()
T.clickTitle('NEXT RACE')
T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name') == 'EVT_WHP_SHORTBOSS_FAIR', 'NEXT RACE launches the Stadium Showdown')
T.check(T.logHas('[title] story cinematics taken off', mark) or T.logHas('EVT_WHP_SHORTBOSS_FAIR (KESTAR BOOL - 1 v 1)', mark), 'as the boss race (the cinematics off; the LAUNCH line)')
T.check(not T.logHas('[title] grid cut', mark), 'no grid cut (the Showdown is a 1 v 1 already)')
race(2, 1)
T.check(T.logHas('FINALE JUNKER: lost, 2nd vs Kestar Bool (try 1)', mark), 'lost: logged')
T.check(T.logHas('cup over: JUNKER galactic - you 3rd with 40 points, BRONZE trophy', mark), 'the cup over with the points races\' result')
sv = T.save()
T.check(sv.run == nil and sv.best.riffraff.galactic == 3 and sv.titles.riffraff.tries == 1 and not sv.titles.riffraff.won and sv.boss == nil,
  'saved: the bronze, one try at the title, not won; the boss untouched (not Ace)')
T.check(not dofile(T.dir .. '/Scripts/core.lua').serialize(sv.records or {}):find('SHORTBOSS', 1, true), 'no track record for the Showdown')
T.check(T.titles() == 'CONTINUE', 'the cup result page')
local spec = H.SCREENS.standings()
local hero = {}
for _, l in ipairs(spec.hero and spec.hero.lines or {}) do hero[#hero + 1] = tostring(l[1]) end
text = table.concat(hero, ' / ')
T.check(text:find('BRONZE TROPHY', 1, true) ~= nil and text:find('KESTAR BOOL KEEPS THE TITLE', 1, true) ~= nil, 'the cup result: the bronze, Kestar keeps the title (' .. text .. ')')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(T.medals():find('|BRONZE|$') ~= nil and T.ntiles() == 7, 'the cups page: the Galactic bronze, still seven tiles (' .. T.medals() .. ')')
M.press('BACKSPACE'); M.tick(3)
T.check(T.pips('JUNKER') == '-----B-.', 'home: the bronze, the star still grey (' .. tostring(T.pips('JUNKER')) .. ')')

---------------------------------------------------------------------------------------------------------------------
-- 3. off the podium: the cup ends after race 4, no finale
T.clickTitle('JUNKER'); M.tick(3)
mark = T.mark()
T.clickTitle('GALACTIC CUP')
race(6)
for i = 2, 4 do T.clickTitle('NEXT RACE'); race(6) end
T.check(T.logHas('cup over: JUNKER galactic - you 6th with 28 points', mark) and not T.logHas('the finale added', mark), 'no trophy: the cup over after four races, no finale')
sv = T.save()
T.check(sv.run == nil and sv.titles.riffraff.tries == 1 and sv.best.riffraff.galactic == 3, 'nothing more saved; the bronze kept')
T.clickTitle('CONTINUE'); M.tick(3)
M.press('BACKSPACE'); M.tick(3)

---------------------------------------------------------------------------------------------------------------------
-- 4. Ace: gold, the finale won: the Ace champion, Kestar unlocked as a racer; the cup result says so
T.check(RC.locked('Antagonist') and RC.unlockText({ unlockBoss = true }) == 'Kestar Bool races only for himself until you beat him in the ACE Galactic Cup finale.', 'Kestar locked, the unlock text names the finale (' .. tostring(RC.unlockText({ unlockBoss = true })) .. ')')
T.clickTitle('ACE'); M.tick(3)
mark = T.mark()
T.clickTitle('GALACTIC CUP')
race(1)
for i = 2, 4 do T.clickTitle('NEXT RACE'); race(1) end
T.check(T.logHas('cup ACE galactic: 1st with 60 points after 4 races - GOLD trophy; the finale added as race 5: KESTAR BOOL', mark), 'Ace: gold, the finale added')
T.clickTitle('NEXT RACE')
race(1, 1)
T.check(T.logHas('FINALE ACE: WON - you are the ACE champion vs Kestar Bool (try 1) - Kestar Bool unlocked as a racer', mark), 'won: the Ace champion, Kestar unlocked (logged)')
T.check(T.logHas('cup over: ACE galactic - you 1st with 60 points, GOLD trophy - PERFECT CUP', mark), 'the cup over: gold, perfect (the finale won too)')
sv = T.save()
T.check(sv.titles.ace.won == true and sv.titles.ace.vs == 'Kestar Bool' and sv.boss.beaten == true and sv.boss.tries == 1 and not RC.locked('Antagonist'),
  'saved: the Ace title, the boss beaten, Kestar unlocked')
spec = H.SCREENS.standings()
hero = {}
for _, l in ipairs(spec.hero and spec.hero.lines or {}) do hero[#hero + 1] = tostring(l[1]) end
text = table.concat(hero, ' / ')
T.check(text:find('GOLD TROPHY', 1, true) ~= nil and text:find('ACE CHAMPION', 1, true) ~= nil and text:find('KESTAR BOOL RACES IN YOUR COLOURS NOW', 1, true) ~= nil,
  'the cup result: gold, ACE CHAMPION, Kestar unlocked (' .. text .. ')')
-- the native cup result's summary (cupend.lua): five races, the finale without points, the maximum 60, its award line
local CE = require('cupend')
local sm = CE.summary(H.S.result)
T.check(sm and #sm.races == 5 and sm.races[5].finale and sm.races[5].pts == 0 and sm.max == 60 and sm.total == 60 and sm.finale.won,
  ('the tour-end summary: 5 races, the finale without points, 60 of 60 (%s)'):format(sm and (#sm.races .. ' ' .. sm.total .. '/' .. sm.max) or '?'))
T.clickTitle('CONTINUE'); M.tick(3)
M.press('BACKSPACE'); M.tick(3)
T.check(T.pips('ACE') == '-----G-*', 'home: the Ace Galactic gold and the champion\'s star (' .. tostring(T.pips('ACE')) .. ')')

---------------------------------------------------------------------------------------------------------------------
-- 5. the rules on their own: the gate, the race entry, the rows, the nearest goal
local run = { cup = 'galactic', class = 'challenger', history = {}, race = 5 }
T.check(TI.finaleDue(run, 3) and not TI.finaleDue(run, 4) and not TI.finaleDue(run, nil), 'Gate = trophy: top 3')
cfg.Boss.Gate = 'gold'
T.check(TI.finaleDue(run, 1) and not TI.finaleDue(run, 2), 'Gate = gold: 1st only')
cfg.Boss.Gate = 'always'
T.check(TI.finaleDue(run, 12) and TI.finaleDue(run, nil), 'Gate = always')
cfg.Boss.Gate = 'trophy'
T.check(not TI.finaleDue({ cup = 'jakku', class = 'ace', race = 5 }, 1) and not TI.finaleDue({ cup = 'rally', class = 'ace', race = 8, timed = true }, 1), 'planet cups and the Rally Cup: never')
cfg.Boss.Where = 'tile'
T.check(not TI.finaleDue(run, 1) and not TI.finaleOn(), 'Where = tile: no finale')
cfg.Boss.Where = 'cup'
local fr = TI.finaleRace()
T.check(fr.path == EVB and fr.title == 'KESTAR BOOL' and fr.kind == '1 v 1' and fr.laps == 6 and fr.boss, 'the finale as a race entry')
local r2 = { history = {}, race = 5 }
local rows = TI.finaleRows(r2, nil)
T.check(#rows == 2 and rows[1].key == 'YOU' and rows[1].dnf and rows[1].pts == 0 and rows[2].key == 'Kestar Bool' and rows[2].place == 1 and r2.race == 6, 'a DNF in the finale: your row a DNF, Kestar first')
-- the tie rule ignores the finale's rows (cup.lua rankAt)
local st = CU.new('ace', 'galactic', 'car', 4)
CU.addRace(st, { { name = 'Me', you = true, pos = 2, finished = true }, { name = 'Biddy Blas', pos = 1, finished = true } }, { 15, 12 })
CU.addRace(st, { { name = 'Me', you = true, pos = 1, finished = true }, { name = 'Biddy Blas', pos = 2, finished = true } }, { 15, 12 })
st.races, st.finale = 3, true
TI.finaleRows(st, 1)
local tab = CU.table(st)
T.check(tab[1].key == 'YOU' and tab[1].total == 27 and tab[2].total == 27 and tab[1].gain == 0, 'the table after the finale: level on points, the order from race 2 kept, no points gained (' .. tab[1].key .. ')')
local PR = require('prog')
local goal = PR.nextGoal({ best = { riffraff = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 1, galactic = 1 }, challenger = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 1, galactic = 1 }, ace = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 1, galactic = 1, rally = 1, pods = 1 } }, titles = {} }, 'ace')
T.check(goal and goal.text == 'beat Kestar Bool in the Galactic Cup finale at ACE', 'every gold: the nearest goal is the finale (' .. tostring(goal and goal.text) .. ')')
T.finish()
