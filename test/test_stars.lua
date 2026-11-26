-- v0.37.0 (owner 2026-11-25: "the star for each league...what does that mean? it's not obvious to the player"; TASKS
-- §3): the info lines say what the marks mean, and a perfect cup wears a crown so the star means only the league title.
local M = require('mock')
local W = require('world')
local T = require('util')

T.boot({ version = 3, races = 20, cups = 5, class = 'riffraff', restores = {}, abilityRestores = {} }, { Progression = { On = false } })
W.cupEvents()
local H = rawget(_G, 'GU_TEST_SCREENS')
local K = require('gp')
local cfg = require('config')
local ART = require('art')

local function homeInfo(key)
  for _, it in ipairs(H.SCREENS.home().items) do if it.classKey == key then return it.info end end
end
local function lines(s) local n = 0; for _ in tostring(s):gmatch('[^\n]+') do n = n + 1 end; return n end

-- 1. HOME: the focused league's info line = its rules, then the gold star's meaning (not won yet: how to win it)
local i1 = homeInfo('riffraff')
T.check(i1:find(cfg.Leagues[1].rules, 1, true) == 1, 'HOME: the rules line first')
T.check(i1:find('Gold star: the league title. Finish the Galactic Cup in the top 3, then beat Kestar Bool in a one-on-one race to win it.', 1, true) ~= nil,
  'HOME: the star explained, title not won (' .. i1 .. ')')
local i2 = homeInfo('challenger')
T.check(lines(i1) == lines(i2), 'HOME: every league\'s info the same height')
-- won: the champion line
K.data.titles = K.data.titles or {}
K.data.titles.riffraff = { won = true }
local i3 = homeInfo('riffraff')
T.check(i3:find('Gold star: you are the JUNKER champion. You beat Kestar Bool in the Galactic Cup final.', 1, true) ~= nil,
  'HOME: the champion line once the title is won (' .. i3 .. ')')
-- Gate gold: says win, not top 3
cfg.Boss.Gate = 'gold'
T.check(homeInfo('challenger'):find('Win the Galactic Cup, then beat', 1, true) ~= nil, 'Gate gold: "Win the Galactic Cup"')
cfg.Boss.Gate = 'trophy'
-- switch off: the rules line alone, as before
cfg.StarLines = false
T.check(homeInfo('challenger') == cfg.Leagues[2].rules .. '\n ', 'StarLines = false: the rules line alone (v0.36 behaviour)')
cfg.StarLines = true

-- 2. the cups page: no trophy = no crown line; a trophy = how to earn the crown; perfect = the crown and its line
K.data.class = 'riffraff'
M.press('F6'); M.tick(6)
T.clickTitle('JUNKER'); M.tick(3)
local items = H.SCREENS.cups().items
T.check(not items[1].info:find('crown', 1, true), 'cups: no trophy, no crown line')
K.data.best.riffraff = K.data.best.riffraff or {}
K.data.best.riffraff.jakku = 2
items = H.SCREENS.cups().items
T.check(items[1].info:find('Win every race of this cup in one go to earn the crown.', 1, true) ~= nil, 'cups: a trophy, not perfect: how to earn the crown')
T.check(items[1].corner == nil, 'cups: no crown yet')
K.data.best.riffraff.jakku = 1
K.data.perfect.riffraff = { jakku = true }
items = H.SCREENS.cups().items
T.check(items[1].info:find('Crown: a perfect cup. You won every race.', 1, true) ~= nil, 'cups: the perfect cup line')
T.check(items[1].corner and items[1].corner[1][1] == cfg.PerfectIcon and cfg.PerfectIcon:find('T_UI_Map_ChampionEvent_Icn', 1, true) ~= nil,
  'cups: a perfect cup wears the crown, not the star')
T.check(items[1].corner[1][1] ~= ART.STAR, 'the star is the league title\'s only')
local n = 0; for _ in items[6].info:gmatch('\n') do n = n + 1 end
T.check(n == 4, 'cups: the info stays five lines (' .. n .. ')')
cfg.PerfectIcon = 'star'
T.check(H.SCREENS.cups().items[1].corner[1][1] == ART.STAR, 'PerfectIcon = star: the old star back')
cfg.PerfectIcon = '/Game/Griffin/UI/Library/Textures/Icons/Map/T_UI_Map_ChampionEvent_Icn'

T.finish()
