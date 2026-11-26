#!/usr/bin/env bash
# podrun.sh <podRacer key> <experiment file> <tag> - one PRO pod race on a fresh game: set the pilot and the experiment
# in the test save, launch, wait for the GRAND PRIX tab, HOME -> PODRACING -> PRO -> START (each step checked in the
# log), race with TestAutopilot (race.sh), print the log lines of interest. The game is left running at the end.
set -u
KEY="$1"; EXP="$2"; TAG="$3"
G="$HOME/.local/share/Steam/steamapps/common/STAR WARS Galactic Racer/Griffin/Binaries/Win64/ue4ss/Mods/GalacticGrandPrix"
L="$G/grandprix.log"
UG="$HOME/Projects/swgr-underground"
WT="$(cd "$(dirname "$0")/../.." && pwd)"
if ps -eo args | grep -q "[S]hipping.exe Griffin"; then echo "the game is running - close it first"; exit 1; fi
sed -i "s/^  podRacer = \"[A-Za-z]*\",/  podRacer = \"$KEY\",/" "$G/save.lua"
grep -q "podRacer = \"$KEY\"" "$G/save.lua" || { echo "podRacer not set"; exit 1; }
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
(cd "$UG" && autotest/k.sh Right Right Right >/dev/null 2>&1)
step "Return" "\[menu\] pods"
step "Return" "\[menu\] garage"
tail -n +$((n+1)) "$L" | grep "\[cup\] PODRACING" | tail -1 | cut -c1-140
grep -q "PODRACING PRO pods drawn" <(tail -n +$((n+1)) "$L") || { echo "not at PRO"; exit 1; }
(cd "$UG" && autotest/shot.sh "$TAG-start" >/dev/null 2>&1)
m=$(wc -l < "$L")
(cd "$UG" && autotest/k.sh Return >/dev/null 2>&1)
(sleep 50; cd "$UG" && autotest/shot.sh "$TAG-race" >/dev/null 2>&1) &
(cd "$WT" && timeout 590 autotest/race.sh) | tail -3
tail -n +$((m+1)) "$L" | grep -E "podrecon|aiuse|loadout|\[exp\]|\[pods\]|build for|LAUNCH|RESULT|racing as" | cut -c1-400
