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
   league leader (the best bot of your last cup at that league), and Kestar Bool is the final boss after the Ace title.
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

### Cups (owner, 2026-11-12: random cups, v0.26)
- One cup per planet, four races, always on that planet - **drawn at random when you pick the cup**: four of the
  planet's base tracks, each with a random variant (forward / reverse, night, wet, snow, mines, scorching, storm...).
  Like a real season: you don't know the line-up until you enter, and the start screen shows it before you race, so
  the tune-ups are picked on what you got.
- **The same rule in every league**: the league sets the speed, the abilities and the AI, not the tracks. (Ideas
  kept for later, not now: leaning the draw by league, e.g. Riff-Raff mostly plain forward layouts; an occasional
  "Grand Tour" cup with every track of a planet.)
- A cup never races the same base layout twice (no "Debris Dunes" and then "Debris Dunes, scorching").
- **Records stay per exact track variant**; a medal means "won a Jakku Cup at that league", whatever was drawn.
- The Galactic Cup stays as the finale: three races on three different planets, then The Galactic Gauntlet at Derven
  Acos. A trophy in the five planet cups opens it, and a trophy in it opens the title race.
- The cups page holds the five planets, GALACTIC CUP and TITLE RACE (and Kestar Bool on the Ace page once the Ace
  title is won). The title race runs on the first track of the leader's most recent cup.
- (Before v0.26 a cup was fixed per class: 50cc classic, 100cc reverse, 150 / 200cc conditions. The owner wanted
  "more realistic ... simulate a real cup".)

### Leagues (owner, 2026-11-12: three leagues replace the four cc classes; was "200cc")
- **RIFF-RAFF, CHALLENGER, ACE**, the game's own racer ranks ("cc" is Mario Kart's word). The league is described by
  a tagline on the focused poster (v0.27: the 1-3 chevrons read as progress), the facts under the name on the
  cups page.
- Riff-Raff: no upgrades, level-1 abilities, no tune-ups, an AI with some mercy. Challenger: parts 5, level 2, one
  tune-up, an honest AI. Ace: parts 9, level 3, two tune-ups, the honest AI a notch harder.
- A clear ladder: Riff-Raff is open, Challenger opens from Riff-Raff's planet cups, Ace from Challenger's. Each league
  has its own title race; Kestar Bool, the champion and an Ace himself, is the final boss after the Ace title.
- This answers "three classes or four" (200cc "may still be cut"): the old 200cc is Ace, the old 100cc is gone.
  Moving to leagues started every save afresh (the owner's choice: the garage kept, the medals not).

### Cups are not resumable (v0.9.0)
Like Mario Kart, leaving a Grand Prix loses it. See DESIGN.md §13.
