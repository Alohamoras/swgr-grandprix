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
the same field. Gold, silver or bronze at the end. Win your way from 50cc to 150cc, then reverse cups. No vehicle
upgrades to grind: the class sets everyone's speed and your skill and ability choices do the rest.

Separate from the campaign and from the Underground: its own tab on the main menu, its own save file, never the game's
save.

## 2. Pillars
- **Cups of 4 races** from the campaign's tracks, one cup per planet plus mixed cups.
- **Speed classes 50cc / 100cc / 150cc**: they set how fast every vehicle is, how sharp the AI is, and how strong
  everyone's abilities are.
- **Points over a cup**, standings between races, a trophy at the end.
- **Abilities, not upgrades**: pick one offensive, one defensive, one utility and one wildcard. **No Autopilot.**
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

- **Reverse cups**: the same cups on the reverse (or night / weather) variants, unlocked after 150cc. The game has a
  reverse version of most tracks; where one is missing, use a weather or night variant.
- **Champion Showdown**: a bonus race against Kestar Bool (`EVT_WHP_SHORTBOSS_FAIR`), unlocked with gold in every
  150cc cup.
- Later: a podracer cup.

## 4. Speed classes
The recon behind this: your parts make your vehicle much faster (5 levels on every part: a race went from 152 s to
124 s, top speed 448 → 576 kph); AI pace comes from the rubber band (`DA_RaceTuneConfig`), which follows you; the AI's
own part levels don't change its pace. So a class sets **your** part level, and the AI keeps up through the rubber
band.

| | 50cc | 100cc | 150cc |
|---|---|---|---|
| Your parts (all 6 slots) | level 3 | level 6 | level 10 |
| AI pressure (rubber band) | easy | the game's own | hard |
| AI abilities | 1 at level 1 | 2 at level 2 | full kit at level 3, used more often |
| Your ability level | 1 | 2 (pick the branch) | 3 |

Values are a starting point to tune. AI pressure and AI ability kits are the Underground's `ai.lua` and `loadout.lua`
(proven: every bot gets its own signature kit at race load, the same every race).

## 5. Abilities: your four picks
Before each cup you pick four, one per category. The level comes from the class (§4); at levels 2 and 3 you pick the
branch (e.g. Concussive Bolt or Multi-Bolt). Picks are kept for the whole cup (like choosing your kart); a setting can
allow changes between races.

| Category | Families (level 1 → level 2 / 3 branches) |
|---|---|
| **Offensive** | Ion Bolt (Concussive / Multi), Shockwave (Magnetic / Vectored) |
| **Defensive** | Shield (Impact / Surging), Concussion Mine (Double / Freezing) |
| **Utility** | Status Scrubber (Auto / Multi), Vent (Auto / Supercooled / Flame), Surge (Impact / Overtaking) |
| **Wildcard** | any family above, as long as it isn't already one of your picks |

- **Autopilot is never offered** and is removed if it shows up in a build (it's also kept off the AI).
- Mines sit under Defensive because they're dropped behind you to block chasers. Owner to confirm.
- The crash ability (Ion Blast) stays the vehicle's default. It could become a fifth pick later.
- A build has exactly 4 ability slots, so the four picks fill them. Written into the launch build the way the
  Underground does it (`race.lua` `applyAbilities`), put back at the menu.

## 6. A cup, race by race
1. **GRAND PRIX tab** on the main menu (the Underground's tab code) → class → cup → vehicle (car / bike / skimmer)
   → four abilities.
2. Race 1 launches straight away (quick race; StreamlineCampaign skips the intros).
3. Results come back: **points for all 12 racers**, then a standings screen with the cup so far.
4. Continue → the next race launches. Quit at any point gives up the cup (it can be resumed if we keep state; see
   open questions).
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

## 8. Progression and unlocks
- 50cc: every planet cup open. 100cc: gold in every 50cc cup (or a setting: any 3 golds). 150cc: the same from 100cc.
- Outer Rim and Galactic cups: gold in all five planet cups at the class.
- Reverse cups: after the 150cc cups.
- Champion Showdown: gold in every 150cc cup.
- Best trophy per cup and class saved, shown on the cup tiles. No money, no shop, no upgrades.
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

## 10. Risks and unknowns (recon list R1–R6, TASKS.md)
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

## 11. Open questions for the owner
- Mines as Defensive (§5)?
- Cup line-up (§3): happy with these, and with leaving knockouts / 1 v 1s out?
- Can you quit mid-cup and resume, or does quitting forfeit?
- Should the AI's abilities also follow the four-category rule, or keep their signature kits?
- 150cc parts at 10 (maxed) or 9, leaving room for a "200cc" later?
