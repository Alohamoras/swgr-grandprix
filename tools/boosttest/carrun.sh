#!/usr/bin/env bash
# carrun.sh <experiment file> <tag> - one CHALLENGER car race on a fresh game (the experiment fixes the track):
# launch, wait for the tab, HOME -> CHALLENGER -> the first cup -> START (each step checked in the log), race with
# TestAutopilot (race.sh), print the lines of interest. The game is left running at the end.
set -u
EXP="$1"; TAG="$2"
G="$HOME/.local/share/Steam/steamapps/common/STAR WARS Galactic Racer/Griffin/Binaries/Win64/ue4ss/Mods/GalacticGrandPrix"
L="$G/grandprix.log"
UG="$HOME/Projects/swgr-underground"
WT="$(cd "$(dirname "$0")/../.." && pwd)"
if ps -eo args | grep -q "[S]hipping.exe Griffin"; then echo "the game is running - close it first"; exit 1; fi
cp "$EXP" "$G/experiment.lua"
n=$(wc -l < "$L")
steam steam://rungameid/4078430 >/dev/null 2>&1 & disown
for i in $(seq 1 60); do tail -n +$((n+1)) "$L" | grep -q "GRAND PRIX tab added" && break; sleep 2; done
tail -n +$((n+1)) "$L" | grep -q "GRAND PRIX tab added" || { echo "no tab after 120 s"; exit 1; }
sleep 8
step() { # step <keys> <log text expected>
  local m; m=$(wc -l < "$L")
  (cd "$UG" && autotest/k.sh $1 >/dev/null 2>&1)
  for i in $(seq 1 10); do tail -n +$((m+1)) "$L" | grep -q "$2" && return 0; sleep 1; done
  echo "step '$1' did not reach '$2'"; tail -3 "$L" | cut -c1-140; exit 1
}
step "e e e e" "\[menu\] home"
# HOME: focus on the league raced last; walk left to the first poster, then right once = CHALLENGER
(cd "$UG" && autotest/k.sh Left Left Left Right >/dev/null 2>&1)
step "Return" "\[menu\] cups"
tail -n +$((n+1)) "$L" | grep "\[menu\] cups" | tail -1 | cut -c1-120
step "Up Up Left Left Left Left Return" "\[menu\] garage"
tail -n +$((n+1)) "$L" | grep "\[cup\] " | tail -1 | cut -c1-160
grep -q "\[cup\] CHALLENGER" <(tail -n +$((n+1)) "$L") || { echo "not at CHALLENGER"; exit 1; }
m=$(wc -l < "$L")
(cd "$UG" && autotest/k.sh Return >/dev/null 2>&1)
(sleep 60; cd "$UG" && autotest/shot.sh "$TAG-race" >/dev/null 2>&1) &
(cd "$WT" && timeout 590 autotest/race.sh) | tail -2
tail -n +$((m+1)) "$L" | grep -E "\[exp\]|LAUNCH|RESULT|boostrecon|\[ai\] league" | cut -c1-300
