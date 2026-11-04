#!/bin/bash

set -euo pipefail

echo "=================================================="
echo " Linux Provisioning"
echo "=================================================="

PROVISION_DIR="$(dirname "$(readlink -f "$0")")"

bash "${PROVISION_DIR}/packages.sh"
bash "${PROVISION_DIR}/systemd.sh"

echo "=================================================="
echo " Linux Provisioning Completed"
echo "=================================================="