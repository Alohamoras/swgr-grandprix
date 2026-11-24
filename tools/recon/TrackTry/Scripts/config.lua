-- TrackTry: launch a track that has no event of its own (LaunchCustomRace), from the main menu, on a key.
-- Edit, then Ctrl+F4 (or restart the game). Keys: HOME = Tracks[1], PAGE UP = [2], PAGE DOWN = [3], DELETE = [4].
return {
    Tracks = {
        -- the hidden Jakku sprint: a layout on The Giants' Graveyard road with no EVT_ asset
        { path = '/Game/Griffin/Gameplay/Events/Planets/Mastiff/P2P_A/TRAK_MAS_P2P_SHORT_03', condition = 'TrackCondition.Sunset' },
        -- the campaign intro's sunset point-to-point (its event is story-only)
        { path = '/Game/Griffin/Gameplay/Events/Planets/Mastiff/Loop_A/TRAK_MAS_P2P_SUNSET', condition = 'TrackCondition.Sunset' },
        -- The Giants' Graveyard with mines
        { path = '/Game/Griffin/Gameplay/Events/Planets/Mastiff/P2P_A/TRAK_MAS_P2P_FWD_MINES', condition = 'TrackCondition.Sunset' },
        -- the hidden sprint with mines
        { path = '/Game/Griffin/Gameplay/Events/Planets/Mastiff/P2P_A/TRAK_MAS_P2P_SHORT_03_MINES', condition = 'TrackCondition.Sunset' },
    },
    -- the game mode variant from the event list's QuickRaceGameModes: GMV_Race (FreeRace's default) or GMV_FullGridRace
    Mode = 'GMV_Race',
    -- vehicle archetype (0 car, 2 bike, 3 skimmer) and the launch build
    Vehicle = 0,
    Build = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base',
    -- a track's own cinematic chains (intro, pre-race, event complete...) are taken off before launch and put back at
    -- the main menu, so a story track can't bring the menu back dead (KNOWLEDGE.md: Stadium Showdown, rival events)
    ClearCinematics = true,
}
