#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BOOT_DIR="$PROJECT_ROOT/boot"
UBOOT_DIR="$PROJECT_ROOT/u-boot"

mkdir -p "$BOOT_DIR"
# Make sure directory exists before curl writes to it
mkdir -p "$BOOT_DIR"

echo "📦 Cloning and building U-Boot..."
if [ ! -d "$UBOOT_DIR" ]; then
  git clone https://source.denx.de/u-boot/u-boot.git "$UBOOT_DIR"
  cd "$UBOOT_DIR"
  git checkout v2024.01
else
  cd "$UBOOT_DIR"
fi

echo "ℹ️  Applying defconfig for Raspberry Pi Zero W..."
# This sets up a minimal working configuration specific to the Pi Zero W (BCM2835 SoC)
# The defconfig includes support for:
# - SD card (MMC)
# - Serial console over UART (ttyAMA0)
# - Flattened device tree loading
# - Boot from FAT partition (via firmware)
# - Basic environment and scripting support
# You can inspect or modify the generated .config afterward
make rpi_0_w_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j$(nproc)
cp u-boot.bin "$BOOT_DIR/"

cd "$SCRIPT_DIR"

echo "⬇️  Downloading Raspberry Pi firmware binaries..."
FIRMWARE_URL="https://github.com/raspberrypi/firmware/raw/master/boot"
for f in start.elf fixup.dat; do
  echo "🌐 Fetching: $FIRMWARE_URL/$f"
  if curl -L --create-dirs "$FIRMWARE_URL/$f" -o "$BOOT_DIR/$f"; then
    echo "✔ Downloaded $f"
  else
    echo "❌ Failed to download $f"
    exit 1
  fi
done

echo "⚙️  Creating config.txt..."
cat > "$BOOT_DIR/config.txt" <<EOF
kernel=u-boot.bin
disable_commandline_tags=1
disable_splash=1
disable_overscan=1
dtparam=audio=off
enable_uart=1
EOF

echo "⚙️  Creating boot.cmd..."
cat > "$BOOT_DIR/boot.cmd" <<EOF
setenv bootargs console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootwait rw init=/init
load mmc 0:1 0x08000000 zImage
load mmc 0:1 0x08100000 bcm2835-rpi-zero-w.dtb
bootz 0x08000000 - 0x08100000
EOF

echo "⚙️  Compiling boot.scr from boot.cmd..."
mkimage -A arm -T script -C none -n "boot script" -d "$BOOT_DIR/boot.cmd" "$BOOT_DIR/boot.scr"

echo "✅ U-Boot setup complete. Files available in: $BOOT_DIR"
ls -lh "$BOOT_DIR"

