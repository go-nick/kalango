#!/usr/bin/env python3
"""Build the kalango icon theme: Papirus-Dark with kalango's own folders.

A small overlay theme. Every Papirus folder and place icon gets kalango's design,
black glass with a glowing neon outline, keeping Papirus's symbol (documents, music,
home, ...) recolored to neon. Everything else falls through to Papirus-Dark via
Inherits, so Papirus updates keep working.

The glow is layered translucent lines, not an SVG filter, because icon renderers
may ignore filters.

Generated from the installed Papirus (papirus-icon-theme, official repos), so it
follows Papirus updates when re-run.

Output: ~/.local/share/icons/kalango/ (or the folder given as an argument)
"""
import configparser
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

PAPIRUS = Path("/usr/share/icons/Papirus")
INDEX = Path("/usr/share/icons/Papirus-Dark/index.theme")
DST = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / ".local/share/icons/kalango"

FRONT = "#5294e2"   # Papirus's blue folder front, which identifies the icons we replace
SYMBOL = "#1d344f"  # Papirus's symbol color on those icons
NEON = "#3DFF9A"

# Drawn on a 64 x 64 grid and scaled to each size
OUTLINE = "M9 11 H24 Q26 11 27.5 12.5 L32 17 H55 Q60 17 60 22 V49 Q60 54 55 54 H9 Q4 54 4 49 V16 Q4 11 9 11 Z"
FLAP = "M4 26 H60"


def folder(size):
    """The folder at one icon size; small sizes drop the glow, which would turn to mud."""
    k = 64 / size   # stroke widths below are in real pixels
    line = f'fill="none" stroke="{NEON}" stroke-linejoin="round"'
    glow = "" if size < 32 else (
        f'<path d="{OUTLINE}" {line} stroke-opacity=".12" stroke-width="{4 * k}"/>'
        f'<path d="{OUTLINE}" {line} stroke-opacity=".22" stroke-width="{2.5 * k}"/>')
    flap = "" if size < 22 else f'<path d="{FLAP}" {line} stroke-opacity=".35" stroke-width="{k}"/>'
    return (f'<g transform="scale({size / 64})"><path d="{OUTLINE}" fill="#000000" fill-opacity=".8"/>'
            f'{glow}{flap}<path d="{OUTLINE}" {line} stroke-width="{(1 if size < 32 else 1.25) * k}"/></g>')


def redraw(svg):
    """Papirus's symbol, in neon, on kalango's folder."""
    size = int(re.search(r'<svg[^>]*\bwidth="(\d+)', svg).group(1))
    symbols = re.findall(rf'<(?:path|rect|circle|ellipse|g)\b[^>]*fill:{SYMBOL}[^>]*?/>', svg)
    symbols = "".join(s.replace(f"fill:{SYMBOL}", f"fill:{NEON}") for s in symbols)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}">'
            f'{folder(size)}{symbols}</svg>')


def main():
    if DST.exists():
        shutil.rmtree(DST)

    papirus = configparser.ConfigParser(interpolation=None, strict=False)
    papirus.optionxform = str
    papirus.read(INDEX)

    dirs = []
    # Real directories first: big sizes are symlinks to them (96 -> 48, 128 -> 64)
    for places in sorted(PAPIRUS.glob("*/places"), key=Path.is_symlink):
        name = f"{places.parent.name}/places"
        out = DST / name
        if places.is_symlink():
            target = places.readlink()
            # normpath: the size directory doesn't exist yet, so stat can't walk "../"
            if Path(os.path.normpath(out.parent / target)).exists() and papirus.has_section(name):
                out.parent.mkdir(parents=True, exist_ok=True)
                out.symlink_to(target)
                dirs.append(name)
            continue
        for icon in places.iterdir():
            if icon.suffix != ".svg" or not icon.exists():
                continue
            text = icon.read_text()
            if FRONT not in text:
                continue
            out.mkdir(parents=True, exist_ok=True)
            (out / icon.name).write_text(redraw(text))
        if out.exists() and papirus.has_section(name):
            dirs.append(name)

    theme = configparser.ConfigParser(interpolation=None)
    theme.optionxform = str
    theme["Icon Theme"] = {
        "Name": "kalango",
        "Comment": "Papirus-Dark with kalango's own folders",
        "Inherits": "Papirus-Dark,breeze-dark,hicolor",
        "Example": "folder",
        "Directories": ",".join(dirs),
    }
    for name in dirs:
        theme[name] = dict(papirus[name])
    with open(DST / "index.theme", "w") as f:
        theme.write(f, space_around_delimiters=False)

    subprocess.run(["gtk-update-icon-cache", "-q", "-f", "-t", DST], check=False)
    print(f"   {DST} ({sum(1 for _ in DST.rglob('*.svg'))} icons)")


if __name__ == "__main__":
    main()
