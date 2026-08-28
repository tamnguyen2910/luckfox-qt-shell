#!/bin/bash
# ============================================================
# Luckfox Shell - Run on Board
#
# Required:
#   LUCKFOX_SSH_KEY  - path to SSH private key
# Optional:
#   LUCKFOX_BOARD_IP    - default 192.168.1.3
#   LUCKFOX_BOARD_USER  - default root
# ============================================================
set -e

: "${LUCKFOX_SSH_KEY:?ERROR: Set LUCKFOX_SSH_KEY to your SSH private key (e.g. ~/.ssh/id_ed25519)}"
: "${LUCKFOX_BOARD_IP:=192.168.1.3}"
: "${LUCKFOX_BOARD_USER:=root}"

BOARD_IP="$LUCKFOX_BOARD_IP"
BOARD_USER="$LUCKFOX_BOARD_USER"
SSH_KEY="$LUCKFOX_SSH_KEY"
APP_NAME="luckfox-shell"

SSH_CMD="ssh -o StrictHostKeyChecking=no -i $SSH_KEY $BOARD_USER@$BOARD_IP"

echo "=== Launching $APP_NAME on $BOARD_IP ==="
$SSH_CMD "pkill -x $APP_NAME 2>/dev/null || true; sleep 0.5; \
    export QT_QPA_PLATFORM='linuxfb:fb=/dev/fb0:size=800x480:mmsize=800x480'; \
    export QT_QPA_FONTDIR=/usr/share/fonts/dejavu/; \
    export LD_LIBRARY_PATH=/usr/lib:/usr/lib/qt5/lib:/usr/lib/aarch64-linux-gnu; \
    nohup /root/$APP_NAME > /tmp/luckfox-shell.log 2>&1 & \
    sleep 1; \
    pgrep -x $APP_NAME >/dev/null && echo 'RUNNING (pid '\$(pgrep -x $APP_NAME)')' || echo 'NOT RUNNING'; \
    echo '--- log ---'; cat /tmp/luckfox-shell.log"
