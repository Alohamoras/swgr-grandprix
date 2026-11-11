-- 100cc calibration (2026-11-11): v0.18's 100cc with more mercy (slowdown 0.5, 0.3), The War Fields (reverse)
local SM = { SpeedMatchingMaxMatchers = 0 }
local J = {}
for _ = 1, 3 do J[#J + 1] = { class = '100', cup = 'jakku', race = 1, label = '100 slow0.5', ai = { pressure = 0, pacing = { MaxAiCatchupScale = 1.0, MaxAiSlowdownScale = 0.5 }, errors = 0, config = SM } } end
for _ = 1, 3 do J[#J + 1] = { class = '100', cup = 'jakku', race = 1, label = '100 slow0.3', ai = { pressure = 0, pacing = { MaxAiCatchupScale = 1.0, MaxAiSlowdownScale = 0.3 }, errors = 0, config = SM } } end
return J
