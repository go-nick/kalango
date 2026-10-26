#!/usr/bin/env bash
# Make KWin's Scale open/close animation fade kalango shell surfaces instead of zooming them.
#
# The launcher is a full-screen layer with blur behind it. Scale zooms every new window
# from 80%, which made the blur visibly grow. KWin fades blur together with window
# opacity, so keeping only the fade makes the blur start full-size and strengthen.
#
# Generates a user-level copy of the system effect (~/.local/share overrides /usr/share)
# with one change. Re-run after Plasma updates so the copy tracks upstream.
set -euo pipefail

SRC=/usr/share/kwin/effects/scale
DST="$HOME/.local/share/kwin/effects/scale"

rm -rf "$DST"
mkdir -p "$(dirname "$DST")"
cp -r "$SRC" "$DST"

python3 - "$DST/contents/code/main.js" <<'EOF'
import re, sys

path = sys.argv[1]
js = open(path, encoding="utf-8").read()

# Helper: kalango's Quickshell surfaces only fade
helper = '''    // kalango: Quickshell shell surfaces (launcher, ...) only fade, never zoom
    static isFadeOnly(window) {
        return window.windowClass.startsWith("quickshell ");
    }

    static isScaleWindow(window) {'''
js, n1 = re.subn(r"    static isScaleWindow\(window\) \{", helper, js, count=1)

# Drop the Scale step from the open and close animations for those surfaces
js, n2 = re.subn(
    r"\{\s*type: Effect\.Scale,\s*(from|to): (this\.(?:in|out)Scale)\s*\},",
    r"...(ScaleEffect.isFadeOnly(window) ? [] : [{ type: Effect.Scale, \1: \2 }]),",
    js)

if n1 != 1 or n2 != 2:
    sys.exit(f"kwin-scale-fade-only: upstream scale effect changed (helper={n1}, scale steps={n2}); update this script")
open(path, "w", encoding="utf-8").write(js)
EOF

# Reload so KWin picks up the user copy
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect scale >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect scale >/dev/null 2>&1 || true
