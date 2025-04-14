#!/bin/bash
set -e

# This meta-script orchestrates the first bootstrap stage
# of building a minimal toolchain in your rootfs. It delegates
# the actual steps to the following individual scripts:
#
#   1. build-glibc-headers.sh  → Installs glibc headers only
#   2. build-binutils.sh       → Builds binutils (as, ld, strip)
#   3. build-libgcc.sh         → Builds libgcc for the target
#
# Each script is self-contained and explains what it does.
# This script ensures they are run in the correct order.

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "🔁 Bootstrapping stage 1: Installing glibc headers..."
"$PROJECT_ROOT/build-glibc-headers.sh"

echo "🔁 Bootstrapping stage 2: Building and installing binutils..."
"$PROJECT_ROOT/build-coreutils.sh"

echo "🔁 Bootstrapping stage 3: Building and installing libgcc..."
"$PROJECT_ROOT/build-libgcc.sh"

echo "✅ Bootstrap stage complete! Your rootfs is now ready for building a native GCC and full glibc later."

