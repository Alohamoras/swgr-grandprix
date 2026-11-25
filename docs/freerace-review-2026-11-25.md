# FreeRace 1.1c and 1.3, read for the Grand Prix (2026-11-25)

Nexus mod 80 (FreeRace) read in full from the copy in `~/Downloads` (`FreeRace 80 1.1c 2026-11-08T05-55Z ...zip`,
downloaded 2026-11-08), then **1.3** (`FreeRace 80 1.3 2026-11-14T19-08Z ...zip`, the owner downloaded it 2026-11-25;
see §6 for what changed). No licence in the zip: ideas only, our own code (AUTOMATION.md).

Second read: the first (2026-11-10/11, `docs/ai-tuning-research-2026-11-11.md`, `docs/research-2026-11-10.md`) took the
rubber-band presets, `LaunchCustomRace`, the CONTINUE click, the pilot swap, `Server_UpdateVehicleRecipe`, the `Mod_`
tab id and the font lesson. This read is the whole mod, feature by feature, against the Grand Prix as it stands at
v0.31.1.

## 1. What it is

A main-menu tab ("Free Race") that launches a single custom race with every rule exposed: vehicle class, planet, track
(every track of every class on the planet, conditions random), laps, racers 2-12, race mode, tier build, pilot (you race
as any racer, podracers included), difficulty (4 levels), catch-up (off / AI / players / both), damage resistance
(x1-x4 / god), your abilities (up to 4 of 11), ramjet (on / off / infinite for you), speed cap, wreck limit, track
weather on / off. Plus quality-of-life bits that run in every mode: cockpit camera, controller deadzones, a HUD tab in
Settings (hide any HUD part), an effects-volume mix, a steady ramjet camera, two screen effects off, RETRY on the
results screen and RESTART in the pause menu.

Size: 35 Lua files, 11,489 lines; 2 Windows Python tools (`PodNames.pyw`, `RaceName.pyw`: tkinter editors for two
text files); 71 PNG tiles (planet x class track art, option icons, and 24 pilot portraits rendered from the game's
`T_UI_PlayerChar_*` / `T_UI_RivalChar_*` textures - the same art we chose to reference in game rather than ship).

Architecture worth noting (`main.lua`, `fr_sched.lua`): one 50 ms game-thread loop runs a list of named jobs, each
with its own period and a `race = true` flag; a guard (`fr_guard.lua`) decides each tick whether race jobs may run
(the race world is the first one after a FreeRace launch within 3 minutes AND `KismetSystemLibrary:IsStandalone(gs)`;
anything else drops every pending change and puts game data back). Each job's errors are counted and logged by name
(first 5, then every 100th) without stopping the others. Every job is timed with `os.clock`; every 5 s, if the mod took
more than 5 % of real time, a `slow:` line names the costliest jobs. Race-time state is one table (`S.run`) with one
entry per feature, armed at launch and cleared at the menu (`AT_MENU` list) or when a race is not theirs
(`NOT_OURS` list).

## 2. Already in the Grand Prix (nothing to take)

- Rubber-band presets (`AiMax/MinTimeAhead*`, aggression, ability chance) per difficulty, applied to every
  `GameTuneComponent.RaceTuneData.Config` while loading until 3 s after the start: ours is `ai.lua` (interpolated).
- `DA_AIConfig` pacing / perfect start / forced errors written at launch, put back at the menu, originals in the save.
- `LaunchCustomRace` (TrackTry), the CONTINUE event on `WBP_SimpleRaceResultsScreen_C` (chain.lua), the `Mod_` tab,
  tiles from `WBP_FE_TileCommon_Btn`, the loading-screen cover between races (`ui.lua U.cover`).
- `CharacterList.Player` swap and `GridMakeup.Entries[].NumEntrants` cut (title races, the rally's 4-car grid).
- Vehicle paint through the racer's preset map (ours, v0.31); FreeRace instead sends the multiplayer CUSTOMIZE recipe
  to `PlayerVehicleCustomisationComponent` by `Server_UpdateVehicleRecipe`.
- Bots' ability kits written into each bot's race copy at load (loadout.lua) - and FreeRace confirms the reason this
  must happen before the spawn: **the AI never fire an ability the mod spawns itself**; only game-made instances fire.
- An offline guard (`PartyManager`, matchmaking, `IsStandalone` in race.lua).

## 3. Worth taking, ranked

### 3.1 AI ability selection cycling (small, answers R7)
`fr_abilities.lua` `cycle_ai_abilities`: **the AI only fires its *selected* ability** (`AbilityComponent.SelectedAbilityIx`),
so a bot with four abilities uses one. FreeRace moves every bot's `SelectedAbilityIx` to the next ability every 4 s
from 2 s after the start, and counts uses (an ability going from state Ready 8 to Active 16 or WarmingUp 2 = a use;
one log line per 30 s). Two more conditions for a bot to fire an ability at all:
- an `AIAbilityConfig` in `RaceAIComponentConfig.AbilityConfigCollection.AbilityConfigs[]` must list the ability's
  class in `AbilityClasses` (FreeRace adds uncovered classes to the config of the same family, e.g. `Shockwave_Punch`
  to Shockwave's, and puts the arrays back at the menu);
- the ability's `AbilityConfig.WarmupTime` is the recharge (FreeRace: 7.5 s for the AI, 15 s for you; `EnergyCost 0`).

For us: our kits give each bot four abilities and the owner's open question R7 is whether they fire Shields and the
rest. Likely answer: they fire only slot 0's. Adding the 4 s cycle (and logging uses) is ~60 lines in loadout.lua.
Check coverage of the `_AI` mine variants and Shield in the collection first (one log line, as FreeRace prints).

### 3.2 Start grace (small, a felt fix)
`fr_difficulty.lua` `start_grace`: for the first 15 s after `bIsRaceStarted`, every pacing struct's `MaxAiCatchupScale`
is held at 0, the difficulty's lift of `AiMinTimeAheadModifier` is paused (back to the game's value) and
`AiAbilityChanceMultiplier` is 0; then all of it returns. Reason (their comment): "the pacing curves want every AI
racer at least level with you from the green light, so catch-up launches them all away." Plus
`DA_AIConfig.DefaultPercentageChancePerfectStart` 75 -> 15 % at launch (ours already has `perfectStart` per profile,
unset in the shipped profiles).

### 3.3 Precision buoys on The Galactic Gauntlet (small, a real bug in our final)
`fr_track.lua` `apply_buoys`: `PrecisionRunBuoy` actors (the floating blue markers of the Precision runs) sit in the
route layer of The Galactic Gauntlet and **load in every race there**, shoving / crashing a car that passes close at
speed. Our Galactic Cup final is `EVT_WHP_LOOP_A_FWD_RACE` on that track. Fix as they do: `SetActorHiddenInGame(true)`,
`SetActorEnableCollision(false)`, `SetActorTickEnabled(false)` on each (never destroy: the rewind tracks them); search
every 3 s until 15 s after the start, catch late ones with `NotifyOnNewObject('/Script/Griffin.PrecisionRunBuoy')`
(keep only paths, never the object), and re-hide once a second (the game shows them again after a rewind).

### 3.4 Lap count (small, a new dial)
`fr_launch.lua` `set_laps`: after launch, `EventRecipeSubsystem.ActiveRecipe.recipe.EventStages[1].LapCount = n`
(looked for every tick for up to 30 s). Our `race(path, title, kind, laps)` carries `laps` for display only. With this
the leagues could differ in length (Junker 2 laps, Ace 4), the rally's sprint stages could be forced to 1 lap, and an
"endurance" cup becomes possible without new events.

### 3.5 Wreck limit (small, closes DESIGN §7 without the recon)
`fr_wrecks.lua`: `RaceEventComponent.StartingVehicleHealth` / `VehicleHealth` on your player state. Lesson: "the game
knocks you out on its own count (3), whatever StartingVehicleHealth says", so the limit is counted by the mod: each
wreck the game takes off is put back until only the game's own allowance is left for the final ones; 'No limit' always
tops it up. The HUD icons (`WBP_HUD_Crashes_C.CounterContainer`, one `WBP_CrashCounter` per wreck; `DisplayHealth`,
`SetLitness(lit, animate)`, `Img_CrashPip` tint) are grown / trimmed to the limit. Gives us "no crash limit" (§7) and
a per-league wreck allowance (Junker 5, Ace 3) with the HUD matching.

### 3.6 Runtime tune sets (medium, an enabler)
`fr_tune.lua`: a `TuneSet` object made at runtime - `StaticConstructObject(TNS_Condition_Shield:GetClass(), outer)`,
`Operations[i] = { Category = FName('VehicleHealthConfig'), Property = FName('MaxImpactWorld'), Operation = 7
(FloatMultiply), FloatParam = x, ... }` - applied to one racer's `TuneComponent` through `RequestApplyTuneSet` /
`Server_ApplyTuneSet` / `ApplyTuneSet` (found by reflection, parameters filled by type). Re-applied when
`SetsApplied` no longer lists it (the race clears tune sets at the start). Used for damage resistance (x2-x4, god
mode: thresholds +1000), ramjet on / off (`VehicleBoostConfig.CanRamjet`, BoolSetTrue 1 / BoolSetFalse 2), infinite
ramjet (`VehicleRamjetConfig.ActiveHeatingRate` Vector2DMultiply 19 x0.05, `PassiveHeatingRate` x10,
`OverheatedSpeedScaleVsCoolingRate` FloatCurveAllMultiply 34 x10) and corrosion x3 (`VehicleConditionConfig
.CorrodingActivationTimes` / `CorrodingExplosionTimes`). For us this is per-racer tuning with nothing written to game
assets and nothing to put back: pilot strength (v0.28 edits part stacks on each copy), Junker fragility, a title-race
handicap, or a "shielded start" without the affix.

### 3.7 Catch-up for the back of the grid (small, from the pacing rows)
`catch_rows`: the `PacingConfigs[i].AIMaxTimeAhead / AIMinTimeAhead` rows named `RiffRaff*` / `Losers*` are set to
trail you, so AI catch-up never reaches them; FreeRace renames those `RowName`s to `Challengers*` (or `Elite*` on its
two hardest levels) so every opponent stays in the race. Noted in our 2026-11-11 research, never built. Also
`BP_RacingGameMode_C` CDO `CatchupEnabled` (0 None, 3 Both) with its two curves `CatchupStartDistanceVsPowerLevel` /
`CatchupFullDistanceVsPowerLevel` and `TNS_Catchup_1Percent` amounts: player catch-up in single player, if ever wanted
(we decided against rubber-banding the player; keep as a known lever).

### 3.8 RESTART in the pause menu (medium)
`retry.lua`: a row made from RESUME's class (`WBP_Pause_Btn_*`), put into every `FilterListMap` list that holds RESUME
right after it, text colour mirrored from RESUME per focus state (a fresh row came out near-invisible), read every
frame (`IsPressed` / `GetSelected`; a menu closing right after the press counts too). Pressing it calls the game's own
`ReturnToMainMenu` (found by `FindObject('Function', nil, 'ReturnToMainMenu', true)`, called on the live object of its
outer class or a library's `Default__`), holds the loading-screen cover over the trip and relaunches from the menu.
Their lessons: the hidden "[Dev] Reset Vehicle" row is NOT reusable (it runs the vehicle reset on every press and
closed the menu before a 50 ms poll saw it); `AddChild` puts a row last and `ShiftChild` did nothing, so the rows
after RESUME are removed and re-added. For us: "RESTART STAGE" in the rally (classic rally allows one restart), or a
plain restart for any cup race, through our existing via-menu relaunch (chain.lua `CH.via`).

### 3.9 Track weather off / hazard list (small, optional)
`fr_track.lua` `apply_weather`: `ConditionVolume` (tag `ConditionTagToApply`: Chilled, Heated, Corrosion...) and
`SolarConditionActor` switched off (trigger box collision 0, tick off, tag `None`), keeping dust / caustic / lava by
tag; the vehicle's live conditions read from `VehicleConditionComponent.ConditionObjectsList[].ActivationLevel` and
`EnvironmentalInstigators`. A "fair weather" league rule, or just the readout for the rally's hidden-weather stages
("your conditions: Chilled 0.62 (track: ConditionVolume)").

### 3.10 Speed cap (medium, probably not for us)
`fr_speed.lua`: no limiter function found by reflection on cars, so it clamps `GetPhysicsLinearVelocity` on the root
each tick, exempt while boosting (afterburner `TimeActive` / ramjet `RamjetState` 2-5 rising), easing back over 3 s,
and rescales `CVF_SpeedScaleToCoolingRate_Ramjet` so the ramjet still cools under the cap. Our leagues set pace by
power level, which the bots follow; a cap is a different feel (everyone bunched). Keep as a known lever only.

### 3.11 Diagnostics worth copying (small)
- The catch-up readout: every 5 s one line with every racer in race order (`P1 Sen L2 310kph +120m CU B`), distance
  from you from `K2_GetActorLocation`, `CU` when a `*Catchup*` tune set is in `TuneComponent.SetsApplied`, `B` when
  boosting. A richer `[gaps]` for tuning the leagues.
- The reset watch: a jump of more than 30 m in 100 ms that speed cannot explain = a reset, logged with height, speed,
  the nearest race spline (`RaceSplineComponent:FindLocationClosestToWorldLocation`, its `OutOfBoundsDistance`) and
  the reset volumes around (`CliffResetVolume`, `ResetVolume`, `NoResetVolume`, `KillZVolume`). Their dated notes
  (2026-11-07): airborne or landing sideways counts as "facing backwards" for the wrong-way reset; `OutOfBoundsDistance`
  x2 changed nothing (those splines are the warning zone); mid-air resets on Bool River Run came from an overhead
  `ResetVolume` 122 m up (they switch off volumes whose floor is 15 m+ above the track) and from
  `RaceSplineMetadata.DefaultHeight` (x20).
- `Vehicle.AllowResetProtection 0` (console variable via `KismetSystemLibrary:ExecuteConsoleCommand`) turns off the
  flashing yellow protection after a reset. Cosmetic.
- The per-job timer and the `slow:` line (`fr_sched.lua`): our `[perf]` line measures tick gaps; theirs names the job.

### 3.12 Not for us
- Pilot swap for podracers, pod names, `PvpPlaneInstantActionPlayable`, pods lent to Shade / Kestar
  (`PreferredVehicleType = 1`): podracers are outside the Grand Prix.
- Your name in the standings (`GameMode:ChangeName(ctl, name, true)`, else `PlayerNamePrivate`): we already read names
  from the player states; renaming bots remains untried.
- Clearing the picked pilot's custom look (`CharacterRecipe.Head/Outfit/ColourScheme/Voice/VoiceMod` RowName None).
- The warm-up (preflight) checklist trimming: only needed because their launch build carries the AI pool.
- The start-slot swap on Rhodochrosite Run (podracer grids).
- Shipping PNG tiles and the Windows `.pyw` editors.

## 4. UI and quality-of-life modules

(fr_ui, fr_nav, fr_page, fr_menu, fr_hud, fr_hudmenu, fr_mix, fr_mixmenu, fr_deadzone, cockpit, fr_ramcam, fr_screenfx,
fr_holo, fr_live, fr_base; read module by module, the full notes are in the session transcript)

### 4.1 Same as ours already
- Tab on `WBP_FE_MainMenu_C`: `RegisterTab(FName('Mod_FreeRace'), firstTabButtonClass, SizeBox stub, count)`, the
  panel inserted after `WS_ScreenContent` with its slot copied, the switcher collapsed while the tab shows (tab.lua).
- Clicks by toggle polling (`SetIsSelectable / SetIsToggleable / SetShouldSelectUponReceivingFocus(false)`, then
  `GetSelected()` and `SetIsSelected(false, false)`), Enter as a 250 ms fallback; gamepad B through a hidden
  `CommonActivatableWidget` with `bIsBackHandler` whose deactivation is the press (ours: tab.lua, chain.lua).
- Fonts sampled from a live TextBlock per menu instance (their crash note matches ours in KNOWLEDGE.md).
- The loading-screen cover (`WBP_LoadingScreen_C` in the viewport).

### 4.2 Worth taking
- **Box navigation** (`fr_nav.lua` `reach` / `N.wire`): every focusable gets `{ x, y, w, h }` in layout units; for each
  direction the nearest entry that lies that way wins (score = 1000 if it does not overlap across the travel axis,
  + 10 x the across gap + the along gap + 0.01 x the centre-line offset), and the result is pushed into UMG with
  `SetNavigationRuleExplicit(dir, widget)` (left 0, right 1, up 2, down 3) so the game's own stick / d-pad follow the
  same graph. We hand-wire `nav` tables per screen (and the tests check indexes); a tile added or moved costs nothing
  with this. Small, and it removes a class of bugs.
- **LT / RT paging**: the game hands the triggers only to a tab list inside an activated screen, so FreeRace spawns a
  hidden copy of `WBP_Tab_List_C` (`NextTabEnhancedInputAction = IA_UI_Tab_RightSecondary`, `Previous... =
  IA_UI_Tab_LeftSecondary`, dummy tabs, `SetListeningForInput(true)`, wrapped in a constructed
  `CommonActivatableWidget` that is activated while the page is up) and reads `GetSelectedTabId()` each tick. Our
  cups / garage / standings pages are arrow-only on the pad; triggers would page them. Medium (their lessons: rebind
  250 / 1000 / 3000 ms after the page is up; old lists from earlier builds still hear the press - clear them).
- **Tile art cropping at the brush** (`fit_art`): `Img_TileArt:SetBrushFromTexture(tex)`, then edit `img.Brush`:
  `UVRegion.Min/Max` + `bIsValid = true` (centre crop with a focus point), `ImageSize`, `DrawAs = 4` (rounded box) with
  `OutlineSettings.CornerRadii`; `B_ImageTint` (the stock retainer with `MI_UI_Squircle_TextureMask`) collapsed, since
  it tiles art that is not the stock size. Our pilot faces on the tiles could use the crop; the stock mask can stay.
- **HUD parts hidden by class** (`fr_hud.lua`): one list of ~50 `WBP_Hud_*_C` classes by part (position, lap, lap
  times, map, abilities, reticles, afterburner, ramjet, energy, speed, taunt heads, status, player tags, threats,
  messages, goals, prompts, countdown). Hide = `SetVisibility(2)` + `SetRenderOpacity(0)`; three animated warnings
  (`WBP_Hud_Vulnerable_C`, `WBP_EnvironmentalDisturbance_C`, `WBP_CriticalMalfunction_C`) are `RemoveFromParent()`ed
  because their animation re-shows them; new HUD widgets caught with `NotifyOnNewObject('/Script/UMG.UserWidget')` and
  handled on the next frame so they never draw. For the rally: hide the position widget and the map (stage times
  only), or a "clean HUD" league rule. Small to medium.
- **Game-native settings rows** (`fr_hudmenu.lua`, `fr_mixmenu.lua`, `fr_deadzone.lua`): `WBP_Setting_Btn_C` spawned
  with a constructed `/Script/Griffin.GfnCosmeticSettingDescriptor` (`DisplayName`, `Description`, `SetDescriptor`),
  the value from the inside of a `WBP_Toggle_Btn_C` (`Txt_Toggle`, `Img_ToggleHandle`) or `WBP_Slider_Btn_C`
  (`PB_Amount`, `Txt_Percent`) placed into the row's `NS_SettingType`; left / right through two invisible focusable
  `UMG.Button`s wired with `SetNavigationRuleExplicit`; the description panel through `OnFocusedSettingUpdated(desc)`.
  A whole tab = `RegisterTab(FName('Mod_HUD'), ...)` on the Settings screen's tab list, then showing the Gameplay page
  with its own rows collapsed. Our config.lua knobs (ChainRaces.On, Rally.HideWeather, AI.Adjust...) could become
  Settings rows the owner flips in game. Medium.
- **Live 3D pilot** (`fr_live.lua`, prototype): the game's `CharacterTurntableActor` spawned deferred far above the
  menu (`CharacterRecipe = racer.DefaultRecipe`, `bAutoSpawnOnBeginPlay`), a `SceneCapture2D` with
  `PrimitiveRenderMode = 2` and `ShowOnlyActorComponents` into a `CreateRenderTarget2D(owner, w, h, 2, clear, false,
  false)` (UE5 wants the 7th parameter), a point light, the render target set as the tile's brush
  (`SetBrushResourceObject`). The turning pilot on our PILOT tile. Flashy, medium, risky (actors in the menu world).
- **Search discipline** (`fr_base.lua`): `FindAllOf` only at menus or on a schedule; one `StaticFindObject` per tick,
  round-robin ("~10 ms a call here"; ten every 3 s froze a frame ~120 ms); `B.live(o)` = `IsValid()` plus
  `HasAnyFlags(0x8000 + 0x10000)` (RF_BeginDestroyed | RF_FinishDestroyed); the race world told from a stale one by
  comparing `GameEngine.GameViewport.World` with `gs:GetOuter():GetOuter()` by address ("after a race the old world's
  game state can stay about ... well into the menus"). The flags check is cheap and we do not do it.

### 4.3 Against our house rules, or not for us
- FreeRace **holds UObjects between ticks** (its whole cache) and uses **RegisterHook** (`BP_Vertical_Btn:BP_OnHovered`
  for row hover; post-hooks on `BP_VehicleState_C:ReceiveTick` and its malfunction timeline for the screen effects).
  Both are banned here (AUTOMATION.md) after our own crashes; their notes show the cost of the other way (10 ms per
  path lookup) and the risks of theirs ("holding the player across a level load crashed the game", GetParent on a
  dying widget crashed, 2026-11-06).
- PNG tiles from disk (`KismetRenderingLibrary:ImportFileAsTexture2D(pc, path)`; "imported textures live only while a
  brush holds them"): we reference in-game textures instead.
- Cockpit camera (socket moves on the vehicle's static mesh asset, `pc:FOV`), steady ramjet camera (the `CMD_*RamjetIdle*`
  camera data assets copied from their `ParentData`), effects-volume mix (`AudioModulationStatics:SetGlobalBusMixValue`
  on `CB_PlayerVehicles` / `CB_AIVehicles`...), controller deadzones (`InputModifierDeadZone` on `IMC_Vehicle_Default`
  mappings), concussed / damage-flash overlays off (`BP_VehicleState_C.PostProcess` blendable weights): all good
  quality-of-life, all outside a cups mod. If the owner wants any of them they belong in a mod of their own.

## 5. Suggested order

1. Buoys off on The Galactic Gauntlet (3.3) - a fix to our final; one evening.
2. AI ability cycling + coverage log (3.1) - closes R7 and makes the kits matter; one evening, then an owner race.
3. Start grace + perfect start 15 % (3.2) - a felt fix at the green light; with 2, one playtest covers both.
4. Lap count (3.4) and wreck limit (3.5) - two new league dials; a chunk each.
5. Box navigation (4.2) - a refactor of main.lua's nav tables with the tests updated; worth it before more screens.
6. Runtime tune sets (3.6) - when the next per-racer tuning need comes (pilot strength v2, a title-race handicap).
7. RESTART in the pause menu (3.8), LT / RT paging, HUD parts, Settings rows, the live pilot - polish, owner's pick.

## 6. Version 1.3 (2026-11-14): what changed since 1.1c

A diff of the two zips (line endings ignored): 7 new modules (`fr_mines`, `fr_probe`, `fr_pull`, `fr_records`, `fr_rowfix`,
`fr_static`, `fr_summary`), 18 changed, 15,058 lines now (was 11,489). Nearly every change is tagged with a user request
dated 2026-11-09 to 2026-11-14, so 1.3 is a week of one player's wishes, podracer-heavy. What matters for us:

### 6.1 TOUR mode and the game's own end-of-tour screen (`fr_summary.lua`, `retry.lua`, main.lua) - the big one
Six races on six random planets, 3 laps, the last on Tatooine or the Derven Acos sprint, chained through the menu like
RETRY (our chain.lua flow). New on the results screen: a MAIN MENU button beside RETRY / CONTINUE, all three shown
together with CONTINUE's own fade (`sync_buttons`), and with TOUR on the results **press CONTINUE by themselves after
9 s without input, counting down in CONTINUE's label** (`tour_auto`; any of ~40 keys / pad inputs resets it).
At the tour's end **the game's PvP tour summary** (`/Game/Griffin/UI/Screens/PostRace/WBP_PostRace_InstantAction_RunEnd`,
class `WBP_PostRace_InstantAction_RunEnd_C`) is created over the results (`WidgetBlueprintLibrary:Create`,
`AddToViewport(10000)`) and filled with view models made by `StaticConstructObject('/Script/Griffin.<VM>', w)`:
- `RunFinishedVM` (`RunSuccessful`, `NumEventFinishes`, `NumTop3EventFinishes`, `NumDNFs`, `RacesWon`, `HighestWinStreak`,
  `TourPlanets[]`) set as `w.RunStatsVM`;
- one `PlanetStatVM` per planet (`Planet`, `NumTimesVisited`, `bIsFirstVisitedPlanet`, `bIsLastVisitedPlanet`,
  `TimelineEntries[]`) with a `RunTimelineEntryVM` per race (`FinishPosition`, `NumberOfWrecks`, `Activity` 2 standard /
  6 champion = the crown);
- `PvpXPResultsVM` (`StartRank`, `CurrentRank`, `NextRank`, `CurrentXP`, thresholds, `TotalXPEarned`, `XPAwards[] = { XP,
  Tag, Reason }`) as `w.XPVM`;
then the panels' own functions: `w:RefreshPlanets()`, `WBP_Timeline:TriggerTimelineAnimation()`, `WBP_MP_Wins:UpdateWins(n)`,
`WBP_MP_Participation:UpdateParticipation(finished, streak)`, `WBP_MP_Progress:BeginProgressAnimationFromXPAwards()`;
the per-race widgets (`WBP_RunRecap_Event_C`, found by class, matched by their `'Timeline Event VM'`) get the place box
shown for every race (`SzB_SecondaryInfo`, `WS_SecondaryInfo` index 0, `Txt_Position`) and the skull box
(`VS_Switcher` 0, `Txt_MPInfo_Position_1`) showing takedowns.
Lessons they logged: the screen is never activated (activation builds the PvP view models and binds Continue to the
PvP flow); `RefreshPlanets` adds to the timeline's own list, so `TourPlanetsToShow` must start empty or every planet
shows twice; the progress panel adds each award to `TotalXPEarned` itself (set to the total it showed double); the
gamepad cannot reach a non-activated screen, so the results' own CONTINUE is left focused under it (render opacity 0)
for A to press; its geometry never came back, so the Continue hint is centred from the viewport size; `AddToViewport(60)`
at the menu drew under the menu's tiles; `RaceEventViewModel.NumberOfTakedowns` read 0 in every race, takedowns are
counted from the bots' crash components instead (below).
**For us:** the Galactic Grand Prix's CUP RESULT could be the game's own tour-summary screen: the cup's races as the
timeline (planet art, place per race, wrecks), wins / top-3 / DNF tiles, and the XP panel repurposed as the points table
or left out. Native look for free. Medium-large; their lessons cut the recon by days. The 9 s auto-continue is a small,
nice thing for our NEXT RACE prompt (optional, off by default).

### 6.2 AI ability rules (`fr_abilities.lua`, +440 lines)
- The AI pool gained the **Shield** and **Magnetic Concussion Shockwave** (`BP_Ability_Shockwave_MagneticConcussion`);
  the game's "acid" and "corroding" shields are not abilities but AI rules (`DA_AIAbility_ShieldConfig_Acid` /
  `_Corroding`) that raise the plain Shield, so once a bot has the Shield class the game fires it on acid routes.
- **Ion Blast is a crash ability**: `VehicleBuildDef.CrashAbility` (its own slot, not one of the four);
  `BP_Ability_IonBlast_Cooled / _Overclocked / _Shielded` under `Abilities/IonBlast/`. Set on the launch build, every
  racer gets one; the player's copy is tamed through its own config (`AttackConditionDuration`,
  `SuccessBuffConditionDuration`, `SinglePlayerAIKillChance` = 0). Taking it off the component while the warm-up charged
  it crashed the game in dxgi (2026-11-13): never clear a charging ability.
- **Per-ability cooldowns for the AI**: `AbilityConfig.WarmupTime` by class name - mines at 7.5 / 0.0975 ≈ 77 s (their
  log: Mine 71 + Triple Mine 25 of 284 AI uses in 7 races), Disruptors 15 s, the rest 7.5 s. Bots pick the player as
  aggression target 45 % less (`AiAggressionVPlayerChanceMultiplier` x0.55, after the difficulty's).
- **Disruptor softened**: bots' Disruptor / Ion Blast hit for 1.5 s (`AttackConditionDuration` on the *instance's own*
  config copy, telling it from the shared one by path); after one hit, no bot Disruptor can lock onto the player for
  20-30 s (`TimeUntilLockOn` pushed to 1e6 while `TrackedTargets[].TrackedPlayer` is the player, put back when it lets go).
- **Final lap rule**: when the leader is on the last lap (`RacingGameState.LapCount` vs each `CurrentLapNumber`), bots
  may use only the Flame Vent, and only with a racer within 3 m: other abilities' `State` held at WarmingUp (2) each
  step and their `EnergyCost` 999 (put back at the menu). Tried and NOT working: `AIAbilityConfig.PercentageChance = 0`
  (the AI keeps its own copy) and `PlayerAbilityComponent.RaceRunning = false`; the AI trigger rules are
  InstancedStructs Lua can't write.
- Player Flame Vent at the ramjet redline (`BoostState.RamjetState.RamjetState` 4 CriticalWarning / 5 GraceTime):
  speed pushed to x1.2 for the vent's `VentAttackDuration` by `SetPhysicsLinearVelocity`.
**For us:** confirms 3.1 (cycle the selection) and adds the per-class cooldown dial and the "own config copy" test for
touching one bot's ability without touching the shared asset. The Shield-in-pool note answers part of R7: a bot with the
Shield class will raise it where the game's acid / corroding rules say, and only there.

### 6.3 Opponents' cars: tune sets as a per-bot speed dial (`fr_vehicle.lua`, +600 lines)
- **Opponent pace**: a runtime tune set on each bot's `TuneComponent` after the start grace:
  `VehicleThrustConfig.MaxRPM / LowSpeedAcceleration / MidSpeedAcceleration / HighSpeedAcceleration` FloatMultiply x1.8
  ("opponent top speed before / after" logged from `BodyState.TopSpeedKmph`). Braking x3 / x4.5 was tried and taken
  back (pods air-brake while steering; they slowed on straights); turning x3 "sent them all haywire".
  **This is the lever our pilot-strength work lacked**: KNOWLEDGE.md says bot pace follows the shared template and parts
  barely move it; a thrust tune set per bot is independent of both. Worth one held-race test (3 bots at x1.1, x1.0,
  x0.9) before anything else in this list.
- **Opponent shielding**: the player's armour levels on every bot (MaxImpact x N, the eight crash / vulnerable thresholds
  x N, `WallGrindTakedownTime`), with a **quick respawn**: `VehicleResetConfig.MinResetSpeedMph` +500 and the game's own
  `Server_RequestResetOnTrack` (found by name on the pawn or a component, parameters by type) 0.5 s into any crash and
  after 0.8 s under 100 kph with no crash ("unstick"). Pod engine snap (`JellyConfiguration.LinSnapDistance...`) x N on
  assets only bots use.
- **Respawn shield** for the player: god-mode tune set for 3 s after each reset, removed by `RequestRemoveTuneSet` (new
  `T.remove`; else undone by an inverse set). A reset is detected as `VehiclePawn.InputSourceOverrides` holding reason 10
  (Reset); **autopilot after a reset is ended** with `StopInputSourceOverride_OnServer(10)` (`MinAIControlDuration` x0
  alone did nothing).
- **Takedowns** counted from the bots' `CrashComponent` (`BlameComponent.BlameContributors[].Contributor`,
  `TakedownContributors`) naming the player, pawn or controller; also every bot crash with its `CrashTags` and
  `ManagedCrash.CrashReason`, resets, stops; a summary line every 30 s.
**For us:** the per-bot thrust dial (test first), the respawn shield as a Junker-league mercy, takedowns as a standings
bonus or a results line, "autopilot after reset off" as an owner option.

### 6.4 Rubber band by hand (`fr_pull.lua`) and catch-up
Bots behind the player get `SetPhysicsLinearVelocity` x(1 + rate x dt) every 50 ms, harder the further back (full at
500 m or a lap down), capped at 1.1 x the player's 10 s average pace near them and 800-1000 kph far back, never on a
jump (vertical share > 15 %), off during the start grace; AI catch-up boost x5 on top. Tuned for uncapped podracers on
car tracks. We decided against rubber-banding; keep as a known lever. `fr_difficulty` also scales the driving styles
(`MinTimeBetweenBoosts` x0.4 etc., found through each `RaceAIComponent.DrivingStyle`, not by class search) and turns
off `ForcedErrorChance` / `EnableSpeedMatchingZone` except on Story / Hard and on landspeeder tracks.

### 6.5 Smaller things worth having
- **Results screen caught as it is made** (`NotifyOnNewObject('/Script/UMG.UserWidget')` filtered by class, path kept)
  instead of a sweep per look: "a full sweep here every look, from the featured racer's finish on, was a dropped frame
  each time while the rest of the field raced home (2026-11-11)". Our chain.lua sweeps every 300 ms from your finish.
- **One scan, many classes** (`fr_hud`): one `FindAllOf('UserWidget')` classified by a class map instead of 45
  per-class sweeps at ~20 ms each; items keep their class and are let go when the slot is reused by another widget
  (a destroyed widget's slot went to a Settings row, which then flashed, 2026-11-09).
- **Inter-mod flag**: `ModRef:SetSharedVariable('TheaterShowHidesHud', bool)` / `GetSharedVariable` so one mod stands
  aside while another owns a job. We run three mods at once; a "GalacticGrandPrix.race" flag would let Streamline /
  Underground skip their race work in our cups.
- **START locked while the game's tiles are locked** (queued for an online match): `GetIsEnabled() == false`,
  `GetLocked() == true` or `IsInteractionEnabled() == false` on any `WBP_FE_TileCommon_Btn` on the page locks the mod's
  own button, with the game's dark wash / frame / padlock look (`Icn_Lock` brush copied, never the whole brush: that
  crashed). A cheap extra guard for our "never automate multiplayer" rule.
- **Personal records** (`fr_records.lua`): best lap (`PlayerRaceEventComponent.BestLapTime`) and best race per track,
  class and lap count, saved as a Lua chunk in the game's Saved folder, "NEW BEST LAP" lines on the results screen in
  the screen's `Title_Text` font. We keep race records per league; best lap is the missing half.
- `RacingGameState.LapCount` is the race's lap count (used for the final-lap rule and the records).
- **Custom racers from another mod** (`custom_racers.txt`, Pod Builder): an asset not in the registry is not found by
  `LoadAsset`; `KismetSystemLibrary:MakeSoftObjectPath(path)` -> `Conv_SoftObjPathToSoftObjRef` -> `LoadAsset_Blocking`
  loads it. Directly relevant to our vehicle-model pak work.
- **Track mines off** on `_MINES` layouts: ownerless `ProximityMine` actors (no `OwnerVehicle` / `OwnerAbility`) hidden
  like the buoys. Our pools use the mines variants on purpose, so only an option.
- **Applying a condition to a racer**: `VehiclePawn.RequestApplyTimedCondition_OnServer(tag, duration, instigator...)`
  (parameters read at run time), tag from the victim's `VehicleConditionComponent.ConditionObjectsList[].ConditionTag`.
  Used for their "rear contact static" and elemental mines (`ProximityMine.ConditionTagsToApply` rewritten). A tool for
  league gimmicks if ever wanted.
- Crashes they hit that we should not: game data the menu holds freed by the GC while the page is up (reading a field
  off it took the game down, 2026-11-10: now `alive()` before each use, and the pilot list dropped at every new menu
  because an unloaded racer asset's name crashed an FText copy); copying a whole brush between game widgets crashed
  (2026-11-08); `AddToViewport(60)` draws under the menu.
- Perfect start chance is now 45 % (was 15 % in 1.1c, the game's 75 %); podracers get a 10 s grace with the game's own
  catch-up.

### 6.6 Revised order
1. Buoys off on The Galactic Gauntlet (3.3).
2. AI ability cycling + coverage log + per-class cooldowns (3.1, 6.2).
3. **Per-bot thrust tune set test** (6.3): three held races; if it moves the bots' pace it replaces the parts-stacking
   pilot strength and the template leak stops mattering.
4. Start grace (3.2), results screen by `NotifyOnNewObject` (6.5), START locked with the game's tiles (6.5).
5. Lap count and wreck limit (3.4, 3.5).
6. The game's tour-summary screen as our CUP RESULT (6.1) - the owner's call: big, native-looking payoff.
7. Box navigation, RESTART, HUD parts, Settings rows, takedowns, best laps, the live pilot: polish.
