-- ATTIC (not loaded, not deployed). Excerpts of mod/GalacticGrandPrix/Scripts/main.lua as of v0.21.0: the wiring of
-- study mode (studymode.lua, also in attic/). Removed after v0.21.0; see attic/README.md. Each block names where it was.
-- The [aiset] boot read-back that sat next to the poll call is NOT study mode and stays in main.lua.

-- (header comment)
-- v0.16: study mode (test-only): study.lua in the mod folder runs a batch of single races with AI profiles (studymode.lua).

-- (module reload list: 'studymode' was in it)
for _, m in ipairs({ 'core', 'config', 'abil', 'cup', 'title', 'racer', 'prog', 'gp', 'loadout', 'ai', 'race', 'ui', 'tab', 'studymode', 'standings', 'chain' }) do package.loaded[m] = nil end

-- (forward declarations, after msgLine)
local ST = require('studymode') -- v0.16 study mode (test-only; wired below the input)
local studyEnv

-- (tick(), right after `if not ok then log('watch error: ' .. tostring(out))`: the result of a study race)
  elseif out and out.failed and ST.running() then
    -- v0.16: a study job's race never loaded: logged and skipped (no page opened)
    ST.onFailed(out.failed)
  elseif ST.owns(out) then
    -- v0.16: a study job's result: its log line and CSV row; the page stays shut (the next job follows)
    S.result = out
    local okS, errS = pcall(ST.onResult, out)
    if not okS then log('[study] result not written: ' .. tostring(errS)) end

-- (after the TB.onLeave / onGone / onFail handlers)
---------------------------------------------------------------------------------------------------------------------
-- v0.16: study mode (test-only, studymode.lua): a job's single race at the main menu, no cup. Ready = menu up, no race
-- of ours, no cup, nothing to put back, no result screen waiting (flags only, no lookups). Our page is closed first
-- through the usual close path; the launch itself is the title race's (R.launch with the class's parts, your racer,
-- abilities and tune-ups), with the job's AI profile.
studyEnv = {
  ready = function() return R.menuUp() and not R.run and not K.run() and not R.pendingRestore() and not S.openAt end,
  launch = function(job, ev)
    if S.ui then close('study job'); return 'wait' end
    local ok, why = R.launch(ev, ev.class, myVehicle().key, picksFor(ev.class), modsFor(), { ai = job.ai })
    if ok then S.message = nil end
    return ok, why
  end,
}
ST.boot()

-- (bootPoll: BootToGrandPrix stood aside while study.lua had jobs left; its header comment said
-- "Never with study.lua jobs pending (the study needs the plain menu).")
  if ST.pending() then
    boot.done = true
    log('[boot] not opening the GRAND PRIX tab: study mode has jobs pending (study.lua) - the study needs the plain main menu')
    return
  end

-- (the main menu poll, after the [aiset] boot read-back)
    -- v0.16: study mode (test-only; nothing but an io.open every 5 s without study.lua)
    local okS, errS = pcall(ST.poll, POLL_MS, studyEnv)
    if not okS then log('[study] poll: ' .. tostring(errS)) end

-- (config.lua, BootToGrandPrix's comment ended "Not with a study (study.lua) pending.")
-- (test/test_boot.lua had two scenarios, 'study' (jobs pending: no boot into the tab, logged) and 'studydone' (all
-- jobs done: boots as usual); they are in attic/test_boot_study.lua)
