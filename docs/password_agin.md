# Stage 09 — Password Aging

## 1. What Is Password Aging?

Password aging controls how long a user's password remains valid.

Linux can enforce rules such as:

```text
password changed
      ↓
maximum lifetime
      ↓
password expires
      ↓
user must change password
```

This is different from login authentication itself.

The project uses `chage` to configure password-aging policy.

---

# 2. The `chage` Command

`chage` means **change age information for a user**.

It can configure and display password-aging information.

Display the current policy:

```bash
chage -l USER
```

For example:

```bash
chage -l admin1
```

---

# 3. Important Password-Aging Values

The output contains several fields.

### Last password change

Example:

```text
Last password change : Sep 26, 2026
```

This records when the password was last changed.

---

### Minimum password lifetime

```text
Minimum number of days between password change
```

Example:

```text
0
```

This means the user can change the password again immediately.

---

### Maximum password lifetime

```text
Maximum number of days between password change
```

This is the important expiration setting.

For example:

```text
90
```

means the password expires after 90 days.

---

### Warning period

```text
Number of days of warning before password expires
```

For example:

```text
7
```

means the user is warned during the final seven days before expiration.

---

### Password inactive

```text
Password inactive
```

This controls what happens after a password expires if the account remains unused.

---

### Account expiration

```text
Account expires
```

This is different from password expiration.

It controls when the entire account becomes expired.

---

# 4. Current `admin1` Configuration

The existing VM reports:

```text
Last password change
    Sep 26, 2026

Password expires
    never

Password inactive
    never

Account expires
    never

Minimum days
    0

Maximum days
    99999

Warning days
    7
```

The important value is:

```text
Maximum number of days between password change
    99999
```

This means the password effectively does not expire.

---

# 5. Current `developer1` Configuration

The existing VM reports:

```text
Last password change
    Sep 26, 2026

Password expires
    never

Password inactive
    never

Account expires
    never

Minimum days
    0

Maximum days
    99999

Warning days
    7
```

Therefore `developer1` currently has no practical password expiration.

---

# 6. Current `deploy1` Configuration

The existing VM reports:

```text
Last password change
    Sep 26, 2026

Password expires
    never

Password inactive
    never

Account expires
    never

Minimum days
    0

Maximum days
    99999

Warning days
    7
```

Therefore `deploy1` currently has no practical password expiration.

---

# 7. Current State Summary

The three project users currently have:

```text
                 admin1   developer1   deploy1
                 -------  ----------   -------
Min days            0          0           0
Max days          99999      99999       99999
Warning              7          7           7
Password expires   never      never       never
Account expires    never      never       never
```

Therefore:

```text
Current VM
    ↓
passwords do not expire
```

---

# 8. Login Configuration

The `/etc/passwd` entries are:

```text
admin1:x:1001:1001::/home/admin1:/bin/bash
developer1:x:1002:1002::/home/developer1:/bin/bash
deploy1:x:1003:1003::/home/deploy1:/bin/bash
```

This tells us:

```text
admin1
├── UID: 1001
├── primary GID: 1001
├── home: /home/admin1
└── shell: /bin/bash


developer1
├── UID: 1002
├── primary GID: 1002
├── home: /home/developer1
└── shell: /bin/bash


deploy1
├── UID: 1003
├── primary GID: 1003
├── home: /home/deploy1
└── shell: /bin/bash
```

The UID values are existing VM values and are not currently treated as fixed project requirements.

---

# 9. Project Requirement

The project requires password aging.

The intended policy is:

```text
Maximum password lifetime = 90 days
```

Therefore the automated configuration should eventually apply:

```bash
chage -M 90 admin1
chage -M 90 developer1
chage -M 90 deploy1
```

The existing VM has not yet been configured with this policy.

---

# 10. What `-M 90` Means

The command:

```bash
chage -M 90 admin1
```

means:

```text
maximum password lifetime
        ↓
90 days
```

It does not mean:

```text
account expires after 90 days
```

It only controls the password lifetime.

The distinction is:

```text
Password expiration
        ↓
password must be changed


Account expiration
        ↓
account itself expires
```

---

# 11. Verify the Configuration

After applying the policy, verify:

```bash
chage -l admin1
chage -l developer1
chage -l deploy1
```

The important result should become:

```text
Maximum number of days between password change : 90
```

The password expiration date should then be calculated from the last password-change date.

---

# 12. Why This Is Separate From PAM

Password aging and failed-login protection solve different problems.

```text
chage
   ↓
How long is the password valid?
```

Whereas:

```text
PAM / faillock
   ↓
What happens after repeated failed login attempts?
```

For example:

```text
Password aging:

Sep 26
   ↓
90 days
   ↓
password expires
```

While PAM lockout is:

```text
wrong password
      ↓
wrong password
      ↓
wrong password
      ↓
configured threshold
      ↓
account authentication locked
```

They are separate security mechanisms.

---

# 13. Reproduction Requirement

The automated VM must reproduce:

```text
admin1
    ↓
maximum password age = 90 days

developer1
    ↓
maximum password age = 90 days

deploy1
    ↓
maximum password age = 90 days
```

Provisioning should therefore apply:

```bash
chage -M 90 admin1
chage -M 90 developer1
chage -M 90 deploy1
```

Then verify the result.

---

# 14. Verification Requirements

The final verification should check:

```bash
chage -l admin1
chage -l developer1
chage -l deploy1
```

and confirm:

```text
Maximum number of days between password change : 90
```

The verification should not depend on the exact calendar date because that changes every time the password is changed.

The important invariant is:

```text
maximum password age = 90
```

---

# Stage 09 Status

```text
✓ Existing password-aging configuration inspected
✓ admin1 inspected
✓ developer1 inspected
✓ deploy1 inspected
✓ Current policy documented
✓ Current state identified: 99999 days / effectively never
✓ Target policy defined: 90 days
```

Important:

```text
CURRENT VM
    ↓
99999 days
    ↓
no practical expiration

TARGET AUTOMATED VM
    ↓
90 days
    ↓
password expiration enabled
```

Stage 09 is now documented.

**Next: Stage 10 — PAM / `faillock`.**
