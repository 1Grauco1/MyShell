#!/usr/bin/env bash

G_ANT_DIR="${G_ANT_DIR:-$HOME/g_ant}"
G_ANT_REPO="${G_ANT_REPO:-https://github.com/zaeemali272/g_ant.git}"

log() {
    echo "[UpdateManager] $*"
}

# 1. Ensure G_ant exists and is updated
if [ ! -d "$G_ANT_DIR" ]; then
    log "Cloning G_ant..."
    git clone "$G_ANT_REPO" "$G_ANT_DIR"
else
    log "Pulling G_ant..."
    git -C "$G_ANT_DIR" pull
fi

# 2. Run the install script with passed arguments
cd "$G_ANT_DIR" || exit 1

log "Running: ./install.sh $*"
# Automatically select option 2
echo "2" | bash "./install.sh" "$@"
