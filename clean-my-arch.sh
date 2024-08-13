#!/usr/bin/env bash
# Title: Arch Linux Maintenance Tool
# Author: serjlc
# Dependencies: gum, pacman, yay, reflector

set -euo pipefail

# Constants
readonly CACHE_DIR="$HOME/.cache"
readonly CONFIG_DIR="$HOME/.config"
readonly JOURNAL_DIR="/var/log/journal"
readonly MIRRORLIST="/etc/pacman.d/mirrorlist"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run a command with sudo if necessary
run_with_sudo() {
    if [[ $EUID -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Function to display directory size
display_dir_size() {
    local dir=$1
    local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
    echo "Size of $dir: $size"
}

# Function to perform an action if confirmed
confirm_and_run() {
    local prompt=$1
    local cmd=$2
    if gum confirm "$prompt"; then
        eval "$cmd"
    fi
}

# Pacman Maintenance function
pacman_maintenance() {
    confirm_and_run "Check for system updates from main repository?" "run_with_sudo pacman -Syu"
    
    if gum confirm "Remove unused packages from the pacman cache?"; then
        run_with_sudo pacman -Sc
        
        # Handle unused repositories
        local unused_repos=$(pacman -Qqdt)
        if [ -n "$unused_repos" ]; then
            echo "Unused repositories found:"
            echo "$unused_repos"
            if gum confirm "Do you want to remove these unused repositories?"; then
                run_with_sudo pacman -Rns $unused_repos
            fi
        else
            echo "No unused repositories found."
        fi
    fi
        # Check for orphan packages
    local orphan_packages=$(pacman -Qtdq)
        if [ -n "$orphan_packages" ]; then
          echo "Orphan packages found:"
          echo "$orphan_packages"
          if gum confirm "Do you want to remove these orphan packages?"; then
              run_with_sudo pacman -Rns $orphan_packages
          fi
    else
        echo "No orphan packages found."
    fi

}


# Check dependencies
for dep in gum pacman yay reflector; do
    if ! command_exists "$dep"; then
        echo "Error: $dep is not installed. Please install it to continue."
        exit 1
    fi
done

# Startup banner
gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 50 --margin "1 2" --padding "2 4" \
    'Welcome to Clean My Arch!'

# General Maintenance
confirm_and_run "Display failed systemd services?" "systemctl --failed"
confirm_and_run "Display log files with priority level 3+?" "journalctl -p 3 -xb"
confirm_and_run "Display your .cache directory size?" "display_dir_size \"$CACHE_DIR\""
confirm_and_run "Display your .config directory size?" "display_dir_size \"$CONFIG_DIR\""
confirm_and_run "Display disk usage of journal directory?" "display_dir_size \"$JOURNAL_DIR\""

# Delete logs from journal
if gum confirm "Delete logs from journal?"; then
    vacuum_time=$(gum input --placeholder "Enter the vacuum-time (default is 2 weeks): ")
    vacuum_time=${vacuum_time:-2weeks}
    run_with_sudo journalctl --vacuum-time="$vacuum_time"
fi

# Update mirror list
if gum confirm "Update mirror list?"; then
    country=$(gum input --placeholder "Enter your country: ")
    run_with_sudo reflector -c "$country" -a 6 --sort rate --save "$MIRRORLIST"
fi

# Run Pacman Maintenance
pacman_maintenance

# Yay Maintenance
confirm_and_run "Check for system updates from AUR repository?" "yay -Syu"
confirm_and_run "Remove unused packages from the yay cache?" "yay -Sc"
confirm_and_run "Clean up all unwanted dependencies?" "yay -Yc"



echo "Maintenance completed successfully!"
