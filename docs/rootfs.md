# Root Filesystem Setup (rootfs)

This document explains the full process of manually creating and preparing a minimal root filesystem (`rootfs`) for a Raspberry Pi Zero W. This approach is designed for a Linux-from-scratch system and reflects our improved method using BusyBox and a statically created shell script as init.

---

## Why Manually Build a RootFS?

Manually creating the root filesystem helps you:

- Learn how Linux initializes a system from scratch
- Understand the purpose of critical directories and files
- Debug minimal boot failures effectively
- Create portable, minimal systems for embedded targets

This approach avoids heavy build systems like Yocto or Buildroot and favors transparency over automation.

---

## What This Script Does

The `scripts/create-rootfs-structure.sh` script is responsible for:

1. Creating the minimal folder layout of a Linux root filesystem
2. Adding essential symlinks for `/bin`, `/sbin`, and `/lib`
3. Copying your custom `init.sh` into the rootfs and marking it executable

---

## What the Directory Structure Looks Like

### Command:
```bash
mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,dev,tmp,var,mnt,home}
mkdir -p "$ROOTFS"/usr/{bin,sbin,lib}
```

### Meaning of Each Directory:
- **`/bin`** → Essential user commands (e.g., `sh`, `cp`, `ls`)
- **`/sbin`** → System administration commands (e.g., `init`, `mount`)
- **`/etc`** → Static system configuration (e.g., `fstab`, `inittab`)
- **`/proc`** → Kernel-provided virtual filesystem for process info
- **`/sys`** → Kernel device and system information
- **`/dev`** → Device files (e.g., `/dev/console`, `/dev/null`) via `devtmpfs`
- **`/tmp`** → Temporary files, often RAM-backed (`tmpfs`)
- **`/var`** → Variable files (e.g., logs, spool files)
- **`/mnt`** → Mount point for temporary/manual mounts
- **`/home`** → Optional user home directories
- **`/usr/bin`, `/usr/sbin`, `/usr/lib`** → Where BusyBox and linked libraries live

---

## Creating Essential Symlinks

### Command:
```bash
ln -sf usr/bin "$ROOTFS/bin"
ln -sf usr/sbin "$ROOTFS/sbin"
ln -sf usr/lib "$ROOTFS/lib"
```

### Why These Symlinks Matter:
- Linux expects `/bin/sh`, `/sbin/init`, and `/lib/ld-linux.so` to exist
- By symlinking to `/usr/...`, we can keep all actual binaries in one place
- This keeps your rootfs simpler and avoids duplication

This approach is compatible with BusyBox and embedded best practices.

---

## Adding the Init Script

Your `init.sh` script defines what runs as PID 1 — the first userspace process after kernel boot. It is installed by this logic:

### Logic:
```bash
INIT_SRC="$PROJECT_ROOT/init.sh"
INIT_DST="$ROOTFS/init"

if [ -f "$INIT_SRC" ]; then
    cp "$INIT_SRC" "$INIT_DST"
    chmod +x "$INIT_DST"
fi
```

### What `init.sh` Typically Looks Like:
```sh
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs devtmpfs /dev

exec /bin/sh
```

This script ensures:
- Basic virtual filesystems are mounted
- A shell is launched for debugging or manual commands

It should be marked executable and referenced via `init=/init` in `cmdline.txt`.

---

## Kernel Dependency

Your kernel must be configured with:
- `CONFIG_DEVTMPFS=y`
- `CONFIG_DEVTMPFS_MOUNT=y`

These allow `/dev` to auto-populate with device nodes and remove the need to `mknod` them manually.

---

## Next Step: Populate with BusyBox

Once this rootfs layout is in place:
- Build BusyBox with `CONFIG_STATIC=y` and install it with `CONFIG_PREFIX=$ROOTFS`
- BusyBox will populate `/usr/bin`, `/usr/sbin`, etc.
- The `/init` script will start BusyBox's `sh`, enabling a working minimal shell

At this point, you can create a bootable SD image with this rootfs.

---

## Summary
- This structure is required for kernel boot → `init` → shell flow
- All core folders are created manually for transparency
- Symlinks ensure paths like `/bin/sh` work without duplication
- `init.sh` becomes PID 1 and mounts necessary virtual filesystems

This rootfs is the foundation of your minimal Linux system.


