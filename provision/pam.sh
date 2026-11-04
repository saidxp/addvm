#!/bin/bash
set -euo pipefail

echo "=== Stage 10: Provisioning PAM / pam_faillock ==="

FAILLOCK_CONF="/etc/security/faillock.conf"

if [ -f "$FAILLOCK_CONF" ]; then
    # Ensure deny = 3
    if grep -qE '^[[:space:]]*deny[[:space:]]*=' "$FAILLOCK_CONF"; then
        sed -i -E 's/^[[:space:]]*deny[[:space:]]*=.*/deny = 3/' "$FAILLOCK_CONF"
    else
        echo "deny = 3" >> "$FAILLOCK_CONF"
    fi

    # Ensure fail_interval = 60
    if grep -qE '^[[:space:]]*fail_interval[[:space:]]*=' "$FAILLOCK_CONF"; then
        sed -i -E 's/^[[:space:]]*fail_interval[[:space:]]*=.*/fail_interval = 60/' "$FAILLOCK_CONF"
    else
        echo "fail_interval = 60" >> "$FAILLOCK_CONF"
    fi

    # Ensure unlock_time = 60
    if grep -qE '^[[:space:]]*unlock_time[[:space:]]*=' "$FAILLOCK_CONF"; then
        sed -i -E 's/^[[:space:]]*unlock_time[[:space:]]*=.*/unlock_time = 60/' "$FAILLOCK_CONF"
    else
        echo "unlock_time = 60" >> "$FAILLOCK_CONF"
    fi
else
    mkdir -p /etc/security
    cat << 'EOF' > "$FAILLOCK_CONF"
deny = 3
fail_interval = 60
unlock_time = 60
EOF
fi

# Ensure PAM common-auth calls pam_faillock.so
PAM_AUTH="/etc/pam.d/common-auth"
if [ -f "$PAM_AUTH" ] && ! grep -q "pam_faillock.so" "$PAM_AUTH"; then
    # Inject pam_faillock lines into PAM common-auth if pam_authconfig didn't already
    sed -i '1i auth    required       pam_faillock.so preauth' "$PAM_AUTH"
    sed -i '/auth.*pam_unix.so/a auth    [default=die]  pam_faillock.so authfail' "$PAM_AUTH"
    sed -i '$a auth    sufficient     pam_faillock.so authsucc' "$PAM_AUTH"
fi

# Ensure PAM common-account calls pam_faillock.so
PAM_ACCT="/etc/pam.d/common-account"
if [ -f "$PAM_ACCT" ] && ! grep -q "pam_faillock.so" "$PAM_ACCT"; then
    sed -i '1i account required       pam_faillock.so' "$PAM_ACCT"
fi

echo "PAM / faillock provisioning complete."
