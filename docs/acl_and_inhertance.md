# Stage 13 — ACL and Inheritance

## 1. Goal

The shared directory is:

```text
/home/soubaaiss/test
```

The purpose of this stage is to document the POSIX ACL configuration used by the reference VM.

ACLs provide more precise access control than the basic owner/group/other permission bits.

The project uses ACLs for:

* granting `deploy1` additional access without putting `deploy1` in the `project` group;
* defining permissions inherited by newly created files and directories.

---

## 2. Inspect the Current ACL

The ACL was inspected with:

```bash
getfacl /home/soubaaiss/test
```

The reference VM returned:

```text
getfacl: Removing leading '/' from absolute path names
# file: home/soubaaiss/test
# owner: root
# group: project
# flags: --t
user::rwx
user:deploy1:r-x
group::rwx
mask::rwx
other::---
default:user::rwx
default:user:deploy1:r-x
default:group::rwx
default:group:project:rwx
default:mask::rwx
default:other::r-x
```

The message:

```text
getfacl: Removing leading '/' from absolute path names
```

is normal. `getfacl` removes the leading `/` when displaying the `# file:` path.

---

## 3. Access ACL

The first part of the ACL controls access to the existing directory.

```text
user::rwx
user:deploy1:r-x
group::rwx
mask::rwx
other::---
```

### Owner

```text
user::rwx
```

The owner is:

```text
root
```

Therefore:

```text
root → rwx
```

---

### Named user: deploy1

```text
user:deploy1:r-x
```

This gives `deploy1`:

```text
r → read/list directory entries
x → enter/traverse directory
w → not allowed
```

Therefore:

```text
deploy1 → read + traverse
```

`deploy1` is not a member of the `project` group. The ACL provides this additional access directly to the user.

---

### Group

```text
group::rwx
```

The directory's group is:

```text
project
```

Therefore:

```text
project → rwx
```

The `project` group contains:

```text
admin1
developer1
```

So:

```text
admin1      → rwx through project
developer1  → rwx through project
```

---

### ACL mask

```text
mask::rwx
```

The ACL mask limits the effective permissions of:

* named users;
* named groups;
* the owning group.

Because the mask is:

```text
rwx
```

it does not reduce the requested permissions of the `project` group or `deploy1`.

---

### Other users

```text
other::---
```

Users who do not match the owner, named ACL, or group entries receive:

```text
---
```

Therefore:

```text
other users → no access
```

---

# 4. Access ACL Model

The current directory access model is:

```text
/home/soubaaiss/test
        │
        ├── root
        │     └── rwx
        │
        ├── project group
        │     ├── admin1
        │     └── developer1
        │
        │     └── rwx
        │
        ├── deploy1
        │     └── r-x
        │
        └── others
              └── ---
```

In simplified form:

```text
admin1      → RWX
developer1  → RWX
deploy1     → RX
others      → none
```

---

# 5. Default ACL

The directory also contains a default ACL:

```text
default:user::rwx
default:user:deploy1:r-x
default:group::rwx
default:group:project:rwx
default:mask::rwx
default:other::r-x
```

A default ACL is different from the normal access ACL.

The access ACL answers:

```text
Who can access this directory now?
```

The default ACL answers:

```text
What ACL entries should new objects inherit?
```

Default ACLs are only meaningful on directories because they provide inheritance rules for newly created files and subdirectories.

---

# 6. Default Owner Entry

```text
default:user::rwx
```

This is the default permission for the owner class of newly created objects.

It does not mean that every new file becomes owned by `root`.

The actual owner of a newly created file is still the user who creates it.

The default ACL controls the inherited permission entry.

---

# 7. Default deploy1 Entry

```text
default:user:deploy1:r-x
```

New objects inherit an ACL entry for:

```text
deploy1
```

with:

```text
r-x
```

So the reference VM intends `deploy1` to retain read/traverse access through inheritance.

---

# 8. Default Group Entry

```text
default:group::rwx
```

New objects inherit the permissions associated with the owning group class.

Because the directory uses:

```text
group = project
```

the shared group receives the intended shared permissions.

---

# 9. Default Named Group Entry

The reference VM also contains:

```text
default:group:project:rwx
```

This explicitly gives the `project` group:

```text
rwx
```

in the default ACL.

Therefore new objects inherit a named ACL entry for:

```text
project
```

with:

```text
rwx
```

---

# 10. Default ACL Mask

```text
default:mask::rwx
```

The default mask limits the effective permissions of inherited named users and groups.

Because it is:

```text
rwx
```

the inherited `project` and `deploy1` entries are not reduced by the mask.

---

# 11. Default Other Entry

The reference VM contains:

```text
default:other::r-x
```

This means newly created objects inherit:

```text
other → r-x
```

subject to the final mode and ACL behavior of the created object.

This is different from the access ACL of the directory itself:

```text
other::---
```

Therefore we must distinguish:

```text
Access ACL
    other → ---

Default ACL
    other → r-x
```

This difference is intentional in the observed reference configuration and must be preserved in the specification unless the assignment requires a different security policy.

---

# 12. Setgid + ACL

The directory also has the setgid bit.

The two mechanisms have different responsibilities:

```text
setgid
   ↓
new objects inherit group = project
```

while:

```text
default ACL
   ↓
new objects inherit ACL permissions
```

Therefore:

```text
developer1 creates file
        │
        ├── setgid
        │      ↓
        │   group = project
        │
        └── default ACL
               ↓
        inherited ACL entries
```

Setgid and default ACL solve different problems and can be used together.

---

# 13. ACL Verification Commands

Inspect the complete ACL:

```bash
getfacl /home/soubaaiss/test
```

Inspect only the access ACL:

```bash
getfacl --access /home/soubaaiss/test
```

Inspect only the default ACL:

```bash
getfacl --default /home/soubaaiss/test
```

These commands make it easier to distinguish:

```text
access ACL
```

from:

```text
default ACL
```

---

# 14. Provisioning Requirements

The future Vagrant provisioning must reproduce the required ACL state.

The target directory will eventually be:

```text
/home/soubaaiss/01-talent
```

rather than the current reference directory:

```text
/home/soubaaiss/test
```

The provisioning must:

1. Create the directory.
2. Set ownership to `root:project`.
3. Configure the required base permissions.
4. Enable setgid.
5. Apply the access ACL.
6. Apply the default ACL.
7. Preserve the required ACL mask.
8. Verify the resulting ACL.

The provisioning must be idempotent.

Running it multiple times must produce the same final state.

---

# 15. Important Distinction

The project uses three different mechanisms:

```text
Basic permissions
        ↓
owner / group / other


Setgid
        ↓
inherit the directory's group


ACL
        ↓
grant specific users/groups additional permissions


Default ACL
        ↓
inherit ACL permissions to new objects
```

They are not interchangeable.

---

## Final ACL Model

The reference VM currently implements:

```text
DIRECTORY ACCESS

root        → rwx
project     → rwx
deploy1     → r-x
others      → ---
```

And inheritance:

```text
NEW OBJECTS

owner class → rwx
deploy1     → r-x
project     → rwx
other       → r-x
mask        → rwx
```

**Stage 13 — ACL inspection and design documented.**

**Next: Stage 14 — inspect the sticky-bit directory and document its purpose and exact permissions.**
