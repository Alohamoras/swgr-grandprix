# Boost recon (TASKS §1k, 2026-11-26): does the field speed up when you boost?

Owner: "explore why the racers in front of you speed up so quickly when you ramjet and afterburner, this is the most
annoying part of the game, it should feel faster to boost and the field just adapts automatically without boosting."

Owner away; test save; GP dev build with `boostrecon.lua` (experiment `boostRecon = true`: every 0.5 s your speed and
boost state, and the racer directly ahead / behind - name, speed, boost state, straight-line distance) and
`tools/boostan.py` (each time you go into ramjet with a racer within 250 m ahead: did it ramjet too within 3 s, its
speed and the gap over the next 5 s). Data: `docs/data/boostrecon-2026-11-26.csv`. TestAutopilot drove; CHALLENGER;
the track fixed to THE WAR FIELDS (2 laps); one race per variant, a fresh game each.

## Results

| Race | Variant | You | Field | Your ramjets with a racer ahead | Racer ahead went into ramjet within 3 s |
|---|---|---|---|---|---|
| b0 | baseline | 1st 1:38.41 | +7.0 s to +41 s | 2 | 1 of 2 (Soren Zaks: 408 -> 510 kph) |
| b0' | baseline, bots +3 parts | 1st 1:38.19 | +13.5 s ... | 2 | 2 of 2 (+104 kph on average) |
| b1 | + `AllowAIToContinuePlayerBoost = false` | 1st 1:39.65 | +2.4 s ... | 2 | 2 of 2 |
| b2 | + speed matching zone off | 1st 1:37.15 | +13.6 s ... | 2 | (both already in ramjet) |
| b3 | + driving style `MinRacePacingFactorForBoost = 100` | 1st 1:50.39 (top speed 523, was ~675) | +0.02 s to ~+8 s | 0 | - |

## What it says

1. **The pattern is real in the data:** every time the racer ahead was not already in ramjet, it went into ramjet within
   3 s of yours (5 of 5), gaining ~100 kph. The game's own boost state (`VehicleBoostComponent.BoostState` 4 = ramjet)
   shows it, not just the speed.
2. **But it may be the track, not you:** the autopilot ramjets only twice a race (~10 s and ~37 s in, the same two
   straights), and the bots ramjet on the same straights. "It replied" and "it boosts where everyone boosts" look the
   same here. Sorting that out needs ramjets at odd places - your hands, not the autopilot.
3. **`AllowAIToContinuePlayerBoost` off changed nothing** (b1). **Speed matching off** (b2): no case to judge (the
   racers ahead were already in ramjet when you went in).
4. **The driving style is shared by the bots AND the autopilot** (`DS_<Car|Bike|Skimmer>_Base`): b3 stopped the bots'
   ramjets only when their pacing factor is very high - and stopped the autopilot's too (523 kph top speed), so b3
   says nothing about the reply. It does say the bots' finishing times hardly need the ramjet (the field finished
   1:50-1:58 against ~1:51-2:08 in b0'). A human player doesn't drive with that asset, so for you b3 would change only
   the bots.

## Round 2 (2026-11-26 afternoon): the base rate, forced ramjets, speed matching off

`tools/boostan.py` now also prints a **base rate**: in 3 s windows where you are NOT ramjetting and the racer ahead
(within 250 m) isn't either, how often does it go into ramjet anyway? Four more races (`tools/boosttest/exp/f0, f2,
f0b, f2b`: bots +5 parts, your ramjet "forced" every 8-12 s; f2 / f2b with the speed matching zone off). Data appended
to `docs/data/boostrecon-2026-11-26.csv`.

| | Racer ahead went into ramjet within 3 s of yours (when not already in one) | ...in a quiet 3 s window (base rate) |
|---|---|---|
| Round 1 (b0, b0', b1, b2) | 5 of 5 | 0 of 7 |
| Round 2, baseline (f0, f0b) | 1 of 3 | 2 of 7 |
| Round 2, speed matching off (f2, f2b) | 3 of 4 | 2 of 6 |
| **All** | **9 of 12 (75%)** | **4 of 20 (20%)** |

- **The reply looks real:** 75% right after your ramjet against 20% otherwise. Still small numbers, but the gap is large.
- **Speed matching off doesn't stop it** (3 of 4) - lever B is out.
- **Forcing your ramjet doesn't work:** `VehicleBoostComponent:Server_ChangeState(4)` did nothing while your ramjet
  wasn't charged (state stayed 2/2/0, ramjet "not ready"); it only "took" when you were already in ramjet (15 of 25).
  So test 2 couldn't make ramjets at odd places. A charged-ramjet path (`URamjet` state 1 first, or the
  `FVehicleBoostRequests_SetRamjetReady` request) is untested.
- **So the next step is lever A in the owner's hands** (docs/boost-fix-test-plan.md test 3): the bots' boost threshold
  `MinRacePacingFactorForBoost` (0.99) up to 1.3, which an autopilot can't test.

## Pods and the ramjet (same session)

`VehicleBoostComponent.RamjetInstalled` is **false on all 8 pods** (true on every car). Setting it true 18 s into a pod
race didn't make any pod ramjet (the boost state stayed 2) - it may need setting while the race loads, and whether
your boost button then works needs the owner's hands.

## Candidates (owner's pick; nothing built - "only if one variant is clearly right")

- **A. Bots ramjet less readily:** `MinRacePacingFactorForBoost` up on the three driving styles (b3's lever, a smaller
  value than 100; **the game's value is 0.99** on all three styles, i.e. a bot may boost whenever its pacing factor is
  about 1 or more - nearly always). Felt only by you, since your car is not driven by the style. Risk: the field
  slower on the straights. What "pacing factor" means exactly is not known; values like 1.1 / 1.3 are the ones to try.
- **B. Speed matching off for good** (b2's lever; `SpeedMatchingMaxMatchers` is already 0 in every league profile, the
  zone switch is separate).
- **C. One owner race each** with A and B (the dev build's experiment.lua), then pick by feel - the real test, since the
  question is how it feels when *you* boost.
