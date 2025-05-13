#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIG ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="$SCRIPT_DIR/users.csv"
KEY_DIR="$SCRIPT_DIR/ssh_keys"
LOG_FILE="$SCRIPT_DIR/verify_keys.log"

# Setup logging
exec 1> >(tee -a "$LOG_FILE") 2>&1
echo "=== Verification started at $(date) ==="

# Process each user
while IFS=';' read -r ssh_file username _; do
    # Skip CSV header
    if [[ "$ssh_file" == "ssh_filename" ]]; then
        continue
    fi

    echo "→ Verifying user '$username' with key '$ssh_file'"

    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo "  ✗ User '$username' does not exist" >&2
        continue
    fi

    # Compare keys
    AUTH_KEYS="/home/$username/.ssh/authorized_keys"
    KEY_PATH="$KEY_DIR/$ssh_file"

    if [[ ! -f "$AUTH_KEYS" ]]; then
        echo "  ✗ No authorized_keys file found for $username" >&2
        continue
    fi

    if [[ ! -f "$KEY_PATH" ]]; then
        echo "  ✗ Source key file '$ssh_file' not found" >&2
        continue
    fi

    # Get key fingerprints - improved for multiple keys
    installed_fps=($(ssh-keygen -lf "$AUTH_KEYS" | awk '{print $2}'))
    source_fp=$(ssh-keygen -lf "$KEY_PATH" | awk '{print $2}')

    # Check if source fingerprint exists in installed keys
    key_found=0
    for installed_fp in "${installed_fps[@]}"; do
        if [[ "$installed_fp" == "$source_fp" ]]; then
            key_found=1
            break
        fi
    done

    if [ $key_found -eq 1 ]; then
        echo "  ✓ SSH key matches for user $username"
    else
        echo "  ✗ SSH key not found for user $username" >&2
        echo "    Expected: $source_fp" >&2
        echo "    Installed keys:" >&2
        for fp in "${installed_fps[@]}"; do
            echo "      - $fp" >&2
        done
    fi

done < "$CSV_FILE"

echo "=== Verification completed at $(date) ==="