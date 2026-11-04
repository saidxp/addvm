#!/bin/bash
set -euo pipefail

echo "=== Stage 08: Provisioning Sudo Policies ==="

SUDOERS_DIR="/etc/sudoers.d"

# Configure Admin Sudo Policy
cat << 'EOF' > "${SUDOERS_DIR}/admin"
Cmnd_Alias USER_MANAGEMENT = /usr/sbin/useradd, /usr/sbin/usermod, /usr/sbin/userdel, /usr/sbin/groupadd, /usr/sbin/groupmod, /usr/sbin/groupdel, /usr/bin/passwd, /usr/bin/chage
Cmnd_Alias PACKAGE_MANAGEMENT = /usr/bin/apt, /usr/bin/apt-get
Cmnd_Alias SERVICE_RESTART = /usr/bin/systemctl restart *

%admin ALL=(root) USER_MANAGEMENT, PACKAGE_MANAGEMENT, SERVICE_RESTART
EOF

# Configure Developer Sudo Policy
cat << 'EOF' > "${SUDOERS_DIR}/developer"
%developer ALL=(root) /usr/bin/systemctl restart myservice.service
EOF

# Configure Deploy Sudo Policy
cat << 'EOF' > "${SUDOERS_DIR}/deploy"
%deploy ALL=(root) /usr/bin/systemctl restart myservice.service
EOF

# Set secure 0440 permissions
chmod 0440 "${SUDOERS_DIR}/admin"
chmod 0440 "${SUDOERS_DIR}/developer"
chmod 0440 "${SUDOERS_DIR}/deploy"
chown root:root "${SUDOERS_DIR}/admin" "${SUDOERS_DIR}/developer" "${SUDOERS_DIR}/deploy"

# Validate sudo configuration
visudo -c

echo "Sudo policy provisioning complete."
