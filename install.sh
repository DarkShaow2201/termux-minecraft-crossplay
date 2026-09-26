#!/data/data/com.termux/files/usr/bin/bash
#
# Install a Java + Bedrock cross-play Minecraft server in Termux.
# Run this script inside Termux, not from a normal Linux shell.
#
# Optional environment variables:
#   SERVER_DIR=$HOME/minecraft-server
#   MC_MEMORY=2G
#
set -euo pipefail

KIT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SERVER_DIR="${SERVER_DIR:-"$HOME/minecraft-server"}"
MC_MEMORY="${MC_MEMORY:-1G}"
PAPER_VERSION="${PAPER_VERSION:-}"
PAPER_API="https://fill.papermc.io/v3/projects/paper"
GEYSER_URL="https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot"
FLOODGATE_URL="https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot"

log() {
  printf '\n\033[1;36m==> %s\033[0m\n' "$*"
}

die() {
  printf '\033[1;31mError:\033[0m %s\n' "$*" >&2
  exit 1
}

command -v pkg >/dev/null 2>&1 || die "This installer must be run in Termux."

log "Installing Termux dependencies"
pkg update -y
pkg install -y curl wget ca-certificates coreutils sed grep

log "Finding the latest Paper build"
paper_json="$(curl -fsSL "$PAPER_API/versions")"
if [ -z "$PAPER_VERSION" ]; then
  paper_version="$(
    printf '%s' "$paper_json" |
      grep -o '"version":{"id":"[^"]*"' |
      head -n 1 |
      sed 's/.*"id":"//; s/"$//'
  )"
else
  paper_version="$PAPER_VERSION"
fi
[ -n "$paper_version" ] || die "Could not determine the latest Paper version."

version_json="$(curl -fsSL "$PAPER_API/versions/$paper_version")"
java_required="$(
  printf '%s' "$version_json" |
    grep -o '"minimum":[0-9]*' |
    head -n 1 |
    sed 's/[^0-9]//g'
)"
[ -n "$java_required" ] || die "Could not determine the Java version required by Paper $paper_version."

# The current Paper release declares the required Java major version. This
# avoids hard-coding Java 21 as Paper's requirement changes over time.
if ! pkg install -y "openjdk-$java_required"; then
  die "Termux could not install OpenJDK $java_required required by Paper $paper_version. Set PAPER_VERSION to an older compatible release or update Termux."
fi
java -version 2>&1 | head -n 1

build_json="$(curl -fsSL "$PAPER_API/versions/$paper_version/builds")"
paper_build="$(
  printf '%s' "$build_json" |
    grep -o '"id":[0-9]*' |
    head -n 1 |
    sed 's/[^0-9]//g'
)"
[ -n "$paper_build" ] || die "Could not determine the latest Paper build."

paper_url="$(
  printf '%s' "$build_json" |
    grep -o '"url":"https://[^"]*paper-[^"]*\.jar"' |
    head -n 1 |
    sed 's/.*"url":"//; s/"$//'
)"
paper_jar="$(
  printf '%s' "$build_json" |
    grep -o '"name":"paper-[^"]*\.jar"' |
    head -n 1 |
    sed 's/.*"name":"//; s/"$//'
)"
[ -n "$paper_url" ] || die "Could not determine the Paper download URL."
[ -n "$paper_jar" ] || paper_jar="paper-$paper_version-$paper_build.jar"

log "Downloading Paper $paper_version build $paper_build"
curl -fL --retry 3 "$paper_url" -o paper.jar

mkdir -p "$SERVER_DIR/plugins" "$SERVER_DIR/worlds"
cd "$SERVER_DIR"

download_plugin() {
  local url="$1"
  local output="$2"
  log "Downloading $output"
  curl -fL --retry 3 "$url" -o "plugins/$output"
}

download_plugin "$GEYSER_URL" "Geyser-Spigot.jar"
download_plugin "$FLOODGATE_URL" "floodgate-spigot.jar"

download_modrinth_plugin() {
  local slug="$1"
  local output="$2"
  local versions_json
  local plugin_url
  versions_json="$(
    curl -fsSL --retry 3 \
      "https://api.modrinth.com/v2/project/$slug/version?loaders=%5B%22paper%22%5D"
  )"
  plugin_url="$(
    printf '%s' "$versions_json" |
      grep -o '"url":"https://[^"]*\.jar"' |
      head -n 1 |
      sed 's/.*"url":"//; s/"$//'
  )"
  [ -n "$plugin_url" ] || die "Could not find a Paper build for Modrinth project $slug."
  download_plugin "$plugin_url" "$output"
}

# Server utilities requested for this kit.
download_modrinth_plugin "essentialsx" "EssentialsX.jar"
download_modrinth_plugin "griefprevention" "GriefPrevention.jar"
download_modrinth_plugin "coreprotect" "CoreProtect.jar"
download_modrinth_plugin "oneplayersleepgg" "OnePlayerSleep.jar"

# ViaVersion adds support for older Java clients. ViaBackwards and ViaRewind
# extend that range where the current server and plugin versions allow it.
download_github_jar() {
  local repo="$1"
  local name="$2"
  local asset_url
  asset_url="$(
    curl -fsSL "https://api.github.com/repos/$repo/releases/latest" |
      grep -o '"browser_download_url":[^,]*' |
      sed 's/.*"browser_download_url":[[:space:]]*"//; s/"$//' |
      grep -E "/${name}-[^/]+\.jar$" |
      head -n 1 || true
  )"
  [ -n "$asset_url" ] || die "Could not find the latest $name plugin from GitHub."
  download_plugin "$asset_url" "$name.jar"
}

download_github_jar "ViaVersion/ViaVersion" "ViaVersion"
download_github_jar "ViaVersion/ViaBackwards" "ViaBackwards"
download_github_jar "ViaVersion/ViaRewind" "ViaRewind"

cat > eula.txt <<'EOF'
# By setting eula=true you agree to the Minecraft EULA:
# https://aka.ms/MinecraftEULA
eula=true
EOF

cat > server.properties <<'EOF'
server-port=25565
query.port=25565
level-name=worlds/world
motd=Termux Cross-Play Server
online-mode=true
enable-query=false
enable-rcon=false
view-distance=8
simulation-distance=6
white-list=false
max-players=10
spawn-protection=0
allow-flight=false
EOF

cat > server.env <<EOF
# Edit this file to change memory, ports, or the server directory.
SERVER_DIR=$SERVER_DIR
MC_MEMORY=$MC_MEMORY
JAVA_FLAGS="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200"
EOF

# Keep the runtime helpers beside paper.jar so the printed commands work even
# when the installer was launched from a downloaded folder.
cp "$KIT_DIR/start.sh" "$KIT_DIR/stop.sh" "$KIT_DIR/backup.sh" "$SERVER_DIR/"
cp "$KIT_DIR/setup-access.sh" "$SERVER_DIR/"
cp "$KIT_DIR/tunnel.sh" "$SERVER_DIR/"
if [ ! -f "$SERVER_DIR/worlds/README.txt" ]; then
  cp "$KIT_DIR/worlds/README.txt" "$SERVER_DIR/worlds/README.txt"
fi
chmod +x "$SERVER_DIR/start.sh" "$SERVER_DIR/stop.sh" "$SERVER_DIR/backup.sh"
chmod +x "$SERVER_DIR/setup-access.sh"
chmod +x "$SERVER_DIR/tunnel.sh"

log "Installation complete"
printf '%s\n' \
  "Server directory: $SERVER_DIR" \
  "Java address/port: <phone-ip>:25565 (TCP)" \
  "Bedrock address/port: <phone-ip>:19132 (UDP)" \
  "" \
  "Start it with:" \
  "  cd \"$SERVER_DIR\" && ./start.sh" \
  "  ./setup-access.sh   # ban list and operator setup" \
  "  ./tunnel.sh   # optional public Java + Bedrock access" \
  "" \
  "On first start, Geyser creates its config and the launcher applies Floodgate authentication."