#!/usr/bin/env bash
# boostbatch.sh [variant ...] - boost-test races, one per experiment file in tools/boosttest/exp (default: b0 b1 b2 b3),
# each on a fresh game (the game is closed first - ONLY if Claude started it: never close a game the owner left open).
# Needs: ./deploy.sh <ref> --dev, TestAutopilot enabled + armed. Output: out/<variant>.txt per race; the rows go to
# Mods/GalacticGrandPrix/boostrecon.csv (analyse with tools/boostan.py). Plan: docs/boost-fix-test-plan.md.
D="$(cd "$(dirname "$0")" && pwd)"
OUT="$D/out"; mkdir -p "$OUT"
[ $# -eq 0 ] && set -- b0 b1 b2 b3
for b in "$@"; do
  pid=$(ps -eo pid,args | grep "[S]hipping.exe Griffin" | awk '{print $1}')
  [ -n "$pid" ] && kill $pid
  for i in $(seq 1 20); do ps -eo args | grep -q "[A]ppId=4078430" || break; sleep 2; done
  sleep 3
  "$D/carrun.sh" "$D/exp/$b.lua" "gp-$b" > "$OUT/$b.txt" 2>&1
  echo "== $b"; grep -E "RESULT|\[exp\] result|bot parts|did not|not at|no tab" "$OUT/$b.txt" | cut -c1-260
done
