# Work plan: Galactic Grand Prix

Design: DESIGN.md. Shared playbook and house rules: ~/Projects/swgr-underground/AUTOMATION.md.
One git tag per chunk; push after each tag. Questions and playtests for the owner: OWNER.md.
**Done work and the old plan (to v0.27.5, 2026-11-12): docs/TASKS-done.md.** This file holds open work only;
when an item is done, move it there with a one-line result.

Now: v0.27.5 installed (2026-11-12). Three leagues (Riff-Raff / Challenger / Ace), random cups, the garage as the
start screen, cups chained on the results screen.

## 1. Next up: better AI drivers (owner kicks it off)
**Kickoff prompt:** "Start the AI driving spike in TASKS.md - I'm away for about an hour." Needs the desktop to
Claude alone (the owner away), the game closed at the start. Back up the owner's save first (md5), restore after.

**Why (owner, 2026-11-12, after a day of Challenger cups):** "some tracks are close or i take 2nd-4th but never
lower, some tracks i'm ahead by 15+ seconds ... i think the AI could still drive better, they don't seem to use the
afterburner or ramjet very well, and they crash and make mistakes more than i think they would ... i'm going for
realism here so i'm open to ideas. We could make all the enemy vehicles a little faster or slower at random."

**What the log showed (Challenger, 2026-11-12, `[gaps]` lines in grandprix.log):**
| Track | You | Gap |
|---|---|---|
| Cloister Run (snow) | 1st | +17.9 s to Griff Halloran |
| Mountain to Sea | 1st | +15.4 s to Malis Vazosk |
| Dai Bendu Ascension (snow) | 1st | +9.7 s to Lyren Shok |
| Scrap Spiral | 1st | +5.9 s to Shade |
| Fallen Empire (scorching) | 1st | +4.3 s to Goli & 02-R0 |
| Griffin's Flight | 2nd | -1.8 s to Lyren Shok |
| Andobi Edge | 2nd | -1.3 s to Goli & 02-R0 |
| The Giants' Graveyard | 2nd | -3.3 s to Lyren Shok |
| The Pyroducts (wet) | 3rd | -2.6 s to Katja Mox |
| The War Fields (reverse) | 3rd | -7.4 s to Sen Fira |
- The field spread 1st-12th is 21-43 s every race: far looser than a real field of similar cars.
- The best bot is often a weak pilot (Malis Vazosk, Griff Halloran) while the campaign's Elite (Sen Fira, Biddy
  Blas, Lyren Shok) finish far back: results look decided by mistakes and crashes, not by pace. Snow tracks and the
  long sprints are the worst for the bots.
- Challenger and Ace already run the bots with no help and no handicap we know of: no catch-up, no slowdown for
  you, no forced errors, no easing off while you crash, no speed matching (config `AI.Profiles`). So what's left is
  how they drive. (Riff-Raff still has the mercy slowdown 0.4 and forced errors - on purpose.)

**Levers, matched to what the owner saw** (full detail: docs/ai-driving-research-2026-11-12.md):
1. **Afterburner / ramjet use - the driving style's boost rules** (`URaceAIDrivingStyleDef` DS_Car_Base /
   DS_Bike_Base / DS_Skimmer_Base): `MinEnergyForAfterburner`, `MinTimeBetweenBoosts`, `MinBoostTime`,
   `MaxDegreesOffHeadingForBoost`, `BoostTopSpeedThresholdRatio`, `MinRacePacingFactorForBoost`,
   `RamjetExtrapolationTime`. Most direct fix for "they don't boost well"; free pace, no rubber band.
2. **Crashes and mistakes:** the AI-only affixes `AFX_AI_SlowerCrashRecovery` / `AFX_AI_TemporarilySlower` and the
   tune sets `TNS_AI_General` (on every bot via DA_AIConfig) / `TNS_AI_ReducedPower` look like built-in handicaps:
   if so, neutralise them at Challenger / Ace (memory only, put back at the menu). The style's look-ahead, aim point,
   corner extrapolation and avoidance numbers may be behind the crashes, but steering gains are risky (unstable
   bots crash more) - try last, small steps.
3. **Faster / slower cars at random - "pilot strength + form":** the bots' race copies are already edited at load
   (loadout.lua), and every build has parts levels (`UpgradeSlots`) and a `PowerLevel` / `OverridenPowerLevel`.
   Claude's pick for realism: each pilot a fixed strength (the Elite always quick, Malis / Ary always slow) plus a
   small per-race form swing (about +-1 parts level), so the same rivals are usually the ones to beat and an
   underdog can still have a day. Unproven: the old "bot parts don't change pace" finding was made with the rubber
   band on, which hid it. Also possible: a constant tune-set boost (catch-up's `TNS_AI_Catchup_Boost` applied once,
   never removed - a faster field, not a rubber band).
4. (Possible later) a per-track AI adjustment if some tracks stay lopsided after 1-3: static, measured once, not a
   rubber band.

**Owner to decide before step 3 is built:** fixed pilot strength + small form (Claude's pick) or fully random?

**Steps** (house rules: no hooks, no per-tick lookups in races, nothing kept between ticks, writes memory only and
put back at the menu, key binds only set flags):
- [x] 1. Recon, read only (2026-11-12, one launch): **docs/ai-driving-results-2026-11-12.md.** Every bot drives an
      exact copy of YOUR car (same parts, power 30) - nothing in the cars tells pilots apart; no hidden handicap
      affixes at load (TNS_AI_General helps the bots); the boost rules are cautious, the bike's most of all. Step 2's
      switch (`experiment.lua`: styles, config, bot parts, a fixed event, every racer's time) is built (v0.27.7).
- [x] 2. Held-race batches (2026-11-12, 12 races, docs/ai-driving-results-2026-11-12.md "Step 2"): boost rules no
      effect; bot parts work (+2 levels = ~3-4.5 s); pilot strength puts the Elite on top; the race-to-race swings
      (~20 s per pilot) are the bots' own mistakes and stay.
- [x] 3. Report and proposal (results doc). Owner: fixed strengths, no per-race randomness. **Built as v0.28.0**
      (config `AI.Strength`). Next: the owner races cups at Challenger and Ace (OWNER.md). Ace checked 2026-11-12:
      extra parts barely change the bots there (results doc); if Ace feels even, try TNS_AI_Aggression_Boost on the Elite.
- Done: desk research (docs/ai-driving-research-2026-11-12.md). Tools: TestAutopilot v1.5 (hold.txt); the
  job-scratch scripts step.sh / apwait.sh / chainrace.sh / titlerun.sh (copy into tools/ if the job folder is gone).

## 1b. League styles (owner 2026-11-12: "different styles of racing"; agreed, not built)
**docs/league-styles-2026-11-12.md** - each league its own character (the car, the field, the tracks, the kit).
- [x] Junker: renamed, afterburner and ramjet +2 (v0.28.3).
- [ ] Junker = banger racing: more aggressive bots (`AI.Profiles.riffraff.aggression`).
- [ ] Ace = weather and night: the draw leans to condition variants (gp.lua `K.draw`, a per-league lean).

## 1c. Looks (owner 2026-11-12; not started)
- [ ] **Rust for Junker** (spike first): the game's All Rust patina (`LP_AllRust`), the dirt override and the panel
      damage call on your car at a Junker race load - docs/custom-vehicle-models-2026-11-12.md "The cheap alternative".
- [ ] **New vehicle models** (big; inspiration photos of a junker speeder): the process in
      docs/custom-vehicle-models-2026-11-12.md. First step if wanted: a pipeline proof (one car kit cooked back with a
      trivial change).

## 2. Waiting on the owner's play (details and tick boxes in OWNER.md "Playtests")
- [ ] v0.27.x: the finish times then STANDINGS (A, or 6 s); Challenger open from the start; Riff-Raff's feel (parts
      2 on three slots); the posters' taglines and the cups page brief; the garage's TUNE-UP / ABILITY captions.
- [x] The game's own track intro (flyover) shows in our races with StreamlineCampaign off (seen in all 23 launch
      checks, 2026-11-12). Owner's call: drop the race list from the start screen header (`startHeader`, main.lua)?
- [ ] v0.27.5: the tab at game start (no auto-open; ~1 s sooner; `TabSettleS = 1.0` if the menu misbehaves).
- [ ] The parts slot-to-stat mapping: slots confirmed in game 2026-11-12 (0 Grip, 1 Acceleration, 2 Resilience,
      3 Boost, 4 Battery, 5 Advanced); which on-screen bar each drives is still a guess by name.
- [ ] Riff-Raff's brief "Stock engines" now it has parts 2 (e.g. "Hot-rodded junkers")?
- [x] The pool races never launched (23 by the log): all launched 2026-11-12, all fine (docs/data/launch-check-2026-11-12.txt).
- [ ] Do the AI fire their abilities, Shields included (R7)?

## 3. Known gaps (small fixes)
- [x] A DNF skipped the results panel; the last race kept the game's own CONTINUE. Both fixed in v0.28.1 (in-game
      check: OWNER.md).

## 4. Discussions (owner's call; talk before building)
- **Kestar is a weak final boss** (veers off the line, loses by ~20 s even to the autopilot; the Showdown was likely
  built around the game's catch-up). Boss keeps the game's own AI, a boss profile, or leave him? (OWNER.md) The AI
  spike above may fix it anyway.
- **The Galactic Cup format** (three random planets, then The Galactic Gauntlet): right, or something else?
- **Loadout options written up: docs/loadout-options-2026-11-12.md** (split HEAT SHIELD, weather in every cup, golds
  unlock packs, rebalance). Owner to pick.
- **Tune-ups gated by league** vs earned (trophies, golds, titles) or not gated at all; **heat / cold and the
  packs** - make picking the right pack matter more, or drop it.
- **Ideas for the future (owner, 2026-11-12):** a deeper dive into the tune-up system; a **Grand Tour** (every track
  on a planet, or all 86); a **podracing cup or league** (docs/tracks-by-planet.md "Not in the cups"); **leaning by
  league** for the random cups (Riff-Raff mostly forward layouts, conditions likely at Ace).
- **Progress badges** beside HOME (the game's insignias) in place of goal lines.
- **PHILOSOPHY.md is out of date** (rival cut, leagues): rewrite to match today? (OWNER.md)

## 5. Housekeeping
- [ ] attic/ cleanup (old study mode, the chain reset route): keep, or delete now nothing uses it.
- [ ] Test mods left disabled in the Mods folder (LookSpike, RaceFlowSpike, the recon mods): remove when done.

## 6. v1.0
- [ ] The owner plays every cup at every league; tune parts, AI, AI kits, points. Tag v1.0.0.
