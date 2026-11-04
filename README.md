# Reproducible Debian Server Vagrant Project

This repository implements a fully reproducible, automated Debian server project based on the specifications documented across Stages 01 through 20.

---

## 1. Project Architecture

The chosen architecture separates operating system foundation from project configuration:

```text
Clean Debian Base Box (Debian 13 Trixie / amd64)
      ↓
Oracle VirtualBox Provider
      ↓
Vagrant VM Lifecycle
      ↓
Vagrant Shell Provisioner (provision/provision.sh)
      ↓
Automated Server Configuration & Access Control
      ↓
Verification (verify.sh)
```

- **Base Box:** Provides the clean Debian OS, Linux kernel, base storage layout, and Vagrant SSH management.
- **Provisioning:** Idempotently configures packages, users, role groups, resource group, sudo policies, password aging, PAM/faillock, shared project directory, permissions, setgid, ACLs, sticky-bit scratch directory, systemd monitoring service, and SSH security policies.

---

## 2. Directory Structure

```text
.
├── Vagrantfile               # Vagrant VM orchestration and provider configuration
├── debian13.box              # Local Debian Base Box package
├── verify.sh                 # Verification script (checks configuration & behavioral rules)
├── README.md                 # Project documentation and architectural reconciliation matrix
├── keys/                     # Public SSH keys installed onto the server
│   ├── admin1.pub
│   ├── developer1.pub
│   └── deploy1.pub
├── systemd/                  # Monitoring service unit and script source files
│   ├── myservice.service
│   └── myservice.sh
└── provision/                # Deterministic, modular provisioning scripts
    ├── provision.sh          # Main orchestration entry point
    ├── packages.sh           # Stage 04: Package installation (sudo, acl, openssh-server, lvm2)
    ├── users.sh              # Stage 06: Idempotent user creation (admin1, developer1, deploy1)
    ├── groups.sh             # Stage 07: Role groups (admin, developer, deploy) & resource group (project)
    ├── sudo.sh               # Stage 08: Sudo policies under /etc/sudoers.d/ (mode 0440)
    ├── password.sh           # Stage 09: Password aging policy (90-day maximum lifetime)
    ├── pam.sh                # Stage 10: PAM faillock policy (deny=3, fail_interval=60, unlock_time=60)
    ├── filesystem.sh         # Stage 11: Parent directory traversal ACLs & shared directory creation
    ├── permissions.sh        # Stage 12: Ownership (root:project), mode 2770, and setgid
    ├── acl.sh                # Stage 13: Deploy1 read-only ACL & default ACL inheritance
    ├── sticky.sh             # Stage 14: Sticky-bit scratch directory (mode 1777)
    ├── systemd.sh            # Stage 05: Installation and activation of myservice.service
    └── ssh.sh                # Stages 15/16: Public key installation and SSH server hardening
```

---

## 3. Quick Start & Execution Commands

### Add Local Base Box (if not already added)

```bash
vagrant box add debian13-local debian13.box
```

### Build and Provision the VM

```bash
vagrant up
```

### Re-run Provisioning (Idempotency Test)

```bash
vagrant provision
```

### Destroy and Rebuild

```bash
vagrant destroy -f
vagrant up
```

### Execute Verification Checks inside the VM

```bash
vagrant ssh -c "sudo /vagrant/verify.sh"
```

---

## 4. Reconciled Specification & Verifier Inconsistencies

During Phase 1 (Inspection) and Phase 2 (Reconciliation), the following discrepancies in historical markdown files and old verifier logic were detected and resolved:

| Feature / Topic | Historical Markdown / Old Verifier Issue | Authoritative Decision / Implementation | Rationale |
| :--- | :--- | :--- | :--- |
| **Password Aging** | Old `verify.sh` checked `soubaaiss` for 1-day max age (`EXPECTED_MAX_DAYS=1`). | Applied 90 days (`chage -M 90`) to `admin1`, `developer1`, `deploy1`. | Stage 09 & prompt Section 18 explicitly define 90-day max age for the 3 project accounts. |
| **Shared Directory Mode** | Stage 12 noted an old reference observation of mode `2777`. | Configured mode `2770` (`drwxrws---`) with group `project`. | Stage 11, Stage 17, and prompt Section 22/24 explicitly require `2770` for security boundaries. |
| **Obsolete Group** | Stage 06/07 noted a misspelled group `devloper` and user `tamine` on reference VM. | Created role group `developer` containing `developer1`. Excluded `devloper` and `tamine`. | Misspellings and extra users are historical VM issues, not project requirements. |
| **Scratch Directory Path** | Stage 14 & verifier contained spelling `scrath` / `scrathc`. | Primary path set to `/home/soubaaiss/test/scratch` with mode `1777` (and compat path). | Prompt Section 27 requires consistent scratch path across provisioning, verification, and docs. |
| **Deploy1 Group Membership**| Deploy1 must not have write access to shared project directory. | `deploy1` belongs ONLY to `deploy` group, receiving read/traverse access via ACL (`u:deploy1:rx`). | Prevents `deploy1` from inheriting group `project` write permissions. |
| **Sudo Permissions** | Sudoers files must have restricted mode `0440`. | `/etc/sudoers.d/{admin,developer,deploy}` created with mode `0440` and validated with `visudo -c`. | Satisfies security standards and visudo validation. |
| **PAM Faillock State** | Old verifier expected existing failure records for user `soubaaiss`. | Configured `/etc/security/faillock.conf` and PAM stack; no artificial failure records injected. | Clean reproducible VMs must not depend on pre-existing login failure records. |
| **Shared Directory Test** | Old verifier set `TEST_FILE="$PROJECT_DIR"` treating directory as file. | Verifier updated to create a real test file inside the shared directory for access/setgid tests. | Ensures valid behavioral testing of setgid and ACL inheritance. |

---

## 5. Verification Results

Running `./verify.sh` verifies:
- Account creation & group memberships (`admin1`, `developer1`, `deploy1`, `admin`, `developer`, `deploy`, `project`).
- Sudo rule syntax (`visudo -c`) & restricted privileges (`sudo -l -U`).
- 90-day password expiration policy (`chage -l`).
- PAM `faillock.conf` policy & PAM module configuration.
- Shared directory ownership (`root:project`), mode (`2770`), setgid bit, and ACL inheritance.
- Sticky-bit scratch directory mode (`1777`) and deletion denial behavior.
- Systemd monitoring service status (`active (running)`, `enabled`, `Restart=always`).
- SSH server configuration (`sshd -t`, `PubkeyAuthentication yes`, `PasswordAuthentication no`).
- Behavioral access tests (setgid group inheritance, deploy1 read-only ACL, sticky-bit deletion protection).
