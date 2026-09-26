#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR"
backup_dir="$SCRIPT_DIR/backups"
stamp="$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$backup_dir"

if [ -p .minecraft-console ]; then
  printf '%s\n' "save-all flush" > .minecraft-console || true
  sleep 3
fi

world_paths=()
for world_dir in worlds/world worlds/world_nether worlds/world_the_end; do
  if [ -d "$world_dir" ]; then
    world_paths+=("$world_dir")
  fi
done

if [ "${#world_paths[@]}" -eq 0 ]; then
  echo "No world folders found yet; start the server once before backing up."
  exit 1
fi

tar --exclude='./backups' --exclude='./logs' -czf \
  "$backup_dir/world-$stamp.tar.gz" \
  "${world_paths[@]}"
echo "Backup written to $backup_dir/world-$stamp.tar.gz"