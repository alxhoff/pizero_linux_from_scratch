#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KERNEL_DIR="$PROJECT_ROOT/kernel"
DTS_DIR="$KERNEL_DIR/arch/arm/boot/dts"
DTS_FILE="$DTS_DIR/rpi-zero-w-minimal.dts"

if [[ -f "$DTS_FILE" ]]; then
    echo "⚠️  Minimal DTS already exists at: $DTS_FILE"
    exit 1
fi

echo "📄 Creating minimal DTS at: $DTS_FILE"

cat > "$DTS_FILE" <<'EOF'
/dts-v1/;
#include "bcm2835.dtsi"

/ {
  compatible = "raspberrypi,model-zero-w", "brcm,bcm2835";
  model = "Raspberry Pi Zero W";

  memory@0 {
    device_type = "memory";
    reg = <0 0x20000000>; // 'reg' = <start-address size>. Here: start at 0x00000000, size 512MB.
  };

  chosen {
    stdout-path = "serial1:115200n8"; // Tells the kernel which device to use for early boot messages (console output)
  };
};

&uart1 {
  status = "okay";
};

&sdhost {
  status = "okay";
  bus-width = <4>; // Specifies the width of the SD data bus. 4-bit mode gives higher throughput than 1-bit.
};
EOF

echo "✅ Done. You can now build the DTB with:"
echo "   make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- dtbs"

