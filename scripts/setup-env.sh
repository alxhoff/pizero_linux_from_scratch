#!/bin/bash

set -e

PROJECT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [--help]

Prepares your Linux-from-scratch workspace for Raspberry Pi Zero W (v1).

This script:
  - Creates the standard project directory layout
  - Installs all required packages using apt
  - Ensures you're using the correct soft-float toolchain

Target: Raspberry Pi Zero W
  - CPU: ARM1176JZF-S (ARMv6 with VFPv2)
  - Requires soft-float ABI (no VFPv3 support)

Toolchain:
  - Uses: arm-linux-gnueabi-gcc
  - Avoid: arm-linux-gnueabihf (assumes VFPv3+, won't work reliably on ARMv6)
  - Soft-float ABI means float args are passed via general-purpose registers.
    This is compatible across more devices and necessary for Pi Zero W.

Required packages (via apt):
  - build-essential: gcc, make, etc.
  - bc: for kernel version math in Makefiles
  - git: fetch kernel source and other tools
  - device-tree-compiler: compiles .dts to .dtb
  - flex, bison: for kernel menuconfig lexer/parser
  - libncurses-dev: needed for menuconfig UI
  - u-boot-tools: optional, for working with U-Boot bootloaders (mkimage)

Toolchain:
  - arm-linux-gnueabi-gcc: cross-compiler targeting ARMv6 with soft-float ABI

EOF
}

if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

echo "📁 Creating project directory structure in $PROJECT_DIR..."
mkdir -p "$PROJECT_DIR"/{boot,kernel,rootfs,dt,build,scripts,docs}
echo "✅ Directories created."

echo "📦 Installing required packages via apt..."
apt-get update
apt-get install -y \
    build-essential \
    bc \
    git \
    device-tree-compiler \
    flex \
    bison \
    libncurses-dev \
    u-boot-tools \
    gcc-arm-linux-gnueabi \
    g++-arm-linux-gnueabi

echo "🔍 Checking for cross-toolchain (arm-linux-gnueabi-gcc)..."
if ! command -v arm-linux-gnueabi-gcc &> /dev/null; then
    echo "❌ Cross-compiler not found even after install. Please verify manually."
    exit 1
fi

echo "✅ Toolchain found: $(arm-linux-gnueabi-gcc -dumpversion)"
echo "✅ Environment setup complete. You’re ready to fetch and configure the kernel."

