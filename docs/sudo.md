# Stage 08 — Sudo

## 1. What Is Sudo?

`sudo` allows a normal Linux user to execute specific commands with elevated privileges, usually as `root`.

Instead of giving a user the root account, we define exactly which privileged commands that user can execute.

The basic model is:

```text
User
  ↓
Group
  ↓
Sudoers rule
  ↓
Allowed privileged command
```

For this project:

```text
admin1
   ↓
admin group
   ↓
admin sudo policy
   ↓
administrative commands


developer1
   ↓
developer group
   ↓
developer sudo policy
   ↓
restart myservice.service only


deploy1
   ↓
deploy group
   ↓
deploy sudo policy
   ↓
restart myservice.service only
```

---

# 2. Why Does the Project Need Sudo?

The project has three different roles:

```text
admin
developer
deploy
```

They must not all have the same privileges.

The required model is:

```text
admin
├── manage users
├── manage groups
├── install packages
└── restart any service


developer
└── restart only myservice.service


deploy
└── restart only myservice.service
```

This is an example of **least privilege**.

A user receives only the privileged operations required by their role.

---

# 3. Sudo Configuration

The main sudo configuration file is:

```text
/etc/sudoers
```

Project-specific rules are stored in:

```text
/etc/sudoers.d/
```

The Debian system currently contains:

```text
/etc/sudoers.d/
├── admin
├── developer
├── deploy
└── README
```

The main `/etc/sudoers` file contains:

```text
@includedir /etc/sudoers.d
```

This tells sudo to load the configuration files from:

```text
/etc/sudoers.d/
```

---

# 4. Why Use `/etc/sudoers.d/`?

The project does not need us to put all custom rules directly into:

```text
/etc/sudoers
```

Instead, each role can have its own file:

```text
/etc/sudoers.d/admin
/etc/sudoers.d/developer
/etc/sudoers.d/deploy
```

This gives us a clear separation:

```text
admin rules
     ↓
/etc/sudoers.d/admin

developer rules
     ↓
/etc/sudoers.d/developer

deploy rules
     ↓
/etc/sudoers.d/deploy
```

It also makes the configuration easier to manage and automate.

---

# 5. Main Sudo Defaults

The current Debian VM contains:

```text
Defaults env_reset
Defaults mail_badpass
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults use_pty
```

These are general sudo defaults.

The system also contains:

```text
root ALL=(ALL:ALL) ALL
%sudo ALL=(ALL:ALL) ALL
```

The second rule means members of the Debian `sudo` group have broad sudo privileges.

Therefore, our project users must not accidentally be members of the `sudo` group unless the project explicitly requires it.

---

# 6. Admin Sudo Policy

The project requires the `admin` role to manage the system.

The actual file is:

```text
/etc/sudoers.d/admin
```

Its configuration is:

```text
Cmnd_Alias USER_MANAGEMENT = /usr/sbin/useradd, /usr/sbin/usermod, /usr/sbin/userdel, /usr/sbin/groupadd, /usr/sbin/groupmod, /usr/sbin/groupdel, /usr/bin/passwd, /usr/bin/chage

Cmnd_Alias PACKAGE_MANAGEMENT = /usr/bin/apt, /usr/bin/apt-get

Cmnd_Alias SERVICE_RESTART = /usr/bin/systemctl restart *

%admin ALL=(root) USER_MANAGEMENT, PACKAGE_MANAGEMENT, SERVICE_RESTART
```

---

# 7. Understanding `Cmnd_Alias`

A `Cmnd_Alias` groups several commands under one name.

For example:

```text
Cmnd_Alias USER_MANAGEMENT = ...
```

creates the alias:

```text
USER_MANAGEMENT
```

which represents:

```text
useradd
usermod
userdel
groupadd
groupmod
groupdel
passwd
chage
```

Then we can use:

```text
%admin ALL=(root) USER_MANAGEMENT
```

instead of writing every command again.

---

# 8. Admin User Management

The admin policy allows:

```text
/usr/sbin/useradd
/usr/sbin/usermod
/usr/sbin/userdel
/usr/sbin/groupadd
/usr/sbin/groupmod
/usr/sbin/groupdel
/usr/bin/passwd
/usr/bin/chage
```

Therefore the `admin` role can perform user and group administration through sudo.

For example:

```bash
sudo useradd testuser
```

or:

```bash
sudo usermod -aG developer testuser
```

The command is executed as `root`.

---

# 9. Admin Package Management

The project allows:

```text
/usr/bin/apt
/usr/bin/apt-get
```

Therefore an admin can perform package-management operations such as:

```bash
sudo apt update
```

or:

```bash
sudo apt install package
```

The exact behavior is determined by the sudo command specification and the arguments accepted by the command.

---

# 10. Admin Service Restart

The admin policy contains:

```text
Cmnd_Alias SERVICE_RESTART = /usr/bin/systemctl restart *
```

This allows the `admin` role to restart services through `systemctl`.

For example:

```bash
sudo systemctl restart myservice.service
```

The wildcard means the service name is not restricted to `myservice.service`.

Therefore:

```text
admin
   ↓
systemctl restart *
   ↓
can restart services
```

---

# 11. Developer Sudo Policy

The developer role must have much less privilege.

The actual file is:

```text
/etc/sudoers.d/developer
```

Its rule is:

```text
%developer ALL=(root) /usr/bin/systemctl restart myservice.service
```

This means:

```text
members of developer
        ↓
may execute as root
        ↓
/usr/bin/systemctl restart myservice.service
```

So `developer1` can run:

```bash
sudo systemctl restart myservice.service
```

---

# 12. What Developer Cannot Do

The developer rule does **not** grant general root access.

For example, the developer role is not supposed to have permission to execute arbitrary commands such as:

```bash
sudo bash
```

or:

```bash
sudo su
```

or:

```bash
sudo systemctl stop ssh
```

The intended privilege is specifically:

```text
restart myservice.service
```

This is the important difference between:

```text
restricted sudo
```

and:

```text
full root access
```

---

# 13. Deploy Sudo Policy

The deploy role has the same restricted service-management requirement.

The actual file is:

```text
/etc/sudoers.d/deploy
```

Its rule is:

```text
%deploy ALL=(root) /usr/bin/systemctl restart myservice.service
```

Therefore:

```text
deploy1
   ↓
deploy group
   ↓
sudo
   ↓
restart myservice.service
```

The command is:

```bash
sudo systemctl restart myservice.service
```

---

# 14. Why Groups Are Used

The sudo rules are written against groups:

```text
%admin
%developer
%deploy
```

The `%` means the name refers to a group.

For example:

```text
%developer ALL=(root) ...
```

means:

```text
every member of the developer group
```

inherits that sudo rule.

Therefore:

```text
developer1
    ↓
member of developer
    ↓
gets developer sudo permissions
```

This is better for the project than writing separate rules for every user.

---

# 15. Role Separation

The final authorization model is:

```text
                  SUDO
                   │
       ┌───────────┼───────────┐
       │           │           │
     admin      developer     deploy
       │           │           │
       │           │           │
       ▼           ▼           ▼
 user/group     restart      restart
 management     myservice    myservice
 packages
 services
```

More specifically:

```text
admin1
  ↓
admin
  ↓
user management
package management
restart any service


developer1
  ↓
developer
  ↓
restart myservice.service only


deploy1
  ↓
deploy
  ↓
restart myservice.service only
```

---

# 16. Checking Effective Sudo Permissions

Do not rely only on reading the sudoers files.

The most useful command is:

```bash
sudo -l -U USER
```

For this project:

```bash
sudo -l -U admin1
sudo -l -U developer1
sudo -l -U deploy1
```

This asks sudo:

> What commands is this user actually allowed to execute?

---

# 17. Actual `admin1` Result

The existing VM reports:

```text
User admin1 may run the following commands:
```

```text
(root) /usr/sbin/useradd
(root) /usr/sbin/usermod
(root) /usr/sbin/userdel
(root) /usr/sbin/groupadd
(root) /usr/sbin/groupmod
(root) /usr/sbin/groupdel
(root) /usr/bin/passwd
(root) /usr/bin/chage
(root) /usr/bin/apt
(root) /usr/bin/apt-get
(root) /usr/bin/systemctl restart *
```

Therefore the admin policy is currently effective.

---

# 18. Actual `developer1` Result

The existing VM reports:

```text
User developer1 may run:
```

```text
(root) /usr/bin/systemctl restart myservice.service
```

Therefore the developer restriction is currently effective.

---

# 19. Actual `deploy1` Result

The existing VM reports:

```text
User deploy1 may run:
```

```text
(root) /usr/bin/systemctl restart myservice.service
```

Therefore the deploy restriction is currently effective.

---

# 20. Validating Sudo Configuration

Use:

```bash
visudo -c
```

This checks the sudo configuration.

The existing VM currently reports:

```text
/etc/sudoers: parsed OK
/etc/sudoers.d/README: parsed OK
```

But it also reports:

```text
/etc/sudoers.d/admin: bad permissions, should be mode 0440
/etc/sudoers.d/deploy: bad permissions, should be mode 0440
/etc/sudoers.d/developer: bad permissions, should be mode 0440
```

So there are two separate concepts:

```text
sudoers syntax
        ↓
valid
```

but:

```text
sudoers file permissions
        ↓
incorrect
```

---

# 21. Correct Sudoers File Permissions

The project sudoers files should have:

```text
0440
```

Therefore the final configuration should use:

```bash
chmod 0440 /etc/sudoers.d/admin
chmod 0440 /etc/sudoers.d/developer
chmod 0440 /etc/sudoers.d/deploy
```

The important point for automation is:

```text
create sudoers file
        ↓
set correct owner
        ↓
set mode 0440
        ↓
validate with visudo
```

We should not simply copy the current incorrect permissions into the automated VM.

---

# 22. Why `visudo` Should Be Used

Do not normally edit sudoers files with:

```bash
nano /etc/sudoers.d/developer
```

Instead use:

```bash
visudo -f /etc/sudoers.d/developer
```

`visudo` validates the syntax before accepting the configuration.

This is important because a syntax error in sudo configuration can cause serious authorization problems.

For the project:

```bash
visudo -f /etc/sudoers.d/admin
visudo -f /etc/sudoers.d/developer
visudo -f /etc/sudoers.d/deploy
```

---

# 23. What Must Be Reproduced

The automated VM must reproduce the **authorization model**, not the accidental current state.

Required:

```text
admin group
    ↓
admin1
    ↓
administrative commands
```

```text
developer group
    ↓
developer1
    ↓
restart only myservice.service
```

```text
deploy group
    ↓
deploy1
    ↓
restart only myservice.service
```

And:

```text
/etc/sudoers.d/admin
/etc/sudoers.d/developer
/etc/sudoers.d/deploy
```

must have correct permissions:

```text
0440
```

---

# 24. Verification Commands

After provisioning, the project should verify:

```bash
visudo -c
```

Then:

```bash
sudo -l -U admin1
sudo -l -U developer1
sudo -l -U deploy1
```

The expected authorization model is:

```text
admin1
→ user/group management
→ package management
→ restart any service

developer1
→ restart myservice.service only

deploy1
→ restart myservice.service only
```

---

# 25. Important Mental Model

The most important thing to remember is:

```text
/etc/passwd
    ↓
Who is the user?


/etc/group
    ↓
Which groups does the user belong to?


/etc/sudoers.d/
    ↓
What privileged commands can those groups execute?


sudo -l -U USER
    ↓
What can this user actually execute?
```

So:

```text
developer1
     │
     ▼
developer group
     │
     ▼
/etc/sudoers.d/developer
     │
     ▼
systemctl restart myservice.service
```

That is **Stage 08 — Sudo**.

---

# Stage 08 Status

```text
✓ Sudo installed
✓ /etc/sudoers.d/ used
✓ Admin policy identified
✓ Developer policy identified
✓ Deploy policy identified
✓ Effective permissions verified
✓ Sudo syntax checked
⚠ Sudoers file permissions need correction to 0440
```

**Stage 08 is now documented.**
