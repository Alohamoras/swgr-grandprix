#!/usr/bin/env bash
# race.sh - after launching a Grand Prix race: let TestAutopilot drive it (armed), keep the game from idle-pausing,
# click through the game's results, and wait for the mod's RESULT line. Prints the result. (Same as the Underground's.)
L="$HOME/.steam/steam/steamapps/common/STAR WARS Galactic Racer/Griffin/Binaries/Win64/ue4ss/Mods/GalacticGrandPrix/grandprix.log"
n=$(wc -l < "$L"); s=$(date +%s); last=$s; fin=""
# the game window by its class (a browser tab named "...Galactic Racer..." must never match)
w=$(for x in $(xdotool search --class steam_app_4078430); do case "$(xdotool getwindowname $x 2>/dev/null)" in *"Galactic Racer"*) echo $x;; esac; done | head -1)
[ -z "$w" ] && { echo "no game window"; exit 1; }
xdotool windowactivate --sync "$w" 2>/dev/null
# 2026-11-11: the owner was typing in a browser while a race ran; the throttle taps went into their document.
# Keys only go to the game window when it is ALREADY the active one; if anything else has focus, stop at once.
key() { [ "$(xdotool getactivewindow 2>/dev/null)" = "$w" ] || { echo "STOPPED: the game lost focus (someone is using the desktop); no keys sent"; exit 3; }; "$@"; }
until tail -n +$((n+1)) "$L" | grep -q "RESULT "; do
  sleep 1; now=$(date +%s)
  [ $((now - s)) -gt 600 ] && { echo "TIMEOUT after 600 s"; exit 1; }
  if [ $((now - last)) -ge 15 ]; then
    if [ -z "$fin" ]; then key xdotool keydown w; sleep 0.1; xdotool keyup w
    else key xdotool key Return; fi
    last=$now
  fi
  [ -z "$fin" ] && tail -n +$((n+1)) "$L" | grep -q "finished " && { fin=1; echo "finished at $((now - s)) s"; }
done
tail -n +$((n+1)) "$L" | grep -E "finished |RESULT |\[ai\]|\[racer\]|\[loadout\] mods|NEW RECORD" | cut -c1-200
