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
- [x] 1. Recon, read only (2026-11-12, one launch): **docs/ai-driving-results-2026-11-12.md.** Every bot drives an
      exact copy of YOUR car (same parts, power 30) - nothing in the cars tells pilots apart; no hidden handicap
      affixes at load (TNS_AI_General helps the bots); the boost rules are cautious, the bike's most of all. Step 2's
      switch (`experiment.lua`: styles, config, bot parts, a fixed event, every racer's time) is built (v0.27.7).
- [x] 2. Held-race batches (2026-11-12, 12 races, docs/ai-driving-results-2026-11-12.md "Step 2"): boost rules no
      effect; bot parts work (+2 levels = ~3-4.5 s); pilot strength puts the Elite on top; the race-to-race swings
      (~20 s per pilot) are the bots' own mistakes and stay.
- [x] 3. Report and proposal (results doc). Owner: fixed strengths, no per-race randomness. **Built as v0.28.0**
      (config `AI.Strength`). Next: the owner races cups at Challenger and Ace (OWNER.md). Ace checked 2026-11-12:
      extra parts barely change the bots there (results doc); if Ace feels even, try TNS_AI_Aggression_Boost on the Elite.
- Done: desk research (docs/ai-driving-research-2026-11-12.md). Tools: TestAutopilot v1.5 (hold.txt); the
  job-scratch scripts step.sh / apwait.sh / chainrace.sh / titlerun.sh (copy into tools/ if the job folder is gone).

## 1a. Release pass for Nexus (owner 2026-11-13: "start the release pass")
Owner's plan: keep playing ~a week without crashes, then publish as a beta.
- [x] Test switches behind config `DevTools` (off for players; `deploy.sh --dev` for research).
- [x] `tools/package.sh`: the release zip (checks: no save / log, DevTools off, every script compiles, no local paths).
- [x] Player README (docs/release/README.txt, in the zip) and the Nexus description (docs/release/nexus-description.bbcode).
- [x] `tools/mods-toggle.sh`: all mods off for multiplayer.
- [x] UE4SS link (Nexus mod 2); no licence (owner: Nexus's own permission settings instead), screenshots: docs/release/screenshots/ (5, 2560x1440, the
      Steam name blurred).
- [x] Resolution check (2026-11-13, windowed 1920x1080 and 2560x1440): HOME, cups, start screen and the standings
      scale cleanly. Small fixes: [ ] the SENTINEL CUP label is cut off at 1440p (wraps at 1080p); [ ] the Junker
      tagline runs past its strip on HOME (all sizes).
- [ ] **Launch hang** (1 of 5 launches today, 3 of 4 on 2026-11-12): black screen before the main menu, UE4SS.log
      ends at "Event loop start" (all mods loaded). Not yet known whether it's the mods, SkipIntro or Proton: try
      launches with GP off, then SkipIntro off. A must-know before publishing (players will blame the mod).
  **2026-11-13 lead:** three launches in a row looked exactly like this (blank screen, log ends at `Event loop start`)
  but were busy (CPU 800-1400%) and reached the menu after 4.5-5 min. Most "hangs" may be slow starts (shader rebuild?):
  wait 5+ min, watching CPU, before killing. KNOWLEDGE.md section 3.
  **2026-11-13 afternoon:** one more hang with the CPU idle (~3%, "not responding" after ~7 min) - a different kind
  from the busy slow starts; 6 other launches that day took 15-18 s. Relaunch fixed it.
- [ ] A week of crash-free play, then `tools/package.sh <tag>` and upload as a beta.
- [x] **FreeRace 1.1c + 1.3 read (2026-11-25)**: `docs/freerace-review-2026-11-25.md`; items 1-6 built as v0.32.x, the rest listed in §1g.

## 1a-menus. Menu text and layout review (owner 2026-11-25) - pass 1 built v0.35.0, pass 2 open
**docs/menu-text-review-2026-11-25.md**: the voice (§1), every screen's text with replacements (§2), four layout changes
(§3), the build plan (§4). Owner: "use your recommendations, do one version, go".
- [x] Pass 1, the words (v0.35.0): every §2 line, plus §3.2 (a locked tune-up tile titled by its league). Owner to read
      them in game: HOME, a cups page, a START screen, one results panel (OWNER.md).
- [ ] Pass 2, the layout, one item a version, each seen in game: §3.1 the results prompt as two text blocks (next race left,
      the B hint right); §3.3 RESET PROGRESS smaller and off the D-pad path; §3.4 the cups page header centred over the tiles;
      ~~§3.5 check the cup result's award lines fit without the game's ellipsis~~ (moot: the award lines are off, v0.36.2).
- [ ] **Layout grammar (2026-11-25, docs/layout-grammar-2026-11-25.md):** measured against the game's own CAMPAIGN page.
      Units are a 3840 x 2160 slate; the game's content is a left column x 120-2205 (clear of the speeder and the droid),
      ours are centred and 750-1135 units wider; our out-of-tile text is UMG's Roboto, not the game's faces; one ink on pale
      pages. Owner 2026-11-25: left column, game fonts, cups 4 + 3. Build order (§5), one item a version, each seen in game:
      - [x] 1 game fonts: v0.36.0 built + installed 2026-11-25 while the game ran (restart needed); owner to look at HOME,
            a cups page, START and one results panel; `[fonts]` log lines say which assets were found
      - [ ] 2 the column (spec.column x 120 w 2085, rows + header left-aligned, GAP 28 / 40)
      - [ ] 3 cups 4 + 3 at 500 x 340, the info line's 2-line box (the circuits are off the page since v0.36.1, `CupTracks`)
      - [ ] 4 the results prompt as two blocks (§3.1), RESET PROGRESS small (§3.3)

## 1a-rally-ai. The Rally Cup's catch-up (owner 2026-11-25) - v0.34.3, untested in game
"the enemies need a much stronger catch up factor": config `Rally.AI` on top of the league's profile (`A.merged`): catch-up
x1.6 after 0.5 s behind. **Open:** the number (1.6 a guess; the owner's next rally's `[gaps]` lines decide); whether the
15 s start grace should hold the catch-up at the game's value (FreeRace held MaxAiCatchupScale at 0 for 15 s; ours lives on
the assets, written at launch, so a hold would need a second write at 15 s); a catch-up for the planet cups' back markers.

## 1a-cupend. The cup result screen's bottom half (owner 2026-11-25) - v0.34.2, v0.36.2
v0.34.2: "Participation streak and win count seem superfluous": WINS tile = trophy over standing, title line carries the
verdict. The 18:01 read-back (Rally Cup, Junker) settled the open question: `SetText` sticks (Wins label=GOLD TROPHY
amount=1ST), the tile texts are not bound.
v0.36.2 (owner: "the bottom half doesn't really make much sense"): the bottom half was the game's PvP rank-up panel - a bar
from "1st" to "GOLD", the points as XP, the races as XP awards. `CupResult.Progress = false` collapses it; the second tile
is POINTS over "102 OF 105".
v0.36.5 (owner's Jakku screenshot 22:37: "the bottom half needs to be reworked, it still doesn't make much sense ... less is
more"): "60 OF 60" wrapped into three big lines, the game's headings PARTICIPATION STREAK / WIN COUNT stayed, the title
stayed RESULTS (our text names were wrong; the widget has `SetScreenTitleText`). Now one tile: the trophy tile's section
holder (`WBP_Panel_Presentation_SectionHolder_C`, found by GetParent) headed CUP RESULT through its `WBP_SectionSubLabel:
SetLabel`, its row slot Fill + Center; the points tile's holder collapsed. **Open (owner's look):** did the centring take
(the log's `[cupend] tile holders` line says the parent chain and `panels:` which step failed)? The final top 3 only if the
owner asks for it.

## 1a-planets. The planets on the cup tiles (v0.33.0) - reverted v0.34.1
Owner 2026-11-25 (seen in game): "didn't really turn out like I wanted them to" -> `CupPlanets = false`. Code kept behind the
switch. Open, if ever wanted again: what look was wanted (smaller? a corner badge? the planet instead of the poster?).

## 1b. League styles (owner 2026-11-12: "different styles of racing"; agreed, not built)
**docs/league-styles-2026-11-12.md** - each league its own character (the car, the field, the tracks, the kit).
- [x] Junker: renamed, afterburner and ramjet +2 (v0.28.3).
- [ ] Junker = banger racing: more aggressive bots (`AI.Profiles.riffraff.aggression`).
- [ ] Ace = weather and night: the draw leans to condition variants (gp.lua `K.draw`, a per-league lean).
**2026-11-25 (owner): the car per league decided** - the plan in the doc's "2026-11-25" section. One tag per chunk:
- [x] L1. **Parts** (config only): Junker `{ [1] = 10, [3] = 10, [4] = 2 }`, Challenger `7`, Ace `10`; `AI.Strength.ace` shifted
      to `{ elite = 0, contender = -1, weak = -3 }` (no room above 10); briefs / taglines. Tests; the `[builds]` lines
      show each tier's levels. **Owner to confirm Challenger 7** (OWNER.md). **Built v0.34.0 (2026-11-25), installed;
      the owner's test is next.** Found while building: a strength lift only reaches a slot that has a tune set
      (loadout.lua L.botParts skips level-0 slots), so at Junker the Elite's +1 goes onto the afterburner and ramjet
      (10 -> 11 stacks), not onto cornering / grip as the plan said; and the game's own level 10 is 13 stacks, so
      "no room above 10" is unproven - a held race with Ace back at `{ elite = 2 }` would show whether 12 stacks count.
- [ ] L2. **Ace clean field:** `AI.Profiles.ace` aggression (VersusPlayer and VersusAI) down; check the `[gaps]` spread.
- [ ] L3. **Wreck limit per league** (= §1g item 8): `Leagues[].wrecks`, Junker 5, the others the game's 3; the mod tops
      `VehicleHealth` up and grows the HUD pips (`WBP_HUD_Crashes_C`).
- [ ] L4. **Owner playtest:** a cup at each league. Junker fun or a pinball? Ace too fast at 10? Do the Elite still lead at Ace?

## 1c. Looks (owner 2026-11-12; not started)
- **Rust for Junker** (owner: research and build all three, then look in game) - docs/custom-vehicle-models-2026-11-12.md
  "The cheap alternative":
  - [x] **Patina:** the All Rust finish (`LP_AllRust`) on your car at a Junker race load.
  - [x] **Dirt:** the car grimy from the start (`DebugDirtOverrideValue` on its customisation component).
  - [x] **Damage:** works, but off (owner: overboard on top of the rust).
  - Built v0.29.0; v0.29.1 = rust + dirt. **2026-11-13: the rust never showed** - the patina was never found (wrong
    load call, then the wrong path: it's in /GriffinSharedVehicles/), fixed in v0.29.5 and now set on every car, but
    the paint doesn't change (side-by-side screenshots): the materials component doesn't redraw from PatinaData.
    What players see is the dirt. [ ] Spike: the recipe route (the car's PatinaTag + RefreshRecipe on its
    customisation component).
- [ ] **New vehicle models** (big; inspiration photos of a junker speeder): the process in
      docs/custom-vehicle-models-2026-11-12.md. First step if wanted: a pipeline proof (one car kit cooked back with a
      trivial change).

## 1d. Race types as special rounds (owner 2026-11-13, via the Podracing session; research only)
**docs/race-types-2026-11-13.md.** Eliminator (1 event, The War Fields) and Knockout (2, The Galactic Gauntlet);
Takedown / Ramjet later.
- [x] Desk research: modes, events, settings; the `EventMode` swap lead; tools in v0.29.2 (`[elim]` order log,
      `experiment.lua eventPath` / `modeFrom`).
- [x] In-game recon (2026-11-26, docs/race-types-2026-11-13.md §2 "Recon results"): the eliminator and the knockout launch
      from the GP flow; the `[elim]` order is clean; `modeFrom` makes any track an eliminator and the points already follow it;
      the knockout's recap doesn't hang. Score by position (the knockout flags 2nd / 3rd eliminated too); skip records for mode-swapped races.
- [ ] Owner picks a shape (A-D in the doc), then build.

## 1e. Rally cup (owner 2026-11-24: "all the tracks that are point to point")
**14 point-to-point race events, 6 routes, 5 planets** (Derven Acos has none; all 14 already in config.lua as 1-lap
Sprints): Jakku The Giants' Graveyard (day); Lantaana Geothermal Tour (day, night, wet); Ando Prime Mountain to Sea
(day, night, snow) and Dai Bendu Ascension = the same road reversed (day, night, snow); Crait Rhodochrosite Run (day,
mines); Sentinel I Bool River Run (reverse day, forward overcast). The `P2P` folders' SHORT_0N events (Ahlren Jungle
Speedway, Andobi Edge, Skakoan Gambit, Mineral Loop, Corrosion Hypersphere) are 4-6 lap loops, not point to point.
- **Shape picked (owner 2026-11-24): one cup, 7 stages (one per route and direction), the night / weather variant
  drawn at random per stage.** Rally-vibe extras offered the same evening (owner to pick):
  1. **Stage times, not points:** standings by total time across the stages, gaps shown ("+4.2 s"); a DNF scores the
     slowest finisher's time + a penalty. Every racer's EventFinishTime is already read per race (race.lua v0.10).
  2. **Small field:** you + 3 (special-stage feel) through the GridMakeup entries, as title.lua cuts the title race to 2.
  3. **Tour order:** Jakku, Lantaana, Ando Prime x2, Crait, Sentinel x2; the finale always at night (Bool River Run).
  4. **Weather roulette:** the stage's variant drawn when the cup starts but only shown on the stage's start screen.
  5. **Mines finale:** Rhodochrosite Run (Mines) as a fixed stage.
  6. **Group B spec:** a fixed build for the cup, defensive / utility abilities only (no lock-on bolts).
  7. **Power stage:** a time bonus for the fastest final stage (needs 1).
- **Hidden Jakku tracks (TrackDefs with no EVT_):** `Mastiff/P2P_A/TRAK_MAS_P2P_SHORT_03` (+ `_MINES`),
  `TRAK_MAS_P2P_FWD_MINES`; `Mastiff/Loop_A/TRAK_MAS_P2P_SUNSET` is the campaign intro's (its event
  `EVT_MAS_POINTTOPOINT_SUNSET_CampaignIntro` is story-only). Only reachable through `LaunchCustomRace`.
- [x] **tools/recon/TrackTry** (2026-11-24): HOME / PAGE UP / PAGE DOWN / DELETE at the main menu launch the four
      tracks above via LaunchCustomRace (GMV_Race, car, VBD_Car_Base, TrackCondition.Sunset); logs the TrackDef's
      flags and cinematic chains, clears the chains for the launch, puts them back at the menu. **Raced by the owner
      the same evening: `TRAK_MAS_P2P_SHORT_03` = "Star Destroyer Speedway", a 5-lap short circuit (p2p=false),
      dev status "L6 - DESIGN - Stoney to look at", conditions Sunset / BlueHour. Owner: "just the short track,
      nothing special." Not a sprint; no rally material. LaunchCustomRace from our own code works.** The other three
      (sunset intro track, the two mines layouts) untried.
- [ ] (only if wanted) Star Destroyer Speedway in the Jakku pool as a 5-lap short circuit: needs a LaunchCustomRace
      route in race.lua beside LaunchQuickRace. Low value.
- [x] **v0.30.0 built (2026-11-24): the Rally Cup with extras 1-4** (owner: "go with 1 through 4") - config `Pools.rally`
      / `Cups.rally` / `Rally`, gp.lua drawRally + pickRivals, cup.lua timed, title.lua gridCut, standings timed
      tables, chain / main hide the weather. 41 test files pass (test_rally.lua). Installed; **owner to race it**:
      the 4-car grid loads, the stage times read for all four, the put-back at the menu, the tile layout (row 2 now
      Galactic + title + Kestar + Rally). Extras 5-7 (mines finale, Group B spec, power stage) not built.

## 1f. PR #1 (MilkManEX, 2026-11-24: pilot icons, alternate-vehicle presets, signature loadouts) - reviewed 2026-11-24
- **Blocker:** `mod/GalacticGrandPrix/icons/*.png` are the game's own racer portraits (14 x 256 px renders) committed to
  the public repo and packaged into the Nexus zip (package.sh): breaks the house rule (never commit / publish game
  assets). The game ships no portrait texture to point at instead (nearest: `T_UI_Flipbook_<Racer>_Holo` sprite sheets).
- The PR's own suite fails 3 of 40 files (test_abilities, test_oldpicks, test_start). test_oldpicks is a real regression:
  `picksFor` resets the saved picks to the pilot's signature kit whenever `picksRacer` differs - on an existing save that
  is every player's first launch after the upgrade. The other two are test expectations not updated (VEHICLE tile shifts
  the garage indexes; PILOT / VEHICLE captions).
- Code: paint.lua writes a preset class into `RacerDef.PreferredCustomisationForVehicleArchetype` (a plain enum -> class
  map: fine, no soft pointers) but its restore record is memory only (not save-first) and `loadPreset` passes the full
  object name to LoadAsset (core.lua v0.29.4: LoadAsset wants the package path) so a preset not already in memory won't
  load; ui.lua `importFile` holds the imported texture UObject across ticks (house rule; v0.9.2 crash) and a transient
  texture can be GC'd; the vehicle tile is ignored by the title / boss races (launchTo uses the pilot's own vehicle);
  `K.data.vehicle` / `picksRacer` not in gp.lua fill(); `P.tick` is dead code. Not seen in game by us.
- Merge: one trivial conflict (CHANGELOG); merged onto v0.30.0 it compiles, the rally tests pass, the same 3 fail.
- **Merged as v0.31.0 (2026-11-25, owner: "pull in the PR with all the fixes", portraits "point at the in game
  character art")**: the PNGs dropped; config Portraits = each racer's `MainIcon` texture in the paks (from the
  CharacterDefs via grx); the file import gone; picks kept on an old save; the preset loads by package path; the
  put-back record in the save (`paintRestore`); the title / boss races use the picked vehicle; save fields registered;
  the three tests fixed. **Owner to playtest v0.31.0 together with the rally** (OWNER.md).
- [x] v0.31.1: the preset loads by class name (the package path left cooked Blueprint classes unloaded); owner saw two schemes in game. Release zip dist/GalacticGrandPrix-v0.31.1.zip built 2026-11-25.
- [ ] Reply on the PR (owner's account): merged with changes, thanks; the icon files could not be shipped.

## 1g. FreeRace 1.1c + 1.3 follow-ups (owner 2026-11-25: "build 1 through 6, add the other things to a doc")
The read: `docs/freerace-review-2026-11-25.md` (what the mod does, what we already had, every idea with the engine names,
the 1.3 delta in §6). Built as v0.32.x, one tag a chunk; **playtested 2026-11-25 (owner: "feeling pretty great")**; v0.32.6-8 installed, to playtest (OWNER.md):
- [x] 1. Buoys off on The Galactic Gauntlet (v0.32.0, hazards.lua). **In game 2026-11-25: `no Precision buoys on this track
      (16 sweeps)`** - our Gauntlet race is the knockout's event (`EVT_WHP_LOOP_A_FWD_RACE`) with its own data layers;
      FreeRace's buoys came with `LaunchCustomRace` on the bare TrackDef. Harmless (16 sweeps in 45 s on that one track);
      could be switched off (`Hazards.Buoys = false`) or kept for TrackTry-style launches.
- [x] 2. AI ability cycling, coverage, cooldowns (v0.32.1, aiuse.lua): closes R7 once the log shows `[aiuse] fired`.
- [x] 3. Per-bot thrust dial as a TEST (v0.32.2, tune.lua, thrust.lua): **held-race protocol** - deploy `--dev`,
      experiment.lua `{ label = 'thrust', botThrustBy = { ['Sen Fira'] = 1.1, ['Lyren Shok'] = 1.0, ['Biddy Blas'] = 0.9 } }`,
      three races on The Giants' Graveyard with your car held on the line (tap W every 15 s); the `[thrust]` top-speed
      line and the `[exp] result` finish times say whether the dial moves them (~3 s a level is the parts' effect to
      beat). If it works: `AI.Thrust` per league replaces `AI.Strength`'s part stacks.
- [x] 4. Start grace (v0.32.3, ai.lua `AI.Grace`): no bot abilities and no pace lift for 15 s after the green light;
      perfect starts 75 -> 45 %. Check: the first corner calmer, the field not gone at once.
- [x] 5. Results screen caught as it is made (v0.32.4, chain.lua): no 300 ms sweeps after your finish; a fallback
      sweep every 3 s. Check: the standings panel still comes; no stutter while the field comes home.
- [x] 6. START locked with the game's tiles (v0.32.5): with the game's menu locked for an online queue, our START
      refuses with a message (`[menu] the game has locked its tiles`).

The rest, in the order recommended (details and engine names in the review doc's §3, §4, §6):
- [ ] 7. **Lap count** (§3.4): `EventRecipeSubsystem.ActiveRecipe.recipe.EventStages[1].LapCount` after launch - our
      `laps` is display-only; leagues of different lengths, rally stages forced to one lap, an endurance cup.
- [ ] 8. **Wreck limit** (§3.5): `RaceEventComponent.VehicleHealth` topped up (the game knocks out on its own count),
      HUD icons `WBP_HUD_Crashes_C` matched; closes DESIGN §7 ("no crash limit") and a per-league allowance.
- [x] 9. **Catch-up for the back of the grid** (§3.7): v0.32.6, `AI.BackRows` - the `RiffRaff*` / `Losers*` pacing rows
      renamed to the league's tier at launch, put back at the menu. Owner to playtest: do Ary and Malis stay in touch?
- [x] 10. **The game's tour-summary screen as CUP RESULT** (§6.1): v0.32.8 cupend.lua; seen in game 2026-11-25 (owner:
      "I love the layout"); v0.32.9 the tiles say the trophy / place / points / podiums, and the old result page is skipped.
- [x] 11. **Box-based navigation** (§4.2): v0.32.7, ui.lua `U.boxNav` - every layout's map from the tiles' boxes, pushed
      into the game's navigation; the grid's arithmetic links gone. No page's links changed today.
- [ ] 12. **Runtime tune sets as a general tool** (§3.6; tune.lua is the start): damage resistance, respawn shield
      (god mode 3 s after a reset), ramjet on / off, per-racer handicaps.
- [ ] 13. **RESTART in the pause menu** (§3.8): a row of RESUME's class, `ReturnToMainMenu` + our via-menu relaunch;
      a classic rally restart.
- [ ] 14. **Inter-mod flag** (§6.5): `ModRef:SetSharedVariable` so Streamline / Underground stand aside in a cup race.
- [ ] 15. Takedowns from the bots' `CrashComponent` blame lists (§6.3): a results line / a standings bonus.
- [ ] 16. **Best laps: TIME TO BEAT at the start, BEST LAP at the end** (owner 2026-11-25: "track best lap times so
      that at the start of the race you are shown a 'time to beat' and at the end of the track a 'best lap' time
      etc."; was "best-lap records ... NEW BEST LAP line on the results", §6.5). The record already exists: gp.lua
      `records[league][eventPath].lap` (filled from `PlayerRaceEventComponent.BestLapTime` in race.lua). Missing is
      the showing:
      - [x] Start: (v0.39.0, seen in game) "TIME TO BEAT 1:12.40" (your best lap here at this league; none yet = "NO LAP SET") on screen
            through the countdown, gone at the green light.
      - [x] Each lap crossed (v0.39.0, built, OFF: `TimeToBeat.LapLine`; seen working with it on) (watch `CurrentLapNumber`): that lap's time and +/- against the record, "NEW BEST LAP"
            when it beats it (the "etc." - owner to confirm they want the per-lap line, not just start and end).
      - [x] End: (v0.38.0, seen in game) the results / standings panel says BEST LAP 1:11.85 beside the race time, NEW BEST LAP when it's a
            record (the near-miss line "0.4 S OFF YOUR LAP RECORD" shares the NEW RECORD row, DESIGN v0.12).
      - [x] Spike first (2026-11-25: a plain UserWidget in the viewport works; KNOWLEDGE.md §6): we have never drawn our own text in a race. Try a plain UserWidget added to the viewport
            during the countdown (a TextBlock, game font, white with a shadow) vs writing into a HUD text the game
            already shows; no hooks, nothing kept between ticks; it must stand aside for FreeRace / Theater's HUD
            flag (`TheaterShowHidesHud`, KNOWLEDGE.md). Record the outcome in KNOWLEDGE.md.
      - [ ] Open: a record per league (as now) or per track across leagues? Also show the best race time? Off
            switch in config (`LapTimes = true`).
- [ ] 17. Auto-continue on the results after 9 s idle, a countdown in the button, off by default (§6.1).
- [ ] 18. LT / RT paging through a hidden `WBP_Tab_List_C` (§4.2).
- [ ] 19. HUD parts hidden by class, a rally HUD without position and map (§4.2).
- [ ] 20. Settings rows for our config knobs in the game's Settings screen (§4.2).
- [ ] 21. Autopilot after a reset off (`StopInputSourceOverride_OnServer(10)`) as an owner option (§6.3).
- [ ] 22. The turning 3D pilot on the PILOT tile (§4.2): flashy, risky, last.
Not for us (noted in the doc): the hand-made rubber band, opponent armour and quick respawn, the podracer features,
PNG tiles, the cockpit / mix / deadzone work (a mod of their own if ever wanted).

## 1h. Podracing cup (owner 2026-11-25: "i like your ideas, draft up some tasks") - v0.40.0 built (P1-P3, P6), pacing is the owner's
Shape agreed in §4: one PODRACING CUP tile, four races from the pod-made tracks, you in a pod, the seven pod pilots
as the field, points as usual, no title-race link. One tag per chunk; nothing touches the car cups.
- [x] **P1. Recon** (2026-11-25, docs/podracing-recon-2026-11-25.md: LaunchCustomRace on the bare pod tracks, GMV_Race's grid make-up at 8, you in your pilot's pod). A `tools/recon/PodTry` mod on TrackTry's pattern: launch one
      pod race from the main menu with archetype 1 and build `VBD_MP_PlaneTour` (fallbacks `VBD_000_1Mastiff_Plane`,
      `VBD_Plane_Base`) on Mos Espa Speedway; log the TrackDefs tagged `Vehicle.Special.Plane` (every planet; name,
      laps, p2p, conditions), the pod events under `Events/Plane_Memory` / `Plane_PresentDay` and whether
      `LaunchQuickRace(arch, event, build)` or `LaunchCustomRace(..., TRAK, ...)` is the way; at load the field
      (`GfnPlayerState` pilots, their pods from `RecipeState.Racers[].VehicleCustomisation`), who the player is
      (CharacterList.Player's pod), the finish (`EventFinishTime`, positions) and the results screen class. Expect
      a car racer as player to need `PreferredVehicleType = 1` + a pod preset (FreeRace's `lend_pods`). Write
      `docs/podracing-recon-<date>.md` and the KNOWLEDGE rows.
- [x] **P2. The pool and the cup (config).** (v0.40.0: `Pools.pods` 10 races on 5 layouts, the cup `pods` = PODRACER CUP, config `Pods`; the pod vehicle lives in `Pods.Build`, not `Vehicles`, so the garage's cycle never offers it) `Pools.pods` = the pod tracks found in P1 (title, laps, variants; Mos
      Espa reversed left out - FreeRace: it never finishes loading); `Cups` + `{ key = 'pods', name = 'PODRACING CUP',
      pods = true, pool = 'pods' }`; `Vehicles` + a pod entry `{ key = 'pod', arch = 1, build = <P1's>, name = ... }`;
      art (`art.lua`: a pod planet / the game's podracing tile textures). `K.draw` draws 4 from the pool as the rally
      does; `prog.lua` keeps it out of the planet cups and the champion count (like `rally`).
- [x] **P3. The launch.** (v0.40.0: pods.lua + race.lua preparePod / LaunchCustomRace; v1 leaves the pod build, kits, looks and paint as the game has them - the open part below) race.lua `prepare`: a `pods` cup forces the pod vehicle (the garage's pick is for cars) and the
      pod launch path from P1; `R.fits` knows `Vehicle.Special.Plane`; the part levels / abilities / mods on the pod
      build the way the car builds get them (or none: pods have Disruptor / Shockwave / mines only - AB.classPaths
      filtered to those families, `_AI` variants for the bots); the character list: the player as a pod racer
      (`racer.lua`: your pick's pod if it has one - Shade's MythP3, Kestar's Northropi - else the game's default pod
      pilot) and `Opponents` = the seven pod pilots, one pod each, cut to the grid size (title.lua's `gridCut`).
- [ ] **P4. The field and the AI.** loadout.lua: kits for the pod pilots (config `Abilities.PodRacers`, families
      bolt / shockwave / mine); ai.lua: a pod profile (pressure, pacing) - start from Challenger's, and a 10 s grace
      (FreeRace found pods rocket off the line); aiuse / thrust unchanged. Pilot strength: none at first (a different
      cast); `AI.BackRows` as the league's.
- [ ] **P5. Standings, results, the cup end.** cup.lua needs nothing (points by place); standings.lua names (pod pilots'
      `CharacterName` come through `PlayerNamePrivate` like the others - check in P1); cupend.lua: the pod planets'
      PlanetDefs (Outer Rim = Beagle) and the champion crown; the Rally-style `shown` titles if variants are hidden.
- [x] **P6. The garage.** (v0.40.0: the VEHICLE tile reads PODRACER with who you race as; the ability / tune-up tiles still show but are not applied to pods - hide them for this cup next) A POD tile when the pods cup is picked (or the pod pick inside the VEHICLE tile's cycle:
      racer.lua `RC.cycleVehicle` gains 'pod'); the pod's picture; the start screen header "PODRACING CUP - 4 races on
      the pod tracks".
- [~] **P7. Tests + docs.** (v0.40.0: test_pods; DESIGN.md §3d, README / release texts still to write) test_pods.lua (draw, launch build / archetype, the field of seven, points, cup end), the mock
      world's pod pilots and tracks; DESIGN.md §3d; README / release texts; OWNER.md playtest list (pacing above all:
      the `[gaps]` lines over a cup, then the pod profile tuned).
- [ ] **P8. Pacing pass (owner's races).** Two cups, read the gaps; tune the pod profile and grace; decide whether the
      pod pilots get a strength tier.
Open after v0.40.0: P4 (the pods' kits and an AI profile of their own; a 10 s grace), P5 (the cup result's planet names for
the pod tracks: "Outer Rim" is a guess - see the `[cupend] ... no PlanetDef for` log line), the league's parts / your abilities on the
pod or not (owner), TestAutopilot does not arm on a second pod race in a row ("your car has no Autopilot ability").
Follow-ups once this stands: the "clean" no-offence cup (§4) could reuse P3's family filter for the player's picks.

### 1h-L. PODRACING as a league of its own (owner 2026-11-26) - PL1 + PL2 built v0.41.0 (not yet seen in game); PL0 recon waits for the game
Owner after racing v0.40.0: "The podracing cup is fun ... is the pod racer the same speed and tracks for each cup? does it
make more sense to just have podracing league with one cup? also there's no ramjet or abilities, which does feel good for
learning, but would be nice to turn up the difficulty if we wanted to." Answer: today's cup IS the same at every league (the
game's pod build untouched, the same 10-race pool; only the league's AI settings differ). Agreed plan: one PODRACING poster
on HOME with one cup, the difficulty chosen on its start screen. **Pods do take abilities** (owner: the campaign gives them
at times) - so abilities are a build step, not a question; the ramjet is still unknown.

| Step | Your pod | The field |
|---|---|---|
| **Learner** (= v0.40 today) | the game's pod build, no abilities | no abilities, the game's pace, start grace |
| **Pro** | your abilities, pod-suitable families only | the pods carry and fire kits; the AI pushes harder |
| **Champion** | as Pro (+ parts / ramjet if PL0 says they work) | faster bots (thrust dial), full aggression, a shorter grace |
**Owner 2026-11-26: two steps, LEARNER and PRO** (PRO = the table's Pro + Champion: abilities both sides, the harder AI;
the thrust dial / shorter grace if PRO turns out too easy); both open from the start; the v0.40 results move to LEARNER.

- [ ] **PL0. Recon (owner away, test save, ~1 h).** On `VBD_MP_PlaneTour`: read its `AbilitySlots`, `SlotToUpgradeLevelMap`,
      `Affixes` and the pawn's components (is there a ramjet? which part slot drives pod speed?); write an ability into the
      pod build's slots (Ion Bolt / Shockwave / mine classes, then the campaign's pod abilities - find which ones the
      campaign hands pods: `Tour3/Racers/Plane` builds `VBD_PlaneTest_0x`, the memory events' builds) and race: does it show
      on the HUD and fire? Bots: does aiuse.lua's selection cycling make the pod pilots fire (their configs are in
      `DA_AIAbilityConfigCollection`)? Parts levels 0 vs 10 on the pod build in two held races: does pod pace change? Write
      the results into docs/podracing-recon-2026-11-25.md + KNOWLEDGE rows. (TestAutopilot: restart the game between pod races.)
- [x] **PL1. The league.** (v0.41.0: `Pods.League` + `Pods.Steps`, kept out of `Leagues` so the car unlock chain never sees them; each step its own league key `pods` / `podspro`; no cups page - the poster opens the start screen; the save move in gp.lua `K.movePods`) config `Leagues` + `{ key = 'pods', name = 'PODRACING', pods = true, open = true }` (its own
      poster art, tagline, rules line to the §1j rules); the `pods` cup moves out of `Cups`-for-every-league into this league
      only (the three car leagues' cups pages lose the PODRACER CUP tile); save: best / records / perfect under `pods`; old
      saves: a v0.40 pods result at a car league moves to the league (or is dropped - owner). prog.lua: no unlock gate,
      not counted toward any car league; HOME's pips for this poster = one per difficulty step.
- [x] **PL2. The difficulty step.** (v0.41.0: the STEP tile, LEARNER / PRO, saved `podStep`; per-step records by league key; AI.Profiles.pods = Challenger's, podspro = Ace's) On the pods start screen a STEP tile (Learner / Pro / Champion, cycles like the vehicle
      tile, the info line says what changes in plain words); saved per player (`podStep`); each step keeps its own trophy,
      record and perfect cup (`best.pods[cup..step]` or a step key - decide in PL1); the cup result says the step.
- [x] **PL2b. The owner's v0.41 notes (2026-11-26: "i like your suggestions, write up some tasks and do it") - built v0.42.0 (not yet seen in game):**
  - [x] **A league page, not a step tile** (owner asked about a PODRACING tab at the top; it would touch the Party box, so
        agreed instead): the HOME poster opens a PODRACING page with LEARNER and PRO as league posters (medal, crown,
        rules line), each opening the cup's start screen. B: start screen -> the pods page -> HOME; CONTINUE after the
        cup -> the pods page. The DIFFICULTY tile goes. (If a top tab is wanted later, this page moves to it as is.)
  - [x] **Fly the pod of the pilot you pick** (owner: "why don't we get to pilot the podracing vehicle for the pilot we
        choose?"): only five pilots have a pod in the game data (Shade MythP3, Goli and Fola Hexing, Sebulba Nesodon,
        Kestar Northropi); everyone else silently became Shade. On the pods start screen the PILOT tile cycles only those
        five, saved apart from your car pilot (`podRacer`), the info line names the pod. Kestar's stays locked until you
        beat him (owner). (Unproven, for the recon PL0: the six pod-only racers as your pilot.)
  - [x] **Pod words on the pods start screen** (owner: "signature kit ... doesn't apply to pod racing", the Kestar line):
        no signature-kit message, the lock line about his pod.
  - [x] **Bug: racing as Sebulba put him on the grid twice** (his `DA_PlaneRacer_Nesodon` twin stayed in the field):
        config `Pods.Twins`, the twin dropped from the field.
- [ ] **PL3. Your abilities on the pod** (PRO; v0.41.0 hid the ability / tune-up tiles on the pods start screen - they come back at PRO with this step): race.lua `preparePod` writes your picks onto the pod build the way
      `applyAbilities` does for cars (originals in `abilityRestores`), filtered to the families PL0 proves (`AB.classPaths`
      + a family filter); the start screen's ability tiles shown only at Pro / Champion (hidden at Learner - today they show
      and do nothing); tune-ups the same if PL0 shows affixes work on pods.
- [ ] **PL4. The field's kits and pace** (P4 folded in): config `Abilities.PodRacers` (a kit per pod pilot, `_AI` variants),
      loadout.lua / aiuse.lua run for pod races at Pro / Champion; an AI profile per step (`Pods.Steps[step].ai`: pressure,
      pacing, aggression, grace 10 / 10 / 5 s), Champion's thrust dial (thrust.lua) on the pod pilots.
- [ ] **PL5. Tests + docs.** test_pods: the league on HOME, the step tile, the per-step records, abilities written / put back
      per step; DESIGN.md §3d; README / release text; OWNER.md playtest (one cup per step; the `[gaps]` lines).
- [ ] **PL6. Pacing (owner's races).** Learner should be winnable while learning; Champion a fight. Tune each step's profile.

## 1i. HEAT: optional handicaps for Ace cups (owner 2026-11-25: "the heat options sound brutal and fun, write up that work") - not started
The plan: `docs/heat-2026-11-25.md` (rules, the 15 modifiers with their dials, screens, save, risks). Switch handicaps on
before an Ace cup; each is worth heat; each cup keeps the best heat you won gold at. One tag per chunk.
- [ ] **H0. Owner's calls** (OWNER.md): the name, when it opens (first Ace gold or the Ace title), the first set, and
      whether a gold at heat should be the only thing that counts.
- [ ] **H1. Rules and save** (heat.lua, config `Heat`, gp.lua fill): `run.heat`, `heatPicks`, `heatBest`; the modifiers as
      overrides merged over the league / AI profile at launch only; the `[heat]` log line; tests (merge, stacking, best on
      gold only, old save, Rally / title untouched, put back at the menu).
- [ ] **H2. First modifiers, all on today's dials:** Faster field I-III, Budget cap I-II, Bare garage, Weak kit, No mercy at
      the start, Grudge, Armed field (doc §3 rows 1-4, 6-8). Held race first: does Budget cap drop the bots with you?
- [ ] **H3. Screens:** the HEAT tile and panel on the start screen, the badge on the Ace cup tiles, `HEAT n` on the
      standings header, the CUP RESULT line / NEW HEAT BEST.
- [ ] **H4. Small builds:** Unarmed (the `noOffence` idea, §4), Podium or bust (cup.lua).
- [ ] **H5. With other work:** Wreck limit (after §1g-8), Long haul (after §1g-7), Foul weather (after the §1b lean),
      Faster field+ (after the thrust test).
- [ ] **H6. Recon:** start from the back of the grid (no grid-slot write known); Kestar Bool in a normal event's field.
- [ ] **H7. Owner playtest:** a few Ace cups climbing the heat; tune the points; watch the `[gaps]` spread at high heat.

## 1j. Plain-English pass on every line we wrote (owner 2026-11-25) - proposal written, owner reviewing
Owner: "i still don't like the phrasing on a lot of the text, it's concise, but it still sounds like it was written by
AI, i.e. 'the clock decides' and 'every rig on the same grid'.. it sort of invents terms and assumes the reader can
figure out what you're trying to say. I think you can do better." The v0.35.0 rewrite (pass 1) made it short, not
clear. This pass is about being clear.
- [x] **The rules (write them at the top of the doc, check every line against them):** (docs/plain-english-2026-11-25.md)
      - Say what happens, in the words the game uses. No coined terms ("rig", "the clock", "the field", "wound to
        ten", "proper rigs"); the game says vehicle / car, parts level, racers, abilities, tune-ups.
      - Full sentences a first-time player understands without knowing the mod. If a rule is the point, state the
        rule ("the lowest total time wins"), not a hint at it ("the clock decides").
      - No slogans, no rule-of-three rhythm, no "X, and Y" flourishes, no clipped fragments to sound punchy.
      - Numbers as numbers where they're rules ("level 7 parts", "4 tracks"), words only in flavour text.
      - Flavour lines (taglines) may have character, but must still mean something literal.
- [x] **The inventory:** (86 lines in docs/plain-english-2026-11-25.md, 2026-11-25) every player-facing string we wrote, in one table with where it is (file:line), where it
      shows, the line now and the proposed line: config.lua (league tagline / brief / rules, tune-up lines, rally
      and finale texts, messages), main.lua (cup info lines, Kestar tile, wipe / leave / offline / error prompts,
      the garage captions), standings / cupend / stakes lines (stakes.lua, near misses), title.lua. Leave the game's own
      planet and pilot bios as they are (the config `line`s copied from the game).
- [ ] **Examples, to set the bar:**
      - Rally (main.lua ~341) now: "Four stages, four racers, the clock decides. Weather and nightfall are unknown until
        you arrive." -> "4 point-to-point tracks against 3 other racers. Your times are added up across all 4, and
        the lowest total wins. You won't know the weather or time of day until each race starts."
      - Challenger rules (config ~221) now: "Every part at seven, and every rig on the grid the same. Two abilities,
        one tune-up." -> "All vehicles, yours included, have level 7 parts, so nobody has an engine advantage. You
        can take 2 abilities and 1 tune-up."
      - Riff-Raff rules now: "Afterburner and ramjet wound to ten on a scrapyard chassis. Cornering, resilience and drift
        stock, the battery barely holding." -> "Every vehicle has level 10 engine parts and stock everything else:
        fast on the straights, hard to turn, and the battery drains quickly. 1 ability, no tune-ups."
        (check the real slot levels in config before writing)
      - Ace tagline now: "Every credit on the rig. The galaxy's ..." -> say what Ace is: "The best racers in the galaxy,
        on fully upgraded vehicles."
- [ ] **Owner review before install:** page up 2026-11-25: https://claude.ai/artifact/EaNJsutAe6cWz2RPApBvNL (ticks + notes
      saved in its db collection `review`, doc per line id L01..L86; read back with ArtifactData list). The whole table as a page (old / new side by side, a box to tick or a note per
      line) so the owner signs off line by line; then one tag (strings only, tests for any width / line-count
      limits - the info lines are padded to 1-2 lines, `padInfo`).
- [ ] Add the rules to KNOWLEDGE.md / AUTOMATION.md as the house style for all the Galactic Racer mods' text.

## 1k. Boosting should feel fast: the field speeds up when you boost (owner 2026-11-26) - not started
Owner: "explore why the racers in front of you speed up so quickly when you ramjet and afterburner, this is the most
annoying part of the game, it should feel faster to boost and the field just adapts automatically without boosting."
A recon first (owner away, test save), then a fix the owner picks. Leads, from docs/ai-tuning-research-2026-11-11.md
and docs/freerace-review-2026-11-25.md:
- **The time window (the likeliest):** each bot paces against you (`URaceAIComponent.mPawnToPaceAgainst`) inside a
  window ahead of / behind you (`AIMinTimeAhead` / `AIMaxTimeAhead` curve rows per tier, moved by `DA_RaceTuneConfig`
  Modifier / Multiplier). A boost shrinks the gap, a bot drops under its minimum time ahead and speeds up to get back
  into the window. Our league profiles LIFT that minimum (`AiMinTimeAheadModifier`, held at the game's value only in
  the start grace) - we may be making it worse. Our catch-up is already off (`MaxAiCatchupScale` 1.0), but the window
  can still pull a bot ahead (or that is the catch-up path the scale doesn't reach - check).
- **Speed matching:** a zone around you (`URaceAISpeedMatchingComponent`; config `SpeedMatchingMaxMatchers`, which our
  profiles already set to 0) and a per-driving-style `EnableSpeedMatchingZone` (FreeRace turns it off through each
  `RaceAIComponent.DrivingStyle`) - is the style switch still on for our bots?
- **The bots' own boosts:** do they fire afterburner / ramjet in answer to yours (driving style `MinTimeBetweenBoosts`,
  the boost rules)? The 2026-11-12 spike found boost-rule changes did nothing to pace - but did not look at timing.
- **Measure, don't guess:** a held race (TestAutopilot), log every 0.5 s the bot directly ahead's speed and gap to you,
  and mark when you boost (your pawn's boost / ramjet state); then the same with (a) `AiMinTimeAheadModifier` at the
  game's value all race, (b) `EnableSpeedMatchingZone` off on every bot's style, (c) the window rows widened. The fix
  that makes the gap close on a boost without making the field slow everywhere else wins. Pods too (PL0's races).
- Watch-out: "the field adapts" is the game's rubber band by design; take too much out and the leaders run away
  (the v0.16 study: with all help off, the bots were as fast as or faster than the autopilot). Per league if needed.

## 2. Waiting on the owner's play (details and tick boxes in OWNER.md "Playtests")
- [ ] v0.27.x: the finish times then STANDINGS (A, or 6 s); Challenger open from the start; Riff-Raff's feel (parts
      2 on three slots); the posters' taglines and the cups page brief; the garage's TUNE-UP / ABILITY captions.
- [x] The game's own track intro (flyover) shows in our races with StreamlineCampaign off (seen in all 23 launch
      checks, 2026-11-12). Owner's call: drop the race list from the start screen header (`startHeader`, main.lua)?
- [ ] v0.27.5: the tab at game start (no auto-open; ~1 s sooner; `TabSettleS = 1.0` if the menu misbehaves).
- [ ] The parts slot-to-stat mapping: slots confirmed in game 2026-11-12 (0 Grip, 1 Acceleration, 2 Resilience,
      3 Boost, 4 Battery, 5 Advanced); which on-screen bar each drives is still a guess by name.
- [ ] Riff-Raff's brief "Stock engines" now it has parts 2 (e.g. "Hot-rodded junkers")?
- [x] The pool races never launched (23 by the log): all launched 2026-11-12, all fine (docs/data/launch-check-2026-11-12.txt).
- [x] Do the AI fire their abilities, Shields included (R7)? **Answered 2026-11-25 (v0.32.1 in game)**: with the selection cycled every 4 s each bot fired 2-4 kinds a race (Vents, Surges, Repairs, Mines, Shockwaves, Disruptors); Shields only where the game's acid / corroding rules say. Before: slot 0 only.

## 3. Known gaps (small fixes)
- [ ] **Say what the stars mean (owner 2026-11-25: "the star for each league...what does that mean? it's not obvious
      to the player").** One icon (`ART.STAR`), two meanings, neither said anywhere: on a HOME league tile the last
      pip is the league TITLE (gold = you beat Kestar Bool in the Galactic Cup's finale, `titles[league]`; faint grey =
      not yet; main.lua ~274), and on a cup tile the corner star is a PERFECT CUP (won every race; main.lua ~382).
      Claude's pick, to confirm with the owner (OWNER.md):
      - [x] (v0.37.0, worded to §1j) HOME: the focused league's info line ends with the title's state - "CHAMPION: BEAT KESTAR BOOL IN THE
            GALACTIC CUP FINALE" (grey) / "LEAGUE CHAMPION" (gold) - so the star is explained where you're looking.
      - [x] (v0.37.0) Cups page: a perfect cup's info line says "PERFECT CUP: EVERY RACE WON"; an unperfected won cup can say
            "WIN EVERY RACE FOR A STAR".
      - [x] (v0.37.0) Two icons, not one: keep the star for the league title, and a different game icon for a perfect cup (a
            laurel / crown from the game's icon set; look in `ICONS`) so the two can't be confused.
      - [ ] Optional: a one-time hint the first time a star lights ("STAR = LEAGUE CHAMPION") on the cup result screen.
- [x] **(v0.38.1: Ink = linear {0.44, 0.082, 0.045} = the pill's sRGB 177/81/60, read off the screen) Menu ink = the tab pill's orange (owner 2026-11-25: "the orange text in the menus, it should be the same
      orange shade as the top bar in the menu uses i.e. when Grand Prix is highlighted").** v0.36.4's config
      `Ink = { 0.78, 0.33, 0.06 }` is a burnt orange of our own; the selected-tab pill is terracotta, about
      `{ 0.78, 0.31, 0.23 }` by eye (KNOWLEDGE.md, menu accent row). Read the pill's real colour (its brush /
      `ColorAndOpacity` on the selected tab widget, or sample a screenshot with GRAND PRIX highlighted), set `Ink` to it
      exactly and `Ink2` to a darker shade of the same hue (two weights still). Check readability on the pale pages
      and over the droid / Steam box; note the exact value in KNOWLEDGE.md.
- [x] A DNF skipped the results panel; the last race kept the game's own CONTINUE. Both fixed in v0.28.1 (in-game
      check: OWNER.md).

## 4. Discussions (owner's call; talk before building)
- [ ] **Auto-brake, a small mod of its own (owner 2026-11-25: "when you release the gas, brake is auto applied";
      feasibility after 15:00 when their credits reset).** Where to look: the vehicle controls are Enhanced Input
      contexts (`IMC_Vehicle_Default` / `_Alternative`, throttle and brake on the trigger axes - FreeRace edited their
      deadzone modifiers at launch and rebuilt the mappings with `EnhancedInputLocalPlayerSubsystem:RequestRebuildControlMappings`);
      `AVehiclePawn` / its movement and input components in the header dump for a brake input the mod could write each
      frame while the throttle axis reads 0 (and the player isn't braking); or an input modifier object on the brake
      mapping. Questions: does writing the brake input fight the game's own input every frame (a 1 ms loop, as FreeRace's
      HUD frame)? Only your car (bots have no input). Offline only. A tiny mod, its own repo.
- [ ] **A podracing cup (owner 2026-11-25: "many tracks are probably too small and tight")**. What we know
      (KNOWLEDGE.md §3-4, docs/tracks-by-planet.md, the FreeRace read): podracer = archetype 1 ("Plane"), tag
      `Vehicle.Special.Plane`; the game has pod-made tracks only on Beagle / Outer Rim (Mos Espa Speedway + variants),
      Lantaana (Holdfast's Folly), Ando (Mawhonic Speedway) and one each on Crait, Jakku and Derven - ~6-9 tracks, so
      one cup of 4 from a pool, not a cup per planet; the car tracks are too tight (FreeRace: pods on them "wrecked on
      almost every corner", 1000 kph into walls; its author bolted on armour, quick respawns and a hand-made rubber
      band to cope - not our way). The pod field is its own cast: 7 pod pilots (`DA_PlaneRacer_*`, Sebulba's era) with
      one pod each, unique per race (8-pod grid), and Shade / Kestar can borrow pods (`PreferredVehicleType` 1 +
      `PRE_Plane_MythP3` / Northropi) - so our 14 car racers, their kits, pilot strength and the title race don't carry
      over; it is a different game inside the game. Launch: our events are campaign `EVT_*`; the pod races are
      `Events/Plane_Memory` / `Plane_PresentDay` events or bare `TRAK_*` via `LaunchCustomRace` (TrackTry proved that),
      build `VBD_MP_PlaneTour` or `VBD_000_1Mastiff_Plane` (never launched by us: a recon first). Abilities for pods:
      Disruptor, Shockwave, mines (no Vent / Surge). Pacing: unknown for pods under our AI profiles; the start surge is
      worse for pods (FreeRace gave them their own 10 s grace).
      **Shape that could work**: one PODRACING CUP tile on the cups page (any league, or a single fixed difficulty),
      pool = the pod-made tracks, 4 races, you in a pod (Shade's MythP3 by default; a pod pick in the garage later),
      the 7 pod pilots as the field, points as usual, no title race link. Needs a recon session (launch one pod
      race from our flow, read the field, the finish, the results screen) before any design is firm - half a day,
      then the cup itself is mostly config. Owner's call on whether the small cast is worth it.
- [ ] **A mode without offensive abilities (owner 2026-11-25)**: "a nice break for the constant combat of regular
      gameplay", possibly as an extension of the Rally Cup (a clean rally). Needs a lot of pacing testing. Levers we
      already have: the start grace's mechanism for the whole race (`AiAbilityChanceMultiplier` 0 on the race tune =
      the bots fire nothing; or kits of defensive / utility families only - shield, scrubber, vent, surge - via
      aiuse / loadout), and the player's offensive picks (bolt, shockwave, mine) greyed in the garage for that cup.
      Ramming is separate (`AiAggressionVPlayerChanceMultiplier`): decide whether "no combat" means no ramming too.
      Open: a cup flag (`noOffence = true`, like `rally`) or a league rule; whether the bots' pace changes without
      abilities (they lose Surges too) - the held-race method and the `[gaps]` lines tell.
- **Kestar is a weak final boss** (veers off the line, loses by ~20 s even to the autopilot; the Showdown was likely
  built around the game's catch-up). Boss keeps the game's own AI, a boss profile, or leave him? (OWNER.md) The AI
  spike above may fix it anyway.
- **The Galactic Cup format** (three random planets, then The Galactic Gauntlet): right, or something else?
- **Loadout options written up: docs/loadout-options-2026-11-12.md** (split HEAT SHIELD, weather in every cup, golds
  unlock packs, rebalance). Owner to pick.
- **Tune-ups gated by league** vs earned (trophies, golds, titles) or not gated at all; **heat / cold and the
  packs** - make picking the right pack matter more, or drop it.
- **Ideas for the future (owner, 2026-11-12):** a deeper dive into the tune-up system; a **Grand Tour** (every track
  on a planet, or all 86); a **podracing cup or league** (docs/tracks-by-planet.md "Not in the cups"); **leaning by
  league** for the random cups (Riff-Raff mostly forward layouts, conditions likely at Ace).
- [ ] **A shared best-lap leaderboard, optional (owner 2026-11-26: "racers could optionally push to for best lap
      times"; a later idea, not started).** The game mod stays offline: it never touches the network (house rule, ban
      worry; UE4SS Lua has no sockets, and calling `curl` from the game would freeze it). A small **companion script**
      (`tools/gp-board`, run while the game is closed) does the network part:
      `push` reads `save.lua` `records[league][track]` (`time`, `lap`, `at`, `vehicle`) and sends your best laps;
      `pull` downloads the shared board and writes `Mods/GalacticGrandPrix/leaderboard.txt`, which the mod reads.
      In game, `lapshow.lua` / `standings.lua` add a world best next to yours: `BEST LAP 0:48.12 · WORLD 0:47.10 (Biddy)`.
      **Where the data lives** (owner's call, OWNER.md): (1) recommended, a public GitHub repo with `leaderboard.json`,
      pulled from the raw URL with no account; pushes come in as a pre-filled GitHub issue, and an Action checks each
      one and merges it into the JSON (free, every change visible, bad entries can be deleted; pushers need a GitHub
      account); (2) a Cloudflare Worker + KV (no account needed, but someone has to own it and keep spam out);
      (3) a Google Form feeding a Sheet (almost no code, but pulling is clunky).
      **Rules:** an entry is keyed by league + track + vehicle class, with the mod version so a later rule change
      doesn't mix incompatible times; on the honour system (`save.lua` is plain text, no anti-cheat, so never call it
      "ranked"); a display name picked in the script, never a Steam ID; opt-in, so the mod works the same with no
      `leaderboard.txt`. Size: the companion script is ~100 lines, plus one line in the mod.
- **Progress badges** beside HOME (the game's insignias) in place of goal lines.
- **PHILOSOPHY.md is out of date** (rival cut, leagues): rewrite to match today? (OWNER.md)

## 5. Housekeeping
- [ ] attic/ cleanup (old study mode, the chain reset route): keep, or delete now nothing uses it.
- [x] Test mods left disabled in the Mods folder: moved to `~/.local/share/swgr-mod-attic/2026-11-13/` (2026-11-13; sources in the repos, UndergroundProto only there).

## 6. v1.0
- [ ] The owner plays every cup at every league; tune parts, AI, AI kits, points. Tag v1.0.0.
