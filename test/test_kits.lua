-- v0.31 (PR #1): signature kits and the vehicle pick. A brand-new save starts on the pilot's own four (Shade's);
-- cycling the pilot gives the next pilot's four and their own vehicle; a save with picks from before v0.31 keeps them
-- (test_oldpicks); the garage's PILOT tile carries the racer's face (the game's MainIcon texture path, nothing shipped).
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot(nil, { Progression = { On = false } })
local K, cfg = require('gp'), require('config')
local H = rawget(_G, 'GU_TEST_SCREENS')
M.press('F6'); M.tick(6)
T.clickTitle('GARAGE'); M.tick(5)
T.check(T.titles():find('^SHADE|LANDSPEEDER|ION BOLT|SHIELD|VENT|STATUS SCRUBBER', 1) ~= nil,
  'a new save: Shade, his landspeeder, his signature four (bolt, shield, vent, scrubber at level 1) (' .. T.titles() .. ')')
local sv = T.save()
T.check(sv.picksRacer == 'DarkEnigma' and (sv.picks[1] or sv.picks.offensive) == 'bolt.concuss', 'saved as Shade\'s kit (picksRacer)')
local items = H.S.ui.items
T.check(items[1].kind == 'racer' and type(items[1].glyph) == 'table' and items[1].glyph[1] == cfg.Portraits.DarkEnigma
  and items[1].glyph.side == 'left' and cfg.Portraits.DarkEnigma:find('/Game/Griffin/UI/Library/Textures/Content/Characters/T_UI_PlayerChar_4', 1, true) == 1,
  'the PILOT tile: Shade\'s face from the game\'s own texture, on the left (' .. tostring(items[1].glyph and items[1].glyph[1]) .. ')')
T.check(items[2].kind == 'vehicle' and items[2].title == 'LANDSPEEDER', 'the VEHICLE tile: his landspeeder')
-- every racer has a face in the game data
local missing = {}
for _, r in ipairs(cfg.Racers) do if not cfg.Portraits[r.key] then missing[#missing + 1] = r.key end end
T.check(#missing == 0, 'every racer has a portrait path (' .. table.concat(missing, ',') .. ')')
-- the next pilot: Ary Quill, his kit, his vehicle
T.clickTitle('SHADE'); M.tick(5)
T.check(T.titles():find('^ARY QUILL|LANDSPEEDER|ION BOLT|SHIELD|VENT|SURGE|') ~= nil,
  'Select on the pilot: Ary Quill with his signature four (' .. T.titles() .. ')')
sv = T.save()
T.check(sv.racer == 'Protege' and sv.picksRacer == 'Protege' and sv.vehicle == 'car', 'saved: the pilot, his kit, his vehicle')
-- the vehicle tile cycles the three; the pick sticks to the pilot
T.clickTitle('LANDSPEEDER'); M.tick(5)
T.check(T.titles():find('^ARY QUILL|SPEEDER BIKE|', 1) ~= nil and T.save().vehicle == 'bike', 'the VEHICLE tile: speeder bike (' .. T.titles() .. ')')
-- a cup launches with the picked vehicle, and the rider's scheme is tried for it (the mock racer has no customisation map)
M.press('BACKSPACE'); M.tick(3)
T.clickTitle('JUNKER'); M.tick(3)
local mark = T.mark()
T.clickTitle('JAKKU CUP')
T.check(T.logHas('vehicle=bike', mark), 'the cup launches on the bike')
T.check(T.logHas('[paint] Ary Quill', mark), 'the scheme for a vehicle not his own is tried (logged)')
T.finish()
