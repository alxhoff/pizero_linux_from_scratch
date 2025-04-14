# Enabling Networking on the Raspberry Pi Zero W

This guide explains how to enable networking (specifically Wi-Fi) on a minimal Raspberry Pi Zero W system, including all required changes to the device tree, kernel configuration, firmware, and userspace tools.

---

## 🧠 Overview
To enable Wi-Fi networking, we must:

1. Enable and configure the required nodes in the device tree
2. Build kernel support for wireless networking and the Broadcom driver
3. Install firmware blobs for the Wi-Fi chip
4. Add required userspace tools to configure and manage networking
5. Bring up the interface manually

---

## 1. Device Tree Configuration

If you are not building a custom minimal device tree and want a reliable, working configuration for Wi-Fi and Bluetooth, the simplest option is to include the official Raspberry Pi overlay:

```dts
#include "bcm283x-rpi-wifi-bt.dtsi"
```

This file sets up the SDIO (`mmc1`) interface, Wi-Fi power sequencing, required GPIOs, and Bluetooth via UART0. It ensures compatibility with the onboard Broadcom combo chip used in the Raspberry Pi Zero W.

This approach is **recommended** for functional systems unless your goal is to learn by manually recreating the full configuration from scratch.

---

### 📄 Manual Minimal Device Tree Example (Explained)

- The SDIO interface (`sdhci`) with the Broadcom Wi-Fi chip as a child node
- Power sequencing through a simple GPIO-based regulator
- Bluetooth support over UART0


### 📡 What is SDIO?
SDIO (Secure Digital Input Output) is an extension of the standard SD (Secure Digital) interface used not just for storage cards, but also to connect peripheral devices like Wi-Fi and Bluetooth chips. It uses the same physical and electrical interface as SD cards, but instead of acting as a block storage device, it transfers data packets to and from a peripheral controller.

In the Raspberry Pi Zero W, the onboard Broadcom Wi-Fi/BT chip is connected via SDIO, using the secondary SD host controller (`mmc1`). Enabling the correct GPIOs and mmc nodes in the device tree is necessary to allow the kernel and drivers to initialize and communicate with this device.


The Raspberry Pi Zero W uses an onboard Broadcom Wi-Fi/BT combo chip connected via SDIO. To enable it:

- Make sure your device tree includes:
  ```dts
  #include "bcm283x-rpi-wifi-bt.dtsi"
  ```
  This file sets up the `mmc1` SDIO interface and the required GPIOs.

- If you're building from a minimal device tree, you can reintroduce only the required parts:

  - Enable the SDIO interface via GPIO:
    ```dts
    &mmc {
        status = "okay";
        brcm,sdhci; // Enables internal Broadcom SDHCI for SDIO
    };
    ```

  - Add the `wifi_pwrseq` node for the chip's power management:
    ```dts
    wifi_pwrseq: wifi-pwrseq {
        compatible = "mmc-pwrseq-simple";
        reset-gpios = <&gpio 41 GPIO_ACTIVE_LOW>;
    };
    ```

  - Link the power sequence to mmc1:
    ```dts
    &mmc1 {
        vmmc-supply = <&vdd_3v3_reg>;
        mmc-pwrseq = <&wifi_pwrseq>;
        non-removable;
        status = "okay";
    };
    ```

---

## 2. Kernel Configuration

In your kernel configuration (`make menuconfig`), you must enable support for wireless networking and the specific driver used by the Pi Zero W’s Broadcom Wi-Fi chip.

### Required Wireless Stack:
- `CONFIG_CFG80211` – This is the central configuration API for Linux wireless drivers. It provides the common infrastructure that Wi-Fi drivers plug into.
- `CONFIG_MAC80211` – This is the core implementation of the IEEE 802.11 protocol. Drivers like `brcmfmac` rely on this to handle things like association, scanning, and encryption.

### Required Driver:
- `CONFIG_BRCMFMAC` – This is the FullMAC driver for Broadcom Wi-Fi chips. "FullMAC" means the chip handles most of the MAC-layer protocol itself.
- `CONFIG_BRCMUTIL` – A helper module needed by Broadcom wireless drivers.

### Optional (but useful):
- `CONFIG_BT_HCIUART` – Enables Bluetooth support over UART. Useful if you want to enable the onboard Bluetooth chip later.
- `CONFIG_CRYPTO_LIB_SHA256` – Needed for WPA and WPA2 support when using tools like `wpa_supplicant`.

### Build Type:
You can build these features either as modules (`<M>`) or built-in (`<*>`).
- **Built-in**: Easier for minimal setups without module loading infrastructure.
- **Modules**: More flexible, but require module loading tools (e.g. `modprobe`) and may increase rootfs complexity.

To simplify early testing and bootstrapping, it's recommended to build these directly into the kernel (`<*>`) at first.

---

## 3. Firmware Installation

The Broadcom Wi-Fi chip requires proprietary firmware:

- Download from Raspberry Pi firmware repository:
```bash
git clone https://github.com/RPi-Distro/firmware-nonfree
cp firmware-nonfree/brcm/brcmfmac43430-sdio.* rootfs/lib/firmware/brcm/
```

Files needed:
- `brcmfmac43430-sdio.bin`
- `brcmfmac43430-sdio.txt`

Create the directory if it doesn't exist:
```bash
mkdir -p rootfs/lib/firmware/brcm
```

---

## 4. Userspace Tools

To use networking on a minimal Linux system, you need a few essential userspace tools. These handle things the kernel does not do on its own — like configuring Wi-Fi, bringing up network interfaces, and getting an IP address.

### Required Tools and What They Do:

- `wpa_supplicant` – This tool negotiates with WPA/WPA2 protected wireless networks. It communicates with the kernel wireless stack (via nl80211 or wext) to connect to access points securely using credentials defined in a config file.

- `ip` (from `iproute2`) – Replaces older tools like `ifconfig` and `route`. It is used to bring up interfaces, assign IP addresses, manage routes, and view interface status.

- `udhcpc` (from BusyBox) or `dhcpcd` – These tools act as DHCP clients. They request an IP address from your router and configure the network interface accordingly. `udhcpc` is small and minimal; `dhcpcd` is more feature-rich.

All of these tools must be installed into your rootfs using your cross-toolchain, or alternatively as statically linked binaries if built natively. They are necessary for dynamic and secure network configuration at runtime.

Install into your rootfs using your cross-toolchain or native statically-linked builds.

### Example wpa_supplicant config:
Create `/etc/wpa_supplicant.conf`:
```conf
network={
    ssid="YourSSID"
    psk="YourPassword"
}
```

---

## 5. Bringing Up Wi-Fi

After booting and logging in via serial:

```bash
ip link set wlan0 up
wpa_supplicant -i wlan0 -c /etc/wpa_supplicant.conf -B
udhcpc -i wlan0  # or dhcpcd wlan0
```

---

## 🔁 6. Auto-Configuration at Boot

To automate network bring-up at boot, create an init script.

### Example: `/etc/init.d/network`
```sh
#!/bin/sh

ip link set wlan0 up
wpa_supplicant -i wlan0 -c /etc/wpa_supplicant.conf -B
udhcpc -i wlan0
```

Make it executable:
```bash
chmod +x /etc/init.d/network
```

Then call it from `/init` or your boot init system:
```sh
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

/etc/init.d/network &
exec /bin/sh
```

This ensures networking is started automatically during boot.


You should now have network access. Verify with:
```bash
ip a
ping 8.8.8.8
```

---

## ✅ Summary

To enable networking:
- Device tree: enable `mmc1`, GPIOs, `wifi_pwrseq`
- Kernel: enable Broadcom and wireless drivers
- Firmware: install `brcmfmac43430-sdio.*` to `/lib/firmware/brcm`
- Userspace: use `wpa_supplicant` and DHCP client
- Test via UART shell



