#!/usr/bin/env bash

set -euo pipefail

KWIN_PLUGIN_ID="thinkpad-fullscreen-backlight"
SERVICE_FILE="$HOME/.config/systemd/user/kbdlight@.service"
HELPER_FILE="/usr/local/bin/kbdlight"
STATE_FILE="/run/user/$(id -u)/thinkpad-fullscreen-backlight.state"

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
    fail "Do not run the entire uninstaller with sudo. Run it normally: ./uninstall.sh"
fi

for command in sudo kpackagetool6 kwriteconfig6 systemctl; do
    command -v "$command" >/dev/null 2>&1 || fail "Missing required command: $command"
done

printf '%s\n' "Disabling KWin script..."
kwriteconfig6 \
    --file kwinrc \
    --group Plugins \
    --key "${KWIN_PLUGIN_ID}Enabled" \
    false

printf '%s\n' "Removing KWin script..."
kpackagetool6 \
    --type=KWin/Script \
    --remove "$KWIN_PLUGIN_ID" \
    >/dev/null 2>&1 || true

printf '%s\n' "Removing systemd user service..."
rm -f "$SERVICE_FILE"
systemctl --user daemon-reload
systemctl --user reset-failed >/dev/null 2>&1 || true

rm -f "$STATE_FILE"

if [[ -e "$HELPER_FILE" ]]; then
    printf '%s\n' "Removing privileged helper..."
    sudo rm -f "$HELPER_FILE"
else
    printf '%s\n' "Privileged helper is already absent."
fi

if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

printf '\n%s\n' "Uninstallation complete."
prompt_logout
