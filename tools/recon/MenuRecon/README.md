# MenuRecon: read-only property dumps at the main menu

Test-only UE4SS mod (not shipped). Dumps every live object of the classes you name, or any asset by path, with all their
plain properties, into `menurecon.log`. Written 2026-11-10 for the research doc (docs/research-2026-11-10.md).

Install: copy `Scripts/` to `Mods/MenuRecon/Scripts/` and add an empty `enabled.txt` (rename to `disabled.txt` to switch
it off; it polls its folder once a second). Files next to it:
- `classes.txt`: class names, one per line (`RaceTuneData`, `CharacterList`, `RacerDef` ...). Every instance is dumped
  (CDOs marked), 30 per class at most.
- `assets.txt`: asset paths (`/Game/Griffin/AI/DA_AIConfig`), loaded with LoadAsset and dumped.
- `dump.txt`: the trigger; removed when the dump starts.

Only plain property types are read (bool, numbers, enums, names, strings, text, object and class pointers, structs and
arrays of those). Soft pointers, delegates, maps, sets and optionals are only named. **The first version read everything
and crashed the game on GfnGameInstance** (crash_2026_11_11_01_05_14): never read a soft pointer from Lua.

Dumps kept here: `menurecon-20261110.log` (character list, racer styles and defs, planets, sponsors, difficulties, AI
config, event list, tours), `-b.log` (favours, tune sets, AI ability configs, driving style, campaign racer setups,
antagonists, rivalries, racing memories), `-c.log` (difficulty favours and tune sets by path, game-mode variants).
