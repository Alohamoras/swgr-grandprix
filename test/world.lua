-- Scenario helpers on top of mock.lua: a main menu, a race, a return to the menu.
local M = require('mock')
local W = { pad = {} }

local function vec(x) return { X = x, Y = 0, Z = 0 } end

function W.widgetLib()
  local lib = StaticFindObject('/Script/UMG.Default__WidgetBlueprintLibrary')
  rawget(lib, '__props').Create = function(self, pc, cls, owner)
    local cname = rawget(cls, '__name') or 'W'
    local w = M.new('widget', {}, cname)
    local p = rawget(w, '__props')
    p.WidgetTree = M.new('WidgetTree', {})
    p.IsInViewport = function() return p.__inViewport == true end
    p.AddToViewport = function() p.__inViewport = true; M.add('UserWidget', w) end
    p.RemoveFromParent = function() p.__inViewport = false; M.kill(w) end
    p.IsHovered = function() return p.__hovered == true end
    p.SzB_SizeOverride = M.new('sz', {})
    p.Img_TileArt = M.new('img', {})
    p.Img_Icon = M.new('img', {})
    -- toggle tiles (v0.8.6+): selected state, and the game UI's focus
    p.GetSelected = function() return p.__sel == true end
    p.SetIsSelected = function(_, v) p.__sel = v end
    p.HasAnyUserFocus = function() return p.__focus == true end
    p.HasUserFocus = function() return p.__focus == true end
    p.HasKeyboardFocus = function() return p.__focus == true end
    if cname:find('Common_Btn', 1, true) then
      -- v0.19: a button of CONTINUE's class (chain.lua's NEXT RACE): its own name, registered (C.ref / C.deref)
      rawset(w, '__name', cname .. '_' .. rawget(w, '__addr'))
      M.add(cname, w)
      W.chainBtn = w
    end
    if cname == 'UserWidget' then W.tiles = {}
    elseif cname:find('Tile') then
      W.tiles = W.tiles or {}; table.insert(W.tiles, w)
      W.pending = W.pending or {}; table.insert(W.pending, w)
    elseif cname == 'CommonActivatableWidget' then
      -- tab page (v0.9): the Back screen is made right after a page's tiles - those are the page on screen
      p.IsActivated = function() return p.__active == true end
      p.ActivateWidget = function() p.__active = true end
      p.DeactivateWidget = function() p.__active = false end
      W.backs = W.backs or {}; table.insert(W.backs, w)
      W.tiles, W.pending = W.pending or {}, {}
    end
    return w
  end
end

function W.frontEnd()
  M.clear('FrontEndGameMode'); M.clear('RacingGameState'); M.clear('GfnPlayerState')
  W.fe = M.add('FrontEndGameMode', M.new('FrontEndGameMode_' .. M.nextAddr, {
    LaunchQuickRace = function(self, arch, ev, build)
      table.insert(M.calls, { name = 'LaunchQuickRace', args = { arch, ev, build } })
      W.launchRecipe(ev) -- v0.19: the game builds the race's recipe from the event
    end,
  }))
  if M.fireNew then M.fireNew('/Script/Griffin.FrontEndGameMode', W.fe) end
  W.mm = M.add('WBP_FE_MainMenu_C', M.new('WBP_FE_MainMenu_C_' .. M.nextAddr, {}, 'WBP_FE_MainMenu_C'))
  local mp = rawget(W.mm, '__props')
  mp.__vis = 4
  mp.IsInViewport = function() return true end
  mp.GetVisibility = function() return mp.__vis end
  mp.SetVisibility = function(_, v) mp.__vis = v end
  mp.IsActivated = function() return mp.__active ~= false end
end

-- a main menu with the game's tab bar and content switcher (v0.9 tab host)
local TAB_IDS = { 'Recommended', 'Campaign', 'Arcade', 'Multiplayer' }
function W.tabMenu()
  local ids, buttons = {}, {}
  for _, id in ipairs(TAB_IDS) do ids[#ids + 1] = id; buttons[id] = M.new('Btn_' .. id, {}, 'WBP_Tab_Btn_C') end
  W.tab = { ids = ids, buttons = buttons, selected = 'Recommended' }
  local tl = M.new('WBP_Tab_List', {
    GetTabCount = function() return #ids end,
    GetTabIdAtIndex = function(_, i) return ids[i + 1] end,
    GetTabButtonBaseByID = function(_, id) return buttons[id] end,
    GetSelectedTabId = function() return W.tab.selected end,
    SelectTabByID = function(_, id) if buttons[id] then W.tab.selected = id; return true end; return false end,
    RegisterTab = function(_, id, cls, stub, at)
      ids[#ids + 1] = id
      local b = M.new('Btn_' .. id, {}, 'WBP_Tab_Btn_C')
      rawget(b, '__props').SetText = function(_, t) W.tab.label = rawget(t, '__props').__text end
      buttons[id] = b
      return true
    end,
  }, 'WBP_Tab_List_C')
  local vb = M.new('VB_Content', {
    GetChildIndex = function() return 0 end,
    InsertChildAt = function(_, i, w) W.tab.page = w; return M.new('slot', {}) end,
  }, 'FuseVerticalBox')
  local ws = M.new('WS_ScreenContent', { GetParent = function() return vb end }, 'FuseWidgetSwitcher')
  local wp = rawget(ws, '__props')
  wp.__vis = 4
  wp.GetVisibility = function() return wp.__vis end
  wp.SetVisibility = function(_, v) wp.__vis = v end
  wp.GetActiveWidget = function() return M.new('WBP_FE_Recommended', {}) end
  local mp = rawget(W.mm, '__props')
  mp.WBP_Tab_List = tl
  mp.WS_ScreenContent = ws
  mp.WidgetTree = M.new('WidgetTree', { RootWidget = M.new('root', {}, 'Overlay') })
  mp.IsActivated = function() return mp.__active ~= false end
  W.tab.tl, W.tab.ws = tl, ws
  W.tabbed = true
end
-- simulate the player picking a tab (LB / RB / mouse)
function W.pickTab(id) W.tab.selected = id end

function W.setup()
  M.install()
  W.widgetLib()
  M.add('GfnGameInstance', M.new('GfnGameInstance', { PrimaryFlow = 0 }))
  W.pc = M.add('PlayerController', M.new('PC', {
    IsLocalPlayerController = function() return true end,
    IsInputKeyDown = function(self, k) return W.pad[k.KeyName] == true end,
  }))
  for i, n in ipairs({ 'VA_Car', 'VA_Plane', 'VA_Bike', 'VA_Skimmer' }) do
    M.add('VehicleArchetype', M.new(n, { archetype = i - 1 }))
  end
  local ksl = StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
  rawget(ksl, '__props').IsStandalone = function() return true end
  W.characterList()
  W.aiConfig()
  W.recipeSetup()
  W.frontEnd()
end

-- the game instance's character list (v0.8, menu dump 2026-11-10): the 16 racer defs as loaded assets, Player = Shade,
-- Opponents = the 11 of every quick-race grid in the game's order. Objects are named by their full path, as
-- GetFullName gives it in game ('RacerDef /Game/.../DA_Racer_X.DA_Racer_X').
local RACERS = '/Game/Griffin/Narrative/CharacterDefs/Racers/DA_Racer_'
W.RACER_NAMES = { Antagonist = 'Kestar Bool', DarkEnigma = 'Shade', ElegantProfessional = 'Katja Mox', Ghost = 'Goli & 02-R0',
  InnerHonour = 'Soren Zaks', Mentor = 'Sebulba', Mercenary = 'Malis Vazosk', Nomad = 'Fola Kanjen', Protege = 'Ary Quill',
  QuietStrength = 'Nik Skandaro', Rager = 'Biddy Blas', Star = 'Lyren Shok', Thrall = 'Sen Fira', Veteran = 'Griff Halloran',
  TestPilot = 'Autopilot', MentorBossRace = 'Sebulba' }
W.OPPONENTS = { 'Mercenary', 'ElegantProfessional', 'Star', 'InnerHonour', 'Thrall', 'Ghost', 'Rager', 'Nomad', 'Veteran',
  'QuietStrength', 'Protege' }
-- URacerDef.PreferredVehicleType as read in game 2026-11-11 (0 car, 2 bike, 3 skimmer; LookSpike log)
W.PREFERRED = { Mercenary = 2, ElegantProfessional = 2, Thrall = 2, Rager = 2, Veteran = 3, Ghost = 3, Nomad = 3, Star = 3,
  Mentor = 3, MentorBossRace = 3 }
function W.racerDef(key)
  local full = RACERS .. key .. '.DA_Racer_' .. key
  if not M.assets[full] then
    M.assets[full] = M.new(full, { CharacterName = FText(W.RACER_NAMES[key] or key), PreferredVehicleType = W.PREFERRED[key] or 0 }, 'RacerDef')
  end
  return M.assets[full]
end
function W.characterList()
  M.clear('CharacterList')
  for key in pairs(W.RACER_NAMES) do W.racerDef(key) end
  local opp = {}
  for i, key in ipairs(W.OPPONENTS) do opp[i] = W.racerDef(key) end
  W.opponents = opp
  local path = '/Game/Griffin/Narrative/CharacterDefs/DA_CharacterList'
  W.chars = M.new(path .. '.DA_CharacterList', { Player = W.racerDef('DarkEnigma'), Opponents = M.tarr(opp) }, 'CharacterList')
  M.assets[path .. '.DA_CharacterList'] = W.chars
  M.add('CharacterList', W.chars)
  return W.chars
end
-- the list as text for checks: 'Player=DarkEnigma Opp=Mercenary,ElegantProfessional,...'
function W.charsText()
  local p = rawget(W.chars, '__props')
  local function key(o) return (o and not rawget(o, '__dead')) and (rawget(o, '__name'):match('DA_Racer_([%w_]+)$') or '?') or '-' end
  local l = {}
  for i = 1, p.Opponents:GetArrayNum() do l[i] = key(p.Opponents[i]) end
  return 'Player=' .. key(p.Player) .. ' Opp=' .. table.concat(l, ',')
end

-- the AI config asset DA_AIConfig with the game's own values (MenuRecon 2026-11-10); W.ai = its fields (plain tables,
-- as UE4SS hands structs back by reference). The mod's ai.lua writes it at launch and puts it back at the menu.
function W.aiConfig()
  W.ai = {
    DefaultPacingSettings = { RacePacingLowestSpeedMph = 150, MaxAiCatchupScale = 1.3, MaxAiSlowdownScale = 0.75,
      AiAheadTimeToMaxSlowdown = 1.5, AiBehindTimeToMaxCatchup = 2, AiSlowdownDuringCrash = 0.5 },
    ForcedErrorChance = 15, ForcedErrorDuration = 8, DefaultPercentageChancePerfectStart = 75,
    AggressionConfig = { VersusAI = { Cooldown = 4, Chance = 100 }, VersusPlayer = { Cooldown = 2, Chance = 50 } },
    EnableSpeedMatchingZone = true, SpeedMatchingMaxMatchers = 2, SpeedMatchingSpeedLag = 5,
  }
  M.assets['/Game/Griffin/AI/DA_AIConfig.DA_AIConfig'] = M.new('DA_AIConfig', W.ai, 'RaceAIComponentConfig')
  W.pacingAssets()
  return W.ai
end
-- v0.16.1: the pacing assets RP_Default / RP_Honest (URacePacingConfig). Their values in game are not read yet: these
-- are made up (RP_Default as DA_AIConfig's but catch-up 1.2, RP_Honest no slowdown), so the tests can tell them apart.
-- W.rp.Default / W.rp.Honest = their fields.
function W.pacingAssets()
  W.rp = {}
  for name, pace in pairs({ Default = { 1.2, 0.75 }, Honest = { 1.25, 1.0 } }) do
    W.rp[name] = {
      PacingConfigs = M.tarr({ {}, {}, {}, {}, {} }),
      PacingSettingsConfig = { RacePacingLowestSpeedMph = 150, MaxAiCatchupScale = pace[1], MaxAiSlowdownScale = pace[2],
        AiAheadTimeToMaxSlowdown = 1.5, AiBehindTimeToMaxCatchup = 2, AiSlowdownDuringCrash = 0.5 },
    }
    local path = '/Game/Griffin/AI/Pacing/Default/RP_' .. name
    M.assets[path .. '.RP_' .. name] = M.new('RP_' .. name, W.rp[name], 'RacePacingConfig')
  end
end
-- n race tune objects (a GameTuneComponent each, its RaceTuneData.Config with the game's own rubber-band values);
-- returns the configs and the tune data objects
function W.tune(n)
  local confs, rtds = {}, {}
  for i = 1, n or 1 do
    confs[i] = { TotalCrashAllowance = 3, AiMaxTimeAheadModifier = 0, AiMinTimeAheadModifier = 0, AiMaxTimeAheadMultiplier = 1,
      AiMinTimeAheadMultiplier = 1, AiTimeAheadSlowdownModifier = 0, AiAggressionVPlayerCooldownMultiplier = 1,
      AiAggressionVPlayerChanceMultiplier = 1, AiCountdownToSlamPlayerModifier = 0, AiAbilityChanceMultiplier = 1 }
    rtds[i] = M.add('RaceTuneData', M.new('rtd' .. M.nextAddr, { Config = confs[i] }))
    M.add('GameTuneComponent', M.new('tc' .. M.nextAddr, { RaceTuneData = rtds[i] }))
  end
  return confs, rtds
end

-- a build asset with a slot map
function W.build(path, levels)
  local n = path:match('([^/]+)$')
  local full = path .. '.' .. n
  local slots = {}
  for i = 1, 4 do slots[i] = CreateInvalidObject() end
  -- Affixes: the build's own mod list (empty, as the game's base builds; v0.4), UnlockedAffixSlots 4
  local affixes = {}
  local b = M.new(n, { SlotToUpgradeLevelMap = M.tmap(levels or { [0] = 0, 0, 0, 0, 0, 0 }), AbilitySlots = M.tarr(slots),
    Affixes = M.tarr(affixes), UnlockedAffixSlots = 4, MaximumAffixSlots = 10 }, 'VehicleBuildDef')
  W.buildAffixes = W.buildAffixes or {}
  W.buildAffixes[n] = affixes
  W.buildSlots = W.buildSlots or {}
  W.buildSlots[n] = slots
  M.assets[full] = b
  return b
end
-- an event asset
function W.event(path, tag)
  local n = path:match('([^/]+)$')
  local e = M.new(n, { VehicleTypeTag = { TagName = { ToString = function() return tag or 'Vehicle.Standard' end } } }, 'RaceEventDef')
  M.assets[path .. '.' .. n] = e
  return e
end

-- a racer's build copies (one per vehicle type) with 4 ability slots each, starting as `slots`, and affix slots (4, or
-- as many as the launch build carries) holding the launch build's Affixes (the game copies them to every racer, bots
-- included: recon 2026-11-10)
local function buildCopies(slots)
  local copies = {}
  local mods = (W.buildAffixes or {}).VBD_Car_Base or {}
  for i = 1, 4 do
    local list = {}
    for j = 1, 4 do list[j] = slots[j] or CreateInvalidObject() end
    local aff = {}
    for j = 1, math.max(4, #mods) do aff[j] = { PrimaryAffix = mods[j] or CreateInvalidObject(), Status = mods[j] and 1 or 0 } end
    copies[i] = { AbilitySlots = M.tarr(list), AffixSlots = M.tarr(aff) }
  end
  return M.tarr(copies)
end
-- the affix names in a racer's first race copy ('-' = empty)
function W.affixes(ps)
  local st = rawget(ps, '__props').RacerBuildState.VehicleBuilds[1]
  local out = {}
  for j = 1, st.AffixSlots:GetArrayNum() do
    local a = st.AffixSlots[j].PrimaryAffix
    out[j] = (a and not rawget(a, '__dead')) and rawget(a, '__name') or '-'
  end
  return table.concat(out, ',')
end
W.buildCopies = buildCopies
W.BOT_NAMES = { 'Biddy Blas', 'Kestar Bool', 'Katja Mox', 'Zed Unknown', 'Sen Fira', 'Lyren Shok', 'Shade', 'Ary Quill',
  'Nik Skandaro', 'Fola Kanjen', 'Goli & 02-R0' }
-- race world with the player + bots. opts.noBuilds: bots have no build copies yet. Every racer starts with YOUR
-- abilities (W.yourAbility), as the game does.
function W.race(nBots, opts)
  opts = opts or {}
  M.kill(W.fe)
  M.kill(W.mm)
  W.yourAbility = W.yourAbility or M.new('BP_Ability_Autopilot_C', {}, 'Class')
  W.gs = M.add('RacingGameState', M.new('RacingGameState_' .. M.nextAddr, { bIsRaceStarted = true,
    EventRecipe = { EventStages = M.tarr({ W.stageCopy(W.activeStage()) }) }, EventRecipeState_Replication = { ActiveStage = 0 },
    AuthorityGameMode = W.gm }))
  W.rec = { EventPosition = 6, bHasFinishedEvent = false, CurrentLapNumber = 1 }
  W.player = M.add('GfnPlayerState', M.new('me', { bIsABot = false, RaceEventComponent = M.new('rec', W.rec),
    PlayerNamePrivate = FText('Dwayne'), RacerBuildState = { VehicleBuilds = buildCopies({ W.yourAbility }) },
    PawnPrivate = M.new('pawn', { GetVelocity = function() return vec(10000) end,
      BuildComponent = M.new('bc', { Active_Cornering = 1, Active_Acceleration = 2 }) }) }))
  W.bots = {}
  for i = 1, nBots or 3 do
    W.bots[i] = M.add('GfnPlayerState', M.new('bot' .. i, { bIsABot = true, RaceEventComponent = M.new('rec', { EventPosition = i }),
      PlayerNamePrivate = FText(W.BOT_NAMES[i] or ('Bot ' .. i)),
      RacerBuildState = { VehicleBuilds = opts.noBuilds and M.tarr({}) or buildCopies({ W.yourAbility }) },
      PawnPrivate = M.new('pawn', { GetVelocity = function() return vec(9000) end }) }))
  end
end
-- the slots of a racer's first build copy, as class names ('-' = empty)
function W.slots(ps, copy)
  local st = rawget(ps, '__props').RacerBuildState.VehicleBuilds[copy or 1]
  local out = {}
  for j = 1, st.AbilitySlots:GetArrayNum() do
    local c = st.AbilitySlots[j]
    out[j] = (c and not rawget(c, '__dead')) and rawget(c, '__name') or '-'
  end
  return table.concat(out, ',')
end
-- you finish in `pos`; time / lap (seconds) = the race time and best lap the component then shows (v0.8 records)
function W.finish(pos, time, lap)
  W.rec.EventPosition = pos; W.rec.bHasFinishedEvent = true
  if time then W.rec.EventFinishTime = time end
  if lap then W.rec.BestLapTime = lap end
end
-- bot i finishes in `pos` with race time `time` (seconds, EventFinishTime on its RaceEventComponent; v0.10 gap log).
-- No time = finished but no time shown (the gap log skips it); finished = false = still racing / DNF.
function W.botFinish(i, pos, time, finished)
  local rec = rawget(rawget(W.bots[i], '__props').RaceEventComponent, '__props')
  rec.EventPosition = pos
  rec.bHasFinishedEvent = finished ~= false
  rec.EventFinishTime = time or 0
end
-- a lap done: the best lap so far and the lap you're on
function W.lap(best, n) W.rec.BestLapTime = best; if n then W.rec.CurrentLapNumber = n end end
function W.backToMenu() W.dropRaceWorld(); W.frontEnd(); if W.tabbed then W.tabMenu() end end

---------------------------------------------------------------------------------------------------------------------
-- v0.19 (chain.lua): the race recipe, the results screen, the game's reset

-- an event with the fields the recipe copies (TrackDef, LapCount, TrackConditionTag); cond = 'TrackCondition.Night' etc.
function W.raceEvent(path, laps, cond)
  local n = path:match('([^/]+)$')
  local e = M.new(n, { VehicleTypeTag = { TagName = M.new('Vehicle.Standard', {}, 'FName') },
    TrackDef = M.new((n:gsub('^EVT_', 'TRAK_')), {}, 'TrackDef'), LapCount = laps or 2,
    TrackConditionTag = { TagName = M.new(cond or 'TrackCondition.Sunset', {}, 'FName') } }, 'RaceEventDef')
  M.assets[path .. '.' .. n] = e
  return e
end
-- every event of the config's cups (call after T.boot: the config is loaded by then)
function W.cupEvents()
  for _, cup in ipairs(require('config').Cups) do
    local lists = cup.races[1] and { cup.races } or cup.races
    for _, list in pairs(lists) do
      for _, r in ipairs(list) do
        local cond = r.cond and ('TrackCondition.' .. r.cond:gsub(',.*', ''):gsub('%s', '')) or 'TrackCondition.Sunset'
        if not M.assets[r.path .. '.' .. r.path:match('([^/]+)$')] then W.raceEvent(r.path, r.laps, cond) end
      end
    end
  end
end
-- one stage of a recipe (FRaceEventInstance: the four fields chain.lua reads and writes) from an event
local function stageOf(ev)
  local function f(k) local ok, v = pcall(function() return rawget(ev, '__props')[k] end); return ok and v or nil end
  local tag = f('TrackConditionTag')
  return { AuthoredEvent = ev, TrackDef = f('TrackDef'), LapCount = tonumber(f('LapCount')) or 2,
    trackConditions = { TagName = type(tag) == 'table' and tag.TagName or nil } }
end
function W.stageCopy(st)
  if not st then return {} end
  return { AuthoredEvent = st.AuthoredEvent, TrackDef = st.TrackDef, LapCount = st.LapCount,
    trackConditions = { TagName = st.trackConditions and st.trackConditions.TagName } }
end
-- the game instance's EventRecipeSubsystem (lives on across race worlds); ActiveRecipe = nil until a launch
function W.recipeSetup()
  W.sub = M.add('EventRecipeSubsystem', M.new('EventRecipeSubsystem', {}))
  -- the racing game mode: RequestResetRace = a new race world from the subsystem's recipe (W.resetMode = 'nothing':
  -- the reset does nothing; 'empty' (v0.19.1, the v0.19.0 hang in game): a new race world with you only, no AI racer
  -- ever); RequestReturnToMenus = counted (the test then goes back to the menu)
  W.resets, W.toMenu, W.resetMode, W.noRecipe = 0, 0, nil, nil
  W.gm = M.new('BP_RacingGameMode_C_1', {
    RequestResetRace = function()
      W.resets = W.resets + 1
      if W.resetMode == 'empty' then W.dropRaceWorld(); W.race(0); rawget(W.gs, '__props').bIsRaceStarted = false
      elseif W.resetMode ~= 'nothing' then W.chainWorld() end
    end,
    RequestReturnToMenus = function() W.toMenu = W.toMenu + 1 end,
  }, 'BP_RacingGameMode_C')
end
function W.launchRecipe(ev)
  if W.noRecipe then rawget(W.sub, '__props').ActiveRecipe = nil; return end
  local inst = M.add('EventRecipeInstance', M.new('EventRecipeInstance_' .. M.nextAddr, {
    recipe = { EventStages = M.tarr({ stageOf(ev) }) }, RecipeState = { ActiveStage = 0 } }, 'EventRecipeInstance'))
  rawget(W.sub, '__props').ActiveRecipe = inst
  W.recipe = inst
end
function W.activeStage()
  local inst = W.sub and rawget(W.sub, '__props').ActiveRecipe
  return inst and rawget(inst, '__props').recipe.EventStages[1] or nil
end
-- the event name of a stage ('?' if none)
function W.stageEvent(st) return st and st.AuthoredEvent and rawget(st.AuthoredEvent, '__name') or '?' end
-- the race world goes (the reset or the menu): its race state, racers, results screen and our widgets on it
function W.dropRaceWorld()
  for _, cls in ipairs({ 'RacingGameState', 'GfnPlayerState', 'WBP_SimpleRaceResultsScreen_C', 'WBP_Common_Btn_C', 'WBP_Simple_RaceResultsPanel_C' }) do
    for _, o in ipairs(M.objects[cls] or {}) do M.kill(o) end
    M.clear(cls)
  end
  for _, o in ipairs(W.canvasKids or {}) do M.kill(o) end
  W.canvasKids, W.screen, W.chainBtn = {}, nil, nil
end
-- the game's results screen after a race (WBP_SimpleRaceResultsScreen_C, CONTINUE on its canvas Default_Results).
-- opts.refuse = the canvas takes no children. W.continued counts presses of its CONTINUE.
function W.results(opts)
  opts = opts or {}
  W.canvasKids, W.continued = {}, 0
  local canvas = M.new('Default_Results', { AddChildToCanvas = function(_, w)
    if opts.refuse then return nil end
    W.canvasKids[#W.canvasKids + 1] = w
    return M.new('CanvasPanelSlot', {}, 'CanvasPanelSlot')
  end }, 'FuseCanvasPanel')
  local slot = M.new('CanvasPanelSlot', {
    GetAnchors = function() return { Minimum = { X = 0.5, Y = 1 }, Maximum = { X = 0.5, Y = 1 } } end,
    GetAlignment = function() return { X = 0.5, Y = 1 } end, GetPosition = function() return { X = 0, Y = -76 } end,
    GetAutoSize = function() return true end, GetZOrder = function() return 1 end }, 'CanvasPanelSlot')
  local cont = M.new('WBP_Common_Btn_Continue', { GetParent = function() return canvas end, Slot = slot, WidthOverride = 300 }, 'WBP_Common_Btn_C')
  local w = M.new('WBP_SimpleRaceResultsScreen_C_' .. M.nextAddr, { WidgetTree = M.new('WidgetTree', {}), WBP_Common_Btn_Continue = cont,
    IsInViewport = function() return true end }, 'WBP_SimpleRaceResultsScreen_C')
  rawget(w, '__props')[require('chain').CONTINUE_EVENT] = function() W.continued = W.continued + 1 end
  M.add('WBP_SimpleRaceResultsScreen_C', w)
  W.screen = w
  -- (v0.19.1) the game's own results table on it: chain.lua hides it under the panel (W.tableVis: its visibility)
  W.tableVis = 4
  M.add('WBP_Simple_RaceResultsPanel_C', M.new('WBP_Simple_RaceResultsPanel_C_' .. M.nextAddr, {
    IsVisible = function() return W.tableVis ~= 1 and W.tableVis ~= 2 end, SetVisibility = function(_, v) W.tableVis = v end },
    'WBP_Simple_RaceResultsPanel_C'))
  return w
end
-- the reset: the old race world goes, a new one comes with the subsystem recipe's event
function W.chainWorld()
  W.dropRaceWorld()
  W.race(11)
end
-- press our NEXT RACE button (the game's UI turns the toggle button selected)
function W.pressNext()
  assert(W.chainBtn, 'no NEXT RACE button')
  rawget(W.chainBtn, '__props').__sel = true
end
-- every text set on a widget since the call index `from` (SetText(FText) calls), joined by newlines
function W.textsSince(from)
  local out = {}
  for i = from or 1, #M.calls do
    local c = M.calls[i]
    if c.name == 'SetText' and type(c.args[1]) == 'table' then
      local p = rawget(c.args[1], '__props')
      if p and p.__text then out[#out + 1] = p.__text end
    end
  end
  return table.concat(out, '\n')
end

return W
