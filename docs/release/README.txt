GALACTIC GRAND PRIX {VERSION} - a cups mode for STAR WARS: Galactic Racer
==========================================================================

Kart-racer-style Grand Prix cups as a new GRAND PRIX tab on the main menu. Race a cup of four tracks back to back,
score points against the field, win trophies, climb three leagues and take the title. OFFLINE ONLY.

WHAT'S IN IT
- Three leagues, each with its own feel:
    JUNKER      scrapyard junk with too much engine - grimy cars, one ability, no tune-ups
    CHALLENGER  tuned rigs - two abilities, one tune-up
    ACE         full power - three abilities, two tune-ups
- Seven cups per league: one per planet (Jakku, Lantaana, Ando Prime, Crait, Sentinel I), the Galactic Cup, and the
  RALLY CUP. A planet cup draws four races at random from that planet's tracks, directions and conditions (night,
  wet, snow, scorching, mines, storm...), so no two cups are the same.
- The RALLY CUP: every point-to-point road in the game as a seven-stage rally in tour order, four cars, standings by
  total time. The night and weather of each stage are drawn when you start and kept secret until the stage loads;
  the finale is Dai Bendu Ascension at night. A stage not finished costs the slowest finisher's time plus 30 s.
- Points after every race (15, 12, 10, 9 ... 1), standings on the results screen, then straight into the next race.
  Gold, silver and bronze trophies; track records; "near miss" lines when you just missed one.
- A title race for each league against its points leader, and a final boss once you're the Ace champion.
- Rivals that stay rivals: the elite pilots (Sen Fira, Biddy Blas, Lyren Shok) race stronger cars and are usually
  the ones to beat. No catch-up for the AI at Challenger and Ace - a lead you build is yours.
- Pick your pilot, then a vehicle (landspeeder, speeder bike, or skim speeder). A new pilot starts on their own vehicle. The other two get that rider's scheme (ace, enforcer, raider, vintage, or robotic, in paint, rust, or steel). The pilot tile shows that racer's face (the game's own portrait). Your four abilities start as that pilot's signature kit, and you can change them, along with your tune-ups, on the cup's start screen.
- Its own save file: your campaign is never touched.

REQUIREMENTS
- STAR WARS: Galactic Racer (Steam, PC).
- UE4SS for Galactic Racer ("Galactic Racer Edition", Open Beta v0.9.4 or later): https://www.nexusmods.com/starwarsgalacticracer/mods/2

INSTALL
1. Install UE4SS first (follow its instructions; it goes in Griffin\Binaries\Win64).
2. Unzip this archive into Griffin\Binaries\Win64\ue4ss\Mods\ so you have
   ...\ue4ss\Mods\GalacticGrandPrix\Scripts\main.lua and ...\GalacticGrandPrix\enabled.txt
3. Start the game. The GRAND PRIX tab appears on the main menu (or press F6).

HOW TO PLAY
- GRAND PRIX tab -> pick a league -> pick a cup -> the start screen (your pilot, vehicle, abilities, tune-ups) -> START.
- After each race: the finish times, then the standings (A); NEXT RACE starts the next one. B on the standings leaves
  the cup (points lost - cups can't be paused). The Rally Cup shows times and gaps instead of points.
- JUNKER and CHALLENGER are open from the start; ACE opens with a trophy in all five Challenger planet cups.
- RESET PROGRESS on the GRAND PRIX home page clears your trophies and records (it asks twice).

MULTIPLAYER - READ THIS
This mod is for offline play. It refuses to run its races while you're in a party or matchmaking, but the safest
thing for multiplayer is to switch mods off completely: rename Griffin\Binaries\Win64\dwmapi.dll to dwmapi.dll.off
before playing online, and back afterwards. Using mods online is at your own risk.

SETTINGS (Scripts\config.lua - make a copy before editing)
- BootToGrandPrix = true    open the GRAND PRIX tab when the game starts
- MenuKey = 'F6'            the key that opens the tab
- AI.Strength               how much stronger each pilot tier's cars are, per league
- Looks.riffraff            the Junker look (dirt; field = the AI cars too)

UNINSTALL
Delete the GalacticGrandPrix folder. Everything the mod changes in the game is in memory only and put back when you
return to the main menu.

FILES
- GalacticGrandPrix\save.lua      your Grand Prix progress (trophies, records)
- GalacticGrandPrix\grandprix.log what the mod did - attach it to a bug report

KNOWN LIMITS
- English only. Tested at 4K; other resolutions not checked yet.
- Game updates can break UE4SS mods; if the tab stops appearing after a patch, check for a new version.

CREDITS
- UE4SS (Re-UE4SS project) and the UE4SS Galactic Racer Edition (Nexus mod 2) - what this mod runs on.
- FreeRace (https://www.nexusmods.com/starwarsgalacticracer/mods/80) - for showing how to press the results
  screen's CONTINUE, its difficulty presets and the vehicle-recipe call.
- STAR WARS: Galactic Racer by Fuse Games, published by EA. STAR WARS and related names are trademarks of Lucasfilm Ltd.
- Developed with the help of Claude (Anthropic).
