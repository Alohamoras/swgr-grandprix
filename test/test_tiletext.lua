-- v0.14 (TASKS.md A7, owner 2026-11-10: "can't fully read the tune-up tiles in the garage"): the text of every tile
-- any menu can show fits that tile (ui.lua U.FIT / U.tileFits: the budgets and how they were measured). Every
-- screen is built from its spec (main.lua's SCREENS, the test hook) in every state that changes a tile's text:
-- HOME and the cups pages at every class with nothing / every trophy / a place / perfect cups / titles won and every
-- possible champion, every lock; the garage at every class level with every racer (v0.15: naming their vehicle type;
-- HOME's GARAGE tile with each racer too), ability in each slot and
-- tune-up in both slots; the standings before every race of every cup at every class and after a cup; the title
-- result; the confirms; the offline page.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot()
local H = rawget(_G, 'GU_TEST_SCREENS')
assert(H, 'no test hook')
local SC, S = H.SCREENS, H.S
local K, U, cfg = require('gp'), require('ui'), require('config')
local AB, MS, TI = require('abil'), require('modsel'), require('title')

local bad, seenBad, count = {}, {}, 0
local function check(where, spec)
  local w = spec.layout and spec.layout.w or U.TILE_W
  -- (v0.23: a rows page - each tile at its own row's width, times its span)
  local widthOf = {}
  if spec.rows then
    for r, sp in ipairs(U.rowItems(spec.rows, #(spec.items or {}))) do
      for i = sp.from, sp.to do widthOf[i] = U.itemWidth(spec.rows[r], spec.items[i]) end
    end
  end
  for idx, it in ipairs(spec.items or {}) do
    local w = widthOf[idx] or w
    count = count + 1
    -- TILE_DUMP=1: every distinct tile text, for a look by eye
    if os.getenv('TILE_DUMP') then
      local k = ('%s | %s | %s'):format(it.title or '', it.badge or '', (it.desc or ''):gsub('\n', ' / '))
      if not seenBad['dump:' .. k] then seenBad['dump:' .. k] = true; io.stdout:write('TILE ' .. k .. '\n') end
    end
    local ok, why = U.tileFits(it, w)
    if not ok then
      local k = why
      if not seenBad[k] then seenBad[k] = true; bad[#bad + 1] = where .. ': ' .. why end
    end
  end
  return spec
end
local function cupsAt(cls, where) S.class = cls; return check(where .. ' cups ' .. cls, SC.cups()) end

-- 1. a fresh save: locked classes, locked Galactic Cups and title races (every class's page, open or not)
K.reset()
check('fresh home', SC.home())
for _, c in ipairs(K.classes()) do cupsAt(c.key, 'fresh') end

-- 2. progress: every cup at every class with the same result, for each result; titles won or tried
for _, b in ipairs({ 1, 2, 3, 5, 12 }) do
  K.data.best, K.data.perfect, K.data.titles = {}, {}, {}
  for _, c in ipairs(K.classes()) do
    K.data.best[c.key], K.data.perfect[c.key] = {}, {}
    for _, cup in ipairs(K.cups()) do
      K.data.best[c.key][cup.key] = b
      if b == 1 then K.data.perfect[c.key][cup.key] = true end
    end
    K.data.titles[c.key] = { tries = 3, won = b == 1 }
  end
  check('home best ' .. b, SC.home())
  for _, c in ipairs(K.classes()) do cupsAt(c.key, 'best ' .. b) end
end
-- trophies in some planet cups only (the Galactic Cup / title race locked on an open class, part counts on HOME)
K.data.best, K.data.perfect, K.data.titles = {}, {}, {}
for _, c in ipairs(K.classes()) do K.data.best[c.key] = { jakku = 1, lantaana = 3 } end
check('home part', SC.home())
for _, c in ipairs(K.classes()) do cupsAt(c.key, 'part') end

-- 3. v0.21: every possible title race opponent on the TITLE RACE tile ('vs Griff Halloran': any racer the leader can
-- be), with the title open and won; and the KESTAR BOOL tile (the boss) on the 150cc page, beaten and not
local opened = {}
for _, c in ipairs(K.classes()) do opened[c.key] = { jakku = 1, lantaana = 1, ando = 1, crait = 1, sentinel = 1, galactic = 1 } end
K.data.best = opened
for _, r in ipairs(cfg.Racers or {}) do
  for _, c in ipairs(K.classes()) do
    K.data.leader = { [c.key] = { name = r.name, cup = 'crait' } }
    K.data.titles = { [c.key] = { won = r.key == 'Ghost', tries = 1 }, ['150'] = { won = true, tries = 1 } }
    K.data.boss = (r.key == 'Ghost') and { beaten = true } or nil
    cupsAt(c.key, 'leader ' .. r.name)
  end
end
K.data.leader, K.data.titles, K.data.boss = {}, {}, nil

-- 4. the garage at each class level: cycle every tile through all it offers
local seenAb, seenTu, seenRacer, seenVeh = {}, {}, {}, {}
local function garage(cls)
  K.data.class = cls
  local spec = check('garage ' .. cls, SC.garage())
  return spec.items
end
local function find(items, pat)
  -- (v0.24: the garage's tiles have no badges; their kind: '^RACER' -> 'racer')
  local nth = pat:match('^%^ABILITY (%d)') or pat:match('^%^TUNE%%%-UP (%d)')
  local kind = pat:find('ABILITY', 1, true) and 'ability' or (pat:find('TUNE', 1, true) and 'tuneup') or nil
  local n = 0
  for i, it in ipairs(items) do
    if nth and it.kind == kind then n = n + 1; if n == tonumber(nth) then return i end end
    if not nth and ((it.badge or ''):find(pat) or (it.kind or ''):upper():find(pat)) then return i end
  end
end
-- (v0.15: no VEHICLE tile; the RACER tile names the racer's vehicle type, and HOME's GARAGE tile the racer and it.
-- Kestar Bool unlocked here (v0.21: the boss beaten), so every racer is on the tile.)
K.data.boss = { beaten = true, tries = 1 }
for _, c in ipairs(K.classes()) do
  local items = garage(c.key)
  T.check(find(items, '^VEHICLE') == nil, 'no VEHICLE tile in the garage at ' .. c.key)
  for _ = 1, #(cfg.Racers or {}) do
    local i = find(items, '^RACER'); seenRacer[items[i].title] = true
    seenVeh[items[i].desc] = true
    check('home racer ' .. items[i].title, SC.home())
    items[i].act(); items = garage(c.key)
  end
  for slot = 1, 4 do
    for _ = 1, 12 do
      local i = find(items, '^ABILITY ' .. slot)
      seenAb[items[i].title] = true
      items[i].act(); items = garage(c.key)
    end
  end
  for slot = 1, MS.MAX do
    for _ = 1, #MS.all() + 1 do
      local i = find(items, '^TUNE%-UP ' .. slot)
      seenTu[items[i].title] = true
      items[i].act(); items = garage(c.key)
    end
  end
end
-- (coverage: every vehicle, racer, ability at every level and tune-up was on a tile)
local missing = {}
for _, v in ipairs(K.vehicles()) do
  local t = v.name:sub(1, 1) .. v.name:sub(2):lower()
  if not seenVeh[t] then missing[#missing + 1] = t end
end
for _, r in ipairs(cfg.Racers or {}) do if not seenRacer[r.name:upper()] then missing[#missing + 1] = r.name end end
for _, p in ipairs(MS.all()) do if not seenTu[p.name:upper()] then missing[#missing + 1] = p.name end end
for _, c in ipairs(K.classes()) do
  local level = AB.levelFor(c.key)
  for _, fam in ipairs(AB.families()) do
    for br in pairs(cfg.Abilities.Lines[fam]) do
      local lab = AB.label(fam .. '.' .. br, level):upper()
      if not seenAb[lab] then missing[#missing + 1] = lab end
    end
  end
end
T.check(#missing == 0, 'the garage showed every vehicle, racer, ability and tune-up' .. (#missing > 0 and (': missing ' .. table.concat(missing, ', ')) or ''))

-- 5. the standings: before every race of every cup at every class (NEXT RACE), and after a cup (CONTINUE)
local races = 0
for _, c in ipairs(K.classes()) do
  for _, cup in ipairs(K.cups()) do
    local run = K.startCup(c.key, cup.key, 'car', K.data.picks, K.data.mods)
    for n = 1, run.races do
      run.race = n
      S.result = { ev = K.nextRace(), run = run, pos = 3 }
      check(('standings %s %s race %d'):format(c.key, cup.key, n), SC.standings())
      races = races + 1
    end
    K.data.run = nil
    for _, tr in ipairs({ 'GOLD', 'SILVER', 'BRONZE', false }) do
      S.result = { cupOver = true, run = run, ev = { title = 'X', race = 4 }, trophy = tr or nil, rank = tr and 1 or 5, pts = 40 }
      check('cup result ' .. tostring(tr), SC.standings())
    end
  end
end
T.check(races == 4 * 4 * #K.cups(), 'the standings before every race (' .. races .. ')')

-- 6. the title result, the confirms, the offline page
for _, won in ipairs({ true, false }) do
  S.result = { titleRace = true, won = won, vs = 'Griff Halloran', pos = won and 1 or 2, ev = { class = '150' }, bossOpened = won }
  check('title result', SC.titleResult())
  S.result = { boss = true, won = won, vs = 'Kestar Bool', pos = won and 1 or 2, ev = { class = '150' }, firstWin = won }
  check('boss result', SC.titleResult())
end
S.confirm = { text = 'Reset all progress? Every trophy, record and title is cleared.', back = 'home', noFirst = true }
check('confirm reset', SC.confirm())
S.confirm = { text = "Are you sure? This can't be undone.", back = 'home', noFirst = true }
check('confirm reset 2', SC.confirm())
S.confirm = { text = 'Leave the cup? Your points are lost.', back = 'standings' }
check('confirm leave', SC.confirm())
S.blocked = 'matchmaking is running'
check('offline', SC.offline())
S.blocked = nil

-- v0.14.1 (seen in game 2026-11-11: 'Champion: GRIFF / HALLORAN' wrapped on the focused 50CC tile): a class tile on
-- HOME names only YOUR title; another champion's name is in the info line
K.data.best, K.data.perfect, K.data.titles = {}, {}, {}
for _, c in ipairs(K.classes()) do K.data.best[c.key] = { jakku = 1 } end
local descs = {}
for _, it in ipairs(SC.home().items or {}) do
  if it.title and it.title:match('CC$') then descs[#descs + 1] = tostring(it.desc) end
end
T.check(not table.concat(descs, '|'):find('Champion: %u%u+ %u'), 'no other champion on a class tile (' .. table.concat(descs, '|') .. ')')
K.data.titles = { ['100'] = { won = true, tries = 1 } }
local home = SC.home().items or {}
local got
local star
for _, it in ipairs(home) do if it.title == '100CC' then got = it.desc; star = it.pips and it.pips[#it.pips] end end
T.check(got == nil and star and star[1] == require('art').STAR and not star[3], 'v0.24: your title is the gold star at the end of the pips, no words (' .. tostring(got) .. ')')
for _, it in ipairs(home) do if it.title == '100CC' then T.check(not tostring(it.info):find('Champion', 1, true), 'v0.21: not repeated in the info line (less clutter)') end end

T.check(#bad == 0, ('every tile\'s text fits its tile (%d tiles checked)%s'):format(count,
  #bad > 0 and (':\n  ' .. table.concat(bad, '\n  ')) or ''))
T.finish()
