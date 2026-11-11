-- v0.15: the racer decides the vehicle. An old save with the bike picked and Shade as the racer: the pick is dropped
-- (logged once) and Shade races the landspeeder; the garage has no VEHICLE tile; a bike racer picked on the RACER
-- tile races the bike. 200cc sets every part on the racer's build and puts it back. Quitting a race from the game's
-- pause menu is a DNF and the cup goes on; leaving the cup (B on the standings, YES) forfeits it (v0.9: cups cannot be
-- resumed); a cup left on the page when HOME is shown is dropped.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 2, races = 0, cups = 0, vehicle = 'bike', racer = 'DarkEnigma', restores = {}, abilityRestores = {} },
  { Progression = { On = false } }) -- (unlocks: test_prog, test_unlocks)
T.check(T.logHas('[save] the old vehicle pick (bike) is dropped: the racer decides the vehicle now (v0.15); racer kept: DarkEnigma'),
  'old save: the vehicle pick dropped, logged')
T.check(T.save().vehicle == nil and T.save().racer == 'DarkEnigma', 'the save: no vehicle, the racer kept')
M.press('F6'); M.tick(6)
T.check(T.titles():find('|GARAGE|', 1, true) ~= nil, 'HOME (' .. T.titles() .. ')')
-- Shade with the old bike pick: the landspeeder
T.clickTitle('200CC'); M.tick(3)
T.clickTitle('JAKKU CUP')
local args = M.lastCall('LaunchQuickRace').args
T.check(rawget(args[1], '__name') == 'VA_Car', 'Shade (old save, bike picked) races the landspeeder')
T.check(rawget(args[3], '__name'):find('VBD_Car_Base', 1, true) ~= nil, 'with the car build')
T.check(T.levels('VBD_Car_Base') == '0=9 1=9 2=9 3=9 4=9 5=9' and T.levels('VBD_Bike_Base') == '0=0 1=0 2=0 3=0 4=0 5=0',
  '200cc parts on the car build, the bike build untouched')
W.race(11); M.tick(10)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.levels('VBD_Car_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'the car build put back at the menu')
M.press('BACKSPACE'); M.tick(5)
T.clickTitle('YES'); M.tick(3)
T.check(T.save().run == nil and T.logHas('[menu] home'), 'the Jakku cup left')
T.clickTitle('GARAGE'); M.tick(3)
T.check(T.logHas('[menu] garage'), 'GARAGE opens the garage')
T.check(T.titles():find('^SHADE|') ~= nil and not T.titles():find('LANDSPEEDER', 1, true), 'no VEHICLE tile: the racer first (' .. T.titles() .. ')')
T.check(T.badges():find('^RACER|') ~= nil and not T.badges():find('VEHICLE', 1, true), 'no VEHICLE badge (' .. T.badges() .. ')')
T.clickTitle('SHADE'); M.tick(3)
T.clickTitle('ARY QUILL'); M.tick(3)
T.check(T.save().racer == 'Mercenary' and T.titles():find('^MALIS VAZOSK|') ~= nil, 'Select twice on the racer: Malis Vazosk (a bike racer)')
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('200CC'); M.tick(3)
T.clickTitle('CRAIT CUP')
local args = M.lastCall('LaunchQuickRace').args
T.check(rawget(args[1], '__name') == 'VA_Bike', 'the cup races with the bike')
T.check(T.levels('VBD_Bike_Base') == '0=9 1=9 2=9 3=9 4=9 5=9', '200cc: every part at 9 (v0.10: the extra, not maxed)')
T.check(T.levels('VBD_Car_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'the landspeeder build untouched')
-- you quit the race from the pause menu: back at the menu without finishing = DNF, 0 points
W.race(11); M.tick(10)
t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.check(T.levels('VBD_Bike_Base') == '0=0 1=0 2=0 3=0 4=0 5=0', 'the bike build put back at the menu')
T.check(T.logHas('RESULT CRIMSON MINES (MINES, NIGHT): DNF'), 'quitting the race = DNF (200cc races the 150cc list)')
T.check(T.save().run.points.YOU == 0 and T.save().run.race == 2, 'DNF: no points, on to race 2')
T.check(T.logHas('[menu] standings'), 'standings shown')
T.check(T.titles() == 'NEXT RACE', 'the standings offer NEXT RACE only (' .. T.titles() .. ')')
M.press('BACKSPACE'); M.tick(5)
T.check(T.titles() == 'YES|NO', 'B: "Leave the cup?", YES first (' .. T.titles() .. ')')
-- B on the question goes back to the standings too
M.press('BACKSPACE'); M.tick(5)
T.check(T.titles() == 'NEXT RACE' and T.save().run ~= nil, 'B on the question: the standings again, the cup kept')
M.press('BACKSPACE'); M.tick(5)
T.clickTitle('YES'); M.tick(3)
T.check(T.save().run == nil, 'YES forfeits it')
T.check(T.logHas('cup forfeited: 200 crait after 1 of 4 races'), 'forfeit logged')
T.check(T.save().best['200'] == nil, 'no trophy saved')
T.check(T.logHas('[menu] home') and T.titles() == '50CC|100CC|150CC|200CC|GARAGE|RESET PROGRESS', 'YES goes HOME: the classes, GARAGE, RESET (' .. T.titles() .. ')')

-- a cup alive when HOME is shown (here: the launch of race 2 timed out, which lands on the cups page) is dropped
T.clickTitle('200CC'); M.tick(3)
T.clickTitle('ANDO CUP')
T.check(T.save().run and T.save().run.cup == 'ando', 'a second cup starts (Ando)')
W.race(11); M.tick(10)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
T.clickTitle('NEXT RACE')
local R = require('race')
T.check(R.run ~= nil and R.run.phase == 'loading', 'race 2 launched, loading')
local mark = T.mark()
M.tick(1210) -- 121 s: no race world
T.check(T.logHas('no race world after 120 s - giving up', mark) and T.logHas('[menu] cups', mark), 'the launch timed out: back on the cups page')
T.check(T.save().run ~= nil, 'the cup is still in the save there')
M.press('BACKSPACE'); M.tick(3)
T.check(T.logHas('[cup] ando 200cc dropped at the home screen (race 2 of 4): cups cannot be resumed', mark) and T.save().run == nil,
  'B to HOME: the cup is dropped and logged')
T.finish()
