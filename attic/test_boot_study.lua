-- ATTIC (not run by test/all.sh). Excerpt of test/test_boot.lua as of v0.21.0: its two study-mode scenarios. The
-- scenario list was { 'main', 'off', 'study', 'studydone' }, and the file removed study.lua / study_state.lua /
-- study_results.csv from the sandbox before and after. See attic/README.md.

elseif scenario == 'study' then
  local f = io.open(T.dir .. '/study.lua', 'w')
  f:write("return { { class = '50', cup = 'jakku', race = 1, label = 'a' } }\n")
  f:close()
  T.boot(save(), { BootToGrandPrix = true, Progression = { On = false }, Manual = true })
  require('studymode').SETTLE_MS = 1e9 -- (the study's own launch held off: this checks the boot, not the study)
  menu(); M.tick(120)
  check(T.logHas('[boot] not opening the GRAND PRIX tab: study mode has jobs pending (study.lua)'), 'study pending: logged why')
  check(not T.logHas('[boot] opening') and not T.logHas('[menu] home') and W.tab.selected == 'Recommended', 'study pending: not opened')
  check(count('[boot]') == 1, 'one [boot] line')

elseif scenario == 'studydone' then
  -- study.lua there but every job done: boots into the page as usual
  local f = io.open(T.dir .. '/study.lua', 'w')
  f:write("return { { class = '50', cup = 'jakku', race = 1, label = 'a' } }\n")
  f:close()
  f = io.open(T.dir .. '/study_state.lua', 'w'); f:write('return { next = 2 }\n'); f:close()
  T.boot(save(), { BootToGrandPrix = true, Progression = { On = false }, Manual = true })
  menu(); M.tick(30)
  check(count(OPEN) == 1 and T.titles() == HOME, 'study all done: opened on HOME')
end
