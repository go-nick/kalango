#!/usr/bin/env bash
# kalango — write the KDE settings kalango owns, then reload what can reload live.
# Only touches specific keys; everything else in the KDE configs stays yours.
set -euo pipefail

kw() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }

echo ":: colors"
plasma-apply-colorscheme NickLab >/dev/null

echo ":: cursor"
# Built by scripts/build-cursors.py; applies live
plasma-apply-cursortheme kalango-cursors >/dev/null

echo ":: fonts"
"$HOME/.local/bin/nickfont" "FiraCode Nerd Font" 10 >/dev/null
kw kdeglobals General XftAntialias true
kw kdeglobals General XftHintStyle hintslight
kw kdeglobals General XftSubPixel rgb

echo ":: tiling (Krohnkite)"
kw kwinrc Plugins krohnkiteEnabled true
for k in screenGapLeft screenGapRight screenGapTop screenGapBottom screenGapBetween; do
    kw kwinrc Script-krohnkite "$k" 10
done
kw kwinrc Script-krohnkite noTileBorder true
kw kwinrc Script-krohnkite floatingTitle NickKeys
# KWin's own edge snapping fights the tiler
kw kwinrc Windows ElectricBorderMaximize false
kw kwinrc Windows ElectricBorderTiling false

echo ":: borders (KDE-Rounded-Corners)"
kw kwinrc Plugins kwin4_effect_shapecornersEnabled true
rc() { kw kwinrc Round-Corners "$1" "$2"; }
rc Size 6;                    rc InactiveCornerRadius 6;   rc UseSquircleShape false
rc OutlineThickness 2;        rc OutlineIsGradient true;   rc ActiveOutlineUseCustom true
rc OutlineColor 46,107,255;   rc OutlineColor2 61,255,154; rc OutlineGradientAngle 0
rc OutlineSpinSeconds 8       # kalango patch: seconds per rotation, 0 = static
rc InactiveOutlineThickness 2; rc InactiveOutlineIsGradient false
rc InactiveOutlineColor 12,50,44; rc InactiveOutlineUseCustom true
rc SecondOutlineThickness 0;  rc InactiveSecondOutlineThickness 0
rc ShadowSize 30;             rc InactiveShadowSize 15
rc DisableRoundTile false;    rc DisableOutlineTile false
rc DisableRoundMaximize true; rc DisableOutlineMaximize true
# kalango shell surfaces (launcher, ...) draw their own frames
rc Exclusions quickshell

echo ":: open/close animation"
# Scale zooms new windows; kalango shell surfaces should only fade (see script)
"$(dirname "$0")/scripts/kwin-scale-fade-only.sh"

echo ":: blur"
kw kwinrc Plugins blurEnabled true
kw kwinrc Effect-blur BlurStrength 3
kw kwinrc Effect-blur NoiseStrength 2

echo ":: top bar"
# The kalango top bar (Quickshell) replaces Plasma's panels. Bring one back
# any time: right-click the desktop > Add Panel.
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
    'panels().forEach(p => p.remove())' >/dev/null
# Notifications sit under the bar's bell until kalango has its own
kw plasmanotifyrc Notifications PopupPosition TopLeft

echo ":: wallpapers"
# Plasma's slideshow crossfades between the kalango wallpapers on every monitor
# (PNGs rendered by scripts/install-wallpapers.sh). FillMode 2 = crop to fill,
# so the portrait monitor gets the centre of each drawing.
WALLS="$HOME/.local/share/wallpapers/kalango"
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    desktops().forEach(d => {
        d.wallpaperPlugin = 'org.kde.slideshow';
        d.currentConfigGroup = ['Wallpaper', 'org.kde.slideshow', 'General'];
        d.writeConfig('SlidePaths', ['$WALLS/']);
        d.writeConfig('SlideInterval', 600);   // seconds
        d.writeConfig('FillMode', 2);
        d.reloadConfig();
    })" >/dev/null

echo ":: konsole"
kw konsolerc "Desktop Entry" DefaultProfile NickLab.profile

echo ":: shortcuts"
# Set live through kglobalaccel (no logout). The helper refuses keys another
# action owns, so free keys before binding them.
ks() { "$(dirname "$0")/scripts/kde-shortcut.py" "$@"; }
ks kwin "Show Desktop"                                     # frees Meta+D for Krohnkite
ks kwin "Edit Tiles"                                       # frees Meta+T for Krohnkite
ks plasmashell "manage activities"                         # frees Meta+Q
ks org.kde.krunner.desktop _launch Alt+Space Alt+F2 Search # frees Meta+Space
ks kalango-launcher.desktop _launch Meta+Space
ks plasmashell "activate application launcher" Alt+F1     # frees lone Meta; Kickoff keeps Alt+F1
ks kalango-hints.desktop _launch Meta                      # lone Meta tap: hint mode
ks org.kde.plasma-systemmonitor.desktop _launch Ctrl+Escape # frees Meta+Escape
ks ksmserver "Lock Session" Screensaver Meta+Escape        # frees Meta+L for Krohnkite
ks kwin "Window Close" Alt+F4 Meta+Q
ks nickkeys.desktop _launch Meta+/

echo ":: window rules"
R=kwinrulesrc id=nickkeys-popup
kw $R $id Description "NickKeys popup"
kw $R $id title NickKeys;               kw $R $id titlematch 1
kw $R $id wmclass org.qt-project.qml6;  kw $R $id wmclassmatch 1
kw $R $id size 1100,650;                kw $R $id sizerule 3
kw $R $id placement 5;                  kw $R $id placementrule 3
kw $R $id above true;                   kw $R $id aboverule 3
kw $R $id skiptaskbar true;             kw $R $id skiptaskbarrule 3
kw $R $id decorationpolicy none;        kw $R $id decorationpolicyrule 3
rules=$(kreadconfig6 --file $R --group General --key rules)
case ",$rules," in
    *",$id,"*) ;;
    *) rules="${rules:+$rules,}$id"
       kw $R General count "$(( $(kreadconfig6 --file $R --group General --key count --default 0) + 1 ))" ;;
esac
kw $R General rules "$rules"

echo ":: reload"
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
# Effects only re-read their settings when reconfigured individually
for fx in kwin4_effect_shapecorners blur; do
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect "$fx" >/dev/null 2>&1 || true
done
echo "done. Log out and back in once so KWin reloads scripts, effects and shortcuts."
