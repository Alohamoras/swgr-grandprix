# Better AI drivers: desk research (2026-11-12)

TASKS "Spike: better AI drivers". The owner: "it's strange that the catch-up factor can make opponents faster, but we
don't have any other levers to just make them better drivers; perhaps the AI is at its limit for driving skill?"

Sources: the game's class dump (`ue4ss/CXXHeaderDump/Griffin.hpp`, `Griffin_enums.hpp`), the list of AI assets in the
paks (`/Game/Griffin/AI/`, 50 assets, `swgr-vehiclelooks/tools/utocdir.py`), the 2026-11-10 MenuRecon logs
(`tools/recon/MenuRecon/menurecon-20261110-b/c.log`), docs/ai-tuning-research-2026-11-11.md, KNOWLEDGE.md §5.
No game was run. Tags: **P** proven in game, **R** read from the dump / asset list, **G** a guess.

## Short answer
The AI is probably not at its limit. We have only tried the **pacing** settings (the rubber band). The game has
three more families of AI settings we've never changed, and the game's own difficulty levels use one of them:

| # | Lever | What it is | Why it could matter | Readable / writable from Lua |
|---|---|---|---|---|
| 1 | **Power level of the bots' cars** | every vehicle's build has a `PowerLevel`; the campaign's difficulties raise the bots' by +4 (Hard / "Ace") and +12 ×1.1 (Nightmare, tour 3) | the game designers' own difficulty lever; tonight's test suggests the bots' level follows YOURS (your car 1 level slower -> Biddy slower too) | the build state is plain ints (R); we already edit each bot's race copy at load (P, loadout.lua) |
| 2 | **Tune sets on the bots** | named bundles of stat changes; `DA_AIConfig.GeneralAITuneSet` = `TNS_AI_General` is applied to every bot (R, MenuRecon); catch-up works by applying `TNS_AI_Catchup_Boost` | a constant boost (catch-up's tune applied all race, whatever the position) = a faster field, not a rubber band; `TNS_AI_General` / `TNS_AI_ReducedPower` may be handicaps we can remove | tune sets' `Operations` were read from Lua on 2026-11-10 (P); `AVehiclePawn:RequestApplyTuneSet(set, n)` exists (R) |
| 3 | **Driving styles** | `DS_Car_Base`, `DS_Bike_Base`, `DS_Skimmer_Base` (`URaceAIDrivingStyleDef`): one per vehicle type, shared by every bot | how they boost, steer and take corners - the "driving skill" itself | plain floats and small structs (R) |

Plus two smaller ones: **archetypes** (Ace / Elite / Challenger / RiffRaff / Loser; part of the field may be built to
be slow) and the **AI-only affixes** `AFX_AI_TemporarilySlower` and `AFX_AI_SlowerCrashRecovery` (names suggest
handicaps; where they're applied is unknown).

## 1. Power level (the most promising)
- `FVehicleBuildState` (every vehicle's build): `UpgradeSlots` (the part levels we write for you), `PowerLevel`,
  `OverridenPowerLevel`, `PowerLevelMaxRemainder` (R). `UVehicleUpgradeDef.PowerLevel` per part (R), so the power
  level is the build's total strength.
- The game generates bot builds to a target (`FGeneratedVehicleBuild { PowerLevelTarget, PowerLevel }`,
  `GenerateVehicleBuildPreviewForRacerStyle(PowerLevelTarget, ...)`) and asks `FindPowerLevelForPlayer` (R).
- Campaign difficulty tune sets (MenuRecon, P): `TNS_Diff_AiHard`: `CampaignTuneConfig.AiPowerLevelModifier +4`;
  `TNS_Diff_AiNightmare_Tour3`: `AiPowerLevelMultiplier +0.1`, `AiPowerLevelModifier +12`; `TNS_Diff_AiEasy`: pacing
  only (`AiMaxTimeAheadMultiplier x0.65`, `AiMinTimeAheadModifier -3`).
- `FCampaignTuneConfig` is campaign-only (R; KNOWLEDGE §5): our quick races don't read it. So in our races the
  bots' power level most likely just follows yours - which fits tonight's result (2026-11-11 night: your parts
  7 -> 6, Biddy +6 s -> +10 s behind; few runs, noisy).
- The old finding "bot part levels don't change pace" (KNOWLEDGE §5, Underground) measured average speed (361-369
  kph either way) **with the rubber band on**, which pins the bots to your pace anyway. Not valid for us now.
- **Test:** at load, raise every bot's race-copy `UpgradeSlots` levels (and / or `OverridenPowerLevel`) above yours
  (+1, +2, +3 levels), the race otherwise unchanged; measure the bots' finish times.

## 2. Tune sets
- `UTuneSet { Operations, PlaneOperations, CoreVehicleOperations : TArray<FTuneOperation> }`; `FTuneOperation
  { Priority, FloatParam, IntParam, Vector2DParam, VectorParam, Operation (ETuneOperations: BoolSetTrue/False,
  FloatAdd, FloatSubtract, FloatMultiply, ...), Category (FName), Property (FName) }` (R). Read from Lua before (P).
- AI tune sets in the paks (R): `TNS_AI_General` (on every bot via `DA_AIConfig.GeneralAITuneSet`, P),
  `TNS_AI_ReducedPower`, `TNS_AI_Catchup_Boost` (catch-up's boost; also `URaceAIDrivingStyleDef.CatchupTuneSet` and
  `ARacingGameMode.CatchupTuneSet`), `Aggression/TNS_AI_Aggression_Boost`.
- Applying one: `AVehiclePawn:RequestApplyTuneSet(TuneSet, numTimesToApplyTune)` / `RequestRemoveTuneSet` (R); the
  vehicle keeps a count per set (`TMap<UTuneSet*, int32> SetsApplied` - a TMap, don't read it).
- **Unknown until read in game:** what each AI tune set changes (the vehicle stats are named at run time:
  `FVehicleTuningConfig` is empty in the dump, so the Category / Property names come from the assets).
- **Tests:** (a) read all four; (b) if `TNS_AI_General` / `ReducedPower` hold handicaps, neutralise them in memory
  (FloatParam to the neutral value; put back at the menu); (c) apply `TNS_AI_Catchup_Boost` once to every bot at
  the start, never removed: a constant boost.

## 3. Driving styles
`URaceAIDrivingStyleDef` (R), per vehicle type (`DS_Car_Base` is DA_AIConfig's `Car`, P):
- **Boosting:** `MinBoostTime`, `MinRacePacingFactorForBoost`, `MinThrottleForBoost`, `MinEnergyForAfterburner`,
  `MinTimeBetweenBoosts`, `BoostTopSpeedThresholdRatio`, `MaxDegreesOffHeadingForBoost`, `RamjetExtrapolationTime`.
  If bots boost more cautiously than a good player, this is free pace.
- **Steering / lines:** `MinLookAheadDistance`, `MaxLookAheadDistance`, `LookAheadFactor`, `MinAimPointDistance`,
  `MaxAimPointDistance`, `CornerExtrapolationTime`, `VelocitySteeringWeighting`, `SteeringPIDConfig`,
  `ThrottlePIDConfig` (`FPIDConfig`, 16 bytes: the controller gains), the `...Frozen` variants.
- **Traffic:** `AvoidanceWidthMultiplier`, `AvoidanceLengthMultiplier`, `DangerOutsideExtents`;
  `DA_AIConfig.ExtraEvadeLength`, `MinAvoidDistanceVehicleAndObstacle`.
- Per type: bike `ActivateEnergyBraking...`; car `DriftSteeringPIDConfig`, `DriftingVelocitySteeringWeighting`;
  skimmer `KnifingSteeringPIDConfig`, `KnifingVelocitySteeringWeighting`.
- Risk: steering gains can make bots unstable (more crashes). Boost rules are the safer first test.
- **Caution:** the test autopilot drives your car with the same AI, so it probably uses `DS_Car_Base` too: change a
  style and the autopilot changes with it. Measure with your car held on the line (hold.txt), not against it.

## 4. Archetypes and the AI-only affixes
- `ERacerArchetype`: Ace 0, Elite 1, Challenger 2, RiffRaff 3, Loser 4, Rival 5, Boss 6, Player 7, Custom 8 (R).
  `FRacerArchetypeConfig { GameModePacingOverrideMap (TMap), PowerLevel (TOptional), AggressionOverride,
  PercentageChancePerfectStart (TOptional) }` - unreadable from Lua (KNOWLEDGE §5). Our tiers (Elite: Sen Fira,
  Biddy Blas, Lyren Shok; Challenger: Goli & 02-R0) came from the campaign research, not from our races. If the rest
  of a quick-race field is RiffRaff / Loser with lower power levels or pacing overrides, that's a built-in spread.
  Test indirectly: read each bot's race-copy `PowerLevel` at load (lever 1's recon shows it).
- `AFX_AI_TemporarilySlower`, `AFX_AI_SlowerCrashRecovery` (`/Game/Griffin/AI/`, in ModRecon's affix list): AI-only
  affixes. **Guess:** the forced-error and crash handicaps. Forced errors are already off from 100cc; whether the
  slower crash recovery is on every bot is unknown. Test: log the bots' affix slots and active passives at load.

## 5. Measuring without the autopilot getting in the way
- **Held races** (TestAutopilot v1.5 `hold.txt`): your car never leaves the line; the 11 bots race each other. Their
  finish times (`[gaps]` / `EventFinishTime`) are a clean measure of their pace under each change - nothing about
  you or the autopilot. The race ends for us as a DNF (the panel gap: TASKS "A DNF skips the results panel"); fine
  for a test.
- One change per batch against an untouched baseline, 3 races each, one track (The Giants' Graveyard 150cc: a
  sprint, ~95 s for the best bot, no DNFs in the study). Count crashes (bots' `EventFinishTime` spread, screenshots).
- Then the best one or two with the autopilot driving, to see the margin against "a clean driver".

## Plan
1. **Recon mod** (tools/recon/AIDriveRecon, read-only first): at the main menu, log every field of DS_Car_Base /
   DS_Bike_Base / DS_Skimmer_Base, the operations of the four AI tune sets, the two AFX_AI affixes' definitions,
   DA_AIConfig's avoidance fields; in a race at load, each bot's race-copy `PowerLevel`, `OverridenPowerLevel`,
   `UpgradeSlots` levels and affix slots. One launch, no writes. (Owner away.)
2. **Write tests**, each behind a key that only sets a flag, memory only, put back at the menu: (a) bots' parts +2;
   (b) catch-up boost applied once at the start; (c) driving style boost rules relaxed; (d) the AI handicap tune sets
   neutralised (only if step 1 shows they are handicaps).
3. **Held-race batches** (~15-20 races, about 1-1.5 h of game time, owner away), then a report and a proposal for the
   AI profiles.
