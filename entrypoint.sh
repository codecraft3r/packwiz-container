#!/bin/bash

SERVER_DIR="/mnt/server"
SETUP_COMPLETE_FLAG="$SERVER_DIR/.setup_complete"

# Check if setup has already been completed
if [[ ! -f "$SETUP_COMPLETE_FLAG" ]]; then
    echo "First run detected. Running setup..."
    /setup.sh
    
    # Create flag file to indicate setup is complete
    touch "$SETUP_COMPLETE_FLAG"
    echo "Setup complete."
else
    echo "Setup already completed. Skipping setup script."
fi

# Start the server (modify this based on what your setup.sh creates)
cd "$SERVER_DIR"

java -jar packwiz-installer-bootstrap.jar -g -s server 
sh /mnt/server/run.sh