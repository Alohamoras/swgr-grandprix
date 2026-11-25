-- AI driving spike, step 2 (TASKS.md section 1; test-only switch): a file experiment.lua in the mod folder changes the
-- next race's AI - the driving styles (written like the AI config: originals in the save, put back at the menu), more
-- DA_AIConfig fields, the bots' part stacks at load - and logs every racer's time in the result. No file: nothing.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 3 }, { StartScreen = true, Progression = { On = false }, DevTools = true })
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
-- v0.28 pilot strength (config AI.Strength, no experiment): fixed, by tier, at Challenger Elite +2 / contender +1 / weak -1
T.check(T.logHas('[ai] pilot strength (challenger): ') and T.logHas('Biddy Blas +2 (') and T.logHas('Sen Fira +2 (') and T.logHas('Kestar Bool +2 (')
  and not T.logHas('Katja Mox +') and not T.logHas('Katja Mox -'), 'v0.28: pilot strength at load - the Elite +2, an unlisted pilot left as you')
T.check(T.logHas('Biddy Blas +2 (20 upgrades, now 7)'), 'v0.28: Biddy\'s stacking parts 5 -> 7 (the Battery upgrade left alone)')
local LO = require('loadout')
T.check(LO.strengthFor('Biddy Blas', 'riffraff') == 1 and LO.strengthFor('Goli & 02-R0', 'riffraff') == 0 and LO.strengthFor('Malis Vazosk', 'ace') == -3 and LO.strengthFor('Biddy Blas', 'ace') == 0 and LO.strengthFor('Goli & 02-R0', 'ace') == -1
  and LO.strengthFor('Shade', 'ace') == 0 and LO.strengthFor('Biddy Blas', 'nosuch') == 0, 'v0.28 / v0.34.0: the strength table per league (Riff-Raff: the Elite +1 only; Ace shifted down: Elite 0, contender -1, weak -3)')
W.backToMenu(); M.tick(45)
M.press('BACKSPACE'); M.tick(3); T.clickTitle('YES'); M.tick(3) -- (leave the cup)

-- the file: styles, a config field, bot stacks
local f = io.open(EXP, 'w')
f:write([[return { label = 'boost-a', styles = { Car = { MinEnergyForAfterburner = 0.2, MinBoostTime = 1.5 }, Bike = { MaxDegreesOffHeadingForBoost = 45 } },
  event = "THE GIANTS' GRAVEYARD", config = { ForcedErrorDuration = 4 }, botStacks = 2, botStacksBy = { ['Katja Mox'] = -1 } }]])
f:close()
local mark = T.mark()
-- v0.29.3 (release pass): with DevTools off the file does nothing (players never get the test switches)
require('config').DevTools = false
T.check(require('ai').experiment() == nil, 'DevTools = false: experiment.lua ignored')
require('config').DevTools = true
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
T.check(T.logHas('[exp] bot parts: ', mark) and not T.logHas('[ai] pilot strength', mark) and T.logHas('Katja Mox -1 (', mark) and T.logHas('Biddy Blas +2 (', mark),
  'the bots\' part stacks moved at load (Katja -1, the rest +2; the test switch replaces pilot strength)')
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
-- quitAfterS (the launch checks): N s after the launch, once the field is read, the race goes back to the main menu
f = io.open(EXP, 'w')
f:write([[return { label = 'launch', event = "SCRAP SPIRAL", quitAfterS = 20 }]])
f:close()
mark = T.mark()
local tl = T.titles()
local launchTile = tl:find('NEXT RACE', 1, true) and 'NEXT RACE' or nil
if not launchTile then
  if tl:find('CONTINUE', 1, true) then T.clickTitle('CONTINUE'); M.tick(3) end
  if T.titles():find('JAKKU CUP', 1, true) then T.clickTitle('JAKKU CUP'); M.tick(5) end
  launchTile = 'START'
end
T.clickTitle(launchTile); M.tick(5)
T.check(T.logHas('[exp] event: SCRAP SPIRAL instead of', mark), 'quitAfterS: the event launched (' .. tl .. ')')
W.race(11); M.tick(100)
T.check(not T.logHas('[exp] quitAfterS', mark), 'quitAfterS: not before its time')
M.tick(150)
T.check(T.logHas('[exp] quitAfterS 20: back to the main menu', mark) and (T.logHas('RequestReturnToMenus() called', mark) or T.logHas("CONTINUE pressed", mark)),
  'quitAfterS: 20 s after the launch, the race sent back to the main menu')
T.check(T.logCount('[exp] quitAfterS') == 1, 'quitAfterS: once')
-- race types research: eventPath (any event by path) + modeFrom (borrow another event's race mode; put back at the menu)
local ELIM = '/Game/Griffin/Gameplay/Events/Planets/Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD_ELIMINATOR'
local elimMode = M.new('TimeEliminatorConfig_0', {}, 'TimeEliminatorConfig')
M.assets[ELIM .. '.EVT_MAS_LOOP_A_FWD_ELIMINATOR'] = M.new('EVT_MAS_LOOP_A_FWD_ELIMINATOR', { EventMode = elimMode }, 'RaceEventDef')
for _, pool in pairs(require('config').Pools) do
  for _, r in ipairs(pool) do
    if r.title == 'SCRAP SPIRAL' then
      local nm = r.path:match('([^/]+)$')
      local evo = W.raceEvent(r.path, 6)
      M.assets[r.path .. '.' .. nm] = evo
      M.add('TeamRaceConfig', rawget(evo, '__props').EventMode) -- (findable again by path + address, C.deref)
    end
  end
end
W.backToMenu(); M.tick(45)
f = io.open(EXP, 'w')
f:write(('return { label = "mode", event = "SCRAP SPIRAL", modeFrom = %q }'):format(ELIM))
f:close()
mark = T.mark()
tl = T.titles()
if tl:find('NEXT RACE', 1, true) then T.clickTitle('NEXT RACE')
else
  if tl:find('CONTINUE', 1, true) then T.clickTitle('CONTINUE'); M.tick(3) end
  if T.titles():find('JAKKU CUP', 1, true) then T.clickTitle('JAKKU CUP'); M.tick(5) end
  T.clickTitle('START')
end
M.tick(5)
T.check(T.logHas('[exp] modeFrom: SCRAP SPIRAL races with TimeEliminatorConfig_0 (EVT_MAS_LOOP_A_FWD_ELIMINATOR, was TeamRaceConfig_0)', mark),
  'modeFrom: the event launched with the eliminator\'s race mode (' .. tl .. ')')
W.race(11); M.tick(30)
W.backToMenu(); M.tick(45)
T.check(T.logHas('[exp] modeFrom put back (main menu): ', mark) and T.logHas('-> TeamRaceConfig_0', mark), 'modeFrom: the event\'s own mode back at the menu')
os.remove(EXP)
T.finish()
