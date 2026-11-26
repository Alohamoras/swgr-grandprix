# For the owner: questions and playtests

Claude's running list of what only you can answer or judge. Tick a box, or write a note under it, and Claude picks it
up next session. Newest first in each section. (Started 2026-11-11; Claude keeps it current.)

## Questions for you
- [ ] **League cars (2026-11-25, plan in docs/league-styles-2026-11-12.md "2026-11-25"):** (1) Challenger at 7 on every
      part - confirm (was 5)? (2) Junker wreck limit 5 (the game's is 3) - or more? (3) Ace bots: keep their full ability
      kits, or defensive / utility only for a cleaner field? (4) OK to shift Ace pilot strength down (Elite at your 10,
      contenders 9, weak 7), since nothing goes above 10?
- [ ] **HEAT for Ace (2026-11-25, plan in docs/heat-2026-11-25.md):** (1) the name - HEAT, or something Star Wars-y
      (BOUNTY, WAGER, HOT RUN)? (2) opens at your first Ace gold (Claude's pick) or after the Ace title? (3) the first
      set (Claude's pick: Faster field, Budget cap, Bare garage, Weak kit, No mercy at the start, Grudge, Armed field - all on
      dials we already have)? (4) only a gold records the heat (Claude's pick), or any trophy? (5) any modifier you'd
      cut or add?
- [ ] **Mechanic shop mod (2026-11-24):** "highest level parts" - level 10 outright (one visit = a maxed slot), or the biggest
      upgrade step the shop can offer over your current level? ShopRecon's first dump (after you visit the mechanic once) will show
      which the game can do. Half price = 50 % off the shown price. Repo ~/Projects/swgr-mechanic.
- [x] **Streamline Campaign on Nexus (2026-11-23):** 1.0.0 uploaded and live (owner). Was: title, category, permissions, the upload
      (any?). Release checklist: ~/Projects/swgr-streamline/TASKS.md "Release 1.0.0".
- [x] **Nexus release:** UE4SS link (Nexus mod 2), no licence (Nexus permissions instead), screenshots in docs/release/screenshots/ (2026-11-13).
- [ ] **Special rounds (race types):** docs/race-types-2026-11-13.md section 4 - A eliminator mid-cup, B knockout as
  the Galactic Cup finale, C by league style (Junker eliminator, Ace knockout finale), D bonus events. Pick after the
  in-game recon (needs the PC to Claude for ~30 min).
- [ ] **Making the loadout choice matter:** options in docs/loadout-options-2026-11-12.md. Claude's pick: split HEAT
  SHIELD into fire / frost packs + every planet cup draws at least one weather race, then golds unlock packs.
- [x] **AI pilots: fixed strength + small form, or fully random?** Answered 2026-11-12: fixed, no per-race randomness (built in v0.28).
- [ ] **Kestar is a weak final boss** (Claude's tests, 2026-11-11 night: he veers left off the line, then loses by
  20 s over 6 laps even to the autopilot). The Showdown was likely built around the game's own catch-up, which our
  150cc settings switch off. Give the boss race the game's own AI (a rubber band, but only for him), a boss profile
  of its own, or leave him? (TASKS "Discussions")
- [ ] **Review and UI plan** (docs/review-2026-11-11.md): pick the order. Proposal: A, the quiet pass (cut stray
  text) -> B, a layout per screen (cups page first: medal icons, faces on the title tiles, a centred page without
  the grey box) -> a feature freeze while you race a full season -> progress badges.
- [ ] **Do you ever change your abilities or tune-ups between cups?** If not, the garage could shrink to the racer.
- [ ] **PHILOSOPHY.md is out of date** (the rival is cut; 200cc is a keeper): OK to rewrite it to match today?
- [ ] **Ideas from your Google Doc** (realism mode, a podracer cup): send the details when you want them on the list.
- [ ] **Credits: the two `<author>` names** (UE4SS Galactic Racer Edition, Nexus mod 2; FreeRace, mod 80) in
  docs/release/nexus-description.bbcode and the README - fill from the mods' "Created by" lines (Nexus blocked us).
- [ ] **Underground: keep the test races on your career?** (2026-11-13) Four test races (v0.14 check + v0.15's three
  leagues, Autopilot driving) played on your real Underground career: bank 2,010 -> 18,190, +4 races, Turbojet
  Manifold level 4 unlocked. Keep, or restore `~/.local/share/swgr-save-backups/ai-fixed-test-20261113/ug-save.lua`
  (the save before them; it converts to v4 on load)?
- [ ] **Underground: the launch build at level 1 crashed the game** in testing (fixed: never below 2). The Grand
  Prix's Junker parts leave some slots at 0 in the launch build (not 1) - no crash seen there in ~20 Junker races;
  nothing to do unless you see one.

- [ ] **Underground v0.25 LOOKS (built, your OK 2026-11-13):** beat a rival's duel and wear their car (garage ->
  LOOKS). **Your bought themes are NOT offered:** putting a theme look on the car crashed the game in both races I
  tried; the rivals' looks were fine in 4. If you'd still like themes, they can come back on the menu car only.
- [ ] **Underground: Claude's test races on your career (2026-11-13 evening):** 10 races (3 Ace, 6 Junker, 1
  Challenger; one more crashed): the Junker gatekeeper beaten, 9 of 12 Junker cleared, bank 50,400. Keep them, or go back to before
  (`~/.local/share/swgr-save-backups/looks-econ-20261113/ug-save.lua`, bank 25,750, 32 races)? Your campaign save was put back.
  If Steam asks about a cloud conflict, pick the local files.

- **Underground - the speed leak fix (2026-11-15, T1-6).** Confirmed: the shared launch build (set to the race's top
  level, 10 in Ace) makes every car faster, yours included, whatever its own parts. Fix: **one fixed launch level for
  every league** - your pace then depends only on your parts; the leagues' fields get re-checked (they lose the extra
  Ace pace). Which level: **6** or **3**? Details: swgr-underground docs/power-leak-plan-2026-11-15.md.
  **Answered 2026-11-15:** plan agreed - 3 if a crash check (cars above the template) is clean, else 10; then an
  ENGINE upgrade (Underground TASKS.md SPEED PLAN).
- **Underground - speed matching off (v0.25.1)?** Still on in the Underground (2 bots near you copy your speed);
  the Grand Prix has it off. Yes / no.
- **Underground - revised leak fix (2026-11-22, SPEED PLAN S2).** S4 showed the opponents' speed comes only from the
  shared template, so it can't be fixed at one level. Proposal: keep the template per league and cancel the leak on YOUR
  car (your power figure = parts total - a league correction, ~24 points in Ace). OK? Then ~8 calibration races.
- **Reboot the PC when convenient** - GPU faults (kernel Xid) still happen in races; no reboot since 2026-11-12. **Rebooted 2026-11-22** (the NVIDIA driver update needed it); before that: **Owner away all week (2026-11-15): no reboot until then** - tests run on the un-rebooted PC (same as the 2026-11-15 baseline).

## Playtests (only a real race can tell)
- [ ] **BikeSkin v0.4.0 (2026-11-26) + StreamlineCampaign 1.0.1 switched on - restart the game.** The drifter bike is
      now your landspeeder's **Marlin** kit, shown in CUSTOMIZE as **"Drifter Bike (prototype)"**: pick it, race the
      landspeeder (also in the campaign) = the bike; any other look (your Beluga) = a normal landspeeder. Check: the
      name shows; a Marlin race is the bike; a Beluga race is a plain landspeeder that doesn't lean (the first race
      after switching kits might still lean - tell me if it did). Other kit: `Kit = "..."` in BikeSkin's config.lua.
- [x] **BikeSkin v0.3.0 (2026-11-26, ~/Projects/swgr-bikeskin) - the real mod, installed, loads at the next game
      start; no keys.** (Owner: "everything else played great"; pose -> Bike_Scout in v0.3.1.) Every offline race on a **landspeeder**: ~4 s in it becomes Shade's bike, your rider takes the
      Bike_Race pose (your pick), and it leans like the second F9 (every landspeeder leans, bots too). Check: all three
      there? Still right after a crash / reset? Any stutter every 2 s? Settings (bike look, Bike_Scout pose, lean off):
      `mod/BikeSkin/Scripts/config.lua`. (Spike results: F7 press 1 right; F9 twice looked right. The spike is off now.)
- [x] **BikeDrift v0.2.0 (2026-11-25):** "better, for what it is I think it's neat" - parked as is, still installed
      (off: `Mods/BikeDrift/enabled.txt` -> `disabled.txt`). Was: **BikeDrift v0.1.0 (2026-11-25, new mod, repo ~/Projects/swgr-bikedrift) - installed 2026-11-25 18:31, loads at the next game start:**
      Race any bike event and corner hard with X (the energy
      brake): it should slide out and keep its speed instead of skidding and jolting. Tell me: too loose / too slow /
      too grippy, and whether the slide runs out mid-corner on long bends. All bikes slide, the bots' too. Values with the
      game's own beside each: `mod/BikeDrift/Scripts/config.lua`. Off: `Mods/BikeDrift/enabled.txt` -> `disabled.txt`.
- [ ] **v0.32.6-8 (2026-11-25 evening, your picks 9-11), installed 2026-11-25 18:00 after the playtest:**
  - **The cup result screen (10):** seen 2026-11-25 (Sentinel gold): "I love the layout of the screen and the recap". v0.32.9 puts
    the trophy / place / points / podiums on the two tiles and skips our old page after it - check both.
    (Was:) after a cup's last race, CUP RESULT now shows the game's own tour-end screen first
    (planets, your place per race, the points as the XP bar), then A / Enter / Escape takes you on to our cup result
    page. Built from another mod's notes, never seen in game by us: tell me what it looks like, what's wrong on it, or
    if it never appears (the log says `[cupend] ...` or `no tour-end screen (why)`). `CupResult.Native = false` in
    config.lua goes back to the old flow.
  - **The back of the grid (9):** Ary Quill and Malis Vazosk are no longer set to trail you by design. Do they stay in
    touch now? The first launch logs the pacing rows the game really has (`[ai] league x: pacing rows on RP_Default`).
  - **Navigation (11):** nothing should change on any page; if the stick or D-pad ever lands somewhere odd, say which
    page and which tile.
- [x] **v0.32.x (2026-11-25), from the FreeRace read - six chunks, one playtest.** Owner, two Ace cups on Lantaana: "the bots kit ... seemed to make a big difference, ace in the galactic cup is much more challenging now, it's feeling pretty great. There are still some races where i dominate" (the log: a wet sprint won by 20 s, field spread 146 s - the bots crash on it). Log: every feature ran; the bots fired 2-4 kinds each; shared configs, so the recharge dial did nothing (noted). The thrust dial was OFF (config AI.Thrust = false): the difference is the kits + the start grace. Buoys: no Gauntlet race yet.
  - **Galactic Cup, the final (The Galactic Gauntlet):** no floating blue buoys shoving you any more. The log says
    `[hazards] precision buoys: N hidden` (N > 0 confirms they were there).
  - **The bots' abilities:** they should fire more than one of their four now, and more kinds. After any race the log
    has `[aiuse] fired in this race: Biddy Blas: Vent_Flame 2, Shield 1 | ...` - that line answers R7 ("do they
    fire their Shields?"). Also `[aiuse] our kits at <league>: ... NOT fired by the AI: ...` lists what the game's AI
    rules never cover. Mines every 30 s and Disruptors every 15 s at most per bot.
  - **The start:** for 15 s after the green light no bot fires anything and the Ace pace lift waits; AI perfect starts
    45 % (was 75). Does the first corner feel fairer? Log: `[ai] ... (start grace: for 15 s)` and `start grace over`.
  - **The results screen:** the standings panel comes as before, now without a 300 ms sweep behind it; any stutter
    gone while the rest of the field finishes?
  - **Nothing to see** for the START lock (it only acts when the game locks its tiles for an online queue).
  - **The thrust test (when you have 20 minutes, your call):** TASKS.md §1g item 3 - three held races with
    `--dev` and experiment.lua; the `[thrust]` and `[exp] result` lines tell us if the dial works. If it does, it
    replaces the part-stack pilot strength.
- [x] **Streamline Campaign 1.0.0** (2026-11-23, ~4 h played): all features confirmed in the log. Was: a normal campaign session, ideally with one story
      cutscene and one Restart Campaign. Tell me if anything got skipped that you wanted to see.
- [x] **v0.29, Junker: the crash fix and the rust look.** Owner 2026-11-12: no crash; looks show, dents overboard -> rust + dirt only (v0.29.1). Junker races load again (the crash was pilot strength
  meeting Junker's empty parts slots). In a Junker race: does your car (and the field) look rusted, dirty and dented?
  The log's `[looks]` lines say what was applied. Each part can be switched off in config `Looks.riffraff`
  (`patina`, `dirt`, `damage`; `field = false` = your car only).
- [ ] **Underground v0.24, the money (economy pass):** leagues pay more (Junker x1.4, Challenger x3.4), a lost duel
  pays as last place. Does the cash feel right - enough to keep upgrading, not so much that it's trivial? The aim is a
  maxed car around race 60 (docs/economy-2026-11-13.md).
- [ ] **Underground v0.23, the Ace finals (when you get there).** Beating the Ace gatekeeper (The Qualifier) and then
  Kestar's Stadium Showdown should end on our result page (CHAMPION OF THE UNDERGROUND), with no black screen - the
  campaign's story scene is switched off for that race. Only tested in the test harness so far.
- [ ] **v0.28.1, the end of a cup and a DNF.** After the last race: the finish times with a CUP RESULT button (the
  game's CONTINUE gone); A takes you to the cup result. If you wreck or get knocked out: once the others finish, the
  standings and NEXT RACE show on the results screen like any race (the log says `out of the race (wrecked): a DNF`).
- [ ] **v0.28, pilot strength.** The Elite (Sen Fira, Biddy, Lyren) now drive +2 parts levels above you at Challenger
  and Ace (+1 at Riff-Raff); Goli, Griff and Nik +1; Malis and Ary -1. Does the same group fight you for the cup? Too
  hard, too easy? Each number is in config `AI.Strength` (one level = about 1.5-2 s on a ~110 s race). **Ace:** tested
  2026-11-12 - extra parts barely help up there (diminishing returns), so the Ace Elite may feel no stronger than the
  rest. If Ace feels too even, say so: a different lever (a speed boost on the Elite) would be next.
- [ ] **v0.27.5, the GRAND PRIX tab at game start.** The game now opens on its own main menu; pick GRAND PRIX
  yourself (or press F6). The tab should appear about a second sooner than before. If the menu ever acts up just
  after it appears (a crash, a tab that vanishes), say so: config `TabSettleS = 1.0` puts back the old wait.
- [ ] **v0.26, three leagues and random cups (not installed yet).**
  - **The first boot is a clean start**, as you chose: your save is copied to `save.backup-v2-<date>.lua` in the mod
    folder, then every medal, record, title, the boss and the leaders are cleared. Kept: your racer, your four
    abilities and your tune-ups. Kestar is locked again (if you race as him, you'll be Shade until you beat him after
    the Ace title). The log says it once: `[save] v0.26: three leagues - a clean start (backup ...)`.
  - HOME: JUNKER, CHALLENGER, ACE with the medal pips top left (v0.27: no chevrons). Focus each poster: does its
    tagline show under the name ("Outer Rim junkers and scrapyard hopefuls" / "Tuned rigs and pilots out to make a
    name" / "The fastest pilots in the galaxy"), and do they suit? Open a league: is the brief under its name
    ("Tuned engines - two abilities - one tune-up") readable? Wording lives in config.lua `Leagues`.
  - v0.27.3: while the finish times show, a STANDINGS button (A = standings now, else after 6 s), then NEXT RACE.
    No more "Leave the cup?" after pressing A.
  - StreamlineCampaign is now OFF (its enabled.txt renamed disabled.txt): does the game's own track intro (flyover
    with the track name) play at the start of our races? If yes, the track list can leave the cup screen.
    **Seen by Claude 2026-11-12:** yes - in all 23 launch checks the game's own intro (the flyover with the track's
    name, planet, RACE and laps) played. So the start screen's race list could go (your cinematic idea) - your call.
  - 2026-11-23: StreamlineCampaign turned back ON at the owner's request (campaign cutscene speed-ups). It also skips
    intro dialogue in our quick races (KNOWLEDGE §3); turn it off again before Grand Prix / Underground intro checks.
  - v0.27.2: Riff-Raff and Challenger open on a fresh save; only Ace is locked (5 Challenger trophies).
  - v0.27.1: after races 1-3 of a cup the game's finish times stay up for 6 s, then the standings. Long enough? (config
    `ChainRaces.Panel.TimesS`)
  - v0.27 Riff-Raff: afterburner, ramjet and battery parts at 2. Does it feel livelier, and does the field keep up
    (the bots seem to follow your power level)? Does "Stock engines" in its brief still fit, or "Hot-rodded junkers"?
  - Pick a cup: the start screen lists the four races drawn for it, with their conditions. B and pick it again gives
    a new draw. Does a drawn cup feel like a real season? Is the Galactic Cup (three planets, then the Gauntlet) right?
  - Riff-Raff (parts 0, the old 50cc AI), Challenger (parts 5, the old 150cc AI), Ace (parts 9, the old 200cc AI):
    does the ladder feel right?
  - **Done by Claude 2026-11-12:** all 23 pool races the GP had never launched were launched once (v0.28.2
    quitAfterS): all load with 12 racers and the right conditions - docs/data/launch-check-2026-11-12.txt / .png.
  - ~~**Never raced by the Grand Prix - the risk.**~~ The in-game check should launch each of these once (a quick race
    from the cup is enough: it loads, 12 cars, the right track and conditions). 27 variants (the doc's not-✓ ones);
    the 12 marked * were in the v0.6-v0.10 remix / conditions cups, the other 15 have never been in any version:
    - Jakku: THE WAR FIELDS (SCORCHING)* `EVT_MAS_LOOP_A_FWD_HARD`; THE WAR FIELDS (REVERSE, SCORCHING)
      `EVT_MAS_LOOP_A_REV_HARD`; DEBRIS DUNES (REVERSE, SCORCHING)* `EVT_MAS_LOOP_B_REV_HARD`.
    - Lantaana: GRIFFIN'S FLIGHT (WET)* `EVT_DAL_LOOP_A_FWD_Overcast_Wet`; MORO KEHN TUNNELS (NIGHT)*
      `EVT_DAL_LOOP_B_FWD_Night`; MORO KEHN TUNNELS (WET) `EVT_DAL_LOOP_B_FWD_Overcast_Wet`; MORO KEHN TUNNELS
      (REVERSE, NIGHT) `EVT_DAL_LOOP_B_REV_Night`; GEOTHERMAL TOUR (WET) `EVT_DAL_P2P_FWD_Overcast_Wet`; THE PYRODUCTS
      (NIGHT) `EVT_DAL_LOOP_A_SHORT_01_Night`; THE PYRODUCTS (WET)* `EVT_DAL_LOOP_A_SHORT_01_Overcast_Wet`; OVERFLOW
      RALLY (WET) `EVT_DAL_LOOP_A_SHORT_06_Overcast_Wet`; AHLREN JUNGLE SPEEDWAY (NIGHT)* `EVT_DAL_P2P_SHORT_05_Night`;
      AHLREN JUNGLE SPEEDWAY (WET) `EVT_DAL_P2P_SHORT_05_Overcast_Wet`.
    - Ando Prime: ICE FIELD CIRCUIT (SNOW) `EVT_COR_Loop_A_FWD_Overcast_Snow`; ICE FIELD CIRCUIT (REVERSE, NIGHT)
      `EVT_COR_Loop_A_REV_Night`; ICE FIELD CIRCUIT (REVERSE, SNOW)* `EVT_COR_Loop_A_REV_Overcast_Snow`; MONASTERY
      MOUNTAINS (NIGHT) `EVT_COR_Loop_B_FWD_Night`; MONASTERY MOUNTAINS (REVERSE, SNOW)*
      `EVT_COR_Loop_B_REV_Overcast_Snow`; MOUNTAIN TO SEA (NIGHT) `EVT_COR_P2P_FWD_Night`; DAI BENDU ASCENSION (NIGHT)
      `EVT_COR_P2P_REV_Night`; DAI BENDU ASCENSION (SNOW) `EVT_COR_P2P_REV_Overcast_Snow`; VONIUM PIPELINE (NIGHT)*
      `EVT_COR_Loop_A_SHORT_02_Night`; CLOISTER RUN (SNOW) `EVT_COR_Loop_B_SHORT_01_Overcast_Snow`; ANDOBI EDGE (SNOW)
      `EVT_COR_P2P_SHORT_05_Overcast_Snow`.
    - Crait: CRIMSON MINES (MINES)* `EVT_SPA_Loop_A_FWD_MINES`; CRIMSON MINES (REVERSE, MINES)*
      `EVT_SPA_Loop_A_REV_MINES`; SALT CIRCLE (MINES)* `EVT_SPA_Loop_A_SHORT_01_MINES`.
    - Sentinel I: none (every variant was already raced).
- [ ] **v0.24:** pick a cup and you land on the garage with START selected - quick enough? The medal row on each
  class tile on HOME, the lock and medal pictures, the ability and tune-up icons: pretty, readable? No grey bars
  behind tile text any more: does the text still read on the bright pictures?
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
- 2026-11-11 night, Claude's in-game check (owner away, save restored, md5 checked): v0.22-v0.24 seen working
  (CHANGELOG v0.25.0); fixed in v0.25: HOME opening on RESET, milky unfocused tiles, hard-to-read tile text, broken
  portraits. Title race: a lone bot's pace swings ~10 s; a leading bot doesn't wait (your 40 s slower Biddy was his
  own crashes or knock-offs). One parts level measured at only ~1 s (TASKS "Discussions": harder opponents).
  Screenshots: ~/Projects/swgr-underground/autotest/shots/n*.png.
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

## Vehicle model project (swgr-vehiclemodel, 2026-11-22)
- What vehicle class and look do you want (landspeeder / podracer / bike)? Sketches or references welcome.
- Where did the "Anakin's Podracer" reference mod come from (file location or link)?
- ~~OK to install Blender?~~ Done 2026-11-22 (Blender 5.3, no root).
- **Unreal Editor 5.7.4 needs your Epic login** (Claude can't download it): either download the Linux zip while signed
  in at https://www.unrealengine.com/linux, or link your GitHub account to Epic (Epic account → Apps and Accounts →
  GitHub, then accept the EpicGames org email invite) so Claude can build it from source.
- [x] **Rally cup extras** (2026-11-24): owner picked 1-4 (time standings, 4 cars, tour order + night finale, hidden weather) - built in v0.30.0.
- [~] **Playtest the RALLY CUP (v0.30.0): seen in the log 2026-11-24 evening** - hot reload at the menu loaded v0.30.0 fine; a Challenger run then a full Ace run as Ary Quill (rivals Sebulba, Malis Vazosk, Fola Kanjen): 4-car grid every stage, all four timed, put back at the menu every time, gold in 11:20.42. Owner 2026-11-25: "playtest was good" (Ace rally + v0.31 garage).
- [x] **Playtest v0.31 (PR #1 reworked): done 2026-11-25** - two vehicles with the rider's scheme "looked great" (v0.31.1); zip built. **Owner: upload dist/GalacticGrandPrix-v0.31.1.zip to Nexus** (text: docs/release/nexus-changelog-v0.31.1.txt; description: docs/release/nexus-description.bbcode). Was: faces, tiles and kept picks fine per the owner; **the rider's scheme never applied in v0.31.0** (`[paint] ... preset not loaded`, both tries) - v0.31.1 tries both LoadAsset forms and logs which worked: race once more on a vehicle that isn't the pilot's and look for `[paint] <name>: preset PRE_..._C (loaded by ...)` then the scheme on the car. Original list: the garage shows a PILOT tile with the racer's face on the left (the game's own icon) and a VEHICLE tile; cycling the pilot resets vehicle + abilities to theirs, your old picks survived the upgrade (log `[racer] your saved abilities kept`); pick a vehicle that isn't the pilot's own and race: does the car / bike / skimmer wear the rider's scheme (log `[paint] <name> <vehicle>: PRE_... before the race`, then `[paint] put back (main menu)`); the title race tile and Kestar's show a face; any face drawing broken (the v0.25 problem was the big previews - these are the 256 px icons). the tile sits after the title race (and Kestar at Ace); does the 4-car grid load and race (3 named rivals, logged `[rally] rivals`); do all four get times on the standings (a `*` marks a made-up one); is the weather really hidden until the stage loads; does the route list on the start screen read well; does the make-up / Opponents put-back log at the menu (`[title] grid put back`). Note the race-1 line `[title] grid cut for the rally`.
