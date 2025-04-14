#!/bin/bash
set -e

# Configuration
BUSYBOX_VERSION=1.36.1
TARGET=arm-linux-gnueabi
ARCH=arm
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"
JOBS=$(nproc)
BUILD_DIR="$PROJECT_ROOT/build"

# Optional: if toolchain is not in PATH, adjust here
# export PATH=/opt/toolchains/your-toolchain/bin:$PATH

# Compiler flags
CFLAGS="--sysroot=$ROOTFS"
LDFLAGS="--sysroot=$ROOTFS"
KCONFIG_NOTIMESTAMP=1

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Download BusyBox
echo "📦 Downloading BusyBox $BUSYBOX_VERSION..."
wget -nc https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
rm -rf busybox-$BUSYBOX_VERSION && tar -xf busybox-$BUSYBOX_VERSION.tar.bz2
cd busybox-$BUSYBOX_VERSION

# Configure BusyBox for static cross build
echo "🔧 Configuring BusyBox (static ARM build with init)..."
make ARCH=$ARCH CROSS_COMPILE=$TARGET- distclean
make ARCH=$ARCH CROSS_COMPILE=$TARGET- defconfig

# Enable static linking and built-in init
sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
sed -i 's/^# CONFIG_FEATURE_INIT is not set/CONFIG_FEATURE_INIT=y/' .config
sed -i 's/^# CONFIG_INIT is not set/CONFIG_INIT=y/' .config
sed -i 's/^CONFIG_TC=y/# CONFIG_TC is not set/' .config

# Apply defaults for any new options without prompting
yes "" | make ARCH=$ARCH CROSS_COMPILE=$TARGET- oldconfig

# Build BusyBox
echo "🔨 Building BusyBox..."
make ARCH=$ARCH CROSS_COMPILE=$TARGET- CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" -j"$JOBS"

# Install into rootfs
echo "📥 Installing BusyBox to $ROOTFS..."
make ARCH=$ARCH CROSS_COMPILE=$TARGET- CONFIG_PREFIX="$ROOTFS" install

# Symlink /init if not already present
if [ ! -f "$ROOTFS/init" ]; then
  ln -sv /bin/busybox "$ROOTFS/init"
fi

echo "✅ BusyBox $BUSYBOX_VERSION cross-built cleanly for $TARGET and installed to $ROOTFS"

