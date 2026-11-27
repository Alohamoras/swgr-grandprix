GALACTIC GRAND PRIX {VERSION} - a cups mode for STAR WARS: Galactic Racer
==========================================================================

Kart-racer-style Grand Prix cups as a new GRAND PRIX tab on the main menu. Race a cup of four tracks back to back,
score points against the field, win trophies, climb three leagues and take the title. OFFLINE ONLY.

WHAT'S IN IT
- Three leagues, each with its own feel:
    JUNKER      scrapyard junk with too much engine - afterburner and ramjet at 10 on a stock chassis, grimy cars,
                one ability, no tune-ups
    CHALLENGER  every part at level 7, yours and theirs - two abilities, one tune-up
    ACE         the finest vehicles money can buy, every part at level 10 - three abilities, two tune-ups, and a
                field that is faster and meaner
- Seven cups per league: one per planet (Jakku, Lantaana, Ando Prime, Crait, Sentinel I), the Galactic Cup, and the
  RALLY CUP. A planet cup draws four races at random from that planet's tracks, directions and conditions (night,
  wet, snow, scorching, mines, storm...), so no two cups are the same.
- The RALLY CUP: every point-to-point road in the game as a seven-stage rally in tour order, four cars, standings by
  total time. The night and weather of each stage are drawn when you start and kept secret until the stage loads;
  the finale is Dai Bendu Ascension at night. A stage not finished costs the slowest finisher's time plus 30 s.
- PODRACING, a league of its own (the fourth poster): the PODRACER CUP, four races drawn from the pod tracks of Mos
  Espa, Mawhonic and Holdfast's Folly, against Sebulba, the other pod racers and Kestar Bool. Pick LEARNER or PRO:
    LEARNER     no abilities on the grid - the pace to learn the tracks
    PRO         every pod at level 7, your four abilities on your pod, and every pod racer carries a kit of their own
  You fly your pilot's own podracer: Shade, Goli, Fola, Sebulba, or Kestar once you've beaten him. Each level keeps
  its own trophy and lap records.
- Points after every race (15, 12, 10, 9 ... 1), standings on the results screen, then straight into the next race.
  Gold, silver and bronze trophies, a crown for a perfect cup; track and lap records with "near miss" lines when you
  just missed one; PREVIOUS BEST LAP shown through the start countdown; the CUP RESULT on the game's own tour-end
  screen at the end.
- Take a trophy in the Galactic Cup and Kestar Bool waits as its finale: a 1 v 1 in the stadium for the league title.
  Beat him at Ace and he races for you.
- Rivals that stay rivals: the elite pilots (Sen Fira, Biddy Blas, Lyren Shok) race stronger cars and are usually
  the ones to beat. The bots use their abilities. The racers ahead of you don't fire their ramjet just because you
  did, so boosting feels fast; the ones behind you catch up harder instead. A lead you build is yours.
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
- JUNKER and CHALLENGER are open from the start; ACE unlocks with a trophy in all five CHALLENGER planet cups; a
  league's Galactic Cup unlocks with a trophy in its five planet cups; the Rally Cup with a Galactic Cup trophy.
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
- English only. Tested at 4K, 1440p and 1080p windowed.
- Game updates can break UE4SS mods; if the tab stops appearing after a patch, check for a new version.

CREDITS
- UE4SS (Re-UE4SS project) and the UE4SS Galactic Racer Edition (Nexus mod 2) - what this mod runs on.
- FreeRace (https://www.nexusmods.com/starwarsgalacticracer/mods/80) by CaptainLeland
  (https://www.nexusmods.com/profile/CaptainLeland) - several ideas in this mod come
  from reading FreeRace's code (re-implemented here; none of its files are included): chaining races through the
  results screen's CONTINUE, the game's tour-end screen as the cup summary, the bots cycling their abilities with
  cooldowns, the start grace, the buoys off The Galactic Gauntlet, catching the results screen as it is made, runtime
  tune sets on the opponents' cars, its difficulty presets and the vehicle-recipe call. Thank you.
- STAR WARS: Galactic Racer by Fuse Games, published by EA. STAR WARS and related names are trademarks of Lucasfilm Ltd.
- Developed with the help of Claude (Anthropic).
