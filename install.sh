#!/usr/bin/env bash
# kalango installer — openSUSE Tumbleweed + KDE Plasma 6.
# Safe to re-run: every step skips or overwrites what is already there.
set -euo pipefail

REPO=$(cd "$(dirname "$0")" && pwd)

echo ":: packages (sudo)"
grep -vE '^\s*(#|$)' "$REPO/packages.txt" | xargs sudo zypper --non-interactive install --no-recommends

echo ":: files -> \$HOME"
# Copy home/ into $HOME, filling in @HOME@ placeholders
(cd "$REPO/home" && find . -type f) | while read -r f; do
    dest="$HOME/${f#./}"
    # Never clobber favorites someone already starred
    [[ "$f" == */keys-favorites.json && -e "$dest" ]] && continue
    # Wave writes to its own settings; only new users get kalango's
    [[ "$f" == */waveterm/settings.json && -e "$dest" ]] && continue
    mkdir -p "$(dirname "$dest")"
    # Dev setups symlink repo dirs into $HOME; writing a file onto itself would empty it
    [[ "$(realpath -m "$dest")" == "$(realpath "$REPO/home/$f")" ]] && continue
    sed "s|@HOME@|$HOME|g" "$REPO/home/$f" > "$dest"
    [[ -x "$REPO/home/$f" ]] && chmod +x "$dest"
done
kbuildsycoca6 >/dev/null 2>&1 || true

echo ":: fonts"
"$REPO/scripts/install-fonts.sh"

echo ":: krohnkite"
"$REPO/scripts/install-krohnkite.sh"

echo ":: wallpapers"
"$REPO/scripts/install-wallpapers.sh"

echo ":: icons"
"$REPO/scripts/build-icons.py"

echo ":: cursors"
"$REPO/scripts/build-cursors.py"

echo ":: borders"
"$REPO/scripts/build-borders.sh"

echo ":: quickshell"
"$REPO/scripts/build-quickshell.sh"

echo ":: calendar"
"$REPO/scripts/install-calendar.sh"

echo ":: wave terminal (sudo)"
"$REPO/scripts/install-wave.sh"

echo ":: zen browser"
"$REPO/scripts/install-zen.sh"

echo ":: login screen (sudo)"
"$REPO/scripts/install-login-theme.sh"

"$REPO/apply.sh"
