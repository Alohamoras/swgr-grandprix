-- art.lua (v0.7): every picture the menus ask for is a real texture in the game (tools/art/textures.txt, from the pak index).
local here = arg[0]:match('^(.*)/test/[^/]+$') or '.'
package.path = here .. '/mod/GalacticGrandPrix/Scripts/?.lua;' .. package.path
local cfg = require('config')
local ART = require('art')
local MS = require('modsel')
local failed = false
local function check(c, what) io.stdout:write((c and 'PASS ' or 'FAIL ') .. what .. '\n'); if not c then failed = true end end

local have = {}
for line in io.lines(here .. '/tools/art/textures.txt') do have[line] = true end
local MM = '/Game/Griffin/UI/Library/Textures/Content/MainMenu/'
local function real(p) return p ~= nil and (have[p] or have[MM .. p]) == true end

local bad = {}
local function each(p, what) if not real(p) then bad[#bad + 1] = what .. ' -> ' .. tostring(p) end end
for _, c in ipairs(cfg.Classes) do each(ART.class(c.key), 'class ' .. c.key) end
local cups = 0
for _, cup in ipairs(cfg.Cups) do
  for _, v in ipairs(cfg.Vehicles) do each(ART.cup(cup, v.key), cup.key .. ' / ' .. v.key) end
  cups = cups + 1
end
for b = 1, 3 do each(ART.medal(b), 'medal ' .. b) end
for _, g in ipairs(MS.groups()) do each(ART.modGroup(g), 'mod group ' .. g) end
for _, v in ipairs(cfg.Vehicles) do each(ART.vehicle(v.key), 'vehicle ' .. v.key) end
each(ART.ABILITIES, 'abilities'); each(ART.MODS, 'mods'); each(ART.SHOWDOWN, 'showdown'); each(ART.BACKDROP, 'backdrop')
check(#bad == 0, 'every picture exists in the game (' .. cups .. ' cups x 3 vehicles, classes, medals, groups)' ..
  (#bad > 0 and (': ' .. table.concat(bad, '; ')) or ''))

check(ART.cup({ key = 'jakku' }, 'bike'):find('Mas_Bike_Tile$') ~= nil, 'Jakku on a bike: the Jakku bike poster')
check(ART.cup({ key = 'crait' }, 'car'):find('Spa_Bike_Tile$') ~= nil, 'Crait has no car poster: the bike one')
check(ART.cup({ key = 'sentinel' }, 'skimmer'):find('Hus_Car_Tile$') ~= nil, 'Sentinel has only a car poster')
check(ART.cup({ key = 'galactic', final = true }, 'bike'):find('Whp_Bike_Tile$') ~= nil, 'the Galactic Cup: the Derven poster')
check(ART.cup({ key = 'jakku_remix' }, 'car') == nil and ART.cup({ key = 'outerrim' }, 'car') == nil, 'v0.11: no art for the removed cups')
check(ART.cup({ key = 'nowhere' }, 'car') == nil and ART.medal(4) == nil and ART.class('75') == nil, 'unknown -> nil (the old tile is kept)')
local seen, dup = {}, false
for _, c in ipairs(cfg.Classes) do if seen[ART.class(c.key)] then dup = true end; seen[ART.class(c.key)] = true end
check(not dup, 'each class its own banner')
if failed then os.exit(1) end
