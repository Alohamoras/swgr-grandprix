# attic/: old code, kept for reference

Code taken out of the mod because nothing uses it any more (owner, 2026-11-11: "take out the unused code and save it
somewhere as old code"). **Nothing in this folder is loaded by the mod, deployed or run by the tests.** `deploy.sh`
only copies `mod/GalacticGrandPrix` (`git archive "$REF" mod/GalacticGrandPrix`), and `test/all.sh` only checks
`mod/` and `tools/recon/` and runs `test/test_*.lua`. Excerpt files are cut out of larger files, so they don't compile
on their own.

All of it was last in **v0.21.0** (tag `v0.21.0`; `git show v0.21.0:<path>` gives the whole file as it was).

## Study mode (v0.16 to v0.21.0)

Batches of single races with a different AI profile for each, driven by the test-only TestAutopilot, for the AI tuning
study (DESIGN.md §14, TASKS.md B10). It was off unless a `study.lua` file was in the mod folder. It did its job: the
two batches in docs/ai-study-2026-11-11.md led to the v0.18 profiles. Since then it only cost an `io.open` every 5 s at
the menu, and it was why BootToGrandPrix skipped the boot when study jobs were left.

| File | What it was |
|---|---|
| `studymode.lua` | the whole module: `mod/GalacticGrandPrix/Scripts/studymode.lua` |
| `main-study-wiring.lua` | excerpts of `main.lua`: the `ST` require, the study result and failure branches in `tick()`, `studyEnv` + `ST.boot()`, BootToGrandPrix's "study jobs pending" check, and the `ST.poll` call in the menu poll |
| `test_study.lua` | the whole test: `test/test_study.lua` |
| `test_study_resume.lua` | the whole test: `test/test_study_resume.lua` |
| `test_boot_study.lua` | excerpt of `test/test_boot.lua`: its `study` and `studydone` scenarios |

Kept in the mod (not study mode): the `[aiset]` read-back (ai.lua, main.lua's boot read-back) and the `[gaps]` log
(gp.lua / race.lua). There are no config entries for study mode. Only BootToGrandPrix's comment mentioned it, and that
mention is gone. test_boot's `study` scenario now checks that a leftover study.lua changes nothing.

## The same-layout reset route for chained races (v0.19.0 to v0.21.0)

NEXT RACE on the results screen's panel, done without going to the main menu: the next event was written into the race
recipe (both copies, read back), then `BP_RacingGameMode_C:RequestResetRace()`, with a load timeout (`LoadTimeoutS`), a
watchdog (`WatchdogS`: AI racers and a start), a check of the new world's event and `CH.fallback` to the menu route.
In game on v0.19.0 (2026-11-11 17:35), Mastiff/Loop_A to Mastiff/P2P_A got stuck on PLEASE WAIT and the game had to
be killed. The reset only re-uses the loaded map. Since v0.19.1 it was off by default (`ChainRaces.Reset = false`)
and limited to the same layout folder. It was proven only for Loop_A to Loop_A.

The menu route stays and is unchanged: the results panel, then NEXT RACE (or CONTINUE / B), the main menu under the
cover, then the auto-launch (`CH.via`, main.lua `viaMenu`).

| File | What it was |
|---|---|
| `chain-reset-route.lua` | excerpts, each labelled with where it came from. **chain.lua**: the old header, `CH.resetOn` / `loadTimeoutMs` / `watchdogMs`, `CH.args`, `CH.planet` / `layout` / `sameLayout`, the old `CH.plan` (routes 'menu' / 'reset'), the recipe section (`writeRecipe`, `putBack`, `worldEvent`, `CH.undo`), `CH.fallback`, and the route switch at the end of `CH.tick`. **race.lua**: the recipe put-back in `R.restoreBuild`, `R.chainLaunch`, readField's AI racer count (`r.bots`), `chainApi.launch`, `fallbackWatch` and the `'fallback'` phase, the reset branches of `R.watch` (new world check, no new world, the watchdog). **main.lua**: `require('chain').args = cupArgs`. **config.lua**: `ChainRaces.Reset`, `LoadTimeoutS`, `WatchdogS` and their comment |
| `test_chain_reset.lua` | excerpts of `test/test_chain.lua`: the old header, `CRAIT` / `resetCfg` / `craitRace2`, scenarios E, F, G, H and I, and J's `CH.layout` / `CH.sameLayout` checks |

The fake game's recipe and `RequestResetRace` (test/world.lua: `W.resets`, `W.resetMode`, `W.noRecipe`,
`W.stageEvent`, `W.activeStage`, `W.chainWorld`) stay in world.lua. It models the game, and test_chain's A and B
still check that `W.resets == 0` (the menu route never resets). To bring the route back, start from
`git show v0.21.0:mod/GalacticGrandPrix/Scripts/chain.lua` (and race.lua) rather than these excerpts.

## Candidates, not removed

Code that is switched off or has no caller, found while doing the above. **Nothing here was removed.** Each one is for
the owner to decide.

1. **The per-race AI profile override.** `R.launch(..., opts)` with `opts.ai`, `prepare`'s `opts`, and the `prof`
   parameters through ai.lua (`A.profile`, `A.pressure`, `A.classOp`, `A.tuneValue`, `A.plan`, `AI.launch` /
   `AI.begin`), plus the `' study'` / `'(study profile)'` log tags. Study mode was the only caller. test_aiset's
   "study profile" block still uses it.
2. **The v0.20 grey page panel** (`PageBackdrop = false` since v0.21): `U.PAGE_GREY` when `PageBackdrop = true`, in
   ui.lua `U.pageColor`, and the `[menu] page backdrop` line. The pages with their own picture use `U.PAGE_GREY`
   anyway, so only the switch would go.
3. **The v0.20 two-button results panel** (`ChainRaces.Panel.HideContinue = false`; v0.21 hides CONTINUE): chain.lua
   `addButton`'s side-by-side layout and navigation rules, `ButtonGap` / `GAP`, the v0.20 prompt in `CH.prompt`, and
   the not-hidden branch of `CH.goneBeforeNext`. test_chain C4 covers it.
4. **The fake game's reset machinery** in test/world.lua (see above). It is only exercised by attic/test_chain_reset.lua
   and the `W.resets == 0` checks.
5. **test/util.lua's `errors=` exception** in the "error in log" check. It was there for the study's `[study]` lines
   (the profile's `errors=` key). The `[aiset]` / `[ai]` lines of a profile with `errors` could still print it, so it
   only matters together with item 1.
6. **`tab.lua`'s `[tab] ..` step trace** (`TabTrace`, on by default; its comment says to turn it off "once the tab is
   proven", which it has been). It is not switched off, but it is debug output nobody reads now.
