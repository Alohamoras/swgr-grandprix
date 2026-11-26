# Podracing recon (TASKS §1h P1), 2026-11-25

Owner away; test copy of the GP save (the owner's backed up with its md5 in `~/.local/share/swgr-save-backups/away-20261125/`).
Tool: `tools/recon/PodTry` (v0.1.0, TrackTry's pattern: a key at the main menu launches, a 2 s read logs the race,
everything it changed is put back when the main menu returns). Log: `Mods/PodTry/podtry.log`. TestAutopilot armed.
Three pod races, all offline (`IsStandalone` true), no crash, the main menu back every time.

## The answer in one paragraph

**Podracers launch and race fine from our own Lua, and the route for a GP pods cup is `LaunchCustomRace` on the bare
pod tracks** (archetype 1 = `VA_Plane`, game mode `GMV_Race`, build `VBD_MP_PlaneTour`): you race as your own pilot
in their pod (Shade = MythP3, Kestar = Northropi) once their `PreferredVehicleType` is set to 1 for the race, and the
field is drawn from `CharacterList.Opponents`, which we set to the pod pilots. The finish, the positions and every
racer's `EventFinishTime` read exactly as in a car race, the results screen is the same "Race FINISHED" screen, so
GP's standings panel and chain should work unchanged. **Grid: `GMV_Race`'s own `GridMakeup.Entries[1].NumEntrants`
set to 8 (it is 5) gives you + the 7 pod racers, no repeats** (race 4; put back at the menu).

## What was launched

| # | Route | What | Grid | You | Result (autopilot) |
|---|---|---|---|---|---|
| 1 | `LaunchQuickRace(VA_Plane, EVT_BGL_PLANE_RMEM_FWD_01, VBD_MP_PlaneTour)` | "Memories of Mos Espa" (a campaign flashback event) | 6: the event's 5 `CustomOpponents` | **Sebulba** (`DA_Racer_Mentor`, Nesodon pod) - the event decides; our Opponents ignored | 1st, 2:34.38; field 2:37.6-2:40.8 |
| 2 | `LaunchCustomRace(VA_Plane, GMV_Race, TRAK_BGL_PLANE_FWD, Afternoon.Dry, VBD_MP_PlaneTour)` | Mos Espa Speedway, bare track | 5: you + 4 of our 7 (Sebulba, Ody Mandrell, Gasgano, Dud Bolt) | **Shade in his MythP3 pod** (`PreferredVehicleType` 0 -> 1, put back) | 1st, 2:34.72; field 2:37.2-2:44.3 |
| 3 | same, `GMV_FullGridRace`, `TRAK_DAL_PLANE_FWD` | Holdfast's Folly | 12: our 7 repeated to fill (2x Gasgano, Ben Quadinaros, Teemto, Ody) + Kestar in Northropi | Shade / MythP3 | 5th, 2:45.51; field 2:42.5-3:01.8 |
| 4 | `GMV_Race` with its grid make-up 5 -> 8, `TRAK_COR_PLANE_FWD` | Mawhonic Speedway | **8: you + all 7, no repeats** (Ody Mandrell, Ben Quadinaros, Gasgano, Teemto Pagalies, Dud Bolt, Kestar Bool, Sebulba) | Shade / MythP3 | 1st, 2:30.16; field 2:32.9-2:43.2 |

The game's quick-race modes (`GfnEventList.QuickRaceGameModes`): `GMV_MultiVehicleRace` "Multi Vehicle Race" grid
[4,4,4], `GMV_Race` "Single Vehicle Race" [5], `GMV_FullGridRace` "Race [FULL GRID]" [12], `GMV_Eliminator` [4,4,4]
(mode 4).

Your pawn was `VBP_Plane_Memory_C` every time (FreeRace: the `PlaneMemories` builds spawn the scenario pod, faster than
the tier builds' `VBP_Plane`). The 75 % perfect start of the bots was visible: they led off the line.

## The pod tracks (6 layouts, all 3 laps, all circuits)

| Track asset | Name | Planet | Conditions | Dev status |
|---|---|---|---|---|
| `Plane_Memory/TRAK_BGL_PLANE_FWD` | Mos Espa Speedway | Beagle (Outer Rim) | Afternoon.Dry, Sunset (+ .MEM) | (none) |
| `Plane_Memory/TRAK_BGL_PLANE_REV` | Mos Espa Speedway (reverse) | Beagle | none listed | L5 - LD Blockout [IN PROGRESS] - FreeRace: never finishes loading; leave out |
| `Plane_Memory/TRAK_COR_PLANE_FWD` | Mawhonic Speedway | Corgi (Ando Prime) | Afternoon.Dry, Overcast.Snow (+ .MEM) | L6 - DESIGN REFINEMENT |
| `Plane_Memory/TRAK_COR_PLANE_REV` | Mawhonic Speedway (reverse) | Corgi | same | L6 - ART BLOCKOUT |
| `Plane_Memory/TRAK_DAL_PLANE_FWD` | Holdfast's Folly | Dalmatian (Lantaana) | Afternoon.Dry, Overcast.Wet (+ .MEM) | L5 - DESIGN - In progress |
| `Plane_Memory/TRAK_DAL_PLANE_REV` | Holdfast's Folly (reverse) | Dalmatian | same | L5 - DESIGN - "Requires high level design of play" |

`Plane_Insta/TRAK_INSTA_*` are copies of the COR / DAL ones (same internal names). `Plane_MP/*` is multiplayer: never
touched (house rule). The pod arcade builds `VBD_ARC_*_PLANE_*` name SPA / MAS / WHP plane layouts too (arcade time
trials only; not looked at). Note the `.MEM` conditions (the flashback look) - a cup should pick the plain ones.

## The pod events (12 "memories", campaign flashbacks)

All `Plane_Memory/EVT_*_PLANE_RMEM_*`: 6-pod grid, 5 `CustomOpponents`, 3 laps (FWD_12 "The Harder They Fall": 5),
`TeamRaceConfig`, an `IntroCinematic` (`CINC_TrackIntro_*_MemoryEvent`) and `EventCompleteCinematicChain`
(`CINC_FinishedRace_Memory`) - both cleared for our launch and put back. Names: Memories of Mos Espa, Day of the Flame
Vents, A Pretender Approaches, The Harder They Fall (BGL); Hot Shot, Fear and Respect, Other Weapons Too, The More
They Come (COR); Legends of Speed, Explosive Inspiration, Whatever It Takes, Two Birds With One Shockwave (DAL).
**Not for a cup:** you are always Sebulba and the field is fixed by the event; changing `CustomOpponents` means
touching soft pointers (`Driver`) - a known crash.

## The pod cast

`/Game/Griffin/Narrative/CharacterDefs/Racers/DA_PlaneRacer_<veg>` (all `PreferredVehicleType` 1): Cabbage = **Dud
Bolt** (Cretornis), Celery = **Gasgano** (Hexing), Garlic = **Teemto Pagalies** (Sordes), Nesodon = **Sebulba**
(Nesodon), Onion = **Ben Quadinaros** (Dearc), Pepper = **Ody Mandrell** (Tarchia); each has an `Aged` twin (the
present-day version). Plus the car racers who own a pod: Shade (MythP3), Kestar Bool (Northropi), and in FreeRace's map
Ghost / Nomad (Hexing), Mentor (Nesodon). Names come through `PlayerNamePrivate` like the car racers'. So a unique
field is **you + 6 pod pilots + Kestar = 8**.

## What GP needs (P2-P7)

- Launch: `LaunchCustomRace(VA_Plane, GMV_Race, TRAK, {TagName = condition}, VBD_MP_PlaneTour, nil)` - GP has only
  `LaunchQuickRace` today (race.lua); TrackTry's call works as is. Clear the track's six cinematic chains (TrackTry /
  PodTry pattern), put back at the menu. `R.fits` must accept `Vehicle.Special.Plane` (and two DAL/COR tracks say
  just `Vehicle.Special`).
- The field: `CharacterList.Opponents` = the 6 pod pilots + Kestar; your racer's and Kestar's `PreferredVehicleType`
  = 1 for the race (racer.lua already swaps the character list and puts it back).
- **Grid size - settled:** `GMV_Race`'s `GridMakeup.Entries[1].NumEntrants = 8` before launch (title.lua's `setEntries`
  pattern), put back at the menu -> you + the 7 pod racers. Points: the first 8 of `Points` (15 ... 5).
- The race read (positions, finish times, best lap, the `[gaps]` line), the results screen and the chain panel are
  the car race's: nothing new to read.
- Pace: the autopilot won 3 of 4 (by 2.8-10 s); at Holdfast's Folly in a 12 field it was 5th. The bots got a
  big start (perfect starts); a pod grace of 10 s (FreeRace) is worth having. Pacing is the owner's P8.

## KNOWLEDGE.md rows added

§3 "A podracer race launches" and §4 "the pod cast" (2026-11-25).

## PL0 (2026-11-26): abilities, parts and the ramjet on pods (TASKS §1h-L)

Owner away; test save (the owner's GP save and the game's SaveGames backed up with md5s in
`~/.local/share/swgr-save-backups/pods-boost-20261126/`). GP dev build (podrecon.lua, experiment.lua switches
`podRecon / podPicks / podEquip / podFire / podLoadout / podAiuse / podLevels`), TestAutopilot driving, PRO step,
a fresh game per pod race (TestAutopilot cannot arm a second pod race in one session).

| Race | Pilot, track | Switches | Result |
|---|---|---|---|
| 1 | Fola, Mos Espa | your picks onto the pod build, fire, read the field | 1st 2:34.83; field 2:35.2-2:49.2 |
| 2 | Sebulba, Mos Espa | your picks onto your **race copy** at load, fire, the field given kits | 1st 2:36.00; field 2:42.0-2:59.1, 7 racers |
| 3 | Goli, Mawhonic | pod parts 0 | autopilot never armed ("your car has no Autopilot ability"), killed; no time |
| 4 | Fola, Mos Espa | pod parts 10 | 3rd 2:17.01 (top speed 1400 kph, 995 in race 1); Sebulba 2:05.25, field to 2:31.7 |

- **The pod build `VBD_MP_PlaneTour` has no ability slots** (0; levels 0=0 1=2 2=1 3=0 4=0 5=0, one affix
  `AFXCustom_LotsOfBattery`, 6 affix slots): writing abilities into it does nothing.
- **Your pod's race copy has 4 ability slots** (`GfnPlayerState.RacerBuildState.VehicleBuilds[].AbilitySlots`, as for
  cars). Ability classes written there while the race loads become your abilities: race 2 wrote Multi-Bolt II,
  Surging Shield II, Overtaking Surge II (slot 1 was TestAutopilot's), and every `Server_Trigger(true)` took the fired
  one to active (11 fires).
- **The pod racers fire kits once given them** (loadout.lua's `equip` on their race copies, as for cars): race 2, about
  20 uses - Disruptor, Mine, Shield, Surge. Without kits (race 1) they carry and fire nothing.
- **Pod parts work, and the field gets them too** (every pod races a copy of the launch build, as cars do): all six
  parts at 10 = 17.8 s faster for the same pilot on Mos Espa, and the whole field faster with it. Parts at 0 broke
  the autopilot's ability (race 3) - not tried again.
- **The ramjet:** every pod has a `Ramjet` and an `Afterburner` component (8 of each in an 8-pod race), the ramjets
  read Ready (1) most of the race - but the autopilot never used one in four pod races, and every pod's
  `VehicleBoostComponent.BoostState` read 2 (afterburner) all race, while the same autopilot in a car goes into
  ramjet (state 4) within 10 s. So the ramjet may simply not engage on a pod (the owner: "there's no ramjet"). Only a
  real pad can tell whether the boost button does anything more on a pod.
- **The pilots:** Goli flies her own green Hexing (screenshot, race 3), Fola her Hexing, Sebulba his Nesodon with no
  twin on the grid (race 2: you + 6).
