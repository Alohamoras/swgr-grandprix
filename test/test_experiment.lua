-- AI driving spike, step 2 (TASKS.md section 1; test-only switch): a file experiment.lua in the mod folder changes the
-- next race's AI - the driving styles (written like the AI config: originals in the save, put back at the menu), more
-- DA_AIConfig fields, the bots' part stacks at load - and logs every racer's time in the result. No file: nothing.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 3 }, { StartScreen = true, Progression = { On = false } })
local EXP = T.dir .. '/experiment.lua'
os.remove(EXP)
local function startCup()
  M.press('F6'); M.tick(6)
  T.clickTitle('CHALLENGER'); M.tick(3)
  T.clickTitle('JAKKU CUP'); M.tick(5)
  T.clickTitle('START'); M.tick(5)
end

-- no file: nothing changes
startCup()
T.check(M.called('LaunchQuickRace') == 1 and W.ds.Car.MinEnergyForAfterburner == 0.4 and not T.logHas('[exp]'), 'no experiment.lua: no [exp], the styles untouched')
W.race(11); M.tick(5)
T.check(not T.logHas('[exp]'), 'no experiment.lua: nothing at load')
W.backToMenu(); M.tick(45)
M.press('BACKSPACE'); M.tick(3); T.clickTitle('YES'); M.tick(3) -- (leave the cup)

-- the file: styles, a config field, bot stacks
local f = io.open(EXP, 'w')
f:write([[return { label = 'boost-a', styles = { Car = { MinEnergyForAfterburner = 0.2, MinBoostTime = 1.5 }, Bike = { MaxDegreesOffHeadingForBoost = 45 } },
  event = "THE GIANTS' GRAVEYARD", config = { ForcedErrorDuration = 4 }, botStacks = 2, botStacksBy = { ['Katja Mox'] = -1 } }]])
f:close()
local mark = T.mark()
T.clickTitle('CHALLENGER'); M.tick(3) -- (YES left the cup to HOME)
T.clickTitle('JAKKU CUP'); M.tick(5)
T.clickTitle('START'); M.tick(5)
T.check(T.logHas('[exp] experiment "boost-a" for this race', mark), 'the experiment named at launch')
T.check(W.ds.Car.MinEnergyForAfterburner == 0.2 and W.ds.Car.MinBoostTime == 1.5 and W.ds.Bike.MaxDegreesOffHeadingForBoost == 45
  and W.ds.Skimmer.MinEnergyForAfterburner == 0.4, 'the car and bike styles written, the skimmer\'s untouched')
T.check(T.logHas('[exp] driving style DS_Car_Base: MinBoostTime 3 -> 1.5, MinEnergyForAfterburner 0.4 -> 0.2', mark), 'the style writes logged')
T.check(T.save().aiRestores['/Game/Griffin/AI/DS_Car_Base'].MinEnergyForAfterburner == 0.4, 'the style\'s originals in the save first (a crash is put right)')
T.check(W.ai.ForcedErrorDuration == 4, 'an extra DA_AIConfig field from the experiment')
T.check(T.logHas("[exp] event: THE GIANTS' GRAVEYARD instead of", mark) and T.launched() == 'EVT_MAS_P2P_FWD', 'the experiment\'s fixed event launched (' .. tostring(T.launched()) .. ')')
W.race(11); M.tick(5)
T.check(T.logHas('[exp] bot parts: ', mark) and T.logHas('Katja Mox -1 (', mark) and T.logHas('Biddy Blas +2 (', mark),
  'the bots\' part stacks moved at load (Katja -1, the rest +2)')
local biddy
for _, ps in ipairs(W.players or {}) do
  if tostring(rawget(rawget(ps, '__props'), 'PlayerNamePrivate')):find('Biddy', 1, true) then biddy = ps end
end
T.check(T.logHas('now 7)', mark) and T.logHas('now 4)', mark), 'Biddy\'s stacking upgrades 5 -> 7, Katja\'s 5 -> 4 (the non-stacking one left alone)')
W.finish(1); M.tick(25); W.results(); M.tick(10) -- (the result is recorded on the results screen: chain.lua)
W.backToMenu(); M.tick(45)
-- (the swapped event isn't the cup's race, so the chain leaves it alone: the result is recorded at the main menu)
T.check(T.logHas('[exp] result "boost-a" ', mark), 'every racer\'s time in the result while the experiment runs')
T.check(W.ds.Car.MinEnergyForAfterburner == 0.4 and W.ds.Car.MinBoostTime == 3 and W.ds.Bike.MaxDegreesOffHeadingForBoost == 30
  and W.ai.ForcedErrorDuration == 8, 'at the menu: the styles and the config field put back')
T.check(T.logHas('[ai] AI config put back (main menu): DS_Car_Base MinBoostTime=3 MinEnergyForAfterburner=0.4', mark), 'the style put-back logged')
os.remove(EXP)
T.finish()
