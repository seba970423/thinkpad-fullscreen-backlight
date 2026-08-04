# ThinkPad Fullscreen Backlight for KDE Plasma

Automatically turns off the ThinkPad keyboard backlight whenever a relevant
window enters fullscreen, then restores Plasma's previous keyboard-backlight
state when fullscreen ends.

## Features

- Native KDE Plasma 6 KWin script
- Event-driven fullscreen detection; no polling
- Respects Plasma's current keyboard-backlight state
- Off stays off after fullscreen
- Brightness level 1 restores to level 1
- Brightness level 2 restores to level 2
- Minimal privileged C helper
- Installer and uninstaller
- Optional logout prompt after installation and uninstallation

## Requirements

- KDE Plasma 6
- ThinkPad keyboard backlight exposed as `tpacpi::kbd_backlight`
- `gcc`
- `kpackagetool6`
- `kwriteconfig6`
- `qdbus6`
- systemd user services

## Installation

```bash
./install.sh
```

Run the installer as your normal user. It requests `sudo` only when installing
the restricted helper into `/usr/local/bin/kbdlight`.

At the end, the installer asks:

```text
Log out now? [y/N]:
```

Choose `y` to start a fresh Plasma session immediately. Press Enter or choose
`n` to remain logged in. The default is **No**.

## Behaviour

Immediately before the first relevant fullscreen window appears, the helper
reads the real ThinkPad keyboard-backlight brightness and stores it for the
current login session.

- Plasma backlight off (`0`) → remains off after fullscreen
- Brightness level `1` → restores level `1`
- Brightness level `2` → restores level `2`

While fullscreen is active, the backlight is set to `0`. When the final
fullscreen window closes or leaves fullscreen, the stored value is restored.

## Uninstallation

```bash
./uninstall.sh
```

After removal, the uninstaller offers the same optional logout prompt. The
KWin script is disabled and removed before the prompt appears.

## Manual override while fullscreen

The extension turns the keyboard backlight off once when fullscreen begins.

It does not lock the backlight off. If you manually change the keyboard
backlight through GNOME while remaining fullscreen, that choice is respected.

- Enter fullscreen → backlight turns off
- Turn it on manually while fullscreen → it stays on
- Turn it off manually while fullscreen → it stays off
- Exit fullscreen → the latest user-selected level is preserved

This matches the GNOME variant of this tool.

## License

MIT License
