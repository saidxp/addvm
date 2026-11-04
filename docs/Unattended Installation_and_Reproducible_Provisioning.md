# Stage 18 — Unattended Installation and Reproducible Provisioning

## 1. Goal

The server must be reproducible without manually configuring Debian after every new VM creation.

The target workflow is:

```text
vagrant destroy -f
        ↓
vagrant up
        ↓
Debian Vagrant Base Box
        ↓
automatic provisioning
        ↓
complete server configuration
        ↓
verification
        ↓
PASS
```

The goal is that the required `linux` and `login` configuration can be recreated automatically.

---

## 2. Chosen Approach

There are two possible meanings of unattended installation:

```text
A. Automate the Debian Installer
   → Preseed / automated ISO installation

B. Start from a Debian Vagrant Base Box
   → automatically configure the server with provisioning
```

For this project, we choose:

```text
Debian Vagrant Base Box
        +
Vagrant Provisioning
```

We are therefore **not** automating the Debian Installer itself.

The Debian operating system is provided by the Vagrant base box.

The project-specific server configuration is created by provisioning.

---

## 3. Base Box Responsibility

The Base Box provides the initial Debian environment.

Conceptually:

```text
Base Box
   ↓
Debian
   ↓
Kernel
   ↓
Basic filesystem
   ↓
Vagrant SSH access
```

The Base Box should provide a clean operating-system foundation.

It should not contain our project-specific configuration.

The following must be created by provisioning:

```text
admin1
developer1
deploy1

admin
developer
deploy
project

sudo policies
password aging
PAM/faillock
shared directories
permissions
setgid
ACL
sticky bit
systemd service
SSH project configuration
authorized_keys
```

---

## 4. Provisioning Responsibility

Provisioning transforms the clean Base Box into the required server.

```text
Clean Debian Base Box
        ↓
Vagrant Provisioning
        ↓
Required Server
```

Provisioning is responsible for configuring:

```text
Packages
Users
Groups
Sudo
Password aging
PAM
Filesystem
Permissions
Setgid
ACL
Sticky bit
Systemd
SSH
```

---

## 5. No Manual Server Configuration

After the project is completed, a new VM must not require manual configuration for the required server state.

The following must be automated:

```text
Create users
Create groups
Install required packages
Configure sudo
Configure password aging
Configure PAM
Create directories
Set ownership
Set permissions
Enable setgid
Configure ACLs
Enable sticky bit
Install systemd service
Enable systemd service
Configure SSH
Install public keys
```

The user should only need to start the build process:

```bash
vagrant up
```

---

## 6. Unattended Does Not Mean Everything Is Automated

The word **unattended** in this project means:

> The server configuration can be applied without manually entering configuration commands.

It does not necessarily mean that the Debian Installer itself must be automated.

Our selected architecture is:

```text
Debian installation
        ↓
provided by Base Box

Server configuration
        ↓
provided by Provisioning

Verification
        ↓
provided by verify.sh
```

---

## 7. Idempotent Provisioning

The provisioning must be idempotent.

This means running provisioning more than once should leave the machine in the same intended final state.

For example:

```text
User already exists
        ↓
do not fail

Group already exists
        ↓
do not fail

Directory already exists
        ↓
apply required ownership and permissions

Configuration already exists
        ↓
ensure required content/state
```

The important property is:

```text
same input
    ↓
same final server state
```

---

## 8. Dynamic Values

Provisioning must not depend on values that naturally change between machines.

Examples of values that must not be hard-coded as project requirements:

```text
Machine ID
Boot ID
MAC address
Current DHCP IP
Current gateway
Current kernel build
```

Instead, the provisioning should reproduce the required behavior.

For example:

```text
Network → DHCP
```

rather than:

```text
192.168.11.245
```

---

## 9. Rebuild Requirement

The most important reproducibility test is:

```bash
vagrant destroy -f
vagrant up
```

The new VM must contain the complete required configuration again.

The result must be equivalent to the configured reference server for all project requirements.

The verification process must then be able to check the resulting server.

---

## 10. Verification

The verification script has a separate responsibility.

It does not configure the machine.

Instead:

```text
Provisioning
    ↓
creates required state

verify.sh
    ↓
checks required state
```

The final workflow is:

```text
vagrant up
      ↓
provisioning
      ↓
server configured
      ↓
verify.sh
      ↓
PASS / FAIL
```

The verification script should test both:

```text
Configuration state
```

and:

```text
Actual behavior
```

---

## 11. Private SSH Keys

The user's private SSH keys are **not** part of the VM provisioning.

The private key stays on the client:

```text
~/.ssh/id_ed25519
```

Only the public key is installed on the server:

```text
~/.ssh/id_ed25519.pub
        ↓
/home/USER/.ssh/authorized_keys
```

Therefore provisioning must never require a user's private key to be copied into the VM.

---

## 12. Separation of Responsibilities

The final architecture is:

```text
             BASE BOX
                 ↓
        Debian environment
                 ↓
          PROVISIONING
                 ↓
   ┌─────────────┼─────────────┐
   │             │             │
 users        security      services
   │             │             │
 groups       ACL / SSH     systemd
   │             │
   └─────────────┴─────────────┘
                 ↓
          LOGIN SERVER
                 ↓
             verify.sh
```

Each layer has a different responsibility:

```text
Base Box
    → initial Debian environment

Provisioning
    → configure the server

verify.sh
    → verify the final state
```

---

## 13. Future Repository Structure

The exact repository structure will be finalized during the Vagrant and provisioning design stages.

The intended structure is conceptually:

```text
project/
├── Vagrantfile
├── provision/
│   ├── packages.sh
│   ├── users.sh
│   ├── groups.sh
│   ├── sudo.sh
│   ├── security.sh
│   ├── filesystem.sh
│   ├── systemd.sh
│   └── ssh.sh
└── verify.sh
```

This is a design direction, not yet the final implementation.

---

## 14. Final Installation Flow

The final automated workflow will be:

```text
1. Vagrant selects the Debian Base Box
          ↓
2. VirtualBox creates the VM
          ↓
3. Debian starts
          ↓
4. Vagrant connects to the VM
          ↓
5. Provisioning installs required packages
          ↓
6. Provisioning creates users and groups
          ↓
7. Provisioning configures sudo and security
          ↓
8. Provisioning configures filesystem permissions
          ↓
9. Provisioning configures systemd
          ↓
10. Provisioning configures SSH
          ↓
11. Verification checks the final server
```

No manual server configuration should be required between these steps.

---

## 15. Final Decision

For this project:

```text
Unattended strategy
    ↓
Debian Vagrant Base Box
        +
Vagrant Provisioning
```

Therefore:

```text
Base Box
    → provides Debian

Provisioning
    → builds the required server

verify.sh
    → verifies the result
```

We will not use Preseed or build a custom Debian installer unless a later requirement makes that necessary.

**Stage 18 — unattended and reproducible installation strategy defined.**

**Next: Stage 19 — select the exact Vagrant provider and Debian Base Box.**
