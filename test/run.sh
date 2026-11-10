#!/usr/bin/env bash
# Run a test scenario against the mod in mod/GalacticGrandPrix:  test/run.sh test/test_flow.lua
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX="${SANDBOX_DIR:-${TMPDIR:-/tmp}}/gp_test"
rm -rf "$SANDBOX"; mkdir -p "$SANDBOX"
cp -r "$ROOT/mod/GalacticGrandPrix" "$SANDBOX/"
cd "$ROOT/test"
LUA_PATH="$ROOT/test/?.lua;;" MOD_MAIN="$SANDBOX/GalacticGrandPrix/Scripts/main.lua" lua5.4 "$ROOT/$1"
