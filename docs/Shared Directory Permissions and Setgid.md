# Stage 12 — Shared Directory Permissions and Setgid

## 1. Goal

The shared directory created in Stage 11 is:

```text
/home/soubaaiss/test
```

It is owned by:

```text
root:project
```

The directory uses mode `2777` to enable setgid and grant read, write, and execute permissions to the owner, group, and others.

The purpose of this stage is to understand the permission bits and document the configuration that will later be reproduced through Vagrant provisioning.

---

## 2. Directory Ownership

The directory ownership is:

```text
Owner: root
Group: project
```

The `project` group is used by `admin1` and `developer1` for shared access.

Ownership can be inspected with:

```bash
ls -ld /home/soubaaiss/test
```

---

## 3. Understanding Mode `2777`

The command used to configure the directory is:

```bash
chmod 2777 /home/soubaaiss/test
```

The mode is composed of four digits:

```text
2 7 7 7
│ │ │ └── Others: rwx
│ │ └──── Group:  rwx
│ └────── Owner:  rwx
└──────── Setgid
```

### Permission breakdown

| Permission | Meaning                              |
| ---------- | ------------------------------------ |
| `2`        | Setgid bit                           |
| First `7`  | Owner has read, write, and execute   |
| Second `7` | Group has read, write, and execute   |
| Third `7`  | Others have read, write, and execute |

The expected permission string is:

```text
drwxrwsrwx
```

The `s` in the group-execute position indicates that setgid is enabled.

---

## 4. What Setgid Does

Setgid on a directory causes newly created files and subdirectories to inherit the directory's group rather than simply using the creating user's primary group.

For example:

```text
developer1 creates app.txt
             ↓
       shared directory
             ↓
       setgid enabled
             ↓
       group = project
```

This helps keep shared files associated with the `project` group.

Setgid does not, by itself, guarantee that group members can write to every new file. The resulting file permissions also depend on the creation mode, ACLs, and other permission settings.

---

## 5. Important Security Consideration

Mode `2777` grants permissions to **all users** at the basic filesystem-permission level.

That means users outside the intended project roles can also receive read, write, and execute permissions unless additional access controls restrict them.

This differs from the more restrictive mode `2770`:

| Mode   | Owner | Group | Others |
| ------ | ----- | ----- | ------ |
| `2777` | RWX   | RWX   | RWX    |
| `2770` | RWX   | RWX   | None   |

The project’s intended access model from Stage 11 is:

```text
admin1      → read/write
developer1  → read/write
deploy1     → restricted write access
other users → no access
```

Therefore, the final Vagrant configuration must consider the ACLs and the intended security boundaries, not just the numeric mode.

---

## 6. Verify the Permission Bits

Inspect the directory:

```bash
ls -ld /home/soubaaiss/test
```

Inspect the numeric mode:

```bash
stat -c '%a' /home/soubaaiss/test
```

Inspect the owner and group:

```bash
stat -c '%U:%G' /home/soubaaiss/test
```

Inspect ACL entries:

```bash
getfacl /home/soubaaiss/test
```

These commands provide different information:

* `ls -ld` shows the human-readable permissions.
* `stat` reports the numeric mode and ownership.
* `getfacl` reveals additional access-control entries and default ACLs.

---

## 7. Reference VM Observation

The directory was inspected with:

```bash
ls -ld /home/soubaaiss/test
```

Observed output:

```text
drwxrwx--T+ 3 root project 4096 Sep 28 13:25 /home/soubaaiss/test
```

This output does **not** represent mode `2777`.

It indicates:

* `root` is the owner.
* `project` is the group.
* The sticky bit is enabled.
* The setgid bit is not visible.
* Additional ACL entries exist, indicated by `+`.
* The permissions differ from the documented `2777` target.

The exact current mode and ACLs must be inspected before deciding which settings the automated VM should reproduce.

---

## 8. Provisioning Requirement

When implementing this stage in Vagrant, provisioning must:

1. Create the shared directory if it does not exist.
2. Set ownership to `root:project`.
3. Apply the selected permission mode.
4. Configure setgid if required.
5. Apply the ACL policy from Stage 11.
6. Verify the resulting permissions and access behavior.

The provisioning must be idempotent: running it more than once must produce the same intended state.

**Stage 12 — Permission model documented.**

**Next: inspect the complete ACL and confirm the final access policy before implementing it in Vagrant.**
