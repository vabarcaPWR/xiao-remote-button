#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MICRO_DIR="$PROJECT_ROOT/micro"

BAUD=115200
PORT=""

usage() {
    echo "Usage: $0 [--port DEVICE] [--baud RATE]"
    echo ""
    echo "  --port DEVICE   Serial port (default: auto-detect /dev/ttyACM*)"
    echo "  --baud RATE     Baud rate (default: $BAUD)"
    echo ""
    echo "Opens serial monitor to view firmware logs via USB CDC."
    echo "Press Ctrl+C to exit."
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --port) PORT="$2"; shift 2 ;;
        --baud) BAUD="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [ -z "$PORT" ]; then
    PORT=$(ls /dev/ttyACM* 2>/dev/null | head -1 || true)
    if [ -z "$PORT" ]; then
        echo "❌ No serial port found. Is the XIAO connected and running firmware?"
        echo "   Try: ls /dev/ttyACM* or ls /dev/ttyUSB*"
        exit 1
    fi
fi

echo "📡 Monitoring $PORT at ${BAUD} baud (Ctrl+C to exit)..."
echo "─────────────────────────────────────────────────────"

if command -v minicom &>/dev/null; then
    minicom -D "$PORT" -b "$BAUD" -o
elif command -v screen &>/dev/null; then
    screen "$PORT" "$BAUD"
elif command -v picocom &>/dev/null; then
    picocom -b "$BAUD" "$PORT"
else
    cat "$PORT"
fi
