#!/bin/bash
set -euo pipefail

# ========= PATHS & CONFIG =========
APP_DIR="$(pwd)"
FRONTEND_DIR="${APP_DIR}/myapp-frontend"
BACKEND_DIR="${APP_DIR}/myapp-backend"
SERVICE_NAME="myapp"
SERVICE_USER="$(whoami)"
SERVICE_GROUP="www-data"
NGINX_SITE="/etc/nginx/sites-available/${SERVICE_NAME}"
WEBROOT="/var/www/html"

echo "🚀 Deploy script starting from: ${APP_DIR}"
echo "Frontend: ${FRONTEND_DIR}"
echo "Backend:  ${BACKEND_DIR}"
echo "Service will run as: ${SERVICE_USER}"

# ========= SYSTEM PACKAGES =========
echo "📦 Updating server and installing base packages..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y curl git nginx python3 python3-pip build-essential

# ========= NODE 18 INSTALL (NodeSource) =========
echo "🔧 Ensuring Node.js 18 is installed (required for Vite)..."
if command -v node >/dev/null 2>&1; then
  NODE_VER="$(node -v || true)"
  echo "Current node version: ${NODE_VER}"
fi

# Install Node 18 if node missing or version < 16 (naive semver check)
INSTALL_NODE=false
if ! command -v node >/dev/null 2>&1; then
  INSTALL_NODE=true
else
  # get major version
  NODE_MAJOR=$(node -v | sed -E 's/v([0-9]+).*/\1/')
  if [ "${NODE_MAJOR:-0}" -lt 16 ]; then
    INSTALL_NODE=true
  fi
fi

if [ "${INSTALL_NODE}" = true ]; then
  echo "Installing Node.js 18 via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

echo "node version: $(node -v)"
echo "npm version: $(npm -v)"

# ========= FRONTEND BUILD =========
echo "📦 Building frontend..."
if [ ! -d "${FRONTEND_DIR}" ]; then
  echo "❌ Frontend directory not found: ${FRONTEND_DIR}"
  exit 1
fi

cd "${FRONTEND_DIR}"

# clean node_modules and lockfile to avoid old-binary issues
rm -rf node_modules package-lock.json yarn.lock || true

echo "Installing frontend dependencies..."
# prefer npm ci when lockfile is present, otherwise npm install
if [ -f package-lock.json ]; then
  npm ci --silent
else
  npm install --silent
fi

# run build (exit on failure)
if npm run build --silent; then
  echo "✅ Frontend build succeeded."
else
  echo "❌ Frontend build failed."
  exit 1
fi

# detect build output directory (build/ or dist/)
if [ -d "${FRONTEND_DIR}/build" ]; then
  BUILD_OUTPUT="${FRONTEND_DIR}/build"
elif [ -d "${FRONTEND_DIR}/dist" ]; then
  BUILD_OUTPUT="${FRONTEND_DIR}/dist"
else
  echo "❌ Could not find frontend build output (build/ or dist/)."
  exit 1
fi

# copy to nginx webroot
echo "📁 Copying frontend to ${WEBROOT}..."
sudo rm -rf "${WEBROOT:?}"/*
sudo cp -r "${BUILD_OUTPUT}/"* "${WEBROOT}/"

# ========= BACKEND SETUP =========
echo "🐍 Installing backend Python dependencies (system python)..."
if [ ! -d "${BACKEND_DIR}" ]; then
  echo "❌ Backend directory not found: ${BACKEND_DIR}"
  exit 1
fi
cd "${BACKEND_DIR}"

if [ ! -f .env ]; then
  echo "❌ Backend .env file missing at ${BACKEND_DIR}/.env"
  exit 1
fi

if [ -f requirements.txt ]; then
  echo "Installing requirements.txt via pip3..."
  sudo pip3 install -r requirements.txt
else
  echo "No requirements.txt found — installing minimal runtime packages..."
  sudo pip3 install gunicorn python-dotenv mysql-connector-python Flask Flask-Cors
fi

# find gunicorn binary path (installed by pip3)
GUNICORN_BIN="$(command -v gunicorn || true)"
if [ -z "${GUNICORN_BIN}" ]; then
  # try common location
  if [ -x "/usr/local/bin/gunicorn" ]; then
    GUNICORN_BIN="/usr/local/bin/gunicorn"
  else
    echo "❌ gunicorn not found in PATH. Ensure pip3 installation succeeded."
    exit 1
  fi
fi
echo "Using gunicorn binary at: ${GUNICORN_BIN}"

# ========= systemd service =========
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
ExecStartPre=/usr/bin/python3 ${BACKEND_DIR}/init_db.py

# Start gunicorn with system python-installed gunicorn
ExecStart=${GUNICORN_BIN} --workers 3 --bind 127.0.0.1:5000 app:app

Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICE

echo "🔁 Reloading systemd and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable --now ${SERVICE_NAME}.service

# ========= NGINX CONFIG =========
echo "⚙️ Configuring nginx site..."
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

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2|woff|ttf)$ {
        try_files $uri =404;
        expires 7d;
        add_header Cache-Control "public, no-transform";
    }
}
NGINX

sudo ln -sf "${NGINX_SITE}" /etc/nginx/sites-enabled/${SERVICE_NAME}
sudo rm -f /etc/nginx/sites-enabled/default || true

echo "🔍 Testing nginx configuration..."
sudo nginx -t
echo "🔁 Restarting nginx..."
sudo systemctl restart nginx

# ========= FINAL CHECKS =========
echo "🧾 Service status (last 20 lines):"
sudo journalctl -u ${SERVICE_NAME}.service -n 20 --no-pager || true

echo "🌐 Nginx error log (last 20 lines):"
sudo tail -n 20 /var/log/nginx/error.log || true
