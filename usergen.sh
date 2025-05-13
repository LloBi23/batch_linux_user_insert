#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIG ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="$SCRIPT_DIR/users.csv"
KEY_DIR="$SCRIPT_DIR/ssh_keys"
LOG_FILE="$SCRIPT_DIR/usergen.log"

# Setup logging
exec 1> >(tee -a "$LOG_FILE") 2>&1
echo "=== User generation started at $(date) ==="

# Check required files
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: users.csv not found in $SCRIPT_DIR" >&2
    exit 1
fi

if [[ ! -d "$KEY_DIR" ]]; then
    echo "Error: ssh_keys directory not found in $SCRIPT_DIR" >&2
    exit 1
fi

# Create associative array for multiple keys
declare -A user_keys

# First pass: collect all keys per user
while IFS=';' read -r ssh_file username password; do
    # Skip header
    [[ "$ssh_file" == "ssh_filename" ]] && continue
    
    # Store keys for each user
    if [[ -n "${user_keys[$username]:-}" ]]; then
        user_keys[$username]+=" $ssh_file"
    else
        user_keys[$username]="$ssh_file"
    fi
done < "$CSV_FILE"

# Process each user
for username in "${!user_keys[@]}"; do
    echo "→ Processing user '$username'"
    
    # Get password from CSV
    password=$(grep -m1 ";$username;" "$CSV_FILE" | cut -d';' -f3)
    
    # Create user
    if ! id "$username" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$username"
        echo "  • Created user '$username'"
    fi
    
    # Set password
    echo "$username:$password" | sudo chpasswd
    echo "  • Password set"
    
    # Setup SSH directory
    SSH_DIR="/home/$username/.ssh"
    sudo mkdir -p "$SSH_DIR"
    AUTH_KEYS="$SSH_DIR/authorized_keys"
    
    # Clear existing keys
    sudo truncate -s 0 "$AUTH_KEYS"
    
    # Process all keys for this user
    for key_file in ${user_keys[$username]}; do
        KEY_PATH="$KEY_DIR/$key_file"
        
        if [[ ! -f "$KEY_PATH" ]]; then
            echo "  ! Key file '$key_file' not found — skipping" >&2
            continue
        fi
        
        # Append key
        sudo bash -c "cat '$KEY_PATH' >> '$AUTH_KEYS'"
        echo "  • Installed key: $key_file"
    done
    
    # Fix permissions
    sudo chown -R "$username:$username" "$SSH_DIR"
    sudo chmod 700 "$SSH_DIR"
    sudo chmod 600 "$AUTH_KEYS"
    echo "  • Set correct permissions"
done

echo "=== User generation completed at $(date) ==="
