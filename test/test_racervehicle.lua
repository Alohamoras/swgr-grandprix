-- v0.15 (TASKS.md A6): the racer decides the vehicle. The racer -> build table for all 14 (config Racers[].vehicle,
-- matching the game's PreferredVehicleType read 2026-11-11); Kestar Bool locked until beaten after the Ace title (a
-- save with him picked races as Shade, logged; cycling skips him; he's back once beaten); the garage's RACER tile
-- names the vehicle type and the lock; a mismatch with the game's byte is logged once; the league's parts go on the
-- racer's build and are put back.
local M = require('mock')
local W = require('world')
local T = require('util')
local EV = '/Game/Griffin/Gameplay/Events/Planets/'

-- a save with Kestar picked, the boss not beaten
T.boot({ version = 3, races = 9, cups = 1, class = 'challenger', racer = 'Antagonist', restores = {}, abilityRestores = {} },
  { Progression = { On = false } })
local RC, K, R, cfg = require('racer'), require('gp'), require('race'), require('config')
local H = rawget(_G, 'GU_TEST_SCREENS')
local SC = H.SCREENS

-- 1. the table: all 14 racers, each to the build of their type
local WANT = { DarkEnigma = 'car', Protege = 'car', QuietStrength = 'car', InnerHonour = 'car', Antagonist = 'car',
  Mercenary = 'bike', ElegantProfessional = 'bike', Thrall = 'bike', Rager = 'bike',
  Veteran = 'skimmer', Ghost = 'skimmer', Nomad = 'skimmer', Star = 'skimmer', Mentor = 'skimmer' }
local BUILD = { car = 'VBD_Car_Base', bike = 'VBD_Bike_Base', skimmer = 'VBD_Skimmer_Base' }
local ARCH = { car = 0, bike = 2, skimmer = 3 }
local bad, n = {}, 0
for _, r in ipairs(cfg.Racers) do
  n = n + 1
  local v = RC.vehicle(r.key)
  if r.vehicle ~= WANT[r.key] or v.key ~= WANT[r.key] or not v.build:find(BUILD[WANT[r.key]] .. '$')
    or v.arch ~= ARCH[WANT[r.key]] or v.arch ~= W.PREFERRED[r.key] and not (v.arch == 0 and W.PREFERRED[r.key] == nil) then
    bad[#bad + 1] = r.key
  end
end
T.check(n == 14 and #bad == 0, 'all 14 racers: the build of their own type, matching PreferredVehicleType (' .. table.concat(bad, ', ') .. ')')
T.check(RC.vehicleText('Rager') == 'Speeder bike' and RC.vehicleText('DarkEnigma') == 'Landspeeder' and RC.vehicleText('Mentor') == 'Skim speeder',
  'the vehicle type in words')
T.check(RC.vehicle('DarkEnigma').key == 'car', 'Shade: the base landspeeder')

-- 2. Kestar locked -> Shade
T.check(RC.locked('Antagonist') and not RC.locked('Mentor') and not RC.locked('DarkEnigma'), 'Kestar locked (not beaten), the others not')
T.check(RC.current().key == 'DarkEnigma' and T.save().racer == 'DarkEnigma', 'Kestar picked but locked: Shade, saved')
T.check(T.logHas('[racer] Kestar Bool is locked (to unlock: beat kestar bool in the ace galactic cup finale) - racing as Shade'), 'the fall back logged')

-- 3. cycling skips him while locked
local seen, kestar = {}, false
for _ = 1, 30 do
  local r = RC.cycle(1)
  seen[r.key] = true
  if r.key == 'Antagonist' then kestar = true end
end
local count = 0
for _ in pairs(seen) do count = count + 1 end
T.check(not kestar and count == 13, 'cycling forward: 13 racers, never Kestar (' .. count .. ')')
for _ = 1, 30 do if RC.cycle(-1).key == 'Antagonist' then kestar = true end end
T.check(not kestar, 'nor backward')
-- the garage: a VEHICLE tile beside the pilot; the RACER tile names the pilot and how to unlock Kestar
while RC.current().key ~= 'Rager' do RC.cycle(1) end
local items = SC.garage().items
local racer, veh
for _, it in ipairs(items) do
  if it.kind == 'racer' then racer = it end
  if it.kind == 'vehicle' then veh = it end
end
T.check(racer and racer.title == 'BIDDY BLAS', 'the RACER tile: Biddy Blas')
T.check(veh and veh.title == 'SPEEDER BIKE', 'the VEHICLE tile: his speeder bike (' .. tostring(veh and veh.title) .. ')')
T.check(racer and racer.info:find('^Biddy Blas:  Hot%-headed') ~= nil, 'its info: "Biddy Blas: <bio>" (' .. tostring(racer and racer.info) .. ')')
T.check(racer and racer.info:find('Kestar Bool is locked. To unlock: beat Kestar Bool in the ACE Galactic Cup finale.', 1, true) ~= nil, 'and how to unlock Kestar')
-- HOME's GARAGE tile: the racer and the vehicle type
local garage
for _, it in ipairs(SC.home().items) do if it.title == 'GARAGE' then garage = it end end
T.check(garage and garage.desc == 'Biddy Blas\nSpeeder bike', 'HOME\'s GARAGE tile: racer and vehicle type (' .. tostring(garage and garage.desc):gsub('\n', ' / ') .. ')')
T.check(garage and not garage.info:find('%a'), 'v0.22: no info line on GARAGE (the tile names the racer)')

-- 4. v0.21: the Ace title alone doesn't unlock him; beating him (the final boss) does: Kestar in the cycle, the lock
-- line gone
K.data.titles['ace'] = { won = true, tries = 2, vs = 'Sen Fira' }
T.check(RC.locked('Antagonist'), 'v0.21: the Ace title alone: Kestar still locked')
K.data.boss = { beaten = true, tries = 1 }
for _ = 1, 14 do if RC.cycle(1).key == 'Antagonist' then kestar = true; break end end
T.check(kestar and RC.current().key == 'Antagonist' and RC.vehicle().key == 'car', 'boss beaten: Kestar in the cycle, a landspeeder')
for _, it in ipairs(SC.garage().items) do
  if it.kind == 'racer' then T.check(not it.info:find('locked', 1, true), 'no lock line any more (' .. it.info .. ')') end
  if it.kind == 'vehicle' then T.check(it.title == 'LANDSPEEDER', 'Kestar\'s vehicle tile is the landspeeder (' .. tostring(it.title) .. ')') end
end

-- 5. as Sebulba at Challenger: the skimmer build at parts 5, the others untouched, put back at the menu; the game's byte
-- read once from his def (matches: nothing logged)
while RC.current().key ~= 'Mentor' do RC.cycle(1) end
M.press('F6'); M.tick(6)
T.clickTitle('CHALLENGER'); M.tick(3)
T.clickTitle('JAKKU CUP')
local args = M.lastCall('LaunchQuickRace').args
T.check(rawget(args[1], '__name') == 'VA_Skimmer' and rawget(args[3], '__name'):find('VBD_Skimmer_Base', 1, true) ~= nil,
  'Sebulba races the skim speeder build')
T.check(T.levels('VBD_Skimmer_Base') == '0=7 1=7 2=7 3=7 4=7 5=7', 'Challenger parts on the skimmer build')
T.check(T.levels('VBD_Car_Base') == '0=0 1=0 2=0 3=0 4=0 5=0' and T.levels('VBD_Bike_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'the car and bike builds untouched')
T.check(T.logHas('vehicle=skimmer') and not T.logHas('PreferredVehicleType'), 'launch logged with the skimmer; the game\'s byte agrees (no mismatch line)')
W.race(11); M.tick(10)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.levels('VBD_Skimmer_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'the skimmer build put back at the menu')
M.press('BACKSPACE'); M.tick(5)
T.clickTitle('YES'); M.tick(3)
T.check(T.save().run == nil, 'cup left')

-- 6. a mismatch between config and the game's byte is logged once per racer (and config wins)
rawget(W.racerDef('Nomad'), '__props').PreferredVehicleType = 2
while RC.current().key ~= 'Nomad' do RC.cycle(1) end
local ev = { path = EV .. 'Mastiff/EVT_MAS_LOOP_A_FWD', title = 'The War Fields', kind = 'circuit' }
local ok = R.launch(ev, 'ace', RC.vehicle().key, nil, nil)
T.check(ok and T.logHas('[racer] Fola Kanjen: the game\'s PreferredVehicleType is 2, config says skimmer (arch 3) - racing the config\'s skimmer'),
  'mismatch logged; config wins (' .. tostring(ok) .. ')')
T.check(T.levels('VBD_Skimmer_Base') == '0=10 1=10 2=10 3=10 4=10 5=10', 'the skimmer build at Ace')
W.race(11); M.tick(10)
W.backToMenu(); M.tick(45)
T.check(T.levels('VBD_Skimmer_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'put back')
local mark = T.mark()
ok = R.launch(ev, 'ace', RC.vehicle().key, nil, nil)
T.check(ok and not T.logHas('PreferredVehicleType', mark), 'checked once per racer per session')
W.race(11); M.tick(10)
W.backToMenu(); M.tick(45)

-- 7. losing the boss win again (a hand-edited save) makes the pick fall back too
while RC.current().key ~= 'Antagonist' do RC.cycle(1) end
K.data.boss = nil
T.check(RC.current().key == 'DarkEnigma' and K.data.racer == 'DarkEnigma', 'Kestar locked again: Shade')
T.check(M.deadTouches == 0, 'no freed object touched')
T.finish()
