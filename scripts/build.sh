#!/bin/bash
# ============================================================
# Luckfox Shell - Build Script
# Cross-compile for Luckfox Pico (RV1106) using the buildroot
# Qt5 toolchain.
#
# Required:
#   QMAKE  - path to the cross qmake binary
#           (default: ${LUCKFOX_QMAKE} or the path baked in below)
# Optional:
#   LUCKFOX_PROJECT_DIR - override project root
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="${LUCKFOX_PROJECT_DIR:-$SCRIPT_DIR}"
BUILD_DIR="${PROJECT_DIR}/build"

# QMAKE: env var > hardcoded default (the path used in the original dev env).
# Override on the command line for other setups:
#   LUCKFOX_QMAKE=/path/to/qmake bash scripts/build.sh
: "${LUCKFOX_QMAKE:=/home/tamnguyen/Desktop/LINUX/Build_Luckfox/luckfox-pico/sysdrv/source/buildroot/buildroot-2023.02.6/output/host/bin/qmake}"

if [ ! -x "$LUCKFOX_QMAKE" ]; then
    echo "ERROR: qmake not found at: $LUCKFOX_QMAKE"
    echo "       Set LUCKFOX_QMAKE to your cross-toolchain qmake."
    exit 1
fi

# ─── Step 1: qmake ─────────────────────────────
echo "=== [1/2] qmake ==="
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
"$LUCKFOX_QMAKE" "${PROJECT_DIR}/luckfox_shell.pro"

# ─── Step 2: make ──────────────────────────────
echo "=== [2/2] make ==="
make -j"$(nproc)"

if [ ! -f "luckfox-shell" ]; then
    echo "ERROR: Build failed! luckfox-shell not found."
    exit 1
fi

echo "Build OK: ${BUILD_DIR}/luckfox-shell"
