#!/usr/bin/env bash
# Syntax-check every mod file and run every test scenario. Exit code 0 = all good.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
for f in "$ROOT"/mod/GalacticGrandPrix/Scripts/*.lua "$ROOT"/tools/recon/*/Scripts/*.lua; do luac5.4 -p "$f" || fail=1; done
for t in "$ROOT"/test/test_*.lua; do
  name="$(basename "$t")"
  out="$("$ROOT/test/run.sh" "test/$name" 2>&1)"; rc=$?
  if [ $rc -ne 0 ]; then echo "== $name FAILED"; echo "$out" | grep -v '^PASS'; fail=1
  else echo "== $name ok ($(echo "$out" | grep -c '^PASS') checks)"; fi
done
exit $fail
