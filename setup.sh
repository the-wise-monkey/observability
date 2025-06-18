#!/usr/bin/env bash

set -e

ENV_FILE=".env"
SERVICE_NAME="observability"

# Function to prompt for env vars
create_env() {
  echo "Creating .env file..."
  read -p "Enter Metabase Database URL: " MB_DB_URL
  read -p "Enter Metabase SSL Certificate Path: " MB_DB_SSL_CERT
  echo "MB_DB_URL=\"$MB_DB_URL\"" > "$ENV_FILE"
  echo "MB_DB_SSL_CERT=\"$MB_DB_SSL_CERT\"" >> "$ENV_FILE"
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
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
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

echo "Service $SERVICE_NAME is set up and running."
