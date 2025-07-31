#!/bin/bash

# Define server directory
SERVER_DIR="/mnt/server"
mkdir -p "$SERVER_DIR"
cd "$SERVER_DIR" || exit 1

# Ensure PACKWIZ_URL is set
if [[ -z "$PACKWIZ_URL" ]]; then
    echo "Error: PACKWIZ_URL environment variable is not set."
    exit 1
fi



# Fetch pack.toml
echo "Fetching pack.toml from $PACKWIZ_URL"
curl -sSL "$PACKWIZ_URL" -o pack.toml

# Extract modloader and version information
MODLOADER=$(grep -E '^(forge|neoforge|fabric|quilt)\s*=' pack.toml | awk -F'=' '{print $1}' | tr -d ' ')
MODLOADER_VERSION=$(grep -E "^$MODLOADER\s*=" pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
MINECRAFT_VERSION=$(grep -E '^minecraft\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')

if [[ -z "$MODLOADER" || -z "$MINECRAFT_VERSION" ]]; then
    echo "Error: Unable to determine modloader or Minecraft version from pack.toml."
    exit 1
fi

echo "Detected modloader: $MODLOADER"
echo "Modloader version: $MODLOADER_VERSION"
echo "Minecraft version: $MINECRAFT_VERSION"

# Install mc-image-helper directly in the current directory
echo "Installing mc-image-helper..."
mkdir -p mc-image-helper
curl -sSL https://github.com/itzg/mc-image-helper/releases/download/1.41.9/mc-image-helper-1.41.9.tgz | tar -xz -C mc-image-helper --strip-components=1
chmod +x mc-image-helper/bin/mc-image-helper

# Install mod loader using mc-image-helper
case "$MODLOADER" in
    forge)
        echo "Installing Forge..."
        ./mc-image-helper/bin/mc-image-helper install-forge \
            --minecraft-version "$MINECRAFT_VERSION" \
            --forge-version "$MODLOADER_VERSION" \
            --output-directory "$SERVER_DIR" \
            --results-file "${SERVER_DIR}/install-results.properties"
        ;;
    neoforge)
        echo "Installing NeoForge..."
        ./mc-image-helper/bin/mc-image-helper install-neoforge \
            --minecraft-version "$MINECRAFT_VERSION" \
            --neoforge-version "$MODLOADER_VERSION" \
            --output-directory "$SERVER_DIR" \
            --results-file "${SERVER_DIR}/install-results.properties"
        ;;
    fabric)
        echo "Installing Fabric..."
        ./mc-image-helper/bin/mc-image-helper install-fabric-loader \
            --minecraft-version "$MINECRAFT_VERSION" \
            --loader-version "$MODLOADER_VERSION" \
            --output-directory "$SERVER_DIR" \
            --results-file "${SERVER_DIR}/install-results.properties"
        ;;
    quilt)
        echo "Installing Quilt..."
        ./mc-image-helper/bin/mc-image-helper install-quilt \
            --minecraft-version "$MINECRAFT_VERSION" \
            --loader-version "$MODLOADER_VERSION" \
            --output-directory "$SERVER_DIR" \
            --results-file "${SERVER_DIR}/install-results.properties"
        ;;
    *)
        echo "Error: Unsupported modloader '$MODLOADER'."
        exit 1
        ;;
esac

# Download and install Packwiz installer bootstrap
echo "Installing Packwiz bootstrap..."
PACKWIZ_BOOTSTRAP_URL=$(curl -s https://api.github.com/repos/packwiz/packwiz-installer-bootstrap/releases/latest | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url')
if [[ -z "$PACKWIZ_BOOTSTRAP_URL" ]]; then
    echo "Error: Failed to get Packwiz bootstrap URL."
    exit 1
fi

curl -sSL "$PACKWIZ_BOOTSTRAP_URL" -o packwiz-installer-bootstrap.jar

# Create packwiz-installer.properties file
echo "Creating packwiz-installer.properties..."
cat > packwiz-installer.properties << EOF
pack.url=$PACKWIZ_URL
auto-update=true
EOF

# Export JVM arguments to user_jvm_args.txt
echo "-Xms${MB_RAM}M -Xmx${MB_RAM}M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true" > user_jvm_args.txt

# Create server.properties file
cat >> server.properties << EOF
allow-flight=true
enable-rcon=true
rcon.password=packwiz
rcon.port=25575
EOF

# Create whitelist.json if WHITELIST_JSON is set
if [[ -n "$WHITELIST_JSON" ]]; then
    echo "Creating whitelist.json..."
    echo "$WHITELIST_JSON" | jq '.' > whitelist.json
    cat >> server.properties << EOF
    white-list=true
    enforce-whitelist=true
EOF
else
    echo "No whitelist.json provided, skipping creation."
fi

echo "Installation complete."
echo "The server is configured to use the packwiz modpack at: $PACKWIZ_URL"