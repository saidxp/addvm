# Stage 10 — PAM / faillock

## 1. Goal

The project requires protection against repeated failed authentication attempts.

The Debian server uses:

```text
PAM
 ↓
pam_faillock
 ↓
track failed authentication attempts
 ↓
temporarily block authentication
```

This is separate from password aging.

```text
chage
    ↓
password lifetime

PAM / faillock
    ↓
failed-login protection
```

---

## 2. Current Configuration

The existing Debian VM already contains:

```text
/etc/security/faillock.conf
```

The active configuration is:

```text
deny = 3
fail_interval = 60
unlock_time = 60
```

This means:

```text
3 failed authentication attempts
        ↓
within 60 seconds
        ↓
authentication is locked
        ↓
60 seconds
        ↓
authentication becomes available again
```

---

## 3. PAM Integration

The `pam_faillock` module is already integrated into PAM.

The following entries exist in:

```text
/etc/pam.d/common-auth
```

```text
auth    required       pam_faillock.so preauth
auth    [default=die]  pam_faillock.so authfail
auth    sufficient     pam_faillock.so authsucc
```

The following entry exists in:

```text
/etc/pam.d/common-account
```

```text
account required pam_faillock.so
```

Therefore, the project does not only have the configuration file; PAM is actually using `pam_faillock`.

---

## 4. PAM Module

The existing amd64 Debian VM contains:

```text
/usr/lib/x86_64-linux-gnu/security/pam_faillock.so
```

The module is owned by:

```text
root:root
```

The exact architecture-specific path is not considered a fixed project requirement.

The important requirement is:

```text
pam_faillock
    ↓
installed
    ↓
configured
    ↓
used by PAM
```

---

## 5. Current Failure Records

The following commands were checked:

```bash
faillock --user admin1
faillock --user developer1
faillock --user deploy1
```

All three users currently have no recorded authentication failures.

Therefore:

```text
admin1      → 0 failures
developer1  → 0 failures
deploy1     → 0 failures
```

---

## 6. Required Configuration

The new automated VM must reproduce the following security policy:

```text
deny = 3
fail_interval = 60
unlock_time = 60
```

It must also ensure that:

```text
pam_faillock.so
```

is connected to the PAM authentication/account stack.

The base Debian image alone must not be assumed to provide the project's final security configuration.

Provisioning will configure this later.

---

## 7. Verification

The final verification should check the policy:

```bash
grep -E '^[[:space:]]*(deny|fail_interval|unlock_time)[[:space:]]*=' \
    /etc/security/faillock.conf
```

Expected:

```text
deny = 3
fail_interval = 60
unlock_time = 60
```

Verify PAM integration:

```bash
grep -Rni "pam_faillock" /etc/pam.d/
```

The expected `pam_faillock.so` entries should be present.

Failure records can be inspected with:

```bash
faillock --user admin1
faillock --user developer1
faillock --user deploy1
```

---

## 8. Testing

A real lockout test can be performed later.

The expected behavior is:

```text
wrong authentication
        ↓
failure recorded
        ↓
wrong authentication
        ↓
failure recorded
        ↓
wrong authentication
        ↓
lockout
        ↓
60 seconds
        ↓
authentication available again
```

Because PAM controls authentication, testing must be done carefully with a reliable administrative access method available.

Failure records can be reset with:

```bash
faillock --user USER --reset
```

For example:

```bash
faillock --user developer1 --reset
```

The reset command is for testing/administration and should not be part of normal provisioning.

---

## 9. Provisioning Requirement

The provisioning stage must eventually:

```text
Install required PAM/faillock support
        ↓
Configure /etc/security/faillock.conf
        ↓
Configure PAM integration
        ↓
Validate PAM configuration
        ↓
Verify faillock policy
```

The existing VM is currently used as the reference configuration.

We are **not modifying the reference VM during the discovery stage**.

---

## 10. Stage Status

```text
✓ faillock.conf inspected
✓ deny = 3 identified
✓ fail_interval = 60 identified
✓ unlock_time = 60 identified
✓ PAM common-auth inspected
✓ PAM common-account inspected
✓ pam_faillock.so confirmed installed
✓ PAM integration confirmed
✓ Failure records inspected
✓ No current failure records
✓ No changes made to the reference VM
✓ Target configuration documented
```

### Final target

```text
PAM / faillock

deny = 3
fail_interval = 60
unlock_time = 60

        ↓

3 failures within 60 seconds
        ↓
temporary authentication lock
        ↓
60-second unlock time
```

**Stage 10 complete.**

**Next stage: Stage 11 — Shared Directory.**
