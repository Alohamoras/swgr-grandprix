#!/usr/bin/env bash
# Switch every UE4SS mod off (for multiplayer) or back on, by renaming the loader dwmapi.dll <-> dwmapi.dll.off.
#   tools/mods-toggle.sh        show the state
#   tools/mods-toggle.sh off    mods off: the game starts clean (for online play)
#   tools/mods-toggle.sh on     mods on again
# Refuses while the game is running.
set -euo pipefail
W="${GAME_WIN64:-$HOME/.local/share/Steam/steamapps/common/STAR WARS Galactic Racer/Griffin/Binaries/Win64}"
state() { if [ -f "$W/dwmapi.dll" ]; then echo on; elif [ -f "$W/dwmapi.dll.off" ]; then echo off; else echo missing; fi; }
want="${1:-}"
if [ -z "$want" ]; then echo "mods are $(state)"; exit 0; fi
if pgrep -f "[S]hipping.exe Griffin" >/dev/null; then echo "the game is running - close it first"; exit 1; fi
case "$want:$(state)" in
  off:on)  mv "$W/dwmapi.dll" "$W/dwmapi.dll.off"; echo "mods OFF - safe for multiplayer (run '$0 on' to switch back)";;
  on:off)  mv "$W/dwmapi.dll.off" "$W/dwmapi.dll"; echo "mods ON";;
  off:off|on:on) echo "mods are already $want";;
  *) echo "can't tell the state (dwmapi.dll not found in $W)"; exit 1;;
esac
