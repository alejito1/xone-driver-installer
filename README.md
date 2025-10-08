This is  a fork of SavageCore's xone-steam-deck-installer all rights and donations will go to his pages.

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/SavageCore/xone-steam-deck-installer/test.yml?style=for-the-badge&label=ShellCheck)
 ![GitHub Downloads (specific asset, all releases)](https://img.shields.io/github/downloads/SavageCore/xone-steam-deck-installer/xone_install_or_update.sh?style=for-the-badge)


# Donate

Enjoying this script? Consider buying me a beer/coffee!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/E1E6P7VIQ)

First time setting up your Deck? You may enjoy my [setup guide](https://gist.github.com/SavageCore/eeb8b6ba032c0865e5c2a9eb8e073ab5). It'll get you started on Emulation.

# Universal xone Driver installation script for 

A fork of [cdleveille's](https://gist.github.com/cdleveille/e84c235c6e8c17042d35a7c0d92cdc96) script. With additional features and improvements.

- Support for most linux distros
- Added zenity for a basic "GUI"
- Added sudo check
- Added various checks to prevent the script from redoing things that are already done
- Ensure the module is loaded after install and on boot
- Return `steamos-readonly` to its previous state after install
- Allow Xbox 360 controllers by installing [xpad-noone](https://github.com/forkymcforkface/xpad-noone) which removes Xbox One support from the standard Linux `xpad` driver and allows it to coexist with `xone`

# Installation ⬇️

1. Clone or download the repo's zip
2. You can clone and use the script with `wget -O /tmp/bootstrap.sh https://github.com/alejito1/xone-steam-deck-installer/releases/latest/download/bootstrap.sh && sh /tmp/bootstrap.sh` 
3. If something breaks try launching Konsole and chmod 777 the scripts (just for being sure everything works)
4. Install the driver

⚠️ If you have problems during install please read this [pinned issue](https://github.com/SavageCore/xone-steam-deck-installer/issues/1).

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
