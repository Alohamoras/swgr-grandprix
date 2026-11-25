-- Galactic Grand Prix v0.32.8: the CUP RESULT on the game's own end-of-tour screen (the owner's pick 10 of the FreeRace
-- list; docs/freerace-review-2026-11-25.md §6.1: the FreeRace mod's TOUR summary technique, our own code).
--
-- The game's PvP tour ends on WBP_PostRace_InstantAction_RunEnd: a timeline of planets with a dot per race (place,
-- wrecks), WINS / PARTICIPATION tiles and an XP progress panel. Here it is made over our last race's results screen
-- and filled with the cup: one PlanetStatVM per planet (one for a planet cup, five for the Galactic Cup, six for the
-- rally) holding a RunTimelineEntryVM per race (your place; the cup's last race gets the champion crown), a
-- RunFinishedVM with the finishes / top-3 / DNFs / wins / best streak, and the XP panel carrying your POINTS: one award
-- per race ("Race 2: THE WAR FIELDS, 2nd"), the bar your total against the cup's maximum. The panels are filled through
-- their own functions (RefreshPlanets, TriggerTimelineAnimation, UpdateWins, UpdateParticipation,
-- BeginProgressAnimationFromXPAwards), the numbers written into the texts a moment later as well.
-- Lessons taken from FreeRace's dozen builds (their comments): the screen is NEVER activated (its activation builds the
-- PvP tour's view models and binds Continue to the PvP flow); the screen's own TourPlanetsToShow carries the planets,
-- the timeline's starts EMPTY (RefreshPlanets adds to it: filled twice, every planet showed twice); the progress panel
-- adds each award to its total itself (preset to the total it showed double); the gamepad cannot reach a screen that
-- is not activated, so the results screen stays under it, see-through, with our CUP RESULT button focused: A presses
-- that button again, which closes the summary and leaves for the menu (Enter / Backspace / Escape do the same through
-- chain.lua's flags); AddToViewport under 10000 drew under the menu; the timeline's race widgets only show the place
-- for a podium, so each one's place box is shown for every race, found by class a few times while the timeline plays in.
-- Nothing is kept between ticks but the screen's path + address and numbers; the view models are told apart by address.
-- Config CupResult.Native = false: the old flow (CUP RESULT goes straight to our cup result page at the menu, which
-- still follows either way).
local C = require('core')
local cfg = require('config')
local K = require('gp')
local CU = require('cup')
local try, alive, log = C.try, C.alive, C.log

local CE = { live = nil }
CE.SCREEN = '/Game/Griffin/UI/Screens/PostRace/WBP_PostRace_InstantAction_RunEnd.WBP_PostRace_InstantAction_RunEnd_C'
CE.EVENT = 'WBP_RunRecap_Event_C'
local VM = '/Script/Griffin.'
local Z = 10000
local ACT_STANDARD, ACT_CHAMPION = 2, 6     -- ECampaignMapNodeActivity: the dot on the timeline (the crown)
local VIS_COLLAPSED, VIS_SELF_HIT_INVISIBLE = 1, 4

local function conf() return type(cfg.CupResult) == 'table' and cfg.CupResult or {} end
function CE.on() return conf().Native ~= false end
local function fixupMs() return (tonumber(conf().FixupS) or 12) * 1000 end
function CE.closeMs() return (tonumber(conf().CloseS) or 120) * 1000 end
-- v0.32.9 (owner, after the first one in game: "I love the layout ... I'd rather have something more prominent that
-- just says how I did overall in the cup (gold / silver medal etc.)" than the wins-in-a-row and races-in-a-row tiles):
-- the WINS tile carries the trophy - one medal in the trophy's colour, "GOLD TROPHY" over "1ST" - and the
-- participation tile your points and podiums. Config CupResult.Tiles = 'streaks' keeps the game's own meaning.
-- v0.34.2 (owner, after the Ando cup 2026-11-25: "Participation streak and win count seem superfluous, replace those
-- with just the trophy or ending standing of the cup"): Tiles = 'trophy' (the default) - the participation tile is
-- collapsed and its UpdateParticipation never called; the WINS tile is the trophy (the medal in its colour, "GOLD
-- TROPHY" over your standing "1ST"); the screen's title line says the trophy and the standing too ("ANDO CUP  -  JUNKER
-- -  GOLD TROPHY, 1ST"), in case the tile's texts are bound to the game's numbers (a read-back line in the log,
-- `[cupend] tiles read back`, says what the texts hold a while after our writes). 'result' = v0.32.9's two tiles.
local MEDAL = { GOLD = { R = 1.0, G = 0.78, B = 0.2, A = 1 }, SILVER = { R = 0.8, G = 0.8, B = 0.85, A = 1 }, BRONZE = { R = 0.8, G = 0.5, B = 0.25, A = 1 } }
local function tilesMode() local t = conf().Tiles; return (t == 'streaks' or t == 'result') and t or 'trophy' end
local function resultTiles() return tilesMode() ~= 'streaks' end
local function trophyName(sm) return type(sm.trophy) == 'string' and sm.trophy:upper() or nil end
local function standing(sm) return sm.rank and C.ordinal(sm.rank):upper() or '-' end
-- the trophy and the standing as one line ("GOLD TROPHY, 1ST" / "NO TROPHY, 5TH")
local function verdict(sm) return ((trophyName(sm) and (trophyName(sm) .. ' TROPHY')) or 'NO TROPHY') .. ', ' .. standing(sm) end
-- what a text block shows now (read-only; '-' = no such block, '?' = unreadable)
local function textOf(o, field)
  local t = alive(o) and try(function() return o[field] end)
  if not alive(t) then return '-' end
  local ft = try(function() return t:GetText() end)
  local s = ft and try(function() return ft:ToString() end)
  return type(s) == 'string' and s or '?'
end

---------------------------------------------------------------------------------------------------------------------
-- the cup as numbers: { races = { { title, planet (config entry), place (nil = DNF), pts, path } }, wins, top3, dnfs,
-- streak, total, max, rank, trophy, name }

function CE.summary(out)
  local run = out and out.run
  if type(run) ~= 'table' then return nil end
  local list, hist = K.runRaces(run), run.history or {}
  local races, wins, top3, dnfs, streak, best = {}, 0, 0, 0, 0, 0
  for i, race in ipairs(list) do
    local me
    for _, r in ipairs(hist[i] or {}) do if r.key == CU.YOU then me = r end end
    local place = (me and not me.dnf and tonumber(me.place)) or nil
    if not place then dnfs = dnfs + 1; streak = 0
    else
      if place == 1 then wins = wins + 1; streak = streak + 1 else streak = 0 end
      if place <= 3 then top3 = top3 + 1 end
    end
    if streak > best then best = streak end
    races[i] = { title = race.shown or race.title or '?', planet = K.planetOf(race.path), place = place, pts = (me and tonumber(me.pts)) or 0, path = race.path,
      finale = race.boss == true } -- (v0.33: the Galactic Cup's finale, Kestar's 1 v 1: no points)
  end
  local cup = K.cup(run.cup)
  local pts = type(cfg.Points) == 'table' and tonumber(cfg.Points[1]) or 15
  local scored = 0
  for _, r in ipairs(races) do if not r.finale then scored = scored + 1 end end
  -- (your points: out.pts from K.record; the sum of the races' points when it isn't there)
  local total = tonumber(out.pts)
  if not total then total = 0; for _, r in ipairs(races) do total = total + r.pts end end
  return { races = races, wins = wins, top3 = top3, dnfs = dnfs, streak = best, total = total,
    max = pts * scored, rank = tonumber(out.rank), trophy = out.trophy, name = cup and cup.name or tostring(run.cup),
    league = K.leagueName(run.class), timed = run.timed == true, finale = type(out.finale) == 'table' and out.finale or nil }
end

---------------------------------------------------------------------------------------------------------------------
-- building the screen

local function new(clsName, outer)
  local c = try(StaticFindObject, VM .. clsName)
  if not alive(c) then log('[cupend] class ' .. clsName .. ' not found'); return nil end
  local o = try(StaticConstructObject, c, outer)
  if not alive(o) then log('[cupend] ' .. clsName .. ' could not be made') end
  return alive(o) and o or nil
end
local function set(o, field, v) return pcall(function() o[field] = v end) end
-- an array property filled from a list: the list whole, then element by element when the count doesn't read back
local function setList(o, field, list)
  pcall(function() o[field] = list end)
  local n = try(function() return o[field]:GetArrayNum() end)
  if n ~= #list then
    local a = try(function() return o[field] end)
    if a then for i, v in ipairs(list) do pcall(function() a[i] = v end) end end
    n = try(function() return o[field]:GetArrayNum() end)
    if type(n) ~= 'number' then n = (type(a) == 'table') and #a or -1 end
  end
  return n
end
-- the game's planet definitions by the name they show (one sweep, at the cup's end only)
local function planetDefs()
  local by = {}
  for _, p in ipairs(C.find('PlanetDef')) do
    local n = C.text(p, 'PlayerFacingName')
    if n and not by[n] then by[n] = p end
  end
  return by
end

local function fill(w, sm)
  local defs = planetDefs()
  local d = { byVm = {}, order = {} }
  -- the planets in the order first raced, a timeline entry per race there
  local planets, by = {}, {}
  for i, r in ipairs(sm.races) do
    local pname = r.planet and r.planet.name or ('?' .. i)
    local p = by[pname]
    if not p then
      p = { name = pname, def = defs[pname], entries = {} }
      by[pname] = p
      planets[#planets + 1] = p
    end
    local e = new('RunTimelineEntryVM', w)
    if e then
      set(e, 'FinishPosition', r.place or 0)
      set(e, 'NumberOfWrecks', 0)
      -- (the crown on the cup's last race; v0.33: on the finale only when you won it)
      set(e, 'Activity', (i == #sm.races and not (r.finale and r.place ~= 1)) and ACT_CHAMPION or ACT_STANDARD)
      local a = C.addr(e)
      if a then d.byVm[a] = r end
      p.entries[#p.entries + 1] = e
    end
  end
  local pvms, missing = {}, {}
  for i, p in ipairs(planets) do
    local v = new('PlanetStatVM', w)
    if v then
      if alive(p.def) then set(v, 'Planet', p.def) else missing[#missing + 1] = p.name end
      set(v, 'NumTimesVisited', #p.entries)
      set(v, 'bIsLocked', false)
      set(v, 'bIsFirstVisitedPlanet', i == 1)
      set(v, 'bIsLastVisitedPlanet', i == #planets)
      setList(v, 'TimelineEntries', p.entries)
      pvms[#pvms + 1] = v
    end
  end
  local run = new('RunFinishedVM', w)
  if run then
    set(run, 'RunSuccessful', true)
    set(run, 'NumEventFinishes', #sm.races - sm.dnfs)
    set(run, 'NumTop3EventFinishes', sm.top3)
    set(run, 'NumDNFs', sm.dnfs)
    set(run, 'RacesWon', sm.wins)
    set(run, 'HighestWinStreak', sm.streak)
    setList(run, 'TourPlanets', pvms)
    set(w, 'RunStatsVM', run)
  end
  local nShown = setList(w, 'TourPlanetsToShow', pvms)
  -- the XP panel: your points
  local awards = {}
  for i, r in ipairs(sm.races) do
    local what = r.place and C.ordinal(r.place) or 'DNF'
    if r.finale then
      -- v0.33: the finale's line: won - the champion; lost - who kept the title
      local fin = sm.finale or {}
      -- (v0.35.0: no "Finale:" / "Race 2:" labels - the timeline shows the order)
      what = r.place == 1 and ('%s CHAMPION'):format(tostring(fin.league or sm.league):upper()) or 'HE KEEPS THE TITLE'
      awards[#awards + 1] = { XP = 0, Tag = { TagName = FName('None') }, Reason = FText(('%s, ONE ON ONE   -   %s'):format(tostring(fin.vs or 'Kestar Bool'):upper(), what)) }
    else
      awards[#awards + 1] = { XP = r.pts, Tag = { TagName = FName('None') }, Reason = FText(('%s, %s'):format(r.title, what)) }
    end
  end
  local xp = new('PvpXPResultsVM', w)
  if xp then
    set(xp, 'StartRank', 1); set(xp, 'CurrentRank', 1); set(xp, 'NextRank', 2)
    set(xp, 'CurrentXP', 0); set(xp, 'CurrentRankXPThreshold', 0); set(xp, 'NextRankXPThreshold', math.max(1, sm.max))
    set(xp, 'TotalXPEarned', sm.total)
    setList(xp, 'XPAwards', awards)
    set(w, 'XPVM', xp)
  end
  d.run, d.xp, d.pvms, d.awards = run, xp, pvms, awards
  log(('[cupend] view models: %d planets (%d shown%s), %d races, %d awards = %d points of %d'):format(#pvms, tonumber(nShown) or -1,
    #missing > 0 and ('; no PlanetDef for ' .. table.concat(missing, ', ')) or '', #sm.races, #awards, sm.total, sm.max))
  return d
end

-- the panels filled through their own functions
local function panels(w, d, sm)
  local function sub(name) local o = try(function() return w[name] end); return alive(o) and o or nil end
  local tl, wins, part, prog = sub('WBP_Timeline'), sub('WBP_MP_Wins'), sub('WBP_MP_Participation'), sub('WBP_MP_Progress')
  local ok = {}
  local function call(label, f) ok[#ok + 1] = label .. (try(function() f(); return true end) == true and '' or ' (failed)') end
  if tl then
    local hb = try(function() return tl.HB_Planets end)
    if alive(hb) then try(function() hb:ClearChildren() end) end
    if d.run then set(tl, 'RunVM', d.run) end
    pcall(function() tl.TourPlanetsToShow = {} end)   -- (RefreshPlanets fills the timeline's own list: empty first)
  end
  call('RefreshPlanets', function() w:RefreshPlanets() end)
  if tl then call('TriggerTimelineAnimation', function() tl:TriggerTimelineAnimation() end) end
  if wins then
    if resultTiles() then
      -- the trophy as the medal: its colour on the tile, one medal drawn (none without a trophy)
      local t = trophyName(sm)
      if t and MEDAL[t] then set(wins, 'MedalColour', MEDAL[t]) end
      call('UpdateWins', function() wins:UpdateWins(t and 1 or 0) end)
    else
      call('UpdateWins', function() wins:UpdateWins(sm.wins) end)
    end
  end
  if part then
    if tilesMode() == 'trophy' then
      -- v0.34.2: the participation tile goes (the owner: superfluous); its function never called
      ok[#ok + 1] = 'Participation hidden' .. (try(function() part:SetVisibility(VIS_COLLAPSED); return true end) == true and '' or ' (failed)')
    else
      call('UpdateParticipation', function() part:UpdateParticipation(#sm.races - sm.dnfs, sm.streak) end)
    end
  end
  if prog then
    if d.xp then set(prog, 'PVPXPVM', d.xp) end
    set(prog, 'StartRank', 1); set(prog, 'CurrentRank', 1); set(prog, 'NextRank', 2); set(prog, 'StartXP', 0)
    set(prog, 'TotalXPEarned', 0)                      -- (the animation adds each award itself)
    set(prog, 'NextXPThreshold', math.max(1, sm.max))
    setList(prog, 'XPAwards', d.awards)
    call('BeginProgressAnimationFromXPAwards', function() prog:BeginProgressAnimationFromXPAwards() end)
  end
  -- the screen's title: the cup and the league (the title widget's text block, whichever name it has)
  local title = sub('WBP_Screen_Title')
  if title then
    local text = ('%s  -  %s'):format(sm.name, sm.league)
    if tilesMode() == 'trophy' then text = text .. '  -  ' .. verdict(sm) end
    if sm.finale and sm.finale.won then text = text .. '  -  CHAMPION' end
    local done = false
    for _, f in ipairs({ 'Txt_Title', 'Txt_Label', 'Txt_Header' }) do
      local t = try(function() return title[f] end)
      if alive(t) and pcall(function() t:SetText(FText(text)) end) then done = true; break end
    end
    if not done then try(function() title:SetText(FText(text)) end) end
  end
  log('[cupend] panels: ' .. table.concat(ok, ', '))
end

-- the numbers into the texts the panels' own set-up may not show (a moment after the panels, then again later)
local function direct(w, sm, readBack)
  local function put(holder, field, s)
    local o = try(function() return w[holder] end)
    local t = alive(o) and try(function() return o[field] end)
    if alive(t) then try(function() t:SetText(FText(s)) end) end
  end
  if readBack then
    -- v0.34.2: what the texts hold now, before this pass writes them again - bound texts would show the game's numbers
    local wins, part = try(function() return w.WBP_MP_Wins end), try(function() return w.WBP_MP_Participation end)
    log(('[cupend] tiles read back (%s): Wins label=%s amount=%s | Participation vis=%s races=%s streak=%s'):format(tilesMode(),
      textOf(wins, 'Txt_Label'), textOf(wins, 'Txt_Amount'), tostring(alive(part) and try(function() return part:GetVisibility() end) or '-'),
      textOf(part, 'Txt_Amount_1'), textOf(part, 'Txt_WinsAmount')))
  end
  if tilesMode() == 'trophy' then
    -- the WINS tile: the trophy over your standing; the participation tile kept collapsed (the game's set-up may show it)
    local t = trophyName(sm)
    put('WBP_MP_Wins', 'Txt_Label', t and (t .. ' TROPHY') or 'NO TROPHY')
    put('WBP_MP_Wins', 'Txt_Amount', standing(sm))
    local part = try(function() return w.WBP_MP_Participation end)
    if alive(part) then try(function() part:SetVisibility(VIS_COLLAPSED) end) end
  elseif resultTiles() then
    -- the WINS tile: the trophy and your place; the participation tile: points and podiums
    local t = trophyName(sm)
    put('WBP_MP_Wins', 'Txt_Label', t and (t .. ' TROPHY') or 'NO TROPHY')
    put('WBP_MP_Wins', 'Txt_Amount', sm.rank and C.ordinal(sm.rank):upper() or '-')
    put('WBP_MP_Participation', 'Txt_WinRaces', 'POINTS')
    put('WBP_MP_Participation', 'Txt_WinsAmount', ('%d / %d'):format(sm.total, sm.max))
    put('WBP_MP_Participation', 'Txt_Races', 'PODIUMS')
    put('WBP_MP_Participation', 'Txt_Amount_1', ('%d OF %d'):format(sm.top3, #sm.races))
  else
    put('WBP_MP_Wins', 'Txt_Amount', tostring(sm.wins))
    put('WBP_MP_Participation', 'Txt_Amount_1', tostring(#sm.races - sm.dnfs))
    put('WBP_MP_Participation', 'Txt_WinsAmount', tostring(sm.streak))
  end
  put('WBP_MP_Progress', 'Txt_RankThreshold', ('%d / %d'):format(sm.total, sm.max))
  if sm.rank then put('WBP_MP_Progress', 'Txt_CurrentRank', C.ordinal(sm.rank)) end
  if type(sm.trophy) == 'string' then put('WBP_MP_Progress', 'Txt_NextRank', sm.trophy:upper()) end
end

-- v0.33 recon (once per summary, for the cups page's planets - art.lua A.ball): what the timeline's planet widgets
-- draw: each child of the planets box, its class and the texture behind the first image field found. Read only.
local function planetPictures(w)
  local tl = try(function() return w.WBP_Timeline end)
  local hb = alive(tl) and try(function() return tl.HB_Planets end)
  local n = alive(hb) and try(function() return hb:GetChildrenCount() end)
  if type(n) ~= 'number' or n < 1 then return nil end
  local out = {}
  for i = 0, math.min(n, 8) - 1 do
    local c = try(function() return hb:GetChildAt(i) end)
    if alive(c) then
      local found = {}
      for _, f in ipairs({ 'Img_Planet', 'Img_PlanetIcon', 'Img_Planet_Icon', 'Image_Planet', 'Img_Icon', 'Img_Bg', 'Img_Background' }) do
        local img = try(function() return c[f] end)
        local res = alive(img) and try(function() return img.Brush.ResourceObject end)
        if alive(res) then found[#found + 1] = f .. '=' .. tostring(try(function() return res:GetFName():ToString() end)) end
      end
      out[#out + 1] = tostring(C.clsname(c)) .. (#found > 0 and (' (' .. table.concat(found, ' ') .. ')') or '')
    end
  end
  return table.concat(out, ', ')
end

-- the timeline's race widgets show the place for a podium only: the place box shown for every race (matched to its
-- race by its view model's address), a few times while the timeline plays in
local function places(st)
  local n = 0
  for _, e in ipairs(C.find(CE.EVENT)) do
    local vm = try(function() return e['Timeline Event VM'] end)
    local r = alive(vm) and st.byVm[C.addr(vm)]
    if r then
      n = n + 1
      local function vis(f, v) local o = try(function() return e[f] end); if alive(o) then try(function() o:SetVisibility(v) end) end end
      vis('SzB_SecondaryInfo', VIS_SELF_HIT_INVISIBLE)
      local ws = try(function() return e.WS_SecondaryInfo end)
      if alive(ws) then try(function() ws:SetActiveWidgetIndex(r.place and 0 or 1) end) end
      vis('HB_PositionInfo', VIS_SELF_HIT_INVISIBLE); vis('Txt_Position', VIS_SELF_HIT_INVISIBLE)
      vis('SzB_MPInfo', VIS_COLLAPSED)             -- (the PvP tour's takedown skull: not ours)
      local t = try(function() return e.Txt_Position end)
      if alive(t) and r.place then try(function() t:SetText(FText(tostring(r.place))) end) end
    end
  end
  return n
end

---------------------------------------------------------------------------------------------------------------------
-- show / tick / close

-- the summary over the results screen (out = the recorded cup result). Returns the screen, or nil + why.
function CE.show(out)
  if not CE.on() then return nil, 'CupResult.Native is off' end
  if CE.live then return nil, 'a summary is already up' end
  local sm = CE.summary(out)
  if not sm or #sm.races == 0 then return nil, 'no cup to show' end
  local pc, lib, cls = C.localPC(), C.lib('WidgetBlueprintLibrary', 'UMG'), C.uclass(CE.SCREEN)
  if not alive(pc) then return nil, 'no player controller' end
  if not alive(lib) then return nil, 'no widget library' end
  if not cls then return nil, 'the tour-end screen class is not loaded' end
  local w = try(function() return lib:Create(pc, cls, pc) end)
  if not alive(w) then return nil, 'the screen could not be made' end
  local d = fill(w, sm)
  try(function() w:AddToViewport(Z) end)
  panels(w, d, sm)
  local cont = try(function() return w.WBP_Continue end)
  if alive(cont) then try(function() cont:SetVisibility(3) end) end   -- a hint only (HitTestInvisible)
  CE.live = { ref = C.ref(w), at = C.clock, sm = sm, byVm = d.byVm, lastPlaces = -1e9, direct = 0 }
  log(('[cupend] the cup result on the game\'s tour-end screen: %s, %s - %s, %d points, %d wins, %d DNF'):format(sm.name, sm.league,
    sm.rank and C.ordinal(sm.rank) or '?', sm.total, sm.wins, sm.dnfs))
  return w
end

-- every tick while it is up (chain.lua): the place boxes while the timeline plays in, the texts; false once it is gone
function CE.tick()
  local st = CE.live
  if not st then return false end
  local w = C.deref(st.ref)
  if not w then CE.live = nil; log('[cupend] the summary went with its screen'); return false end
  local age = C.clock - st.at
  if age <= fixupMs() and C.clock - st.lastPlaces >= 500 then
    st.lastPlaces = C.clock
    local n = places(st)
    if n > 0 and not st.placesSaid then st.placesSaid = true; log(('[cupend] timeline race widgets: %d, place boxes shown'):format(n)) end
  end
  if (st.direct == 0 and age > 1000) or (st.direct == 1 and age > 2500) or (st.direct == 2 and age > 8000) or (st.direct == 3 and age > 20000) then
    st.direct = st.direct + 1
    direct(w, st.sm, st.direct == 4)      -- (the last pass reads the texts back first: did ours stick?)
    if st.direct == 2 then
      local pics = planetPictures(w)
      if pics then log('[cupend] the timeline\'s planet widgets: ' .. pics) end
    end
  end
  return true
end

function CE.close(why)
  local st = CE.live
  CE.live = nil
  if not st then return false end
  local w = C.deref(st.ref)
  if w then try(function() w:RemoveFromParent() end) end
  log('[cupend] summary closed (' .. tostring(why) .. ')')
  return w ~= nil
end

return CE
