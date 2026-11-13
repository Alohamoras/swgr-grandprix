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

## Step 2 results: 12 held races (2026-11-12, 17:37-18:59)
Challenger, The Giants' Graveyard, your car held on the line (TestAutopilot `hold.txt`) so only the 11 bots raced;
3 races per round. Data: docs/data/ai-held-races-2026-11-12.txt; `python3 tools/ai_held_stats.py <that file>`; the
experiment files in tools/recon/MenuRecon/ai-2026-11-12/. Save backed up and restored (md5 f87ec478...).

| Round | Change | Best bot (s) | Median bot | Last bot | Spread |
|---|---|---|---|---|---|
| base | none | 106.5 | 114.4 | 125.6 | 19.0 |
| boost | boost rules loosened (energy 0.2, burn 1.5 s, 70 deg; bike 0.3 / 0.5 throttle / 45 deg) | 105.8 | 115.0 | 128.2 | 22.3 |
| parts+2 | every bot's parts +2 levels | **102.0** | **111.2** | 124.8 | 22.8 |
| strength | Elite +2, Goli / Griff / Nik +1, Malis / Ary -1, the rest 0 | **101.2** | **110.9** | 128.9 | 27.7 |

Average time per pilot (s):
| Pilot | base | boost | parts+2 | strength (their change) |
|---|---|---|---|---|
| Biddy Blas | 118.5 | 113.4 | 113.1 | **101.2** (+2) |
| Lyren Shok | 118.3 | 116.5 | 114.1 | **104.5** (+2) |
| Sen Fira | 112.8 | 120.0 | 112.5 | **107.8** (+2) |
| Goli & 02-R0 | 115.2 | 119.1 | 119.8 | 111.5 (+1) |
| Ary Quill | 113.9 | 114.8 | 110.4 | 112.2 (-1) |
| Katja Mox | 111.8 | 109.8 | 108.8 | 113.5 (0) |
| Malis Vazosk | 117.3 | 114.1 | 109.0 | 114.2 (-1) |
| Shade | 114.2 | 121.8 | 109.3 | 116.6 (0) |
| Fola Kanjen | 108.9 | 110.3 | 107.0 | 117.1 (0) |
| Griff Halloran | 118.8 | 118.3 | 113.6 | 119.1 (+1) |
| Soren Zaks | 116.8 | 119.5 | 113.3 | 123.4 (0) |

### What it means
1. **Boost rules: no effect.** Loosening them didn't change the times (best -0.7 s, median +0.6 s: noise). Not the
   bottleneck - drop this lever.
2. **The bots' parts work.** The race uses the race copy's parts: +2 levels made the field ~3-4.5 s quicker (best
   -4.5 s, median -3.2 s) on a ~110 s race - about 1.5-2 s a level.
3. **Pilot strength works: the Elite rose to the top.** With Elite +2, Biddy, Lyren and Sen were the three fastest
   on average (101-108 s); in the base races they were mid-pack or worse (113-119 s). The -1 pilots didn't drop much
   (one level is small next to the noise).
4. **The noise is the bots' own mistakes, and it's big.** The same pilot swings up to ~20 s race to race (Shade
   109-122, Sen Fira 107-120 across rounds); the field spread is 19-28 s. Parts move the average, not the
   swings - so even with strength, an Elite will sometimes have a bad race (realistic), but blowouts will still
   happen. The steering / avoidance settings are the only lever left on the swings, and the riskiest (untested).
5. **Against you:** the owner's own Challenger time here is 1:46.39 (2nd behind Lyren 1:43.09, before this test). The
   base field's best averages 106.5 s - level with you; with the strength tiers, ~101 s - a few seconds ahead.

### Proposal (not built; the owner decides)
- **Pilot strength per league** on the bots' parts at load (no rubber band, no catch-up - a fixed car per pilot):
  Elite (Sen Fira, Biddy Blas, Lyren Shok) +2, Challenger tier (Goli, Griff, Nik) +1, Loser / Riff-Raff tier
  (Malis, Ary) -1, the rest as you. Riff-Raff: the same but halved (Elite +1, none below you) - the mercy stays.
  Ace: you're at parts 9; Elite at 10 (the top) + the others as you, unless +2 above the top works (to test).
- **Form:** each pilot +-1 level at random each race (on top), so the order isn't fixed - an underdog can have a day.
- Keep the boost rules as they are. Look at the steering / avoidance numbers later only if the blowouts still bother.
