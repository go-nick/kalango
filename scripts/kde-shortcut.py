#!/usr/bin/env python3
"""Set a KDE global shortcut live through kglobalaccel (no logout needed).

    kde-shortcut.py <component> <action> <key> [<key> ...]
    kde-shortcut.py kwin "Window Close" Alt+F4 Meta+Q
    kde-shortcut.py kalango-hints.desktop _launch Meta     # lone Meta tap
    kde-shortcut.py kwin "Show Desktop"                     # no keys = unbind

kglobalaccel persists the result to kglobalshortcutsrc itself. Uses
setForeignShortcutKeys, the call System Settings uses: the self-registration
call (setShortcutKeys) silently refuses modifier-only keys such as a lone Meta.

setForeignShortcutKeys does not check conflicts (two actions can end up on one
key), so this refuses any key another action owns. Free it first.
"""
import sys

import dbus

MODIFIERS = {"Shift": 0x02000000, "Ctrl": 0x04000000, "Alt": 0x08000000, "Meta": 0x10000000}
KEYS = {
    "Space": 0x20, "/": 0x2F, "Escape": 0x01000000, "Esc": 0x01000000, "Return": 0x01000004,
    "Search": 0x01000092, "Screensaver": 0x010000BA,
    # Modifier keys on their own (a lone tap)
    "Meta": 0x01000022, "Alt": 0x01000023, "Ctrl": 0x01000021, "Shift": 0x01000020,
    **{f"F{n}": 0x01000030 + n - 1 for n in range(1, 13)},
}


def key_code(text):
    *mods, key = text.split("+") if text != "+" else ["+"]
    code = 0
    for m in mods:
        if m not in MODIFIERS:
            sys.exit(f"kde-shortcut: unknown modifier {m!r} in {text!r}")
        code |= MODIFIERS[m]
    if key in KEYS:
        code |= KEYS[key]
    elif len(key) == 1:
        code |= ord(key.upper())
    else:
        sys.exit(f"kde-shortcut: unknown key {key!r} in {text!r}")
    return code


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    component, action, *keys = sys.argv[1:]
    codes = [key_code(k) for k in keys]

    accel = dbus.Interface(dbus.SessionBus().get_object("org.kde.kglobalaccel", "/kglobalaccel"),
                           "org.kde.KGlobalAccel")
    action_id = [component, action, component, action]
    for key, code in zip(keys, codes):
        owners = [(str(o[2]), str(o[0])) for o in accel.getGlobalShortcutsByKey(code)]
        others = [o for o in owners if o != (component, action)]
        if others:
            sys.exit(f"kde-shortcut: {key} is already used by "
                     + ", ".join(f"{c} / {a}" for c, a in others) + "; unbind it first")
    accel.doRegister(action_id)
    accel.setForeignShortcutKeys(action_id, dbus.Array(
        [dbus.Struct([dbus.Array([dbus.Int32(c), 0, 0, 0], signature="i")]) for c in codes],
        signature="(ai)"))

    got = sorted(int(s[0][0]) for s in accel.shortcutKeys(action_id))
    if got != sorted(codes):
        sys.exit(f"kde-shortcut: {component} / {action}: wanted {keys}, kglobalaccel kept "
                 f"{[hex(c) for c in got]} (key already taken?)")


if __name__ == "__main__":
    main()
