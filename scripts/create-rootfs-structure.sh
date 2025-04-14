#!/bin/bash
set -e

# Define project and rootfs paths
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"

echo "📁 Creating base rootfs structure in $ROOTFS..."

mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,dev,tmp,var,mnt,home}
mkdir -p "$ROOTFS"/usr/{bin,sbin,lib}
chmod 0755 "$ROOTFS"

# Create symlinks for standard layout
ln -sf usr/bin "$ROOTFS/bin"
ln -sf usr/sbin "$ROOTFS/sbin"
ln -sf usr/lib "$ROOTFS/lib"

# Copy init.sh into rootfs/init
INIT_SRC="$PROJECT_ROOT/init.sh"
INIT_DST="$ROOTFS/init"

if [ -f "$INIT_SRC" ]; then
    echo "📄 Copying init script from $INIT_SRC to $INIT_DST"
    cp "$INIT_SRC" "$INIT_DST"
    chmod +x "$INIT_DST"
else
    echo "⚠️  Warning: $INIT_SRC not found. Skipping init copy."
fi

echo "✅ Base rootfs directory structure created."

