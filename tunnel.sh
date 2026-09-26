#!/data/data/com.termux/files/usr/bin/bash
#
# Download and run the Playit agent. The first run prints a claim URL.
# Create a TCP Minecraft tunnel to 127.0.0.1:25565 and a UDP tunnel to
# 127.0.0.1:19132 in the Playit dashboard.
#
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR"

command -v curl >/dev/null 2>&1 || {
  echo "curl is required. Run: pkg install -y curl"
  exit 1
}

case "$(uname -m)" in
  aarch64|arm64)
    agent_name="playit-linux-aarch64"
    ;;
  x86_64|amd64)
    agent_name="playit-linux-amd64"
    ;;
  *)
    echo "Unsupported Termux CPU architecture: $(uname -m)"
    echo "Playit currently provides Linux ARM64 and AMD64 agents."
    exit 1
    ;;
esac

if [ ! -x ./playit-agent ]; then
  echo "Downloading Playit agent for $(uname -m)..."
  curl -fL --retry 3 \
    "https://github.com/playit-cloud/playit-agent/releases/latest/download/$agent_name" \
    -o playit-agent
  chmod +x playit-agent
fi

cat <<'EOF'

Playit setup:
1. The agent will print a claim URL the first time it runs. Open it in a browser.
2. In the Playit dashboard create:
   - Minecraft Java TCP -> local address 127.0.0.1:25565
   - Custom UDP or Minecraft Bedrock UDP -> local address 127.0.0.1:19132
3. Give Java players the assigned hostname and port.
4. Give Bedrock players the assigned hostname and UDP port.

Keep this process running while people are playing.

EOF
exec ./playit-agent