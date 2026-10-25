#!/usr/bin/env bash
# kalango — write the KDE settings kalango owns, then reload what can reload live.
# Only touches specific keys; everything else in the KDE configs stays yours.
set -euo pipefail

kw() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }

echo ":: colors"
plasma-apply-colorscheme NickLab >/dev/null

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

echo ":: blur"
kw kwinrc Plugins blurEnabled true
kw kwinrc Effect-blur BlurStrength 10
kw kwinrc Effect-blur NoiseStrength 2

echo ":: konsole"
kw konsolerc "Desktop Entry" DefaultProfile NickLab.profile

echo ":: shortcuts"
sc() { kwriteconfig6 --file kglobalshortcutsrc --group "$1" --key "$2" "$3"; }
sc ksmserver   "Lock Session"      "Screensaver	Meta+Escape,Screensaver	Meta+L,Lock Session"
sc kwin        "Window Close"      "Alt+F4	Meta+Q,Alt+F4,Close Window"
sc kwin        "Show Desktop"      "none,Meta+D,Peek at Desktop"
sc kwin        "Edit Tiles"        "none,Meta+T,Toggle Tiles Editor"
sc plasmashell "manage activities" "none,Meta+Q,Show Activity Switcher"
kwriteconfig6 --file kglobalshortcutsrc --group services --group nickkeys.desktop --key _launch "Meta+/"
kwriteconfig6 --file kglobalshortcutsrc --group services --group org.kde.krunner.desktop --key _launch "Meta+Space	Alt+Space	Alt+F2	Search"

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
echo "done. Log out and back in once so KWin reloads scripts, effects and shortcuts."
