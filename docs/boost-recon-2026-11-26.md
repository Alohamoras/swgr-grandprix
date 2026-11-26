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

## Candidates (owner's pick; nothing built - "only if one variant is clearly right")

- **A. Bots ramjet less readily:** `MinRacePacingFactorForBoost` up on the three driving styles (b3's lever, a smaller
  value than 100; **the game's value is 0.99** on all three styles, i.e. a bot may boost whenever its pacing factor is
  about 1 or more - nearly always). Felt only by you, since your car is not driven by the style. Risk: the field
  slower on the straights. What "pacing factor" means exactly is not known; values like 1.1 / 1.3 are the ones to try.
- **B. Speed matching off for good** (b2's lever; `SpeedMatchingMaxMatchers` is already 0 in every league profile, the
  zone switch is separate).
- **C. One owner race each** with A and B (the dev build's experiment.lua), then pick by feel - the real test, since the
  question is how it feels when *you* boost.
