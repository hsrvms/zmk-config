#!/usr/bin/env bash
# Build script for handwired 12x4 keyboard with Miryoku layout
# Usage:
#   ./build.sh          — incremental build
#   ./build.sh clean    — pristine (clean) build
#   ./build.sh flash    — copy UF2 to NICENANO drive

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")" && pwd)"
ZMK_APP="${WORKSPACE}/zmk/app"
ZMK_CONFIG="${WORKSPACE}/config"
BOARD="nice_nano"
SHIELD="handwired_12x4"
UF2="${ZMK_APP}/build/zephyr/zmk.uf2"

# Activate virtual environment
if [ -f "${HOME}/zmk-venv/bin/activate" ]; then
    source "${HOME}/zmk-venv/bin/activate"
fi

# Add Zephyr SDK toolchain to PATH
ZEPHYR_SDK="${HOME}/zephyr-sdk"
if [ -d "${ZEPHYR_SDK}/sysroots/sysroots/x86_64-pokysdk-linux/usr/bin" ]; then
    export PATH="${ZEPHYR_SDK}/sysroots/sysroots/x86_64-pokysdk-linux/usr/bin:${PATH}"
fi

cd "${ZMK_APP}"

BUILD_ARGS=(
    -b "${BOARD}"
    --
    -DSHIELD="${SHIELD}"
    -DZMK_CONFIG="${ZMK_CONFIG}"
    -DZEPHYR_TOOLCHAIN_VARIANT=zephyr
    -DZEPHYR_SDK_INSTALL_DIR="${ZEPHYR_SDK}"
)

case "${1:-build}" in
    clean)
        echo "=== Pristine build ==="
        west build -p "${BUILD_ARGS[@]}"
        ;;
    flash)
        if [ ! -f "${UF2}" ]; then
            echo "Firmware not found, building first..."
            west build -p "${BUILD_ARGS[@]}"
        fi
        echo ""
        echo "=== Flashing ==="
        echo "1. Double-click reset on the Pro Micro"
        echo "2. Wait for NICENANO drive to appear"
        echo "3. Run:"
        echo "   cp ${UF2} /run/media/\$USER/NICENANO/"
        ;;
    build|*)
        echo "=== Incremental build ==="
        west build "${BUILD_ARGS[@]}"
        ;;
esac

if [ -f "${UF2}" ]; then
    echo ""
    echo "=== Build complete ==="
    echo "Firmware: ${UF2} ($(du -h "${UF2}" | cut -f1))"
fi
