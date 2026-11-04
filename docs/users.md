# Stage 06 — Users

## 1. Project Users

The `login` project creates three users:

```text
admin1
developer1
deploy1
```

No fixed UID values are required by the project.

The provisioning should create the users and allow Debian to assign the appropriate UIDs.

---

## 2. User Configuration

### admin1

```text
Username: admin1
Home:     /home/admin1
Shell:    /bin/bash
```

Current groups:

```text
admin1
admin
project
```

---

### developer1

```text
Username: developer1
Home:     /home/developer1
Shell:    /bin/bash
```

Current groups:

```text
developer1
devloper
developer
project
```

There is an existing misspelled group:

```text
devloper
```

The correct role group is:

```text
developer
```

The provisioning design should use the correctly named `developer` group. The obsolete `devloper` group should not be intentionally reproduced unless later inspection shows that the assignment requires it.

---

### deploy1

```text
Username: deploy1
Home:     /home/deploy1
Shell:    /bin/bash
```

Current groups:

```text
deploy1
deploy
```

---

## 3. User Creation Model

The users were created with:

```bash
/usr/sbin/useradd -m -s /bin/bash USER
```

The important properties are:

```text
-m
 ↓
create the user's home directory

-s /bin/bash
 ↓
use Bash as the login shell
```

The provisioning must reproduce these properties.

It does not need to reproduce the original numeric UID values.

---

## 4. Passwords

Passwords are not documented in this stage.

The project should create/configure the accounts, while password-aging policy is handled separately in:

```text
Stage 09 — Password Aging
```

Password hashes are not copied from the original VM.

---

## 5. User Model

The intended project model is:

```text
admin1
 ├── admin
 └── project

developer1
 ├── developer
 └── project

deploy1
 └── deploy
```

The `project` group is a resource-access group and is therefore documented separately from the role groups.

---

## 6. Stage 06 Conclusion

The project requires three Linux accounts:

```text
admin1
developer1
deploy1
```

Each account requires:

```text
individual home directory
/bin/bash login shell
appropriate role group
```

`admin1` and `developer1` also belong to the `project` resource-access group.

`deploy1` does not belong to `project`.

The original VM contains the obsolete `devloper` group membership for `developer1`; this is treated as an existing configuration issue rather than a required part of the target configuration.

**Stage 06 — Users: COMPLETE**
