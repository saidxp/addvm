#!/bin/bash
set -euo pipefail

echo "=== Stage 09: Provisioning Password Aging ==="

USERS=("admin1" "developer1" "deploy1")

for user in "${USERS[@]}"; do
    echo "Setting max password age to 90 days for $user..."
    chage -M 90 "$user"
done

echo "Password aging policy provisioning complete."
