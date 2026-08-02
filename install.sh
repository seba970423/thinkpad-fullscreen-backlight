#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HELPER_SOURCE="$PROJECT_DIR/kbdlight.c"
HELPER_BUILD="$PROJECT_DIR/kbdlight"
SERVICE_SOURCE="$PROJECT_DIR/kbdlight@.service"
KWIN_PLUGIN_ID="thinkpad-fullscreen-backlight"

if [[ $EUID -eq 0 ]]; then
    echo "Do not run the entire installer with sudo."
    echo "Run it normally: ./install.sh"
    exit 1
fi

for command in gcc sudo install kpackagetool6 kwriteconfig6 qdbus6 systemctl; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Missing required command: $command"
        exit 1
    fi
done

if [[ ! -e /sys/class/leds/tpacpi::kbd_backlight/brightness ]]; then
    echo "ThinkPad keyboard backlight interface was not found."
    echo "Expected:"
    echo "  /sys/class/leds/tpacpi::kbd_backlight/brightness"
    exit 1
fi

USER_GROUP="$(id -gn)"

echo "Compiling keyboard-backlight helper..."
gcc -O2 -Wall -Wextra -o "$HELPER_BUILD" "$HELPER_SOURCE"

echo "Installing helper..."
sudo install \
    -o root \
    -g "$USER_GROUP" \
    -m 4750 \
    "$HELPER_BUILD" \
    /usr/local/bin/kbdlight

echo "Installing systemd user service..."
mkdir -p "$HOME/.config/systemd/user"
install -m 0644 \
    "$SERVICE_SOURCE" \
    "$HOME/.config/systemd/user/kbdlight@.service"

systemctl --user daemon-reload

echo "Installing KWin script..."

if kpackagetool6 --type=KWin/Script --list |
    grep -q "$KWIN_PLUGIN_ID"; then
    kpackagetool6 \
        --type=KWin/Script \
        --upgrade "$PROJECT_DIR"
else
    kpackagetool6 \
        --type=KWin/Script \
        --install "$PROJECT_DIR"
fi

echo "Enabling KWin script..."
kwriteconfig6 \
    --file kwinrc \
    --group Plugins \
    --key "${KWIN_PLUGIN_ID}Enabled" \
    true

echo "Reloading KWin configuration..."
qdbus6 org.kde.KWin /KWin reconfigure

rm -f "$HELPER_BUILD"

echo
echo "Installation complete."
echo "Enter and leave fullscreen to test it."
echo "A logout and login may be required if it does not react immediately."
