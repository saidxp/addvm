#!/bin/bash
set -euo pipefail

echo "=== Stages 15 & 16: Provisioning SSH Configuration and Public Keys ==="

KEYS_DIR=""
if [ -d "/vagrant/keys" ]; then
    KEYS_DIR="/vagrant/keys"
else
    KEYS_DIR="$(dirname "$(readlink -f "$0")")/../keys"
fi

USERS=("admin1" "developer1" "deploy1")

for user in "${USERS[@]}"; do
    USER_SSH_DIR="/home/${user}/.ssh"
    AUTH_KEYS_FILE="${USER_SSH_DIR}/authorized_keys"

    mkdir -p "$USER_SSH_DIR"
    chmod 700 "$USER_SSH_DIR"
    chown "${user}:${user}" "$USER_SSH_DIR"

    PUB_KEY_SRC="${KEYS_DIR}/${user}.pub"
    if [ -f "$PUB_KEY_SRC" ]; then
        echo "Installing SSH public key for $user..."
        cat "$PUB_KEY_SRC" > "$AUTH_KEYS_FILE"
        chmod 600 "$AUTH_KEYS_FILE"
        chown "${user}:${user}" "$AUTH_KEYS_FILE"
    else
        echo "WARNING: Public key file $PUB_KEY_SRC not found!"
    fi
done

# Configure OpenSSH Server Settings safely
SSHD_CONF_DIR="/etc/ssh/sshd_config.d"
PROJECT_SSHD_CONF="${SSHD_CONF_DIR}/50-project.conf"

mkdir -p "$SSHD_CONF_DIR"

cat << 'EOF' > "$PROJECT_SSHD_CONF"
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
EOF

chmod 644 "$PROJECT_SSHD_CONF"

# Validate sshd configuration
echo "Validating SSH server configuration..."
sshd -t

# Reload SSH service
echo "Reloading SSH service..."
systemctl reload ssh || systemctl restart ssh

echo "SSH provisioning complete."
