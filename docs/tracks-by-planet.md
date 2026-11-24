# Every track, by planet (2026-11-12)

From the game's own files: every race event under `Gameplay/Events/Planets` in the paks (178 events), read with
`swgr-vehiclelooks/tools/utocdir.py`; names from the Underground and Grand Prix configs. **✓ = used in a Grand Prix
cup today** (config.lua). "Base track" = one layout; its variants are the direction (forward / reverse) and the
conditions. Event paths: `/Game/Griffin/Gameplay/Events/Planets/<Planet>/<Layout>/<EVT name>`.

**v0.26 (random cups):** every race variant below (the eliminators, knockouts, arenas and story / special events
aside) is in its planet's pool (config `Pools`); the ✓ marks the ones raced by v0.25's fixed cups. The full event
list is kept in docs/data/events-2026-11-12.txt.

32 base tracks: Jakku 5, Lantaana 7, Ando Prime 7, Crait 5, Sentinel I 7, Derven Acos 1 (plus its two boss arenas).

## Jakku (Mastiff)
| Track | Kind | Variants in the game |
|---|---|---|
| The War Fields | circuit (Loop_A) | forward ✓, dawn ✓, scorching, reverse ✓, reverse scorching, eliminator |
| The Giants' Graveyard | sprint (P2P_A) | forward ✓ (the only one) |
| Debris Dunes | circuit (Loop_B) | forward ✓, scorching ✓, reverse ✓, reverse scorching; Act 1 / 2 / 3 (story) |
| Fallen Empire | short circuit (Loop_A SHORT_02) | normal ✓, scorching ✓ |
| Scrap Spiral | short circuit (Loop_B SHORT_01) | normal ✓ (the only one) |
Also: the campaign intro (a sunset point-to-point, `TRAK_MAS_P2P_SUNSET`). **Tracks with no event** (TrackDefs only,
LaunchCustomRace): `TRAK_MAS_P2P_SHORT_03` = **Star Destroyer Speedway**, a 5-lap short circuit (dev status "L6 - DESIGN", unfinished; raced via
tools/recon/TrackTry 2026-11-24: ordinary, not a sprint) (+ mines), `TRAK_MAS_P2P_FWD_MINES`.

## Lantaana (Dalmatian)
| Track | Kind | Variants in the game |
|---|---|---|
| Griffin's Flight | circuit (Loop_A) | forward ✓, night ✓, wet (no reverse) |
| Moro Kehn Tunnels | circuit (Loop_B) | forward ✓, night, wet, reverse ✓, reverse night, reverse wet ✓ |
| Geothermal Tour | sprint (P2P) | forward ✓, night ✓, wet; a "shakedown" event |
| The Pyroducts | short circuit (Loop_A SHORT_01) | normal ✓, night, wet |
| Overflow Rally | short circuit (Loop_A SHORT_06) | normal ✓ (Galactic Cup), wet |
| Dhunkri River Circuit | short circuit (Loop_B SHORT_03) | normal ✓, wet ✓ |
| Ahlren Jungle Speedway | short circuit (P2P SHORT_05) | normal ✓, night, wet |
Also: three special car races on Loop_A (1 lap, 1 lap night, multi-lap).

## Ando Prime (Corgi)
| Track | Kind | Variants in the game |
|---|---|---|
| Ice Field Circuit | circuit (Loop_A) | forward ✓, night ✓, snow, reverse ✓, reverse night, reverse snow |
| Monastery Mountains | circuit (Loop_B) | forward ✓, night, snow ✓, reverse ✓, reverse snow |
| Mountain to Sea | sprint (P2P forward) | normal ✓, night, snow ✓ |
| Dai Bendu Ascension | sprint (P2P reverse) | normal ✓, night, snow |
| Vonium Pipeline | short circuit (Loop_A SHORT_02) | normal ✓, night, snow ✓ |
| Cloister Run (our name, v0.21) | short circuit (Loop_B SHORT_01) | normal ✓, snow |
| Andobi Edge | short circuit (P2P SHORT_05) | normal ✓ (Galactic Cup), snow |

## Crait (Spaniel)
| Track | Kind | Variants in the game |
|---|---|---|
| Crimson Mines | circuit (Loop_A) | forward ✓, mines, mines night ✓, reverse ✓, reverse mines |
| Forgil Canyon | circuit (Loop_B) | forward ✓, mines ✓ |
| Rhodochrosite Run | sprint (Loop_B P2P) | normal ✓, mines ✓ |
| Salt Circle | short circuit (Loop_A SHORT_01) | normal ✓, mines |
| Crystal Caverns | short circuit (Loop_B SHORT_02) | normal ✓, mines ✓ |

## Sentinel I (Husky)
| Track | Kind | Variants in the game |
|---|---|---|
| Sentinel Lakes | circuit (LOOP_A) | reverse ✓ (the game's default), forward overcast ✓ |
| Caustic Fields | circuit (LOOP_B) | reverse ✓, forward overcast ✓, forward blue hour ✓ |
| Bool River Run | sprint (P2P) | reverse ✓, forward overcast ✓ |
| The Acid Ring | short circuit (LOOP_B SHORT_02) | normal ✓ (the only one) |
| Skakoan Gambit | short circuit (P2P SHORT_01) | normal ✓ (Galactic Cup) |
| Mineral Loop | short circuit (P2P SPEC_SHORT_01) | normal ✓, approaching storm ✓ |
| Corrosion Hypersphere | short circuit (P2P SPEC_SHORT_02) | normal ✓, approaching storm ✓ |

## Derven Acos (Whippet, the finals)
| Track | Kind | Variants in the game |
|---|---|---|
| The Galactic Gauntlet | circuit | race ✓ (Galactic Cup), knockout (tour 2), knockout (tour 3) |
| The Qualifier | 1 v 1 arena | the mid-boss race |
| Stadium Showdown | 1 v 1 arena | Kestar Bool ✓ (the final boss) |

## Not in the cups: other event types
- **Challenge events on the planet tracks** (`EVT_SHK_...`, about 90): battle (BAT), precision (PRE), PRT and
  ramjet (RAM) events for one vehicle type each, on the same layouts.
- **Rival 1 v 1s** (`Events/Rivalry1v1`, 11): one per rival, each on a planet track (e.g. The Ghost on Debris
  Dunes reverse).
- **Arcade** (`Gameplay/Arcade/Events`, 53): time trials (TT) and precision (PRE) for each vehicle type, plus the
  podracer time trials.
- **Podracing** (`Events/Plane_Memory`, `Plane_PresentDay`, ...): Mos Espa Speedway (BGL), Holdfast's Folly
  (Lantaana), Mawhonic Speedway (Ando), and podracer tracks on Crait, Jakku and Derven; the "memories" campaign
  and present-day races (the podracer cup idea).
