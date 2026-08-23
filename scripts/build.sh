#!/bin/bash
# ============================================================
# Luckfox Shell - Build Script
# Universal container for all Luckfox Qt5 apps on 800x480
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
QMAKE="/home/tamnguyen/Desktop/LINUX/Build_Luckfox/luckfox-pico/sysdrv/source/buildroot/buildroot-2023.02.6/output/host/bin/qmake"
BUILD_DIR="${SCRIPT_DIR}/build"

# ─── Step 1: qmake ─────────────────────────────
echo "=== [1/2] qmake ==="
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
$QMAKE "${SCRIPT_DIR}/luckfox_shell.pro"

# ─── Step 2: make ──────────────────────────────
echo "=== [2/2] make ==="
make -j$(nproc)

if [ ! -f "luckfox-shell" ]; then
    echo "ERROR: Build failed! luckfox-shell not found."
    exit 1
fi

echo "Build OK: ${BUILD_DIR}/luckfox-shell"
