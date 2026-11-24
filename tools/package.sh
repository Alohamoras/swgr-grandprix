#!/usr/bin/env bash
# Build the release zip for players (Nexus): ./tools/package.sh [tag]  (default: the newest tag)
# -> dist/GalacticGrandPrix-<tag>.zip with GalacticGrandPrix/{Scripts/, icons/, enabled.txt, README.txt}. Never the save, the
# log, the tests or the tools. The test switches stay off (config DevTools = false - checked).
set -euo pipefail
cd "$(dirname "$0")/.."
REF="${1:-$(git tag -l 'v*' --sort=-v:refname | head -1)}"
git rev-parse --verify -q "$REF^{commit}" >/dev/null || { echo "unknown version: $REF"; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
git archive "$REF" mod/GalacticGrandPrix | tar -x -C "$TMP"
# (the player README is text, not code: always the newest committed one, so a text fix doesn't need a new version)
mkdir -p "$TMP/docs/release"; git show HEAD:docs/release/README.txt > "$TMP/docs/release/README.txt"
OUT="$TMP/pkg/GalacticGrandPrix"
mkdir -p "$OUT"
cp -r "$TMP/mod/GalacticGrandPrix/Scripts" "$OUT/"
if [ -d "$TMP/mod/GalacticGrandPrix/icons" ]; then cp -r "$TMP/mod/GalacticGrandPrix/icons" "$OUT/"; fi
touch "$OUT/enabled.txt"
if [ -f "$TMP/docs/release/README.txt" ]; then sed "s/{VERSION}/$REF/g" "$TMP/docs/release/README.txt" > "$OUT/README.txt"; fi
# checks: no player data, test switches off, every script compiles
for bad in save.lua grandprix.log experiment.lua logbuilds.txt; do
  [ -e "$OUT/$bad" ] && { echo "refusing: $bad in the package"; exit 1; }
done
grep -q '{UE4SS_LINK}' "$OUT/README.txt" 2>/dev/null && { [ "${DRAFT:-}" = 1 ] && echo "warning: README.txt still has {UE4SS_LINK} (DRAFT=1)" || { echo "refusing: fill in {UE4SS_LINK} in docs/release/README.txt (or DRAFT=1)"; exit 1; }; }
grep -q '^    DevTools = false,' "$OUT/Scripts/config.lua" || { echo "refusing: DevTools is not false in config.lua"; exit 1; }
for f in "$OUT"/Scripts/*.lua; do luac5.4 -p "$f" || { echo "refusing: $f does not compile"; exit 1; }; done
grep -rlE '/home/|C:\\\\Users' "$OUT" && { echo "refusing: a local path in the package"; exit 1; } || true
mkdir -p dist
ZIP="dist/GalacticGrandPrix-$REF.zip"
rm -f "$ZIP"
python3 -I - "$TMP/pkg" "$ZIP" <<'PY'
import os, sys, zipfile
root, out = sys.argv[1], os.path.abspath(sys.argv[2])
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for d, _, files in os.walk(root):
        for f in sorted(files):
            full = os.path.join(d, f)
            z.write(full, os.path.relpath(full, root))
PY
echo "Built $ZIP ($(du -h "$ZIP" | cut -f1)):"
unzip -l "$ZIP" | tail -n +4 | head -n -2 | awk '{print "  " $4}'
