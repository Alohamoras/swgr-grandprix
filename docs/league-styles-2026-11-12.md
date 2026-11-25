# League styles: speed or style? (2026-11-12)

The owner (2026-11-12): "are the 3 classes really about speed, or are they different styles of racing, i kind of
like this idea". Started with v0.28.3: RIFF-RAFF renamed **JUNKER** and given +2 afterburner and ramjet - "racing a
piece of junk that can go faster than it probably should". Owner: yes to the direction and to both first steps below;
captured here to come back to (TASKS.md section 1b).

## The idea
The speed still rises league by league, but what you remember is each league's character. Every league has four
handles we already control:

| | JUNKER | CHALLENGER | ACE |
|---|---|---|---|
| **The car** (config `Leagues[].parts`, per slot) | too much engine on bad bones: afterburner and ramjet high (4), cornering / resilience / drift stock - fast on straights, a handful in corners | balanced (5 everywhere) | everything high (9): full power, precise |
| **The field** (`AI.Profiles`: aggression, pacing; `AI.Strength`) | banger racing: more aggressive bots, more shoving; some mercy (slowdown 0.4) | a real rivalry: the Elite fight you for the cup (v0.28 strength) | clean and fast: the best pilots, few mistakes |
| **The tracks** (the random draw, `Pools`) | wide, forgiving circuits; little weather | a mix, reverse layouts | weather and night: the hard variants |
| **The kit** (`Leagues[].abilities` / `mods`) | one ability, no tune-ups: just drive | tactics: abilities + one tune-up | full loadout: the right pack for the conditions matters |

It ties into the loadout options (docs/loadout-options-2026-11-12.md): Ace is where weather and packs count.

**Caution:** a style has to be felt in the first race, not read on the poster. Junker's lopsided car does that by
itself; the others need differences big enough to notice.

## Agreed next steps (owner: yes to both)
1. **Junker = banger racing:** the bots more aggressive at Junker. Lever: `AI.Profiles.riffraff.aggression = { chance
   = x, cooldown = y }` on `AggressionConfig.VersusPlayer` (game: 50 % chance, 2 s cooldown) and maybe `VersusAI`
   (100 %, 4 s) so they shove each other too; pressure -1 today also lowers aggression (-0.35) - raise it. Check in a
   cup that it's fun, not unfair (Junker is the entry league).
2. **Ace = weather and night:** each Ace cup's draw prefers condition variants (snow, scorching, wet, night, mines,
   storm) - the "leaning by league" idea (TASKS section 4). Lever: gp.lua `K.draw` with a per-league preference
   (config, e.g. `Leagues[].lean = 'conditions'`); Junker could lean to clear forward layouts the same way.

## Later (not agreed yet)
- Challenger's identity beyond strength: reverse layouts, the rival talk on the standings.
- Junker's car: lower cornering / resilience below stock is not possible (stock = 0); more engine is the only way.
- Junker's tracks: lean to wide, forgiving layouts (which ones - to list from docs/tracks-by-planet.md).

## 2026-11-25: the car per league, decided (owner)
Owner, 2026-11-25: "for ace let's set everything to 10. for junker don't need to lower crash threshold, having a higher
wreck limit would be nice - and take the afterburner and ramjet to 10." And on Ace: "i really like the clean
professional field idea". Plan only; work items in TASKS.md §1b.

| | JUNKER | CHALLENGER | ACE |
|---|---|---|---|
| **Feel** | too much engine on a scrapyard chassis: rockets down the straights, wobbles in the corners | balanced, even, nothing extreme | the money league (F1): everything maxed, a clean professional field |
| **Parts** (`Leagues[].parts`; slots 0 Cornering, 1 Acceleration, 2 Resilience, 3 Boost, 4 Battery, 5 Advanced) | `{ [1] = 10, [3] = 10, [4] = 2 }`: afterburner and ramjet 10 (were 6), battery 2, cornering / resilience / drift stock 0 | `7` everywhere (was 5) | `10` everywhere (was 9) |
| **Wrecks a race** | **5** (the game's own is 3): §1g item 8, counted by the mod, HUD pips to match | 3 (the game's) | 3 (the game's) |
| **The field** | banger racing (§1b step 1: more aggression) | the Elite fight you for the cup | **clean and professional:** little contact, no forced errors, quick and precise; you lose to pace, not to a shove |
| **Crash threshold** | stock (owner: no lowering) | stock | stock |

### What the numbers do
- Every bot races a copy of your launch build (KNOWLEDGE §5), so each league's car is the **whole field's** car. Junker's
  field slides and wrecks too, which is the banger feel for free, and the higher wreck limit keeps that chaos from
  ending your race.
- Top speed rises steeply with part level (all six slots: 6 → 618 kph, 10 → 741). Ace at 10 is the fastest the mod has
  run (the old 200cc at 9 was "fast and brutal, i crash a lot"). Junker's engine at 10 on a 0-grip chassis probably
  beats Challenger's 7s on the straights, which is "fast-ish" as intended. Its corners decide the race.
- **Pilot strength has no room at 10.** `AI.Strength` lifts tiers' parts (`ace = { elite = 2, contender = 1, weak = -1 }`).
  With your car at 10 there is nothing above 10, so Elite, contenders and you would all race the same car and only the
  weak tier would differ. Shift Ace down: `ace = { elite = 0, contender = -1, weak = -3 }` (the Elite as fast as you,
  the rest a step and three steps back). Junker's `elite = 1` still lifts the 0 slots (cornering, grip), so the Elite are
  the ones who corner well there, a good fit. Challenger at 7 + 2 = 9 has room. The thrust dial (§1g item 3, untested)
  would make this independent of the parts if it works.

### Ace: the clean professional field
Levers on `AI.Profiles.ace` (ai.lua, all written at launch and put back at the menu):
- `aggression = { chance = 0.25, cooldown = 2 }` on `AggressionConfig.VersusPlayer` (game: 50 %, 2 s): rare ramming.
  The same for `VersusAI` (game: 100 %, 4 s) through `config`, so they race each other cleanly too.
- Pressure 0.5 today also adds aggression (+0.5 at pressure 1, interpolated). The explicit aggression above comes after
  it and wins. Keep the pressure for pace.
- `errors = 0` (already), `perfectStart = 45` (already). Elite back rows (already, `AI.BackRows.ace`): the whole field quick.
- Abilities stay (level 3, the pilots' kits) as racing tools. Open (owner): bias the Ace bots to defensive / utility
  families (shield, scrubber, vent, surge) for a cleaner look, or keep their full kits.
- Check: the `[gaps]` spread at Ace should shrink (fewer crashes, a tighter field). The 2026-11-25 Ace log had a wet
  sprint with a 146 s spread from crashes.

### Built: v0.34.0 (2026-11-25), L1 - the parts and the strength shift
Config only (`Leagues[].parts`, `AI.Strength.ace`, taglines, briefs); tests updated; installed for the owner's test.
Two corrections to the plan above, found in the code while building:
- **"Junker's `elite = 1` still lifts the 0 slots" is wrong.** loadout.lua `L.botParts` only moves a slot that has a live
  tune set (a level-0 slot has none - the v0.28.4 crash). At Junker the Elite's +1 goes onto the afterburner and ramjet
  (10 -> 11 stacks); their cornering stays stock like everyone's. The Elite are the ones with even more engine, not the
  ones who corner well.
- **"Nothing above 10" is unproven.** Our mods write 10 stacks at level 10, but the game's own level 10 is 13 stacks
  (KNOWLEDGE §5), so a stack count of 11 or 12 may well still add speed. The shift to `{ elite = 0, contender = -1,
  weak = -3 }` is built as decided; if the owner wants the old shape back (Elite above you), a held race at Ace with
  `{ elite = 2 }` and the `[builds]` lines would show whether 12 stacks count.

### Knock-on
- **HEAT (docs/heat-2026-11-25.md):** *Detuned* becomes *Budget cap* (10 → 8 / 6), the money league's handicap. *Grudge*
  undoes the clean field on purpose (heat makes them dirty).
- **Taglines / briefs** (`Leagues[].tagline / brief`): Junker "Scrapyard junk with too much engine" still fits. Challenger
  "Balanced rigs - ..." and Ace "Money, maxed out, and a clean field" (wording at build time).
- DESIGN.md §5b's league table is updated when built, not now.
