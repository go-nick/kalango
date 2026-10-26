#!/usr/bin/env bash
# Build Quickshell from source into ~/.local (no sudo).
# Quickshell is not in the openSUSE repos yet; this is the stopgap until kalango
# ships it as an RPM on OBS. All build dependencies are in packages.txt.
set -euo pipefail

VERSION=v0.3.2
SRC="$HOME/.local/src/quickshell"

if [[ ! -d "$SRC" ]]; then
    git clone -q --depth 1 --branch "$VERSION" https://github.com/quickshell-mirror/quickshell.git "$SRC"
fi
if "$HOME/.local/bin/qs" --version 2>/dev/null | grep -q "Quickshell ${VERSION#v} "; then
    echo "   quickshell ${VERSION#v} already installed"
    exit 0
fi

cmake -S "$SRC" -B "$SRC/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DDISTRIBUTOR="kalango (local build)" >/dev/null
cmake --build "$SRC/build"
cmake --install "$SRC/build" >/dev/null
