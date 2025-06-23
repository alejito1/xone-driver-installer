#!/bin/bash
# Uninstall script for xone Steam Deck installer

REPO_BASE_PATH="/home/deck/repos"
XONE_LOCAL_REPO="$REPO_BASE_PATH/xone"
XPAD_NOONE_LOCAL_REPO="$REPO_BASE_PATH/xpad-noone"
XPAD_NOONE_VERSION="1.0"

KEEP_READ_ONLY="false"
REDIRECT=">/dev/null 2>&1"
SHORTCUTS_REMOVED="false"

uninstall_xone() {
    cd "$XONE_LOCAL_REPO" 2>/dev/null || {
        return
    }

    # Run the xone uninstall script
    eval sudo ./uninstall.sh "$REDIRECT"
    echo -e "\e[1mUninstalled xone\e[0m"
}


uninstall_xpad_noone() {
    modules=$(lsmod | grep '^xpad_noone' | cut -d ' ' -f 1 | tr '\n' ' ')
    version=$XPAD_NOONE_VERSION

    if [ -n "$modules" ]; then
        # shellcheck disable=SC2086
        eval sudo modprobe -r -a $modules "$REDIRECT"
    fi

    if [ -n "$version" ]; then
        eval sudo dkms remove -m xpad-noone -v "$version" --all "$REDIRECT"
        sudo rm -rf "/usr/src/xpad-noone-$version"
    fi

    echo -e "\e[1mUninstalled xpad-noone\e[0m"
}

if [ -z "$KONSOLE_DBUS_SESSION" ] && [ -x "$(command -v konsole)" ]; then
    exec konsole -e "$0" "$@"
fi

# Check if the user has sudo privileges
# If not, prompt the user for a password
if ! sudo -n true 2>/dev/null; then
    if ! zenity --password --title="Sudo password" | eval sudo -S echo "" "$REDIRECT"; then
        zenity --error --text="Sorry, you need to have sudo privileges to run this script." --title="Error"
        exit 1
    fi
fi

# If output of `sudo steamos-readonly status` is "enabled", disable it
if [ "$(sudo steamos-readonly status)" == "enabled" ]; then
    sudo steamos-readonly disable
    KEEP_READ_ONLY="true"
fi

# Clear the terminal screen
clear

echo -e "\e[1mxone uninstall script by SavageCore\e[0m"
echo -e "\e[1mhttps://github.com/SavageCore/xone-steam-deck-installer/\e[0m"
echo "─────────────────────────────"
echo ""
echo "This script will uninstall the drivers and remove all related files."
echo ""

# Remove the xone_install_or_update.sh script
if [ -f ~/xone_install_or_update.sh ]; then
    rm ~/xone_install_or_update.sh
    echo -e "\e[1mRemoved xone_install_or_update.sh script\e[0m"
fi

# Remove the desktop files
if [ -f ~/Desktop/xone.desktop ]; then
    rm ~/Desktop/xone.desktop
    SHORTCUTS_REMOVED="true"
fi

if [ -f ~/Desktop/xone_debug.desktop ]; then
    rm ~/Desktop/xone_debug.desktop
    SHORTCUTS_REMOVED="true"
fi

if [ -f ~/Desktop/enable-pairing.desktop ]; then
    rm ~/Desktop/enable-pairing.desktop
    SHORTCUTS_REMOVED="true"
fi

if [ -f ~/Desktop/disable-pairing.desktop ]; then
    rm ~/Desktop/disable-pairing.desktop
    SHORTCUTS_REMOVED="true"
fi

if [ "$SHORTCUTS_REMOVED" = "true" ]; then
    echo -e "\e[1mRemoved desktop files\e[0m"
fi

# Uninstall xone
uninstall_xone

# Uninstall xpad-noone
uninstall_xpad_noone

# Clean up the local repositories
if [ -d "$XONE_LOCAL_REPO" ]; then
    rm -rf "$XONE_LOCAL_REPO"
    echo -e "\e[1mRemoved xone local repository\e[0m"
fi

if [ -d "$XPAD_NOONE_LOCAL_REPO" ]; then
    rm -rf "$XPAD_NOONE_LOCAL_REPO"
    echo -e "\e[1mRemoved xpad-noone local repository\e[0m"
fi

# If REPO_BASE_PATH exists and is empty, remove it
if [ -d "$REPO_BASE_PATH" ]; then
    if [ -z "$(ls -A "$REPO_BASE_PATH")" ]; then
        rmdir "$REPO_BASE_PATH"
        echo -e "\e[1m$REPO_BASE_PATH is now empty, removed\e[0m"
    fi
fi

# Remove /etc/modules-load.d/xone-dongle.conf
if [ -f /etc/modules-load.d/xone-dongle.conf ]; then
    sudo rm /etc/modules-load.d/xone-dongle.conf
    echo -e "\e[1mRemoved /etc/modules-load.d/xone-dongle.conf\e[0m"
fi

# Remove /etc/modules-load.d/xpad-noone.conf
if [ -f /etc/modules-load.d/xpad-noone.conf ]; then
    sudo rm /etc/modules-load.d/xpad-noone.conf
    echo -e "\e[1mRemoved /etc/modules-load.d/xpad-noone.conf\e[0m"
fi

# Re enable steamos-readonly if it was enabled before
if [ $KEEP_READ_ONLY = "true" ]; then
    sudo steamos-readonly enable
fi

# Remove the uninstall script itself
if [ -f ~/xone_uninstall.sh ]; then
    rm ~/xone_uninstall.sh
    echo -e "\e[1mRemoved xone_uninstall.sh script\e[0m"
fi

zenity --info \
    --text="Done.\n\nThe xone Steam Deck installer has been uninstalled successfully" \
    --title="Uninstall complete" \
