## Stage 02 — Storage

### Existing Configuration

The original Debian server uses a 20 GB virtual disk with the following layout:

| Device      |     Size | Type / Filesystem   | Mount point |
| ----------- | -------: | ------------------- | ----------- |
| `/dev/sda`  |    20 GB | Disk                | —           |
| `/dev/sda1` |   487 MB | EFI, FAT32          | `/boot/efi` |
| `/dev/sda2` | 19.52 GB | LVM physical volume | —           |

The physical volume `/dev/sda2` belongs to the volume group `V0G`.

### Logical Volumes

| Logical volume |    Size | Filesystem | Mount point |
| -------------- | ------: | ---------- | ----------- |
| `V0G-root`     | 7.45 GB | ext4       | `/`         |
| `V0G-home`     | 3.72 GB | ext4       | `/home`     |
| `V0G-var`      | 6.07 GB | ext4       | `/var`      |
| `V0G-swap`     | 1.86 GB | swap       | —           |

### LVM Free Space

The volume group `V0G` contains approximately 424 MB of unallocated space.

This space was intentionally retained as headroom for future logical-volume extensions or additional logical volumes.

The free space must be considered when reproducing the storage layout.

### Persistent Mount Configuration

The original `/etc/fstab` defines persistent mounts for:

* Root filesystem
* EFI partition
* `/home`
* `/var`
* Swap

The original configuration also contains a CD-ROM mount entry for `/dev/sr0`.

The CD-ROM entry is installation/environment-specific and does not need to be reproduced unless required by the selected base image.

### Reproduction Considerations

The original installation uses LVM with separate logical volumes for `/`, `/home`, `/var`, and swap.

The `add-vm` assignment permits using a minimal base box whose disk layout is determined by the box itself. If this approach is selected, the provisioning must document the base box's storage layout and reproduce additional storage configuration where practical.

The exact original partition sizes are not assumed to be reproduced until the Vagrant base-box strategy is selected.

**Status: Existing storage layout collected. Reproduction strategy pending Stage 19 and the final provisioning design.**
