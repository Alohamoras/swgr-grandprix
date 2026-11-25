-- Galactic Grand Prix: the title race per league and the final boss (v0.8; v0.21 owner, OWNER.md "Done" 2026-11-11).
--
-- The title race (v0.21): a 1 v 1 on a NORMAL track against the league leader. It opens with a trophy in the Galactic
-- Cup at the league (prog.lua P.titleOpen). The leader = the best-placed bot in the final standings of your most recent
-- finished cup at that league (if you won it, the 2nd; else the cup winner), saved when a cup ends (gp.lua:
-- leader[league] = { name, cup, path }). v0.26 (random cups): the track = the first race of that cup run (path, saved
-- with the leader). No cup finished at the league yet: config Title.Default[league] (a DA_Racer_ key) on the first race
-- of a random draw of Title.DefaultCup (Jakku), made once per league and saved (titleTrack[league]), so the tile shows
-- a stable track. Winning makes you the league champion (saved: titles[league]). Your racer swap (racer.lua) still
-- applies.
-- The two-car grid (KNOWLEDGE.md §3, RaceFlowSpike B6, raceflow-b6-20261111.log): before LaunchQuickRace the event's
-- GridMakeup is set to 2 entrants (its first entry 2, the others 0) and CharacterList.Opponents cut to the one racer;
-- both go back at the main menu, once (T.gridRestore, from race.lua R.restoreBuild). The originals are in the save
-- (gridRestore) BEFORE anything changes, so a crash mid-race is put right at the next boot's menu.
--
-- The final boss (v0.21): Kestar Bool in the game's Stadium Showdown (the old title race, config Boss), a KESTAR BOOL
-- tile on the Ace cups page once the Ace title is won (v0.26; was 150cc). Beating him saves boss = { beaten = true } and unlocks him
-- as a racer (racer.lua unlockBoss). The Showdown's story cinematics are taken off for the race and put back (below).
-- v0.33 (owner 2026-11-25: "ditch the title race and put the Kestar race at the end of the Galactic Cup"): the title
-- race is off (config Title.On) and the Showdown is the Galactic Cup's FINALE at every league (config Boss, Where =
-- 'cup'): a trophy in the cup's four points races adds it as race 5 of the same run (gp.lua K.record: T.finaleDue,
-- T.finaleRace), no points; T.finale records the result - titles[league] (the champion) and, at Boss.League, the
-- boss (the racer unlock). The tile way (Where = 'tile') and T.record stay for config.
--
-- Pure logic plus memory-only writes to two data assets, each through try / pcall; nothing kept between ticks.
local C = require('core')
local cfg = require('config')
local K = require('gp')
local CU = require('cup')
local log = C.log
local try, alive = C.try, C.alive

local T = {}
local function conf() return cfg.Title or {} end
local function bconf() return cfg.Boss or {} end
function T.on() return conf().On ~= false end
function T.bossOn() return bconf().On ~= false and bconf().Event ~= nil end
function T.bossClass() return bconf().League or 'ace' end
function T.status(classKey) return (K.data.titles or {})[classKey] end
-- v0.33: where Kestar is raced - 'cup' (the Galactic Cup's finale) or 'tile' (the v0.21 boss tile, after the title)
function T.bossWhere() return bconf().Where == 'tile' and 'tile' or 'cup' end
function T.finaleOn() return T.bossOn() and T.bossWhere() == 'cup' end

---------------------------------------------------------------------------------------------------------------------
-- the title race's opponent and track

local function racerByName(name) for _, r in ipairs(cfg.Racers or {}) do if r.name == name then return r end end return nil end
local function racerByKey(key) for _, r in ipairs(cfg.Racers or {}) do if r.key == key then return r end end return nil end
local function defaultCup()
  return K.cup(conf().DefaultCup or 'jakku') or (function() for _, c in ipairs(K.cups()) do if not c.final then return c end end end)()
end

-- the best-placed bot of a finished cup (run = the cup state, cup.lua): its name, or nil
function T.leaderOf(run)
  for _, r in ipairs(CU.standings(run or { points = {}, last = {} })) do
    if r.key ~= CU.YOU then return r.key end
  end
  return nil
end

-- your racer's key (racer.lua; nil when it can't be read)
local function yourKey()
  local ok, RC = pcall(require, 'racer')
  local r = ok and RC.current and RC.current()
  return r and r.key or nil
end

-- the league leader: { key, name, cup = the cup key it came from (nil = the default), path = the first race of that
-- cup run, source = 'cup' | 'default' }. Never your own racer (raced as the leader: the league's default, else the
-- first other racer).
function T.leader(classKey)
  local mine = yourKey()
  local l = (K.data.leader or {})[classKey]
  if type(l) == 'table' and type(l.name) == 'string' then
    local r = racerByName(l.name)
    if r and r.key ~= mine then return { key = r.key, name = r.name, cup = l.cup, path = l.path, source = 'cup' } end
  end
  local dk = (conf().Default or {})[classKey]
  local r = dk and racerByKey(dk)
  if not r or r.key == mine then
    r = nil
    for _, o in ipairs(cfg.Racers or {}) do if o.key ~= mine and not o.unlockBoss and o.key ~= 'Mentor' and o.key ~= 'DarkEnigma' then r = o; break end end
  end
  r = r or { key = 'Rager', name = 'Biddy Blas' }
  return { key = r.key, name = r.name, source = 'default' }
end
function T.opponent(classKey) return T.leader(classKey).name end

-- v0.26: the title race's track before any cup has finished at the league: the first race of a random draw of
-- Title.DefaultCup, made once and saved (titleTrack[league]); a saved path no pool knows any more is drawn again
local function defaultTrack(classKey)
  K.data.titleTrack = K.data.titleTrack or {}
  local r = K.raceByPath(K.data.titleTrack[classKey])
  if r then return r end
  local cup = defaultCup()
  local d = cup and K.draw(cup)[1]
  r = d and K.raceByPath(d.path)
  if not r then return nil end
  K.data.titleTrack[classKey] = r.path
  K.save()
  log(('[title] %s: no cup finished yet - the title race track is %s (a random %s draw, kept)'):format(K.leagueName(classKey),
    r.title, cup.name))
  return r
end
-- the launchable title race: the first race of the leader's most recent cup run at the league (no leader yet, or a
-- path no pool knows: the default track), plus the title flag the result read looks for and the opponent for the grid
function T.event(classKey)
  local l = T.leader(classKey)
  local r = l.source == 'cup' and K.raceByPath(l.path) or nil
  if not r then r = defaultTrack(classKey) end
  if not r then return nil end
  local p = K.planetOf(r.path)
  return { path = r.path, title = r.title, kind = r.kind, laps = r.laps, class = classKey, titleRace = true,
    opponent = l.key, vs = l.name, trackCup = p and p.key or nil, leaderFrom = l.source }
end

---------------------------------------------------------------------------------------------------------------------
-- the two-car grid (race.lua prepare, before RC.begin): the event's grid make-up to 2, CharacterList.Opponents to the
-- one racer. Originals in the save first (gridRestore = { event, entries = { n, ... }, opponents = { def paths } }).

local function entries(e)
  local out = {}
  local arr = try(function() return e.GridMakeup.Entries end)
  local n = tonumber((try(function() return arr:GetArrayNum() end))) or 0
  for i = 1, n do out[i] = tonumber((try(function() return arr[i].NumEntrants end))) or 0 end
  return out
end
local function sum(list) local s = 0; for _, v in ipairs(list) do s = s + v end; return s end
local function setEntries(e, list)
  for i, n in ipairs(list) do pcall(function() e.GridMakeup.Entries[i].NumEntrants = n end) end
  return sum(entries(e))
end
local function oppKeys(paths)
  local o = {}
  for _, p in ipairs(paths) do o[#o + 1] = tostring(p):match('DA_Racer_([%w_]+)$') or tostring(p) end
  return table.concat(o, ',')
end
-- the character list's Opponents made equal to `paths` (a longer list is emptied first, then filled). -> read back ok
local function setOpponents(RC, list, paths)
  local arr = try(function() return list.Opponents end)
  if not arr then return false end
  local cur = RC.opponentPaths(list)
  if #cur > #paths then pcall(function() arr:Empty() end); cur = {} end
  for i, p in ipairs(paths) do
    if cur[i] ~= p then
      local d = C.asset(p)
      if d then pcall(function() list.Opponents[i] = d end) end
    end
  end
  local now = RC.opponentPaths(list)
  if #now ~= #paths then return false end
  for i, p in ipairs(paths) do if now[i] ~= p then return false end end
  return true
end

function T.gridPending() return type(K.data.gridRestore) == 'table' end

-- v0.30: the grid cut to you + the racers at `paths` (racer def paths), for the title race (one) and the Rally Cup
-- (three). e = the event asset, evPath its path, label for the log. Returns true when the grid is cut.
function T.gridCut(e, evPath, paths, label)
  local RC = require('racer')
  if T.gridPending() then
    log('[title] an earlier grid change was still to be put back - done before this launch')
    T.gridRestore('before launch')
  end
  local list = RC.findList()
  if not list then log('[title] grid NOT cut: character list not found - a full field'); return false end
  local ents = entries(e)
  if #ents == 0 then log('[title] grid NOT cut: the event has no grid make-up entries - a full field'); return false end
  for _, p in ipairs(paths) do
    if not C.asset(p) then log('[title] grid NOT cut: racer not found ' .. p .. ' - a full field'); return false end
  end
  local n = #paths + 1
  local orig = RC.opponentPaths(list)
  K.data.gridRestore = { event = evPath, entries = ents, opponents = orig, vs = label }
  K.save()
  local want = {}
  for i = 1, #ents do want[i] = i == 1 and n or 0 end
  if setEntries(e, want) ~= n then
    setEntries(e, ents)
    K.data.gridRestore = nil
    K.save()
    log(('[title] grid NOT cut: the grid make-up did not take %d entrants - a full field'):format(n))
    return false
  end
  local ok = setOpponents(RC, list, paths)
  log(('[title] grid cut for %s: %s make-up %d -> %d entrants; CharacterList.Opponents %d -> %s%s%s'):format(label,
    evPath:match('([^/]+)$'), sum(ents), n, #orig, oppKeys(paths), #paths == 1 and ' only' or '', ok and '' or ' - FAILED (read back differs)'))
  return ok
end
-- e = the event asset, ev = T.event's table. Returns true when the grid is the two of you.
function T.gridPrepare(e, ev)
  local RC = require('racer')
  return T.gridCut(e, ev.path, { RC.path(ev.opponent) }, 'the title race')
end

-- at the main menu (race.lua R.restoreBuild; also after a crash, from the save): the make-up and the list back, once
function T.gridRestore(why)
  local rec = K.data.gridRestore
  if type(rec) ~= 'table' then return false end
  local RC = require('racer')
  local okE, okO = 'not found', 'not found'
  local e = rec.event and C.asset(rec.event)
  if e and type(rec.entries) == 'table' then
    local n = setEntries(e, rec.entries)
    okE = (n == sum(rec.entries) and 'done' or 'FAILED') .. (' (%d entrants)'):format(n)
  end
  local list = RC.findList()
  if list and type(rec.opponents) == 'table' then
    okO = (setOpponents(RC, list, rec.opponents) and 'done' or 'FAILED') .. (' (%d: %s)'):format(#rec.opponents, oppKeys(rec.opponents))
  end
  K.data.gridRestore = nil
  K.save()
  log(('[title] grid put back (%s): make-up %s; Opponents %s'):format(why or '?', okE, okO))
  return true
end

---------------------------------------------------------------------------------------------------------------------
-- the final boss: Kestar Bool in the Stadium Showdown

function T.bossEvent()
  if not T.bossOn() then return nil end
  return { path = bconf().Event, title = bconf().Name or 'KESTAR BOOL', kind = '1 v 1', class = T.bossClass(), boss = true }
end
function T.bossName() return bconf().Opponent or 'Kestar Bool' end
-- the boss tile shows once the boss class's title is won
function T.bossOpen(data)
  data = data or K.data
  local t = (data.titles or {})[T.bossClass()]
  return T.bossOn() and type(t) == 'table' and t.won == true
end
function T.bossBeaten(data)
  data = data or K.data
  return type(data.boss) == 'table' and data.boss.beaten == true
end

-- The Showdown event carries the campaign's story cinematics: EventCompleteCinematicChain = the Act 2 victory scene,
-- which outside the campaign leads to a black screen (seen in game, 2026-11-10: the race finished, the cutscene
-- was skipped by Streamline, then nothing). So before the boss race these chains are taken off the event (memory
-- only) and put back at the menu; the originals' paths live in the save (titleRestore) so a crash is put right too.
T.CHAINS = { 'EventCompleteCinematicChain', 'EventFailedCinematicChain' }
function T.prepare(e, path)
  local rec = { path = path, fields = {} }
  local n = 0
  for _, f in ipairs(T.CHAINS) do
    local o = try(function() return e[f] end)
    if alive(o) then
      local full = try(function() return o:GetFullName() end)
      if type(full) == 'string' then
        local obj = full:match('^%S+%s+(.+)$') or full
        rec.fields[f] = obj:match('^(.*)%.[^./]+$') or obj -- the package path (C.asset adds the object name)
        if pcall(function() e[f] = CreateInvalidObject() end) then n = n + 1 end
      end
    end
  end
  if n > 0 then
    K.data.titleRestore = rec
    K.save()
    local names = {}
    for f, p in pairs(rec.fields) do names[#names + 1] = f .. '=' .. p:match('([^/.]+)$') end
    log(('[title] story cinematics taken off %s for this race: %s'):format(path:match('([^/]+)$'), table.concat(names, ', ')))
  end
  return n
end
function T.pending() return type(K.data.titleRestore) == 'table' or T.gridPending() end
function T.restore(why)
  local rec = K.data.titleRestore
  if type(rec) ~= 'table' then return 0 end
  local e = C.asset(rec.path)
  local n = 0
  for f, p in pairs(rec.fields or {}) do
    local o = C.asset(p)
    if e and o and pcall(function() e[f] = o end) then n = n + 1 end
  end
  K.data.titleRestore = nil
  K.save()
  log(('[title] story cinematics put back (%s): %d'):format(why or '?', n))
  return n
end

---------------------------------------------------------------------------------------------------------------------
-- v0.33: the Galactic Cup's finale (Where = 'cup')

-- the finale as a cup race entry (gp.lua: appended to the run's list after the points races)
function T.finaleRace()
  local name = bconf().Name or 'KESTAR BOOL'
  return { path = bconf().Event, title = name, base = name, kind = '1 v 1', laps = tonumber(bconf().Laps) or 6, boss = true }
end
-- is the finale due after this run's points races? rank = your rank in the cup's points table (Gate: 'trophy' = top
-- 3, 'gold' = 1st, 'always')
function T.finaleDue(run, rank)
  if not T.finaleOn() or type(run) ~= 'table' or run.timed then return false end
  local cup = K.cup(run.cup)
  if not (cup and cup.final) then return false end
  local gate = bconf().Gate or 'trophy'
  if gate == 'always' then return true end
  if not rank then return false end
  return rank <= (gate == 'gold' and 1 or 3)
end
-- the cups page's line about it
function T.finaleText()
  local gate = bconf().Gate or 'trophy'
  -- v0.35.0 (docs/menu-text-review-2026-11-25.md): in the announcer's voice
  local lead = gate == 'always' and 'Then' or (gate == 'gold' and 'Take gold and' or 'Finish on the podium and')
  return ('%s %s waits in the stadium. One race for the title.'):format(lead, T.bossName())
end
-- the finale's rows into the run's history (no points, nothing in the points table: the standings stay as the points
-- races left them - cup.lua skips finale rows for the tie rule). pos = your finishing position (nil = DNF)
function T.finaleRows(run, pos)
  local me = tonumber(pos)
  local rows = { { key = CU.YOU, place = me or 2, pts = 0, dnf = me == nil, finale = true },
    { key = T.bossName(), place = me == 1 and 2 or 1, pts = 0, dnf = false, finale = true } }
  run.history[#run.history + 1] = rows
  run.race = run.race + 1
  return rows
end
-- the finale's result into the save: titles[league] (won = the league champion); at Boss.League the boss too (the
-- racer unlock). Returns what the result screens show: { finale = true, won, vs, pos, tries, firstWin, league,
-- unlockedRacer }
function T.finale(ev, pos, run)
  local won = pos == 1
  local cls = run.class
  K.data.titles = K.data.titles or {}
  local t = K.data.titles[cls] or { tries = 0 }
  t.tries = (t.tries or 0) + 1
  local was = t.won == true
  if won then t.won, t.at, t.vs = true, os.date('%Y-%m-%d'), T.bossName() end
  K.data.titles[cls] = t
  local out = { finale = true, won = won, vs = T.bossName(), pos = pos, tries = t.tries, firstWin = won and not was,
    league = K.leagueName(cls) }
  if cls == T.bossClass() then
    local b = type(K.data.boss) == 'table' and K.data.boss or {}
    b.tries = (b.tries or 0) + 1
    local beaten = b.beaten == true
    if won then b.beaten, b.at = true, os.date('%Y-%m-%d') end
    K.data.boss = b
    out.unlockedRacer = won and not beaten
  end
  log(('FINALE %s: %s vs %s (try %d)%s'):format(K.leagueName(cls),
    won and ('WON - you are the ' .. K.leagueName(cls) .. ' champion') or (pos and ('lost, ' .. C.ordinal(pos)) or 'DNF'),
    T.bossName(), t.tries, out.unlockedRacer and (' - ' .. T.bossName() .. ' unlocked as a racer') or ''))
  return out
end

---------------------------------------------------------------------------------------------------------------------
-- a finished title race or boss race (called from K.record): won = 1st of the two. Returns what the result screen shows.

function T.record(ev, pos)
  local won = pos == 1
  if ev.boss then
    local b = type(K.data.boss) == 'table' and K.data.boss or {}
    b.tries = (b.tries or 0) + 1
    local was = b.beaten == true
    if won then b.beaten, b.at = true, os.date('%Y-%m-%d') end
    K.data.boss = b
    log(('KESTAR BOOL (final boss): %s (try %d)'):format(won and ('WON - ' .. T.bossName() .. ' beaten'
      .. (was and '' or ', unlocked as a racer')) or (pos and ('lost, ' .. C.ordinal(pos)) or 'DNF'), b.tries))
    return { boss = true, won = won, vs = T.bossName(), tries = b.tries, firstWin = won and not was }
  end
  local cls = ev.class
  K.data.titles = K.data.titles or {}
  local t = K.data.titles[cls] or { tries = 0 }
  t.tries = (t.tries or 0) + 1
  local was = t.won == true
  local vs = ev.vs or T.opponent(cls)
  if won then t.won, t.at, t.vs = true, os.date('%Y-%m-%d'), vs end
  K.data.titles[cls] = t
  log(('TITLE RACE %s: %s vs %s on %s (try %d)'):format(K.leagueName(cls), won and 'WON - you are the champion' or (pos and ('lost, ' .. C.ordinal(pos)) or 'DNF'),
    vs, tostring(ev.title), t.tries))
  local out = { titleRace = true, won = won, vs = vs, tries = t.tries, firstWin = won and not was }
  if out.firstWin and cls == T.bossClass() and T.bossOn() and not T.bossBeaten() then
    out.bossOpened = true
    log('unlocked: ' .. (bconf().Name or 'KESTAR BOOL') .. ' (the final boss) on the ' .. K.leagueName(cls) .. ' cups page')
  end
  return out
end

return T
