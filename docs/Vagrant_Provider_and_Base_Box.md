# Stage 19 — Vagrant Provider and Base Box

## 1. Goal

Stage 19 defines **what Vagrant will use to create the virtual machine**.

There are two important parts:

```text
Provider
    ↓
who actually runs the VM?

Base Box
    ↓
what system do we start from?
```

---

# 2. Provider

The project uses:

```text
VirtualBox
```

VirtualBox is the virtualization software that actually creates and runs the VM.

The relationship is:

```text
Vagrant
    ↓
VirtualBox
    ↓
Debian VM
```

Vagrant itself is not the hypervisor. It controls the VM lifecycle and asks the provider to create, start, stop, and destroy the machine. Vagrant has built-in support for VirtualBox.

---

# 3. Base Box

A Vagrant **Base Box** is a prepared machine image used as the starting point for the VM.

Instead of:

```text
Debian ISO
    ↓
install Debian manually
```

we use:

```text
Debian Vagrant Box
    ↓
Vagrant
    ↓
VirtualBox
    ↓
new Debian VM
```

Vagrant boxes are provider-specific packages used as the starting environment for Vagrant machines.

---

# 4. Architecture

The reference server uses:

```text
amd64 / x86-64
```

The base box must therefore provide a compatible architecture.

Vagrant supports architecture metadata for boxes and can select an appropriate architecture for the provider.

---

# 5. Selected Provider

The selected provider is:

```text
VirtualBox
```

This matches the virtualization environment used by the reference server.

VirtualBox is also supported directly by Vagrant.

---

# 6. Selected Base Box

The selected Debian base box is:

```text
cloud-image/debian-13
```

This is a Debian 13 (Trixie) Vagrant box and is documented for use with VirtualBox.

A currently published version is:

```text
20260810.2566.0
```

The current published Vagrant references list this version for Debian 13.

---

# 7. Vagrant Configuration

The basic configuration will therefore be based on:

```ruby
config.vm.box = "cloud-image/debian-13"
config.vm.box_version = "20260810.2566.0"

config.vm.provider "virtualbox" do |vb|
  # VM resources will be defined later.
end
```

The exact CPU, memory, network, and other VM settings will be finalized during the provisioning/Vagrant implementation stage.

---

# 8. Complete Relationship

The final architecture is:

```text
                    VAGRANT
                       │
                       ▼
                  VirtualBox
                       │
                       ▼
             Debian 13 Base Box
                       │
                       ▼
                Debian VM
                       │
                       ▼
                 Provisioning
                       │
          ┌────────────┼────────────┐
          │            │            │
        Users       Security      Services
          │            │            │
          ▼            ▼            ▼
       Groups       ACL/SSH      systemd
          │
          └────────────┬────────────┘
                       ▼
                  Final Server
```

---

# 9. What Vagrant Is Responsible For

Vagrant will:

```text
1. Select the base box.
2. Ask VirtualBox to create the VM.
3. Start the VM.
4. Connect to the VM.
5. Run the provisioning scripts.
6. Manage the VM lifecycle.
```

For example:

```bash
vagrant up
```

starts the complete build process.

```bash
vagrant halt
```

stops the VM.

```bash
vagrant destroy -f
```

removes the VM.

The actual VM is still created and run by VirtualBox.

---

# 10. What the Base Box Is Responsible For

The Base Box provides the starting Debian environment.

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
Vagrant-ready environment
```

It is not supposed to contain our project-specific server configuration.

---

# 11. What Provisioning Is Responsible For

After the Base Box is started, provisioning creates the project configuration:

```text
Base Box
    ↓
Debian
    ↓
Provisioning
    ↓
users
groups
sudo
PAM
ACL
permissions
systemd
SSH
    ↓
required server
```

This separation is important because we want to rebuild the server from the same starting point.

---

# 12. Why We Pin the Box Version

The project requires reproducible rebuilds.

Instead of allowing the starting image to change silently:

```text
cloud-image/debian-13
    ↓
whatever version is newest today
```

we specify a version:

```text
cloud-image/debian-13
    ↓
20260810.2566.0
```

This makes the starting environment more predictable when rebuilding the project.

---

# 13. Final Decision

```text
Provider:
    VirtualBox

Guest:
    Debian 13 (Trixie)

Architecture:
    amd64 / x86-64

Base Box:
    cloud-image/debian-13

Version:
    20260810.2566.0
```

The build starts from:

```text
cloud-image/debian-13
```

and then Vagrant provisioning creates the complete `linux` + `login` server.

**Stage 19 — Vagrant provider, architecture, and base box defined.**

**Next: Stage 20 — design the provisioning architecture and map all previous stages into the scripts that Vagrant will execute.**
