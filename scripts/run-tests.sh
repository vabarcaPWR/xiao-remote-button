#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [micro|app|all]"
    echo ""
    echo "  micro   Run firmware unit tests (Ceedling)"
    echo "  app     Run Flutter app tests"
    echo "  all     Run all tests (default)"
    exit 1
}

run_micro_tests() {
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW} 🔧 Firmware Tests (Ceedling)${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    cd "$PROJECT_ROOT/micro"
    ceedling test:all
    echo ""
}

run_app_tests() {
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW} 📱 App Tests (Flutter)${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    cd "$PROJECT_ROOT/app"
    flutter test
    echo ""
}

TARGET="${1:-all}"

case "$TARGET" in
    micro)
        run_micro_tests
        ;;
    app)
        run_app_tests
        ;;
    all)
        run_micro_tests
        run_app_tests
        ;;
    *)
        usage
        ;;
esac

echo -e "${GREEN}✅ All requested tests completed successfully${NC}"
