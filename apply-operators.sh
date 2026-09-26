#!/data/data/com.termux/files/usr/bin/bash
#
# Grant OP permissions to the usernames listed in operators.txt.
# Run this while ./start.sh is running.
#
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
FIFO="$SCRIPT_DIR/.minecraft-console"
OPERATORS_FILE="$SCRIPT_DIR/operators.txt"

if [ ! -p "$FIFO" ]; then
  echo "The server console is not available."
  echo "Start the server first with: ./start.sh"
  exit 1
fi

if [ ! -f "$OPERATORS_FILE" ]; then
  echo "Missing operators.txt."
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
    *)
      [ "${#1}" -le 16 ]
      ;;
  esac
}

applied=0
while IFS= read -r name || [ -n "$name" ]; do
  # Remove Windows line endings and surrounding spaces.
  name="${name//$'\r'/}"
  name="${name#"${name%%[![:space:]]*}"}"
  name="${name%"${name##*[![:space:]]}"}"

  case "$name" in
    ""|\#*)
      continue
      ;;
  esac

  if valid_name "$name"; then
    send_command "op $name"
    echo "Operator added: $name"
    applied=$((applied + 1))
  else
    echo "Skipped invalid Minecraft username: $name"
  fi
done < "$OPERATORS_FILE"

echo "Applied operator permissions to $applied username(s)."