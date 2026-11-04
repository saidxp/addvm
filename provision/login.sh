#!/bin/bash

set -euo pipefail

echo "=================================================="
echo " Login / Security Provisioning"
echo "=================================================="

PROVISION_DIR="$(dirname "$(readlink -f "$0")")"

bash "${PROVISION_DIR}/users.sh"
bash "${PROVISION_DIR}/groups.sh"
bash "${PROVISION_DIR}/sudo.sh"
bash "${PROVISION_DIR}/password.sh"
bash "${PROVISION_DIR}/pam.sh"
bash "${PROVISION_DIR}/filesystem.sh"
bash "${PROVISION_DIR}/permissions.sh"
bash "${PROVISION_DIR}/acl.sh"
bash "${PROVISION_DIR}/sticky.sh"
bash "${PROVISION_DIR}/ssh.sh"

echo "=================================================="
echo " Login / Security Provisioning Completed"
echo "=================================================="