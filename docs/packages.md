# Stage 04 — Packages

## 1. Purpose

This stage records only the packages that are explicitly required by the project.

Packages that are part of the normal Debian base system or required for basic booting are not listed here.

The goal is to distinguish:

```text
Package installation
        ↓
software required by the project

Configuration
        ↓
how that software is configured
```

Package installation and configuration are handled in separate stages.

---

## 2. Required Packages

The existing Debian VM contains the following project-required packages:

| Package          | Installed version    | Purpose                                |
| ---------------- | -------------------- | -------------------------------------- |
| `sudo`           | `1.9.16p2-3+deb13u2` | Privileged command authorization       |
| `acl`            | `2.3.2-2+b1`         | POSIX ACL configuration and management |
| `openssh-server` | `1:10.0p1-7+deb13u4` | SSH server                             |
| `lvm2`           | `2.03.31-2`          | LVM storage management                 |

The packages were verified with:

```bash
dpkg-query
```

through the project package collector:

```bash
./package.sh
```

The observed result was:

```text
sudo = 1.9.16p2-3+deb13u2
acl = 2.3.2-2+b1
openssh-server = 1:10.0p1-7+deb13u4
lvm2 = 2.03.31-2
```

---

## 3. Package vs Configuration

Installing a package does not reproduce its project configuration.

For example:

```text
sudo
  ↓
install sudo
  ↓
Stage 08
  ↓
configure /etc/sudoers.d/
```

Similarly:

```text
acl
  ↓
install acl
  ↓
Stage 13
  ↓
configure filesystem ACLs
```

And:

```text
openssh-server
  ↓
install OpenSSH server
  ↓
Stages 15–16
  ↓
configure sshd and authentication
```

For `lvm2`:

```text
lvm2
  ↓
provide LVM tools
  ↓
Stage 02
  ↓
storage layout
```

Therefore, the package stage does **not** contain sudo rules, ACL rules, SSH configuration, or storage configuration.

---

## 4. What Will Be Reproduced

During provisioning, these project dependencies must be available:

```text
sudo
acl
openssh-server
lvm2
```

Conceptually:

```bash
apt-get install -y sudo acl openssh-server lvm2
```

The actual provisioning implementation will be created later, after all stages have been documented.

The provisioning must also remain idempotent, so running it again must not unnecessarily break or duplicate the configuration.

---

## 5. What Is Not Recorded

The project does not record every package installed on Debian.

Packages that belong to the normal Debian base environment, boot process, or basic operating system functionality are not treated as project-specific dependencies unless the project explicitly requires them.

This keeps the `add-vm` specification focused on:

```text
What our project needs
```

rather than:

```text
Everything Debian happens to have installed
```

---

## 6. Stage 04 Conclusion

The project has four explicitly identified package dependencies:

```text
sudo
acl
openssh-server
lvm2
```

Their installation will eventually be handled by provisioning.

Their individual configuration will be handled by their respective project stages.

**Stage 04 — Packages: COMPLETE**
