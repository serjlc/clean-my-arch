# Clean My Arch

A simple maintenance script for my Arch Linux.

## What it does

- Updates system packages (pacman and AUR)
- Cleans package caches
- Removes orphaned packages
- Updates mirror list
- Manages system logs
- Analyzes disk usage
- Creates system backups

## Requirements

- `gum`
- `pacman`
- `yay`
- `reflector`
- `rsync` (for backups)
- `ncdu` (will be installed if not present)

## How to use

1. Make sure you have the required tools installed.
2. Download the script.
3. Make it executable:
   ```bash
   chmod +x clean_my_arch.sh
4. Run the script:
   ``` bash
   ./clean_my_arch.sh
