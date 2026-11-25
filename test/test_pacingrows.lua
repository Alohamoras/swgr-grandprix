-- v0.32.6: the back of the grid (ai.lua A.launchRows): the pacing assets' RiffRaff / Losers rows renamed to the league's
-- tier at launch (Challengers; Elite at Ace), the names in the save first, back at the menu and at boot after a crash.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } })
local R = require('race')
local cfg = require('config')
local function wait3() local t0 = os.time(); while os.time() - t0 < 3 do end end

-- the tier windows on both pacing assets: five tiers, each window a pair of curve-table row handles
local function handle(name) return { RowName = M.new(name, {}, 'FName'), CurveTable = M.new('CT_Pacing', {}) } end
local function windows(suffix)
  local list = {}
  for i, tier in ipairs({ 'Ace', 'Elite', 'Challengers', 'RiffRaff', 'Losers' }) do
    list[i] = { AIMaxTimeAhead = handle(tier .. '_Max' .. suffix), AIMinTimeAhead = handle(tier .. '_Min' .. suffix) }
  end
  return list
end
local rows = {}
for _, name in ipairs({ 'Default', 'Honest' }) do
  rows[name] = windows(name == 'Honest' and '_H' or '')
  W.rp[name].PacingConfigs = M.tarr(rows[name])
end
-- a row's name as text (a written one is the mock FName's plain string)
local function rowText(h) local r = h.RowName; return type(r) == 'string' and r or rawget(r, '__name') end
local RP = '/Game/Griffin/AI/Pacing/Default/RP_'

-- Challenger: the two trailing tiers become Challengers on both assets
local mark = T.mark()
local ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'JAKKU', kind = 'Circuit' }, 'challenger', 'car')
T.check(ok == true, 'launched at Challenger')
T.check(rowText(rows.Default[4].AIMaxTimeAhead) == 'Challengers_Max' and rowText(rows.Default[4].AIMinTimeAhead) == 'Challengers_Min'
  and rowText(rows.Default[5].AIMaxTimeAhead) == 'Challengers_Max' and rowText(rows.Default[5].AIMinTimeAhead) == 'Challengers_Min',
  'RP_Default: the RiffRaff and Losers windows now read the Challengers rows')
T.check(rowText(rows.Honest[5].AIMinTimeAhead) == 'Challengers_Min_H' and rowText(rows.Default[1].AIMaxTimeAhead) == 'Ace_Max'
  and rowText(rows.Default[3].AIMinTimeAhead) == 'Challengers_Min', 'RP_Honest too; the Ace / Challengers windows untouched')
T.check(T.logHas('[ai] league challenger: pacing rows on RP_Default: Ace_Max Ace_Min Elite_Max Elite_Min Challengers_Max Challengers_Min RiffRaff_Max RiffRaff_Min Losers_Max Losers_Min; back of the grid -> RiffRaff_Max -> Challengers_Max, RiffRaff_Min -> Challengers_Min, Losers_Max -> Challengers_Max, Losers_Min -> Challengers_Min', mark),
  'the rows seen and the renames logged')
local sv = T.save()
local rr = sv.aiRowRestores and sv.aiRowRestores[RP .. 'Default']
T.check(rr and rr['PacingConfigs.4.AIMaxTimeAhead'] == 'RiffRaff_Max' and rr['PacingConfigs.5.AIMinTimeAhead'] == 'Losers_Min'
  and sv.aiRowRestores[RP .. 'Honest']['PacingConfigs.5.AIMaxTimeAhead'] == 'Losers_Max_H', 'the original names in the save (both assets)')
-- the race, then the menu: the rows back
W.race(11); M.tick(5); W.finish(1); M.tick(25); wait3()
mark = T.mark()
W.backToMenu(); M.tick(45)
T.check(rowText(rows.Default[4].AIMaxTimeAhead) == 'RiffRaff_Max' and rowText(rows.Default[5].AIMinTimeAhead) == 'Losers_Min'
  and rowText(rows.Honest[4].AIMinTimeAhead) == 'RiffRaff_Min_H', 'the rows back at the menu')
T.check(T.logHas('[ai] pacing rows put back (main menu): RP_Default RiffRaff_Max RiffRaff_Min Losers_Max Losers_Min', mark), 'put back logged')
T.check(next(T.save().aiRowRestores or {}) == nil and next(T.save().aiRestores or {}) == nil, 'nothing left to put back')

-- Ace: Elite
mark = T.mark()
ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'JAKKU', kind = 'Circuit' }, 'ace', 'car')
T.check(ok == true and rowText(rows.Default[4].AIMaxTimeAhead) == 'Elite_Max' and rowText(rows.Default[5].AIMinTimeAhead) == 'Elite_Min', 'Ace: the back of the grid on the Elite rows')
W.race(11); M.tick(5); W.finish(1); M.tick(25); wait3(); W.backToMenu(); M.tick(45)
T.check(rowText(rows.Default[4].AIMaxTimeAhead) == 'RiffRaff_Max', 'back after the Ace race')
-- a failed launch puts them straight back
rawget(W.fe, '__props').LaunchQuickRace = function() error('boom') end
mark = T.mark()
ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'JAKKU', kind = 'Circuit' }, 'ace', 'car')
T.check(ok == false and rowText(rows.Default[5].AIMaxTimeAhead) == 'Losers_Max' and next(T.save().aiRowRestores or {}) == nil, 'a failed launch: the rows straight back')
W.backToMenu(); M.tick(5) -- (a fresh front end: the launch works again)
-- BackRows off for a league: nothing
cfg.AI.BackRows.riffraff = false
mark = T.mark()
ok = R.launch({ path = cfg.Pools.jakku[1].path, title = 'JAKKU', kind = 'Circuit' }, 'riffraff', 'car')
T.check(ok == true and rowText(rows.Default[4].AIMaxTimeAhead) == 'RiffRaff_Max' and not T.logHas('back of the grid ->', mark), 'BackRows false at Junker: the game\'s rows kept')
W.race(11); M.tick(5); W.finish(1); M.tick(25); wait3(); W.backToMenu(); M.tick(45)

-- a left-over from a crash: put back at boot
T.reset()
T.boot({ version = 3, aiRowRestores = { [RP .. 'Default'] = { ['PacingConfigs.4.AIMaxTimeAhead'] = 'RiffRaff_Max' } } }, { Progression = { On = false }, NoTabMenu = true })
local rd = windows('')
rd[4].AIMaxTimeAhead = handle('Challengers_Max')
W.rp.Default.PacingConfigs = M.tarr(rd)
M.tick(5)
T.check(rowText(rd[4].AIMaxTimeAhead) == 'RiffRaff_Max' and T.logHas('[ai] pacing rows put back (left over from an earlier race): RP_Default RiffRaff_Max'), 'a left-over row put back at boot')
T.check(next(T.save().aiRowRestores or {}) == nil, 'and cleared from the save')
T.finish()
