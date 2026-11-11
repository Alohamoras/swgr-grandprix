-- v0.8 racer.lua: your pilot. A pending put-back after a 'crash', cycling and saving, the character list at launch
-- (Player set, the restore record in the save), the settle once the race is under way, an opponent pilot swapped out
-- of the grid for Shade, a quit before the settle, a failed launch.
local M = require('mock')
local W = require('world')
local T = require('util')
local EV = '/Game/Griffin/Gameplay/Events/Planets/'
local RACERS = '/Game/Griffin/Narrative/CharacterDefs/Racers/DA_Racer_'

-- 1. boot after a 'crash': the save says Kestar was in CharacterList.Player; the list (in memory) still shows it
T.boot({ racer = 'Antagonist', racerRestore = { key = 'Antagonist', player = RACERS .. 'DarkEnigma', list = '/Game/Griffin/Narrative/CharacterDefs/DA_CharacterList' } },
  { Progression = { On = false }, Manual = true })
rawget(W.chars, '__props').Player = W.racerDef('Antagonist')
T.check(W.charsText():find('^Player=Antagonist') ~= nil, 'before the first tick: the list still holds Kestar')
W.tabMenu(); M.tick(18)
T.check(W.charsText() == 'Player=DarkEnigma Opp=Mercenary,ElegantProfessional,Star,InnerHonour,Thrall,Ghost,Rager,Nomad,Veteran,QuietStrength,Protege',
  'pending restore at the menu: Shade back in Player, opponents untouched (' .. W.charsText() .. ')')
T.check(T.save().racerRestore == nil, 'the restore record is cleared from the save')
T.check(T.logHas('[racer] Shade put back (left over from an earlier race)'), 'put-back logged')

local RC = require('racer')
local R = require('race')
local K = require('gp')

-- 2. the list, the pick, cycling
local list = RC.list()
T.check(#list == 14 and list[1].key == 'DarkEnigma' and list[14].key == 'Antagonist', '14 pilots, Shade first, Kestar last')
local okCfg, seen = true, {}
for _, r in ipairs(list) do
  if seen[r.key] or not W.RACER_NAMES[r.key] or W.RACER_NAMES[r.key] ~= r.name or type(r.line) ~= 'string' or #r.line > 70 or #r.line == 0 then okCfg = false end
  seen[r.key] = true
  if r.key == 'TestPilot' or r.key == 'MentorBossRace' then okCfg = false end
end
T.check(okCfg, 'every pilot: a game key, the game\'s name, a line of 1-70 chars; no Autopilot / boss Sebulba')
T.check(RC.current().key == 'Antagonist' and RC.displayName() == 'Kestar Bool', 'the pick comes from the save (Kestar Bool)')
T.check(RC.cycle(1).key == 'DarkEnigma', 'cycle forward from the last wraps to Shade')
T.check(T.save().racer == 'DarkEnigma', 'the pick is saved')
T.check(RC.cycle(-1).key == 'Antagonist' and RC.cycle(-1).key == 'Mentor', 'cycle back: Kestar, Sebulba')
T.check(RC.displayName('Ghost') == 'Goli & 02-R0' and RC.displayName('nope') == '?', 'displayName by key')
RC.cycle(1); RC.cycle(1) -- Kestar, Shade
T.check(RC.cycle(1).key == 'Protege', 'cycle forward from Shade: Ary Quill')

-- 3. launch as Kestar (not one of the opponents) through START CUP
for _ = 1, 12 do if RC.current().key ~= 'Antagonist' then RC.cycle(1) end end
T.check(RC.current().key == 'Antagonist', 'Kestar picked')
M.press('F6'); M.tick(6)
T.clickTitle('150CC'); M.tick(3)
T.clickTitle('JAKKU CUP')
T.check(M.called('LaunchQuickRace') == 1, 'START CUP launches race 1')
T.check(W.charsText() == 'Player=Antagonist Opp=Mercenary,ElegantProfessional,Star,InnerHonour,Thrall,Ghost,Rager,Nomad,Veteran,QuietStrength,Protege',
  'at launch: Player = Kestar, the 11 opponents as they were (' .. W.charsText() .. ')')
local sv = T.save()
T.check(sv.racerRestore and sv.racerRestore.key == 'Antagonist' and sv.racerRestore.player == RACERS .. 'DarkEnigma' and sv.racerRestore.opp == nil,
  'the save holds what to put back (Shade), no opponent swap')
T.check(T.logHas('[racer] racing as Kestar Bool (DA_Racer_Antagonist): CharacterList.Player set (was Shade)'), 'launch logged')
-- v0.9: no lock while a cup runs (the garage can't be reached mid-cup without leaving the cup); the race keeps the
-- pilot it launched with (the save's restore record)
local r = RC.cycle(1)
T.check(r ~= nil and RC.current().key ~= 'Antagonist' and T.save().racerRestore.key == 'Antagonist', 'the pick can change mid-cup; the race keeps Kestar')
RC.cycle(-1)
T.check(RC.current().key == 'Antagonist', 'and back to Kestar')

-- the race world: the list stays swapped until the settle time (past the grid and the countdown), then goes back
W.race(11); M.tick(5)
rawget(W.player, '__props').PlayerNamePrivate = FText('Kestar Bool')
M.tick(20)
T.check(T.logHas('field: 12 racers'), 'racing: the field is read')
T.check(W.charsText():find('^Player=Antagonist') ~= nil and T.save().racerRestore ~= nil, 'the list stays swapped for the first seconds of the race')
M.tick(110)
T.check(W.charsText():find('^Player=DarkEnigma') ~= nil, 'settled: Shade back in Player while the race runs')
T.check(T.save().racerRestore == nil, 'the restore record is cleared at the settle')
T.check(T.logHas('[racer] racing as Kestar Bool (DA_Racer_Antagonist); Shade put back'), 'settle logged')
local mark = T.mark()
-- you win; the bots (one of them also called Kestar Bool in the mock) finish behind you
for i, b in ipairs(W.bots) do
  local rec = rawget(rawget(b, '__props').RaceEventComponent, '__props')
  rec.EventPosition, rec.bHasFinishedEvent = i + 1, true
end
W.finish(1); M.tick(25)
W.backToMenu(); M.tick(45)
T.check(T.logHas('build put back (main menu)', mark) and not T.logHas('[racer]', mark), 'back at the menu: nothing more to put back for the pilot')
T.check(T.logHas('cup jakku race 1: 1 YOU, 2 Biddy Blas, 3 Kestar Bool'), 'the result: YOU (keyed by bIsABot, whatever the name), the bots by name')
T.check(M.deadTouches == 0, 'no freed object touched')
K.forfeit()

-- 4. an opponent pilot (Katja Mox, Opponents[2]): she leaves the grid, Shade takes her slot; the loadout keys the bots
-- by name and a bot called Shade gets Shade's four
for _ = 1, 14 do if RC.current().key ~= 'ElegantProfessional' then RC.cycle(1) end end
T.check(RC.current().key == 'ElegantProfessional', 'Katja Mox picked')
local ev = { path = EV .. 'Mastiff/EVT_MAS_LOOP_A_FWD', title = 'The War Fields', kind = 'circuit' }
local ok, err = R.launch(ev, '150', 'car', nil, nil)
T.check(ok == true, 'launch as Katja (' .. tostring(err) .. ')')
T.check(W.charsText() == 'Player=ElegantProfessional Opp=Mercenary,DarkEnigma,Star,InnerHonour,Thrall,Ghost,Rager,Nomad,Veteran,QuietStrength,Protege',
  'at launch: Player = Katja, Opponents[2] = Shade (' .. W.charsText() .. ')')
sv = T.save()
T.check(sv.racerRestore and sv.racerRestore.opp and sv.racerRestore.opp.i == 2 and sv.racerRestore.opp.path == RACERS .. 'ElegantProfessional',
  'the save holds the opponent swap (slot 2, Katja)')
T.check(T.logHas('CharacterList.Player set (was Shade); Katja Mox out of Opponents[2], Shade in'), 'swap logged')
W.race(11); M.tick(130)
T.check(W.charsText() == 'Player=DarkEnigma Opp=Mercenary,ElegantProfessional,Star,InnerHonour,Thrall,Ghost,Rager,Nomad,Veteran,QuietStrength,Protege',
  'settled: Shade back in Player, Katja back in Opponents[2] (' .. W.charsText() .. ')')
T.check(T.logHas('[racer] racing as Katja Mox (DA_Racer_ElegantProfessional); Shade put back (Opponents[2] = Katja Mox again)'), 'settle with the swap logged')
T.check(T.logHas('Shade=Disruptor_Concuss+Shield_Surging+VentV2+Repair_Auto'), 'a bot named Shade gets Shade\'s four from the loadout (keyed by name)')
W.finish(3); M.tick(5)
W.backToMenu(); M.tick(45)
T.check(R.run == nil, 'race over')

-- 5. quitting before the settle: the menu return puts the list back
for _ = 1, 14 do if RC.current().key ~= 'Antagonist' then RC.cycle(1) end end
ok = R.launch(ev, '150', 'car', nil, nil)
T.check(ok == true and W.charsText():find('^Player=Antagonist') ~= nil, 'launch as Kestar again')
W.race(11); M.tick(10)
T.check(W.charsText():find('^Player=Antagonist') ~= nil, 'still swapped 1 s into the race')
mark = T.mark()
W.backToMenu(); M.tick(45)
T.check(W.charsText():find('^Player=DarkEnigma') ~= nil and T.save().racerRestore == nil, 'quit early: Shade back at the menu, record cleared')
T.check(T.logHas('[racer] Shade put back (main menu)', mark), 'put-back at the menu logged')

-- 6. a failed launch puts it back at once
rawget(W.fe, '__props').LaunchQuickRace = function() error('no race for you') end
ok, err = R.launch(ev, '150', 'car', nil, nil)
T.check(ok == false and W.charsText():find('^Player=DarkEnigma') ~= nil and T.save().racerRestore == nil, 'launch failed: Shade back, record cleared')
T.check(T.logHas('[racer] Shade put back (launch failed)'), 'put-back after the failed launch logged')

-- 7. Shade picked: the game's own pilot, nothing touched
rawget(W.fe, '__props').LaunchQuickRace = function() end
for _ = 1, 14 do if RC.current().key ~= 'DarkEnigma' then RC.cycle(1) end end
mark = T.mark()
ok = R.launch(ev, '150', 'car', nil, nil)
T.check(ok == true and T.save().racerRestore == nil and T.logHas('[racer] racing as Shade (DA_Racer_DarkEnigma): the game\'s own pilot', mark), 'Shade: nothing to swap')
W.race(11); M.tick(130)
T.check(not T.logHas('put back', mark), 'nothing to settle as Shade')
W.backToMenu(); M.tick(45)
T.check(M.deadTouches == 0, 'no freed object touched')
T.finish()
