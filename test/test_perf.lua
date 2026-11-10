-- v0.3.1: no full object sweeps (FindAllOf) every tick during a race - they made the race stutter. Count them.
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
T.clickTitle('50CC'); M.tick(3)
T.clickTitle('JAKKU CUP'); M.tick(3)
T.clickTitle('START CUP')
W.race(11); M.tick(30)   -- loading + the first seconds (the AI loadout, the first racer sweep)
local real, count = _G.FindAllOf, {}
_G.FindAllOf = function(cls) count[cls] = (count[cls] or 0) + 1; return real(cls) end
M.tick(100)              -- 10 s of racing (100 ms ticks)
_G.FindAllOf = real
local parts, total = {}, 0
for cls, n in pairs(count) do parts[#parts + 1] = cls .. '=' .. n; total = total + n end
table.sort(parts)
T.check(total <= 6, 'at most 6 sweeps in 10 s of racing (was ~250): ' .. table.concat(parts, ' '))
T.check((count.RacingGameState or 0) == 0, 'the race state is never swept for while racing')
T.check((count.GfnPlayerState or 0) <= 1, 'the racers: found once (+1 sweep at 5 s for late joiners)')
W.finish(1); M.tick(3)
local t0 = os.time(); while os.time() - t0 < 3 do end
W.backToMenu(); M.tick(45)
local results = 0
for _, l in ipairs(M.log) do if l:find('RESULT THE WAR FIELDS', 1, true) then results = results + 1 end end
T.check(results == 1, 'the race is recorded exactly once (' .. results .. ')')
T.check(T.logHas('PERF THE WAR FIELDS: frames:') and T.logHas('Lua memory: start'), 'PERF line written, with Lua memory')
T.check(T.logHas('our tick (real clock):') and T.logHas('race watch average 0.30 ms'), 'our tick timed with the real clock')
T.check(T.save().races == 1, 'races = 1')
T.finish()
