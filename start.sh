#!/bin/bash
set -euo pipefail

# ========= PATHS =========
APP_DIR="$(pwd)"
FRONTEND_DIR="${APP_DIR}/myapp-frontend"
BACKEND_DIR="${APP_DIR}/myapp-backend"
SERVICE_NAME="myapp"
SERVICE_USER="$(whoami)"
SERVICE_GROUP="www-data"
NGINX_SITE="/etc/nginx/sites-available/${SERVICE_NAME}"
WEBROOT="/var/www/html"

echo "🚀 Starting deployment from: ${APP_DIR}"

# ========= SYSTEM PACKAGES =========
echo "📦 Updating server and installing system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y curl git nginx python3 python3-pip build-essential nodejs npm

# ========= FRONTEND BUILD =========
echo "📦 Building React frontend..."
cd "${FRONTEND_DIR}"
npm install --silent

if npm run build --silent; then
  echo "✅ Frontend build successful."
else
  echo "❌ Frontend build failed."
  exit 1
fi

# Detect build folder (build/ or dist/)
if [ -d "${FRONTEND_DIR}/build" ]; then
  BUILD_OUTPUT="${FRONTEND_DIR}/build"
elif [ -d "${FRONTEND_DIR}/dist" ]; then
  BUILD_OUTPUT="${FRONTEND_DIR}/dist"
else
  echo "❌ No build output found (expected build/ or dist/)."
  exit 1
fi

echo "📁 Copying frontend to nginx webroot..."
sudo rm -rf "${WEBROOT:?}"/*
sudo cp -r "${BUILD_OUTPUT}/"* "${WEBROOT}/"

# ========= BACKEND SETUP =========
echo "🐍 Installing backend Python dependencies..."

cd "${BACKEND_DIR}"

if [ ! -f .env ]; then
  echo "❌ Backend .env file missing at ${BACKEND_DIR}/.env"
  exit 1
fi

# Install backend Python packages globally
if [ -f requirements.txt ]; then
  sudo pip3 install -r requirements.txt
else
  sudo pip3 install gunicorn python-dotenv mysql-connector-python Flask Flask-Cors
fi

# ========= SYSTEMD SERVICE =========
echo "⚙️ Creating systemd service: ${SERVICE_NAME}.service..."
sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<SERVICE
[Unit]
Description=Flask Gunicorn Service for notes_app
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
WorkingDirectory=${BACKEND_DIR}
EnvironmentFile=${BACKEND_DIR}/.env

# Run DB init BEFORE starting gunicorn
# ExecStartPre=/usr/bin/python3 ${BACKEND_DIR}/init_db.py

# Start gunicorn with system python
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 127.0.0.1:5000 app:app

Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable --now ${SERVICE_NAME}.service

# ========= NGINX CONFIG =========
echo "⚙️ Configuring nginx proxy..."
sudo tee "${NGINX_SITE}" > /dev/null <<'NGINX'
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINX

sudo ln -sf "${NGINX_SITE}" /etc/nginx/sites-enabled/${SERVICE_NAME}
sudo rm -f /etc/nginx/sites-enabled/default

echo "🔍 Testing nginx configuration..."
sudo nginx -t
sudo systemctl restart nginx

# ========= DONE =========
echo "🎉 Deployment completed successfully!"
echo "🌐 Visit your app at: http://<EC2_PUBLIC_IP>/"
echo "📜 Check backend logs: sudo journalctl -u ${SERVICE_NAME}.service -f"

