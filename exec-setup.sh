echo "Creating RCON CLI configuration..."
cat > $HOME/.rcon-cli.yaml << EOF
host: 127.0.0.1
port: 25575
password: packwiz
EOF

echo "Installing RCON CLI..."
GOBIN=/usr/local/bin go install github.com/itzg/rcon-cli@latest