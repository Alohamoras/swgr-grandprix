-- Galactic Grand Prix settings: speed classes, cups, vehicles (DESIGN.md §3-4).
local EV = '/Game/Griffin/Gameplay/Events/Planets/'

-- a race: path, the name shown, the kind
local function race(path, title, kind) return { path = EV .. path, title = title, kind = kind } end

return {
    -- The tab on the game's main menu, next to the game's own tabs
    TabLabel = 'GRAND PRIX',
    -- Tile layout on the tab's page (at 4K one UI unit is about one pixel)
    TabLayout = { TileWidth = 520, TileHeight = 350, Columns = 4, VisibleRows = 3, TextScale = 1.6, FocusScale = 1.04, DimOthers = 0.72 },
    -- Key that selects the GRAND PRIX tab at the main menu (Backspace / B = back)
    MenuKey = 'F6',

    -- After a race: cover the main menu with the game's loading screen while it's rebuilt, so the race results lead
    -- straight to the ranking (v0.3.8). false = show the menu as before.
    HideMenuFlash = true,

    -- Lua garbage: collect a little on every tick (KB of work per step) so it never piles up into one big pause
    -- (v0.3.4, race stutter). GcStep = false to switch off for a comparison.
    GcStep = true,
    GcStepKB = 64,

    -- Progression (v0.5, DESIGN.md §8). Classes with open = true are open from the start (50cc, 100cc); each other
    -- class opens with a trophy in every planet cup of the class before it (Unlock = 'gold': gold in every one).
    -- Bonus cups (bonus = true: Outer Rim, Galactic) open with gold in every planet cup at that class. Anything you
    -- have already raced through stays open. On = false switches every lock off.
    Progression = { On = true, Unlock = 'trophy' },

    -- Speed classes: every part of your vehicle at this level (the AI keeps pace through the game's rubber band)
    Classes = {
        -- parts = every part at this level; abilities = the level of everyone's abilities (yours and the AI's);
        -- mods = how many of your mod slots are open (v0.4, owner: 50cc none - pure driving)
        -- (v0.3.6, owner: four classes - 50cc with no upgrades at all, up to a maxed 200cc. Keys are used in the
        -- save: never change them; the save was converted from the three-class layout, every class moved up one.)
        { key = '50', name = '50cc', parts = 0, mods = 0, abilities = 1, open = true, blurb = 'No upgrades: pure driving' },
        { key = '100', name = '100cc', parts = 3, mods = 2, abilities = 1, open = true, blurb = 'Learn the tracks' },
        { key = '150', name = '150cc', parts = 6, mods = 3, abilities = 2, blurb = 'Faster, sharper rivals' },
        { key = '200', name = '200cc', parts = 10, mods = 4, abilities = 3, blurb = 'Everything maxed out' },
    },

    -- Points by place in each race (1st first); a racer who doesn't finish scores 0
    Points = { 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 },

    -- The title race (v0.8, title.lua): one 1 v 1 at the end of each class against the class champion. The game's
    -- Stadium Showdown against Kestar Bool (6 laps, about 5 minutes; he copies your build, so he scales with the
    -- class). Opens with a trophy in every planet cup at the class. Fallback = the champion named on the class tile
    -- before any cup is finished there (the lore); after that the racer with most points across the planet cups.
    Title = { On = true, Event = EV .. 'Whippet/FINALBOSS/EVT_WHP_SHORTBOSS_FAIR', Name = 'TITLE RACE', Opponent = 'Kestar Bool',
        Fallback = { ['50'] = 'Griff Halloran', ['100'] = 'Lyren Shok', ['150'] = 'Biddy Blas', ['200'] = 'Kestar Bool' } },

    -- Cups of 4 races (full 12-car grids; no knockouts or 1 v 1s). key is used in the save: never change it.
    Cups = {
        { key = 'jakku', name = 'JAKKU CUP', art = 'T_UI_FE_Tile_01', races = {
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD', 'THE WAR FIELDS', 'Circuit'),
            race('Mastiff/P2P_A/EVT_MAS_P2P_FWD', "THE GIANTS' GRAVEYARD", 'Sprint'),
            race('Mastiff/Loop_B/EVT_MAS_LOOP_B_FWD', 'DEBRIS DUNES', 'Circuit'),
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_SHORT_02', 'FALLEN EMPIRE', 'Short circuit'),
        } },
        { key = 'lantaana', name = 'LANTAANA CUP', art = 'T_UI_FE_Tile_02', races = {
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_FWD', "GRIFFIN'S FLIGHT", 'Circuit'),
            race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_FWD', 'MORO KEHN TUNNELS', 'Circuit'),
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_01', 'THE PYRODUCTS', 'Short circuit'),
            race('Dalmatian/P2P/EVT_DAL_P2P_SHORT_05', 'AHLREN JUNGLE SPEEDWAY', 'Short circuit'),
        } },
        { key = 'ando', name = 'ANDO CUP', art = 'T_UI_FE_Tile_05', races = {
            race('Corgi/Loop_A/EVT_COR_Loop_A_FWD', 'ICE FIELD CIRCUIT', 'Circuit'),
            race('Corgi/Loop_B/EVT_COR_Loop_B_FWD', 'MONASTERY MOUNTAINS', 'Circuit'),
            race('Corgi/P2P/EVT_COR_P2P_FWD', 'MOUNTAIN TO SEA', 'Sprint'),
            race('Corgi/Loop_A/EVT_COR_Loop_A_SHORT_02', 'VONIUM PIPELINE', 'Short circuit'),
        } },
        { key = 'crait', name = 'CRAIT CUP', art = 'T_UI_FE_Tile_A', races = {
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_FWD', 'CRIMSON MINES', 'Circuit'),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_FWD', 'FORGIL CANYON', 'Circuit'),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_P2P', 'RHODOCHROSITE RUN', 'Sprint'),
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_SHORT_01', 'SALT CIRCLE', 'Short circuit'),
        } },
        { key = 'sentinel', name = 'SENTINEL CUP', art = 'T_UI_FE_Tile_01', races = {
            race('Husky/LOOP_A/EVT_HSK_LOOP_A_REV', 'SENTINEL LAKES', 'Circuit'),
            race('Husky/LOOP_B/EVT_HSK_LOOP_B_REV', 'CAUSTIC FIELDS', 'Circuit'),
            race('Husky/P2P/EVT_HSK_P2P_REV', 'BOOL RIVER RUN', 'Sprint'),
            race('Husky/LOOP_B/EVT_HSK_LOOP_B_SHORT_02', 'THE ACID RING', 'Short circuit'),
        } },
        { key = 'outerrim', name = 'OUTER RIM CUP', art = 'T_UI_FE_Tile_02', bonus = true, races = {
            race('Mastiff/Loop_B/EVT_MAS_LOOP_B_SHORT_01', 'SCRAP SPIRAL', 'Short circuit'),
            race('Dalmatian/P2P/EVT_DAL_P2P_FWD', 'GEOTHERMAL TOUR', 'Sprint'),
            race('Corgi/P2P/EVT_COR_P2P_REV', 'DAI BENDU ASCENSION', 'Sprint'),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_SHORT_02', 'CRYSTAL CAVERNS', 'Short circuit'),
        } },
        { key = 'galactic', name = 'GALACTIC CUP', art = 'T_UI_FE_Tile_05', bonus = true, races = {
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_06', 'OVERFLOW RALLY', 'Short circuit'),
            race('Corgi/P2P/EVT_COR_P2P_SHORT_05', 'ANDOBI EDGE', 'Short circuit'),
            race('Husky/P2P/EVT_HSK_P2P_SHORT_01', 'SKAKOAN GAMBIT', 'Short circuit'),
            race('Whippet/KNOCKOUT/EVT_WHP_LOOP_A_FWD_RACE', 'THE GALACTIC GAUNTLET', 'Circuit'),
        } },
        -- Remix cups (v0.6.2, owner 2026-11-10): the five planet cups reversed where the game has a reverse layout,
        -- else in their night / wet / snow / mines / scorching versions, else another track from the planet. Open
        -- after a trophy in all five planet cups at the top class (prog.lua), then at any open class. Every event read
        -- in game (GPRecon dump 2026-11-10): normal 12-car team races, any vehicle. Track names of the two new tracks
        -- read in game: the Sentinel special short 02 is Corrosion Hypersphere; the Ando short 01 has no player-facing name
        -- (a developer label only) but is a finished, lit 5-lap ice circuit (seen 2026-11-10).
        { key = 'jakku_remix', name = 'JAKKU REMIX', art = 'T_UI_FE_Tile_01', remix = true, races = {
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_REV', 'THE WAR FIELDS (REVERSE)', 'Circuit'),
            race('Mastiff/Loop_B/EVT_MAS_LOOP_B_SHORT_01', 'SCRAP SPIRAL', 'Short circuit'),
            race('Mastiff/Loop_B/EVT_MAS_LOOP_B_REV', 'DEBRIS DUNES (REVERSE)', 'Circuit'),
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_SHORT_02_HARD', 'FALLEN EMPIRE (SCORCHING)', 'Short circuit'),
        } },
        { key = 'lantaana_remix', name = 'LANTAANA REMIX', art = 'T_UI_FE_Tile_02', remix = true, races = {
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_FWD_Night', "GRIFFIN'S FLIGHT (NIGHT)", 'Circuit'),
            race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_REV_Overcast_Wet', 'MORO KEHN TUNNELS (REVERSE, WET)', 'Circuit'),
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_01_Overcast_Wet', 'THE PYRODUCTS (WET)', 'Short circuit'),
            race('Dalmatian/P2P/EVT_DAL_P2P_SHORT_05_Night', 'AHLREN JUNGLE SPEEDWAY (NIGHT)', 'Short circuit'),
        } },
        { key = 'ando_remix', name = 'ANDO REMIX', art = 'T_UI_FE_Tile_05', remix = true, races = {
            race('Corgi/Loop_A/EVT_COR_Loop_A_REV_Overcast_Snow', 'ICE FIELD CIRCUIT (REVERSE, SNOW)', 'Circuit'),
            race('Corgi/Loop_B/EVT_COR_Loop_B_REV_Overcast_Snow', 'MONASTERY MOUNTAINS (REVERSE, SNOW)', 'Circuit'),
            race('Corgi/Loop_B/EVT_COR_Loop_B_SHORT_01', 'ANDO SHORT CIRCUIT', 'Short circuit'),
            race('Corgi/Loop_A/EVT_COR_Loop_A_SHORT_02_Overcast_Snow', 'VONIUM PIPELINE (SNOW)', 'Short circuit'),
        } },
        { key = 'crait_remix', name = 'CRAIT REMIX', art = 'T_UI_FE_Tile_A', remix = true, races = {
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_REV_MINES', 'CRIMSON MINES (REVERSE, MINES)', 'Circuit'),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_FWD_MINES', 'FORGIL CANYON (MINES)', 'Circuit'),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_P2P_MINES', 'RHODOCHROSITE RUN (MINES)', 'Sprint'),
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_FWD_MINES_Night', 'CRIMSON MINES (MINES, NIGHT)', 'Circuit'),
        } },
        { key = 'sentinel_remix', name = 'SENTINEL REMIX', art = 'T_UI_FE_Tile_01', remix = true, races = {
            race('Husky/LOOP_A/EVT_HSK_LOOP_A_FWD_Overcast', 'SENTINEL LAKES (FORWARD)', 'Circuit'),
            race('Husky/LOOP_B/EVT_HSK_LOOP_B_FWD_BlueHour', 'CAUSTIC FIELDS (FORWARD, BLUE HOUR)', 'Circuit'),
            race('Husky/P2P/EVT_HSK_P2P_FWD_Overcast', 'BOOL RIVER RUN (FORWARD)', 'Sprint'),
            race('Husky/P2P/EVT_HSK_P2P_SPEC_SHORT_02_ApproachingStorm', 'CORROSION HYPERSPHERE (STORM)', 'Short circuit'),
        } },
    },

    -- Abilities (v0.3, DESIGN.md §5). You pick four before a cup (Rule below); the class sets their level, and
    -- at levels 2 and 3 you pick the branch. The AI racers get four each the same way (Racers below). Autopilot is
    -- never offered or given.
    Abilities = {
        -- 'free' (owner, 2026-11-10): pick any four, one per family. 'categories': one per category below (v0.3.0).
        -- The AI racers keep their category fours (Racers) either way.
        Rule = 'free',
        -- the families, in the order the pick screen shows them (Autopilot is never one)
        Families = { 'bolt', 'shockwave', 'mine', 'shield', 'scrubber', 'vent', 'surge' },
        Categories = {
            { key = 'offensive', name = 'OFFENSIVE', families = { 'bolt', 'shockwave' } },
            { key = 'defensive', name = 'DEFENSIVE', families = { 'shield' } },
            { key = 'utility', name = 'UTILITY', families = { 'scrubber', 'vent', 'surge' } },
            -- mines, or any family above that isn't already one of your picks
            { key = 'wildcard', name = 'WILDCARD', families = { 'mine', 'bolt', 'shockwave', 'shield', 'scrubber', 'vent', 'surge' } },
        },
        Default = { offensive = 'bolt.concuss', defensive = 'shield.impact', utility = 'surge.impact', wildcard = 'mine.double' },
        Blurb = { bolt = 'Lock on and disrupt a rival', mine = 'Drop charges behind you', scrubber = 'Clear bad status effects',
            shield = 'Shrug off hits for a while', shockwave = 'Blast nearby racers away', surge = 'A burst of speed',
            vent = 'Cool your ramjet down' },
        -- upgrade lines: family -> branch -> level 1, 2, 3 (Gameplay/Abilities/<path>); _AI = the game's bot versions
        -- (yours drop the _AI). From the Underground (recon 2026-11-09).
        Lines = {
            bolt      = { concuss = { 'Disruptor/BP_Ability_Disruptor', 'Disruptor/BP_Ability_Disruptor_Concuss', 'Disruptor/BP_Ability_Disruptor_ConcussV2' },
                          multi   = { 'Disruptor/BP_Ability_Disruptor', 'Disruptor/BP_Ability_Disruptor_Multi', 'Disruptor/BP_Ability_Disruptor_Surge' } },
            mine      = { double  = { 'Mine/BP_Ability_Mine_AI', 'Mine/BP_Ability_Mine_Double_AI', 'Mine/BP_Ability_Mine_Triple_AI' },
                          frozen  = { 'Mine/BP_Ability_Mine_AI', 'Mine/BP_Ability_Mine_Frozen_AI', 'Mine/BP_Ability_Mine_EnergyRecovery' } },
            scrubber  = { auto    = { 'Repair/BP_Ability_Repair', 'Repair/BP_Ability_Repair_Auto', 'Repair/BP_Ability_Repair_AutoV2' },
                          multi   = { 'Repair/BP_Ability_Repair', 'Repair/BP_Ability_Repair_ExtraRepair', 'Repair/BP_Ability_Repair_ExtraRepairV2' } },
            shield    = { impact  = { 'Shield/BP_Ability_Shield', 'Shield/BP_Ability_Shield_Charged', 'Shield/BP_Ability_Shield_ChargedV2' },
                          surging = { 'Shield/BP_Ability_Shield', 'Shield/BP_Ability_Shield_Surging', 'Shield/BP_Ability_Shield_SurgingV2' } },
            shockwave = { magnetic = { 'Shockwave/BP_Ability_Shockwave', 'Shockwave/BP_Ability_Shockwave_Magnetic', 'Shockwave/BP_Ability_Shockwave_MagneticConcussion' },
                          vectored = { 'Shockwave/BP_Ability_Shockwave', 'Shockwave/BP_Ability_Shockwave_Punch', 'Shockwave/BP_Ability_Shockwave_Punch_Mk2' } },
            surge     = { impact  = { 'Surge/BP_Ability_Surge', 'Surge/BP_Ability_Surge_Aggressive', 'Surge/BP_Ability_Surge_AggressiveV2' },
                          overtake = { 'Surge/BP_Ability_Surge', 'Surge/BP_Ability_Surge_Overtake', 'Surge/BP_Ability_Surge_OvertakeV2' } },
            vent      = { auto    = { 'Vent/BP_Ability_Vent', 'Vent/BP_Ability_VentV2', 'Vent/BP_Ability_Vent_Auto' },
                          freezing = { 'Vent/BP_Ability_Vent', 'Vent/BP_Ability_VentV2', 'Vent/BP_Ability_Vent_Freezing' },
                          flame   = { 'Vent/BP_Ability_Vent', 'Vent/BP_Ability_Vent_Flame', 'Vent/BP_Ability_Vent_Acid' } },
        },
        Names = {
            Disruptor = 'Ion Bolt', Disruptor_Concuss = 'Concussive Bolt', Disruptor_ConcussV2 = 'Concussive Bolt II',
            Disruptor_Multi = 'Multi-Bolt', Disruptor_Surge = 'Multi-Bolt II',
            Mine = 'Concussion Mine', Mine_Double = 'Concussion Mine II', Mine_Triple = 'Concussion Mine III',
            Mine_Frozen = 'Freezing Mine', Mine_EnergyRecovery = 'Freezing Mine II',
            Repair = 'Status Scrubber', Repair_Auto = 'Auto-Scrubber', Repair_AutoV2 = 'Auto-Scrubber II',
            Repair_ExtraRepair = 'Multi-Scrubber', Repair_ExtraRepairV2 = 'Multi-Scrubber II',
            Shield = 'Shield', Shield_Charged = 'Impact Shield', Shield_ChargedV2 = 'Impact Shield II',
            Shield_Surging = 'Surging Shield', Shield_SurgingV2 = 'Surging Shield II',
            Shockwave = 'Shockwave', Shockwave_Magnetic = 'Magnetic Shockwave', Shockwave_MagneticConcussion = 'Magnetic Shockwave II',
            Shockwave_Punch = 'Vectored Shockwave', Shockwave_Punch_Mk2 = 'Vectored Shockwave II',
            Surge = 'Surge', Surge_Aggressive = 'Impact Surge', Surge_AggressiveV2 = 'Impact Surge II',
            Surge_Overtake = 'Overtaking Surge', Surge_OvertakeV2 = 'Overtaking Surge II',
            Vent = 'Vent', VentV2 = 'Vent II', Vent_Auto = 'Auto-Vent', Vent_Freezing = 'Supercooled Vent',
            Vent_Flame = 'Flame Vent', Vent_Acid = 'Corrosive Vent',
        },
        -- The AI racers' four (DA_Racer_<key>; name = English fallback), sorted from the Underground's signature kits
        -- by their style in the game's data. The same every race; the class sets the level.
        AI = true,
        Racers = {
            Antagonist          = { name = 'Kestar Bool',    offensive = 'bolt.concuss',       defensive = 'shield.impact',  utility = 'surge.impact',   wildcard = 'shockwave.vectored' },
            Rager               = { name = 'Biddy Blas',     offensive = 'shockwave.vectored', defensive = 'shield.impact',  utility = 'vent.flame',     wildcard = 'surge.impact' },
            DarkEnigma          = { name = 'Shade',          offensive = 'bolt.concuss',       defensive = 'shield.surging', utility = 'vent.auto',      wildcard = 'scrubber.auto' },
            ElegantProfessional = { name = 'Katja Mox',      offensive = 'bolt.multi',         defensive = 'shield.surging', utility = 'scrubber.auto',  wildcard = 'surge.overtake' },
            Ghost               = { name = 'Goli & 02-R0',   offensive = 'bolt.multi',         defensive = 'shield.surging', utility = 'surge.overtake', wildcard = 'vent.auto' },
            InnerHonour         = { name = 'Soren Zaks',     offensive = 'shockwave.magnetic', defensive = 'shield.impact',  utility = 'scrubber.auto',  wildcard = 'bolt.concuss' },
            Mercenary           = { name = 'Malis Vazosk',   offensive = 'shockwave.vectored', defensive = 'shield.impact',  utility = 'surge.impact',   wildcard = 'mine.double' },
            Nomad               = { name = 'Fola Kanjen',    offensive = 'bolt.concuss',       defensive = 'shield.surging', utility = 'scrubber.auto',  wildcard = 'surge.overtake' },
            Protege             = { name = 'Ary Quill',      offensive = 'bolt.multi',         defensive = 'shield.surging', utility = 'vent.auto',      wildcard = 'surge.overtake' },
            QuietStrength       = { name = 'Nik Skandaro',   offensive = 'shockwave.magnetic', defensive = 'shield.impact',  utility = 'scrubber.auto',  wildcard = 'mine.frozen' },
            Star                = { name = 'Lyren Shok',     offensive = 'shockwave.vectored', defensive = 'shield.surging', utility = 'surge.impact',   wildcard = 'vent.auto' },
            Thrall              = { name = 'Sen Fira',       offensive = 'bolt.multi',         defensive = 'shield.surging', utility = 'surge.overtake', wildcard = 'mine.double' },
            Veteran             = { name = 'Griff Halloran', offensive = 'shockwave.vectored', defensive = 'shield.impact',  utility = 'surge.impact',   wildcard = 'mine.double' },
            Mentor              = { name = 'Sebulba',        offensive = 'shockwave.vectored', defensive = 'shield.impact',  utility = 'surge.overtake', wildcard = 'mine.double' },
        },
        -- anyone else gets the default four
    },

    -- Vehicles (v0.1: the landspeeder; the choice comes with the cup flow). arch = the game's vehicle archetype
    -- (0 car, 2 bike, 3 skimmer); build = the launch build whose part levels are set for the race and put back after.
    Vehicles = {
        { key = 'car', arch = 0, name = 'LANDSPEEDER', build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base' },
        { key = 'bike', arch = 2, name = 'SPEEDER BIKE', build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Bike_Base' },
        { key = 'skimmer', arch = 3, name = 'SKIM SPEEDER', build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Skimmer_Base' },
    },

    -- Your racer (v0.8, racer.lua): any of the game's named pilots. key = the racer def DA_Racer_<key>
    -- (/Game/Griffin/Narrative/CharacterDefs/Racers/); name = the game's CharacterName (what the HUD and the standings
    -- show); line = one line for the RACER tile (from the game's bios). The first entry is the default and the game's
    -- own pilot (CharacterList.Player = Shade); the pick is kept in the save (racer). A pilot who is one of the 11
    -- opponents takes Shade's place on the grid for the race, so the field stays 12. Keys are the game's: don't change.
    Racers = {
        { key = 'DarkEnigma',          name = 'Shade',          line = 'The campaign\'s racer' },
        { key = 'Protege',             name = 'Ary Quill',      line = 'Audacious heir to the Quill racing legacy' },
        { key = 'Mercenary',           name = 'Malis Vazosk',   line = 'Racing and mercenary work are one and the same' },
        { key = 'QuietStrength',       name = 'Nik Skandaro',   line = 'The Bools\' former enforcer, racing for solace' },
        { key = 'Veteran',             name = 'Griff Halloran', line = 'Still in his Imperial Navy armour; flying is what he knows' },
        { key = 'Ghost',               name = 'Goli & 02-R0',   line = 'A meek prodigy from Polis Massa and their companion droid' },
        { key = 'InnerHonour',         name = 'Soren Zaks',     line = 'A former smuggler redeeming his life on the racetrack' },
        { key = 'Nomad',               name = 'Fola Kanjen',    line = 'From racing farmers\' cattle to the Galactic League' },
        { key = 'ElegantProfessional', name = 'Katja Mox',      line = 'Forging her own destiny apart from the disgraced MoxCorp' },
        { key = 'Thrall',              name = 'Sen Fira',       line = 'Races for Kestar until her debt to the Bools is repaid' },
        { key = 'Rager',               name = 'Biddy Blas',     line = 'Hot-headed; his last shot at a face on a cereal box' },
        { key = 'Star',                name = 'Lyren Shok',     line = 'Celebrity waveskimmer racer after a new start and fans' },
        { key = 'Mentor',              name = 'Sebulba',        line = 'The legend himself, never on the League\'s grid' },
        { key = 'Antagonist',          name = 'Kestar Bool',    line = 'Galactic League Champion, proud son of the Bool family' },
    },

    -- AI strength per class (ai.lua; DESIGN.md §4, docs/research-2026-11-10.md "Difficulty"). Everything is
    -- memory-only and put back at the menu. Enabled = false switches all of it off.
    AI = {
        Enabled = true,
        -- Hidden tuning dial: added to every class's pressure (e.g. 0.25 = every class a notch harder). Keep 0.
        Adjust = 0,
        -- One profile per class key. pressure (-1..2): the rubber band on the game's race tune data, the way its own
        -- difficulties set it - -1 = Cadet (AI max time ahead x0.65 / min -3 s, abilities -0.25, aggression -0.35,
        -- slam countdown +0.8 s), 0 = the game's own, 1 = Nightmare (+2.5 s / +1.5 s, abilities +0.5, aggression +1,
        -- cooldown x0.75), 2 = Champion (+5 s / +3 s, abilities +1.25, aggression +2.5, cooldown x0.5); in between is
        -- interpolated. ops = { AiField = { add, mul } }: an explicit extra op on one tune field, after the pressure's.
        -- The rest write the AI config asset (DA_AIConfig) at launch and put it back at the menu:
        --   pacing = { field = value }: its DefaultPacingSettings (the game's: RacePacingLowestSpeedMph 150,
        --     MaxAiCatchupScale 1.3, MaxAiSlowdownScale 0.75, AiAheadTimeToMaxSlowdown 1.5, AiBehindTimeToMaxCatchup
        --     2, AiSlowdownDuringCrash 0.5). MaxAiSlowdownScale = 1.0 is "honest pacing": the AI never slows down for
        --     you when it's ahead, so "fail now, win later" is real.
        --   catchup = multiplier on MaxAiCatchupScale (how much faster the AI goes when behind; 1.3 x 1.15 = 1.5).
        --   errors = multiplier on ForcedErrorChance (the game's 15 %/s near you; 0.5 = half the mistakes).
        --   perfectStart = the AI's chance of a perfect start, % (the game's 75).
        --   aggression = { chance = multiplier, cooldown = multiplier } on AggressionConfig.VersusPlayer (50 %, 2 s).
        --   config = { ['Field'] = value, ['Struct.Field'] = value }: any other number on the asset, by path.
        Profiles = {
            ['50'] = { pressure = -1 },
            ['100'] = { pressure = 0 },
            ['150'] = { pressure = 0.5, pacing = { MaxAiSlowdownScale = 1.0 }, errors = 0.5 },
            ['200'] = { pressure = 1.2, pacing = { MaxAiSlowdownScale = 1.0 }, catchup = 1.15, errors = 0.5, perfectStart = 90 },
        },
    },
}
