#!/bin/bash
# ==============================================================================
# Verification Script for Debian Server Vagrant Provisioning Project
# ==============================================================================

set -u

PASS=0
FAIL=0

pass() {
    echo "[PASS] $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL=$((FAIL + 1))
}

echo "=================================================="
echo " Starting Verification Checks"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. Users Verification
# ------------------------------------------------------------------------------
echo "--- 1. Users Verification ---"
for user in admin1 developer1 deploy1; do
    if id "$user" &>/dev/null; then
        pass "User $user exists."
    else
        fail "User $user does NOT exist."
    fi
done

# ------------------------------------------------------------------------------
# 2. Groups Verification
# ------------------------------------------------------------------------------
echo "--- 2. Groups Verification ---"
for grp in admin developer deploy project; do
    if getent group "$grp" &>/dev/null; then
        pass "Group $grp exists."
    else
        fail "Group $grp does NOT exist."
    fi
done

# Verify memberships
if id -nG admin1 2>/dev/null | grep -qw "admin" && id -nG admin1 2>/dev/null | grep -qw "project"; then
    pass "admin1 belongs to admin and project groups."
else
    fail "admin1 group membership is incorrect."
fi

if id -nG developer1 2>/dev/null | grep -qw "developer" && id -nG developer1 2>/dev/null | grep -qw "project"; then
    pass "developer1 belongs to developer and project groups."
else
    fail "developer1 group membership is incorrect."
fi

if id -nG deploy1 2>/dev/null | grep -qw "deploy"; then
    pass "deploy1 belongs to deploy group."
else
    fail "deploy1 group membership is incorrect."
fi

if id -nG deploy1 2>/dev/null | grep -qw "project"; then
    fail "deploy1 MUST NOT be a member of project group."
else
    pass "deploy1 is correctly excluded from project group."
fi

if id -nG developer1 2>/dev/null | grep -qw "sudo" || id -nG deploy1 2>/dev/null | grep -qw "sudo"; then
    fail "developer1 or deploy1 must NOT be members of sudo group."
else
    pass "developer1 and deploy1 are not in sudo group."
fi

# ------------------------------------------------------------------------------
# 3. Sudo Configuration Verification
# ------------------------------------------------------------------------------
echo "--- 3. Sudo Configuration Verification ---"
if visudo -c &>/dev/null; then
    pass "Sudoers syntax is valid (visudo -c)."
else
    fail "Sudoers syntax validation failed."
fi

for policy in admin developer deploy; do
    f="/etc/sudoers.d/$policy"
    if [ -f "$f" ]; then
        mode=$(stat -c '%a' "$f")
        if [ "$mode" = "440" ] || [ "$mode" = "0440" ]; then
            pass "Sudoers policy file $f exists with permissions 0440."
        else
            fail "Sudoers policy file $f has incorrect permissions ($mode, expected 0440)."
        fi
    else
        fail "Sudoers policy file $f missing."
    fi
done

# Check effective sudo permissions
if sudo -l -U developer1 2>/dev/null | grep -q "myservice.service"; then
    pass "developer1 has effective sudo permission for myservice.service restart."
else
    fail "developer1 effective sudo permission missing."
fi

if sudo -l -U deploy1 2>/dev/null | grep -q "myservice.service"; then
    pass "deploy1 has effective sudo permission for myservice.service restart."
else
    fail "deploy1 effective sudo permission missing."
fi

if sudo -l -U admin1 2>/dev/null | grep -q "USER_MANAGEMENT"; then
    pass "admin1 has effective sudo permissions configured."
else
    fail "admin1 effective sudo permissions missing."
fi

# ------------------------------------------------------------------------------
# 4. Password Aging Verification
# ------------------------------------------------------------------------------
echo "--- 4. Password Aging Verification ---"
for user in admin1 developer1 deploy1; do
    max_days=$(chage -l "$user" 2>/dev/null | grep "Maximum number of days" | awk -F': ' '{print $2}')
    if [ "$max_days" = "90" ]; then
        pass "Password max age for $user is 90 days."
    else
        fail "Password max age for $user is $max_days (expected 90)."
    fi
done

# ------------------------------------------------------------------------------
# 5. PAM / pam_faillock Verification
# ------------------------------------------------------------------------------
echo "--- 5. PAM / faillock Verification ---"
if [ -f "/etc/security/faillock.conf" ]; then
    deny=$(grep -E '^[[:space:]]*deny[[:space:]]*=' /etc/security/faillock.conf | awk -F'=' '{print $2}' | tr -d ' ')
    f_interval=$(grep -E '^[[:space:]]*fail_interval[[:space:]]*=' /etc/security/faillock.conf | awk -F'=' '{print $2}' | tr -d ' ')
    u_time=$(grep -E '^[[:space:]]*unlock_time[[:space:]]*=' /etc/security/faillock.conf | awk -F'=' '{print $2}' | tr -d ' ')

    if [ "$deny" = "3" ] && [ "$f_interval" = "60" ] && [ "$u_time" = "60" ]; then
        pass "faillock.conf is configured with deny=3, fail_interval=60, unlock_time=60."
    else
        fail "faillock.conf policy settings incorrect: deny=$deny, fail_interval=$f_interval, unlock_time=$u_time."
    fi
else
    fail "/etc/security/faillock.conf is missing."
fi

if grep -q "pam_faillock.so" /etc/pam.d/common-auth 2>/dev/null && grep -q "pam_faillock.so" /etc/pam.d/common-account 2>/dev/null; then
    pass "PAM integration for pam_faillock is active in common-auth and common-account."
else
    fail "PAM integration for pam_faillock missing from /etc/pam.d/."
fi

# ------------------------------------------------------------------------------
# 6. Shared Directory & Permissions Verification
# ------------------------------------------------------------------------------
echo "--- 6. Shared Directory Verification ---"
SHARED_DIR="/home/soubaaiss/01-talent"
if [ -d "$SHARED_DIR" ]; then
    pass "Shared directory $SHARED_DIR exists."

    owner_group=$(stat -c '%U:%G' "$SHARED_DIR")
    if [ "$owner_group" = "root:project" ]; then
        pass "Shared directory ownership is root:project."
    else
        fail "Shared directory ownership is $owner_group (expected root:project)."
    fi

    mode=$(stat -c '%a' "$SHARED_DIR")
    if [ "$mode" = "2770" ]; then
        pass "Shared directory mode is 2770 (setgid enabled)."
    else
        fail "Shared directory mode is $mode (expected 2770)."
    fi

    # Check ACLs
    facl_output=$(getfacl "$SHARED_DIR" 2>/dev/null)
    if echo "$facl_output" | grep -q "user:deploy1:r-x"; then
        pass "Directory ACL has user:deploy1:r-x."
    else
        fail "Directory ACL missing user:deploy1:r-x."
    fi

    if echo "$facl_output" | grep -q "default:group:project:rwx"; then
        pass "Default ACL has default:group:project:rwx."
    else
        fail "Default ACL missing default:group:project:rwx."
    fi
else
    fail "Shared directory $SHARED_DIR does NOT exist."
fi

# ------------------------------------------------------------------------------
# 7. Sticky-Bit Scratch Directory Verification
# ------------------------------------------------------------------------------
echo "--- 7. Sticky-Bit Scratch Directory Verification ---"
SCRATCH_DIR="/home/soubaaiss/test/scratch"
if [ -d "$SCRATCH_DIR" ]; then
    pass "Scratch directory $SCRATCH_DIR exists."
    smode=$(stat -c '%a' "$SCRATCH_DIR")
    if [ "$smode" = "1777" ]; then
        pass "Scratch directory mode is 1777 (sticky bit enabled)."
    else
        fail "Scratch directory mode is $smode (expected 1777)."
    fi
else
    fail "Scratch directory $SCRATCH_DIR missing."
fi

# ------------------------------------------------------------------------------
# 8. Systemd Monitoring Service Verification
# ------------------------------------------------------------------------------
echo "--- 8. Systemd Service Verification ---"
if systemctl is-enabled myservice.service &>/dev/null; then
    pass "myservice.service is enabled."
else
    fail "myservice.service is NOT enabled."
fi

if systemctl is-active myservice.service &>/dev/null; then
    pass "myservice.service is active (running)."
else
    fail "myservice.service is NOT active."
fi

if grep -q "Restart=always" /etc/systemd/system/myservice.service 2>/dev/null && grep -q "RestartSec=5" /etc/systemd/system/myservice.service 2>/dev/null; then
    pass "myservice.service preserves Restart=always and RestartSec=5."
else
    fail "myservice.service unit definition missing Restart parameters."
fi

# ------------------------------------------------------------------------------
# 9. SSH Server & Keys Verification
# ------------------------------------------------------------------------------
echo "--- 9. SSH Server & Keys Verification ---"
if sshd -t &>/dev/null; then
    pass "sshd syntax validation (sshd -t) succeeded."
else
    fail "sshd syntax validation (sshd -t) failed."
fi

sshd_t_out=$(sshd -T 2>/dev/null)
if echo "$sshd_t_out" | grep -iq "pubkeyauthentication yes" && echo "$sshd_t_out" | grep -iq "passwordauthentication no"; then
    pass "Effective SSH config: PubkeyAuthentication=yes and PasswordAuthentication=no."
else
    fail "Effective SSH config does not enforce pubkey-only authentication."
fi

for user in admin1 developer1 deploy1; do
    ak="/home/$user/.ssh/authorized_keys"
    sdir="/home/$user/.ssh"
    if [ -f "$ak" ]; then
        smode=$(stat -c '%a' "$sdir")
        fmode=$(stat -c '%a' "$ak")
        owner=$(stat -c '%U:%G' "$ak")
        if [ "$smode" = "700" ] && [ "$fmode" = "600" ] && [ "$owner" = "$user:$user" ]; then
            pass "SSH key files for $user have correct ownership ($user:$user) and permissions (700/600)."
        else
            fail "SSH key files for $user have incorrect mode/owner (dir:$smode, file:$fmode, owner:$owner)."
        fi
    else
        fail "authorized_keys missing for $user."
    fi
done

# ------------------------------------------------------------------------------
# 10. Real Behavioral Access Tests
# ------------------------------------------------------------------------------
echo "--- 10. Behavioral Access Tests ---"
TEST_FILE="${SHARED_DIR}/behavior_test_$$.txt"

# Behavioral Test A: developer1 creates file in shared dir, verify setgid group inheritance
if su -s /bin/bash developer1 -c "touch $TEST_FILE" &>/dev/null; then
    file_grp=$(stat -c '%G' "$TEST_FILE" 2>/dev/null || echo "none")
    if [ "$file_grp" = "project" ]; then
        pass "Setgid test: file created by developer1 inherited group 'project'."
    else
        fail "Setgid test: created file group is '$file_grp' (expected 'project')."
    fi

    # Behavioral Test B: admin1 can write to file created by developer1
    if su -s /bin/bash admin1 -c "echo 'admin1_write' >> $TEST_FILE" &>/dev/null; then
        pass "Shared access test: admin1 successfully modified file created by developer1."
    else
        fail "Shared access test: admin1 failed to modify developer1 file."
    fi

    # Behavioral Test C: deploy1 can read file but cannot write to file
    if su -s /bin/bash deploy1 -c "cat $TEST_FILE" &>/dev/null; then
        pass "Deploy ACL test: deploy1 can read shared file."
    else
        fail "Deploy ACL test: deploy1 failed to read shared file."
    fi

    if su -s /bin/bash deploy1 -c "echo 'deploy1_write' >> $TEST_FILE" &>/dev/null; then
        fail "Deploy ACL test: deploy1 should NOT be allowed to write to shared file."
    else
        pass "Deploy ACL test: deploy1 write access correctly denied."
    fi

    rm -f "$TEST_FILE"
else
    fail "Setgid behavioral test: developer1 could not create test file in $SHARED_DIR."
fi

# Behavioral Test D: Sticky bit deletion denial
STICKY_TEST_FILE="${SCRATCH_DIR}/sticky_test_$$.txt"
if su -s /bin/bash developer1 -c "touch $STICKY_TEST_FILE" &>/dev/null; then
    if su -s /bin/bash deploy1 -c "rm -f $STICKY_TEST_FILE" &>/dev/null; then
        fail "Sticky bit test: deploy1 was able to delete developer1's file in scratch directory!"
    else
        pass "Sticky bit test: deploy1 deletion of developer1 file in scratch directory was correctly DENIED."
    fi
    rm -f "$STICKY_TEST_FILE"
else
    fail "Sticky bit test setup: developer1 could not create test file in $SCRATCH_DIR."
fi

# ------------------------------------------------------------------------------
# Verification Summary
# ------------------------------------------------------------------------------
echo "=================================================="
echo " Verification Summary"
echo "=================================================="
echo " PASS: $PASS"
echo " FAIL: $FAIL"
echo "=================================================="

if [ "$FAIL" -eq 0 ]; then
    echo "Result: ALL VERIFICATION CHECKS PASSED!"
    exit 0
else
    echo "Result: VERIFICATION FAILED WITH $FAIL ERRORS."
    exit 1
fi
