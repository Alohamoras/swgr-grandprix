-- v0.39.0 (owner 2026-11-25: "at the start of the race you are shown a 'time to beat'"; TASKS §1g-16): our own text
-- in a race - "TIME TO BEAT  1:12.40" (your lap record on this track at this league; none yet = "NO LAP SET") on screen
-- through the countdown, gone at the green light. Config TimeToBeat.
--
-- The first text we ever drew in a race (the spike, KNOWLEDGE.md §6). Two routes, config TimeToBeat.Route:
--   'viewport': a plain UserWidget of our own (UMG's native class, its WidgetTree given a CanvasPanel root with the
--               text in it), added to the viewport over the HUD;
--   'hud':      the text added into the canvas of the game's own countdown widget's parent (the HUD's tree).
-- Rules kept: no hooks; nothing kept between ticks but C.ref (path + address); only before the start (a sweep every
-- TICK_MS while the countdown runs - nobody is racing yet), nothing after; stands aside while another mod has set the
-- shared HUD flag TheaterShowHidesHud (FreeRace / Theater). Every step is logged as [lapshow].
local C = require('core')
local cfg = require('config')
local K = require('gp')
local log, try, alive = C.log, C.try, C.alive

local LS = {}
local TICK_MS = 250
local COUNTDOWN = 'WBP_Hud_Countdown_C'

local function conf() local t = cfg.TimeToBeat; return type(t) == 'table' and t or nil end
function LS.on() local t = conf(); return t ~= nil and t.On ~= false end

-- the line for a race: your lap record at this league on this track (gp.lua records[league][path].lap)
function LS.text(ev)
  if not (ev and ev.class and ev.path) then return nil end
  local rec = ((K.data.records or {})[ev.class] or {})[ev.path]
  local lap = rec and tonumber(rec.lap)
  if lap and lap > 0 then return 'TIME TO BEAT  ' .. K.fmtTime(lap) end
  return 'NO LAP SET'
end

-- at launch (race.lua R.launch): the job, or nil. Never on a finale / title race (no records) or a rally stage (the
-- rally's own clock is the total; v1 shows nothing there)
function LS.start(ev)
  if not LS.on() or not ev or ev.boss or ev.titleRace then return nil end
  local s = LS.text(ev)
  if not s then return nil end
  return { text = s, last = -1e9 }
end

local function hudHidden()
  local ok, v = pcall(function() return ModRef:GetSharedVariable('TheaterShowHidesHud') end)
  return ok and v == true
end

local function make(cls, outer)
  local c = try(StaticFindObject, cls)
  return alive(c) and alive(outer) and try(StaticConstructObject, c, outer) or nil
end

-- the text block: the game's display font, white with a shadow
local function textBlock(outer, s)
  local t = make('/Script/UMG.TextBlock', outer)
  if not alive(t) then return nil end
  local tc = conf() or {}
  try(function() t:SetText(FText(s)) end)
  local col = tc.Color or { 1, 1, 1 }
  try(function() t:SetColorAndOpacity({ SpecifiedColor = { R = col[1], G = col[2], B = col[3], A = 1 }, ColorUseRule = 0 }) end)
  try(function() t:SetShadowOffset({ X = 3, Y = 3 }) end)
  try(function() t:SetShadowColorAndOpacity({ R = 0, G = 0, B = 0, A = 0.75 }) end)
  try(function() t:SetJustification(1) end)
  local fpath = ((cfg.GameFonts or {}).display or {})[1]
  local fo = fpath and C.asset(fpath) or nil   -- (looked up each time: nothing kept between races)
  try(function()
    local f = t.Font
    f.Size = tonumber(tc.Size) or 44
    if alive(fo) then f.FontObject = fo end
    t:SetFont(f)
  end)
  return t
end

-- a canvas child placed at the top centre (TimeToBeat.Y = the share of the screen height down)
local function place(canvas, w)
  local slot = try(function() return canvas:AddChildToCanvas(w) end)
  if not alive(slot) then return false end
  local y = tonumber((conf() or {}).Y) or 0.3
  try(function() slot:SetAnchors({ Minimum = { X = 0.5, Y = y }, Maximum = { X = 0.5, Y = y } }) end)
  try(function() slot:SetAlignment({ X = 0.5, Y = 0.5 }) end)
  try(function() slot:SetAutoSize(true) end)
  try(function() slot:SetZOrder(50) end)
  return true
end

local function showViewport(job)
  local pc, lib = C.localPC(), C.lib('WidgetBlueprintLibrary', 'UMG')
  local uw = try(StaticFindObject, '/Script/UMG.UserWidget')
  local w = (alive(pc) and alive(lib) and alive(uw)) and try(function() return lib:Create(pc, uw, pc) end)
  if not alive(w) then return false, 'no UserWidget' end
  local tree = try(function() return w.WidgetTree end)
  if not alive(tree) then
    tree = make('/Script/UMG.WidgetTree', w)
    if alive(tree) then try(function() w.WidgetTree = tree end) end
  end
  if not alive(tree) then return false, 'no widget tree' end
  local canvas = make('/Script/UMG.CanvasPanel', tree)
  local t = textBlock(tree, job.text)
  if not (alive(canvas) and alive(t)) then return false, 'no canvas / text' end
  try(function() tree.RootWidget = canvas end)
  if not place(canvas, t) then return false, 'not placed' end
  try(function() w:SetVisibility(4) end)          -- HitTestInvisible: never takes input
  try(function() w:AddToViewport(50) end)
  job.ref = C.ref(w)
  return true
end

local function showHud(job, cd)
  local p = try(function() return cd:GetParent() end)
  local hops = 0
  while alive(p) and hops < 6 and C.clsname(p) ~= 'CanvasPanel' do p = try(function() return p:GetParent() end); hops = hops + 1 end
  if not alive(p) then return false, 'no canvas above the countdown' end
  local outer = try(function() return p:GetOuter() end)
  local t = textBlock(alive(outer) and outer or p, job.text)
  if not alive(t) then return false, 'no text' end
  if not place(p, t) then return false, 'not placed' end
  job.ref = C.ref(t)
  return true
end

local function hide(job, why)
  local w = C.deref(job.ref)
  if w then try(function() w:RemoveFromParent() end) end
  job.ref = nil
  log(('[lapshow] off (%s)%s'):format(why, w and '' or ' - already gone'))
end

-- each race tick before the start; r.ls = the job, r.gsRef the race state. Returns nothing; marks job.done at the end
function LS.tick(r)
  local job = r.ls
  if not job or job.done then return end
  if C.clock - job.last < TICK_MS then return end
  job.last = C.clock
  local gs = C.deref(r.gsRef)
  local started = gs and try(function() return gs.bIsRaceStarted end) == true
  if started or r.startedAt then
    if job.ref then hide(job, 'green light') end
    job.done = true
    log(('[lapshow] done: %s'):format(job.shown and ('shown %.1f s by %s'):format((C.clock - job.shown) / 1000, job.route) or 'never shown'))
    return
  end
  if hudHidden() then
    if job.ref then hide(job, 'another mod hides the HUD') end
    return
  end
  -- the countdown: the race state's CountdownEndTime (set when it starts; the 2026-11-25 spike: the HUD's
  -- WBP_Hud_Countdown exists from the load with IsVisible() false, so its visibility is only logged)
  local cet = gs and try(function() return gs.CountdownEndTime end)
  local now = gs and try(function() return gs:GetServerWorldTimeSeconds() end)
  local counting = type(cet) == 'number' and type(now) == 'number' and cet > 0 and now < cet
  if counting and not job.cdAt then
    job.cdAt = C.clock
    log(('[lapshow] countdown running: %.1f s to the green light'):format(cet - now))
  end
  local cd = C.first(COUNTDOWN)
  local vis = alive(cd) and try(function() return cd:IsVisible() end)
  if alive(cd) and vis ~= job.vis then
    job.vis = vis
    log(('[lapshow] countdown widget %s visible %s (parent %s), CountdownEndTime %s, world time %s'):format(C.idname(cd),
      tostring(vis), C.clsname(try(function() return cd:GetParent() end)), tostring(cet), tostring(now)))
  end
  if job.ref or not (counting or vis) then return end
  local route = (conf() or {}).Route or 'viewport'
  local ok, why = false, nil
  if route == 'hud' then ok, why = showHud(job, cd) else ok, why = showViewport(job) end
  job.tries = (job.tries or 0) + 1
  if ok then
    job.shown, job.route = C.clock, route
    log(('[lapshow] "%s" shown (%s)'):format(job.text, route))
  else
    log(('[lapshow] %s route failed: %s'):format(route, tostring(why)))
    if job.tries >= 3 then job.done = true end
  end
end

-- the race went away before the start (quit, crash): drop what we drew
function LS.stop(r)
  local job = r and r.ls
  if job and job.ref then hide(job, 'race over') end
  if job then job.done = true end
end

return LS
