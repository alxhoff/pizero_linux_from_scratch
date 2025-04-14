# Creating the System Image for Raspberry Pi Zero W

This document explains how to package your boot directory and root filesystem into a bootable SD card image for the Raspberry Pi Zero W.

We will create a full `.img` file that:
- Contains two partitions
  - FAT32 `/boot` partition (64MB)
  - ext4 root filesystem (`/`) partition (~7936MB)
- Can be directly flashed to an SD card with `dd`

---

## Why Do This?
While your rootfs and kernel may be complete, they cannot boot on hardware until written into a correctly partitioned SD card image. The Raspberry Pi’s firmware requires specific boot files and structure in the first FAT32 partition.

This process produces a bootable image that:
- Mimics the physical layout of an SD card
- Can be tested in emulators or flashed to real hardware

---

## Script Overview
The `build-system-image.sh` script does the following:

1. Creates an 8GB blank image file
2. Partitions it with two partitions: FAT32 (64MB) and ext4 (rest)
3. Sets up loop device mapping using `losetup` and `kpartx`
4. Formats each partition
5. Mounts them
6. Copies boot files and rootfs content into the image
7. Cleans up loop devices and mounts

---

## Prerequisites
Ensure your container or host has these tools installed:
```bash
apt install -y dosfstools e2fsprogs parted kpartx
```

And run the container with:
```bash
docker run --privileged ...
```

---

## How the Image is Built

### 1. Create Image File
```bash
dd if=/dev/zero of=sdcard.img bs=1M count=8192
```
This creates an empty 8GB image.

### 2. Partition with `parted`
```bash
parted sdcard.img --script -- mklabel msdos
parted sdcard.img --script -- mkpart primary fat32 1MiB 65MiB
parted sdcard.img --script -- mkpart primary ext4 65MiB 8192MiB
```
This creates:
- Partition 1 (FAT32): `/boot`
- Partition 2 (ext4): rootfs `/`

### 3. Attach Loop Device
```bash
LOOPDEV=$(losetup --show -f sdcard.img)
kpartx -a "$LOOPDEV"
```
This creates device mappings like `/dev/mapper/loop0p1` and `/dev/mapper/loop0p2`

### 4. Format Partitions
```bash
mkfs.vfat /dev/mapper/loop0p1
mkfs.ext4 /dev/mapper/loop0p2
```

### 5. Mount and Copy Contents
```bash
mount /dev/mapper/loop0p1 /mnt/boot
mount /dev/mapper/loop0p2 /mnt/root

cp -a boot/* /mnt/boot/
cp -a rootfs/* /mnt/root/
```

### 6. Clean Up
```bash
umount /mnt/boot /mnt/root
kpartx -d "$LOOPDEV"
losetup -d "$LOOPDEV"
```

---

## Flash to SD Card
```bash
dd if=sdcard.img of=/dev/sdX bs=4M status=progress conv=fsync
```
Replace `/dev/sdX` with your SD card device.

---

## Summary
- Produces an SD card image that can boot on Raspberry Pi Zero W
- Includes a proper partition layout: `/boot` (FAT32) and rootfs (`ext4`)
- Can be generated inside Docker with `--privileged`

This final packaging step turns your manually built rootfs and kernel into a flashable, bootable embedded Linux system.


