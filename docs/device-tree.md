# Raspberry Pi Zero W Device Tree Deep Dive

This document explains the purpose and structure of the Device Tree for the Raspberry Pi Zero W. It covers the full DTS file found in the upstream kernel and provides a stripped-down version for minimal boot, with the aim of building knowledge incrementally.

---

## What is a Device Tree?

### How does ACPI/BIOS work on x86?
On x86 systems, firmware like BIOS or UEFI initializes and describes hardware devices via ACPI (Advanced Configuration and Power Interface). ACPI tables passed to the OS describe:
- CPUs and their capabilities
- Memory ranges
- Devices and buses (PCI, USB, etc.)
- Interrupt routing, I/O ports, DMA channels

This lets x86 systems automatically detect and configure devices. ARM platforms don't have a standardized firmware interface, so we use the Device Tree to do this manually.

The Device Tree is a data structure passed to the kernel at boot that describes the hardware layout of the system. It's essential on platforms like ARM where there is no standard mechanism (like x86's ACPI/BIOS) to enumerate devices.

A Device Tree:
- Describes CPU, memory, peripherals, and buses.
- Is compiled from DTS (Device Tree Source) to DTB (Device Tree Blob).
- Allows the kernel to load only the drivers it needs for the platform.

---

## Original DTS Breakdown

The original DTS for the Pi Zero W includes multiple `#include` statements, pulling in common SoC and board-specific definitions:

```dts
#include "bcm2835.dtsi"
#include "bcm2835-rpi.dtsi"
#include "bcm2835-rpi-common.dtsi"
#include "bcm283x-rpi-led-deprecated.dtsi"
#include "bcm283x-rpi-usb-otg.dtsi"
#include "bcm283x-rpi-wifi-bt.dtsi"
```

Each of these includes contributes the following:

| Include | Description |
|--------|-------------|
| `bcm2835.dtsi` | Defines the core SoC layout: CPU, memory controller, DMA, clocks. |
| `bcm2835-rpi.dtsi` | Adds shared peripherals and buses common to all RPi boards. |
| `bcm2835-rpi-common.dtsi` | Common baseboard properties (power regulators, HDMI, etc.). |
| `bcm283x-rpi-led-deprecated.dtsi` | Legacy LED node (often replaced by `led_act`). |
| `bcm283x-rpi-usb-otg.dtsi` | USB OTG controller and power switches. |
| `bcm283x-rpi-wifi-bt.dtsi` | Wi-Fi/BT combo chip configuration. |

### Top-Level Nodes

```dts
/ {
  compatible = "raspberrypi,model-zero-w", "brcm,bcm2835"; // Tells the kernel what board and SoC this matches
  model = "Raspberry Pi Zero W"; // Human-readable name

  memory@0 {
    device_type = "memory";
    reg = <0 0x20000000>; // 512MB RAM
  };

  chosen {
    stdout-path = "serial1:115200n8"; // UART console over mini UART (ttyS1)
  };
};
```

This defines the board name, total memory, and UART console.

---

## Minimal Stripped-Down DTS

### Where to place the DTS and how to use it
To integrate your custom minimal DTS into the kernel build:

1. **Placement**:
   - Save the file as `rpi-zero-w-minimal.dts`
   - Place it in the kernel source under: `arch/arm/boot/dts/`

2. **Compile the DTB manually**:
   ```bash
   make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- dtbs
   ```
   - This will generate: `arch/arm/boot/dts/rpi-zero-w-minimal.dtb`

3. **Use it at boot**:
   - Copy the `.dtb` to the first (boot) partition of your Pi’s SD card. This is the /boot folder in this repo.
   - In `config.txt`, add or replace the line:
     ```
     device_tree=rpi-zero-w-minimal.dtb
     ```

   This ensures the firmware loads your custom DTB instead of the default one.

---

Here’s a minimal DTS file for the Raspberry Pi Zero W that boots the board with UART and SD card:

```dts
/dts-v1/;
#include "bcm2835.dtsi"

/ {
  compatible = "raspberrypi,model-zero-w", "brcm,bcm2835";
  model = "Raspberry Pi Zero W";

  memory@0 {
    device_type = "memory";
    reg = <0 0x20000000>; // 'reg' = <start-address size>. Here: start at 0x00000000, size 512MB.
};

  chosen {
    stdout-path = "serial1:115200n8"; // Tells the kernel which device to use for early boot messages (console output)
};
};

&uart1 {
  status = "okay";
};

&sdhost {
  status = "okay";
  bus-width = <4>; // Specifies the width of the SD data bus. 4-bit mode gives higher throughput than 1-bit.
};
```

This setup includes:
- SoC base with `bcm2835.dtsi`
- Memory declaration
- Console via `uart1` (mini UART)
- SD card via `sdhost`

---

## Using the Full Upstream Device Tree Instead

In some cases, especially for feature-complete systems or when starting from a known-good baseline, you may want to use the **full upstream DTB** rather than maintaining your own stripped-down version.

To do this:

1. **Use the pre-defined board DT** from the kernel tree:
   - Example for Pi Zero W:
     ```bash
     make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- bcmrpi_defconfig
     make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- zImage dtbs
     ```
   - This builds all default device trees for Raspberry Pi boards.
   - The relevant DTB will be generated as:
     ```
     arch/arm/boot/dts/broadcom/bcm2835-rpi-zero-w.dtb
     ```

2. **Install the DTB** to your SD card boot partition. This is the /boot folder in this repo:
   ```bash
   cp arch/arm/boot/dts/broadcom/bcm2835-rpi-zero-w.dtb /path/to/boot/partition/
   ```

3. **Configure `config.txt`**:
   ```
   device_tree=bcm2835-rpi-zero-w.dtb
   ```

4. (Optional) Inspect or modify the full DT source:
   ```bash
   dtc -I dtb -O dts -o full-decoded.dts arch/arm/boot/dts/broadcom/bcm2835-rpi-zero-w.dtb
   ```
   This allows you to audit all included features and devices for inspiration or pruning.

Using the full upstream tree is a great way to ensure maximum hardware compatibility while building confidence. Once you understand what parts are needed, you can switch to a minimal one and start trimming from there.

---

