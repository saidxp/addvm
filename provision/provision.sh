#!/bin/bash

set -euo pipefail

echo "=================================================="
echo " Starting Main Debian Server Provisioning"
echo "=================================================="

PROVISION_DIR="$(dirname "$(readlink -f "$0")")"

bash "${PROVISION_DIR}/linux.sh"

bash "${PROVISION_DIR}/login.sh"

echo "=================================================="
echo " All Provisioning Completed Successfully"
echo "=================================================="