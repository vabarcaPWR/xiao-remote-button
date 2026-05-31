#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MICRO_DIR="$PROJECT_ROOT/micro"
BUILD_DIR="$MICRO_DIR/build/micro"

export PATH="$HOME/.local/bin:$PATH"
export ZEPHYR_BASE="$HOME/ncs/zephyr"
export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
export GNUARMEMB_TOOLCHAIN_PATH=/usr

BOARD="xiao_ble/nrf52840/sense"
CLEAN=false

usage() {
    echo "Usage: $0 [--clean]"
    echo ""
    echo "  --clean   Remove build directory before building"
    echo ""
    echo "Builds firmware for $BOARD"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean) CLEAN=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [ "$CLEAN" = true ] && [ -d "$BUILD_DIR" ]; then
    echo "🧹 Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

echo "🔨 Building firmware for $BOARD..."
# --no-sysbuild and -DCONFIG_PARTITION_MANAGER_ENABLED=n are required
# for the Adafruit nRF52 bootloader (UF2) on XIAO BLE Sense.
# Without these, the NCS Partition Manager links code at address 0x0
# instead of 0x27000 where the bootloader expects it.
cd "$PROJECT_ROOT"
west build -b "$BOARD" micro -d "$BUILD_DIR" --no-sysbuild \
    -- -DCONFIG_PARTITION_MANAGER_ENABLED=n

echo ""
echo "✅ Build successful!"
echo "   Binary: $BUILD_DIR/zephyr/zephyr.uf2"
echo "   Flash:  ./scripts/micro-flash.sh"
