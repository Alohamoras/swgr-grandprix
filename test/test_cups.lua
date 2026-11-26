-- v0.26 (random cups): one cup per planet, its 4 races drawn from the planet's pool when you pick it (the same rule in
-- every league), the Galactic Cup, the title race: 7 tiles at every league. A cup tile shows its medal but no
-- conditions line; the focused cup's info names the planet's tracks. A cup races its draw, in order. Records are kept
-- per exact event path. (v0.11-v0.25: a fixed race list per class; the old remix / conditions / Outer Rim results were
-- dropped from the save at load - an old save now gets a clean start, test_leagues.)
local M = require('mock')
local W = require('world')
local T = require('util')
local EV = '/Game/Griffin/Gameplay/Events/Planets/'
local REV = EV .. 'Mastiff/Loop_A/EVT_MAS_LOOP_A_REV'
T.boot({ version = 3, races = 80, cups = 12, class = 'riffraff',
  best = { riffraff = { jakku = 1 }, challenger = { jakku = 1, lantaana = 2 }, ace = { sentinel = 3 } },
  perfect = { challenger = { jakku = true } },
  records = { challenger = { [REV] = { time = 120.5, lap = 55, at = '2026-11-10', vehicle = 'car' } } },
  restores = {}, abilityRestores = {} }, { Progression = { On = false } })
local sv = T.save()
T.check(sv.best.challenger.jakku == 1 and sv.records.challenger[REV].time == 120.5 and sv.races == 80, 'a v3 save loads as it is')

local function descs()
  local all = {}
  for _, t in ipairs(W.tiles or {}) do
    local d = rawget(t, '__props').TxtDescription
    all[#all + 1] = d and rawget(d, '__props').__text or ''
  end
  return all
end
local H = rawget(_G, 'GU_TEST_SCREENS')
local function info(i) return tostring(H.S.ui.items[i].info or '') end
M.press('F6'); M.tick(6)
local ALL = 'JAKKU CUP|LANTAANA CUP|ANDO CUP|CRAIT CUP|SENTINEL CUP|GALACTIC CUP|RALLY CUP|PODRACER CUP' -- (v0.33: no title race)
for _, cls in ipairs({ 'JUNKER', 'CHALLENGER', 'ACE' }) do
  T.clickTitle(cls); M.tick(3)
  T.check(T.titles() == ALL, cls .. ': the 8 tiles (' .. T.titles() .. ')')
  local d = descs()
  local none = true
  for i = 1, 6 do none = none and d[i] == '' end
  T.check(none, cls .. ': no conditions line on the cup tiles (' .. table.concat(d, ' / '):gsub('\n', ' ') .. ')')
  -- (v0.36.1, owner: no track names on the cups page - the planet's line alone)
  T.check(info(1):find("Jakku. Starship wrecks boil under the scorching heat of this desert world.", 1, true) ~= nil
    and info(1):find('THE WAR FIELDS', 1, true) == nil and info(1):find('SCRAP SPIRAL', 1, true) == nil,
    cls .. ': the Jakku Cup\'s info is its planet\'s line, no track names (' .. info(1):gsub('\n', ' | ') .. ')')
  T.check(info(6):find('Derven Acos. Home of the Galactic League, where racers face the ultimate challenge.\nThree planets, then Derven Acos.\nFinish on the podium and Kestar Bool waits in the stadium. One race for the title.', 1, true) ~= nil,
    cls .. ': the Galactic Cup\'s info: the planets, then the finals, then (v0.33) the finale (' .. info(6):gsub('\n', ' | ') .. ')')
  M.press('BACKSPACE'); M.tick(3)
end
T.clickTitle('CHALLENGER'); M.tick(3)
T.check(T.medals():find('^GOLD|SILVER|', 1) ~= nil and T.marks():find('^CROWN GOLD|') ~= nil,
  'Challenger: the Jakku gold with its perfect-cup crown (v0.37), the Lantaana silver (' .. T.marks() .. ')')
M.press('BACKSPACE'); M.tick(3)

-- a cup races its draw (the tests' fixed rnd: pool order, each track's last variant)
T.clickTitle('JUNKER'); M.tick(3)
local mark = T.mark()
T.clickTitle('JAKKU CUP')
T.check(T.logHas('[cup] JUNKER jakku drawn: THE WAR FIELDS (REVERSE, SCORCHING) / THE GIANTS\' GRAVEYARD / DEBRIS DUNES (REVERSE, SCORCHING) / FALLEN EMPIRE (SCORCHING)', mark),
  'the draw logged')
T.check(T.logHas('LAUNCH EVT_MAS_LOOP_A_REV_HARD (THE WAR FIELDS (REVERSE, SCORCHING) - Circuit) league=riffraff', mark), 'race 1 = the first race drawn')
T.check(T.save().run.cup == 'jakku' and T.save().run.races == 4 and #T.save().run.list == 4, 'the planet cup, four races, the draw in the run')
W.race(11); M.tick(5); W.finish(2); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
mark = T.mark()
T.clickTitle('NEXT RACE')
T.check(T.logHas("LAUNCH EVT_MAS_P2P_FWD (THE GIANTS' GRAVEYARD - Sprint) league=riffraff", mark), 'race 2 = the second race drawn')
W.race(11); M.tick(5); W.finish(2, 61.5, 61.5); M.tick(25)
t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
sv = T.save()
T.check(sv.records.riffraff[EV .. 'Mastiff/P2P_A/EVT_MAS_P2P_FWD'] ~= nil and sv.records.challenger[REV].time == 120.5,
  'records per league and exact path: the new one under Riff-Raff, the Challenger one untouched')
M.press('BACKSPACE'); M.tick(5)
T.clickTitle('YES'); M.tick(3)
T.check(T.save().run == nil, 'left the cup')
T.clickTitle('ACE'); M.tick(3)
mark = T.mark()
T.clickTitle('ANDO CUP')
T.check(T.logHas('LAUNCH EVT_COR_Loop_A_REV_Overcast_Snow (ICE FIELD CIRCUIT (REVERSE, SNOW) - Circuit) league=ace', mark), 'Ace: Ando drawn from its own pool (Ice Field, reverse, snow)')
T.finish()
