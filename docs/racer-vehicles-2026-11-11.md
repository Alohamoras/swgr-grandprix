# Racer vehicles: research for queue item B7 / A6 (2026-11-11, offline half)

The in-game half (one race as Biddy Blas in his own vehicle) was not run: the screen was locked overnight. Everything
below comes from the header dump (`ue4ss/CXXHeaderDump/Griffin.hpp`), the VehicleLooks preset dump
(`~/Projects/swgr-vehiclelooks/VehicleLooks/all_presets.txt`, 191 presets) and the VehicleLooks / Streamline notes.

## The answer in short
- Every racer has exactly one personal vehicle preset. **None is a podracer**: Kestar Bool drives a landspeeder
  (`PRE_Car_Antagonist`), Sebulba a skim speeder (`PRE_Skimmer_Rook_Mentor`). The podracer blocker in A6 is gone.
- A preset is the look only (parts and livery). Handling comes from the build (`VehicleBuildDef` /
  `RacerBuildState`), which the mod already chooses by vehicle type (car 0, bike 2, skimmer 3) and levels per class.
- So "racer = vehicle" is: the racer's vehicle type picks the launch build the mod already has, and the racer's
  preset goes on as your look.

## Racer to vehicle
| Racer | Codename | Vehicle | Preset |
|---|---|---|---|
| Shade | DarkEnigma | Landspeeder (owner: base landspeeder) | `PRE_Car_Beluga_Protagonist` or the plain build |
| Ary Quill | Protege | Landspeeder | `PRE_Car_Orca_Protege` |
| Nik Skandaro | QuietStrength | Landspeeder | `PRE_Car_Hammerhead_QuietStrength` |
| Soren Zaks | InnerHonour | Landspeeder | `PRE_Car_Snook_InnerHonour` |
| Kestar Bool | Antagonist | Landspeeder | `PRE_Car_Antagonist` |
| Malis Vazosk | Mercenary | Speeder bike | `PRE_Bike_Boa_Mercenary` |
| Katja Mox | ElegantProfessional | Speeder bike | `PRE_Bike_Rattlesnake_ElegantProfessional` |
| Sen Fira | Thrall | Speeder bike | `PRE_Bike_Boomslang_Thrall` |
| Biddy Blas | Rager | Speeder bike | `PRE_Bike_Sidewinder_Rager` |
| Griff Halloran | Veteran | Skim speeder | `PRE_Skimmer_Saker_VeteranUpdated` |
| Goli & 02-R0 | Ghost | Skim speeder | `PRE_Skimmer_Pelican_Ghost` |
| Fola Kanjen | Nomad | Skim speeder | `PRE_Skimmer_Condor_Nomad` |
| Lyren Shok | Star | Skim speeder | `PRE_Skimmer_Crow_StarUpdated` |
| Sebulba | Mentor | Skim speeder | `PRE_Skimmer_Rook_Mentor` |

Paths: `/GriffinSharedVehicles/Griffin/Vehicles/<Cars|Bikes|Skimmers>/Presets/PRE_...` (Kestar's checked in
VehicleLooks; the others follow the dump's names). The vehicle type is inferred from the preset name. The game's own
field is `URacerDef.PreferredVehicleType` (a plain enum byte, safe to read from Lua) next to
`PreferredCustomisationForVehicleArchetype` (TMap archetype -> preset class). Reading the byte in game confirms the
table.

## Where the game puts a racer's vehicle in a race
- `FEventRecipeState.Racers[]` = `FRecipeRacerSetup { Player, Pilot (URacerDef), vehicleType, VehicleCustomisation }`
  on `UEventRecipeInstance.RecipeState` and the game state's `EventRecipeState_Replication`. This is the per-race
  list of who drives what in which look.
- Your look: `AGfnPlayerState.VehicleCustomisationComponent` with `Client_SetOverrideVehicleRecipe(presetClass)`;
  FreeRace uses `Server_UpdateVehicleRecipe(FCstSavedVehicleRecipeData)` while the race loads. On the pawn,
  `UCstCustomisationComponent:SetActiveVehicleRecipeFromPreset(presetCDO)`. VehicleLooks v0.2 has code for both
  (`~/Projects/swgr-vehiclelooks/VehicleLooks/Scripts/main.lua`, functions around `wearing` / `loadPreset`), not
  yet proven in a race. A theme swap (VehicleLooks v0.3) was proven but gives parts without the livery colours.

## What the in-game half has to answer (B7, needs the screen unlocked)
1. Read `PreferredVehicleType` on each `DA_Racer_*` at the menu (plain byte) and compare with the table.
2. One race as Biddy Blas: bike build at the class parts, `Client_SetOverrideVehicleRecipe(PRE_Bike_Sidewinder_Rager_C)`
   while the race loads; screenshot. Does the livery come too? Does it survive the race start?
3. If not: try writing `VehicleCustomisation` on your entry in the race's `RecipeState.Racers[]` while loading.
4. Kestar Bool: the same with `PRE_Car_Antagonist` (no podracer needed).

## Risks
- Reading a TMap of class pointers from Lua is untested here; prefer the plain `PreferredVehicleType` byte plus the
  preset table above in config, and never touch soft pointers (`LargePreviewImage`, `ThirdPersonPawn`).
- Loading presets by path: some presets returned nil in VehicleLooks (Beluga_Diorama, FieldEventKits). The 14 above
  are the ones to check first.
