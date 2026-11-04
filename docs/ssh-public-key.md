# Stage 16 — SSH Public-Key Authentication

## 1. Goal

The server must authenticate the project users with SSH public keys:

```text
admin1
developer1
deploy1
```

The private keys stay on the client machines.

The public keys are installed on the Debian server.

---

## 2. SSH Key Pair

An SSH key pair contains:

```text
private key
public key
```

For Ed25519:

```bash
ssh-keygen -t ed25519
```

This normally creates:

```text
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

The files have different responsibilities:

```text
id_ed25519
    ↓
PRIVATE KEY
    ↓
stays on the client
```

```text
id_ed25519.pub
    ↓
PUBLIC KEY
    ↓
installed on the server
```

The private key must never be copied to the server or committed to Git.

---

## 3. Public-Key Installation

The public key is placed in:

```text
/home/USER/.ssh/authorized_keys
```

For example:

```text
/home/admin1/.ssh/authorized_keys
/home/developer1/.ssh/authorized_keys
/home/deploy1/.ssh/authorized_keys
```

The file contains the public key as a complete line.

Example:

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... client@machine
```

---

## 4. Manual Installation

The public-key installation is performed manually on the current server.

For example:

```bash
mkdir -p /home/admin1/.ssh
nano /home/admin1/.ssh/authorized_keys
```

Paste the complete contents of the client's:

```text
id_ed25519.pub
```

into:

```text
/home/admin1/.ssh/authorized_keys
```

Repeat the same process for:

```text
developer1
deploy1
```

---

## 5. Recommended Installation Method

The public key can also be copied from the client with:

```bash
ssh-copy-id admin1@SERVER_IP
ssh-copy-id developer1@SERVER_IP
ssh-copy-id deploy1@SERVER_IP
```

This installs the public key into the corresponding user's:

```text
~/.ssh/authorized_keys
```

Manual installation and `ssh-copy-id` produce the same basic server-side result.

---

# 6. SSH Directory Permissions

The `.ssh` directory must be restricted:

```bash
chmod 700 /home/admin1/.ssh
chmod 700 /home/developer1/.ssh
chmod 700 /home/deploy1/.ssh
```

The `authorized_keys` file must also be restricted:

```bash
chmod 600 /home/admin1/.ssh/authorized_keys
chmod 600 /home/developer1/.ssh/authorized_keys
chmod 600 /home/deploy1/.ssh/authorized_keys
```

---

# 7. Ownership

The `.ssh` directory and its contents must belong to the corresponding user.

For example:

```bash
chown -R admin1:admin1 /home/admin1/.ssh
chown -R developer1:developer1 /home/developer1/.ssh
chown -R deploy1:deploy1 /home/deploy1/.ssh
```

The final structure is:

```text
/home/admin1/.ssh/
└── authorized_keys
```

```text
/home/developer1/.ssh/
└── authorized_keys
```

```text
/home/deploy1/.ssh/
└── authorized_keys
```

---

# 8. Authentication Flow

When a user connects:

```bash
ssh admin1@SERVER_IP
```

the SSH client uses the private key:

```text
client
  │
  │ private key
  ▼
SSH authentication
  │
  ▼
Debian server
  │
  │ checks matching public key
  ▼
/home/admin1/.ssh/authorized_keys
  │
  ▼
authentication succeeds
  │
  ▼
admin1 shell
```

The server never needs the client's private key.

---

# 9. Test Public-Key Authentication

Before disabling password authentication, test each account.

From the client:

```bash
ssh admin1@SERVER_IP
```

```bash
ssh developer1@SERVER_IP
```

```bash
ssh deploy1@SERVER_IP
```

The authentication must succeed using the configured SSH keys.

The client can explicitly select a key with:

```bash
ssh -i ~/.ssh/id_ed25519 USER@SERVER_IP
```

---

# 10. Verify the Server-Side Files

On the server:

```bash
ls -la /home/admin1/.ssh
ls -la /home/developer1/.ssh
ls -la /home/deploy1/.ssh
```

Verify the `authorized_keys` permissions:

```bash
stat -c '%U:%G %a %n' /home/admin1/.ssh/authorized_keys
stat -c '%U:%G %a %n' /home/developer1/.ssh/authorized_keys
stat -c '%U:%G %a %n' /home/deploy1/.ssh/authorized_keys
```

The expected ownership and mode are:

```text
admin1:admin1       600
developer1:developer1 600
deploy1:deploy1     600
```

---

# 11. SSH Key Security Rule

The following file stays on the client:

```text
~/.ssh/id_ed25519
```

The following file is copied to the server:

```text
~/.ssh/id_ed25519.pub
```

The server stores the public key in:

```text
~/.ssh/authorized_keys
```

Therefore:

```text
PRIVATE KEY
    → client only

PUBLIC KEY
    → server authorized_keys
```

Never put the private key in:

```text
authorized_keys
```

Never put the private key in the Git repository.

---

# 12. Relation to Stage 15

Stage 15 defines the SSH server policy:

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
```

Stage 16 provides the actual credentials required by that policy:

```text
public key
    ↓
authorized_keys
```

Together:

```text
Stage 15
SSH accepts public-key authentication
        +
Stage 16
user public key is installed
        ↓
SSH key login works
```

---

# 13. Provisioning Responsibility

Later, Vagrant provisioning will reproduce the **server-side** configuration.

Provisioning must:

1. Create the users.
2. Create each user's `.ssh` directory.
3. Create or update `authorized_keys`.
4. Install the required public key.
5. Set `.ssh` permissions to `700`.
6. Set `authorized_keys` permissions to `600`.
7. Set the correct ownership.
8. Validate the SSH server configuration.
9. Reload SSH.

The provisioning process must never require the user's private key to exist inside the VM.

---

# 14. Client Key vs Server Configuration

The client private key is not part of the server configuration.

```text
CLIENT
────────────────────
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

```text
SERVER
──────────────────────────────
/home/admin1/.ssh/authorized_keys
/home/developer1/.ssh/authorized_keys
/home/deploy1/.ssh/authorized_keys
```

The server only needs the public keys.

---

# 15. Final SSH Authentication Model

```text
                 CLIENT
                    │
             private key
                    │
                    ▼
               SSH request
                    │
                    ▼
              DEBIAN SERVER
                    │
                    ▼
             authorized_keys
                    │
             public key match
                    │
                    ▼
             authentication
               successful
                    │
                    ▼
                USER SHELL
```

For the three project users:

```text
admin1
    ↓
/home/admin1/.ssh/authorized_keys

developer1
    ↓
/home/developer1/.ssh/authorized_keys

deploy1
    ↓
/home/deploy1/.ssh/authorized_keys
```

**Stage 16 — SSH public-key authentication documented.**

**Important:** the public keys can be installed manually on the current VM for testing. Later, Vagrant provisioning will reproduce the server-side `authorized_keys` configuration automatically.
