-- v0.3.1: no full object sweeps (FindAllOf) every tick during a race - they made the race stutter. Count them.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot()
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
T.finish()
