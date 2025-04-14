# Bootstrapping glibc for a Custom Linux RootFS

This document explains the role of glibc in a Linux system, and how to manually install the minimum headers required to bootstrap a root filesystem. This is a critical early step in making your Linux-from-scratch system usable.

---

## 🧠 What is glibc?

**glibc (GNU C Library)** is the standard C runtime used by almost all Linux systems. It provides the core APIs that allow userspace programs to interact with the kernel via syscalls, and offers a wide range of libc functions like:

- `printf`, `open`, `read`, `write`
- `malloc`, `free`
- `execvp`, `fork`, `wait`
- `time`, `locale`, `errno`, etc.

Without glibc, userspace programs cannot function unless they are statically linked against an alternative libc (like musl or dietlibc).

### What glibc provides:
- **Headers**: used at **compile time** when building userspace programs (via GCC)
- **Libraries**: needed at **runtime** to execute dynamically linked binaries

Both must be installed into your root filesystem if you want to compile or run standard Linux applications.

---

## 🔄 glibc vs Kernel

The Linux kernel provides only low-level syscalls and interfaces. glibc wraps these in user-friendly C functions.

- Kernel provides: raw syscalls (via `int 0x80` or `svc #0` on ARM)
- glibc provides: `printf()`, `fopen()`, `execve()` — which internally make syscalls

This boundary means: **programs don’t compile directly against the kernel, but against glibc**, which in turn talks to the kernel.

---

## 📦 Installing glibc headers (bootstrapping stage)

Before you can build utilities or compile BusyBox or glibc itself, you need **minimal glibc headers** installed in your rootfs.

This is done with:
```bash
scripts/build-glibc-headers.sh
```

### What this script does:
```bash
#!/bin/bash
set -e

TARGET=arm-linux-gnueabi
GLIBC_VERSION=2.33
PROJECT_ROOT="$(cd \"$(dirname \"$0\")/..\" && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"
JOBS=$(nproc)

mkdir -p "$PROJECT_ROOT/build"
cd "$PROJECT_ROOT/build"

wget -nc https://ftp.gnu.org/gnu/libc/glibc-$GLIBC_VERSION.tar.xz
rm -rf glibc-$GLIBC_VERSION && tar -xf glibc-$GLIBC_VERSION.tar.xz

mkdir -p glibc-build && cd glibc-build

../glibc-$GLIBC_VERSION/configure \
  --prefix=/usr \
  --host=$TARGET \
  --build=$(../glibc-$GLIBC_VERSION/scripts/config.guess) \
  --with-headers=$ROOTFS/usr/include \
  --disable-multilib \
  --disable-werror \
  --disable-shared \
  --disable-nls

make install-bootstrap-headers=yes install-headers install_root="$ROOTFS"

# Ensure gnu/stubs.h exists
mkdir -p "$ROOTFS/usr/include/gnu"
touch "$ROOTFS/usr/include/gnu/stubs.h"
```

---

## 🧱 Why We Only Install Headers (Not glibc libs yet)

At this stage:
- You do **not** need glibc's `.so` shared libraries
- You're only preparing the rootfs to build other critical tools (like BusyBox or your own libc)

This is known as the **Stage 1 bootstrap**, and is commonly used in:
- Linux From Scratch
- crosstool-NG
- Minimal embedded systems

The goal: **make the rootfs ready to compile other things**.

---

## Where Headers Are Installed

After the script completes, you'll have:
```bash
rootfs/usr/include/
rootfs/usr/include/stdio.h
rootfs/usr/include/sys/types.h
rootfs/usr/include/gnu/stubs.h
```

These headers are used when:
- Building BusyBox
- Building a native GCC for the target
- Compiling C apps natively in the chroot

---

## ⚠️ Note on `gnu/stubs.h`

Some tools expect this file to exist even if it is empty. We manually create it to satisfy such expectations:
```bash
touch $ROOTFS/usr/include/gnu/stubs.h
```

---

## Summary
- glibc is essential for compiling and running C programs on Linux
- Installing headers into the rootfs allows you to build other programs for the target
- The `build-glibc-headers.sh` script bootstraps just the **headers**
- No glibc `.so` files or full libraries are needed at this stage

Next steps after this:
- Compile BusyBox
- Optionally build and install the full glibc if you need dynamic linking
- Or use static BusyBox and build a full userland later

This header bootstrap is the **foundation** for compiling a Linux system from scratch.


