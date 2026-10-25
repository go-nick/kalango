#!/usr/bin/env bash
# Download Nerd Fonts (latest release) into ~/.local/share/fonts/NerdFonts.
set -euo pipefail

FONTS=(CascadiaMono JetBrainsMono GeistMono FiraCode IBMPlexMono Iosevka
       SpaceMono VictorMono Mononoki Meslo ZedMono Hack)
DEST="$HOME/.local/share/fonts/NerdFonts"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for f in "${FONTS[@]}"; do
    if [[ -d "$DEST/$f" ]] && compgen -G "$DEST/$f/*" >/dev/null; then
        echo "   $f already installed"; continue
    fi
    echo "   $f"
    mkdir -p "$TMP/$f" "$DEST/$f"
    curl -fsSL -o "$TMP/$f.tar.xz" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$f.tar.xz"
    tar -xJf "$TMP/$f.tar.xz" -C "$TMP/$f"
    # Proportional variants are skipped: kalango wants monospace everywhere
    find "$TMP/$f" -type f \( -name '*.ttf' -o -name '*.otf' \) ! -name '*Propo*' \
        -exec cp {} "$DEST/$f/" \;
done
fc-cache -f "$HOME/.local/share/fonts" >/dev/null
