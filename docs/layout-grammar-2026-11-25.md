# How the game lays a page out, and how ours differ (2026-11-25)

Owner: "spend a little time thinking about how the game interface formatting and layout works. Your first attempts to
lay things out in an aesthetically pleasing way was ok but not great."

Read from: ui.lua (every screen is built there), the specs in main.lua, config TabLayout / HomeRows / CupsRows /
GarageRows, the five release screenshots (docs/release/screenshots, 2560 x 1440), the game's own CAMPAIGN page
(~/Projects/swgr-underground/autotest/shots/menu1.png, 1280 x 720) and the game's font list in the pak manifest.
Measurements below are in **layout units** (see §1). Nothing here is built; §5 is the plan.

## 1. The facts (measured)

**Layout units are a 3840 x 2160 slate.** Every number we write (TileWidth 560, HomeRows 760, GAP 20, font size 34 x
TextScale 1.6) is in a design space the engine scales to the screen: at 1440p by 2/3. Check: HomeRows w = 760 ->
507 px at 2560, the focused JUNKER poster measures 525 px = 507 x FocusScale 1.04. So: the screen is always 3840
wide and 2160 tall to us, whatever the owner's resolution. That is why the 1080p / 1440p checks scaled cleanly.

**The game's page is a left column; the diorama owns the right.** On the CAMPAIGN page:

| What | x from | x to | y from | y to |
|---|---|---|---|---|
| tab bar text (left edge) | 120 | | 130 | 180 |
| hero tile (CONTINUE CAMPAIGN) | 115 | 1280 | 366 | 1880 |
| small tiles (LOGBOOK, UPGRADE) | 1325 | 2205 | 375 | 1125 / 1180 - 1880 |
| the speeder's nose (3D scene) | 2210 | | 450 | |
| the pit droid's head | 2820 | | 300 | 1000 |

So the game's content lives in **x 120 to 2205, y 360 to 1880**: a column 2085 wide, left-aligned on the same margin
as the tab bar, ending exactly where the yellow speeder begins. Two columns of tiles, never more. Nothing is centred
on the screen. Tile gaps are about 40-45 units. The smallest game tile is 880 x 750; the hero 1165 x 1515.

**Our pages are centred on the full screen and wider than the column:**

| Page | tiles span (x) | over the scene by | tile size |
|---|---|---|---|
| HOME (3 posters) | 745 - 3055 | 850 (the ACE poster sits on the droid's face) | 760 x 560 |
| cups (5 + 2) | 470 - 3340 | 1135 (Sentinel Cup over the droid; the lock row over the speeder) | 560 x 380 |
| START (garage) | 885 - 2960 | 755 (Status Scrubber and START over the speeder) | 470 x 300, START 170 tall |
| results panel (over the game's screen) | 705 - 2770, min width 1600 | n/a: the game's screen is dark art | text only |

`spec.center = true` puts the page border in the middle of the menu (ui.lua buildInner, SetHorizontalAlignment 2),
and each row centres under the row above (U.buildRows). The header (title, lines, info) is left-aligned inside the
same border, so it sits at the border's left edge while the tiles sit at the middle: the two never share an edge
unless a row is as wide as the page. That is the whole of the "header floats in the top-left quarter" complaint
(menu-text-review §3.4): not a padding bug but two alignment systems on one page.

**Two typefaces, one of them not the game's.** The tile titles, the tabs and "Race FINISHED" are the game's display
face (heavy, condensed, textured). Everything we draw outside a tile (page titles, the briefs, the circuits, the info
line, the standings table, the prompt) is UMG's default **Roboto**: `textBlock()` in ui.lua sets only `Font.Size`
and never a typeface. The game ships its own faces as assets:
`/Game/Griffin/UI/Library/Fonts/Font_Display`, `Font_Body`, `Font_Numbers`, `Font_Decorative`, `Font_Diegetic`,
`Font_DiegeticBody`, `Font_Subtitles_Fiction` (composite fonts), built from CockpitSanz (Regular / Bold / BoldStencil),
LibreFranklin (Bold / ExtraBold), Aldrich and Noto. Which composite is which look is a guess until seen in game;
the safer route KNOWLEDGE already names: copy `.Font` from a live game TextBlock (the tab button's label for the
display face; a results-screen line for the body face), re-sampled per build.

**One ink on pale pages.** With no backdrop, every text colour is swapped for dark grey (U.ink: white and gold ->
0.12, grey -> 0.26). So the page title, the brief, the circuits and the gold info line are all the same colour; the
only hierarchy left is size. The game's menu text is black display caps, and its one accent is the terracotta pill
behind the selected tab (about R 0.78 G 0.31 B 0.23), white text on it. Our gold (1, 0.82, 0.35) is the results
screen's colour: right on the dark panel, never seen on the pale menu.

**The tile's anatomy** (WBP_FE_TileCommon_Btn, the game's): badge `Txt_Label_Supplemental` small italic caps top
left; `Img_Icon` top right, drawn as a one-colour shape; title `Txt_Label_Title` big caps bottom left, wrapping upward
(12 characters a line at 520 wide, 2 lines); `RT_Description` under the title, on the focused tile only, cut after 2
lines; the art through a material (ImageScale / offset). Focus: the game brightens the art and draws a white frame;
we add scale 1.04 and darken the other tiles to 0.72. Our overlays (medal 120, pips 66, corner 72, tag 15, the
portrait glyph flush left) sit in an Overlay over the tile. Text budget and wrap rules: ui.lua U.FIT, test_tiletext.

**Spacing today:** GAP 20 between tiles (the game: 40-45), page padding 36 / 24, 14 above the first row, 4 between
lines, 6 above the info line, 18 above the prompt on the results panel. The info line has no fixed height, so a page's
tiles drop by a line when the focused tile's info wraps to two (menu-review-2026-11-11 §11).

## 2. The grammar the game follows (what to copy)

1. **One column, one margin.** Content starts at x 120 under the tab bar's left edge and ends at 2205. Every
   left edge on the page (header, rows, prompt) is that margin. Rows are left-aligned, not centred.
2. **The scene is part of the page.** The right 40 % is the paddock. Tiles never cover the droid or the speeder;
   the page reads as "a board on the wall next to the car".
3. **Few, big tiles.** Two columns at most; the smallest tile 880 x 750. A page is a poster wall, not a grid of
   cards. Where we need seven cups on one page, they are the exception and should be the only small things on it.
4. **The tab is the title.** The game puts no text on the page outside tiles. When text is needed, it belongs
   inside a tile (CONTINUE CAMPAIGN carries its own sub-button) or in one short line under the margin.
5. **One typeface family, three roles.** Display face for headlines and tile titles (caps), body face for
   sentences, numbers face for tables. Never Roboto.
6. **Black, one accent.** On the pale menu: black caps headlines, dark grey body, terracotta for the single thing
   that is "current" (the selected tab). On dark screens: white body, gold headlines (the results screen).
7. **Fixed slots.** Nothing on the page moves when focus moves: the info line gets a two-line box.

## 3. What this means for each screen (proposals, not built)

**HOME.** The three league posters are right (owner). Two changes keep them and fit the column: left-align the
row on the 120 margin (the posters then span 120 - 2420, the ACE poster off the droid's face but still over the
speeder's tail, which is low and dark and reads fine), or shrink them to 680 x 500 to end at 2180. RESET PROGRESS
becomes a small tile (400 x 120, HomeRows[2]) tucked under ACE at the right of the row, not centred under the middle
poster (menu-text-review §3.3). No text on the page: the posters carry the taglines.

**Cups.** The one page that cannot be two columns. In the grammar:
```
 x=120                                                      2205
 JUNKER                                     (display face, black)
 One ability. No tune-ups.                  (body face, dark grey)
 [JAKKU CUP] [LANTAANA CUP] [ANDO CUP] [CRAIT CUP]    4 x 500 x 340, gap 28
 [SENTINEL CUP] [   GALACTIC CUP (span 2)  ] [RALLY CUP]
 The War Fields - The Giants' Graveyard - Debris Dunes - Fallen Empire - Scrap Spiral   (info line, 2-line box)
```
Four and three instead of five and two: 4 x 500 + 3 x 28 = 2084 wide, exactly the column. The header's left edge
is the first tile's left edge. The circuits move from the header to the info line of the focused cup (they already
are the cup's info; today they are printed twice). The planet line can lead the info line ("Jakku. Starship wrecks
boil under the scorching heat of this desert world.") as the owner agreed.

**START (the garage).** The rows are right (owner). Left-align them on the margin and the page fits: 4 x 470 + gaps
= 1940 wide. The START bar stays as wide as the rows above it, which is the game's hero-tile width class. The
header (JAKKU CUP / JUNKER) sits on the same margin.

**The results panel (over Race FINISHED).** Already in the dark-screen half of the grammar: gold headline, white
body, a table. Three fixes: the body face and numbers face instead of Roboto; the prompt as two blocks on one line
(next race left on the margin, the B hint right-aligned, menu-text-review §3.1); the table's first column
(RACER) and the headline on the same left edge as the title line (today the place column indents the names).

**The cup result (the game's tour-end screen).** The game's own layout; our lines go through its XP panel in its
small font. Nothing to lay out, only to keep short (§3.5 of the text review).

## 4. Numbers for the build

| Token | Today | Proposed | Why |
|---|---|---|---|
| column | centred, any width | x 120 - 2205, left-aligned | the game's margin; clear of the speeder |
| row alignment | centre (2) | left (1), the page border left (0) | one edge per page |
| GAP | 20 | 28 (tiles in a row), 40 between rows | nearer the game's 40-45 |
| cups tiles | 560 x 380, 5 + 2 | 500 x 340, 4 + 3 | fits the column |
| page title | 34 x 1.6 Roboto, dark grey | display face, black, 34 x 1.6 | the game's headline |
| lines / info | 18-22 x 1.6 Roboto | body face, dark grey; info in a 2-line box | no jump, right face |
| table | 20 x 1.6 Roboto | numbers face for the number columns | the game's results look |
| accent | none on pale pages | terracotta for the current cup's name in the info line (to try) | one accent, like the tab |
| prompt | one gold sentence | two blocks: NEXT ... left, B hint right | §3.1 |

## 5. Build order (pass 2 of the menu review, one item a version, each seen in game)

1. **Fonts first** (ui.lua `textBlock`): copy the display and body `.Font` from live game widgets at each build; a
   config switch `GameFonts = true`. Every page changes at once, with no layout change, so the owner can judge the
   face alone. If a live widget cannot be found, `Font_Display` / `Font_Body` by asset path as the fallback.
2. **The column**: `spec.center` -> `spec.column = { x = 120, w = 2085 }`; rows and header left-aligned; GAP 28/40.
   HOME and START move left and nothing else changes.
3. **The cups page** 4 + 3, the circuits into the info line, the info line's fixed box.
4. **The results prompt** as two blocks (§3.1), then RESET PROGRESS small (§3.3).

Each step is a config value or a few lines in ui.lua; test_tiletext keeps the tile text honest at the new widths
(the budget scales with width: 500 wide = 11.5 characters a title line, so "SENTINEL CUP" (12) needs checking).

## 6. Questions for the owner - answered 2026-11-25: 1 left column, 2 the game's typefaces, 3 cups 4 + 3
1. Left column like the game (tiles clear of the droid and the speeder), or keep the pages centred?
2. The game's typefaces for our text (display / body / numbers), or keep Roboto?
3. Cups as 4 + 3 at 500 x 340, or 5 + 2 at the present size moved left (then Sentinel Cup ends at 2990, on the droid)?
