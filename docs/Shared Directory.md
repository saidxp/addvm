# Stage 11 — Shared Directory

## 1. Goal

The project requires a shared directory named:

```text
01-talent
```

The directory will be created at:

```text
/home/soubaaiss/01-talent
```

The directory is a shared project resource.

The access model is:

```text
admin1      → read + write
developer1  → read + write
deploy1     → write only
```

The users `admin1` and `developer1` will access the directory through the `project` group.

`deploy1` will **not** be a member of the `project` group. Instead, `deploy1` will receive a specific ACL.

---

# 2. Access Model

The final model is:

```text
                    /home/soubaaiss/01-talent
                              │
                              │
                         group: project
                              │
                  ┌───────────┴───────────┐
                  │                       │
              admin1                  developer1
                RW                        RW

                              +
                         special ACL
                              │
                              ▼
                           deploy1
                              W
```

Therefore:

```text
admin1      → RW
developer1  → RW
deploy1     → W
others      → no access
```

Where:

```text
R = read
W = write
```

---

# 3. Resource Group

The group used for normal shared-project access is:

```text
project
```

The group contains:

```text
project
├── admin1
└── developer1
```

`deploy1` must **not** belong to this group because the group provides read/write access.

Expected group:

```text
project
├── admin1
└── developer1
```

---

# 4. Directory Ownership

The directory should be owned by:

```text
root:project
```

Therefore:

```text
owner → root
group → project
```

This keeps ownership separate from the users who work inside the directory.

The users receive access through the group and ACLs rather than becoming owners of the directory.

---

# 5. Directory Permissions

The base directory permissions should provide:

```text
owner → rwx
group → rwx
others → ---
```

The base mode is:

```bash
chmod 2770 /home/soubaaiss/01-talent
```

The `2` enables the setgid bit.

Therefore the expected mode is approximately:

```text
drwxrws---
```

The permission model is:

```text
root       → rwx
project    → rwx
others     → ---
```

Because `admin1` and `developer1` belong to `project`, they receive:

```text
rwx
```

on the directory.

---

# 6. Why Setgid Is Required

The shared directory uses the setgid bit.

```text
setgid
   ↓
new objects inherit the directory's group
   ↓
group = project
```

For example:

```text
developer1 creates:
    /home/soubaaiss/01-talent/app.txt
```

The new file should inherit:

```text
group = project
```

This prevents newly created files from becoming associated with an unrelated primary group.

The target directory mode is therefore:

```text
2770
```

---

# 7. Default ACL

Setgid controls the inherited group, but the project also requires predictable permissions for newly created objects.

A default ACL will therefore be configured on:

```text
/home/soubaaiss/01-talent
```

The default ACL for the project group should provide:

```text
project → rwx
```

The default ACL mask should allow the intended group permissions:

```text
mask → rwx
```

Conceptually:

```text
new object
     ↓
inherits group = project
     ↓
inherits project ACL
     ↓
admin1/developer1 retain shared read/write access
```

---

# 8. Deploy User — Write-Only Access

`deploy1` must not be added to:

```text
project
```

because that group provides read/write access.

Instead, `deploy1` receives a specific ACL.

The important distinction is:

### Directory

For a directory, write-only access requires:

```text
wx
```

because:

```text
w → create/delete/rename directory entries
x → traverse/enter the directory
```

Without `x`, directory write permission alone is not useful for normal entry creation.

Therefore the directory ACL for `deploy1` should be:

```text
user:deploy1:-wx
```

This means:

```text
deploy1
├── cannot list the directory
├── can enter/traverse it
└── can create/delete/rename entries where permitted
```

There is deliberately no `r` permission.

---

# 9. Deploy Access to New Files

New files created inside the directory should also receive a special default ACL for `deploy1`.

The intended file permission is:

```text
deploy1 → -w-
```

Meaning:

```text
read  → NO
write → YES
execute → NO
```

Therefore:

```text
new file
     │
     ├── admin1/developer1 → read + write
     │
     └── deploy1           → write only
```

This is different from the directory ACL.

```text
Directory:
deploy1 → wx

Files:
deploy1 → w
```

---

# 10. Parent Directory Traversal

The shared directory is located under:

```text
/home/soubaaiss
```

Users must be able to traverse the parent directory to reach:

```text
/home/soubaaiss/01-talent
```

If `/home/soubaaiss` is restrictive, the required users will receive only the necessary traversal permission through ACLs.

The intended permission is:

```text
admin1      → --x
developer1  → --x
deploy1     → --x
```

This does **not** give them permission to list the contents of `/home/soubaaiss`.

It only allows path traversal to the shared directory.

---

# 11. Target Structure

The final filesystem structure should be:

```text
/home/soubaaiss/
└── 01-talent/
    ├── owner: root
    ├── group: project
    ├── mode: 2770
    │
    └── ACL:
        ├── admin1      → RW
        ├── developer1  → RW
        └── deploy1     → W
```

---

# 12. Target Access Table

| User         | Group membership | Directory | Files |
| ------------ | ---------------- | --------: | ----: |
| `admin1`     | `project`        |       RWX |    RW |
| `developer1` | `project`        |       RWX |    RW |
| `deploy1`    | not in `project` |        WX |     W |
| other users  | none             |       --- |   --- |

The important distinction is:

```text
admin1
    ↓
project group
    ↓
normal shared access

developer1
    ↓
project group
    ↓
normal shared access

deploy1
    ↓
individual ACL
    ↓
write-only access
```

---

# 13. Commands to Be Implemented Later

These commands are **the target configuration**, not commands to execute during the discovery stage.

Create the directory:

```bash
mkdir -p /home/soubaaiss/01-talent
```

Set ownership:

```bash
chown root:project /home/soubaaiss/01-talent
```

Set base permissions and setgid:

```bash
chmod 2770 /home/soubaaiss/01-talent
```

Configure the default project ACL:

```bash
setfacl -m d:g:project:rwx /home/soubaaiss/01-talent
setfacl -m d:m:rwx /home/soubaaiss/01-talent
```

Configure deploy's directory ACL:

```bash
setfacl -m u:deploy1:-wx /home/soubaaiss/01-talent
```

Configure deploy's default file ACL:

```bash
setfacl -m d:u:deploy1:-w- /home/soubaaiss/01-talent
```

The exact resulting ACLs will be verified on the VM before these commands are placed into Vagrant provisioning.

---

# 14. Verification Requirements

The automated VM must eventually verify:

### Directory exists

```bash
test -d /home/soubaaiss/01-talent
```

### Ownership

```bash
stat -c '%U:%G' /home/soubaaiss/01-talent
```

Expected:

```text
root:project
```

### Setgid

```bash
stat -c '%A' /home/soubaaiss/01-talent
```

Expected to contain:

```text
s
```

in the group-execute position.

### Group

```bash
getent group project
```

Expected members:

```text
admin1
developer1
```

and **not**:

```text
deploy1
```

### ACL

```bash
getfacl /home/soubaaiss/01-talent
```

The ACL must show:

```text
user:deploy1:-wx
```

and the corresponding default ACL for new files.

---

# 15. Access Tests

The final verification should test the actual behavior rather than only checking configuration text.

### Admin

`admin1` must be able to:

```text
create
read
modify
delete
```

files in:

```text
/home/soubaaiss/01-talent
```

### Developer

`developer1` must be able to:

```text
create
read
modify
delete
```

files in:

```text
/home/soubaaiss/01-talent
```

### Deploy

`deploy1` must:

```text
NOT read files
CAN write files
```

and must not receive the read/write privileges provided by the `project` group.

### Other users

Users outside the access model must not receive access to the shared directory.

---

# 16. Provisioning Requirement

This stage will later be implemented by Vagrant provisioning.

The provisioning must be idempotent.

Running provisioning multiple times must not:

```text
create duplicate groups
break ACLs
change ownership incorrectly
remove required permissions
```

The desired flow is:

```text
Create project group if necessary
        ↓
Ensure admin1 is in project
        ↓
Ensure developer1 is in project
        ↓
Ensure deploy1 is NOT in project
        ↓
Create /home/soubaaiss/01-talent
        ↓
Set root:project ownership
        ↓
Set 2770 permissions
        ↓
Configure setgid
        ↓
Configure default ACLs
        ↓
Configure deploy1 write-only ACL
        ↓
Verify resulting access
```

---

# 17. Final Security Model

```text
                     01-talent
                         │
                  root:project
                         │
                    mode 2770
                         │
             ┌───────────┴───────────┐
             │                       │
          project                  ACL
             │                       │
       ┌─────┴─────┐                 │
       │           │                 │
    admin1      developer1        deploy1
       │           │                 │
       RW          RW                W
                                     │
                              no read permission
```

The key rule is:

```text
admin1      → RW
developer1  → RW
deploy1     → W
```

`project` is the **read/write resource group**.

`deploy1` receives its restricted access through an **individual ACL**, not through the group.

**Stage 11 design complete.**

**Next: implement and verify the directory on the reference VM, then document the exact final state before writing Vagrant provisioning.**
