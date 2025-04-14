# Viewing and Debugging the Boot Process

Understanding the Linux boot process is essential when building your system from scratch. This guide walks through how to view and debug each stage when booting a system like the Raspberry Pi Zero W.

---

## 🧠 Overview of the Boot Process

1. **Boot ROM (SoC)**
   - Executes hardcoded bootloader instructions.
   - Loads `start.elf` from the first FAT32 partition on the SD card.

2. **start.elf (GPU firmware)**
   - Parses `config.txt`.
   - Loads `u-boot.bin` (our second-stage bootloader).

3. **U-Boot**
   - Initializes memory and peripherals.
   - Loads the Linux kernel (`zImage`) and DTB.
   - Passes control to the kernel.

4. **Linux Kernel**
   - Mounts root filesystem.
   - Starts `init` (our first userspace program).

5. **init**
   - Launches shell or init manager (in our case, a basic shell).

---

## 🔍 Ways to View Boot Output

### 1. **UART Serial Console (Recommended)**

Most low-level boot messages are printed to the serial console, not the HDMI port. To see them:

- Connect a USB-to-TTL serial cable to the Pi's UART0 (GPIO14/GPIO15).
- On your host:

```bash
screen /dev/ttyUSB0 115200
# or use picocom / minicom
```

- You’ll see:
  - U-Boot banner
  - Kernel decompression logs
  - Kernel early printks
  - init script execution output

### 2. **Kernel Logging via `dmesg`**

Once booted:
```bash
dmesg | less
```
Shows the kernel's log buffer: drivers, mounts, memory info, etc.

---

## 🧰 Debugging Techniques

### 🔸 U-Boot Debugging
- Enable `CONFIG_CMDLINE` and `CONFIG_CMDLINE_EDITING` to modify bootargs.
- Stop autoboot and type `printenv` to inspect variables.
- Try booting manually:

```bash
load mmc 0:1 0x08000000 zImage
load mmc 0:1 0x08100000 dtb
bootz 0x08000000 - 0x08100000
```

### 🔸 Kernel Arguments
Append these to your `bootargs` to increase verbosity:
- `earlyprintk` — output during early kernel init
- `init=/bin/sh` — drop to shell if init is broken
- `debug ignore_loglevel` — show all kernel messages

### 🔸 Root Filesystem Debugging
- If mount fails, add `rootwait` to ensure kernel waits for SD card.
- Use `init=/bin/sh` to skip init system and get a shell.
- Make sure `/dev/console` exists.

---

## 🚨 Common Boot Failures

| Symptom                        | Likely Cause                            |
|-------------------------------|-----------------------------------------|
| No serial output              | Bad SD image or wrong boot partition    |
| U-Boot shows but kernel hangs| Wrong kernel or DTB, bad bootargs       |
| Kernel panic: no init found  | Missing or broken `/init` script        |
| Shell launches but no commands| Utilities missing from rootfs           |

---

## 🛠 Tools for Help

- `strace /init` — trace system calls
- `ls -l /dev` — check device nodes exist
- `mount` / `df` — check if filesystems are mounted
- `echo $?` — get last command's exit status

---

## ✅ Tip: Log Everything
Attach the UART console and save logs from first boot:
```bash
screen /dev/ttyUSB0 115200 | tee firstboot.log
```

This helps when debugging future changes or failures.


