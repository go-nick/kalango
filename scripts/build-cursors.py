#!/usr/bin/env python3
"""Build the kalango cursor theme: KDE's Breeze cursors recolored to the palette.

Neon green outline, Void spinner with blue and green arcs. Generated from the
installed Breeze cursors, so it follows Plasma updates when re-run.

Output: ~/.icons/kalango-cursors/ (the cursor tools and libXcursor search ~/.icons,
not ~/.local/share/icons)
  cursors_scalable/  SVG cursors (Plasma 6 Wayland, sharp at any size)
  cursors/           classic Xcursor files for XWayland apps (needs xcursorgen)
"""
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

SRC = Path("/usr/share/icons/breeze_cursors")
DST = Path.home() / ".icons/kalango-cursors"
SIZES = [24, 32, 48, 64, 96]

RECOLOR = [
    # Spinner disc: white -> Void with a neon ring (before the generic white rule)
    (re.compile(r'(<circle[^>]*)fill="#fff"'), r'\1fill="#0A0F14" stroke="#3DFF9A" stroke-width="1.2"'),
    (re.compile(r'fill="#fff"'), 'fill="#3DFF9A"'),     # outline: neon green
    (re.compile(r'fill="#46a7ac"'), 'fill="#3DFF9A"'),  # spinner arc
    (re.compile(r'fill="#d4497f"'), 'fill="#2E6BFF"'),  # spinner arc
    (re.compile(r'fill="#3daee9"'), 'fill="#2E6BFF"'),  # accents
]


def recolor(svg):
    text = svg.read_text()
    for pattern, repl in RECOLOR:
        text = pattern.sub(repl, text)
    svg.write_text(text)


def build_xcursor(name, scalable, out, tmp):
    """Render one SVG cursor (all frames) at every size into an Xcursor file."""
    frames = json.loads((scalable / name / "metadata.json").read_text())
    lines = []
    for size in SIZES:
        for frame in frames:
            scale = size / frame["nominal_size"]
            svg = scalable / name / frame["filename"]
            width = int(re.search(r'width="([\d.]+)"', svg.read_text()).group(1))
            png = tmp / f"{name}-{size}-{frame['filename']}.png"
            subprocess.run(["rsvg-convert", "-w", str(round(width * scale)), "-o", png, svg], check=True)
            line = f"{size} {round(frame['hotspot_x'] * scale)} {round(frame['hotspot_y'] * scale)} {png}"
            if "delay" in frame:
                line += f" {frame['delay']}"
            lines.append(line)
    cfg = tmp / f"{name}.cfg"
    cfg.write_text("\n".join(lines) + "\n")
    subprocess.run(["xcursorgen", cfg, out / name], check=True)


def main():
    if DST.exists():
        shutil.rmtree(DST)
    scalable = DST / "cursors_scalable"
    shutil.copytree(SRC / "cursors_scalable", scalable, symlinks=True)
    for svg in scalable.rglob("*.svg"):
        if not svg.is_symlink():
            recolor(svg)

    # Xcursors: same names as Breeze; aliases stay symlinks
    xcursors = DST / "cursors"
    xcursors.mkdir()
    with tempfile.TemporaryDirectory() as tmp:
        for entry in sorted((SRC / "cursors").iterdir()):
            if entry.is_symlink():
                (xcursors / entry.name).symlink_to(entry.readlink())
            elif (scalable / entry.name / "metadata.json").exists():
                build_xcursor(entry.name, scalable, xcursors, Path(tmp))

    (DST / "index.theme").write_text(
        "[Icon Theme]\n"
        "Name=kalango\n"
        "Comment=Breeze cursors in the kalango palette\n"
        "Inherits=breeze_cursors\n")
    print(f"   {DST}")


if __name__ == "__main__":
    main()
