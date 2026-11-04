# Stage 17 — Verification Requirements

## 1. Purpose

The `verify.sh` script is a verification script for the `login` project.

It does not configure the server.

Its purpose is to check whether the server already has the required configuration:

```text
Vagrant provisioning
        ↓
server configured
        ↓
verify.sh
        ↓
PASS / FAIL
```

The verification script checks users, groups, directories, ACLs, password aging, PAM, sudo, SSH, shared-directory behavior, and sticky-bit behavior.

---

# 2. Users

The script verifies that these users exist:

```text
admin1
developer1
deploy1
```

It uses:

```bash
id "$1"
```

The required users are therefore:

```text
admin1
developer1
deploy1
```

---

# 3. Role Groups

The script verifies these groups exist:

```text
admin
developer
deploy
```

It also verifies:

```text
admin1      → admin
developer1  → developer
deploy1     → deploy
```

The script explicitly checks that:

```text
deploy1 ∉ project
```

Therefore the final server must preserve this separation.

---

# 4. Shared Project Group

The verification script expects:

```text
project
```

to be used for the shared directory.

The intended membership is:

```text
project
├── admin1
└── developer1

deploy1 is NOT a member
```

---

# 5. Shared Directory

The script currently defines:

```bash
PROJECT_DIR="/home/soubaaiss/test"
```

It expects the directory to:

```text
exist
```

and have:

```text
owner = root
group = project
mode  = 2770
```

The expected mode is explicitly:

```text
2770
```

Therefore:

```text
setgid      → enabled
owner       → rwx
group       → rwx
others      → ---
```

This is important because earlier we inspected `2777` on the reference directory, but the current verification script requires `2770`.

The final automated configuration must follow the actual verification requirement rather than the old `2777` observation.

---

# 6. Shared Directory ACL

The script expects the shared directory to contain:

```text
user:deploy1:r-x
```

It also expects these default ACL entries:

```text
default:group:project:rwx
default:user:deploy1:r-x
```

Therefore the verification requirements are:

```text
Access ACL
    deploy1 → r-x

Default ACL
    project → rwx
    deploy1 → r-x
```

---

# 7. Password Aging

The script currently contains:

```bash
EXPECTED_MAX_DAYS=1
```

and checks:

```text
soubaaiss
```

Therefore the current script expects:

```text
soubaaiss
→ maximum password age = 1 day
```

This does **not** match our earlier project design:

```text
admin1      → 90 days
developer1  → 90 days
deploy1     → 90 days
```

It also refers to `soubaaiss`, which is not one of the three project accounts.

This is a verification-script inconsistency that must be resolved before the final automation.

The intended project configuration remains:

```text
admin1      → 90 days
developer1  → 90 days
deploy1     → 90 days
```

---

# 8. PAM Failed-Login Lockout

The script expects:

```text
deny = 3
fail_interval = 60
unlock_time = 60
```

It also checks:

```text
/etc/pam.d/common-auth
```

for:

```text
pam_faillock.so preauth
pam_faillock.so authfail
pam_faillock.so authsucc
```

And it checks:

```text
/etc/pam.d/common-account
```

for:

```text
pam_faillock.so
```

Therefore the final server must contain both:

```text
faillock policy
```

and:

```text
PAM integration
```

---

# 9. PAM Verification Inconsistency

The script later runs:

```bash
/usr/sbin/faillock --user soubaaiss
```

and expects there to be recorded failures.

This is a problem for a clean rebuilt VM because the account:

```text
soubaaiss
```

is not one of the project users we created.

Also, a verification script should normally be able to verify a clean system without depending on old authentication failures already being present.

Therefore this part of the script should be reviewed before we treat `verify.sh` as the immutable final verifier.

---

# 10. Developer Sudo

The script verifies:

```text
/etc/sudoers.d/developer
```

and expects exactly:

```text
%developer ALL=(root) /usr/bin/systemctl restart myservice.service
```

It also verifies the effective privilege of:

```text
developer1
```

The required capability is:

```text
developer1
    ↓
sudo
    ↓
restart myservice.service
```

---

# 11. Deploy Sudo

The script verifies:

```text
/etc/sudoers.d/deploy
```

and expects:

```text
%deploy ALL=(root) /usr/bin/systemctl restart myservice.service
```

It also verifies that:

```text
deploy1
```

has the effective permission.

Therefore:

```text
deploy1
    ↓
sudo
    ↓
restart myservice.service
```

---

# 12. Admin Sudo

The script verifies:

```text
/etc/sudoers.d/admin
```

and expects these command aliases:

```text
USER_MANAGEMENT
PACKAGE_MANAGEMENT
SERVICE_RESTART
```

It also expects:

```text
%admin
```

to be authorized.

The effective permissions must allow `admin1` to:

```text
manage users
install/manage packages
restart services
```

---

# 13. Effective Sudo Verification

The script also checks the effective result using:

```bash
sudo -l -U USER
```

This is important because the existence of a sudoers file alone does not prove that the rule is effective.

The final server must satisfy:

```text
admin1
    → user management
    → package management
    → service restart

developer1
    → myservice.service restart only

deploy1
    → myservice.service restart only
```

---

# 14. SSH Configuration

The script checks the effective SSH configuration with:

```bash
sshd -T
```

It expects:

```text
pubkeyauthentication yes
passwordauthentication no
```

Therefore the final SSH server must use:

```text
public key authentication → enabled
password authentication    → disabled
```

Our Stage 15 design additionally requires:

```text
kbdinteractiveauthentication no
usepam yes
```

Those should remain part of the final configuration even though this version of `verify.sh` does not check them.

---

# 15. SSH Authorized Keys

For each user:

```text
admin1
developer1
deploy1
```

the script checks:

```text
/home/USER/.ssh
/home/USER/.ssh/authorized_keys
```

It requires:

```text
.ssh owner             → USER
.ssh mode              → 700

authorized_keys owner  → USER
authorized_keys mode   → 600
authorized_keys        → not empty
```

Therefore the final structure is:

```text
/home/admin1/.ssh/authorized_keys
/home/developer1/.ssh/authorized_keys
/home/deploy1/.ssh/authorized_keys
```

with the corresponding ownership and permissions.

---

# 16. Shared Directory Behavior

The script intends to test:

```text
developer1 creates/writes a file
        ↓
new file gets group = project
        ↓
deploy1 can read
        ↓
deploy1 cannot write
```

This verifies real filesystem behavior rather than checking permissions only.

The intended model is:

```text
developer1 → write
admin1     → shared access
deploy1    → restricted access
```

---

# 17. Verification-Script Bug: `TEST_FILE`

The script contains:

```bash
TEST_FILE="$PROJECT_DIR"
```

But:

```text
PROJECT_DIR
    = /home/soubaaiss/test
```

That means the script is using the **directory itself as the test file**.

Then it executes:

```bash
rm -f "$TEST_FILE"
```

and later redirects output into:

```text
"$TEST_FILE"
```

This is not a valid file-creation test because the path represents the shared directory.

The test should instead use a file such as:

```text
/home/soubaaiss/test/verify-test.txt
```

before checking its group and access.

Therefore this part of the existing script needs correction before it can be treated as a reliable final verifier.

---

# 18. Sticky Bit Verification

The script intends to test:

```text
sticky bit
```

and expects:

```text
1777
```

It also intends to test that one user cannot delete another user's file.

The desired behavior is:

```text
user A creates file
       ↓
user B tries to delete file
       ↓
DENIED
```

This is the correct purpose of the sticky bit.

---

# 19. Sticky-Bit Test Inconsistency

The script defines:

```bash
STICKY_TEST_FILE="/home/soubaaiss/test/scrath/.test.txt"
```

but our actual observed directory was:

```text
/home/soubaaiss/test/scrathc
```

So the script contains:

```text
scrath
```

while the existing directory is:

```text
scrathc
```

The script also uses:

```bash
sudo -u soubaaiss
```

although the intended project users are:

```text
admin1
developer1
deploy1
```

Therefore the sticky-bit test currently does not correspond to the actual server design.

This must be corrected before final automation.

---

# 20. Incomplete Verification Script

The supplied script ends with:

```bash
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
```

At this point the script does not yet show a final summary or exit status.

A complete verifier should eventually report something like:

```text
=== Verification Summary ===

PASS: X
FAIL: Y
```

and return a meaningful exit code, for example:

```text
0 → all checks passed
non-zero → one or more checks failed
```

We need the remainder of the original file before deciding whether this is actually the end of `verify.sh`.

---

# 21. What Stage 17 Gives Us

The verifier gives us two different things:

```text
REQUIREMENTS
    ↓
what the automated VM must contain

TESTS
    ↓
how we prove that the configuration works
```

Examples:

```text
Requirement:
developer1 can restart myservice.service

Verification:
sudo -l -U developer1
```

```text
Requirement:
setgid + project group

Verification:
create file
↓
check file group
```

```text
Requirement:
SSH public-key authentication

Verification:
sshd -T
authorized_keys
```

---

# 22. Important Conflicts to Resolve

Before implementing the Vagrant configuration, the following verifier issues must be resolved:

```text
1. Password age:
   script expects soubaaiss = 1 day
   project design expects admin1/developer1/deploy1 = 90 days

2. PAM test:
   script expects faillock records for soubaaiss
   clean VM should not depend on old failure records

3. Shared-directory TEST_FILE:
   script uses the directory as if it were a file

4. Sticky directory:
   script uses /scrath
   actual reference directory is /scrathc

5. Sticky test user:
   script uses soubaaiss
   project uses admin1/developer1/deploy1

6. Script completeness:
   supplied content ends before a final summary/exit status
```

These are **verification-script problems**, not reasons to change the server design automatically.

We should resolve them before Stage 18 because the assignment requires the rebuilt VM to pass the final verification reliably.

---

# 23. Final Verification Architecture

The final workflow should be:

```text
Vagrant
   ↓
creates VM
   ↓
provisioning
   ↓
users
groups
sudo
chage
PAM
directories
permissions
ACLs
sticky bit
SSH
   ↓
verify.sh
   ↓
functional tests
   ↓
PASS / FAIL
```

The verifier should test both:

```text
configuration state
```

and:

```text
actual behavior
```

**Stage 17 — verification requirements documented and inconsistencies identified.**

**Next: resolve the `verify.sh` inconsistencies, then Stage 18 — unattended installation.**
