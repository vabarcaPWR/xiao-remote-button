#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MICRO_DIR="$PROJECT_ROOT/micro"

export PATH="$HOME/.local/bin:$PATH"
export ZEPHYR_BASE="$HOME/ncs/zephyr"
export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
export GNUARMEMB_TOOLCHAIN_PATH=/usr

BOARD="xiao_ble/nrf52840"
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

cd "$MICRO_DIR"

if [ "$CLEAN" = true ] && [ -d build ]; then
    echo "🧹 Cleaning build directory..."
    rm -rf build
fi

echo "🔨 Building firmware for $BOARD..."
west build -b "$BOARD" . ${CLEAN:+--pristine}

echo ""
echo "✅ Build successful!"
echo "   Binary: $MICRO_DIR/build/micro/zephyr/zephyr.uf2"
echo "   Flash:  ./scripts/micro-flash.sh"
