# Kernel Configuration for Raspberry Pi Zero W (v1)

This guide walks you through the *manual* configuration of the Linux kernel for the Raspberry Pi Zero W (ARM1176JZF-S, ARMv6). It assumes you are not using any vendor-provided defconfig and want to build a minimal, bootable kernel from scratch for a custom system.

---

## Why Manual Configuration?

In embedded and low-level Linux systems, understanding exactly which kernel features are enabled gives you:

- A smaller, faster kernel
- Full control over hardware support and userspace integration
- Greater knowledge of the hardware-software interface
- Easier debugging and modification

Vendor configs often enable hundreds of irrelevant features and pull in dependencies you don’t need.

---

## Default Config Strategy

### ✅ Start minimal with `allnoconfig`
For absolute control:
```bash
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- allnoconfig
```
This creates a minimal `.config`. Then run `make menuconfig` to manually enable only the features you need:
- SD/MMC
- Serial console
- Root filesystem (e.g. ext4, tmpfs)
- Device Tree

### 🧩 Or use `bcm2835_defconfig` as a base
If you want a functioning starting point to trim from:
```bash
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- bcm2835_defconfig
```
This includes support for Pi peripherals, USB, networking, audio, framebuffer, and more. It's a good baseline if you prefer not to configure everything manually.

---

## Launching Menuconfig

After cloning the mainline kernel and setting your environment:
```bash
make mrproper
make menuconfig
```
Ensure:
```bash
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabi-
```

---

## What is initramfs?

An **initramfs** (initial RAM filesystem) is a temporary root filesystem loaded into memory by the kernel at boot time. It's typically used to:

- Load essential drivers before the real root filesystem is available (e.g. disk, flash)
- Perform early init tasks (e.g., decrypting partitions, scanning for LVM, RAID)
- Handle rootfs switching or custom boot logic (e.g., pivot_root)

It is a gzip-compressed cpio archive either embedded directly into the kernel image or loaded externally.

For this project, we **are not using initramfs initially**, because:
- We aim to boot directly into a minimal static root filesystem (rootfs) on the SD card
- The Pi Zero's boot process (via firmware + config.txt) loads the kernel and DT directly, then the kernel mounts the rootfs

You can add initramfs support later for things like:
- Boot-time hardware setup
- Rootfs overlays or hybrid images
- Making the system more modular or initrd-based rescue environments

To enable it:
- Set `CONFIG_BLK_DEV_INITRD=y`
- Provide `initramfs.cpio.gz` or configure the kernel to embed it directly via `CONFIG_INITRAMFS_SOURCE`

---

## Key Sections to Configure

Below is a comprehensive breakdown of each important kernel config area with explanations of what each option does, why it is needed, and how it applies to the Raspberry Pi Zero W.

---

### 1. General Setup
- `CONFIG_LOCALVERSION="-rpi0"`: Add a suffix to the kernel version string. This helps differentiate between kernel builds.
- `CONFIG_BLK_DEV_INITRD`: Enables initial RAM disk (initramfs) support. Even though we're not using it now, it's useful for recovery setups and rootfs overlays.
- `CONFIG_KERNEL_ZIMAGE`: Ensures the kernel builds a compressed `zImage`, which is required by the Pi firmware.

### 2. System Type → ARM system type
- `CONFIG_ARCH_BCM2835`: Selects the Broadcom SoC family used by the Pi Zero W. This enables access to SoC-specific drivers.
- `CONFIG_CLK_BCM2835`: Enables the clock controller for peripherals like UART, SDIO, and SPI. Required for almost all functioning hardware.
- `CONFIG_BCM2835_WDT`: Watchdog support for auto-reboot if the system hangs. Useful in remote or embedded applications.
- `CONFIG_BCM2835_THERMAL`: Allows monitoring SoC temperature — good for performance tuning or thermal protection.
- `CONFIG_RASPBERRYPI_POWER`: Enables power domain management, essential for powering up/down USB and video peripherals.
- `CONFIG_HW_RANDOM_BCM2835`: Enables the hardware RNG, improving entropy — valuable for cryptography (e.g., SSH).
- `CONFIG_BCM2835_MBOX`, `CONFIG_RASPBERRYPI_FIRMWARE`: Provides communication with the GPU firmware, needed for framebuffer, clock control, and other firmware-driven features.

### 3. Processor Type and Features
- `CONFIG_CPU_ARM1176`: Specific to the ARM1176JZF-S CPU. Enables correct cache, MMU, and instruction set support.
- `CONFIG_ARM_THUMB`: Enables support for the Thumb 16-bit compressed instruction set. This helps reduce code size in memory-constrained systems.
- `CONFIG_AEABI`: Enables the ARM EABI calling convention, ensuring compatibility with toolchains and libraries.
- `CONFIG_VFP`: Enables hardware floating-point support via the Vector Floating Point unit (VFPv2 on Pi Zero).

### 4. Kernel Features
- `CONFIG_HIGHMEM`: Enables support for memory above 896MB. Not strictly required on Pi Zero (512MB), but good practice.
- `CONFIG_FUTEX`: Enables fast userspace mutexes, required by modern libraries (e.g., glibc, pthreads).
- `CONFIG_MODULES`: Enables loadable kernel module support — useful for separating drivers or testing modules.

### 5. Boot Options
- Set default kernel command line (CONFIG_CMDLINE): `console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootwait`
  - `ttyAMA0`: UART output
  - `115200`: baud rate
  - `root=`: defines rootfs location (usually second partition)
  - `rootwait`: waits for device node before trying to mount

### 6. Device Drivers
- `CONFIG_GPIO_SYSFS`, `CONFIG_PINCTRL_BCM2835`: Enables general-purpose IO with user-space access.
- `CONFIG_LEDS_CLASS`, `CONFIG_LEDS_GPIO`: LED support — useful for onboard or user-defined indicators.
- `CONFIG_MMC`, `CONFIG_MMC_BCM2835`, `CONFIG_MMC_BLOCK`: Needed to access SD cards.
- `CONFIG_SERIAL_AMBA_PL011`, `CONFIG_SERIAL_AMBA_PL011_CONSOLE`: Enables the main serial port for console output.
- `CONFIG_USB`: Core USB stack
- `CONFIG_USB_GADGET`, `CONFIG_USB_ETH`, `CONFIG_USB_MASS_STORAGE`: Enables USB OTG device modes like Ethernet-over-USB or storage gadgets.
- `CONFIG_INPUT`, `CONFIG_INPUT_EVDEV`: Enables input event support for devices like keyboards.
- `CONFIG_INET`: Enables IPv4 networking
- `CONFIG_IP_PNP`, `CONFIG_IP_PNP_DHCP`: Enables IP autoconfiguration (e.g., DHCP)
- `CONFIG_EXT4_FS`: Required for ext4 root filesystem
- `CONFIG_PROC_FS`: Enables `/proc` virtual filesystem
- `CONFIG_TMPFS`: Enables `tmpfs`, needed for `/tmp`, `/run`, etc.
- `CONFIG_DEVTMPFS`, `CONFIG_DEVTMPFS_MOUNT`: Automatically mounts `/dev` using devtmpfs — critical for dynamic device nodes

