# ThinkPad Fullscreen Backlight

Automatically turns off the ThinkPad keyboard backlight whenever a window enters fullscreen on KDE Plasma 6 Wayland, and restores it when exiting fullscreen.

## Features

- Event-driven (no polling)
- Native KDE Plasma 6 KWin script
- Uses a systemd user service
- Tiny C helper for ThinkPad keyboard backlight control

## Requirements

- KDE Plasma 6
- Wayland
- ThinkPad with `thinkpad_acpi` keyboard backlight support
- systemd
- GCC

## Supported hardware

Currently tested on ThinkPad laptops exposing the following keyboard backlight interface:

`/sys/class/leds/tpacpi::kbd_backlight`

## Project files

- `kbdlight.c` — C helper that controls the keyboard backlight
- `contents/code/main.js` — KWin script
- `metadata.json` — KWin package metadata
- `kbdlight@.service` — systemd user service
- `install.sh` — installation script
- `uninstall.sh` — uninstallation script

## Installation

Clone the repository:

```bash
git clone https://github.com/seba970423/thinkpad-fullscreen-backlight.git
cd thinkpad-fullscreen-backlight
```

Run the installer:

```bash
./install.sh
```

The installer will request your password only when installing the privileged helper into `/usr/local/bin`.

## Uninstallation

```bash
./uninstall.sh
```

## License

MIT
