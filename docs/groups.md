# Stage 07 — Groups

## 1. Group Model

The project uses two types of groups.

### Role groups

These represent the user's administrative/job role:

```text
admin
developer
deploy
```

### Resource-access group

This group controls access to the shared project directory:

```text
project
```

The concepts are separate:

```text
Role group
    ↓
sudo authorization

Resource group
    ↓
filesystem access
```

---

## 2. Actual Group Configuration

The groups were inspected with:

```bash
echo "===== PROJECT GROUPS ====="

for group in admin developer deploy project devloper; do
    echo
    echo "--- $group ---"
    getent group "$group" || echo "NOT FOUND"
done
```

The actual result from the existing VM is:

```text
===== PROJECT GROUPS =====

--- admin ---
admin:x:1004:admin1

--- developer ---
developer:x:1007:developer1,tamine

--- deploy ---
deploy:x:1006:deploy1

--- project ---
project:x:1008:admin1,developer1,tamine

--- devloper ---
devloper:x:1005:developer1
```

---

## 3. Role Groups

### `admin`

Current membership:

```text
admin
└── admin1
```

The group has GID:

```text
1004
```

The numeric GID is not required to remain fixed in the `add-vm` project.

---

### `developer`

Current membership:

```text
developer
├── developer1
└── tamine
```

The group has GID:

```text
1007
```

`developer1` is the project user.

`tamine` is an additional existing user on the VM and is currently a member of the `developer` group.

This membership was observed on the existing machine and must not automatically be assumed to be required by the `add-vm` project.

---

### `deploy`

Current membership:

```text
deploy
└── deploy1
```

The group has GID:

```text
1006
```

---

## 4. Resource Group

The `project` group currently contains:

```text
project
├── admin1
├── developer1
└── tamine
```

The group has GID:

```text
1008
```

The project-specific users requiring shared project access are:

```text
admin1
developer1
```

`tamine` is an additional existing member observed on the VM.

Its membership must be treated separately from the required project configuration unless the assignment explicitly requires `tamine`.

---

## 5. Obsolete Group

The existing VM also contains:

```text
devloper
└── developer1
```

GID:

```text
1005
```

This is the misspelled version of:

```text
developer
```

The intended role group is:

```text
developer
```

The `devloper` group is therefore considered an existing configuration issue and is **not part of the intended target configuration**.

Provisioning should not recreate it unless a later project requirement explicitly requires it.

---

## 6. Target Group Configuration

For the `add-vm` project, the intended configuration is:

```text
ROLE GROUPS

admin
└── admin1

developer
└── developer1

deploy
└── deploy1


RESOURCE GROUP

project
├── admin1
└── developer1
```

The following existing memberships are not part of the intended project configuration:

```text
developer → tamine
project   → tamine
devloper  → developer1
```

They are documented because they exist on the original VM, but they should not be reproduced blindly.

---

## 7. Group IDs

The project does not require fixed numeric GIDs.

The provisioning should create groups by name:

```text
admin
developer
deploy
project
```

and allow Debian to allocate the appropriate numeric GIDs.

The important properties are:

```text
group name
+
membership
+
permissions/authorization attached to the group
```

rather than the original numeric GID.

---

## 8. Stage 07 Conclusion

The existing VM contains:

```text
admin
developer
deploy
project
devloper
```

The target project configuration requires:

```text
admin
developer
deploy
project
```

with:

```text
admin
└── admin1

developer
└── developer1

deploy
└── deploy1

project
├── admin1
└── developer1
```

The existing `devloper` group and the additional `tamine` memberships are recorded as existing-state information, not as required configuration.

**Stage 07 — Groups: COMPLETE**
