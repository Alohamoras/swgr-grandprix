# The menus: text and layout review (2026-11-25)

Owner: "there's a lot of AI phrased text. I think any text we do put on the screen should have the feel of star wars.
We need to explain enough about the choices so the player understands what they are choosing, but not put extra
information that they might not need." Plus the standing menu rules (main.lua header, 2026-11-10): never more than
two levels deep, no words you don't need, no scrolling.

Every line below was read from the code (main.lua, standings.lua, chain.lua, cupend.lua, prog.lua, cup.lua, config.lua)
and the five screenshots in docs/release/screenshots/. Nothing here is built yet. §1 is the voice to write in, §2 the
screen-by-screen proposals (exact replacement text), §3 the layout changes, §4 the build plan.

## 1. The voice

**The game already shows us how it talks.** Its own copy that we display is the best writing on our screens:
- Racer bios: "Hot-headed; his last shot at a face on a cereal box", "Still in his Imperial Navy armour; flying is
  what he knows", "Races for Kestar until her debt to the Bools is repaid".
- Planet lines: "Starship wrecks boil under the scorching heat of this desert world", "Rivers of acid make this
  planet hostile to life itself".
- Headlines: "Race FINISHED", "GRAND PRIX", tile names in caps.

Third person, present tense, concrete nouns from the setting (rig, credits, grid, circuit, podium, the League, the
Bools, the Outer Rim), one clause of flavour, no explanation of the game's rules. That is the voice for everything we
write: a **paddock announcer at the Galactic League**, not a manual.

**The tells of our own text today** (what reads as written by a machine), and the rule that replaces each:

| Tell | Today | Rule |
|---|---|---|
| A label, a colon, an explanation | "To open: A trophy in all 5 planet cups at JUNKER (3 / 5)", "Shade:  The campaign's racer." | Say it as a sentence or a headline. No "To open:", no "Select:", no "Next:". |
| Parentheses and slashes | "(3 / 5)", "(was 1:37.16)", "Leave the party / stop matchmaking" | No parentheses on screen. Counts as "3 of 5". One alternative, or a comma. |
| Semicolons and dashes as glue | "Immune to Disrupted; Shielded for the first 10 s", "Money, maxed out, and a clean field" | Two short sentences, or a comma. The spaced dash stays only as the separator between fields on one line ("JAKKU CUP  -  SCRAP SPIRAL"). |
| Talking about the game | "The campaign's racer", "the game's own", "pick him in the garage", "this tab" | Never name the software. The garage is a place; the campaign does not exist here. |
| Saying what the picture shows | "race 2 of 4" next to a "RACE 2 / 4" badge, "Vehicle selected" after the tile changed | If the tile, badge or icon says it, the text does not. |
| Control hints in the copy | "B: leave the cup.", "CONTINUE: the main menu (to leave the cup)." | A control hint is a button glyph and two words, right-aligned, never a sentence in the prompt line. |
| Counting things the player did not ask about | "Signature abilities.", "Asks twice", "the standings by total time" | Only what changes the choice in front of them. |
| Capitals | tiles and stakes lines in caps, info lines in sentence case, "Race FINISHED" (the game's) | Headlines and stakes in caps. Explanations in sentence case, one or two sentences. Never a caps sentence with a full stop. |

**What stays as it is:** the stakes lines ("LEADING BY 3 OVER GOLI & 02-R0, 3 RACES LEFT", "GOLD IS YOURS: 12 CLEAR, 1
RACE LEFT"), the near misses ("2 POINTS FROM SILVER", "0.4 S OFF YOUR RECORD"), "NEW RECORD", "PERFECT CUP", the
racer bios, the ability blurbs ("Blast nearby racers away"), the tune-up names. These already read like race copy.

## 2. Screen by screen

### 2a. HOME (the three leagues, RESET PROGRESS)

| Where | Now | Proposed | Why |
|---|---|---|---|
| JUNKER tagline | Scrapyard junk with too much engine | **keep** | The owner's line; it is the voice. |
| CHALLENGER tagline | Balanced rigs and pilots out to make a name | **Proper rigs, and pilots out to make a name** | "Balanced" is a design word (a stat bar), not something a pilot says. |
| ACE tagline | Money, maxed out, and a clean field | **Every credit on the rig. The best pilots in the galaxy** | The list of three reads machine-made. "Clean field" is our AI term; the player will feel it. |
| A locked league (desc) | To open: 5 trophies at JUNKER | **Five JUNKER trophies open it** | No label. The count in words. |
| A locked league (info and press) | To open: A trophy in all 5 planet cups at JUNKER (3 / 5) / "ACE is locked. To open it: ..." | **A trophy in every JUNKER planet cup opens it. 3 of 5 so far.** The press message goes (the info line already says it). | One sentence, the progress as a second. |
| RESET PROGRESS, question 1 | Reset all progress? Every trophy, record and title is cleared. | **Wipe the record books? Every trophy, lap record and title goes.** | In the setting. |
| RESET PROGRESS, question 2 | Are you sure? This can't be undone. | **There is no way back. Wipe them?** | |
| after a reset | Progress reset - a clean start / Could not back up the save - nothing was reset | **A clean slate.** / **The save could not be backed up. Nothing was wiped.** | |

### 2b. CUPS (one league's cups)

| Where | Now | Proposed | Why |
|---|---|---|---|
| JUNKER brief | Hot-rodded junk   -   one ability   -   no tune-ups | **One ability. No tune-ups.** | The tagline on HOME already said what the rig is; here only the rules of the league matter. |
| CHALLENGER brief | Balanced engines   -   two abilities   -   one tune-up | **Two abilities. One tune-up.** | |
| ACE brief | Maxed-out engines   -   three abilities   -   two tune-ups | **Three abilities. Two tune-ups.** | |
| planet cup info | THE WAR FIELDS   -   THE GIANTS' GRAVEYARD   -   DEBRIS DUNES   -   FALLEN EMPIRE / SCRAP SPIRAL | **keep** (the circuits the cup draws from) | The one list a player uses: it is how you pick a tune-up. Option: lead with the planet line, e.g. "Jakku. Starship wrecks boil under the scorching heat of this desert world." above the circuits (the game's own text, config Planets.line, unused today). |
| GALACTIC CUP info | A race on 3 of:   Jakku   -   Lantaana   -   Ando Prime   -   Crait   -   Sentinel I / Then X or Y at Derven Acos / A trophy adds the finale: Kestar Bool, 1 v 1 in the stadium, for the league title | **Three planets, then Derven Acos, home of the Galactic League.** / **Finish on the podium and Kestar Bool waits in the stadium. One race for the title.** | Says what it is and what is at stake, nothing about draw rules. "on 3 of:" is code speech. |
| GALACTIC CUP locked (desc / info) | To open: 5 trophies at JUNKER / To open: A trophy in all 5 planet cups at JUNKER (3 / 5) + the circuits | **Five JUNKER trophies open it** / **A trophy in every JUNKER planet cup opens it. 3 of 5 so far.** | As on HOME. |
| RALLY CUP info | 7 point-to-point stages in tour order, 4 cars; the standings by total time. The night and weather are drawn when you start and kept secret. + the routes | **Seven stages, four racers, the clock decides. Weather and nightfall are unknown until you arrive.** + the routes | Drops "tour order", "drawn", "standings" (rules talk). |
| a locked cup pressed | JAKKU CUP is locked at ACE. To open it: ... | message goes | The info line says it; the lock icon says it. |

### 2c. START (the garage, before a cup)

| Where | Now | Proposed | Why |
|---|---|---|---|
| header | JAKKU CUP / JUNKER | **keep** | |
| pilot tile info | Shade:  The campaign's racer. | **Shade. No family name, no sponsor, just the rig.** (the others keep the game's bios: "Biddy Blas. Hot-headed; his last shot at a face on a cereal box.") | "The campaign's racer" names the software. Name, full stop, bio: no colon. |
| pilot picked (message) | Racing as Biddy Blas. Speeder bike. Signature abilities. | **Biddy Blas. Speeder bike, his own kit.** | |
| a locked pilot (in the info) | Kestar Bool is locked. Beat him in the Galactic Cup finale at ACE. | **Kestar Bool races only for himself until you beat him in the Ace finale.** | |
| vehicle tile info | Landspeeder, speeder bike, or skim speeder. A new pilot starts on their own. The other two wear that rider's scheme. | **Landspeeder, speeder bike or skim speeder, in the pilot's colours.** | The second and third sentences explain the implementation. |
| vehicle picked (message) | Speeder bike selected | message goes (the tile changed) | |
| ability tile info | Shockwave:  Blast nearby racers away. | **Shockwave. Blast nearby racers away.** | Colon to full stop; the blurbs stay. |
| ability picked (message) | Surge picked | message goes (the tile changed) | |
| tune-up tile info | Heat Shield:  Immune to Burning and Frozen. | **Heat Shield. Immune to Burning and Frozen.** The lines with semicolons become two sentences: "Immune to Disrupted. Shielded for the first 10 s." | |
| empty tune-up slot | Tune-up 2 is empty. | **Nothing fitted.** | |
| a slot above this league (info) | Tune-up 2 opens at ACE. / "(Tune-up 2: from ACE.)" | **Opens at ACE.** and the tile's title **ACE** under its TUNE-UP caption, instead of "TUNE-UP 2" | The tile itself says where it opens; no number (the slots have no identity to the player). |
| tune-up fitted (message) | HEAT SHIELD fitted / Tune-up slot 1 emptied | message goes / **Slot emptied** | |
| the ABILITY / TUNE-UP / PILOT / VEHICLE captions | on every tile | **keep** | They are the one thing that tells an ability tile from a tune-up tile. |
| title race header (if ever back) | TITLE RACE / JUNKER   -   vs Biddy Blas   -   The War Fields | **JUNKER TITLE / Biddy Blas, The War Fields** | |
| boss header (if ever back) | KESTAR BOOL / FINAL BOSS   -   1 v 1 in the stadium | **KESTAR BOOL / The stadium, one on one** | "Final boss" is a video-game word. |

### 2d. After a race (the panel over the game's results screen; the same lines on the menu's standings page)

| Where | Now | Proposed | Why |
|---|---|---|---|
| line 1 | JAKKU CUP   -   SCRAP SPIRAL   -   race 1 of 4 | **JAKKU CUP   -   SCRAP SPIRAL   -   RACE 1 OF 4** | One headline line, all caps, like the stakes line under it. |
| line 2 | 1st   -   1:33.08   -   14.4 s ahead | **keep** | Your row says the place too, but the time and the margin are only here. |
| stakes | LEADING BY 3 OVER GOLI & 02-R0, 3 RACES LEFT | **keep** | |
| record | NEW RECORD  1:33.08   (was 1:37.16) | **NEW RECORD  1:33.08, was 1:37.16** | No parentheses. |
| table headers | RACER / THIS RACE / POINTS / MOVED | **keep**; the rally's THIS STAGE / TOTAL / GAP keep | |
| prompt | NEXT RACE: race 2 of 4, FALLEN EMPIRE (SCORCHING).   B: leave the cup. | **NEXT   FALLEN EMPIRE, SCORCHING** on the left and **B   LEAVE THE CUP** on the right (two text blocks, or one line with wide spacing) | "race 2 of 4" repeats line 1 and the NEXT RACE badge; the weather is part of the name, not an aside; the control hint is a hint, not a sentence. |
| the same, last race | NEXT: the cup result ... CUP RESULT, then the main menu | the button says CUP RESULT; the prompt line goes | |
| the finale next (v0.33) | BRONZE TROPHY SECURED   -   NEXT: KESTAR BOOL, 1 v 1 FOR THE JUNKER TITLE | **BRONZE TROPHY SECURED. KESTAR BOOL NEXT, ONE RACE FOR THE JUNKER TITLE** | |
| rally prompt | NEXT STAGE: stage 2 of 7, GEOTHERMAL TOUR. ... | **NEXT   GEOTHERMAL TOUR** (the route only, the weather secret as today) | |
| Leave the cup? | Leave the cup? Your points are lost. / Cup abandoned | **Leave the cup? The points and the trophy go with it.** / **Cup abandoned** | |

### 2e. The cup result (the game's tour-end screen, v0.32.8-v0.34.2)

| Where | Now | Proposed | Why |
|---|---|---|---|
| title | ANDO CUP  -  JUNKER  -  GOLD TROPHY, 1ST | **keep** (v0.34.2; the tile says the same) | |
| award lines (the points table) | Race 2: THE WAR FIELDS, 2nd | **THE WAR FIELDS   -   2nd   -   12 points**? No: the XP panel prints the points itself. **THE WAR FIELDS, 2nd** | The timeline shows the order; "Race 2:" is a label. |
| rally award lines | Stage 3: GEOTHERMAL TOUR, 1st | **GEOTHERMAL TOUR, 1st** | |
| the finale award | Finale: KESTAR BOOL 1 v 1, won - ACE CHAMPION / lost - Kestar Bool keeps the title | **KESTAR BOOL, ONE ON ONE   -   ACE CHAMPION** / **KESTAR BOOL, ONE ON ONE   -   HE KEEPS THE TITLE** | |
| our old cup result page (skipped since v0.32.9, still built for Native = false) | hero line "GOLD TROPHY", "JAKKU CUP - JUNKER - 47 points - NEW BEST", "UNLOCKED:  CHALLENGER   -   GALACTIC CUP at JUNKER", "Next: a trophy in the Ando Cup at JUNKER opens the GALACTIC CUP" | leave; it is not shown | Not worth the words until it is on screen again. |

### 2f. Unlocks and the title (shown on the results lines and the old pages)

| Where | Now | Proposed |
|---|---|---|
| UNLOCKED line | UNLOCKED:  CHALLENGER   -   GALACTIC CUP at JUNKER | **CHALLENGER OPENS. THE GALACTIC CUP OPENS AT JUNKER** (caps headline, no label) |
| the nearest unlock (prog.lua texts, "Next: ...") | a trophy in the Ando Cup at JUNKER opens the GALACTIC CUP / 2 more trophies at JUNKER open the GALACTIC CUP and CHALLENGER | **A trophy in the Ando Cup opens the Galactic Cup** / **Two more JUNKER trophies open the Galactic Cup and Challenger** (if these lines are ever shown again; today they are only on the skipped page) |
| title / finale result page (titleResult; mostly superseded by the v0.33 finale) | KESTAR BOOL BEATEN / He races for you now: pick him in the garage. / KESTAR BOOL WINS / You finished 3rd. / UNLOCKED:  KESTAR BOOL, the final boss / THE TITLE STAYS WITH BIDDY BLAS | **KESTAR BOOL BEATEN** / **He races in your colours now. Find him in the garage.** / **THE TITLE STAYS WITH KESTAR BOOL** / **3rd** / **KESTAR BOOL WAITS IN THE STADIUM** |
| the finale on the cup result (standings.lua cupSpec) | UNLOCKED:  KESTAR BOOL races for you now (the garage) | **KESTAR BOOL RACES IN YOUR COLOURS NOW** |

### 2g. The rest

| Where | Now | Proposed |
|---|---|---|
| offline page | The Grand Prix is offline only. / Leave the party / stop matchmaking, then come back to this tab. / BACK: Back to the main menu | **The Grand Prix runs offline.** / **Leave your party or the queue, then come back.** / BACK (no desc) |
| wait page | Next race loading... | **Next race loading** (no dots) |
| no cup | No cup in progress | **No cup running** |
| a launch that never loaded | The race never loaded - nothing was recorded. | **The race never loaded. Nothing was recorded.** |
| CONTINUE tile after a cup | CONTINUE / Back to the cups | CONTINUE (no desc; B does the same) |
| the GRAND PRIX tab label | GRAND PRIX | **keep** |

## 3. Layout

Most of the 2026-11-11 review's proposal B is built (rows, posters, faces, medals as pictures). What is left:

1. **The results prompt in two halves.** Today one gold sentence carries the next race and the B hint. Split it: the
   next race on the left ("NEXT   FALLEN EMPIRE, SCORCHING"), the control hint small on the right ("B   LEAVE THE
   CUP"). Two text blocks in a horizontal box under the table; the standings page on the menu gets the same, minus the
   hint (B is the Back screen there).
2. **A locked tune-up tile names the league that opens it.** Title "ACE" under the gold TUNE-UP caption, with the
   lock, instead of "TUNE-UP 2". No info line needed then beyond "Opens at ACE."
3. **RESET PROGRESS off the eye-line.** It sits centred under the three posters, the size of a cup tile, in the
   path of every D-pad press down from a league. Make it the small size (HomeRows[2] at 400 x 120, or the same
   height and tucked right under ACE) so the posters own the page.
4. **The cups page header.** Three left-aligned lines of different weights (JUNKER, the brief, the circuits) sit
   in the top-left quarter while the tiles are centred. Centre the header over the tiles, or keep the league name
   as the page title and move the brief under it in the same column as the tiles' left edge. Either way the circuit
   list stays on one line where it fits (it wraps at five names today: "SCRAP SPIRAL" alone on line 2).
5. **The cup result's award lines.** The XP panel prints "Race 2: THE WAR FIELDS, 2nd" in its small font; with the
   label gone they are shorter and may fit one per line without the game's ellipsis. Check in game.
6. **Nothing else moves.** HOME's posters, the START screen's rows (pilot and tune-ups, four abilities, START) and
   the five-plus-two cups rows are right. The planets on the cup tiles were tried and taken off (v0.34.1).

## 4. Build plan

- **Pass 1, the words (one version, config and format strings only, low risk):** every row of §2 that is a string in
  config.lua (taglines, briefs, blurb colons) or a format string in main.lua / standings.lua / chain.lua / prog.lua /
  cupend.lua / title.lua. The tile-text budget (ui.lua U.FIT: 12 characters a line on a title, 19 on a desc) is
  checked by test_tiletext, so any new desc that does not fit fails a test, not the screen. Owner to read the new
  lines in game on HOME, a cups page, a START screen and one results panel.
- **Pass 2, the layout (one version per item, each seen in game):** §3 items 1-4 in that order.
- **Not in scope:** the HUD and the game's own screens (Race FINISHED, the tour-end panel's labels, CONTINUE), the
  racer bios and planet lines (the game's), the stakes and near-miss lines (already in voice).

## 5. Questions for the owner (also in OWNER.md)

1. The voice: the paddock announcer (terse, third person, in-universe nouns) as described in §1 - or something
   drier, closer to the game's own menu (which hardly says anything)?
2. The two taglines that change (CHALLENGER, ACE): the proposals above, or your own lines?
3. The planet line on each cup's info (the game's text, e.g. "Jakku. Starship wrecks boil under the scorching heat of
   this desert world."): yes, above the circuits, or leave the circuits alone?
4. Pass 1 as one version, or screen by screen?
