#!/bin/bash
set -euo pipefail

echo "=== Stage 13: Provisioning ACLs and Default Inheritance ==="

SHARED_DIR="/home/soubaaiss/01-talent"

# Configure access ACL for deploy1 (read + traverse access)
setfacl -m u:deploy1:rx "$SHARED_DIR"

# Configure default ACLs for inheritance on newly created files/subdirectories
setfacl -m d:g:project:rwx "$SHARED_DIR"
setfacl -m d:u:deploy1:rx "$SHARED_DIR"
setfacl -m d:m:rwx "$SHARED_DIR"

echo "ACL configuration complete for $SHARED_DIR."
