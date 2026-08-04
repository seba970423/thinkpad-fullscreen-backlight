#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HELPER_SOURCE="$PROJECT_DIR/kbdlight.c"
HELPER_BUILD="$PROJECT_DIR/kbdlight"
SERVICE_SOURCE="$PROJECT_DIR/kbdlight@.service"
KWIN_PLUGIN_ID="thinkpad-fullscreen-backlight"
SYSFS_BRIGHTNESS="/sys/class/leds/tpacpi::kbd_backlight/brightness"

cleanup() {
    rm -f "$HELPER_BUILD"
}
trap cleanup EXIT

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}


prompt_logout() {
    local choice

    printf '\n'
    read -r -p "Log out now? [y/N]: " choice

    case "${choice,,}" in
        y|yes)
            printf '%s\n' "Logging out..."
            if ! qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout; then
                printf '%s\n' "Unable to log out automatically. Please log out manually." >&2
            fi
            ;;
        *)
            printf '%s\n' "Logout skipped."
            ;;
    esac
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

USER_GROUP="$(id -gn)"

printf '%s\n' "ThinkPad Fullscreen Backlight for KDE Plasma"
printf '\n%s\n' "This installer will:"
printf '%s\n' "  - compile and install the restricted keyboard-backlight helper"
printf '%s\n' "  - install the systemd user service"
printf '%s\n' "  - install and enable the KWin script"
printf '%s\n' "  - preserve Plasma's current keyboard-backlight state"
printf '\n'

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

printf '%s\n' "Enabling KWin script..."
kwriteconfig6 \
    --file kwinrc \
    --group Plugins \
    --key "${KWIN_PLUGIN_ID}Enabled" \
    true

printf '%s\n' "Reloading KWin configuration..."
qdbus6 org.kde.KWin /KWin reconfigure

printf '\nInstallation complete.\n'
printf '%s\n' "The keyboard backlight now follows Plasma's current state:"
printf '%s\n' "  - Off stays off after fullscreen"
printf '%s\n' "  - Level 1 restores to level 1"
printf '%s\n' "  - Level 2 restores to level 2"
printf '%s\n' "Enter and leave fullscreen to test it."
printf '%s\n' "A fresh Plasma session ensures the installed script is loaded."
prompt_logout
