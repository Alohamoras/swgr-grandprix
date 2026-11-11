-- AI tuning study, batch 2 (2026-11-11): 100/200cc open loop, 150cc aggression halved, 150cc gentle slowdown, noise
local P1 = { MaxAiSlowdownScale = 1.0, MaxAiCatchupScale = 1.0 }
local SM = { SpeedMatchingMaxMatchers = 0 }
local OPEN = { pacing = P1, errors = 0, config = SM }
local CALM = { pacing = P1, errors = 0, config = SM, aggression = { chance = 0.5, cooldown = 2 } }
local GENTLE = { pacing = { MaxAiSlowdownScale = 0.85, MaxAiCatchupScale = 1.0 }, errors = 0, config = SM }
local J = {}
local function add(class, race, label, ai, n) for _ = 1, n do J[#J + 1] = { class = class, cup = 'jakku', race = race, label = label, ai = ai } end end
add('100', 2, '100 open', OPEN, 2)
add('100', 1, '100 open', OPEN, 2)
add('150', 1, '150 calm', CALM, 3)
add('150', 2, '150 calm', CALM, 2)
add('150', 1, '150 gentle', GENTLE, 3)
add('150', 2, '150 gentle', GENTLE, 2)
add('150', 1, '150 open', OPEN, 2)
add('200', 1, '200 open', OPEN, 2)
return J
