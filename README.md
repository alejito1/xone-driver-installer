# ⚠️ Semi deprecated

Unless you need Xbox 360 controller support then it's superseded by the driver's own [install script](https://github.com/dlundqvist/xone#steam-decksteamos)

# Donate

Enjoying this script? Consider buying me a beer/coffee!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/E1E6P7VIQ)

First time setting up your Deck? You may enjoy my [setup guide](https://gist.github.com/SavageCore/eeb8b6ba032c0865e5c2a9eb8e073ab5). It'll get you started on Emulation.

# Improvements 💪

Main changes at initial release versus [cdleveille's](https://gist.github.com/cdleveille/e84c235c6e8c17042d35a7c0d92cdc96) original script:
- Added zenity for a basic "GUI"
- Added sudo check
- Added various checks to prevent the script from redoing things that are already done
- Ensure the module is loaded after install and on boot
- Return `steamos-readonly` to its previous state after install

# Installation ⬇️

1. Switch to [Desktop mode](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C)
2. Launch Konsole
3. Run `wget -O /tmp/bootstrap.sh https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/bootstrap.sh && sh /tmp/bootstrap.sh`

⚠️ If you have problems during install please read this [pinned issue](https://github.com/SavageCore/xone-steam-deck-installer/issues/1).

## Pairing 👫

You can enable and disable pairing mode from the included Desktop shortcuts, saving you from getting up and pressing that button!

After installation you may need to restart your Deck to get things working. Failing that try shutting down and waiting a minute before starting up again. Using the Desktop shortcut or command to enable pairing can also get things working.

`echo 0 | sudo tee /sys/bus/usb/drivers/xone-dongle/*/pairing`

# Updating 🔄

1. Switch to [Desktop mode](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C)
2. Click the Install/Update Xone icon on your desktop

# Uninstalling ❌

1. Switch to [Desktop mode](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C)
2. Launch Konsole
3. Run `wget -O /tmp/xone_uninstall.sh https://github.com/SavageCore/xone-steam-deck-installer/raw/refs/heads/main/src/xone_uninstall.sh && sh /tmp/xone_uninstall.sh`

# Troubleshooting 🛠️

1. Switch to [Desktop mode](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C)
2. Click the Install/Update Xone (DEBUG) icon on your desktop
3. Please search for an existing [issue](https://github.com/SavageCore/xone-steam-deck-installer/issues) then post a [new](https://github.com/SavageCore/xone-steam-deck-installer/issues/new) one if you can't find it! You can also pop by my [Discord](https://discord.gg/MxMFhsKrZd) and leave a message in #xone-install-script
4. This script was originally a [Gist](https://gist.github.com/SavageCore/263a3413532bc181c9bb215c8fe6c30d) so you may find some useful information in the comments there too.
