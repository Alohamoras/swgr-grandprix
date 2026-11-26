# Plain-English pass on every line we wrote (TASKS §1j), 2026-11-25

Owner (2026-11-25): "it's concise, but it still sounds like it was written by AI ... it sort of invents terms and assumes the reader can figure out what you're trying to say."
This is the proposal only: nothing here is installed until the owner approves it line by line on the review page (link in OWNER.md). Then one tag, strings only, with the width / line-count tests.

## The rules

1. Say what happens, in the words the game uses. No coined terms ("rig", "the clock", "the field", "wound to ten"); the game says vehicle, parts level, racers, abilities, tune-ups.
2. Full sentences a first-time player understands without knowing the mod. If a rule is the point, state the rule ("the lowest total time wins"), not a hint at it ("the clock decides").
3. No slogans, no rule-of-three rhythm, no "X, and Y" flourishes, no clipped fragments to sound punchy.
4. Numbers as numbers where they are rules ("level 7 parts", "4 tracks"); words only in flavour text.
5. Flavour lines (taglines) may have character, but must still mean something literal.

## Every line (86)


### HOME

| # | file:line | where it shows | now | proposed | note |
|---|---|---|---|---|---|
| L01 | `config.lua:223` | JUNKER poster, line under the name (tagline) | Scrapyard junk with too much engine | Cheap vehicles with oversized engines | "Scrapyard junk" is flavour; the new line says what the league is. Tagline limit 48 characters. |
| L02 | `config.lua:227` | CHALLENGER poster tagline | Proper rigs, and pilots out to make a name | Upgraded vehicles and racers on the way up | "rigs" is a coined word; the game says vehicles. |
| L03 | `config.lua:231` | ACE poster tagline | Every credit on the rig. The galaxy's finest | The galaxy's best racers, fully upgraded | From TASKS §1j's example, cut to fit the 48-character limit. |
| L04 | `config.lua:225` | HOME, focused JUNKER: the info line (league rules) | Afterburner and ramjet wound to ten on a scrapyard chassis. Cornering, resilience and drift stock, the battery barely holding. One ability, no tune-ups. | All vehicles have level 10 afterburner and ramjet parts, a level 2 battery and stock parts everywhere else, so they are fast on the straights and hard to turn. You can take 1 ability and no tune-ups. | Checked against config parts = { [1] = 10, [3] = 10, [4] = 2 } (afterburner 10, ramjet 10, battery 2, the rest 0). |
| L05 | `config.lua:229` | HOME, focused CHALLENGER: rules | Every part at seven, and every rig on the grid the same. Two abilities, one tune-up. | All vehicles, yours included, have level 7 parts, so nobody has an engine advantage. You can take 2 abilities and 1 tune-up. | TASKS §1j example, as written. |
| L06 | `config.lua:233` | HOME, focused ACE: rules | Every part at ten, every credit spent. Three abilities, two tune-ups, and the field fires everything it carries. | All vehicles, yours included, have level 10 parts. You can take 3 abilities and 2 tune-ups, and the other racers use every ability they carry. | "the field" is a coined term for the other racers. |
| L07 | `main.lua (v0.37.0, new)` | HOME, focused league: 2nd info line, title not won (the grey star) | (new in v0.37.0) | Gold star: the league title. Finish the Galactic Cup in the top 3, then beat Kestar Bool in a one-on-one race to win it. | Already installed in v0.37.0, written to these rules. Approve or reword. |
| L08 | `main.lua (v0.37.0, new)` | HOME, focused league: 2nd info line, title won (the gold star) | (new in v0.37.0) | Gold star: you are the JUNKER champion. You beat Kestar Bool in the Galactic Cup final. | Already installed in v0.37.0. |
| L09 | `prog.lua:49` | HOME, a locked league poster: the line under the name | Five JUNKER trophies open it | Needs 5 JUNKER trophies | Numbers as numbers (a rule). Tile line: 19 characters a line, 2 lines. |
| L10 | `prog.lua:68` | HOME, focused locked league: info line | A trophy in every JUNKER planet cup opens it. 2 of 5 so far. | Unlocks when you win a trophy (finish in the top 3) in all 5 JUNKER planet cups. You have 2 of 5. | Says what a trophy is the first time a player meets the word. Gold variant: "Unlocks when you win gold in all 5 ... cups." |
| L11 | `main.lua:316` | HOME page heading | CHOOSE A LEAGUE | CHOOSE A LEAGUE | Keep. |
| L12 | `main.lua:297` | HOME, small tile | RESET PROGRESS | RESET PROGRESS | Keep. |

### Cups page

| # | file:line | where it shows | now | proposed | note |
|---|---|---|---|---|---|
| L13 | `main.lua:368` | Galactic Cup, info line 2 | Three planets, then Derven Acos. | One race on each of 3 random planets, then the 4th race on Derven Acos. | Says it is one race a planet, and that Derven Acos is a race too. |
| L14 | `title.lua:305` | Galactic Cup, info line 3 (the finale) | Finish on the podium and Kestar Bool waits in the stadium. One race for the title. | Finish in the top 3 and you race Kestar Bool one on one in the stadium for the league title. | Gold-only variant: "Win the cup and you race ...". |
| L15 | `main.lua:373` | Rally Cup, info line | Four stages, four racers, the clock decides. Weather and nightfall are unknown until you arrive. | 7 point-to-point tracks against 3 other racers. Your times are added up across all 7, and the lowest total wins. You won't know the weather or time of day until each race starts. | TASKS §1j example, with the real count: the rally runs every stage in its pool (7 today, filled in from the pool) and config Rally.Grid = 4 (you + 3). |
| L16 | `main.lua (v0.37.0, new)` | A perfect cup (the crown in the corner): last info line | (new in v0.37.0) | Crown: a perfect cup. You won every race. | Already installed in v0.37.0. |
| L17 | `main.lua (v0.37.0, new)` | A cup with a trophy but not perfect: last info line | (new in v0.37.0) | Win every race of this cup in one go to earn the crown. | Already installed in v0.37.0. |
| L18 | `prog.lua:49 / :83` | Locked Galactic Cup: tile line and info line | Five JUNKER trophies open it  /  A trophy in every JUNKER planet cup opens it. 2 of 5 so far. | Needs 5 JUNKER trophies  /  Unlocks when you win a trophy (finish in the top 3) in all 5 JUNKER planet cups. You have 2 of 5. | Same rewrite as the locked league. |

### Start screen (garage)

| # | file:line | where it shows | now | proposed | note |
|---|---|---|---|---|---|
| L19 | `racer.lua:63` | Kestar Bool focused while locked: added to the pilot info | Kestar Bool races only for himself until you beat him in the ACE Galactic Cup finale. | You can race as Kestar Bool after you beat him in the final race of the Galactic Cup at ACE. | Says what unlocks and how. |
| L20 | `config.lua:556` | Shade's line (ours, not the game's) | No family name, no sponsor, just the rig | A racer with no family name and no sponsor | The other bios are the game's and stay as they are. |
| L21 | `config.lua:568` | Sebulba's line (ours) | The legend himself, never on the League's grid | The podracing legend. He does not race in the Galactic League. |  |
| L22 | `main.lua:538` | VEHICLE tile focused: info line | Landspeeder, speeder bike or skim speeder, in the pilot's colours. | Choose a landspeeder, speeder bike or skim speeder. It wears your pilot's colours. |  |
| L23 | `main.lua:564` | A tune-up slot your league does not have: info line | Opens at ACE. | Unlocks in the ACE league. |  |
| L24 | `main.lua:570` | An empty tune-up slot: info line | Nothing fitted. | No tune-up fitted. |  |
| L25 | `main.lua:529` | Message after picking a pilot | Shade. Landspeeder, signature kit. | Shade, in a landspeeder, with Shade's own 4 abilities. | "signature kit" is a coined term. |
| L26 | `main.lua:575` | Message after emptying a tune-up slot | Slot emptied | Tune-up removed. |  |
| L27 | `config.lua:676` | HEAT SHIELD (tune-up info) | Immune to Burning and Frozen | You can't be Burning or Frozen. | Limit 60 characters (test_modsel). |
| L28 | `config.lua:678` | ARMOUR | Immune to Disrupted. Shielded for the first 10 s | You can't be Disrupted. Shielded for the first 10 s. |  |
| L29 | `config.lua:680` | ICE COLD | Cooled while airborne. Cooled blocks Corroded | Cooled in the air. While Cooled you can't be Corroded. | The game: "While Cooled, protected from Corroded". |
| L30 | `config.lua:682` | REDLINER | Ramjet cools while active. Cooled 20 s when Redlining | The ramjet can cool while in use. Redlining: Cooled 20 s. |  |
| L31 | `config.lua:684` | RAMJET RIDER | No Ramjet heat in the air. 90% resets, no blow-up | No ramjet heat in the air. 90% chance it resets, not explodes. | The game: "90% chance Ramjet resets and strengthens rather than explodes". |
| L32 | `config.lua:686` | AFTERBURNER | No fuel used in the air. a full tank on landing | No afterburner fuel used in the air. Refills on landing. | Also fixes the lower-case "a". |
| L33 | `config.lua:688` | BRAWLER | Takedowns ready the Ramjet and give 4 Energy | A takedown readies the ramjet and gives 4 energy. |  |
| L34 | `config.lua:690` | SURVIVOR | After a crash: Shielded and Surging for 30 s | After a crash you're Shielded and Surging for 30 s. |  |
| L35 | `config.lua:692` | SLIPSTREAMER | Slipstreaming cools you. 5 s of it starts a Surge | Slipstreaming cools you. 5 s of it makes you Surging. | The game calls the effect Surging. |
| L36 | `config.lua:694` | FIREBUG | Burning makes 90% less heat and Overcharges you | Burning heats you 90% less and makes you Overcharged. |  |
| L37 | `config.lua:696` | ENGINEER | Malfunctions end 200% sooner. a perfect fix restores a Crash | Faster malfunction fixes. A perfect fix gives back 1 crash. | "200% sooner" doesn't mean anything; the game says "recover 200% faster". |
| L38 | `config.lua:698` | TENACIOUS | Corroded crashes you 200% slower and never chokes you | Corroded takes 3x longer to crash you and never Chokes you. | The game: "Takes 200% longer to Crash from Corroded" (= 3x the time). |
| L39 | `config.lua:467` | Ability info: Ion Bolt family | Lock on and disrupt a rival | Locks on to a racer and Disrupts them | Shown as "NAME. blurb." |
| L40 | `config.lua:467` | Ability info: mines | Drop charges behind you | Drops mines behind you |  |
| L41 | `config.lua:468` | Ability info: scrubber | Clear bad status effects | Removes bad status effects from you |  |
| L42 | `config.lua:468` | Ability info: shield | Shrug off hits for a while | Protects you from hits for a few seconds |  |
| L43 | `config.lua:468` | Ability info: shockwave | Blast nearby racers away | Pushes nearby racers away |  |
| L44 | `config.lua:469` | Ability info: surge | A burst of speed | Gives you a burst of speed |  |
| L45 | `config.lua:469` | Ability info: vent | Cool your ramjet down | Cools your ramjet down |  |

### Standings after a race

| # | file:line | where it shows | now | proposed | note |
|---|---|---|---|---|---|
| L46 | `standings.lua:182` | Headline | JAKKU CUP   -   THE WAR FIELDS   -   RACE 2 OF 4 | JAKKU CUP   -   THE WAR FIELDS   -   RACE 2 OF 4 | Keep. |
| L47 | `standings.lua:97` | Your line | 2nd   -   1:45.07   -   0.4 s behind Biddy Blas | 2nd   -   1:45.07   -   best lap 0:34.20   -   0.4 s behind Biddy Blas | v0.38.0 adds the best lap (config LapTimes). Words unchanged. |
| L48 | `cup.lua:254` | Stakes line, gold can no longer be lost | GOLD IS YOURS: 12 POINTS CLEAR, 1 RACE LEFT | GOLD IS YOURS: 12 POINTS AHEAD WITH 1 RACE LEFT | "clear" assumes the reader knows the racing term. |
| L49 | `cup.lua:256` | Stakes, leading | LEADING BY 3 OVER BIDDY BLAS, 2 RACES LEFT | YOU LEAD BIDDY BLAS BY 3 POINTS, 2 RACES LEFT | Says points. |
| L50 | `cup.lua:255 / :272` | Stakes, tied | LEVEL ON POINTS WITH BIDDY BLAS | TIED ON POINTS WITH BIDDY BLAS |  |
| L51 | `cup.lua:262` | Stakes, last race, any finish wins | YOU LEAD ...: ANY FINISH WINS THE CUP | YOU LEAD ...: FINISH THE LAST RACE AND THE CUP IS YOURS |  |
| L52 | `cup.lua:263` | Stakes, last race | YOU LEAD ...: 6TH OR BETTER WINS THE CUP | YOU LEAD ...: FINISH 6TH OR BETTER TO WIN THE CUP |  |
| L53 | `cup.lua:265` | Stakes, last race | TIED ...: A WIN TAKES THE CUP | TIED ...: WIN THE LAST RACE TO WIN THE CUP |  |
| L54 | `cup.lua:273` | Stakes, behind | 3 POINTS BEHIND BIDDY BLAS, 2 RACES LEFT | 3 POINTS BEHIND BIDDY BLAS, 2 RACES LEFT | Keep: already plain. |
| L55 | `cup.lua:278` | Stakes, gold gone, silver possible | GOLD IS OUT OF REACH, SILVER IS NOT | YOU CAN'T WIN GOLD NOW, BUT SILVER IS STILL POSSIBLE |  |
| L56 | `cup.lua:281` | Stakes, gold gone | GOLD IS OUT OF REACH, 4 POINTS FROM SILVER | YOU CAN'T WIN GOLD NOW. YOU ARE 4 POINTS FROM SILVER |  |
| L57 | `cup.lua:284` | Stakes, nothing left | THE TROPHIES ARE OUT OF REACH | YOU CAN'T WIN A TROPHY IN THIS CUP NOW |  |
| L58 | `cup.lua:233` | Rally stakes, leading | LEADING BY 3.2 S OVER LYREN SHOK, 2 STAGES LEFT | YOU LEAD LYREN SHOK BY 3.2 S IN TOTAL TIME, 2 STAGES LEFT | The rally is decided on total time; say so. |
| L59 | `cup.lua:234` | Rally stakes, behind | 3.2 S BEHIND LYREN SHOK, 2 STAGES LEFT | 3.2 S BEHIND LYREN SHOK IN TOTAL TIME, 2 STAGES LEFT |  |
| L60 | `standings.lua:191` | After race 4 of the Galactic Cup, top 3 | GOLD TROPHY SECURED. KESTAR BOOL NEXT, ONE RACE FOR THE JUNKER TITLE | YOU HAVE THE GOLD TROPHY. NEXT: KESTAR BOOL, ONE ON ONE, FOR THE JUNKER LEAGUE TITLE |  |
| L61 | `standings.lua:107` | Notes row, new race record | NEW RECORD  1:45.07, was 1:46.10 | NEW TRACK RECORD  1:45.07 (OLD 1:46.10) | "was" in lower case in a caps line; say which record. |
| L62 | `gp.lua:478` | Notes row, near miss | 0.4 S OFF YOUR RECORD | 0.4 S SLOWER THAN YOUR TRACK RECORD |  |
| L63 | `gp.lua:477` | Notes row, equal | LEVEL WITH YOUR RECORD | EQUAL TO YOUR TRACK RECORD |  |
| L64 | `standings.lua (v0.38.0)` | Notes row, lap record | NEW BEST LAP  0:34.20 | NEW LAP RECORD  0:34.20 | Pairs with NEW TRACK RECORD. Owner's own words were "BEST LAP"; pick one. |
| L65 | `gp.lua (v0.38.0, new)` | Notes row, lap near miss | 0.4 S OFF YOUR LAP RECORD | 0.4 S SLOWER THAN YOUR LAP RECORD | From DESIGN v0.12; follows the track-record line. |
| L66 | `standings.lua:57` | Table column headings | RACER   THIS RACE   POINTS   MOVED | RACER   THIS RACE   POINTS   PLACES | "MOVED" (+2 / -1) is places gained or lost; say places. |
| L67 | `chain.lua:127` | Prompt under the standings on the game's results screen | NEXT   THE WAR FIELDS          B   LEAVE THE CUP | NEXT RACE: THE WAR FIELDS          B   LEAVE THE CUP |  |

### Cup result

| # | file:line | where it shows | now | proposed | note |
|---|---|---|---|---|---|
| L68 | `cup.lua:302` | Notes row, near trophy | 1 POINT FROM GOLD | 1 POINT SHORT OF GOLD |  |
| L69 | `cup.lua:306` | Notes row, lost a tie | TIED FOR GOLD, LOST ON THE LAST RACE | TIED ON POINTS FOR GOLD, BUT LOST THE TIE-BREAK (THE LAST RACE) | The tie rule is the last race; say it is a tie-break. |
| L70 | `standings.lua:120` | Unlock line | CHALLENGER OPENS  /  CHALLENGER AND THE GALACTIC CUP AT JUNKER OPEN | UNLOCKED: CHALLENGER  /  UNLOCKED: CHALLENGER AND THE GALACTIC CUP AT JUNKER |  |
| L71 | `standings.lua:148` | Fallback result page, a better finish than before | ... - 102 points   -   NEW BEST | ... - 102 points   -   YOUR BEST FINISH IN THIS CUP | "NEW BEST" of what? |
| L72 | `standings.lua:155` | Finale won at Ace | KESTAR BOOL RACES IN YOUR COLOURS NOW | YOU CAN NOW RACE AS KESTAR BOOL | "in your colours" is a coined phrase. |
| L73 | `standings.lua:157` | Finale lost | KESTAR BOOL KEEPS THE TITLE | KESTAR BOOL WON. NO LEAGUE TITLE THIS TIME |  |
| L74 | `cupend.lua:304` | Game's cup screen title, finale won | JAKKU CUP  -  CHALLENGER  -  CHAMPION | GALACTIC CUP  -  CHALLENGER  -  LEAGUE CHAMPION |  |

### Prompts and messages

| # | file:line | where it shows | now | proposed | note |
|---|---|---|---|---|---|
| L75 | `main.lua:300` | RESET, first question | Wipe the record books? Every trophy, lap record and title goes. | Reset all progress? This deletes every trophy, lap record and league title. |  |
| L76 | `main.lua:302` | RESET, second question | There is no way back. Wipe them? | This can't be undone. Reset everything? |  |
| L77 | `main.lua:305` | After reset | A clean slate. | Progress reset. |  |
| L78 | `main.lua:305` | Reset failed | The save could not be backed up. Nothing was wiped. | The save couldn't be backed up, so nothing was reset. |  |
| L79 | `main.lua:819` | B during a cup | Leave the cup? The points and the trophy go with it. | Leave the cup? You lose this cup's points and can't win its trophy. |  |
| L80 | `main.lua:820` | After leaving | Cup abandoned | You left the cup. |  |
| L81 | `main.lua:122` | NEXT RACE with no cup | No cup running | No cup in progress. |  |
| L82 | `main.lua:626` | Offline page | The Grand Prix runs offline. | The Grand Prix only works offline. |  |
| L83 | `race.lua:31-56` | Offline page, the reason | you are in a party (2 players)  /  matchmaking is running  /  the game has locked its tiles (an online queue?) | You are in a party of 2 players.  /  Matchmaking is running.  /  The game's menu is locked, probably by an online queue. | Log-style text shown to the player. |
| L84 | `race.lua:284` | Launch refused, wrong vehicle | The Speeder bike can't enter THE WAR FIELDS (it needs: Vehicle.Standard.Car) | A speeder bike can't race on THE WAR FIELDS. Pick a landspeeder for this cup. | Drop the engine tag; say what to do. (The vehicle named comes from the track's tag.) |
| L85 | `race.lua:279 / :287 / :429` | Launch failed | Event not found: X  /  Vehicle or build not found  /  Launch failed - see grandprix.log | The race couldn't start: its event wasn't found.  /  The race couldn't start: the vehicle wasn't found.  /  The race couldn't start. Details are in grandprix.log. |  |
| L86 | `race.lua:391` | Launch refused | Cannot launch: not at the main menu | The race can't start: not at the main menu. |  |

## Not reworded

| what | where | why |
|---|---|---|
| Track names we made up | CLOISTER RUN, BOOL RIVER RUN (FORWARD) (config Pools) | Left as they are: names, not sentences. |
| Off with today's settings | TITLE RACE tile and result page, KESTAR BOOL tile, the GARAGE tile, the race list on the start screen, the cups page brief, the XP panel lines | Not shown with the current config; reworded only if switched back on. |
| The game's own text | planet lines, the pilots' bios (except Shade and Sebulba above), track names, ability names | Left as the game has them. |
| Never reached | goal / next-unlock sentences in prog.lua (nothing shows them) | Left alone. |

## After approval

- One tag (strings only): config.lua, main.lua, prog.lua, cup.lua, standings.lua, gp.lua, chain.lua, race.lua, title.lua, cupend.lua, racer.lua.
- Tests that pin the old wording change with it (test_finale, test_nearmiss, test_stakes, test_config's 48-char tagline limit, test_modsel's 60-char tune-up limit, test_tiletext).
- The rules go into KNOWLEDGE.md as the house style for all the Galactic Racer mods' text.
