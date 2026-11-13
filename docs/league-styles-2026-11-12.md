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
