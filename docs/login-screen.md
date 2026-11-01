# Login screen

kalango's SDDM theme lives in `sddm/kalango`. `scripts/install-login-theme.sh` installs it
with sudo, along with the wallpapers, JetBrains Mono and the cursor, because SDDM runs as its
own user and can't read `$HOME`.

## Seeing it

- **Log out to see it.** This machine has autologin on (`DISPLAYMANAGER_AUTOLOGIN` in
  `/etc/sysconfig/displaymanager`), so a reboot skips the login screen. **A reboot doesn't test it.**
- **Preview:** `sddm-greeter-qt6 --test-mode --theme sddm/kalango`, with wallpapers in a
  `backgrounds/` folder next to `Main.qml`. It takes keyboard focus, so don't type elsewhere.

Test mode only checks how the theme draws. It doesn't match a real logout, so always finish with one:

| | Test mode | Real logout |
|---|---|---|
| Greeter | Started directly | SDDM picks it from `metadata.desktop` |
| Display | Your Wayland session | X11, as user `sddm` |
| On-screen keyboard | Off | On, unless the config turns it off |
| Power buttons | Hidden | Shown |

## Two settings it needs

Both failed only at a real logout (#23):

- **`QtVersion=6` in `metadata.desktop`.** Without it SDDM looks for the Qt5 `sddm-greeter`, doesn't
  find it, and uses its built-in theme: a blue screen with a failed login attempt.
- **`InputMethod=` (empty) in `/etc/sddm.conf.d/10-kalango.conf`.** SDDM defaults to
  `qtvirtualkeyboard`, which opens a large on-screen keyboard over the card. Breeze manages that
  keyboard in its own code; our theme doesn't, so it stays off. For a touchscreen-only machine,
  this is what would need revisiting.

## When it goes wrong

Back to the stock login, from a text console (Ctrl+Alt+F3) if needed. The restart ends any open session:

```
sudo rm /etc/sddm.conf.d/10-kalango.conf
sudo systemctl restart display-manager
```

Read what happened at the last logout:

```
sudo journalctl -b --no-pager | grep -iE "sddm-greeter|greeter|Main\.qml|/themes/"
```

Look for `Using fallback theme` and `Loading ... Main.qml`: `qrc:/theme/Main.qml` means the
built-in theme loaded, not ours.
