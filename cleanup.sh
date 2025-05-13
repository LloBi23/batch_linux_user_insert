#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIG ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="$SCRIPT_DIR/users.csv"
BACKUP_DIR="$SCRIPT_DIR/backups"
LOG_FILE="$SCRIPT_DIR/cleanup.log"

# Command line options
BATCH_MODE=0
ASSUME_YES=0
SHOW_HELP=0

# Improved argument handling
usage() {
    echo "Usage: $0 [-b] [-y] [-h]"
    echo "  -b  Batch mode (list only, no deletions)"
    echo "  -y  Assume yes (auto-confirm deletions)"
    echo "  -h  Show this help message"
}

while getopts "byh" opt; do
    case $opt in
        b) BATCH_MODE=1 ;;
        y) ASSUME_YES=1 ;;
        h) SHOW_HELP=1 ;;
        *) usage; exit 1 ;;
    esac
done

if [ $SHOW_HELP -eq 1 ]; then
    usage
    exit 0
fi

# Setup logging with timestamp
exec 1> >(tee -a "$LOG_FILE") 2>&1
echo "=== Cleanup started at $(date) ==="

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup current user data
echo "Creating system backup..."
sudo cp /etc/passwd "$BACKUP_DIR/passwd.$(date +%Y%m%d_%H%M%S)"
sudo cp /etc/shadow "$BACKUP_DIR/shadow.$(date +%Y%m%d_%H%M%S)"

# Get valid usernames from CSV
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: users.csv not found in $SCRIPT_DIR" >&2
    exit 1
fi

# Extract valid usernames from CSV (skip header)
valid_users=$(tail -n +2 "$CSV_FILE" | cut -d';' -f2)

# Store users in array for consistent counting
mapfile -t UNWANTED_USERS < <(
    while IFS=: read -r username _ uid _ _ home_dir _; do
        if [ "$uid" -ge 1000 ] && [ "$uid" -lt 60000 ]; then
            if [[ ! " $valid_users " =~ " $username " ]]; then
                echo "$username:$uid:$home_dir"
            fi
        fi
    done < /etc/passwd
)

# Show total count
echo "Found ${#UNWANTED_USERS[@]} potentially unwanted users"

# Process users
for user_info in "${UNWANTED_USERS[@]}"; do
    IFS=: read -r username uid home_dir <<< "$user_info"
    echo "Found potential unwanted user: $username"
    echo "  Home directory: $home_dir"
    echo "  UID: $uid"
    
    if [ $BATCH_MODE -eq 1 ]; then
        echo "  → Will be deleted in non-batch mode"
        continue
    fi
    
    DELETE_USER=0
    if [ $ASSUME_YES -eq 1 ]; then
        DELETE_USER=1
    else
        read -p "Delete this user? (y/N): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] && DELETE_USER=1
    fi

    if [ $DELETE_USER -eq 1 ]; then
        echo "Deleting user $username..."
        sudo userdel -r "$username" || {
            echo "Error deleting user $username" >&2
            continue
        }
        echo "✓ User $username deleted successfully"
    else
        echo "  → Skipped (user confirmation)"
    fi
done

echo "=== Cleanup completed at $(date) ==="