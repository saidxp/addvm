#!/bin/bash
set -euo pipefail

echo "=== Stage 06: Provisioning Users ==="

USERS=("admin1" "developer1" "deploy1")

for user in "${USERS[@]}"; do
    if ! id "$user" &>/dev/null; then
        echo "Creating user $user..."
        useradd -m -s /bin/bash "$user"
    else
        echo "User $user already exists. Verifying shell and home..."
        usermod -s /bin/bash "$user"
        if [ ! -d "/home/$user" ]; then
            mkdir -p "/home/$user"
            chown "$user:$user" "/home/$user"
        fi
    fi
done

echo "User provisioning complete."
