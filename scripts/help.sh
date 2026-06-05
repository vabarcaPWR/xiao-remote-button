#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "═══════════════════════════════════════════"
echo " fip-remote-button — Available Scripts"
echo "═══════════════════════════════════════════"
echo ""
echo " 🔧 Firmware (micro/)"
echo "   ./scripts/micro-build.sh [--clean]     Build firmware"
echo "   ./scripts/micro-flash.sh [--mount PATH] Flash via UF2 bootloader"
echo "   ./scripts/micro-monitor.sh [--port DEV] Serial monitor (USB CDC)"
echo ""
echo " 📱 App (app/)"
echo "   ./scripts/app-build.sh [--release]     Build APK"
echo "   ./scripts/app-run.sh [--release] [--device ID]  Build & run on device"
echo ""
echo " 🧪 Tests"
echo "   ./scripts/run-tests.sh [micro|app|all] Run unit tests"
echo ""
echo " ℹ️  Use --help on any script for full usage."
echo ""
