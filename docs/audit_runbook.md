# Audit Test Runbook

Everything you need to run the audit, in order, with the exact command and the output
you should see. Copy-paste each command.

**Project:** https://github.com/saidxp/addvm
**Host:** Debian 13, `x86_64`, VirtualBox 7.1.18, Vagrant 2.4.9

---

## 0. Before you start (do this first)

The audit depends on a full destroy-and-rebuild cycle that takes several minutes.
**Start it immediately** so it runs in the background while you work through the
Repository and Understanding sections.

```bash
cd /home/saidxp/addvm
vagrant destroy -f && vagrant up
```

Leave this window open and continue reading below while it runs.

---

## 1. Repository

### 1.1 Show the git repository

```bash
cd /home/saidxp/addvm
git log --oneline
git remote -v
```

**Expected:**

```
857bc94 Host base box on GitHub Releases and reference it via box_url
2d3dc0e Reproducible Debian 13 Vagrant project: Vagrantfile, modular provisioning scripts, verification, docs
origin  git@github.com:saidxp/addvm.git (push)
```

### 1.2 Does the repo contain the Vagrant config + provisioning scripts?

```bash
git ls-files
```

**Expected:** 45 tracked files — `Vagrantfile`, `provision/*.sh` (15 scripts),
`keys/*.pub`, `systemd/*`, `docs/*.md`, `verify.sh`, `README.md`, `.gitignore`.

### 1.3 Is it committed, not just local files?

```bash
git status --porcelain --untracked-files=all
git fetch origin && test "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" && echo "IN SYNC WITH GITHUB"
```

**Expected:**
- First command prints **nothing** (no uncommitted or untracked work).
- Then: `IN SYNC WITH GITHUB`.

Only these two are ignored, on purpose:

```bash
git status --porcelain --ignored | grep '^!!'
```

```
!! .vagrant/        # local runtime state, must never be committed
!! debian13.box     # 948 MB, exceeds GitHub's 100 MB commit limit -> hosted as a Release
```

### 1.4 Preseed / cloud-init file?

```bash
grep -ri "preseed\|cloud-init" --include="*.md" --include="*.sh" --include="Vagrantfile" . | grep -v docs/
```

**Expected:** **no results** — this is correct and intentional. There is **no**
preseed or cloud-init file, because this project deliberately chose the *other*
allowed approach: a minimal base box configured entirely by provisioning.
The decision is written in `docs/Unattended Installation_and_Reproducible_Provisioning.md`
(section 2 and section 15):

> We will not use Preseed or build a custom Debian installer unless a later requirement makes that necessary.

---

## 2. Understanding

### 2.1 "Name one thing your code now does that you previously did by hand"

Pick one and be ready to *show* it, not just say it. Easiest one to demonstrate:

**User creation.** By hand it was:

```bash
sudo useradd -m -s /bin/bash admin1
sudo usermod -aG admin,project admin1
```

Now `provision/users.sh` + `provision/groups.sh` do it automatically on every
`vagrant up`, and they also detect an existing user instead of failing. Prove it:

```bash
vagrant ssh -c "id admin1"
```

```
uid=1002(admin1) gid=1002(admin1) groups=1002(admin1),1005(admin),1008(project)
```

Alternative, equally good: the SSH hardening. By hand you would edit
`/etc/ssh/sshd_config` and reload `sshd` by eye; now `provision/ssh.sh` does it and
validates with `sshd -t` before reloading.

### 2.2 "How does your build differ between x86-64 and Apple Silicon?"

Answer in these three parts:

| | x86-64 (what you built on) | Apple Silicon (arm64) |
|---|---|---|
| Provider | **VirtualBox** (works on x86 Linux/Windows) | VirtualBox has no macOS/arm64 host build -> use **`vagrant-libvirt`**, **QEMU**, or **UTM/Parallels** |
| Base box | `debian13-local`, built as `amd64` | needs an **`arm64`** Debian 13 box; the amd64 `.box` will not boot |
| Provisioning | unchanged | unchanged — this is the payoff of keeping all config in scripts |

The scripts contain **no** architecture-specific code, so only the provider and box
lines in the `Vagrantfile` would change.

Documented in: `docs/Vagrant_Provider_and_Base_Box.md` (sections 4, 5, 13) and
`docs/debian_base.md` ("Reproduction Requirements").

> ⚠️ **Known doc inconsistency — mention it before the auditor finds it.**
> `docs/Vagrant_Provider_and_Base_Box.md` section 6/13 names the box as
> `cloud-image/debian-13` version `20260810.2566.0`, but the actual `Vagrantfile`
> uses the custom local box `debian13-local` hosted on GitHub Releases.
> The architecture decision (VirtualBox + amd64) is correct; only the box name is stale.

### 2.3 Does the provider match this machine's architecture?

```bash
uname -m
vagrant global-status | grep virtualbox
VBoxManage --version
```

**Expected:** `x86_64` and provider `virtualbox` — they match, and the box imports as
`virtualbox (amd64)`. (This check is the one that would fail if you ran the VirtualBox
provider on Apple Silicon.)

---

## 3. Reproducibility  ← the central check

### 3.1 Did the rebuild need any manual input?

Go back to the terminal from section 0. Scroll through the output.

**Expected:** no prompt ever appeared. Vagrant imported the box, booted, replaced the
insecure key, mounted shared folders, then ran every stage by itself:

```
=== Stage 04: Installing Required Packages ===
=== Stage 05: Provisioning Systemd Monitoring Service ===
=== Stage 06: Provisioning Users ===
=== Stage 07: Provisioning Groups ===
=== Stage 08: Provisioning Sudo Policies ===
=== Stage 09: Provisioning Password Aging ===
=== Stage 10: Provisioning PAM / pam_faillock ===
=== Stage 11: Provisioning Shared Filesystem Structure ===
=== Stage 12: Provisioning Directory Ownership, Permissions, and Setgid ===
=== Stage 13: Provisioning ACLs and Default Inheritance ===
=== Stage 14: Provisioning Sticky-Bit Scratch Directory ===
=== Stages 15 & 16: Provisioning SSH Configuration and Public Keys ===
 All Provisioning Completed Successfully
```

### 3.2 Did `vagrant up` complete successfully?

```bash
vagrant status
```

**Expected:** `default  running (virtualbox)`

### 3.3 Run the verification script UNCHANGED

This is the central check of the project. Do not edit the script first.

```bash
vagrant ssh -c "sudo /vagrant/verify.sh"
```

**Expected:** `PASS: 43`, `FAIL: 1`, exit code 1. See section 7 below — the one
failure is a confirmed bug in the script's own assertion, **not** missing configuration.
If you are asked whether the config was captured in code, show section 7's proof.

### 3.4 Prove the rebuild is genuinely self-contained (fresh clone)

```bash
rm -rf /tmp/auditclone
git clone https://github.com/saidxp/addvm.git /tmp/auditclone
ls /tmp/auditclone
```

**Expected:** the clone contains `Vagrantfile`, `provision/`, `keys/`, `systemd/`,
`docs/`, `verify.sh`, `README.md` — and **no** `debian13.box`, which is correct
because the `Vagrantfile` now downloads it:

```bash
grep box_url /tmp/auditclone/Vagrantfile
curl -sI https://github.com/saidxp/addvm/releases/download/box/debian13.box | grep -i "^HTTP\|location" | head -3
```

```
config.vm.box_url = "https://github.com/saidxp/addvm/releases/download/box/debian13.box"
HTTP/2 302
location: https://release-assets.githubusercontent.com/...
```

The asset is 993,626,672 bytes — identical to the local `debian13.box`.

> Note: `box_url` is only used when the box name is **not** already installed locally.
> On your machine `debian13-local` exists, so `vagrant up` uses it and never
> re-downloads. To force-test the download path without touching your real box:
>
> ```bash
> cd /tmp && vagrant box add audit-check https://github.com/saidxp/addvm/releases/download/box/debian13.box --provider virtualbox
> vagrant box remove audit-check --provider virtualbox
> ```
>
> Expected: `Successfully added box 'audit-check' for 'virtualbox (amd64)'!`

---

## 4. Idempotency

### 4.1 Run provisioning a second time

```bash
vagrant provision
```

**Expected:** exits cleanly with no errors, and reports existing state instead of
trying to recreate it:

```
User admin1 already exists. Verifying shell and home...
usermod: no changes
Group admin already exists.
Group developer already exists.
Group deploy already exists.
Group project already exists.
 All Provisioning Completed Successfully
```

Confirm the exit code:

```bash
vagrant provision > /dev/null 2>&1; echo "EXIT=$?"
```

**Expected:** `EXIT=0`

### 4.2 Did it duplicate anything?

```bash
vagrant ssh -c "sudo bash -c '
echo \"-- users (must be 1 each) --\"
grep -c ^admin1: /etc/passwd; grep -c ^developer1: /etc/passwd; grep -c ^deploy1: /etc/passwd
echo \"-- authorized_keys (1 line each) --\"
wc -l /home/admin1/.ssh/authorized_keys /home/developer1/.ssh/authorized_keys /home/deploy1/.ssh/authorized_keys
echo \"-- sshd directives (no repeats) --\"
grep -hE \"^PasswordAuthentication|^PubkeyAuthentication\" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null | sort | uniq -c
echo \"-- faillock.conf --\"
grep -E \"^(deny|unlock_time|fail_interval)\" /etc/security/faillock.conf
echo \"-- group membership (no appended duplicates) --\"
getent group project admin developer deploy
echo \"-- sudoers files (no duplicates) --\"
sort /etc/sudoers.d/admin | uniq -cd
'"
```

**Expected:**

```
1 / 1 / 1                 each user appears once in /etc/passwd
1 line each               authorized_keys, one key per user
      1 PasswordAuthentication no
      2 PubkeyAuthentication yes   (1 in main config + 1 in drop-in, same value -> harmless)
deny = 3 / fail_interval = 60 / unlock_time = 60, once each
project:x:1008:admin1,developer1   (not admin1,admin1,developer1...)
                              the final uniq -cd prints nothing = zero duplicate lines
```

Why it is idempotent: `users.sh`/`groups.sh` test for existence first, and file-based
config uses `cat > file` (overwrite) rather than `>>` (append). Append is the usual
way these scripts break on a second run.

---

## 5. Snapshots

### 5.1 Take a snapshot, make a visible change, roll back

```bash
vagrant snapshot save audit-checkpoint
vagrant ssh -c "echo VISIBLE_CHANGE | sudo tee /etc/audit_marker && sudo ls -l /etc/audit_marker"
```

Note: one snapshot of this running VM used **364 MB** of disk — check with `df -h /home`
before taking several.

Now roll back:

```bash
vagrant snapshot restore audit-checkpoint
vagrant ssh -c "sudo ls -l /etc/audit_marker"
```

**Expected — the change is gone:**

```
ls: cannot access '/etc/audit_marker': No such file or directory
```

`restore` powers the VM off, rewinds it, and boots it again, so it takes about a minute.
The rollback also reverts things you may have wanted to keep — it is a disposable undo
button for the whole VM, and it never touches your host files in `provision/`.

Other useful commands:

```bash
vagrant snapshot list
vagrant snapshot delete audit-checkpoint
```

Clean up at the end:

```bash
vagrant snapshot delete audit-checkpoint
```

### 5.2 "When would you use a snapshot rather than rebuilding from code?"

| | Snapshot | Rebuild from code |
|---|---|---|
| Speed | seconds–minutes | several minutes (1 GB box + all stages) |
| Captures | whatever the VM is doing right now, including mistakes | only what you wrote into scripts |
| Shareable | ❌ lives only on your disk, cannot be pushed to GitHub | ✅ anyone cloning the repo gets the same server |
| Good for | risky experiments, temporary test states, "what if I break this" | the real permanent definition of the server |

Say it plainly: **a snapshot is for temporary experiments I intend to throw away;
rebuilding from code is the source of truth.** Anything worth keeping must end up in
`provision/*.sh` and be committed — never left living only inside a snapshot, because
snapshots die with the machine. Snapshots also prove nothing about reproducibility,
since they cannot be transferred to another host.

---

## 6. Documentation

Read `docs/` (21 stage documents plus this runbook) plus `README.md`, then answer: *could you clone and build
this yourself without asking questions?*

Check the doc set covers, in order:

- architecture and layering — `README.md` section 1, `docs/Vagrant_Provisioning_Design.md`
- provider / base box / architecture — `docs/Vagrant_Provider_and_Base_Box.md`, `docs/debian_base.md`
- unattended strategy — `docs/Unattended Installation_and_Reproducible_Provisioning.md`
- per-stage detail — `packages.md`, `users.md`, `groups.md`, `sudo.md`, `password_agin.md`,
  `apm_faillock.md`, `Shared Directory.md`, `Shared Directory Permissions and Setgid.md`,
  `acl_and_inhertance.md`, `Sticky Bit Scratch Directory.md`, `service.md`,
  `ssh-public-key.md`, `ssh-server-conf.md`, `network.md`, `storage.md`
- how to verify — `README.md` sections 3 and 5, `docs/verifycation.md`

**Verdict:** yes for the build itself — `README.md` section 3 gives clone → `vagrant up`
→ `verify.sh` and the box now downloads automatically, so there are no hidden manual
steps. Be ready to name the two weaknesses rather than have them found:

1. The stale box name in `docs/Vagrant_Provider_and_Base_Box.md` (section 2.3 above).
2. `README.md` section 5 lists what `verify.sh` checks but never states the expected
   pass/fail count, so the one known-broken assertion looks like a real config failure.

---

## 7. Known issue: the 1 verify.sh FAIL is a false negative

`verify.sh` line 117:

```bash
if sudo -l -U admin1 2>/dev/null | grep -q "USER_MANAGEMENT"; then
```

`provision/sudo.sh` defines a `Cmnd_Alias USER_MANAGEMENT`, but **`sudo -l` expands
alias names into the real command paths and never prints the token `USER_MANAGEMENT`.**
So the assertion can never match, on a correctly configured machine, every time.

Proof the policy IS applied correctly:

```bash
vagrant ssh -c "sudo -l -U admin1 | tail -3; sudo -l -U admin1 | grep -c USER_MANAGEMENT"
```

```
User admin1 may run the following commands on vbox:
    (root) /usr/sbin/useradd, /usr/sbin/usermod, /usr/sbin/userdel, /usr/sbin/groupadd,
           /usr/sbin/groupmod, /usr/sbin/groupdel, /usr/bin/passwd, /usr/bin/chage,
           /usr/bin/apt, /usr/bin/apt-get, /usr/bin/systemctl restart *
0        <- the literal string USER_MANAGEMENT never appears
```

So all 11 user-management commands admin1 needs are granted — the configuration is
correct and fully captured in code; only the test is wrong.

**The fix** (match on a real command instead of the alias name) — apply only if the
auditor agrees the script itself is defective, and say so out loud:

```bash
if sudo -l -U admin1 2>/dev/null | grep -q "/usr/sbin/useradd"; then
```

---

## 8. Current audit status

| Section | Result | Evidence |
|---|---|---|
| Repository | ✅ | 45 files committed, HEAD == origin/main, `.box` correctly excluded |
| Understanding | ⚠️ | answers above; doc names a stale box (`cloud-image/debian-13` vs `debian13-local`) |
| Reproducibility (rebuild, no input) | ✅ | destroy + up, all 11 stages, zero prompts |
| Reproducibility (verify.sh) | ⚠️ 43/44 | 1 FAIL is a script bug, proven in section 7 |
| Idempotency | ✅ | 2nd run EXIT=0, "already exists", zero duplicated lines |
| Snapshots | ✅ | `/MARKER_AUDIT2` and `/etc/motd` both reverted by rollback; 364 MB/snapshot |
| Documentation | ⚠️ | sufficient to build; two gaps listed in section 6 |

**Honest one-line verdict:** the environment is genuinely reproducible from code and
passes every real check, while `verify.sh` reports 43/44 because one of its own
assertions is broken. Do not silently edit the script to force 44/44 — present the
evidence and let the auditor decide.

---

## 9. Teardown / housekeeping

```bash
vagrant snapshot list                       # make sure no test snapshots remain
df -h /home                                 # disk was at 93% during these tests
rm -rf /tmp/auditclone                      # if you made the fresh clone
vagrant destroy -f                          # only when the audit is fully finished
```
