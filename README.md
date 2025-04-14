# Pi Zero Linux From Scratch: Build Overview

This project builds a complete custom Linux system from scratch for the **Raspberry Pi Zero W (v1)** — without using pre-made distributions, defconfigs, or build systems like Yocto. Everything is cross-compiled manually using an Ubuntu-based Docker container to ensure portability and isolation.

---

## 🧱 Project Structure

This repo is organized into:

- `scripts/` — executable scripts that build and assemble each part of the system
- `rootfs/` — the root filesystem we manually construct
- `boot/` — the FAT32 partition content (kernel, DTB, firmware, U-Boot)
- `build/` — temporary build directory for toolchains, kernel, and BusyBox
- `docs/*.md` — detailed documentation for every component

---

## 🐳 Using the Docker Build Environment

To keep your host clean and ensure consistency across systems, all builds happen in a dedicated Docker container based on Ubuntu.

### Run the Docker environment:
```bash
./run-dev-container.sh
```
This:
- Builds the container if it doesn't exist
- Mounts your project into `/build`
- Grants full privileges (`--privileged`) so you can use `losetup`, `mount`, etc.
- Drops you into a bash shell inside the container

### Image name:
- `pizero-cross:latest`

You can rebuild the container with:
```bash
docker build --no-cache -t pizero-cross:latest -f Dockerfile .
```

---

## 🧭 Build Workflow Overview

Below is the high-level process for building your Linux system:

### 1. Initial Setup
```bash
./scripts/setup-env.sh
```
- Installs required packages in Ubuntu (build-essential, gcc, etc.)
- Creates project folder structure

---

### 2. Fetch Kernel Sources
```bash
./scripts/fetch-kernel.sh
```
- Downloads and unpacks the Linux kernel

---

### 3. Create RootFS Structure
```bash
./scripts/create-rootfs-structure.sh
```
- Creates the expected rootfs directory tree
- Adds `/init` from `init.sh`
- Adds critical symlinks (`/bin`, `/sbin`, `/lib` → `/usr/...`)

---

### 4. Install Kernel Headers
```bash
./scripts/build-kernel.sh
```
- Configures and builds the kernel (`zImage`, DTBs)
- Installs kernel headers into `rootfs/usr/include`

---

### 5. Bootstrap glibc Headers
```bash
./scripts/build-glibc-headers.sh
```
- Installs minimal glibc headers into `rootfs/usr/include`
- Required to compile any userspace software later

---

### 6. Build BusyBox
```bash
./scripts/build-busybox.sh
```
- Builds BusyBox statically for ARMv6 soft-float
- Installs all essential tools (sh, ls, mount, etc.) into rootfs
- Provides a working `/init`, `/bin/sh`, etc.

---

### 7. (Optional) Create Device Tree or Bootloader
```bash
./scripts/create-minimal-dtb.sh
./scripts/create-uboot-setup.sh
```
- Optional tools for customizing device tree and boot config

---

### 8. Check RootFS Sanity
```bash
./scripts/check-rootfs.sh
```
- Verifies that required files and symlinks exist
- Validates basic completeness before image creation

---

### 9. Create Bootable System Image
```bash
./scripts/build-system-image.sh
```
- Builds a partitioned SD card image with `/boot` (FAT32) and `/` (ext4)
- Mounts the partitions, copies content, detaches loop devices
- Outputs: `sdcard.img`

Flash to SD card with:
```bash
dd if=sdcard.img of=/dev/sdX bs=4M status=progress conv=fsync
```

---

## 📚 Documentation
For in-depth detail on each step, see the following:
- `docs/rootfs.md` — directory layout, init, and devtmpfs
- `docs/kernel-configuration.md` — configuring the Linux kernel
- `docs/glibc.md` — bootstrapping glibc headers
- `docs/busybox.md` — using BusyBox as a complete userspace
- `docs/building-utilities-and-system-image.md` — image creation

---

## ✅ Final Notes
- Everything is cross-compiled with `arm-linux-gnueabi-`
- All utilities are statically linked
- The result is a bootable Pi Zero system using minimal hand-rolled components

This project is ideal for learning, debugging, and deploying tightly controlled embedded Linux systems.


