#!/bin/bash
set -e

echo "🧹 Cleaning up build folders..."

rm -rf boot \
       build \
       kernel \
       mksh \
       rootfs \
       u-boot

echo "✅ Done. Clean slate ready!"

