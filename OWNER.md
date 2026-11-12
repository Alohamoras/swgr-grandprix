# For the owner: questions and playtests

Claude's running list of what only you can answer or judge. Tick a box, or write a note under it, and Claude picks it
up next session. Newest first in each section. (Started 2026-11-11; Claude keeps it current.)

## Questions for you
- [ ] **Review and UI plan** (docs/review-2026-11-11.md): pick the order. Proposal: A, the quiet pass (cut stray
  text) -> B, a layout per screen (cups page first: medal icons, faces on the title tiles, a centred page without
  the grey box) -> a feature freeze while you race a full season -> progress badges.
- [ ] **Do you ever change your abilities or tune-ups between cups?** If not, the garage could shrink to the racer.
- [ ] **PHILOSOPHY.md is out of date** (the rival is cut; 200cc is a keeper): OK to rewrite it to match today?
- [ ] **Ideas from your Google Doc** (realism mode, a podracer cup): send the details when you want them on the list.

## Playtests (only a real race can tell)
- [ ] **v0.23, the cups page:** five planets in a row, the Galactic Cup wide below, the title race and Kestar with
  faces (Kestar's, and the opponent's where the game has art). Are the medals bigger and gold vs bronze clear now?
  Does the pad move between the rows the way you expect?
- [ ] **v0.22, the quiet pass:** is the dark grey text easy to read on HOME, the cups page and the garage? Anything
  cut you miss, or anything left you'd cut? Does the GRAND PRIX tab now show about 1 s after the menu?
- [ ] **v0.21 (not installed yet):** the title race is now a 1 v 1 against the class leader on a normal track (the
  tile says "vs <name>"); Kestar Bool is a final boss tile on the 150cc page after the 150cc title; RESET asks twice
  and clears titles too; no grey panel behind HOME / cups / garage (does the text still read? `PageBackdrop = true`
  brings it back); after a cup race only NEXT RACE on the results screen, B leaves the cup (does the pad's B work
  there?); a little harder at 50 / 100cc, and from 100cc the bots don't ease off while you crash, 200cc a notch harder.
- [ ] **Your campaign save** (Claude's slip, 2026-11-11 19:10): a stray Return opened the campaign hub (Act I, Ando
  Prime); Claude exited at once via the pause menu (nothing played). The game autosaves when the hub loads, so your
  campaign should be exactly where it was. Glance at it next time you open the campaign.
- [ ] **Gold and bronze medal icons on the cup tiles still look alike** (the v0.20 tint didn't show). Tell me if it
  bothers you; the cup result screen's medal is gold correctly.
- [x] (answered 2026-11-11, see Done) **v0.20 menus** (v0.20.1 installed, checked by Claude in game 2026-11-11): the rival marked in light blue on the standings, the new cup result
  screen (big medal, top 3, what's next), the "Next:" line on HOME, tile labels readable when selected, and the game's
  footer (with "Restart Campaign") gone from our pages. If tiles look odd: `TileLabelStrip = false` in config.lua.
- [ ] **A cup at 150cc on the new AI** (50cc and 100cc raced 2026-11-11: felt good, a little too easy to catch up).
- [x] ~~A cup at 100cc and a cup at 150cc on v0.18.1~~ (the new AI: no catch-up anywhere). Does a clean race win by a
  few seconds and a messy one lose? Is it consistent race to race? Too easy / too hard? Your `[gaps]` lines are logged.
- [x] (2026-11-11: "worked pretty well") **NEXT RACE on the results screen** (v0.19.1): does the pad's **A** press it? Does the next race start without
  you seeing the menu? Does CONTINUE then B still leave the cup?
- [ ] **Boot straight into the Grand Prix** (v0.17): does the pad's **B** go back to the main menu on the first press?
- [ ] **Racer looks:** you race in your racer's own vehicle look. Do the screenshots match what you expect?
  `~/Projects/swgr-underground/autotest/shots/look1-a.png` (Nik's Hammerhead), `look1-b.png` (Griff's skim speeder),
  `b6-2-race.png` (Shade's base landspeeder).
- [ ] **Knock-offs at 150cc:** the AI attacks you more at high classes (you noticed this too). Fair, or too much? The
  study can try calmer aggression if you want.
- [ ] **AI abilities (R7):** do the AI racers fire their abilities, Shields included?
- [ ] **Controller pass** on all menus: cycling tiles with A, B to go back, the cups page.
- [ ] **Menu flash** between a race and the standings: is the cover still hiding it well?
- [ ] **v1.0 pass:** every cup at every class, once the above feel right.

## Done (moved here when answered)
- 2026-11-11 evening, after racing a 50cc and a 100cc cup (owner's answers):
  - Difficulty "pretty good, most wins felt earned"; catching up a little harder than before, more so at 100cc, but
    still possible after a crash or two: **make it a little harder**.
  - NEXT RACE worked well. **At the end of a cup, CONTINUE goes to that class's cups page** with the focus on the cup
    just raced (not to another cup).
  - **Cut the rival.** The title race becomes a 1 v 1 on a normal track against the class leader (the best bot of
    your last cup at that class). **Kestar: a final boss after 150cc** (a stadium 1 v 1 opened by the 150cc title;
    beating him unlocks him as a racer).
  - **Less clutter** on HOME and the sub-screens; the "Next:" line on HOME isn't useful (remove it). The grey
    see-through page background isn't needed if the text reads fine without it.
  - **RESET clears all progress, title wins included**, behind two "are you sure" questions.
  - No goals lines; later, **progress badges on the right side of the screen** showing every unlock / achievement
    (like the base game's badge screen) - on the to-do list.
  - The Ando short track: name it something more on theme (Claude picks).
  - **200cc "fast and brutal", but crashing a lot still gets ~2nd: overall a little tougher.** (200cc Jakku: 2nd,
    3rd, 2nd, 1st = gold; 150cc Galactic: silver.) v0.21: bots no longer ease off while you crash (100cc+), 200cc a
    notch above 150cc.
  - **No CONTINUE on the results screen between cup races**: it's the same as leaving the cup, so redundant and
    misleading. Only NEXT RACE; B leaves the cup (with the question).
- 2026-11-11 evening: v0.20 checked in game (footer gone, label strips, rival in light blue, cup result screen,
  CONTINUE to the next cup, HOME "Next:" line).
- 2026-11-11: run AI batches with the autopilot (done: docs/ai-study-2026-11-11.md); boot into the Grand Prix
  (v0.17); cups without the menu (v0.19.1); the next four tasks (TASKS "Next").
