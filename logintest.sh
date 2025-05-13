#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIG ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="$SCRIPT_DIR/users.csv"
LOG_FILE="$SCRIPT_DIR/login_tests.log"
TIMEOUT=10  # seconds to wait for each connection attempt

# Setup logging
exec 1> >(tee -a "$LOG_FILE") 2>&1
echo "=== Login tests started at $(date) ==="

# Function to test SSH connection
test_ssh_login() {
    local username=$1
    local test_cmd="whoami"
    
    echo "→ Testing SSH login for user: $username"
    
    # Test SSH connection with timeout
    if timeout $TIMEOUT ssh -o BatchMode=yes \
                           -o StrictHostKeyChecking=no \
                           -o ConnectTimeout=5 \
                           -o PasswordAuthentication=no \
                           "$username@localhost" "$test_cmd" &>/dev/null; then
        echo "  ✓ SSH key authentication successful"
        return 0
    else
        echo "  ✗ SSH key authentication failed" >&2
        return 1
    fi
}

# Process each user from CSV
while IFS=';' read -r _ username _; do
    # Skip header
    [[ "$username" == "username" ]] && continue
    
    # Skip empty or invalid lines
    [[ -z "$username" ]] && continue
    
    # Test login
    if test_ssh_login "$username"; then
        echo "  • Login test passed for $username"
    else
        echo "  • Login test failed for $username" >&2
    fi
    
    # Add separation between tests
    echo
    
done < "$CSV_FILE"

echo "=== Login tests completed at $(date) ==="