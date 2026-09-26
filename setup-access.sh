#!/data/data/com.termux/files/usr/bin/bash
#
# Configure the live server ban list and operator list through its console.
# Run this while ./start.sh is running.
#
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
FIFO="$SCRIPT_DIR/.minecraft-console"

if [ ! -p "$FIFO" ]; then
  echo "The server console is not available."
  echo "Start the server first with: ./start.sh"
  exit 1
fi

send_command() {
  printf '%s\n' "$1" > "$FIFO"
  sleep 1
}

valid_name() {
  case "$1" in
    ""|*[!A-Za-z0-9_]*)
      return 1
      ;;
    ?????????????????)
      return 1
      ;;
    *)
      [ "${#1}" -le 16 ]
      ;;
  esac
}

add_players() {
  local label="$1"
  local command="$2"
  local raw name
  read -r -p "$label (comma-separated, blank to skip): " raw
  raw="${raw// /}"
  [ -n "$raw" ] || return 0

  IFS=',' read -r -a names <<< "$raw"
  for name in "${names[@]}"; do
    if valid_name "$name"; then
      send_command "$command $name"
      echo "Added: $name"
    else
      echo "Skipped invalid Minecraft username: $name"
    fi
  done
}

echo "This will use a ban list and grant operator access to selected names."
echo "Only grant operator to people you trust."
read -r -p "Continue? [y/N] " answer
case "$answer" in
  y|Y|yes|YES)
    ;;
  *)
    echo "Cancelled."
    exit 0
    ;;
esac

send_command "whitelist off"
add_players "Players to ban" "ban"
add_players "Players to make operators" "op"
send_command "banlist players"

echo
echo "Ban list enabled and access setup complete."
echo "Everyone can join except banned names."
echo "To view the current lists, use: banlist players   and   ops"