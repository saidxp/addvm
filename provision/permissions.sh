#!/bin/bash
set -euo pipefail

echo "=== Stage 12: Provisioning Directory Ownership, Permissions, and Setgid ==="

SHARED_DIR="/home/soubaaiss/01-talent"

# Set ownership to root:project
chown root:project "$SHARED_DIR"

# Set mode to 2770 (rwx for owner and group, none for others, setgid bit enabled)
chmod 2770 "$SHARED_DIR"

echo "Permissions and setgid configured for $SHARED_DIR."
