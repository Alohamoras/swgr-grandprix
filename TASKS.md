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

## 1b. League styles (owner 2026-11-12: "different styles of racing"; agreed, not built)
**docs/league-styles-2026-11-12.md** - each league its own character (the car, the field, the tracks, the kit).
- [x] Junker: renamed, afterburner and ramjet +2 (v0.28.3).
- [ ] Junker = banger racing: more aggressive bots (`AI.Profiles.riffraff.aggression`).
- [ ] Ace = weather and night: the draw leans to condition variants (gp.lua `K.draw`, a per-league lean).

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
- [ ] In-game recon (owner away): launch from the GP flow, the elimination order, the results screen, the knockout's
      cinematic, `modeFrom` on another track.
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
- [x] 1. Buoys off on The Galactic Gauntlet (v0.32.0, hazards.lua): the Precision run's buoys hidden in our Galactic
      Cup final. Check: no blue buoys shoving you on the Gauntlet; `[hazards]` lines.
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
- [x] 10. **The game's tour-summary screen as CUP RESULT** (§6.1): v0.32.8, cupend.lua - built on FreeRace's notes,
      NOT yet seen in game. Owner to playtest at the next cup end (OWNER.md); `CupResult.Native = false` is the way back.
- [x] 11. **Box-based navigation** (§4.2): v0.32.7, ui.lua `U.boxNav` - every layout's map from the tiles' boxes, pushed
      into the game's navigation; the grid's arithmetic links gone. No page's links changed today.
- [ ] 12. **Runtime tune sets as a general tool** (§3.6; tune.lua is the start): damage resistance, respawn shield
      (god mode 3 s after a reset), ramjet on / off, per-racer handicaps.
- [ ] 13. **RESTART in the pause menu** (§3.8): a row of RESUME's class, `ReturnToMainMenu` + our via-menu relaunch;
      a classic rally restart.
- [ ] 14. **Inter-mod flag** (§6.5): `ModRef:SetSharedVariable` so Streamline / Underground stand aside in a cup race.
- [ ] 15. Takedowns from the bots' `CrashComponent` blame lists (§6.3): a results line / a standings bonus.
- [ ] 16. Best-lap records beside the race records, a NEW BEST LAP line on the results (§6.5).
- [ ] 17. Auto-continue on the results after 9 s idle, a countdown in the button, off by default (§6.1).
- [ ] 18. LT / RT paging through a hidden `WBP_Tab_List_C` (§4.2).
- [ ] 19. HUD parts hidden by class, a rally HUD without position and map (§4.2).
- [ ] 20. Settings rows for our config knobs in the game's Settings screen (§4.2).
- [ ] 21. Autopilot after a reset off (`StopInputSourceOverride_OnServer(10)`) as an owner option (§6.3).
- [ ] 22. The turning 3D pilot on the PILOT tile (§4.2): flashy, risky, last.
Not for us (noted in the doc): the hand-made rubber band, opponent armour and quick respawn, the podracer features,
PNG tiles, the cockpit / mix / deadzone work (a mod of their own if ever wanted).

## 1h. Podracing cup (owner 2026-11-25: "i like your ideas, draft up some tasks") - not started
Shape agreed in §4: one PODRACING CUP tile, four races from the pod-made tracks, you in a pod, the seven pod pilots
as the field, points as usual, no title-race link. One tag per chunk; nothing touches the car cups.
- [ ] **P1. Recon (owner away, test save, ~half a day).** A `tools/recon/PodTry` mod on TrackTry's pattern: launch one
      pod race from the main menu with archetype 1 and build `VBD_MP_PlaneTour` (fallbacks `VBD_000_1Mastiff_Plane`,
      `VBD_Plane_Base`) on Mos Espa Speedway; log the TrackDefs tagged `Vehicle.Special.Plane` (every planet; name,
      laps, p2p, conditions), the pod events under `Events/Plane_Memory` / `Plane_PresentDay` and whether
      `LaunchQuickRace(arch, event, build)` or `LaunchCustomRace(..., TRAK, ...)` is the way; at load the field
      (`GfnPlayerState` pilots, their pods from `RecipeState.Racers[].VehicleCustomisation`), who the player is
      (CharacterList.Player's pod), the finish (`EventFinishTime`, positions) and the results screen class. Expect
      a car racer as player to need `PreferredVehicleType = 1` + a pod preset (FreeRace's `lend_pods`). Write
      `docs/podracing-recon-<date>.md` and the KNOWLEDGE rows.
- [ ] **P2. The pool and the cup (config).** `Pools.pods` = the pod tracks found in P1 (title, laps, variants; Mos
      Espa reversed left out - FreeRace: it never finishes loading); `Cups` + `{ key = 'pods', name = 'PODRACING CUP',
      pods = true, pool = 'pods' }`; `Vehicles` + a pod entry `{ key = 'pod', arch = 1, build = <P1's>, name = ... }`;
      art (`art.lua`: a pod planet / the game's podracing tile textures). `K.draw` draws 4 from the pool as the rally
      does; `prog.lua` keeps it out of the planet cups and the champion count (like `rally`).
- [ ] **P3. The launch.** race.lua `prepare`: a `pods` cup forces the pod vehicle (the garage's pick is for cars) and the
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
- [ ] **P6. The garage.** A POD tile when the pods cup is picked (or the pod pick inside the VEHICLE tile's cycle:
      racer.lua `RC.cycleVehicle` gains 'pod'); the pod's picture; the start screen header "PODRACING CUP - 4 races on
      the pod tracks".
- [ ] **P7. Tests + docs.** test_pods.lua (draw, launch build / archetype, the field of seven, points, cup end), the mock
      world's pod pilots and tracks; DESIGN.md §3d; README / release texts; OWNER.md playtest list (pacing above all:
      the `[gaps]` lines over a cup, then the pod profile tuned).
- [ ] **P8. Pacing pass (owner's races).** Two cups, read the gaps; tune the pod profile and grace; decide whether the
      pod pilots get a strength tier.
Follow-ups once this stands: the "clean" no-offence cup (§4) could reuse P3's family filter for the player's picks.

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
- **Progress badges** beside HOME (the game's insignias) in place of goal lines.
- **PHILOSOPHY.md is out of date** (rival cut, leagues): rewrite to match today? (OWNER.md)

## 5. Housekeeping
- [ ] attic/ cleanup (old study mode, the chain reset route): keep, or delete now nothing uses it.
- [x] Test mods left disabled in the Mods folder: moved to `~/.local/share/swgr-mod-attic/2026-11-13/` (2026-11-13; sources in the repos, UndergroundProto only there).

## 6. v1.0
- [ ] The owner plays every cup at every league; tune parts, AI, AI kits, points. Tag v1.0.0.
