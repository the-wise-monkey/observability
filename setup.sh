#!/usr/bin/env bash

set -e

ENV_FILE=".env"
SERVICE_NAME="observability"

# Function to prompt for env vars
create_env() {
  echo "Creating .env file..."
  echo
  
  # Grafana configuration
  echo "=== Grafana Configuration ==="
  # Currently no specific env vars needed for Grafana
  echo "Grafana will use default configuration."
  echo
  
  # Metabase configuration
  echo "=== Metabase Configuration ==="
  read -p "Enter Metabase Database connection URI: " MB_DB_CONNECTION_URI
  read -p "Enter Metabase Site URL (default: http://localhost/metabase): " MB_SITE_URL
  MB_SITE_URL=${MB_SITE_URL:-http://localhost/metabase}
  echo
  
  # Promtail configuration (optional S3 logs configuration)
  echo "=== Promtail Configuration ==="
  echo "Optional: Configure S3 logs bucket for log scraping"
  read -p "Enter S3 Logs Bucket Name (optional, press Enter to skip): " S3_LOGS_BUCKET_NAME
  read -p "Enter S3 Logs Prefix (optional, press Enter to skip): " S3_LOGS_PREFIX
  echo
  
  # Write to .env file
  {
    echo "# Metabase Configuration"
    echo "MB_DB_CONNECTION_URI=\"$MB_DB_CONNECTION_URI\""
    echo "MB_SITE_URL=\"$MB_SITE_URL\""
    echo
    if [ -n "$S3_LOGS_BUCKET_NAME" ] || [ -n "$S3_LOGS_PREFIX" ]; then
      echo "# Promtail S3 Configuration (for S3 log scraping)"
      [ -n "$S3_LOGS_BUCKET_NAME" ] && echo "S3_LOGS_BUCKET_NAME=\"$S3_LOGS_BUCKET_NAME\""
      [ -n "$S3_LOGS_PREFIX" ] && echo "S3_LOGS_PREFIX=\"$S3_LOGS_PREFIX\""
    fi
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
PUBLIC_IP=$(curl -4 -s ifconfig.me || curl -4 -s ipinfo.io/ip || echo "<your-ipv4>")

# Print access URLs
cat <<EOF

Service $SERVICE_NAME is set up and running.

Access your services at:
  Grafana:   http://$PUBLIC_IP/grafana
  Metabase:  http://$PUBLIC_IP/metabase
EOF
