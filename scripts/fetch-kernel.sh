#!/bin/bash

set -e

KERNEL_REPO="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
DEFAULT_BRANCH="master"
TARGET_DIR="$(dirname "$0")/../kernel"

show_help() {
cat <<EOF
Usage: $(basename "$0") [--version <tag>] [--help]

Clones the mainline Linux kernel from kernel.org into ./kernel directory.

Options:
  --version <tag>   Checkout a specific version (e.g. v6.6, v6.1.55)
  --help            Show this help message

Why mainline?
  - Ensures you're working with clean, upstream code.
  - Avoids vendor patches and simplifies understanding what's going on.

Where is it cloned?
  - Kernel source is cloned into ./kernel relative to the script location.

Example:
  ./fetch-kernel.sh --version v6.6

EOF
}

# Defaults
KERNEL_VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            shift
            KERNEL_VERSION="$1"
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Clone
echo "📥 Cloning Linux kernel from $KERNEL_REPO..."
git clone --depth=1 "${KERNEL_REPO}" "$TARGET_DIR"

# Checkout version if provided
if [[ -n "$KERNEL_VERSION" ]]; then
    echo "🔄 Checking out version: $KERNEL_VERSION"
    cd "$TARGET_DIR"
    git fetch --depth=1 origin "refs/tags/$KERNEL_VERSION"
    git checkout "tags/$KERNEL_VERSION"
fi

echo "✅ Kernel source ready in: $TARGET_DIR"

