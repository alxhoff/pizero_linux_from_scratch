#!/bin/bash
set -e

# Configuration
TARGET=arm-linux-gnueabi
ARCH=arm
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL_SRC="$PROJECT_ROOT/kernel"
OUTPUT_DIR="$KERNEL_SRC/out"
ROOTFS="$PROJECT_ROOT/rootfs"
JOBS=$(nproc)

echo "🔧 Building Linux kernel for Raspberry Pi Zero W..."
echo "Outputting in: $OUTPUT_DIR"

# Clean up any previous broken state
rm -rf "$OUTPUT_DIR"

# Configure kernel
make -C "$KERNEL_SRC" ARCH=$ARCH CROSS_COMPILE=$TARGET- O="$OUTPUT_DIR" bcm2835_defconfig

# Build kernel, device tree, and modules
make -C "$KERNEL_SRC" ARCH=$ARCH CROSS_COMPILE=$TARGET- O="$OUTPUT_DIR" zImage dtbs modules -j"$JOBS"

# Install kernel headers for glibc into rootfs
make -C "$KERNEL_SRC" ARCH=$ARCH CROSS_COMPILE=$TARGET- O="$OUTPUT_DIR" headers_install INSTALL_HDR_PATH="$ROOTFS/usr"

echo "✅ Kernel build complete. zImage and DTBs are in $OUTPUT_DIR/arch/arm/boot"

