#!/usr/bin/env bash

set -euo pipefail

KWIN_PLUGIN_ID="thinkpad-fullscreen-backlight"

if [[ $EUID -eq 0 ]]; then
    echo "Do not run the entire uninstaller with sudo."
    echo "Run it normally: ./uninstall.sh"
    exit 1
fi

echo "Disabling KWin script..."
kwriteconfig6 \
    --file kwinrc \
    --group Plugins \
    --key "${KWIN_PLUGIN_ID}Enabled" \
    false

echo "Removing KWin script..."
kpackagetool6 \
    --type=KWin/Script \
    --remove "$KWIN_PLUGIN_ID" 2>/dev/null || true

echo "Removing systemd user service..."
rm -f "$HOME/.config/systemd/user/kbdlight@.service"
systemctl --user daemon-reload

echo "Removing privileged helper..."
sudo rm -f /usr/local/bin/kbdlight

qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo
echo "Uninstallation complete."
