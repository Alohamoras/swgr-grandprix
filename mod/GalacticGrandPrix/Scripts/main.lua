-- Galactic Grand Prix: kart-racer-style cups for STAR WARS Galactic Racer (DESIGN.md).
-- The GRAND PRIX tab on the game's main menu (or F6) -> speed class -> cup -> race. Races launch straight away through
-- the game's offline quick race (FrontEndGameMode:LaunchQuickRace) with every part at the class's level.
-- v0.2: cups of 4 races with points for all 12 racers, standings after each race, a trophy at the end.
-- v0.3: your four abilities (v0.3.10: free pick, one per family), the AI racers' four, levels by class.
-- v0.9: cups cannot be resumed (owner): leaving a cup before its last standings loses it.
-- v0.11: one cup per planet with a race list per class (classic / reverse / conditions), the Galactic Cup, the title race.
-- Design: DESIGN.md  Plan: TASKS.md  Save: save.lua  Log: grandprix.log

local VERSION = '0.11.0'

local here = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
local scripts = here:match('^(.*)[/\\][^/\\]+$') or '.'
package.path = scripts .. '/?.lua;' .. package.path
for _, m in ipairs({ 'core', 'config', 'abil', 'cup', 'gp', 'loadout', 'ai', 'race', 'ui', 'tab' }) do package.loaded[m] = nil end

local C = require('core')
C.DIR = scripts:match('^(.*)[/\\][Ss]cripts$') or '.'
local cfg = require('config')
for k, v in pairs(rawget(_G, 'GU_TEST_CFG') or {}) do cfg[k] = v end -- test harness only (test/util.lua)
local K = require('gp')
local R = require('race')
local U = require('ui')
local ART = require('art')
local TB = require('tab')
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
local startLoop -- forward

---------------------------------------------------------------------------------------------------------------------
-- screens: each returns a spec for ui.build; tile `act` functions change state and return true to redraw

local function go(screen) S.screen = screen; S.message = nil; return true end

local CU = require('cup')
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
-- 'Race 3 of 4' / 'Race 4 of 4 - the final race'
local function raceOf(run)
  return ('Race %d of %d%s'):format(run.race, run.races, run.race == run.races and ' - the final race' or '')
end
local function shortName(key) return key == CU.YOU and 'YOU' or key end

-- launch the cup's next race (the cup's own vehicle and class)
local function launchNext()
  local run, ev = K.run(), K.nextRace()
  if not (run and ev) then S.message = 'No cup in progress'; return true end
  local ok, why = R.launch(ev, run.class, run.vehicle, run.picks or picksFor(run.class), run.mods or modsFor())
  if ok then S.message = nil; return 'launched' end
  S.message = why
  return true
end

-- after a race: ONE screen (owner, 2026-11-10: fewer screens) - the ranking by points, as a table: place, racer,
-- points this race, total, places moved. After the last race the same table with the trophy on top.
local GREEN, RED = { 0.45, 0.9, 0.5 }, { 1, 0.5, 0.45 }
local function rankingTable(run)
  local rows = {}
  for _, r in ipairs(CU.table(run)) do
    local move, mc = '', nil
    if r.move and r.move > 0 then move, mc = '+' .. r.move, GREEN
    elseif r.move and r.move < 0 then move, mc = tostring(r.move), RED end
    rows[#rows + 1] = {
      cells = { ordinal(r.rank), shortName(r.key), r.dnf and 'DNF' or (r.raced and ('+' .. r.gain) or '-'), tostring(r.total), move },
      color = r.you and U.GOLD or U.WHITE, colors = { [5] = mc }, highlight = r.you,
    }
  end
  return { size = 20, header = { '', 'RACER', 'THIS RACE', 'POINTS', 'MOVED' },
    cols = { { w = 90, align = 'right' }, { w = 460 }, { w = 220, align = 'right' }, { w = 180, align = 'right' }, { w = 160, align = 'right' } },
    rows = rows }
end

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
-- the info text always takes the same number of lines, so the grid doesn't jump as the focus moves
local INFO_LINES = 5
local function padInfo(text)
  local n = select(2, tostring(text or ''):gsub('\n', '')) + 1
  return tostring(text or '') .. string.rep('\n ', math.max(0, INFO_LINES - n))
end
local function racerName() return RC and RC.displayName and RC.displayName() or nil end
local function levelNow() return AB.levelFor(K.data.class or (K.classes()[1] or {}).key) end
-- the class's champion line (the title races; the racer with most points across its planet cups)
local function championLine(classKey)
  if not TI.on() then return nil end
  local name = TI.champion(classKey)
  return name and ('Champion: ' .. tostring(name):upper()) or nil
end
-- the title race tile on the cups page: locked until a trophy in the Galactic Cup at the class; won = CHAMPION
local function titleTile(cls)
  if not (TI.on() and TI.event(cls.key)) then return nil end
  local st = TI.status(cls.key)
  local open, why = true, nil
  if PR.titleOpen then open, why = PR.titleOpen(K.data, cls.key) end
  why = tostring(why or '?')
  local vs = TI.opponent(cls.key)
  if not open then
    return { title = 'TITLE RACE', art = ART.SHOWDOWN, badge = 'LOCKED', disabled = true, desc = 'To open: ' .. why,
      info = padInfo('The title race: 1 v 1 against the champion, ' .. vs .. '.  To open: ' .. why),
      act = function() S.message = 'The title race is locked. To open it: ' .. why; return true end }
  end
  return { title = 'TITLE RACE', art = ART.SHOWDOWN, badge = st and st.won and 'CHAMPION' or ('VS ' .. vs:upper()),
    desc = (st and st.won) and ('You hold the title\n(defend it: select)') or ('1 v 1 against ' .. vs .. '\nSelect to race'),
    info = padInfo(('1 v 1, 6 laps, no points: win and you are the %s champion.%s'):format(cls.name, st and (('  Tries: %d.'):format(st.tries or 0)) or '')),
    act = function()
      local ev = TI.event(cls.key)
      local ok, why2 = R.launch(ev, cls.key, K.data.vehicle, picksFor(cls.key), modsFor())
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
    local open, why = PR.classOpen(K.data, c.key)
    if not open then
      items[#items + 1] = { title = c.name:upper(), art = ART.class(c.key), badge = 'LOCKED', disabled = true,
        desc = 'To open: ' .. why, info = c.name .. ' is locked.  To open it: ' .. why,
        act = function() S.message = c.name .. ' is locked. To open it: ' .. why; return true end }
    else
      local champ = championLine(c.key)
      items[#items + 1] = { title = c.name:upper(), art = ART.class(c.key),
        badge = golds > 0 and ('%d / %d GOLD'):format(golds, total) or (trophies > 0 and ('%d / %d TROPHIES'):format(trophies, total) or nil),
        desc = (c.blurb or '') .. (champ and ('\n' .. champ) or ''),
        info = ('%s: every part at level %d, abilities level %d.  Gold %d / %d, trophies %d / %d.%s'):format(c.name, c.parts or 0,
          c.abilities or 1, golds, total, trophies, total, champ and ('  ' .. champ) or ''),
        act = function() S.class = c.key; K.data.class = c.key; K.save(); return go('cups') end }
    end
  end
  local veh = K.vehicle(K.data.vehicle)
  local who = racerName()
  items[#items + 1] = { title = 'GARAGE', art = ART.vehicle(veh.key),
    desc = veh.name .. (who and ('\n' .. who) or '') .. '\n' .. picksText(picksFor(K.data.class or '50'), levelNow()):gsub('  /  ', ', '),
    info = 'Your vehicle, racer, abilities and tune-ups.',
    act = function() return go('garage') end }
  items[#items + 1] = { title = 'RESET PROGRESS', art = 'T_UI_FE_Tile_02', desc = 'Start over\n(asks first)',
    info = 'Clears every trophy, record and best finish. Your garage is kept. A backup of the save is made first.',
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
-- the focused cup's info: its races at this class with planet, kind and laps (the title names the conditions, and
-- a first line sums them up, so a snow or scorching cup shows before Select), then your records at this class
local function cupInfo(cup, classKey)
  local out = {}
  local cond = condText(cup, classKey)
  if cond then out[1] = 'Conditions: ' .. cond end
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
    local open, why = PR.cupOpen(K.data, cls.key, cup.key)
    local info = cupInfo(cup, cls.key)
    if not open then
      items[#items + 1] = { title = cup.name, art = ART.cup(cup, K.data.vehicle) or cup.art, badge = 'LOCKED', disabled = true,
        desc = 'To open: ' .. why, info = padInfo('To open: ' .. why .. '\n' .. info),
        act = function() S.message = cup.name .. ' is locked at ' .. cls.name .. '. To open it: ' .. why; return true end }
    else
      local mIcon, mColor = medal(cls.key, cup.key)
      local perfect = K.perfect and K.perfect(cls.key, cup.key)
      items[#items + 1] = { title = cup.name, art = ART.cup(cup, K.data.vehicle) or cup.art,
        badge = trophyBadge(cls.key, cup.key) or planetBadge(cup, cls.key), icon = mIcon, iconColor = mColor,
        desc = bestText(cls.key, cup.key) .. (perfect and '  -  PERFECT' or '') .. '\n' .. (condText(cup, cls.key)
          or (K.races(cup, cls.key)[1] or {}).title or ''),
        info = padInfo(info),
        act = function()
          local veh = K.vehicle(K.data.vehicle)
          K.startCup(cls.key, cup.key, veh.key, picksFor(cls.key), modsFor())
          local res = launchNext()
          if res ~= 'launched' then K.forfeit() end -- couldn't start: no cup left half-begun
          return res
        end }
    end
  end
  local tt = titleTile(cls)
  if tt then items[#items + 1] = tt end
  local veh = K.vehicle(K.data.vehicle)
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
  local veh = K.vehicle(K.data.vehicle)
  items[#items + 1] = { title = veh.name, art = ART.vehicle(veh.key), badge = 'VEHICLE', desc = 'Select: next vehicle',
    info = 'Landspeeder, speeder bike or skim speeder: every cup race takes any of the three.',
    act = function()
      local vs, nxt = K.vehicles(), 1
      for i, v in ipairs(vs) do if v.key == veh.key then nxt = i % #vs + 1 end end
      K.data.vehicle = vs[nxt].key; K.save()
      S.message = vs[nxt].name .. ' selected'
      return true
    end }
  if RC and RC.current then
    local r = RC.current() or {}
    items[#items + 1] = { title = (r.name or 'RACER'):upper(), art = (r.key == 'Antagonist') and ART.SHOWDOWN or 'T_UI_FE_Tile_01', badge = 'RACER',
      desc = (r.line or '') .. '\nSelect: next racer', info = (r.name or '?') .. ':  ' .. (r.line or '') .. '  (the pilot you race as; name, look and voice come with the pilot)',
      act = function()
        local n = RC.cycle(1)
        S.message = n and ('Racing as ' .. n.name) or nil
        return true
      end }
  end
  for i = 1, 4 do
    local lab = AB.label(picks[i], level)
    items[#items + 1] = { title = (lab or '?'):upper(), art = ART.ABILITIES, badge = 'ABILITY ' .. i,
      desc = AB.blurb(picks[i]) .. '\nSelect: next',
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
      badge = ('TUNE-UP %d  -  FROM %s'):format(i, (fromClass[i] or '?'):upper()),
      desc = (e and (e.line or e.desc) or 'Select to fit one') .. '\nSelect: next',
      info = e and (e.name .. ':  ' .. (e.line or e.desc or '')) or ('Tune-up slot %d is empty.  Tune-ups change how you race, not how fast.'):format(i),
      act = function()
        if MS.cycle then list[i] = MS.cycle(list, i, 1) end
        K.data.mods = MS.normalize(list); K.save()
        local ne = MS.effect(K.data.mods[i])
        S.message = ne and (ne.name .. ' fitted') or ('Tune-up slot ' .. i .. ' emptied')
        return true
      end }
  end
  return { key = 'garage', title = 'GARAGE',
    lines = { { 'Select a tile to change it.  Kept for every cup until you change it; a cup keeps what it started with.', 20, U.WHITE }, msgLine() },
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
  local ev = r.ev or { title = '?' }
  local run = r.run
  local cup = run and K.cup(run.cup) or { name = '?' }
  local cls = run and K.class(run.class) or { name = '?' }
  local lines = {}
  if r.cupOver then
    lines[#lines + 1] = { r.trophy and (r.trophy .. ' TROPHY') or ('%s PLACE'):format(ordinal(r.rank or 0):upper()), 44, r.trophy and U.GOLD or U.GREY }
    lines[#lines + 1] = { ('%s   -   %s   -   %d points%s%s'):format(cup.name, cls.name, r.pts or 0, r.newBest and '   -   NEW BEST' or '',
      r.perfect and '   -   PERFECT CUP' or ''), 22, U.WHITE }
    if r.unlocked and #r.unlocked > 0 then
      lines[#lines + 1] = { 'UNLOCKED:  ' .. table.concat(r.unlocked, '   -   '), 24, U.GOLD }
    end
  else
    lines[#lines + 1] = { ('%s   -   %s   -   race %d of %d'):format(cup.name, ev.title, ev.race or 0, run and run.races or 4), 22, U.WHITE }
  end
  local you = ('You: %s in this race'):format(r.pos and ordinal(r.pos) or 'did not finish')
  if r.time and K.fmtTime then you = you .. ('   -   %s'):format(K.fmtTime(r.time)) .. (r.lap and ('  (best lap %s)'):format(K.fmtTime(r.lap)) or '') end
  lines[#lines + 1] = { you, 18 }
  if r.newRecord and K.fmtTime then
    lines[#lines + 1] = { ('NEW RECORD  %s%s'):format(K.fmtTime(r.time), r.oldTime and ('   (was %s)'):format(K.fmtTime(r.oldTime)) or ''), 22, U.GOLD }
  elseif r.newLap and K.fmtTime and r.lap then
    lines[#lines + 1] = { ('NEW BEST LAP  %s'):format(K.fmtTime(r.lap)), 20, U.GOLD }
  end
  local items = {}
  if K.run() then
    -- v0.9: NEXT RACE only (no LATER: cups cannot be resumed; B asks "Leave the cup?" - handle, below)
    local nxt = K.nextRace()
    local run2 = K.run()
    items[#items + 1] = { title = 'NEXT RACE', art = ART.cup(K.cup(run2.cup), run2.vehicle) or 'T_UI_FE_Tile_Campaign_Hero', badge = ('RACE %d / %d'):format(run2.race, run2.races),
      desc = ('%s\n%s (%s)'):format(raceOf(run2), nxt.title, nxt.kind or ''), act = launchNext }
  else
    items[#items + 1] = { title = 'CONTINUE', art = ART.cup(cup, run and run.vehicle) or 'T_UI_FE_Tile_Campaign_Hero', desc = 'Back to the cups',
      icon = r.trophy and ART.medal(TROPHY_INDEX[r.trophy]) or nil, iconColor = r.trophy and ART.medalColor(TROPHY_INDEX[r.trophy]) or nil, act = function() return go('cups') end }
  end
  return { key = 'standings', title = r.cupOver and 'CUP RESULT' or 'STANDINGS', lines = lines,
    table = run and rankingTable(run) or nil, items = items, backdrop = ART.BACKDROP }
end

SCREENS.confirm = function()
  local c = S.confirm or { text = '?' }
  local function done(screen) S.screen, S.confirm = screen, nil; return true end
  local yes = { title = 'YES', art = 'T_UI_FE_Tile_01', desc = 'Yes', act = function()
    if c.yes then c.yes() end
    return done(c.after or c.back or 'home')
  end }
  local no = { title = 'NO', art = 'T_UI_FE_Tile_02', desc = 'Cancel', act = function() return done(c.back or 'home') end }
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
local function handle(name)
  if name == 'menu' then
    -- (v0.9: the menu key reopens the standings rather than HOME while a cup is alive - HOME would drop the cup)
    if S.ui then close('menu key') else S.message = nil; if not onCup() then S.screen = 'home' end; show() end
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
  if R.pendingRestore() and not R.run and alive(C.first('FrontEndGameMode')) then R.restoreBuild('left over from an earlier race') end
  while #keys > 0 do
    local k = table.remove(keys, 1)
    local ok, err = pcall(handle, k)
    if not ok then log('key error: ' .. tostring(err)) end
  end
  -- tab page: its widgets live in the main menu's tree; check the menu is still there before touching any of them
  if S.ui and not TB.isShown() then S.ui = nil end
  if S.ui then
    if not alive(S.ui.w) or not alive(C.first('FrontEndGameMode')) then S.ui = nil
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

-- main menu poll (front end only, 200 ms): finds the menu and keeps our tab on it
do
  local seenMenu, ticks = false, 0
  local POLL_MS = 200
  C.gameLoop(POLL_MS, function()
    if R.run then return end
    local fe = C.cached('FrontEndGameMode', 2)
    if not alive(fe) then return end
    if not seenMenu then seenMenu = true end
    ticks = ticks + 1
    if tabMode() then
      if ticks % 5 == 1 then
        local ok, err = pcall(TB.discover)
        if not ok then log('[tab] discover error: ' .. tostring(err)) end
      end
      local ok, err = pcall(TB.update, POLL_MS)
      if not ok then log('[tab] update error: ' .. tostring(err)) end
    end
  end, 'poll')
end

startLoop()

log(('v%s loaded - the GRAND PRIX tab on the main menu (or %s) opens it'):format(VERSION, cfg.MenuKey or 'F6'))
