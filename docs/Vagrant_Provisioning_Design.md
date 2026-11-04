# Stage 20 — Vagrant Provisioning Design

## 1. Goal

The purpose of provisioning is to transform the clean Debian Base Box into the final server required by the project.

The Base Box provides:

```text
Debian 13
amd64
VirtualBox-compatible VM
SSH access for Vagrant
base filesystem/storage layout
```

Provisioning provides:

```text
project users
project groups
sudo authorization
password aging
PAM failed-login protection
shared filesystem access
permissions
setgid
ACLs
sticky bit
systemd service
project SSH configuration
```

The final objective is:

```text
vagrant destroy -f
        ↓
vagrant up
        ↓
new VM from the same Base Box
        ↓
provisioning runs
        ↓
same final server configuration
```

No manual project configuration should be required after `vagrant up`.

---

# 2. Provisioning Architecture

The project will use one main provisioning entry point:

```text
Vagrantfile
    ↓
provision/provision.sh
    ↓
individual provisioning scripts
```

The planned structure is:

```text
login/
├── Vagrantfile
├── debian13.box
├── provision/
│   ├── provision.sh
│   ├── packages.sh
│   ├── users.sh
│   ├── groups.sh
│   ├── sudo.sh
│   ├── password.sh
│   ├── pam.sh
│   ├── filesystem.sh
│   ├── permissions.sh
│   ├── acl.sh
│   ├── sticky.sh
│   ├── systemd.sh
│   └── ssh.sh
└── README.md
```

The exact number of scripts may be reduced if two closely related configuration stages are better kept together.

The important requirement is a clear separation of responsibilities.

---

# 3. Vagrantfile

The Vagrantfile is the entry point for the VM lifecycle.

Its responsibilities are:

```text
choose the Base Box
        ↓
choose VirtualBox
        ↓
configure VM resources
        ↓
configure Vagrant networking
        ↓
start the VM
        ↓
run provisioning
```

Conceptually:

```ruby
Vagrant.configure("2") do |config|

  config.vm.box = "debian13-local"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.provision "shell",
    path: "provision/provision.sh"

end
```

The exact box name and VM resource values will be finalized during implementation.

---

# 4. Provisioning Entry Point

The main script is:

```text
provision/provision.sh
```

Its job is orchestration.

It should:

1. stop immediately when a required command fails;
2. execute provisioning stages in a deterministic order;
3. avoid duplicating configuration logic;
4. call each specialized script once.

Conceptually:

```bash
#!/bin/bash
set -e

bash /vagrant/provision/packages.sh
bash /vagrant/provision/users.sh
bash /vagrant/provision/groups.sh
bash /vagrant/provision/sudo.sh
bash /vagrant/provision/password.sh
bash /vagrant/provision/pam.sh
bash /vagrant/provision/filesystem.sh
bash /vagrant/provision/permissions.sh
bash /vagrant/provision/acl.sh
bash /vagrant/provision/sticky.sh
bash /vagrant/provision/systemd.sh
bash /vagrant/provision/ssh.sh
```

The final script order may be adjusted when dependencies between stages are implemented.

---

# 5. Provisioning Order

The final logical order is:

```text
Base Box
   ↓
packages
   ↓
users
   ↓
groups
   ↓
sudo
   ↓
password aging
   ↓
PAM / faillock
   ↓
filesystem
   ↓
permissions / setgid
   ↓
ACL
   ↓
sticky bit
   ↓
systemd
   ↓
SSH
```

This order reflects dependencies.

For example:

```text
create project group
        ↓
give group ownership
        ↓
configure permissions
        ↓
configure ACL
```

The directory cannot receive a group that does not yet exist.

---

# 6. Idempotent Provisioning

The provisioning system must be idempotent.

Idempotent means:

```text
first run
    ↓
create/configure desired state

second run
    ↓
verify desired state
    ↓
do not break or duplicate it
```

Examples:

### User

Bad:

```bash
useradd admin1
```

without checking whether the user already exists.

Better:

```text
does admin1 exist?
    ↓
NO  → create it
YES → leave it in place
```

### Group

```text
does project exist?
    ↓
NO  → create it
YES → continue
```

### Directory

```text
does /home/soubaaiss/01-talent exist?
    ↓
NO  → create it
YES → continue
```

### Systemd

The script should be safe to run repeatedly:

```text
copy/update unit
    ↓
daemon-reload
    ↓
enable
    ↓
start/restart only when necessary
```

---

# 7. Package Provisioning

The Base Box should remain minimal.

The provisioning layer installs the packages required by the project:

```text
sudo
acl
openssh-server
lvm2
```

The package stage uses:

```bash
apt-get update
apt-get install -y sudo acl openssh-server lvm2
```

The package stage is responsible only for software installation.

It does not configure:

```text
sudoers
PAM
SSH keys
ACLs
systemd service
```

Those remain in their respective stages.

---

# 8. User Provisioning

The required users are:

```text
admin1
developer1
deploy1
```

Each must have:

```text
home directory
Bash shell
unique UID
```

Target:

```text
admin1      → /home/admin1 → /bin/bash
developer1  → /home/developer1 → /bin/bash
deploy1     → /home/deploy1 → /bin/bash
```

Creation logic:

```text
user exists?
    ↓
YES → verify required properties
NO  → create user
```

User passwords should not be hard-coded into repository scripts.

---

# 9. Group Provisioning

Role groups:

```text
admin
developer
deploy
```

Resource-access group:

```text
project
```

Target memberships:

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

`deploy1` must not belong to:

```text
project
```

because membership in `project` provides read/write filesystem access.

The accidental group:

```text
devloper
```

must not be reproduced in the final VM.

---

# 10. Sudo Provisioning

Sudo policies are stored under:

```text
/etc/sudoers.d/
```

The provisioning stage creates:

```text
/etc/sudoers.d/admin
/etc/sudoers.d/developer
/etc/sudoers.d/deploy
```

Policies:

### Developer

```text
%developer ALL=(root) /usr/bin/systemctl restart myservice.service
```

### Deploy

```text
%deploy ALL=(root) /usr/bin/systemctl restart myservice.service
```

### Admin

The admin role receives the explicitly required administrative capabilities:

```text
user management
package management
restart any service
```

Command paths must match the actual Debian installation.

The policy must be validated with:

```bash
visudo -c
```

and effective privileges checked with:

```bash
sudo -l -U admin1
sudo -l -U developer1
sudo -l -U deploy1
```

Sudoers files must have secure permissions such as:

```text
0440
```

---

# 11. Password Aging Provisioning

The project requires:

```text
maximum password lifetime = 90 days
```

Provisioning applies:

```bash
chage -M 90 admin1
chage -M 90 developer1
chage -M 90 deploy1
```

Verification:

```bash
chage -l admin1
chage -l developer1
chage -l deploy1
```

Target:

```text
Maximum number of days between password change : 90
```

This stage is independent from PAM failed-login protection.

---

# 12. PAM / Failed-Login Provisioning

The project uses:

```text
pam_faillock
```

Target policy:

```text
deny = 3
fail_interval = 60
unlock_time = 60
```

Meaning:

```text
3 failed attempts
       ↓
within 60 seconds
       ↓
account locked
       ↓
automatic unlock after 60 seconds
```

The provisioning stage must ensure:

```text
/etc/security/faillock.conf
```

contains the required policy and that PAM actually invokes:

```text
pam_faillock.so
```

The PAM configuration must contain the required authentication and account rules.

Verification:

```bash
grep -R "pam_faillock" /etc/pam.d/
faillock --user USER
```

The provisioning process must not depend on previous failed-login records.

A clean rebuilt VM should start with no failure records.

---

# 13. Storage Boundary

The original Debian installation uses:

```text
/dev/sda
    ├── EFI partition
    └── /dev/sda2
          ↓
         LVM PV
          ↓
         VG V0G
          ├── root
          ├── home
          ├── var
          └── swap
```

The project storage model intentionally leaves free space inside the volume group.

Conceptually:

```text
Physical Volume
      ↓
Volume Group
      ↓
Logical Volumes

VG
├── LV root
├── LV home
├── LV var
├── LV swap
└── FREE SPACE
```

For the selected Base Box architecture, the base Debian storage layout is part of the prepared Base Box.

Project provisioning must not accidentally destroy the existing LVM layout.

The important mental model remains:

```text
VG = pool

LV = allocation from that pool

free VG space = space still available for future allocation
```

Extending an LV and growing its filesystem are separate operations.

---

# 14. Shared Project Directory

The required shared directory is:

```text
/home/soubaaiss/01-talent
```

Target ownership:

```text
root:project
```

Target basic mode:

```text
2770
```

Therefore:

```text
owner → rwx
group → rwx
others → ---
setgid → enabled
```

Target access model:

```text
admin1      → read/write
developer1  → read/write
deploy1     → read/traverse
others      → no access
```

---

# 15. Parent Directory Traversal

The shared directory is under:

```text
/home/soubaaiss
```

If the parent directory prevents the project users from reaching it, the provisioning stage should grant only traversal permission with ACL:

```bash
setfacl -m u:admin1:--x /home/soubaaiss
setfacl -m u:developer1:--x /home/soubaaiss
setfacl -m u:deploy1:--x /home/soubaaiss
```

This is path traversal permission.

It does not make the parent directory a shared directory.

---

# 16. Setgid

The shared directory must use setgid:

```bash
chmod 2770 /home/soubaaiss/01-talent
```

Target mode:

```text
drwxrws---
```

Setgid causes newly created files and directories to inherit:

```text
group = project
```

Conceptually:

```text
developer1 creates file
        ↓
directory has setgid
        ↓
new file group = project
```

---

# 17. Default ACL

Setgid alone controls the inherited group.

The default ACL controls inherited permissions.

The shared directory should therefore receive:

```bash
setfacl -m d:g:project:rwx /home/soubaaiss/01-talent
setfacl -m d:u:deploy1:rx /home/soubaaiss/01-talent
setfacl -m d:m:rwx /home/soubaaiss/01-talent
```

The result is:

```text
new object
    ↓
project group receives shared access
    ↓
deploy1 inherits read/traverse access
```

Verification:

```bash
getfacl /home/soubaaiss/01-talent
```

---

# 18. Deploy Read-Only ACL

`deploy1` must not be added to the `project` group.

Instead:

```bash
setfacl -m u:deploy1:rx /home/soubaaiss/01-talent
```

This gives:

```text
r → read/list
x → enter/traverse
w → absent
```

Therefore:

```text
deploy1 can read
deploy1 cannot write
```

This special permission is implemented using an ACL rather than group membership.

---

# 19. Sticky-Bit Scratch Directory

The project also requires a separate scratch area.

Its purpose is different from the shared project directory.

Target concept:

```text
world writable
+
sticky bit
```

The final path must match the project requirement and verification script.

If the required path is:

```text
/home/soubaaiss/test/scratch
```

then provisioning should create it and apply:

```bash
mkdir -p /home/soubaaiss/test/scratch
chmod 1777 /home/soubaaiss/test/scratch
```

Target basic mode:

```text
drwxrwxrwt
```

The sticky bit means:

```text
developer1 creates file
        ↓
deploy1 tries to delete it
        ↓
deletion denied
```

The directory can remain world-writable while preventing users from deleting one another's files merely because they can write to the directory.

The exact final scratch path must be kept consistent between:

```text
provisioning
verification
README
```

---

# 20. Systemd Service Provisioning

The project systemd unit is:

```text
/etc/systemd/system/myservice.service
```

Target unit:

```ini
[Unit]
Description=My system monitoring service

[Service]
ExecStart=/usr/local/bin/myservice.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

The monitoring script is:

```text
/usr/local/bin/myservice.sh
```

Provisioning must:

```text
copy script
    ↓
make executable
    ↓
install unit
    ↓
daemon-reload
    ↓
enable service
    ↓
start service
```

Commands:

```bash
chmod +x /usr/local/bin/myservice.sh

systemctl daemon-reload
systemctl enable myservice.service
systemctl start myservice.service
```

Verification:

```bash
systemctl status myservice.service --no-pager
systemctl is-enabled myservice.service
journalctl -u myservice.service --no-pager
```

Target:

```text
Active: active (running)
enabled
```

The monitoring output remains dynamic.

Provisioning should reproduce the service configuration, not hard-code the output of commands such as:

```text
date
uptime
df
free
ip
```

---

# 21. Restart Policy

The service uses:

```ini
Restart=always
RestartSec=5
```

This behavior must be preserved.

Provisioning should not replace it with:

```text
Restart=on-failure
```

because that changes the required service behavior.

Verification can be performed with:

```bash
systemctl show -p MainPID --value myservice.service
```

followed by terminating the process and checking that systemd starts a new instance.

---

# 22. SSH Server Provisioning

The Base Box already provides the SSH access required by Vagrant.

This is separate from the project's final SSH authentication configuration.

There are two SSH concepts:

```text
Vagrant SSH
    ↓
used by Vagrant to provision the VM
```

and:

```text
Project SSH
    ↓
used by admin1/developer1/deploy1
```

Provisioning must not confuse the two.

The project SSH server configuration must result in:

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
```

The effective configuration can be checked with:

```bash
sshd -T
```

Syntax must be validated with:

```bash
sshd -t
```

Then:

```bash
systemctl reload ssh
```

---

# 23. Project SSH Keys

Each project user requires:

```text
/home/admin1/.ssh/authorized_keys
/home/developer1/.ssh/authorized_keys
/home/deploy1/.ssh/authorized_keys
```

Target permissions:

```text
.ssh              → 700
authorized_keys   → 600
```

Target ownership:

```text
admin1      → admin1
developer1  → developer1
deploy1     → deploy1
```

The private SSH keys must never be copied into the VM.

The private keys remain on the client.

The server receives only public keys.

---

# 24. Public Keys and Reproducibility

Because provisioning must be reproducible, the project must decide where the authorized public keys come from.

Acceptable project-owned input:

```text
public key files
```

For example:

```text
keys/
├── admin1.pub
├── developer1.pub
└── deploy1.pub
```

The provisioning script can install these public keys into the corresponding users' `authorized_keys`.

Private keys must never be placed in:

```text
Git
Vagrantfile
provision/
Base Box
server
```

Only public keys may be stored in the repository when appropriate.

---

# 25. Vagrant SSH vs Project SSH

Vagrant needs its own SSH mechanism to provision the VM.

Therefore:

```text
Vagrant connection
    ≠
project user authentication
```

During:

```bash
vagrant up
```

Vagrant first establishes its own connection.

Then:

```text
Vagrant SSH
      ↓
provisioning
      ↓
project SSH configuration
```

The final project SSH configuration must not prevent Vagrant from completing provisioning.

Therefore, the SSH stage should be executed near the end of provisioning.

---

# 26. Network Boundary

The Base Box and Vagrant configuration provide the infrastructure required for the VM to boot and for Vagrant to connect.

The original Debian network behavior was:

```text
enp0s3
    ↓
DHCP
```

with a dynamically assigned address and gateway.

The final Vagrant networking configuration should be documented separately from the project user's SSH configuration.

The important separation is:

```text
Vagrant network
        ↓
VM connectivity

SSH configuration
        ↓
authentication
```

One must not assume that a changed DHCP address is part of the reproducible project state.

---

# 27. Storage and Network vs Provisioning

Not every property belongs in a shell provisioning script.

The architecture is therefore:

```text
             BASE BOX
        ┌─────────────────┐
        │ Debian 13       │
        │ base OS         │
        │ base storage    │
        │ Vagrant SSH     │
        └────────┬────────┘
                 ↓
            VAGRANTFILE
                 ↓
             NETWORK /
          VM configuration
                 ↓
           PROVISIONING
                 ↓
        project configuration
```

This prevents one script from trying to recreate the entire operating-system installation.

---

# 28. Verification Strategy

The provisioning system must be tested from a destroyed VM.

The main test is:

```bash
vagrant destroy -f
vagrant up
```

After the VM is created, verify:

```text
users
groups
sudo
password aging
PAM
filesystem
setgid
ACL
sticky bit
systemd
SSH
```

The existing project `verify.sh` should be used as a reference for required final states.

However, known inconsistencies in the current verifier must be resolved before treating it as a completely reliable automated gate.

Examples of existing inconsistencies include:

```text
password aging checks soubaaiss
instead of the three project users

shared-directory path differs from the latest project path

sticky-directory spelling/path differs

some tests use the directory itself as a file

some sticky-bit tests use soubaaiss
instead of the project users
```

These must be reconciled with the actual assignment requirements before final automation.

Provisioning must not be changed merely to make an incorrect verifier pass.

---

# 29. Idempotency Test

After the first successful build:

```bash
vagrant provision
```

should not destroy or duplicate the configuration.

The expected result is:

```text
first provision
    ↓
server configured

second provision
    ↓
same configuration
```

Examples:

```text
no duplicate users
no duplicate groups
no broken ACLs
no duplicate sudo entries
no broken systemd unit
no broken SSH configuration
```

---

# 30. Clean Rebuild Test

The strongest test is:

```bash
vagrant destroy -f
vagrant up
```

This must create the server from scratch.

The final system should reproduce:

```text
admin1
developer1
deploy1
```

with:

```text
admin
developer
deploy
project
```

and the required sudo, security, filesystem, systemd and SSH configuration.

---

# 31. Final Architecture

The entire project can be represented as:

```text
                       Git repository
                             │
                             ▼
                        Vagrantfile
                             │
                             ▼
                    Debian Base Box
                             │
                    Debian 13 / amd64
                             │
                             ▼
                         VirtualBox
                             │
                             ▼
                         Debian VM
                             │
                             ▼
                    Vagrant SSH access
                             │
                             ▼
                  provision/provision.sh
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼
       packages            users              groups
          │                  │                  │
          └──────────────────┼──────────────────┘
                             ▼
                           sudo
                             │
                             ▼
                      password aging
                             │
                             ▼
                       PAM/faillock
                             │
                             ▼
                        filesystem
                             │
                 ┌───────────┴───────────┐
                 ▼                       ▼
             setgid                    ACL
                 │                       │
                 └───────────┬───────────┘
                             ▼
                       sticky bit
                             │
                             ▼
                          systemd
                             │
                             ▼
                            SSH
```

---

# 32. Final Desired State

After:

```bash
vagrant destroy -f
vagrant up
```

the VM should contain:

```text
USERS
admin1
developer1
deploy1
```

```text
ROLE GROUPS
admin
developer
deploy
```

```text
RESOURCE GROUP
project
```

```text
SUDO
admin
    → required administration

developer
    → restart myservice.service only

deploy
    → restart myservice.service only
```

```text
PASSWORD
90-day maximum lifetime
```

```text
PAM
3 failures
60-second interval
60-second unlock
```

```text
SHARED DIRECTORY
/home/soubaaiss/01-talent

root:project
2770
setgid
default ACL
deploy1 = r-x
```

```text
SCRATCH
required project scratch directory
1777
sticky bit
```

```text
SYSTEMD
myservice.service
Restart=always
RestartSec=5
enabled
active
```

```text
SSH
public-key authentication
password authentication disabled
keyboard-interactive authentication disabled
```

---

# 33. Complete Flow

The final automated lifecycle is:

```text
1. Vagrant reads Vagrantfile
       ↓
2. Vagrant selects Debian Base Box
       ↓
3. VirtualBox creates VM
       ↓
4. Debian boots
       ↓
5. Vagrant establishes its SSH connection
       ↓
6. packages are installed
       ↓
7. users are created
       ↓
8. groups are created
       ↓
9. sudo policies are installed
       ↓
10. password aging is configured
       ↓
11. PAM/faillock is configured
       ↓
12. project filesystem is created
       ↓
13. ownership and permissions are configured
       ↓
14. setgid is enabled
       ↓
15. default ACLs are configured
       ↓
16. deploy1 receives read-only ACL access
       ↓
17. sticky-bit directory is created
       ↓
18. systemd service is installed
       ↓
19. systemd service is enabled and started
       ↓
20. project SSH public keys are installed
       ↓
21. SSH configuration is validated
       ↓
22. SSH password authentication is disabled
       ↓
23. final verification runs
```

---

# 34. Stage 20 Result

The provisioning architecture is designed so that:

```text
Base Box
    =
clean Debian starting point

Vagrantfile
    =
VM lifecycle and provider configuration

provision.sh
    =
orchestration

individual scripts
    =
server configuration

verify.sh
    =
final-state verification
```

The central requirement is:

```text
Destroying the VM must destroy the configuration.

Running vagrant up again must recreate the configuration.
```

Therefore the project is reproducible rather than dependent on the current state of one manually configured Debian VM.

**Status: Stage 20 — Provisioning Design completed.**
