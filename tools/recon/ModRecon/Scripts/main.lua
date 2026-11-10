-- ModRecon: recon for Grand Prix mods (affixes), DESIGN.md §5b, TASKS.md v0.4. Test-only, not shipped. Offline only.
-- Does nothing until a trigger file appears in Mods/ModRecon/ (checked once a second; no keys, no hooks):
--   dump.txt     load every affix in afx_paths.txt, write affixes.tsv (name, rarity, group, descriptions, numbers)
--   arm.txt      (main menu) one affix path or asset name per line: written into VBD_Car_Base.Affixes (memory only),
--                UnlockedAffixSlots raised to fit. Logs the list before / after. Undo: restore.txt or a restart.
--   check.txt    (in a race) log every racer's passives (PassiveManagerComponent.PassiveList -> Config) and the race
--                copies' AffixSlots: does an armed affix reach the car?
--   restore.txt  put VBD_Car_Base.Affixes / UnlockedAffixSlots back as they were before arm.txt
--   strip.txt    (before a race) at race load, as soon as the bots' race copies exist, clear their AffixSlots and log
--                whether their passives were already made: can mods be yours only?
-- Log: modrecon.log. Keeps no UObject between ticks.
local DIR = (debug.getinfo(1, 'S').source:match('^@(.*[/\\])Scripts[/\\]') or '')
local LOG = DIR .. 'modrecon.log'
local BUILD = '/Game/Griffin/Gameplay/Campaign/Builds/VBD_Car_Base.VBD_Car_Base'

local function try(f, ...)
  local r = table.pack(pcall(f, ...))
  if r[1] then return table.unpack(r, 2, r.n) end
  return nil, tostring(r[2])
end
local function alive(o) return o ~= nil and try(function() return o:IsValid() end) == true end
local function log(m)
  local f = io.open(LOG, 'a')
  if f then f:write(os.date('%H:%M:%S ') .. tostring(m) .. '\n'); f:close() end
end
local function nm(o) return alive(o) and (try(function() return o:GetFName():ToString() end) or '?') or '-' end
local function full(o) return alive(o) and (try(function() return o:GetFullName() end) or '?') or '-' end
local function txt(t) local s = try(function() return t:ToString() end); return s and s:gsub('[\r\n\t]+', ' ') or '' end
local function tag(t) local s = try(function() return t.TagName:ToString() end); return (s and s ~= 'None') and s or '' end
local function exists(f) local h = io.open(DIR .. f, 'r'); if h then h:close(); return true end; return false end
local function readAll(f) local h = io.open(DIR .. f, 'r'); if not h then return nil end; local s = h:read('a'); h:close(); return s end
local function lines(f) local o = {}; for l in (readAll(f) or ''):gmatch('[^\r\n]+') do if l:match('%S') and not l:match('^%s*#') then o[#o + 1] = l:match('^%s*(.-)%s*$') end end; return o end
local function find(c)
  local got, out = try(FindAllOf, c), {}
  for _, o in ipairs(type(got) == 'table' and got or {}) do if alive(o) and not nm(o):find('^Default__') then out[#out + 1] = o end end
  return out
end
local function load(path)
  local o = try(StaticFindObject, path)
  if alive(o) then return o end
  try(LoadAsset, path)
  o = try(StaticFindObject, path)
  return alive(o) and o or nil
end
local RAR = { [0] = 'common', [1] = 'rare', [2] = 'epic', [3] = 'legendary', [4] = 'faulty', [5] = 'experimental', [6] = 'none' }
local function mapText(m)
  local o = {}
  try(function() m:ForEach(function(k, v) o[#o + 1] = txt(k:get()) .. '=' .. tostring(v:get()) end) end)
  table.sort(o)
  return table.concat(o, ' ')
end
local function arrNames(a)
  local o = {}
  try(function() a:ForEach(function(_, el) o[#o + 1] = nm(el:get()) end) end)
  return o
end
local PATHS = {}
for _, p in ipairs(lines('afx_paths.txt')) do PATHS[p:match('([^/.]+)$')] = p end
local function pathOf(s) return s:find('/', 1, true) and s or PATHS[s] end

---------------------------------------------------------------------------------------------------- dump
local function dump()
  local out = { table.concat({ 'asset', 'rarity', 'name', 'description', 'faulty_description', 'group', 'unlocked_by',
    'show_in_build', 'percent', 'int', 'faulty_percent', 'faulty_int', 'rules', 'path' }, '\t') }
  local ok, bad = 0, 0
  for _, p in ipairs(lines('afx_paths.txt')) do
    local a = load(p)
    if a then
      ok = ok + 1
      local rules = try(function() return a.PassiveRule:GetArrayNum() end) or -1
      out[#out + 1] = table.concat({ nm(a), RAR[tonumber(try(function() return a.Rarity end) or 6)] or '?',
        txt(try(function() return a.PlayerFacingName end)), txt(try(function() return a.PlayerFacingDescription end)),
        txt(try(function() return a.FaultyPlayerFacingDescription end)), tag(try(function() return a.EconomyGroup end)),
        tag(try(function() return a.UnlockedBy end)), tostring(try(function() return a.bShowInBuild end)),
        mapText(try(function() return a.PercentProperties end)), mapText(try(function() return a.IntProperties end)),
        mapText(try(function() return a.FaultyPercentProperties end)), mapText(try(function() return a.FaultyIntProperties end)),
        tostring(rules), p }, '\t')
    else
      bad = bad + 1
      log('dump: could not load ' .. p)
    end
  end
  local f = io.open(DIR .. 'affixes.tsv', 'w')
  if f then f:write(table.concat(out, '\n') .. '\n'); f:close() end
  log(('dump: %d affixes written to affixes.tsv, %d not loaded'):format(ok, bad))
end

---------------------------------------------------------------------------------------------------- arm / restore
local ORIG -- { paths, unlocked } before the first arm (memory only)
local function buildState(b)
  return ('Affixes=[%s] UnlockedAffixSlots=%s MaximumAffixSlots=%s'):format(table.concat(arrNames(b.Affixes), ', '),
    tostring(try(function() return b.UnlockedAffixSlots end)), tostring(try(function() return b.MaximumAffixSlots end)))
end
local function setList(b, objs)
  local arr = b.Affixes
  local n = try(function() return arr:GetArrayNum() end) or 0
  -- shrink: try Empty() first, then fill index by index (UE4SS grows a TArray when you assign index Num + 1)
  if n > #objs then
    local okE, errE = pcall(function() arr:Empty() end)
    log('  Empty(): ' .. tostring(okE) .. ' ' .. tostring(errE or ''))
    n = try(function() return arr:GetArrayNum() end) or 0
  end
  for i, o in ipairs(objs) do
    local okS, errS = pcall(function() arr[i] = o end)
    log(('  Affixes[%d] = %s: %s %s (array now %s)'):format(i, nm(o), tostring(okS), tostring(errS or ''),
      tostring(try(function() return arr:GetArrayNum() end))))
  end
end
local function arm()
  local b = load(BUILD)
  if not b then log('arm: build not found'); return end
  log('arm: before ' .. buildState(b))
  if not ORIG then
    local o = {}
    try(function() b.Affixes:ForEach(function(_, el) o[#o + 1] = full(el:get()):match('^%S+%s+(.+)$') end) end)
    ORIG = { paths = o, unlocked = try(function() return b.UnlockedAffixSlots end) }
  end
  local objs = {}
  for _, s in ipairs(lines('arm.txt')) do
    local p = pathOf(s)
    local a = p and load(p)
    if a then objs[#objs + 1] = a else log('arm: unknown affix ' .. s) end
  end
  setList(b, objs)
  local okU = pcall(function() if (b.UnlockedAffixSlots or 0) < #objs then b.UnlockedAffixSlots = #objs end end)
  log('arm: UnlockedAffixSlots raise ' .. tostring(okU))
  log('arm: after ' .. buildState(b))
end
local function restore()
  local b = load(BUILD)
  if not (b and ORIG) then log('restore: nothing to put back'); return end
  local objs = {}
  for _, p in ipairs(ORIG.paths) do local a = load(p); if a then objs[#objs + 1] = a end end
  setList(b, objs)
  pcall(function() b.UnlockedAffixSlots = ORIG.unlocked end)
  log('restore: after ' .. buildState(b))
  ORIG = nil
end

---------------------------------------------------------------------------------------------------- check (in a race)
local function check()
  for _, pm in ipairs(find('PassiveManagerComponent')) do
    local owner = try(function() return pm:GetOwner() end)
    local cfgs = {}
    try(function() pm.PassiveList:ForEach(function(_, el)
      local p = el:get()
      cfgs[#cfgs + 1] = nm(try(function() return p.Config end))
    end) end)
    log(('check: passives of %s (%s): %s'):format(nm(owner), nm(pm), #cfgs > 0 and table.concat(cfgs, ', ') or 'none'))
  end
  for _, ps in ipairs(find('GfnPlayerState')) do
    local name = try(function() return ps.PlayerNamePrivate:ToString() end) or nm(ps)
    local parts = {}
    try(function() ps.RacerBuildState.VehicleBuilds:ForEach(function(i, el)
      local vb = el:get()
      local a = {}
      try(function() vb.AffixSlots:ForEach(function(_, s)
        local x = s:get()
        a[#a + 1] = nm(try(function() return x.PrimaryAffix end)) .. '/' .. tostring(try(function() return x.Status end))
      end) end)
      parts[#parts + 1] = ('build%d unlocked=%s [%s]'):format(i, tostring(try(function() return vb.UnlockedAffixSlots end)), table.concat(a, ', '))
    end) end)
    log(('check: race copy of %s: %s'):format(name, table.concat(parts, ' | ')))
  end
end

---------------------------------------------------------------------------------------------------- strip (race load)
local STRIP -- ticks left while waiting for the bots (100 ms each)
local function passivesOf(ps)
  for _, pm in ipairs(find('PassiveManagerComponent')) do
    local owner = try(function() return pm:GetOwner() end)
    if alive(owner) and try(function() return owner:GetAddress() end) == try(function() return ps:GetAddress() end) then
      return try(function() return pm.PassiveList:GetArrayNum() end) or -1
    end
  end
  return -2
end
local function strip()
  local bots = {}
  for _, ps in ipairs(find('GfnPlayerState')) do
    if try(function() return ps.bIsABot end) == true then
      local n = try(function() return ps.RacerBuildState.VehicleBuilds:GetArrayNum() end) or 0
      if n == 0 then return false end
      bots[#bots + 1] = ps
    end
  end
  if #bots == 0 then return false end
  local cleared, failed, before = 0, 0, {}
  for _, ps in ipairs(bots) do
    before[#before + 1] = tostring(passivesOf(ps))
    local vb = ps.RacerBuildState.VehicleBuilds
    for b = 1, vb:GetArrayNum() do
      local slots = vb[b].AffixSlots
      for j = 1, slots:GetArrayNum() do
        local had = alive(try(function() return slots[j].PrimaryAffix end))
        if had then
          local ok = pcall(function() slots[j].PrimaryAffix = CreateInvalidObject(); slots[j].Status = 0 end)
          if ok and not alive(try(function() return slots[j].PrimaryAffix end)) then cleared = cleared + 1 else failed = failed + 1 end
        end
      end
    end
  end
  log(('strip: %d bots, %d affix slots cleared, %d failed; bots\' passive counts at that moment: %s'):format(#bots, cleared,
    failed, table.concat(before, ',')))
  return true
end

LoopInGameThreadWithDelay(100, function()
  if STRIP then
    STRIP = STRIP - 1
    local ok, done = pcall(strip)
    if not ok then log('strip error: ' .. tostring(done)); STRIP = nil
    elseif done then STRIP = nil
    elseif STRIP <= 0 then log('strip: gave up (no bots appeared)'); STRIP = nil end
  end
  return false
end)

local tick = 0
LoopInGameThreadWithDelay(1000, function()
  if exists('strip.txt') and not STRIP then os.remove(DIR .. 'strip.txt'); STRIP = 1200; log('strip: armed for the next race load') end
  tick = tick + 1
  for _, t in ipairs({ { 'dump.txt', dump }, { 'arm.txt', arm }, { 'check.txt', check }, { 'restore.txt', restore } }) do
    if exists(t[1]) then
      local ok, err = pcall(t[2])
      if not ok then log(t[1] .. ' error: ' .. tostring(err)) end
      os.remove(DIR .. t[1])
    end
  end
  return false
end)
log('ModRecon loaded (' .. tostring((function() local n = 0; for _ in pairs(PATHS) do n = n + 1 end; return n end)()) .. ' affix paths)')
