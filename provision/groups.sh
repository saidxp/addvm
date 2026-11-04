#!/bin/bash
set -euo pipefail

echo "=== Stage 07: Provisioning Groups ==="

ROLE_GROUPS=("admin" "developer" "deploy" "project")

for grp in "${ROLE_GROUPS[@]}"; do
    if ! getent group "$grp" &>/dev/null; then
        echo "Creating group $grp..."
        groupadd "$grp"
    else
        echo "Group $grp already exists."
    fi
done

# Assign user memberships idempotently
usermod -aG admin admin1
usermod -aG project admin1

usermod -aG developer developer1
usermod -aG project developer1

usermod -aG deploy deploy1

# Remove developer1 and deploy1 from generic sudo group if present
if getent group sudo &>/dev/null; then
    gpasswd -d developer1 sudo &>/dev/null || true
    gpasswd -d deploy1 sudo &>/dev/null || true
fi

# Ensure deploy1 is not in project group
if getent group project | grep -q "\bdeploy1\b"; then
    gpasswd -d deploy1 project &>/dev/null || true
fi

echo "Group provisioning complete."
