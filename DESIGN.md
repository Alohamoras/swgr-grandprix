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

### Cups (draft)
Full 12-car grids only. Knockouts, eliminators and 1 v 1 races are left out of points cups (no fair points).

| Cup | Races |
|---|---|
| **Jakku Cup** | The War Fields · Giants' Graveyard · Debris Dunes · Fallen Empire |
| **Lantaana Cup** | Griffin's Flight · Moro Kehn Tunnels · The Pyroducts · Ahlren Jungle Speedway |
| **Ando Cup** | Ice Field Circuit · Monastery Mountains · Mountain to Sea · Vonium Pipeline |
| **Crait Cup** | Crimson Mines · Forgil Canyon · Rhodochrosite Run · Salt Circle |
| **Sentinel Cup** | Sentinel Lakes · Caustic Fields · Bool River Run · The Acid Ring |
| **Outer Rim Cup** | Scrap Spiral · Geothermal Tour · Dai Bendu Ascension · Crystal Caverns |
| **Galactic Cup** | Overflow Rally · Andobi Edge · Skakoan Gambit · The Galactic Gauntlet |

- **Remix cups** (v0.6.2, owner 2026-11-10; replaces "reverse cups"): only ~10 of the 28 cup races have a true reverse
  layout, so each planet cup gets a remix: reverse where it exists, else its night / wet / snow / mines / scorching
  version, else another track from the planet. Open after a trophy in all five planet cups at the top class, then at
  every open class. Line-ups in config.lua (`remix = true`).
- **Champion Showdown**: a bonus race against Kestar Bool (`EVT_WHP_SHORTBOSS_FAIR`), unlocked with gold in every
  150cc cup.
- Later: a podracer cup.

## 4. Speed classes
The recon behind this: your parts make your vehicle much faster (5 levels on every part: a race went from 152 s to
124 s, top speed 448 → 576 kph); AI pace comes from the rubber band (`DA_RaceTuneConfig`), which follows you; the AI's
own part levels don't change its pace. So a class sets **your** part level, and the AI keeps up through the rubber
band.

| | 50cc | 100cc | 150cc | 200cc |
|---|---|---|---|---|
| Your parts (all 6 slots) | 0 (no upgrades) | 3 | 7 (v0.8; was 6) | 10 (maxed) |
| AI pressure (rubber band) | the game's own (tuning later, maybe) | | | |
| Abilities (yours and the AI's) | level 1 | level 1 | level 2 | level 3 |

(v0.3.6, owner: four classes, a no-upgrades 50cc up to a maxed 200cc. The first layout was 50 / 100 / 150cc with
parts 3 / 6 / 10; saves were converted, every class moved up one.)

Values are a starting point to tune; 200cc is fully maxed. AI pressure and AI abilities use the
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

## 8. Progression and unlocks (owner asked for it, 2026-11-09)
- **50cc and 100cc are open from the start** (owner, 2026-11-10), with their five planet cups.
- **150cc and 200cc each open with a trophy (bronze or better) in all five planet cups of the class below** (100 →
  150 → 200cc)
  (proposal; the first draft said gold in every cup, which is 20 races of perfect play per class). The rule is a
  setting (`Unlock = 'trophy' | 'gold'`), so it can be made stricter.
- Outer Rim and Galactic cups: gold in all five planet cups at that class.
- Reverse cups: after the 150cc cups.
- Champion Showdown: gold in every 200cc cup.
- Best trophy per cup and class saved, shown on the cup tiles (a visible marker on the tile, owner 2026-11-10). No money, no shop, no upgrades.
- Unlocks are worked out from the saved best finishes, so trophies won before this is built count (e.g. the owner's
  50cc Jakku gold). Locked classes / cups show what opens them.
- **Kept (v0.5.0):** a class or cup you've already raced through or have a cup in progress in stays open, so v0.5
  never takes away what you were playing. `Progression.On = false` switches the locks off.
- v0.5.0 = class and bonus-cup unlocks; then reverse cups and the Champion Showdown (each needs checks in game).
- **Reset progress** (owner, 2026-11-10, v0.3.11): RESET PROGRESS, the last tile on the class screen, asks first
  (NO selected first). Clears every trophy and best finish, the cup in progress and the cups count; keeps your
  abilities, vehicle and race count. The save is copied to `save.backup-reset-<date>.lua` first. One full reset only.
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
  CUPS (per class) = every cup on one 5 x 4 page: planet / remix / conditions cups, the bonus cups, the TITLE RACE;
  the focused cup shows its races (planet, kind, laps) and your records; Select starts it. GARAGE = VEHICLE, RACER,
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
  in all five planet cups at the class; a win = the class champion (shown on the class tile). The class points
  leader as the opponent (two-car grid on a normal event) is a later step that needs an in-game check.
- **Your racer**: any of the game's 14 named pilots (CharacterList.Player swapped at launch and put back). No
  free-text names, no vehicle cosmetics.
- **AI profile per class** (ai.lua): the rubber band pressure per class (Cadet at 50cc ... Champion-ish at 200cc),
  honest pacing from 150cc (the AI no longer slows down when ahead), forced errors halved, catch-up up at 200cc.
  This is what makes "fail now, come back faster and win" real: at 150cc+ the field no longer waits for you.
- **Records**: best time and lap per track and class, perfect cups, every cup's final points, golds per class.
- **Tune-ups**: the mods trimmed to twelve named packages (two affixes each, protection / plain playstyle), slots
  0 / 1 / 2 / 2; the AI's Elite tier carries HEAT SHIELD from 150cc (+ ARMOUR at 200cc), the Challenger at 200cc.
- **Classes**: parts 0 / 3 / 7 / 10; remix cups and the title race open from 150cc; 200cc gates nothing (the
  optional summit).
- **Conditions cups**: five more (night / wet / snow / scorching / mines line-ups from the game's unused 12-car
  events, two never-raced tracks), opened by gold in the planet's cup at the class.
- Dropped for good: vehicle cosmetics, credits / shop, ghosts, a difficulty menu, free-text names.
