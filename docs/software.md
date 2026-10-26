# What kalango installs

Everything kalango puts on a machine, grouped by where it comes from. For the ISO,
every row must be an RPM: the first group already is; the rest still need packaging
on OBS (see kalango's packaging rule in the README).

## 1. Official openSUSE packages

Listed in [`packages.txt`](../packages.txt) and installed by `install.sh` with zypper.
Already RPMs from the official Tumbleweed repos, so they go straight onto the ISO.
Build tools in that list are only needed until the pieces in group 2 ship as RPMs.

## 2. Built or downloaded by kalango (needs OBS packaging)

| Software | Version | Installed by | Goes to | Notes |
|---|---|---|---|---|
| Quickshell | v0.3.2 | `scripts/build-quickshell.sh` | `~/.local` | Top bar and launcher. Built against Qt private API: rebuild on Qt updates |
| KDE-Rounded-Corners + `patches/kde-rounded-corners-spin-gradient.patch` | v0.11.0 | `scripts/build-borders.sh` | `/usr` (sudo `cmake --install`, **not tracked by rpm**) | Window borders. Must be rebuilt for every KWin version (#6) |
| Krohnkite + `patches/krohnkite-cross-screen-focus.patch` | 0.9.9.2 | `scripts/install-krohnkite.sh` | `~/.local/share/kwin/scripts` | Tiling (KWin script) |
| Nerd Fonts (12 monospace families) | latest release, **unpinned** | `scripts/install-fonts.sh` | `~/.local/share/fonts/NerdFonts` | Pin a version when packaging; check which already exist in openSUSE repos |
| KWin Scale effect, kalango copy | follows installed KWin | `scripts/kwin-scale-fade-only.sh` | `~/.local/share/kwin/effects/scale` | Launcher fades instead of zooming. Becomes a patch or goes away (#6) |

## 3. kalango's own files

From this repo, copied or generated into `$HOME` today. On the ISO these become
kalango RPMs that install system-wide defaults (`/usr/share`, `/etc/xdg`, `/etc/skel`).

| What | Source | Installed to |
|---|---|---|
| Quickshell config (top bar, launcher) | `home/.config/quickshell/kalango/` | `~/.config/quickshell/kalango` |
| Color scheme, Konsole profile | `home/.local/share/color-schemes`, `home/.local/share/konsole` | same under `~` |
| Tools: `nickfont`, `nickkeys`, `nickborders-rebuild` | `home/.local/bin`, `home/.local/share/nicklab`, `home/.config/nicklab` | same under `~` |
| Launchers, autostart | `home/.local/share/applications`, `home/.config/autostart` | same under `~` |
| Wallpapers (calango: sunbath, scales, line) | `wallpapers/*.svg`, rendered by `scripts/install-wallpapers.sh` | `~/.local/share/wallpapers/kalango` (4K PNG) |
| KDE settings, shortcuts, window rules, panel removal, slideshow | `apply.sh`, `scripts/kde-shortcut.py` | KDE config files in `~/.config` |

## Not shipped

Development tools used to build kalango itself, such as `gh` and `git`.
