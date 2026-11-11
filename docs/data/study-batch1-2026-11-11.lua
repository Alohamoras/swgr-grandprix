-- AI tuning study, batch 1 (2026-11-11): Phase 0/0b baseline, Phase 1 open loop, 1b window check
local OPEN = { pacing = { MaxAiSlowdownScale = 1.0, MaxAiCatchupScale = 1.0 }, errors = 0,
               config = { SpeedMatchingMaxMatchers = 0 } }
local OPEN_P2 = { pacing = OPEN.pacing, errors = 0, config = OPEN.config, pressure = 2 }
local J = {}
local function add(class, race, label, ai, n) for _ = 1, n do J[#J + 1] = { class = class, cup = 'jakku', race = race, label = label, ai = ai } end end
add('150', 1, '150 base', nil, 4)
local classes, races = { '50', '150' }, { 1, 2, 4 }
for a = 1, 2 do for b = 1, 3 do add(classes[a], races[b], classes[a] .. ' open', OPEN, 2) end end
add('150', 1, '150 open p2', OPEN_P2, 2)
return J
