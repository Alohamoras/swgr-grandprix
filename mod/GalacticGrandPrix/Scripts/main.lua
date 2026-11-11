-- Galactic Grand Prix: kart-racer-style cups for STAR WARS Galactic Racer (DESIGN.md).
-- The GRAND PRIX tab on the game's main menu (or F6) -> speed class -> cup -> race. Races launch straight away through
-- the game's offline quick race (FrontEndGameMode:LaunchQuickRace) with every part at the class's level.
-- v0.2: cups of 4 races with points for all 12 racers, standings after each race, a trophy at the end.
-- v0.3: your four abilities (v0.3.10: free pick, one per family), the AI racers' four, levels by class.
-- v0.9: cups cannot be resumed (owner): leaving a cup before its last standings loses it.
-- v0.11: one cup per planet with a race list per class (classic / reverse / conditions), the Galactic Cup, the title race.
-- v0.16: study mode (test-only): study.lua in the mod folder runs a batch of single races with AI profiles (studymode.lua).
-- v0.17: the game boots straight into the GRAND PRIX tab (HOME), once per launch (config BootToGrandPrix).
-- v0.19: cups without the main menu: the standings over the game's results screen, NEXT RACE from there (chain.lua).
-- Design: DESIGN.md  Plan: TASKS.md  Save: save.lua  Log: grandprix.log

local VERSION = '0.19.0'

local here = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
local scripts = here:match('^(.*)[/\\][^/\\]+$') or '.'
package.path = scripts .. '/?.lua;' .. package.path
for _, m in ipairs({ 'core', 'config', 'abil', 'cup', 'rival', 'gp', 'loadout', 'ai', 'race', 'ui', 'tab', 'studymode', 'standings', 'chain' }) do package.loaded[m] = nil end

local C = require('core')
C.DIR = scripts:match('^(.*)[/\\][Ss]cripts$') or '.'
local cfg = require('config')
for k, v in pairs(rawget(_G, 'GU_TEST_CFG') or {}) do cfg[k] = v end -- test harness only (test/util.lua)
local K = require('gp')
local R = require('race')
local U = require('ui')
local ART = require('art')
local TB = require('tab')
local AI = require('ai')
local try, alive, log, ordinal = C.try, C.alive, C.log, C.ordinal

K.load()
K.drop('at boot') -- v0.9: a cup left in the save by a restart or a crash is lost (cups cannot be resumed)

local function tabMode() return not TB.failed end
U.setLayout('tab')

---------------------------------------------------------------------------------------------------------------------
-- screen state

local S = {
  ui = nil,          -- the built screen { w, items, scroll, pc }
  screen = nil,      -- 'home' | 'cups' | 'garage' | 'standings' | 'confirm' | 'offline' (v0.8: two levels)
  confirm = nil,     -- { text, yes = function, back = screen, after = screen after yes }
  class = nil,       -- class key
  cup = nil,         -- cup key
  focus = 1,
  focusMem = {},     -- screen key -> focused tile
  shownAt = 0,
  message = nil,     -- one-line message on the next screen
  result = nil,      -- last race result for the result screen
  openAt = nil,      -- clock time to open the result screen after a race
}

local function msgLine() return { S.message or '', 20, U.GOLD } end

local show -- forward
local ST = require('studymode') -- v0.16 study mode (test-only; wired below the input)
local studyEnv
local startLoop -- forward
local boot, bootPoll -- v0.17 boot into the Grand Prix (below the study mode)

---------------------------------------------------------------------------------------------------------------------
-- screens: each returns a spec for ui.build; tile `act` functions change state and return true to redraw

local function go(screen) S.screen = screen; S.message = nil; return true end

local CU = require('cup')
local RV = require('rival')
local AB = require('abil')
local PR = require('prog')
local MS = require('modsel')

-- your four picks, made valid for a class's level (and kept in the save)
local function picksFor(classKey)
  local p = AB.normalize(K.data.picks, AB.levelFor(classKey))
  K.data.picks = p
  return p
end
-- your mods (four slots), made valid and kept in the save (v0.4)
local function modsFor()
  K.data.mods = MS.normalize(K.data.mods)
  return K.data.mods
end
local function modsText(list, classKey)
  local n = MS.slotsFor(classKey)
  if n == 0 then return 'None at this class' end
  local names = MS.names(list, classKey)
  return #names > 0 and table.concat(names, '  /  ') or ('No mods yet (' .. n .. ' slots)')
end
local function picksText(picks, level)
  local o = {}
  for _, p in ipairs(AB.toList(picks)) do o[#o + 1] = AB.label(p, level) end
  return table.concat(o, '  /  ')
end
local TROPHY_NAME = { 'GOLD', 'SILVER', 'BRONZE' }
local TROPHY_INDEX = { GOLD = 1, SILVER = 2, BRONZE = 3 }
local function bestText(classKey, cupKey)
  local b = K.best(classKey, cupKey)
  if not b then return 'Not raced yet' end
  return TROPHY_NAME[b] and ('Best: ' .. TROPHY_NAME[b] .. ' trophy') or ('Best: ' .. ordinal(b))
end
-- the trophy badge on a cup tile (v0.3.11, owner): GOLD / SILVER / BRONZE, nil without a trophy
local function trophyBadge(classKey, cupKey)
  local b = K.best(classKey, cupKey)
  return b and TROPHY_NAME[b] and (TROPHY_NAME[b] .. ' TROPHY') or nil
end
-- v0.7: the trophy's medal in the cup tile's icon slot
local function medal(classKey, cupKey)
  local b = K.best(classKey, cupKey)
  if not (b and TROPHY_NAME[b]) then return nil end
  return ART.medal(b), ART.medalColor(b)
end

-- launch the cup's next race (the cup's own vehicle and class)
-- (v0.19: the same arguments for a race chained from the results screen, chain.lua / race.lua R.chainLaunch)
local function cupArgs(run) return run.class, run.vehicle, run.picks or picksFor(run.class), run.mods or modsFor() end
require('chain').args = cupArgs
local function launchNext()
  local run, ev = K.run(), K.nextRace()
  if not (run and ev) then S.message = 'No cup in progress'; return true end
  local ok, why = R.launch(ev, cupArgs(run))
  if ok then S.message = nil; return 'launched' end
  S.message = why
  return true
end

-- v0.19: the standings text (lines and the ranking table) is built in standings.lua, shared with the panel over the
-- game's results screen (chain.lua)
local SD = require('standings')

local SCREENS = {}

-- v0.8 (owner's menu rules, 2026-11-10): never more than two levels deep, no words you don't need, no scrolling.
--   Level 1 HOME: the four classes, GARAGE, RESET PROGRESS. B leaves the tab.
--   Level 2 CUPS (a class): the five planet cups, the GALACTIC CUP and the TITLE RACE on one page (4 + 3, v0.11);
--     focusing a cup shows its races at that class (conditions named) and your records; Select starts it. No cup page.
--   Level 2 GARAGE: vehicle, racer, four abilities, tune-ups - Select cycles the option in place. No pick screens.
-- v0.9: a cup lives from its first race's launch to the standings of its last race, and nowhere else: the standings
--   after races 1-3 offer NEXT RACE only; B there asks "Leave the cup?" (YES forfeits and goes HOME). No CONTINUE /
--   QUIT CUP tiles, no IN PROGRESS cup tile, no LATER. HOME never shows with a cup alive (K.drop).

local function classStats(classKey)
  local golds, trophies, total = 0, 0, 0
  for _, cup in ipairs(K.cups()) do
    total = total + 1
    local b = K.best(classKey, cup.key)
    if b == 1 then golds = golds + 1 end
    if b and b <= 3 then trophies = trophies + 1 end
  end
  return golds, trophies, total
end
local RC = (function() local ok, m = pcall(require, 'racer'); return ok and m or nil end)()
local TI = require('title')
-- the info text always takes the same number of lines on a screen, so the grid doesn't jump as the focus moves
-- (cups: 5; HOME: 2)
local INFO_LINES = 5
local function padInfo(text, lines)
  local n = select(2, tostring(text or ''):gsub('\n', '')) + 1
  return tostring(text or '') .. string.rep('\n ', math.max(0, (lines or INFO_LINES) - n))
end
-- v0.14 (TASKS.md A7): a tile shows a short name and at most a short second line (ui.lua U.FIT, test_tiletext); the
-- long text (effects, bios, blurbs, what opens a lock) is in the focused tile's info line
local SELECT_NEXT = 'Select: next'
local function racerName() return RC and RC.displayName and RC.displayName() or nil end
-- v0.15: the vehicle is your racer's (config Racers[].vehicle); no vehicle pick
local function myVehicle() return (RC and RC.vehicle) and RC.vehicle() or K.vehicle('car') end
local function levelNow() return AB.levelFor(K.data.class or (K.classes()[1] or {}).key) end
-- the class's champion line (the title races; the racer with most points across its planet cups)
local function championLine(classKey)
  if not TI.on() then return nil end
  local name = TI.champion(classKey)
  return name and ('Champion: ' .. tostring(name):upper()) or nil
end
-- v0.13: the champion and the rival for HOME's info line: '  Champion: BIDDY BLAS.  Rival: SEN FIRA' ('  Champion and
-- rival: SEN FIRA' when they are the same racer; '' when neither)
local function rivalInfo(classKey, champ)
  local name = RV.name(K.data, classKey)
  local riv = name and ('Rival: ' .. name:upper()) or nil
  if champ and riv and champ == 'Champion: ' .. name:upper() then return '  Champion and rival: ' .. name:upper() end
  if champ and riv then return '  ' .. champ .. '.  ' .. riv end
  local one = champ or riv
  return one and ('  ' .. one) or ''
end
-- the title race tile on the cups page: locked until a trophy in the Galactic Cup at the class; won = CHAMPION
local function titleTile(cls)
  if not (TI.on() and TI.event(cls.key)) then return nil end
  local st = TI.status(cls.key)
  local open, why, short = true, nil, nil
  if PR.titleOpen then open, why, short = PR.titleOpen(K.data, cls.key) end
  why = tostring(why or '?')
  local vs = TI.opponent(cls.key)
  if not open then
    return { title = 'TITLE RACE', art = ART.SHOWDOWN, badge = 'LOCKED', disabled = true, desc = 'To open: ' .. tostring(short or why),
      info = padInfo('The title race: 1 v 1 against the champion, ' .. vs .. '.  To open: ' .. why),
      act = function() S.message = 'The title race is locked. To open it: ' .. why; return true end }
  end
  -- (the badge names the opponent, or CHAMPION once you hold the title; the rest is in the info)
  return { title = 'TITLE RACE', art = ART.SHOWDOWN, badge = st and st.won and 'CHAMPION' or ('VS ' .. vs:upper()),
    info = padInfo(('%s1 v 1 against %s, 6 laps, no points: win and you are the %s champion.%s'):format(
      (st and st.won) and 'You hold the title: defend it.  ' or '', vs, cls.name, st and (('  Tries: %d.'):format(st.tries or 0)) or '')),
    act = function()
      local ev = TI.event(cls.key)
      local ok, why2 = R.launch(ev, cls.key, myVehicle().key, picksFor(cls.key), modsFor())
      if ok then S.message = nil; return 'launched' end
      S.message = why2
      return true
    end }
end

SCREENS.home = function()
  local items = {}
  -- v0.9: no cup is alive at HOME (one still here was left by a race that never loaded, or the page closed on the
  -- standings): it is dropped, logged
  K.drop('at the home screen')
  for _, c in ipairs(K.classes()) do
    local golds, trophies, total = classStats(c.key)
    local open, why, short = PR.classOpen(K.data, c.key)
    if not open then
      items[#items + 1] = { title = c.name:upper(), art = ART.class(c.key), badge = 'LOCKED', disabled = true,
        desc = 'To open: ' .. tostring(short or why), info = padInfo((c.blurb or '') .. '\n' .. c.name .. ' is locked.  To open it: ' .. why, 2),
        act = function() S.message = c.name .. ' is locked. To open it: ' .. why; return true end }
    else
      local champ = championLine(c.key)
      items[#items + 1] = { title = c.name:upper(), art = ART.class(c.key),
        badge = golds > 0 and ('%d / %d GOLD'):format(golds, total) or (trophies > 0 and ('%d / %d TROPHIES'):format(trophies, total) or nil),
        -- v0.14.1: only YOUR title on the tile ('Champion: GRIFF HALLORAN' wrapped onto two lines in game, 2026-11-11);
        -- the champion's name is in the info line
        desc = (champ == 'Champion: YOU') and champ or nil,
        info = padInfo((c.blurb or '') .. '\n' .. ('%s: parts level %d, abilities %d.  Gold %d / %d, trophies %d / %d.%s'):format(c.name,
          c.parts or 0, c.abilities or 1, golds, total, trophies, total, rivalInfo(c.key, champ)), 2),
        act = function() S.class = c.key; K.data.class = c.key; K.save(); return go('cups') end }
    end
  end
  -- v0.15: the racer and their vehicle type (the racer decides the vehicle)
  local veh = myVehicle()
  local who = racerName() or '?'
  local vtext = (RC and RC.vehicleText) and RC.vehicleText() or veh.name
  items[#items + 1] = { title = 'GARAGE', art = ART.vehicle(veh.key),
    desc = who .. '\n' .. vtext,
    info = padInfo('Your racer, abilities and tune-ups.\n' .. who .. '  -  ' .. vtext:lower() .. '  -  '
      .. picksText(picksFor(K.data.class or '50'), levelNow()):gsub('  /  ', ', '), 2),
    act = function() return go('garage') end }
  items[#items + 1] = { title = 'RESET PROGRESS', art = 'T_UI_FE_Tile_02', desc = 'Asks first',
    info = padInfo('Start over: clears every trophy, record and best finish. Your garage is kept. A backup of the save is made first.', 2),
    act = function()
      S.confirm = { text = 'Reset all progress? Every trophy and best finish will be cleared. Your garage is kept. (A backup of the save is made first.)',
        back = 'home', noFirst = true,
        yes = function()
          local b = K.reset()
          S.message = b and 'Progress reset - a clean start' or 'Could not back up the save - nothing was reset'
        end }
      return go('confirm')
    end }
  return { key = 'home', title = 'GALACTIC GRAND PRIX',
    lines = { { 'The Galactic League: four divisions, a season of cups in each.', 22, U.WHITE },
      { ('Races %d        Cups finished %d'):format(K.data.races, K.data.cups), 18 }, msgLine() },
    items = items, info = true }
end

-- the cups of a class, on one page (v0.11): the five planet cups, then the finale (the Galactic Cup), then the
-- title race
local function cupsInOrder()
  local out = {}
  for _, c in ipairs(K.cups()) do if not c.final then out[#out + 1] = c end end
  for _, c in ipairs(K.cups()) do if c.final then out[#out + 1] = c end end
  return out
end
local function planetBadge(cup, classKey)
  local ps = K.cupPlanets and K.cupPlanets(cup, classKey) or {}
  if #ps == 1 then return ps[1]:upper() end
  if #ps > 1 then return (#ps .. ' PLANETS') end
  return nil
end
-- a cup's conditions at a class, for the tile and the info: 'Night, wet' (nil: none)
local function condText(cup, classKey)
  local list = K.cupConditions(cup, classKey)
  if #list == 0 then return nil end
  local s = table.concat(list, ', '):lower()
  return s:sub(1, 1):upper() .. s:sub(2)
end
-- the focused cup's info: a first line with your best (or `head`: what opens it) and the conditions summed up (so a
-- snow or scorching cup shows before Select), then its races at this class with planet, kind and laps (the title
-- names the conditions) and your records at this class
local function cupInfo(cup, classKey, head)
  local out = {}
  local cond = condText(cup, classKey)
  out[1] = (head or bestText(classKey, cup.key) .. ((K.perfect and K.perfect(classKey, cup.key)) and '  -  PERFECT CUP' or ''))
    .. (cond and ('.  Conditions: ' .. cond) or '')
  for i, r in ipairs(K.races(cup, classKey)) do
    local line = K.raceLine and K.raceLine(r) or r.title
    local rec = K.recordFor and K.recordFor(classKey, r.path)
    if rec and K.fmtTime then line = line .. ('     best %s'):format(rec.time and K.fmtTime(rec.time) or 'no time yet') .. (rec.lap and (' / lap ' .. K.fmtTime(rec.lap)) or '') end
    out[#out + 1] = ('%d  %s'):format(i, line)
  end
  return table.concat(out, '\n')
end

SCREENS.cups = function()
  local cls = K.class(S.class) or K.classes()[1]
  local items = {}
  for _, cup in ipairs(cupsInOrder()) do
    local open, why, short = PR.cupOpen(K.data, cls.key, cup.key)
    if not open then
      items[#items + 1] = { title = cup.name, art = ART.cup(cup, myVehicle().key) or cup.art, badge = 'LOCKED', disabled = true,
        desc = 'To open: ' .. tostring(short or why), info = padInfo(cupInfo(cup, cls.key, 'To open: ' .. why)),
        act = function() S.message = cup.name .. ' is locked at ' .. cls.name .. '. To open it: ' .. why; return true end }
    else
      local mIcon, mColor = medal(cls.key, cup.key)
      local perfect = K.perfect and K.perfect(cls.key, cup.key)
      -- the tile: your best when the badge doesn't show it (a trophy does), then the conditions; when both don't fit,
      -- the conditions (the best is in the info line too)
      local b = K.best(cls.key, cup.key)
      local bestLine = perfect and 'Perfect cup' or (not b and 'Not raced yet') or (not TROPHY_NAME[b] and ('Best: ' .. ordinal(b))) or nil
      local cond = condText(cup, cls.key)
      local it = { title = cup.name, art = ART.cup(cup, myVehicle().key) or cup.art,
        badge = trophyBadge(cls.key, cup.key) or planetBadge(cup, cls.key), icon = mIcon, iconColor = mColor,
        info = padInfo(cupInfo(cup, cls.key)),
        act = function()
          local veh = myVehicle()
          K.startCup(cls.key, cup.key, veh.key, picksFor(cls.key), modsFor())
          local res = launchNext()
          if res ~= 'launched' then K.forfeit() end -- couldn't start: no cup left half-begun
          return res
        end }
      it.desc = (bestLine and cond) and (bestLine .. '\n' .. cond) or bestLine or cond
      if bestLine and cond and not U.tileFits(it, (cfg.CupsLayout or {}).w) then it.desc = cond end
      items[#items + 1] = it
    end
  end
  local tt = titleTile(cls)
  if tt then items[#items + 1] = tt end
  local veh = myVehicle()
  return { key = 'cups', title = cls.name:upper() .. '  -  CUPS',
    lines = { { cls.blurb or '', 22, U.WHITE },
      { ('%s, every part at level %d, abilities level %d.  Select a cup to start it: the first race launches straight away.'):format(
      veh.name, cls.parts or 0, cls.abilities or 1), 18 }, msgLine() },
    items = items, info = true, layout = cfg.CupsLayout }
end

-- the garage: one tile per thing you can change; Select cycles it (v0.8: no pick screens)
local function cyclePick(i)
  local level = levelNow()
  local picks = picksFor(K.data.class or '50')
  local choices = AB.choices(i, level, picks)
  if #choices == 0 then return nil end
  local at = 0
  local cur = AB.rel(picks[i], level)
  for k, o in ipairs(choices) do if o.rel == cur then at = k end end
  local nxt = choices[at % #choices + 1]
  local np = {}
  for k = 1, 4 do np[k] = picks[k] end
  np[i] = nxt.pick
  K.data.picks = AB.normalize(np, level)
  K.save()
  return nxt.name
end
SCREENS.garage = function()
  local level = levelNow()
  local picks = picksFor(K.data.class or '50')
  local items = {}
  -- v0.15 (TASKS.md A6): no VEHICLE tile - the racer decides the vehicle; the RACER tile names it. A locked racer
  -- (Kestar Bool until the 150cc title) is skipped by Select and named in the info line with how to unlock him.
  if RC and RC.current then
    local r = RC.current() or {}
    local vtext = RC.vehicleText and RC.vehicleText() or '?'
    local locks = {}
    for _, o in ipairs(RC.list()) do
      if RC.locked and RC.locked(o) then locks[#locks + 1] = ('  %s is locked. %s.'):format(o.name, RC.unlockText(o)) end
    end
    items[#items + 1] = { title = (r.name or 'RACER'):upper(), art = (r.key == 'Antagonist') and ART.SHOWDOWN or 'T_UI_FE_Tile_01', badge = 'RACER',
      desc = vtext, info = ('%s - %s:  %s.  Select: next racer.'):format(r.name or '?', vtext:lower(), r.line or '') .. table.concat(locks),
      act = function()
        local n = RC.cycle(1)
        S.message = n and ('Racing as %s (%s)'):format(n.name, RC.vehicleText(n.key):lower()) or nil
        return true
      end }
  end
  for i = 1, 4 do
    local lab = AB.label(picks[i], level)
    items[#items + 1] = { title = (lab or '?'):upper(), art = ART.ABILITIES, badge = 'ABILITY ' .. i,
      desc = SELECT_NEXT,
      info = ('Ability %d: %s  -  %s.  Levels up with the class (branches from 100cc).'):format(i, lab or '?', AB.blurb(picks[i])),
      act = function() local n = cyclePick(i); if n then S.message = n .. ' picked' end; return true end }
  end
  local list = modsFor()
  local slots, fromClass = 0, {}
  for _, c in ipairs(K.classes()) do
    local n = MS.slotsFor(c.key)
    for s = slots + 1, n do fromClass[s] = c.name end
    if n > slots then slots = n end
  end
  for i = 1, slots do
    local e = MS.effect(list[i])
    items[#items + 1] = { title = e and e.name:upper() or 'NONE', art = e and (ART.modGroup and ART.modGroup(e.group)) or ART.MODS,
      badge = 'TUNE-UP ' .. i, desc = e and SELECT_NEXT or 'Select to fit one',
      info = (e and (e.name .. ':  ' .. (e.line or e.desc or '') .. '.') or ('Tune-up slot %d is empty.  Tune-ups change how you race, not how fast.'):format(i))
        .. ('  (Tune-up %d: from %s.)'):format(i, fromClass[i] or '?'),
      act = function()
        if MS.cycle then list[i] = MS.cycle(list, i, 1) end
        K.data.mods = MS.normalize(list); K.save()
        local ne = MS.effect(K.data.mods[i])
        S.message = ne and (ne.name .. ' fitted') or ('Tune-up slot ' .. i .. ' emptied')
        return true
      end }
  end
  return { key = 'garage', title = 'GARAGE',
    lines = { { 'Select a tile to change it.', 20, U.WHITE }, msgLine() },
    items = items, info = true }
end

-- shown in the tab when the multiplayer guard refuses (instead of an empty page)
SCREENS.offline = function()
  return {
    key = 'offline', title = 'GRAND PRIX',
    lines = { { 'The Grand Prix is offline only.', 26, U.WHITE }, { S.blocked or '', 20, U.GOLD },
      { 'Leave the party / stop matchmaking, then come back to this tab.', 18 } },
    items = { { title = 'BACK', art = 'T_UI_FE_Tile_03', desc = 'Back to the main menu', act = function() return 'close' end } },
  }
end

-- a title race's result: no points, just the title
SCREENS.titleResult = function()
  local r = S.result or {}
  local cls = K.class(r.ev and r.ev.class) or { name = '?' }
  local lines = {}
  if r.won then
    lines[#lines + 1] = { ('%s CHAMPION'):format(cls.name:upper()), 44, U.GOLD }
    lines[#lines + 1] = { ('You beat %s in the title race.'):format(r.vs or 'the champion'), 22, U.WHITE }
  else
    lines[#lines + 1] = { 'THE TITLE STAYS WITH ' .. tostring(r.vs or 'the champion'):upper(), 36, U.GREY }
    lines[#lines + 1] = { ('You finished %s.  Come back faster: the title race can be run again.'):format(r.pos and ordinal(r.pos) or 'without finishing'), 22, U.WHITE }
  end
  if r.time and K.fmtTime then lines[#lines + 1] = { ('Your time %s'):format(K.fmtTime(r.time)) .. (r.lap and ('   -   best lap ' .. K.fmtTime(r.lap)) or ''), 18 } end
  return { key = 'titleResult', title = 'TITLE RACE', lines = lines, backdrop = ART.BACKDROP,
    items = { { title = 'CONTINUE', art = ART.SHOWDOWN, desc = 'Back to the cups', icon = r.won and ART.medal(1) or nil, iconColor = r.won and ART.medalColor(1) or nil,
      act = function() return go('cups') end } } }
end

SCREENS.standings = function()
  local r = S.result or {}
  local run = r.run
  local cup = run and K.cup(run.cup) or { name = '?' }
  local spec = SD.spec(r)
  local items = {}
  if K.run() then
    -- v0.9: NEXT RACE only (no LATER: cups cannot be resumed; B asks "Leave the cup?" - handle, below)
    local nxt = K.nextRace()
    local run2 = K.run()
    items[#items + 1] = { title = 'NEXT RACE', art = ART.cup(K.cup(run2.cup), run2.vehicle) or 'T_UI_FE_Tile_Campaign_Hero', badge = ('RACE %d / %d'):format(run2.race, run2.races),
      -- (the badge says which race; the race's name, without its conditions when they don't fit)
      desc = nxt.title, act = launchNext }
    local it = items[#items]
    if not U.tileFits(it) then it.desc = nxt.title:match('^(.-)%s*%(') or nxt.title end
  else
    items[#items + 1] = { title = 'CONTINUE', art = ART.cup(cup, run and run.vehicle) or 'T_UI_FE_Tile_Campaign_Hero', desc = 'Back to the cups',
      icon = r.trophy and ART.medal(TROPHY_INDEX[r.trophy]) or nil, iconColor = r.trophy and ART.medalColor(TROPHY_INDEX[r.trophy]) or nil, act = function() return go('cups') end }
  end
  spec.items = items
  return spec
end

SCREENS.confirm = function()
  local c = S.confirm or { text = '?' }
  local function done(screen) S.screen, S.confirm = screen, nil; return true end
  local yes = { title = 'YES', art = 'T_UI_FE_Tile_01', act = function()
    if c.yes then c.yes() end
    return done(c.after or c.back or 'home')
  end }
  local no = { title = 'NO', art = 'T_UI_FE_Tile_02', act = function() return done(c.back or 'home') end }
  return { key = 'confirm', title = 'CONFIRM', lines = { { c.text, 26, U.WHITE }, msgLine() },
    items = c.noFirst and { no, yes } or { yes, no } }
end

---------------------------------------------------------------------------------------------------------------------
-- showing / closing

-- the hidden Back screen of a tab page: switched off before the page goes (it's an activatable widget)
local function dropBack()
  local b = S.ui and S.ui.back
  if b and alive(b.h) then try(function() b.h:DeactivateWidget() end) end
end

local function close(why)
  dropBack()
  S.ui = nil
  log('[menu] closed (' .. (why or '?') .. ')')
  -- leaving the page = going back to the game's first tab (unless the tab was already left)
  if why ~= 'tab left' and TB.isShown() then TB.selectHome() end
end

local function setFocus(i)
  if not S.ui or #S.ui.items == 0 then return end
  S.focus = (i - 1) % #S.ui.items + 1
  S.focusMem[S.key or ''] = S.focus
  U.focus(S.ui, S.focus)
end

show = function()
  local fe, why = R.atMainMenu()
  local blocked = nil
  if not fe then
    log('[menu] ' .. why)
    -- in our tab, say why rather than leave the page empty (nothing else is built or launched)
    if not (TB.isShown() and why ~= 'not at the main menu') then return end
    blocked = why
  end
  if not tabMode() then log('[menu] the GRAND PRIX tab could not be added to the main menu - see the [tab] lines above'); return end
  if not TB.isShown() then
    -- the page is built when our tab is selected (TB.onEnter); ask for it
    S.pendingScreen = S.screen
    if not TB.select() then log('[menu] the GRAND PRIX tab is not ready yet') end
    return
  end
  dropBack()
  S.ui = nil
  S.screen = S.screen or 'home'
  S.blocked = blocked
  local ok, spec = pcall(SCREENS[blocked and 'offline' or S.screen])
  if not ok then log('[menu] screen error: ' .. tostring(spec)); S.screen = 'home'; spec = SCREENS.home() end
  local sc = TB.current
  if not sc then return end
  local ui = U.build(spec, { tree = sc.tree, panel = sc.panel })
  if not ui then return end
  S.ui, S.key, S.shownAt = ui, spec.key, C.clock
  S.grabs = 0
  -- B on any page: the game turns this invisible screen off, which reads as BACK (tab.lua)
  ui.back = TB.backScreen(sc, sc.panel)
  setFocus(math.min(S.focusMem[spec.key] or 1, #ui.items))
  log(('[menu] %s (%d tiles)'):format(spec.key, #ui.items))
  startLoop()
end

local lastPress = -1e9
local function press(i, how)
  local it = S.ui and S.ui.items[i]
  if not it or not it.act then return end
  -- one press can arrive twice (our key/mouse handling and the game's own button click): act once
  if C.clock - lastPress < 400 then return end
  lastPress = C.clock
  if how then log('[menu] press ' .. i .. ' (' .. how .. ')') end
  local ok, res = pcall(it.act)
  if not ok then log('[menu] tile error: ' .. tostring(res)); return end
  if res == 'close' then S.message = nil; close('exit')
  elseif res == 'launched' then
    dropBack()
    S.ui = nil
    log('[menu] closed (race launched)')
  elseif res then show() end
end

---------------------------------------------------------------------------------------------------------------------
-- input

local BACK = { cups = 'home', garage = 'home', standings = 'cups', titleResult = 'cups' }
-- v0.9: B on the standings while the cup runs (races 1-3) - one confirm: YES forfeits and goes HOME, NO = the standings
local function leaveCup()
  S.confirm = { text = 'Leave the cup? Your points are lost.', back = 'standings',
    yes = function() K.forfeit(); S.message = 'Cup abandoned' end, after = 'home' }
  go('confirm')
  show()
end
-- the page is on the cup's standings (or its "Leave the cup?" question) with the cup alive
local function onCup() return K.run() ~= nil and (S.screen == 'standings' or (S.screen == 'confirm' and S.confirm and S.confirm.back == 'standings')) end
-- open the page (the menu key, and v0.17's boot open): selects the GRAND PRIX tab (show -> TB.select); the page is
-- built when the tab is picked (TB.onEnter). (v0.9: the standings rather than HOME while a cup is alive - HOME would
-- drop the cup)
local function openPage()
  S.message = nil
  if not onCup() then S.screen = 'home' end
  show()
end
local function handle(name)
  if name == 'menu' then
    if S.ui then close('menu key') else openPage() end
    return
  end
  if not S.ui or C.clock - S.shownAt < 350 then return end
  local ti = name:match('^tile:(%d+)$')
  if ti then press(tonumber(ti), 'game click'); return end
  local fi = name:match('^focus:(%d+)$')
  if fi then
    S.focus = tonumber(fi); S.focusMem[S.key or ''] = S.focus
    U.highlight(S.ui, S.focus)
    return
  end
  local cols = (S.ui and S.ui.cols) or U.COLS
  if name == 'left' then setFocus(S.focus - 1)
  elseif name == 'right' then setFocus(S.focus + 1)
  elseif name == 'up' then setFocus(math.max(1, S.focus - cols))
  elseif name == 'down' then setFocus(math.min(#S.ui.items, S.focus + cols))
  elseif name == 'accept' then press(S.focus)
  elseif name == 'back' then
    if S.blocked then close('back')
    elseif S.screen == 'confirm' then S.screen = (S.confirm and S.confirm.back) or 'home'; S.confirm = nil; show()
    elseif S.screen == 'standings' and K.run() then leaveCup()
    elseif BACK[S.screen] then go(BACK[S.screen]); show() else close('back') end
  elseif name == 'click' then
    for i, it in ipairs(S.ui.items) do
      if try(function() return it.btn:IsHovered() end) == true then press(i); return end
    end
  end
end

-- the game's own UI driving our tiles (controller D-pad / A when CommonUI keeps the pad from the poll): follow the
-- tile it has focused, and act on a tile whose selected state flipped (they're toggle buttons, see U.makeToggle)
local loggedSync = false
local function syncGameUI()
  if not S.ui or C.clock - S.shownAt < 350 then return end
  for i, it in ipairs(S.ui.items) do
    if try(function() return it.btn:GetSelected() end) == true then
      try(function() it.btn:SetIsSelected(false, false) end)
      press(i, 'game click')
      return
    end
  end
  -- which tile has the game UI's focus: the one we think first (every tick), the rest every 3rd tick only - each
  -- check is an engine call, and fewer calls are kinder to UE4SS (v0.9.7)
  local function has(it) return TB.hasFocus(it.btn) end
  local focused
  local cur = S.ui.items[S.focus]
  if cur and has(cur) then focused = S.focus
  else
    S.scan = (S.scan or 0) + 1
    if S.scan % 3 ~= 0 and C.clock - S.shownAt >= 1500 then return end
    for i, it in ipairs(S.ui.items) do
      if i ~= S.focus and has(it) then focused = i; break end
    end
  end
  -- the menu may take focus once right after a redraw - give it back to our tile for 1.5 s, then leave the game alone
  -- (up from the top row may legitimately go to the tab bar)
  if not focused and C.clock - S.shownAt < 1500 and C.clock - (S.lastGrab or -1e9) >= 300 then
    S.lastGrab = C.clock
    local it = S.ui.items[S.focus]
    if it then try(function() it.btn:SetFocus() end) end
    S.grabs = (S.grabs or 0) + 1
    if S.grabs <= 2 then log('[menu] tab page: focus to tile ' .. S.focus .. ' (' .. S.grabs .. ')') end
  end
  if focused and focused ~= S.focus then
    if not loggedSync then loggedSync = true; log('[menu] the game\'s UI is moving focus on our tiles') end
    S.focus = focused; S.focusMem[S.key or ''] = focused
    U.highlight(S.ui, focused)
  end
end

---------------------------------------------------------------------------------------------------------------------
-- the tick: runs only while there's something to do

local TICK_MS = 100
local keys = {}
local function busy() return #keys > 0 or S.ui ~= nil or R.run ~= nil or S.openAt ~= nil or R.pendingRestore() end

local function tick()
  C.clock = C.clock + TICK_MS
  -- (v0.13.1: R.menuUp() is a flag, not a lookup - race.lua)
  if R.pendingRestore() and not R.run and R.menuUp() then R.restoreBuild('left over from an earlier race') end
  while #keys > 0 do
    local k = table.remove(keys, 1)
    local ok, err = pcall(handle, k)
    if not ok then log('key error: ' .. tostring(err)) end
  end
  -- tab page: its widgets live in the main menu's tree; check the menu is still there before touching any of them
  if S.ui and not TB.isShown() then S.ui = nil end
  if S.ui then
    if not alive(S.ui.w) or not R.menuUp() then S.ui = nil
    else
      local ok, err = pcall(syncGameUI)
      if not ok then log('[menu] sync error: ' .. tostring(err)) end
      -- B through the hidden Back screen; LT / RT read here; the game does the D-pad and A itself
      if S.ui and S.ui.back and TB.backPressed(S.ui.back) then pcall(handle, 'back') end
    end
  end
  local timing = R.run ~= nil and R.run.phase == 'racing'
  local t0 = timing and R.nowMs() or nil
  local ok, out = pcall(R.watch)
  local t1 = t0 and R.nowMs() or nil
  -- v0.3.4 (stutter): every engine object we touch leaves a small Lua wrapper behind. Collect a little on every
  -- tick so the garbage never builds up into one big collection that freezes a frame (the hitches the owner felt
  -- lined up with our ticks, and only in Grand Prix races).
  if cfg.GcStep ~= false then collectgarbage('step', cfg.GcStepKB or 64) end
  local t2 = t1 and R.nowMs() or nil
  if t2 then pcall(R.perfTick, t1 - t0, t2 - t1) end
  if not ok then log('watch error: ' .. tostring(out))
  elseif out and out.failed and ST.running() then
    -- v0.16: a study job's race never loaded: logged and skipped (no page opened)
    ST.onFailed(out.failed)
  elseif ST.owns(out) then
    -- v0.16: a study job's result: its log line and CSV row; the page stays shut (the next job follows)
    S.result = out
    local okS, errS = pcall(ST.onResult, out)
    if not okS then log('[study] result not written: ' .. tostring(errS)) end
  elseif out and out.failed then
    -- the launch went nowhere: ours back with a message
    S.message = out.failed == 'timeout' and 'The race never loaded - nothing was recorded.' or nil
    if out.failed == 'timeout' and alive(C.first('FrontEndGameMode')) then S.screen = 'cups'; show() end
  elseif out then
    S.result, S.openAt = out, C.clock
    -- cover the main menu while it's rebuilt, so the race results lead straight to the ranking (config HideMenuFlash)
    if cfg.HideMenuFlash ~= false and (out.run or out.titleRace) then pcall(U.cover, true) end
  end
  if S.openAt and C.clock >= S.openAt and not R.run then
    -- the menu is rebuilt after a race: wait for our tab on it, then open the result in the tab
    if TB.ready() then
      S.openAt = nil; S.message = nil
      local run = S.result and S.result.run
      if run then S.class, S.cup = run.class, run.cup
      elseif S.result and S.result.titleRace and S.result.ev then S.class = S.result.ev.class end
      S.screen = run and 'standings' or (S.result and S.result.titleRace) and 'titleResult' or 'cups'
      show()
      if S.ui then pcall(U.cover, false) end -- (else the tab is being selected: TB.onEnter drops the cover once the page is up)
    end
    if S.openAt and C.clock - S.openAt > 30000 then S.openAt = nil; pcall(U.cover, false); log('the GRAND PRIX tab never came back - not opening the result') end
  end
end

-- one permanent game-thread loop (v0.10; it used to start and stop itself - see C.gameLoop)
local looping = false
startLoop = function()
  if looping then return end
  looping = true
  C.gameLoop(TICK_MS, function() if busy() then tick() end end, 'tick')
end
local function queue(action) keys[#keys + 1] = action end -- (key thread: only queue; the game-thread loop handles it)

-- Keys: the game's own UI does arrows / Enter / mouse on our page and Q / E switch its tabs, so only these are ours.
local function bind(keyName, action)
  local k = Key and Key[keyName]
  if not k then log('unknown key ' .. tostring(keyName)); return end
  local ok, err = pcall(RegisterKeyBind, k, function()
    if action ~= 'menu' and action ~= 'probe' and not S.ui then return end
    queue(action)
  end)
  if not ok then log('bind failed ' .. keyName .. ': ' .. tostring(err)) end
end
bind(cfg.MenuKey or 'F6', 'menu')
-- (no hooks: the Underground's v0.7.2-0.8.5 hooked the game's button events; none fired for the pad)
bind('BACKSPACE', 'back')
-- v0.19: NEXT RACE on the results screen's standings (chain.lua reads the flag; only while its panel is up)
do
  local ck = (type(cfg.ChainRaces) == 'table' and cfg.ChainRaces.On == true) and cfg.ChainRaces.Key or nil
  local k = ck and Key and Key[ck]
  if k then
    local CHm = require('chain')
    local ok, err = pcall(RegisterKeyBind, k, function() CHm.key = true end)
    if not ok then log('bind failed ' .. ck .. ': ' .. tostring(err)) end
  end
end

---------------------------------------------------------------------------------------------------------------------
-- the GRAND PRIX tab: our page is built when the tab is picked, and dropped when another tab is
TB.onEnter = function()
  S.screen = S.pendingScreen or S.screen or 'home'
  S.pendingScreen = nil
  show()
  if S.ui then pcall(U.cover, false) end
end
TB.onLeave = function() if S.ui then close('tab left') end end
-- the menu holding our page was freed: drop the page without touching its widgets (they went with it)
TB.onGone = function() S.ui = nil; log('[menu] closed (menu gone)') end
TB.onFail = function() S.ui = nil end

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

-- v0.17 (TASKS.md 11, owner: "i want the game to launch and go directly to the grand prix menu, pressing b would still
-- back out to the main menu"): at the first main menu after the game starts, the GRAND PRIX tab opens by itself on
-- HOME, through the menu key's own path (openPage -> show -> TB.select: our tab picked by its id, never by stepping
-- through the game's tabs, so never MULTIPLAYER). Once per launch: `boot.done` is set the moment it opens or gives
-- up, and nothing sets it back (the mod is loaded once per game start), so a race, B or leaving the tab never
-- reopens it (the result page after a cup race is S.openAt's own flow). It waits for our tab on a settled menu
-- (TB.ready: after "[tab] GRAND PRIX tab added"), for nothing left to put back (parts, abilities, tune-ups, AI config,
-- racer, title: R.pendingRestore) and no cup (dropped at load, K.drop 'at boot'), then BOOT_DELAY_MS more.
-- Never with study.lua jobs pending (the study needs the plain menu). Flags only, apart from TB.ready's check of the
-- menu (only while waiting, a few seconds at boot).
local BOOT_DELAY_MS = 1000
boot = { done = cfg.BootToGrandPrix == false, waitMs = 0, checkMs = nil }
if boot.done then log('[boot] BootToGrandPrix is off: the game\'s own main menu') end
bootPoll = function(dt)
  if boot.checkMs then
    -- (2-3 s after opening: say whether the tab stayed up - the game could pick its own tab late; not retried)
    boot.checkMs = boot.checkMs - dt
    if boot.checkMs <= 0 then
      boot.checkMs = nil
      log(TB.current and TB.current.shown and '[boot] the GRAND PRIX tab is up'
        or '[boot] the GRAND PRIX tab did not stay selected (not tried again)')
    end
  end
  if boot.done then return end
  if not tabMode() then boot.done = true; log('[boot] not opening the GRAND PRIX tab: the tab could not be added'); return end
  -- the player got there first (menu key, picked the tab), or a race / result is under way: nothing to do
  if S.ui or TB.current or R.run or S.openAt then boot.done = true; log('[boot] the GRAND PRIX tab is already open or a race is under way: not opening it'); return end
  if ST.pending() then
    boot.done = true
    log('[boot] not opening the GRAND PRIX tab: study mode has jobs pending (study.lua) - the study needs the plain main menu')
    return
  end
  if R.pendingRestore() or K.run() or not TB.ready() then boot.waitMs = 0; return end
  boot.waitMs = boot.waitMs + (dt or 0)
  if boot.waitMs < BOOT_DELAY_MS then return end
  boot.done = true
  log('[boot] opening the GRAND PRIX tab (BootToGrandPrix)')
  openPage()
  boot.checkMs = 3000
end

-- main menu poll (front end only, 200 ms): finds the menu and keeps our tab on it. v0.13.1: the menu's game mode
-- comes from R.menuPoll (a notification, and a sweep every 2-3 s at most) - it was a lookup every poll (a sweep 5x a
-- second, plus 10x a second from the tick while our page was up)
do
  local seenMenu, ticks = false, 0
  local POLL_MS = 200
  C.gameLoop(POLL_MS, function()
    if R.run then return end
    if not R.menuPoll(POLL_MS) then return end
    if not seenMenu then seenMenu = true end
    -- v0.16.1: [aiset] the AI / pacing assets as they are, once after boot (after any put-back from a crash)
    if not AI.bootRead and not R.pendingRestore() then
      local okA, errA = pcall(AI.bootReadback)
      if not okA then AI.bootRead = true; log('[aiset] read-back failed: ' .. tostring(errA)) end
    end
    -- v0.16: study mode (test-only; nothing but an io.open every 5 s without study.lua)
    local okS, errS = pcall(ST.poll, POLL_MS, studyEnv)
    if not okS then log('[study] poll: ' .. tostring(errS)) end
    ticks = ticks + 1
    if tabMode() then
      if ticks % 5 == 1 then
        local ok, err = pcall(TB.discover)
        if not ok then log('[tab] discover error: ' .. tostring(err)) end
      end
      local ok, err = pcall(TB.update, POLL_MS)
      if not ok then log('[tab] update error: ' .. tostring(err)) end
    end
    local okB, errB = pcall(bootPoll, POLL_MS)
    if not okB then boot.done = true; log('[boot] failed: ' .. tostring(errB)) end
  end, 'poll')
end

startLoop()

-- tests only (test/util.lua sets GU_TEST_CFG): the screen builders and state, so test_tiletext can check the text of
-- every tile every screen can show without clicking through them all
if rawget(_G, 'GU_TEST_CFG') then rawset(_G, 'GU_TEST_SCREENS', { SCREENS = SCREENS, S = S }) end

log(('v%s loaded - the GRAND PRIX tab on the main menu (or %s) opens it'):format(VERSION, cfg.MenuKey or 'F6'))
