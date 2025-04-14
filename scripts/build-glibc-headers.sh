#!/bin/bash
set -e

# Configuration
TARGET=arm-linux-gnueabi
GLIBC_VERSION=2.33
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"
JOBS=$(nproc)

mkdir -p "$PROJECT_ROOT/build"
cd "$PROJECT_ROOT/build"

echo "📦 Downloading glibc $GLIBC_VERSION..."
wget -nc https://ftp.gnu.org/gnu/libc/glibc-$GLIBC_VERSION.tar.xz
rm -rf glibc-$GLIBC_VERSION && tar -xf glibc-$GLIBC_VERSION.tar.xz

mkdir -p glibc-build && cd glibc-build

echo "🔧 Configuring glibc headers only..."
../glibc-$GLIBC_VERSION/configure \
  --prefix=/usr \
  --host=$TARGET \
  --build=$(../glibc-$GLIBC_VERSION/scripts/config.guess) \
  --with-headers=$ROOTFS/usr/include \
  --disable-multilib \
  --disable-werror \
  --disable-shared \
  --disable-nls

echo "📥 Installing bootstrap headers..."
make install-bootstrap-headers=yes install-headers install_root="$ROOTFS"

# Ensure gnu/stubs.h exists
touch "$ROOTFS/usr/include/gnu/stubs.h"

echo "✅ glibc headers installed to $ROOTFS/usr/include"

