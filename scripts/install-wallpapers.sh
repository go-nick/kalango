#!/usr/bin/env bash
# Render kalango's wallpaper SVGs to 4K PNGs in ~/.local/share/wallpapers/kalango.
# The SVGs in wallpapers/ are the source; PNGs are rendered because Plasma's SVG
# support skips filters (the glows). Only re-renders when an SVG is newer.
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
DST="$HOME/.local/share/wallpapers/kalango"

mkdir -p "$DST"
for svg in "$REPO"/wallpapers/*.svg; do
    png="$DST/$(basename "${svg%.svg}").png"
    [[ "$png" -nt "$svg" ]] && continue
    rsvg-convert --width 3840 --height 2160 --output "$png" "$svg"
    echo "   $(basename "$png")"
done
