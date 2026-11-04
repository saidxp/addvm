# Stage 14 — Sticky Bit Scratch Directory

## 1. Goal

The project contains a separate scratch directory:

```text
/home/soubaaiss/test/scrathc
```

The directory is intended to be writable by multiple users while preventing users from deleting or renaming files owned by other users.

This behavior is provided by the **sticky bit**.

---

## 2. Inspect the Directory

The directory was inspected with:

```bash
ls -ld /home/soubaaiss/test/scrathc
```

The reference VM returned:

```text
drwxrwxrwt+ 2 root root 4096 Sep 28 18:25 /home/soubaaiss/test/scrathc
```

The important permission string is:

```text
drwxrwxrwt+
```

---

## 3. Permission Breakdown

The directory permissions are:

```text
d rwx rwx rwx t
│ │   │   │   │
│ │   │   │   └── sticky bit
│ │   │   └────── others: rwx
│ │   └────────── group: rwx
│ └────────────── owner: rwx
└──────────────── directory
```

The normal numeric permission mode is:

```text
1777
```

Breakdown:

```text
1 → sticky bit
7 → owner rwx
7 → group rwx
7 → others rwx
```

The expected basic permission string is:

```text
drwxrwxrwt
```

The final:

```text
t
```

shows that the sticky bit is enabled.

---

## 4. Ownership

The reference directory is owned by:

```text
owner = root
group = root
```

This was shown by:

```text
# owner: root
# group: root
```

The `project` group is not the owning group of this scratch directory.

This is separate from the shared project directory.

---

## 5. What the Sticky Bit Does

The directory is writable by multiple users:

```text
owner  → rwx
group  → rwx
others → rwx
```

Without the sticky bit, a user with write permission on the directory could generally remove or rename entries created by another user.

The sticky bit changes this behavior.

For example:

```text
developer1 creates developer.txt
             ↓
        scratch directory
             ↓
deploy1 tries to delete developer.txt
             ↓
             DENIED
```

The sticky bit restricts deletion and renaming of directory entries so that an ordinary user cannot remove another user's files merely because the directory is writable.

The directory owner and privileged users retain the corresponding administrative ability.

---

## 6. Access ACL

The complete ACL was inspected with:

```bash
getfacl /home/soubaaiss/test/scrathc
```

The reference VM returned:

```text
getfacl: Removing leading '/' from absolute path names
# file: home/soubaaiss/test/scrathc
# owner: root
# group: root
# flags: --t
user::rwx
user:deploy1:r-x
group::rwx
group:project:rwx
mask::rwx
other::rwx
```

The access ACL therefore contains:

```text
root        → rwx
deploy1     → r-x
group root  → rwx
project     → rwx
others      → rwx
mask        → rwx
```

---

## 7. Named ACL for deploy1

The directory contains:

```text
user:deploy1:r-x
```

This explicitly gives `deploy1`:

```text
r → read/list
x → traverse/enter
w → not granted
```

Therefore:

```text
deploy1 → r-x
```

This named-user ACL is separate from the sticky-bit behavior.

The sticky bit controls deletion/renaming behavior.

The ACL controls access permissions.

---

## 8. Named ACL for project

The directory also contains:

```text
group:project:rwx
```

This grants the `project` group:

```text
rwx
```

Therefore users belonging to `project` receive the corresponding ACL permissions when accessing the scratch directory.

This is independent of the directory's owning group:

```text
owner group = root
named ACL group = project
```

So:

```text
root
    ↓
owning group

project
    ↓
named ACL group
```

---

## 9. ACL Mask

The access ACL contains:

```text
mask::rwx
```

The mask limits the effective permissions of named users and groups and the owning group.

Because the mask is:

```text
rwx
```

the ACL entries are not reduced by the mask.

---

# 10. Default ACL

The scratch directory also has a default ACL.

The reference VM returned:

```text
default:user::rwx
default:user:deploy1:r-x
default:group::rwx
default:group:project:rwx
default:mask::rwx
default:other::r-x
```

The default ACL is an inheritance policy for objects created inside the scratch directory.

It is separate from the sticky bit.

---

## 11. Default ACL Model

The observed default ACL is:

```text
default:user::rwx
default:user:deploy1:r-x
default:group::rwx
default:group:project:rwx
default:mask::rwx
default:other::r-x
```

Conceptually:

```text
new object
    │
    ├── owner class → rwx
    ├── deploy1     → r-x
    ├── group class → rwx
    ├── project     → rwx
    ├── mask        → rwx
    └── other       → r-x
```

The actual permissions of a newly created object are still affected by the object's creation mode and filesystem ACL rules.

---

# 12. Sticky Bit vs ACL

These mechanisms solve different problems.

```text
Sticky bit
    ↓
controls deletion / renaming of entries
```

```text
Access ACL
    ↓
controls who can access the directory
```

```text
Default ACL
    ↓
controls ACL inheritance for new objects
```

They can therefore exist together:

```text
scratch directory
       │
       ├── sticky bit
       │      ↓
       │   protects entries
       │
       ├── access ACL
       │      ↓
       │   current access
       │
       └── default ACL
              ↓
         inherited access
```

---

# 13. Why `+` Appears in `ls`

The output was:

```text
drwxrwxrwt+
```

The final:

```text
+
```

means additional ACL entries exist beyond the traditional owner/group/other permission model.

This is confirmed by:

```bash
getfacl /home/soubaaiss/test/scrathc
```

which shows the named entries for:

```text
deploy1
project
```

and the default ACL.

---

# 14. Verification Commands

Check the permission string:

```bash
ls -ld /home/soubaaiss/test/scrathc
```

Check the numeric mode:

```bash
stat -c '%a' /home/soubaaiss/test/scrathc
```

Check ownership:

```bash
stat -c '%U:%G' /home/soubaaiss/test/scrathc
```

Inspect the access ACL:

```bash
getfacl --access /home/soubaaiss/test/scrathc
```

Inspect the default ACL:

```bash
getfacl --default /home/soubaaiss/test/scrathc
```

Inspect everything:

```bash
getfacl /home/soubaaiss/test/scrathc
```

---

# 15. Provisioning Requirements

The future Vagrant provisioning must reproduce the required scratch-directory behavior.

The target directory will be created under the final project path.

The provisioning must:

1. Create the scratch directory.
2. Set the required owner and group.
3. Apply the required writable directory permissions.
4. Enable the sticky bit.
5. Apply the required access ACL entries.
6. Apply the required default ACL entries.
7. Verify the resulting mode and ACL.

The provisioning must be idempotent.

Running the provisioning multiple times must produce the same intended state.

---

# 16. Final Reference Configuration

The reference VM currently has:

```text
Path:
    /home/soubaaiss/test/scrathc

Owner:
    root

Group:
    root

Basic mode:
    1777

Sticky bit:
    enabled
```

Access ACL:

```text
user::rwx
user:deploy1:r-x
group::rwx
group:project:rwx
mask::rwx
other::rwx
```

Default ACL:

```text
default:user::rwx
default:user:deploy1:r-x
default:group::rwx
default:group:project:rwx
default:mask::rwx
default:other::r-x
```

The important security concept is:

```text
1777
  ↓
everyone can use the directory

sticky bit
  ↓
users cannot normally delete/rename each other's entries

ACL
  ↓
specific users/groups receive additional access

default ACL
  ↓
new objects inherit the defined ACL entries
```

**Stage 14 — Sticky-bit scratch directory documented.**

**Next: Stage 15 — inspect the SSH server configuration.**
