# Other race types as "special rounds" (research, 2026-11-13)

The owner (via the Podracing session, 2026-11-13): research Eliminator and Knockout first as special rounds in cups;
note Takedown and Ramjet for later. Read-only research; nothing built until the owner picks a shape.
**Status: desk research done (this file); the in-game recon (part 2) is waiting for a free desktop.** Tools for it
are in v0.29.2.

## 1. What exists (the game's files: Manifest_UFSFiles_Win64.txt, UndergroundProto/events_dump.txt, the header dump)
| Mode (`ERaceEventModeType`) | Config class | Events | Track | Laps / grid |
|---|---|---|---|---|
| Eliminator (4) | `TimeEliminatorConfig` | **one**: `EVT_MAS_LOOP_A_FWD_ELIMINATOR` | The War Fields (Jakku), forward | 2 / 12 |
| Knockout (5) | `KnockoutRaceConfig` | **two**: `EVT_WHP_LOOP_A_FWD_KNOCKOUT_TOUR2`, `_TOUR3` ("HERE BE DRAGONS") | The Galactic Gauntlet (Derven) | 2 / 12 |
| Takedowns (6) | `TakedownEventConfig` | ~45 shakedowns `EVT_SHK_BAT_<Bike/Car/Skimmer>_<planet>_...` | every planet | 8 grid |
| Ramjet distance (7) | `RamjetDistanceConfig` | ~40 shakedowns `EVT_SHK_RAM_...` | every planet | solo |
| Team race (1) | `TeamRaceConfig` | everything we race today | | 12 |
(Time trial 2, hot lap 3, precision driving 8: the arcade's.)

**So as they stand, special rounds would repeat fast:** one eliminator track, one knockout track.

### How the modes work (header dump)
- **Eliminator** (`FTimeEliminatorSettings`): a grace time, then an elimination timer that shrinks per player out
  (`EliminationTimerPerPlayerEliminated`, a curve), the last car goes each time; `MinRacersForRacePhase` (then it's a
  straight race to the flag), `bEndWithRace`, `MinRaceDistanceMetres`, bonus time for you when you're at the back /
  crash. **Nothing in it is tied to its track.**
- **Knockout** (`FKnockoutRaceSettings`): a list of phases (`EliminationRound` / `RaceRound` / `CinematicRecap`), each
  with its own laps, elimination timer and racers left (`MinRacersForPhaseComplete`), a rolling start; the Gauntlet's
  has a recap cinematic (a soft pointer - never read it from Lua). More tied to its event.
- **Takedowns** (`FTakedownEventSettings`): a number of takedowns to make, target times, a bot tune set; objective
  event, not a placing (KNOWLEDGE: `EventPosition` is not success there; the success read is still unknown).
- **Ramjet distance**: distance in the ramjet from a starting speed; a solo challenge.

### The modes on other tracks: a lead
Each event holds its mode as an object (`EventMode`, e.g. `TimeEliminatorConfig_0`). Swapping a normal event's
`EventMode` for the eliminator's at launch (memory only, put back at the menu - the way we already change the grid)
could make **any track an eliminator**. v0.29.2 `experiment.lua modeFrom` does exactly that, to test.

## 2. Open, for the in-game recon (v0.29.2 tools; owner away)
1. **Does the eliminator launch from the GP flow** (`experiment.lua eventPath`), with our field, loadouts and pilot
   strength? (The Underground launched them.) And a normal event with `modeFrom` = the eliminator: does the mode
   carry over (HUD, eliminations), or crash?
2. **The elimination order** - the scoring blocker (KNOWLEDGE: "logged as DNF so far"). Each racer's
   `PlayerRaceEventComponent.bHasBeenEliminated` (read every 2 s with the field) now logs `[elim] n: <racer>
   eliminated ... (position, fail reasons)` in order. Check: the order matches the game's; the position an eliminated
   racer keeps; the winner finishes normally.
3. **What the results screen shows** for these modes (screenshot), and whether our panel / chain copes (a DNF now runs
   the chain since v0.28.1).
4. The knockout too (`eventPath` = the Tour 2 one), and whether its recap cinematic plays or hangs outside the
   campaign (the Showdown's cinematic had to be taken off in v0.8.1).
Plan: back up save.lua; 2-3 eliminator launches, 1-2 knockout, 1-2 `modeFrom` tries; screenshots; restore.

## 3. Scoring (proposal)
Points by final placing, with the eliminated ranked by when they went out: the first car out is 12th, the last one
eliminated 2nd (or behind the field still racing in the final phase), the winner 1st. Read from the `[elim]` order;
a tie in one 2 s read broken by `EventPosition`. If you're out, your place is fixed at that moment - the cup goes on.

## 4. Shapes to pick from (owner)
- **A. A special round mid-cup:** race 3 of each planet cup at Challenger / Ace is an eliminator (on that planet's
  track, if `modeFrom` works; else only Jakku has one). Points as above.
- **B. The finale:** the Galactic Cup's last race is the knockout at The Galactic Gauntlet (it's already the Derven
  track) - the campaign's own "HERE BE DRAGONS" climax.
- **C. By league style** (docs/league-styles-2026-11-12.md): JUNKER = banger racing -> its special round an
  eliminator (survive the wreckers); ACE -> the knockout finale; CHALLENGER -> straight races (the rivalry).
- **D. Bonus events, no points:** Takedown (8 grid, a takedown target) or a Ramjet run as a one-off challenge
  between cups, with a medal for the target - later, once a success read exists.
Claude's pick: **C** (it gives each league a signature event) with B as Ace's finale, if part 2 shows the modes
launch and the order reads cleanly; otherwise B alone (the one track that needs no mode swap at all).
