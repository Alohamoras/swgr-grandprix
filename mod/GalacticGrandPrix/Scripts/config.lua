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

    -- Speed classes: every part of your vehicle at this level (the AI keeps pace through the game's rubber band)
    Classes = {
        { key = '50', name = '50cc', parts = 3, blurb = 'Learn the tracks' },
        { key = '100', name = '100cc', parts = 6, blurb = 'Faster, sharper rivals' },
        { key = '150', name = '150cc', parts = 10, blurb = 'Everything maxed out' },
    },

    -- Points by place in each race (1st first); a racer who doesn't finish scores 0
    Points = { 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 },

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
        { key = 'outerrim', name = 'OUTER RIM CUP', art = 'T_UI_FE_Tile_02', races = {
            race('Mastiff/Loop_B/EVT_MAS_LOOP_B_SHORT_01', 'SCRAP SPIRAL', 'Short circuit'),
            race('Dalmatian/P2P/EVT_DAL_P2P_FWD', 'GEOTHERMAL TOUR', 'Sprint'),
            race('Corgi/P2P/EVT_COR_P2P_REV', 'DAI BENDU ASCENSION', 'Sprint'),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_SHORT_02', 'CRYSTAL CAVERNS', 'Short circuit'),
        } },
        { key = 'galactic', name = 'GALACTIC CUP', art = 'T_UI_FE_Tile_05', races = {
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_06', 'OVERFLOW RALLY', 'Short circuit'),
            race('Corgi/P2P/EVT_COR_P2P_SHORT_05', 'ANDOBI EDGE', 'Short circuit'),
            race('Husky/P2P/EVT_HSK_P2P_SHORT_01', 'SKAKOAN GAMBIT', 'Short circuit'),
            race('Whippet/KNOCKOUT/EVT_WHP_LOOP_A_FWD_RACE', 'THE GALACTIC GAUNTLET', 'Circuit'),
        } },
    },

    -- Vehicles (v0.1: the landspeeder; the choice comes with the cup flow). arch = the game's vehicle archetype
    -- (0 car, 2 bike, 3 skimmer); build = the launch build whose part levels are set for the race and put back after.
    Vehicles = {
        { key = 'car', arch = 0, name = 'LANDSPEEDER', build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base' },
        { key = 'bike', arch = 2, name = 'SPEEDER BIKE', build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Bike_Base' },
        { key = 'skimmer', arch = 3, name = 'SKIM SPEEDER', build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Skimmer_Base' },
    },
}
