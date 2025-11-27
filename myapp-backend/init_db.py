#!/bin/bash
set -e

# ========= SETUP =========
APP_DIR="$(pwd)"
FRONTEND_DIR="${APP_DIR}/myapp-frontend"
BACKEND_DIR="${APP_DIR}/myapp-backend"
echo "🚀 Starting deployment from $(pwd)"

# ========= SYSTEM_UPDATE =========
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y curl git nginx build-essential python3-venv

# ========= NODE_INSTALL =========
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# ========= PM2_INSTALL =========
sudo npm install -g pm2

# ========= BACKEND_SETUP =========
echo "⚙️ Setting up Flask backend..."
cd "$BACKEND_DIR" || exit 1
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt || pip install Flask gunicorn
deactivate
pm2 start venv/bin/gunicorn --name myapp-backend -- -b 0.0.0.0:5000 app:app

# ========= FRONTEND_SETUP =========
echo "⚙️ Building React frontend..."
cd "$FRONTEND_DIR" || exit 1
npm install 
npm run build

# ========= NGINX_CONFIG =========
sudo rm -rf /var/www/html/*
sudo cp -r dist/* /var/www/html/
echo "⚙️ Configuring nginx..."
sudo tee /etc/nginx/sites-available/myapp >/dev/null <<NGINX
server {
    listen 80;

    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINX
sudo ln -sf /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/myapp
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# ========= PM2_REBOOT_SETUP =========
pm2 save
pm2 startup systemd -u ubuntu --hp /home/ubuntu

# ========= DEPLOYMENT_COMPLETE =========
echo "✅ Deployment completed!"
