#!/usr/bin/env bash
# Install Flight Deck Calendar into the kalango shell, where its qs.* imports resolve,
# and apply kalango's patch for the names that clash on Qt 6.12.
# Only what runs is copied: Quickshell would otherwise scan the project's test folders.
set -euo pipefail

VERSION=v1.1.0
REPO=$(cd "$(dirname "$0")/.." && pwd)
DEST="$HOME/.config/quickshell/kalango/flight-deck"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/joryeugene/omarchy-calendar/archive/refs/tags/$VERSION.tar.gz" \
    | tar -xz -C "$TMP" --strip-components=1

rm -rf "$DEST"
mkdir -p "$DEST"
cp -r "$TMP"/*.qml "$TMP"/*.js "$TMP/calendarctl" "$TMP/src" "$TMP/LICENSE" "$DEST/"
(cd "$DEST" && git apply "$REPO/patches/flight-deck-qt612-names.patch")
echo "   $VERSION"
