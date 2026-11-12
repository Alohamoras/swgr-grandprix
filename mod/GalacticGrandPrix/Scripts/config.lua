-- Galactic Grand Prix settings: speed classes, cups, vehicles (DESIGN.md §3-4).
local EV = '/Game/Griffin/Gameplay/Events/Planets/'

-- a race: path, the name shown, the kind, laps (the event's own lap count: events_dump.txt / GPRecon, 2026-11-10;
-- a sprint is 1 lap). The planet comes from the path's first folder (Planets below, gp.lua planetOf).
-- v0.11: base = the track without its direction / conditions ('THE WAR FIELDS (REVERSE, SCORCHING)' -> 'THE WAR
-- FIELDS'; a cup never races one twice), cond = the conditions in the title ('SCORCHING', 'MINES, NIGHT'; nil = none).
local function race(path, title, kind, laps)
    local base, inner = title:match('^(.-)%s*%((.*)%)$')
    local cond = {}
    for w in (inner or ''):gmatch('[^,]+') do
        w = w:match('^%s*(.-)%s*$')
        if w ~= 'REVERSE' and w ~= 'FORWARD' then cond[#cond + 1] = w end
    end
    return { path = EV .. path, title = title, kind = kind, laps = laps, base = base or title,
        cond = #cond > 0 and table.concat(cond, ', ') or nil }
end

return {
    -- The tab on the game's main menu, next to the game's own tabs
    TabLabel = 'GRAND PRIX',
    -- Tile layout on the tab's page (at 4K one UI unit is about one pixel)
    TabLayout = { TileWidth = 520, TileHeight = 350, Columns = 4, VisibleRows = 3, TextScale = 1.6, FocusScale = 1.04, DimOthers = 0.72 },
    -- The cups page (v0.11): the five planet cups, the Galactic Cup and the title race - 7 tiles, 4 + 3 at the home
    -- page's tile size, no scrolling; v0.21: 8 at 150cc once its title is won (the KESTAR BOOL tile: 4 + 4).
    -- cols / rows / w / h (nil = the TabLayout grid)
    CupsLayout = { cols = 4, rows = 2, w = 520, h = 350 },
    -- v0.23 (TASKS round 3 item 2): the cups page in rows, centred: the five planet cups in one row, then the Galactic
    -- Cup two tiles wide, the title race and (150cc, after its title) Kestar Bool. nil = the CupsLayout grid.
    CupsRows = { { w = 560, h = 380, n = 5 }, { w = 560, h = 380 } },
    -- v0.24: HOME in rows: the four classes as tall posters (a medal per cup on each), RESET small below; the garage
    -- (the start screen) at this tile size, START this tall
    HomeRows = { { w = 600, h = 560, n = 4 }, { w = 600, h = 200 } },
    GarageRows = { w = 470, h = 300, startH = 170 },
    -- v0.24 (owner): the garage is every race's start screen (cup -> garage with START focused -> race). false = the
    -- v0.23 way: a cup starts at once, the GARAGE tile on HOME.
    StartScreen = true,
    -- v0.23: racers' faces on the title race and final boss tiles, by racer key. v0.25 (seen in game 2026-11-11): the
    -- game's large character pictures (Content/Characters/*_Fallback) draw broken through the tile's picture (a white
    -- tile with scraps), so none are listed; the stadium picture stays. Format: { RacerKey = '/Game/...texture' }.
    Portraits = {},
    -- Key that selects the GRAND PRIX tab at the main menu (Backspace / B = back)
    MenuKey = 'F6',
    -- v0.17 (TASKS.md 11): at the first main menu after the game starts, open the GRAND PRIX tab by itself (HOME).
    -- Once per launch: after a race, B or leaving the tab it stays shut.
    -- false = the game's own main menu as before.
    BootToGrandPrix = true,

    -- After a race: cover the main menu with the game's loading screen while it's rebuilt, so the race results lead
    -- straight to the ranking (v0.3.8). false = show the menu as before.
    HideMenuFlash = true,

    -- v0.20 (menu review 5): hide the game's footer (WBP_ActionBar: "Select / C Restart Campaign / Settings") while
    -- the GRAND PRIX tab is up; put back when another tab is picked. Logged as [footer]. false = leave it (still
    -- found and logged once). Note: hiding the prompts does not switch off the game's C key.
    HideFooter = true,
    -- v0.20 (menu review 3): a dark strip behind every tile's small top label and its description, so they read on a
    -- focused (brightened) tile. Logged as [tiles]. false = the tiles as in v0.19.
    TileLabelStrip = false, -- (v0.24, owner: no dark grey bars behind tile text)
    -- v0.21 (owner: "the grey see-through background isn't needed if the text reads fine without it"): the
    -- translucent dark panel behind HOME / the cups page / the garage / the questions. false = none (fully
    -- transparent); true = the v0.20 panel. The standings, the cup result and the title result keep their own picture
    -- backdrop either way (their tables and big lines sit over the menu's busy art). Logged once as [menu] page backdrop.
    PageBackdrop = false,
    -- v0.22: dark grey text on the pages without a picture behind them (the menu's art is pale); false = light text
    DarkText = true,
    -- v0.22: seconds the main menu must be on screen before the tab is added (was ~3 s, a v0.9.0 crash guard)
    TabSettleS = 1.0,

    -- v0.19 (TASKS.md "Next" 2, DESIGN.md §15): cups without the main menu. After a cup race (not the last), the
    -- standings are drawn over the game's own results screen (opaque, the game's table hidden under it) with a NEXT
    -- RACE button left of CONTINUE. CONTINUE goes to the main menu and today's standings page (B there leaves the cup).
    -- v0.19.1: NEXT RACE (pad A / Enter on it, or Key) goes VIA THE MENU: the results go to the main menu the game's
    -- own way, the cover goes up there (no standings page) and the next race launches by itself once the menu has
    -- settled (MenuSettleS). Every cup, the Galactic Cup too. (CrossPlanet is gone: it no longer matters.)
    -- (Reset / LoadTimeoutS / WatchdogS, the v0.19.0 RequestResetRace route, are gone: attic/chain-reset-route.lua.)
    -- ResultsWaitS = how long after you finish to look for the results screen. Panel = where the standings go on the
    -- results screen's canvas (Y from the top, at 4K one unit is about one pixel), their least size, the gap between
    -- NEXT RACE and CONTINUE (ButtonGap), HideGameTable = false to leave the game's table as it is. On = false:
    -- today's flow, nothing in the race world.
    -- v0.21 (owner: "there doesn't need to be a continue button, this is the same as hitting escape and leave cup"):
    -- after a cup race that isn't the last, only NEXT RACE, centred where the two buttons were; the game's CONTINUE is
    -- hidden (HideContinue = false: v0.20's two buttons). B / Escape / Backspace there: the main menu and straight to
    -- "Leave the cup?" (NO = the standings with NEXT RACE). The last race keeps the game's CONTINUE (the cup result).
    ChainRaces = { On = true, Key = 'N', ResultsWaitS = 90, MenuSettleS = 5,
        Panel = { Y = 330, MinWidth = 1700, MinHeight = 1250, ButtonGap = 80, HideGameTable = true, HideContinue = true } },

    -- Lua garbage: collect a little on every tick (KB of work per step) so it never piles up into one big pause
    -- (v0.3.4, race stutter). GcStep = false to switch off for a comparison.
    GcStep = true,
    GcStepKB = 64,

    -- Progression (v0.5, v0.11; DESIGN.md §8). Classes with open = true are open from the start (50cc, 100cc); each
    -- other class opens with a trophy in every planet cup of the class before it (Unlock = 'gold': gold in every one).
    -- The Galactic Cup (final = true) opens at a class with a trophy (or gold) in every planet cup at that class; the
    -- title race with a trophy (or gold) in the Galactic Cup at that class. Anything you have already raced through
    -- stays open. On = false switches every lock off.
    Progression = { On = true, Unlock = 'trophy' },

    -- Speed classes: every part of your vehicle at this level (the AI keeps pace through the game's rubber band)
    Classes = {
        -- parts = every part at this level; abilities = the level of everyone's abilities (yours and the AI's);
        -- mods = how many of your mod slots are open (v0.4, owner: 50cc none - pure driving)
        -- (v0.3.6, owner: four classes - 50cc with no upgrades at all, up to a maxed 200cc. Keys are used in the
        -- save: never change them; the save was converted from the three-class layout, every class moved up one.)
        -- Parts 0 / 3 / 7 / 10 (research 2026-11-10 §200cc: parts are back-loaded, 6 -> 10 was +120 kph; 7 spreads the
        -- top two classes). v0.10 (owner, docs/PHILOSOPHY.md "200cc"): 200cc is an optional extra like Mario Kart's -
        -- parts 9 (was 10), the 150cc AI profile, nothing opens from it. (v0.21: the class blurbs are gone - owner:
        -- less clutter on HOME and the cups page.)
        { key = '50', name = '50cc', parts = 0, mods = 0, abilities = 1, open = true },
        { key = '100', name = '100cc', parts = 3, mods = 1, abilities = 1, open = true },
        { key = '150', name = '150cc', parts = 7, mods = 2, abilities = 2 },
        -- raceList (v0.11) = the class whose race lists this one races (200cc: the 150cc cups at the extra speed)
        { key = '200', name = '200cc', parts = 9, mods = 2, abilities = 3, raceList = '150' },
    },

    -- Points by place in each race (1st first); a racer who doesn't finish scores 0
    Points = { 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 },

    -- Near misses on the standings (v0.12, docs/PHILOSOPHY.md point 4), shown only when this close so they stay
    -- special: RecordSeconds = a finished race within this many seconds of your record at the class ("0.4 S OFF YOUR
    -- RECORD"); TrophyPoints = a cup missing the next trophy colour up by this many points or fewer ("1 POINT FROM
    -- GOLD"). false = off.
    Near = { RecordSeconds = 1.0, TrophyPoints = 3 },

    -- (v0.21: the rival per class is gone - owner, 2026-11-11. An old save's `rivals` is dropped at load.)

    -- The title race (v0.8, title.lua; v0.21 owner): a 1 v 1 on a normal track against the class leader, at the end of
    -- each class. Opens with a trophy in the Galactic Cup at the class (v0.11). The opponent = the best-placed bot in
    -- the final standings of your most recent finished cup at that class (if you won it, the 2nd; else the winner),
    -- saved per class when a cup ends (leader[class] = { name, cup }); the track = the first race of that cup's list at
    -- that class, its normal laps. The grid is cut to the two of you for the race (GridMakeup 2 entrants,
    -- CharacterList.Opponents = that racer: KNOWLEDGE.md §3, RaceFlowSpike B6), put back at the menu. Default = the
    -- opponent (a DA_Racer_ key) before any cup has finished at the class: 50cc Griff Halloran, 100cc Lyren Shok,
    -- 150cc Biddy Blas, 200cc Sen Fira (the campaign's Riff-Raff to Elite tiers); the track then the first planet cup's.
    Title = { On = true, Name = 'TITLE RACE',
        Default = { ['50'] = 'Veteran', ['100'] = 'Star', ['150'] = 'Rager', ['200'] = 'Thrall' } },

    -- The final boss (v0.21, owner): Kestar Bool in the game's Stadium Showdown (6 laps, about 5 minutes; he copies your
    -- build), the old title race. A KESTAR BOOL tile on the cups page of Class once that class's title is won; raced at
    -- that class's parts. Beating him saves `boss` and unlocks him as a racer (Racers, unlockBoss). The event's story
    -- cinematics are taken off for the race and put back (title.lua). On = false: no boss tile.
    Boss = { On = true, Event = EV .. 'Whippet/FINALBOSS/EVT_WHP_SHORTBOSS_FAIR', Name = 'KESTAR BOOL', Opponent = 'Kestar Bool', Class = '150' },

    -- The planets, by the codename in the event paths (Events/Planets/<codename>/...). name and line are the game's
    -- own (PlanetDef). key doubles as the planet cup's key (jakku ... sentinel). Derven has no cup of its own (the
    -- Galactic Cup ends there).
    Planets = {
        Mastiff   = { key = 'jakku',    name = 'Jakku',       line = 'Starship wrecks boil under the scorching heat of this desert world' },
        Dalmatian = { key = 'lantaana', name = 'Lantaana',    line = 'Deadly lava contrasts cool waters on this lush jungle planet' },
        Corgi     = { key = 'ando',     name = 'Ando Prime',  line = 'Jagged cliffs dot the freezing tundra of this ice world' },
        Spaniel   = { key = 'crait',    name = 'Crait',       line = 'A salt world of vast plains and crystalline caverns' },
        Husky     = { key = 'sentinel', name = 'Sentinel I',  line = 'Rivers of acid make this planet hostile to life itself' },
        Whippet   = { key = 'derven',   name = 'Derven Acos', line = 'Home of the Galactic League, where racers face the ultimate challenge' },
    },

    -- Cups of 4 races (full 12-car grids; no knockouts or 1 v 1s). key is used in the save: never change it.
    -- v0.11 (owner, docs/PHILOSOPHY.md "Cups"): one cup per planet, always that planet, with a race list per class -
    --   ['50']  the classic forward layouts (the v0.2-v0.10 planet cups),
    --   ['100'] the reverse layouts where the planet has them, filled up with the planet's other plain tracks (the
    --           old Outer Rim Cup's four went here; Sentinel's own default is reverse, so its 100cc is forward),
    --   ['150'] the conditions: night / wet / overcast / dawn / scorching / snow / mines / storm / blue hour.
    -- 200cc races the 150cc lists (Classes raceList). A cup never races the same base track twice (race(): base).
    -- Every event was in this file before v0.11 (planet, remix, conditions, Outer Rim cups: checked in game or against
    -- the events dump) except four plain layouts read from the UndergroundProto events_dump.txt (2026-11-08:
    -- TeamRaceConfig, grid 12, Vehicle.Standard, laps as below): EVT_DAL_LOOP_B_REV, EVT_DAL_LOOP_B_SHORT_03,
    -- EVT_COR_Loop_A_REV, EVT_COR_Loop_B_REV. Sentinel's forward layouts exist only under an overcast sky.
    -- The Galactic Cup (final = true) races the same four at every class.
    Cups = {
        { key = 'jakku', name = 'JAKKU CUP', art = 'T_UI_FE_Tile_01', races = {
            ['50'] = {
                race('Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD', 'THE WAR FIELDS', 'Circuit', 2),
                race('Mastiff/P2P_A/EVT_MAS_P2P_FWD', "THE GIANTS' GRAVEYARD", 'Sprint', 1),
                race('Mastiff/Loop_B/EVT_MAS_LOOP_B_FWD', 'DEBRIS DUNES', 'Circuit', 2),
                race('Mastiff/Loop_A/EVT_MAS_LOOP_A_SHORT_02', 'FALLEN EMPIRE', 'Short circuit', 6),
            },
            ['100'] = {
                race('Mastiff/Loop_A/EVT_MAS_LOOP_A_REV', 'THE WAR FIELDS (REVERSE)', 'Circuit', 2),
                race('Mastiff/P2P_A/EVT_MAS_P2P_FWD', "THE GIANTS' GRAVEYARD", 'Sprint', 1),
                race('Mastiff/Loop_B/EVT_MAS_LOOP_B_REV', 'DEBRIS DUNES (REVERSE)', 'Circuit', 2),
                race('Mastiff/Loop_B/EVT_MAS_LOOP_B_SHORT_01', 'SCRAP SPIRAL', 'Short circuit', 6),
            },
            ['150'] = {
                race('Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD_DAWN', 'THE WAR FIELDS (DAWN)', 'Circuit', 2),
                race('Mastiff/P2P_A/EVT_MAS_P2P_FWD', "THE GIANTS' GRAVEYARD", 'Sprint', 1),
                race('Mastiff/Loop_B/EVT_MAS_LOOP_B_FWD_HARD', 'DEBRIS DUNES (SCORCHING)', 'Circuit', 2),
                race('Mastiff/Loop_A/EVT_MAS_LOOP_A_SHORT_02_HARD', 'FALLEN EMPIRE (SCORCHING)', 'Short circuit', 4),
            },
        } },
        { key = 'lantaana', name = 'LANTAANA CUP', art = 'T_UI_FE_Tile_02', races = {
            ['50'] = {
                race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_FWD', "GRIFFIN'S FLIGHT", 'Circuit', 2),
                race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_FWD', 'MORO KEHN TUNNELS', 'Circuit', 2),
                race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_01', 'THE PYRODUCTS', 'Short circuit', 5),
                race('Dalmatian/P2P/EVT_DAL_P2P_SHORT_05', 'AHLREN JUNGLE SPEEDWAY', 'Short circuit', 5),
            },
            ['100'] = {
                race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_REV', 'MORO KEHN TUNNELS (REVERSE)', 'Circuit', 2),
                race('Dalmatian/P2P/EVT_DAL_P2P_FWD', 'GEOTHERMAL TOUR', 'Sprint', 1),
                race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_SHORT_03', 'DHUNKRI RIVER CIRCUIT', 'Short circuit', 6),
                race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_FWD', "GRIFFIN'S FLIGHT", 'Circuit', 2),
            },
            ['150'] = {
                race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_FWD_Night', "GRIFFIN'S FLIGHT (NIGHT)", 'Circuit', 2),
                race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_REV_Overcast_Wet', 'MORO KEHN TUNNELS (REVERSE, WET)', 'Circuit', 2),
                race('Dalmatian/P2P/EVT_DAL_P2P_FWD_Night', 'GEOTHERMAL TOUR (NIGHT)', 'Sprint', 1),
                race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_SHORT_03_Overcast_Wet', 'DHUNKRI RIVER CIRCUIT (WET)', 'Short circuit', 5),
            },
        } },
        { key = 'ando', name = 'ANDO CUP', art = 'T_UI_FE_Tile_05', races = {
            ['50'] = {
                race('Corgi/Loop_A/EVT_COR_Loop_A_FWD', 'ICE FIELD CIRCUIT', 'Circuit', 2),
                race('Corgi/Loop_B/EVT_COR_Loop_B_FWD', 'MONASTERY MOUNTAINS', 'Circuit', 3),
                race('Corgi/P2P/EVT_COR_P2P_FWD', 'MOUNTAIN TO SEA', 'Sprint', 1),
                race('Corgi/Loop_A/EVT_COR_Loop_A_SHORT_02', 'VONIUM PIPELINE', 'Short circuit', 4),
            },
            -- (the short 01 has no player-facing name, a developer label only; a finished, lit 5-lap ice circuit on the
            -- Monastery Mountains loop. v0.21: named CLOISTER RUN (owner: "something more on theme", Claude picked) -
            -- records are kept by event path, so the rename changes nothing in the save)
            ['100'] = {
                race('Corgi/Loop_A/EVT_COR_Loop_A_REV', 'ICE FIELD CIRCUIT (REVERSE)', 'Circuit', 2),
                race('Corgi/Loop_B/EVT_COR_Loop_B_REV', 'MONASTERY MOUNTAINS (REVERSE)', 'Circuit', 3),
                race('Corgi/P2P/EVT_COR_P2P_REV', 'DAI BENDU ASCENSION', 'Sprint', 1),
                race('Corgi/Loop_B/EVT_COR_Loop_B_SHORT_01', 'CLOISTER RUN', 'Short circuit', 5),
            },
            ['150'] = {
                race('Corgi/Loop_A/EVT_COR_Loop_A_FWD_Night', 'ICE FIELD CIRCUIT (NIGHT)', 'Circuit', 2),
                race('Corgi/Loop_B/EVT_COR_Loop_B_FWD_Overcast_Snow', 'MONASTERY MOUNTAINS (SNOW)', 'Circuit', 3),
                race('Corgi/P2P/EVT_COR_P2P_FWD_Overcast_Snow', 'MOUNTAIN TO SEA (SNOW)', 'Sprint', 1),
                race('Corgi/Loop_A/EVT_COR_Loop_A_SHORT_02_Overcast_Snow', 'VONIUM PIPELINE (SNOW)', 'Short circuit', 4),
            },
        } },
        { key = 'crait', name = 'CRAIT CUP', art = 'T_UI_FE_Tile_A', races = {
            ['50'] = {
                race('Spaniel/Loop_A/EVT_SPA_Loop_A_FWD', 'CRIMSON MINES', 'Circuit', 2),
                race('Spaniel/Loop_B/EVT_SPA_Loop_B_FWD', 'FORGIL CANYON', 'Circuit', 2),
                race('Spaniel/Loop_B/EVT_SPA_Loop_B_P2P', 'RHODOCHROSITE RUN', 'Sprint', 1),
                race('Spaniel/Loop_A/EVT_SPA_Loop_A_SHORT_01', 'SALT CIRCLE', 'Short circuit', 8),
            },
            ['100'] = {
                race('Spaniel/Loop_A/EVT_SPA_Loop_A_REV', 'CRIMSON MINES (REVERSE)', 'Circuit', 2),
                race('Spaniel/Loop_B/EVT_SPA_Loop_B_SHORT_02', 'CRYSTAL CAVERNS', 'Short circuit', 5),
                race('Spaniel/Loop_B/EVT_SPA_Loop_B_P2P', 'RHODOCHROSITE RUN', 'Sprint', 1),
                race('Spaniel/Loop_B/EVT_SPA_Loop_B_FWD', 'FORGIL CANYON', 'Circuit', 2),
            },
            ['150'] = {
                race('Spaniel/Loop_A/EVT_SPA_Loop_A_FWD_MINES_Night', 'CRIMSON MINES (MINES, NIGHT)', 'Circuit', 2),
                race('Spaniel/Loop_B/EVT_SPA_Loop_B_FWD_MINES', 'FORGIL CANYON (MINES)', 'Circuit', 2),
                race('Spaniel/Loop_B/EVT_SPA_Loop_B_P2P_MINES', 'RHODOCHROSITE RUN (MINES)', 'Sprint', 1),
                race('Spaniel/Loop_B/EVT_SPA_Loop_B_SHORT_02_MINES', 'CRYSTAL CAVERNS (MINES)', 'Short circuit', 5),
            },
        } },
        { key = 'sentinel', name = 'SENTINEL CUP', art = 'T_UI_FE_Tile_01', races = {
            ['50'] = {
                race('Husky/LOOP_A/EVT_HSK_LOOP_A_REV', 'SENTINEL LAKES', 'Circuit', 3),
                race('Husky/LOOP_B/EVT_HSK_LOOP_B_REV', 'CAUSTIC FIELDS', 'Circuit', 3),
                race('Husky/P2P/EVT_HSK_P2P_REV', 'BOOL RIVER RUN', 'Sprint', 1),
                race('Husky/LOOP_B/EVT_HSK_LOOP_B_SHORT_02', 'THE ACID RING', 'Short circuit', 6),
            },
            ['100'] = {
                race('Husky/LOOP_A/EVT_HSK_LOOP_A_FWD_Overcast', 'SENTINEL LAKES (FORWARD, OVERCAST)', 'Circuit', 3),
                race('Husky/P2P/EVT_HSK_P2P_SPEC_SHORT_01', 'MINERAL LOOP', 'Short circuit', 5),
                race('Husky/LOOP_B/EVT_HSK_LOOP_B_FWD_Overcast', 'CAUSTIC FIELDS (FORWARD, OVERCAST)', 'Circuit', 3),
                race('Husky/P2P/EVT_HSK_P2P_SPEC_SHORT_02', 'CORROSION HYPERSPHERE', 'Short circuit', 4),
            },
            ['150'] = {
                race('Husky/LOOP_B/EVT_HSK_LOOP_B_FWD_BlueHour', 'CAUSTIC FIELDS (FORWARD, BLUE HOUR)', 'Circuit', 3),
                race('Husky/P2P/EVT_HSK_P2P_FWD_Overcast', 'BOOL RIVER RUN (FORWARD, OVERCAST)', 'Sprint', 1),
                race('Husky/P2P/EVT_HSK_P2P_SPEC_SHORT_01_ApproachingStorm', 'MINERAL LOOP (STORM)', 'Short circuit', 5),
                race('Husky/P2P/EVT_HSK_P2P_SPEC_SHORT_02_ApproachingStorm', 'CORROSION HYPERSPHERE (STORM)', 'Short circuit', 4),
            },
        } },
        { key = 'galactic', name = 'GALACTIC CUP', art = 'T_UI_FE_Tile_05', final = true, races = {
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_06', 'OVERFLOW RALLY', 'Short circuit', 4),
            race('Corgi/P2P/EVT_COR_P2P_SHORT_05', 'ANDOBI EDGE', 'Short circuit', 4),
            race('Husky/P2P/EVT_HSK_P2P_SHORT_01', 'SKAKOAN GAMBIT', 'Short circuit', 6),
            race('Whippet/KNOCKOUT/EVT_WHP_LOOP_A_FWD_RACE', 'THE GALACTIC GAUNTLET', 'Circuit', 2),
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

    -- Vehicles (v0.15: the racer you pick decides which one, Racers[].vehicle). arch = the game's vehicle archetype
    -- (0 car, 2 bike, 3 skimmer; also the value of URacerDef.PreferredVehicleType); build = the launch build whose
    -- part levels are set for the race and put back after.
    Vehicles = {
        { key = 'car', arch = 0, name = 'LANDSPEEDER', build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base' },
        { key = 'bike', arch = 2, name = 'SPEEDER BIKE', build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Bike_Base' },
        { key = 'skimmer', arch = 3, name = 'SKIM SPEEDER', build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Skimmer_Base' },
    },

    -- Your racer (v0.8, racer.lua): any of the game's named pilots. key = the racer def DA_Racer_<key>
    -- (/Game/Griffin/Narrative/CharacterDefs/Racers/); name = the game's CharacterName (what the HUD and the standings
    -- show); line = one line from the game's bios (v0.14: in the garage's info line when the RACER tile is focused). The first entry is the default and the game's
    -- own pilot (CharacterList.Player = Shade); the pick is kept in the save (racer). A pilot who is one of the 11
    -- opponents takes Shade's place on the grid for the race, so the field stays 12. Keys are the game's: don't change.
    -- v0.15 (TASKS.md A6): vehicle = the racer's own vehicle type (a Vehicles key): the launch build follows the racer.
    -- The game's own field is URacerDef.PreferredVehicleType (read in game 2026-11-11, it matches this table; racer.lua
    -- compares it once per racer at launch and logs a mismatch). Shade drives the base landspeeder (owner). unlockBoss
    -- (v0.21) = locked until you beat the final boss (Boss above: Kestar Bool himself); until then the garage skips him.
    Racers = {
        { key = 'DarkEnigma',          name = 'Shade',          vehicle = 'car',     line = 'The campaign\'s racer' },
        { key = 'Protege',             name = 'Ary Quill',      vehicle = 'car',     line = 'Audacious heir to the Quill racing legacy' },
        { key = 'Mercenary',           name = 'Malis Vazosk',   vehicle = 'bike',    line = 'Racing and mercenary work are one and the same' },
        { key = 'QuietStrength',       name = 'Nik Skandaro',   vehicle = 'car',     line = 'The Bools\' former enforcer, racing for solace' },
        { key = 'Veteran',             name = 'Griff Halloran', vehicle = 'skimmer', line = 'Still in his Imperial Navy armour; flying is what he knows' },
        { key = 'Ghost',               name = 'Goli & 02-R0',   vehicle = 'skimmer', line = 'A meek prodigy from Polis Massa and their companion droid' },
        { key = 'InnerHonour',         name = 'Soren Zaks',     vehicle = 'car',     line = 'A former smuggler redeeming his life on the racetrack' },
        { key = 'Nomad',               name = 'Fola Kanjen',    vehicle = 'skimmer', line = 'From racing farmers\' cattle to the Galactic League' },
        { key = 'ElegantProfessional', name = 'Katja Mox',      vehicle = 'bike',    line = 'Forging her own destiny apart from the disgraced MoxCorp' },
        { key = 'Thrall',              name = 'Sen Fira',       vehicle = 'bike',    line = 'Races for Kestar until her debt to the Bools is repaid' },
        { key = 'Rager',               name = 'Biddy Blas',     vehicle = 'bike',    line = 'Hot-headed; his last shot at a face on a cereal box' },
        { key = 'Star',                name = 'Lyren Shok',     vehicle = 'skimmer', line = 'Celebrity waveskimmer racer after a new start and fans' },
        { key = 'Mentor',              name = 'Sebulba',        vehicle = 'skimmer', line = 'The legend himself, never on the League\'s grid' },
        { key = 'Antagonist',          name = 'Kestar Bool',    vehicle = 'car',     line = 'Galactic League Champion, proud son of the Bool family', unlockBoss = true },
    },

    -- AI strength per class (ai.lua; DESIGN.md §4, docs/research-2026-11-10.md "Difficulty"). Everything is
    -- memory-only and put back at the menu. Enabled = false switches all of it off.
    AI = {
        Enabled = true,
        -- Hidden tuning dial: added to every class's pressure (e.g. 0.25 = every class a notch harder). Keep 0.
        Adjust = 0,
        -- v0.16.1: every pacing write (pacing / catchup below) also goes to the pacing assets RP_Default and
        -- RP_Honest (their PacingSettingsConfig, a second copy of the same scales), put back with DA_AIConfig.
        -- false = DA_AIConfig only (as up to v0.16.0).
        WritePacingAssets = true,
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
        -- v0.18 (AI study 2026-11-11, docs/ai-study-2026-11-11.md): the race reads its pacing from RP_Default, whose
        -- default slowdown (0.3) is what held the field back; with the band off the bots are as quick as a clean
        -- autopilot and steady. So: no catch-up anywhere (a lead you build is yours), speed matching off, and a
        -- "mercy" slowdown for bots ahead of their window. Forced errors stay at 50cc only.
        -- v0.18.1 (check races): 0.5-0.85 barely slowed the bots; 0.3 (the game's own) is the mercy that shows (100cc
        -- best bot ~123 s against ~118). Your car gains more from the class parts than the bots do, so 150 / 200cc go
        -- fully honest (1.0: best bot ~105 s at The War Fields dawn against the owner's 102.4).
        -- v0.21 (owner after a 50cc and a 100cc cup: "catching up after a crash or two was still possible"): a little
        -- less mercy - slowdown 0.3 -> 0.4 at 50cc, 0.3 -> 0.45 at 100cc (study: 0.3 gave the best bot ~123 s at The
        -- War Fields reverse 100cc, 0.5 ~118 s). Catch-up stays 1.0.
        -- v0.21 (owner after a 200cc cup: "200cc is fast and brutal, i crash a lot and still get ~2nd place, so overall
        -- the difficulty could be a little tougher"): from 100cc up the bots no longer ease off while you crash
        -- (AiSlowdownDuringCrash 1.0; the game's: RP_Default 0.9, DA_AIConfig 0.5 - 50cc keeps them), and 200cc a
        -- notch above 150cc (pressure 0.5).
        Profiles = {
            ['50'] = { pressure = -1, pacing = { MaxAiCatchupScale = 1.0, MaxAiSlowdownScale = 0.4 },
                       config = { SpeedMatchingMaxMatchers = 0 } },
            ['100'] = { pressure = 0, pacing = { MaxAiCatchupScale = 1.0, MaxAiSlowdownScale = 0.45, AiSlowdownDuringCrash = 1.0 }, errors = 0,
                        config = { SpeedMatchingMaxMatchers = 0 } },
            ['150'] = { pressure = 0, pacing = { MaxAiCatchupScale = 1.0, MaxAiSlowdownScale = 1.0, AiSlowdownDuringCrash = 1.0 }, errors = 0,
                        config = { SpeedMatchingMaxMatchers = 0 } },
            -- 200cc: the 150cc profile plus pressure 0.5 (v0.21: a notch harsher; was the same as 150cc)
            ['200'] = { pressure = 0.5, pacing = { MaxAiCatchupScale = 1.0, MaxAiSlowdownScale = 1.0, AiSlowdownDuringCrash = 1.0 }, errors = 0,
                        config = { SpeedMatchingMaxMatchers = 0 } },
        },
    },

    -- Tune-ups (v0.8, research 2026-11-10 "Vehicle mods"): the vehicle's mods trimmed to twelve named packages, picked
    -- in place on the garage tile (modsel.lua). Each bundles one to three of the catalogue's affixes (mods.lua keys:
    -- protection and plain playstyle effects only - nothing tagged "check", no pure-speed ones) at their top step;
    -- the class sets how many you fit (Classes[].mods). key is used in the save: never change it. line = what it does,
    -- one line (60 characters at most; v0.14: in the garage's info line when the tile is focused - the tile shows the
    -- name only, ui.lua U.FIT); group = the catalogue group whose picture the tile shows (art.lua).
    TuneUps = {
        { key = 'heat_shield', name = 'HEAT SHIELD', group = 'Status protection', line = 'Immune to Burning and Frozen',
          mods = { 'Conditions_BurningProtection', 'Conditions_FreezeProtection' } },
        { key = 'armour', name = 'ARMOUR', group = 'Shields, surges & slipstream', line = 'Immune to Disrupted; Shielded for the first 10 s',
          mods = { 'Conditions_DisruptedProtection', 'Shielded_GainOnRaceStart' } },
        { key = 'ice_cold', name = 'ICE COLD', group = 'Cooling & heat', line = 'Cooled while airborne; Cooled blocks Corroded',
          mods = { 'Cooled_GainWhileAirborne', 'Cooled_CorrodeProtection' } },
        { key = 'redliner', name = 'REDLINER', group = 'Ramjet', line = 'Ramjet cools while active; Cooled 20 s when Redlining',
          mods = { 'Ramjet_TempCanDropWhileBoosting', 'Ramjet_CooledWhenCritical' } },
        { key = 'ramjet_rider', name = 'RAMJET RIDER', group = 'Ramjet', line = 'No Ramjet heat in the air; 90% resets, no blow-up',
          mods = { 'Ramjet_NoHeatWhileAirborne', 'Ramjet_CriticalResetChance' } },
        { key = 'afterburner', name = 'AFTERBURNER', group = 'Afterburner', line = 'No fuel used in the air; a full tank on landing',
          mods = { 'Afterburner_BetterWhileAirborne', 'Afterburner_RefillOnLanding' } },
        { key = 'brawler', name = 'BRAWLER', group = 'Takedowns', line = 'Takedowns ready the Ramjet and give 4 Energy',
          mods = { 'Takedown_ResetHeat', 'Energy_GainOnTakedown' } },
        { key = 'survivor', name = 'SURVIVOR', group = 'Crashes & recovery', line = 'After a crash: Shielded and Surging for 30 s',
          mods = { 'Crash_ReturnWithShield', 'Crash_ReturnWithSurge' } },
        { key = 'slipstreamer', name = 'SLIPSTREAMER', group = 'Shields, surges & slipstream', line = 'Slipstreaming cools you; 5 s of it starts a Surge',
          mods = { 'Slipstream_gainSurging', 'Cooled_GainWhileSlipstream' } },
        { key = 'firebug', name = 'FIREBUG', group = 'Cooling & heat', line = 'Burning makes 90% less heat and Overcharges you',
          mods = { 'Burning_GainOvercharged', 'Conditions_DecreaseBurningPotency' } },
        { key = 'engineer', name = 'ENGINEER', group = 'Crashes & recovery', line = 'Malfunctions end 200% sooner; a perfect fix restores a Crash',
          mods = { 'SysMalf_ShorterMalfunction', 'CritMalf_PerfectRecoversCrash' } },
        { key = 'tenacious', name = 'TENACIOUS', group = 'Status protection', line = 'Corroded crashes you 200% slower and never chokes you',
          mods = { 'Conditions_CorrodeResistance', 'Corrode_NoLongerChokes' } },

        -- The AI's tune-ups (loadout.lua): per class, per tier, the packages those bots race with; a bot in no tier
        -- (or at a class not listed) gets none. Tiers = the campaign's own ranking (research 2026-11-10: Elite = Sen
        -- Fira, Biddy Blas, Lyren Shok; Challenger = Goli & 02-R0), as DA_Racer_<key> keys (Abilities.Racers).
        -- The bots copy the launch build, so it carries your packages plus theirs at launch and each racer's race
        -- copy loses what isn't theirs at load (yours included). AIExtra = false: the AI only keeps what you also
        -- carry (the launch build = yours only) - the fallback if clearing your own race copy turns out not to work.
        AI = {
            ['150'] = { Elite = { 'heat_shield' } },
            ['200'] = { Elite = { 'heat_shield', 'armour' }, Challenger = { 'heat_shield' } },
        },
        Tiers = { Elite = { 'Thrall', 'Rager', 'Star' }, Challenger = { 'Ghost' } },
        AIExtra = true,
    },
}
