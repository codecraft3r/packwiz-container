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

# Prepare packwiz installer arguments
echo "Running packwiz installer..."
if [[ -n "$PACKWIZ_URL" ]]; then
    echo "Using direct PACKWIZ_URL: $PACKWIZ_URL"
    java -jar packwiz-installer-bootstrap.jar -g -s server "$PACKWIZ_URL"
elif [[ -n "$GH_USER" && -n "$GH_REPO" ]]; then
    echo "Using GitHub user: $GH_USER and repo: $GH_REPO"
    java -jar packwiz-installer-bootstrap.jar -g -s server --user "$GH_USER" --repo "$GH_REPO"
else
    echo "Error: Either PACKWIZ_URL or both GH_USER and GH_REPO environment variables must be set"
    exit 1
fi

echo "Done. Starting Minecraft server..."
sh /mnt/server/run.sh