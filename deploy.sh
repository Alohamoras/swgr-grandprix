#!/usr/bin/env bash
# Install a version of the Galactic Grand Prix mod into the game.
#   ./deploy.sh            -> the newest tagged version
#   ./deploy.sh v0.2       -> that tag (see: git tag -l, or CHANGELOG.md)
#   ./deploy.sh HEAD       -> the latest work in progress (may be untested)
# Your save (save.lua) and log (grandprix.log) in the game folder are never touched.
# Do this with the game closed (Ctrl+F4 hot reload has crashed the game - restart instead).
set -euo pipefail
cd "$(dirname "$0")"
GAME="${GAME_MODS:-$HOME/.local/share/Steam/steamapps/common/STAR WARS Galactic Racer/Griffin/Binaries/Win64/ue4ss/Mods}"
REF="${1:-$(git tag -l 'v*' --sort=-v:refname | head -1)}"
[ -n "$REF" ] || { echo "no tags yet"; exit 1; }
git rev-parse --verify -q "$REF^{commit}" >/dev/null || { echo "unknown version: $REF"; git tag -l 'v*'; exit 1; }
DEST="$GAME/GalacticGrandPrix"
mkdir -p "$DEST"
# back up the current save before switching versions
[ -f "$DEST/save.lua" ] && cp "$DEST/save.lua" "$DEST/save.backup-$(date +%Y%m%d-%H%M%S).lua"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
git archive "$REF" mod/GalacticGrandPrix | tar -x -C "$TMP"
rm -rf "$DEST/Scripts"
cp -r "$TMP/mod/GalacticGrandPrix/." "$DEST/"
echo "$REF ($(git rev-parse --short "$REF^{commit}"))" > "$DEST/VERSION.txt"
# UE4SS only starts a mod folder that has enabled.txt
[ -f "$DEST/disabled.txt" ] || touch "$DEST/enabled.txt"
echo "Installed Galactic Grand Prix $REF into the game."
git log -1 --format='  %s' "$REF"
