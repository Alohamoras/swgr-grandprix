-- Galactic Grand Prix: menu art (v0.7.0, owner 2026-11-10: "I like all of those, just go for it").
-- Every picture is one of the game's own textures, loaded by path (research and previews: tools/art/README.md,
-- https://claude.ai/artifact/6mLfAbAs7k8NeCqvpU8yML). Pure functions: paths only, nothing looked up here.
local A = {}

local TEX = '/Game/Griffin/UI/Library/Textures/'
local ARCADE = TEX .. 'Content/Arcade/T_UI_Arcade_'

-- the leagues (v0.26; were the speed classes): three of the game's four difficulty banners - Riff-Raff sage,
-- Challenger blue, Ace red (the gold one, the old 100cc's, is left out)
local LEAGUE = { riffraff = 1, challenger = 3, ace = 4 }
function A.league(key)
  local n = LEAGUE[tostring(key)]
  return n and (TEX .. 'Backgrounds/T_UI_DifficultySettings0' .. n .. '_Bg') or nil
end

-- the planets' Arcade art: a poster (Tile) and a dark full-colour scene (Bg) per vehicle, not every pair exists
-- (from the pak index, 2026-11-10)
local HAVE = {
  Tile = {
    Mas = { Car = 1, Bike = 1, Skimmer = 1, Plane = 1 }, Dal = { Car = 1, Bike = 1, Skimmer = 1, Plane = 1 },
    Cor = { Car = 1, Bike = 1, Skimmer = 1, Plane = 1 }, Spa = { Bike = 1, Plane = 1 }, Hus = { Car = 1 },
    Whp = { Car = 1, Bike = 1, Skimmer = 1, Plane = 1 }, Bgl = { Plane = 1 },
  },
  Bg = {
    Mas = { Car = 1, Bike = 1, Skimmer = 1, Plane = 1 }, Dal = { Car = 1, Bike = 1, Skimmer = 1, Plane = 1 },
    Cor = { Car = 1, Bike = 1, Skimmer = 1, Plane = 1 }, Spa = { Car = 1, Bike = 1, Skimmer = 1, Plane = 1 },
    Hus = { Bike = 1, Skimmer = 1 }, Whp = { Car = 1, Bike = 1, Skimmer = 1, Plane = 1 }, Bgl = { Plane = 1 },
  },
}
local VEH = { car = 'Car', bike = 'Bike', skimmer = 'Skimmer' }
local ORDER = { 'Car', 'Bike', 'Skimmer', 'Plane' }

-- a planet's picture, your vehicle's version when there is one
function A.planet(planet, kind, vehicleKey)
  local have = HAVE[kind] and HAVE[kind][planet]
  if not have then return nil end
  local want = VEH[vehicleKey or 'car'] or 'Car'
  local pick = have[want] and want
  if not pick then for _, v in ipairs(ORDER) do if have[v] then pick = v; break end end end
  return pick and (ARCADE .. planet .. '_' .. pick .. '_' .. kind) or nil
end

-- the cups (v0.11: the five planet cups and the Galactic Cup): the planet's poster, your vehicle's version
local PLANET = { jakku = 'Mas', lantaana = 'Dal', ando = 'Cor', crait = 'Spa', sentinel = 'Hus', galactic = 'Whp' }
function A.cup(cup, vehicleKey)
  if not cup then return nil end
  if cup.artPath then return cup.artPath end
  local p = PLANET[cup.key]
  if not p then return nil end
  return A.planet(p, 'Tile', vehicleKey)
end

-- the trophy medals (best = 1 / 2 / 3)
local MEDAL = { 'Gold', 'Silver', 'Bronze' }
function A.medal(best)
  local m = MEDAL[best or 0]
  return m and (TEX .. 'Icons/Leaderboard/T_UI_Grit_Medals_' .. m) or nil
end
-- the tile draws its icon as a one-colour shape (seen in game), so each medal gets its colour back
local MEDAL_COLOR = { { 1, 0.78, 0.25 }, { 0.82, 0.86, 0.92 }, { 0.86, 0.52, 0.3 } }
function A.medalColor(best) return MEDAL_COLOR[best or 0] end

-- the mod groups: the game's racer-style pictures
local GROUP = {
  ['Afterburner'] = 'Afterburner', ['Ramjet'] = 'Ramjet', ['Cooling & heat'] = 'Cooling',
  ['Shields, surges & slipstream'] = 'Surging', ['Status protection'] = 'Frozen', ['Abilities & energy'] = 'Abilities',
  ['Takedowns'] = 'Battling', ['Crashes & recovery'] = 'Struggling', ['Driving skill'] = 'Airborne',
}
function A.style(name) return TEX .. 'Content/RacerStyles/T_UI_RacerStyle_' .. name .. '_Bg' end
function A.modGroup(g) return GROUP[g] and A.style(GROUP[g]) or nil end

-- your vehicle (the game's main-menu vehicle tiles)
local VTILE = { car = 'T_UI_FE_Tile_05', bike = 'T_UI_FE_Tile_05_Bike', skimmer = 'T_UI_FE_Tile_05_Skim' }
function A.vehicle(key) return VTILE[key] or 'T_UI_FE_Tile_05' end

A.ABILITIES = A.style('Abilities')
-- (darker than the group pictures' sunny desert ones: the white title stays readable on a focused tile)
A.MODS = A.style('Afterburner')
A.SHOWDOWN = A.style('Antagonist')
-- behind the points table (dark, so the text stays readable)
A.BACKDROP = TEX .. 'Backgrounds/T_UI_Scenario_Bg'

-- v0.15.1 (seen in game 2026-11-11): the game brightens a FOCUSED tile's picture, and the white title on the
-- brightest pictures became hard to read (the sage / gold difficulty banners, Kestar's portrait). Those pictures are
-- drawn darker (the tile's picture tinted grey). Brightness under the title, 0-255, measured on the textures
-- (tools/art/iotex.py previews): sage (Riff-Raff) 136, gold 130 (not used since v0.26), Kestar 151; blue (Challenger) 104 and red (Ace) 112
-- read fine in game, so the factor brings each to about 100.
A.DIM = {
  T_UI_DifficultySettings01_Bg = 0.75,
  T_UI_RacerStyle_Antagonist_Bg = 0.7,
}
function A.dim(path)
  local base = path and tostring(path):match('([^/.]+)$')
  return base and A.DIM[base] or nil
end

-- v0.24 (owner: pictures, not words on tiles): the game's own icons, tinted (one-colour shapes)
local ICONS = TEX .. 'Icons/'
A.LOCK = ICONS .. 'T_UI_Lock_Icn'
A.STAR = ICONS .. 'T_UI_Star_Lg_Icn'
-- v0.26 (owner: the leagues' speed as a picture, 1-3 chevrons on each HOME poster): the game's plain right-pointing
-- arrowhead (a solid wedge, 64 px; decoded from the paks with tools/art/iotex.py, 2026-11-12), drawn white in the
-- poster's top right corner (ui.lua U.decorate it.corner), a little smaller than the corner icons so three sit beside
-- the medal pips on a 760-wide poster
A.SPEED = ICONS .. 'Leaderboard/T_UI_SimpleArrow_Icn'
A.SPEED_COLOR = { 1, 1, 1 }
A.SPEED_PX = 56
-- a league's chevrons as corner pictures: n of them (nil for none)
function A.speed(n)
  n = tonumber(n) or 0
  if n < 1 then return nil end
  local out = {}
  for i = 1, n do out[i] = { A.SPEED, A.SPEED_COLOR, nil, px = A.SPEED_PX } end
  return out
end
A.GREY = { 0.55, 0.57, 0.6 }       -- a medal not won yet (drawn faint)
A.LOCK_COLOR = { 0.9, 0.9, 0.92 }
-- an ability family's big icon (Icons/Abilities/LargeAbilityIcons)
local FAMILY = { bolt = 'IonBolt', shockwave = 'Shockwave', mine = 'Mines', shield = 'Shield', scrubber = 'StatusScrubber',
  vent = 'Vent', surge = 'Surge' }
function A.ability(family)
  local n = family and FAMILY[family]
  return n and (ICONS .. 'Abilities/LargeAbilityIcons/T_UI_Ability_' .. n .. '_Lg_Icn') or nil
end
-- a tune-up's icon: its first affix's (matched against the game's texture list, tools/art/textures.txt, 2026-11-11)
local TUNE = {
  heat_shield = 'Conditions_BurningProtection', armour = 'Conditions_DisruptedProtection', ice_cold = 'Cooled_GainWhileAirborne',
  redliner = 'Ramjet_TempCanDropWhileBoosting', ramjet_rider = 'Ramjet_NoHeatWhileAirborne',
  afterburner = 'Afterburner_BetterWhileAirborne_v3', brawler = 'Takedown_ResetHeat', survivor = 'Crash_ReturnWithShield',
  slipstreamer = 'Slipstream_gainSurging_v1', firebug = 'Burning_GainOvercharged', engineer = 'SysMalf_ShorterMalfunction',
  tenacious = 'Conditions_CorrodeResistance',
}
function A.tuneUp(key)
  local n = key and TUNE[key]
  return n and (ICONS .. 'Affixes/LargeAffixIcons/T_UI_AFX_' .. n .. '_Lg_Icn') or nil
end

return A
