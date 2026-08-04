#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HELPER_SOURCE="$PROJECT_DIR/kbdlight.c"
HELPER_BUILD="$PROJECT_DIR/kbdlight"
SERVICE_SOURCE="$PROJECT_DIR/kbdlight@.service"
KWIN_PLUGIN_ID="thinkpad-fullscreen-backlight"
KWIN_CONFIG_GROUP="Script-$KWIN_PLUGIN_ID"
SYSFS_BRIGHTNESS="/sys/class/leds/tpacpi::kbd_backlight/brightness"
SYSFS_MAX_BRIGHTNESS="/sys/class/leds/tpacpi::kbd_backlight/max_brightness"

cleanup() {
    rm -f "$HELPER_BUILD"
}
trap cleanup EXIT

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

if [[ $EUID -eq 0 ]]; then
    fail "Do not run the entire installer with sudo. Run it normally: ./install.sh"
fi

for command in gcc sudo install kpackagetool6 kwriteconfig6 qdbus6 systemctl grep; do
    command -v "$command" >/dev/null 2>&1 || fail "Missing required command: $command"
done

[[ -f "$HELPER_SOURCE" ]] || fail "Missing source file: $HELPER_SOURCE"
[[ -f "$SERVICE_SOURCE" ]] || fail "Missing service file: $SERVICE_SOURCE"
[[ -e "$SYSFS_BRIGHTNESS" ]] || fail "ThinkPad keyboard backlight interface not found: $SYSFS_BRIGHTNESS"

max_brightness=2
if [[ -r "$SYSFS_MAX_BRIGHTNESS" ]]; then
    read -r max_brightness < "$SYSFS_MAX_BRIGHTNESS"
fi

if (( max_brightness < 2 )); then
    fail "This keyboard reports a maximum brightness of $max_brightness; levels 1 and 2 are required."
fi

printf '%s\n' "Choose the keyboard backlight level to restore after leaving fullscreen:"
printf '%s\n' "  1) Low"
printf '%s\n' "  2) High (recommended)"

while true; do
    read -r -p "Brightness level [1-2, default 2]: " restore_brightness
    restore_brightness="${restore_brightness:-2}"

    case "$restore_brightness" in
        1|2) break ;;
        *) printf '%s\n' "Please enter 1 or 2." ;;
    esac
done

USER_GROUP="$(id -gn)"

printf '%s\n' "Compiling keyboard-backlight helper..."
gcc -O2 -Wall -Wextra -Wpedantic -o "$HELPER_BUILD" "$HELPER_SOURCE"

printf '%s\n' "Installing privileged helper..."
sudo install \
    -o root \
    -g "$USER_GROUP" \
    -m 4750 \
    "$HELPER_BUILD" \
    /usr/local/bin/kbdlight

printf '%s\n' "Installing systemd user service..."
mkdir -p "$HOME/.config/systemd/user"
install -m 0644 \
    "$SERVICE_SOURCE" \
    "$HOME/.config/systemd/user/kbdlight@.service"
systemctl --user daemon-reload

printf '%s\n' "Installing KWin script..."
if kpackagetool6 --type=KWin/Script --list | grep -Fq "$KWIN_PLUGIN_ID"; then
    kpackagetool6 --type=KWin/Script --upgrade "$PROJECT_DIR"
else
    kpackagetool6 --type=KWin/Script --install "$PROJECT_DIR"
fi

printf '%s\n' "Saving restore brightness level: $restore_brightness"
kwriteconfig6 \
    --file kwinrc \
    --group "$KWIN_CONFIG_GROUP" \
    --key RestoreBrightness \
    "$restore_brightness"

printf '%s\n' "Enabling KWin script..."
kwriteconfig6 \
    --file kwinrc \
    --group Plugins \
    --key "${KWIN_PLUGIN_ID}Enabled" \
    true

printf '%s\n' "Reloading KWin configuration..."
qdbus6 org.kde.KWin /KWin reconfigure

printf '\nInstallation complete.\n'
printf 'The keyboard backlight will restore to level %s after fullscreen.\n' "$restore_brightness"
printf '%s\n' "Enter and leave fullscreen to test it."
printf '%s\n' "A logout and login may be required if it does not react immediately."
