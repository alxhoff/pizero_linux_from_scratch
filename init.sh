#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs devtmpfs /dev

echo "✅ Booted into custom init script!"
exec /bin/sh

