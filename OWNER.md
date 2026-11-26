# For the owner: questions and playtests

Claude's running list of what only you can answer or judge. Tick a box, or write a note under it, and Claude picks it
up next session. Newest first in each section. (Started 2026-11-11; Claude keeps it current.)

## Questions for you
- [ ] **Your saves after the away session (2026-11-26 ~00:50):** the Grand Prix save is back exactly as you left it (md5
      a9a708df..., backup in ~/.local/share/swgr-save-backups/away-20261125/). The game itself had rewritten its meta save
      `GriffinSave.6.sav` during the test races (one recon race was the campaign flashback "Memories of Mos Espa"), so that
      file was put back from the backup too (the changed one is kept in `game-after-session/`). **If Steam reports a cloud
      conflict at the next start, pick the local files.**
- [ ] **The PODRACER CUP's name (2026-11-26):** PODRACER CUP (PODRACING CUP is one letter too long for a tile), OK?
      (v0.41: the other two calls are settled by the PODRACING league - abilities on your pod come at PRO after the
      recon, and the pods no longer count toward a car league.)
- [ ] **Merge to main (2026-11-25):** this session could not move `main` (it works in the `heat-plan` worktree). Everything
      is on branch `worktree-heat-plan` (pushed), a fast-forward of main: in ~/Projects/swgr-grandprix run
      `git merge --ff-only worktree-heat-plan` (and `git push`). KNOWLEDGE.md edits in ~/Projects/swgr-underground are
      uncommitted for the same reason.
- [ ] **Plain-English review, 86 lines (2026-11-25, TASKS §1j) - please do this one first:**
      https://claude.ai/artifact/EaNJsutAe6cWz2RPApBvNL - every line the mod writes on screen, now vs proposed, an
      Approve box and a note per line (saved as you go; Claude reads them back). Also as a doc:
      docs/plain-english-2026-11-25.md. Nothing is installed until you've been through it. Two picks in there are yours:
      "NEW LAP RECORD" vs your "BEST LAP" wording (L64), and "SLOWER THAN" vs "OFF" for the near misses (L62, L65).
- [ ] **The stars (2026-11-25, TASKS §3):** today the gold star on a league tile = you beat Kestar Bool in that
      league's Galactic Cup finale (league champion), and the star in a cup tile's corner = a perfect cup (every race
      won). Claude's pick: say it in the info line under the focused tile, and give the perfect cup a different icon
      so one star means one thing. OK, or would you rather drop one of the two stars?
- [ ] **Best laps (2026-11-25, TASKS §1g item 16):** (1) a line each lap as you cross the finish (lap time, +/- your
      record, NEW BEST LAP), or only TIME TO BEAT at the start and BEST LAP at the end? (2) one lap record per track
      per league (as saved now), or one per track whatever the league? (3) show your best race time at the start too?
- [x] **Layout grammar (2026-11-25, docs/layout-grammar-2026-11-25.md):** answered the same day: (1) the game's left
      column, (2) the game's typefaces, (3) the cups page as 4 + 3 at 500 x 340. Built one item a version (TASKS §1a-menus).
- [x] **Menu text and layout review (2026-11-25, docs/menu-text-review-2026-11-25.md):** answered "use your recommendations,
      do one version, go" - the announcer's voice, Claude's taglines, the planet lines, one version: **v0.35.0** (the words).
      Pass 2 (the layout: the results prompt split, RESET smaller, the cups header) one item a version, after your read.
- [ ] **League cars (2026-11-25, plan in docs/league-styles-2026-11-12.md "2026-11-25"; L1 built as v0.34.0, installed):**
      (1) Challenger at 7 on every part - confirm (was 5)? (2) Junker wreck limit 5 (the game's is 3) - or more? (3) Ace
      bots: keep their full ability kits, or defensive / utility only for a cleaner field? (4) Ace pilot strength is
      shifted down (Elite at your 10, contenders 9, weak 7) - but "nothing goes above 10" is unproven (the game's own
      level 10 is 13 stacks): keep the shift, or test the old +2 / +1 / -1 at 10 in a held race?
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
  in-game recon - **done 2026-11-26**: both modes launch from our flow, and `modeFrom` makes ANY track an eliminator
  with the points already right (results in the doc §2). Your pick of A-D.
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
- **Best-lap leaderboard (later idea, TASKS §4, 2026-11-26).** When it's time to build it: where should the shared
  board live? GitHub repo + JSON (recommended: free and visible, but pushers need a GitHub account), a Cloudflare
  Worker (no account needed, someone has to keep spam out), or a Google Form + Sheet? And should it appear in the
  Nexus release, or stay just for you and friends?
- **Reboot the PC when convenient** - GPU faults (kernel Xid) still happen in races; no reboot since 2026-11-12. **Rebooted 2026-11-22** (the NVIDIA driver update needed it); before that: **Owner away all week (2026-11-15): no reboot until then** - tests run on the un-rebooted PC (same as the 2026-11-15 baseline).

## Playtests (only a real race can tell)
- [ ] **v0.42.0, the PODRACING page and your pod (2026-11-26, installed 11:44, not yet seen in game):** the PODRACING poster opens a page with
      LEARNER and PRO as posters; the start screen's PILOT tile cycles the five pilots with a pod (Shade, Goli, Fola,
      Sebulba; Kestar once beaten) and the vehicle tile names the pod. Check: does Goli / Fola / Sebulba really fly their
      own pod (the recon only raced Shade and Kestar)? B goes start screen -> PODRACING -> HOME.
- [ ] **v0.41.0, PODRACING as its own league (2026-11-26, installed 11:26, not yet seen in game; save backup save.backup-20261126-112649.lua):** HOME has a PODRACING poster
      after ACE (a medal per step); it opens the PODRACER CUP's start screen, where the DIFFICULTY tile cycles LEARNER / PRO.
      The car leagues' cups pages lose the PODRACER CUP tile. Check: your v0.40 pod trophy shows on the LEARNER medal;
      B from the start screen goes HOME; PRO feels harder (it is the AI only for now - abilities need the recon, PL0).
- [ ] **v0.40.0, the PODRACER CUP (2026-11-26, installed) - P8, the pacing, is yours:** a new tile after the Rally Cup at
      every league: 4 races on the pod tracks (Mos Espa, Mawhonic and Holdfast's Folly, forward and reversed, dry or
      weather), you in your pilot's podracer (Shade's MythP3 unless you race as Kestar, Goli, Fola or Sebulba) against
      the 6 pod racers and Kestar Bool: 8 pods. Seen working (a race through to the standings and the next race; a crash
      put right at the next start). Race two cups and tell me: too easy / too hard (the autopilot was 2nd by 0.75 s, the
      field within 12.5 s), do the pods rocket off the line, any track that breaks (the reversed Holdfast's Folly is the
      game's least finished). The `[gaps]` lines in grandprix.log will help me tune it.
- [ ] **v0.39.0, TIME TO BEAT (2026-11-25, installed):** while the countdown runs, "TIME TO BEAT 0:49.81" (your lap record
      on this track at this league) or "NO LAP SET", middle of the screen, gone at the green light. Seen working in 3
      races. Too big, too low, wrong colour? (`TimeToBeat.Size` / `Y` / `Color` in config.lua). The per-lap line is built
      but off until you answer the best-laps question above (`TimeToBeat.LapLine = true` to try it: "LAP 1  0:47.73
      +0.35" for 4 s, up to 2 s after the line).
- [ ] **v0.38.1, the orange = the tab pill exactly (2026-11-25, installed):** read off the screen (sRGB 177, 81, 60; the
      v0.36.4 orange was much lighter because UMG colours are linear). Seen: right on the sand; it fades where a line
      crosses the dark grey starship (HOME's star line's right end, the cups page info line over the Jakku wreck, the
      start screen's cup name). OK, or a dark backing there?
- [ ] **v0.38.0, best lap on the standings (2026-11-25, installed, seen in game):** "1st - 1:12.88 - best lap 0:15.95 -
      0.9 s ahead"; "NEW RECORD 1:12.88, was 1:13.26 - NEW BEST LAP 0:15.95" on one row; "0.3 S OFF YOUR LAP RECORD" when
      close. `LapTimes = false` = as before.
- [ ] **v0.37.0, the stars (2026-11-25, installed, seen in game):** HOME's info line now has a second line under the
      rules ("Gold star: the league title. Finish the Galactic Cup in the top 3, then beat Kestar Bool..."); a perfect cup
      wears a small crown (the game's champion-event icon) instead of the star, and its info line says "Crown: a perfect
      cup. You won every race." (your Challenger Jakku Cup shows it). The crown is faint on Jakku's orange art - OK?
- [ ] **StreamlineCampaign 1.0.4 (2026-11-26, installed, not released - branch `prologue-every-race`):** from the
      1.0.3 scene log of your full Restart Campaign: there's no vehicle choice at the start of Act I (the prologue
      ends in the Mastiff paddock, then the CampaignIntro race in your landspeeder). 1.0.4: prologue skip on (every
      prologue race), the ship-on-pad scene (17 s) at 8x, logging off. Restart the game, Restart Campaign: prologue
      gone, quick arrival? If right: I merge, build the 1.0.4 zip, you upload to Nexus. 1.0.1 backup in
      `~/.local/share/swgr-mod-backups/`.
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
- [ ] **v0.36.4, every pale menu page (2026-11-25, installed while the game ran - restart first):** the text on HOME, the
      cups page, the standings and every other page without a picture is burnt orange now (titles and lines R 0.78 G 0.33
      B 0.06, the small print a deeper rust), the sand strip gone. Does it read over the droid and the Steam box, and over
      the sand? Too loud, too brown? Name the shade you want and it is one line (`Ink`, `Ink2` in config.lua).
- [x] **v0.36.3, HOME:** the sand strip - owner 2026-11-25: it covered one line, the grey stayed on the other menus; a burnt
      orange ink instead (v0.36.4). The CHOOSE A LEAGUE heading stays.
- [ ] **v0.36.5, the cup result's bottom half again (2026-11-25 ~22:50, installed while the game ran - restart first):**
      your Jakku cup screenshot: "60 OF 60" wrapped into three big lines under PARTICIPATION STREAK, the other tile still
      WIN COUNT, the title RESULTS. Now one tile only under the timeline, centred, headed CUP RESULT: 1ST, GOLD TROPHY, the
      medal. The points tile is gone with its heading and backer; the title is the cup and the league ("JAKKU CUP  -
      CHALLENGER"). Check: is the tile centred in its row at its normal width (or stretched across, or still at the left)?
      Does the heading read CUP RESULT (with its Aurebesh line)? Does the title take? Not seen in game (built from the
      header dumps while you played); the log's `[cupend] tile holders` and `panels:` lines say what was found. If you'd
      rather see the final top 3 there after all, say so. `CupResult.Tiles = 'result'` brings the two tiles back.
- [ ] **v0.36.1, HOME and the cups page (2026-11-25):** focus each league on HOME: the rules line under the posters -
      JUNKER "Afterburner and ramjet wound to ten on a scrapyard chassis. Cornering, resilience and drift stock, the battery
      barely holding. One ability, no tune-ups." / CHALLENGER "Every part at seven, and every rig on the grid the same. Two
      abilities, one tune-up." / ACE "Every part at ten, every credit spent. Three abilities, two tune-ups, and the field fires
      everything it carries." Right facts, right voice, short enough? The cups page: no track names and no brief under the
      league's name any more; each planet cup's info is its planet's line alone.
- [ ] **v0.36.0, the game's fonts (2026-11-25, installed while the game ran - restart first):** every line outside a
      tile now uses the game's own typefaces (page titles the display face, sentences and the info line the body face,
      the standings' number columns the numbers face). Look at HOME, a cups page, a START screen and one results panel:
      is the display face the same heavy face as the tiles (else `GameFonts.display` should point at Font_Decorative)?
      Too big or too small anywhere (`size` multipliers in config)? Layout is unchanged in this version on purpose.
- [ ] **v0.35.0 the menus' words (2026-11-25):** read them where they live - HOME (the taglines, a locked league), a cups page
      (the brief, a cup's planet line and circuits, the Galactic Cup and Rally Cup lines), a START screen (the pilot, vehicle,
      ability and tune-up info lines; a locked tune-up tile now titled ACE), one results panel (the caps headline, the
      "NEXT   ...          B   LEAVE THE CUP" prompt). Anything that reads flat or wrong: say which line, and the voice it
      should have. The two taglines are the ones to argue with most.
- [ ] **v0.34.3 Rally Cup catch-up (2026-11-25):** your ask "a much stronger catch up factor" - the rivals now get x1.6 pace
      when 0.5 s behind (the game's own is x1.3 after 2 s; the leagues run 1.0 = none). Race a rally: do the rivals stay with
      you on the stages (the `[gaps]` lines in grandprix.log were 15-57 s behind at 16:27-16:30)? Too strong = they sit on your
      tail whatever you do; then 1.4 (config `Rally.AI.pacing.MaxAiCatchupScale`). Also: should the catch-up reach the planet
      cups' back markers too, or stay a rally thing?
- [ ] **v0.34.0 league cars (2026-11-25):** a cup at each league (§1b L4 after L2 / L3 too). Junker: do the engine-10
      straights and stock corners feel like junk that goes too fast, and is it fun or a pinball? Challenger at 7: right
      step up? Ace at 10: too fast (the old 200cc at 9 was "fast and brutal")? Do Sen / Biddy / Lyren still lead at Ace
      now they race your car (`[builds]` lines in grandprix.log show each tier's levels)?
- [ ] **v0.33.0 (2026-11-25, your two asks of the afternoon; install with the game closed: `./deploy.sh`):**
  - ~~**The planets on the cup tiles**~~ seen 2026-11-25: "didn't really turn out like I wanted them to" - off in
    v0.34.1 (`CupPlanets = false`, code kept). If you ever want another go, say what look you had in mind.
  - **Kestar as the Galactic Cup finale:** race a Galactic Cup to a trophy - after race 4 the standings should say
    "... TROPHY SECURED - NEXT: KESTAR BOOL, 1 v 1 FOR THE ... TITLE" and NEXT RACE launches the Stadium Showdown (6
    laps, his cinematics off). Then the cup result: CHAMPION (or "KESTAR BOOL KEEPS THE TITLE"), the crown on the last
    dot only if you won. Known from before: he is a weak boss without the game's catch-up (OWNER "Kestar is a weak
    final boss") - say if the finale feels too easy and I'll give him a profile of his own.
- [ ] **v0.32.6-8 (2026-11-25 evening, your picks 9-11), installed 2026-11-25 18:00 after the playtest:**
  - **The cup result screen (10):** seen 2026-11-25 (Sentinel gold): "I love the layout of the screen and the recap"; after the
    Ando cup: "Participation streak and win count seem superfluous" -> **v0.34.2:** the streak tile is gone, the WINS tile is the
    trophy over your standing, the title line says "GOLD TROPHY, 1ST" too. Check: does the tile now read GOLD TROPHY / 1ST, or
    still WINS and a number? If the latter, the game's text bindings win - the log's `[cupend] tiles read back` line says so, and
    the title line still carries the verdict; next step then would be our own text over the tile.
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
- [x] **PODRACING league (2026-11-26):** two steps (LEARNER / PRO); the v0.40 cup results move to LEARNER; both steps
      open from the start. Built v0.41.0 (TASKS §1h-L PL1-PL2).
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
