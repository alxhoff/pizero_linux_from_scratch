### 1. Clone and Build U-Boot

U-Boot provides board-specific default configurations called `defconfig` files. These predefine the build settings for particular boards.

In our case:

- **`rpi_0_w_defconfig`** is the default configuration for the **Raspberry Pi Zero W**.
- It selects the correct SoC (BCM2835), memory layout, UART, MMC support, and other hardware-specific options.
- It ensures the resulting `u-boot.bin` is tailored for the Pi Zero W and is bootable by the GPU firmware.

Run the following to build it:

```bash
git clone https://source.denx.de/u-boot/u-boot.git
cd u-boot
git checkout v2024.01  # or your chosen stable version
make rpi_0_w_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j$(nproc)
```


