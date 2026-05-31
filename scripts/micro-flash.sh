#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MICRO_DIR="$PROJECT_ROOT/micro"

export PATH="$HOME/.local/bin:$PATH"
export ZEPHYR_BASE="$HOME/ncs/zephyr"
export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
export GNUARMEMB_TOOLCHAIN_PATH=/usr

UF2_FILE="$MICRO_DIR/build/micro/zephyr/zephyr.uf2"
UF2_MOUNT="/media/$USER/XIAO-SENSE"

usage() {
    echo "Usage: $0 [--mount PATH]"
    echo ""
    echo "  --mount PATH   Override UF2 mount point (default: $UF2_MOUNT)"
    echo ""
    echo "Flashes firmware to XIAO nRF52840 via UF2 bootloader."
    echo "Put the device in bootloader mode: double-tap reset button."
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mount) UF2_MOUNT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [ ! -f "$UF2_FILE" ]; then
    echo "❌ No firmware binary found. Run ./scripts/micro-build.sh first."
    exit 1
fi

if [ ! -d "$UF2_MOUNT" ]; then
    echo "⏳ Waiting for XIAO bootloader volume at $UF2_MOUNT..."
    echo "   → Double-tap the reset button on the XIAO to enter bootloader mode."
    echo ""

    for i in $(seq 1 30); do
        if [ -d "$UF2_MOUNT" ]; then
            break
        fi
        sleep 1
    done

    if [ ! -d "$UF2_MOUNT" ]; then
        echo "❌ Timeout: bootloader volume not found at $UF2_MOUNT"
        echo "   Check that the device is in bootloader mode and the mount point is correct."
        exit 1
    fi
fi

echo "📤 Flashing $UF2_FILE → $UF2_MOUNT..."
cp "$UF2_FILE" "$UF2_MOUNT/"
sync

echo "✅ Firmware flashed! Device will reboot automatically."
