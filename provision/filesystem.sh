#!/bin/bash
set -euo pipefail

echo "=== Stage 11: Provisioning Shared Filesystem Structure ==="

PARENT_DIR="/home/soubaaiss"
SHARED_DIR="${PARENT_DIR}/01-talent"

# Create parent directory if missing
if [ ! -d "$PARENT_DIR" ]; then
    mkdir -p "$PARENT_DIR"
    chmod 755 "$PARENT_DIR"
fi

# Apply traversal ACL to parent directory without giving list/read permissions
setfacl -m u:admin1:--x "$PARENT_DIR"
setfacl -m u:developer1:--x "$PARENT_DIR"
setfacl -m u:deploy1:--x "$PARENT_DIR"

# Create target shared project directory
if [ ! -d "$SHARED_DIR" ]; then
    mkdir -p "$SHARED_DIR"
fi

echo "Shared directory structure created at $SHARED_DIR."
