#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/server.pid"
FIFO="$SCRIPT_DIR/.minecraft-console"

if [ -p "$FIFO" ]; then
  printf '%s\n' "stop" > "$FIFO" || true
elif [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  kill "$(cat "$PID_FILE")"
else
  echo "The server is not running."
fi