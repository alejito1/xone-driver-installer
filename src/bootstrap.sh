#!/bin/bash
# Download the latest version of the script from the repository and run it
echo -e "\e[1mDownloading the latest version of the script...\e[0m"
echo ""
curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/xone_install_or_update.sh" >~/xone_install_or_update.sh || {
    echo "Failed to download xone_install_or_update.sh. Aborting..."
    read -n 1 -s -r -p "Press any key to exit"
    exit 1
}
curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/xone.desktop" >~/Desktop/xone.desktop || {
    echo "Failed to download xone.desktop. Aborting..."
    read -n 1 -s -r -p "Press any key to exit"
    exit 1
}
curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/xone_debug.desktop" >~/Desktop/xone_debug.desktop || {
    echo "Failed to download xone_debug.desktop. Aborting..."
    read -n 1 -s -r -p "Press any key to exit"
    exit 1
}
curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/enable-pairing.desktop" >~/Desktop/enable-pairing.desktop || {
    echo "Failed to download enable-pairing.desktop. Aborting..."
    read -n 1 -s -r -p "Press any key to exit"
    exit 1
}
curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/disable-pairing.desktop" >~/Desktop/disable-pairing.desktop || {
    echo "Failed to download disable-pairing.desktop. Aborting..."
    read -n 1 -s -r -p "Press any key to exit"
    exit 1
}
# Run the script
echo -e "\e[1mRunning the script...\e[0m"
echo ""
clear
chmod +x ~/xone_install_or_update.sh
exec bash ~/xone_install_or_update.sh
