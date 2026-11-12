# Work plan: Galactic Grand Prix

Design: DESIGN.md. Shared playbook and house rules: ~/Projects/swgr-underground/AUTOMATION.md.
One git tag per chunk; push after each tag. Questions and playtests for the owner: OWNER.md.
**Done work and the old plan (to v0.27.5, 2026-11-12): docs/TASKS-done.md.** This file holds open work only;
when an item is done, move it there with a one-line result.

Now: v0.27.5 installed (2026-11-12). Three leagues (Riff-Raff / Challenger / Ace), random cups, the garage as the
start screen, cups chained on the results screen.

## 1. Next up: better AI drivers (owner kicks it off)
**Kickoff prompt:** "Start the AI driving spike in TASKS.md - I'm away for about an hour." Needs the desktop to
Claude alone (the owner away), the game closed at the start. Back up the owner's save first (md5), restore after.

**Why (owner, 2026-11-12, after a day of Challenger cups):** "some tracks are close or i take 2nd-4th but never
lower, some tracks i'm ahead by 15+ seconds ... i think the AI could still drive better, they don't seem to use the
afterburner or ramjet very well, and they crash and make mistakes more than i think they would ... i'm going for
realism here so i'm open to ideas. We could make all the enemy vehicles a little faster or slower at random."

**What the log showed (Challenger, 2026-11-12, `[gaps]` lines in grandprix.log):**
| Track | You | Gap |
|---|---|---|
| Cloister Run (snow) | 1st | +17.9 s to Griff Halloran |
| Mountain to Sea | 1st | +15.4 s to Malis Vazosk |
| Dai Bendu Ascension (snow) | 1st | +9.7 s to Lyren Shok |
| Scrap Spiral | 1st | +5.9 s to Shade |
| Fallen Empire (scorching) | 1st | +4.3 s to Goli & 02-R0 |
| Griffin's Flight | 2nd | -1.8 s to Lyren Shok |
| Andobi Edge | 2nd | -1.3 s to Goli & 02-R0 |
| The Giants' Graveyard | 2nd | -3.3 s to Lyren Shok |
| The Pyroducts (wet) | 3rd | -2.6 s to Katja Mox |
| The War Fields (reverse) | 3rd | -7.4 s to Sen Fira |
- The field spread 1st-12th is 21-43 s every race: far looser than a real field of similar cars.
- The best bot is often a weak pilot (Malis Vazosk, Griff Halloran) while the campaign's Elite (Sen Fira, Biddy
  Blas, Lyren Shok) finish far back: results look decided by mistakes and crashes, not by pace. Snow tracks and the
  long sprints are the worst for the bots.
- Challenger and Ace already run the bots with no help and no handicap we know of: no catch-up, no slowdown for
  you, no forced errors, no easing off while you crash, no speed matching (config `AI.Profiles`). So what's left is
  how they drive. (Riff-Raff still has the mercy slowdown 0.4 and forced errors - on purpose.)

**Levers, matched to what the owner saw** (full detail: docs/ai-driving-research-2026-11-12.md):
1. **Afterburner / ramjet use - the driving style's boost rules** (`URaceAIDrivingStyleDef` DS_Car_Base /
   DS_Bike_Base / DS_Skimmer_Base): `MinEnergyForAfterburner`, `MinTimeBetweenBoosts`, `MinBoostTime`,
   `MaxDegreesOffHeadingForBoost`, `BoostTopSpeedThresholdRatio`, `MinRacePacingFactorForBoost`,
   `RamjetExtrapolationTime`. Most direct fix for "they don't boost well"; free pace, no rubber band.
2. **Crashes and mistakes:** the AI-only affixes `AFX_AI_SlowerCrashRecovery` / `AFX_AI_TemporarilySlower` and the
   tune sets `TNS_AI_General` (on every bot via DA_AIConfig) / `TNS_AI_ReducedPower` look like built-in handicaps:
   if so, neutralise them at Challenger / Ace (memory only, put back at the menu). The style's look-ahead, aim point,
   corner extrapolation and avoidance numbers may be behind the crashes, but steering gains are risky (unstable
   bots crash more) - try last, small steps.
3. **Faster / slower cars at random - "pilot strength + form":** the bots' race copies are already edited at load
   (loadout.lua), and every build has parts levels (`UpgradeSlots`) and a `PowerLevel` / `OverridenPowerLevel`.
   Claude's pick for realism: each pilot a fixed strength (the Elite always quick, Malis / Ary always slow) plus a
   small per-race form swing (about +-1 parts level), so the same rivals are usually the ones to beat and an
   underdog can still have a day. Unproven: the old "bot parts don't change pace" finding was made with the rubber
   band on, which hid it. Also possible: a constant tune-set boost (catch-up's `TNS_AI_Catchup_Boost` applied once,
   never removed - a faster field, not a rubber band).
4. (Possible later) a per-track AI adjustment if some tracks stay lopsided after 1-3: static, measured once, not a
   rubber band.

**Owner to decide before step 3 is built:** fixed pilot strength + small form (Claude's pick) or fully random?

**Steps** (house rules: no hooks, no per-tick lookups in races, nothing kept between ticks, writes memory only and
put back at the menu, key binds only set flags):
- [ ] 1. Recon, read only (tools/recon/AIDriveRecon, one launch): at the menu log every field of the three driving
      styles, the operations of the four AI tune sets, the two AFX_AI affixes' definitions, DA_AIConfig's avoidance
      fields; at race load each bot's race-copy `PowerLevel`, `OverridenPowerLevel`, `UpgradeSlots` and affix slots.
- [ ] 2. Held-race batches (TestAutopilot `hold.txt`: your car stays on the line, the 11 bots race each other - a clean
      measure; the autopilot uses the same driving styles, so never measure against it). One change at a time against
      an untouched baseline, 3 races each on one track (The Giants' Graveyard, Challenger), plus one snow track (Cloister
      Run) where the bots are worst. Order: (a) boost rules relaxed, (b) the handicap affixes / tune sets off, (c) bots'
      parts +2, (d) catch-up tune applied once. Log finish times, spread 1st-12th, DNFs / crashes. ~15-20 races,
      about 1-1.5 h of game time.
- [ ] 3. Report (docs/ai-driving-results-<date>.md) and a proposal per league; the owner picks, then build it as a
      version and the owner races a cup at Challenger and Ace.
- Done: desk research (docs/ai-driving-research-2026-11-12.md). Tools: TestAutopilot v1.5 (hold.txt); the
  job-scratch scripts step.sh / apwait.sh / chainrace.sh / titlerun.sh (copy into tools/ if the job folder is gone).

## 2. Waiting on the owner's play (details and tick boxes in OWNER.md "Playtests")
- [ ] v0.27.x: the finish times then STANDINGS (A, or 6 s); Challenger open from the start; Riff-Raff's feel (parts
      2 on three slots); the posters' taglines and the cups page brief; the garage's TUNE-UP / ABILITY captions.
- [ ] Does the game's own track intro (flyover) show in our races now StreamlineCampaign is off? If yes: drop the
      race list from the start screen header (`startHeader`, main.lua) for a cinematic intro instead.
- [ ] v0.27.5: the tab at game start (no auto-open; ~1 s sooner; `TabSettleS = 1.0` if the menu misbehaves).
- [ ] The parts slot-to-stat mapping (CORNERING / AFTERBURNER / RESILIENCE / RAMJET / BATTERY / DRIFT vs
      `EVehiclePartSlot` 0-5) - unconfirmed.
- [ ] Riff-Raff's brief "Stock engines" now it has parts 2 (e.g. "Hot-rodded junkers")?
- [ ] 27 never-launched race variants from the random pools (OWNER.md v0.26) - launch each once.
- [ ] Do the AI fire their abilities, Shields included (R7)?

## 3. Known gaps (small fixes)
- [ ] **A DNF skips the results panel:** our panel waits for the finish flag, which a DNF never sets, so the game's
      own results show with CONTINUE and our standings come at the main menu. Fix: also act on elimination.
- [ ] **The last race of a cup** still uses the game's own results screen with a live CONTINUE (the standings and
      cup result come at the menu). Same treatment as races 1-3?

## 4. Discussions (owner's call; talk before building)
- **Kestar is a weak final boss** (veers off the line, loses by ~20 s even to the autopilot; the Showdown was likely
  built around the game's catch-up). Boss keeps the game's own AI, a boss profile, or leave him? (OWNER.md) The AI
  spike above may fix it anyway.
- **The Galactic Cup format** (three random planets, then The Galactic Gauntlet): right, or something else?
- **Tune-ups gated by league** vs earned (trophies, golds, titles) or not gated at all; **heat / cold and the
  packs** - make picking the right pack matter more, or drop it.
- **Ideas for the future (owner, 2026-11-12):** a deeper dive into the tune-up system; a **Grand Tour** (every track
  on a planet, or all 86); a **podracing cup or league** (docs/tracks-by-planet.md "Not in the cups"); **leaning by
  league** for the random cups (Riff-Raff mostly forward layouts, conditions likely at Ace).
- **Progress badges** beside HOME (the game's insignias) in place of goal lines.
- **PHILOSOPHY.md is out of date** (rival cut, leagues): rewrite to match today? (OWNER.md)

## 5. Housekeeping
- [ ] attic/ cleanup (old study mode, the chain reset route): keep, or delete now nothing uses it.
- [ ] Test mods left disabled in the Mods folder (LookSpike, RaceFlowSpike, the recon mods): remove when done.

## 6. v1.0
- [ ] The owner plays every cup at every league; tune parts, AI, AI kits, points. Tag v1.0.0.
