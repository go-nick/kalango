# kalango

A beginner-friendly, Omarchy-inspired rice for **openSUSE Tumbleweed + KDE Plasma 6**.
Tiling with gaps and no title bars, a spinning blue→green border on the focused window,
and searchable shortcuts — while the mouse keeps working for everything.

## Palette

| Name | Hex | Role |
|---|---|---|
| Void | `#0A0F14` | background |
| Neon green | `#3DFF9A` | primary (60%) |
| Electric blue | `#2E6BFF` | secondary (30%) |
| Solar yellow | `#FFD23F` | accent (10%) |
| Pine | `#0C322C` | panels |
| Brazil blue | `#002776` | deep panels |
| SUSE green | `#30BA78` | soft green |
| Text | `#E6F1EC` | body text |

Gradient: `#2E6BFF → #3DFF9A`, left to right.

## What's in it

| Piece | What it does |
|---|---|
| **NickLab color scheme** | Flat dark KDE colors from the palette |
| **Nerd Fonts + `nickfont`** | 12 monospace Nerd Fonts and a live font switcher |
| **Krohnkite** (patched) | Auto-tiling, 10px gaps, borderless tiles; Meta+H/J/K/L focus also crosses monitors |
| **KDE-Rounded-Corners** (patched) | 2px gradient border that slowly rotates on the active window |
| **NickLab Konsole** | Translucent, blurred terminal with palette ANSI colors |
| **NickKeys** (`Meta+/`) | Popup that searches every shortcut, with favorites pinned on top |
| **KRunner** (`Meta+Space`) | Search apps, files, settings, math |

See [docs/shortcuts.md](docs/shortcuts.md) for the cheat sheet.

## Install

```bash
git clone https://github.com/go-nick/kalango.git
cd kalango
./install.sh      # asks for sudo for packages and the border effect
```

Then log out and back in once.

Re-apply only the KDE settings (no downloads, no sudo): `./apply.sh`

## Layout

```
home/        files copied into $HOME (@HOME@ is replaced with your home path)
apply.sh     the exact KDE config keys kalango owns, written with kwriteconfig6
install.sh   packages → files → fonts → krohnkite → borders → apply.sh
scripts/     one installer per third-party piece
patches/     kalango's changes to Krohnkite and KDE-Rounded-Corners
packages.txt zypper packages
```

## After a Plasma update

The border effect is compiled against your exact KWin version. If borders vanish after
`zypper dup`, run `nickborders-rebuild` (or `scripts/build-borders.sh`) and log out/in.

`scripts/kwin-scale-fade-only.sh` keeps a patched copy of KWin's Scale animation so the
launcher fades instead of zooming. Re-run it after a Plasma update so the copy tracks upstream;
it stops with an error if upstream changed too much to patch.

## Upstream projects

- [Krohnkite](https://github.com/anametologin/krohnkite) 0.9.9.2
- [KDE-Rounded-Corners](https://github.com/matinlotfali/KDE-Rounded-Corners) v0.11.0
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)
