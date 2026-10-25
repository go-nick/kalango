#!/usr/bin/env bash
# Install Krohnkite (tiling KWin script) and apply kalango's cross-monitor focus patch.
set -euo pipefail

VERSION=0.9.9.2
REPO=$(cd "$(dirname "$0")/.." && pwd)
DEST="$HOME/.local/share/kwin/scripts/krohnkite"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL -o "$TMP/krohnkite.kwinscript" \
    "https://github.com/anametologin/krohnkite/releases/download/$VERSION/krohnkite.kwinscript"
kpackagetool6 -t KWin/Script -i "$TMP/krohnkite.kwinscript" 2>/dev/null \
    || kpackagetool6 -t KWin/Script -u "$TMP/krohnkite.kwinscript"

# Directional focus falls back to KWin's cross-screen switch when there's no neighbor
PATCH="$REPO/patches/krohnkite-cross-screen-focus.patch"
if (cd "$DEST" && git apply --check "$PATCH" 2>/dev/null); then
    (cd "$DEST" && git apply "$PATCH")
    echo "   patched"
else
    echo "   patch already applied"
fi
