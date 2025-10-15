#!/bin/bash

# Source the URL resolver
source /fetch-latest-release.sh

SERVER_DIR="/mnt/server"
SETUP_COMPLETE_FLAG="/.setup_complete"

# Check if setup has already been completed
if [[ ! -f "$SETUP_COMPLETE_FLAG" ]]; then
    echo "First run detected. Running setup..."
    sh /mc-setup.sh

    # Create flag file to indicate setup is complete
    touch "$SETUP_COMPLETE_FLAG"
    echo "Setup complete."
else
    echo "Setup already completed. Skipping setup script."
fi

# Start the server (modify this based on what your setup.sh creates)
cd "$SERVER_DIR"

# Resolve the packwiz URL (with PACKWIZ_URL override)
if [[ -n "$PACKWIZ_URL" ]]; then
    echo "Using direct PACKWIZ_URL override: $PACKWIZ_URL"
    RESOLVED_PACKWIZ_URL="$PACKWIZ_URL"
else
    echo "Resolving packwiz URL from GitHub variables..."
    RESOLVED_PACKWIZ_URL=$(resolve_packwiz_url)
    
    if [[ $? -ne 0 || -z "$RESOLVED_PACKWIZ_URL" ]]; then
        echo "Error: Could not resolve packwiz URL"
        exit 1
    fi
fi

echo "Using packwiz URL: $RESOLVED_PACKWIZ_URL"

echo "Running packwiz installer..."
java -jar packwiz-installer-bootstrap.jar -g -s server "$RESOLVED_PACKWIZ_URL"

echo "Done. Starting Minecraft server..."
sh /mnt/server/run.sh