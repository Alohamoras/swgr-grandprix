# Galactic Grand Prix: design

Status: **draft, 2026-11-09.** A new UE4SS Lua mod for STAR WARS Galactic Racer: kart-racer-style cups with speed
classes, built from the campaign's own races. Nothing built yet. Work plan: TASKS.md.

Sources: the Underground mod (`~/Projects/swgr-underground`: DESIGN.md §10 recon, CONTEXT.md, the event lists in
TASKS.md) and the campaign research (`~/Projects/swgr-streamline/DESIGN.md`). Findings marked *(header dump)* come from
the game's native class list, not from play.

House rules (from the owner, all repos): offline only, the multiplayer guard stays; no Denuvo or DLC bypass; no
`RegisterHook`; never keep UObjects between ticks; `LoopInGameThreadWithDelay` for the tick; key binds only set flags;
memory-only changes to game data, put back after use; one git tag per chunk.

## 1. Vision
What makes it engaging, and the decisions that follow (rubber band per class, conditions folded into the cups,
a rival per class, 200cc as an optional extra): docs/PHILOSOPHY.md (owner, 2026-11-10). It wins over older sections
of this file where they disagree.

Pick a speed class and a cup, choose your vehicle and four abilities, and race four tracks in a row for points against
the same field. Gold, silver or bronze at the end. Win your way from 50cc to 200cc, then reverse cups. No vehicle
upgrades to grind: the class sets everyone's speed and your skill and ability choices do the rest.

Separate from the campaign and from the Underground: its own tab on the main menu, its own save file, never the game's
save.

## 2. Pillars
- **Cups of 4 races** from the campaign's tracks, one cup per planet plus mixed cups.
- **Speed classes 50cc / 100cc / 150cc / 200cc**: they set how fast every vehicle is, how sharp the AI is, and how strong
  everyone's abilities are.
- **Points over a cup**, standings between races, a trophy at the end.
- **Abilities, not upgrades**: pick any four, one per family (free pick, owner 2026-11-10). **No Autopilot.**
- **No crash limit**: crashing costs time, never the race.
- Quick: race → standings → next race, no paddock, no cutscenes.

## 3. The map (what the cups are made from)
The campaign builds each run's map at random from these planets' races (`CampaignMapGenRules`), so the cups are our own
picks. Planet names come from the game's `PlanetDef` (Underground log).

| Planet (codename) | Races | Main tracks |
|---|---|---|
| Jakku (Mastiff) | 14 | The War Fields, Giants' Graveyard (sprint), Debris Dunes, Fallen Empire, Scrap Spiral |
| Lantaana (Dalmatian) | 25 | Griffin's Flight, Moro Kehn Tunnels, Geothermal Tour (sprint), The Pyroducts, Ahlren Jungle Speedway, Overflow Rally, Dhunkri River Circuit |
| Ando (Corgi) | 24 | Ice Field Circuit, Monastery Mountains, Mountain to Sea, Vonium Pipeline, Dai Bendu Ascension, Andobi Edge |
| Crait (Spaniel) | 13 | Crimson Mines, Forgil Canyon, Rhodochrosite Run, Salt Circle, Crystal Caverns |
| Sentinel (Husky) | 13 | Sentinel Lakes, Caustic Fields, Bool River Run, The Acid Ring, Skakoan Gambit, Mineral Loop, Corrosion Hypersphere |
| Derven (Whippet), finals | 5 | The Galactic Gauntlet, 2 knockouts, The Qualifier (1 v 1), Champion Showdown (1 v 1 vs Kestar Bool) |
| Podracer | ~45 | separate pod events (`Plane_*`) |

Variants: forward / reverse, `_HARD`, dawn / night / wet / snow / storm, Crait's mines, eliminators.
Event paths are in the Underground config (`Planets`) and its TASKS.md lists. All proven to launch through quick race
(`FrontEndGameMode:LaunchQuickRace`), including the 1 v 1 boss events.

### Cups (v0.11, owner 2026-11-10: docs/PHILOSOPHY.md "Cups")
Full 12-car grids only. Knockouts, eliminators and 1 v 1 races are left out of points cups (no fair points).
One cup per planet, four races, always on that planet; the race list changes with the class, so the same cup gets
harder in character as well as speed. A cup never races the same base track twice ("base" = the track name without
its direction / conditions: THE WAR FIELDS, THE WAR FIELDS (REVERSE) and THE WAR FIELDS (SCORCHING) are one track).
A cup is fixed per class, so records and golds keep meaning one thing.

- **50cc** the classic forward layouts; **100cc** the reverse layouts where the planet has them, filled up with the
  planet's other plain tracks (the old Outer Rim Cup's four went here); **150cc** the conditions; **200cc** the 150cc
  lists at the extra speed.

| Cup | 50cc | 100cc | 150cc / 200cc |
|---|---|---|---|
| **Jakku** | The War Fields · Giants' Graveyard · Debris Dunes · Fallen Empire | War Fields (rev) · Giants' Graveyard · Debris Dunes (rev) · Scrap Spiral | War Fields (dawn) · Giants' Graveyard · Debris Dunes (scorching) · Fallen Empire (scorching) |
| **Lantaana** | Griffin's Flight · Moro Kehn Tunnels · The Pyroducts · Ahlren Jungle Speedway | Moro Kehn (rev) · Geothermal Tour · Dhunkri River Circuit · Griffin's Flight | Griffin's Flight (night) · Moro Kehn (rev, wet) · Geothermal Tour (night) · Dhunkri River Circuit (wet) |
| **Ando** | Ice Field Circuit · Monastery Mountains · Mountain to Sea · Vonium Pipeline | Ice Field (rev) · Monastery (rev) · Dai Bendu Ascension · Ando short circuit | Ice Field (night) · Monastery (snow) · Mountain to Sea (snow) · Vonium Pipeline (snow) |
| **Crait** | Crimson Mines · Forgil Canyon · Rhodochrosite Run · Salt Circle | Crimson Mines (rev) · Crystal Caverns · Rhodochrosite Run · Forgil Canyon | Crimson Mines (mines, night) · Forgil Canyon (mines) · Rhodochrosite Run (mines) · Crystal Caverns (mines) |
| **Sentinel** | Sentinel Lakes · Caustic Fields · Bool River Run · The Acid Ring (the game's default layouts are the reverse ones) | Sentinel Lakes (fwd, overcast) · Mineral Loop · Caustic Fields (fwd, overcast) · Corrosion Hypersphere | Caustic Fields (fwd, blue hour) · Bool River Run (fwd, overcast) · Mineral Loop (storm) · Corrosion Hypersphere (storm) |
| **Galactic** (finale) | Overflow Rally · Andobi Edge · Skakoan Gambit · The Galactic Gauntlet | same | same |

- Some planets have too few tracks to fill every class with new ones: Jakku has five tracks and only three with
  conditions (Giants' Graveyard is in all three lists), Crait has five; Sentinel's forward layouts exist only
  overcast. Twelve condition events the remix / conditions cups used are no longer raced (CHANGELOG v0.11.0).
- The cups page shows the class's conditions on each cup tile and in the focused cup's info, so the tune-up choice
  (HEAT SHIELD before a scorching cup...) is made before Select.
- Gone in v0.11: the Outer Rim Cup, the remix cups (v0.6.2) and the conditions cups (v0.8).
- **Title race** (v0.8): the Stadium Showdown against Kestar Bool (`EVT_WHP_SHORTBOSS_FAIR`), at every class.
- Later: a podracer cup.

## 4. Speed classes
The recon behind this: your parts make your vehicle much faster (5 levels on every part: a race went from 152 s to
124 s, top speed 448 → 576 kph); AI pace comes from the rubber band (`DA_RaceTuneConfig`), which follows you; the AI's
own part levels don't change its pace. So a class sets **your** part level, and the AI keeps up through the rubber
band.

| | 50cc | 100cc | 150cc | 200cc |
|---|---|---|---|---|
| Your parts (all 6 slots) | 0 (no upgrades) | 3 | 7 (v0.8; was 6) | 9 (v0.10; was 10, maxed) |
| AI profile (ai.lua, config `AI.Profiles`) | pressure -1 (Cadet) | 0 (the game's own) | 0.5, honest pacing, errors x0.5 | the 150cc one (v0.10; was 1.2, catch-up x1.15, perfect start 90) |
| Role | open | open | opens from 100cc | the optional extra: opens from 150cc, opens nothing |
| Abilities (yours and the AI's) | level 1 | level 1 | level 2 | level 3 |

(v0.3.6, owner: four classes, a no-upgrades 50cc up to a maxed 200cc. The first layout was 50 / 100 / 150cc with
parts 3 / 6 / 10; saves were converted, every class moved up one.)

Values are a starting point to tune. v0.10 (owner, docs/PHILOSOPHY.md "200cc"): 200cc is an optional extra like
Mario Kart's: nothing depends on it (no class, cup or title race opens from its results; prog.lua checked),
parts 9 instead of 10, the 150cc AI profile, no harsher conditions than 150cc. Tune it after the owner races it; cut
it if it still feels silly. (Still harsher than 150cc: ability level 3, and the AI tiers' tune-ups at 200cc -
Elite HEAT SHIELD + ARMOUR, Challenger HEAT SHIELD.)

The gap log (v0.10): after every race grandprix.log has one `[gaps]` line next to RESULT, e.g. `[gaps] THE WAR
FIELDS 150cc: you 3rd 1:42.50; winner Biddy Blas -1.50 s; next ahead Kestar Bool -0.50 s; next behind Katja Mox
+0.50 s; field spread 1st-11th 9.0 s` (each racer's `EventFinishTime`, read in the same 2 s field read as the
positions; racers without a time are skipped). The most recent race's numbers are in the save as `last.gaps`.
This is the number to put next to "did my clean race pull away?" when tuning the profiles. AI pressure and AI abilities use the
Underground's `ai.lua` and `loadout.lua` (proven: every bot gets its own abilities at race load, the same every race).
How often the AI uses them: `AiAbilityChanceMultiplier` (rubber-band tune data).

## 5. Abilities: your four picks
**Free pick (owner, 2026-11-10, v0.3.10):** any four of the seven families (Ion Bolt, Shockwave, Concussion Mine,
Shield, Status Scrubber, Vent, Surge), at most one of each. No defence or all defence is allowed. Your four are kept
in the mod's save across races, cups, classes and restarts until you change them; a cup keeps the four it started
with. The AI racers keep their category fours (below). The category rule is still there as a setting
(`Abilities.Rule = 'categories'`); what follows describes it.

Category rule (v0.3.0): before each cup you pick four, one per category. The level comes from the class (§4); at levels 2 and 3 you pick the
branch (e.g. Concussive Bolt or Multi-Bolt). Picks are kept for the whole cup (like choosing your kart); a setting can
allow changes between races.

| Category | Families (level 1 → level 2 / 3 branches) |
|---|---|
| **Offensive** | Ion Bolt (Concussive / Multi), Shockwave (Magnetic / Vectored) |
| **Defensive** | Shield (Impact / Surging) |
| **Utility** | Status Scrubber (Auto / Multi), Vent (Auto / Supercooled / Flame), Surge (Impact / Overtaking) |
| **Wildcard** | Concussion Mine (Double / Freezing), or any family above that isn't already one of your picks |

- **Autopilot is never offered** and is removed if it shows up in a build (it's also kept off the AI).
- Mines are only in the Wildcard slot (owner, 2026-11-09). Defensive is the Shield family, so its choice is the
  branch (from 100cc).
- **The AI follows the same rule** (owner, 2026-11-09: more kart-racer-like). Every named racer has a fixed set of
  four, one per category, matching their style in the game's data (e.g. Biddy Blas: Vectored Shockwave / Shield /
  Flame Vent / mines), the same every race; the class sets the level. The Underground's signature kits (DESIGN.md §3
  there) are re-sorted into the four categories. Known risk: in the Underground tests the AI never fired a Shield, so
  the AI's defensive slot may sit unused; recon R7.
- The crash ability (Ion Blast) stays the vehicle's default. It could become a fifth pick later.
- A build has exactly 4 ability slots, so the four picks fill them. Written into the launch build the way the
  Underground does it (`race.lua` `applyAbilities`), put back at the menu.

## 5b. Mods: the vehicle's affixes (owner's request, 2026-11-09; not built)
Before a cup you also pick a few **mods**: the game's affixes (perks), e.g. "Underbody Intakes I: while airborne,
Afterburner ...", "Uncapped Cooling: Ramjet temperature can decrease while active". Not cosmetics.

What we know (Underground recon, *header dump*):
- 308 affixes with in-game names and descriptions (`AFX_*`, `UAffixPassiveConfig`): common 40, rare 89, epic 68,
  legendary 54, faulty 57 (with a downside). Many come as I / II / III steps of the same effect.
- A build has 4 affix slots (maximum 10: `UnlockedAffixSlots` / `MaximumAffixSlots`).
- Your race copy of the build (`RacerBuildState.VehicleBuilds[].AffixSlots`) holds them as `FVehicleAffix`
  (`PrimaryAffix` / `SecondaryAffix` = direct `UAffixPassiveConfig*`, `Status`), the same kind of copy the AI's
  abilities are written into at race load. The launch build's own list (`Affixes`) is soft pointers: not touched.
- **Recon M1 (2026-11-10, `tools/recon/ModRecon`, log `modrecon-20261110.log`):**
  - The launch build's own list is `UVehicleBuildDef.Affixes` = **direct** `UAffixPassiveConfig*` (the soft-pointer
    list is the debug build class). Base `VBD_Car_Base`: `Affixes` empty, `UnlockedAffixSlots` 4, maximum 10. A Lua
    assignment to index Num + 1 grows the array.
  - Two affixes written there at the menu became **active passives on the car** in the race
    (`PassiveManagerComponent.PassiveList`, race copy `AffixSlots` Status 1 = Active).
  - The AI cars copy the same build and got them too. Clearing the bots' race copies (`AffixSlots[i].PrimaryAffix`) as
    soon as their copies exist at race load left them with **no passives** and kept yours (their passive lists were
    still empty at that moment). So mods can be yours only, or the AI can get its own sets (like their abilities).
  - Catalogue: `tools/recon/ModRecon/affixes.tsv` (316: 308 vehicle mods + AI / scenario / story ones) and
    `catalogue.json` / `mods-catalogue.html` (grouped: 129 effects to choose from, 6 podracer-only, 57 faulty
    effects). Campaign unlocks them in groups (`UnlockedBy` = `Unlock.Cam.Affixes.Base` / `UnlockGroup_NN`).

**Owner's rule (2026-11-10): mods change how you race, not how fast.** Every effect is tagged in
`tools/recon/ModRecon/catalogue.json` (`tag`): `power` = always-on "more of a number" (24, left out), `protect` =
protection / rule-changer (24), `style` = a bonus for driving a certain way (81; 23 flagged `strong` = big speed /
power payoffs to try in game before keeping), `podracer` (6, left out). With the power mods gone, strength by class is
an open question (top step everywhere, or step by class); the class sets the slot count.

Earlier proposal (to confirm with the owner; 50cc stays mod-free - owner, 2026-11-10):
- Slots by class: 50cc 0, 100cc 2, 150cc 3, 200cc 4. Strength by class: 100cc up to rare, 150cc up to epic, 200cc up
  to legendary (each effect at its highest step the class allows; 97 / 119 / 129 effects). One per effect. Faulty
  ones left out (or a later "risky" option).
- A MODS screen next to ABILITIES: affixes grouped by what they affect (Afterburner, Ramjet, Cornering, Abilities,
  Resilience...), each with its in-game description; I / II / III steps shown as one entry at the class's best step.
- Kept for the whole cup, like the abilities. The AI: none at first (their four abilities are their thing); maybe a
  matching set per racer later.


1. **GRAND PRIX tab** on the main menu (the Underground's tab code) → class → cup → vehicle (car / bike / skimmer)
   → four abilities.
   v0.17 (TASKS.md 11): the game starts on this tab - at the first main menu after launch it opens by itself on
   HOME, once per launch (through the menu key's path; never via MULTIPLAYER; after the boot-drop of an old cup and
   the put-backs; not with a study pending). B on HOME = the game's main menu; nothing reopens it after that.
   `BootToGrandPrix = false` turns it off.
2. Race 1 launches straight away (quick race; StreamlineCampaign skips the intros).
3. Results come back: **points for all 12 racers**, then a standings screen with the cup so far.
4. Continue → the next race launches. Quitting gives up the cup (owner: start with whatever is easier to code; a
   forfeit is). v0.2-v0.8 kept the cup in the save to resume later; v0.9 took that out for good (owner: like Mario
   Kart, leaving a Grand Prix loses it - §13).
5. After race 4: the final standings, the trophy (1st gold, 2nd silver, 3rd bronze), and unlocks.

**Points:** 15, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1. Ties on points: the better finish in the last race wins.

**Same field:** the standings follow the named racers (Kestar Bool, Shade, Katja Mox…). The game picks the 11
opponents for most events itself (only the 1 v 1 events have `CustomOpponents`), so the field may change between
races. Recon question R2; fallback: racers missing from a race score 0 for it, and the standings show everyone seen.

## 7. No crash limit
The game ends your race after too many crashes (wrecked). Two memory-only controls *(header dump)*:
- `DA_RaceTuneConfig` → `TotalCrashAllowance` (the race's crash allowance; we already change this asset for AI pace);
- `UseHealth` on the launch vehicle build (`FVehicleBuildState` / `VehicleBuildDef`; `ShouldUseHealth()`,
  `ShouldNextCrashWreckVehicle()` on the player's race component).
Recon R3 picks the one that works; set before launch, put back at the menu. Crashing still costs time.

## 8. Progression and unlocks (owner asked for it, 2026-11-09; v0.11)
- **50cc and 100cc are open from the start** (owner, 2026-11-10), with their five planet cups.
- **150cc and 200cc each open with a trophy (bronze or better) in all five planet cups of the class below** (100 →
  150 → 200cc). The rule is a setting (`Progression.Unlock = 'trophy' | 'gold'`), so it can be made stricter.
- **The Galactic Cup** (the finale, `final = true`) opens at a class with a trophy (any colour; gold with
  `Unlock = 'gold'`) in all five planet cups at that class.
- **The title race** opens at a class with a trophy in the Galactic Cup at that class. Winning it makes you the class
  champion.
- 200cc is the optional extra: nothing outside 200cc opens from its results.
- Best trophy per cup and class saved, shown on the cup tiles. No money, no shop, no upgrades. The class tile counts
  golds / trophies over the six cups (5 planets + Galactic).
- Unlocks are worked out from the saved best finishes every time (nothing extra saved), so trophies won before
  this was built count. Locked classes / cups / the title race show what opens them. The cup result says what it
  unlocked ("UNLOCKED: 150cc - GALACTIC CUP at 100cc", "UNLOCKED: TITLE RACE at 100cc").
- **Kept (v0.5.0):** a class or cup you've already raced through (or the title race once tried) stays open.
  `Progression.On = false` switches the locks off.
- **v0.11 save change:** the results of the removed cups (remix, conditions, Outer Rim) are dropped at the first
  load, logged once; track records stay (per event path).
- **Reset progress** (owner, 2026-11-10, v0.3.11): RESET PROGRESS on HOME asks first (NO selected first). Clears
  every trophy and best finish, records, perfect cups, standings and the cups count; keeps your garage and race
  count. The save is copied to `save.backup-reset-<date>.lua` first.
- Save: `Mods/GalacticGrandPrix/save.lua` (the Underground's save code), never the game's save.

## 9. What we reuse from the Underground
| Underground module | Use here |
|---|---|
| `core.lua` (helpers, `C.gameLoop`, refs, save writing) | as is |
| `tab.lua`, `ui.lua` (main-menu tab, tiles, focus, back) | the GRAND PRIX tab and its screens |
| `race.lua` (launch, results, menu return, put-back, multiplayer guard) | launch each race, read results |
| `ai.lua` (rubber band pressure) | per class |
| `loadout.lua` (AI signature kits) | per class |
| `abilities.lua` / `applyAbilities` | the four picks into the launch build |
| test harness (`test/`, mock world) | the same style of tests |
Copied, not shared: the Underground is on hold and the two can change separately.

## 10. Risks and unknowns (recon list R1–R7, TASKS.md)

**Recon results (GPRecon dump, 2026-11-09):** all 28 cup races are `Vehicle.Standard` (any car / bike / skimmer),
mode `TeamRaceConfig` (12-car grid, `RaceGridMakeup`), no `CustomOpponents`. Laps: sprints 1, circuits 2-3, short
circuits 4-8. First race in game (v0.1): The War Fields, 2 laps, about 2 min 20 s at 50cc.

- **R1 Every racer's finishing position** at the end of a race (points for all 12). Underground reads yours
  (`EventPosition`); its recon read every racer's build in a race, so likely possible.
- **R2 Same field across a cup**: can we choose the 11 opponents? Touching `CustomOpponents[].Driver` (a soft
  pointer) from Lua crashed UE4SS, so only safe methods.
- **R3 Crash limit off** (§7).
- **R4 Speed classes**: lap times per class and per vehicle type (car / bike / skimmer) at parts 3 / 6 / 10, to
  check the classes feel different and the types are fair.
- **R5 Vehicle types per event**: most campaign races take any car, bike or skimmer (`Vehicle.Standard`); check each
  cup race.
- **R6 Race length**: laps and times, so a cup is about 15–20 minutes.

- **R7 AI and Shields**: does the AI ever fire a Shield when it's one of four? (Underground: never, as a third pick.)

## 11. Open questions for the owner
- Cup line-up (§3): happy with these, and with leaving knockouts / 1 v 1s out?

## 12. Decisions
| Date | Decision |
|---|---|
| 2026-11-09 | New design, new repo (owner). Crash limit off. Four picks: offensive, defensive, utility, wildcard; no Autopilot. |
| 2026-11-09 | Recon trimmed: parts 3 / 6 / 10 for every vehicle type (no speed test); the field and the AI's Shields are checked in playtests; crash limit settled later. |
| 2026-11-09 | Four classes (owner): 50cc parts 0, 100cc 3, 150cc 6, 200cc 10; abilities 1 / 1 / 2 / 3. Saves converted (v2): trophies move up one class. |
| 2026-11-09 | Order: mods (v0.4), progression (v0.5), polish (v0.6); AI difficulty and the crash limit moved to the end as "maybe". |
| 2026-11-09 | New task: pick the vehicle's mods (affixes) before a cup, like the abilities (§5b). Difficulty so far: "difficult but fun". |
| 2026-11-09 | Abilities built before the AI difficulty (v0.3); AI difficulty per class becomes v0.4. |
| 2026-11-10 | Abilities: free pick, any four, one per family (owner). The AI keeps its category fours. Points 15-12-10-...-1 kept ("works well"). 50cc and 100cc open from the start. |
| 2026-11-09 | Mines only as the Wildcard. The AI follows the four-category rule too. 150cc fully maxed. Quitting a cup forfeits it (easiest to build). |
| 2026-11-10 | v0.9 (owner): cups are not resumable - like Mario Kart, leaving a Grand Prix loses it. No CONTINUE / QUIT CUP, no LATER, no IN PROGRESS; B on the standings asks; a run in the save at boot is dropped. |

## 13. v0.8 (2026-11-10): the research round
Built from docs/research-2026-11-10.md (the owner's 13 questions; the Claude Doc has the reasoning). Not yet seen in
game. Summary of what changed in the design:
- **Menu, two levels** (owner's rules: never more than two deep, no words you don't need, no scrolling, simple).
  HOME = the four classes, GARAGE, RESET PROGRESS (always these six; v0.9 took the CONTINUE / QUIT CUP tiles off).
  CUPS (per class) = every cup on one page: v0.11 the five planet cups, the GALACTIC CUP and the TITLE RACE (7 tiles,
  4 + 3; was 5 x 4 with the remix / conditions / bonus cups); the focused cup shows its races at that class (planet,
  kind, laps, conditions) and your records; Select starts it. GARAGE = RACER (v0.15: no VEHICLE, the racer decides it),
  ABILITY 1-4, TUNE-UP 1-2, each cycled in place with Select. No cup page, no pick screens, no BACK / EXIT / DONE
  tiles (B goes back).
- **Cups are not resumable (v0.9, owner, 2026-11-10): like Mario Kart, leaving a Grand Prix loses it.** A cup
  exists only from its first race's launch to the standings screen of its last race. The standings after races 1-3
  offer NEXT RACE only; B there asks "Leave the cup? Your points are lost." (YES first: forfeit and HOME; NO: the
  standings). After race 4: CONTINUE / B to the cups. Quitting a race from the game's pause menu is a DNF and the
  cup goes on. A cup found in the save at boot (restart or crash mid-cup) is dropped and logged (`[cup] ... dropped
  at boot ...: cups cannot be resumed`); so is one still alive when HOME is shown. No IN PROGRESS tile, no LATER, no
  lock on the garage while a cup runs. The run stays in the save between the races of a cup (race.lua / racer.lua
  read it across a race load) and keeps the vehicle, picks and tune-ups it started with.
- **The Galactic League frame**: classes = divisions with one intro line each; a season = the five planet cups; the
  **title race** = the Stadium Showdown against Kestar Bool at every class (he copies your build), open with a trophy
  in the Galactic Cup at the class (v0.11; was all five planet cups); a win = the class champion (shown on the class tile). The class points
  leader as the opponent (two-car grid on a normal event) is a later step that needs an in-game check.
- **Your racer**: any of the game's 14 named pilots (CharacterList.Player swapped at launch and put back); v0.15:
  in their own vehicle type (below). No
  free-text names, no vehicle cosmetics.
- **AI profile per class** (ai.lua): the rubber band pressure per class (Cadet at 50cc ... Champion-ish at 200cc),
  honest pacing from 150cc (the AI no longer slows down when ahead), forced errors halved, catch-up up at 200cc.
  This is what makes "fail now, come back faster and win" real: at 150cc+ the field no longer waits for you.
- **Records**: best time and lap per track and class, perfect cups, every cup's final points, golds per class.
- **Tune-ups**: the mods trimmed to twelve named packages (two affixes each, protection / plain playstyle), slots
  0 / 1 / 2 / 2; the AI's Elite tier carries HEAT SHIELD from 150cc (+ ARMOUR at 200cc), the Challenger at 200cc.
- **Classes**: parts 0 / 3 / 7 / 10 (v0.10: 200cc at 9, see §4); 200cc gates nothing (the optional summit).
- **Conditions cups** (v0.8; folded into the planet cups' 150cc lists in v0.11, §3): five more cups of night / wet /
  snow / scorching / mines line-ups, opened by gold in the planet's cup at the class. The remix cups went the same way.
- Dropped for good: vehicle cosmetics, credits / shop, ghosts, a difficulty menu, free-text names.
- **v0.12 (2026-11-11): stakes and near misses on the standings** (docs/PHILOSOPHY.md points 2, 4, 6). After races
  1-3 one stakes line from the points left ("3 POINTS BEHIND BIDDY BLAS, 1 RACE LEFT", "LEADING BY 9 OVER SEN FIRA:
  6TH OR BETTER WINS THE CUP", "GOLD IS OUT OF REACH, SILVER IS NOT"), never claiming what the points can't back (ties
  as the standings rank them: the latest race). Near misses only when close (config `Near`): "0.4 S OFF YOUR RECORD"
  (1 s), "1 POINT FROM GOLD" (3 points). They share the NEW RECORD line, so the screen is no taller than before.
  The unlock pacing (test_pacing): from a fresh save there is always a locked tile one step away that says what opens
  it, and no cup opens more than two things.
- **v0.13 (2026-11-11): a rival per class** (docs/PHILOSOPHY.md point 3; rival.lua, config `Rival`). The rule: after
  every cup race at a class, each racer within 6 points of you in that cup's standings scores 6 minus the gap (2 more
  if ranked just ahead of you), the first to 30 becomes your rival at the class, and another racer takes over only
  when their tally beats the rival's by 10, more than one race can give. You and Kestar Bool are never scored (he
  never races cups); Shade is scored like anyone (he is on the grid when you race as someone else). Saved per class
  (`rivals[class] = { name, scores }`, optional; RESET PROGRESS clears it). The standings name the rival with the gap
  in this cup ("RIVAL: SEN FIRA, AHEAD BY 3" / "RIVAL: SEN FIRA, 5 BEHIND YOU" / "..., LEVEL ON POINTS"): on its own
  line while the screen is under its height (races 1-3: 4 lines, the cup result: 5), else at the end of your "You:"
  line; a stakes line already naming the rival says "YOUR RIVAL" instead ("8 POINTS BEHIND YOUR RIVAL SEN FIRA, 1
  RACE LEFT"), so the rival is never named twice. HOME's class info: "Champion: BIDDY BLAS.  Rival: SEN FIRA"
  ("Champion and rival: X" when the same). **The title-race opponent is still Kestar Bool** (the Stadium Showdown)
  until the two-car grid spike (TASKS.md B6) shows the rival can be put on a normal event's grid.
- **v0.14 (2026-11-11): every tile's text fits** (owner: the tune-up tiles couldn't be read). A tile is a short name
  (the title, at most two lines), a short badge (one line) and at most a short second line under the name (the
  game shows it on the focused tile); everything longer is in the focused tile's info line: the tune-up's effect,
  the ability's blurb, the racer's bio, the class blurb, the garage's full setup, what opens a lock in full, the
  cup's races. The budgets per tile size (ui.lua `U.FIT`, measured on the v0.8 screenshots: title 12 a line, badge
  15, second line 19 with capitals wider, three lines in all) are checked by test_tiletext for every string every
  screen can show. Still estimates until the screenshot pass (TASKS.md B8).
- **v0.15 (2026-11-11): the racer decides the vehicle** (TASKS.md A6, owner-decided). Each racer has their own
  vehicle type (config `Racers[].vehicle`, the same as the game's `URacerDef.PreferredVehicleType`, read in game
  2026-11-11): 4 speeder bikes (Malis Vazosk, Katja Mox, Sen Fira, Biddy Blas), 5 landspeeders (Shade, Ary Quill, Nik
  Skandaro, Soren Zaks, Kestar Bool), 5 skim speeders (Griff Halloran, Goli & 02-R0, Fola Kanjen, Lyren Shok,
  Sebulba). The launch build is that type's (`Vehicles`), with the class parts on it and put back after, as before;
  Shade drives the base landspeeder (owner: no bike / skimmer choice). The VEHICLE tile left the garage: the RACER
  tile's second line names the vehicle type, its info line reads "<racer> - <type>: <bio>", and HOME's GARAGE tile
  shows racer and type. **Kestar Bool is locked until you win the 150cc title race** (`titles['150'].won`): Select
  skips him and the RACER info says "Kestar Bool is locked. To unlock: win the 150cc title."; a save that has him
  picked while locked races as Shade (logged). Old saves: the `vehicle` pick is dropped (logged once), the racer
  stays. At launch the picked racer's `PreferredVehicleType` byte is compared with config once per session (a
  mismatch is logged; config wins). **TODO (B7): the racer's own look** (their livery preset,
  docs/racer-vehicles-2026-11-11.md) is not put on yet: it is unproven in game, so you race the plain build of the
  racer's type until B7 settles it.

## 14. Study mode (v0.16, test-only; TASKS.md B10)
For the AI tuning study: batches of single races driven by the test-only TestAutopilot, one AI setting changed at a
time. Off unless `study.lua` sits in the mod folder (next to save.lua); without it the only cost is an `io.open` at
boot and every 5 s at the menu. The file returns a list of jobs
`{ class = '150', cup = 'ando', race = 1, label = '150 p0.5 catch0.8', ai = { pressure = 0.5, pacing = {...},
catchup = 0.8, errors = 0.5, perfectStart = 90, aggression = {...}, ops = {...}, config = {...} } }`; `ai` replaces
`AI.Profiles[class]` for that race only (ai.lua takes the profile through `R.launch(..., { ai = prof })`; the
global `AI.Adjust` still adds to its pressure). At the main menu (no race, no cup, nothing to put back, no result
screen waiting) and 5 s after it settled, the next job's race (the cup's race list at the class, index `race`)
launches through `R.launch` like the title race: the class's parts, your racer and vehicle, abilities, tune-ups. No
cup run, no points, no trophies; the race count and track records are written as usual (a test save). Our page, if
open, is closed first. Progress is `study_state.lua` (`next`, plus `started` / `tries` while a race runs: a race
interrupted by a restart runs again, twice at most). Results: a `[study] job i/N 'label' EVENT CLASS: you 1st 2:31.37,
P2 +11.17 s (name), P3 +13.0, P6 +20.2, P12 +44.1, AI spread 33.0 s` line (gaps of those finishing places, by time,
to you; not 1st: P1 first, negative) and a row in `study_results.csv` (`job,label,class,event,your_pos,your_time,
gap_p1,gap_p2,gap_p3,gap_p6,gap_p12,ai_spread,settings`; seconds; settings = the profile as compact text). A job that
can't be launched (unknown class / cup / race, a failed launch, a race that never loads) is logged and skipped. After
the last: `[study] all N jobs done`, then nothing. Delete study_state.lua to run a study again. Code: studymode.lua.

## 15. Cups without the main menu (v0.19, TASKS.md "Next" 2; v0.19.1 built, not yet seen in game)
**v0.19.1: NEXT RACE goes via the main menu.** v0.19.0's reset route hung the game in its first in-game cup
(2026-11-11 17:35, Jakku 150cc): Mastiff/Loop_A -> Mastiff/P2P_A by `RequestResetRace` stayed on the black PLEASE
WAIT screen for good (`field: 1 racers`, Escape dead, game killed). `RequestResetRace` re-uses the loaded track world:
only a race in the same layout folder can load that way (B9 proved Loop_A FWD -> Loop_A SHORT_02), and only 8 of the
cups' 48 race-to-race steps are like that. So:
- **Default, every cup (the Galactic Cup too): via the menu.** NEXT RACE on the panel (button or N) sets `CH.via`
  (plain values: cup, class, race number, title) and leaves the results the game's own way (`CH.leave`: the results
  screen's CONTINUE click, else `RacingGameMode:RequestReturnToMenus()`). At the main menu (race.lua hands back the
  result recorded on the results screen, as for CONTINUE), main.lua's `viaMenu` sees `CH.via`: the cover goes up
  (`[cover] on`) instead of the standings page; when the menu has settled - the study mode's rules: `R.menuUp()`, no
  race of ours, `R.pendingRestore()` false, for `ChainRaces.MenuSettleS` (5 s) in a row - the cup's next race launches
  through `R.launch(K.nextRace(), cupArgs(run))`, the very call NEXT RACE on the standings page makes. The cover comes
  off once that race's world is there. The request is checked first (the cup still at that race; else dropped). A
  failed launch, or no settled menu in 30 s: the cover off, today's standings page (logged with why). Everything the
  menu flow does happens unchanged (put-backs at the menu after every race, the set-up at every launch), so points,
  records, put-backs and the save are the menu flow's (test_chain B compares them line for line).
- **The reset route, on request only**: `ChainRaces.Reset = true` (default false) AND the next race in the same
  layout folder (`CH.layout`: the planet's folder and the one after it, `Mastiff/Loop_A`, compared without case).
  Proven for Loop_A -> Loop_A only. Its **watchdog**: `WatchdogS` (20 s) after the reset at least one AI racer must
  have been read and the race started (one lookup of the race state, once, if not seen yet) - else `[chain]
  watchdog: ...`, `RequestReturnToMenus` and the next race via the menu. Every other failure after NEXT RACE (no new
  world in `LoadTimeoutS`, the menu coming instead, a failed set-up / recipe write / reset call, a world running
  another event) also continues via the menu (`CH.fallback(r, why, via = true)`).
- `CrossPlanet` is gone: the menu route doesn't care, and one layout folder is always one planet.
- **Panel**: opaque (alpha 1, plus an opaque backing border; v0.19.0's 0.92 let the game's table show through) and the
  game's own table `WBP_Simple_RaceResultsPanel_C` (the mode rules' ResultsTableWidget, B9 log) hidden while it is up
  (`SetVisibility(Hidden)`, one sweep, once; `Panel.HideGameTable = false` leaves it). NEXT RACE left of CONTINUE,
  side by side: both slots centred (alignment X 0.5), CONTINUE's width read (desired size / width override / slot
  size, at least 420), a slot of that x 1.2 each, `Panel.ButtonGap` (80) between; positions logged.
- **CONTINUE** unchanged: the main menu and today's standings page (B there leaves the cup).
The rest of this section is v0.19.0's design; where it says NEXT RACE resets the race, read "with Reset = true and
the same layout only".

Owner 2026-11-11: the standings at the end of the race, then straight into the next race with no main menu. Proven
pieces (RaceFlowSpike B9, `tools/recon/RaceFlowSpike/raceflow-b9-20261111.log`): a panel on the game's results screen
`WBP_SimpleRaceResultsScreen_C` (canvas `Default_Results`, CONTINUE's parent), and the next race from the race world
by writing the next event into the active stage of the race recipe (`AuthoredEvent`, `TrackDef`, `LapCount`,
`trackConditions`) on both `EventRecipeSubsystem.ActiveRecipe` and the race state's `EventRecipe`, then
`BP_RacingGameMode_C:RequestResetRace()` (a new race world in 0.5 s). Code: chain.lua; race.lua `prepare`,
`R.chainLaunch`, `recordRace`; standings.lua; ui.lua `U.panel`. Config `ChainRaces`.

**When.** After a cup race that is not the cup's last, when you finished it (a DNF or a quit keeps today's flow), and
the next race is on the same planet (or `CrossPlanet = true`). Otherwise nothing at all happens in the race world:
the main menu records the race and shows the standings page, as before. The last race of a cup always goes to the
main menu and the cup result there.

**Same planet.** The codename folder right after `/Planets/` in the two event paths (`.../Planets/Mastiff/Loop_A/...`
-> `Mastiff`), compared without case (the paths mix `Husky/LOOP_A` and `Husky/P2P`). Every planet cup stays on its
planet at every class (test_config checks it), so planet cups chain all four races; the Galactic Cup changes planet
every race (Dalmatian -> Corgi -> Husky -> Whippet), so with `CrossPlanet = false` (the default: a planet change is
not proven) it keeps the main-menu flow. Note: the spike proved Loop_A -> Loop_A on Jakku (The War Fields -> Fallen
Empire); a change of layout folder on one planet (`Loop_A` -> `P2P_A`) is treated as the same planet and is the
first thing to watch in game.

**On the results screen.** Once you have finished, the results screen is looked for every 0.3 s (one sweep each, up
to `ResultsWaitS`). When it is up: the race is recorded right then, by the same code the main menu uses
(`recordRace` -> `K.record`: points, records, rival tally, near misses, gap log, RESULT / PERF lines; the main menu
later hands this result back instead of recording a second time), and the panel goes on: the standings page's own
text (standings.lua: cup / race line, your line, stakes, NEW RECORD / near miss, the table with THIS RACE / POINTS /
MOVED) on a dark box over the game's own table (centred, `Panel.Y` from the top, at least `Panel.MinWidth` x
`MinHeight`), and one prompt line: `NEXT RACE: race 3 of 4, FALLEN EMPIRE.  CONTINUE: the main menu (to leave the
cup).` Beside CONTINUE a **NEXT RACE** button made from CONTINUE's own class (FreeRace's RETRY does the same), made
toggleable and focused, so pad A / Enter / a click on it flips its selected state; we poll it every 0.2 s (one lookup
by path + address each time, only while the panel is up). The keyboard key `ChainRaces.Key` (N) does the same (the
bind only sets a flag).

**NEXT RACE.** `R.chainLaunch` runs `prepare`, the same set-up `R.launch` does at the menu: the class's parts,
abilities and tune-ups on the launch build (their originals went into the save at the cup's first launch and stay
there, so nothing is lost), the AI profile on DA_AIConfig / RP_Default / RP_Honest (the same values: logged "as is"
plus the `[aiset]` read-back), a fresh rubber-band state (the finished race's tune objects get their values back
first), your racer into the character list again (settled 10 s into the race as usual), the AI loadout for the load.
Then the recipe write (both copies, every field read back) and `RequestResetRace`; the loading watch takes the first
race state it hasn't seen (name + address) as the new world and checks its recipe names the event we wrote.

**CONTINUE / B.** B is not read in the race world (no reliable way without hooks). The game's CONTINUE is left as it
is: it goes to the main menu, where today's standings page shows (the result recorded on the results screen, not a
second time), with NEXT RACE and B -> "Leave the cup? Your points are lost." So leaving the cup from the results
screen is CONTINUE, then B. The same happens if the game moves on to the menu by itself (~7 s after the results,
seen in an early recon): the panel and NEXT RACE are up within ~0.3 s of the screen, and if the player is slower the
menu flow simply takes over.

**Fallbacks** (every one logged with `[chain]`; never stuck):
- no results screen within `ResultsWaitS`, or the panel can't be added: the race is (or is then) recorded at the
  main menu as before / CONTINUE shows the standings at the menu;
- NEXT RACE but the set-up, the recipe write or its read-back, or the reset call fails: `CH.fallback` presses the
  results screen's CONTINUE for the player (its bound click event), else `RacingGameMode:RequestReturnToMenus()`;
- no new race world `LoadTimeoutS` after the reset, the main menu coming instead, or a new world running another
  event: the same fallback; at the main menu the last recorded race's standings page shows (the cup at the next
  race; NEXT RACE there launches it from the menu);
- the results going to the menu before NEXT RACE: today's standings page.
Put-backs (build, abilities, tune-ups, AI config and pacing assets, racer, the subsystem recipe's stage) happen once,
at the main menu, when the chain ends (cup over, CONTINUE, a fallback); the recipe's originals are memory only (a
game restart undoes them too). A crash mid-chain is the same as a crash mid-race today: the save's originals are put
back at the next menu, and the cup is dropped at boot (cups cannot be resumed).

**Log lines.** `[chain] race N of 4 finished: next X (same planet) - looking for the results screen`, `[chain] not
chaining: <why>`, `[chain] panel added: on Default_Results (...)` / `panel NOT added: <why>`, `[chain] NEXT RACE
pressed (<how>)`, `[chain] next race written: EVT (track, laps, conditions) ... read back ok`, `[chain] reset called:
...RequestResetRace() for race N of 4, TITLE`, `[chain] new race world <name> <t> s after the reset: <event>`,
`[chain] fallback: <why> - ...`, `[chain] main menu after the fallback: ...`, `[chain] the results went to the main
menu before NEXT RACE: the standings there`, `[chain] recipe put back (main menu): ...`.

## 16. The visible rival and the menu polish (v0.20, TASKS.md "Next" 3 (rival part) and 4; built, not yet seen in game)
From docs/menu-review-2026-11-11.md. The title race is unchanged (Kestar Bool's Showdown) until the owner decides.
- **A rival from the first race** (review 2a; rival.lua `RV.nearest`, config `Rival.FirstRace`, default true): after
  a cup race at a class with no rival yet, the racer who finished nearest you in that race - the one just ahead (the
  excluded, Kestar Bool, skipped), else the one just behind - becomes your rival there at once (`[rival] 100cc: X is
  your rival (finished nearest you in race 1 of jakku)`). From then on §13's tally rule decides changes, unchanged
  (a rival picked this way starts with only one race of tally, so a racer already far ahead in an old save's tally
  can take over at once by the Margin rule). An old save's rival is kept. `FirstRace = false` = v0.13's rule only.
- **The rival's row is marked** on every standings table - the standings page, the panel over the game's results
  screen (both from standings.lua `SD.spec`) and the cup result's top 3: the row in light blue (`SD.RIVAL_COLOR`) and
  "RIVAL" after the name ("Sen Fira   RIVAL"). The call-out / "YOUR RIVAL" stakes lines stay as in v0.13.
- **HOME** (review 2c, 4, 6, 7): one "Next:" line under the title naming the nearest goal (prog.lua `P.nextGoal`:
  the fewest trophies still needed for something locked, from the existing unlock rules - "Next: a trophy in the
  Sentinel Cup at 100cc opens the GALACTIC CUP and 150cc"; ties go to the class last raced; with nothing left to
  unlock, the nearest gold or an unwon title race). The League line and the race / cup counts are gone. Every class
  tile shows the same measure: "N / 6 TROPHIES" on the badge (none before a trophy), "Gold N / 6" under the title
  (shown on the focused tile). "Champion: <bot>" is gone from HOME (it never said what a champion is); your own title
  stays ("Champion: YOU"), and the info line names the rival ("Rival: SEN FIRA"). The focus opens on the class you
  last raced (`K.data.last.class`, else the last picked; a fresh open only - going back keeps the tile you were on).
- **The cup result** (review 1; `SD.cupSpec`, ui.lua `spec.hero` / `spec.after`): a screen of its own - the medal
  (the trophy icon used on the cup tiles, `T_UI_Grit_Medals_*`) drawn large (190 px), tinted bronze / silver / gold
  through the image's brush tint; beside it the trophy (or "5TH PLACE") big, the cup / class / points / NEW BEST, and
  "PERFECT CUP" as a badge line; then the final top 3 (your row under them when lower); then the last race in one line
  (place, time, record / near misses, the cup's near miss "1 POINT FROM GOLD"), the rival call-out, and ONE what's-next
  line: "UNLOCKED: ..." when the cup opened something, else "Next: <the nearest unlock at the class>" (prog.lua
  `P.nextUnlock`; nothing when the class has nothing left to open - the near miss is on the race line). CONTINUE (and B)
  land the cups page's focus on the next open cup at the class without a gold, after the one just raced (wrapping; with
  every other cup golden, the title race), and the tile names it ("Next: CRAIT CUP").
- **A dark strip behind tile labels** (review 3; ui.lua `U.stripBehind`, config `TileLabelStrip`): the tile's badge
  (`Txt_Label_Supplemental`) and description (`RT_Description`, header dump `WBP_FE_TileCommon_Btn.hpp`) each put
  inside a Border (black, alpha 0.6) in their own place in their parent panel (the children from there on taken off and
  put back with their slot settings - no InsertChildAt from Lua); the badge also gets a text shadow. A collapsed text
  leaves an empty zero-size border. Logged once per screen: `[tiles] label strip: badge in <panel class>, description
  in <panel class>` (or `not done (<why>)`).
- **The game's footer** (review 5; tab.lua `T.findFooter`, config `HideFooter`): the main menu's `WBP_ActionBar_C`
  (the prompts "Select / C Restart Campaign / Settings"; the FreeRace mod hides the same widget on its tab) is found
  breadth first from the menu's root (user widgets' own trees too, at most 1500 widgets / 12 deep) when our tab is
  entered, collapsed, and put back to its old visibility when another tab is picked (found again; only the
  visibility number is kept). `[footer] found ... at depth N ... hidden while the GRAND PRIX tab is up` / `[footer] put
  back (visibility N)` / `[footer] not found (N widgets looked at); the menu's root holds: ...`. Hiding the prompts
  does not unbind the game's C key: what C does on our page is still to be checked.
- **Small ones** (review 6, 7): the cups page says only the class blurb and "Parts level N, abilities level N" (no
  vehicle, no how-to); no best lap on a sprint (the standings' "You:" line, NEW BEST LAP, the cups page's records);
  the cup tiles' medal icons tinted by medal through the brush tint (the image colour set in v0.7 didn't hold in game).
  Review 8: your line on the standings ends with the seconds to the car just ahead, or to the one behind when you won
  (`SD.margin` from the race's `K.gaps`; nothing without finish times). Review 9 (per-ability art) not done.
