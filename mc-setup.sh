#!/bin/bash

# Source the URL resolver
source /fetch-latest-release.sh

# Define server directory
SERVER_DIR="/mnt/server"
mkdir -p "$SERVER_DIR"
cd "$SERVER_DIR" || exit 1

# Resolve the packwiz URL from environment variables
echo "Resolving packwiz URL..."
RESOLVED_PACKWIZ_URL=$(resolve_packwiz_url)

if [[ $? -ne 0 || -z "$RESOLVED_PACKWIZ_URL" ]]; then
    echo "Error: Could not resolve packwiz URL. Please set either:"
    echo "  - PACKWIZ_URL (direct URL to pack.toml)"
    echo "  - GH_USERNAME and GH_REPO (optionally with PACK_VERSION)"
    exit 1
fi

echo "Using packwiz URL: $RESOLVED_PACKWIZ_URL"



# Fetch pack.toml
echo "Fetching pack.toml from $RESOLVED_PACKWIZ_URL"
curl -sSL "$RESOLVED_PACKWIZ_URL" -o pack.toml

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
PACKWIZ_BOOTSTRAP_URL="https://github.com/codecraft3r/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar"
if [[ -z "$PACKWIZ_BOOTSTRAP_URL" ]]; then
    echo "Error: Failed to get Packwiz bootstrap URL."
    exit 1
fi

curl -sSL "$PACKWIZ_BOOTSTRAP_URL" -o packwiz-installer-bootstrap.jar

# Create packwiz-installer.properties file
echo "Creating packwiz-installer.properties..."
cat > packwiz-installer.properties << EOF
pack.url=$RESOLVED_PACKWIZ_URL
auto-update=true
EOF

# Export JVM arguments to user_jvm_args.txt
echo "-Xms${MB_RAM}M -Xmx${MB_RAM}M -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3 -XX:+UseG1GC -XX:MaxGCPauseMillis=130 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=28 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=20 -XX:G1MixedGCCountTarget=3 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:SurvivorRatio=32 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5 -XX:G1ConcRSHotCardLimit=16 -XX:G1ConcRefinementServiceIntervalMillis=150" > user_jvm_args.txt

# Create server.properties file
cat >> server.properties << EOF
allow-flight=true
white-list=true
enforce-whitelist=true
enable-rcon=true
rcon.password=packwiz
rcon.port=25575
EOF

# Create whitelist.json if WHITELIST_JSON is set
if [[ -n "${WHITELIST_JSON//[[:space:]]/}" ]]; then
    echo "Creating whitelist.json..."
    if echo "$WHITELIST_JSON" | jq -e . >/dev/null 2>&1; then
        echo "$WHITELIST_JSON" | jq . > whitelist.json.tmp && mv whitelist.json.tmp whitelist.json
    else
        echo "Invalid WHITELIST_JSON provided, skipping creation."
    fi
else
    echo "No whitelist.json provided, skipping creation."
fi

echo "Installation complete."
echo "The server is configured to use the packwiz modpack at: $RESOLVED_PACKWIZ_URL"
