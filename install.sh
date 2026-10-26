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
    [[ "$f" == */nickkeys-favorites.json && -e "$dest" ]] && continue
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

echo ":: borders"
"$REPO/scripts/build-borders.sh"

echo ":: quickshell"
"$REPO/scripts/build-quickshell.sh"

"$REPO/apply.sh"
