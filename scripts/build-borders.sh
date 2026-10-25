#!/usr/bin/env bash
# Build KDE-Rounded-Corners with kalango's spinning-gradient patch and install it (needs sudo).
# Re-run after a Plasma/KWin update if the borders disappear.
set -euo pipefail

VERSION=v0.11.0
REPO=$(cd "$(dirname "$0")/.." && pwd)
SRC="$HOME/.local/src/KDE-Rounded-Corners"
PATCH="$REPO/patches/kde-rounded-corners-spin-gradient.patch"

if [[ ! -d "$SRC" ]]; then
    git clone -q --depth 1 --branch "$VERSION" https://github.com/matinlotfali/KDE-Rounded-Corners.git "$SRC"
fi
if git -C "$SRC" apply --check "$PATCH" 2>/dev/null; then
    git -C "$SRC" apply "$PATCH"
    echo "   patched"
else
    echo "   patch already applied"
fi

rm -rf "$SRC/build"
cmake -S "$SRC" -B "$SRC/build" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$SRC/build" -j"$(nproc)"
sudo cmake --install "$SRC/build"
