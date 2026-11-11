# LookSpike v2: a racer's own look on your vehicle (test only)

Test-only UE4SS mod for TASKS.md B7. Question: can your vehicle wear a racer's own preset look (parts **and** livery
colours) in a Grand Prix race? Nothing here goes into the Grand Prix mod. Off unless you install it as below.

v1 (2026-11-11, log `lookspike-20261111.log`) sent `Client_SetOverrideVehicleRecipe` after the vehicle existed and never
found the vehicle's look component, so the result was unproven. v2 tries four routes, **one per race** (`PLAN` at the
top of `Scripts/main.lua`), and reads the look back after each.

## Install and enable (game closed)

```sh
M="$HOME/.steam/steam/steamapps/common/STAR WARS Galactic Racer/Griffin/Binaries/Win64/ue4ss/Mods"
mkdir -p "$M/LookSpike"
cp -r ~/Projects/swgr-grandprix/tools/recon/LookSpike/Scripts "$M/LookSpike/"
touch "$M/LookSpike/enabled.txt"
```

Switch it off: `mv "$M/LookSpike/enabled.txt" "$M/LookSpike/disabled.txt"` (or remove the folder), game closed.
The log is `$M/LookSpike/lookspike.log` (appended, never replaced; copy it back here as `lookspike-<date>.log`).

## Test plan

Race as **Nik Skandaro on the landspeeder** (the Grand Prix RACER tile; the default preset is his,
`PRE_Car_Hammerhead_QuietStrength`). Start the game, then run four Grand Prix races in one session (one cup, or
single races): race 1 tries C, race 2 B, race 3 A, race 4 O. Take a screenshot of your car on the grid and one after
the start in every race. To test another racer, change `PRESET` (must match the vehicle type you race: a Bike preset
needs the bike) and race that racer's vehicle.

## The routes

| Route | When | What it does |
|---|---|---|
| C | race world appears, before your car is built | your entry in the race's `EventRecipeSubsystem.ActiveRecipe.RecipeState.Racers[]` gets `VehicleCustomisation` = the preset class (a plain class pointer: the same slot the game fills for each bot) |
| B | 4 s after your car shows up | finds your car's `CstCustomisationComponent` (its components by class name, a presentation component's `CustomisationComponent`, or one `FindAllOf` kept only if its owner is your car) and calls `SetActiveVehicleRecipeFromPreset(preset)` |
| A | race world appears | FreeRace's route: `PlayerVehicleCustomisationComponent:Server_UpdateVehicleRecipe(FCstSavedVehicleRecipeData)`. FreeRace sends your saved CUSTOMIZE recipe; we build the struct from the preset (same fields: units, parts, layout, livery / icon / patina tags) |
| O | race world appears | v1's `Client_SetOverrideVehicleRecipe(preset class)`, but before the car is built |

Before anything, the preset's vehicle type is checked against your entry in the race (C, A, O) or your car (B); a
mismatch stops the spike for that race (`STOP:` line). Everything is put back at the next main menu.

## Log lines

| Line | Meaning |
|---|---|
| `LookSpike v2.0 loaded; preset ...; plan C \| B \| A \| O` | the mod started; the plan by race number |
| `preset loaded: recipe "..."` | the preset loaded at the menu (5 s after start). `did NOT load` = wrong path |
| `race N: world ..., standalone=true, plan X` | a race world appeared; route(s) X will be tried. `plan done` = past the list, nothing tried |
| `C: race recipe ..., 12 racers (* = you): i:Pilot/Type/Preset ...` | every racer's entry: the presets the bots get (the `*` entry is yours) |
| `C: your entry i VehicleCustomisation A -> B: written, reads back B` | C's write and its read-back. `your vehicle exists already at the write: true` = it may have come too late |
| `your vehicle: VBP_Car_C_0 (Car), x s after the race world; wears "..."` | your car appeared; `?` = its look component isn't one of its own components |
| `B: VBP_... has n components: ...` | every component class on your car (the v1 mystery: is the look component there?) |
| `B: CstCustomisationComponent i/n ... owner ... <- yours` | the `FindAllOf` fallback; `<- yours` = the one used |
| `B: component ... wears "..."`, `SetActiveVehicleRecipeFromPreset sent`, `now wears "..."` | B's call and the recipe name right after it |
| `A: saved CUSTOMIZE recipes before: Car=...` | your cloud-saved CUSTOMIZE recipes, by name only (read, never written) |
| `A: player state holds "..."; sending "..." (n units, n parts, layout, livery ...)` | what A sends; `player state now holds` = the recipe after the call |
| `O: Client_SetOverrideVehicleRecipe(...) sent (vehicle built already: ...)` | O's call |
| `check (after X): player state holds "..."; vehicle ... wears "..." (want "...") -> ON / not on / unknown` | the read-back 3 s after each route. `ON` = the car's active recipe is the preset's. Later routes in the same entry are skipped once ON |
| `check (25 s after your vehicle showed up) ...` | the same after the countdown: did the look survive the start? |
| `put back: C: entry i VehicleCustomisation -> ...: done` / `the race recipe is gone` | C undone at the main menu (or freed with the race: nothing to undo) |
| `put back: A/O: ... saved CUSTOMIZE recipes now: ... (unchanged)` | proof A / O didn't touch your saved recipes. **`WARNING: CHANGED`** = they did: tell the owner before the game saves to the cloud |
| `FAILED ...`, `error ...`, `loop error` | the call raised a Lua error (caught); the message follows |

`ON` reads only the recipe **name**; the screenshot is the real answer.

## What a screenshot shows if it worked

The base landspeeder (or your own CUSTOMIZE look) is replaced by Nik Skandaro's Hammerhead: different body parts
(nose, engines, fins) **and** his livery colours and markings, the way his car looks when he races as a bot. Parts
without colours (plain grey) = the theme-swap result VehicleLooks already got: only half a success. No change on
screen while the log says `ON` = the recipe changed but the car wasn't rebuilt.

## Crash risk (highest first)

1. **A**: the least-tried path: a Lua table turned into a struct holding arrays of structs. A half-built struct could
   give the game a broken recipe. Also, if the game files the recipe as your saved one, it could reach the cloud
   save (the `put back: A/O` line checks).
2. **B**: rebuilds a moving car's parts in the race (collision and sensors come from the parts). Mid-race rebuilds
   are what the game does only in the garage. Runs on the grid (4 s after the car shows up).
3. **C**: one plain class pointer written before the car is built, in the same list the game fills for the bots.
4. **O**: the v1 call, already sent once in a race without harm; only the timing is new.

House rules kept: `LoopInGameThreadWithDelay` only, no `RegisterHook` (two `NotifyOnNewObject` callbacks only set a
flag), no soft pointers or TMaps read, no UObject kept between ticks, every call in `pcall`, a handful of lookups per
race (one race-world sweep every 2 s at the menu).
