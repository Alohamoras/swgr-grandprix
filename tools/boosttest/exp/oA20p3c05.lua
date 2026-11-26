-- owner race 6: as race 5 (boost threshold 2.0, bots +3 parts, catch-up 1.6) but the catch-up starts after 0.5 s
-- behind you instead of 2 s (the Rally Cup's values). Bots ahead of you still never slow down.
return { label = 'owner 6: boost threshold 2.0 + bots +3 parts + catch-up 1.6 after 0.5 s', boostRecon = true, event = 'THE WAR FIELDS',
  botStacks = 3,
  config = { ['DefaultPacingSettings.MaxAiCatchupScale'] = 1.6, ['DefaultPacingSettings.AiBehindTimeToMaxCatchup'] = 0.5 },
  styles = { Car = { MinRacePacingFactorForBoost = 2.0 }, Bike = { MinRacePacingFactorForBoost = 2.0 }, Skimmer = { MinRacePacingFactorForBoost = 2.0 } } }
