-- Galactic Grand Prix: kart-racer-style cups for STAR WARS Galactic Racer (DESIGN.md).
-- The GRAND PRIX tab on the game's main menu (or F6) -> speed class -> cup -> race. Races launch straight away through
-- the game's offline quick race (FrontEndGameMode:LaunchQuickRace) with every part at the class's level.
-- v0.2: cups of 4 races with points for all 12 racers, standings after each race, a trophy at the end.
-- v0.3: your four abilities (v0.3.10: free pick, one per family), the AI racers' four, levels by class.
-- v0.9: cups cannot be resumed (owner): leaving a cup before its last standings loses it.
-- v0.11: one cup per planet with a race list per class (classic / reverse / conditions), the Galactic Cup, the title race.
-- v0.16: study mode (test-only AI study races; removed after v0.21.0, kept in attic/).
-- v0.17: the game boots straight into the GRAND PRIX tab (HOME), once per launch (config BootToGrandPrix).
-- v0.19: cups without the main menu: the standings over the game's results screen, NEXT RACE from there (chain.lua).
-- v0.19.1: NEXT RACE goes via the menu under the cover (the reset route off; removed after v0.21.0, kept in attic/).
-- v0.20: a rival from the first race, marked on every standings; the cup result a screen of its own; HOME's Next: line;
-- the game's footer hidden on our tab; a dark strip behind tile labels (TASKS "Next" 3 and 4, docs/menu-review).
-- v0.21 (owner, OWNER.md "Done" 2026-11-11): no rival; the title race a 1 v 1 against the class leader on a normal
-- track (two-car grid); Kestar Bool the final boss after 150cc (v0.26: after Ace); less clutter (no Next: line, no blurbs, no grey page
-- backdrop); RESET clears everything behind two questions; CONTINUE after a cup back to that cup; only NEXT RACE on the
-- results screen (B there: leave the cup).
-- v0.26 (owner, 2026-11-12): three leagues (RIFF-RAFF, CHALLENGER, ACE) replace the four cc classes - an old save gets a
-- clean start; every cup is 4 races drawn at random from its planet's pool when you pick it (the start screen shows
-- them), the Galactic Cup 4 from 4 planets. (The code and the save keep the word "class" for a league.)
-- Design: DESIGN.md  Plan: TASKS.md  Save: save.lua  Log: grandprix.log

local VERSION = '0.32.5'

local here = (debug.getinfo(1, 'S').source or ''):gsub('^@', '')
local scripts = here:match('^(.*)[/\\][^/\\]+$') or '.'
package.path = scripts .. '/?.lua;' .. package.path
for _, m in ipairs({ 'core', 'config', 'abil', 'cup', 'title', 'racer', 'prog', 'gp', 'loadout', 'ai', 'race', 'ui', 'tab', 'standings', 'chain' }) do package.loaded[m] = nil end

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

-- v0.26: the cup draw's randomness (gp.lua K.draw), seeded once per load
math.randomseed(os.time())
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
  class = nil,       -- league key (v0.26)
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
local boot, bootPoll -- v0.17 boot into the Grand Prix (below the input)

---------------------------------------------------------------------------------------------------------------------
-- screens: each returns a spec for ui.build; tile `act` functions change state and return true to redraw

local function go(screen) S.screen = screen; S.message = nil; return true end

local CU = require('cup')
local AB = require('abil')
local PR = require('prog')
local MS = require('modsel')
local RC -- (racer.lua, loaded below; picksFor reads it once the file has finished loading)

-- your four picks, made valid for a class's level (and kept in the save).
-- A pilot you have not built a kit for yet gets that pilot's signature four (the kit their bot races with).
-- Edits stay until the pilot changes.
local function picksFor(classKey)
  local who = RC and RC.current and (RC.current() or {}).key
  if who and K.data.picksRacer ~= who then
    -- v0.31: a save from before the signature kits (no picksRacer yet) keeps its four - they become this pilot's;
    -- only a CHANGE of pilot starts the signature kit (PR #1 reset every player's picks on the upgrade)
    if K.data.picksRacer == nil and type(K.data.picks) == 'table' then
      log(('[racer] your saved abilities kept as %s\'s kit (v0.31)'):format(who))
    else
      K.data.picks = AB.racerPicks(who)
    end
    K.data.picksRacer = who
    K.save()
  end
  local p = AB.normalize(K.data.picks, AB.levelFor(classKey))
  K.data.picks = p
  return p
end
-- your mods (four slots), made valid and kept in the save (v0.4)
local function modsFor()
  K.data.mods = MS.normalize(K.data.mods)
  return K.data.mods
end
local TROPHY_NAME = { 'GOLD', 'SILVER', 'BRONZE' }
local TROPHY_INDEX = { GOLD = 1, SILVER = 2, BRONZE = 3 }
-- v0.7: the trophy's medal in the cup tile's icon slot
local function medal(classKey, cupKey)
  local b = K.best(classKey, cupKey)
  if not (b and TROPHY_NAME[b]) then return nil end
  return ART.medal(b), ART.medalColor(b)
end

-- launch the cup's next race (the cup's own vehicle and class)
local function cupArgs(run) return run.class, run.vehicle, run.picks or picksFor(run.class), run.mods or modsFor() end
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
--   Level 1 HOME: the leagues (v0.26: three), RESET PROGRESS. B leaves the tab.
--   Level 2 CUPS (a class): the five planet cups, the GALACTIC CUP and the TITLE RACE on one page (4 + 3, v0.11;
--     v0.21: + KESTAR BOOL at Ace once its title is won, 4 + 4); focusing a cup shows its planet's tracks (v0.26)
--     ; Select draws its races and opens the start screen. No cup page.
--   Level 2 GARAGE: vehicle, racer, four abilities, tune-ups - Select cycles the option in place. No pick screens.
-- v0.9: a cup lives from its first race's launch to the standings of its last race, and nowhere else: the standings
--   after races 1-3 offer NEXT RACE only; B there asks "Leave the cup?" (YES forfeits and goes HOME). No CONTINUE /
--   QUIT CUP tiles, no IN PROGRESS cup tile, no LATER. HOME never shows with a cup alive (K.drop).

RC = (function() local ok, m = pcall(require, 'racer'); return ok and m or nil end)()
local TI = require('title')
-- the info text always takes the same number of lines on a screen, so the grid doesn't jump as the focus moves
-- (cups: 5; HOME: 1)
local INFO_LINES = 5
local function padInfo(text, lines)
  local n = select(2, tostring(text or ''):gsub('\n', '')) + 1
  return tostring(text or '') .. string.rep('\n ', math.max(0, (lines or INFO_LINES) - n))
end
-- v0.14 (TASKS.md A7): a tile shows a short name and at most a short second line (ui.lua U.FIT, test_tiletext); the
-- long text (effects, bios, blurbs, what opens a lock) is in the focused tile's info line
local function racerName() return RC and RC.displayName and RC.displayName() or nil end
-- the category this race launches with: your pick, or the current pilot's own when you have not picked
local function myVehicle()
  if RC and RC.chosenVehicle then return RC.chosenVehicle() end
  return (RC and RC.vehicle) and RC.vehicle() or K.vehicle('car')
end
-- the league picked last (the garage's ability level and tune-up slots), the first league before any pick
local function curLeague() return K.data.class or (K.leagues()[1] or {}).key end
local function levelNow() return AB.levelFor(curLeague()) end
local function launchTo(ev, classKey)
  local ok, why = R.launch(ev, classKey, myVehicle().key, picksFor(classKey), modsFor())
  if ok then S.message = nil; return 'launched' end
  S.message = why
  return true
end
-- the cups of a class, on one page (v0.11): the five planet cups, then the finale (the Galactic Cup), then the
-- title race
local function cupsInOrder()
  local out = {}
  for _, c in ipairs(K.cups()) do if not c.final and not c.rally then out[#out + 1] = c end end
  for _, c in ipairs(K.cups()) do if c.final then out[#out + 1] = c end end
  for _, c in ipairs(K.cups()) do if c.rally then out[#out + 1] = c end end -- (v0.30: the Rally Cup, drawn last on the cups page)
  return out
end
-- v0.23: a racer's face from config Portraits (a game texture path; v0.31: the 256 px MainIcon of each racer's
-- CharacterDef, read from the game data - nothing shipped). nil when unset.
local function portrait(key)
  if not key then return nil end
  local p = (cfg.Portraits or {})[key]
  if type(p) == 'string' and p ~= '' then return p end
  return nil
end
-- v0.24 (owner: pictures, not words on tiles): a locked tile's lock, a perfect cup's star (ui.lua U.decorate)
local function lockCorner() return { { ART.LOCK, ART.LOCK_COLOR } } end
-- a race to start from the garage (v0.24: the garage is the start screen of every cup, title race and boss race):
-- S.start = { kind = 'cup' | 'title' | 'boss', class, cup, draw }
-- v0.26: picking a cup draws its four races (gp.lua K.draw) - the start screen shows them, START races exactly those
-- (they go into the cup run in the save); B and picking the cup again draws again
local startLaunch -- (below, with the garage)
local function toStart(kind, classKey, cupKey)
  S.start = { kind = kind, class = classKey, cup = cupKey }
  if kind == 'cup' then
    S.start.draw = K.draw(cupKey)
    local names = {}
    for i, r in ipairs(S.start.draw) do names[i] = r.title end
    log(('[cup] %s %s drawn: %s'):format(K.leagueName(classKey), cupKey, table.concat(names, ' / ')))
  end
  -- (config StartScreen = false: straight to the race, the v0.23 way - the GARAGE tile is back on HOME)
  if cfg.StartScreen == false then return startLaunch() end
  S.focusMem.garage = nil -- (opens on START)
  return go('garage')
end
-- the title race tile on the cups page (v0.21): a 1 v 1 against the class leader on a normal track; locked until a
-- trophy in the Galactic Cup at the class; won = CHAMPION. The tile names the opponent ('vs Biddy Blas').
local function titleTile(cls)
  if not TI.on() then return nil end
  local ev = TI.event(cls.key)
  if not ev then return nil end
  local st = TI.status(cls.key)
  local open, why, short = true, nil, nil
  if PR.titleOpen then open, why, short = PR.titleOpen(K.data, cls.key) end
  why = tostring(why or '?')
  local vs = ev.vs or '?'
  if not open then
    return { title = 'TITLE RACE', art = ART.SHOWDOWN, corner = lockCorner(), disabled = true, desc = 'To open: ' .. tostring(short or why),
      info = padInfo('To open: ' .. why),
      act = function() S.message = 'The title race is locked. To open it: ' .. why; return true end }
  end
  local laps = tonumber(ev.laps)
  -- (v0.24: a gold medal once won, no CHAMPION badge)
  local won = st and st.won
  local face = portrait(ev.opponent)
  return { title = 'TITLE RACE', art = ART.SHOWDOWN, desc = 'vs ' .. vs,
    glyph = face and { face, { 1, 1, 1 }, side = 'left' } or nil, -- (v0.31: the opponent's face on the left)
    icon = won and ART.medal(1) or nil, iconColor = won and ART.medalColor(1) or nil,
    info = padInfo(('1 v 1 against %s on %s%s: win and you are the %s champion.'):format(vs, ev.title,
      laps and (laps == 1 and ', a sprint' or (', %d laps'):format(laps)) or '', cls.name)),
    act = function() return toStart('title', cls.key) end }
end
-- v0.21: the final boss tile (Kestar Bool in the Stadium Showdown) on the boss class's cups page once its title is won
local function bossTile(cls)
  if not (TI.bossOn() and cls.key == TI.bossClass() and TI.bossOpen(K.data)) then return nil end
  local beaten = TI.bossBeaten(K.data)
  local face = portrait('Antagonist')
  return { title = 'KESTAR BOOL', art = ART.SHOWDOWN, desc = 'Final boss',
    glyph = face and { face, { 1, 1, 1 }, side = 'left' } or nil,
    icon = beaten and ART.medal(1) or nil, iconColor = beaten and ART.medalColor(1) or nil,
    info = padInfo(beaten and 'You beat Kestar Bool: he races for you now (the garage). Run it again any time.'
      or 'The final boss: 1 v 1 against Kestar Bool in the stadium, 6 laps. Beat him to race as him.'),
    act = function() return toStart('boss', cls.key) end }
end

SCREENS.home = function()
  local items = {}
  -- v0.9: no cup is alive at HOME (one still here was left by a race that never loaded, or the page closed on the
  -- standings): it is dropped, logged
  K.drop('at the home screen')
  for _, c in ipairs(K.leagues()) do
    local open, why, short = PR.classOpen(K.data, c.key)
    -- (v0.27: no speed chevrons - they read as progress beside the medals; the focused poster says who races here)
    if not open then
      items[#items + 1] = { title = c.name:upper(), art = ART.league(c.key), corner = lockCorner(), disabled = true,
        desc = 'To open: ' .. tostring(short or why), info = padInfo('To open: ' .. why, 1),
        act = function() S.message = c.name .. ' is locked. To open it: ' .. why; return true end }
    else
      -- v0.24 (owner: progress on the tile, prettier): a row of medals, one per cup in the cups page's order, each
      -- your best (a faint grey one: no trophy yet), then a star for the title (gold once won)
      local pips = {}
      for _, cup in ipairs(cupsInOrder()) do
        local b = K.best(c.key, cup.key)
        if b and b <= 3 then pips[#pips + 1] = { ART.medal(b), ART.medalColor(b) }
        else pips[#pips + 1] = { ART.medal(1), ART.GREY, 0.35 } end
      end
      local st = TI.on() and TI.status(c.key)
      local won = type(st) == 'table' and st.won
      pips[#pips + 1] = won and { ART.STAR, ART.medalColor(1) } or { ART.STAR, ART.GREY, 0.35 }
      items[#items + 1] = { title = c.name:upper(), art = ART.league(c.key), pips = pips, classKey = c.key,
        desc = c.tagline,
        -- (v0.21, owner: less clutter - no blurb, no counts the tile already shows)
        info = padInfo('', 1), -- (v0.22: no parts / abilities line)
        act = function() S.class = c.key; K.data.class = c.key; K.save(); return go('cups') end }
    end
  end
  -- (v0.24: no GARAGE tile - the garage is the start screen of every race, after its cup; config StartScreen = false
  -- brings the v0.23 tile back)
  if cfg.StartScreen == false then
    local veh = myVehicle()
    local vtext = (RC and RC.vehicleText) and RC.vehicleText() or veh.name
    items[#items + 1] = { title = 'GARAGE', art = ART.vehicle(veh.key), desc = (racerName() or '?') .. '\n' .. vtext,
      info = padInfo('', 1), act = function() S.start = nil; return go('garage') end }
  end
  -- v0.21 (owner): RESET clears everything, titles included, behind two questions (NO first on both); the garage stays
  items[#items + 1] = { title = 'RESET PROGRESS', art = 'T_UI_FE_Tile_02',
    info = padInfo('', 1),
    act = function()
      S.confirm = { text = 'Reset all progress? Every trophy, record and title is cleared.', back = 'home', noFirst = true,
        yes = function()
          return { text = 'Are you sure? This can\'t be undone.', back = 'home', noFirst = true,
            yes = function()
              local b = K.reset()
              S.message = b and 'Progress reset - a clean start' or 'Could not back up the save - nothing was reset'
            end }
        end }
      return go('confirm')
    end }
  -- v0.20 (menu review 4a): the focus starts on the class you last raced (show() uses spec.focus when the page has no
  -- remembered focus: openPage clears it). v0.21 (owner): no "Next:" line.
  local last = (K.data.last and K.data.last.class) or K.data.class
  local focus
  for i, it in ipairs(items) do if it.classKey and it.classKey == last and not it.disabled then focus = i end end
  return { key = 'home', title = '', lines = { msgLine() }, items = items, info = true, focus = focus,
    rows = cfg.HomeRows, center = cfg.HomeRows ~= nil }
end

-- the focused cup's info (v0.26, random cups: no fixed race list): what opens a locked cup, then the planet's track
-- names (its pool's base tracks), a few to a line; the Galactic Cup: the planets it draws from, then its finals
local function chunks(list, per)
  local out = {}
  for i = 1, #list, per do out[#out + 1] = table.concat(list, '   -   ', i, math.min(#list, i + per - 1)) end
  return out
end
local function cupInfo(cup, head)
  local out = {}
  if head then out[1] = head end
  local lines
  if cup.final then
    local names = {}
    for _, k in ipairs(cup.from or {}) do
      local first = K.pool(k)[1]
      local p = first and K.planetOf(first.path)
      if k ~= cup.last and p then names[#names + 1] = p.name end
    end
    local n = (tonumber(cup.planets) or 4) - (cup.last and 1 or 0)
    lines = { ('A race on %d of:   %s'):format(n, table.concat(names, '   -   ')) }
    local fin = K.pool(cup.last)
    if #fin > 0 then
      local t = {}
      for _, r in ipairs(fin) do t[#t + 1] = r.title end
      local p = K.planetOf(fin[1].path)
      lines[#lines + 1] = 'Then ' .. table.concat(t, ' or ') .. (p and (' at ' .. p.name) or '')
    end
  elseif cup.rally then
    -- v0.30
    local R = cfg.Rally or {}
    lines = { ('%d point-to-point stages in tour order, %d cars; the standings by total time. The night and weather are drawn when you start and kept secret.'):format(
      #K.bases(cup), tonumber(R.Grid) or 4) }
    for _, l in ipairs(chunks(K.bases(cup), 4)) do lines[#lines + 1] = l end
  else
    lines = chunks(K.bases(cup), 4)
  end
  for _, l in ipairs(lines) do out[#out + 1] = l end
  return table.concat(out, '\n')
end

SCREENS.cups = function()
  local cls = K.league(S.class) or K.leagues()[1]
  local items = {}
  local function cupTile(cup)
    local open, why, short = PR.cupOpen(K.data, cls.key, cup.key)
    if not open then
      items[#items + 1] = { title = cup.name, art = ART.cup(cup, myVehicle().key) or cup.art, span = (cup.final and cfg.CupsRows) and 2 or nil, corner = lockCorner(), disabled = true,
        desc = 'To open: ' .. tostring(short or why), info = padInfo(cupInfo(cup, 'To open: ' .. why)),
        act = function() S.message = cup.name .. ' is locked at ' .. cls.name .. '. To open it: ' .. why; return true end }
    else
      local mIcon, mColor = medal(cls.key, cup.key)
      local perfect = K.perfect and K.perfect(cls.key, cup.key)
      -- (v0.24: a perfect cup is a gold star beside the medal, not words; v0.26: no conditions line - the races are
      -- drawn when you pick the cup)
      items[#items + 1] = { title = cup.name, art = ART.cup(cup, myVehicle().key) or cup.art, span = (cup.final and cfg.CupsRows) and 2 or nil,
        icon = mIcon, iconColor = mColor, -- (v0.22: no medal words, no planet badge)
        corner = perfect and { { ART.STAR, ART.medalColor(1) } } or nil,
        info = padInfo(cupInfo(cup)),
        act = function() return toStart('cup', cls.key, cup.key) end }
    end
  end
  for _, cup in ipairs(cupsInOrder()) do if not cup.rally then cupTile(cup) end end
  local tt = titleTile(cls)
  if tt then items[#items + 1] = tt end
  local bt = bossTile(cls)
  if bt then items[#items + 1] = bt end
  -- v0.30: the Rally Cup after the title race and the boss (the second row)
  for _, cup in ipairs(cupsInOrder()) do if cup.rally then cupTile(cup) end end
  -- (v0.20, menu review 6: the vehicle and the how-to are gone; v0.21, owner: the blurb and the levels line too)
  -- (v0.27: the league's brief under its name - what you race with here)
  local lines = {}
  if cls.brief then lines[#lines + 1] = { cls.brief, 22, U.WHITE } end
  lines[#lines + 1] = msgLine()
  return { key = 'cups', title = cls.name:upper(), lines = lines,
    items = items, info = true, layout = (not cfg.CupsRows) and cfg.CupsLayout or nil, rows = cfg.CupsRows,
    center = cfg.CupsRows ~= nil }
end

-- the garage: one tile per thing you can change; Select cycles it (v0.8: no pick screens)
local function cyclePick(i)
  local level = levelNow()
  local picks = picksFor(curLeague())
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
-- v0.24 (owner): the garage is the START SCREEN of every race - picked a cup (or the title race, or the boss), you
-- land here with START focused and your last picks kept: one press to race, or change something first, for this
-- race on purpose (v0.26: the cup's four drawn races, with their conditions, are in the header, next to the tune-ups). B goes back to the cups.
-- Rows: your racer (two tiles wide) and the tune-ups; the four abilities; START. Pictures, not labels: each ability
-- and tune-up shows the game's own icon.
startLaunch = function()
  local st = S.start
  if not st then return true end
  local res
  if st.kind == 'cup' then
    local veh = myVehicle()
    K.startCup(st.class, st.cup, veh.key, picksFor(st.class), modsFor(), st.draw)
    res = launchNext()
    if res ~= 'launched' then K.forfeit() end -- couldn't start: no cup left half-begun
  elseif st.kind == 'title' then res = launchTo(TI.event(st.class), st.class)
  elseif st.kind == 'boss' then res = launchTo(TI.bossEvent(), st.class) end
  if res == 'launched' then S.start = nil end
  return res
end
-- the start screen's title and header lines: a cup -> its name, then the league (v0.26-v0.28.2: then its four drawn races);
-- the title race -> the league, the opponent and the track; the boss -> one line
local function startHeader(st)
  local cls = K.league(st and st.class) or { name = '?' }
  if not st then return 'GARAGE', {} end
  if st.kind == 'cup' then
    local cup = K.cup(st.cup) or { name = '?' }
    local lines = { { cls.name:upper(), 22, U.WHITE } }
    -- v0.28.3 (owner): no race list - the game's own track intro (the flyover with the track's name) shows each race;
    -- config StartRaceList = true puts the four drawn races back
    if cfg.StartRaceList == true then
      -- (v0.30: the Rally Cup shows its routes only - the weather is drawn but kept secret)
      local hide = cup.rally and (cfg.Rally or {}).HideWeather ~= false
      for i, r in ipairs(st.draw or {}) do lines[#lines + 1] = { ('%d   %s'):format(i, hide and (r.base or r.title) or r.title), 20, U.WHITE } end
    end
    return cup.name, lines
  elseif st.kind == 'title' then
    local ev = TI.event(cls.key) or {}
    return 'TITLE RACE', { { cls.name:upper() .. '   -   vs ' .. tostring(ev.vs or '?') .. '   -   ' .. tostring(ev.title or ''), 22, U.WHITE } }
  end
  return 'KESTAR BOOL', { { 'FINAL BOSS   -   1 v 1 in the stadium', 22, U.WHITE } }
end
SCREENS.garage = function()
  local level = levelNow()
  local picks = picksFor(curLeague())
  local st = S.start
  local items = {}
  -- A locked racer (Kestar Bool until he is beaten after the Ace title) is skipped by Select and named in the
  -- info line with how to unlock him. Selecting a pilot sets the vehicle back to theirs and the four abilities
  -- back to that pilot's signature kit; both can be changed afterwards (PR #1, v0.31). The pilot tile carries the
  -- racer's face: config Portraits, the game's own MainIcon texture.
  if RC and RC.current then
    local r = RC.current() or {}
    local locks = {}
    for _, o in ipairs(RC.list()) do
      if RC.locked and RC.locked(o) then locks[#locks + 1] = ('  %s is locked. %s.'):format(o.name, RC.unlockText(o)) end
    end
    local face = portrait(r.key)
    items[#items + 1] = { title = (r.name or 'RACER'):upper(), span = 2, kind = 'racer',
      art = (r.key == 'Antagonist') and ART.SHOWDOWN or 'T_UI_FE_Tile_01',
      glyph = face and { face, { 1, 1, 1 }, side = 'left' } or nil,
      tag = { 'PILOT', { 0.62, 0.85, 1 } },
      info = ('%s:  %s.'):format(r.name or '?', r.line or '') .. table.concat(locks),
      act = function()
        local prev = (RC.current() or {}).key
        local n = RC.cycle(1)
        if n and n.key ~= prev then
          K.data.vehicle = n.vehicle
          K.data.picks = AB.normalize(AB.racerPicks(n.key), levelNow())
          K.data.picksRacer = n.key
          K.save()
          S.message = ('Racing as %s. %s. Signature abilities.'):format(n.name, RC.vehicleText(n.key))
        end
        return true
      end }
  end
  if RC and RC.cycleVehicle then
    local veh = myVehicle()
    items[#items + 1] = { title = (veh.name or 'VEHICLE'):upper(), span = 2, kind = 'vehicle',
      art = ART.vehicle(veh.key), tag = { 'VEHICLE', U.GOLD },
      info = 'Landspeeder, speeder bike, or skim speeder. A new pilot starts on their own. The other two wear that rider\'s scheme.',
      act = function()
        local v = RC.cycleVehicle(1)
        S.message = v and ((v.name or 'Vehicle') .. ' selected') or nil
        return true
      end }
  end
  local choices = #items
  local list = modsFor()
  local slots, fromClass = 0, {}
  for _, c in ipairs(K.leagues()) do
    local n = MS.slotsFor(c.key)
    for s2 = slots + 1, n do fromClass[s2] = c.name end
    if n > slots then slots = n end
  end
  local open = MS.slotsFor(curLeague())
  for i = 1, slots do
    local e = MS.effect(list[i])
    -- v0.27.4 (owner: tune-ups and abilities looked alike; a slot this league doesn't have looked open): a gold
    -- TUNE-UP caption; on the start screen (its league known) a slot not open there greyed with a lock, Select says
    -- where it opens
    if st and i > open then
      local where = fromClass[i] or '?'
      items[#items + 1] = { title = 'TUNE-UP ' .. i, art = ART.MODS, kind = 'tuneup', disabled = true,
        tag = { 'TUNE-UP', U.GOLD }, corner = lockCorner(),
        info = ('Tune-up %d opens at %s.'):format(i, where),
        act = function() S.message = ('Tune-up %d opens at %s'):format(i, where); return true end }
    else
    items[#items + 1] = { title = e and e.name:upper() or 'NONE', art = e and (ART.modGroup and ART.modGroup(e.group)) or ART.MODS, kind = 'tuneup',
      glyph = e and { ART.tuneUp(e.key), { 1, 1, 1 }, 120 } or nil, tag = { 'TUNE-UP', U.GOLD },
      info = (e and (e.name .. ':  ' .. (e.line or e.desc or '') .. '.') or ('Tune-up %d is empty.'):format(i))
        .. ((i > open) and ('  (Tune-up %d: from %s.)'):format(i, fromClass[i] or '?') or ''),
      act = function()
        if MS.cycle then list[i] = MS.cycle(list, i, 1) end
        K.data.mods = MS.normalize(list); K.save()
        local ne = MS.effect(K.data.mods[i])
        S.message = ne and (ne.name .. ' fitted') or ('Tune-up slot ' .. i .. ' emptied')
        return true
      end }
    end
  end
  local row1 = #items
  local abil = {}
  for i = 1, 4 do
    local lab = AB.label(picks[i], level)
    abil[#abil + 1] = { title = (lab or '?'):upper(), art = ART.ABILITIES, kind = 'ability',
      glyph = { ART.ability(AB.family(picks[i])), { 1, 1, 1 }, 100 }, tag = { 'ABILITY', { 0.62, 0.85, 1 } },
      info = ('%s:  %s.'):format(lab or '?', AB.blurb(picks[i])),
      act = function() local n = cyclePick(i); if n then S.message = n .. ' picked' end; return true end }
  end
  local title, sub = startHeader(st)
  if not st then
    -- the garage on its own (config StartScreen = false: the GARAGE tile on HOME): pilot, vehicle, the four
    -- abilities, the tune-ups, one grid
    local out = {}
    for i = 1, choices do out[#out + 1] = items[i] end
    for _, a in ipairs(abil) do out[#out + 1] = a end
    for k = choices + 1, #items do out[#out + 1] = items[k] end
    return { key = 'garage', title = 'GARAGE', lines = { msgLine() }, items = out, info = true }
  end
  for _, a in ipairs(abil) do items[#items + 1] = a end
  local focus
  if st then
    local art = (st.kind == 'cup' and K.cup(st.cup) and ART.cup(K.cup(st.cup), myVehicle().key))
      or (st.kind == 'title' and portrait((TI.event(st.class) or {}).opponent))
      or (st.kind == 'boss' and portrait('Antagonist')) or ART.SHOWDOWN
    items[#items + 1] = { title = 'START', art = art, span = 4, act = startLaunch }
    focus = #items
  end
  local G = cfg.GarageRows or { w = 470, h = 300, startH = 170 }
  local tunes = row1 - choices
  local rows = {}
  if choices > 0 then rows[#rows + 1] = { w = G.w, h = G.h, n = choices } end
  if tunes > 0 then rows[#rows + 1] = { w = G.w, h = G.h, n = tunes } end
  rows[#rows + 1] = { w = G.w, h = G.h, n = 4 }
  if st then rows[#rows + 1] = { w = G.w, h = G.startH or 170 } end
  local lines = {}
  for _, l in ipairs(sub or {}) do lines[#lines + 1] = l end
  lines[#lines + 1] = msgLine()
  return { key = 'garage', title = title, lines = lines,
    items = items, info = true, rows = rows, center = true, focus = focus }
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

-- a title race's (or the final boss's, v0.21) result: no points, just the title
SCREENS.titleResult = function()
  local r = S.result or {}
  local cls = K.league(r.ev and r.ev.class) or { name = '?' }
  local lines = {}
  if r.boss then
    if r.won then
      lines[#lines + 1] = { 'KESTAR BOOL BEATEN', 44, U.GOLD }
      if r.firstWin then lines[#lines + 1] = { 'He races for you now: pick him in the garage.', 22, U.WHITE } end
    else
      lines[#lines + 1] = { 'KESTAR BOOL WINS', 36, U.GREY }
      lines[#lines + 1] = { ('You finished %s.'):format(r.pos and ordinal(r.pos) or 'without finishing'), 22, U.WHITE }
    end
  elseif r.won then
    lines[#lines + 1] = { ('%s CHAMPION'):format(cls.name:upper()), 44, U.GOLD }
    if r.bossOpened then lines[#lines + 1] = { 'UNLOCKED:  KESTAR BOOL, the final boss', 22, U.GOLD } end
  else
    lines[#lines + 1] = { 'THE TITLE STAYS WITH ' .. tostring(r.vs or 'the leader'):upper(), 36, U.GREY }
    lines[#lines + 1] = { ('You finished %s.'):format(r.pos and ordinal(r.pos) or 'without finishing'), 22, U.WHITE }
  end
  if r.time and K.fmtTime then lines[#lines + 1] = { ('Your time %s'):format(K.fmtTime(r.time)) .. (r.lap and ('   -   best lap ' .. K.fmtTime(r.lap)) or ''), 18 } end
  return { key = 'titleResult', title = '', lines = lines, backdrop = ART.BACKDROP,
    items = { { title = 'CONTINUE', art = ART.SHOWDOWN, desc = 'Back to the cups', icon = r.won and ART.medal(1) or nil, iconColor = r.won and ART.medalColor(1) or nil,
      act = function() return go('cups') end } } }
end

-- v0.21 (owner): after a cup, CONTINUE (and B) go to that class's cups page with the focus on the cup just raced
-- (v0.20 focused the next cup without a gold). -> the cup's tile index, or nil
local function cupFocus(cupKey)
  for i, c in ipairs(cupsInOrder()) do if c.key == cupKey then return i end end
  return nil
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
    items[#items + 1] = { title = 'NEXT RACE', art = ART.cup(K.cup(run2.cup), run2.vehicle) or 'T_UI_FE_Tile_Campaign_Hero',
      badge = ('%s %d / %d'):format(run2.timed and 'STAGE' or 'RACE', run2.race, run2.races),
      -- (the badge says which race; the race's name, without its conditions when they don't fit; v0.30: the Rally Cup
      -- names the route only - nxt.shown)
      desc = nxt.shown or nxt.title, act = launchNext }
    local it = items[#items]
    if not U.tileFits(it) then it.desc = nxt.title:match('^(.-)%s*%(') or nxt.title end
  else
    -- v0.21: CONTINUE (and B) land on the cup just raced
    local at = (r.cupOver and run) and cupFocus(run.cup) or nil
    if at then S.focusMem.cups = at end
    items[#items + 1] = { title = 'CONTINUE', art = ART.cup(cup, run and run.vehicle) or 'T_UI_FE_Tile_Campaign_Hero',
      desc = 'Back to the cups',
      icon = r.trophy and ART.medal(TROPHY_INDEX[r.trophy]) or nil, iconColor = r.trophy and ART.medalColor(TROPHY_INDEX[r.trophy]) or nil,
      act = function() if at then S.focusMem.cups = at end; return go('cups') end }
  end
  spec.items = items
  return spec
end

-- v0.27.6 (owner 2026-11-12: "after a track it sent me to the campaign in the paddock"): while the next cup race waits
-- at the main menu under the cover (viaMenu), the game's own menu underneath had the focus - its Recommended page,
-- on the campaign tile - so an A press in those ~6 s (the cover takes no input) started the campaign. Now our tab is
-- picked under the cover with this page: one tile that does nothing, B does nothing, so stray presses land here.
SCREENS.wait = function()
  local run, nxt = K.run(), K.nextRace()
  local cup = run and K.cup(run.cup)
  return {
    key = 'wait', title = cup and cup.name or 'GRAND PRIX',
    lines = { { 'Next race loading...', 22 } },
    items = { { title = 'NEXT RACE', art = (cup and run and ART.cup(cup, run.vehicle)) or 'T_UI_FE_Tile_Campaign_Hero',
      badge = run and ('%s %d / %d'):format(run.timed and 'STAGE' or 'RACE', run.race, run.races) or nil, desc = nxt and (nxt.shown or nxt.title) or nil,
      act = function() return nil end } },
  }
end

SCREENS.confirm = function()
  local c = S.confirm or { text = '?' }
  S.focusMem.confirm = nil -- (v0.21: every question opens on its first tile - NO on the RESET questions)
  local function done(screen) S.screen, S.confirm = screen, nil; return true end
  local yes = { title = 'YES', art = 'T_UI_FE_Tile_01', act = function()
    -- (v0.21: a yes can hand back a second question - RESET asks twice)
    local nxt = c.yes and c.yes()
    if type(nxt) == 'table' then
      S.confirm, S.screen, S.focusMem.confirm = nxt, 'confirm', nil
      log('[menu] confirm: a second question')
      return true
    end
    return done(c.after or c.back or 'home')
  end }
  local no = { title = 'NO', art = 'T_UI_FE_Tile_02', act = function() return done(c.back or 'home') end }
  -- (v0.25: centred, in a row of two - the darkening look, not the milky fade)
  return { key = 'confirm', title = '', lines = { { c.text, 26, U.WHITE }, msgLine() },
    items = c.noFirst and { no, yes } or { yes, no }, rows = { { w = 420, h = 240 } }, center = true }
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
  setFocus(math.min(S.focusMem[spec.key] or spec.focus or 1, #ui.items))
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
  -- (v0.24: the tile pressed is the one to come back to when the page is rebuilt - the start screen opens on START)
  S.focus = i; S.focusMem[S.key or ''] = i
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

local BACK = { cups = 'home', garage = (cfg.StartScreen == false) and 'home' or 'cups', standings = 'cups', titleResult = 'cups' }
-- v0.9: B on the standings while the cup runs (races 1-3) - one confirm: YES forfeits and goes HOME, NO = the standings
-- (v0.21: also straight from B on the results screen's panel, chain.lua CH.leaveAsk)
local function leaveConfirm()
  return { text = 'Leave the cup? Your points are lost.', back = 'standings',
    yes = function() K.forfeit(); S.message = 'Cup abandoned' end, after = 'home' }
end
local function leaveCup()
  S.confirm = leaveConfirm()
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
  if not onCup() then S.screen = 'home'; S.focusMem.home = nil end -- (v0.20: HOME opens on the league last raced)
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
  -- (v0.23: a rows page has its own D-pad map, S.ui.nav)
  local nav = S.ui.nav and S.ui.nav[S.focus]
  if nav and (name == 'left' or name == 'right' or name == 'up' or name == 'down') then
    if nav[name] then setFocus(nav[name]) end
  elseif name == 'left' then setFocus(S.focus - 1)
  elseif name == 'right' then setFocus(S.focus + 1)
  elseif name == 'up' then setFocus(math.max(1, S.focus - cols))
  elseif name == 'down' then setFocus(math.min(#S.ui.items, S.focus + cols))
  elseif name == 'accept' then press(S.focus)
  elseif name == 'back' then
    if S.blocked then close('back')
    elseif S.screen == 'wait' then show()
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
  -- v0.25 (seen in game 2026-11-11: HOME opened on RESET, not the class last raced): in the first second after a
  -- page appears the game hands focus to a tile of its own choosing - take it back to ours, don't follow it
  if focused and focused ~= S.focus and C.clock - S.shownAt < (cfg.FocusHoldMs or 1000) then
    local it = S.ui.items[S.focus]
    if it then try(function() it.btn:SetFocus() end) end
    if not S.heldSaid then S.heldSaid = true; log(('[menu] the game moved focus to tile %d at once: kept on tile %d'):format(focused, S.focus)) end
    return
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

-- v0.19.1 (chain.lua CH.via, DESIGN.md §15): NEXT RACE on the results screen's panel went via the menu. At the main
-- menu, instead of the standings page: the cover stays up and the cup's next race launches through R.launch (the
-- same call as NEXT RACE on the standings page) once the menu has settled (the readiness rules of v0.16's study
-- mode, now in attic/): the menu up (R.menuUp, a flag), no race of ours, nothing left to put back, ChainRaces.MenuSettleS of that in a row.
-- Returns true while it holds the result back (waiting / launched), false = show today's standings page (the
-- request dropped, logged). Flags only, no lookups, until the launch.
local VIA_GIVEUP_MS = 30000
local function viaMenu()
  local CHm = require('chain')
  local v = CHm.via
  if not v then return false end
  local run, nxt = K.run(), K.nextRace()
  local function drop(why)
    CHm.via = nil
    S.openAt = C.clock -- (the standings page gets its own wait for the tab)
    log('[chain] via the menu: ' .. why .. ' - the standings page instead')
    return false
  end
  if not v.seen then
    v.seen = true
    pcall(U.cover, true)
    log(('[chain] via the menu: at the main menu - the cover up, race %d of %d launches once the menu has settled'):format(v.race, v.races or 4))
  end
  if not (run and nxt and run.cup == v.cup and run.class == v.class and nxt.race == v.race) then
    return drop(('the cup is not at race %d any more (%s)'):format(v.race, run and nxt and ('race ' .. nxt.race) or 'no cup'))
  end
  local ready = R.menuUp() and not R.run and not R.pendingRestore()
  -- v0.27.6: our tab (the wait page) under the cover, so a press can't reach the game's menu (SCREENS.wait); again
  -- if the tab was left (Q / E), at most once a second
  if ready and not (S.ui and S.screen == 'wait') and C.clock - (v.waitTry or -1e9) >= 1000 and TB.ready() then
    v.waitTry = C.clock
    if S.ui then close('next cup race') end
    S.screen = 'wait'
    if not v.waitLogged then v.waitLogged = true; log('[chain] via the menu: the wait page in our tab under the cover (presses land on it, not the game\'s menu)') end
    show()
  end
  if not ready then
    v.readyAt = nil
    if C.clock - (S.openAt or C.clock) > VIA_GIVEUP_MS then return drop(('the main menu did not settle in %d s'):format(VIA_GIVEUP_MS // 1000)) end
    return true
  end
  v.readyAt = v.readyAt or C.clock
  if C.clock - v.readyAt < CHm.settleMs() then return true end
  if S.ui and S.screen ~= 'wait' then close('next cup race'); return true end
  CHm.via = nil
  local ok, why = R.launch(nxt, cupArgs(run))
  if not ok then
    S.message = why
    log('[chain] via the menu: the launch of race ' .. v.race .. ' failed (' .. tostring(why) .. ') - the cover off, the standings page')
    pcall(U.cover, false)
    return false
  end
  S.openAt, S.message, S.chainCover = nil, nil, true
  if S.ui then dropBack(); S.ui = nil; log('[menu] closed (race launched)') end -- (not close: no trip to the game's tab)
  log(('[chain] via the menu: race %d of %d launched from the main menu (%.1f s after the results) - no standings page'):format(
    v.race, v.races or 4, (C.clock - (v.at or C.clock)) / 1000))
  return true
end

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
  elseif out and out.failed then
    if S.chainCover then S.chainCover = nil; pcall(U.cover, false) end
    -- the launch went nowhere: ours back with a message
    S.message = out.failed == 'timeout' and 'The race never loaded - nothing was recorded.' or nil
    if out.failed == 'timeout' and alive(C.first('FrontEndGameMode')) then S.screen = 'cups'; show() end
  elseif out then
    S.result, S.openAt = out, C.clock
    -- cover the main menu while it's rebuilt, so the race results lead straight to the ranking (config HideMenuFlash)
    if cfg.HideMenuFlash ~= false and (out.run or out.titleRace or out.boss) then pcall(U.cover, true) end
  end
  -- v0.19.1: a race launched via the menu is loading under the cover: the cover goes once its race world is there
  if S.chainCover and R.run and R.run.phase ~= 'loading' then
    S.chainCover = nil
    pcall(U.cover, false)
  end
  if S.openAt and C.clock >= S.openAt and not R.run and viaMenu() then
    -- (v0.19.1: the next cup race launches via the menu - no standings page)
  elseif S.openAt and C.clock >= S.openAt and not R.run then
    -- the menu is rebuilt after a race: wait for our tab on it, then open the result in the tab
    if TB.ready() then
      S.openAt = nil; S.message = nil
      local run = S.result and S.result.run
      if run then S.class, S.cup = run.class, run.cup
      elseif S.result and (S.result.titleRace or S.result.boss) and S.result.ev then S.class = S.result.ev.class end
      S.screen = run and 'standings' or (S.result and (S.result.titleRace or S.result.boss)) and 'titleResult' or 'cups'
      -- v0.21: B on the results screen's panel (chain.lua): straight to "Leave the cup?" (NO = the standings)
      local CHm = require('chain')
      local ask = CHm.leaveAsk
      CHm.leaveAsk = nil
      local liveRun = K.run()
      if ask and run and liveRun and liveRun.cup == ask.cup and liveRun.class == ask.class then
        S.confirm, S.screen = leaveConfirm(), 'confirm'
        log(('[chain] B on the results screen: "Leave the cup?" at the main menu (%s %s, race %d of %d next)'):format(
          K.leagueName(ask.class), ask.cup, liveRun.race, liveRun.races))
      elseif ask then
        log('[chain] B on the results screen: no cup alive at the main menu any more - the usual page')
      end
      show()
      if S.ui then pcall(U.cover, false) end -- (else the tab is being selected: TB.onEnter drops the cover once the page is up)
    end
    if S.openAt and C.clock - S.openAt > 30000 then S.openAt = nil; pcall(U.cover, false); log('the GRAND PRIX tab never came back - not opening the result') end
  end
end

-- v0.32 (FreeRace's 2026-11-08 lesson, docs/freerace-review-2026-11-25.md §6.5): while you are queued for an online
-- match the game locks every WBP_FE_TileCommon_Btn, ours included (CommonUI's locked state; a disabled tile counts
-- too). A launch then would race under the queue: race.lua asks this before any launch (R.atMainMenu).
R.menuLocked = function()
  if not (S.ui and S.ui.items) then return nil end
  for _, it in ipairs(S.ui.items) do
    local b = it.btn
    if alive(b) then
      if try(function() return b:GetLocked() end) == true then return 'the game has locked its tiles (an online queue?)' end
      if try(function() return b:GetIsEnabled() end) == false then return 'the game has disabled its tiles (an online queue?)' end
    end
  end
  return nil
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
-- v0.21: B on the results screen's panel, from the keyboard: Backspace or Escape only set chain.lua's flag (read and
-- cleared while the panel is up; cleared when a panel goes up, so a press during the race never counts)
for _, kn in ipairs({ 'BACKSPACE', 'ESCAPE' }) do
  local k = Key and Key[kn]
  if k then
    local CHm = require('chain')
    local ok, err = pcall(RegisterKeyBind, k, function() CHm.back = true end)
    if not ok then log('bind failed ' .. kn .. ': ' .. tostring(err)) end
  end
end
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
  if S.ui and S.screen ~= 'wait' then pcall(U.cover, false) end
end
TB.onLeave = function() if S.ui then close('tab left') end end
-- the menu holding our page was freed: drop the page without touching its widgets (they went with it)
TB.onGone = function() S.ui = nil; log('[menu] closed (menu gone)') end
TB.onFail = function() S.ui = nil end

-- v0.17 (TASKS.md 11, owner: "i want the game to launch and go directly to the grand prix menu, pressing b would still
-- back out to the main menu"): at the first main menu after the game starts, the GRAND PRIX tab opens by itself on
-- HOME, through the menu key's own path (openPage -> show -> TB.select: our tab picked by its id, never by stepping
-- through the game's tabs, so never MULTIPLAYER). Once per launch: `boot.done` is set the moment it opens or gives
-- up, and nothing sets it back (the mod is loaded once per game start), so a race, B or leaving the tab never
-- reopens it (the result page after a cup race is S.openAt's own flow). It waits for our tab on a settled menu
-- (TB.ready: after "[tab] GRAND PRIX tab added"), for nothing left to put back (parts, abilities, tune-ups, AI config,
-- racer, title: R.pendingRestore) and no cup (dropped at load, K.drop 'at boot'), then BOOT_DELAY_MS more.
-- Flags only, apart from TB.ready's check of the menu (only while waiting, a few seconds at boot).
local BOOT_DELAY_MS = 300 -- (v0.22: was 1000; the tab now settles on time, ~1 s)
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
  -- v0.27.5 (owner: "the grand prix tab takes a few seconds to load"): while the menu is up without our tab, look
  -- for it every poll (was every 5th, so up to 1 s lost before the settle wait even began) - for FAST_LOOK_MS at most,
  -- so a menu that never comes into view costs no more than before
  local FAST_LOOK_MS, fastMs = 5000, 0
  C.gameLoop(POLL_MS, function()
    if R.run then return end
    if not R.menuPoll(POLL_MS) then return end
    if not seenMenu then seenMenu = true end
    -- v0.16.1: [aiset] the AI / pacing assets as they are, once after boot (after any put-back from a crash)
    if not AI.bootRead and not R.pendingRestore() then
      local okA, errA = pcall(AI.bootReadback)
      if not okA then AI.bootRead = true; log('[aiset] read-back failed: ' .. tostring(errA)) end
    end
    ticks = ticks + 1
    if tabMode() then
      local noTab = next(TB.screens) == nil
      fastMs = noTab and (fastMs + POLL_MS) or 0
      if ticks % 5 == 1 or TB.settling or (noTab and fastMs <= FAST_LOOK_MS) then
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
