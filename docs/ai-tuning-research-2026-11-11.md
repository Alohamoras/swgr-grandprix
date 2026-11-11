# AI tuning research (2026-11-11)

Goal: AI that is challenging and consistent at 50 / 100 / 150 / 200cc, with as little rubber banding as possible.
Research only: no code or game changes. Tags: **P** = proven in our logs, **R** = read (header dump, game data, FreeRace
source), **W** = web source, **G** = guess / inference, to be tested.

## Summary
- The game's AI is fully player-relative. Each bot paces against one pawn (`URaceAIComponent.mPawnToPaceAgainst`) and
  aims to stay inside a time window ahead of / behind you set by curve rows **per tier** (Ace / Elite / Challengers /
  RiffRaff / Losers). Outside that window it slows down (to 0.75x) or speeds up (to 1.3x). There is no "base skill"
  number we can read. (R)
- Four more player-relative systems sit on top: forced errors only near you, speed matching near you, slowing when you
  crash, and aggression aimed at you. (R)
- Catch-up adds acceleration through a tune set (`TNS_AI_Catchup_Boost`). It is not a top-speed multiplier, which is why
  TestAutopilot still wins by 3-13 s at full catch-up. (R from FreeRace, P from our gap log)
- **What this means:** cut the catch-up and the AI simply gets slower. To keep races close without it, we first need a
  lever that raises the AI's own pace. Finding one comes before tuning catch-up (§c, Phase 3).
- **Possible bug:** pacing settings exist in two places, `DA_AIConfig.DefaultPacingSettings` and the
  `RacePacingConfig` assets (`RP_Default`, `RP_Honest`). FreeRace writes both; we write only the first. Our "honest
  pacing" writes may never reach the race (G). Check this first (Phase 0).
- Other games: the best-regarded approaches keep within-race help small and late-race honest. They get a lively field
  from fixed per-AI pace bands, and adapt difficulty between races, not during (Mario Kart: Double Dash patent, Pure,
  Wipeout Pulse, Sonic CrossWorlds).

---------------------------------------------------------------------------------------------------------------------
## (a) This game's AI

### Public information
| Topic | What's known | Source |
|---|---|---|
| Developer | Fuse Games (founded 2023 by ex-Criterion / Burnout staff; director Matt Webster). Publisher Secret Mode. | W [Unreal interview](https://www.unrealengine.com/developer-interviews/fuse-games-uses-ue5-to-make-a-fast-and-authentic-star-wars-racing-game), [GamesRadar](https://www.gamesradar.com/games/racing/how-former-burnout-devs-came-full-circle-for-star-wars-galactic-racer-to-bring-the-edge-back-into-racing-games-arcade-is-not-the-absence-of-depth/) |
| Difficulties | Campaign only: **Cadet, Pilot (default), Ace, Champion**. Champion: "increases opponent skill and aggression", fewer crashes, crashes refresh only per planet. Quick races have no difficulty option. | W [GamerBlurb](https://gamerblurb.com/guides/star-wars-galactic-racer-how-to-change-difficulty), [PowerPyx](https://www.powerpyx.com/star-wars-galactic-racer-trophy-guide-roadmap/), [The Drive](https://www.thedrive.com/news/star-wars-galactic-racer-review-come-for-the-podracing-stay-for-the-punishment) |
| "Nightmare" | Not a game name. FreeRace relabels Pilot as "Hard" and Ace as "Nightmare"; our ai.lua comments inherited those names. | R FreeRace `fr_rules.lua` |
| Rubber-band complaints | Steam review: "overwhelming, unadjustable rubber-banding". With a 5-10 s lead the AI gets "an artificial top-speed multiplier"; passes on the last straight even at your top speed. Players sandbag in 2nd / 3rd and save boost for the last 10 %. Defenders: it keeps packs tight so abilities matter, and it helps you recover from mistakes. No developer reply. | W [Steam thread](https://steamcommunity.com/app/4078430/discussions/1/594069606514154693/) |
| Ace praised | One guide: Ace gives "a series of photo-finishes"; lowering the difficulty loses that tension. | W [PlayNews](https://www.playnews.gg/en/guides/sebulba-in-star-wars-galactic-racer-how-to-beat-him-during-his-rigged-race) |
| Patches | 1.004.003 (Oct 12) and 1.005 (Oct 22, parties of 6, key presets): no AI or rubber-band changes. | W [Shacknews](https://www.shacknews.com/article/151113/star-wars-galactic-racer-patch-notes-oct-22), [MP1st](https://mp1st.com/title-updates-and-patches/star-wars-galactic-racer-first-hotfix-speeds-out-october-12-update-1-004-003) |
| Mods | Nexus has no Galactic Racer AI mod. FreeRace (Downloads zip, `~/.claude/jobs/e42072a1/tmp/freerace`) is the only reference: 4 difficulties, catch-up off / AI / players / both, a 15 s start grace, AI perfect starts 15 %, a catch-up readout. | R |

### How the pacing works (from the header dump + FreeRace)
1. **Target window.** `URacePacingConfig.PacingConfigs[]` holds a `FVehiclePacingConfig` per tier:
   `AIMaxTimeAhead` / `AIMinTimeAhead` (curve-table rows named by tier, e.g. `Elite...`, `Losers...`). There is also a
   separate `RivalPacingConfig`. FreeRace notes: "the back of the grid uses the RiffRaff and Losers rows ... set to trail
   you, so catch-up never reaches them", and "the pacing curves want every AI racer at least level with you from the
   green light (min time ahead 0)". (R) That explains the 15-44 s field spread in our logs: **the game already has pace
   bands per tier** (P: `[gaps]` field spread). The curve x-axis is probably race progress (G).
2. **Speed scale.** `FPacingSettingsConfig`: when a bot is past its max time ahead, it ramps down to
   `MaxAiSlowdownScale` over `AiAheadTimeToMaxSlowdown`. When it is behind its min, it ramps up to `MaxAiCatchupScale`
   over `AiBehindTimeToMaxCatchup`. The result shows as `FFbRaceAIInfo.RacePacingFactor` (debug struct). (R names, G
   exact maths)
3. **Catch-up = a tune set** (`TNS_AI_Catchup_Boost`, seen in `TuneComponent.SetsApplied`). FreeRace: "catch-up only
   adds acceleration, which a cap cancels". (R) This explains why autopilot beats a full-catch-up field by 3-13 s (P).
4. **Race tune (`DA_RaceTuneConfig` → `FRaceTuneConfig`) moves the window**: Modifier = seconds added, Multiplier =
   scale. The campaign difficulty tune sets are `TNS_Diff_Ai*`. (R)
5. **Player-relative extras** on `URaceAIComponentConfig` (R): forced errors in a zone around you; a speed-matching
   zone (`URaceAISpeedMatchingComponent`); `AiSlowdownDuringCrash`; aggression vs player.

### Every field (Griffin.hpp, read-only)
`FRaceTuneConfig` (on `URaceTuneData.Config`; one shared object per race, P). Defaults: Modifiers 0, Multipliers 1.
| Field | Type | Does (R names / G meaning) | Game difficulties (FreeRace) |
|---|---|---|---|
| TotalCrashAllowance | int32 | crashes before wreck-out | Cadet +1 |
| ResetToFullHealthAtRaceStart | bool | | Champion off |
| NumCrashesToRecoverBeforeLeagueEvents / InPaddock, NumberOfStrikesGainedFromWreck, PositionRequiredForNoStrikePenalty, NumberOfStrikesGainedFromFinishPositionPenalty | int32 | campaign strikes | - |
| AiMaxTimeAheadModifier | float s | added to the window top: how far ahead bots may run before slowing | Ace +2.5, Champion +5 |
| AiMinTimeAheadModifier | float s | added to the window floor: below it, catch-up | Cadet -3, Ace +1.5, Champion +3 |
| AiMaxTimeAheadMultiplier / AiMinTimeAheadMultiplier | float | scale the curves | Cadet max x0.65 |
| AiTimeAheadSlowdownModifier | float | G: shifts the slowdown ramp (never used by any difficulty) | - |
| AiAggressionVPlayerCooldownMultiplier | float | slam cooldown vs you | Cadet +1.25, Ace x0.75, Champion x0.5 |
| AiAggressionVPlayerChanceMultiplier | float | slam chance vs you | -0.35 / +1 / +2.5 |
| AiCountdownToSlamPlayerModifier | float s | wind-up before a slam | +0.8 / -0.2 / -0.4 |
| AiAbilityChanceMultiplier | float | ability use | -0.25 / +0.5 / +1.25 |

`URaceAIComponentConfig` = `/Game/Griffin/AI/DA_AIConfig` (read at race start, P). Game values from our earlier reads.
| Field | Type | Game value / note |
|---|---|---|
| DefaultPacingCurves (AIMaxTimeAhead, AIMinTimeAhead) | FCurveTableRowHandle x2 | the fallback window |
| DefaultPacingSettings.RacePacingLowestSpeedMph | float | 150 (floor for a slowed bot, G) |
| .MaxAiCatchupScale | float | 1.3 |
| .MaxAiSlowdownScale | float | 0.75 (1.0 = honest) |
| .AiAheadTimeToMaxSlowdown | float s | 1.5 |
| .AiBehindTimeToMaxCatchup | float s | 2 |
| .AiSlowdownDuringCrash | float | 0.5 (G: bots slow while **you** are crashed) |
| EnableSpeedMatchingZone | bool | **not read yet** |
| SpeedMatchingMinPlayerSpeedInMph, SpeedMatchingSpeedLag, MaxTimeMatching, Cooldown, TimeAhead, TimeBehind | float | not read yet |
| SpeedMatchingMaxMatchers | int32 | not read yet (0 should switch it off, G) |
| SpeedMatchingUseSpeedMatchingCurve, AllowSpeedMatchingWhenBoosting | bool | |
| SpeedMatchingFactorCurve | FRuntimeFloatCurve | don't read |
| ForcedErrorZoneLengthAhead / Behind | float m | 350 / 150 |
| ForcedErrorTickRate, ForcedErrorChance, ForcedErrorDuration | float | ?, 15, 8 s |
| SpectacleZoneLengthAhead | float | |
| AggressionConfig (FAggressionConfig: RaceTimeBeforeAggression, SlamDuration, MinTargetSpeedInMph, SpaceBetween, TargetZone*, VersusAI / VersusPlayer {EnableAggression, Cooldown, Chance, TimeBeforeSlam}) | struct | VersusPlayer 50 %, 2 s |
| Takedown* | | takedown events only |
| DefaultPercentageChancePerfectStart | float % | 75 |
| AbilityConfigCollection | UAIAbilityConfigCollection* | per-ability chance / cooldown |
| Car / Bike / Skimmer / Plane (+ `*Classes` maps) | URaceAIDrivingStyleDef* | steering / throttle PIDs, `CatchupTuneSet`, boost rules: `MinBoostTime`, `MinRacePacingFactorForBoost`, `MinThrottleForBoost`, `MinEnergyForAfterburner`, `MinTimeBetweenBoosts`, `BoostTopSpeedThresholdRatio` |

`URacePacingConfig` (`/Game/Griffin/AI/Pacing/Default/RP_Default`, `RP_Honest`): `PacingConfigs` (TArray of the
tier windows), `RivalPacingConfig`, `PacingSettingsConfig` (**a second copy of the scales above**). (R)

Per racer and archetype, all unreadable from Lua (TOptional / TMap):
`UArchetypeConfigCollection.ArchetypeConfigMap[ERacerArchetype]` → `FRacerArchetypeConfig { GameModePacingOverrideMap,
TOptional<int32> PowerLevel, AggressionOverride, TOptional<float> PercentageChancePerfectStart }`.
`UAIBuildDef { TOptional<FVehiclePacingConfig> PacingConfig, TOptional<float> PercentageChancePerfectStart }`.
`FAIBuildState { GameModePacingConfigs, PercentageChancePerfectStart, RacerAggressionLevel }`.
`ERacerArchetype`: Ace 0, Elite 1, Challenger 2 (= Default), RiffRaff 3, Loser 4, Rival 5, Boss 6, Player 7, Custom 8.
The player-side catch-up (`ARacingGameMode.CatchupEnabled` None / SP / MP / Both, curves by PowerLevel,
`TNS_Catchup_1Percent`) is MP only by default. (R)

### What our logs already show
- Autopilot won all 11 runs (current profiles) by 3.3-12.9 s; field spread 22-44 s. (P, grandprix.log 2026-11-10/11)
- Bots' part levels didn't change their pace **under the rubber band** (UG). (P) Untested with the band off.
- The owner is about as fast as the autopilot: War Fields 150cc owner 1:42.39 vs autopilot 1:43.35 (dawn). (P)
- So at full catch-up the field's best is still a few seconds slower than a clean owner race on many tracks. (G, small sample)

---------------------------------------------------------------------------------------------------------------------
## (b) Techniques from other games that fit our knobs

| Technique | Who | How it maps here |
|---|---|---|
| **Target places per AI, not one rubber band.** Two "rival" karts aim for 1st and 2nd, the rest 3rd or lower. Each speeds up or slows down against the **other CPUs' places**. Targets swap mid-race only when a rival falls badly behind. Rivals are re-targeted **between races** from cup scores. | Mario Kart: Double Dash ([US 7278913](https://patents.google.com/patent/US7278913B2/en)) | The game already has tier rows plus a `RivalPacingConfig`. Keep the tiers; use our `rival.lua` rival as the "1st target". Do adaptation only between races (our hidden `Adjust`). |
| **Pace groups relative to the player, help fading late.** Close / middle / back / advanced groups, each with a target point that moves over the race. The skill bonus falls each lap and the help shrinks to **zero over the last 20 %**. | Pure, Black Rock ([Jimenez 2009](https://www.gamedeveloper.com/design/the-pure-advantage-advanced-racing-game-ai)) | Our window modifiers are the target points. "Honest last lap" = `MaxAiCatchupScale` → 1.0 for the final lap (needs a mid-race write; FreeRace's 15 s start grace proves mid-race writes take effect, R). |
| **Difficulty separate from speed class.** | Wipeout Pulse ([Engadget](https://www.engadget.com/2007-06-15-separating-challenge-from-speed-in-wipeout-pulse.html)) | 200cc keeps the 150cc AI profile (already the plan); `Adjust` stays the difficulty dial. |
| **Items (abilities) as the comeback, not speed.** "We use items to provide that boost ... a substitute to Initial D's rubber banding". | Sonic Racing CrossWorlds ([Automaton](https://automaton-media.com/en/interviews/sonic-racing-crossworlds-is-like-a-party-game-on-the-outside-but-tuned-like-a-fully-skill-based-racing-game-on-the-inside-developers-say/)) | `AiAbilityChanceMultiplier` / aggression keep pressure in a close pack without speed cheats. Raise these where we cut catch-up, in moderation. |
| **Leaders get weaker items.** | Mario Kart series (W) | Not available: abilities are loadouts, not position-based pickups. |
| **Rubber band the car slightly, not the driver.** Small mass / torque / grip changes, kept small so the handling stays believable. | Forza Drivatar ([Thompson 2021](https://www.gamedeveloper.com/design/how-forza-s-drivatar-actually-works)) | Our pacing scale is the same idea. Keep it within roughly ±10 % so it isn't visible. Players notice "top speed on the straight" first (Steam review). |
| **Subtle and surmountable.** Tie any band to the core mechanic (here: packs close enough to use abilities). Avoid visible cheating. | Dave Mark ([2010](https://www.gamedeveloper.com/design/rubber-banding-as-a-design-requirement)) | Target: top AI within 1-3 s, never "6 s cut to 2 s in a lap". |
| **Benchmark AI pace as a % of a reference lap, per track.** | F1 games / F1Laps ([F1Laps](https://www.f1laps.com/faqs/ai-difficulty-calculator)) | Autopilot = the reference driver. Express AI pace as % of the autopilot's time. Map the owner via their records. |
| **Even a learned AI paces to you.** | GT Sophy (players report pace adapting; three tiers) ([GTPlanet](https://www.gtplanet.net/gran-turismo-sophy-arrives-in-gt7-update-1-29-hands-on-first-impressions/)) | Some adaptation is normal. The aim is to make it small and invisible, not zero. |
| CTR Nitro-Fueled, Mario Kart World | Widely criticised for strong rubber banding on Hard and for CPU pace tied to player behaviour (W, anecdotal: [NintendoSoup](https://nintendosoup.com/mario-kart-world-appears-to-have-a-dynamic-difficulty-system), [GameRevolution](https://www.gamerevolution.com/originals/557587-crash-team-racing-nitro-fueled-too-difficult)) | The pattern to avoid. |

Not found: a primary source on F-Zero GX or Burnout 3 AI (only listicles). Not cited.

---------------------------------------------------------------------------------------------------------------------
## (c) Measurement plan (autopilot batches)

### Principles
- The rubber band paces against **you**. Against a driver faster than the field (the autopilot), bots sit in max
  catch-up almost all race. So autopilot runs measure the field's **ceiling** and its **open-loop** (no rubber band)
  pace. They do not measure how a race feels.
- Change one setting at a time. Use fixed tracks, the same order for every setting, and paired comparisons.
- Write the settings that are actually in effect into every race's log (read back from the objects), not the config.

### Logging to add before the batch (small code changes, for later)
1. `[gapsall]`: every racer's finish time and gap to you, with name and tier (K.gaps already has the list; only the line
   is short).
2. `[aiset]`: the read-back values of every field in §a for DA_AIConfig, RP_Default / RP_Honest `PacingSettingsConfig`,
   and the shared race tune. Include the SpeedMatching fields (never read so far).
3. `[pace]` every 5 s: your position, plus the time gap to the best bot (distance / your speed is enough), and how many
   bots have a `*Catchup*` tune set on. FreeRace reads `TuneComponent.SetsApplied` with `ForEach`. That is a **TMap**,
   which KNOWLEDGE §2 says not to read: try it in a short recon first, or skip it and use the time gaps alone.
4. Per race: the lap times for you and the best bot, your crashes, slams on you, and perfect starts if readable.

### Tracks and counts
- Use three fixed events that every class can launch: **The War Fields** (circuit, 2 laps, Mastiff Loop A FWD), **The
  Giants' Graveyard** (sprint), **Fallen Empire** (short circuit, 6 laps). Plain versions at every class, so the class
  is the only difference.
- Noise first. Our autopilot gaps on one track vary a lot (Ice Field reverse 100cc: +11.9 and +7.4 s). Assume σ ≈ 2 s
  (G). Plan **3 races per cell**, plus a 4th when two settings differ by less than 2 s. Use medians, not means (a crash
  outlier is common).
- About 4 min per race including loading → about 15 races an hour.

### Phases
| # | What | Settings | Classes x tracks x reps | Races |
|---|---|---|---|---|
| 0 | Recon: read RP_Default / RP_Honest and the SpeedMatching values; check our DA_AIConfig writes reach the race | none (menu read); then honest pacing written to **both** assets, 1 race | 150 x War Fields x 1 | 1-2 |
| 0b | Noise baseline | current profile | 150 x War Fields x 4 | 4 |
| 1 | **Open loop: the AI's own pace** | catch-up 1.0, slowdown 1.0 (both assets), errors 0, SpeedMatchingMaxMatchers 0 | 50 / 150 x 3 tracks x 2 | 12 |
| 1b | Is the window inert in open loop? | Phase 1 + pressure 2 | 150 x War Fields x 2 | 2 |
| 2 | Catch-up dose-response | slowdown 1.0; MaxAiCatchupScale 1.0 / 1.1 / 1.2 / 1.3; then AiBehindTimeToMaxCatchup 2 vs 5 at the best one | 150 x 3 tracks x 2 | 30 |
| 3 | **Raw pace levers** (no player-relative help) | (a) slowdown = catch-up = 1.10 (a constant factor); (b) RacePacingLowestSpeedMph 150 → 300; (c) bot parts = yours vs 0, in open loop; (d) driving style boost rules (`MinTimeBetweenBoosts` x0.5, `MinRacePacingFactorForBoost` lower) | 150 x War Fields + Graveyard x 2 | 16 |
| 4 | Candidate profiles (§d) | Plan A or Plan B | 50 / 100 / 150 / 200 x 3 tracks x 3 | 36 |
| 5 | Owner validation | final profiles | owner's cups | - |

About 100 races, roughly 7 hours of an unattended desktop, which can be split across sessions. Phase 0 can change
everything after it: if our pacing writes never reached the race, the existing "honest" profile was never tested.

### What to compute (per cell)
- **G1** = median of (best bot's time minus yours). Positive = you won by that much. **Gtop3** = median gap to the 3rd
  bot. **Spread** = 1st to 12th.
- **Consistency**: IQR of G1 across reps and tracks (want ≤ 2 s); Kendall τ of the bot finishing order across races
  (want > 0.5, so the same racers are strong every time and the field has identities).
- **Closeness** (from `[pace]`): % of samples with the nearest bot within ±2 s; lead changes.
- **Band duty**: % of samples with bots on catch-up. This is the number we are trying to minimise.
- **Open-loop deficit** (Phase 1): best bot's time / autopilot time - 1, per class and track. This is the AI's honest
  skill.

### Targets (for a clean race at the owner's pace ≈ autopilot)
| Class | G1 (you win by) | Gtop3 | Band duty |
|---|---|---|---|
| 50cc | +3 to +8 s | < 12 s | anything (generous) |
| 100cc | +1 to +4 s | < 8 s | ≤ 50 % |
| 150cc / 200cc | 0 to +2 s (a clean race wins, a sloppy one doesn't) | < 5 s | as low as Phase 2 / 3 allow |

The autopilot is not a stand-in for the owner's feel (KNOWLEDGE §5). The table only places the numbers; the owner's
cups decide.

---------------------------------------------------------------------------------------------------------------------
## (d) Proposed starting profiles

The choice depends on Phase 3: is there a lever that raises the AI's own pace?

**Plan A: a raw-pace lever works** (e.g. a constant factor or bot parts lift the open-loop pace to within about 2 % of
the autopilot). Use that lever per class as the "skill", and keep catch-up as a light safety net only:

| Field (config key) | 50cc | 100cc | 150cc | 200cc |
|---|---|---|---|---|
| pressure | -1 | -0.25 | 0.5 | 0.5 |
| pacing.MaxAiSlowdownScale | 0.75 (game) | 0.9 | 1.0 | 1.0 |
| pacing.MaxAiCatchupScale | 1.3 (game) | 1.15 | 1.05 | 1.05 |
| pacing.AiBehindTimeToMaxCatchup | 2 (game) | 3 | 6 | 6 |
| pacing.AiSlowdownDuringCrash (G meaning) | 0.5 (game) | 0.75 | 1.0 | 1.0 |
| errors (x ForcedErrorChance) | 1 | 0.75 | 0.5 | 0.5 |
| perfectStart | 50 | 60 | 75 | 75 |
| raw-pace lever | none | small | from Phase 3 | = 150cc |

**Plan B: catch-up is the only lever** (Phase 3 finds nothing). Keep the strength but make it act late and far:
150 / 200cc slowdown 1.0, catch-up 1.3 but `AiBehindTimeToMaxCatchup` 5-6 s. Nearby bots then drive at about their own
pace, and only the ones far back get full help. Add a 10-15 s start grace (FreeRace's fix for the green-light surge)
and an honest last lap (catch-up → 1.0) if mid-race writes work.

**Why these numbers**
- 50cc stays the game's own band (generous, PHILOSOPHY point 7). 100cc halves the slowdown and trims the catch-up. From
  150cc nobody waits for you, so "fail now, win later" is real (PHILOSOPHY point 1).
- A long catch-up ramp (`AiBehindTimeToMaxCatchup` 6 s) matches Pure's "help fades near the player" and Mario Kart's
  "targets, not tethers". The pack stays close enough for abilities, without the visible straight-line surge players
  complain about.
- `AiSlowdownDuringCrash` 1.0 at the top classes makes a crash cost real time. This rests on the guessed meaning:
  confirm it in Phase 2 with one race and a deliberate crash.
- Fewer forced errors at the top: they only happen near you, so they are a hidden band. Halving them keeps the field
  human without gifting places.
- Keep the game's tier rows (they already give a field with identities). Optionally adapt `Adjust` ±0.25 **between
  cups** from the last cup's median G1, capped and logged, the way Double Dash re-targets its rivals from scores.
- Don't add new pressure above 0.5: it raises the window floor, so it **adds** catch-up duty. It only means "harder"
  when catch-up is strong.

## Open questions to settle in Phase 0-1
- Which pacing settings does the race read: DA_AIConfig, RP_Default, or RP_Honest (and when does RP_Honest apply)?
- SpeedMatching values, and does `SpeedMatchingMaxMatchers` 0 switch it off?
- Do mid-race writes to the pacing scales take effect (needed for the honest last lap and start grace)?
- What `AiSlowdownDuringCrash` and `AiTimeAheadSlowdownModifier` actually do.
- Do bots' part levels change their pace when the band is off?
