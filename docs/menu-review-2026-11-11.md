# Menu review (TASKS B12, 2026-11-11)

A walk through every Grand Prix screen on v0.15.1 / v0.16.0, with the owner's save (restored after), plus one full
100cc Lantaana cup driven by the autopilot. Screenshots: `~/Projects/swgr-underground/autotest/shots/v15-*.png` and
`v16-*.png`. Judged against docs/PHILOSOPHY.md and the owner's menu rules: never more than two menus deep, no words
you don't need, never scroll, simplicity. **Report only: nothing here is built until the owner picks.**

## The flow today
```
game main menu --F6 / tab--> HOME (50 100 150 200 / GARAGE RESET)
                               |-- class --> CUPS (5 planets / GALACTIC CUP / TITLE RACE) --cup--> race 1
                               |                                   standings --NEXT RACE--> race 2..4 --> CUP RESULT --> CUPS
                               |-- GARAGE (racer, 4 abilities, 2 tune-ups)
                               '-- RESET --> confirm
```
- Presses from HOME to a race: two (class, cup). From the game's menu: three plus finding the tab (B11 fixes that).
- Depth: two everywhere. No scrolling anywhere. Both rules are met.
- Between races it's one press (NEXT RACE). Good: this is the "one more race" loop working.

## What works
- The loop is short and the standings page is the strongest screen: stakes line ("LEADING BY 10 OVER KATJA MOX,
  2 RACES LEFT"), NEW RECORD, the MOVED column, the next race named on the tile.
- After a cup, the cups page shows every race's best time and best lap: the near-miss data is there.
- The garage reads well since v0.14: one line of help on top, the focused tile's effect in the info line.
- v0.15 shows correctly: "Nik Skandaro - landspeeder", "Kestar Bool is locked. To unlock: win the 150cc title."

## Findings, ranked (most effect on engagement first)

### 1. The cup result is an anticlimax
The end of a cup, the moment that should feel best, is the standings table with "GOLD TROPHY" written above it.
Nothing says what the trophy brought you or what's next. CONTINUE drops you on the cups page with no hint.
(`v16-cup-end.png`)
- **Proposal 1a:** a result screen of its own: the trophy art large (the trophy icon we already use, tinted
  bronze / silver / gold), "PERFECT CUP" as a badge, the final top 3 only (not 12 rows).
- **Proposal 1b:** one "what's next" line: what this unlocked, or how close the next unlock is ("GALACTIC CUP: 2 more
  trophies at 100cc"), or the near miss ("1 point from gold").
- **Proposal 1c:** CONTINUE lands with the focus on the next cup without a gold, not the one just won.

### 2. The rival is invisible in practice
In a full cup no rival appeared: the rule needs about 30 points of tally across races, so at a class you haven't
raced much there is none, and the standings never mention one. HOME says "Champion: GRIFF HALLORAN", which doesn't
say what a champion is or why it matters. (PHILOSOPHY point 3 is the one that most isn't landing.)
- **Proposal 2a:** pick a rival from the first race of the first cup at a class (the racer who finishes nearest
  you), then let the existing rule take over.
- **Proposal 2b:** mark the rival's row on the standings (a colour and a small "RIVAL" tag), every race, even when
  the stakes line is about someone else.
- **Proposal 2c:** drop "Champion" from HOME, or say what it is ("Title holder: Griff Halloran").

### 3. The focused tile hides its own label
On every screen, the focused tile brightens its art and the small top label vanishes: "1/6 GOLD" on 50CC / 100CC,
"BRONZE TROPHY" on LANTAANA CUP, "JAKKU" on the Jakku tile, "RACE 2 / 4" on NEXT RACE. The darker art in v0.15.1
helped the big names but not the labels. (`v15-home-100.png`, `v16-cups-100-lantaana.png`, `v16-standings1.png`)
- **Proposal 3a:** a dark strip behind the top label (and the subtitle) on every tile, so it reads on any art.
- **Proposal 3b:** or keep the tile dimmed when focused and show focus with the border only.

### 4. HOME doesn't say what to do next
HOME lists four classes with counts, but nothing points at the next goal. PHILOSOPHY point 6 ("one thing just out
of reach") needs it on the first screen you see, more so once B11 boots straight into it.
- **Proposal 4a:** the focus starts on the class you last raced (or the one with the nearest unlock).
- **Proposal 4b:** one line under the title: "Next: a trophy in the Ando Cup at 150cc opens the GALACTIC CUP".

### 5. The game's footer offers "Restart Campaign"
Every page of ours shows the game's own footer: "Select / C Restart Campaign / Settings". Restart Campaign has
nothing to do with the Grand Prix and is a scary button to have one key away. (All screenshots.)
- **Proposal 5:** check what C does on our page (not pressed in this review); hide the footer's C entry while our
  tab is up, or the whole footer if that's simpler.

### 6. Words you don't need
- The cups page repeats "LANDSPEEDER, every part at level 3, abilities level 1. Select a cup to start it: the first
  race launches straight away." on every visit. The instruction is learnt once; the parts level isn't something you
  act on. Proposal: drop the line, or keep only "Parts 3 · Abilities 1" small.
- HOME's "The Galactic League: four divisions, a season of cups in each." Proposal: drop it.
- The standings say "You: 1st in this race - 2:05.83 (best lap 2:00.53)" on a sprint, where best lap = the race.
  Proposal: no best lap on sprints.
- The leave question and the reset question are fine.

### 7. Counts that don't match
HOME shows "1 / 6 GOLD" on three classes and "5 / 6 TROPHIES" on 200CC; the trophy icon on a cup tile looks the
same for bronze and gold. Proposal: the same measure on every class tile (trophies, with golds as a second number
or a star), and the cup tile's icon tinted by its medal.

### 8. Standings: seconds are missing
The stakes are in points only. The `[gaps]` log already has the seconds ("next behind Katja Mox +7.80 s").
Proposal: add the margin to your line: "You: 1st, 7.8 s ahead" or "2nd, 0.4 s behind Biddy Blas". This is the
near-miss PHILOSOPHY point 4 asks for, and it also tells the owner how the rubber band feels.

### 9. Garage: four ability tiles look the same
All four ability tiles use the same art, so they read as one block. Proposal: per-ability art if the paks have
icons (check `tools/art`), otherwise a different tint per slot.

### 10. The two confirms disagree
Reset puts NO first; leave the cup puts YES first (the owner chose that in v0.9). Either is defensible; noting it
so it's a choice, not an accident. Suggest keeping it: the risky action (reset) defaults to NO.

### 11. Small layout jump
The 150cc / 200cc pages with the title tile focused leave a gap between the info line and the tiles, while the
other pages fill it with the race list. Minor; proposal 6 would mostly remove it.

## Mockups

Cup result (proposal 1):
```
 CUP RESULT
 [ GOLD TROPHY art ]   LANTAANA CUP · 100cc · 60 pts · PERFECT CUP
                       1 YOU 60   2 Griff Halloran 33   3 Goli & 02-R0 32
                       Next: 2 more trophies at 100cc open the GALACTIC CUP
 [ CONTINUE ]
```
HOME (proposals 4, 6, 7):
```
 GALACTIC GRAND PRIX
 Next: a trophy in the Ando Cup at 150cc opens the GALACTIC CUP
 [50CC 6 trophies ★1] [100CC 5 ★2] [150CC 5 ★1] [200CC 5 ★0]
 [GARAGE Nik Skandaro] [RESET]
```

## Suggested order to build
1 (cup result), 2 (rival), 3 (label strip), 4 (next goal on HOME), 5 (footer, after checking what C does), then
6-9 as one small polish pass. 10-11 need no work unless the owner wants it.
