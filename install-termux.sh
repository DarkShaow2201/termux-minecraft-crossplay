#!/data/data/com.termux/files/usr/bin/bash
#
# One-command bootstrap for Termux:
# curl -fsSL https://raw.githubusercontent.com/DarkShaow2201/termux-minecraft-crossplay/main/install-termux.sh | bash
#
set -euo pipefail

REPO_URL="https://github.com/DarkShaow2201/termux-minecraft-crossplay.git"
TARGET_DIR="${1:-"$HOME/termux-minecraft-crossplay"}"

command -v pkg >/dev/null 2>&1 || {
  echo "Run this installer inside Termux."
  exit 1
}

if ! command -v git >/dev/null 2>&1; then
  pkg update -y
  pkg install -y git
fi

if [ -d "$TARGET_DIR/.git" ]; then
  echo "Updating existing installer in $TARGET_DIR..."
  git -C "$TARGET_DIR" pull --ff-only
else
  if [ -e "$TARGET_DIR" ]; then
    echo "Target directory already exists and is not a Git checkout: $TARGET_DIR"
    echo "Choose another path by passing it as the first argument."
    exit 1
  fi
  git clone "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"
chmod +x install.sh start.sh stop.sh backup.sh setup-access.sh tunnel.sh
exec ./install.sh