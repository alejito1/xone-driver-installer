#!/bin/bash
# xone install or update script - Multi-Distribution Support
# Refactored version with improved error handling and cross-distro compatibility
# Original by SavageCore, forked from cdleveille's original script
#
# https://github.com/SavageCore/xone-steam-deck-installer
# Script version 0.13.0

set -o pipefail

# Configuration
XONE_LOCAL_REPO="$HOME/repos/xone"
XPAD_NOONE_LOCAL_REPO="$HOME/repos/xpad-noone"
XONE_REMOTE_REPO="https://github.com/dlundqvist/xone"
XPAD_NOONE_REMOTE_REPO="https://github.com/forkymcforkface/xpad-noone"
XPAD_NOONE_VERSION="1.0"
SCRIPT_VERSION="0.13.0"

# Runtime variables
KEEP_READ_ONLY="false"
DEBUG="false"
CURRENT_USER=$(whoami)
DISTRO=""
PACKAGE_MANAGER=""
IS_STEAMOS="false"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG="true"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "\e[1m$1\e[0m"
}

log_error() {
    echo -e "\e[1;31mERROR: $1\e[0m" >&2
}

log_warning() {
    echo -e "\e[1;33mWARNING: $1\e[0m"
}

log_debug() {
    if [[ $DEBUG == "true" ]]; then
        echo -e "\e[0;36mDEBUG: $1\e[0m"
    fi
}

# Error handler
error_exit() {
    log_error "$1"
    read -n 1 -s -r -p "Press any key to exit"
    exit 1
}

# Compare semantic versions
compare_semver() {
    local ver1_major ver1_minor ver1_patch
    local ver2_major ver2_minor ver2_patch
    
    ver1_major=$(echo "$1" | cut -d '.' -f 1)
    ver1_minor=$(echo "$1" | cut -d '.' -f 2)
    ver1_patch=$(echo "$1" | cut -d '.' -f 3)
    
    ver2_major=$(echo "$2" | cut -d '.' -f 1)
    ver2_minor=$(echo "$2" | cut -d '.' -f 2)
    ver2_patch=$(echo "$2" | cut -d '.' -f 3)
    
    if [ "$ver1_major" -gt "$ver2_major" ]; then echo "1"; return; fi
    if [ "$ver1_major" -lt "$ver2_major" ]; then echo "-1"; return; fi
    if [ "$ver1_minor" -gt "$ver2_minor" ]; then echo "1"; return; fi
    if [ "$ver1_minor" -lt "$ver2_minor" ]; then echo "-1"; return; fi
    if [ "$ver1_patch" -gt "$ver2_patch" ]; then echo "1"; return; fi
    if [ "$ver1_patch" -lt "$ver2_patch" ]; then echo "-1"; return; fi
    
    echo "0"
}

# Detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
        
        # Check if SteamOS
        if [[ "$ID" == "steamos" ]] || [[ "$NAME" =~ "SteamOS" ]]; then
            IS_STEAMOS="true"
            DISTRO="steamos"
        fi
        
        log_debug "Detected distribution: $DISTRO"
    else
        log_warning "Could not detect distribution, assuming generic Linux"
        DISTRO="unknown"
    fi
}

# Detect package manager with priority
detect_package_manager() {
    # For SteamOS, always use pacman
    if [[ "$IS_STEAMOS" == "true" ]]; then
        if command -v pacman &>/dev/null; then
            PACKAGE_MANAGER="pacman"
            log_debug "Using pacman (SteamOS detected)"
            return 0
        else
            error_exit "SteamOS detected but pacman not found"
        fi
    fi
    
    # Priority-based detection for other distros
    if command -v pacman &>/dev/null && [[ "$DISTRO" =~ ^(arch|manjaro|endeavouros)$ ]]; then
        PACKAGE_MANAGER="pacman"
    elif command -v apt &>/dev/null && [[ "$DISTRO" =~ ^(ubuntu|debian|linuxmint|pop)$ ]]; then
        PACKAGE_MANAGER="apt"
    elif command -v dnf &>/dev/null && [[ "$DISTRO" =~ ^(fedora|rhel|centos)$ ]]; then
        PACKAGE_MANAGER="dnf"
    elif command -v zypper &>/dev/null && [[ "$DISTRO" =~ ^(opensuse|sles)$ ]]; then
        PACKAGE_MANAGER="zypper"
    elif command -v apk &>/dev/null && [[ "$DISTRO" == "alpine" ]]; then
        PACKAGE_MANAGER="apk"
    elif command -v brew &>/dev/null; then
        PACKAGE_MANAGER="brew"
    else
        error_exit "No supported package manager found"
    fi
    
    log_debug "Using package manager: $PACKAGE_MANAGER"
}

# Get package name for current distro
get_package_name() {
    local generic_name="$1"
    
    case "$PACKAGE_MANAGER" in
        apt)
            case "$generic_name" in
                gcc) echo "build-essential" ;;
                libisl) echo "libisl23" ;;
                libmpc) echo "libmpc3" ;;
                cabextract) echo "cabextract" ;;
                dkms) echo "dkms" ;;
                plymouth) echo "plymouth" ;;
                *) echo "$generic_name" ;;
            esac
            ;;
        dnf|yum)
            case "$generic_name" in
                gcc) echo "gcc make kernel-devel" ;;
                libisl) echo "isl" ;;
                libmpc) echo "libmpc" ;;
                *) echo "$generic_name" ;;
            esac
            ;;
        *)
            echo "$generic_name"
            ;;
    esac
}

# Check if package is installed
is_package_installed() {
    local package="$1"
    
    case "$PACKAGE_MANAGER" in
        pacman)
            pacman -Qs "^$package$" &>/dev/null
            ;;
        apt)
            dpkg -s "$package" &>/dev/null 2>&1
            ;;
        dnf|yum)
            rpm -q "$package" &>/dev/null 2>&1
            ;;
        zypper)
            rpm -q "$package" &>/dev/null 2>&1
            ;;
        apk)
            apk info -e "$package" &>/dev/null 2>&1
            ;;
        brew)
            brew list --formula | grep -qw "^$package\$"
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if package has updates available
has_package_update() {
    local package="$1"
    
    case "$PACKAGE_MANAGER" in
        pacman)
            pacman -Qu 2>/dev/null | grep -qw "$package"
            ;;
        apt)
            apt list --upgradable 2>/dev/null | grep -q "^$package/"
            ;;
        dnf|yum)
            $PACKAGE_MANAGER check-update "$package" &>/dev/null
            [ $? -eq 100 ]
            ;;
        zypper)
            zypper list-updates 2>/dev/null | grep -qw "$package"
            ;;
        apk)
            apk version "$package" 2>/dev/null | grep -q '<'
            ;;
        brew)
            brew outdated | grep -qw "^$package\$"
            ;;
        *)
            return 1
            ;;
    esac
}

# Install a package
install_package() {
    local package="$1"
    local actual_package=$(get_package_name "$package")
    
    log_debug "Installing $actual_package"
    
    case "$PACKAGE_MANAGER" in
        pacman)
            sudo pacman -S --noconfirm $actual_package
            ;;
        apt)
            sudo apt install -y $actual_package
            ;;
        dnf)
            sudo dnf install -y $actual_package
            ;;
        yum)
            sudo yum install -y $actual_package
            ;;
        zypper)
            sudo zypper install -y $actual_package
            ;;
        apk)
            sudo apk add --no-cache $actual_package
            ;;
        brew)
            brew install $actual_package
            ;;
        *)
            return 1
            ;;
    esac
}

# Update a package
update_package() {
    local package="$1"
    local actual_package=$(get_package_name "$package")
    
    log_debug "Updating $actual_package"
    
    case "$PACKAGE_MANAGER" in
        pacman)
            sudo pacman -S --noconfirm $actual_package
            ;;
        apt)
            sudo apt install --only-upgrade -y $actual_package
            ;;
        dnf)
            sudo dnf upgrade -y $actual_package
            ;;
        yum)
            sudo yum update -y $actual_package
            ;;
        zypper)
            sudo zypper update -y $actual_package
            ;;
        apk)
            sudo apk upgrade $actual_package
            ;;
        brew)
            brew upgrade $actual_package
            ;;
        *)
            return 1
            ;;
    esac
}

# Install required packages
install_required_packages() {
    local packages=("curl" "wget" "git" "gcc" "cabextract" "dkms")
    local packages_to_install=()
    local packages_to_update=()
    
    # Add distro-specific packages
    case "$PACKAGE_MANAGER" in
        pacman)
            packages+=("libisl" "libmpc" "plymouth")
            ;;
        apt)
            packages+=("linux-headers-$(uname -r)")
            ;;
        dnf|yum)
            packages+=("kernel-devel" "kernel-headers")
            ;;
    esac
    
    log_info "Checking required packages..."
    echo ""
    
    for package in "${packages[@]}"; do
        if is_package_installed "$package"; then
            if has_package_update "$package"; then
                packages_to_update+=("$package")
            fi
        else
            packages_to_install+=("$package")
        fi
    done
    
    # Install missing packages
    if [ ${#packages_to_install[@]} -ne 0 ]; then
        log_info "Installing required packages..."
        echo ""
        log_debug "Packages to install: ${packages_to_install[*]}"
        
        for package in "${packages_to_install[@]}"; do
            if ! install_package "$package"; then
                log_error "Failed to install $package"
            fi
        done
    fi
    
    # Update packages
    if [ ${#packages_to_update[@]} -ne 0 ]; then
        log_info "Updating required packages..."
        echo ""
        log_debug "Packages to update: ${packages_to_update[*]}"
        
        for package in "${packages_to_update[@]}"; do
            if ! update_package "$package"; then
                log_error "Failed to update $package"
            fi
        done
    fi
    
    if [ ${#packages_to_install[@]} -eq 0 ] && [ ${#packages_to_update[@]} -eq 0 ]; then
        log_info "All required packages are already installed and up to date."
    else
        log_info "Required packages installed and updated successfully."
    fi
    echo ""
}

# Install Linux headers (SteamOS specific)
install_linux_headers_steamos() {
    if [[ "$IS_STEAMOS" != "true" ]]; then
        return 0
    fi
    
    log_info "Checking for linux headers..."
    echo ""
    
    local linux=$(pacman -Qsq linux-neptune | grep -e "[0-9]$" | tail -n 1)
    local kernel_headers="$linux-headers"
    
    log_debug "Using $kernel_headers package"
    
    if pacman -Qs "$kernel_headers" &>/dev/null && ! pacman -Qu "$kernel_headers" &>/dev/null; then
        log_debug "Headers are already installed and up to date"
        return 0
    fi
    
    log_info "Installing required kernel headers, this may take a while..."
    echo ""
    sudo pacman -Sy "$kernel_headers" --noconfirm >/dev/null || error_exit "Failed to install kernel headers"
}

# Setup SteamOS specific environment
setup_steamos_environment() {
    if [[ "$IS_STEAMOS" != "true" ]]; then
        return 0
    fi
    
    # Rename fakeroot.conf to avoid error
    if [ -f /etc/ld.so.conf.d/fakeroot.conf ]; then
        sudo mv /etc/ld.so.conf.d/fakeroot.conf /etc/ld.so.conf.d/fakeroot.conf.bck
    fi
    
    # Disable read-only mode if enabled
    if [ "$(sudo steamos-readonly status)" == "enabled" ]; then
        sudo steamos-readonly disable
        KEEP_READ_ONLY="true"
    fi
    
    # Initialize pacman-key if needed
    if ! pacman-key --list-keys >/dev/null 2>&1; then
        log_info "Initialising pacman..."
        echo ""
        sudo pacman-key --init
    fi
    
    log_debug "Refreshing pacman keys..."
    sudo pacman-key --populate archlinux holo >/dev/null 2>&1
}

# Restore SteamOS environment
restore_steamos_environment() {
    if [[ "$IS_STEAMOS" != "true" ]]; then
        return 0
    fi
    
    if [ "$KEEP_READ_ONLY" = "true" ]; then
        sudo steamos-readonly enable
    fi
}

# Clone or update git repository
clone_or_update_repo() {
    local repo_url="$1"
    local local_path="$2"
    local repo_name="$3"
    
    if [ -d "$local_path" ]; then
        cd "$local_path" || error_exit "Failed to cd into $repo_name repo"
        
        # Check remote URL
        local current_remote=$(git remote get-url origin)
        if [[ "$current_remote" != "$repo_url" ]]; then
            log_warning "Incorrect fork detected for $repo_name"
            echo "  Current:  $current_remote"
            echo "  Expected: $repo_url"
            echo ""
            log_info "Deleting and re-cloning correct fork..."
            echo ""
            
            cd "$HOME/repos" || error_exit "Failed to cd into $HOME/repos"
            rm -rf "$local_path"
            
            log_info "Cloning correct $repo_name fork..."
            echo ""
            git clone "$repo_url" "$local_path" || error_exit "Failed to clone $repo_name"
            cd "$local_path" || error_exit "Failed to cd into newly cloned repo"
            return 1  # Indicates reinstall needed
        fi
        
        # Check for updates
        log_info "Checking for $repo_name updates..."
        echo ""
        git reset --hard >/dev/null 2>&1
        local git_output=$(git pull)
        
        if [[ $git_output != *"Already up to date."* ]]; then
            echo "Updates found"
            return 1  # Indicates reinstall needed
        else
            echo "No updates available"
            return 0
        fi
    else
        # Clone new repo
        mkdir -p "$HOME/repos"
        log_info "Cloning $repo_name repo..."
        echo ""
        git clone "$repo_url" "$local_path" || error_exit "Failed to clone $repo_name"
        cd "$local_path" || error_exit "Failed to cd into $repo_name repo"
        return 1  # Indicates install needed
    fi
}

# Install xone
install_xone() {
    if [ -n "$(dkms status xone)" ]; then
        log_debug "xone is already installed"
        return 0
    fi
    
    cd "$XONE_LOCAL_REPO" || error_exit "Failed to cd into xone repo"
    
    log_info "Installing xone..."
    echo ""
    
    if [[ $DEBUG == "true" ]]; then
        sudo ./install.sh --release
        log_info "Getting xone firmware..."
        echo ""
        sudo install/firmware.sh --skip-disclaimer
    else
        sudo ./install.sh --release >/dev/null 2>&1
        log_info "Getting xone firmware..."
        echo ""
        sudo install/firmware.sh --skip-disclaimer >/dev/null 2>&1
    fi
}

# Uninstall xone
uninstall_xone() {
    cd "$XONE_LOCAL_REPO" || error_exit "Failed to cd into xone repo"
    
    if [[ $DEBUG == "true" ]]; then
        sudo ./uninstall.sh
    else
        sudo ./uninstall.sh >/dev/null 2>&1
    fi
}

# Install xpad-noone
install_xpad_noone() {
    if [ -n "$(dkms status xpad-noone)" ]; then
        log_debug "xpad-noone is already installed"
        return 0
    fi
    
    log_info "Installing xpad-noone..."
    echo ""
    
    sudo modprobe -r xpad-noone 2>/dev/null || true
    
    if [[ $DEBUG == "true" ]]; then
        sudo cp -r "$XPAD_NOONE_LOCAL_REPO" "/usr/src/xpad-noone-$XPAD_NOONE_VERSION"
        sudo dkms install -m xpad-noone -v "$XPAD_NOONE_VERSION"
    else
        sudo cp -r "$XPAD_NOONE_LOCAL_REPO" "/usr/src/xpad-noone-$XPAD_NOONE_VERSION" >/dev/null 2>&1
        sudo dkms install -m xpad-noone -v "$XPAD_NOONE_VERSION" >/dev/null 2>&1
    fi
}

# Uninstall xpad-noone
uninstall_xpad_noone() {
    if [ -n "$(dkms status xpad-noone)" ]; then
        if [[ $DEBUG == "true" ]]; then
            sudo dkms remove -m xpad-noone -v "$XPAD_NOONE_VERSION" --all
        else
            sudo dkms remove -m xpad-noone -v "$XPAD_NOONE_VERSION" --all >/dev/null 2>&1
        fi
        sudo rm -rf "/usr/src/xpad-noone-$XPAD_NOONE_VERSION"
    fi
}

# Load kernel module
load_kernel_module() {
    local module="$1"
    local conf_file="$2"
    
    if ! lsmod | grep -q "$module"; then
        log_debug "Loading $module module"
        
        if [[ $DEBUG == "true" ]]; then
            sudo modprobe "$module" || error_exit "Failed to load $module module"
        else
            sudo modprobe -q "$module" || error_exit "Failed to load $module module"
        fi
        
        sudo touch "/etc/modules-load.d/$conf_file"
        echo "$module" | sudo tee "/etc/modules-load.d/$conf_file" >/dev/null 2>&1
    fi
}

# Install pairing shortcuts (SteamOS only)
install_pairing_shortcuts() {
    if [[ "$IS_STEAMOS" != "true" ]]; then
        return 0
    fi
    
    if [ -f ~/Desktop/enable-pairing.desktop ] && [ -f ~/Desktop/disable-pairing.desktop ]; then
        log_debug "Pairing shortcuts already installed"
        return 0
    fi
    
    curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/enable-pairing.desktop" >~/Desktop/enable-pairing.desktop 2>/dev/null || {
        log_warning "Failed to download enable-pairing.desktop"
    }
    
    curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/disable-pairing.desktop" >~/Desktop/disable-pairing.desktop 2>/dev/null || {
        log_warning "Failed to download disable-pairing.desktop"
    }
}

# Check for script updates
check_script_updates() {
    local required_version=$(curl -sSfL "https://api.github.com/repos/SavageCore/xone-steam-deck-installer/releases/latest" 2>/dev/null | grep -Po '"tag_name": *"\K.*?(?=")' | sed 's/^v//')
    
    if [[ -z "$required_version" ]]; then
        log_debug "Could not check for script updates"
        return 0
    fi
    
    local version_diff=$(compare_semver "$SCRIPT_VERSION" "$required_version")
    
    if [[ $version_diff == -1 ]]; then
        log_info "Script update available. Updating..."
        echo ""
        
        curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/xone_install_or_update.sh" >/tmp/xone_install_or_update.sh || {
            log_error "Failed to download script update"
            return 1
        }
        
        local pwd=$(pwd)
        local args=("$@")
        
        mv /tmp/xone_install_or_update.sh "$0"
        chmod +x "$0"
        
        read -n 1 -s -r -p "Press any key to relaunch the script..."
        clear
        
        cd "$pwd" || error_exit "Failed to change directory"
        exec bash "$0" "${args[@]}"
    fi
}

# Check sudo access
check_sudo_access() {
    # Check if sudo password is set
    if [ "$(passwd -S "$CURRENT_USER" 2>/dev/null | cut -d" " -f2)" != "P" ]; then
        if command -v zenity &>/dev/null; then
            log_info "A sudo password is required"
            local password=$(zenity --password --title="Password")
            local confirm=$(zenity --password --title="Confirm password")
            
            if [ "$password" != "$confirm" ]; then
                zenity --error --text="Passwords do not match\n\nExiting..." --title="Error"
                exit 1
            fi
            
            {
                echo -e "$password\n$password" | passwd
                echo -e "$password" | sudo -S echo "" >/dev/null 2>&1
            } &>/dev/null
        else
            log_info "Please set a sudo password"
            passwd
        fi
    fi
    
    # Verify sudo access
    if ! sudo -n true 2>/dev/null; then
        if command -v zenity &>/dev/null; then
            zenity --password --title="Sudo password" | sudo -S echo "" >/dev/null 2>&1 || {
                zenity --error --text="Sudo privileges required" --title="Error"
                exit 1
            }
        else
            sudo -v || error_exit "Sudo privileges required"
        fi
    fi
}

# Main installation process
main() {
    log_info "xone install script by SavageCore"
    log_info "Version: $SCRIPT_VERSION"
    log_info "https://github.com/SavageCore/xone-steam-deck-installer/"
    echo "─────────────────────────────────"
    echo ""
    echo "This script will install the xone and xpad-noone drivers"
    echo "for the Xbox wireless dongle and controller"
    echo ""
    
    # Detect system
    detect_distro
    detect_package_manager
    
    # Check for updates
    check_script_updates "$@"
    
    # Verify sudo access
    check_sudo_access
    
    # Setup environment
    setup_steamos_environment
    
    # Install prerequisites
    if [[ "$IS_STEAMOS" == "true" ]]; then
        install_linux_headers_steamos
    fi
    
    install_required_packages
    
    # Clone/update repositories
    local xone_needs_install=false
    local xpad_needs_install=false
    
    clone_or_update_repo "$XONE_REMOTE_REPO" "$XONE_LOCAL_REPO" "xone"
    xone_needs_install=$?
    
    clone_or_update_repo "$XPAD_NOONE_REMOTE_REPO" "$XPAD_NOONE_LOCAL_REPO" "xpad-noone"
    xpad_needs_install=$?
    
    # Reinstall if needed
    if [[ $xone_needs_install -eq 1 ]]; then
        uninstall_xone
    fi
    
    if [[ $xpad_needs_install -eq 1 ]]; then
        uninstall_xpad_noone
    fi
    
    # Debug mode: force reinstall
    if [[ $DEBUG == "true" ]]; then
        echo ""
        log_debug "Debug mode: forcing reinstall"
        echo ""
        uninstall_xone
        uninstall_xpad_noone
    fi
    
    # Install drivers
    install_xone
    install_xpad_noone
    
    # Load kernel modules
    load_kernel_module "xone_dongle" "xone-dongle.conf"
    load_kernel_module "xpad_noone" "xpad-noone.conf"
    
    # Remove conflicting config
    if [ -f /etc/modules-load.d/xpad.conf ]; then
        sudo rm /etc/modules-load.d/xpad.conf
    fi
    
    # Restore environment
    restore_steamos_environment
    
    # Install shortcuts
    install_pairing_shortcuts
    
    # Success message
    if command -v zenity &>/dev/null; then
        zenity --info --text="Done. You may now plug in your controller/adapter."
    else
        echo ""
        log_info "Installation complete!"
        echo "You may now plug in your controller/adapter."
    fi
    
    if [[ $DEBUG == "true" ]]; then
        read -n 1 -s -r -p "Press any key to exit"
    fi
}

# Run main function
main "$@"