# Other race types as "special rounds" (research, 2026-11-13)

The owner (via the Podracing session, 2026-11-13): research Eliminator and Knockout first as special rounds in cups;
note Takedown and Ramjet for later. Read-only research; nothing built until the owner picks a shape.
**Status: desk research done; the in-game recon (part 2) done 2026-11-26 (results under §2 "Recon results"); the shape is the owner's (§4).** Tools for it
are in v0.29.2.

## How to pick this up
1. **Install v0.29.2** (`./deploy.sh v0.29.2`, game closed) - it has the research tools; nothing changes without them.
2. **Recon (owner away, ~30 min):** back up `save.lua` (md5) to `~/.local/share/swgr-save-backups/`; launch; at the
   Challenger cups page put an `experiment.lua` in the mod folder and START, one race each:
   - `return { label = "elim", event = "THE WAR FIELDS (ELIMINATOR)", eventPath = "/Game/Griffin/Gameplay/Events/Planets/Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD_ELIMINATOR" }`
   - `return { label = "ko", event = "GAUNTLET KNOCKOUT", eventPath = "/Game/Griffin/Gameplay/Events/Planets/Whippet/KNOCKOUT/EVT_WHP_LOOP_A_FWD_KNOCKOUT_TOUR2" }`
   - `return { label = "mode", event = "SCRAP SPIRAL", modeFrom = "/Game/Griffin/Gameplay/Events/Planets/Mastiff/Loop_A/EVT_MAS_LOOP_A_FWD_ELIMINATOR" }`
   Drive with TestAutopilot (enable it, `armed.txt`; the job-scratch `runheld.sh` / `apwait.sh` pattern, W tap every
   15 s). Read the `[elim]` lines against the game's results screen (screenshot it); note whether the knockout's
   recap cinematic plays or hangs. Restore the save (md5), switch TestAutopilot off, remove `experiment.lua`.
3. **Write the results** into section 2 below, then ask the owner to pick a shape (section 4; OWNER.md question).

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

### Recon results (2026-11-26, owner away; GP v0.40.0 `--dev`, TestAutopilot driving, Challenger, a test copy of the save)
Three races, one each, all offline, no crash, no hang; screenshots in the session (not kept).

| Race | How | What happened |
|---|---|---|
| **Eliminator** (The War Fields) | `experiment.lua eventPath` = `EVT_MAS_LOOP_A_FWD_ELIMINATOR` (mode `TimeEliminatorConfig_0`) | Launched from the GP flow with our field and loadouts. One racer out about every 15 s from 58 s on: 9 out (Sen Fira first ... Nik Skandaro 9th), the last 3 race to the flag; you 1st. **The `[elim]` order is clean** and each racer keeps the position they went out at (12, 11, 10 ...). The game ends on its own screen: a hologram podium of the top 3 and "Eliminator FINISHED" + CONTINUE - no finish-times table. |
| **Knockout** (The Galactic Gauntlet, Tour 2) | `eventPath` = `EVT_WHP_LOOP_A_FWD_KNOCKOUT_TOUR2` (`KnockoutRaceConfig_0`) | Launched and ran 5.5 min to the end, **no hang** (its recap between rounds played or was skipped - nothing stuck). Rounds visible in the timing: 4 out by 70 s, a 48 s break, 5 more by 166 s, then the final; the HUD shows an "AT RISK OF KNOCK OUT" list. At the finish the 2nd and 3rd are ALSO flagged eliminated (positions 2, 3) - **score by position, never by the eliminated flag**. Screens: "FINISHED - You came 1st", then "Galactic Gauntlet FINISHED" with the full order (matches `[elim]` reversed exactly). |
| **Eliminator mode on another track** | `modeFrom` = the eliminator's event; the cup's race (The Giants' Graveyard, a sprint) launched with `TimeEliminatorConfig_0` | **The mode carries over**: eliminations every ~15 s from 54 s, 6 out by your finish (3rd). GP's chain and standings panel attached as for any cup race (the game's table not there - nothing to hide); **the points already follow the elimination order** (eliminated racers keep their position). Side effects to handle in a build: the 3 never-eliminated bots behind you "finished" 90 s later (3:06-3:11, the mode's timeout) and the race set a NEW RECORD on the normal track's record. |

Not tried: the experiment swap (`eventPath`) bypasses the cup run, so the chain stays quiet for the first two ("not a cup
race") - whether our panel copes with the knockout's results screen is untested (the modeFrom race shows the eliminator's
screen takes it). The knockout mode borrowed onto another track (`modeFrom` = the knockout) - its phases and recap are
tied to its event; try before building shape B/C on other tracks.

**What this means for §4:** shape A (an eliminator round mid-cup) works on ANY track through `modeFrom` - the special
round need not be The War Fields; scoring by position is already right; records should be skipped for mode-swapped
races. Shape B (the knockout as the Galactic Cup finale) works on the Gauntlet as it is. The owner picks.

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
