#!/bin/bash
# ============================================================
# Luckfox Shell - Deploy to Board via SSH
#
# Required:
#   LUCKFOX_SSH_KEY  - path to SSH private key (NEVER commit the key)
# Optional:
#   LUCKFOX_BOARD_IP    - default 192.168.1.3
#   LUCKFOX_BOARD_USER  - default root
# ============================================================
set -e

: "${LUCKFOX_SSH_KEY:?ERROR: Set LUCKFOX_SSH_KEY to your SSH private key (e.g. ~/.ssh/id_ed25519)}"
: "${LUCKFOX_BOARD_IP:=192.168.1.3}"
: "${LUCKFOX_BOARD_USER:=root}"
: "${LUCKFOX_BOARD_DEST:=/root}"

BOARD_IP="$LUCKFOX_BOARD_IP"
BOARD_USER="$LUCKFOX_BOARD_USER"
BOARD_DEST="$LUCKFOX_BOARD_DEST"
APP_NAME="luckfox-shell"
SSH_KEY="$LUCKFOX_SSH_KEY"

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
    echo "ERROR: Binary not found. Run scripts/build.sh first."
    exit 1
fi

echo "=== Deploying $APP_NAME to ${BOARD_USER}@${BOARD_IP}:${BOARD_DEST} ==="
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$BOARD_USER@$BOARD_IP" "pkill -x $APP_NAME 2>/dev/null || true"
sleep 0.5
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "$BUILD_DIR/$APP_NAME" "$BOARD_USER@$BOARD_IP:$BOARD_DEST/"
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$BOARD_USER@$BOARD_IP" "chmod +x $BOARD_DEST/$APP_NAME"
echo "Done."
