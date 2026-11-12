-- v0.17 (TASKS.md 11): boot straight into the Grand Prix. At the first main menu after the game starts the GRAND PRIX
-- tab opens by itself on HOME (through the menu key's path: our tab picked by its id, never MULTIPLAYER); once per
-- launch (B, a race, a menu rebuild never reopen it; the standings after a cup race still open as before); config
-- BootToGrandPrix = false = no open; a leftover study.lua (study mode is gone, attic/) changes nothing; an old cup in
-- the save is dropped
-- and the put-backs done before it opens.
-- The mod loads once per process (like once per game start), so each scenario runs in its own Lua: this file with the
-- scenario's name as its argument.
local scenario = arg and arg[1]
if not scenario then
  local failed = false
  for _, s in ipairs({ 'main', 'off', 'study' }) do
    local p = io.popen(('lua5.4 %q %s 2>&1'):format(arg[0], s))
    local out = p:read('a')
    local ok = p:close()
    io.stdout:write(out)
    if not ok then
      failed = true
      if not out:find('FAIL', 1, true) then io.stdout:write('FAIL scenario ' .. s .. ' did not finish\n') end
    end
  end
  os.exit(failed and 1 or 0)
end

local M = require('mock')
local W = require('world')
local T = require('util')
for _, f in ipairs({ 'study.lua', 'study_state.lua', 'study_results.csv' }) do os.remove(T.dir .. '/' .. f) end
local function check(c, what) T.check(c, '[' .. scenario .. '] ' .. what) end
local function count(s)
  local n = 0
  for _, l in ipairs(M.log) do if l:find(s, 1, true) then n = n + 1 end end
  return n
end
local function at(s) for i, l in ipairs(M.log) do if l:find(s, 1, true) then return i end end end
local OPEN = '[boot] opening the GRAND PRIX tab (BootToGrandPrix)'
local HOME = 'RIFF-RAFF|CHALLENGER|ACE|GARAGE|RESET PROGRESS'
local function save(extra)
  local s = { version = 3, races = 5, cups = 0, class = 'riffraff', best = {}, restores = {}, abilityRestores = {} }
  for k, v in pairs(extra or {}) do s[k] = v end
  return s
end
-- the menu with its tab bar, every tab the mod picks recorded
local picked = {}
local function wrap()
  local p = rawget(W.tab.tl, '__props')
  local sel = p.SelectTabByID
  p.SelectTabByID = function(self, id, ...) picked[#picked + 1] = id; return sel(self, id, ...) end
end
local function menu() W.tabMenu(); wrap() end
local function bPress()
  -- B: the game deactivates our invisible Back screen (tab.lua T.backScreen)
  local b = W.backs and W.backs[#W.backs]
  assert(b, 'no Back screen')
  M.tick(2)
  rawget(b, '__props').__active = false
  M.tick(3)
end

if scenario == 'main' then
  -- an old cup run (race 2 of 4) and an AI put-back left in the save by a crash
  T.boot(save({ run = { class = 'challenger', cup = 'lantaana', vehicle = 'car', race = 2, races = 4, points = { YOU = 12 }, last = {}, history = { {} } },
    aiRestores = { ['/Game/Griffin/AI/DA_AIConfig'] = { ForcedErrorChance = 15 } } }),
    { BootToGrandPrix = true, Progression = { On = false }, Manual = true })
  W.ai.ForcedErrorChance = 7.5
  check(T.logHas('[cup] lantaana CHALLENGER dropped at boot (race 2 of 4)') and T.save().run == nil, 'the old cup dropped at load')
  check(not T.logHas('[boot] opening'), 'nothing opened before the main menu')
  menu()
  M.tick(3)
  check(not T.logHas('[boot] opening'), 'not opened while the menu settles (before the tab is added)')
  -- v0.22 (owner: the tab took ~3 s): the tab is in within ~1.4 s of polls (200 ms each) after the menu shows
  local polls = 3
  while not T.logHas('[tab] GRAND PRIX tab added') and polls < 40 do M.tick(1); polls = polls + 1 end
  check(polls <= 7, ('v0.22: the tab added %d polls (~%.1f s) after the menu showed'):format(polls, polls * 0.2))
  M.tick(24 - polls)
  check(count(OPEN) == 1, 'opened once at the first menu')
  local iTab, iOpen, iDrop, iAi = at('[tab] GRAND PRIX tab added'), at(OPEN), at('dropped at boot'), at('[ai] AI config put back')
  check(iTab and iOpen and iTab < iOpen, 'opened after "GRAND PRIX tab added"')
  check(iDrop and iDrop < iOpen, 'the old cup dropped before the open')
  check(iAi and iAi < iOpen and W.ai.ForcedErrorChance == 15, 'the AI config put back before the open')
  check(T.logHas('[menu] home') and T.titles() == HOME, 'HOME shown, no cup tiles (' .. T.titles() .. ')')
  check(W.tab.selected == 'Mod_GrandPrix', 'our tab selected')
  check(T.logHas('[tab] select GRAND PRIX: true'), 'through the menu key\'s path (TB.select)')
  check(T.save().run == nil, 'no cup')
  M.tick(20)
  check(T.logHas('[boot] the GRAND PRIX tab is up'), 'the tab stayed up (logged)')

  -- B on HOME: back to the game's main menu, and it stays there
  bPress()
  check(T.logHas('[menu] closed (back)') and W.tab.selected == 'Recommended', 'B on HOME: back to the game\'s first tab')
  local mark = T.mark()
  M.tick(80)
  check(not T.logHas('[menu] home', mark) and W.tab.selected == 'Recommended' and count(OPEN) == 1, 'B: not reopened')

  -- the main menu rebuilt (as after a race): not reopened
  M.kill(W.mm); W.frontEnd(); menu(); M.tick(40)
  check(count('[tab] GRAND PRIX tab added') >= 2, 'the rebuilt menu got our tab')
  check(count(OPEN) == 1 and W.tab.selected == 'Recommended', 'a rebuilt menu: not reopened')

  -- a cup race: the standings come back after it (as before); afterwards nothing reopens
  M.press('F6'); M.tick(6)
  check(T.titles() == HOME, 'F6 still opens HOME')
  T.clickTitle('RIFF-RAFF'); M.tick(3)
  T.clickTitle('JAKKU CUP')
  check(M.called('LaunchQuickRace') == 1, 'race launched')
  W.race(11); M.tick(5)
  for i, b in ipairs(W.bots) do
    local rec = rawget(rawget(b, '__props').RaceEventComponent, '__props')
    rec.EventPosition = i + 1
    rec.bHasFinishedEvent = true
  end
  M.tick(5)
  W.finish(1); M.tick(25)
  local t0 = os.time(); while os.time() - t0 < 3 do end
  mark = T.mark()
  W.backToMenu(); wrap(); M.tick(45)
  check(T.logHas('[menu] standings', mark) and T.titles() == 'NEXT RACE', 'after the race: the standings open as before')
  check(count(OPEN) == 1, 'after the race: no boot open')
  -- leave the cup, then B on HOME
  M.press('BACKSPACE'); M.tick(5)
  T.clickTitle('YES'); M.tick(3)
  check(T.titles() == HOME and T.save().run == nil, 'cup left: HOME')
  bPress()
  check(W.tab.selected == 'Recommended', 'B: the game\'s main menu')
  mark = T.mark()
  M.tick(80)
  check(not T.logHas('[menu] home', mark) and W.tab.selected == 'Recommended' and count(OPEN) == 1, 'after a race and B: not reopened')

  -- never MULTIPLAYER: only our tab and the game's first tab were ever picked
  local bad = {}
  for _, id in ipairs(picked) do if id ~= 'Mod_GrandPrix' and id ~= 'Recommended' then bad[#bad + 1] = tostring(id) end end
  check(#bad == 0 and #picked >= 5, 'only our tab and the first tab picked, never Multiplayer (' .. table.concat(picked, ',') .. ')')

elseif scenario == 'off' then
  T.boot(save(), { BootToGrandPrix = false, Progression = { On = false }, Manual = true })
  menu(); M.tick(120)
  check(T.logHas('[boot] BootToGrandPrix is off'), 'switch off: logged')
  check(T.logHas('[tab] GRAND PRIX tab added'), 'the tab is still added')
  check(not T.logHas('[boot] opening') and not T.logHas('[menu] home') and W.tab.selected == 'Recommended' and #picked == 0,
    'switch off: nothing opened, no tab picked')
  M.press('F6'); M.tick(6)
  check(T.titles() == HOME, 'F6 still opens HOME')

elseif scenario == 'study' then
  -- after v0.21.0 study mode is gone (attic/): a study.lua left in the mod folder is ignored, the boot is as usual
  local f = io.open(T.dir .. '/study.lua', 'w')
  f:write("return { { class = 'riffraff', cup = 'jakku', race = 1, label = 'a' } }\n")
  f:close()
  T.boot(save(), { BootToGrandPrix = true, Progression = { On = false }, Manual = true })
  menu(); M.tick(120)
  check(count(OPEN) == 1 and T.titles() == HOME, 'leftover study.lua: opened on HOME as usual')
  check(not T.logHas('[study]') and M.called('LaunchQuickRace') == 0, 'leftover study.lua: no [study] lines, nothing launched')
end

for _, f in ipairs({ 'study.lua', 'study_state.lua', 'study_results.csv' }) do os.remove(T.dir .. '/' .. f) end
T.finish()
