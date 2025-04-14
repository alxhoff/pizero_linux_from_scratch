#!/bin/bash
set -e

ROOTFS="$(cd "$(dirname "$0")/.." && pwd)/rootfs"

check() {
  echo -n "[ ] $1..."
  if eval "$2" >/dev/null 2>&1; then
    echo -e "\r[✓] $1"
  else
    echo -e "\r[✗] $1"
    if [ -n "$3" ]; then
      echo "    ↳ Info: $3"
    fi
    MISSING=true
  fi
}

check_arch() {
  file="$1"
  desc="$2"
  if [ -f "$file" ]; then
    echo -n "[ ] Checking architecture of $desc..."
    if readelf -h "$file" 2>/dev/null | grep -q 'ARM'; then
      echo -e "\r[✓] $desc is ARM"
    else
      echo -e "\r[✗] $desc is not ARM ($file)"
      echo "    ↳ Info: Wrong architecture — possibly built for host instead of target."
      MISSING=true
    fi
  fi
}

MISSING=false

# --- Core layout ---
check "rootfs directory exists" "[ -d \"$ROOTFS\" ]"
check "bin directory exists" "[ -d \"$ROOTFS/bin\" ]"
check "lib directory exists" "[ -d \"$ROOTFS/lib\" ]"
check "usr/bin directory exists" "[ -d \"$ROOTFS/usr/bin\" ]"
check "usr/include directory exists" "[ -d \"$ROOTFS/usr/include\" ]"
check "usr/lib directory exists" "[ -d \"$ROOTFS/usr/lib\" ]"

# --- glibc headers ---
check "stdio.h present" "[ -f \"$ROOTFS/usr/include/stdio.h\" ]"
check "stubs.h present" "[ -f \"$ROOTFS/usr/include/gnu/stubs.h\" ]"

# --- kernel headers ---
check "linux/version.h present" "[ -f \"$ROOTFS/usr/include/linux/version.h\" ]"
check "asm headers present" "[ -d \"$ROOTFS/usr/include/asm\" ]"

# --- GCC and runtime (note: full gcc not yet built) ---
check "native gcc symlink exists" "[ -x \"$ROOTFS/usr/bin/gcc\" ]" "Optional: symlink to gcc expected later after native build"
check "gcc binary is ARM" "readelf -h \"$ROOTFS/usr/bin/gcc\" 2>/dev/null | grep -q 'ARM'" "Expected to be missing — full native gcc will be built later"

# --- runtime linker and libc (deferred) ---
check "ld-linux.so.3 present" "[ -f \"$ROOTFS/lib/ld-linux.so.3\" ]" "Expected missing — full glibc not yet built"
check "libc.so.6 present" "[ -f \"$ROOTFS/lib/libc.so.6\" ]" "Expected missing — full glibc not yet built"

# --- libgcc check ---
check "libgcc.a present" "[ -f \"$ROOTFS/usr/lib/libgcc.a\" ]" "This must be built during the bootstrap stage with all-target-libgcc"
check "libgcc_s.so.1 (optional) present" "[ -f \"$ROOTFS/usr/lib/libgcc_s.so.1\" ]" "Only expected if shared libgcc was built"
check_arch "$ROOTFS/usr/lib/libgcc.a" "libgcc.a static library"
check_arch "$ROOTFS/usr/lib/libgcc_s.so.1" "libgcc_s.so.1 shared library"

# --- coreutils (minimal check set) ---
COREUTILS=("ls" "cp" "mv" "rm" "chmod" "chown" "mkdir" "echo")
for tool in "${COREUTILS[@]}"; do
  check "$tool present" "[ -f \"$ROOTFS/usr/bin/$tool\" ]"
  check_arch "$ROOTFS/usr/bin/$tool" "$tool"
done

# --- Optional: mksh shell ---
check_arch "$ROOTFS/usr/bin/mksh" "mksh shell"

# --- interpreter check ---
if [ -f "$ROOTFS/usr/bin/mksh" ]; then
  echo -n "[?] Checking mksh interpreter..."
  interp=$(readelf -l "$ROOTFS/usr/bin/mksh"

