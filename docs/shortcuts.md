# NickLab — shortcuts cheat sheet

**Meta** = the Windows/Super key.
Windows tile automatically (Krohnkite). The mouse still works for everything.

## The two you need most

| Keys | Action |
|---|---|
| **Meta** (tap) | Hints: the main Meta shortcuts, runnable (type to search) |
| **Meta + Space** | kalango menu: apps, settings, YaST, capture, power (type to search) |
| Alt + Space | KRunner: search files, settings, math |
| **Meta + /** | NickKeys: search every shortcut on the system |

## Mouse (works as usual)

| Action | How |
|---|---|
| Focus a window | Click it |
| Swap two tiled windows | Drag a window onto another one (Meta + left-drag if it has no title bar) |
| Resize tiles | Meta + right-drag, or drag the edge between two tiles |
| Move a window anywhere | Meta + left-drag |
| Float a window (stop tiling it) | Meta + F, then move it freely with the mouse |

## Move around (Vim keys)

| Keys | Action |
|---|---|
| Meta + H / J / K / L | Focus left / down / up / right |
| Meta + . / Meta + , | Focus next / previous window (no need to think about direction) |
| Alt + Tab | Classic window switcher |
| Meta + W | Overview of all windows and desktops |

Directional focus only moves if a window exists on that side.

## Arrange windows

| Keys | Action |
|---|---|
| Meta + Shift + H / J / K / L | Move the window left / down / up / right |
| Meta + Ctrl + H / J / K / L | Resize: shrink width / grow height / shrink height / grow width |
| Meta + Return | Make this window the main (big) one |
| Meta + I / Meta + D | More / fewer windows in the main area |
| Meta + R | Rotate the layout |
| Meta + F | Float / unfloat this window |
| Meta + Shift + F | Float / unfloat **all** windows (quick "normal desktop" mode) |

## Layouts

| Keys | Action |
|---|---|
| Meta + T | Tile layout (default: one big window + a stack) |
| Meta + M | Monocle: one window fills the screen, the others hide behind it |
| Meta + \ | Next layout |
| Meta + \| | Previous layout |

## Windows & desktop

| Keys | Action |
|---|---|
| Meta + Q / Alt + F4 | Close window (closes the app only if it was its last window) |
| Meta + PgUp / PgDown | Maximize / minimize |
| Meta + Shift + Right | Send window to the next monitor |
| Meta + F1 … F4 | Switch virtual desktop |
| Meta + G | Grid view of desktops |
| Alt + F1 | Plasma app menu (Kickoff) |
| Meta + Escape | Lock screen |
| Ctrl + Escape | System Monitor |
| Meta + Ctrl + Esc | Force-kill a frozen window (click it) |

## NickLab tools

| Command | What it does |
|---|---|
| `nickkeys` | Same shortcut list in the terminal (`nickkeys --print \| grep Tiling`) |
| `nickfont` | Pick a Nerd Font for the whole UI (live). `nickfont "GeistMono Nerd Font" 11` sets one directly |
| `nickborders-rebuild` | Run if the gradient borders vanish after a Plasma update (`zypper dup`), then log out/in |

## Where to tweak things

- **Shortcuts:** System Settings → Keyboard → Shortcuts → search "Krohnkite"
- **Gaps / tiling options:** System Settings → Window Management → KWin Scripts → Krohnkite ⚙
- **Borders / corners:** System Settings → Window Management → Desktop Effects → Rounded Corners ⚙
- **Colors:** System Settings → Colors → NickLab
