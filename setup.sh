#!/usr/bin/env bash

set -e

ENV_FILE=".env"
SERVICE_NAME="observability"

# Function to prompt for env vars
create_env() {
  echo "Creating .env file..."
  read -p "Enter Metabase Database connection URI: " MB_DB_CONNECTION_URI
  read -p "Enter Metabase Site URL (default: http://localhost/metabase): " MB_SITE_URL
  MB_SITE_URL=${MB_SITE_URL:-http://localhost/metabase}
  {
    echo "MB_DB_CONNECTION_URI=\"$MB_DB_CONNECTION_URI\""
    echo "MB_SITE_URL=\"$MB_SITE_URL\""
  } > "$ENV_FILE"
  echo ".env file created."
}

# Check for .env
if [ ! -f "$ENV_FILE" ]; then
  create_env
else
  echo ".env file already exists."
fi

# Create systemd service file
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Observability Docker Compose Stack
After=network.target

[Service]
Type=simple
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=on-failure
RestartSec=10
StartLimitIntervalSec=600
StartLimitBurst=3
EnvironmentFile=$(pwd)/.env

[Install]
WantedBy=multi-user.target
EOL

echo "Reloading systemd daemon and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "<your-server-ip>")

# Print access URLs
cat <<EOF

Service $SERVICE_NAME is set up and running.

Access your services at:
  Grafana:   http://$PUBLIC_IP/grafana
  Metabase:  http://$PUBLIC_IP/metabase
EOF
