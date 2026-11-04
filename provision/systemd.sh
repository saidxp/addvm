#!/bin/bash
set -euo pipefail

echo "=== Stage 05: Provisioning Systemd Monitoring Service ==="

SCRIPT_SRC=""
SERVICE_SRC=""

# Find source files whether running via Vagrant (/vagrant) or directly in repository
if [ -f "/vagrant/systemd/myservice.sh" ]; then
    SCRIPT_SRC="/vagrant/systemd/myservice.sh"
    SERVICE_SRC="/vagrant/systemd/myservice.service"
else
    SCRIPT_SRC="$(dirname "$(readlink -f "$0")")/../systemd/myservice.sh"
    SERVICE_SRC="$(dirname "$(readlink -f "$0")")/../systemd/myservice.service"
fi

echo "Installing monitoring script from $SCRIPT_SRC to /usr/local/bin/myservice.sh..."
cp "$SCRIPT_SRC" /usr/local/bin/myservice.sh
chmod +x /usr/local/bin/myservice.sh

echo "Installing systemd unit from $SERVICE_SRC to /etc/systemd/system/myservice.service..."
cp "$SERVICE_SRC" /etc/systemd/system/myservice.service

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling and starting myservice.service..."
systemctl enable myservice.service
systemctl restart myservice.service || systemctl start myservice.service

echo "Systemd service provisioning complete."
