-- v0.21 (owner, OWNER.md "Done" 2026-11-11): the title race is a 1 v 1 on a NORMAL track against the league leader
-- (the best bot of your most recent finished cup at the league; the league default before any cup), launched with the
-- two-car grid (the event's GridMakeup 2 entrants, CharacterList.Opponents cut to that racer; RaceFlowSpike B6) and
-- both put back at the menu exactly once - after a crash at the next boot. Never part of a cup, no points, no cup
-- records. v0.26: its track = the first race of the leader's most recent cup run (saved with the leader); before any
-- cup, the first race of a random Jakku draw, made once and kept. Kestar Bool is the final boss: a KESTAR BOOL tile on
-- the Ace cups page once the Ace title is won (8 tiles, 4 + 4), the Stadium Showdown, beating him unlocks him; an old
-- save (the cc classes) gets a clean start, which locks him again.
-- v0.33 (owner 2026-11-25): the title race is OFF and Kestar closes the Galactic Cup (test_finale); this file keeps the
-- old flow under its config (Title.On = true, Boss.Where = 'tile'), which still works.
local M = require('mock')
local W = require('world')
local T = require('util')
local EVB = '/Game/Griffin/Gameplay/Events/Planets/Whippet/FINALBOSS/EVT_WHP_SHORTBOSS_FAIR'
local function legacy(c)
  c = c or {}
  c.Title = { On = true, Name = 'TITLE RACE', DefaultCup = 'jakku', Default = { riffraff = 'Veteran', challenger = 'Rager', ace = 'Thrall' } }
  c.Boss = { On = true, Event = EVB, Name = 'KESTAR BOOL', Opponent = 'Kestar Bool', League = 'ace', Where = 'tile', Laps = 6 }
  return c
end
local five = { jakku = 3, lantaana = 1, ando = 2, crait = 3, sentinel = 1, galactic = 2 }
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

---------------------------------------------------------------------------------------------------------------------
-- 1. no cup finished at Riff-Raff: the league default (Griff Halloran) on the first race of a Jakku draw; you race as Sen Fira
T.boot({ version = 3, races = 20, cups = 5, class = 'riffraff', racer = 'Thrall', best = { riffraff = five },
  restores = {}, abilityRestores = {} }, legacy({ Progression = { On = false } }))
W.cupEvents()
local cfg = require('config')
local EV = '/Game/Griffin/Gameplay/Events/Planets/'
local JAKKU1 = EV .. 'Mastiff/Loop_A/EVT_MAS_LOOP_A_REV_HARD' -- (the tests' Jakku draw: race 1)
local CRAIT1 = EV .. 'Spaniel/Loop_A/EVT_SPA_Loop_A_REV_MINES' -- (the tests' Crait draw: race 1)
M.press('F6'); M.tick(6)
T.clickTitle('JUNKER'); M.tick(3)
T.check(T.titles():find('|TITLE RACE|RALLY CUP$') ~= nil and T.ntiles() == 8, 'the TITLE RACE tile is the 7th of 9 on the Riff-Raff cups page (v0.30: the Rally Cup after it) (' .. T.titles() .. ')')
local H = rawget(_G, 'GU_TEST_SCREENS')
local tt
for _, it in ipairs(H.SCREENS.cups().items) do if it.title == 'TITLE RACE' then tt = it end end
T.check(tt and tt.desc == 'vs Griff Halloran' and tt.badge == nil, 'the tile names the default opponent: vs Griff Halloran (' .. tostring(tt and tt.desc) .. ')')
T.check(tt and tt.info:find('Griff Halloran, one on one, on THE WAR FIELDS (REVERSE, SCORCHING), 2 laps', 1, true) ~= nil, 'its info: the track and laps (' .. tostring(tt and tt.info) .. ')')
T.check(T.save().titleTrack.riffraff == JAKKU1 and T.logCount('the title race track is THE WAR FIELDS (REVERSE, SCORCHING) (a random JAKKU CUP draw, kept)') == 1,
  'v0.26: the default track drawn once from Jakku and saved (titleTrack), logged once')
require('gp').random = function(n) return 1 end -- (another draw would differ: the saved track must not)
for _, it in ipairs(H.SCREENS.cups().items) do if it.title == 'TITLE RACE' then tt = it end end
T.check(tt.info:find('THE WAR FIELDS (REVERSE, SCORCHING)', 1, true) ~= nil and T.save().titleTrack.riffraff == JAKKU1, 'the tile shows a stable track')
require('gp').random = T.RND
local mark = T.mark()
T.clickTitle('TITLE RACE')
T.check(M.called('LaunchQuickRace') == 1 and rawget(M.lastCall('LaunchQuickRace').args[2], '__name') == 'EVT_MAS_LOOP_A_REV_HARD',
  'Select launches a normal track: the saved Jakku race')
T.check(grid(JAKKU1) == '2', 'the event\'s grid make-up: 2 entrants (' .. grid(JAKKU1) .. ')')
T.check(W.charsText() == 'Player=Thrall Opp=Veteran', 'the character list: you as Sen Fira, Opponents = Griff Halloran only (' .. W.charsText() .. ')')
T.check(T.logHas('[title] grid cut for the title race: EVT_MAS_LOOP_A_REV_HARD make-up 12 -> 2 entrants; CharacterList.Opponents 11 -> Veteran only', mark), 'the cut logged')
local sv = T.save()
T.check(sv.gridRestore and sv.gridRestore.event == JAKKU1 and #sv.gridRestore.opponents == 11 and sv.gridRestore.entries[1] == 12,
  'the originals in the save before the race (gridRestore)')
T.check(sv.run == nil, 'no cup started')
local pl = require('gp').levelsFor('riffraff')
T.check(T.levels('VBD_Bike_Base') == ('0=%d 1=%d 2=%d 3=%d 4=%d 5=%d'):format(pl[0], pl[1], pl[2], pl[3], pl[4], pl[5]), 'Riff-Raff parts on Sen Fira\'s bike (' .. T.levels('VBD_Bike_Base') .. ')')
-- the race: the racer settles 10 s in (Player back), the cut list stays for the race
W.race(1); M.tick(115)
T.check(W.charsText() == 'Player=DarkEnigma Opp=Veteran', 'the racer settled in the race: Player back, the grid cut kept (' .. W.charsText() .. ')')
W.finish(2, 130.5, 60); M.tick(25)
wait3()
W.backToMenu(); M.tick(45)
T.check(T.logHas('TITLE RACE JUNKER: lost, 2nd vs Griff Halloran on THE WAR FIELDS (REVERSE, SCORCHING) (try 1)'), 'the loss logged')
T.check(grid(JAKKU1) == '12' and W.charsText() == 'Player=DarkEnigma Opp=' .. ORIG_OPP, 'at the menu: the make-up and the list put back (' .. W.charsText() .. ')')
T.check(T.logCount('[title] grid put back') == 1 and T.logHas('[title] grid put back (main menu): make-up done (12 entrants); Opponents done (11:'),
  'put back exactly once, logged')
T.check(T.logHas('[menu] titleResult'), 'the title result screen')
sv = T.save()
T.check(sv.titles.riffraff and sv.titles.riffraff.tries == 1 and not sv.titles.riffraff.won and sv.races == 21 and sv.gridRestore == nil,
  'saved: one try, not won; the race counted; nothing left to put back')
T.check(next((sv.records or {}).riffraff or {}) == nil, 'a title race sets no cup track record')
M.tick(30)
T.check(T.logCount('[title] grid put back') == 1, 'still put back only once')

-- 2. a finished cup at Riff-Raff: Biddy Blas wins the Crait Cup -> the leader; the title race on that cup run's first race
T.clickTitle('CONTINUE'); M.tick(3)
local K, CU = require('gp'), require('cup')
local BOTS = { 'Biddy Blas', 'Sen Fira', 'Katja Mox', 'Lyren Shok', 'Ary Quill', 'Nik Skandaro', 'Shade', 'Fola Kanjen', 'Soren Zaks', 'Malis Vazosk', 'Griff Halloran' }
local function field(you)
  local f, p = { { name = 'Dwayne', you = true, pos = you, finished = true } }, 1
  for _, n in ipairs(BOTS) do
    if p == you then p = p + 1 end
    f[#f + 1] = { name = n, pos = p, finished = true }; p = p + 1
  end
  return f
end
K.startCup('riffraff', 'crait', 'bike')
for i = 1, 4 do K.record(K.nextRace(), 3, field(3), { time = 100 + i }) end
T.check(K.data.leader.riffraff.name == 'Biddy Blas' and K.data.leader.riffraff.cup == 'crait' and K.data.leader.riffraff.path == CRAIT1,
  'the cup over: Biddy Blas (the winner) is the Riff-Raff leader, saved with the cup run\'s first race')
T.check(T.logHas('[title] JUNKER leader: Biddy Blas (best bot of the crait) - the title race opponent, on CRIMSON MINES (REVERSE, MINES)'), 'the leader logged')
-- (you won a cup: the 2nd is the leader)
K.startCup('challenger', 'jakku', 'car')
for i = 1, 4 do K.record(K.nextRace(), 1, field(1), { time = 100 + i }) end
T.check(K.data.leader.challenger.name == 'Biddy Blas' and require('title').leaderOf({ points = { YOU = 60, A = 40, B = 41 }, last = {} }) == 'B',
  'you won: the best bot (2nd overall) is the leader')
M.press('BACKSPACE'); M.tick(5)
T.clickTitle('JUNKER'); M.tick(3)
for _, it in ipairs(H.SCREENS.cups().items) do if it.title == 'TITLE RACE' then tt = it end end
T.check(tt.desc == 'vs Biddy Blas' and tt.info:find('on CRIMSON MINES (REVERSE, MINES)', 1, true) ~= nil, 'the tile: vs Biddy Blas, on the Crait Cup run\'s first race (' .. tt.info .. ')')
T.clickTitle('TITLE RACE')
T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name') == 'EVT_SPA_Loop_A_REV_MINES' and grid(CRAIT1) == '2' and W.charsText() == 'Player=Thrall Opp=Rager',
  'launched on that race, the grid you and Biddy Blas (' .. W.charsText() .. ')')
W.race(1); M.tick(5)
W.finish(1, 120, 55); M.tick(25)
wait3()
W.backToMenu(); M.tick(45)
T.check(T.logHas('TITLE RACE JUNKER: WON - you are the champion vs Biddy Blas on CRIMSON MINES (REVERSE, MINES) (try 2)'), 'the win logged')
sv = T.save()
T.check(sv.titles.riffraff.won == true and sv.titles.riffraff.tries == 2 and sv.titles.riffraff.vs == 'Biddy Blas', 'saved: won on the second try, vs Biddy Blas')
T.check(grid(CRAIT1) == '12' and W.charsText() == 'Player=DarkEnigma Opp=' .. ORIG_OPP, 'put back again')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(T.marks():find('|GOLD|$') ~= nil and not T.badges():find('CHAMPION', 1, true), 'v0.24: the title tile shows a gold medal (no CHAMPION word) (' .. T.marks() .. ')')
T.check(not T.titles():find('KESTAR BOOL', 1, true), 'no boss tile at Riff-Raff')
-- the leader is your own racer: never a mirror match (the league default instead)
K.data.leader.riffraff = { name = 'Sen Fira', cup = 'jakku', path = CRAIT1 }
local ev = require('title').event('riffraff')
T.check(ev.opponent == 'Veteran' and ev.vs == 'Griff Halloran' and ev.path == JAKKU1, 'racing as Sen Fira, the leader Sen Fira: the league default instead, on the default track (' .. ev.vs .. ')')
-- a leader saved before v0.26 (no path) or with a path no pool knows: the default track
K.data.leader.riffraff = { name = 'Biddy Blas', cup = 'crait' }
T.check(require('title').event('riffraff').path == JAKKU1, 'a leader without a track: the default track')

---------------------------------------------------------------------------------------------------------------------
-- 3. a crash mid title race: the grid and the list stay cut in memory, the save holds the originals; at the next boot
-- they are put back at the first menu
local save = T.save()
save.gridRestore = { event = JAKKU1, entries = { 12 }, opponents = {}, vs = 'Lyren Shok' }
for i, k in ipairs({ 'Mercenary', 'ElegantProfessional', 'Star', 'InnerHonour', 'Thrall', 'Ghost', 'Rager', 'Nomad', 'Veteran', 'QuietStrength', 'Protege' }) do
  save.gridRestore.opponents[i] = '/Game/Griffin/Narrative/CharacterDefs/Racers/DA_Racer_' .. k
end
T.reset()
T.boot(save, legacy({ Progression = { On = false }, Manual = true }))
W.cupEvents()
-- what the crashed game left (memory survives in this fake: the cut grid and list)
rawget(M.assets[JAKKU1 .. '.EVT_MAS_LOOP_A_REV_HARD'], '__props').GridMakeup.Entries[1].NumEntrants = 2
local cp = rawget(W.chars, '__props')
cp.Opponents = M.tarr({ W.racerDef('Star') })
T.check(W.charsText() == 'Player=DarkEnigma Opp=Star' and grid(JAKKU1) == '2', 'crashed: the grid and the list as the title race left them')
W.tabMenu(); M.tick(30)
T.check(grid(JAKKU1) == '12' and W.charsText() == 'Player=DarkEnigma Opp=' .. ORIG_OPP, 'the next boot: both put back at the first menu (' .. W.charsText() .. ')')
T.check(T.logHas('[title] grid put back (left over from an earlier race): make-up done (12 entrants); Opponents done (11:'), 'logged as left over')
T.check(T.save().gridRestore == nil and T.logCount('[title] grid put back') == 1, 'cleared from the save, once')
T.finish()

---------------------------------------------------------------------------------------------------------------------
-- 4. the final boss: the Ace title won (vs the leader): the KESTAR BOOL tile on the Ace page (8 tiles,
-- 4 + 4, no scrolling); Kestar locked until beaten; beating him unlocks him
T.reset()
local all = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 1, galactic = 1 }
T.boot({ version = 3, races = 30, cups = 7, class = 'ace', best = { ace = all, challenger = all },
  titles = { ace = { won = true, tries = 1, vs = 'Sen Fira' }, challenger = { won = true, tries = 1, vs = 'Biddy Blas' } },
  restores = {}, abilityRestores = {} }, legacy({ Progression = { On = false } }))
W.cupEvents()
local RC = require('racer')
T.check(RC.locked('Antagonist'), 'Kestar still locked: the title alone doesn\'t unlock him')
require('config').Pods.On = false -- (v0.40: this block checks the v0.23 two-row layout with the title race and Kestar; no pods tile)
M.press('F6'); M.tick(6)
T.clickTitle('CHALLENGER'); M.tick(3)
T.check(T.ntiles() == 8 and not T.titles():find('KESTAR', 1, true), 'Challenger (its title won too): 8 tiles, no boss')
M.press('BACKSPACE'); M.tick(5)
T.clickTitle('ACE'); M.tick(3)
T.check(T.ntiles() == 9 and T.titles():find('|GALACTIC CUP|TITLE RACE|KESTAR BOOL|RALLY CUP$') ~= nil, 'Ace: 9 tiles, KESTAR BOOL then the Rally Cup (' .. T.titles() .. ')')
local spec = H and rawget(_G, 'GU_TEST_SCREENS').SCREENS.cups()
T.check(spec.rows and #spec.rows == 2 and spec.rows[1].n == 5 and #spec.items == 9 and spec.center,
  'v0.23: two rows, centred: the five planets, then the Galactic Cup, the title race, Kestar and (v0.30) the Rally Cup (no scrolling)')
local U = require('ui')
local nav = U.rowsNav(spec.rows, spec.items)
T.check(spec.items[6].span == 2 and nav[1].down == 6 and nav[5].down == 9 and (nav[6].up == 1 or nav[6].up == 2) and nav[8].up == 4 and nav[3].down == 7 and nav[9].up == 5,
  'v0.23: the Galactic Cup two tiles wide; the D-pad goes to the nearest tile in the next row')
T.check(nav[1].left == nil and nav[5].right == nil and nav[6].right == 7 and nav[8].down == nil and nav[9].right == nil, 'v0.23: edges left to the game')
T.check(spec.items[8].art:find('RacerStyle_Antagonist', 1, true) ~= nil, 'v0.25: Kestar\'s tile keeps the stadium picture (the character art drew broken in game)')
T.check(T.marks():find('|$') ~= nil and not T.badges():find('BOSS', 1, true), 'v0.24: the boss tile has no badge and no medal yet (' .. T.marks() .. ')')
mark = T.mark()
T.clickTitle('KESTAR BOOL')
T.check(rawget(M.lastCall('LaunchQuickRace').args[2], '__name') == 'EVT_WHP_SHORTBOSS_FAIR', 'the Stadium Showdown')
T.check(T.levels('VBD_Car_Base') == '0=10 1=10 2=10 3=10 4=10 5=10', 'Ace parts')
T.check(not T.logHas('[title] grid cut', mark), 'no grid cut for the boss (the Showdown is a 2-car grid already)')
W.race(1); M.tick(5)
W.finish(1, 300, 50); M.tick(25)
wait3()
W.backToMenu(); M.tick(45)
T.check(T.logHas('KESTAR BOOL (final boss): WON - Kestar Bool beaten, unlocked as a racer (try 1)'), 'the win logged')
sv = T.save()
T.check(sv.boss and sv.boss.beaten == true and sv.boss.tries == 1 and not RC.locked('Antagonist'), 'saved: beaten; Kestar unlocked')
T.check(T.logHas('[menu] titleResult'), 'the result screen')
T.clickTitle('CONTINUE'); M.tick(3)
T.check(T.marks():find('|GOLD|$') ~= nil, 'v0.24: the boss tile shows a gold medal once he is beaten (v0.30: the Rally Cup after him) (' .. T.marks() .. ')')
T.finish()

---------------------------------------------------------------------------------------------------------------------
-- 5. v0.26: an old save (the cc classes: the 150cc title won the old way, vs Kestar in the Showdown, and the v0.20
-- rivals) gets a clean start - the title, the boss and the rivals gone, Kestar locked again (Shade raced instead)
T.reset()
T.boot({ version = 2, races = 40, cups = 8, racer = 'Antagonist', titles = { ['150'] = { won = true, tries = 3, vs = 'Kestar Bool', at = '2026-11-10' } },
  boss = { beaten = true, tries = 0, migrated = true },
  rivals = { ['100'] = { name = 'Sen Fira', scores = { ['Sen Fira'] = 30 } } }, restores = {}, abilityRestores = {} })
sv = T.save()
T.check(sv.version == 3 and sv.boss == nil and next(sv.titles) == nil and sv.rivals == nil, 'clean start: no title, no boss, no rivals')
T.check(sv.racer == 'DarkEnigma' and require('racer').locked('Antagonist'), 'Kestar locked again: the pick back to Shade')
T.check(T.logHas('[save] v0.26: three leagues - a clean start (backup save.backup-v2-') and T.logHas('Racer Kestar Bool is locked again: racing as Shade.'), 'logged once, with the fall back')
T.finish()
T.reset()
T.boot(sv)
T.check(not T.logHas('a clean start'), 'the next boot: nothing to clean again')
T.finish()
