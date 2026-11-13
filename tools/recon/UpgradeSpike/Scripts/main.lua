-- UpgradeSpike (2026-11-13, test-only, not shipped, offline only): can the campaign's UPGRADE VEHICLE screen
-- (WBP_PreRun_VehicleUpgrade_C) run at the main menu on a view-model WE make, and does its native upgrade
-- (UVehicleSelectItemVM:UpgradeStatBar) then touch the campaign's meta progression (UCampaignMetaProgression:
-- TuningPointsToSpend, KitPointsToSpend, BaseVehicleStates)? Underground docs/garage-reuse-plan-2026-11-13.md option 1.
-- Steps by trigger files in Mods/UpgradeSpike/ (each removed when run; one step per file):
--   meta.txt   log the campaign meta
--   real.txt   log the game's own vehicle-select VM (BuildVehicleSelectVM) - control, nothing changed
--   make.txt   our item VM + 6 stat-bar VMs, the upgrade widget on screen, Init(our VM); meta logged
--   up.txt     our VM:UpgradeStatBar(its first stat bar); our VM + meta logged
--   reset.txt  our VM:ResetStats(); our VM + meta logged
--   close.txt  remove the widget
-- Never keeps a UObject between ticks: our objects are named (UGSpike*) and found again by path each step.
local DIR = (debug.getinfo(1, 'S').source:match('^@(.*[/\\])Scripts[/\\]') or '')
local LOG = DIR .. 'upgradespike.log'
local function try(f, ...)
  local r = table.pack(pcall(f, ...))
  if r[1] then return table.unpack(r, 2, r.n) end
  return nil, tostring(r[2])
end
local function alive(o) return o ~= nil and type(o) == 'userdata' and try(function() return o:IsValid() end) == true end
local function log(m)
  local f = io.open(LOG, 'a'); if f then f:write(os.date('%H:%M:%S ') .. tostring(m) .. '\n'); f:close() end
end
local function exists(f) local h = io.open(DIR .. f, 'r'); if h then h:close(); return true end; return false end
local function full(o) return alive(o) and (try(function() return o:GetFullName() end) or '?') or '-' end
local function text(v) if v == nil then return 'nil' end; return tostring(try(function() return v:ToString() end) or v) end

local function first(cls)
  local got = try(FindAllOf, cls)
  for _, o in ipairs(type(got) == 'table' and got or {}) do
    if alive(o) and not (try(function() return o:GetFName():ToString() end) or ''):find('^Default__') then return o end
  end
end

local function meta()
  local cs = first('CampaignSubsystem')
  local m = alive(cs) and try(function() return cs.MetaProgression end)
  if not alive(m) then log('  meta: not found (CampaignSubsystem ' .. tostring(alive(cs)) .. ')'); return end
  local parts = {}
  local bv = try(function() return m.BaseVehicleStates end)
  local n = bv and try(function() return bv:GetArrayNum() end) or 0
  for i = 1, math.min(n, 8) do
    local st = try(function() return bv[i] end)
    local vt = st and try(function() return st.vehicleType end)
    local arr = st and try(function() return st.StartingStatForSlot end)
    local k = arr and try(function() return arr:GetArrayNum() end) or 0
    local v = {}
    for j = 1, math.min(k, 8) do v[#v + 1] = tostring(try(function() return arr[j] end)) end
    parts[#parts + 1] = ('type %s [%s]'):format(tostring(vt), table.concat(v, ','))
  end
  log(('  meta: tuning %s, kit %s, tour %s; base vehicles: %s'):format(tostring(try(function() return m.TuningPointsToSpend end)),
    tostring(try(function() return m.KitPointsToSpend end)), tostring(try(function() return m.MainCampaignCurrentTourIx end)),
    table.concat(parts, '; ')))
end

local function logItem(vm, label)
  if not alive(vm) then log('  ' .. label .. ': not found'); return end
  local g = function(k) return try(function() return vm[k] end) end
  log(('  %s %s: "%s" level %s/%s speed %s energy %s tuning %s cost %s canUpgrade %s flow %s locked %s'):format(label, full(vm),
    text(g('PlayerFacingName')), tostring(g('VehicleLevel')), tostring(g('MaxVehicleLevel')), tostring(g('RawSpeed')),
    tostring(g('Energy')), tostring(g('TuningPointsAvailable')), tostring(g('CostToUpgrade')), tostring(g('bCanBeUpgraded')),
    tostring(g('bFlowSupportsVehicleUpgrades')), tostring(g('bIsLocked'))))
  local bars = g('StatBars')
  local n = bars and try(function() return bars:GetArrayNum() end) or 0
  local b = {}
  for i = 1, math.min(n, 8) do
    local s = try(function() return bars[i] end)
    if alive(s) then
      b[#b + 1] = ('%s:%s=%s/%s(base %s, d %s, up %s, afford %s)'):format(tostring(try(function() return s.Slot end)),
        text(try(function() return s.PlayerFacingStatName end)), tostring(try(function() return s.Value end)),
        tostring(try(function() return s.MaxValue end)), tostring(try(function() return s.BaseValue end)),
        tostring(try(function() return s.Delta end)), tostring(try(function() return s.bCanBeUpgraded end)),
        tostring(try(function() return s.bCanAffordUpgrade end)))
    end
  end
  log(('    %d stat bars: %s'):format(n, table.concat(b, '  ')))
end

local function vms() return first('ViewModelSubsystem') end
local function ours()
  local s = vms()
  return alive(s) and try(StaticFindObject, full(s):gsub('^%S+ ', '') .. '.UGSpikeItemVM') or nil
end
local WIDGET = nil -- the widget's path (a string), never the object
local NAMES = { 'Cornering', 'Acceleration', 'Resilience', 'Boost', 'Battery', 'Advanced' }

local function archetype(n)
  for _, v in ipairs(try(FindAllOf, 'VehicleArchetype') or {}) do
    if alive(v) and try(function() return tonumber(v.archetype) end) == n then return v end
  end
end

local steps = {}
steps.meta = function() meta() end
steps.real = function()
  local s = vms()
  local vs = alive(s) and try(function() return s:BuildVehicleSelectVM() end)
  if not alive(vs) then log('  BuildVehicleSelectVM: nothing'); return end
  log('  BuildVehicleSelectVM -> ' .. full(vs) .. ' flow ' .. tostring(try(function() return vs.bFlowSupportsVehicleUpgrades end)))
  local arr = try(function() return vs.Vehicles end)
  for i = 1, math.min(arr and try(function() return arr:GetArrayNum() end) or 0, 4) do logItem(try(function() return arr[i] end), 'real') end
  meta()
end
steps.make = function()
  local s = vms()
  local icls, scls = try(StaticFindObject, '/Script/Griffin.VehicleSelectItemVM'), try(StaticFindObject, '/Script/Griffin.VehicleStatBarVM')
  if not (alive(s) and alive(icls) and alive(scls)) then log('  classes / subsystem missing'); return end
  local vm = try(StaticConstructObject, icls, s, FName('UGSpikeItemVM'))
  if not alive(vm) then log('  item VM not made'); return end
  local car = archetype(0)
  local set = function(o, k, v) local ok, e = pcall(function() o[k] = v end); if not ok then log('  set ' .. k .. ' failed: ' .. tostring(e)) end end
  set(vm, 'VehicleArchetype', car)
  set(vm, 'PlayerFacingName', FText('UNDERGROUND TEST'))
  set(vm, 'VehicleLevel', 3); set(vm, 'MaxVehicleLevel', 14); set(vm, 'RawSpeed', 300); set(vm, 'Energy', 3)
  set(vm, 'TuningPointsAvailable', 42); set(vm, 'CostToUpgrade', 5); set(vm, 'bCanBeUpgraded', true)
  set(vm, 'bFlowSupportsVehicleUpgrades', true); set(vm, 'bIsLocked', false)
  local bars = {}
  for i = 1, 6 do
    local b = try(StaticConstructObject, scls, vm, FName('UGSpikeBar' .. i))
    if alive(b) then
      set(b, 'Slot', i - 1); set(b, 'PlayerFacingStatName', FText(NAMES[i])); set(b, 'bUsePips', true)
      set(b, 'BaseValue', i); set(b, 'Value', i); set(b, 'MaxValue', 10); set(b, 'Delta', 0)
      set(b, 'bCanBeUpgraded', true); set(b, 'bCanAffordUpgrade', true)
      bars[#bars + 1] = b
    end
  end
  set(vm, 'StatBars', bars)
  logItem(vm, 'ours')
  local wcls = try(StaticFindObject, '/Game/Griffin/UI/Screens/WBP_PreRun_VehicleUpgrade.WBP_PreRun_VehicleUpgrade_C')
  if not alive(wcls) then try(LoadAsset, '/Game/Griffin/UI/Screens/WBP_PreRun_VehicleUpgrade'); wcls = try(StaticFindObject, '/Game/Griffin/UI/Screens/WBP_PreRun_VehicleUpgrade.WBP_PreRun_VehicleUpgrade_C') end
  local lib = try(StaticFindObject, '/Script/UMG.Default__WidgetBlueprintLibrary')
  local pc
  for _, p in ipairs(try(FindAllOf, 'PlayerController') or {}) do
    if alive(p) and try(function() return p:IsLocalPlayerController() end) == true then pc = p end
  end
  if not (alive(wcls) and alive(lib) and alive(pc)) then log(('  widget class %s lib %s pc %s'):format(tostring(alive(wcls)), tostring(alive(lib)), tostring(alive(pc)))); return end
  local w = try(function() return lib:Create(pc, wcls, pc) end)
  if not alive(w) then log('  widget not created'); return end
  WIDGET = full(w):gsub('^%S+ ', '')
  local ok1, e1 = pcall(function() w:AddToViewport(500) end)
  local ok2, e2 = pcall(function() w:Init(vm) end)
  local ok3, e3 = pcall(function() w:ActivateWidget() end)
  log(('  widget %s: viewport %s %s, Init %s %s, activate %s %s'):format(WIDGET, tostring(ok1), tostring(e1 or ''), tostring(ok2), tostring(e2 or ''), tostring(ok3), tostring(e3 or '')))
  logItem(vm, 'ours after Init')
  meta()
end
steps.up = function()
  local vm = ours(); if not alive(vm) then log('  our VM is gone'); return end
  local bar = try(function() return vm.StatBars[1] end)
  local ok, e = pcall(function() vm:UpgradeStatBar(bar) end)
  log('  UpgradeStatBar: ' .. tostring(ok) .. ' ' .. tostring(e or ''))
  logItem(vm, 'ours after up')
  meta()
end
steps.reset = function()
  local vm = ours(); if not alive(vm) then log('  our VM is gone'); return end
  local c = try(function() return vm:GetStatResetCost() end)
  local ok, e = pcall(function() vm:ResetStats() end)
  log(('  reset cost %s; ResetStats: %s %s'):format(tostring(c), tostring(ok), tostring(e or '')))
  logItem(vm, 'ours after reset')
  meta()
end
steps.close = function()
  local w = WIDGET and try(StaticFindObject, WIDGET)
  if alive(w) then pcall(function() w:DeactivateWidget() end); pcall(function() w:RemoveFromParent() end); log('  widget removed') else log('  no widget') end
  WIDGET = nil
end

local ORDER = { 'meta', 'real', 'make', 'up', 'reset', 'close' }
LoopInGameThreadWithDelay(500, function()
  for _, k in ipairs(ORDER) do
    if exists(k .. '.txt') then
      os.remove(DIR .. k .. '.txt')
      log('== ' .. k)
      local ok, e = pcall(steps[k])
      if not ok then log('  ERROR ' .. tostring(e)) end
      log('== ' .. k .. ' done')
      return
    end
  end
end)
log('UpgradeSpike loaded')
