# Stage 15 — SSH Server Configuration

## 1. Goal

The Debian server must allow SSH authentication using **public keys**.

The final SSH authentication policy is:

```text
Public-key authentication → enabled
Password authentication    → disabled
Keyboard-interactive       → disabled
PAM                        → enabled
```

The intended configuration is:

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
```

---

## 2. SSH Server

The SSH server is OpenSSH.

The service is managed by systemd:

```bash
systemctl status ssh
```

The server configuration is primarily stored in:

```text
/etc/ssh/sshd_config
```

Additional configuration can exist in:

```text
/etc/ssh/sshd_config.d/
```

---

## 3. Public-Key Authentication

Public-key authentication works with a key pair:

```text
private key
    ↓
kept on client

public key
    ↓
stored on server
```

For a user:

```text
/home/USER/.ssh/authorized_keys
```

contains the user's authorized public key.

The private key must never be copied to the Debian server.

---

## 4. Required SSH Configuration

The final SSH server configuration must contain the equivalent of:

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
```

### PubkeyAuthentication

```text
PubkeyAuthentication yes
```

Enables authentication using SSH public/private key pairs.

---

### PasswordAuthentication

```text
PasswordAuthentication no
```

Disables normal SSH password authentication.

After this setting is active, a user cannot authenticate through the SSH password method.

---

### KbdInteractiveAuthentication

```text
KbdInteractiveAuthentication no
```

Disables keyboard-interactive authentication.

This is important because keyboard-interactive authentication is separate from `PasswordAuthentication` and can be associated with PAM-based authentication flows.

---

### UsePAM

```text
UsePAM yes
```

Keeps PAM integration enabled.

This is required because the server also uses PAM for authentication-related policies such as the failed-login lockout configured in Stage 10.

Therefore:

```text
SSH
 ↓
PAM integration
 ↓
authentication policy
```

remains available even though password-based SSH is disabled.

---

# 5. Authentication Model

The final SSH authentication flow is:

```text
SSH client
     │
     │ private key
     ▼
SSH server
     │
     │ checks public key
     ▼
authorized_keys
     │
     │ matching key
     ▼
authentication accepted
     │
     ▼
Linux user
     │
     ▼
shell
```

Password authentication is not part of the final SSH path:

```text
SSH
 │
 ├── public key → allowed
 │
 └── password   → disabled
```

---

# 6. SSH Configuration Validation

Before applying or reloading the configuration, validate its syntax:

```bash
sshd -t
```

If the command produces no output, the SSH configuration syntax is valid.

This check must be performed before reloading SSH.

---

# 7. Inspect the Effective Configuration

The effective SSH server configuration can be displayed with:

```bash
sshd -T
```

The relevant values should show:

```text
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
usepam yes
```

This verifies the effective configuration rather than relying only on what appears in one configuration file.

---

# 8. Reload SSH

After validating the configuration:

```bash
systemctl reload ssh
```

Reloading is preferred for configuration changes when supported because it applies the new configuration without unnecessarily terminating existing SSH sessions.

---

# 9. Important Safety Order

Public-key authentication must be tested **before** password authentication is disabled.

The correct order is:

```text
1. Generate SSH key
       ↓
2. Install public key on server
       ↓
3. Verify key permissions
       ↓
4. Test SSH login using the key
       ↓
5. Validate sshd configuration
       ↓
6. Disable password authentication
       ↓
7. Reload SSH
       ↓
8. Test key login again
```

Do not disable password SSH before confirming that a working public-key login exists.

---

# 10. Provisioning Requirements

The future Vagrant provisioning must configure the SSH server so that the final effective configuration is:

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
```

Provisioning must:

1. Install `openssh-server`.
2. Ensure the SSH service is enabled and running.
3. Configure public-key authentication.
4. Disable password authentication.
5. Disable keyboard-interactive authentication.
6. Keep PAM enabled.
7. Validate the SSH configuration with `sshd -t`.
8. Reload SSH after configuration changes.
9. Verify the effective configuration with `sshd -T`.

Provisioning must be idempotent.

---

# 11. Final SSH Server Policy

The final server policy is:

```text
                SSH SERVER
                    │
          ┌─────────┴─────────┐
          │                   │
     Public key            Password
       allowed             disabled
          │
          ▼
    authorized_keys
          │
          ▼
      Linux user
```

The resulting security model is:

```text
Public-key authentication → YES
Password authentication    → NO
Keyboard-interactive       → NO
PAM integration            → YES
```

**Stage 15 — SSH server configuration designed and documented.**

**Next: Stage 16 — generate/install the public keys and document the per-user SSH authentication setup.**
