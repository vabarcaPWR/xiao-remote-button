#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$PROJECT_ROOT/app"

export PATH="$HOME/flutter/bin:$PATH"

usage() {
    echo "Usage: $0 [--release]"
    echo ""
    echo "  --release   Build release APK (default: debug)"
    echo ""
    echo "Builds the APK without installing."
    exit 1
}

MODE="debug"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --release) MODE="release"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

cd "$APP_DIR"

echo "📦 Building APK ($MODE)..."
flutter build apk --$MODE

APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-${MODE}.apk"
echo ""
echo "✅ APK built: $APK_PATH"
echo "   Install: adb install $APK_PATH"
