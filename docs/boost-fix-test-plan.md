# Boost fix: the test plan for later (TASKS §1k)

Written 2026-11-26 so the context survives. **Read first:** `docs/boost-recon-2026-11-26.md` (what the first round
found) and the KNOWLEDGE.md rows "Boost reply" / "Pod parts and the ramjet" (swgr-underground).

## The problem, in the owner's words

> "explore why the racers in front of you speed up so quickly when you ramjet and afterburner, this is the most annoying
> part of the game, it should feel faster to boost and the field just adapts automatically without boosting"

The goal is a **feel**: your boost should gain you ground on the racer ahead. Whatever we measure, the owner's own race
decides.

## What we know (2026-11-26, 5 car races + 6 pod races)

- The racer directly ahead goes into ramjet within 3 s of yours, **5 of 5 times** it wasn't already in one (~+100 kph).
- **Confound:** TestAutopilot ramjets only twice a lap-pair (~10 s and ~37 s on THE WAR FIELDS), on the straights where
  every bot ramjets anyway. So "it replied to you" and "it boosts on this straight" look the same. Nothing proves a
  reply yet.
- `AllowAIToContinuePlayerBoost = false` (AI config): no change.
- Speed matching zone off: no case to judge (the racers ahead were already in ramjet).
- **The driving styles `DS_Car_Base / DS_Bike_Base / DS_Skimmer_Base` also drive TestAutopilot.** Any lever on the
  style changes your autopilot too, so an autopilot race can't test a style lever. A human driver isn't driven by the
  style, so for the owner a style lever changes only the bots.
- `MinRacePacingFactorForBoost` = **0.99** in all three styles (a bot may boost whenever its pacing factor is about 1+,
  i.e. nearly always). At 100 the bots still finished ~as fast (they don't need the ramjet much); the autopilot fell to
  523 kph top speed.
- Our league profiles already have catch-up off (`MaxAiCatchupScale` 1.0) and `SpeedMatchingMaxMatchers` 0. At
  CHALLENGER pressure is 0, so the league adds no lift to the bots' minimum time ahead; at ACE (pressure 0.5) it does.
- `EBoostState` 0 none, 1 to afterburner, 2 afterburner, 3 to ramjet, 4 ramjet. `ERamjetState` 1 ready, 2 engaging, 3
  active, 6 overheated. Pods: `BoostState` stays 2 all race and the autopilot never ramjets (a pod ramjet may not exist
  in practice).

## The levers

| Key | Lever | Where (written by the dev build, put back at the menu) | Testable by autopilot? |
|---|---|---|---|
| A | Bots ramjet less readily: `MinRacePacingFactorForBoost` 0.99 -> 1.1 / 1.3 / 2 | experiment `styles = { Car = {...}, Bike = {...}, Skimmer = {...} }` | **No** (moves the autopilot too) - owner only |
| B | Speed matching zone off: `EnableSpeedMatchingZone = false`, `AllowSpeedMatchingWhenBoosting = false` | experiment `config = {...}` (booleans supported since 2026-11-26) | Yes, but needs bots behind-then-ahead |
| B2 | The zone's tuning instead of off: `SpeedMatchingTimeAhead`, `SpeedMatchingSpeedLag`, `SpeedMatchingMaxTimeMatching`, `SpeedMatchingCooldown` (on `DA_AIConfig`) | experiment `config` | Yes |
| D | The window: our lift of the minimum time ahead (`AiMinTimeAheadModifier`; ACE only) | experiment `ops = { AiMinTimeAheadModifier = 'game', AiMinTimeAheadMultiplier = 'game' }` | Yes (needs ACE: unlocked on a test save) |
| E | Other style boost fields: `MinBoostTime`, `MinTimeBetweenBoosts`, `MinThrottleForBoost`, `BoostTopSpeedThresholdRatio` | experiment `styles` | No (same as A) |

## Tests to run

> **2026-11-26 round 2 done (docs/boost-recon-2026-11-26.md "Round 2"):** test 1's base rate says the reply is real
> (9/12 vs 4/20); test 2's forcing didn't work (Server_ChangeState(4) needs a charged ramjet); B (speed matching off)
> doesn't stop it. **Next: test 3 (the owner's race with lever A).**

### 1. Settle the confound from the data we already have (desk, no game) - DONE, see above
Extend `tools/boostan.py` with a **base rate**: in rows where you are NOT boosting, how often does the racer ahead go
into ramjet in any 3 s window? If that is also ~100% on those straights, the "reply" is the track. If it's well below,
the reply is real. Data: `docs/data/boostrecon-2026-11-26.csv`.

### 2. Make ramjets happen at odd places (game, owner away)
Fire YOUR ramjet away from the usual straights so a reply can be seen. Untested idea:
`VehicleBoostComponent:Server_ChangeState(4)` on your pawn (or the `FVehicleBoostRequests_SetRamjetReady` path) at
random times, from boostrecon.lua under an experiment switch (`forceRamjetEvery = 8`). Check first in one race that it
really boosts (your kph jumps, state 4 / ramjet 3), then baseline vs B vs D, 2 races each.
Keep the autopilot in the pack: `botStacks = 3` wasn't enough (it still won by 2-14 s); try 5, or ACE + `botStacks`.

### 3. The owner's races (the real test; needs the owner, ~15 min)
Option C from OWNER.md. Same track (THE WAR FIELDS, CHALLENGER), one race each, the owner not told which is which:
1. baseline (no experiment.lua);
2. A: `MinRacePacingFactorForBoost = 1.3` on all three styles;
3. B: speed matching zone off.

Setup: `./deploy.sh <tag> --dev`, then before each race copy `tools/boosttest/exp/<x>.lua` to
`Mods/GalacticGrandPrix/experiment.lua` (read at each launch; no restart needed for car races). Keep `boostRecon = true`
in each so the rows come in. Ask: "did your boost gain you ground on the racer ahead?" (1-5) and anything odd (field
too slow on the straights?). Then put DevTools back with a normal `./deploy.sh <tag>`.

### 4. Then build the winner
A config knob per league, written at launch and put back at the menu like the AI config already is:
`AI.Profiles[league].styles = { MinRacePacingFactorForBoost = 1.3 }` (A) and/or `config = { EnableSpeedMatchingZone =
false, ... }` (B - the profile `config` table already takes these). Tests in test_ai / test_aiset; a CHANGELOG line;
OWNER playtest. Check pods too (`Pods.Steps` AI profiles) and the Rally (its own catch-up).

## How to run the game tests (the gotchas, all hit on 2026-11-26)

- **Saves first:** copy the GP `save.lua` and the game's whole `SaveGames` folder (both md5'd) to
  `~/.local/share/swgr-save-backups/<name>/`; at the end restore both and compare md5s. The game rewrites
  `GriffinSave.6.sav` during races: restore it with a fresh timestamp (plain `cp`) so Steam Cloud keeps the original.
- **Never close a game the owner left running** - the auto-mode classifier refuses it, rightly. Ask them; a watcher
  `while ps -eo args | grep -q "[S]hipping.exe Griffin"; do sleep 15; done` tells you when it's closed. A game Claude
  started may be killed (AUTOMATION.md §3).
- `pgrep -f` / `pkill -f` match their own shell command: use the `[S]` bracket trick, never `pkill -f <script name>`.
- The GP `save.lua` has CRLF line endings: sed patterns must not anchor on `$`.
- HOME's focus starts on the league raced last: scripts navigate explicitly (carrun.sh walks Left x3 + Right to
  CHALLENGER; podrun.sh Right x3 to PODRACING).
- TestAutopilot: enable (`~/Projects/swgr-testautopilot/deploy.sh`) and `deploy.sh arm`; afterwards `deploy.sh disarm`
  and put `disabled.txt` back (it was off). It can't arm a second pod race in one game session, and fails with pod parts 0.
- deploy.sh installs from git: commit before `./deploy.sh HEAD --dev`. Each deploy drops a `save.backup-*.lua` in the
  mod folder - delete the ones holding test saves afterwards so they aren't mistaken for the owner's.
- A race + launch can pass the 10-minute tool limit: run the scripts in the background.

## The kit (in the repo)

- `mod/GalacticGrandPrix/Scripts/boostrecon.lua` - the 0.5 s rows (DevTools + experiment `boostRecon = true`).
- `tools/boostan.py <csv>` - the per-ramjet analysis.
- `tools/boosttest/carrun.sh <exp> <tag>` - one CHALLENGER race on a fresh game; `boostbatch.sh [b0 b1 ...]` - a batch;
  `podrun.sh <podRacer key> <exp> <tag>` - one PRO pod race.
- `tools/boosttest/exp/` - the experiment files used on 2026-11-26 (b0-b3 with `botStacks = 3`; pod1-pod4).
- `mod/GalacticGrandPrix/Scripts/ai.lua` - experiment `ops` ('game' per tune field), `config` (numbers and booleans),
  `styles` (driving-style fields), all put back at the menu.

## The owner's races (2026-11-26, CHALLENGER, The War Fields; built as v0.45.0)

| Race | Setting | Boost score | Notes |
|---|---|---|---|
| 1 | baseline (0.99) | 2/5 | 2nd; the racers ahead matched the boost |
| 2 | threshold 2.0 (blind) | 4/5 | "definitely faster ... but they had a hard time keeping up in general" |
| 3 | threshold 1.3 (blind) | 3-4/5 | "enemies seemed slower in general" |
| 4 | 2.0 + bots +2 parts | 4/5 | "field kept up better, i crashed once and still took 1st"; the last racer far behind |
| 5 | 2.0 + bots +3 + catch-up 1.6 after 2 s | 4/5 | 5th after two crashes, a pack within 0.4 s; spread 32 s |
| 6 | 2.0 + bots +3 + catch-up 1.6 after 0.5 s | 4/5 | 2nd after one crash; spread 24 s |
| 7 | 2.0 + bots +5 + catch-up 1.6 after 0.5 s | - | "didn't crash ... finished 1st but barely ... pretty close to a good tune" |

Built (owner: all leagues scaled, keep the tiers): threshold 2.0 and catch-up 1.6 after 0.5 s everywhere; strength
around +5 (CHALLENGER, ACE) / +3 (JUNKER). Note: a race's `[exp] result` line carries the experiment file in place when
the results are written - swapping the file before the owner leaves the results screen mislabels it (races 2 and 6).
