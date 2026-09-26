# Termux Minecraft Java + Bedrock server

This kit installs a Paper server with:

- **Geyser-Spigot** — Bedrock clients join a Java server.
- **Floodgate** — Bedrock players do not need a Java Edition account.
- **ViaVersion, ViaBackwards, ViaRewind** — older Java clients can often join a newer server.
- **EssentialsX** — common commands and server utilities.
- **GriefPrevention** — player land claims.
- **CoreProtect** — block-change logging and rollback.
- **OnePlayerSleep** — one player can skip the night for everyone.
- **Ban-list/operator setup** — block selected players while allowing everyone else to join.
- **Operator note file** — add usernames to `operators.txt` and apply them with one command.
- **Network settings file** — set the bind address, advertised IP, and ports in `network.env`.
- **Separate `worlds/` folder** — upload custom worlds without mixing them with plugins and server files.

## Install on Android

1. Install Termux from **F-Droid or GitHub**, not the Play Store build.
2. Run the one-command installer:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/DarkShaow2201/termux-minecraft-crossplay/main/install-termux.sh | bash
   ```

   It clones the installer to `~/termux-minecraft-crossplay`, downloads the
   current server/plugins, and creates the running server directory at
   `~/minecraft-server`.

3. For a manual clone, install Git if needed:

   ```sh
   pkg update -y
   pkg install -y git
   ```

4. Put this folder in Termux, then run:

   ```sh
   cd termux-minecraft
   chmod +x install.sh start.sh stop.sh backup.sh setup-access.sh apply-operators.sh tunnel.sh
   ./install.sh
   ./start.sh
   ```

   If the folder was downloaded elsewhere, copy it into Termux first. The
   install script downloads the current server and plugin builds at that time.

   The installer detects the Java version required by the newest Paper
   release. If your Termux repository does not offer that Java version yet,
   update Termux first; alternatively pin an older Paper line, for example:

   ```sh
   PAPER_VERSION=1.21.11 ./install.sh
   ```

4. Keep Termux awake while the server is running:

   ```sh
   termux-wake-lock
   ```

   Android may still stop background processes, so exempt Termux from battery
   optimization in Android settings.

## Add server operators from a file

The server keeps a separate operator list here:

```text
$HOME/minecraft-server/operators.txt
```

Edit it and add one Minecraft username per line. Then, while the server is
running, apply the list:

```sh
cd "$HOME/minecraft-server"
nano operators.txt
./apply-operators.sh
```

Lines beginning with `#` and blank lines are ignored. The script sends `op`
commands through the live server console, so those players can use server
commands. Only list people you trust.

## Set the server IP address

Edit this file:

```sh
cd "$HOME/minecraft-server"
nano network.env
```

Recommended configuration:

```text
BIND_IP=
ADVERTISE_IP=192.168.1.100
JAVA_PORT=25565
BEDROCK_PORT=19132
```

`192.168.1.100` is an example private Wi-Fi address. It works only if your
router gives that address to the phone. To keep it stable, create a DHCP
reservation for the phone in your router. Without a reservation, find the
current address with `ip addr show wlan0` and update `ADVERTISE_IP`.

Leave `BIND_IP` empty in most cases. This lets the server accept connections
through Wi-Fi, hotspot, and Playit. The local IP is not the public Playit
address; outside players should use the hostname and port shown by Playit.

## Uploading a custom world

The server uses this world path by default:

```text
$HOME/minecraft-server/worlds/world
```

Stop the server before replacing a world:

```sh
cd "$HOME/minecraft-server"
./stop.sh
```

Extract or upload your world so `level.dat` is directly inside:

```text
worlds/world/level.dat
```

Do not upload only a zip file, and do not create an extra nested folder such
as `worlds/world/my-world/level.dat`. The folder containing `level.dat` must be
named `world`, unless you also change `level-name` in `server.properties`.
The Nether and End folders should be named `world_nether` and `world_the_end`
beside it. Start the server again with `./start.sh`.

## Ban list and operator setup

Start the server, then open another Termux session in the server directory:

```sh
cd "$HOME/minecraft-server"
./setup-access.sh
```

Enter player names to ban separated by commas, then enter the names that
should receive operator permissions. The script validates usernames, turns
whitelist mode off, adds the selected names to Minecraft's ban list, and
sends the commands through the running server console. Everyone else can join.
Only give operator access to trusted players.

## Public internet access with Playit

If players are not on the same Wi-Fi, run the optional tunnel launcher in a
second Termux session:

```sh
cd "$HOME/minecraft-server"
./tunnel.sh
```

The first run prints a Playit claim link. After claiming it, create these two
tunnels in the Playit dashboard:

| Tunnel | Local address | Protocol |
|---|---|---|
| Minecraft Java | `127.0.0.1:25565` | TCP |
| Minecraft Bedrock | `127.0.0.1:19132` | UDP |

Use the public hostname and port shown by Playit. Java players use the Java
endpoint; Bedrock players use the UDP endpoint. The Playit process must stay
running, and its UDP support should be tested with one Bedrock player before
sharing the address widely.

## How players connect

Find the phone's local IP with:

```sh
ip addr show wlan0
```

- Java Edition: `PHONE_IP:25565`
- Bedrock Edition: `PHONE_IP`, port `19132`

For players outside the home network, forward **TCP 25565** and **UDP 19132**
to the phone. Mobile networks commonly use CGNAT, which can prevent inbound
connections even when port forwarding is configured; a VPN tunnel or hosted
server is then required.

## Version compatibility

No Minecraft server can accept literally every Java and Bedrock version. Each
client protocol has to be supported by the installed software, and Mojang
updates can temporarily move the compatibility boundary. This setup is the
best practical approach:

- Geyser supports the Bedrock versions supported by its current release.
- ViaVersion plugins extend Java compatibility to older versions where
  supported.
- The newest client versions may require a newer Paper/Geyser release, so
  rerun `install.sh` to update the jars after a major Minecraft release.

Do not install random “all versions” plugins on top of this stack; they often
break login or world compatibility.

## Useful commands

```sh
./start.sh                 # start and view the console
./stop.sh                  # save and stop
./backup.sh                # archive the worlds/ folders
./setup-access.sh          # configure ban list and OPs
./apply-operators.sh       # grant OP to names in operators.txt
./tunnel.sh                # optional public Java + Bedrock tunnel
tail -f server.log         # inspect startup or connection errors
```

The server uses `online-mode=true` for Java authentication. Bedrock accounts
are authenticated by Floodgate. Only give operator permissions to people you
trust.