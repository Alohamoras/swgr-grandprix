# New vehicle models: the process (2026-11-12)

The owner asked how hard it would be to design new vehicle models, with two photos as inspiration (taken
2026-11-13 00:33, `~/Downloads/PXL_20261113_003357371.NIGHT.jpg`, `PXL_20261113_003414787.NIGHT.jpg`): a rusted
open-top speeder with two jet engines on side outriggers, a woven-strap cargo bed on long booms, a canopy roof, two
perforated metal seats and front skid plates. A perfect fit for the JUNKER league (docs/league-styles-2026-11-12.md).
Not started; this is the plan to come back to.

## How the game builds a vehicle (what we know)
- **Every landspeeder shares one body** (`SM_CarRoot`); bikes (`SM_BikeRoot`) and skimmers (`SM_SkimmerRoot`) the
  same. The look comes from **part kits**: 12 car kits (Beluga ... Wahoo) x 6 slots, plus a paint scheme. Only
  podracers have bodies of their own (Cretornis, Northropi...). (swgr-vehiclelooks/CONTEXT.md)
- A vehicle's look = a recipe (`ACstVehicleRecipe`: parts by slot + kit), built by the pawn's
  `UCstCustomisationComponent` from a preset (`UCstVehiclePresetRecipe`, `PRE_Car_*`); themes (`UCstThemeData`) point
  at presets. Our VehicleLooks mod already renames / repoints a theme in memory (proven).
- **Looks and handling are separate**: a new model changes nothing about speed, physics or collision (those are the
  build, `VehicleBuildDef` / `VehicleBuildState`, which we already edit).
- Unreal Engine **5.7**. New meshes must be **cooked** in the matching editor and packed as IoStore files
  (`.utoc` / `.ucas` / `.pak`) dropped into `Griffin/Content/Paks/~mods`. Proven by others:
  - [Anakin's Podracer](https://www.nexusmods.com/starwarsgalacticracer/mods/52) replaces a pod's meshes this way
    (pakchunk 235 - two mods on the same chunk number clash);
  - [SWGAR Podracer Builder](https://www.nexusmods.com/starwarsgalacticracer/mods/65) loads custom pod models;
  - [Vortex extension](https://www.nexusmods.com/site/mods/2425) installs pak mods into `Paks/~mods`.

## The process
1. **Study the existing parts** (Claude): extract the car root and one kit's six parts with an asset viewer
   (FModel / CUE4Parse; asset paths from `Manifest_UFSFiles_Win64.txt`, `swgr-vehiclelooks/tools/utocdir.py`) - scale,
   pivots, sockets where parts attach, the material setup, the slot names.
2. **Model it** (the big job, art): shapes, UVs, PBR textures (rust, paint, the strap weave), LODs.
   - a modeller in Blender: ~20-60 h for game-quality next to the stock cars;
   - AI image-to-3D tools from the photos as a rough base, then clean-up;
   - Claude can script a Blender block-out of primitives, not finished art.
3. **Fit it to the game:** easiest = **replace one existing kit** (e.g. Goblin's six parts) with the new pieces, same
   asset paths, so nothing new is registered. A brand-new kit beside the others is harder (new data assets), though
   the in-memory theme repoint (VehicleLooks) helps.
4. **Cook and pack:** UE 5.7 editor (Epic launcher; best on Windows or a VM), a project mirroring the game's content
   paths, cook, IoStore pack, a free pakchunk number. One-time setup ~1-2 days; Claude can script most of it.
5. **In game:** pick the kit in the garage, or the mod assigns it. Check the joints line up, it looks right moving,
   and the AI don't wear it by accident.

## Risks
- Game updates can break a cooked pak (re-cook needed).
- Multiplayer: a modified pak online is riskier than the Lua mods - keep it out for multiplayer (the mods-off idea).
- Not a Denuvo bypass (the game loads `~mods` paks as designed) - within the house rules.
- Collision stays the stock car's: the long engine outriggers would clip through walls now and then.

## Suggested first step (no art needed)
A pipeline proof: extract one car kit, cook it back with a trivial change (a part scaled or recoloured), see it in a
race. If that works, all that's left is the model itself - and who builds it (the owner, a modeller, an AI 3D tool +
clean-up).

## The cheap alternative: rust on the existing cars (owner, 2026-11-12: "just adding some rust ... for the junker class")
No modelling, no cooking - Lua only. The game's livery system already has **patinas** (finishes), picked in the
campaign garage (`WBP_Paddock_VehicleCustPatina`): `/GriffinSharedVehicles/Griffin/Vehicles/Common/Liveries/Patinas/LP_AllRust`
(**All Rust**, the rust layer `MLI_RustPatina`), `LP_NoPaint11`, `LP_AllSteel`, `LP_Patina211` (a mix), `LP_AllPaint`,
`LP_AllGold`, `LP_Deluxe` (**the paid edition's - never use it**, house rule).
Three levers on a car, all in the header dump:
1. **Patina:** every vehicle recipe has a `PatinaTag` (`FCstSavedVehicleRecipeData`, next to the livery palette /
   mask tags). Set it to All Rust on your car (and maybe the Junker field) at race load. Route to find: the race's
   recipe entry (proven for the racer swap: the recipe list carries each entry's preset), `Server_UpdateVehicleRecipe`
   (FreeRace's way), or the pawn's `UCstCustomisationComponent` + `RefreshRecipe`. Note VehicleLooks found a theme
   swap applies parts but not the palette tags - so the tag route needs a test.
2. **Dirt:** `UCstCustomisationComponent.DebugDirtOverrideValue` (and `DebugWetnessOverrideValue`); the race builds dirt
   up by surface (`UGfnPhysicalMaterial.DirtBuildupRate`). Forcing it high = grime from the start.
3. **Damage:** `UCstCustomisationComponent:DebugApplyAllVehicleDamage(value)` / `DebugPanelMin/MaxDamage` - dented,
   scratched panels at the start (the game's crash damage look).
"Debug" fields may do nothing in the shipping build - the spike tells. Spike: at a Junker race load, try 1-3 one at a
time on your car, screenshot each; then decide which go on the Junker league (yours only, or the whole field).
Effort: a short spike (an hour or two of game time), then a small feature.
