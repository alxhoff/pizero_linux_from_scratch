# U-Boot Setup for Raspberry Pi Zero W

This guide walks through integrating U-Boot into the Raspberry Pi Zero W boot process. Rather than letting the Raspberry Pi firmware boot the kernel directly, we use U-Boot as a flexible, scriptable second-stage bootloader.

---

## 📦 Why Use U-Boot?

While the Raspberry Pi firmware can boot a kernel directly, U-Boot adds essential features for embedded development:

- Interactive shell over UART for debugging
- Scriptable logic (via `boot.cmd` / `boot.scr`)
- Modular loading of kernel, DTB, and initrd from various sources
- Networking and USB booting options
- Easier diagnostics when debugging boot failures

Using U-Boot gives you a boot environment closer to other embedded SoCs, helping generalise your kernel bring-up skills.

---

## 🧠 Boot Sequence Overview

On the Raspberry Pi Zero W (BCM2835), the boot chain looks like this:

1. **GPU boot ROM (in SoC)**
   - Hardcoded to read from SD card's first FAT32 partition

2. **Firmware files**
   - Loads `bootcode.bin`, `start.elf`, and `fixup.dat`

3. **Reads `config.txt`**
   - Configures SoC peripherals
   - Specifies the file to boot (default: `kernel.img`, but we override to `u-boot.bin`)

4. **U-Boot runs (`u-boot.bin`)**
   - Reads and interprets `boot.scr` or environment
   - Loads kernel (`zImage`), DTB, sets `bootargs`, and boots Linux

5. **Linux kernel starts**
   - Mounts rootfs, starts `/init`

---

## 🔧 Step-by-Step Instructions

### 1. Clone and Build U-Boot

```bash
git clone https://source.denx.de/u-boot/u-boot.git
cd u-boot
git checkout v2024.01  # or latest stable
make rpi_0_w_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j$(nproc)
```

This produces `u-boot.bin` in the root directory. It's the file the firmware will execute.

### 2. Prepare the Boot Partition (FAT32)

Copy the following files to the **boot** partition of your SD card:

#### Raspberry Pi firmware files:

- **`bootcode.bin`** — First-stage bootloader file. It initializes SDRAM and loads the next-stage firmware. Required for older models like Pi Zero.
- **`start.elf`** — Main GPU firmware binary. It loads the kernel (or U-Boot in our case), manages peripherals, and handles HDMI output.
- **`fixup.dat`** — Used with `start.elf` to fine-tune low-level hardware setup (e.g. memory split, display config, USB). Must match the version of `start.elf`.

These are proprietary but essential for the GPU-based boot chain to work.

#### Your custom files:

- `u-boot.bin` — U-Boot binary built for the Pi
- `config.txt` — Firmware configuration for enabling UART and loading U-Boot

> You can extract firmware files from the official [raspberrypi/firmware](https://github.com/raspberrypi/firmware/tree/master/boot) GitHub repository. from the official [raspberrypi/firmware](https://github.com/raspberrypi/firmware/tree/master/boot) GitHub repository.

---

### 3. Create `config.txt`

```ini
kernel=u-boot.bin
disable_commandline_tags=1
disable_splash=1
disable_overscan=1
dtparam=audio=off
enable_uart=1
```

- `kernel=u-boot.bin`: tells firmware to boot U-Boot, not Linux directly
- `disable_commandline_tags=1`: let U-Boot handle kernel args
- `enable_uart=1`: enables serial output (UART0)

---

### 4. Create U-Boot Boot Script

U-Boot allows booting Linux using commands embedded in a script file. This lets you define exactly how the kernel and device tree are loaded, and what parameters are passed to the kernel at boot.

Create a file named `boot.cmd`:

```bash
setenv bootargs console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootwait rw init=/init
load mmc 0:1 0x08000000 zImage
load mmc 0:1 0x08100000 bcm2835-rpi-zero-w.dtb
bootz 0x08000000 - 0x08100000
```

#### 🔍 Line-by-Line Explanation:

- `setenv bootargs ...` — Sets the kernel command line (`/proc/cmdline`) passed to Linux. This includes:
  - `console=ttyAMA0,115200`: use the UART0 serial console for output/input
  - `root=/dev/mmcblk0p2`: where the root filesystem is
  - `rootwait`: tells the kernel to wait for the root device
  - `rw`: mount root filesystem read-write
  - `init=/init`: run our custom init script (instead of `/sbin/init`)

- `load mmc 0:1 0x08000000 zImage` — Load the Linux kernel image (`zImage`) from partition 1 of the SD card (FAT32) into RAM address `0x08000000`
- `load mmc 0:1 0x08100000 bcm2835-rpi-zero-w.dtb` — Load the device tree binary into RAM address `0x08100000`

> These memory addresses must be in RAM and must not overlap. U-Boot expects:
> - The kernel image to be at a known executable location (`0x08000000` is common for ARM zImage)
> - The DTB to be placed in RAM and passed as a pointer to the kernel
>
> The kernel itself will read the DTB from the provided address during early boot. Choosing `0x08100000` ensures the DTB does not overwrite the kernel image during boot.

- `bootz 0x08000000 - 0x08100000` — Boot the kernel using the loaded image and device tree. The `-` in the middle means no initramfs is used.` — Boot the kernel using the loaded image and device tree. The `-` in the middle means no initramfs is used.

This script gives full control over how the system boots and can be adjusted for different rootfs setups or multiple kernels.

Then compile it into a binary boot script:

```bash
mkimage -A arm -T script -C none -n "boot script" -d boot.cmd boot.scr
```

Copy `boot.scr` to your boot partition.

> U-Boot will automatically execute `boot.scr` if present.

---

## 🧪 Testing

Ensure your SD card:
- Has a FAT32 first partition with:
  - `bootcode.bin`, `start.elf`, `fixup.dat`
  - `u-boot.bin`, `config.txt`, `boot.scr`, `zImage`, and `.dtb`
- Has a second partition with your ext4 rootfs

Then power up the Pi via UART and watch U-Boot's output. It should print messages and then boot Linux.

---

## ✅ Summary

| Component        | Location         | Purpose                         |
|------------------|------------------|----------------------------------|
| `u-boot.bin`     | FAT32 /boot      | Bootloader launched by firmware |
| `boot.scr`       | FAT32 /boot      | Boot logic/script               |
| `zImage`         | FAT32 /boot      | Kernel image                    |
| `.dtb`           | FAT32 /boot      | Device tree                     |
| `rootfs`         | ext4 partition 2 | Actual root filesystem          |

With this setup, you now have a portable, inspectable, scriptable bootloader environment.

---

## ▶️ Next Steps

Now that U-Boot is integrated and Linux can boot reliably, the next steps will continue expanding the environment and improving flexibility:

### 1. **Add Support for Multiple Kernel Setups**
- Create alternate `boot.cmd` scripts (e.g. with different `init` or `root=` options)
- Use U-Boot variables or menu-based selection to toggle between them

### 2. **Enable USB or Network Booting**
- Add USB support in U-Boot to allow loading the kernel and rootfs from a flash drive
- Optionally enable U-Boot networking and TFTP boot for remote testing or NFS root

### 3. **Automate U-Boot Environment Setup**
- Store persistent variables in U-Boot’s environment
- Use scripts to switch rootfs targets or set boot modes

### 4. **Introduce Initramfs (Optional)**
- Add support for initramfs and test fallback rootfs handoff

### 5. **Explore Secure Boot and Boot Integrity (Advanced)**
- Introduce verified boot flow using U-Boot's FIT image and signed payloads

We’ll continue building on this with new documentation and scripts to cover each of these use cases.


