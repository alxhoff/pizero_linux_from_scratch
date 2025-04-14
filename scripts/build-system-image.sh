#!/bin/bash
set -euo pipefail

# This script creates a full SD card image with two partitions:
# - Partition 1: FAT32 (64MB) for /boot
# - Partition 2: ext4 (~7936MB) for rootfs

IMG="${1:-sdcard.img}"
BOOT_SIZE_MB=64
TOTAL_SIZE_MB=8192
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOTFS_DIR="$PROJECT_ROOT/rootfs"
BOOT_DIR="$PROJECT_ROOT/boot"

MOUNT_DIR="$(mktemp -d)"

cleanup() {
  echo "🧹 Cleaning up..."
  sync || true
  umount "$MOUNT_DIR/boot" 2>/dev/null || true
  umount "$MOUNT_DIR/root" 2>/dev/null || true
  [[ -n "${LOOPDEV:-}" ]] && kpartx -d "$LOOPDEV" 2>/dev/null || true
  [[ -n "${LOOPDEV:-}" ]] && losetup -d "$LOOPDEV" 2>/dev/null || true
  rm -rf "$MOUNT_DIR"
}
trap cleanup EXIT

# Check required tools
for tool in losetup parted mkfs.vfat mkfs.ext4 kpartx; do
  if ! command -v "$tool" &>/dev/null; then
    echo "❌ Required tool '$tool' not found. Install it and try again."
    exit 1
  fi
done

if ! losetup -f &>/dev/null; then
  echo "❌ No free loop device available. Are you running in Docker without --privileged?"
  exit 1
fi

mkdir -p "$BOOT_DIR" "$ROOTFS_DIR"

# Create blank image
echo "📦 Creating $TOTAL_SIZE_MB MB blank image at $IMG..."
dd if=/dev/zero of="$IMG" bs=1M count=$TOTAL_SIZE_MB

# Partition the image
echo "📐 Partitioning the image..."
parted "$IMG" --script -- mklabel msdos
parted "$IMG" --script -- mkpart primary fat32 1MiB "${BOOT_SIZE_MB}MiB"
parted "$IMG" --script -- mkpart primary ext4 "${BOOT_SIZE_MB}MiB" 100%

# Setup loop device
echo "🔁 Attaching loop device..."
LOOPDEV=$(losetup --show -f "$IMG")
echo "🔗 Using loop device: $LOOPDEV"

# Use kpartx to map partitions
echo "🔂 Creating partition mappings..."
kpartx -a "$LOOPDEV"
sleep 1  # Allow time for /dev/mapper links to appear

# Find mapped partitions
DEV1="/dev/mapper/$(basename "$LOOPDEV")p1"
DEV2="/dev/mapper/$(basename "$LOOPDEV")p2"

if [ ! -e "$DEV1" ] || [ ! -e "$DEV2" ]; then
  echo "❌ Mapped partition devices not found: $DEV1 $DEV2"
  exit 1
fi

# Format partitions
mkfs.vfat "$DEV1"
mkfs.ext4 "$DEV2"

# Mount partitions and copy contents
mkdir -p "$MOUNT_DIR/boot" "$MOUNT_DIR/root"
mount "$DEV1" "$MOUNT_DIR/boot"
mount "$DEV2" "$MOUNT_DIR/root"

echo "📁 Copying boot and rootfs contents..."
cp -a "$BOOT_DIR"/* "$MOUNT_DIR/boot/" || true
cp -a "$ROOTFS_DIR"/* "$MOUNT_DIR/root/" || true

echo "✅ Image creation complete: $IMG"
echo "📤 Flash with:"
echo "   sudo dd if=$IMG of=/dev/sdX bs=4M status=progress conv=fsync"

