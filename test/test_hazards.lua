-- v0.32: the Precision buoys hidden in a race on The Galactic Gauntlet (hazards.lua): the first sweep, a late buoy told
-- by the game, one shown again by the game re-hidden on the recheck sweep, the summary; a Jakku race never sweeps.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } })
local R = require('race')
local cfg = require('config')

local function buoy(name)
  local p = { bHidden = false, coll = true, tick = true }
  local b = M.new(name, p, 'PrecisionRunBuoy')
  p.SetActorHiddenInGame = function(_, v) p.bHidden = v end
  p.SetActorEnableCollision = function(_, v) p.coll = v end
  p.GetActorEnableCollision = function() return p.coll end
  p.SetActorTickEnabled = function(_, v) p.tick = v end
  M.add('PrecisionRunBuoy', b)
  return p, b
end
local function wait3() local t0 = os.time(); while os.time() - t0 < 3 do end end

-- a Jakku race: not a buoy track - no sweep, no line
local ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'JAKKU', kind = 'Circuit' }, 'challenger', 'car')
T.check(ok == true, 'a Jakku race launched')
local stray = buoy('Buoy_stray')
W.race(11); M.tick(30)
T.check(M.sweepCount('FindAllOf PrecisionRunBuoy') == 0 and not T.logHas('[hazards]') and stray.bHidden == false,
  'a Jakku race: no buoy sweep, no [hazards] line, a stray buoy left alone')
W.finish(1); M.tick(25); wait3(); W.backToMenu(); M.tick(45)
M.clear('PrecisionRunBuoy')

-- The Galactic Gauntlet (the Galactic Cup's final): the buoys go
local GAUNTLET = '/Game/Griffin/Gameplay/Events/Planets/Whippet/KNOCKOUT/EVT_WHP_LOOP_A_FWD_RACE'
local mark = T.mark()
ok = R.launch({ path = GAUNTLET, title = 'THE GALACTIC GAUNTLET', kind = 'Circuit' }, 'challenger', 'car')
T.check(ok == true and T.logHas('[hazards] THE GALACTIC GAUNTLET: the Precision buoys will be hidden (scans every 3 s for 45 s, then every 10 s)', mark),
  'the Gauntlet: the hazards watch armed at launch')
local b1 = buoy('Buoy_1')
local b2 = buoy('Buoy_2')
W.race(11); M.tick(2)
T.check(b1.bHidden == true and b1.coll == false and b1.tick == false and b2.bHidden == true and b2.coll == false,
  'both buoys hidden, collision and tick off, on the first sweep of the race world')
T.check(T.logHas('[hazards] precision buoys: 2 hidden (2 this race)', mark), 'the first sweep logged')
-- a buoy made later: the game tells us; looked up once, half a second later
local b3, o3 = buoy('Buoy_3')
M.fireNew('/Script/Griffin.PrecisionRunBuoy', o3)
M.tick(3)
T.check(b3.bHidden == false, 'a new buoy is left alone for half a second (it is starting up)')
M.tick(4)
T.check(b3.bHidden == true and b3.coll == false, 'then hidden, from its path + address')
T.check(T.logHas('[hazards] precision buoys: 1 hidden as they were made (3 this race)', mark), 'the late one logged and counted')
-- the loading window: a sweep every 3 s for 45 s, then every 10 s
M.tick(450)
local sweeps = M.sweepCount('FindAllOf PrecisionRunBuoy')
T.check(sweeps >= 14 and sweeps <= 18, 'about 15 sweeps in the first 45 s (' .. sweeps .. ')')
-- the game shows one again (a rewind): re-hidden on the next recheck sweep
b1.bHidden = false
M.tick(101)
T.check(b1.bHidden == true and T.logHas('[hazards] precision buoys: 1 shown again by the game, hidden again', mark), 'a buoy shown again is hidden again')
local later = M.sweepCount('FindAllOf PrecisionRunBuoy') - sweeps
T.check(later >= 1 and later <= 2, 'after the window: one sweep every 10 s (' .. later .. ' in 10 s)')
W.finish(1); M.tick(25); wait3(); W.backToMenu(); M.tick(45)
T.check(T.logHas('[hazards] precision buoys: 3 hidden, 1 re-hidden,', mark), 'the summary line with the RESULT')
T.check(require('hazards').live == nil, 'the watch let go with the race')
-- Hazards.Buoys = false: nothing, even on the Gauntlet
cfg.Hazards.Buoys = false
mark = T.mark()
ok = R.launch({ path = GAUNTLET, title = 'THE GALACTIC GAUNTLET', kind = 'Circuit' }, 'challenger', 'car')
W.race(11); M.tick(5)
T.check(ok == true and not T.logHas('[hazards]', mark), 'Hazards.Buoys = false: the watch stays off')
W.finish(1); M.tick(25); wait3(); W.backToMenu(); M.tick(45)
T.finish()
