#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$PROJECT_ROOT/app"

export PATH="$HOME/flutter/bin:$PATH"

usage() {
    echo "Usage: $0 [--release] [--device DEVICE_ID]"
    echo ""
    echo "  --release       Build in release mode"
    echo "  --device ID     Target device (from 'flutter devices')"
    echo ""
    echo "Builds and installs the Flutter app on a connected Android device."
    exit 1
}

MODE="debug"
DEVICE_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --release) MODE="release"; shift ;;
        --device) DEVICE_ARG="-d $2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

cd "$APP_DIR"

echo "📱 Building & running app ($MODE)..."
flutter run --$MODE $DEVICE_ARG
