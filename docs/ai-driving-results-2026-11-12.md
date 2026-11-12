# Better AI drivers: step 1 results (2026-11-12)

Step 1 of TASKS.md section 1: a read-only scan. One launch with the owner away (16:49-16:51), save backed up and
restored (md5 f87ec478...). Raw data: `tools/recon/MenuRecon/ai-2026-11-12/menurecon-ai.log` (the menu dump) and the
`[builds]` lines of a Challenger Jakku race 1 load (Debris Dunes), copied below in short. The older dumps
(`tools/recon/MenuRecon/menurecon-20261110-b.log`) had DS_Car_Base and three AI tune sets already.

## What we found

### 1. Every bot drives an exact copy of your car
At load, all 11 bots' race copies (four vehicle builds each, archetypes 0-3, all `VBD_Car_Base`) carry **your launch
build**: the same six part upgrades at your league's level (Challenger: `Upgrade_Grip_Max`, `_Acceleration_Max`,
`_Resilience_Max`, `_Boost_Max`, `_Advanced_Max` at 5 stacks, `Upgrade_Battery_05`), power level 30, and your tune-up
affixes (which loadout.lua then sorts out). `OverridenPowerLevel` -1, no applied passives or modifiers.
- **Nothing in the cars tells the pilots apart.** Sen Fira's car is Malis Vazosk's car is yours. Whatever makes one
  pilot faster comes from the driving (the shared driving style) and the racer archetype's pacing settings (a TMap we
  can't read), so "the Elite are better" barely shows - which fits the owner's results (weak pilots winning).
- It explains the 2026-11-11 finding: a slower car for you made the bots slower too - it's the same car.
- **The lever exists:** the copies can be edited at load (abilities already are), so each pilot can get their own
  parts level - "pilot strength + form" is possible. Untested: whether the race applies a copy's changed stacks.

### 2. No hidden handicaps on the bots' cars
- `AFX_AI_TemporarilySlower` = `TNS_AI_ReducedPower` (Power -10) on a timer, then removes itself.
  `AFX_AI_SlowerCrashRecovery` = an effect after a crash reset. **Neither is on any bot at load**; most likely the
  game's forced-error system adds them during a race (forced errors are off at Challenger and Ace).
- `TNS_AI_General` (on every bot) **helps** them: a full afterburner at the start, less damage from crashes, more
  shove from explosions. Not a handicap to remove.
- `TNS_AI_Aggression_Boost` is a real speed boost (acceleration x3 low / x1.5 mid / x1.1 high speed, +10% afterburner
  top speed, ramjet acceleration) given while a bot is being aggressive. `TNS_AI_Catchup_Boost` is far bigger
  (acceleration x13 low speed, afterburner acceleration x3...): too strong to use as a constant boost.

### 3. The boost rules are cautious, the bike's most of all
| Driving style | Car | Skimmer | Bike |
|---|---|---|---|
| MinEnergyForAfterburner (needs this much energy to boost) | 0.4 | 0.4 | 0.5 |
| MinBoostTime (each boost lasts at least, s) | 3.0 | 3.0 | 2.5 |
| MinThrottleForBoost | 0.1 | 0.1 | **0.9** |
| MaxDegreesOffHeadingForBoost | 55 | 55 | **30** |
| BoostTopSpeedThresholdRatio | 0.8 | 0.8 | 0.9 |
| MinTimeBetweenBoosts (s) | 1.0 | 1.0 | 1.0 |
| MinRacePacingFactorForBoost | 0.99 | 0.99 | 0.99 |
| RamjetExtrapolationTime (s) | 0.7 | 0.7 | 0.7 |
A bot waits until it has 40-50% energy and then commits to a long burn, and a bike only boosts nearly flat out and
nearly straight. That fits "they don't use the afterburner or ramjet very well". Steering: look-ahead 5250-10000
(car) / 2250-10000 (bike, skimmer), aim point 1500-4800, avoidance width 0.8-1.0.

### 4. The part slots, confirmed
`EVehiclePartSlot` 0 = Grip, 1 = Acceleration, 2 = Resilience, 3 = Boost, 4 = Battery (one upgrade per level, not
stacking), 5 = Advanced. So Riff-Raff's parts `{ [1]=2, [3]=2, [4]=2 }` are Acceleration, Boost and Battery. (Which
on-screen bar each drives - AFTERBURNER, RAMJET... - is still a guess by name.)

## Step 2: ready to run (test-only switch, v0.27.7)
A file `experiment.lua` in the mod folder, read at every launch (nothing happens without it):
```lua
return {
  label = 'boost-a',                 -- logged with every line
  event = "THE GIANTS' GRAVEYARD",   -- the race launched instead of the cup's (a title from the pools)
  styles = { Car = { MinEnergyForAfterburner = 0.2, MinBoostTime = 1.5 }, Bike = { ... }, Skimmer = { ... } },
  config = { ForcedErrorDuration = 4 },  -- more DA_AIConfig fields
  botStacks = 2,                     -- every bot's stacking part upgrades +2 at load
  botStacksBy = { ['Malis Vazosk'] = -1 },  -- per racer, instead of botStacks
}
```
Styles and config are written like the AI config (originals in the save, put back at the menu and after a crash);
the bots' parts go with the race world. Each race logs `[exp] result "<label>" <race>: <every racer's time>`.

**Batches** (held races: TestAutopilot `hold.txt`, your car stays on the line until the bots finish, then the
autopilot takes it home; Challenger; The Giants' Graveyard, then Cloister Run (snow) for the best one):
| Batch | experiment.lua | Races | Question |
|---|---|---|---|
| base | `{ label = 'base', event = ... }` | 3 | the bots' times today, the spread |
| boost | Car / Skimmer: MinEnergy 0.2, MinBoostTime 1.5, MaxDegrees 70, Threshold 0.95; Bike: MinEnergy 0.3, MinThrottle 0.5, MaxDegrees 45, Threshold 0.95 | 3 | does boosting more make them faster, or crash more? |
| parts | `botStacks = 2` | 3 | does the race use the copy's parts? how much is a level worth to a bot? |
| strength | `botStacksBy`: Elite +2, Challenger tier +1, the rest 0, Malis / Ary -1 | 3 | does a pilot order appear? |
About 12-15 races, ~1 h. Then the report and a proposal per league.
