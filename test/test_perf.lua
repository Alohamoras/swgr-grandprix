-- No full object sweeps every tick during a race - they made the race stutter (v0.3.1). v0.3.9: lookups by path are
-- sweeps too in this game, so none at all: one sweep of the player states every 2 s, the menu by notification.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot()
-- real-looking frame timing (v0.3.4's PERF line broke on non-integer numbers: the race was recorded every tick)
local gsl = StaticFindObject('/Script/Engine.Default__GameplayStatics')
local t = 0
rawget(gsl, '__props').GetRealTimeSeconds = function() t = t + 0.1037; return t end
rawget(gsl, '__props').GetWorldDeltaSeconds = function() return 0.0103 end
-- the real clock (KismetMathLibrary:Now, FDateTime ticks of 100 ns): 0.3 ms per call
local kml = StaticFindObject('/Script/Engine.Default__KismetMathLibrary')
local ticks = 638000000000000000
rawget(kml, '__props').Now = function() ticks = ticks + 3000; return { Ticks = ticks } end
M.press('F6'); M.tick(6)
T.clickTitle('JUNKER'); M.tick(3)
T.clickTitle('JAKKU CUP')
W.race(11); M.tick(30)   -- loading + the first seconds (the AI loadout, the first racer sweep)
local real, count = _G.FindAllOf, {}
_G.FindAllOf = function(cls) count[cls] = (count[cls] or 0) + 1; return real(cls) end
M.tick(100)              -- 10 s of racing (100 ms ticks)
_G.FindAllOf = real
local parts, total = {}, 0
for cls, n in pairs(count) do parts[#parts + 1] = cls .. '=' .. n; total = total + n end
table.sort(parts)
T.check(total <= 6, 'at most 6 sweeps in 10 s of racing (v0.3.0: ~250): ' .. table.concat(parts, ' '))
T.check((count.RacingGameState or 0) == 0 and (count.FrontEndGameMode or 0) == 0, 'no sweeps for the race state or the menu while racing')
T.check((count.GfnPlayerState or 0) >= 4 and (count.GfnPlayerState or 0) <= 6, 'the racers: one sweep every 2 s (' .. tostring(count.GfnPlayerState) .. ')')
local lookups = 0
local realSFO = _G.StaticFindObject
_G.StaticFindObject = function(p) if not p:find('Default__', 1, true) then lookups = lookups + 1 end; return realSFO(p) end
M.tick(50)
_G.StaticFindObject = realSFO
T.check(lookups == 0, 'no lookups by path while racing (they are full sweeps here): ' .. lookups)
W.finish(1); M.tick(25)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
local results = 0
for _, l in ipairs(M.log) do if l:find('RESULT THE WAR FIELDS', 1, true) then results = results + 1 end end
T.check(results == 1, 'the race is recorded exactly once (' .. results .. ')')
T.check(T.logHas('PERF THE WAR FIELDS (REVERSE, SCORCHING): tick gaps') and T.logHas('Lua memory: start'), 'PERF line written, with Lua memory')
T.check(T.logHas('our tick (real clock):'), 'our tick timed with the real clock')
T.check(T.save().races == 1, 'races = 1')
T.finish()
