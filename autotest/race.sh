#!/usr/bin/env bash
# race.sh - after launching a Grand Prix race: let TestAutopilot drive it (armed), keep the game from idle-pausing,
# click through the game's results, and wait for the mod's RESULT line. Prints the result. (Same as the Underground's.)
L="$HOME/.steam/steam/steamapps/common/STAR WARS Galactic Racer/Griffin/Binaries/Win64/ue4ss/Mods/GalacticGrandPrix/grandprix.log"
n=$(wc -l < "$L"); s=$(date +%s); last=$s; fin=""
w=$(xdotool search --name 'Galactic Racer' | head -1); xdotool windowactivate --sync "$w" 2>/dev/null
until tail -n +$((n+1)) "$L" | grep -q "RESULT "; do
  sleep 1; now=$(date +%s)
  [ $((now - s)) -gt 600 ] && { echo "TIMEOUT after 600 s"; exit 1; }
  if [ $((now - last)) -ge 15 ]; then
    if [ -z "$fin" ]; then xdotool keydown w; sleep 0.1; xdotool keyup w
    else xdotool key Return; fi
    last=$now
  fi
  [ -z "$fin" ] && tail -n +$((n+1)) "$L" | grep -q "finished " && { fin=1; echo "finished at $((now - s)) s"; }
done
tail -n +$((n+1)) "$L" | grep -E "finished |RESULT |\[ai\]|\[racer\]|\[loadout\] mods|NEW RECORD" | cut -c1-200
