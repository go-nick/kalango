#!/usr/bin/env bash
# Install Zen Browser from its official GitHub release tarball, at a pinned version.
set -euo pipefail

VERSION=1.24b
SHA256=323f2682e73e38247a51fbcc75e5628ed2bb9b404db00cf9cf16af329a916fae
DEST="$HOME/.local/opt/zen"

# Never replace an existing install: its updater may have moved past this pin,
# and going back a version can break the user's profile.
if [[ -x "$DEST/zen" ]]; then
    echo "   already installed"
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/zen.tar.xz" \
    "https://github.com/zen-browser/desktop/releases/download/$VERSION/zen.linux-x86_64.tar.xz"
echo "$SHA256  $TMP/zen.tar.xz" | sha256sum -c --quiet
mkdir -p "$(dirname "$DEST")"
tar -xJf "$TMP/zen.tar.xz" -C "$(dirname "$DEST")"
echo "   $VERSION"
