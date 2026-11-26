# Kickoff: owner away (picked 2026-11-25)

Paste the prompt below into a fresh Claude Code session started in ~/Projects/swgr-grandprix.

---

I'm away for a while; work through this queue on the Galactic Grand Prix mod without me. Don't wait for me on
anything: when a call is mine, make a sensible pick, note it in OWNER.md, and keep going.

**Before anything:**
1. Read CLAUDE.md, ~/Projects/swgr-underground/KNOWLEDGE.md, ~/Projects/swgr-underground/AUTOMATION.md, DESIGN.md,
   TASKS.md, OWNER.md. The house rules apply throughout: offline only, no hooks, never keep UObjects between ticks,
   one git tag per chunk, push after each tag.
2. The branch `worktree-heat-plan` holds 5 TASKS / OWNER commits from 2026-11-25 (orange ink §3, best laps §1g-16,
   the stars §3, plain-English pass §1j, this kickoff doc) that main doesn't have yet. Merge them onto main first
   (docs only; resolve any TASKS.md / OWNER.md conflicts by keeping both sides).

**Desk work first (no game needed):**
3. **§1j plain-English pass.** Follow TASKS §1j exactly: the rules, the full inventory of every player-facing string
   we wrote (file:line, where it shows, old, new), the examples as the bar. Publish the table as an artifact page
   (old / new side by side, an approve box and a note per line) for me to review. **Do not install the new
   strings** until I've approved them: the page and a doc in docs/ are the deliverable. Link it in OWNER.md.
4. **§3 the stars.** Build Claude's pick from TASKS §3: the info-line text on HOME (league title) and on the cups
   page (perfect cup), and a different game icon for a perfect cup so the star means only the league title. Word
   the new lines to the §1j rules. Tests, tag, install.
5. **§1g-16 best laps, results part.** BEST LAP beside the race time on the results / standings, NEW BEST LAP on a
   record, the near-miss "0.4 S OFF YOUR LAP RECORD" sharing the NEW RECORD row (DESIGN v0.12), using
   `records[league][eventPath].lap`. A config off switch (`LapTimes`). Tests, tag, install.

**Then the game (one session at a time):**
6. Check nothing else is driving the game (`ListAgents`; another session named "1. SWGR - Coding" may be open:
   if it is using the game, wait and do desk work). Check `nvidia-smi` works before launching (see memory: a driver
   update breaks GL until reboot). Close the running game as AUTOMATION.md says. **Back up my save (md5 it) and
   play on a test save; restore my save at the end and check the md5.**
7. **Orange ink (§3).** Screenshot the main menu with GRAND PRIX highlighted, read the selected tab pill's exact
   colour (from the widget's brush if readable, else the screenshot), set config `Ink` to it and `Ink2` to a
   darker shade of the same hue; screenshot the pale pages to check they're readable (droid, Steam box). Record the
   value in KNOWLEDGE.md. Tag, install. While in the menus, screenshot the stars text from step 4.
8. **§1g-16 in-race spike.** Can we show our own text in a race? Try "TIME TO BEAT 1:12.40" through the countdown
   (a plain UserWidget in the viewport vs a HUD text the game already shows), respecting the HUD flag
   `TheaterShowHidesHud`. If it works, build the start line (and the per-lap line behind a config switch, off
   until I answer the OWNER.md question). Write the outcome into KNOWLEDGE.md. Tag, install whatever is finished.
9. **§1h Podracing cup.** P1 recon exactly as TASKS §1h says (PodTry recon mod, docs/podracing-recon-<date>.md,
   KNOWLEDGE rows), then keep going through P2-P7 as far as the time allows, one tag per chunk, installing each
   finished one. Use the autopilot (TestAutopilot, AUTOMATION.md) to drive races; don't steer with scripts. P8 (pacing)
   is mine: leave it in OWNER.md as a playtest.
10. **§1d race-types recon** if there's time left: the in-game recon line in TASKS §1d; write the results into
    docs/race-types-2026-11-13.md. Research only, no build (the shape is my pick).

**Throughout:** a crash or hang: read the logs and the crash dump (AUTOMATION.md), fix or back out, never leave a
broken install. Keep TASKS.md (tick / move done items to docs/TASKS-done.md), CHANGELOG.md, OWNER.md (a playtest
line for every installed change, a question for every pick I need to confirm) and the swgr-grandprix memory current.
At the end: game closed, my save restored (md5 matches), the last good version installed, and a report: what got
done (versions / tags), what's installed, what's waiting on me (the §1j review page link first), and what's next.
