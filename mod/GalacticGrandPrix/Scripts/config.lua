-- Galactic Grand Prix settings: leagues, race pools, cups, vehicles (DESIGN.md §3-4).
local EV = '/Game/Griffin/Gameplay/Events/Planets/'

-- a race in a pool: path, the name shown, the kind, laps (the event's own lap count: events_dump.txt / GPRecon,
-- 2026-11-10; a sprint is 1 lap). The planet comes from the path's first folder (Planets below, gp.lua planetOf).
-- v0.11: base = the track without its direction / conditions ('THE WAR FIELDS (REVERSE, SCORCHING)' -> 'THE WAR
-- FIELDS'; a cup never races one twice), cond = the conditions in the title ('SCORCHING', 'MINES, NIGHT'; nil = none).
local function race(path, title, kind, laps, baseOverride)
    local base, inner = title:match('^(.-)%s*%((.*)%)$')
    local cond = {}
    for w in (inner or ''):gmatch('[^,]+') do
        w = w:match('^%s*(.-)%s*$')
        if w ~= 'REVERSE' and w ~= 'FORWARD' then cond[#cond + 1] = w end
    end
    return { path = EV .. path, title = title, kind = kind, laps = laps, base = baseOverride or base or title,
        cond = #cond > 0 and table.concat(cond, ', ') or nil }
end

return {
    -- v0.29.3 (release pass): the test switches (experiment.lua, logbuilds.txt in the mod folder - AI and race-type
    -- research) only work with DevTools = true. Off for players; `./deploy.sh <tag> --dev` turns it on.
    -- v0.32: track hazards taken out of our races (hazards.lua). Buoys: the Precision run's floating markers load in
    -- every race on The Galactic Gauntlet (our Galactic Cup final) and shove or crash a car passing close - hidden,
    -- collision off, on the events whose path holds one of BuoyEvents ({} = every race). Sweeps every ScanS for
    -- ScanUntilS after the race world came, then every RecheckS (the game can show them again after a rewind).
    Hazards = { Buoys = true, BuoyEvents = { 'EVT_WHP_' }, ScanS = 3, ScanUntilS = 45, RecheckS = 10 },

    DevTools = false,

    -- The tab on the game's main menu, next to the game's own tabs
    TabLabel = 'GRAND PRIX',
    -- Tile layout on the tab's page (at 4K one UI unit is about one pixel)
    TabLayout = { TileWidth = 520, TileHeight = 350, Columns = 4, VisibleRows = 3, TextScale = 1.6, FocusScale = 1.04, DimOthers = 0.72 },
    -- The cups page (v0.11): the five planet cups, the Galactic Cup and the title race - 7 tiles, 4 + 3 at the home
    -- page's tile size, no scrolling; v0.21: 8 at the boss's league once its title is won (the KESTAR BOOL tile: 4 + 4).
    -- cols / rows / w / h (nil = the TabLayout grid)
    CupsLayout = { cols = 4, rows = 2, w = 520, h = 350 },
    -- v0.23 (TASKS round 3 item 2): the cups page in rows, centred: the five planet cups in one row, then the Galactic
    -- Cup two tiles wide, the title race and (Ace, after its title) Kestar Bool. nil = the CupsLayout grid.
    CupsRows = { { w = 560, h = 380, n = 5 }, { w = 560, h = 380 } },
    -- v0.24: HOME in rows: the leagues as tall posters (a medal per cup on each), RESET small below; the garage
    -- (the start screen) at this tile size, START this tall. v0.26: three leagues, wider (760)
    HomeRows = { { w = 760, h = 560, n = 3 }, { w = 600, h = 200 } },
    GarageRows = { w = 470, h = 300, startH = 170 },
    -- v0.24 (owner): the garage is every race's start screen (cup -> garage with START focused -> race). false = the
    -- v0.23 way: a cup starts at once, the GARAGE tile on HOME.
    StartScreen = true,
    -- v0.25: ms after a page appears in which the game's own focus moves are undone (it hands focus to a tile of its
    -- own choosing at once - HOME opened on RESET)
    FocusHoldMs = 1000,
    -- v0.25: a dark drop shadow on tile text (no grey strips since v0.24); false = none
    TileTextShadow = true,
    -- v0.23: racers' faces on the title race and final boss tiles, by racer key. v0.25 (seen in game 2026-11-11): the
    -- game's large character pictures (Content/Characters/*_Fallback) draw broken through the tile's picture (a white
    -- tile with scraps), so none are listed; the stadium picture stays. Format: { RacerKey = '/Game/...texture' }.
    -- v0.31: each racer's face = the 256 px MainIcon texture of their CharacterDef in the game data (DA_Racer_<key>
    -- .MainIcon; read with the vehicle-model repo's grx tool, 2026-11-24). Drawn on the garage's pilot tile, the title
    -- race tile and Kestar's tile (main.lua portrait). Nothing is shipped: the paths are the game's. (The big
    -- *_Fallback previews drew broken on a tile in v0.25; these are the small UI icons.)
    Portraits = (function()
        local CH = '/Game/Griffin/UI/Library/Textures/Content/Characters/'
        return {
            DarkEnigma = CH .. 'T_UI_PlayerChar_4', QuietStrength = CH .. 'T_UI_PlayerChar_1', Veteran = CH .. 'T_UI_PlayerChar_2',
            Nomad = CH .. 'T_UI_PlayerChar_3', InnerHonour = CH .. 'T_UI_PlayerChar_5', ElegantProfessional = CH .. 'T_UI_PlayerChar_6',
            Protege = CH .. 'T_UI_RivalChar_Yara', Mercenary = CH .. 'T_UI_RivalChar_Mercenary', Ghost = CH .. 'T_UI_RivalChar_Ghost',
            Thrall = CH .. 'T_UI_RivalChar_Sen', Rager = CH .. 'T_UI_RivalChar_Ziff', Star = CH .. 'T_UI_RivalChar_Lyren',
            Antagonist = CH .. 'T_UI_Antagonist', Mentor = '/Game/Griffin/UI/Library/Textures/Content/Favors/T_UI_Favor_Mentor_A',
        }
    end)(),
    -- Key that selects the GRAND PRIX tab at the main menu (Backspace / B = back)
    MenuKey = 'F6',
    -- v0.17 (TASKS.md 11): at the first main menu after the game starts, open the GRAND PRIX tab by itself (HOME).
    -- Once per launch: after a race, B or leaving the tab it stays shut.
    -- false = the game's own main menu as before. v0.27.5 (owner): false - the player picks the tab themselves.
    BootToGrandPrix = false,

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
    -- v0.27.5: 0.5 (the v0.9.0 crash was most likely the long-gone CampaignLogger mod; 1.0 if the menu misbehaves)
    TabSettleS = 0.5,

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
        Panel = { Y = 330, MinWidth = 1700, MinHeight = 1250, ButtonGap = 80, HideGameTable = true, HideContinue = true,
            -- v0.27: seconds the game's own results (the finish times) show before the standings panel; 0 = at once
            TimesS = 6 } },

    -- Lua garbage: collect a little on every tick (KB of work per step) so it never piles up into one big pause
    -- (v0.3.4, race stutter). GcStep = false to switch off for a comparison.
    GcStep = true,
    GcStepKB = 64,

    -- Progression (v0.5, v0.11, v0.26; DESIGN.md §8). Leagues with open = true are open from the start (Riff-Raff; v0.27.2 Challenger too - owner: only the top league gated);
    -- each other league opens with a trophy in every planet cup of the league before it (Unlock = 'gold': gold in
    -- every one) - Challenger from Riff-Raff, Ace from Challenger. The Galactic Cup (final = true) opens at a league
    -- with a trophy (or gold) in every planet cup at that league; the title race with a trophy (or gold) in the
    -- Galactic Cup at that league. Anything you have already raced through stays open. On = false switches every lock
    -- off.
    Progression = { On = true, Unlock = 'trophy' },

    -- v0.26 (owner, 2026-11-12, TASKS "Three leagues"): three leagues, named after the game's own racer ranks, replace
    -- the four cc classes. Every part of your vehicle at `parts`; abilities = the level of everyone's abilities (yours
    -- and the AI's); mods = how many tune-up slots are open. v0.27 (owner: the v0.26 speed chevrons read as
    -- progress): tagline = the line on the focused HOME poster (who races here, in the galaxy's words); brief = what
    -- you get, under the league's name on its cups page. key is used in the save (best / records / titles / leader / the cup
    -- run's `class` field, which holds a league key): never change it. The AI profile per league: AI.Profiles below.
    -- parts: one level for every slot, or a table by slot (EVehiclePartSlot: 0 Cornering, 1 Acceleration, 2 Resilience,
    -- 3 Boost, 4 AbilityUsage, 5 Advanced; the stat bars in the same order read CORNERING, AFTERBURNER, RESILIENCE,
    -- RAMJET, BATTERY, DRIFT). v0.27 (owner: Riff-Raff a little slow, not engaging enough): afterburner, ramjet and
    -- battery (energy) at 2, the rest stock.
    -- (Old saves - the cc classes '50' / '100' / '150' / '200' - get a clean start at their first load: gp.lua K.load.)
    Leagues = {
        -- v0.28.3 (owner): JUNKER (was RIFF-RAFF; the key stays 'riffraff' - the save uses it), and the afterburner and
        -- ramjet 2 points more ("racing a piece of junk that can go faster than it probably should"): slots 1 and 3
        -- (Acceleration, Boost - the AFTERBURNER and RAMJET bars by their order on the parts screen) 2 -> 4, Battery 2
        -- v0.29.1 (owner): another +2 - afterburner and ramjet 6
        { key = 'riffraff', name = 'JUNKER', parts = { [1] = 6, [3] = 6, [4] = 2 }, mods = 0, abilities = 1, open = true,
          tagline = 'Scrapyard junk with too much engine',
          brief = 'Hot-rodded junk   -   one ability   -   no tune-ups' },
        { key = 'challenger', name = 'CHALLENGER', parts = 5, mods = 1, abilities = 2, open = true,
          tagline = 'Tuned rigs and pilots out to make a name',
          brief = 'Tuned engines   -   two abilities   -   one tune-up' },
        { key = 'ace', name = 'ACE', parts = 9, mods = 2, abilities = 3,
          tagline = 'The fastest pilots in the galaxy',
          brief = 'Full-power engines   -   three abilities   -   two tune-ups' },
    },

    -- Points by place in each race (1st first); a racer who doesn't finish scores 0
    Points = { 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 },

    -- Near misses on the standings (v0.12, docs/PHILOSOPHY.md point 4), shown only when this close so they stay
    -- special: RecordSeconds = a finished race within this many seconds of your record at the league ("0.4 S OFF YOUR
    -- RECORD"); TrophyPoints = a cup missing the next trophy colour up by this many points or fewer ("1 POINT FROM
    -- GOLD"). false = off.
    Near = { RecordSeconds = 1.0, TrophyPoints = 3, TrophySeconds = 5.0 },

    -- (v0.21: the rival per class is gone - owner, 2026-11-11.)

    -- The title race (v0.8, title.lua; v0.21 owner; v0.26): a 1 v 1 on a normal track against the league leader, at
    -- the end of each league. Opens with a trophy in the Galactic Cup at the league. The opponent = the best-placed bot
    -- in the final standings of your most recent finished cup at that league (if you won it, the 2nd; else the
    -- winner), saved per league when a cup ends (leader[league] = { name, cup, path }); the track = the first race of
    -- that cup run (its path saved with the leader). The grid is cut to the two of you for the race (GridMakeup 2
    -- entrants, CharacterList.Opponents = that racer: KNOWLEDGE.md §3, RaceFlowSpike B6), put back at the menu.
    -- Default = the opponent (a DA_Racer_ key) before any cup has finished at the league: Riff-Raff Griff Halloran,
    -- Challenger Biddy Blas, Ace Sen Fira; the track then the first race of a random draw of the DefaultCup, made once
    -- per league and saved (titleTrack), so the tile shows a stable track.
    Title = { On = true, Name = 'TITLE RACE', DefaultCup = 'jakku',
        Default = { riffraff = 'Veteran', challenger = 'Rager', ace = 'Thrall' } },

    -- The final boss (v0.21, owner; v0.26: after the ACE title): Kestar Bool in the game's Stadium Showdown (6 laps,
    -- about 5 minutes; he copies your build). A KESTAR BOOL tile on the cups page of League once that league's title is
    -- won; raced at that league's parts. Beating him saves `boss` and unlocks him as a racer (Racers, unlockBoss). The
    -- event's story cinematics are taken off for the race and put back (title.lua). On = false: no boss tile.
    Boss = { On = true, Event = EV .. 'Whippet/FINALBOSS/EVT_WHP_SHORTBOSS_FAIR', Name = 'KESTAR BOOL', Opponent = 'Kestar Bool', League = 'ace' },

    -- The planets, by the codename in the event paths (Events/Planets/<codename>/...). name and line are the game's
    -- own (PlanetDef). key doubles as the planet's pool and cup key (jakku ... sentinel; derven = the finals' pool).
    Planets = {
        Mastiff   = { key = 'jakku',    name = 'Jakku',       line = 'Starship wrecks boil under the scorching heat of this desert world' },
        Dalmatian = { key = 'lantaana', name = 'Lantaana',    line = 'Deadly lava contrasts cool waters on this lush jungle planet' },
        Corgi     = { key = 'ando',     name = 'Ando Prime',  line = 'Jagged cliffs dot the freezing tundra of this ice world' },
        Spaniel   = { key = 'crait',    name = 'Crait',       line = 'A salt world of vast plains and crystalline caverns' },
        Husky     = { key = 'sentinel', name = 'Sentinel I',  line = 'Rivers of acid make this planet hostile to life itself' },
        Whippet   = { key = 'derven',   name = 'Derven Acos', line = 'Home of the Galactic League, where racers face the ultimate challenge' },
    },

    -- v0.26 (owner, 2026-11-12, TASKS "Random cups"): the race pool of every planet - every base track in
    -- docs/tracks-by-planet.md with all its race variants (direction and conditions). A cup = 4 tracks drawn at random
    -- from its planet's pool, each with a random variant, never the same base track twice (gp.lua K.draw); the same
    -- rule in every league. Left out: eliminators, knockouts, the 1 v 1 arenas, the story acts, the campaign intro,
    -- every EVT_SHK_ challenge event, the EVT_DAL_CAR_Race_ special car races and the Shakedown event. Every path is
    -- checked against the game's event list (docs/data/events-2026-11-12.txt, test_random_cups). Folder spellings
    -- are the ones raced since v0.2 (the engine's paths are case-insensitive: the list has DALMATIAN, Husky/Loop_A).
    -- kind / laps = display only (the start screen, the title tile's info, the LAUNCH log line, the sprint rule of
    -- standings.lua SD.sprint); the race itself runs the event's own laps. Entries raced before v0.26 keep the laps
    -- read from the events dump; the new variants take their layout's (conditions don't change the lap count).
    -- Records are kept per exact event path.
    Pools = {
        jakku = {
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD', 'THE WAR FIELDS', 'Circuit', 2),
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD_DAWN', 'THE WAR FIELDS (DAWN)', 'Circuit', 2),
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD_HARD', 'THE WAR FIELDS (SCORCHING)', 'Circuit', 2),
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_REV', 'THE WAR FIELDS (REVERSE)', 'Circuit', 2),
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_REV_HARD', 'THE WAR FIELDS (REVERSE, SCORCHING)', 'Circuit', 2),
            race('Mastiff/P2P_A/EVT_MAS_P2P_FWD', "THE GIANTS' GRAVEYARD", 'Sprint', 1),
            race('Mastiff/Loop_B/EVT_MAS_LOOP_B_FWD', 'DEBRIS DUNES', 'Circuit', 2),
            race('Mastiff/Loop_B/EVT_MAS_LOOP_B_FWD_HARD', 'DEBRIS DUNES (SCORCHING)', 'Circuit', 2),
            race('Mastiff/Loop_B/EVT_MAS_LOOP_B_REV', 'DEBRIS DUNES (REVERSE)', 'Circuit', 2),
            race('Mastiff/Loop_B/EVT_MAS_LOOP_B_REV_HARD', 'DEBRIS DUNES (REVERSE, SCORCHING)', 'Circuit', 2),
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_SHORT_02', 'FALLEN EMPIRE', 'Short circuit', 6),
            race('Mastiff/Loop_A/EVT_MAS_LOOP_A_SHORT_02_HARD', 'FALLEN EMPIRE (SCORCHING)', 'Short circuit', 4),
            race('Mastiff/Loop_B/EVT_MAS_LOOP_B_SHORT_01', 'SCRAP SPIRAL', 'Short circuit', 6),
        },
        lantaana = {
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_FWD', "GRIFFIN'S FLIGHT", 'Circuit', 2),
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_FWD_Night', "GRIFFIN'S FLIGHT (NIGHT)", 'Circuit', 2),
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_FWD_Overcast_Wet', "GRIFFIN'S FLIGHT (WET)", 'Circuit', 2),
            race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_FWD', 'MORO KEHN TUNNELS', 'Circuit', 2),
            race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_FWD_Night', 'MORO KEHN TUNNELS (NIGHT)', 'Circuit', 2),
            race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_FWD_Overcast_Wet', 'MORO KEHN TUNNELS (WET)', 'Circuit', 2),
            race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_REV', 'MORO KEHN TUNNELS (REVERSE)', 'Circuit', 2),
            race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_REV_Night', 'MORO KEHN TUNNELS (REVERSE, NIGHT)', 'Circuit', 2),
            race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_REV_Overcast_Wet', 'MORO KEHN TUNNELS (REVERSE, WET)', 'Circuit', 2),
            race('Dalmatian/P2P/EVT_DAL_P2P_FWD', 'GEOTHERMAL TOUR', 'Sprint', 1),
            race('Dalmatian/P2P/EVT_DAL_P2P_FWD_Night', 'GEOTHERMAL TOUR (NIGHT)', 'Sprint', 1),
            race('Dalmatian/P2P/EVT_DAL_P2P_FWD_Overcast_Wet', 'GEOTHERMAL TOUR (WET)', 'Sprint', 1),
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_01', 'THE PYRODUCTS', 'Short circuit', 5),
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_01_Night', 'THE PYRODUCTS (NIGHT)', 'Short circuit', 5),
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_01_Overcast_Wet', 'THE PYRODUCTS (WET)', 'Short circuit', 5),
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_06', 'OVERFLOW RALLY', 'Short circuit', 4),
            race('Dalmatian/Loop_A/EVT_DAL_LOOP_A_SHORT_06_Overcast_Wet', 'OVERFLOW RALLY (WET)', 'Short circuit', 4),
            race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_SHORT_03', 'DHUNKRI RIVER CIRCUIT', 'Short circuit', 6),
            race('Dalmatian/Loop_B/EVT_DAL_LOOP_B_SHORT_03_Overcast_Wet', 'DHUNKRI RIVER CIRCUIT (WET)', 'Short circuit', 5),
            race('Dalmatian/P2P/EVT_DAL_P2P_SHORT_05', 'AHLREN JUNGLE SPEEDWAY', 'Short circuit', 5),
            race('Dalmatian/P2P/EVT_DAL_P2P_SHORT_05_Night', 'AHLREN JUNGLE SPEEDWAY (NIGHT)', 'Short circuit', 5),
            race('Dalmatian/P2P/EVT_DAL_P2P_SHORT_05_Overcast_Wet', 'AHLREN JUNGLE SPEEDWAY (WET)', 'Short circuit', 5),
        },
        -- (Corgi Loop_B SHORT_01 has no player-facing name, a developer label only; a finished, lit 5-lap ice circuit on
        -- the Monastery Mountains loop, named CLOISTER RUN in v0.21 - owner: "something more on theme", Claude picked)
        ando = {
            race('Corgi/Loop_A/EVT_COR_Loop_A_FWD', 'ICE FIELD CIRCUIT', 'Circuit', 2),
            race('Corgi/Loop_A/EVT_COR_Loop_A_FWD_Night', 'ICE FIELD CIRCUIT (NIGHT)', 'Circuit', 2),
            race('Corgi/Loop_A/EVT_COR_Loop_A_FWD_Overcast_Snow', 'ICE FIELD CIRCUIT (SNOW)', 'Circuit', 2),
            race('Corgi/Loop_A/EVT_COR_Loop_A_REV', 'ICE FIELD CIRCUIT (REVERSE)', 'Circuit', 2),
            race('Corgi/Loop_A/EVT_COR_Loop_A_REV_Night', 'ICE FIELD CIRCUIT (REVERSE, NIGHT)', 'Circuit', 2),
            race('Corgi/Loop_A/EVT_COR_Loop_A_REV_Overcast_Snow', 'ICE FIELD CIRCUIT (REVERSE, SNOW)', 'Circuit', 2),
            race('Corgi/Loop_B/EVT_COR_Loop_B_FWD', 'MONASTERY MOUNTAINS', 'Circuit', 3),
            race('Corgi/Loop_B/EVT_COR_Loop_B_FWD_Night', 'MONASTERY MOUNTAINS (NIGHT)', 'Circuit', 3),
            race('Corgi/Loop_B/EVT_COR_Loop_B_FWD_Overcast_Snow', 'MONASTERY MOUNTAINS (SNOW)', 'Circuit', 3),
            race('Corgi/Loop_B/EVT_COR_Loop_B_REV', 'MONASTERY MOUNTAINS (REVERSE)', 'Circuit', 3),
            race('Corgi/Loop_B/EVT_COR_Loop_B_REV_Overcast_Snow', 'MONASTERY MOUNTAINS (REVERSE, SNOW)', 'Circuit', 3),
            race('Corgi/P2P/EVT_COR_P2P_FWD', 'MOUNTAIN TO SEA', 'Sprint', 1),
            race('Corgi/P2P/EVT_COR_P2P_FWD_Night', 'MOUNTAIN TO SEA (NIGHT)', 'Sprint', 1),
            race('Corgi/P2P/EVT_COR_P2P_FWD_Overcast_Snow', 'MOUNTAIN TO SEA (SNOW)', 'Sprint', 1),
            race('Corgi/P2P/EVT_COR_P2P_REV', 'DAI BENDU ASCENSION', 'Sprint', 1),
            race('Corgi/P2P/EVT_COR_P2P_REV_Night', 'DAI BENDU ASCENSION (NIGHT)', 'Sprint', 1),
            race('Corgi/P2P/EVT_COR_P2P_REV_Overcast_Snow', 'DAI BENDU ASCENSION (SNOW)', 'Sprint', 1),
            race('Corgi/Loop_A/EVT_COR_Loop_A_SHORT_02', 'VONIUM PIPELINE', 'Short circuit', 4),
            race('Corgi/Loop_A/EVT_COR_Loop_A_SHORT_02_Night', 'VONIUM PIPELINE (NIGHT)', 'Short circuit', 4),
            race('Corgi/Loop_A/EVT_COR_Loop_A_SHORT_02_Overcast_Snow', 'VONIUM PIPELINE (SNOW)', 'Short circuit', 4),
            race('Corgi/Loop_B/EVT_COR_Loop_B_SHORT_01', 'CLOISTER RUN', 'Short circuit', 5),
            race('Corgi/Loop_B/EVT_COR_Loop_B_SHORT_01_Overcast_Snow', 'CLOISTER RUN (SNOW)', 'Short circuit', 5),
            race('Corgi/P2P/EVT_COR_P2P_SHORT_05', 'ANDOBI EDGE', 'Short circuit', 4),
            race('Corgi/P2P/EVT_COR_P2P_SHORT_05_Overcast_Snow', 'ANDOBI EDGE (SNOW)', 'Short circuit', 4),
        },
        crait = {
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_FWD', 'CRIMSON MINES', 'Circuit', 2),
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_FWD_MINES', 'CRIMSON MINES (MINES)', 'Circuit', 2),
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_FWD_MINES_Night', 'CRIMSON MINES (MINES, NIGHT)', 'Circuit', 2),
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_REV', 'CRIMSON MINES (REVERSE)', 'Circuit', 2),
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_REV_MINES', 'CRIMSON MINES (REVERSE, MINES)', 'Circuit', 2),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_FWD', 'FORGIL CANYON', 'Circuit', 2),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_FWD_MINES', 'FORGIL CANYON (MINES)', 'Circuit', 2),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_P2P', 'RHODOCHROSITE RUN', 'Sprint', 1),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_P2P_MINES', 'RHODOCHROSITE RUN (MINES)', 'Sprint', 1),
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_SHORT_01', 'SALT CIRCLE', 'Short circuit', 8),
            race('Spaniel/Loop_A/EVT_SPA_Loop_A_SHORT_01_MINES', 'SALT CIRCLE (MINES)', 'Short circuit', 8),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_SHORT_02', 'CRYSTAL CAVERNS', 'Short circuit', 5),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_SHORT_02_MINES', 'CRYSTAL CAVERNS (MINES)', 'Short circuit', 5),
        },
        -- (Sentinel's default layouts are the reverse ones; its forward layouts exist only under an overcast sky or at
        -- blue hour, so those titles say FORWARD)
        sentinel = {
            race('Husky/LOOP_A/EVT_HSK_LOOP_A_REV', 'SENTINEL LAKES', 'Circuit', 3),
            race('Husky/LOOP_A/EVT_HSK_LOOP_A_FWD_Overcast', 'SENTINEL LAKES (FORWARD, OVERCAST)', 'Circuit', 3),
            race('Husky/LOOP_B/EVT_HSK_LOOP_B_REV', 'CAUSTIC FIELDS', 'Circuit', 3),
            race('Husky/LOOP_B/EVT_HSK_LOOP_B_FWD_Overcast', 'CAUSTIC FIELDS (FORWARD, OVERCAST)', 'Circuit', 3),
            race('Husky/LOOP_B/EVT_HSK_LOOP_B_FWD_BlueHour', 'CAUSTIC FIELDS (FORWARD, BLUE HOUR)', 'Circuit', 3),
            race('Husky/P2P/EVT_HSK_P2P_REV', 'BOOL RIVER RUN', 'Sprint', 1),
            race('Husky/P2P/EVT_HSK_P2P_FWD_Overcast', 'BOOL RIVER RUN (FORWARD, OVERCAST)', 'Sprint', 1),
            race('Husky/LOOP_B/EVT_HSK_LOOP_B_SHORT_02', 'THE ACID RING', 'Short circuit', 6),
            race('Husky/P2P/EVT_HSK_P2P_SHORT_01', 'SKAKOAN GAMBIT', 'Short circuit', 6),
            race('Husky/P2P/EVT_HSK_P2P_SPEC_SHORT_01', 'MINERAL LOOP', 'Short circuit', 5),
            race('Husky/P2P/EVT_HSK_P2P_SPEC_SHORT_01_ApproachingStorm', 'MINERAL LOOP (STORM)', 'Short circuit', 5),
            race('Husky/P2P/EVT_HSK_P2P_SPEC_SHORT_02', 'CORROSION HYPERSPHERE', 'Short circuit', 4),
            race('Husky/P2P/EVT_HSK_P2P_SPEC_SHORT_02_ApproachingStorm', 'CORROSION HYPERSPHERE (STORM)', 'Short circuit', 4),
        },
        -- the finals: The Galactic Gauntlet's race only (its knockouts and the two 1 v 1 arenas are left out)
        derven = {
            race('Whippet/KNOCKOUT/EVT_WHP_LOOP_A_FWD_RACE', 'THE GALACTIC GAUNTLET', 'Circuit', 2),
        },
        -- v0.30: the Rally Cup's stages, in tour order (one stage per base; the forward Bool River Run gets its own
        -- base so both directions run). Every event here is also in its planet's pool: records are per event path.
        rally = {
            race('Mastiff/P2P_A/EVT_MAS_P2P_FWD', "THE GIANTS' GRAVEYARD", 'Sprint', 1),
            race('Dalmatian/P2P/EVT_DAL_P2P_FWD', 'GEOTHERMAL TOUR', 'Sprint', 1),
            race('Dalmatian/P2P/EVT_DAL_P2P_FWD_Night', 'GEOTHERMAL TOUR (NIGHT)', 'Sprint', 1),
            race('Dalmatian/P2P/EVT_DAL_P2P_FWD_Overcast_Wet', 'GEOTHERMAL TOUR (WET)', 'Sprint', 1),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_P2P', 'RHODOCHROSITE RUN', 'Sprint', 1),
            race('Spaniel/Loop_B/EVT_SPA_Loop_B_P2P_MINES', 'RHODOCHROSITE RUN (MINES)', 'Sprint', 1),
            race('Husky/P2P/EVT_HSK_P2P_REV', 'BOOL RIVER RUN', 'Sprint', 1),
            race('Husky/P2P/EVT_HSK_P2P_FWD_Overcast', 'BOOL RIVER RUN (FORWARD, OVERCAST)', 'Sprint', 1, 'BOOL RIVER RUN (FORWARD)'),
            race('Corgi/P2P/EVT_COR_P2P_FWD', 'MOUNTAIN TO SEA', 'Sprint', 1),
            race('Corgi/P2P/EVT_COR_P2P_FWD_Night', 'MOUNTAIN TO SEA (NIGHT)', 'Sprint', 1),
            race('Corgi/P2P/EVT_COR_P2P_FWD_Overcast_Snow', 'MOUNTAIN TO SEA (SNOW)', 'Sprint', 1),
            race('Corgi/P2P/EVT_COR_P2P_REV', 'DAI BENDU ASCENSION', 'Sprint', 1),
            race('Corgi/P2P/EVT_COR_P2P_REV_Night', 'DAI BENDU ASCENSION (NIGHT)', 'Sprint', 1),
            race('Corgi/P2P/EVT_COR_P2P_REV_Overcast_Snow', 'DAI BENDU ASCENSION (SNOW)', 'Sprint', 1),
        },
    },

    -- Cups of 4 races (full 12-car grids). key is used in the save: never change it. pool = the Pools key a planet cup
    -- draws its races from (v0.26). The Galactic Cup (final = true) draws one race from each of `planets` different
    -- pools of `from`; `last` = a pool whose race always closes it (the finals at Derven Acos, as before v0.26; nil =
    -- every race drawn alike). art = the fallback picture (art.lua A.cup draws the planet's poster).
    -- v0.30 (owner 2026-11-24): the RALLY CUP - every point-to-point road, one stage per route and direction, in tour
    -- order (the rally pool's order); the night / weather variant of each drawn when the cup starts and kept from you
    -- until the stage loads (Rally.HideWeather); the last stage always at night (finale = a word of its event path);
    -- a four-car grid (Rally.Grid: you + 3 rivals drawn from the racers at the start, the same three all cup); the
    -- standings by TOTAL TIME over the stages (cup.lua timed), a DNF = the slowest finisher + Rally.DnfPenaltyS.
    -- rally = true keeps it out of the planet-cup count (progression, the champion) and off the title race's track.
    Rally = { Grid = 4, DnfPenaltyS = 30, GapGuessS = 2, HideWeather = true },
    Cups = {
        { key = 'jakku', name = 'JAKKU CUP', art = 'T_UI_FE_Tile_01', pool = 'jakku' },
        { key = 'lantaana', name = 'LANTAANA CUP', art = 'T_UI_FE_Tile_02', pool = 'lantaana' },
        { key = 'ando', name = 'ANDO CUP', art = 'T_UI_FE_Tile_05', pool = 'ando' },
        { key = 'crait', name = 'CRAIT CUP', art = 'T_UI_FE_Tile_A', pool = 'crait' },
        { key = 'sentinel', name = 'SENTINEL CUP', art = 'T_UI_FE_Tile_01', pool = 'sentinel' },
        { key = 'galactic', name = 'GALACTIC CUP', art = 'T_UI_FE_Tile_05', final = true, planets = 4,
          from = { 'jakku', 'lantaana', 'ando', 'crait', 'sentinel', 'derven' }, last = 'derven' },
        { key = 'rally', name = 'RALLY CUP', art = 'T_UI_FE_Tile_A', rally = true, pool = 'rally', finale = 'Night' },
    },
    -- the races a planet cup draws
    CupRaces = 4,

    -- Abilities (v0.3, DESIGN.md §5). You pick four before a cup (Rule below); the league sets their level, and
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
        -- by their style in the game's data. The same every race; the league sets the level.
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

    -- v0.29 (owner: "adding some rust to existing models to make them look less good (for the junker class)";
    -- docs/custom-vehicle-models-2026-11-12.md): looks per league (looks.lua), applied while each race loads.
    -- patina = the game's own All Rust finish; dirt = 0..1 (the race's own dirt build-up, started high); damage = 0..1
    -- (the crash-damage look: dents, scratches); field = the AI's cars too (false = yours only); againS = the second
    -- pass, seconds after the launch. Leave a lever out to switch it off; Looks.On = false switches all of it off.
    Looks = {
        -- v0.29.1 (owner: "a little overboard" - the dents sit on top of the rust): rust and dirt, no damage
        riffraff = { patina = true, dirt = 1.0, field = true, againS = 12 },
    },

    -- AI strength per league (ai.lua; DESIGN.md §4, docs/research-2026-11-10.md "Difficulty"). Everything is
    -- memory-only and put back at the menu. Enabled = false switches all of it off.
    AI = {
        Enabled = true,
        -- Hidden tuning dial: added to every league's pressure (e.g. 0.25 = every league a notch harder). Keep 0.
        Adjust = 0,
        -- v0.16.1: every pacing write (pacing / catchup below) also goes to the pacing assets RP_Default and
        -- RP_Honest (their PacingSettingsConfig, a second copy of the same scales), put back with DA_AIConfig.
        -- false = DA_AIConfig only (as up to v0.16.0).
        WritePacingAssets = true,
        -- One profile per league key. pressure (-1..2): the rubber band on the game's race tune data, the way its own
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
        -- v0.26 (owner, 2026-11-12): one profile per league - Riff-Raff today's 50cc one, Challenger today's 150cc
        -- one, Ace today's 200cc one (pressure 0.5). (The 100cc profile - mercy 0.45 - went with its class.)
        -- v0.28 (AI driving spike, docs/ai-driving-results-2026-11-12.md; owner: "the same few drivers should be
        -- competitive for the cup"): every bot races a copy of YOUR car, so nothing told the pilots apart. Now each
        -- pilot's car is set at load: their parts levels moved by their tier's number at the league (+2 = about 3-4 s
        -- quicker on a ~110 s race). Fixed - no per-race randomness, no rubber band. Pilots = DA_Racer_<key> -> tier
        -- (a pilot not listed, or you, is left as you); per league: tier -> levels. Strength = false switches it off.
        Strength = {
            Pilots = { Thrall = 'elite', Rager = 'elite', Star = 'elite', Antagonist = 'elite',
                       Ghost = 'contender', Veteran = 'contender', QuietStrength = 'contender',
                       Mercenary = 'weak', Protege = 'weak' },
            riffraff = { elite = 1 },
            challenger = { elite = 2, contender = 1, weak = -1 },
            ace = { elite = 2, contender = 1, weak = -1 },
        },
        Profiles = {
            riffraff = { pressure = -1, pacing = { MaxAiCatchupScale = 1.0, MaxAiSlowdownScale = 0.4 },
                         config = { SpeedMatchingMaxMatchers = 0 } },
            challenger = { pressure = 0, pacing = { MaxAiCatchupScale = 1.0, MaxAiSlowdownScale = 1.0, AiSlowdownDuringCrash = 1.0 }, errors = 0,
                           config = { SpeedMatchingMaxMatchers = 0 } },
            ace = { pressure = 0.5, pacing = { MaxAiCatchupScale = 1.0, MaxAiSlowdownScale = 1.0, AiSlowdownDuringCrash = 1.0 }, errors = 0,
                    config = { SpeedMatchingMaxMatchers = 0 } },
        },
    },

    -- Tune-ups (v0.8, research 2026-11-10 "Vehicle mods"): the vehicle's mods trimmed to twelve named packages, picked
    -- in place on the garage tile (modsel.lua). Each bundles one to three of the catalogue's affixes (mods.lua keys:
    -- protection and plain playstyle effects only - nothing tagged "check", no pure-speed ones) at their top step;
    -- the league sets how many you fit (Leagues[].mods). key is used in the save: never change it. line = what it does,
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

        -- The AI's tune-ups (loadout.lua): per league (v0.26: Challenger = the 150cc lists, Ace = the 200cc), per tier, the packages those bots race with; a bot in no tier
        -- (or at a league not listed) gets none. Tiers = the campaign's own ranking (research 2026-11-10: Elite = Sen
        -- Fira, Biddy Blas, Lyren Shok; Challenger = Goli & 02-R0), as DA_Racer_<key> keys (Abilities.Racers).
        -- The bots copy the launch build, so it carries your packages plus theirs at launch and each racer's race
        -- copy loses what isn't theirs at load (yours included). AIExtra = false: the AI only keeps what you also
        -- carry (the launch build = yours only) - the fallback if clearing your own race copy turns out not to work.
        AI = {
            challenger = { Elite = { 'heat_shield' } },
            ace = { Elite = { 'heat_shield', 'armour' }, Challenger = { 'heat_shield' } },
        },
        Tiers = { Elite = { 'Thrall', 'Rager', 'Star' }, Challenger = { 'Ghost' } },
        AIExtra = true,
    },
}
