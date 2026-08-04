# ThinkPad Fullscreen Backlight

Automatically turns off the ThinkPad keyboard backlight whenever a window enters fullscreen on KDE Plasma 6 Wayland, then restores the user's selected brightness level when fullscreen ends.

## Features

- Event-driven; no polling
- Native KDE Plasma 6 KWin script
- Selectable restore brightness: level 1 or 2
- Uses a systemd user service
- Tiny privileged C helper restricted to brightness values 0, 1, and 2
- Includes an uninstaller

## Requirements

- KDE Plasma 6
- Wayland
- ThinkPad with `thinkpad_acpi` keyboard backlight support
- systemd
- GCC
- `kpackagetool6`, `kwriteconfig6`, and `qdbus6`

## Supported hardware

Currently tested on ThinkPad laptops exposing this keyboard backlight interface:

```text
/sys/class/leds/tpacpi::kbd_backlight
```

The installer also checks that the device reports support for brightness level 2.

## Installation

Clone the repository:

```bash
git clone https://github.com/seba970423/thinkpad-fullscreen-backlight.git
cd thinkpad-fullscreen-backlight
```

Run the installer as your normal user:

```bash
./install.sh
```

The installer asks whether the backlight should return to level `1` or `2` after leaving fullscreen. Pressing Enter selects level `2`.

Do not run the entire installer with `sudo`. It requests elevation only when installing the small helper into `/usr/local/bin`.

Running the installer again upgrades the KWin script and lets you change the selected restore brightness.

## Uninstallation

Run the uninstaller as your normal user:

```bash
./uninstall.sh
```

It disables and removes the KWin script, deletes its saved brightness setting and systemd user service, and removes `/usr/local/bin/kbdlight`.

## Project files

- `kbdlight.c` — restricted helper that writes brightness values to the ThinkPad sysfs interface
- `contents/code/main.js` — event-driven KWin script
- `contents/config/main.xml` — KWin configuration schema
- `metadata.json` — KWin package metadata
- `kbdlight@.service` — systemd user service template
- `install.sh` — installer and brightness selector
- `uninstall.sh` — complete uninstaller

## License

MIT
