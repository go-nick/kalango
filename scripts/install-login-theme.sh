#!/usr/bin/env bash
# Install the kalango login screen (needs sudo). SDDM runs as its own user and can't
# read $HOME, so the theme, wallpapers, font and cursor go to system folders.
# Run install-wallpapers.sh, install-fonts.sh and build-cursors.py first.
#
# Back to the stock theme: sudo rm /etc/sddm.conf.d/10-kalango.conf
# (from a text console, Ctrl+Alt+F3, if the login screen itself is the problem)
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
THEME=/usr/share/sddm/themes/kalango
FONTS=/usr/share/fonts/kalango
CURSORS=/usr/share/icons/kalango-cursors

sudo rm -rf "$THEME" "$FONTS" "$CURSORS"
sudo install -d "$THEME/backgrounds" "$FONTS" /etc/sddm.conf.d
sudo install -m 644 "$REPO"/sddm/kalango/* "$THEME/"
sudo install -m 644 "$HOME"/.local/share/wallpapers/kalango/*.png "$THEME/backgrounds/"
sudo install -m 644 "$HOME"/.local/share/fonts/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-*.ttf "$FONTS/"
sudo fc-cache -f "$FONTS"
sudo cp -r --no-preserve=ownership "$HOME/.icons/kalango-cursors" "$CURSORS"
sudo chmod -R a+rX "$CURSORS"
printf '[Theme]\nCurrent=kalango\nCursorTheme=kalango-cursors\n' \
    | sudo tee /etc/sddm.conf.d/10-kalango.conf >/dev/null
echo "   login screen installed; see it at your next logout"
