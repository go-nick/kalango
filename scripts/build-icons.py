#!/usr/bin/env python3
"""Build the kalango icon theme: Papirus-Dark with folders in the kalango gradient.

A small overlay theme. It only contains Papirus's blue folder icons (folder,
documents, downloads, home, ...), recolored: the folder front becomes the blue ->
green gradient, the tab a darker gradient, the symbol Void. Everything else
falls through to Papirus-Dark via Inherits, so Papirus updates keep working.

Generated from the installed Papirus (papirus-icon-theme, official repos), so it
follows Papirus updates when re-run.

Output: ~/.local/share/icons/kalango/
"""
import configparser
import os
import re
import shutil
import subprocess
from pathlib import Path

PAPIRUS = Path("/usr/share/icons/Papirus")
INDEX = Path("/usr/share/icons/Papirus-Dark/index.theme")
DST = Path.home() / ".local/share/icons/kalango"

FRONT = "#5294e2"   # Papirus blue folder colors
TAB = "#4877b1"
SYMBOL = "#1d344f"

GRADIENTS = (
    '<defs>'
    '<linearGradient id="kalango-front" x1="0" y1="0" x2="1" y2="0">'
    '<stop offset="0" stop-color="#2E6BFF"/><stop offset="1" stop-color="#3DFF9A"/>'
    '</linearGradient>'
    '<linearGradient id="kalango-tab" x1="0" y1="0" x2="1" y2="0">'
    '<stop offset="0" stop-color="#1D47B8"/><stop offset="1" stop-color="#25B86E"/>'
    '</linearGradient>'
    '</defs>'
)


def recolor(svg):
    svg = svg.replace(f"fill:{FRONT}", "fill:url(#kalango-front)")
    svg = svg.replace(f"fill:{TAB}", "fill:url(#kalango-tab)")
    svg = svg.replace(f"fill:{SYMBOL}", "fill:#0A0F14")
    # Gradients go right after the opening <svg ...> tag
    return re.sub(r"(<svg[^>]*>)", r"\1" + GRADIENTS, svg, count=1)


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
            (out / icon.name).write_text(recolor(text))
        if out.exists() and papirus.has_section(name):
            dirs.append(name)

    theme = configparser.ConfigParser(interpolation=None)
    theme.optionxform = str
    theme["Icon Theme"] = {
        "Name": "kalango",
        "Comment": "Papirus-Dark with folders in the kalango gradient",
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
