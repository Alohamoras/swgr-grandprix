# Galactic Grand Prix: what makes it engaging

Agreed with the owner on 2026-11-10. This is the yardstick for new features and tuning: when a choice is unclear,
pick the option that serves these points best. The work plan lives in TASKS.md, section "Engagement plan".

## The short version
A short loop with clear stakes, where getting better visibly pays off.

## The seven points, in order of weight

1. **Your skill has to show in the results.** This is the biggest risk in the mod. The game's rubber band keeps the
   AI at your pace, so a perfect race and a sloppy one can both end in a close fight for 2nd. That feels exciting for
   a while, then hollow. The fix is to loosen the rubber band as you climb the classes, so a clean race lets you pull
   away. Get this right and everything else lands harder.
2. **One more race.** A cup is four races and about ten minutes, which is ideal. Cups are not resumable (v0.9), so a
   cup is something you finish. The standings screen should always show the stakes, like "2 points behind Biddy
   Blas, one race left".
3. **A rival, not just a field.** People get hooked on beating a person, not 11 bots. One named racer per class who
   keeps finishing near you, is called out on the standings screen, and is the one you face in the title race.
4. **Near misses.** "0.4 s off your record" or "1 point from gold" is what makes you press NEXT RACE. Records are
   already saved. This is about showing them at the right moment.
5. **Choices that matter.** Conditions folded into the cups make the garage meaningful: HEAT SHIELD before a
   scorching cup, ICE COLD before a snowy one. Today the loadout is set once and forgotten.
6. **Goals you can see at a glance.** The trophy grid and gold counts already work. Space the unlocks out so there is
   always one thing just out of reach, never a flood.
7. **Difficulty you choose, not difficulty that punishes.** The hardest content is optional and feels fair.

## What we do next, in order

1. **Rubber band per class.** Generous at 50cc, then less and less, so a win at 150cc is earned. Builds on the AI
   profiles (ai.lua, config `AI.Profiles`). Mostly tuning, and only the owner's racing can judge it, so it goes
   first: the other two get better once it feels right.
2. **Conditions folded into the cups.** See "Cups" below.
3. **A rival per class.** Shown on the standings screen, and the opponent in the title race.

## Decisions that follow from this (owner, 2026-11-10)

### Cups
- One cup per planet, four races, the same planet every time. No remix cups, no conditions cups.
- The race list changes with the class, so the same cup gets harder in character as well as speed:
  - 50cc: the classic forward layouts (today's planet cups).
  - 100cc: the reverse layouts.
  - 150cc: the conditions (night, wet, scorching, snow, mines, storm).
  - 200cc: the 150cc lists at the extra speed.
- A cup never races the same base layout twice (no "Debris Dunes" and then "Debris Dunes, wet").
- A cup is fixed per class, so records and golds keep meaning one thing.
- The Galactic Cup stays as the finale: a trophy in the five planet cups opens it, and a trophy in it opens the
  title race. The Outer Rim Cup goes; its tracks move into the planet lists.
- The cups page holds 7 tiles: five planets, GALACTIC CUP, TITLE RACE.

### 200cc
- 200cc stacks everything: parts 10 (about 740 kph average, up to 812, against about 650 at 150cc) and the harshest
  AI profile. The owner enjoys 100cc and 150cc and finds 200cc unfriendly.
- 200cc becomes an optional extra, like Mario Kart's: nothing depends on it, parts 9 instead of 10, the 150cc AI
  profile, no harsher conditions than 150cc. Tune it after the owner races it; cut it if it still feels silly.

### Cups are not resumable (v0.9.0)
Like Mario Kart, leaving a Grand Prix loses it. See DESIGN.md §13.
