# RaceFlowSpike: next race without the menu (B9), two-car grid (B6) (test only)

A test-only UE4SS mod for two spikes in TASKS.md section B. It only reports what happens. Nothing here goes into the
Grand Prix mod. The mod is off unless you install it as shown below.

- **B9** (owner: "the standings at the end of the race, then straight into the next race with no main menu"):
  (a) can we draw a text panel over the game's own race results screen? (b) can the next race start from the race
  world, without going through the main menu?
- **B6** (the rival or class leader as the title-race opponent): can a normal event (The War Fields) run with a
  two-car grid against a chosen opponent (Sen Fira)?

Each spike has its own key and its own log. The settings are in `CONFIG` at the top of `Scripts/main.lua`.

## Install and enable (game closed)

```sh
M="$HOME/.steam/steam/steamapps/common/STAR WARS Galactic Racer/Griffin/Binaries/Win64/ue4ss/Mods"
mkdir -p "$M/RaceFlowSpike"
cp -r ~/Projects/swgr-grandprix/tools/recon/RaceFlowSpike/Scripts "$M/RaceFlowSpike/"
touch "$M/RaceFlowSpike/enabled.txt"
```

To switch it off (game closed): `mv "$M/RaceFlowSpike/enabled.txt" "$M/RaceFlowSpike/disabled.txt"`.

- Logs (appended to, never replaced): `$M/RaceFlowSpike/raceflow-b9.log` and `$M/RaceFlowSpike/raceflow-b6.log`. When
  you're done, copy them back here as `raceflow-b9-<date>.log` and `raceflow-b6-<date>.log`.
- B6 state file: `$M/RaceFlowSpike/b6_state.lua`. It exists only while a B6 change is still to be put back. Never
  delete it while the game is running.

**Key clashes.** TestAutopilot's `F9` forces a garbage collection (a freed-object stress test). With TestAutopilot
enabled, each B9 press also runs a GC. That's harmless if our code is right, but it muddies a crash. For B9 runs,
either disable TestAutopilot or set `CONFIG.KEYS.B9 = 'F7'`. CampaignLogger (disabled) also uses F9 and F10.

## Before you start

- Back up the Grand Prix save (`Mods/GalacticGrandPrix/save.lua`, with its md5) as usual. This spike never touches it,
  but a Grand Prix race that the spike interrupts still gets recorded by the Grand Prix mod.
- Don't run these tests during a Grand Prix **cup**. Use B6's own launch (`F10` / `Ctrl+F10`), or a single Grand Prix
  race. A route that starts a new race from the race world leaves the Grand Prix mod's race watch waiting for the
  menu; it records whatever it last read.

## Run procedure

### B6: two-car grid (F10 at the main menu)

Each `F10` press uses the next entry of `CONFIG.B6.PLAN`. The count starts again at each game start. Run each press
in a new race:

1. Start the game and wait for the main menu (the Grand Prix tab may open by itself: that's fine). Press **F10**.
   **Press 1 = `grid+front`**: the event's grid make-up is summed to 2, and Sen Fira moves to `Opponents[1]` (the list
   keeps all 11 names). The War Fields launches.
2. Watch the grid. How many cars are there, and who is next to you? Take a screenshot on the grid. Finish the race
   or quit, and wait for the main menu: everything is put back (`put back (main menu)` line).
3. Press **F10** again. **Press 2 = `grid+only`**: same grid, and `Opponents` = { Sen Fira } only. This press only
   trims the list if the grid write from step 1 took (the log says so).
4. Main menu, then **F10** a third time. **Press 3 = `only`**: Opponents = { Sen Fira }, grid make-up untouched.
   **Riskiest: run it last** (see the risks below).
5. Copy `raceflow-b6.log` back here.

`Ctrl+F10` = the same launch with nothing trimmed: a plain 12-car War Fields race. It doesn't count as a press. Use it
for B9.

### B9: standings and the next race (F9 in a race)

Each `F9` press uses the next route of `CONFIG.B9.PLAN` (default `A`, then `B`). The count starts again at each game
start. Press 1 tries A, press 2 tries B, and any later press only checks the results screen (part a):

1. Main menu: press **Ctrl+F10** for a plain War Fields race (or start a single Grand Prix race on The War Fields).
   B9's default next event, `EVT_MAS_LOOP_A_SHORT_02`, is on the same Jakku layout, so a restart in the same world
   has a chance.
2. Drive the race (TestAutopilot, or quit to DNF). **The moment the results screen shows, press F9.** The game may go
   on to the main menu by itself about 7 s after the results appear.
   - (a) the spike logs which results widgets are up, adds a gold-on-black text panel ("GRAND PRIX STANDINGS
     (RaceFlowSpike test)" and the finishing order) and logs whether the add took. **Take a screenshot now.**
   - (b) 3 s later, route **A** runs: the next event goes into the race's recipe, then the game's restart. If a
     pause menu is up, that's its RETRY RACE button event; otherwise it's `RacingGameMode:RequestResetRace()`. For
     90 s the spike then watches for one of three outcomes: a new race world (its event is logged), a reset of this
     race world, or the main menu.
   - If route A loads a new race, take a screenshot of the grid and HUD. Do the lap count and the track match
     SHORT_02?
3. Route **B** (second press): get to a results screen again. Finish the race route A loaded, or go back to step 1.
   Then press **F9**: the panel again, then `LaunchQuickRace` is called from the race world on the default front-end
   game mode. **Riskiest step: save the log first.**
4. Optional, after A: set `RESTART = 'pause'` and press F9 **mid-race with the pause menu open** (Esc). That tests
   the pause menu's own RETRY RACE path. In our quick races that button may be hidden (the B1 run saw only EXIT TO
   MAIN MENU and ABANDON TOUR), and the log records its visibility.
5. Optional route **T**: add `'T'` to `PLAN`. It calls `ArcadeSubsystem:TravelToEvent(EVT_ARC_TT_CAR_MAS_A_SHORT_02)`
   from the race world. That subsystem belongs to the game instance, so it exists in a race, unlike the front-end
   game mode. The catch: it only takes arcade events (an arcade time trial).
6. Copy `raceflow-b9.log` back here.

## Log lines

### raceflow-b6.log

| Line | Meaning |
|---|---|
| `reference EVT_WHP_SHORTBOSS_FAIR: grid make-up ...; CustomOpponents n` | the Showdown (a known 2-car grid): how the game itself writes a 1 v 1 |
| `event EVT_MAS_LOOP_A_FWD: grid make-up PlayerChoice x11 (sum 11); CustomOpponents 0; ...` | the normal event's `GridMakeup.Entries[]` (`EntryType` x `NumEntrants`) before any change. `no entries` = the grid size comes from somewhere else (game-mode variant or constants) |
| `constants: GetMaxRacersInAnEvent 12, ...` | `UGfnConstantFunctions` (the game's fixed limits) |
| `CharacterList ...: Player ...; Opponents 11 [1:Protege ...]` | the quick-race opponent list before any change |
| `F10 press N: mode X (originals saved to b6_state.lua)` | the originals are on disk; the changes follow |
| `grid: make-up now ... -> as wanted / NOT as wanted` | the grid write, read back. `added { PlayerChoice, 2 }` = the event had no entries and one was added |
| `Opponents: Thrall to the front ...` / `trimmed to Thrall only ...` | the opponent-list write, read back. `NOT trimmed` = skipped because the grid didn't take |
| `LAUNCH EVT_MAS_LOOP_A_FWD (mode, Car): sent` | `LaunchQuickRace` called (race.lua's launch) |
| `race world ..., standalone=true (our F10 launch, mode)` | the race loaded and is offline |
| `grid at load (x s): recipe racers N: 1:Shade(you)/Car 2:Sen Fira/Bike ...` | **the answer**: `EventRecipeSubsystem.ActiveRecipe.RecipeState.Racers[]` as the race was built (count, pilot, vehicle) |
| `grid at load: stage event ..., mode variant GMV_...` | the recipe's active stage (`FEventRecipe.EventStages[]`) |
| `grid at load: mode variant ... grid make-up ...` | the game-mode variant's own `GridMakeup`, in case that's what sizes the grid |
| `grid 10 s in: race state Racers N: names...; Vehicles N` | `RacingGameState.Racers[]` / `Vehicles[]` after spawn: the cars actually on track |
| `put back (main menu \| before launch \| launch failed \| timeout): grid make-up done -> ...; Opponents done -> ...` | the originals written back from `b6_state.lua`, read back (the file is then removed). `FAILED` = check by hand; a game restart reloads the assets anyway |
| `boot: b6_state.lua is still there` | a crash or a quit mid-race: put back at the first main menu |

### raceflow-b9.log

| Line | Meaning |
|---|---|
| `race recipe at load: event ..., track ..., laps ...` | every race's recipe stage as it loads (the event the race was built from) |
| `F9 press N: route X; race ..., started, finished; flow Owner:State(id)` | the press; `flow` = every `GameFlowStateMachineComponent`'s current state (`Results(15)`, `Racing(5)`, ...) |
| `results widgets: WBP_SimpleRaceResultsScreen_C (...; visibility, IsVisible, IsInViewport) \| ...; ResultsTableWidget = ...` | **(a)**: which results widgets exist, and the results table class the race's mode rules name |
| `panel ADDED: CONTINUE's parent ... (CanvasPanel): children a -> b, slot CanvasPanelSlot, parent ok true, text reads back true, ...` | **(a)**: the panel is in the results screen's tree. Only the screenshot proves it's on screen |
| `panel NOT added: why` / `panel: no WBP_SimpleRaceResultsScreen_C up` | the add failed / F9 wasn't pressed on the results screen |
| `A: next event ...`, `A: subsystem recipe ERI: n stage(s), ActiveStage k` | route A: the target and the game instance's recipe |
| `A: <recipe> stage i before / writes / after` | the swap on each copy (subsystem recipe, race-state copy), read back field by field |
| `A: restart: RacingGameMode:RequestResetRace() called` / `pause menu ... RETRY RACE ...: called` | the restart call |
| `B: LaunchQuickRace(...) on the DEFAULT FrontEndGameMode ...` / `returned` / `FAILED ...` | route B |
| `T: ArcadeSubsystem:TravelToEvent(...)` | route T |
| `route X done; watching 90 s ...` | the watch starts |
| **`NEW RACE WORLD after route X (t s): ..., standalone=...; event ..., laps ...`** | **(b) worked**: a new race world loaded; its event comes from its own recipe |
| `SAME race world changed (...): started a -> b, finished a -> b, LapCount; flow ...; event ...` | this race world was reset in place (or moved on): which event it now holds |
| `MAIN MENU came back t s after route X` | the route went to the main menu (or the results screen moved on by itself) |
| `watch over (90 s): no new race world, no main menu` | nothing happened |
| `put back (main menu): A: subsystem recipe stage i: ... ` / `the subsystem recipe is gone` | A's swap undone on the game instance's recipe (the race-state copy goes with the race world) |
| `loop error ...`, `FAILED ...`, `error ...` | a caught Lua error; the message follows |

## What the dumps say (Griffin.hpp, 2026-11-11)

- **The event field in the recipe:** `UEventRecipeInstance { FEventRecipe recipe; FEventRecipeState RecipeState }`,
  reached through `UEventRecipeSubsystem.ActiveRecipe` (a game-instance subsystem, so it outlives the race world).
  `FEventRecipe.EventStages` is a `TArray<FRaceEventInstance>`, and `FEventRecipeState { int32 ActiveStage;
  TArray<FRecipeRacerSetup> Racers }`. The event itself is **`EventStages[ActiveStage].AuthoredEvent`**
  (`URaceEventDef*`), next to a flattened copy of its data: `TrackDef`, `trackConditions`, `LapCount`, `vehicleType`,
  `RaceEventModeType`, `GameModeVariant`, the cinematic chains. `ARacingGameState` holds its own replicated copy
  (`EventRecipe` + `EventRecipeState_Replication`). `FRaceEventInstance.ExtraWinCriteria` is a soft-pointer array:
  never read it, and never read the struct whole (`GetActiveRecipeEventStage()` / `GetCurrentEventStage()` return
  it by value, so the spike doesn't call them).
- **Restart:** `ARacingGameMode::RequestResetRace()` (also `RequestReturnToMenus()`). The pause menu
  (`WBP_Pause_C`, base of `WBP_PauseRacing_C`) has `Btn_RetryRace` with bound events `..._RetryRace_..._14` and
  `_27`; what they call is in the BP graph, not the dump. `UArcadeSubsystem::RequestRestartEvent()` and
  `TravelToEvent(UArcadeEventDef*)` are the arcade's own restart and launch, from a game-instance subsystem.
  `LaunchQuickRace` exists only on `AFrontEndGameMode`, which has no live instance in a race world.
- **The race's flow states:** `ESimpleRaceGameModeState`: Racing 5, PostRacePhase 6, Outro 14, Results 15,
  RollingRestart 24 (and `URollingRestartRaceState`, the game's in-world restart state).
- **Field size:** `URaceEventDef.GridMakeup` (`FRaceGridMakeup { FText PlayerFacingName; TArray<FRaceGridMakeupEntry>
  Entries }`, entry = `{ ERaceGridEntryType EntryType (Car 0, Plane 1, Bike 2, Skimmer 3, PlayerChoice 4); uint8
  NumEntrants }`). `URaceEventDef.CustomOpponents` (`TArray<FRaceEventCustomRacer>`: `Driver` and `vehicleBuild` are
  soft pointers, so the spike reads only the count). `UGameModeVariantDef.GridMakeup` (the same struct, on the
  variant the stage names). `UCharacterList.Opponents` (`TArray<URacerDef*>`). `UGfnConstantFunctions::
  GetMaxRacersInAnEvent()` (plus `MaxRacersInAnEvent` in a server-config struct, PvP only). No `NumAI` or
  `MaxRacers` field on the event or the racing game mode. After load, the grid is in `RecipeState.Racers[]`
  (`FRecipeRacerSetup { Player, Pilot, vehicleType, VehicleCustomisation }`) and in `ARacingGameState.Racers` /
  `Vehicles`.
- **Results screen:** `WBP_SimpleRaceResultsScreen_C`
  (`/Game/Griffin/UI/Screens/Dev/QuickRace/RaceResults/WBP_SimpleRaceResultsScreen`). It isn't in the header dump
  because the dump was taken at the menu. FreeRace's RETRY button finds `WBP_Common_Btn_Continue` on it and adds its
  button to that button's parent canvas. The table inside is `WBP_Simple_RaceResultsPanel_C` (`ResultsTable_List`, a
  `UEventResultsTableViewModel`). `UGfnRaceEventModeRules.ResultsTableWidget` names the table class per mode.
- **Leads not tried:** `URaceEventDef.NextEventInChain` + `EventProgressToSkipToNextEvent` (the game's own event
  chaining; a soft pointer, so neither read nor written here). `AFrontEndGameMode::TravelToContinueRaceEvent()`
  (front end only).

## Risk per step (highest first)

| # | Step | Crash risk | Save risk |
|---|---|---|---|
| 1 | **B9 route B**: `LaunchQuickRace` on the *default* FrontEndGameMode from the race world. The native code probably reaches the world or game instance through the game mode; on a default object that's null, which may crash. | **high** | low: the race isn't saved by us; the game's own save code may run on a travel |
| 2 | **B6 press 3 (`only`)**: 11+ grid slots with one opponent name. The game may index past the end of the list when it fills the grid. | **high** (on load) | none (data assets; memory only, put back) |
| 3 | **B9 route A**: a reset with a recipe that names another event and track. If the reset re-reads the track in the same world, the route, checkpoints and spawn points no longer match. | medium | low |
| 4 | **B9 route T**: an arcade travel from a quick race. A different flow (arcade time trial, arcade results, arcade best times). | medium | **medium**: arcade personal bests and unlocks are saved by the game (cloud-synced) |
| 5 | **B9 `RESTART = 'pause'`**: the pause menu's RETRY RACE event on a button the menu may hide in this flow. | medium | low |
| 6 | **B6 grid write** (`NumEntrants`, or an entry added when there are none): a struct field in an array on a data asset, written at the menu. | low-medium | none |
| 7 | **B9 (a) panel**: two plain UMG widgets built into the results screen's own tree (FreeRace does the same with a button). They go away with the screen; nothing is kept. | low | none |
| 8 | **B6 `grid+front`**: two entries of `Opponents` swapped (the list keeps its length). racer.lua already does this. | low | none |

Save notes: the spike writes only `b6_state.lua` (its own file). Every game change is in memory: data assets
(`DA_CharacterList`, the event def) and the recipe, all put back at the next main menu or at the next boot, and also
reset by any game restart. The game's campaign save is never touched. The Grand Prix save is untouched, apart from
the Grand Prix mod recording a race it launched itself.

House rules kept: `LoopInGameThreadWithDelay` only. No `RegisterHook`: key binds and the two `NotifyOnNewObject`
callbacks only set flags. No soft pointers or TMaps are read, no UObject is kept between ticks (path + address only),
and every engine call is in `pcall`. A handful of lookups per press: ~6 sweeps for the results probe; at race load
one per tick until the recipe's racers show up (16 at most); one at 10 s. Nothing runs per tick once a race is
under way, except one sweep every 2 s while a B9 route is being watched (90 s).
