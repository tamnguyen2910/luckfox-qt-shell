#!/bin/bash
# ============================================================
# Luckfox Shell - Deploy to Board via SSH
# ============================================================
set -e

BOARD_IP="192.168.1.3"
BOARD_USER="root"
BOARD_DEST="/root"
APP_NAME="luckfox-shell"
SSH_KEY="/home/tamnguyen/.ssh/id_ed25519"

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
    echo "ERROR: Binary not found. Run scripts/build.sh first."
    exit 1
fi

echo "=== Deploying $APP_NAME to $BOARD_IP:$BOARD_DEST ==="
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$BOARD_USER@$BOARD_IP" "pkill -x $APP_NAME 2>/dev/null || true"
sleep 0.5
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "$BUILD_DIR/$APP_NAME" "$BOARD_USER@$BOARD_IP:$BOARD_DEST/"
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$BOARD_USER@$BOARD_IP" "chmod +x $BOARD_DEST/$APP_NAME"
echo "Done."
