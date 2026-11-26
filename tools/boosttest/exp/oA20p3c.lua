-- owner race 5: bots boost only at a pacing factor of 2.0, bots +3 parts (harder), and the back of the field's
-- catch-up on strong (the game's own is 1.3x after its own delay; ours were 1.0 = off). The catch-up only speeds bots
-- BEHIND you; the slowdown of bots ahead of you stays off (MaxAiSlowdownScale 1.0 in the league profile).
return { label = 'owner 5: boost threshold 2.0 + bots +3 parts + catch-up 1.6 after 2 s', boostRecon = true, event = 'THE WAR FIELDS',
  botStacks = 3,
  config = { ['DefaultPacingSettings.MaxAiCatchupScale'] = 1.6, ['DefaultPacingSettings.AiBehindTimeToMaxCatchup'] = 2.0 },
  styles = { Car = { MinRacePacingFactorForBoost = 2.0 }, Bike = { MinRacePacingFactorForBoost = 2.0 }, Skimmer = { MinRacePacingFactorForBoost = 2.0 } } }
