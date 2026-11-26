-- PodTry: launch a podracer race from the main menu on a key and log what the game does (TASKS §1h P1).
-- Keys at the main menu: HOME = Launches[1], PAGE UP = [2], DELETE = [3], PAGE DOWN = the dump (tracks, events, pilots).
local EV = '/Game/Griffin/Gameplay/Events/Plane_Memory/'
local B = '/Game/Griffin/Gameplay/Campaign/Builds/'
return {
    Launches = {
        -- the pod race-memory event on Mos Espa (Beagle), through LaunchQuickRace like every GP race
        { kind = 'quick', event = EV .. 'EVT_BGL_PLANE_RMEM_FWD_01', build = B .. 'PlaneMemories/VBD_MP_PlaneTour' },
        -- the bare track through LaunchCustomRace (TrackTry's route)
        -- (2nd session) Mawhonic Speedway, GMV_Race with its grid make-up set to 8: you + the 7 pod racers, no repeats?
        { kind = 'custom', track = EV .. 'TRAK_COR_PLANE_FWD', grid = 8, build = B .. 'PlaneMemories/VBD_MP_PlaneTour' },
        -- Holdfast's Folly (Lantaana), the bare track, the full-grid mode (how many pods?)
        { kind = 'custom', track = EV .. 'TRAK_DAL_PLANE_FWD', mode = 'GMV_FullGridRace', build = B .. 'PlaneMemories/VBD_MP_PlaneTour' },
    },
    -- the pod field: CharacterList.Opponents replaced by these RacerDefs for the race (put back at the menu); false =
    -- leave the game's own list
    PodPilots = { 'DA_PlaneRacer_Cabbage', 'DA_PlaneRacer_Celery', 'DA_PlaneRacer_Garlic', 'DA_PlaneRacer_Nesodon',
                  'DA_PlaneRacer_Onion', 'DA_PlaneRacer_Pepper', 'DA_Racer_Antagonist' },
    -- your racer (CharacterList.Player, Shade by default) races a pod: its PreferredVehicleType set to 1 for the race
    -- (and Kestar's, if he is in PodPilots); put back at the menu
    LendPods = true,
    -- what the dump loads and describes
    Dump = {
        EV .. 'TRAK_BGL_PLANE_FWD', EV .. 'TRAK_BGL_PLANE_REV', EV .. 'TRAK_COR_PLANE_FWD', EV .. 'TRAK_COR_PLANE_REV',
        EV .. 'TRAK_DAL_PLANE_FWD', EV .. 'TRAK_DAL_PLANE_REV',
        '/Game/Griffin/Gameplay/Events/Plane_Insta/TRAK_INSTA_COR_PLANE_FWD', '/Game/Griffin/Gameplay/Events/Plane_Insta/TRAK_INSTA_COR_PLANE_REV',
        '/Game/Griffin/Gameplay/Events/Plane_Insta/TRAK_INSTA_DAL_PLANE_REV',
        EV .. 'EVT_BGL_PLANE_RMEM_FWD_01', EV .. 'EVT_BGL_PLANE_RMEM_FWD_04', EV .. 'EVT_BGL_PLANE_RMEM_FWD_09', EV .. 'EVT_BGL_PLANE_RMEM_FWD_12',
        EV .. 'EVT_COR_PLANE_RMEM_FWD_03', EV .. 'EVT_COR_PLANE_RMEM_FWD_07', EV .. 'EVT_COR_PLANE_RMEM_REV_06', EV .. 'EVT_COR_PLANE_RMEM_REV_11',
        EV .. 'EVT_DAL_PLANE_RMEM_FWD_02', EV .. 'EVT_DAL_PLANE_RMEM_FWD_08', EV .. 'EVT_DAL_PLANE_RMEM_REV_05', EV .. 'EVT_DAL_PLANE_RMEM_REV_10',
    },
}
