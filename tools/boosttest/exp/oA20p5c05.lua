-- owner race 7: as race 6, bots +5 parts (race 5 had +3) (boost threshold 2.0, bots +3 parts, catch-up 1.6) but the catch-up starts after 0.5 s
-- behind you instead of 2 s (the Rally Cup's values). Bots ahead of you still never slow down.
return { label = 'owner 7: boost threshold 2.0 + bots +5 parts + catch-up 1.6 after 0.5 s', boostRecon = true, event = 'THE WAR FIELDS',
  botStacks = 5,
  config = { ['DefaultPacingSettings.MaxAiCatchupScale'] = 1.6, ['DefaultPacingSettings.AiBehindTimeToMaxCatchup'] = 0.5 },
  styles = { Car = { MinRacePacingFactorForBoost = 2.0 }, Bike = { MinRacePacingFactorForBoost = 2.0 }, Skimmer = { MinRacePacingFactorForBoost = 2.0 } } }
