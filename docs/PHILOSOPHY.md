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
3. **Someone to beat.** People get hooked on beating a person, not 11 bots. The title race is a 1 v 1 against the
   class leader (the best bot of your last cup at that class), and Kestar Bool is the final boss after 150cc.
   (The v0.13-v0.20 rival per class was cut by the owner on 2026-11-11.)
4. **Near misses.** "0.4 s off your record" or "1 point from gold" is what makes you press NEXT RACE. Records are
   already saved. This is about showing them at the right moment.
5. **Choices that matter.** Conditions folded into the cups make the garage meaningful: HEAT SHIELD before a
   scorching cup, ICE COLD before a snowy one. Today the loadout is set once and forgotten.
6. **Goals you can see at a glance.** The trophy grid and gold counts already work. Space the unlocks out so there is
   always one thing just out of reach, never a flood.
7. **Difficulty you choose, not difficulty that punishes.** The hardest content is optional and feels fair.

## How the menus should feel (owner's rules)
Never more than two menus deep; no words you don't need; never scroll; simple, little clutter. Show with pictures
(medals, portraits, art) rather than sentences.

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
- The cups page holds the five planets, GALACTIC CUP and TITLE RACE (and Kestar Bool at 150cc once the title is won).
- Open question (owner, 2026-11-11): one fixed list per class is distinct, but you may want to race every track at
  any class; a cup of every track on a planet would be long. Not settled (TASKS "Discussions").

### 200cc
- 200cc stacks everything: parts 9, the strongest abilities, the hardest AI. Nothing depends on it.
- **It may still be cut** (owner, 2026-11-11). Each class feels distinct today, which is good, but 200cc is so
  powerful that three classes might be better (e.g. parts 0-1 / 5 / 9). Not settled (TASKS "Discussions").

### Cups are not resumable (v0.9.0)
Like Mario Kart, leaving a Grand Prix loses it. See DESIGN.md §13.
